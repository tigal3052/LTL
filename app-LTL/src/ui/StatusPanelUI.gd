# 怨꾩빟:
# - 梨낆엫: combat/reward overlay ?곹깭 ?⑤꼸??HP/Shield, queue, pin/repair ?곹깭? overlay 臾멸뎄瑜??뚮뜑留곹븳??
# - ?낅젰: scene snapshot Dictionary? repair overlay node.
# - 異쒕젰: ?곹깭 UI node 媛깆떊.
# - 湲덉?: gameplay state 蹂寃? controller 吏곸젒 ?묎렐, phase ?꾪솚.
#
# ?ㅽ뻾: define the StatusPanel UI controller.
# 계약: StatusPanelUI renders combat/reward status labels and overlay messages from scene snapshots.
# 실행: define the StatusPanel UI controller.
extends PanelContainer

const TextCatalogScript = preload("res://src/ui/TextCatalog.gd")

@onready var extractor_label: Label = $Margin/StatusBox/NodeRow/ExtractorLabel
@onready var visual_queue_box: HBoxContainer = $Margin/StatusBox/QueueRow/VisualQueueBox
@onready var extractor_visual: Panel = $Margin/StatusBox/NodeRow/ExtractorVisual
@onready var health_bar: ProgressBar = $Margin/StatusBox/HPBox/HealthBar
@onready var shield_bar: ProgressBar = $Margin/StatusBox/ShieldBox/ShieldBar
@onready var pin_progress_bar: ProgressBar = $Margin/StatusBox/TimerRow/PinProgressBar
@onready var pin_label: Label = $Margin/StatusBox/TimerRow/PinLabel
@onready var repair_status_label: Label = $Margin/StatusBox/DrillStatusRow/RepairStatusLabel

# ?ㅽ뻾: update target HP and Shield bars with exact values and percentages.
func render_target_bars(scene: Dictionary) -> void:
	if not _is_status_scene(scene):
		return
	var target: Dictionary = scene.get("targetPanel", {})
	_apply_value_bar(health_bar, float(target.get("health", 0.0)), float(target.get("maxHealth", 100.0)))
	_apply_value_bar(shield_bar, float(target.get("shield", 0.0)), float(target.get("maxShield", 2.4)))

# ?ㅽ뻾: update extractor node label.
func render_extractor_label(scene: Dictionary) -> void:
	var last_node := str(scene.get("lastNodeLabel", ""))
	extractor_label.text = TextCatalogScript.t("status.node", [TextCatalogScript.display_name(last_node) if not last_node.is_empty() else "-"])

# ?ㅽ뻾: render glowing circle gems inside the queue panel.
func render_visual_queue(scene: Dictionary) -> void:
	for child in visual_queue_box.get_children():
		child.queue_free()
	if not _is_status_scene(scene):
		return
	var queue: Dictionary = scene.get("hud", {}).get("queue", {})
	var items: Array = queue.get("items", [])
	for i in range(int(queue.get("capacity", 8))):
		visual_queue_box.add_child(_queue_gem(str(items[i]) if i < items.size() else "", i == 0))

# ?ㅽ뻾: render the repair critical overlay and pin/repair status.
func render_repair_overlay(scene: Dictionary, repair_overlay: PanelContainer) -> void:
	if repair_overlay == null:
		return
	var phase := str(scene.get("phase", ""))
	var hud: Dictionary = scene.get("hud", {})
	var victory := phase == "reward_loot" and bool(scene.get("show_victory_overlay", false)) and not bool(scene.get("is_reveal_vfx_running", false))
	if (phase == "combat" or victory) and not hud.is_empty():
		_render_pin_and_repair_status(hud)
	if phase == "run_complete" and bool(scene.get("failed", false)):
		_show_overlay(repair_overlay, TextCatalogScript.t("overlay.failed.title"), TextCatalogScript.t("overlay.failed.desc"))
	elif victory:
		_show_overlay(repair_overlay, TextCatalogScript.t("overlay.victory.title"), TextCatalogScript.t("overlay.victory.desc"))
	elif phase == "combat":
		_render_combat_overlay(scene, repair_overlay)
	else:
		repair_overlay.visible = false

# ?ㅽ뻾: test whether status widgets should render for this scene.
func _is_status_scene(scene: Dictionary) -> bool:
	var phase := str(scene.get("phase", ""))
	return phase == "combat" or (phase == "reward_loot" and bool(scene.get("show_victory_overlay", false)))

# ?ㅽ뻾: create or update the value label inside a progress bar.
func _apply_value_bar(bar: ProgressBar, value: float, max_value: float) -> void:
	bar.max_value = max_value
	bar.value = value
	bar.show_percentage = false
	var label := bar.get_node_or_null("ValLabel") as Label
	if label == null:
		label = Label.new()
		label.name = "ValLabel"
		label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 10)
		label.add_theme_color_override("font_color", Color.WHITE)
		bar.add_child(label)
	var pct := (value / max_value) * 100.0 if max_value > 0.0 else 0.0
	label.text = "%.1f / %.1f (%.0f%%)" % [value, max_value, pct]

# ?ㅽ뻾: build one queue gem control.
func _queue_gem(color_name: String, is_front: bool) -> Panel:
	var gem := Panel.new()
	var style := StyleBoxFlat.new()
	var filled := not color_name.is_empty()
	style.bg_color = _energy_color(color_name) if filled else Color(0.1, 0.12, 0.15)
	style.corner_radius_top_left = 12 if is_front else 10
	style.corner_radius_top_right = style.corner_radius_top_left
	style.corner_radius_bottom_left = style.corner_radius_top_left
	style.corner_radius_bottom_right = style.corner_radius_top_left
	if is_front or not filled:
		style.border_width_left = 2 if is_front else 1
		style.border_width_top = style.border_width_left
		style.border_width_right = style.border_width_left
		style.border_width_bottom = style.border_width_left
		style.border_color = Color.WHITE if is_front else Color(0.2, 0.24, 0.3, 0.6)
	gem.custom_minimum_size = Vector2(24, 24) if is_front and filled else (Vector2(18, 18) if filled else Vector2(16, 16))
	gem.add_theme_stylebox_override("panel", style)
	return gem

# ?ㅽ뻾: map energy names to UI colors.
func _energy_color(color_name: String) -> Color:
	match color_name:
		"red": return Color(0.9, 0.25, 0.25)
		"blue": return Color(0.25, 0.5, 0.9)
		"green": return Color(0.25, 0.75, 0.35)
		"purple": return Color(0.65, 0.25, 0.85)
	return Color(0.8, 0.8, 0.8)

# ?ㅽ뻾: update pin count and repair status labels.
func _render_pin_and_repair_status(hud: Dictionary) -> void:
	var pin_val := float(hud.get("pin", {}).get("progress", 0))
	pin_progress_bar.max_value = 100.0
	pin_progress_bar.value = pin_val
	pin_progress_bar.show_percentage = false
	var pins_count := 4 if pin_val >= 100 else (3 if pin_val >= 75 else (2 if pin_val >= 50 else (1 if pin_val >= 25 else 0)))
	pin_label.text = TextCatalogScript.t("status.pin", [pins_count])
	if pins_count <= 1:
		pin_label.add_theme_color_override("font_color", Color(0.95, 0.57, 0.1) if pins_count == 1 else Color(0.85, 0.25, 0.25))
	else:
		pin_label.remove_theme_color_override("font_color")
	var repair: Dictionary = hud.get("repair", {})
	var depleted := int(hud.get("queue", {}).get("loaded", 0)) == 0
	var rebuilding := bool(repair.get("active", false))
	var status_text := TextCatalogScript.t("status.repairing") if rebuilding else (TextCatalogScript.t("status.overheated") if depleted else TextCatalogScript.t("status.normal"))
	var terrain_text := _terrain_debuff_status(hud.get("terrainDebuffs", []))
	repair_status_label.text = status_text if terrain_text.is_empty() else "%s | %s" % [status_text, terrain_text]
	repair_status_label.add_theme_color_override("font_color", Color(0.85, 0.25, 0.25) if rebuilding or depleted else (Color(0.72, 0.42, 0.95) if not terrain_text.is_empty() else Color(0.34, 0.68, 0.42)))

# 실행: summarize global terrain debuffs in the drill/node status row.
func _terrain_debuff_status(value: Variant) -> String:
	if not value is Array:
		return ""
	var weakened_stacks := 0
	for debuff in value:
		if debuff is Dictionary and str(debuff.get("effect", "")) == "weakened_terrain":
			weakened_stacks += maxi(1, int(debuff.get("stacks", 1)))
	return TextCatalogScript.t("status.terrain_weakened", [weakened_stacks]) if weakened_stacks > 0 else ""

# ?ㅽ뻾: render the combat repair overlay state.
func _render_combat_overlay(scene: Dictionary, repair_overlay: PanelContainer) -> void:
	var hud: Dictionary = scene.get("hud", {})
	var repair: Dictionary = hud.get("repair", {})
	var rebuilding := bool(repair.get("active", false))
	var depleted := int(hud.get("queue", {}).get("loaded", 0)) == 0
	var status := str(scene.get("feedback", {}).get("status", ""))
	repair_overlay.visible = depleted or rebuilding or status in ["empty_queue", "repair_blocked"]
	if repair_overlay.visible:
		var secs := int(ceil(float(repair.get("progress", 0)) / 20.0))
		var desc := TextCatalogScript.t("overlay.overheat.rebuilding", [secs]) if rebuilding else TextCatalogScript.t("overlay.overheat.desc")
		_show_overlay(repair_overlay, TextCatalogScript.t("overlay.overheat.title"), desc)

# ?ㅽ뻾: set overlay text and visibility.
func _show_overlay(overlay: PanelContainer, title: String, description: String) -> void:
	overlay.visible = true
	(overlay.get_node("Center/WarningBox/WarningLabel") as Label).text = title
	(overlay.get_node("Center/WarningBox/DescriptionLabel") as Label).text = description
