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
signal interaction_sfx_requested(category: String)

const LTLThemeScript = preload("res://src/ui/theme/LTLTheme.gd")
const ToastRedesignThemeScript = preload("res://src/ui/theme/ToastRedesignTheme.gd")
const TYPEWRITER_CHARS_PER_SECOND := 36.0

var speaker_label: Label = null
var body_label: Label = null
var continue_prompt_label: Label = null
var continue_icon_label: Label = null
var visual_area: PanelContainer = null
var visual_image: TextureRect = null
var portrait_image: TextureRect = null
# 실행: 토스트 리디자인 — 코너 밴드용 화자 원형 배지.
var speaker_badge: TextureRect = null

var _current_beat_id := ""
var _dismissed_beat_id := ""
var _skip_input_allowed := true
var _portrait_side := "none"
var _typewriter_key := ""
var _typewriter_text := ""
var _typewriter_visible_chars := 0
var _typewriter_accumulator := 0.0

# 실행: initialize the hidden story surface as a clickable continue target.
func _init() -> void:
	name = "NarrativeToast"
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	# 계약: z_index는 소유자(MainViewChromeRuntime)가 토스트 레이어 정책으로 덮어쓴다.
	z_index = ToastRedesignThemeScript.toast_z_index(440)
	custom_minimum_size = ToastRedesignThemeScript.NARRATIVE_TOAST_SIZE
	set_process(false)

# 실행: build the stable child tree once the control enters the scene.
func _ready() -> void:
	ensure_built()

# 계약: 코너 밴드(436×112) 안에 화자 배지 + 대사 + 진행 힌트를 가로로 배치한다.
# - VisualArea/PortraitImage는 read-model 계약(visualPath/portraitPath) 유지를 위해 트리에 남기되
#   코너 밴드에는 150px 이미지 영역이 들어갈 수 없으므로 기본 숨김이며 화자 배지가 그 역할을 대신한다.
# 실행: create the visual area, dialogue panel, and continue prompt nodes.
func ensure_built() -> void:
	if get_node_or_null("StoryFrame") != null:
		return
	add_theme_stylebox_override("panel", ToastRedesignThemeScript.narrative_toast_style())

	var story_frame := HBoxContainer.new()
	story_frame.name = "StoryFrame"
	story_frame.mouse_filter = Control.MOUSE_FILTER_PASS
	story_frame.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	story_frame.size_flags_vertical = Control.SIZE_EXPAND_FILL
	story_frame.add_theme_constant_override("separation", 14)
	add_child(story_frame)

	var frame_margin := MarginContainer.new()
	frame_margin.name = "FrameMargin"
	frame_margin.mouse_filter = Control.MOUSE_FILTER_PASS
	frame_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	frame_margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	frame_margin.add_theme_constant_override("margin_left", 22)
	frame_margin.add_theme_constant_override("margin_top", 14)
	frame_margin.add_theme_constant_override("margin_right", 20)
	frame_margin.add_theme_constant_override("margin_bottom", 14)
	story_frame.add_child(frame_margin)

	var content_row := HBoxContainer.new()
	content_row.name = "ContentRow"
	content_row.mouse_filter = Control.MOUSE_FILTER_PASS
	content_row.add_theme_constant_override("separation", 14)
	frame_margin.add_child(content_row)

	# 실행: 화자 배지 — 가시 원 외곽(알파 경계)이 40px 슬롯과 맞도록 렌더 사각형을 역보정한다.
	var badge_slot := Control.new()
	badge_slot.name = "SpeakerBadgeSlot"
	badge_slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge_slot.custom_minimum_size = Vector2(40.0, 40.0)
	badge_slot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	content_row.add_child(badge_slot)

	speaker_badge = TextureRect.new()
	speaker_badge.name = "SpeakerBadge"
	speaker_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	speaker_badge.texture = ToastRedesignThemeScript.BadgeSpeakerTexture
	speaker_badge.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	speaker_badge.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
	var badge_rect: Rect2 = ToastRedesignThemeScript.badge_visual_rect(speaker_badge.texture, 40.0)
	speaker_badge.position = badge_rect.position
	speaker_badge.size = badge_rect.size
	badge_slot.add_child(speaker_badge)

	var dialog_box := VBoxContainer.new()
	dialog_box.name = "DialogBox"
	dialog_box.mouse_filter = Control.MOUSE_FILTER_PASS
	dialog_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dialog_box.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	dialog_box.add_theme_constant_override("separation", 4)
	content_row.add_child(dialog_box)

	# 실행: 화자 칩 — 림스톤 pill(정원 radius).
	var speaker_row := HBoxContainer.new()
	speaker_row.name = "SpeakerRow"
	speaker_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dialog_box.add_child(speaker_row)

	var speaker_chip := PanelContainer.new()
	speaker_chip.name = "SpeakerChip"
	speaker_chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	speaker_chip.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	speaker_chip.add_theme_stylebox_override("panel", ToastRedesignThemeScript.speaker_chip_style())
	speaker_row.add_child(speaker_chip)

	speaker_label = Label.new()
	speaker_label.name = "SpeakerLabel"
	speaker_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	speaker_label.text = ""
	speaker_label.add_theme_font_size_override("font_size", 10)
	speaker_label.add_theme_color_override("font_color", ToastRedesignThemeScript.PRIMARY)
	speaker_chip.add_child(speaker_label)

	body_label = Label.new()
	body_label.name = "BodyLabel"
	body_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body_label.text = ""
	body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body_label.add_theme_font_size_override("font_size", 15)
	body_label.add_theme_color_override("font_color", ToastRedesignThemeScript.SOIL)
	dialog_box.add_child(body_label)

	var prompt_row := HBoxContainer.new()
	prompt_row.name = "PromptRow"
	prompt_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	prompt_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	prompt_row.add_theme_constant_override("separation", 5)
	dialog_box.add_child(prompt_row)

	continue_prompt_label = Label.new()
	continue_prompt_label.name = "ContinuePrompt"
	continue_prompt_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	continue_prompt_label.text = ""
	continue_prompt_label.add_theme_font_size_override("font_size", 11)
	continue_prompt_label.add_theme_color_override("font_color", ToastRedesignThemeScript.SECONDARY)
	prompt_row.add_child(continue_prompt_label)

	continue_icon_label = Label.new()
	continue_icon_label.name = "ContinueIcon"
	continue_icon_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	continue_icon_label.text = "▶"
	continue_icon_label.add_theme_font_size_override("font_size", 12)
	continue_icon_label.add_theme_color_override("font_color", ToastRedesignThemeScript.CARET)
	prompt_row.add_child(continue_icon_label)

	# 계약: visualPath/portraitPath read-model 계약 유지용 노드 — 코너 밴드에서는 표시하지 않는다.
	visual_area = PanelContainer.new()
	visual_area.name = "VisualArea"
	visual_area.mouse_filter = Control.MOUSE_FILTER_IGNORE
	visual_area.visible = false
	add_child(visual_area)

	visual_image = TextureRect.new()
	visual_image.name = "VisualImage"
	visual_image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	visual_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	visual_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	visual_image.visible = false
	visual_area.add_child(visual_image)

	portrait_image = TextureRect.new()
	portrait_image.name = "PortraitImage"
	portrait_image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	portrait_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
	portrait_image.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	portrait_image.visible = false
	visual_area.add_child(portrait_image)

# 실행: apply one narrative read model without reallocating the story tree.
func render(model: Dictionary) -> void:
	ensure_built()
	if not bool(model.get("visible", false)):
		visible = false
		set_process(false)
		return
	var beat_id := str(model.get("beatId", ""))
	if beat_id != _current_beat_id:
		_current_beat_id = beat_id
		_dismissed_beat_id = ""
	if not beat_id.is_empty() and beat_id == _dismissed_beat_id:
		visible = false
		set_process(false)
		return
	var speaker := str(model.get("speaker", "")).strip_edges()
	var body := str(model.get("text", "")).strip_edges()
	_skip_input_allowed = bool(model.get("skipInputAllowed", true))
	_portrait_side = str(model.get("portraitSide", "none"))
	speaker_label.text = speaker
	speaker_label.visible = not speaker.is_empty()
	body_label.text = body
	var next_typewriter_key := "%s|%s" % [beat_id, body]
	if next_typewriter_key != _typewriter_key:
		_start_typewriter(next_typewriter_key, body)
	continue_prompt_label.text = str(model.get("continuePrompt", "진행하려면 클릭해주세요"))
	continue_icon_label.text = str(model.get("continueIcon", "▶"))
	continue_prompt_label.visible = _skip_input_allowed
	continue_icon_label.visible = _skip_input_allowed
	_apply_visuals(str(model.get("visualPath", "")), str(model.get("portraitPath", "")), _portrait_side)
	visible = not body.is_empty()
	set_process(visible)

# 실행: consume click, keyboard, or pad input as a request to dismiss the current beat.
func consume_continue_input(event: InputEvent) -> bool:
	if not visible or not _skip_input_allowed:
		return false
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			_handle_continue_input()
			return true
		return false
	if event is InputEventKey:
		if event.pressed and not event.echo:
			_handle_continue_input()
			return true
		return false
	if event is InputEventJoypadButton:
		if event.pressed:
			_handle_continue_input()
			return true
	return false

# 실행: hide the current beat locally so repeated renders do not reopen it.
func dismiss(play_sound: bool = true) -> void:
	if not visible:
		return
	if play_sound:
		interaction_sfx_requested.emit("dialogue_advance")
	_dismissed_beat_id = _current_beat_id
	visible = false
	set_process(false)
	continue_requested.emit(_current_beat_id)

# 실행: route direct panel clicks through the shared continue-input path.
func _process(delta: float) -> void:
	_advance_typewriter(delta)

func advance_typewriter_for_test(delta: float) -> void:
	_advance_typewriter(delta)

func _start_typewriter(key: String, text: String) -> void:
	_typewriter_key = key
	_typewriter_text = text
	_typewriter_visible_chars = 0
	_typewriter_accumulator = 0.0
	if body_label != null:
		body_label.visible_characters = 0

func _advance_typewriter(delta: float) -> void:
	if not visible or body_label == null or _typewriter_text.is_empty() or _typewriter_visible_chars >= _typewriter_text.length():
		return
	_typewriter_accumulator += maxf(0.0, delta) * TYPEWRITER_CHARS_PER_SECOND
	var target := mini(_typewriter_text.length(), int(floor(_typewriter_accumulator)))
	if target <= _typewriter_visible_chars:
		return
	for char_index in range(_typewriter_visible_chars, target):
		if not _typewriter_text.substr(char_index, 1).strip_edges().is_empty():
			interaction_sfx_requested.emit("typewriter_tick")
	_typewriter_visible_chars = target
	body_label.visible_characters = _typewriter_visible_chars

func _complete_typewriter() -> void:
	_typewriter_visible_chars = _typewriter_text.length()
	_typewriter_accumulator = float(_typewriter_visible_chars)
	if body_label != null:
		body_label.visible_characters = _typewriter_visible_chars

func _typewriter_complete() -> bool:
	return _typewriter_text.is_empty() or _typewriter_visible_chars >= _typewriter_text.length()

func _handle_continue_input() -> void:
	interaction_sfx_requested.emit("dialogue_advance")
	if not _typewriter_complete():
		_complete_typewriter()
		return
	dismiss(false)

func _gui_input(event: InputEvent) -> void:
	if consume_continue_input(event):
		accept_event()

# 계약: visualPath/portraitPath 계약은 유지하되 코너 밴드에서는 표면을 표시하지 않는다.
# - 근거: 436×112 코너 밴드에 150px 비주얼 영역을 넣으면 페이지 비침범 규칙이 깨진다.
# - 텍스처는 계속 로드해 read-model 계약(경로 유효성)을 지키고, 화자 배지가 시각 역할을 대신한다.
# 실행: load optional visual and portrait textures for the enhanced toast surface.
func _apply_visuals(visual_path: String, portrait_path: String, portrait_side: String) -> void:
	if visual_image != null:
		visual_image.texture = LTLThemeScript.art_texture(visual_path) if not visual_path.is_empty() else null
		visual_image.visible = false
	if portrait_image != null:
		portrait_image.texture = LTLThemeScript.art_texture(portrait_path) if not portrait_path.is_empty() else null
		portrait_image.visible = false
	if visual_area != null:
		visual_area.visible = false
	_portrait_side = portrait_side

# 계약: 기존 호출자를 위한 no-op 방어 — 코너 밴드에서는 초상 배치가 없다.
# 실행: position the optional portrait inside the upper visual area.
func _layout_portrait_image() -> void:
	if portrait_image == null or visual_area == null or not portrait_image.visible:
		return
