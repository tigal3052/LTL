# 계약: StorySceneFrame renders the shared story-screen shell while StoryScenePage owns flow control.
# 수행: define reusable story-frame visuals with minimal top chrome and stable portrait/dialogue layout.
class_name StorySceneFrame
extends Control

const LTLThemeScript = preload("res://src/ui/theme/LTLTheme.gd")
const StorySceneFrameBitsScript = preload("res://src/scenes/pages/story_scene/StorySceneFrameBits.gd")

const PORTRAIT_BASE_SIZE := Vector2(420.0, 560.0)
const PORTRAIT_BOTTOM_MARGIN := 158.0
const PORTRAIT_SIDE_MARGIN := 30.0

@onready var backdrop: ColorRect = $Backdrop
@onready var background_art: TextureRect = $BackgroundArt
@onready var atmosphere_scrim: ColorRect = $AtmosphereScrim
@onready var top_chrome: Control = $TopChrome
@onready var chrome_title_label: Label = $TopChrome/ChromeFrame/ChromeMargin/ChromeTitleLabel
@onready var left_portrait: TextureRect = $PortraitLayer/LeftPortrait
@onready var right_portrait: TextureRect = $PortraitLayer/RightPortrait
@onready var speaker_tag: PanelContainer = $DialogueDock/SpeakerTag
@onready var speaker_name_label: Label = $DialogueDock/SpeakerTag/SpeakerTagMargin/SpeakerNameLabel
@onready var dialogue_panel: PanelContainer = $DialogueDock/DialoguePanel
@onready var body_label: Label = $DialogueDock/DialoguePanel/DialogueMargin/DialogueBox/BodyLabel
@onready var progress_label: Label = $DialogueDock/DialoguePanel/DialogueMargin/DialogueBox/ButtonRow/ProgressLabel
@onready var continue_button: Button = $DialogueDock/DialoguePanel/DialogueMargin/DialogueBox/ButtonRow/ContinueButton
@onready var skip_button: Button = $DialogueDock/DialoguePanel/DialogueMargin/DialogueBox/ButtonRow/SkipButton

var _active_frame := StorySceneFrameBitsScript.DEFAULT_FRAME.duplicate(true)

func _ready() -> void:
	theme = LTLThemeScript.shared_theme()
	_apply_theme()
	apply_model({})

# 수행: apply one projected story step to the reusable story-frame shell.
func apply_model(model: Dictionary) -> void:
	_active_frame = StorySceneFrameBitsScript.project_frame(
		model.get("frame", {}),
		{},
		str(model.get("speaker", ""))
	)
	backdrop.color = Color(0.02, 0.04, 0.05, 1.0)
	var background_path := str(model.get("backgroundPath", ""))
	background_art.texture = LTLThemeScript.art_texture(background_path) if not background_path.is_empty() else null
	atmosphere_scrim.color = Color(0.07, 0.11, 0.09, clampf(float(_active_frame.get("scrimOpacity", 0.42)), 0.0, 0.85))
	_apply_top_chrome(model)
	_apply_dialogue(model)
	_apply_portraits(model)

func _apply_top_chrome(model: Dictionary) -> void:
	var chrome_mode := str(_active_frame.get("chromeMode", "minimal"))
	top_chrome.visible = chrome_mode != "minimal"
	chrome_title_label.text = str(_active_frame.get("chromeTitle", model.get("sceneId", "")))

func _apply_dialogue(model: Dictionary) -> void:
	var step_index := int(model.get("stepIndex", 0))
	var step_count := maxi(1, int(model.get("stepCount", 1)))
	speaker_name_label.text = str(_active_frame.get("speakerTagText", model.get("speaker", "")))
	body_label.text = str(model.get("text", ""))
	progress_label.text = "%d / %d" % [step_index + 1, step_count]
	continue_button.text = str(model.get("continueText", "Continue"))
	skip_button.text = str(model.get("skipText", "Skip"))

func _apply_portraits(model: Dictionary) -> void:
	var portrait_path := str(model.get("portraitPath", ""))
	var portrait_texture := LTLThemeScript.art_texture(portrait_path) if not portrait_path.is_empty() else null
	var side := str(model.get("side", "left"))
	var portrait_scale := clampf(float(_active_frame.get("portraitScale", 1.0)), 0.70, 1.20)
	var offset_x := float(_active_frame.get("portraitOffsetX", 0.0))
	var offset_y := float(_active_frame.get("portraitOffsetY", 0.0))
	left_portrait.texture = portrait_texture if side == "left" else null
	right_portrait.texture = portrait_texture if side == "right" else null
	left_portrait.visible = side == "left" and portrait_texture != null
	right_portrait.visible = side == "right" and portrait_texture != null
	_set_portrait_layout(left_portrait, true, portrait_scale, offset_x, offset_y)
	_set_portrait_layout(right_portrait, false, portrait_scale, offset_x, offset_y)

func _set_portrait_layout(portrait: TextureRect, is_left: bool, portrait_scale: float, offset_x: float, offset_y: float) -> void:
	var portrait_size := PORTRAIT_BASE_SIZE * portrait_scale
	var bottom_offset := -PORTRAIT_BOTTOM_MARGIN + offset_y
	var top_offset := bottom_offset - portrait_size.y
	if is_left:
		portrait.anchor_left = 0.0
		portrait.anchor_right = 0.0
		portrait.offset_left = PORTRAIT_SIDE_MARGIN + offset_x
		portrait.offset_right = PORTRAIT_SIDE_MARGIN + offset_x + portrait_size.x
	else:
		portrait.anchor_left = 1.0
		portrait.anchor_right = 1.0
		portrait.offset_left = -PORTRAIT_SIDE_MARGIN - offset_x - portrait_size.x
		portrait.offset_right = -PORTRAIT_SIDE_MARGIN - offset_x
	portrait.anchor_top = 1.0
	portrait.anchor_bottom = 1.0
	portrait.offset_top = top_offset
	portrait.offset_bottom = bottom_offset

func _apply_theme() -> void:
	background_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background_art.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	var portrait_modulate := Color(0.98, 0.99, 0.97, 0.98)
	for portrait in [left_portrait, right_portrait]:
		portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
		portrait.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		portrait.self_modulate = portrait_modulate
	var chrome_style := LTLThemeScript.surface_style(Color(0.95, 0.93, 0.84, 0.70), Color(0.34, 0.48, 0.36, 0.52), 14, 1, 0.16)
	$TopChrome/ChromeFrame.add_theme_stylebox_override("panel", chrome_style)
	chrome_title_label.add_theme_font_size_override("font_size", 15)
	chrome_title_label.add_theme_color_override("font_color", Color(0.20, 0.28, 0.21, 0.92))
	speaker_tag.add_theme_stylebox_override("panel", LTLThemeScript.surface_style(Color(0.86, 0.81, 0.66, 0.96), Color(0.35, 0.45, 0.28, 0.82), 10, 2, 0.18))
	speaker_name_label.add_theme_font_size_override("font_size", 16)
	speaker_name_label.add_theme_color_override("font_color", Color(0.24, 0.20, 0.14, 1.0))
	dialogue_panel.add_theme_stylebox_override("panel", LTLThemeScript.surface_style(Color(0.95, 0.94, 0.86, 0.94), Color(0.35, 0.46, 0.33, 0.78), 18, 1, 0.24))
	body_label.add_theme_font_size_override("font_size", 22)
	body_label.add_theme_color_override("font_color", Color(0.18, 0.22, 0.19, 1.0))
	body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	progress_label.add_theme_font_size_override("font_size", 15)
	progress_label.add_theme_color_override("font_color", Color(0.33, 0.39, 0.29, 0.84))
	_apply_button_theme(skip_button, Color(0.86, 0.82, 0.70, 0.96), Color(0.40, 0.48, 0.33, 0.78), Color(0.21, 0.24, 0.18, 1.0))
	_apply_button_theme(continue_button, Color(0.30, 0.47, 0.27, 0.98), Color(0.22, 0.33, 0.20, 0.90), Color(0.96, 0.98, 0.92, 1.0))

func _apply_button_theme(button: Button, background: Color, border: Color, font_color: Color) -> void:
	var normal := LTLThemeScript.surface_style(background, border, 10, 1, 0.12)
	var hover := LTLThemeScript.surface_style(background.lightened(0.05), border, 10, 1, 0.14)
	var pressed := LTLThemeScript.surface_style(background.darkened(0.08), border, 10, 1, 0.10)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("focus", hover)
	button.add_theme_color_override("font_color", font_color)
	button.add_theme_color_override("font_hover_color", font_color)
	button.add_theme_color_override("font_pressed_color", font_color)
	button.add_theme_font_size_override("font_size", 16)
