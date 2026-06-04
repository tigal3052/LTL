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
const RewardCeremonyPolicyScript = preload("res://src/ui/presenters/RewardCeremonyPolicy.gd")
const ENERGY_QUEUE_COLUMNS := 8

@onready var extractor_label: Label = $Margin/StatusBox/NodeRow/ExtractorLabel
@onready var visual_queue_box: GridContainer = $Margin/StatusBox/QueueRow/VisualQueueBox
@onready var extractor_visual: Panel = $Margin/StatusBox/NodeRow/ExtractorVisual
@onready var health_bar: ProgressBar = $Margin/StatusBox/HPBox/HealthBar
@onready var shield_bar: ProgressBar = $Margin/StatusBox/ShieldBox/ShieldBar
@onready var pin_progress_bar: ProgressBar = $Margin/StatusBox/TimerRow/PinProgressBar
@onready var pin_label: Label = $Margin/StatusBox/TimerRow/PinLabel
@onready var repair_status_label: Label = $Margin/StatusBox/DrillStatusRow/RepairStatusLabel
@onready var status_footer_spacer: Control = $Margin/StatusBox/StatusFooterSpacer
@onready var purple_status_row: HBoxContainer = $Margin/StatusBox/StatusFooterSpacer/PurpleStatusRow
@onready var purple_status_label: Label = $Margin/StatusBox/StatusFooterSpacer/PurpleStatusRow/PurpleStatusLabel
@onready var purple_status_value: Label = $Margin/StatusBox/StatusFooterSpacer/PurpleStatusRow/PurpleStatusValue
@onready var combat_timer_label: Label = $Margin/StatusBox/CombatTimerFooterMargin/CombatTimerFooter/CombatTimerLabel

func _ready() -> void:
	_apply_shell_theme()
	_configure_visual_queue_grid()
	_configure_purple_status_overlay()
	render_combat_timer("00:00", false)

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
	_configure_visual_queue_grid()
	_clear_visual_queue_box()
	if not _is_status_scene(scene):
		return
	var queue: Dictionary = scene.get("hud", {}).get("queue", {})
	var items: Array = queue.get("items", [])
	for i in range(int(queue.get("capacity", 16))):
		var color_name := ""
		if i < items.size():
			color_name = str(items[i].get("color", "")) if items[i] is Dictionary else str(items[i])
		visual_queue_box.add_child(_queue_gem(color_name, i == 0))

# 실행: render the relocated combat countdown in the status footer.
func render_combat_timer(timer_text: String, active: bool) -> void:
	combat_timer_label.visible = active
	combat_timer_label.text = timer_text if active else "00:00"

# ?ㅽ뻾: render the repair critical overlay and pin/repair status.
func render_repair_overlay(scene: Dictionary, repair_overlay: PanelContainer) -> void:
	if repair_overlay == null:
		return
	var phase := str(scene.get("phase", ""))
	var hud: Dictionary = scene.get("hud", {})
	var ceremony_active := RewardCeremonyPolicyScript.is_active_scene(scene)
	var victory := phase == "reward_loot" and bool(scene.get("show_victory_overlay", false)) and not bool(scene.get("is_reveal_vfx_running", false))
	if (phase == "combat" or ceremony_active or victory) and not hud.is_empty():
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
	return should_render_status_scene(scene)

# 실행: keep combat target widgets live during active reward ceremony beats so the last HP/time snapshot does not freeze.
static func should_render_status_scene(scene: Dictionary) -> bool:
	var phase := str(scene.get("phase", ""))
	return phase == "combat" or RewardCeremonyPolicyScript.is_active_scene(scene) or (phase == "reward_loot" and bool(scene.get("show_victory_overlay", false)))

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

func _configure_visual_queue_grid() -> void:
	if visual_queue_box == null:
		return
	visual_queue_box.columns = ENERGY_QUEUE_COLUMNS
	visual_queue_box.add_theme_constant_override("h_separation", 6)
	visual_queue_box.add_theme_constant_override("v_separation", 4)

# 실행: detach stale queue gems immediately so repeated same-frame rerenders cannot inflate the status column layout.
func _clear_visual_queue_box() -> void:
	for child in visual_queue_box.get_children():
		visual_queue_box.remove_child(child)
		child.queue_free()

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
	repair_status_label.text = status_text
	repair_status_label.add_theme_color_override("font_color", Color(0.85, 0.25, 0.25) if rebuilding or depleted else Color(0.34, 0.68, 0.42))
	_render_purple_status(hud)

# 실행: summarize global terrain debuffs in the drill/node status row.
func _terrain_debuff_status(value: Variant) -> String:
	if not value is Array:
		return ""
	var weakened_stacks := 0
	for debuff in value:
		if debuff is Dictionary and str(debuff.get("effect", "")) == "weakened_terrain":
			weakened_stacks += maxi(1, int(debuff.get("stacks", 1)))
	return TextCatalogScript.t("status.terrain_weakened", [weakened_stacks]) if weakened_stacks > 0 else ""

func _render_purple_status(hud: Dictionary) -> void:
	var pressure: Dictionary = hud.get("purplePressure", {})
	var stack_count := int(pressure.get("stackCount", 0))
	var buff_count := int(pressure.get("buffCount", 0))
	var parts: Array[String] = []
	if stack_count > 0:
		parts.append(_purple_weakened_text(stack_count))
	if buff_count > 0:
		parts.append(_purple_fortified_text(buff_count))
	purple_status_row.visible = not parts.is_empty()
	if parts.is_empty():
		purple_status_value.text = "-"
		_layout_purple_status_overlay()
		return
	purple_status_value.text = " | ".join(parts)
	purple_status_value.add_theme_color_override("font_color", Color(0.72, 0.42, 0.95))
	_layout_purple_status_overlay()

func _purple_weakened_text(stack_count: int) -> String:
	if TextCatalogScript.locale() == "ko":
		return "지형 약화 x%d" % stack_count
	return "Terrain weakened x%d" % stack_count

func _purple_fortified_text(buff_count: int) -> String:
	if TextCatalogScript.locale() == "ko":
		return "정상 버프 +%d" % buff_count
	return "Stability buff +%d" % buff_count

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

func _configure_purple_status_overlay() -> void:
	if status_footer_spacer == null or purple_status_row == null:
		return
	status_footer_spacer.clip_contents = true
	purple_status_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_layout_purple_status_overlay()
	if not status_footer_spacer.resized.is_connected(_layout_purple_status_overlay):
		status_footer_spacer.resized.connect(_layout_purple_status_overlay)

func _layout_purple_status_overlay() -> void:
	if status_footer_spacer == null or purple_status_row == null:
		return
	var row_height := purple_status_row.get_combined_minimum_size().y
	purple_status_row.position = Vector2.ZERO
	purple_status_row.size = Vector2(maxf(0.0, status_footer_spacer.size.x), row_height)

func _apply_shell_theme() -> void:
	var panel := StyleBoxFlat.new()
	panel.bg_color = Color(0.06, 0.08, 0.11, 0.95)
	panel.border_color = Color(0.19, 0.29, 0.41, 1.0)
	panel.border_width_left = 1
	panel.border_width_top = 1
	panel.border_width_right = 1
	panel.border_width_bottom = 1
	panel.corner_radius_top_left = 12
	panel.corner_radius_top_right = 12
	panel.corner_radius_bottom_left = 12
	panel.corner_radius_bottom_right = 12
	panel.shadow_size = 8
	panel.shadow_color = Color(0.0, 0.0, 0.0, 0.20)
	add_theme_stylebox_override("panel", panel)
	_style_metric_bar(health_bar, Color(0.82, 0.24, 0.24), Color(0.17, 0.08, 0.08))
	_style_metric_bar(shield_bar, Color(0.30, 0.56, 0.96), Color(0.08, 0.11, 0.18))
	_style_metric_bar(pin_progress_bar, Color(0.91, 0.66, 0.18), Color(0.18, 0.13, 0.07))
	extractor_label.add_theme_color_override("font_color", Color(0.82, 0.88, 0.95))
	pin_label.add_theme_color_override("font_color", Color(0.92, 0.95, 0.98))
	repair_status_label.add_theme_color_override("font_color", Color(0.74, 0.82, 0.88))
	purple_status_label.add_theme_color_override("font_color", Color(0.78, 0.80, 0.88))
	purple_status_value.add_theme_color_override("font_color", Color(0.72, 0.42, 0.95))
	combat_timer_label.add_theme_color_override("font_color", Color(0.95, 0.75, 0.25))
	var extractor_style := StyleBoxFlat.new()
	extractor_style.bg_color = Color(0.10, 0.14, 0.18, 1.0)
	extractor_style.border_color = Color(0.35, 0.46, 0.58, 1.0)
	extractor_style.border_width_left = 1
	extractor_style.border_width_top = 1
	extractor_style.border_width_right = 1
	extractor_style.border_width_bottom = 1
	extractor_style.corner_radius_top_left = 10
	extractor_style.corner_radius_top_right = 10
	extractor_style.corner_radius_bottom_left = 10
	extractor_style.corner_radius_bottom_right = 10
	extractor_visual.add_theme_stylebox_override("panel", extractor_style)

func _style_metric_bar(bar: ProgressBar, fill_color: Color, background_color: Color) -> void:
	var fill := StyleBoxFlat.new()
	fill.bg_color = fill_color
	fill.corner_radius_top_left = 8
	fill.corner_radius_top_right = 8
	fill.corner_radius_bottom_left = 8
	fill.corner_radius_bottom_right = 8
	var bg := StyleBoxFlat.new()
	bg.bg_color = background_color
	bg.corner_radius_top_left = 8
	bg.corner_radius_top_right = 8
	bg.corner_radius_bottom_left = 8
	bg.corner_radius_bottom_right = 8
	bg.content_margin_left = 2
	bg.content_margin_top = 2
	bg.content_margin_right = 2
	bg.content_margin_bottom = 2
	bar.add_theme_stylebox_override("fill", fill)
	bar.add_theme_stylebox_override("background", bg)
