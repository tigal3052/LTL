# 계약:
# - 책임: UI 요소에 대한 직접적인 참조를 관리하고 사용자 입력 이벤트를 신호(Signals)로 변환해 방출하며, 수동 렌더링 호출을 실행한다. 임시 보완 상점 패널과 중앙 거대 디지털 타이머 및 모서리 맥동 비네트 효과(VFX)를 동적으로 빌드한다.
# - 입력: MainController(오케스트레이터)의 렌더링 및 연출 호출 명령, 각 버튼/슬롯/셀의 입력 이벤트.
# - 출력: 사용자 액션에 대한 시그널 방출(reset_pressed, start_combat_pressed, hold_fire_pressed, shop_open_pressed, buy_passive, etc.)
# - 금지: 비즈니스 시뮬레이터 직접 참조, 도메인 상태 변경.

# 실행: define the main-scene UI view as a PanelContainer script and declare signals.
extends PanelContainer
signal reset_pressed
signal start_combat_pressed
signal hold_fire_pressed
signal repair_pressed
signal claim_rewards_pressed
signal settings_open_pressed
signal confirm_proceed_pressed
signal confirm_cancel_pressed
signal node_meta_clicked(meta: Variant)
signal reward_meta_clicked(meta: Variant)
signal discard_zone_input(event: InputEvent)
signal repair_overlay_input(event: InputEvent)
signal backpack_slot_clicked(coord: Vector2)
signal cell_hovered(cell_id: String, color_name: String)
signal cell_clicked(cell_id: String, color_name: String)
signal cell_pressed(cell_id: String, color: String)
signal cell_released
signal key_pressed(keycode: int)

# New Shop signals
signal shop_open_pressed
signal buy_passive(passive_id: String, cost: int)

# 실행: cache UI node references.
@onready var phase_label: Label = $RootMargin/AppShell/Header/Margin/PhaseRow/PhaseLabel
@onready var stage_label: Label = $RootMargin/AppShell/Header/Margin/PhaseRow/StageLabel
@onready var node_select_text: RichTextLabel = $RootMargin/AppShell/ActivePhaseContainer/NodeSelectPanel/Margin/NodeSelectBox/NodeSelectText
@onready var reward_text: RichTextLabel = $RootMargin/AppShell/ActivePhaseContainer/RewardPanel/Margin/RewardBox/RewardRow/RewardText
@onready var reset_button: Button = $RootMargin/AppShell/ActionBar/ResetButton
@onready var start_button: Button = $RootMargin/AppShell/ActionBar/StartButton
@onready var hold_fire_button: Button = $RootMargin/AppShell/ActionBar/HoldFireButton
@onready var repair_button: Button = $RootMargin/AppShell/ActionBar/RepairButton
@onready var claim_rewards_button: Button = $RootMargin/AppShell/ActionBar/ClaimRewardsButton
@onready var settings_open_button: Button = $RootMargin/AppShell/Header/Margin/PhaseRow/SettingsOpenButton
@onready var repair_overlay: PanelContainer = $RepairOverlay
@onready var confirm_overlay: PanelContainer = $ConfirmOverlay
@onready var confirm_proceed_button: Button = $ConfirmOverlay/Center/ConfirmBox/ButtonsRow/ConfirmButton
@onready var confirm_cancel_button: Button = $ConfirmOverlay/Center/ConfirmBox/ButtonsRow/CancelButton
@onready var settings_panel = $SettingsPanel
@onready var backpack_ui = $RootMargin/AppShell/TopContent/BackpackContainer/BackpackEnginePanel
@onready var battlefield_ui = $RootMargin/AppShell/ActivePhaseContainer/BattlefieldPanel
@onready var status_panel = $RootMargin/AppShell/TopContent/LeftColumn/StatusPanel
@onready var log_console = $RootMargin/AppShell/TopContent/RightSidebar/Margin/InspectorBox/InspectorText
@onready var vfx_manager = $VFXManager
@onready var discard_zone: PanelContainer = $RootMargin/AppShell/ActivePhaseContainer/RewardPanel/Margin/RewardBox/RewardRow/DiscardZone
@onready var discard_label: Label = $RootMargin/AppShell/ActivePhaseContainer/RewardPanel/Margin/RewardBox/RewardRow/DiscardZone/DiscardLabel

# Shop UI Dynamic nodes
var shop_open_button: Button
var shop_panel: PanelContainer
var shop_gold_label: Label
var shop_xp_label: Label
var shop_buttons: Dictionary = {}
var shop_labels: Dictionary = {}
var current_shop_state: Dictionary = {}

# Giant Timer UI Dynamic nodes
var giant_timer_panel: PanelContainer
var giant_timer_label: Label
var vignette_overlay: Panel
var pulse_time: float = 0.0
var heartbeat_player: AudioStreamPlayer
var _heartbeat_volume: float = 75.0
var heartbeat_timer: float = 1.0

# 실행: connect raw UI signals to custom view signals for orchestrator consumption.
func _ready() -> void:
	reset_button.pressed.connect(func(): reset_pressed.emit())
	start_button.pressed.connect(func(): start_combat_pressed.emit())
	hold_fire_button.pressed.connect(func(): hold_fire_pressed.emit())
	repair_button.pressed.connect(func(): repair_pressed.emit())
	repair_button.visible = false # R button disabled/hidden since repair is automatic now
	claim_rewards_button.pressed.connect(func(): claim_rewards_pressed.emit())
	settings_open_button.pressed.connect(func(): settings_open_pressed.emit())
	confirm_proceed_button.pressed.connect(func(): confirm_proceed_pressed.emit())
	confirm_cancel_button.pressed.connect(func(): confirm_cancel_pressed.emit())
	node_select_text.meta_clicked.connect(func(meta): node_meta_clicked.emit(meta))
	reward_text.meta_clicked.connect(func(meta): reward_meta_clicked.emit(meta))
	discard_zone.gui_input.connect(func(ev): discard_zone_input.emit(ev))
	repair_overlay.gui_input.connect(func(ev):
		if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
			repair_overlay_input.emit(ev)
	)
	backpack_ui.slot_clicked.connect(func(coord): backpack_slot_clicked.emit(coord))
	battlefield_ui.cell_hovered.connect(func(cid, col): cell_hovered.emit(cid, col))
	battlefield_ui.cell_clicked.connect(func(cid, col): cell_clicked.emit(cid, col))
	battlefield_ui.cell_pressed.connect(func(cid, col): cell_pressed.emit(cid, col))
	battlefield_ui.cell_released.connect(func(): cell_released.emit())
	
	# Instantiate Dynamic Shop Button
	shop_open_button = Button.new()
	shop_open_button.text = "🛒 Shop"
	shop_open_button.pressed.connect(func(): shop_open_pressed.emit())
	$RootMargin/AppShell/Header/Margin/PhaseRow.add_child(shop_open_button)
	$RootMargin/AppShell/Header/Margin/PhaseRow.move_child(shop_open_button, $RootMargin/AppShell/Header/Margin/PhaseRow.get_child_count() - 2)
	
	_create_shop_panel()
	
	# Instantiate Giant Timer & Vignette Overlay
	_create_giant_timer()
	_create_vignette_overlay()
	_create_heartbeat_player()
	
	# Connect volume slider signal
	settings_panel.volume_changed.connect(set_volume)

# 실행: forward unhandled keys to presenter.
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		key_pressed.emit(event.keycode)

# 실행: setup settings panel.
func setup_settings(shake_enabled: bool, is_fullscreen: bool) -> void:
	settings_panel.setup(shake_enabled, is_fullscreen)

# 실행: setup backpack slots.
func setup_backpack_slots() -> void:
	backpack_ui.setup_grid_slots()

# 실행: render backpack items using model data.
func render_backpack(inventory) -> void:
	backpack_ui.render_backpack_items(inventory)

# 실행: update ghost item display.
func update_backpack_ghost(artifact) -> void:
	backpack_ui.update_ghost_display(artifact)

# 실행: toggle settings visibility.
func toggle_settings() -> void:
	settings_panel.visible = not settings_panel.visible
	if settings_panel.visible:
		shop_panel.visible = false

# 실행: set settings visibility directly.
func set_settings_visible(val: bool) -> void:
	settings_panel.visible = val

# 실행: get settings visibility state.
func is_settings_visible() -> bool:
	return settings_panel.visible

# 실행: toggle calibration shop visibility.
func toggle_shop() -> void:
	shop_panel.visible = not shop_panel.visible
	if shop_panel.visible:
		settings_panel.visible = false

# 실행: set shop visibility directly.
func set_shop_visible(val: bool) -> void:
	shop_panel.visible = val

# 실행: get shop visibility state.
func is_shop_visible() -> bool:
	return shop_panel.visible

# 실행: render labels, manage view visibility and update status bars based on scene snapshot.
func render_scene(scene: Dictionary, show_victory_overlay: bool) -> void:
	var phase := str(scene.get("phase", "unknown"))
	phase_label.text = "Phase: %s" % phase.capitalize()
	stage_label.text = "Stage %d / %d" % [int(scene.get("stageIndex", 0)) + 1, maxi(1, int(scene.get("maxStages", 1)))]
	
	var is_reveal_vfx_running = bool(scene.get("is_reveal_vfx_running", false))
	var show_victory = show_victory_overlay or is_reveal_vfx_running
	
	$RootMargin/AppShell/ActivePhaseContainer/NodeSelectPanel.visible = (phase == "node_select")
	battlefield_ui.visible = (phase == "combat" or (phase == "reward_loot" and show_victory))
	$RootMargin/AppShell/ActivePhaseContainer/RewardPanel.visible = (phase == "reward_loot" and not show_victory)
	status_panel.visible = (phase == "combat" or (phase == "reward_loot" and show_victory))
	
	# Only allow shop button in node_select phase
	shop_open_button.visible = (phase == "node_select")
	if phase != "node_select":
		shop_panel.visible = false
		
	# Render Giant Timer Option A
	if phase == "combat":
		giant_timer_panel.visible = true
		var target: Dictionary = scene.get("targetPanel", {})
		var time_limit = float(target.get("timeLimitTicks", 2400.0))
		var elapsed = float(target.get("elapsedTicks", 0.0))
		var time_left = max(0.0, time_limit - elapsed)
		
		# Convert 20 ticks = 1 second
		var seconds_left = int(time_left / 20.0)
		var minutes = seconds_left / 60
		var seconds = seconds_left % 60
		giant_timer_label.text = "%02d:%02d" % [minutes, seconds]
		
		var ratio = time_left / time_limit if time_limit > 0.0 else 1.0
		vignette_overlay.visible = (ratio <= 0.20)
		
		# Update battlefield combat border progress
		battlefield_ui.update_combat_time(time_left, time_limit, true)
	else:
		giant_timer_panel.visible = false
		vignette_overlay.visible = false
		
		# Turn off combat border
		battlefield_ui.update_combat_time(0.0, 0.0, false)
		
	battlefield_ui.render_battlefield(scene, [])
	status_panel.render_target_bars(scene)
	status_panel.render_extractor_label(scene)
	status_panel.render_visual_queue(scene)
	status_panel.render_repair_overlay(scene, repair_overlay)

# 실행: set battlefield disabled tiles.
func update_battlefield_disabled(scene: Dictionary, disabled_tiles: Array) -> void:
	battlefield_ui.render_battlefield(scene, disabled_tiles)

# 실행: update action buttons enabled state.
func update_action_state(scene: Dictionary, show_victory_overlay: bool) -> void:
	var phase := str(scene.get("phase", "unknown"))
	start_button.disabled = not (phase == "node_select" and scene.get("nodeSelect", {}).get("candidates", []).size() > 0)
	hold_fire_button.disabled = not (phase == "combat" and bool(scene.get("hud", {}).get("aim", {}).get("canFire", false)))
	repair_button.disabled = not (phase == "combat" and bool(scene.get("hud", {}).get("repair", {}).get("available", false)))
	claim_rewards_button.disabled = (phase != "reward_loot" or show_victory_overlay)

# 실행: show or hide confirm overlay.
func set_confirm_overlay_visible(val: bool) -> void:
	confirm_overlay.visible = val

# 실행: append a message to the system log console.
func add_log(message: String) -> void:
	log_console.add_log(message)

# 실행: update discard zone label and modulate color.
func update_discard_zone(label_text: String, is_active: bool) -> void:
	discard_label.text = label_text
	discard_zone.self_modulate = Color.WHITE if is_active else Color(0.5, 0.5, 0.5, 0.5)

# 실행: get global hit position of a cell.
func get_cell_global_pos(cell_id: String) -> Vector2:
	var hit_pos = global_position + size / 2
	for child in battlefield_ui.battlefield_grid.get_children():
		if child is CellView and child.cell_id == cell_id:
			hit_pos = child.global_position + child.size / 2
			break
	return hit_pos

# 실행: get global start position of the extractor.
func get_extractor_global_pos() -> Vector2:
	return status_panel.extractor_visual.global_position + status_panel.extractor_visual.size / 2

# 실행: trigger resonance beam effect.
func trigger_resonance_beam(start_pos: Vector2, hit_pos: Vector2, color: String) -> void:
	vfx_manager.draw_resonance_beam(start_pos, hit_pos, color)

# 실행: trigger hit particle spawn.
func trigger_hit_particles(hit_pos: Vector2, status: String, color: String) -> void:
	vfx_manager.spawn_hit_particles(hit_pos, status, color)

# 실행: trigger screenshake VFX.
func trigger_screenshake(duration: float, magnitude: float) -> void:
	vfx_manager.trigger_screenshake(duration, magnitude, self)

# 실행: update rich text labels directly.
func set_node_select_text(val: String) -> void:
	node_select_text.text = val

# 실행: update reward text label.
func set_reward_text(val: String) -> void:
	reward_text.text = val

# 실행: dynamically construct the calibration shop panel.
func _create_shop_panel() -> void:
	shop_panel = PanelContainer.new()
	shop_panel.visible = false
	add_child(shop_panel)
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.08, 0.10, 0.96)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.24, 0.35, 0.50, 1.0)
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_right = 12
	style.corner_radius_bottom_left = 12
	shop_panel.add_theme_stylebox_override("panel", style)
	
	var center = CenterContainer.new()
	shop_panel.add_child(center)
	
	var box = VBoxContainer.new()
	box.custom_minimum_size = Vector2(420, 280)
	box.add_theme_constant_override("separation", 14)
	center.add_child(box)
	
	var title = Label.new()
	title.text = "CALIBRATION SHOP (PLAYTEST)"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", Color(0.3, 0.6, 0.95))
	box.add_child(title)
	
	var cur_row = HBoxContainer.new()
	cur_row.add_theme_constant_override("separation", 30)
	cur_row.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_child(cur_row)
	
	shop_gold_label = Label.new()
	shop_gold_label.text = "Gold: 0g"
	shop_gold_label.add_theme_color_override("font_color", Color(0.95, 0.75, 0.25))
	cur_row.add_child(shop_gold_label)
	
	shop_xp_label = Label.new()
	shop_xp_label.text = "XP: 0"
	shop_xp_label.add_theme_color_override("font_color", Color(0.3, 0.85, 0.4))
	cur_row.add_child(shop_xp_label)
	
	box.add_child(HSeparator.new())
	
	var passives_box = VBoxContainer.new()
	passives_box.add_theme_constant_override("separation", 8)
	box.add_child(passives_box)
	
	var passives_info = [
		{"id": "starting_gold_boost", "name": "Starting Gold Boost", "desc": "+10 starting gold. Cost: %d gold", "base_cost": 50, "step": 50},
		{"id": "cooldown_reduction", "name": "Drill Cooldown Reduction", "desc": "-5%% drill cooldown. Cost: %d gold", "base_cost": 75, "step": 75},
		{"id": "aim_damage_boost", "name": "Aim Damage Boost", "desc": "+1 flat damage. Cost: %d gold", "base_cost": 100, "step": 100}
	]
	
	for p in passives_info:
		var row = HBoxContainer.new()
		passives_box.add_child(row)
		
		var label_vbox = VBoxContainer.new()
		label_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(label_vbox)
		
		var name_lbl = Label.new()
		name_lbl.text = p["name"]
		name_lbl.add_theme_font_size_override("font_size", 12)
		name_lbl.add_theme_color_override("font_color", Color(0.9, 0.9, 0.95))
		label_vbox.add_child(name_lbl)
		
		var desc_lbl = Label.new()
		desc_lbl.text = p["desc"] % p["base_cost"]
		desc_lbl.add_theme_font_size_override("font_size", 10)
		desc_lbl.add_theme_color_override("font_color", Color(0.65, 0.68, 0.72))
		label_vbox.add_child(desc_lbl)
		shop_labels[p["id"]] = desc_lbl
		
		var btn = Button.new()
		btn.text = "Buy"
		btn.custom_minimum_size = Vector2(100, 24)
		row.add_child(btn)
		shop_buttons[p["id"]] = btn
		
		var pid = p["id"]
		var base_cost = p["base_cost"]
		var step = p["step"]
		btn.pressed.connect(func():
			var current_lvl = 0
			if current_shop_state.has("purchasedPassives") and current_shop_state["purchasedPassives"].has(pid):
				current_lvl = int(current_shop_state["purchasedPassives"][pid])
			var cost = base_cost + current_lvl * step
			buy_passive.emit(pid, cost)
		)
		
	box.add_child(HSeparator.new())
	
	var close_btn = Button.new()
	close_btn.text = "Close"
	close_btn.pressed.connect(func(): shop_panel.visible = false)
	box.add_child(close_btn)

# 실행: update shop label and buttons.
func render_shop(growth_state: Dictionary) -> void:
	current_shop_state = growth_state.duplicate(true)
	var gold_val = int(growth_state.get("gold", 0))
	var xp_val = int(growth_state.get("xp", 0))
	shop_gold_label.text = "Gold: %dg" % gold_val
	shop_xp_label.text = "XP: %d" % xp_val
	
	var passives = growth_state.get("purchasedPassives", {})
	
	var passives_info = {
		"starting_gold_boost": {"desc": "+10 starting gold. Cost: %d gold | Level: %d", "base_cost": 50, "step": 50},
		"cooldown_reduction": {"desc": "-5%% drill cooldown. Cost: %d gold | Level: %d", "base_cost": 75, "step": 75},
		"aim_damage_boost": {"desc": "+1 flat damage. Cost: %d gold | Level: %d", "base_cost": 100, "step": 100}
	}
	
	for pid in passives_info.keys():
		var info = passives_info[pid]
		var lvl = int(passives.get(pid, 0))
		var cost = info["base_cost"] + lvl * info["step"]
		
		if shop_labels.has(pid):
			shop_labels[pid].text = info["desc"] % [cost, lvl]
			
		if shop_buttons.has(pid):
			shop_buttons[pid].disabled = (gold_val < cost)
			shop_buttons[pid].text = "Buy (%dg)" % cost

# 실행: dynamically construct the central giant timer panel.
func _create_giant_timer() -> void:
	giant_timer_panel = PanelContainer.new()
	giant_timer_panel.visible = false
	giant_timer_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# Add directly to MainUI and set as top-level so it floats over the grid
	add_child(giant_timer_panel)
	giant_timer_panel.set_as_top_level(true)
	
	var t_style = StyleBoxFlat.new()
	t_style.bg_color = Color(0.04, 0.04, 0.06, 0.95)
	t_style.border_width_left = 2
	t_style.border_width_top = 2
	t_style.border_width_right = 2
	t_style.border_width_bottom = 2
	t_style.border_color = Color(0.24, 0.35, 0.50, 0.8)
	t_style.corner_radius_top_left = 8
	t_style.corner_radius_top_right = 8
	t_style.corner_radius_bottom_right = 8
	t_style.corner_radius_bottom_left = 8
	t_style.content_margin_left = 10
	t_style.content_margin_top = 2
	t_style.content_margin_right = 10
	t_style.content_margin_bottom = 2
	giant_timer_panel.add_theme_stylebox_override("panel", t_style)
	
	giant_timer_label = Label.new()
	giant_timer_label.text = "00:00"
	giant_timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	giant_timer_label.add_theme_font_size_override("font_size", 16)
	giant_timer_label.add_theme_color_override("font_color", Color(0.95, 0.75, 0.25))
	giant_timer_panel.add_child(giant_timer_label)

# 실행: dynamically construct full-screen vignette overlay panel.
func _create_vignette_overlay() -> void:
	vignette_overlay = Panel.new()
	vignette_overlay.name = "VignetteOverlay"
	vignette_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vignette_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vignette_overlay.visible = false
	add_child(vignette_overlay)
	move_child(vignette_overlay, 1) # place behind settings overlay but cover screen
	
	var v_style = StyleBoxFlat.new()
	v_style.draw_center = false
	v_style.border_width_left = 50
	v_style.border_width_top = 50
	v_style.border_width_right = 50
	v_style.border_width_bottom = 50
	v_style.border_color = Color(0.85, 0.1, 0.1, 0.0)
	v_style.corner_radius_top_left = 16
	v_style.corner_radius_top_right = 16
	v_style.corner_radius_bottom_right = 16
	v_style.corner_radius_bottom_left = 16
	v_style.shadow_color = Color(1.0, 0.0, 0.0, 0.0)
	v_style.shadow_size = 25
	vignette_overlay.add_theme_stylebox_override("panel", v_style)

# 실행: animate flashing timer label and pulsing red vignette overlay when time is critical.
func _process(delta: float) -> void:
	# Position the giant timer panel dynamically relative to the battlefield_ui
	if giant_timer_panel.visible:
		var bf_pos = battlefield_ui.global_position
		var bf_size = battlefield_ui.size
		var panel_size = giant_timer_panel.size
		if panel_size == Vector2.ZERO:
			panel_size = giant_timer_panel.get_combined_minimum_size()
		# Place at top-center of battlefield_ui, inset slightly down (e.g. 4px)
		giant_timer_panel.global_position = Vector2(
			bf_pos.x + (bf_size.x - panel_size.x) / 2.0,
			bf_pos.y + 4.0
		)

	if giant_timer_panel.visible and vignette_overlay.visible:
		pulse_time += delta
		var pulse = 0.35 + 0.65 * abs(sin(pulse_time * 6.5))
		
		# Animate border color alpha on local flat style box
		var v_style = vignette_overlay.get_theme_stylebox("panel") as StyleBoxFlat
		if v_style:
			v_style.border_color = Color(0.85, 0.1, 0.1, pulse * 0.35)
			v_style.shadow_color = Color(1.0, 0.0, 0.0, pulse * 0.2)
			
		# Animate timer font color flashing between red and gold
		var label_color = Color(0.9, 0.1, 0.1).lerp(Color(0.95, 0.75, 0.25), abs(sin(pulse_time * 3.5)))
		giant_timer_label.add_theme_color_override("font_color", label_color)
		
		# Animate timer border color pulsing red
		var t_style = giant_timer_panel.get_theme_stylebox("panel") as StyleBoxFlat
		if t_style:
			t_style.border_color = Color(0.9, 0.1, 0.1, 0.5 + 0.5 * pulse)
			
		# Scale pulse effect for the giant timer label
		# Scale around the label center
		giant_timer_label.pivot_offset = giant_timer_label.size / 2.0
		giant_timer_label.scale = Vector2.ONE * (1.0 + 0.08 * pulse)
		
		# Play heartbeat sound every 1.0 second
		heartbeat_timer += delta
		if heartbeat_timer >= 1.0:
			heartbeat_timer = 0.0
			if heartbeat_player and not heartbeat_player.playing:
				heartbeat_player.play()
	else:
		heartbeat_timer = 1.0
		if heartbeat_player and heartbeat_player.playing:
			heartbeat_player.stop()
			
		# Reset timer to default colors and scale if visible
		if giant_timer_panel.visible:
			var t_style = giant_timer_panel.get_theme_stylebox("panel") as StyleBoxFlat
			if t_style:
				t_style.border_color = Color(0.24, 0.35, 0.50, 0.8)
			giant_timer_label.add_theme_color_override("font_color", Color(0.95, 0.75, 0.25))
			giant_timer_label.scale = Vector2.ONE

# 실행: set the audio player volume.
func set_volume(val: float) -> void:
	_heartbeat_volume = val
	_update_heartbeat_volume()

# 실행: initialize the heartbeat audio player and synthesize a heartbeat wave.
func _create_heartbeat_player() -> void:
	heartbeat_player = AudioStreamPlayer.new()
	heartbeat_player.name = "HeartbeatPlayer"
	add_child(heartbeat_player)
	
	# Synthesize a double-pulse heartbeat (lub-dub) wave
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_8_BITS
	stream.mix_rate = 8000
	stream.stereo = false
	
	# 0.8 seconds duration at 8000Hz = 6400 samples
	var data = PackedByteArray()
	data.resize(6400)
	
	for i in range(6400):
		var t = float(i) / 8000.0
		var val = 0.0
		# First beat (lub): low frequency, 55Hz, decays quickly
		if t >= 0.0 and t < 0.15:
			var env = sin((t / 0.15) * PI)
			val = sin(t * 2.0 * PI * 55.0) * env * 90.0
		# Second beat (dub): slightly higher/quieter, 45Hz
		elif t >= 0.2 and t < 0.35:
			var env = sin(((t - 0.2) / 0.15) * PI)
			val = sin(t * 2.0 * PI * 45.0) * env * 70.0
			
		data[i] = int(clamp(val, -128.0, 127.0))
		
	stream.data = data
	heartbeat_player.stream = stream
	
	# Get initial volume from slider
	if settings_panel and settings_panel.volume_slider:
		_heartbeat_volume = settings_panel.volume_slider.value
	_update_heartbeat_volume()

# 실행: calculate and apply the decibel volume for the heartbeat stream.
func _update_heartbeat_volume() -> void:
	if heartbeat_player:
		if _heartbeat_volume <= 0.0:
			heartbeat_player.volume_db = -80.0
		else:
			# Convert volume percent (0-100) to decibels
			heartbeat_player.volume_db = linear_to_db(_heartbeat_volume / 100.0)
