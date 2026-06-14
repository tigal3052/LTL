# 계약:
# - 책임: battle HUD status, terrain copy, weakness cards, energy queue, and phase timing readouts stay contained inside the status sidebar.
# 실행: define the battle status panel as a PanelContainer script and update queue, timing, and terrain controls from scene models.
extends PanelContainer
const TextCatalogScript = preload("res://src/ui/TextCatalog.gd")
const RewardCeremonyPolicyScript = preload("res://src/ui/presenters/RewardCeremonyPolicy.gd")
const LTLThemeScript = preload("res://src/ui/theme/LTLTheme.gd")
const EnergyQueuePulseSlotScript = preload("res://src/ui/EnergyQueuePulseSlot.gd")
const ENERGY_QUEUE_COLUMNS := 8
const ENERGY_QUEUE_ROWS := 2
const ENERGY_QUEUE_MAX_SLOTS := 16
const STATUS_ROW_LABEL_WIDTH := 76.0
const TILE_TEXTURE_PATHS := {
	"red": "res://resources/UI/tile/red_tile.png",
	"blue": "res://resources/UI/tile/blue_tile.png",
	"green": "res://resources/UI/tile/green_tile.png",
	"purple": "res://resources/UI/tile/purple_tile.png"
}
@onready var status_box: VBoxContainer = $Margin/StatusBox
@onready var info_shell: PanelContainer = $Margin/StatusBox/InfoShell
@onready var info_title: Button = $Margin/StatusBox/InfoShell/InfoMargin/InfoBox/InfoTitle
@onready var terrain_copy: Label = $Margin/StatusBox/InfoShell/InfoMargin/InfoBox/TerrainCopy
@onready var weakness_card_grid: GridContainer = $Margin/StatusBox/InfoShell/InfoMargin/InfoBox/WeaknessCardGrid
@onready var info_detail_shell: PanelContainer = $Margin/StatusBox/InfoShell/InfoMargin/InfoBox/InfoDetailShell
@onready var info_note_row: HFlowContainer = $Margin/StatusBox/InfoShell/InfoMargin/InfoBox/InfoDetailShell/InfoDetailMargin/InfoNoteRow
@onready var ops_shell: PanelContainer = $Margin/StatusBox/OpsShell
@onready var ops_box: VBoxContainer = $Margin/StatusBox/OpsShell/OpsMargin/OpsBox
@onready var status_title: Label = $Margin/StatusBox/OpsShell/OpsMargin/OpsBox/StatusTitle
@onready var node_card: PanelContainer = $Margin/StatusBox/InfoShell/InfoMargin/InfoBox/NodeCard
@onready var extractor_visual: Panel = $Margin/StatusBox/InfoShell/InfoMargin/InfoBox/NodeCard/Margin/NodeInfoBox/NodeRow/ExtractorVisual
@onready var extractor_label: Label = $Margin/StatusBox/InfoShell/InfoMargin/InfoBox/NodeCard/Margin/NodeInfoBox/NodeRow/ExtractorLabel
@onready var node_meta_label: Label = $Margin/StatusBox/InfoShell/InfoMargin/InfoBox/NodeCard/Margin/NodeInfoBox/NodeMetaLabel
@onready var health_label: Label = $Margin/StatusBox/OpsShell/OpsMargin/OpsBox/HPBox/HealthLabel
@onready var health_bar: ProgressBar = $Margin/StatusBox/OpsShell/OpsMargin/OpsBox/HPBox/HealthBar
@onready var shield_label: Label = $Margin/StatusBox/OpsShell/OpsMargin/OpsBox/ShieldBox/ShieldLabel
@onready var shield_bar: ProgressBar = $Margin/StatusBox/OpsShell/OpsMargin/OpsBox/ShieldBox/ShieldBar
@onready var queue_row: HBoxContainer = $Margin/StatusBox/OpsShell/OpsMargin/OpsBox/QueueRow
@onready var queue_label: Label = $Margin/StatusBox/OpsShell/OpsMargin/OpsBox/QueueRow/QueueLabel
@onready var visual_queue_box: GridContainer = $Margin/StatusBox/OpsShell/OpsMargin/OpsBox/QueueRow/QueueStack/QueueShell/QueueMargin/VisualQueueBox
@onready var pin_title_label: Label = $Margin/StatusBox/OpsShell/OpsMargin/OpsBox/TimerRow/PinLabel
@onready var pin_progress_bar: ProgressBar = $Margin/StatusBox/OpsShell/OpsMargin/OpsBox/TimerRow/PinProgressBar
@onready var drill_status_title: Label = $Margin/StatusBox/OpsShell/OpsMargin/OpsBox/DrillStatusRow/DrillStatusLabel
@onready var repair_status_label: Label = $Margin/StatusBox/OpsShell/OpsMargin/OpsBox/DrillStatusRow/RepairStatusLabel
@onready var status_footer_spacer: Control = $Margin/StatusBox/OpsShell/OpsMargin/OpsBox/StatusFooterSpacer
@onready var purple_status_row: HBoxContainer = $Margin/StatusBox/OpsShell/OpsMargin/OpsBox/StatusFooterSpacer/PurpleStatusRow
@onready var purple_status_label: Label = $Margin/StatusBox/OpsShell/OpsMargin/OpsBox/StatusFooterSpacer/PurpleStatusRow/PurpleStatusLabel
@onready var purple_status_value: Label = $Margin/StatusBox/OpsShell/OpsMargin/OpsBox/StatusFooterSpacer/PurpleStatusRow/PurpleStatusValue
@onready var combat_timer_label: Label = $Margin/StatusBox/OpsShell/OpsMargin/OpsBox/CombatTimerFooterMargin/CombatTimerFooter/CombatTimerLabel

var queue_hint_label: Label
var pin_value_label: Label
var info_details_expanded := false

func _ready() -> void:
	_apply_shell_theme()
	_connect_info_toggle()
	_install_queue_hint_label()
	_install_pin_value_label()
	_apply_row_alignment()
	_configure_visual_queue_grid()
	_configure_purple_status_overlay()
	apply_locale()
	render_node_info({})
	render_hud_projection({})
	render_combat_timer("00:00", false)

func apply_locale() -> void:
	_update_info_toggle_text()
	status_title.text = TextCatalogScript.t("panel.drill_node_status")
	health_label.text = TextCatalogScript.t("panel.health")
	shield_label.text = TextCatalogScript.t("panel.shield")
	queue_label.text = TextCatalogScript.t("panel.queue")
	pin_title_label.text = TextCatalogScript.t("panel.pin_status")
	drill_status_title.text = TextCatalogScript.t("panel.drill_status")
	if weakness_card_grid.get_child_count() == 0:
		terrain_copy.text = TextCatalogScript.t("panel.info.empty")
	_sync_info_detail_visibility()
	if purple_status_row.visible:
		purple_status_label.text = TextCatalogScript.t("panel.purple_status")

func render_target_bars(scene: Dictionary) -> void:
	if not _is_status_scene(scene):
		return
	var target: Dictionary = scene.get("targetPanel", {})
	_apply_value_bar(health_bar, float(target.get("health", 0.0)), float(target.get("maxHealth", 100.0)))
	_apply_value_bar(shield_bar, float(target.get("shield", 0.0)), float(target.get("maxShield", 2.4)))

func render_extractor_label(scene: Dictionary) -> void:
	var context: Dictionary = scene.get("selectedNodeContext", {})
	var node_label := str(context.get("label", scene.get("lastNodeLabel", "")))
	extractor_label.text = TextCatalogScript.t(
		"status.node",
		[TextCatalogScript.display_name(node_label) if not node_label.is_empty() else "-"]
	)
	node_meta_label.text = _node_meta_text(context, scene.get("targetPanel", {}))

func render_node_info(scene: Dictionary) -> void:
	_clear_container(weakness_card_grid)
	_clear_container(info_note_row)
	info_note_row.visible = false
	if scene.is_empty():
		terrain_copy.text = TextCatalogScript.t("panel.info.empty")
		_sync_info_detail_visibility()
		return
	var context: Dictionary = scene.get("selectedNodeContext", {})
	var target_panel: Dictionary = scene.get("targetPanel", {})
	var weaknesses: Array = _normalized_colors(context.get("weakness", target_panel.get("weakness", [])))
	if context.is_empty() and target_panel.is_empty() and weaknesses.is_empty():
		terrain_copy.text = TextCatalogScript.t("panel.info.empty")
		_sync_info_detail_visibility()
		return
	var shield_mul := float(context.get("shieldMul", context.get("shield_mul", 1.0)))
	var health_mul := float(context.get("healthMul", context.get("health_mul", 1.0)))
	terrain_copy.text = _terrain_copy(context, weaknesses)
	if weaknesses.is_empty():
		weakness_card_grid.columns = 1
		weakness_card_grid.add_child(_build_neutral_card(shield_mul, health_mul))
	else:
		weakness_card_grid.columns = 1
		for color_name in weaknesses:
			var metrics := _metric_values_for_color(context, str(color_name))
			weakness_card_grid.add_child(
				_build_color_card(
					str(color_name),
					float(metrics.get("shield", shield_mul)),
					float(metrics.get("health", health_mul))
				)
			)
	_render_note_row(context, weaknesses)
	_sync_info_detail_visibility()

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
		_render_pin_projection({})
		_render_repair_projection({})
		_render_status_footer({})
		if queue_hint_label != null:
			queue_hint_label.text = ""
		return
	var queue: Dictionary = model.get("queue", {})
	var slot_colors: Array = queue.get("slotColors", []).duplicate(true) if queue.get("slotColors", []) is Array else []
	var capacity := clampi(int(queue.get("capacity", ENERGY_QUEUE_COLUMNS)), 0, ENERGY_QUEUE_MAX_SLOTS)
	if capacity <= 0:
		capacity = ENERGY_QUEUE_COLUMNS
	for index in range(ENERGY_QUEUE_MAX_SLOTS):
		var slot := EnergyQueuePulseSlotScript.new()
		var enabled := index < capacity
		var loaded := index < slot_colors.size()
		var slot_color := str(slot_colors[index]) if loaded else ""
		slot.configure(slot_color, loaded, enabled, index == 0 and loaded)
		visual_queue_box.add_child(slot)
	if queue_hint_label != null:
		queue_hint_label.text = _queue_hint_text(queue, model.get("feedback", {}))
	_render_pin_projection(model.get("pin", {}))
	_render_repair_projection(model.get("repair", {}))
	_render_status_footer(model)

func render_combat_timer(timer_text: String, active: bool) -> void:
	combat_timer_label.visible = active
	combat_timer_label.text = timer_text if active else "00:00"

func render_repair_overlay(_scene: Dictionary, repair_overlay: PanelContainer, overlay_model: Dictionary = {}) -> void:
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

func _connect_info_toggle() -> void:
	if info_title == null:
		return
	info_title.toggle_mode = true
	info_title.button_pressed = info_details_expanded
	if not info_title.pressed.is_connected(_on_info_title_pressed):
		info_title.pressed.connect(_on_info_title_pressed)
	_update_info_toggle_text()
	_sync_info_detail_visibility()

func _on_info_title_pressed() -> void:
	info_details_expanded = not info_details_expanded
	info_title.button_pressed = info_details_expanded
	_update_info_toggle_text()
	_sync_info_detail_visibility()

func _update_info_toggle_text() -> void:
	if info_title == null:
		return
	var marker := "-" if info_details_expanded else "+"
	info_title.text = "%s  %s" % [TextCatalogScript.t("panel.info.core"), marker]

func _sync_info_detail_visibility() -> void:
	if info_detail_shell == null:
		return
	var has_details := info_note_row != null and info_note_row.get_child_count() > 0
	var expanded_with_cards := info_details_expanded and weakness_card_grid != null and weakness_card_grid.get_child_count() > 0
	info_detail_shell.visible = info_details_expanded and has_details
	if weakness_card_grid != null:
		weakness_card_grid.visible = expanded_with_cards
	if node_card != null:
		node_card.visible = info_details_expanded
	if ops_shell != null:
		ops_shell.visible = not info_details_expanded
		ops_shell.size_flags_vertical = Control.SIZE_EXPAND_FILL
	if info_shell != null:
		info_shell.size_flags_vertical = Control.SIZE_EXPAND_FILL if info_details_expanded else Control.SIZE_FILL
	if info_note_row != null:
		info_note_row.visible = has_details
	if terrain_copy != null:
		terrain_copy.visible = true

func _is_status_scene(scene: Dictionary) -> bool:
	return should_render_status_scene(scene)

static func should_render_status_scene(scene: Dictionary) -> bool:
	var phase := str(scene.get("phase", ""))
	return phase == "combat" or RewardCeremonyPolicyScript.is_active_scene(scene) or (phase == "reward_loot" and bool(scene.get("show_victory_overlay", false)))

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

func _configure_visual_queue_grid() -> void:
	if visual_queue_box == null:
		return
	visual_queue_box.columns = ENERGY_QUEUE_COLUMNS
	visual_queue_box.add_theme_constant_override("h_separation", 6)
	visual_queue_box.add_theme_constant_override("v_separation", 8)

func _clear_visual_queue_box() -> void:
	for child in visual_queue_box.get_children():
		visual_queue_box.remove_child(child)
		child.queue_free()

func _render_pin_projection(pin: Dictionary) -> void:
	var progress := clampf(float(pin.get("progress", 0.0)), 0.0, 100.0)
	pin_progress_bar.max_value = 100.0
	pin_progress_bar.value = progress
	pin_progress_bar.show_percentage = false
	if pin_value_label != null:
		pin_value_label.text = "%d%%" % int(round(progress))

func _node_meta_text(context: Dictionary, target_panel: Dictionary) -> String:
	var weaknesses: Array = []
	var raw_weakness = context.get("weakness", target_panel.get("weakness", []))
	if raw_weakness is Array:
		weaknesses = raw_weakness.duplicate(true)
	var weakness_text := _weakness_label(weaknesses)
	var risk_text := TextCatalogScript.enum_label("risk", str(context.get("risk_tier", "safe")))
	return "%s  |  %s" % [weakness_text, risk_text]

func _weakness_label(weaknesses: Array) -> String:
	if weaknesses.is_empty():
		return TextCatalogScript.t("node.no_weakness")
	var labels: Array[String] = []
	for weakness in weaknesses:
		labels.append(TextCatalogScript.color_label(str(weakness)))
	return " + ".join(labels)

func _metric_values_for_color(context: Dictionary, color_name: String) -> Dictionary:
	var shield_mul := float(context.get("shieldMul", context.get("shield_mul", 1.0)))
	var health_mul := float(context.get("healthMul", context.get("health_mul", 1.0)))
	var shield_by_color: Dictionary = context.get("shieldMulByColor", context.get("shield_mul_by_color", {}))
	var health_by_color: Dictionary = context.get("healthMulByColor", context.get("health_mul_by_color", {}))
	if shield_by_color.has(color_name):
		shield_mul = float(shield_by_color.get(color_name, shield_mul))
	if health_by_color.has(color_name):
		health_mul = float(health_by_color.get(color_name, health_mul))
	return {
		"shield": shield_mul,
		"health": health_mul
	}

func _terrain_copy(context: Dictionary, weaknesses: Array) -> String:
	if weaknesses.is_empty():
		return TextCatalogScript.t("panel.info.terrain.base")
	if weaknesses.size() == 1:
		return TextCatalogScript.t("panel.info.terrain.single", [_joined_color_labels(weaknesses)])
	return TextCatalogScript.t("panel.info.terrain.composite", [_joined_color_labels(weaknesses)])

func _render_note_row(context: Dictionary, weaknesses: Array) -> void:
	var mode_key := "panel.info.note.base_mode"
	var mode_accent := Color(0.39, 0.76, 1.0, 1.0)
	if weaknesses.size() == 1:
		mode_key = "panel.info.note.single_mode"
		mode_accent = LTLThemeScript.accent_color(str(weaknesses[0]))
	elif weaknesses.size() > 1:
		mode_key = "panel.info.note.composite_mode"
		mode_accent = Color(0.79, 0.83, 0.57, 1.0)
	info_note_row.add_child(_note_chip(TextCatalogScript.t(mode_key), mode_accent))
	if context.is_empty():
		info_note_row.visible = true
		return
	var risk_text := _risk_text(str(context.get("risk_tier", "safe")))
	info_note_row.add_child(_note_chip(TextCatalogScript.t("panel.info.note.risk", [risk_text]), Color(0.39, 0.76, 1.0, 1.0)))
	var reward_bias := str(context.get("rewardBias", context.get("reward_bias", "")))
	if not reward_bias.is_empty():
		info_note_row.add_child(_note_chip(TextCatalogScript.t("panel.info.note.reward", [_reward_bias_text(reward_bias)]), LTLThemeScript.TEXT_WARNING))
	var raw_hint := str(context.get("recommendedBuildHint", context.get("recommended_build_hint", "")))
	if not raw_hint.is_empty():
		info_note_row.add_child(_note_chip(TextCatalogScript.t("panel.info.note.hint", [_hint_text(raw_hint)]), LTLThemeScript.TEXT_SUCCESS))
	info_note_row.visible = info_note_row.get_child_count() > 0

func _note_chip(text_value: String, accent: Color) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	panel.add_theme_stylebox_override("panel", LTLThemeScript.surface_style(
		Color(0.09, 0.12, 0.17, 0.96),
		Color(accent.r, accent.g, accent.b, 0.32),
		999,
		1,
		0.10
	))
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_top", 3)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_bottom", 3)
	panel.add_child(margin)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	margin.add_child(row)
	row.add_child(_round_dot(accent, 8.0, "NoteDot"))
	var label := Label.new()
	label.text = text_value
	label.add_theme_font_size_override("font_size", 11)
	label.add_theme_color_override("font_color", LTLThemeScript.TEXT_PRIMARY)
	row.add_child(label)
	return panel

func _build_neutral_card(shield_mul: float, health_mul: float) -> PanelContainer:
	var card := _base_card()
	var content := _card_content(card)
	content.add_child(_card_title(TextCatalogScript.t("panel.info.neutral_title")))
	content.add_child(_metric_stack(shield_mul, health_mul))
	return card

func _build_color_card(color_name: String, shield_mul: float, health_mul: float) -> PanelContainer:
	var card := _base_card()
	var content := _card_content(card)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	content.add_child(row)
	var icon := TextureRect.new()
	icon.texture = _tile_texture(color_name)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.custom_minimum_size = Vector2(34.0, 34.0)
	row.add_child(icon)
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 4)
	row.add_child(box)
	box.add_child(_card_title(TextCatalogScript.t("panel.info.weakness_label", [TextCatalogScript.color_label(color_name)])))
	box.add_child(_metric_stack(shield_mul, health_mul))
	return card

func _metric_stack(shield_mul: float, health_mul: float) -> GridContainer:
	var stack := GridContainer.new()
	stack.columns = 2
	stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stack.add_theme_constant_override("h_separation", 4)
	stack.add_theme_constant_override("v_separation", 4)
	stack.add_child(_metric_card(TextCatalogScript.t("panel.info.metric.health"), health_mul, Color(1.0, 0.52, 0.52, 1.0)))
	stack.add_child(_metric_card(TextCatalogScript.t("panel.info.metric.shield"), shield_mul, Color(0.39, 0.76, 1.0, 1.0)))
	return stack

func _metric_card(label_text: String, value: float, accent: Color) -> PanelContainer:
	var card := PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.custom_minimum_size = Vector2(0.0, 58.0)
	card.add_theme_stylebox_override("panel", LTLThemeScript.surface_style(
		Color(0.08, 0.11, 0.15, 0.96),
		Color(accent.r, accent.g, accent.b, 0.24),
		10,
		1,
		0.12
	))
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 6)
	margin.add_theme_constant_override("margin_top", 6)
	margin.add_theme_constant_override("margin_right", 6)
	margin.add_theme_constant_override("margin_bottom", 6)
	card.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)
	margin.add_child(box)
	var head := HBoxContainer.new()
	head.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_theme_constant_override("separation", 6)
	box.add_child(head)
	head.add_child(_round_dot(accent, 8.0, "MetricDot"))
	var label := Label.new()
	label.name = "MetricLabel"
	label.text = label_text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_font_size_override("font_size", 10)
	label.add_theme_color_override("font_color", LTLThemeScript.TEXT_PRIMARY)
	head.add_child(label)
	var value_label := Label.new()
	value_label.text = "x%.2f" % value
	value_label.add_theme_font_size_override("font_size", 18)
	value_label.add_theme_color_override("font_color", LTLThemeScript.TEXT_PRIMARY)
	box.add_child(value_label)
	return card

func _round_dot(accent: Color, size: float, node_name: String) -> Panel:
	var dot := Panel.new()
	dot.name = node_name
	dot.custom_minimum_size = Vector2(size, size)
	var style := StyleBoxFlat.new()
	style.bg_color = accent
	var radius := int(round(size * 0.5))
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_right = radius
	style.corner_radius_bottom_left = radius
	style.shadow_color = Color(accent.r, accent.g, accent.b, 0.35)
	style.shadow_size = 4
	dot.add_theme_stylebox_override("panel", style)
	return dot

func _card_title(text_value: String) -> Label:
	var label := Label.new()
	label.text = text_value
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_font_size_override("font_size", 11)
	label.add_theme_color_override("font_color", LTLThemeScript.TEXT_PRIMARY)
	return label

func _base_card() -> PanelContainer:
	var card := PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.custom_minimum_size = Vector2(0.0, 80.0)
	card.add_theme_stylebox_override("panel", LTLThemeScript.surface_style(
		Color(0.10, 0.14, 0.19, 0.97),
		Color(0.28, 0.38, 0.48, 1.0),
		14,
		1,
		0.14
	))
	return card

func _card_content(card: PanelContainer) -> VBoxContainer:
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	card.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	margin.add_child(box)
	return box

func _tile_texture(color_name: String) -> Texture2D:
	return LTLThemeScript.art_texture(str(TILE_TEXTURE_PATHS.get(color_name, "")))

func _normalized_colors(value: Variant) -> Array:
	if not (value is Array):
		return []
	var result: Array = []
	for entry in value:
		var color_name := str(entry).to_lower()
		if color_name in TILE_TEXTURE_PATHS and not result.has(color_name):
			result.append(color_name)
	return result

func _joined_color_labels(colors: Array) -> String:
	var labels: Array[String] = []
	for color_name in colors:
		labels.append(TextCatalogScript.color_label(str(color_name)))
	return " + ".join(labels)

func _risk_text(risk_tier: String) -> String:
	var label := TextCatalogScript.enum_label("risk", risk_tier)
	return label if label != "risk.%s" % risk_tier.to_lower() else risk_tier

func _reward_bias_text(reward_bias: String) -> String:
	var label := TextCatalogScript.enum_label("reward_bias", reward_bias)
	if label != "reward_bias.%s" % reward_bias.to_lower():
		return label
	match TextCatalogScript.locale():
		"ko":
			match reward_bias:
				"blue_energy":
					return "Blue Energy"
				"artifact_choice":
					return "Artifact Choice"
		_:
			match reward_bias:
				"blue_energy":
					return "Blue Energy"
				"artifact_choice":
					return "Artifact Choice"
	return reward_bias.replace("_", " ")

func _hint_text(raw_hint: String) -> String:
	var localized := TextCatalogScript.hint_label(raw_hint)
	if localized != raw_hint:
		return localized
	return raw_hint

func _render_purple_status(pressure: Dictionary) -> String:
	var stack_count := int(pressure.get("stackCount", 0))
	var buff_count := int(pressure.get("buffCount", 0))
	var parts: Array[String] = []
	if stack_count > 0:
		parts.append(TextCatalogScript.t("status.purple.weakened", [stack_count]))
	if buff_count > 0:
		parts.append(TextCatalogScript.t("status.purple.buff", [buff_count]))
	return " | ".join(parts)

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
	info_shell.add_theme_stylebox_override("panel", LTLThemeScript.surface_style(
		Color(0.09, 0.12, 0.16, 0.98),
		Color(0.26, 0.34, 0.44, 1.0),
		16,
		1,
		0.12
	))
	_style_info_toggle()
	info_detail_shell.add_theme_stylebox_override("panel", LTLThemeScript.surface_style(
		Color(0.07, 0.10, 0.14, 0.94),
		Color(0.38, 0.47, 0.56, 0.72),
		12,
		1,
		0.10
	))
	ops_shell.add_theme_stylebox_override("panel", LTLThemeScript.surface_style(
		Color(0.08, 0.10, 0.14, 0.98),
		Color(0.22, 0.30, 0.40, 1.0),
		16,
		1,
		0.12
	))
	node_card.add_theme_stylebox_override("panel", LTLThemeScript.surface_style(
		Color(0.09, 0.12, 0.16, 0.98),
		Color(0.25, 0.35, 0.44, 1.0),
		14,
		1,
		0.12
	))
	_style_metric_bar(health_bar, Color(0.82, 0.24, 0.24), Color(0.17, 0.08, 0.08))
	_style_metric_bar(shield_bar, Color(0.30, 0.56, 0.96), Color(0.08, 0.11, 0.18))
	_style_metric_bar(pin_progress_bar, Color(0.91, 0.66, 0.18), Color(0.18, 0.13, 0.07))
	extractor_label.add_theme_color_override("font_color", LTLThemeScript.TEXT_PRIMARY)
	node_meta_label.add_theme_color_override("font_color", LTLThemeScript.TEXT_MUTED)
	terrain_copy.add_theme_color_override("font_color", LTLThemeScript.TEXT_MUTED)
	pin_title_label.add_theme_color_override("font_color", LTLThemeScript.TEXT_PRIMARY)
	repair_status_label.add_theme_color_override("font_color", LTLThemeScript.TEXT_MUTED)
	purple_status_label.add_theme_color_override("font_color", LTLThemeScript.TEXT_MUTED)
	purple_status_value.add_theme_color_override("font_color", LTLThemeScript.TEXT_PURPLE)
	combat_timer_label.add_theme_color_override("font_color", LTLThemeScript.TEXT_WARNING)
	extractor_visual.add_theme_stylebox_override("panel", LTLThemeScript.surface_style(LTLThemeScript.SURFACE_MID, Color(0.35, 0.46, 0.58, 1.0), 10))

func _style_info_toggle() -> void:
	if info_title == null:
		return
	info_title.flat = false
	info_title.alignment = HORIZONTAL_ALIGNMENT_LEFT
	info_title.add_theme_font_size_override("font_size", 13)
	info_title.add_theme_color_override("font_color", LTLThemeScript.TEXT_PRIMARY)
	info_title.add_theme_color_override("font_hover_color", LTLThemeScript.TEXT_PRIMARY)
	info_title.add_theme_color_override("font_pressed_color", LTLThemeScript.TEXT_PRIMARY)
	info_title.add_theme_color_override("font_focus_color", LTLThemeScript.TEXT_PRIMARY)
	var normal := LTLThemeScript.surface_style(Color(0.10, 0.14, 0.19, 0.92), Color(0.33, 0.42, 0.52, 0.86), 12, 1, 0.10)
	var hover := LTLThemeScript.surface_style(Color(0.12, 0.16, 0.21, 0.96), Color(0.56, 0.45, 0.24, 0.96), 12, 1, 0.16)
	var pressed := LTLThemeScript.surface_style(Color(0.11, 0.15, 0.20, 0.98), LTLThemeScript.BORDER_WARM, 12, 1, 0.18)
	for style in [normal, hover, pressed]:
		style.content_margin_left = 10
		style.content_margin_right = 10
		style.content_margin_top = 5
		style.content_margin_bottom = 5
	info_title.add_theme_stylebox_override("normal", normal)
	info_title.add_theme_stylebox_override("hover", hover)
	info_title.add_theme_stylebox_override("pressed", pressed)
	info_title.add_theme_stylebox_override("focus", hover)

func _apply_row_alignment() -> void:
	for label in [health_label, shield_label, queue_label, pin_title_label, drill_status_title]:
		if label == null:
			continue
		label.custom_minimum_size = Vector2(STATUS_ROW_LABEL_WIDTH, 0.0)
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	for control in [health_bar, shield_bar, visual_queue_box.get_parent().get_parent() if visual_queue_box != null else null, pin_progress_bar, repair_status_label]:
		var row_value = control as Control
		if row_value == null:
			continue
		row_value.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if repair_status_label != null:
		repair_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		repair_status_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

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
	queue_hint_label.visible = false
	if ops_box != null and queue_row != null:
		ops_box.add_child(queue_hint_label)
		ops_box.move_child(queue_hint_label, queue_row.get_index() + 1)

func _install_pin_value_label() -> void:
	if pin_progress_bar == null or pin_value_label != null:
		return
	pin_value_label = Label.new()
	pin_value_label.name = "PinValueLabel"
	pin_value_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pin_value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pin_value_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	pin_value_label.add_theme_font_size_override("font_size", 10)
	pin_value_label.add_theme_color_override("font_color", LTLThemeScript.TEXT_PRIMARY)
	pin_progress_bar.add_child(pin_value_label)

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
	repair_status_label.text = str(repair.get("label", TextCatalogScript.t("hud.repair.stable")))
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

func _clear_container(container: Node) -> void:
	if container == null:
		return
	for child in container.get_children():
		container.remove_child(child)
		child.queue_free()
