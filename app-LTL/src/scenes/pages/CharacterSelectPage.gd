extends Control

const LTLThemeScript = preload("res://src/ui/theme/LTLTheme.gd")
const TextCatalogScript = preload("res://src/ui/TextCatalog.gd")
const BackpackGridFactoryScript = preload("res://src/ui/presenters/BackpackGridFactory.gd")
const BackpackArtifactRendererScript = preload("res://src/ui/backpack/BackpackArtifactRenderer.gd")
const InteractionFXScript = preload("res://src/ui/InteractionFX.gd")
const CharacterSelectLoadoutTextScript = preload("res://src/scenes/pages/character_select/CharacterSelectLoadoutText.gd")
const CharacterSelectPaletteViewScript = preload("res://src/scenes/pages/character_select/CharacterSelectPaletteView.gd")
const CharacterSelectViewBitsScript = preload("res://src/scenes/pages/character_select/CharacterSelectViewBits.gd")
const ViewBitsScript = preload("res://src/scenes/pages/leviathan_select/LeviathanSelectViewBits.gd")

const BACKDROP_PATH := "res://resources/charactor/background.png"
const TOP_BAR_HEIGHT := 76.0

signal character_selected(character_id: String)
signal continue_requested
signal color_selected(color: String)
signal settings_requested
signal codex_requested
signal interaction_sfx_requested(category: String)

# === Stage-based @onready refs ===
@onready var top_bar: PanelContainer = $TopBar
@onready var top_bar_margin: MarginContainer = $TopBar/TopBarMargin
@onready var brand_label: Label = $TopBar/TopBarMargin/TopBarRow/BrandRow/BrandLabel
@onready var tabs_row: HBoxContainer = $TopBar/TopBarMargin/TopBarRow/BrandRow/TabsRow
@onready var top_actions: HBoxContainer = $TopBar/TopBarMargin/TopBarRow/TopActions
@onready var workspace_margin: Control = $Stage  # alias used by LeviathanSelectChromeBits.apply_top_bar_theme
@onready var stage: Control = $Stage
@onready var hero_bg: TextureRect = $Stage/HeroBg
@onready var scrim_bottom: ColorRect = $Stage/ScrimBottom
@onready var hero_char: TextureRect = $Stage/HeroChar
@onready var roster_rail: PanelContainer = $Stage/RosterRail
@onready var roster_scroll: ScrollContainer = $Stage/RosterRail/RosterMargin/RosterVBox/RosterScroll
@onready var roster_list: VBoxContainer = $Stage/RosterRail/RosterMargin/RosterVBox/RosterScroll/RosterList
@onready var roster_kicker: Label = $Stage/RosterRail/RosterMargin/RosterVBox/RosterHead/RosterKicker
@onready var roster_title_label: Label = $Stage/RosterRail/RosterMargin/RosterVBox/RosterHead/RosterTitle
@onready var roster_hint: Label = $Stage/RosterRail/RosterMargin/RosterVBox/RosterHead/RosterHint
@onready var hero_copy: VBoxContainer = $Stage/HeroCopy
@onready var hero_role: Label = $Stage/HeroCopy/HeroRole
@onready var hero_name: Label = $Stage/HeroCopy/HeroName
@onready var hero_summary: Label = $Stage/HeroCopy/HeroSummary
@onready var hero_line: Label = $Stage/HeroCopy/HeroLine
@onready var tag_labels := [
	$Stage/HeroCopy/TagRow/TagOneShell/TagOne,
	$Stage/HeroCopy/TagRow/TagTwoShell/TagTwo,
	$Stage/HeroCopy/TagRow/TagThreeShell/TagThree
]
@onready var wing: PanelContainer = $Stage/Wing
@onready var preset_kicker: Label = $Stage/Wing/WingMargin/WingVBox/PresetSection/PresetHead/PresetHeadLeft/PresetKicker
@onready var preset_title: Label = $Stage/Wing/WingMargin/WingVBox/PresetSection/PresetHead/PresetHeadLeft/PresetTitle
@onready var preset_hint: Label = $Stage/Wing/WingMargin/WingVBox/PresetSection/PresetHead/PresetHint
@onready var preset_grid: GridContainer = $Stage/Wing/WingMargin/WingVBox/PresetSection/PresetGrid
@onready var bag_kicker: Label = $Stage/Wing/WingMargin/WingVBox/BagSection/BagHead/BagHeadLeft/BagKicker
@onready var bag_title: Label = $Stage/Wing/WingMargin/WingVBox/BagSection/BagHead/BagHeadLeft/BagTitle
@onready var bag_hint: Label = $Stage/Wing/WingMargin/WingVBox/BagSection/BagHead/BagHint
@onready var starter_item_list: VBoxContainer = $Stage/Wing/WingMargin/WingVBox/BagSection/StarterItemList
@onready var item_detail_title: Label = $Stage/Wing/WingMargin/WingVBox/DetailSection/ItemDetailTitle
@onready var item_detail_metric: Label = $Stage/Wing/WingMargin/WingVBox/DetailSection/ItemDetailMetric
@onready var item_detail_body: Label = $Stage/Wing/WingMargin/WingVBox/DetailSection/ItemDetailBody
@onready var detail_grid: GridContainer = $Stage/Wing/WingMargin/WingVBox/DetailSection/DetailGrid
@onready var continue_button: Button = $Stage/Wing/WingMargin/WingVBox/CtaDock/ContinueButton

var _roster: Array = []
var _selected_id := ""
var _selected_color := "red"
var _roster_buttons: Dictionary = {}
var _color_buttons: Dictionary = {}
var _starter_item_buttons: Dictionary = {}
var _layout_sync_pending := false
var _layout_followup_passes := 0
var _top_tab_buttons: Array[Button] = []
var _action_buttons: Array[Button] = []
var _selected_starter_item_id := ""
var _hero_transition_tween: Tween = null
var _cached_firefly_texture: Texture2D = null
var _cta_fireflies_active := false

func _ready() -> void:
	theme = LTLThemeScript.shared_theme()
	continue_button.set_meta(InteractionFXScript.META_SFX_CATEGORY, "ui_confirm")
	continue_button.pressed.connect(func() -> void:
		continue_requested.emit()
	)
	hero_bg.texture = LTLThemeScript.art_texture(BACKDROP_PATH)
	_apply_theme()
	_apply_cleanup_layout()
	_rebuild_top_menu()
	_queue_settled_layout_sync()

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and is_inside_tree():
		_queue_settled_layout_sync()

func _process(_delta: float) -> void:
	if _cta_fireflies_active:
		_animate_cta_fireflies()

func apply_state(state: Dictionary) -> void:
	_roster = state.get("characterRoster", []).duplicate(true)
	_selected_color = str(state.get("selectedStartColor", _selected_color))
	var selected_character: Dictionary = state.get("selectedCharacter", {})
	_selected_id = str(selected_character.get("id", _selected_id))
	if _selected_id.is_empty():
		_selected_id = _first_selectable_id()
	_rebuild_top_menu()
	_sync_roster()
	_sync_palette()
	_render_selected(selected_character)
	_queue_settled_layout_sync()

# ===========================================================================
# Theme — Glassmorphism / Dark roster / Bright hero-copy
# ===========================================================================

func _apply_theme() -> void:
	# 1. Stage background — fullscreen hero bg
	hero_bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	hero_bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED

	# 2. Bottom scrim
	scrim_bottom.color = Color(0.08, 0.13, 0.08, 0.54)

	# 3. Top bar — semi-transparent parchment
	var top_style := LTLThemeScript.surface_style(Color(0.95, 0.91, 0.82, 0.98), Color(0.78, 0.74, 0.65, 0.22), 0, 0, 0.0)
	top_style.shadow_size = 0
	top_bar.add_theme_stylebox_override("panel", top_style)
	top_bar.z_index = 20

	# 4. Roster-rail — dark gradient that fades to reveal the background image on the right
	var rail_gradient := GradientTexture2D.new()
	var rg := Gradient.new()
	rg.set_color(0, Color(0.02, 0.035, 0.024, 0.92))
	rg.set_color(1, Color(0.02, 0.035, 0.024, 0.0))
	rg.set_offset(0, 0.0)
	rg.set_offset(1, 1.0)
	rg.add_point(0.55, Color(0.02, 0.035, 0.024, 0.80))
	rg.add_point(0.82, Color(0.02, 0.035, 0.024, 0.32))
	rail_gradient.gradient = rg
	rail_gradient.fill_from = Vector2(0.0, 0.5)
	rail_gradient.fill_to = Vector2(1.0, 0.5)
	rail_gradient.width = 256
	rail_gradient.height = 4
	var roster_style := StyleBoxTexture.new()
	roster_style.texture = rail_gradient
	roster_rail.add_theme_stylebox_override("panel", roster_style)

	# Roster head text colors
	roster_kicker.add_theme_color_override("font_color", Color(0.85, 0.90, 0.79, 1.0))
	roster_title_label.add_theme_color_override("font_color", Color(0.98, 0.97, 0.90, 1.0))
	roster_hint.add_theme_color_override("font_color", Color(0.84, 0.89, 0.78, 1.0))

	# 5. Wing — glassmorphism panel (more opaque for legibility)
	var wing_style := StyleBoxFlat.new()
	wing_style.bg_color = Color(0.93, 0.96, 0.90, 0.72)
	wing_style.border_color = Color(1.0, 1.0, 1.0, 0.55)
	wing_style.set_border_width_all(1)
	wing_style.set_corner_radius_all(16)
	wing_style.shadow_color = Color(0.024, 0.055, 0.031, 0.35)
	wing_style.shadow_size = 18
	wing.add_theme_stylebox_override("panel", wing_style)

	# Wing section kickers/titles — bolder via font outline
	var section_kicker_color := Color(0.11, 0.24, 0.14, 1.0)
	var section_title_color := Color(0.043, 0.129, 0.071, 1.0)
	for kicker in [preset_kicker, bag_kicker]:
		kicker.add_theme_color_override("font_color", section_kicker_color)
		kicker.add_theme_constant_override("outline_size", 1)
		kicker.add_theme_color_override("font_outline_color", section_kicker_color)
	for title in [preset_title, bag_title]:
		title.add_theme_color_override("font_color", section_title_color)
		title.add_theme_font_size_override("font_size", 18)
		title.add_theme_constant_override("outline_size", 3)
		title.add_theme_color_override("font_outline_color", section_title_color)
	bag_hint.add_theme_color_override("font_color", Color(0.15, 0.30, 0.17, 1.0))
	preset_hint.add_theme_color_override("font_color", Color(0.15, 0.30, 0.17, 1.0))
	item_detail_title.add_theme_color_override("font_color", section_title_color)
	item_detail_title.add_theme_font_size_override("font_size", 18)
	item_detail_title.add_theme_constant_override("outline_size", 3)
	item_detail_title.add_theme_color_override("font_outline_color", section_title_color)
	item_detail_metric.add_theme_color_override("font_color", Color(0.13, 0.24, 0.15, 1.0))
	item_detail_body.add_theme_color_override("font_color", Color(0.13, 0.24, 0.15, 1.0))

	# 6. Hero-copy — bright overlay text + text shadow via LabelSettings
	hero_name.add_theme_font_size_override("font_size", 42)
	hero_name.add_theme_color_override("font_color", Color(0.98, 0.97, 0.90, 1.0))
	var name_settings := LabelSettings.new()
	name_settings.font_size = 42
	name_settings.font_color = Color(0.98, 0.97, 0.90, 1.0)
	name_settings.shadow_color = Color(0.0, 0.0, 0.0, 0.50)
	name_settings.shadow_offset = Vector2(1, 2)
	hero_name.label_settings = name_settings
	hero_role.add_theme_color_override("font_color", Color(0.92, 0.95, 0.87, 1.0))
	var role_settings := LabelSettings.new()
	role_settings.font_size = 13
	role_settings.font_color = Color(0.92, 0.95, 0.87, 1.0)
	role_settings.shadow_color = Color(0.0, 0.0, 0.0, 0.35)
	role_settings.shadow_offset = Vector2(1, 1)
	hero_role.label_settings = role_settings
	hero_role.uppercase = true
	hero_summary.add_theme_color_override("font_color", Color(0.93, 0.95, 0.87, 1.0))
	var summary_settings := LabelSettings.new()
	summary_settings.font_color = Color(0.93, 0.95, 0.87, 1.0)
	summary_settings.shadow_color = Color(0.0, 0.0, 0.0, 0.30)
	summary_settings.shadow_offset = Vector2(1, 1)
	hero_summary.label_settings = summary_settings
	hero_line.add_theme_color_override("font_color", Color(0.85, 0.90, 0.80, 0.85))
	hero_line.add_theme_font_size_override("font_size", 14)
	var line_settings := LabelSettings.new()
	line_settings.font_size = 14
	line_settings.font_color = Color(0.85, 0.90, 0.80, 0.85)
	line_settings.shadow_color = Color(0.0, 0.0, 0.0, 0.25)
	line_settings.shadow_offset = Vector2(1, 1)
	hero_line.label_settings = line_settings

	# Tag chips — dark bg, light border
	for label in tag_labels:
		if label == null:
			continue
		label.add_theme_color_override("font_color", Color(0.90, 0.93, 0.85, 1.0))
		label.add_theme_font_size_override("font_size", 12)

	# 7. CTA button base
	continue_button.add_theme_font_size_override("font_size", 16)
	brand_label.add_theme_color_override("font_color", Color(0.15, 0.28, 0.21, 1.0))

func _apply_cleanup_layout() -> void:
	# Roster head labels
	roster_kicker.text = "EXPEDITION ROSTER"
	roster_title_label.text = TextCatalogScript.t("character.page.title")
	roster_hint.text = "3명 중 1명 선택"

	# Wing section labels
	preset_kicker.text = "PRESET"
	preset_title.text = "시작 세트"
	preset_hint.text = "카드로 선택"
	bag_kicker.text = "FIRST EXPEDITION"
	bag_title.text = "첫 탐사 꾸러미"

	# Scrollbar hidden
	CharacterSelectViewBitsScript.hide_scrollbar_chrome(roster_scroll)

	# Item detail defaults
	item_detail_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	# Wing section dividers — white 28% opacity bottom borders
	for section_name in ["PresetSection", "BagSection", "DetailSection"]:
		var section := wing.get_node_or_null("WingMargin/WingVBox/%s" % section_name)
		if section != null:
			var sep := HSeparator.new()
			sep.name = "SectionSep"
			sep.mouse_filter = Control.MOUSE_FILTER_IGNORE
			var sep_style := StyleBoxFlat.new()
			sep_style.bg_color = Color(1.0, 1.0, 1.0, 0.28)
			sep_style.set_content_margin_all(0)
			sep.custom_minimum_size = Vector2(0.0, 1.0)
			sep.add_theme_stylebox_override("separator", sep_style)
			sep.add_theme_constant_override("separation", 0)
			section.add_child(sep)

# ===========================================================================
# Top menu (unchanged logic)
# ===========================================================================

func _rebuild_top_menu() -> void:
	brand_label.text = "Looting The Leviathan"
	var character_text := TextCatalogScript.t("character.page.title")
	var leviathan_text := TextCatalogScript.t("leviathan.roster.title")
	var codex_text := TextCatalogScript.t("action.codex")
	var settings_text := TextCatalogScript.t("action.settings")
	_top_tab_buttons = ViewBitsScript.replace_chrome_buttons(
		tabs_row,
		[
			{"name": "CharacterTabButton", "text": character_text, "actionId": "character", "kind": "top_group", "active": true},
			{"name": "LeviathanTabButton", "text": leviathan_text, "actionId": "leviathan", "kind": "top_group"},
			{"name": "CodexActionButton", "text": codex_text, "actionId": "codex", "kind": "top_group"},
			{"name": "SettingsActionButton", "text": settings_text, "actionId": "settings", "kind": "top_group"}
		],
		self,
		"_handle_top_menu_action",
		LTLThemeScript
	)
	_action_buttons = ViewBitsScript.replace_chrome_buttons(top_actions, [], self, "_handle_top_menu_action", LTLThemeScript)
	ViewBitsScript.apply_top_bar_theme(self, _top_tab_buttons, _action_buttons, LTLThemeScript)

func _handle_top_menu_action(action_id: String) -> void:
	match action_id:
		"leviathan":
			continue_requested.emit()
		"codex":
			codex_requested.emit()
		"settings":
			settings_requested.emit()
		_:
			return

# ===========================================================================
# Roster
# ===========================================================================

func _sync_roster() -> void:
	for child in roster_list.get_children():
		child.queue_free()
	_roster_buttons.clear()
	var rendered_count := 0
	var locked_rendered := false
	for character in _roster:
		var selectable := bool(character.get("selectable", false))
		if not selectable:
			if locked_rendered or rendered_count >= 3:
				continue
			locked_rendered = true
		elif rendered_count >= 3:
			continue
		rendered_count += 1
		var character_id := str(character.get("id", ""))
		var button := CharacterSelectViewBitsScript.build_roster_button(character)
		button.name = "CharacterChoice_%s" % character_id
		button.disabled = not bool(character.get("selectable", false))
		button.pressed.connect(func() -> void:
			_selected_id = character_id
			_refresh_roster_styles()
			_render_selected(_find_character(character_id))
			character_selected.emit(character_id)
		)
		# Hover: slide right + brighten (Task 10-A)
		button.mouse_entered.connect(_on_roster_card_hover_enter.bind(button))
		button.mouse_exited.connect(_on_roster_card_hover_exit.bind(button))
		roster_list.add_child(button)
		_roster_buttons[character_id] = button
	_refresh_roster_styles()

func _refresh_roster_styles() -> void:
	for character_id in _roster_buttons.keys():
		var button := _roster_buttons[character_id] as Button
		var character := _find_character(character_id)
		var selectable := bool(character.get("selectable", false))
		var is_selected: bool = str(character_id) == _selected_id
		button.set_meta("selected", is_selected)
		var accent := LTLThemeScript.accent_color(str(character.get("accentColor", "red")))
		CharacterSelectViewBitsScript.apply_roster_button_style_dark(button, selectable, is_selected, accent, LTLThemeScript)

# ===========================================================================
# Palette / Preset grid
# ===========================================================================

func _sync_palette() -> void:
	for child in preset_grid.get_children():
		child.queue_free()
	_color_buttons.clear()
	for color_name in ["red", "blue", "purple", "green"]:
		var button := CharacterSelectPaletteViewScript.build_palette_button(color_name)
		button.set_meta(InteractionFXScript.META_SFX_CATEGORY, "starter_set_select")
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.pressed.connect(_select_palette_color.bind(color_name))
		preset_grid.add_child(button)
		_color_buttons[color_name] = button
	_refresh_palette_styles()

func _select_palette_color(color_name: String) -> void:
	if color_name != _selected_color:
		_selected_color = color_name
	_refresh_palette_styles()
	_refresh_bag_preview()
	_refresh_starter_item_list()
	_refresh_continue_button_theme()
	color_selected.emit(color_name)

func _refresh_palette_styles() -> void:
	CharacterSelectPaletteViewScript.refresh_palette_styles_glassmorphism(_color_buttons, _selected_color)

# ===========================================================================
# Hero rendering + transition animation (Task 9)
# ===========================================================================

func _render_selected(selected_character: Dictionary) -> void:
	var selected := selected_character.duplicate(true)
	if selected.is_empty():
		selected = _find_character(_selected_id)
	if selected.is_empty():
		selected = _find_character(_first_selectable_id())
	if selected.is_empty():
		return
	_selected_id = str(selected.get("id", _selected_id))
	var new_texture := LTLThemeScript.art_texture(str(selected.get("portraitPath", "")))
	if hero_char.texture != null and hero_char.texture != new_texture:
		_transition_hero_art(new_texture)
	else:
		hero_char.texture = new_texture
	hero_name.text = str(selected.get("name", TextCatalogScript.character_text("miner", "name", "Anchor Miner")))
	hero_role.text = str(selected.get("role", ""))
	hero_summary.text = str(selected.get("summary", selected.get("description", "")))
	hero_line.text = str(selected.get("heroLine", ""))
	hero_line.visible = not hero_line.text.is_empty()
	var tags: Array = selected.get("tags", []).duplicate(true)
	for index in range(tag_labels.size()):
		var label: Label = tag_labels[index]
		if label == null:
			continue
		label.text = str(tags[index]) if index < tags.size() else ""
		label.visible = not label.text.is_empty()
		var tag_panel := label.get_parent() as PanelContainer
		if tag_panel != null:
			tag_panel.add_theme_stylebox_override("panel", _flat_surface(Color(0.08, 0.12, 0.07, 0.34), Color(0.89, 0.93, 0.82, 0.32), 999, 1))
	continue_button.text = "탐험대 확정"
	_refresh_roster_styles()
	_refresh_bag_preview()
	_refresh_starter_item_list()
	_refresh_continue_button_theme()

func _transition_hero_art(new_texture: Texture2D) -> void:
	if _hero_transition_tween != null and _hero_transition_tween.is_running():
		_hero_transition_tween.kill()
	var original_x := hero_char.position.x
	var tween := create_tween().set_parallel(true)
	tween.tween_property(hero_char, "position:x", original_x - 50.0, 0.25).set_ease(Tween.EASE_IN)
	tween.tween_property(hero_char, "modulate:a", 0.0, 0.25).set_ease(Tween.EASE_IN)
	_hero_transition_tween = tween
	await tween.finished
	hero_char.texture = new_texture
	hero_char.position.x = original_x + 50.0
	hero_char.modulate.a = 0.0
	var tween2 := create_tween().set_parallel(true)
	tween2.tween_property(hero_char, "position:x", original_x, 0.25).set_ease(Tween.EASE_OUT)
	tween2.tween_property(hero_char, "modulate:a", 1.0, 0.25).set_ease(Tween.EASE_OUT)
	_hero_transition_tween = tween2

# ===========================================================================
# Bag / Starter items
# ===========================================================================

func _refresh_bag_preview() -> void:
	bag_hint.text = "실제 지급품"

func _refresh_starter_item_list() -> void:
	for child in starter_item_list.get_children():
		child.queue_free()
	_starter_item_buttons.clear()
	var item_models := CharacterSelectLoadoutTextScript.starter_item_models(_selected_color)
	if item_models.is_empty():
		_selected_starter_item_id = ""
		_refresh_starter_item_detail()
		return
	var found_selected := false
	for item_model in item_models:
		if str(item_model.get("itemId", "")) == _selected_starter_item_id:
			found_selected = true
			break
	if not found_selected:
		_selected_starter_item_id = str(item_models[0].get("itemId", ""))
	for item_model in item_models:
		var item_id := str(item_model.get("itemId", ""))
		var button := CharacterSelectViewBitsScript.build_starter_item_button(item_model)
		button.pressed.connect(func() -> void:
			_selected_starter_item_id = item_id
			_refresh_starter_item_styles()
			_refresh_starter_item_detail()
			interaction_sfx_requested.emit("item_click")
		)
		starter_item_list.add_child(button)
		_starter_item_buttons[item_id] = button
	_refresh_starter_item_styles()
	_refresh_starter_item_detail()

func _refresh_starter_item_styles() -> void:
	for item_id in _starter_item_buttons.keys():
		var button := _starter_item_buttons[item_id] as Button
		var is_selected: bool = str(item_id) == _selected_starter_item_id
		button.set_meta("selected", is_selected)
		var accent := LTLThemeScript.accent_color(_selected_color)
		CharacterSelectViewBitsScript.apply_starter_item_button_style(button, is_selected, accent, LTLThemeScript)

func _refresh_starter_item_detail() -> void:
	var detail := CharacterSelectLoadoutTextScript.detail_for_item_id(_selected_color, _selected_starter_item_id)
	item_detail_title.text = str(detail.get("title", ""))
	item_detail_metric.text = str(detail.get("metricLine", ""))
	item_detail_metric.visible = not item_detail_metric.text.is_empty()
	item_detail_body.text = str(detail.get("body", ""))

const CTA_BUTTON_PATH := "res://resources/UI/cta/expedition_cta_button.png"

func _refresh_continue_button_theme() -> void:
	# Transparent button chrome — the ornate frame image is the visual
	var flat := StyleBoxEmpty.new()
	continue_button.add_theme_stylebox_override("normal", flat)
	continue_button.add_theme_stylebox_override("hover", flat)
	continue_button.add_theme_stylebox_override("pressed", flat)
	continue_button.add_theme_stylebox_override("focus", flat)
	continue_button.add_theme_stylebox_override("disabled", flat)
	continue_button.add_theme_color_override("font_color", Color(1.0, 0.973, 0.875, 1.0))
	continue_button.add_theme_color_override("font_hover_color", Color(1.0, 0.988, 0.902, 1.0))
	continue_button.add_theme_color_override("font_pressed_color", Color(0.90, 0.87, 0.78, 1.0))
	continue_button.add_theme_font_size_override("font_size", 20)
	continue_button.add_theme_constant_override("outline_size", 6)
	continue_button.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.85))
	_ensure_cta_decor()

func _ensure_cta_decor() -> void:
	if continue_button.get_node_or_null("CtaFrameBg") != null:
		return
	continue_button.clip_contents = false
	# Ornate frame background behind the label
	var frame_bg := TextureRect.new()
	frame_bg.name = "CtaFrameBg"
	frame_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	frame_bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	frame_bg.stretch_mode = TextureRect.STRETCH_SCALE
	frame_bg.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	frame_bg.show_behind_parent = true
	if ResourceLoader.exists(CTA_BUTTON_PATH):
		frame_bg.texture = load(CTA_BUTTON_PATH)
	continue_button.add_child(frame_bg)
	# Firefly overlay layer — glowing motes that drift on hover
	var fireflies := Control.new()
	fireflies.name = "CtaFireflies"
	fireflies.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fireflies.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fireflies.clip_contents = true
	fireflies.modulate = Color(1, 1, 1, 0.0)
	continue_button.add_child(fireflies)
	var rng := RandomNumberGenerator.new()
	rng.seed = 20260707
	for i in range(7):
		var mote := _make_firefly(rng)
		fireflies.add_child(mote)
	continue_button.mouse_entered.connect(_on_cta_hover_enter)
	continue_button.mouse_exited.connect(_on_cta_hover_exit)

func _make_firefly(rng: RandomNumberGenerator) -> TextureRect:
	var mote := TextureRect.new()
	mote.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mote.texture = _firefly_texture()
	mote.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	mote.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
	var s := rng.randf_range(6.0, 12.0)
	mote.custom_minimum_size = Vector2(s, s)
	mote.size = Vector2(s, s)
	mote.position = Vector2(rng.randf_range(0.08, 0.92), rng.randf_range(0.2, 0.8))
	mote.set_meta("_norm_pos", mote.position)
	mote.modulate = Color(1.0, 0.96, 0.62, rng.randf_range(0.5, 0.95))
	mote.set_meta("_rng_phase", rng.randf_range(0.0, TAU))
	mote.set_meta("_rng_speed", rng.randf_range(0.5, 1.2))
	mote.set_meta("_rng_amp", rng.randf_range(6.0, 16.0))
	return mote

func _firefly_texture() -> Texture2D:
	if _cached_firefly_texture != null:
		return _cached_firefly_texture
	var size := 32
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var center := Vector2(size, size) * 0.5
	for y in range(size):
		for x in range(size):
			var d := Vector2(x, y).distance_to(center) / (size * 0.5)
			var a: float = clampf(1.0 - d, 0.0, 1.0)
			a = pow(a, 2.2)
			img.set_pixel(x, y, Color(1.0, 0.95, 0.65, a))
	_cached_firefly_texture = ImageTexture.create_from_image(img)
	return _cached_firefly_texture

func _on_cta_hover_enter() -> void:
	var fireflies := continue_button.get_node_or_null("CtaFireflies") as Control
	if fireflies == null:
		return
	var frame_bg := continue_button.get_node_or_null("CtaFrameBg") as TextureRect
	if frame_bg != null:
		var glow := continue_button.create_tween()
		glow.tween_property(frame_bg, "modulate", Color(1.12, 1.12, 1.05, 1.0), 0.25)
	var fade := continue_button.create_tween()
	fade.tween_property(fireflies, "modulate:a", 1.0, 0.4)
	_cta_fireflies_active = true
	_animate_cta_fireflies()

func _on_cta_hover_exit() -> void:
	var fireflies := continue_button.get_node_or_null("CtaFireflies") as Control
	var frame_bg := continue_button.get_node_or_null("CtaFrameBg") as TextureRect
	if frame_bg != null:
		var glow := continue_button.create_tween()
		glow.tween_property(frame_bg, "modulate", Color(1, 1, 1, 1), 0.3)
	_cta_fireflies_active = false
	if fireflies != null:
		var fade := continue_button.create_tween()
		fade.tween_property(fireflies, "modulate:a", 0.0, 0.4)

func _animate_cta_fireflies() -> void:
	# Continuous slow drift while hovered — driven by _process time
	var fireflies := continue_button.get_node_or_null("CtaFireflies") as Control
	if fireflies == null or not _cta_fireflies_active:
		return
	var rect := fireflies.size
	var t := Time.get_ticks_msec() / 1000.0
	for mote in fireflies.get_children():
		var tr := mote as TextureRect
		if tr == null:
			continue
		var norm: Vector2 = tr.get_meta("_norm_pos", Vector2(0.5, 0.5))
		var phase: float = tr.get_meta("_rng_phase", 0.0)
		var speed: float = tr.get_meta("_rng_speed", 1.0)
		var amp: float = tr.get_meta("_rng_amp", 10.0)
		var base := Vector2(norm.x * rect.x, norm.y * rect.y)
		var drift := Vector2(
			sin(t * speed + phase) * amp,
			cos(t * speed * 0.7 + phase) * amp * 0.6
		)
		tr.position = base + drift - tr.size * 0.5
		tr.modulate.a = 0.5 + 0.45 * (0.5 + 0.5 * sin(t * speed * 1.6 + phase))

# ===========================================================================
# Hover interactions (Task 10)
# ===========================================================================

# 10-A: Roster card hover — slide right + brighten
func _on_roster_card_hover_enter(button: Button) -> void:
	if button.get_meta("selected", false):
		return
	var tween := create_tween()
	tween.tween_property(button, "position:x", button.position.x + 8.0, 0.15).set_ease(Tween.EASE_OUT)
	button.set_meta("_hover_tween", tween)
	button.set_meta("_hover_origin_x", button.position.x)

func _on_roster_card_hover_exit(button: Button) -> void:
	if button.get_meta("selected", false):
		return
	var old_tween = button.get_meta("_hover_tween", null)
	if old_tween is Tween and old_tween.is_running():
		old_tween.kill()
	var origin_x: float = button.get_meta("_hover_origin_x", button.position.x - 8.0)
	var tween := create_tween()
	tween.tween_property(button, "position:x", origin_x, 0.15).set_ease(Tween.EASE_IN)

# ===========================================================================
# Responsive layout
# ===========================================================================

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
	var vp := get_viewport_rect().size
	if vp.x <= 0.0 or vp.y <= 0.0:
		return
	var stage_height := vp.y - TOP_BAR_HEIGHT
	if stage_height <= 0.0:
		return

	# Roster-rail width: ~26% (min 300, max 400)
	var rail_w := clampf(vp.x * 0.26, 300.0, 400.0)
	roster_rail.offset_right = rail_w

	# Wing width: ~28% (min 360, max 420)
	var wing_w := clampf(vp.x * 0.28, 360.0, 420.0)
	wing.offset_left = -(wing_w + 26.0)

	# Hero-copy: between roster-rail right + 32px margin and wing left - 20px margin
	hero_copy.offset_left = rail_w + 32.0
	hero_copy.offset_right = -(wing_w + 26.0 + 20.0)

	# Hero-char: centered between roster and wing, bottom anchored
	var hero_left := rail_w * 0.6
	var hero_right := wing_w + 26.0 + wing_w * 0.2
	hero_char.anchor_left = 0.0
	hero_char.anchor_right = 1.0
	hero_char.anchor_top = 0.1
	hero_char.anchor_bottom = 1.0
	hero_char.offset_left = hero_left
	hero_char.offset_right = -hero_right

	if _layout_followup_passes > 0:
		_layout_followup_passes -= 1
		_queue_layout_sync()

# ===========================================================================
# Helpers
# ===========================================================================

func _flat_surface(bg_color: Color, border_color: Color, radius: int, border_width: int) -> StyleBoxFlat:
	var style := LTLThemeScript.surface_style(bg_color, border_color, radius, border_width, 0.0)
	style.shadow_size = 0
	return style

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
