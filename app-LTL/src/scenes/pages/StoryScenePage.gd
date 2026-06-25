# 계약: StoryScenePage renders one VN story step and emits continue/skip requests without changing game state.
# 실행: define the Full VN story page control.
extends Control

signal continue_requested(scene_id: String)
signal skip_requested(scene_id: String)
signal interaction_sfx_requested(category: String)

const LTLThemeScript = preload("res://src/ui/theme/LTLTheme.gd")
const InteractionFXScript = preload("res://src/ui/InteractionFX.gd")
const TYPEWRITER_CHARS_PER_SECOND := 36.0

@onready var backdrop: ColorRect = $Backdrop
@onready var background_art: TextureRect = $BackgroundArt
@onready var left_portrait: TextureRect = $CharacterLayer/LeftPortrait
@onready var right_portrait: TextureRect = $CharacterLayer/RightPortrait
@onready var dialogue_panel: PanelContainer = $DialoguePanel
@onready var speaker_label: Label = $DialoguePanel/DialogueMargin/DialogueBox/SpeakerLabel
@onready var body_label: Label = $DialoguePanel/DialogueMargin/DialogueBox/BodyLabel
@onready var progress_label: Label = $DialoguePanel/DialogueMargin/DialogueBox/ButtonRow/ProgressLabel
@onready var continue_button: Button = $DialoguePanel/DialogueMargin/DialogueBox/ButtonRow/ContinueButton
@onready var skip_button: Button = $DialoguePanel/DialogueMargin/DialogueBox/ButtonRow/SkipButton

var _scene_id := ""
var _typewriter_key := ""
var _typewriter_text := ""
var _typewriter_visible_chars := 0
var _typewriter_accumulator := 0.0

# 실행: connect page controls and apply stable visual styling.
func _ready() -> void:
	continue_button.set_meta(InteractionFXScript.META_SKIP, true)
	skip_button.set_meta(InteractionFXScript.META_SKIP, true)
	continue_button.pressed.connect(_handle_continue_pressed)
	skip_button.pressed.connect(_handle_skip_pressed)
	_apply_theme()
	apply_state({})

# 실행: render a projected story scene model.
func apply_state(state: Dictionary) -> void:
	var model: Dictionary = state.get("storyScene", state) if state.get("storyScene", state) is Dictionary else {}
	if not bool(model.get("visible", false)):
		visible = false
		set_process(false)
		return
	visible = true
	set_process(true)
	_scene_id = str(model.get("sceneId", ""))
	var background_path := str(model.get("backgroundPath", ""))
	background_art.texture = LTLThemeScript.art_texture(background_path) if not background_path.is_empty() else null
	var portrait_path := str(model.get("portraitPath", ""))
	var portrait_texture := LTLThemeScript.art_texture(portrait_path) if not portrait_path.is_empty() else null
	var side := str(model.get("side", "left"))
	left_portrait.texture = portrait_texture if side == "left" else null
	left_portrait.visible = side == "left" and portrait_texture != null
	right_portrait.texture = portrait_texture if side == "right" else null
	right_portrait.visible = side == "right" and portrait_texture != null
	speaker_label.text = str(model.get("speaker", ""))
	var body_text := str(model.get("text", ""))
	var step_index := int(model.get("stepIndex", 0))
	body_label.text = body_text
	var next_typewriter_key := "%s|%d|%s" % [_scene_id, step_index, body_text]
	if next_typewriter_key != _typewriter_key:
		_start_typewriter(next_typewriter_key, body_text)
	progress_label.text = "%d / %d" % [step_index + 1, maxi(1, int(model.get("stepCount", 1)))]
	continue_button.text = str(model.get("continueText", "Continue"))
	skip_button.text = str(model.get("skipText", "Skip"))

func _process(delta: float) -> void:
	_advance_typewriter(delta)

# 실행: let keyboard confirmation progress the current VN step.
func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			_handle_skip_pressed()
		else:
			_handle_continue_pressed()
		get_viewport().set_input_as_handled()

# 실행: apply the project visual language to the VN page.
func advance_typewriter_for_test(delta: float) -> void:
	_advance_typewriter(delta)

func _start_typewriter(key: String, text: String) -> void:
	_typewriter_key = key
	_typewriter_text = text
	_typewriter_visible_chars = 0
	_typewriter_accumulator = 0.0
	body_label.visible_characters = 0

func _advance_typewriter(delta: float) -> void:
	if not visible or _typewriter_text.is_empty() or _typewriter_visible_chars >= _typewriter_text.length():
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
	body_label.visible_characters = _typewriter_visible_chars

func _typewriter_complete() -> bool:
	return _typewriter_text.is_empty() or _typewriter_visible_chars >= _typewriter_text.length()

func _handle_continue_pressed() -> void:
	interaction_sfx_requested.emit("dialogue_advance")
	if not _typewriter_complete():
		_complete_typewriter()
		return
	continue_requested.emit(_scene_id)

func _handle_skip_pressed() -> void:
	interaction_sfx_requested.emit("ui_cancel")
	skip_requested.emit(_scene_id)

func _apply_theme() -> void:
	backdrop.color = Color(0.03, 0.04, 0.06, 1.0)
	background_art.self_modulate = Color(0.78, 0.82, 0.88, 0.34)
	for portrait in [left_portrait, right_portrait]:
		portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
		portrait.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	dialogue_panel.add_theme_stylebox_override("panel", LTLThemeScript.surface_style(Color(0.05, 0.06, 0.08, 0.96), Color(0.70, 0.82, 0.78, 0.72), 8, 1, 0.24))
	speaker_label.add_theme_font_size_override("font_size", 15)
	body_label.add_theme_font_size_override("font_size", 21)
	body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	progress_label.add_theme_color_override("font_color", Color(0.74, 0.78, 0.76, 0.86))
