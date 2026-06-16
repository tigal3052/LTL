# ?④쑴鍮?
# 계약: render short narrative beat text as a non-blocking runtime overlay.
# - Responsibility: render short narrative beat text as a non-blocking runtime overlay.
# - Input: narrative read-model dictionaries with visible, speaker, and text fields.
# - Output: a stable toast node tree for runtime and headless UI checks.
# - Forbidden: beat selection, progress writes, telemetry emission, or input capture.
#
# ??쎈뻬: define the narrative toast overlay control.
# 실행: define the narrative toast overlay control.
class_name NarrativeToast
extends PanelContainer

var speaker_label: Label = null
var body_label: Label = null

# ??쎈뻬: prepare a hidden, input-transparent overlay.
func _init() -> void:
	name = "NarrativeToast"
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 440
	custom_minimum_size = Vector2(360.0, 96.0)

# ??쎈뻬: build the toast node tree after entering the scene.
func _ready() -> void:
	ensure_built()

# ??쎈뻬: create child labels once with stable names for tests and UI rendering.
func ensure_built() -> void:
	if get_node_or_null("Margin") != null:
		return
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.07, 0.09, 0.10, 0.94)
	panel_style.border_color = Color(0.58, 0.72, 0.76, 0.42)
	panel_style.border_width_left = 1
	panel_style.border_width_top = 1
	panel_style.border_width_right = 1
	panel_style.border_width_bottom = 1
	panel_style.corner_radius_top_left = 8
	panel_style.corner_radius_top_right = 8
	panel_style.corner_radius_bottom_left = 8
	panel_style.corner_radius_bottom_right = 8
	add_theme_stylebox_override("panel", panel_style)

	var margin := MarginContainer.new()
	margin.name = "Margin"
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_bottom", 12)
	add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.name = "VBox"
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_theme_constant_override("separation", 5)
	margin.add_child(vbox)

	speaker_label = Label.new()
	speaker_label.name = "SpeakerLabel"
	speaker_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	speaker_label.text = ""
	speaker_label.add_theme_font_size_override("font_size", 12)
	speaker_label.add_theme_color_override("font_color", Color(0.77, 0.89, 0.90, 1.0))
	vbox.add_child(speaker_label)

	body_label = Label.new()
	body_label.name = "BodyLabel"
	body_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body_label.text = ""
	body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body_label.add_theme_font_size_override("font_size", 15)
	body_label.add_theme_color_override("font_color", Color(0.96, 0.97, 0.92, 1.0))
	vbox.add_child(body_label)

# ??쎈뻬: apply a narrative read model to the visible toast state.
func render(model: Dictionary) -> void:
	ensure_built()
	if not bool(model.get("visible", false)):
		visible = false
		return
	var speaker := str(model.get("speaker", "")).strip_edges()
	speaker_label.text = speaker
	speaker_label.visible = not speaker.is_empty()
	body_label.text = str(model.get("text", ""))
	visible = not body_label.text.strip_edges().is_empty()
