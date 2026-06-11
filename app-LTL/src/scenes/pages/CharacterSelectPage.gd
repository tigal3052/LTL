extends Control

const LTLThemeScript = preload("res://src/ui/theme/LTLTheme.gd")
const TextCatalogScript = preload("res://src/ui/TextCatalog.gd")
const ArtifactScript = preload("res://src/models/Artifact.gd")
const BACKDROP_PATH := "res://resources/charactor/background.png"

signal character_selected(character_id: String)
signal continue_requested
signal color_selected(color: String)
signal settings_requested

@onready var backdrop: ColorRect = $Backdrop
@onready var root_margin: MarginContainer = $Margin
@onready var page_stack: VBoxContainer = $Margin/VStack
@onready var hero_section: VBoxContainer = $Margin/VStack/HeroSection
@onready var page_title: Label = $Margin/VStack/HeroSection/PageTitle
@onready var page_subtitle: Label = $Margin/VStack/HeroSection/PageSubtitle
@onready var board_shell: PanelContainer = $Margin/VStack/BoardShell
@onready var board_head: HBoxContainer = $Margin/VStack/BoardShell/ShellMargin/ShellVBox/BoardHead
@onready var mode_pill: Label = $Margin/VStack/BoardShell/ShellMargin/ShellVBox/BoardHead/ModePill
@onready var selector_hint: Label = $Margin/VStack/BoardShell/ShellMargin/ShellVBox/BoardBody/SelectorZone/ZoneMargin/ZoneVBox/ZoneHead/ZoneHint
@onready var roster_zone: PanelContainer = $Margin/VStack/BoardShell/ShellMargin/ShellVBox/BoardBody/SelectorZone
@onready var roster_scroll: ScrollContainer = $Margin/VStack/BoardShell/ShellMargin/ShellVBox/BoardBody/SelectorZone/ZoneMargin/ZoneVBox/RosterScroll
@onready var roster_list: VBoxContainer = $Margin/VStack/BoardShell/ShellMargin/ShellVBox/BoardBody/SelectorZone/ZoneMargin/ZoneVBox/RosterScroll/RosterList
@onready var feature_zone: PanelContainer = $Margin/VStack/BoardShell/ShellMargin/ShellVBox/BoardBody/FeatureZone
@onready var feature_hint: Label = $Margin/VStack/BoardShell/ShellMargin/ShellVBox/BoardBody/FeatureZone/ZoneMargin/ZoneVBox/ZoneHead/ZoneHint
@onready var hero_stage: PanelContainer = $Margin/VStack/BoardShell/ShellMargin/ShellVBox/BoardBody/FeatureZone/ZoneMargin/ZoneVBox/HeroColumn/HeroStage
@onready var hero_layer: Control = $Margin/VStack/BoardShell/ShellMargin/ShellVBox/BoardBody/FeatureZone/ZoneMargin/ZoneVBox/HeroColumn/HeroStage/StageMargin/HeroLayer
@onready var stage_backdrop: TextureRect = $Margin/VStack/BoardShell/ShellMargin/ShellVBox/BoardBody/FeatureZone/ZoneMargin/ZoneVBox/HeroColumn/HeroStage/StageMargin/HeroLayer/StageBackdrop
@onready var hero_art: TextureRect = $Margin/VStack/BoardShell/ShellMargin/ShellVBox/BoardBody/FeatureZone/ZoneMargin/ZoneVBox/HeroColumn/HeroStage/StageMargin/HeroLayer/HeroArt
@onready var copy_card: PanelContainer = $Margin/VStack/BoardShell/ShellMargin/ShellVBox/BoardBody/FeatureZone/ZoneMargin/ZoneVBox/HeroColumn/CopyCard
@onready var hero_name: Label = $Margin/VStack/BoardShell/ShellMargin/ShellVBox/BoardBody/FeatureZone/ZoneMargin/ZoneVBox/HeroColumn/CopyCard/CopyMargin/CopyVBox/HeroName
@onready var hero_role: Label = $Margin/VStack/BoardShell/ShellMargin/ShellVBox/BoardBody/FeatureZone/ZoneMargin/ZoneVBox/HeroColumn/CopyCard/CopyMargin/CopyVBox/HeroRole
@onready var hero_description: Label = $Margin/VStack/BoardShell/ShellMargin/ShellVBox/BoardBody/FeatureZone/ZoneMargin/ZoneVBox/HeroColumn/CopyCard/CopyMargin/CopyVBox/HeroDescription
@onready var tag_labels := [
	$Margin/VStack/BoardShell/ShellMargin/ShellVBox/BoardBody/FeatureZone/ZoneMargin/ZoneVBox/HeroColumn/CopyCard/CopyMargin/CopyVBox/TagRow/TagOneShell/TagOne,
	$Margin/VStack/BoardShell/ShellMargin/ShellVBox/BoardBody/FeatureZone/ZoneMargin/ZoneVBox/HeroColumn/CopyCard/CopyMargin/CopyVBox/TagRow/TagTwoShell/TagTwo,
	$Margin/VStack/BoardShell/ShellMargin/ShellVBox/BoardBody/FeatureZone/ZoneMargin/ZoneVBox/HeroColumn/CopyCard/CopyMargin/CopyVBox/TagRow/TagThreeShell/TagThree
]
@onready var hero_summary: Label = $Margin/VStack/BoardShell/ShellMargin/ShellVBox/BoardBody/FeatureZone/ZoneMargin/ZoneVBox/HeroColumn/CopyCard/CopyMargin/CopyVBox/HeroSummary
@onready var prep_zone: PanelContainer = $Margin/VStack/BoardShell/ShellMargin/ShellVBox/BoardBody/PrepZone
@onready var prep_hint: Label = $Margin/VStack/BoardShell/ShellMargin/ShellVBox/BoardBody/PrepZone/ZoneMargin/ZoneVBox/ZoneHead/ZoneHint
@onready var palette_card: PanelContainer = $Margin/VStack/BoardShell/ShellMargin/ShellVBox/BoardBody/PrepZone/ZoneMargin/ZoneVBox/PrepColumn/PaletteCard
@onready var palette_title: Label = $Margin/VStack/BoardShell/ShellMargin/ShellVBox/BoardBody/PrepZone/ZoneMargin/ZoneVBox/PrepColumn/PaletteCard/PaletteMargin/PaletteVBox/PaletteTitle
@onready var palette_scroll: ScrollContainer = $Margin/VStack/BoardShell/ShellMargin/ShellVBox/BoardBody/PrepZone/ZoneMargin/ZoneVBox/PrepColumn/PaletteCard/PaletteMargin/PaletteVBox/PaletteScroll
@onready var palette_list: VBoxContainer = $Margin/VStack/BoardShell/ShellMargin/ShellVBox/BoardBody/PrepZone/ZoneMargin/ZoneVBox/PrepColumn/PaletteCard/PaletteMargin/PaletteVBox/PaletteScroll/PaletteList
@onready var bag_card: PanelContainer = $Margin/VStack/BoardShell/ShellMargin/ShellVBox/BoardBody/PrepZone/ZoneMargin/ZoneVBox/PrepColumn/BagCard
@onready var bag_vbox: VBoxContainer = $Margin/VStack/BoardShell/ShellMargin/ShellVBox/BoardBody/PrepZone/ZoneMargin/ZoneVBox/PrepColumn/BagCard/BagMargin/BagVBox
@onready var bag_head: HBoxContainer = $Margin/VStack/BoardShell/ShellMargin/ShellVBox/BoardBody/PrepZone/ZoneMargin/ZoneVBox/PrepColumn/BagCard/BagMargin/BagVBox/BagHead
@onready var bag_hint: Label = $Margin/VStack/BoardShell/ShellMargin/ShellVBox/BoardBody/PrepZone/ZoneMargin/ZoneVBox/PrepColumn/BagCard/BagMargin/BagVBox/BagHead/BagHint
@onready var mini_bag: HBoxContainer = $Margin/VStack/BoardShell/ShellMargin/ShellVBox/BoardBody/PrepZone/ZoneMargin/ZoneVBox/PrepColumn/BagCard/BagMargin/BagVBox/MiniBag
@onready var mini_slots := [
	$Margin/VStack/BoardShell/ShellMargin/ShellVBox/BoardBody/PrepZone/ZoneMargin/ZoneVBox/PrepColumn/BagCard/BagMargin/BagVBox/MiniBag/Slot1,
	$Margin/VStack/BoardShell/ShellMargin/ShellVBox/BoardBody/PrepZone/ZoneMargin/ZoneVBox/PrepColumn/BagCard/BagMargin/BagVBox/MiniBag/Slot2,
	$Margin/VStack/BoardShell/ShellMargin/ShellVBox/BoardBody/PrepZone/ZoneMargin/ZoneVBox/PrepColumn/BagCard/BagMargin/BagVBox/MiniBag/Slot3,
	$Margin/VStack/BoardShell/ShellMargin/ShellVBox/BoardBody/PrepZone/ZoneMargin/ZoneVBox/PrepColumn/BagCard/BagMargin/BagVBox/MiniBag/Slot4,
	$Margin/VStack/BoardShell/ShellMargin/ShellVBox/BoardBody/PrepZone/ZoneMargin/ZoneVBox/PrepColumn/BagCard/BagMargin/BagVBox/MiniBag/Slot5
]
@onready var cta_label: Label = $Margin/VStack/BoardShell/ShellMargin/ShellVBox/BoardBody/PrepZone/ZoneMargin/ZoneVBox/PrepColumn/CtaCard/CtaMargin/CtaVBox/CtaLabel
@onready var cta_copy: Label = $Margin/VStack/BoardShell/ShellMargin/ShellVBox/BoardBody/PrepZone/ZoneMargin/ZoneVBox/PrepColumn/CtaCard/CtaMargin/CtaVBox/CtaCopy
@onready var continue_button: Button = $Margin/VStack/BoardShell/ShellMargin/ShellVBox/BoardBody/PrepZone/ZoneMargin/ZoneVBox/PrepColumn/CtaCard/CtaMargin/CtaVBox/ContinueButton
@onready var cta_footnote: Label = $Margin/VStack/BoardShell/ShellMargin/ShellVBox/BoardBody/PrepZone/ZoneMargin/ZoneVBox/PrepColumn/CtaCard/CtaMargin/CtaVBox/CtaFootnote
@onready var cta_card: PanelContainer = $Margin/VStack/BoardShell/ShellMargin/ShellVBox/BoardBody/PrepZone/ZoneMargin/ZoneVBox/PrepColumn/CtaCard

var _roster: Array = []
var _selected_id := ""
var _selected_color := "red"
var _roster_buttons: Dictionary = {}
var _color_buttons: Dictionary = {}
var _layout_sync_pending := false
var _layout_followup_passes := 0
var _settings_button: Button
var _bag_detail_title: Label
var _bag_detail_body: Label

func _ready() -> void:
	continue_button.pressed.connect(func() -> void:
		continue_requested.emit()
	)
	stage_backdrop.texture = LTLThemeScript.art_texture(BACKDROP_PATH)
	_ensure_settings_button()
	_ensure_bag_detail_panel()
	_bind_bag_hover_signals()
	_apply_theme()
	_apply_cleanup_layout()
	_queue_settled_layout_sync()

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and is_inside_tree():
		_queue_settled_layout_sync()

func apply_state(state: Dictionary) -> void:
	_roster = state.get("characterRoster", []).duplicate(true)
	_selected_color = str(state.get("selectedStartColor", _selected_color))
	var selected_character: Dictionary = state.get("selectedCharacter", {})
	_selected_id = str(selected_character.get("id", _selected_id))
	if _selected_id.is_empty():
		_selected_id = _first_selectable_id()
	page_title.text = TextCatalogScript.t("character.page.title")
	if _settings_button != null:
		_settings_button.text = TextCatalogScript.t("action.settings")
	_sync_roster()
	_sync_palette()
	_render_selected(selected_character)
	_queue_settled_layout_sync()

func _apply_theme() -> void:
	backdrop.color = Color(0.05, 0.08, 0.11, 0.98)
	board_shell.add_theme_stylebox_override("panel", LTLThemeScript.surface_style(Color(0.07, 0.09, 0.12, 0.98), Color(0.18, 0.23, 0.30, 1.0), 28, 1, 0.28))
	for panel in [roster_zone, feature_zone, prep_zone]:
		panel.add_theme_stylebox_override("panel", LTLThemeScript.surface_style(Color(0.06, 0.08, 0.11, 0.98), Color(0.18, 0.23, 0.30, 1.0), 24, 1, 0.18))
	for panel in [hero_stage, copy_card, palette_card, bag_card, cta_card]:
		panel.add_theme_stylebox_override("panel", LTLThemeScript.surface_style(Color(0.10, 0.13, 0.17, 0.92), Color(0.18, 0.23, 0.30, 1.0), 20, 1, 0.18))
	for label in tag_labels:
		if label == null:
			continue
		label.add_theme_color_override("font_color", LTLThemeScript.TEXT_PRIMARY)
		label.add_theme_font_size_override("font_size", 12)
	mode_pill.add_theme_color_override("font_color", Color(0.97, 0.90, 0.72, 1.0))
	mode_pill.add_theme_font_size_override("font_size", 12)
	continue_button.add_theme_font_size_override("font_size", 16)
	page_title.add_theme_font_size_override("font_size", 32)
	page_subtitle.add_theme_font_size_override("font_size", 14)
	hero_name.add_theme_font_size_override("font_size", 26)
	page_subtitle.add_theme_color_override("font_color", LTLThemeScript.TEXT_MUTED)
	hero_role.add_theme_color_override("font_color", LTLThemeScript.TEXT_MUTED)
	hero_description.add_theme_color_override("font_color", LTLThemeScript.TEXT_MUTED)
	hero_summary.add_theme_color_override("font_color", LTLThemeScript.TEXT_PRIMARY)
	bag_hint.add_theme_color_override("font_color", LTLThemeScript.TEXT_MUTED)
	cta_copy.add_theme_color_override("font_color", LTLThemeScript.TEXT_MUTED)
	cta_copy.add_theme_font_size_override("font_size", 14)
	cta_footnote.add_theme_color_override("font_color", LTLThemeScript.TEXT_MUTED)
	cta_footnote.add_theme_font_size_override("font_size", 13)
	if _settings_button != null:
		var normal := LTLThemeScript.surface_style(Color(0.10, 0.13, 0.17, 0.94), Color(0.84, 0.68, 0.34, 0.65), 16, 1, 0.10)
		var hover := normal.duplicate()
		hover.bg_color = normal.bg_color.lightened(0.06)
		var pressed := normal.duplicate()
		pressed.bg_color = normal.bg_color.darkened(0.05)
		_settings_button.add_theme_stylebox_override("normal", normal)
		_settings_button.add_theme_stylebox_override("hover", hover)
		_settings_button.add_theme_stylebox_override("pressed", pressed)
		_settings_button.add_theme_stylebox_override("focus", hover)
		_settings_button.add_theme_font_size_override("font_size", 14)
		_settings_button.add_theme_color_override("font_color", LTLThemeScript.TEXT_PRIMARY)
	if _bag_detail_title != null:
		_bag_detail_title.add_theme_font_size_override("font_size", 15)
		_bag_detail_title.add_theme_color_override("font_color", LTLThemeScript.TEXT_PRIMARY)
	if _bag_detail_body != null:
		_bag_detail_body.add_theme_font_size_override("font_size", 13)
		_bag_detail_body.add_theme_color_override("font_color", LTLThemeScript.TEXT_MUTED)
	var detail_card := bag_vbox.get_node_or_null("BagDetailCard") as PanelContainer
	if detail_card != null:
		detail_card.add_theme_stylebox_override("panel", LTLThemeScript.surface_style(Color(0.08, 0.10, 0.13, 0.95), Color(0.18, 0.23, 0.30, 1.0), 18, 1, 0.08))

func _apply_cleanup_layout() -> void:
	page_title.text = TextCatalogScript.t("character.page.title")
	page_subtitle.visible = false
	board_head.visible = false
	mode_pill.visible = false
	for node in [selector_hint, feature_hint, prep_hint, palette_title, bag_head, cta_label, cta_copy, cta_footnote]:
		if node != null:
			node.visible = false
	hero_section.add_theme_constant_override("separation", 4)
	page_stack.add_theme_constant_override("separation", 14)
	palette_card.size_flags_vertical = Control.SIZE_EXPAND_FILL
	bag_card.size_flags_vertical = 0
	bag_card.custom_minimum_size.y = 220.0
	cta_card.size_flags_vertical = 0
	cta_card.custom_minimum_size.y = 88.0
	continue_button.custom_minimum_size.y = 62.0
	mini_bag.add_theme_constant_override("separation", 10)
	for slot in mini_slots:
		if slot != null:
			slot.custom_minimum_size = Vector2(52.0, 52.0)
	_refresh_bag_detail(0)

func _ensure_settings_button() -> void:
	if has_node("SettingsButton"):
		_settings_button = get_node("SettingsButton") as Button
		return
	_settings_button = Button.new()
	_settings_button.name = "SettingsButton"
	_settings_button.text = TextCatalogScript.t("action.settings")
	_settings_button.custom_minimum_size = Vector2(120.0, 40.0)
	_settings_button.anchor_left = 1.0
	_settings_button.anchor_right = 1.0
	_settings_button.offset_left = -140.0
	_settings_button.offset_right = -20.0
	_settings_button.offset_top = 18.0
	_settings_button.offset_bottom = 58.0
	_settings_button.focus_mode = Control.FOCUS_ALL
	_settings_button.pressed.connect(func() -> void:
		settings_requested.emit()
	)
	add_child(_settings_button)

func _ensure_bag_detail_panel() -> void:
	if bag_vbox.has_node("BagDetailCard"):
		_bag_detail_title = bag_vbox.get_node("BagDetailCard/BagDetailMargin/BagDetailVBox/BagDetailTitle") as Label
		_bag_detail_body = bag_vbox.get_node("BagDetailCard/BagDetailMargin/BagDetailVBox/BagDetailBody") as Label
		return
	var detail_card := PanelContainer.new()
	detail_card.name = "BagDetailCard"
	detail_card.custom_minimum_size = Vector2(0.0, 104.0)
	var detail_margin := MarginContainer.new()
	detail_margin.name = "BagDetailMargin"
	detail_margin.add_theme_constant_override("margin_left", 14)
	detail_margin.add_theme_constant_override("margin_top", 14)
	detail_margin.add_theme_constant_override("margin_right", 14)
	detail_margin.add_theme_constant_override("margin_bottom", 14)
	var detail_vbox := VBoxContainer.new()
	detail_vbox.name = "BagDetailVBox"
	detail_vbox.add_theme_constant_override("separation", 8)
	_bag_detail_title = Label.new()
	_bag_detail_title.name = "BagDetailTitle"
	_bag_detail_body = Label.new()
	_bag_detail_body.name = "BagDetailBody"
	_bag_detail_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail_vbox.add_child(_bag_detail_title)
	detail_vbox.add_child(_bag_detail_body)
	detail_margin.add_child(detail_vbox)
	detail_card.add_child(detail_margin)
	bag_vbox.add_child(detail_card)

func _bind_bag_hover_signals() -> void:
	for index in range(mini_slots.size()):
		var slot := mini_slots[index] as Control
		if slot == null:
			continue
		slot.mouse_entered.connect(func(slot_index := index) -> void:
			_refresh_bag_detail(slot_index)
		)
		slot.mouse_exited.connect(func() -> void:
			_refresh_bag_detail(0)
		)

func _sync_roster() -> void:
	for child in roster_list.get_children():
		child.queue_free()
	_roster_buttons.clear()
	for character in _roster:
		var character_id := str(character.get("id", ""))
		var button := Button.new()
		button.name = "CharacterChoice_%s" % character_id
		button.custom_minimum_size = Vector2(0.0, 68.0)
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.expand_icon = true
		button.focus_mode = Control.FOCUS_NONE
		button.text = "%s\n%s" % [str(character.get("name", "Unknown")), str(character.get("rosterMeta", ""))]
		var portrait_path := str(character.get("portraitPath", ""))
		var portrait_texture := LTLThemeScript.art_texture(portrait_path)
		if portrait_texture != null:
			button.icon = portrait_texture
		button.disabled = not bool(character.get("selectable", false))
		button.pressed.connect(func() -> void:
			_selected_id = character_id
			_refresh_roster_styles()
			_render_selected(_find_character(character_id))
			character_selected.emit(character_id)
		)
		roster_list.add_child(button)
		_roster_buttons[character_id] = button
	_refresh_roster_styles()

func _sync_palette() -> void:
	for child in palette_list.get_children():
		child.queue_free()
	_color_buttons.clear()
	for color_name in ["red", "blue", "purple", "green"]:
		var button := Button.new()
		button.name = "Palette_%s" % color_name
		button.custom_minimum_size = Vector2(0.0, 72.0)
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.focus_mode = Control.FOCUS_NONE
		button.text = _starter_palette_button_text(color_name)
		button.pressed.connect(func() -> void:
			_selected_color = color_name
			_refresh_palette_styles()
			_refresh_bag_preview()
			_refresh_cta_copy()
			color_selected.emit(color_name)
		)
		palette_list.add_child(button)
		_color_buttons[color_name] = button
	_refresh_palette_styles()

func _render_selected(selected_character: Dictionary) -> void:
	var selected := selected_character.duplicate(true)
	if selected.is_empty():
		selected = _find_character(_selected_id)
	if selected.is_empty():
		selected = _find_character(_first_selectable_id())
	if selected.is_empty():
		return
	hero_art.texture = LTLThemeScript.art_texture(str(selected.get("portraitPath", "")))
	hero_name.text = str(selected.get("name", TextCatalogScript.character_text("miner", "name", "Anchor Miner")))
	hero_role.text = str(selected.get("role", ""))
	hero_description.text = str(selected.get("description", ""))
	hero_summary.text = str(selected.get("summary", ""))
	var tags: Array = selected.get("tags", []).duplicate(true)
	for index in range(tag_labels.size()):
		var label: Label = tag_labels[index]
		if label == null:
			continue
		label.text = str(tags[index]) if index < tags.size() else ""
		label.visible = not label.text.is_empty()
		var tag_panel := label.get_parent() as PanelContainer
		if tag_panel != null:
			tag_panel.add_theme_stylebox_override("panel", LTLThemeScript.surface_style(Color(0.08, 0.10, 0.13, 0.95), Color(0.18, 0.23, 0.30, 1.0), 999, 1, 0.08))
	continue_button.text = TextCatalogScript.t("character.continue")
	_refresh_bag_preview()
	_refresh_cta_copy()

func _refresh_roster_styles() -> void:
	for character_id in _roster_buttons.keys():
		var button: Button = _roster_buttons[character_id]
		var character := _find_character(character_id)
		var selectable := bool(character.get("selectable", false))
		var selected: bool = character_id == _selected_id
		var border: Color = LTLThemeScript.BORDER_WARM if selected else LTLThemeScript.BORDER_COLD
		var bg: Color = Color(0.14, 0.11, 0.07, 0.92) if selected else Color(0.10, 0.13, 0.17, 0.94)
		if not selectable:
			bg = Color(0.09, 0.11, 0.14, 0.90)
			border = Color(0.22, 0.27, 0.33, 1.0)
		var normal := LTLThemeScript.surface_style(bg, border, 18, 1, 0.12)
		var hover := normal.duplicate()
		hover.bg_color = bg.lightened(0.06)
		var pressed := normal.duplicate()
		pressed.bg_color = bg.darkened(0.05)
		button.add_theme_stylebox_override("normal", normal)
		button.add_theme_stylebox_override("hover", hover)
		button.add_theme_stylebox_override("pressed", pressed)
		button.add_theme_stylebox_override("focus", hover)
		button.add_theme_font_size_override("font_size", 13)
		button.add_theme_color_override("font_color", LTLThemeScript.TEXT_PRIMARY if selectable else LTLThemeScript.TEXT_MUTED)

func _refresh_palette_styles() -> void:
	for color_name in _color_buttons.keys():
		var button: Button = _color_buttons[color_name]
		var selected: bool = color_name == _selected_color
		var accent: Color = LTLThemeScript.accent_color(color_name)
		var normal := LTLThemeScript.surface_style(Color(0.10, 0.13, 0.17, 0.94), accent if selected else Color(0.18, 0.23, 0.30, 1.0), 18, 1, 0.10)
		if selected:
			normal.bg_color = accent.darkened(0.65)
		var hover := normal.duplicate()
		hover.bg_color = normal.bg_color.lightened(0.05)
		var pressed := normal.duplicate()
		pressed.bg_color = normal.bg_color.darkened(0.04)
		button.add_theme_stylebox_override("normal", normal)
		button.add_theme_stylebox_override("hover", hover)
		button.add_theme_stylebox_override("pressed", pressed)
		button.add_theme_stylebox_override("focus", hover)
		button.add_theme_font_size_override("font_size", 11)
		button.add_theme_color_override("font_color", LTLThemeScript.TEXT_PRIMARY)

func _refresh_bag_preview() -> void:
	var accent := LTLThemeScript.accent_color(_selected_color)
	for index in range(mini_slots.size()):
		var slot_panel := mini_slots[index] as Panel
		if slot_panel == null:
			continue
		var style := LTLThemeScript.surface_style(Color(0.08, 0.10, 0.13, 0.98), Color(0.18, 0.23, 0.30, 1.0), 14, 1, 0.04)
		if index == 0:
			style.bg_color = accent.darkened(0.22)
			style.border_color = accent
		elif index == 1:
			style.bg_color = accent.darkened(0.42).lightened(0.10)
			style.border_color = accent.lightened(0.12)
		slot_panel.add_theme_stylebox_override("panel", style)
	bag_hint.text = TextCatalogScript.t("character.bag_hint", [TextCatalogScript.color_label(_selected_color)])
	_refresh_bag_detail(0)

func _refresh_cta_copy() -> void:
	var selected := _find_character(_selected_id)
	var name := str(selected.get("name", TextCatalogScript.t("character.page.title")))
	cta_copy.text = TextCatalogScript.t("character.cta.copy", [name])
	cta_footnote.text = TextCatalogScript.t("character.cta.footnote")
	var accent := LTLThemeScript.accent_color(_selected_color)
	var normal := LTLThemeScript.surface_style(accent.darkened(0.62), Color(0.84, 0.68, 0.34, 1.0), 18, 1, 0.18)
	var hover := normal.duplicate()
	hover.bg_color = normal.bg_color.lightened(0.06)
	var pressed := normal.duplicate()
	pressed.bg_color = normal.bg_color.darkened(0.06)
	continue_button.add_theme_stylebox_override("normal", normal)
	continue_button.add_theme_stylebox_override("hover", hover)
	continue_button.add_theme_stylebox_override("pressed", pressed)
	continue_button.add_theme_stylebox_override("focus", hover)
	continue_button.add_theme_color_override("font_color", Color(0.98, 0.97, 0.94, 1.0))
	_refresh_bag_detail(0)
	_queue_settled_layout_sync()

func _refresh_bag_detail(slot_index: int) -> void:
	if _bag_detail_title == null or _bag_detail_body == null:
		return
	var detail := _detail_for_slot(slot_index)
	_bag_detail_title.text = str(detail.get("title", ""))
	_bag_detail_body.text = str(detail.get("body", ""))

func _detail_for_slot(slot_index: int) -> Dictionary:
	var loadout := _starter_loadout_for_color(_selected_color)
	if slot_index >= 0 and slot_index < loadout.size():
		return _detail_for_artifact(loadout[slot_index])
	return _empty_bag_detail()

func _detail_for_artifact(artifact) -> Dictionary:
	if artifact == null:
		return _empty_bag_detail()
	return {
		"title": _starter_artifact_title(artifact),
		"body": _starter_artifact_summary(artifact)
	}

func _starter_palette_text(color_name: String) -> String:
	var loadout := _starter_loadout_for_color(color_name)
	var drill = loadout[0] if loadout.size() > 0 else null
	var beacon = loadout[1] if loadout.size() > 1 else null
	return TextCatalogScript.t("character.starter_palette_text", [
		TextCatalogScript.color_label(color_name),
		_starter_artifact_title(drill),
		_starter_artifact_summary(drill),
		_starter_artifact_title(beacon),
		_starter_artifact_summary(beacon)
	])

func _starter_loadout_for_color(color_name: String) -> Array:
	var loadout = ArtifactScript.get_starter_loadout(color_name)
	return loadout.duplicate(true) if loadout is Array else []

func _starter_palette_button_text(color_name: String) -> String:
	var loadout := _starter_loadout_for_color(color_name)
	var drill = loadout[0] if loadout.size() > 0 else null
	var beacon = loadout[1] if loadout.size() > 1 else null
	return TextCatalogScript.t("character.starter_set_button", [
		TextCatalogScript.color_label(color_name),
		_starter_palette_metric_line(drill),
		_starter_palette_metric_line(beacon)
	])

func _starter_artifact_title(artifact) -> String:
	if artifact == null:
		return TextCatalogScript.t("character.unknown_item")
	var color_name := TextCatalogScript.color_label(str(artifact.energy_type))
	var item_type := TextCatalogScript.item_label(str(artifact.item_type))
	return TextCatalogScript.t("character.starter_title", [color_name, item_type])

func _starter_artifact_summary(artifact) -> String:
	if artifact == null:
		return TextCatalogScript.t("character.no_data")
	var item_type := str(artifact.item_type)
	if item_type == "drill":
		return TextCatalogScript.t("character.drill_summary", [float(artifact.base_damage), int(artifact.base_cooldown_ticks)])
	if item_type == "beacon":
		var cooldown_effect := _beacon_tick_phrase(int(artifact.beacon_cooldown_mod))
		return TextCatalogScript.t("character.beacon_summary", [int(artifact.base_cooldown_ticks), cooldown_effect, float(artifact.beacon_damage_mod)])
	return TextCatalogScript.t("character.pending_effect")

func _beacon_tick_phrase(delta: int) -> String:
	if delta < 0:
		return TextCatalogScript.t("character.beacon_tick.down", [abs(delta)])
	if delta > 0:
		return TextCatalogScript.t("character.beacon_tick.up", [delta])
	return TextCatalogScript.t("character.beacon_tick.flat")

func _starter_palette_metric_line(artifact) -> String:
	if artifact == null:
		return TextCatalogScript.t("character.palette_metric.empty")
	var item_type := str(artifact.item_type)
	var item_label := TextCatalogScript.item_label(item_type)
	if item_type == "drill":
		return TextCatalogScript.t("character.palette_metric.drill", [item_label, float(artifact.base_damage), int(artifact.base_cooldown_ticks)])
	if item_type == "beacon":
		return TextCatalogScript.t("character.palette_metric.beacon", [
			item_label,
			int(artifact.base_cooldown_ticks),
			_beacon_tick_compact(int(artifact.beacon_cooldown_mod)),
			float(artifact.beacon_damage_mod)
		])
	return item_label

func _beacon_tick_compact(delta: int) -> String:
	if delta < 0:
		return TextCatalogScript.t("character.beacon_tick_compact.down", [abs(delta)])
	if delta > 0:
		return TextCatalogScript.t("character.beacon_tick_compact.up", [delta])
	return TextCatalogScript.t("character.beacon_tick_compact.flat")

func _empty_bag_detail() -> Dictionary:
	return {
		"title": TextCatalogScript.t("character.empty_slot.title"),
		"body": TextCatalogScript.t("character.empty_slot.body")
	}

func _queue_settled_layout_sync() -> void:
	_layout_followup_passes = max(_layout_followup_passes, 1)
	_queue_layout_sync()

func _queue_layout_sync() -> void:
	if _layout_sync_pending:
		return
	_layout_sync_pending = true
	call_deferred("_sync_responsive_layout")

func _sync_responsive_layout() -> void:
	_layout_sync_pending = false
	if not is_inside_tree():
		return
	var outer_height := size.y - _vertical_margins(root_margin)
	if outer_height <= 0.0:
		return
	board_shell.custom_minimum_size = Vector2.ZERO
	var board_gap := float(page_stack.get_theme_constant("separation"))
	var available_board_height := maxf(540.0, outer_height - hero_section.get_combined_minimum_size().y - board_gap)
	var shell_margin := board_shell.get_node("ShellMargin") as MarginContainer
	var shell_vbox := shell_margin.get_node("ShellVBox") as VBoxContainer
	var board_head_height := board_head.get_combined_minimum_size().y if board_head.visible else 0.0
	var board_head_gap := float(shell_vbox.get_theme_constant("separation")) if board_head.visible else 0.0
	var body_budget := maxf(420.0, available_board_height - _vertical_margins(shell_margin) - board_head_height - board_head_gap)
	var selector_budget := maxf(320.0, body_budget - _zone_shell_vertical_overhead(roster_zone))
	var feature_budget := maxf(320.0, body_budget - _zone_shell_vertical_overhead(feature_zone))
	var prep_budget := maxf(320.0, body_budget - _zone_shell_vertical_overhead(prep_zone))
	roster_scroll.custom_minimum_size.y = clampf(selector_budget, 420.0, 560.0)
	var hero_target := clampf(feature_budget - copy_card.get_combined_minimum_size().y - 14.0, 300.0, 380.0)
	hero_stage.custom_minimum_size.y = hero_target
	hero_layer.custom_minimum_size.y = maxf(224.0, hero_target - 28.0)
	var fixed_prep_height := bag_card.get_combined_minimum_size().y + cta_card.get_combined_minimum_size().y + 24.0
	var palette_height := maxf(240.0, prep_budget - fixed_prep_height)
	palette_scroll.custom_minimum_size.y = palette_height
	if _layout_followup_passes > 0:
		_layout_followup_passes -= 1
		_queue_layout_sync()

func _zone_shell_vertical_overhead(panel: PanelContainer) -> float:
	if panel == null:
		return 0.0
	var zone_margin := panel.get_node("ZoneMargin") as MarginContainer
	var zone_vbox := zone_margin.get_node("ZoneVBox") as VBoxContainer
	var zone_head := zone_vbox.get_node("ZoneHead") as Control
	return _vertical_margins(zone_margin) + zone_head.get_combined_minimum_size().y + float(zone_vbox.get_theme_constant("separation"))

func _vertical_margins(margin_container: MarginContainer) -> float:
	if margin_container == null:
		return 0.0
	return float(margin_container.get_theme_constant("margin_top") + margin_container.get_theme_constant("margin_bottom"))

func _first_selectable_id() -> String:
	for character in _roster:
		if bool(character.get("selectable", false)):
			return str(character.get("id", ""))
	return ""

func _find_character(character_id: String) -> Dictionary:
	for character in _roster:
		if str(character.get("id", "")) == character_id:
			return character.duplicate(true)
	return {}
