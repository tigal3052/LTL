extends Control

const LTLThemeScript = preload("res://src/ui/theme/LTLTheme.gd")
const DEFAULT_STAGE_BACKDROP_PATH := "res://resources/charactor/background.png"
const DEFAULT_CHARACTER_ART_PATH := "res://resources/charactor/charactor1.png"

signal return_requested

@export var default_eyebrow := ""
@export var default_title := ""
@export_multiline var default_subtitle := ""
@export var default_board_title := ""
@export_multiline var default_board_hint := ""
@export_multiline var default_cause := ""
@export_multiline var default_tip := ""
@export var default_button_text := ""
@export var default_art_path := ""
@export var default_character_art_path := DEFAULT_CHARACTER_ART_PATH
@export var default_stage_backdrop_path := DEFAULT_STAGE_BACKDROP_PATH

@onready var page_backdrop: TextureRect = $PageBackdrop
@onready var eyebrow_label: Label = $Margin/VStack/HeroSection/Eyebrow
@onready var hero_title_label: Label = $Margin/VStack/HeroSection/HeroTitle
@onready var hero_subtitle_label: Label = $Margin/VStack/HeroSection/HeroSubtitle
@onready var board_shell: PanelContainer = $Margin/VStack/BoardShell
@onready var board_head: HBoxContainer = $Margin/VStack/BoardShell/ShellMargin/ShellVBox/BoardHead
@onready var board_title_label: Label = $Margin/VStack/BoardShell/ShellMargin/ShellVBox/BoardHead/BoardTitle
@onready var board_hint_label: Label = $Margin/VStack/BoardShell/ShellMargin/ShellVBox/BoardHead/BoardHint
@onready var hero_frame: PanelContainer = $Margin/VStack/BoardShell/ShellMargin/ShellVBox/BoardBody/HeroFrame
@onready var hero_stage_backdrop: TextureRect = $Margin/VStack/BoardShell/ShellMargin/ShellVBox/BoardBody/HeroFrame/HeroStageMargin/HeroStage/HeroStageBackdrop
@onready var hero_stage_character: TextureRect = $Margin/VStack/BoardShell/ShellMargin/ShellVBox/BoardBody/HeroFrame/HeroStageMargin/HeroStage/HeroStageCharacter
@onready var failure_cause_label: Label = $Margin/VStack/BoardShell/ShellMargin/ShellVBox/BoardBody/FailureCauseLabel
@onready var failure_tip_label: Label = $Margin/VStack/BoardShell/ShellMargin/ShellVBox/BoardBody/FailureTipLabel
@onready var retry_button: Button = $Margin/VStack/BoardShell/ShellMargin/ShellVBox/BoardBody/RetryButton

func _ready() -> void:
	retry_button.pressed.connect(func() -> void: return_requested.emit())
	_apply_theme()
	_apply({})

func apply_state(state: Dictionary) -> void:
	_apply(state)

func _apply(state: Dictionary) -> void:
	eyebrow_label.text = str(state.get("pageEyebrow", default_eyebrow))
	hero_title_label.text = str(state.get("pageTitle", default_title))
	hero_subtitle_label.text = str(state.get("pageSubtitle", default_subtitle))
	board_title_label.text = str(state.get("pageBoardTitle", default_board_title))
	board_hint_label.text = str(state.get("pageBoardHint", default_board_hint))
	failure_cause_label.text = str(state.get("pageCause", default_cause))
	failure_tip_label.text = str(state.get("pageTip", default_tip))
	retry_button.text = str(state.get("pageButtonText", default_button_text))

	hero_subtitle_label.visible = not hero_subtitle_label.text.is_empty()
	board_title_label.visible = not board_title_label.text.is_empty()
	board_hint_label.visible = not board_hint_label.text.is_empty()
	board_head.visible = board_title_label.visible or board_hint_label.visible

	var backdrop_path := str(state.get("pageHeroPath", default_art_path))
	page_backdrop.texture = LTLThemeScript.art_texture(backdrop_path) if not backdrop_path.is_empty() else null

	var stage_backdrop_path := str(state.get("pageStageBackdropPath", default_stage_backdrop_path))
	hero_stage_backdrop.texture = LTLThemeScript.art_texture(stage_backdrop_path) if not stage_backdrop_path.is_empty() else null

	var character_art_path := str(state.get("pageCharacterArtPath", default_character_art_path))
	hero_stage_character.texture = LTLThemeScript.art_texture(character_art_path) if not character_art_path.is_empty() else null

func _apply_theme() -> void:
	var board_style := LTLThemeScript.surface_style(Color(0.10, 0.06, 0.08, 0.90), Color(0.24, 0.16, 0.14, 0.96), 28, 1, 0.34)
	board_style.shadow_size = 30
	board_style.shadow_offset = Vector2(0.0, 14.0)
	board_style.shadow_color = Color(0.0, 0.0, 0.0, 0.44)
	board_shell.add_theme_stylebox_override("panel", board_style)

	var hero_frame_style := LTLThemeScript.surface_style(Color(0.09, 0.07, 0.08, 0.56), Color(1.0, 1.0, 1.0, 0.12), 24, 1, 0.12)
	hero_frame_style.draw_center = true
	hero_frame.add_theme_stylebox_override("panel", hero_frame_style)

	eyebrow_label.add_theme_font_size_override("font_size", 12)
	eyebrow_label.add_theme_color_override("font_color", Color(0.90, 0.56, 0.40, 0.98))

	hero_title_label.add_theme_font_size_override("font_size", 92)
	hero_title_label.add_theme_color_override("font_color", Color(0.98, 0.95, 0.95, 1.0))
	hero_title_label.add_theme_color_override("font_outline_color", Color(0.05, 0.03, 0.03, 0.66))
	hero_title_label.add_theme_constant_override("outline_size", 1)

	hero_subtitle_label.add_theme_font_size_override("font_size", 18)
	hero_subtitle_label.add_theme_color_override("font_color", Color(0.83, 0.72, 0.70, 0.96))

	board_title_label.add_theme_font_size_override("font_size", 22)
	board_title_label.add_theme_color_override("font_color", Color(0.98, 0.95, 0.93, 1.0))

	board_hint_label.add_theme_font_size_override("font_size", 14)
	board_hint_label.add_theme_color_override("font_color", Color(0.76, 0.63, 0.60, 0.92))

	failure_cause_label.add_theme_font_size_override("font_size", 17)
	failure_cause_label.add_theme_color_override("font_color", Color(0.92, 0.83, 0.80, 0.98))
	failure_tip_label.add_theme_font_size_override("font_size", 17)
	failure_tip_label.add_theme_color_override("font_color", Color(0.88, 0.76, 0.72, 0.92))

	page_backdrop.self_modulate = Color(1.0, 1.0, 1.0, 0.20)
	hero_stage_backdrop.self_modulate = Color(0.86, 0.88, 0.92, 0.58)
	hero_stage_character.self_modulate = Color(1.0, 1.0, 1.0, 0.96)

	retry_button.focus_mode = Control.FOCUS_NONE
	retry_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	retry_button.add_theme_stylebox_override("normal", _retry_button_style(Color(0.11, 0.08, 0.10, 0.98), Color(0.28, 0.21, 0.21, 0.94), Color(0.0, 0.0, 0.0, 0.34)))
	retry_button.add_theme_stylebox_override("hover", _retry_button_style(Color(0.14, 0.10, 0.12, 1.0), Color(0.98, 0.91, 0.91, 0.38), Color(0.0, 0.0, 0.0, 0.40)))
	retry_button.add_theme_stylebox_override("pressed", _retry_button_style(Color(0.08, 0.06, 0.07, 0.98), Color(0.44, 0.30, 0.28, 0.94), Color(0.0, 0.0, 0.0, 0.28)))
	retry_button.add_theme_stylebox_override("focus", _retry_button_style(Color(0.14, 0.10, 0.12, 1.0), Color(0.98, 0.91, 0.91, 0.38), Color(0.0, 0.0, 0.0, 0.40)))
	retry_button.add_theme_font_size_override("font_size", 22)
	retry_button.add_theme_color_override("font_color", Color(0.98, 0.95, 0.95, 1.0))

func _retry_button_style(bg_color: Color, border_color: Color, shadow_color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_color = border_color
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 18
	style.corner_radius_top_right = 18
	style.corner_radius_bottom_left = 18
	style.corner_radius_bottom_right = 18
	style.shadow_size = 18
	style.shadow_offset = Vector2(0.0, 8.0)
	style.shadow_color = shadow_color
	return style
