# 계약:
# - 책임: 체력바, 실드바, 고정(Pin) 진행도 바, 활성 큐 비주얼 젬(Gem) 리스트 및 오버히트/수리 오버레이 상태를 렌더링한다. HP/Shield 수치의 병행 표기 및 타이머 카운트다운을 지원한다.
# - 입력: HP/Shield 수치 Dictionary, pin 상태 Dictionary, queue 아이템 Array, repair_overlay 참조 노드.
# - 출력: UI 라벨 및 프로그레스바 수치 업데이트.
# - 금지: 핵심 제어 컨트롤러 및 도메인 시뮬레이터 참조.
# 실행: define the StatusPanel UI controller.
extends PanelContainer
@onready var extractor_label: Label = $Margin/StatusBox/NodeRow/ExtractorLabel
@onready var visual_queue_box: HBoxContainer = $Margin/StatusBox/QueueRow/VisualQueueBox
@onready var extractor_visual: Panel = $Margin/StatusBox/NodeRow/ExtractorVisual
@onready var health_bar: ProgressBar = $Margin/StatusBox/HPBox/HealthBar
@onready var shield_bar: ProgressBar = $Margin/StatusBox/ShieldBox/ShieldBar
@onready var pin_progress_bar: ProgressBar = $Margin/StatusBox/TimerRow/PinProgressBar
@onready var pin_label: Label = $Margin/StatusBox/TimerRow/PinLabel
@onready var repair_status_label: Label = $Margin/StatusBox/DrillStatusRow/RepairStatusLabel

# 실행: update target HP and Shield bars with exact values and percentages.
func render_target_bars(scene: Dictionary) -> void:
	if not (str(scene.get("phase", "")) == "combat" or (str(scene.get("phase", "")) == "reward_loot" and scene.get("show_victory_overlay", false))):
		return
	var target: Dictionary = scene.get("targetPanel", {})
	var max_hp = float(target.get("maxHealth", 100.0))
	var max_shield = float(target.get("maxShield", 2.4))
	var hp_val = float(target.get("health", 0.0))
	var sh_val = float(target.get("shield", 0.0))
	
	health_bar.max_value = max_hp
	health_bar.value = hp_val
	health_bar.show_percentage = false
	
	shield_bar.max_value = max_shield
	shield_bar.value = sh_val
	shield_bar.show_percentage = false
	
	# Draw custom exact value label inside HealthBar
	var hp_lbl = health_bar.get_node_or_null("ValLabel") as Label
	if hp_lbl == null:
		hp_lbl = Label.new()
		hp_lbl.name = "ValLabel"
		hp_lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		hp_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		hp_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		hp_lbl.add_theme_font_size_override("font_size", 10)
		hp_lbl.add_theme_color_override("font_color", Color.WHITE)
		health_bar.add_child(hp_lbl)
	var hp_pct = (hp_val / max_hp) * 100.0 if max_hp > 0.0 else 0.0
	hp_lbl.text = "%.1f / %.1f (%.0f%%)" % [hp_val, max_hp, hp_pct]
	
	# Draw custom exact value label inside ShieldBar
	var sh_lbl = shield_bar.get_node_or_null("ValLabel") as Label
	if sh_lbl == null:
		sh_lbl = Label.new()
		sh_lbl.name = "ValLabel"
		sh_lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		sh_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		sh_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		sh_lbl.add_theme_font_size_override("font_size", 10)
		sh_lbl.add_theme_color_override("font_color", Color.WHITE)
		shield_bar.add_child(sh_lbl)
	var sh_pct = (sh_val / max_shield) * 100.0 if max_shield > 0.0 else 0.0
	sh_lbl.text = "%.1f / %.1f (%.0f%%)" % [sh_val, max_shield, sh_pct]

# 실행: update extractor node label.
func render_extractor_label(scene: Dictionary) -> void:
	var last_node = str(scene.get("lastNodeLabel", ""))
	if last_node != "":
		extractor_label.text = "노드: %s" % last_node
	else:
		extractor_label.text = "노드: —"

# 실행: render glowing circle gems inside the queue panel.
func render_visual_queue(scene: Dictionary) -> void:
	for child in visual_queue_box.get_children():
		child.queue_free()
	if not (str(scene.get("phase", "")) == "combat" or (str(scene.get("phase", "")) == "reward_loot" and scene.get("show_victory_overlay", false))):
		return
	var hud: Dictionary = scene.get("hud", {})
	var queue: Dictionary = hud.get("queue", {})
	var capacity := int(queue.get("capacity", 8))
	var items: Array = queue.get("items", [])
	for i in range(capacity):
		var gem := Panel.new()
		var style := StyleBoxFlat.new()
		style.corner_radius_top_left = 10
		style.corner_radius_top_right = 10
		style.corner_radius_bottom_right = 10
		style.corner_radius_bottom_left = 10
		if i < items.size():
			var color_name = str(items[i])
			if color_name == "red":
				style.bg_color = Color(0.9, 0.25, 0.25)
			elif color_name == "blue":
				style.bg_color = Color(0.25, 0.5, 0.9)
			elif color_name == "green":
				style.bg_color = Color(0.25, 0.75, 0.35)
			elif color_name == "purple":
				style.bg_color = Color(0.65, 0.25, 0.85)
			if i == 0:
				gem.custom_minimum_size = Vector2(24, 24)
				style.corner_radius_top_left = 12
				style.corner_radius_top_right = 12
				style.corner_radius_bottom_right = 12
				style.corner_radius_bottom_left = 12
				style.border_width_left = 2
				style.border_width_top = 2
				style.border_width_right = 2
				style.border_width_bottom = 2
				style.border_color = Color.WHITE
			else:
				gem.custom_minimum_size = Vector2(18, 18)
		else:
			style.bg_color = Color(0.1, 0.12, 0.15) # Empty socket slot
			style.border_width_left = 1
			style.border_width_top = 1
			style.border_width_right = 1
			style.border_width_bottom = 1
			style.border_color = Color(0.2, 0.24, 0.3, 0.6)
			gem.custom_minimum_size = Vector2(16, 16)
		gem.add_theme_stylebox_override("panel", style)
		visual_queue_box.add_child(gem)

# 실행: render the repair critical overlay when drill fails, and update pin bars with exact remaining ticks.
func render_repair_overlay(scene: Dictionary, repair_overlay: PanelContainer) -> void:
	if repair_overlay == null:
		return
	
	var phase := str(scene.get("phase", ""))
	var hud: Dictionary = scene.get("hud", {})
	var is_victory_overlay = (phase == "reward_loot" and scene.get("show_victory_overlay", false) and not scene.get("is_reveal_vfx_running", false))
	
	# Update Pin and Repair status bars (visible in both combat and victory overlay reward_loot)
	if (phase == "combat" or is_victory_overlay) and not hud.is_empty():
		var pin: Dictionary = hud.get("pin", {})
		pin_progress_bar.max_value = 100.0
		var pin_val = float(pin.get("progress", 0))
		pin_progress_bar.value = pin_val
		pin_progress_bar.show_percentage = false
		
		var pins_count = 0
		if pin_val >= 100:
			pins_count = 4
		elif pin_val >= 75:
			pins_count = 3
		elif pin_val >= 50:
			pins_count = 2
		elif pin_val >= 25:
			pins_count = 1
		else:
			pins_count = 0
			
		# Show only pins count
		pin_label.text = "Pins: %d" % pins_count
		
		if pins_count == 1:
			pin_label.add_theme_color_override("font_color", Color(0.95, 0.57, 0.1))
		elif pins_count == 0:
			pin_label.add_theme_color_override("font_color", Color(0.85, 0.25, 0.25))
		else:
			pin_label.remove_theme_color_override("font_color")
			
		var repair: Dictionary = hud.get("repair", {})
		var depleted := int(hud.get("queue", {}).get("loaded", 0)) == 0
		var is_rebuilding := bool(repair.get("active", false))
		if is_rebuilding:
			repair_status_label.text = "REPAIRING..."
			repair_status_label.add_theme_color_override("font_color", Color(0.85, 0.25, 0.25))
		elif depleted:
			repair_status_label.text = "OVERHEATED!"
			repair_status_label.add_theme_color_override("font_color", Color(0.85, 0.25, 0.25))
		else:
			repair_status_label.text = "Normal"
			repair_status_label.add_theme_color_override("font_color", Color(0.34, 0.68, 0.42))

	# Manage overlays
	var failed := bool(scene.get("failed", false))
	if phase == "run_complete" and failed:
		repair_overlay.visible = true
		var warning_lbl = repair_overlay.get_node("Center/WarningBox/WarningLabel") as Label
		var desc_lbl = repair_overlay.get_node("Center/WarningBox/DescriptionLabel") as Label
		warning_lbl.text = "⚠️ EXPEDITION FAILED ⚠️"
		desc_lbl.text = "Time limit exceeded or core destroyed.\nClick here to restart."
		return
	elif is_victory_overlay:
		repair_overlay.visible = true
		var warning_lbl = repair_overlay.get_node("Center/WarningBox/WarningLabel") as Label
		var desc_lbl = repair_overlay.get_node("Center/WarningBox/DescriptionLabel") as Label
		warning_lbl.text = "🎉 LEVIATHAN CRUST CLEARED 🎉"
		desc_lbl.text = "Mining operation successful.\nClick here to claim rewards."
		return
	elif phase == "combat":
		var repair: Dictionary = hud.get("repair", {})
		var depleted := int(hud.get("queue", {}).get("loaded", 0)) == 0
		var is_rebuilding := bool(repair.get("active", false))
		var feedback: Dictionary = scene.get("feedback", {})
		var status = str(feedback.get("status", ""))
		repair_overlay.visible = depleted or is_rebuilding or status == "empty_queue" or status == "repair_blocked"
		if repair_overlay.visible:
			var warning_lbl = repair_overlay.get_node("Center/WarningBox/WarningLabel") as Label
			var desc_lbl = repair_overlay.get_node("Center/WarningBox/DescriptionLabel") as Label
			warning_lbl.text = "⚠️ MINING DRILL CRITICAL FAILURE ⚠️"
			if is_rebuilding:
				var secs = ceil(float(repair.get("progress", 0)) / 20.0)
				desc_lbl.text = "Core overheated. Energy queue depleted.\nRebuilding drill core automatically (%ds remaining)..." % secs
			else:
				desc_lbl.text = "Core overheated. Energy queue depleted.\nRebuilding drill core automatically..."
	else:
		repair_overlay.visible = false
