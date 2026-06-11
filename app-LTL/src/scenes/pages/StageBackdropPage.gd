extends Control

const LTLThemeScript = preload("res://src/ui/theme/LTLTheme.gd")

@export var default_kicker := ""
@export var default_title := ""
@export_multiline var default_subtitle := ""
@export var default_badge := ""
@export var default_art_path := ""

@onready var backdrop: ColorRect = $Backdrop
@onready var hero_art: TextureRect = $HeroArt
@onready var badge_label: Label = $Margin/Shell/Margin/VStack/BadgeLabel
@onready var kicker_label: Label = $Margin/Shell/Margin/VStack/KickerLabel
@onready var title_label: Label = $Margin/Shell/Margin/VStack/TitleLabel
@onready var subtitle_label: RichTextLabel = $Margin/Shell/Margin/VStack/SubtitleLabel

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_apply({
		"pageBadge": default_badge,
		"pageKicker": default_kicker,
		"pageTitle": default_title,
		"pageSubtitle": default_subtitle,
		"pageHeroPath": default_art_path
	})

func apply_state(state: Dictionary) -> void:
	_apply(state)

func _apply(state: Dictionary) -> void:
	if badge_label != null:
		var badge_text := str(state.get("pageBadge", default_badge))
		badge_label.text = badge_text
		badge_label.visible = not badge_text.is_empty()
	if kicker_label != null:
		kicker_label.text = str(state.get("pageKicker", default_kicker))
	if title_label != null:
		title_label.text = str(state.get("pageTitle", default_title))
	if subtitle_label != null:
		subtitle_label.text = str(state.get("pageSubtitle", default_subtitle))
	if hero_art != null:
		var art_path := str(state.get("pageHeroPath", default_art_path))
		hero_art.texture = LTLThemeScript.art_texture(art_path) if not art_path.is_empty() else null
	if backdrop != null:
		var tint: Color = state.get("pageTint", Color(0.05, 0.07, 0.10, 0.92))
		backdrop.color = tint
