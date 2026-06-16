# 계약: M7 narrative beat를 진행 가능한 story surface로 표시한다.
# - 책임: read-model의 speaker/text/prompt 값을 상단 visual area와 하단 dialogue area에 렌더링한다.
# - 입력: visible, beatId, speaker, text, continuePrompt, continueIcon, skipInputAllowed를 가진 Dictionary.
# - 출력: 재사용 가능한 story surface 노드와 클릭/키/패드 dismiss affordance.
# - 금지: narrative beat 선택, progress 저장, telemetry 발행, page transition 변경.
#
# 실행: define the narrative story surface control.
class_name NarrativeToast
extends PanelContainer

signal continue_requested(beat_id: String)

const LTLThemeScript = preload("res://src/ui/theme/LTLTheme.gd")

var speaker_label: Label = null
var body_label: Label = null
var continue_prompt_label: Label = null
var continue_icon_label: Label = null
var visual_area: PanelContainer = null
var visual_image: TextureRect = null
var portrait_image: TextureRect = null

var _current_beat_id := ""
var _dismissed_beat_id := ""
var _skip_input_allowed := true
var _portrait_side := "none"

# 실행: initialize the hidden story surface as a clickable continue target.
func _init() -> void:
	name = "NarrativeToast"
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	z_index = 440
	custom_minimum_size = Vector2(420.0, 300.0)

# 실행: build the stable child tree once the control enters the scene.
func _ready() -> void:
	ensure_built()

# 실행: create the visual area, dialogue panel, and continue prompt nodes.
func ensure_built() -> void:
	if get_node_or_null("StoryFrame") != null:
		return
	add_theme_stylebox_override("panel", StyleBoxEmpty.new())

	var story_frame := VBoxContainer.new()
	story_frame.name = "StoryFrame"
	story_frame.mouse_filter = Control.MOUSE_FILTER_PASS
	story_frame.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	story_frame.size_flags_vertical = Control.SIZE_EXPAND_FILL
	story_frame.add_theme_constant_override("separation", 10)
	add_child(story_frame)

	visual_area = PanelContainer.new()
	visual_area.name = "VisualArea"
	visual_area.mouse_filter = Control.MOUSE_FILTER_IGNORE
	visual_area.custom_minimum_size = Vector2(0.0, 150.0)
	visual_area.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	visual_area.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	visual_area.add_theme_stylebox_override("panel", _visual_style())
	story_frame.add_child(visual_area)

	var visual_margin := MarginContainer.new()
	visual_margin.name = "VisualMargin"
	visual_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	visual_margin.add_theme_constant_override("margin_left", 18)
	visual_margin.add_theme_constant_override("margin_top", 14)
	visual_margin.add_theme_constant_override("margin_right", 18)
	visual_margin.add_theme_constant_override("margin_bottom", 14)
	visual_area.add_child(visual_margin)

	var visual_plate := ColorRect.new()
	visual_plate.name = "VisualPlate"
	visual_plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	visual_plate.color = Color(0.16, 0.20, 0.21, 0.76)
	visual_plate.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	visual_plate.size_flags_vertical = Control.SIZE_EXPAND_FILL
	visual_margin.add_child(visual_plate)

	visual_image = TextureRect.new()
	visual_image.name = "VisualImage"
	visual_image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	visual_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	visual_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	visual_image.self_modulate = Color(0.82, 0.88, 0.90, 0.30)
	visual_image.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	visual_area.add_child(visual_image)

	portrait_image = TextureRect.new()
	portrait_image.name = "PortraitImage"
	portrait_image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	portrait_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
	portrait_image.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	portrait_image.visible = false
	visual_area.add_child(portrait_image)

	var dialog_panel := PanelContainer.new()
	dialog_panel.name = "DialogPanel"
	dialog_panel.mouse_filter = Control.MOUSE_FILTER_PASS
	dialog_panel.custom_minimum_size = Vector2(0.0, 142.0)
	dialog_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dialog_panel.add_theme_stylebox_override("panel", _dialog_style())
	story_frame.add_child(dialog_panel)

	var dialog_margin := MarginContainer.new()
	dialog_margin.name = "DialogMargin"
	dialog_margin.mouse_filter = Control.MOUSE_FILTER_PASS
	dialog_margin.add_theme_constant_override("margin_left", 20)
	dialog_margin.add_theme_constant_override("margin_top", 16)
	dialog_margin.add_theme_constant_override("margin_right", 20)
	dialog_margin.add_theme_constant_override("margin_bottom", 14)
	dialog_panel.add_child(dialog_margin)

	var dialog_box := VBoxContainer.new()
	dialog_box.name = "DialogBox"
	dialog_box.mouse_filter = Control.MOUSE_FILTER_PASS
	dialog_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dialog_box.add_theme_constant_override("separation", 7)
	dialog_margin.add_child(dialog_box)

	speaker_label = Label.new()
	speaker_label.name = "SpeakerLabel"
	speaker_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	speaker_label.text = ""
	speaker_label.add_theme_font_size_override("font_size", 13)
	speaker_label.add_theme_color_override("font_color", Color(0.75, 0.89, 0.90, 1.0))
	dialog_box.add_child(speaker_label)

	body_label = Label.new()
	body_label.name = "BodyLabel"
	body_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body_label.text = ""
	body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body_label.add_theme_font_size_override("font_size", 18)
	body_label.add_theme_color_override("font_color", Color(0.97, 0.96, 0.89, 1.0))
	dialog_box.add_child(body_label)

	var prompt_row := HBoxContainer.new()
	prompt_row.name = "PromptRow"
	prompt_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	prompt_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	prompt_row.add_theme_constant_override("separation", 8)
	dialog_box.add_child(prompt_row)

	var prompt_spacer := Control.new()
	prompt_spacer.name = "PromptSpacer"
	prompt_spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	prompt_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	prompt_row.add_child(prompt_spacer)

	continue_prompt_label = Label.new()
	continue_prompt_label.name = "ContinuePrompt"
	continue_prompt_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	continue_prompt_label.text = ""
	continue_prompt_label.add_theme_font_size_override("font_size", 13)
	continue_prompt_label.add_theme_color_override("font_color", Color(0.80, 0.86, 0.82, 0.88))
	prompt_row.add_child(continue_prompt_label)

	continue_icon_label = Label.new()
	continue_icon_label.name = "ContinueIcon"
	continue_icon_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	continue_icon_label.text = "▶"
	continue_icon_label.add_theme_font_size_override("font_size", 16)
	continue_icon_label.add_theme_color_override("font_color", Color(0.98, 0.82, 0.45, 1.0))
	prompt_row.add_child(continue_icon_label)

# 실행: apply one narrative read model without reallocating the story tree.
func render(model: Dictionary) -> void:
	ensure_built()
	if not bool(model.get("visible", false)):
		visible = false
		return
	var beat_id := str(model.get("beatId", ""))
	if beat_id != _current_beat_id:
		_current_beat_id = beat_id
		_dismissed_beat_id = ""
	if not beat_id.is_empty() and beat_id == _dismissed_beat_id:
		visible = false
		return
	var speaker := str(model.get("speaker", "")).strip_edges()
	var body := str(model.get("text", "")).strip_edges()
	_skip_input_allowed = bool(model.get("skipInputAllowed", true))
	_portrait_side = str(model.get("portraitSide", "none"))
	speaker_label.text = speaker
	speaker_label.visible = not speaker.is_empty()
	body_label.text = body
	continue_prompt_label.text = str(model.get("continuePrompt", "진행하려면 클릭해주세요"))
	continue_icon_label.text = str(model.get("continueIcon", "▶"))
	continue_prompt_label.visible = _skip_input_allowed
	continue_icon_label.visible = _skip_input_allowed
	_apply_visuals(str(model.get("visualPath", "")), str(model.get("portraitPath", "")), _portrait_side)
	visible = not body.is_empty()

# 실행: consume click, keyboard, or pad input as a request to dismiss the current beat.
func consume_continue_input(event: InputEvent) -> bool:
	if not visible or not _skip_input_allowed:
		return false
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			dismiss()
			return true
		return false
	if event is InputEventKey:
		if event.pressed and not event.echo:
			dismiss()
			return true
		return false
	if event is InputEventJoypadButton:
		if event.pressed:
			dismiss()
			return true
	return false

# 실행: hide the current beat locally so repeated renders do not reopen it.
func dismiss() -> void:
	if not visible:
		return
	_dismissed_beat_id = _current_beat_id
	visible = false
	continue_requested.emit(_current_beat_id)

# 실행: route direct panel clicks through the shared continue-input path.
func _gui_input(event: InputEvent) -> void:
	if consume_continue_input(event):
		accept_event()

static func _visual_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.08, 0.09, 0.88)
	style.border_color = Color(0.45, 0.62, 0.66, 0.42)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	return style

static func _dialog_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.07, 0.08, 0.09, 0.96)
	style.border_color = Color(0.62, 0.74, 0.72, 0.56)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	return style

# 실행: load optional visual and portrait textures for the enhanced toast surface.
func _apply_visuals(visual_path: String, portrait_path: String, portrait_side: String) -> void:
	if visual_image != null:
		visual_image.texture = LTLThemeScript.art_texture(visual_path) if not visual_path.is_empty() else null
		visual_image.visible = visual_image.texture != null
	if portrait_image != null:
		portrait_image.texture = LTLThemeScript.art_texture(portrait_path) if not portrait_path.is_empty() else null
		portrait_image.visible = portrait_image.texture != null and portrait_side in ["left", "right"]
		call_deferred("_layout_portrait_image")

# 실행: position the optional portrait inside the upper visual area.
func _layout_portrait_image() -> void:
	if portrait_image == null or visual_area == null or not portrait_image.visible:
		return
	var area_size := visual_area.size
	var portrait_width := clampf(area_size.x * 0.32, 120.0, 240.0)
	var portrait_height := maxf(120.0, area_size.y - 18.0)
	var x := 14.0 if _portrait_side == "left" else area_size.x - portrait_width - 14.0
	portrait_image.position = Vector2(x, 9.0)
	portrait_image.size = Vector2(portrait_width, portrait_height)
