# 계약: StoryScenePage renders one VN story step and emits continue/skip requests without changing game state.
# 실행: define the story-scene flow controller on top of the reusable shared frame.
extends Control

signal continue_requested(scene_id: String)
signal skip_requested(scene_id: String)
signal interaction_sfx_requested(category: String)

const InteractionFXScript = preload("res://src/ui/InteractionFX.gd")
const TYPEWRITER_CHARS_PER_SECOND := 36.0

@onready var story_frame = $StoryFrame
@onready var body_label: Label = $StoryFrame/DialogueDock/DialoguePanel/DialogueMargin/DialogueBox/BodyLabel
@onready var continue_button: Button = $StoryFrame/DialogueDock/DialoguePanel/DialogueMargin/DialogueBox/ButtonRow/ContinueButton
@onready var skip_button: Button = $StoryFrame/DialogueDock/DialoguePanel/DialogueMargin/DialogueBox/ButtonRow/SkipButton

var _scene_id := ""
var _typewriter_key := ""
var _typewriter_text := ""
var _typewriter_visible_chars := 0
var _typewriter_accumulator := 0.0

# 실행: connect page controls while leaving visuals to the shared story-frame component.
func _ready() -> void:
	continue_button.set_meta(InteractionFXScript.META_SKIP, true)
	skip_button.set_meta(InteractionFXScript.META_SKIP, true)
	continue_button.pressed.connect(_handle_continue_pressed)
	skip_button.pressed.connect(_handle_skip_pressed)
	apply_state({})

# 실행: render one projected story-scene model into the shared frame shell.
func apply_state(state: Dictionary) -> void:
	var model: Dictionary = state.get("storyScene", state) if state.get("storyScene", state) is Dictionary else {}
	if not bool(model.get("visible", false)):
		visible = false
		set_process(false)
		story_frame.apply_model({})
		return
	visible = true
	set_process(true)
	_scene_id = str(model.get("sceneId", ""))
	story_frame.apply_model(model)
	var body_text := str(model.get("text", ""))
	var step_index := int(model.get("stepIndex", 0))
	var next_typewriter_key := "%s|%d|%s" % [_scene_id, step_index, body_text]
	if next_typewriter_key != _typewriter_key:
		_start_typewriter(next_typewriter_key, body_text)
	else:
		body_label.text = body_text

func _process(delta: float) -> void:
	_advance_typewriter(delta)

# 실행: let keyboard confirmation progress or skip the current VN step.
func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			_handle_skip_pressed()
		else:
			_handle_continue_pressed()
		get_viewport().set_input_as_handled()

# 실행: expose deterministic typewriter advancement for runtime contract tests.
func advance_typewriter_for_test(delta: float) -> void:
	_advance_typewriter(delta)

func _start_typewriter(key: String, text: String) -> void:
	_typewriter_key = key
	_typewriter_text = text
	_typewriter_visible_chars = 0
	_typewriter_accumulator = 0.0
	body_label.text = text
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
