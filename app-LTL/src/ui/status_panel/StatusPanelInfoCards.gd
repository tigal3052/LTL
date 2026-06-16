# 怨꾩빟:
# - Responsibility: build status-panel node info copy, note chips, and weakness metric cards.
# - Input: selected node context dictionaries and target panel snapshots.
# - Output: UI controls or localized strings for StatusPanelUI to attach.
# - Forbidden: status panel shell visibility, queue rendering, timer rendering, or repair overlay state.
#
# ?ㅽ뻾: define the status panel info-card helper.
class_name StatusPanelInfoCards
extends RefCounted

const TextCatalogScript = preload("res://src/ui/TextCatalog.gd")
const LTLThemeScript = preload("res://src/ui/theme/LTLTheme.gd")
const TILE_TEXTURE_PATHS := {
	"red": "res://resources/UI/tile/red_tile.png",
	"blue": "res://resources/UI/tile/blue_tile.png",
	"green": "res://resources/UI/tile/green_tile.png",
	"purple": "res://resources/UI/tile/purple_tile.png"
}

static func node_meta_text(context: Dictionary, target_panel: Dictionary) -> String:
	var weaknesses: Array = []
	var raw_weakness = context.get("weakness", target_panel.get("weakness", []))
	if raw_weakness is Array:
		weaknesses = raw_weakness.duplicate(true)
	var weakness_text := _weakness_label(weaknesses)
	var risk_text := TextCatalogScript.enum_label("risk", str(context.get("risk_tier", "safe")))
	return "%s  |  %s" % [weakness_text, risk_text]

static func normalized_colors(value: Variant) -> Array:
	if not (value is Array):
		return []
	var result: Array = []
	for entry in value:
		var color_name := str(entry).to_lower()
		if color_name in TILE_TEXTURE_PATHS and not result.has(color_name):
			result.append(color_name)
	return result

static func metric_values_for_color(context: Dictionary, color_name: String) -> Dictionary:
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

static func terrain_copy(context: Dictionary, weaknesses: Array) -> String:
	if weaknesses.is_empty():
		return TextCatalogScript.t("panel.info.terrain.base")
	if weaknesses.size() == 1:
		return TextCatalogScript.t("panel.info.terrain.single", [_joined_color_labels(weaknesses)])
	return TextCatalogScript.t("panel.info.terrain.composite", [_joined_color_labels(weaknesses)])

static func render_note_row(info_note_row: HFlowContainer, context: Dictionary, weaknesses: Array) -> void:
	if info_note_row == null:
		return
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

static func build_neutral_card(shield_mul: float, health_mul: float) -> PanelContainer:
	var card := _base_card()
	var content := _card_content(card)
	content.add_child(_card_title(TextCatalogScript.t("panel.info.neutral_title")))
	content.add_child(metric_stack(shield_mul, health_mul))
	return card

static func build_color_card(color_name: String, shield_mul: float, health_mul: float) -> PanelContainer:
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
	box.add_child(metric_stack(shield_mul, health_mul))
	return card

static func metric_stack(shield_mul: float, health_mul: float) -> GridContainer:
	var stack := GridContainer.new()
	stack.columns = 2
	stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stack.add_theme_constant_override("h_separation", 4)
	stack.add_theme_constant_override("v_separation", 4)
	stack.add_child(_metric_card(TextCatalogScript.t("panel.info.metric.health"), health_mul, Color(1.0, 0.52, 0.52, 1.0)))
	stack.add_child(_metric_card(TextCatalogScript.t("panel.info.metric.shield"), shield_mul, Color(0.39, 0.76, 1.0, 1.0)))
	return stack

static func _weakness_label(weaknesses: Array) -> String:
	if weaknesses.is_empty():
		return TextCatalogScript.t("node.no_weakness")
	var labels: Array[String] = []
	for weakness in weaknesses:
		labels.append(TextCatalogScript.color_label(str(weakness)))
	return " + ".join(labels)

static func _note_chip(text_value: String, accent: Color) -> PanelContainer:
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

static func _metric_card(label_text: String, value: float, accent: Color) -> PanelContainer:
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

static func _round_dot(accent: Color, size: float, node_name: String) -> Panel:
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

static func _card_title(text_value: String) -> Label:
	var label := Label.new()
	label.text = text_value
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_font_size_override("font_size", 11)
	label.add_theme_color_override("font_color", LTLThemeScript.TEXT_PRIMARY)
	return label

static func _base_card() -> PanelContainer:
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

static func _card_content(card: PanelContainer) -> VBoxContainer:
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

static func _tile_texture(color_name: String) -> Texture2D:
	return LTLThemeScript.art_texture(str(TILE_TEXTURE_PATHS.get(color_name, "")))

static func _joined_color_labels(colors: Array) -> String:
	var labels: Array[String] = []
	for color_name in colors:
		labels.append(TextCatalogScript.color_label(str(color_name)))
	return " + ".join(labels)

static func _risk_text(risk_tier: String) -> String:
	var label := TextCatalogScript.enum_label("risk", risk_tier)
	return label if label != "risk.%s" % risk_tier.to_lower() else risk_tier

static func _reward_bias_text(reward_bias: String) -> String:
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

static func _hint_text(raw_hint: String) -> String:
	var localized := TextCatalogScript.hint_label(raw_hint)
	if localized != raw_hint:
		return localized
	return raw_hint
