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
const LTLThemeScript = preload("res://src/ui/theme/LTLTheme.gd")
const ENERGY_QUEUE_COLUMNS := 3

@onready var extractor_label: Label = $Margin/StatusBox/NodeRow/ExtractorLabel
@onready var status_box: VBoxContainer = $Margin/StatusBox
@onready var queue_row: HBoxContainer = $Margin/StatusBox/QueueRow
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
var queue_hint_label: Label

func _ready() -> void:
	_apply_shell_theme()
	_install_queue_hint_label()
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
	render_hud_projection({})
	if not _is_status_scene(scene):
		return
	var HudReadModelScript = load("res://src/ui/read_models/HudReadModel.gd")
	if HudReadModelScript != null:
		render_hud_projection(HudReadModelScript.project(scene))

func render_hud_projection(model: Dictionary) -> void:
	_configure_visual_queue_grid()
	_clear_visual_queue_box()
	if model.is_empty():
		if queue_hint_label != null:
			queue_hint_label.text = ""
		return
	var queue: Dictionary = model.get("queue", {})
	visual_queue_box.add_child(_queue_role_panel(_queue_role_label("now"), str(queue.get("nowColor", "")), true))
	visual_queue_box.add_child(_queue_role_panel(_queue_role_label("next"), str(queue.get("nextColor", "")), false))
	visual_queue_box.add_child(_queue_reserve_panel(int(queue.get("reserveCount", 0)), int(queue.get("loaded", 0))))
	if queue_hint_label != null:
		queue_hint_label.text = _queue_hint_text(queue, model.get("feedback", {}))
	_render_repair_projection(model.get("repair", {}))
	_render_status_footer(model)

# 실행: render the relocated combat countdown in the status footer.
func render_combat_timer(timer_text: String, active: bool) -> void:
	combat_timer_label.visible = active
	combat_timer_label.text = timer_text if active else "00:00"

# ?ㅽ뻾: render the repair critical overlay and pin/repair status.
func render_repair_overlay(scene: Dictionary, repair_overlay: PanelContainer, overlay_model: Dictionary = {}) -> void:
	if repair_overlay == null:
		return
	if overlay_model.is_empty():
		repair_overlay.visible = false
		return
	if not bool(overlay_model.get("visible", true)):
		repair_overlay.visible = false
		return
	var mode := str(overlay_model.get("mode", "hidden"))
	if mode == "hidden":
		repair_overlay.visible = false
		return
	_show_overlay(
		repair_overlay,
		str(overlay_model.get("title", "")),
		"%s\n\n%s" % [str(overlay_model.get("cause", "")), str(overlay_model.get("tip", ""))]
	)
	_apply_overlay_tone(repair_overlay, str(overlay_model.get("accent", "warning")))

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
func _configure_visual_queue_grid() -> void:
	if visual_queue_box == null:
		return
	visual_queue_box.columns = ENERGY_QUEUE_COLUMNS
	visual_queue_box.add_theme_constant_override("h_separation", 10)
	visual_queue_box.add_theme_constant_override("v_separation", 6)

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
	_render_repair_projection({
		"stage": "repair_required" if bool(hud.get("repair", {}).get("active", false)) else ("critical" if int(hud.get("queue", {}).get("loaded", 0)) == 0 else "stable"),
		"label": TextCatalogScript.t("status.repairing") if bool(hud.get("repair", {}).get("active", false)) else (TextCatalogScript.t("status.overheated") if int(hud.get("queue", {}).get("loaded", 0)) == 0 else TextCatalogScript.t("status.normal"))
	})
	_render_status_footer({"purplePressure": hud.get("purplePressure", {}).duplicate(true), "hazard": hud.get("hazard", {}).duplicate(true), "feedback": {}})

# 실행: summarize global terrain debuffs in the drill/node status row.
func _terrain_debuff_status(value: Variant) -> String:
	if not value is Array:
		return ""
	var weakened_stacks := 0
	for debuff in value:
		if debuff is Dictionary and str(debuff.get("effect", "")) == "weakened_terrain":
			weakened_stacks += maxi(1, int(debuff.get("stacks", 1)))
	return TextCatalogScript.t("status.terrain_weakened", [weakened_stacks]) if weakened_stacks > 0 else ""

func _render_purple_status(pressure: Dictionary) -> String:
	var stack_count := int(pressure.get("stackCount", 0))
	var buff_count := int(pressure.get("buffCount", 0))
	var parts: Array[String] = []
	if stack_count > 0:
		parts.append(_purple_weakened_text(stack_count))
	if buff_count > 0:
		parts.append(_purple_fortified_text(buff_count))
	return " | ".join(parts)

func _purple_weakened_text(stack_count: int) -> String:
	return TextCatalogScript.t("status.purple.weakened", [stack_count])

func _purple_fortified_text(buff_count: int) -> String:
	return TextCatalogScript.t("status.purple.buff", [buff_count])

# ?ㅽ뻾: render the combat repair overlay state.
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
	add_theme_stylebox_override("panel", LTLThemeScript.surface_style(LTLThemeScript.SURFACE_DARK))
	_style_metric_bar(health_bar, Color(0.82, 0.24, 0.24), Color(0.17, 0.08, 0.08))
	_style_metric_bar(shield_bar, Color(0.30, 0.56, 0.96), Color(0.08, 0.11, 0.18))
	_style_metric_bar(pin_progress_bar, Color(0.91, 0.66, 0.18), Color(0.18, 0.13, 0.07))
	extractor_label.add_theme_color_override("font_color", LTLThemeScript.TEXT_PRIMARY)
	pin_label.add_theme_color_override("font_color", LTLThemeScript.TEXT_PRIMARY)
	repair_status_label.add_theme_color_override("font_color", LTLThemeScript.TEXT_MUTED)
	purple_status_label.add_theme_color_override("font_color", LTLThemeScript.TEXT_MUTED)
	purple_status_value.add_theme_color_override("font_color", LTLThemeScript.TEXT_PURPLE)
	combat_timer_label.add_theme_color_override("font_color", LTLThemeScript.TEXT_WARNING)
	extractor_visual.add_theme_stylebox_override("panel", LTLThemeScript.surface_style(LTLThemeScript.SURFACE_MID, Color(0.35, 0.46, 0.58, 1.0), 10))

func _style_metric_bar(bar: ProgressBar, fill_color: Color, background_color: Color) -> void:
	bar.add_theme_stylebox_override("fill", LTLThemeScript.value_bar_fill(fill_color))
	bar.add_theme_stylebox_override("background", LTLThemeScript.value_bar_background(background_color))

func _install_queue_hint_label() -> void:
	if visual_queue_box == null or queue_hint_label != null:
		return
	queue_hint_label = Label.new()
	queue_hint_label.name = "QueueHintLabel"
	queue_hint_label.add_theme_font_size_override("font_size", 11)
	queue_hint_label.add_theme_color_override("font_color", LTLThemeScript.TEXT_MUTED)
	queue_hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	queue_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	queue_hint_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if status_box != null and queue_row != null:
		status_box.add_child(queue_hint_label)
		status_box.move_child(queue_hint_label, queue_row.get_index() + 1)

func _queue_role_panel(role_text: String, color_name: String, dominant: bool) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(0.0, 52.0 if dominant else 44.0)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override(
		"panel",
		LTLThemeScript.surface_style(
			LTLThemeScript.SURFACE_MID if dominant else Color(0.09, 0.11, 0.14, 0.98),
			LTLThemeScript.accent_color(color_name) if not color_name.is_empty() else LTLThemeScript.BORDER_COLD,
			12,
			2 if dominant else 1
		)
	)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_top", 6)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_bottom", 6)
	panel.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)
	margin.add_child(box)
	var role_label := Label.new()
	role_label.text = role_text
	role_label.add_theme_font_size_override("font_size", 11)
	role_label.add_theme_color_override("font_color", LTLThemeScript.TEXT_MUTED)
	box.add_child(role_label)
	var value_label := Label.new()
	value_label.text = _queue_chip_text(color_name, dominant)
	value_label.add_theme_font_size_override("font_size", 16 if dominant else 14)
	value_label.add_theme_color_override("font_color", LTLThemeScript.TEXT_PRIMARY if not color_name.is_empty() else LTLThemeScript.TEXT_MUTED)
	box.add_child(value_label)
	return panel

func _queue_reserve_panel(reserve_count: int, loaded: int) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(0.0, 44.0)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", LTLThemeScript.surface_style(Color(0.08, 0.10, 0.13, 0.98), LTLThemeScript.BORDER_COLD, 12))
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_top", 6)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_bottom", 6)
	panel.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)
	margin.add_child(box)
	var role_label := Label.new()
	role_label.text = _queue_role_label("reserve")
	role_label.add_theme_font_size_override("font_size", 11)
	role_label.add_theme_color_override("font_color", LTLThemeScript.TEXT_MUTED)
	box.add_child(role_label)
	var value_label := Label.new()
	value_label.text = TextCatalogScript.t("hud.queue.reserve_status", [loaded, reserve_count])
	value_label.add_theme_font_size_override("font_size", 14)
	value_label.add_theme_color_override("font_color", LTLThemeScript.TEXT_PRIMARY)
	box.add_child(value_label)
	return panel

func _queue_chip_text(color_name: String, dominant: bool) -> String:
	if color_name.is_empty():
		return TextCatalogScript.t("hud.queue.empty")
	var icon := _energy_shape(color_name)
	var color_text := TextCatalogScript.color_label(color_name)
	return "%s  %s" % [icon, color_text] if dominant else "%s  %s" % [icon, color_text]

func _queue_role_label(role_name: String) -> String:
	return TextCatalogScript.t("hud.queue.role.%s" % role_name)

func _energy_shape(color_name: String) -> String:
	match color_name:
		"red":
			return "▲"
		"blue":
			return "◌"
		"purple":
			return "◆"
		"green":
			return "✦"
	return "•"

func _queue_hint_text(queue: Dictionary, feedback: Dictionary) -> String:
	if bool(feedback.get("isEmptyQueue", false)):
		return TextCatalogScript.t("hud.queue.hint.empty_queue")
	if bool(feedback.get("isMismatch", false)):
		return TextCatalogScript.t("hud.queue.hint.mismatch")
	if bool(queue.get("queueMatch", false)):
		return TextCatalogScript.t("hud.queue.hint.match")
	return TextCatalogScript.t("hud.queue.hint.default")

func _render_repair_projection(repair: Dictionary) -> void:
	var stage := str(repair.get("stage", "stable"))
	repair_status_label.text = str(repair.get("label", "Stable"))
	match stage:
		"stable":
			repair_status_label.add_theme_color_override("font_color", LTLThemeScript.TEXT_SUCCESS)
		"strained":
			repair_status_label.add_theme_color_override("font_color", LTLThemeScript.TEXT_WARNING)
		"critical", "repair_required":
			repair_status_label.add_theme_color_override("font_color", LTLThemeScript.TEXT_DANGER)
		_:
			repair_status_label.add_theme_color_override("font_color", LTLThemeScript.TEXT_MUTED)

func _render_status_footer(model: Dictionary) -> void:
	var parts: Array[String] = []
	var hazard: Dictionary = model.get("hazard", {})
	if bool(hazard.get("active", false)):
		parts.append(str(hazard.get("summary", "")))
	var purple_text := _render_purple_status(model.get("purplePressure", {}))
	if not purple_text.is_empty():
		parts.append(purple_text)
	var feedback: Dictionary = model.get("feedback", {})
	if bool(feedback.get("isRepairBlocked", false)):
		parts.append(TextCatalogScript.t("status.repair_locked"))
	purple_status_row.visible = not parts.is_empty()
	if parts.is_empty():
		purple_status_value.text = "-"
		_layout_purple_status_overlay()
		return
	purple_status_label.text = TextCatalogScript.t("status.field")
	purple_status_value.text = " | ".join(parts)
	var font_color := LTLThemeScript.TEXT_PURPLE
	if bool(hazard.get("active", false)):
		font_color = LTLThemeScript.TEXT_DANGER if str(hazard.get("severity", "stable")) == "critical" else LTLThemeScript.TEXT_WARNING
	purple_status_value.add_theme_color_override("font_color", font_color)
	_layout_purple_status_overlay()

func _apply_overlay_tone(overlay: PanelContainer, accent: String) -> void:
	overlay.add_theme_stylebox_override("panel", LTLThemeScript.overlay_style(accent))
