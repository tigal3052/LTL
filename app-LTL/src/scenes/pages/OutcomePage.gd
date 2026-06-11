extends Control

const LTLThemeScript = preload("res://src/ui/theme/LTLTheme.gd")

signal return_requested

@export var default_title := ""
@export_multiline var default_description := ""
@export var default_button_text := ""
@export var default_art_path := ""

@onready var hero_art: TextureRect = $HeroArt
@onready var title_label: Label = $Margin/Shell/Margin/VStack/TitleLabel
@onready var description_label: Label = $Margin/Shell/Margin/VStack/DescriptionLabel
@onready var return_button: Button = $Margin/Shell/Margin/VStack/ReturnButton

func _ready() -> void:
	return_button.pressed.connect(func() -> void: return_requested.emit())
	_apply({})

func apply_state(state: Dictionary) -> void:
	_apply(state)

func _apply(state: Dictionary) -> void:
	title_label.text = str(state.get("pageTitle", default_title))
	description_label.text = str(state.get("pageSubtitle", default_description))
	return_button.text = str(state.get("pageButtonText", default_button_text))
	var art_path := str(state.get("pageHeroPath", default_art_path))
	hero_art.texture = LTLThemeScript.art_texture(art_path) if not art_path.is_empty() else null
