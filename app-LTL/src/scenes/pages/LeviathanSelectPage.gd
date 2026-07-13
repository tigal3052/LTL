extends Control

const LTLThemeScript = preload("res://src/ui/theme/LTLTheme.gd")
const TextCatalogScript = preload("res://src/ui/TextCatalog.gd")
const InteractionFXScript = preload("res://src/ui/InteractionFX.gd")
const ViewBitsScript = preload("res://src/scenes/pages/leviathan_select/LeviathanSelectViewBits.gd")
const RailCardFactoryScript = preload("res://src/scenes/pages/leviathan_select/LeviathanSelectRailCardFactory.gd")
const RailScrollControllerScript = preload("res://src/scenes/pages/leviathan_select/LeviathanSelectRailScrollController.gd")

## ROLLBACK SWITCH: flip to false to restore the pre-fullscreen-hero layout
## (left GlobalRail visible, hero copy bottom-left). When this slice is
## confirmed good, delete this flag and the `_LEGACY_` / old-path branches
## below in one pass.
const FULLSCREEN_HERO_LAYOUT_ENABLED := true

const LEVIATHAN_TABLE_PATH := "res://src/data/leviathan-table.json"
const GLOBAL_RAIL_WIDTH_RATIO := 0.165
const GLOBAL_RAIL_WIDTH_MIN := 208.0
const GLOBAL_RAIL_WIDTH_MAX := 224.0
const OVERLAY_RAIL_WIDTH_RATIO := 0.31
const OVERLAY_RAIL_WIDTH_MIN := 292.0
const OVERLAY_RAIL_WIDTH_MAX := 336.0
const CTA_HEIGHT_RATIO := 0.145
const CTA_HEIGHT_MIN := 100.0
const CTA_HEIGHT_MAX := 104.0
const HERO_NAME_SIZE_MIN := 34.0
const HERO_NAME_SIZE_MAX := 46.0
const HERO_SUMMARY_SIZE_MIN := 13.0
const HERO_SUMMARY_SIZE_MAX := 16.0
const CARD_HEIGHT_MIN := 132.0
const CARD_HEIGHT_MAX := 138.0
const CARD_HEIGHT_RATIO := 0.177
const RAIL_CONTENT_LEFT_INSET := 0.0
const CARD_TOP_SNAP_THRESHOLD := 72
const CARD_TOP_REST_GAP := 0.0
const RAIL_PREVIEW_TOP_SPEC := {
	"title": "북해 전초 계약",
	"subtitle": "항차 0 · 프롤로그",
	"biome": "상단 시작 카드",
	"badge": "정찰",
	"badge_fg": Color(0.96, 0.98, 0.99, 0.86),
	"badge_bg": Color(0.10, 0.14, 0.18, 0.72),
	"scale": 0.50,
	"art_seed_index": 0,
}
const RAIL_PREVIEW_TAIL_SPECS := [
	{
		"title": "황혼 리자드",
		"subtitle": "항차 4 · 구간 1",
		"biome": "흐릿한 분지대",
		"badge": "잠금",
		"badge_fg": Color(0.88, 0.88, 0.90, 0.78),
		"badge_bg": Color(0.08, 0.09, 0.10, 0.78),
		"placeholder_text": "LOCK",
		"scale": 1.0,
		"art_seed_index": 1,
	},
	{
		"title": "심연 미르",
		"subtitle": "항차 4 · 구간 2",
		"biome": "침식 해역 지대",
		"badge": "잠금",
		"badge_fg": Color(0.88, 0.88, 0.90, 0.78),
		"badge_bg": Color(0.08, 0.09, 0.10, 0.78),
		"placeholder_text": "LOCK",
		"scale": 1.0,
		"art_seed_index": 2,
	},
	{
		"title": "청해 드레이크",
		"subtitle": "항차 5 · 구간 1",
		"biome": "파쇄 수로 지대",
		"badge": "잠금",
		"badge_fg": Color(0.88, 0.88, 0.90, 0.78),
		"badge_bg": Color(0.08, 0.09, 0.10, 0.78),
		"placeholder_text": "LOCK",
		"scale": 1.0,
		"art_seed_index": 3,
	},
	{
		"title": "심층 계약 대기",
		"subtitle": "미확인 수역",
		"biome": "하단 대기 카드",
		"badge": "잠금",
		"badge_fg": Color(0.88, 0.88, 0.90, 0.78),
		"badge_bg": Color(0.08, 0.09, 0.10, 0.78),
		"placeholder_text": "LOCK",
		"scale": 1.0,
		"art_seed_index": 3,
	},
]

signal start_requested
signal leviathan_selected(leviathan_id: String)
signal settings_requested
signal codex_requested
signal return_to_character_select_requested

@onready var backdrop: ColorRect = $Backdrop
@onready var top_bar: PanelContainer = $TopBar
@onready var top_bar_margin: MarginContainer = $TopBar/TopBarMargin
@onready var brand_label: Label = $TopBar/TopBarMargin/TopBarRow/BrandRow/BrandLabel
@onready var tabs_row: HBoxContainer = $TopBar/TopBarMargin/TopBarRow/BrandRow/TabsRow
@onready var top_actions: HBoxContainer = $TopBar/TopBarMargin/TopBarRow/TopActions
@onready var workspace_margin: MarginContainer = $WorkspaceMargin
@onready var workspace: HBoxContainer = $WorkspaceMargin/Workspace
@onready var global_rail: PanelContainer = $WorkspaceMargin/Workspace/GlobalRail
@onready var portrait_shell: PanelContainer = $WorkspaceMargin/Workspace/GlobalRail/RailMargin/RailVBox/PortraitShell
@onready var portrait_icon: Label = $WorkspaceMargin/Workspace/GlobalRail/RailMargin/RailVBox/PortraitShell/PortraitMargin/PortraitIcon
@onready var leader_title: Label = $WorkspaceMargin/Workspace/GlobalRail/RailMargin/RailVBox/LeaderTitle
@onready var leader_rank: Label = $WorkspaceMargin/Workspace/GlobalRail/RailMargin/RailVBox/LeaderRank
@onready var rail_divider: HSeparator = $WorkspaceMargin/Workspace/GlobalRail/RailMargin/RailVBox/RailDivider
@onready var nav_list: VBoxContainer = $WorkspaceMargin/Workspace/GlobalRail/RailMargin/RailVBox/NavList
@onready var hero_shell: Control = $WorkspaceMargin/Workspace/HeroShell
@onready var hero_art: TextureRect = $WorkspaceMargin/Workspace/HeroShell/HeroArt
@onready var hero_shade: ColorRect = $WorkspaceMargin/Workspace/HeroShell/HeroShade
@onready var hero_copy_margin: MarginContainer = $WorkspaceMargin/Workspace/HeroShell/HeroCopyMargin
@onready var hero_eyebrow_shell: PanelContainer = $WorkspaceMargin/Workspace/HeroShell/HeroCopyMargin/HeroCopyBox/HeroEyebrowShell
@onready var hero_eyebrow: Label = $WorkspaceMargin/Workspace/HeroShell/HeroCopyMargin/HeroCopyBox/HeroEyebrowShell/HeroEyebrowMargin/HeroEyebrow
@onready var hero_name: Label = $WorkspaceMargin/Workspace/HeroShell/HeroCopyMargin/HeroCopyBox/HeroName
@onready var hero_summary: Label = $WorkspaceMargin/Workspace/HeroShell/HeroCopyMargin/HeroCopyBox/HeroSummary
@onready var hero_facts_row: HBoxContainer = $WorkspaceMargin/Workspace/HeroShell/HeroCopyMargin/HeroCopyBox/HeroFactsRow
@onready var clear_shell: PanelContainer = $WorkspaceMargin/Workspace/HeroShell/HeroCopyMargin/HeroCopyBox/ClearShell
@onready var clear_label: Label = $WorkspaceMargin/Workspace/HeroShell/HeroCopyMargin/HeroCopyBox/ClearShell/ClearMargin/ClearLabel
@onready var overlay_rail: PanelContainer = $WorkspaceMargin/Workspace/HeroShell/OverlayRail
@onready var cards_scroll: ScrollContainer = $WorkspaceMargin/Workspace/HeroShell/OverlayRail/OverlayVBox/CardsScroll
@onready var cards_box: VBoxContainer = $WorkspaceMargin/Workspace/HeroShell/OverlayRail/OverlayVBox/CardsScroll/CardsVBox
@onready var start_button_frame: MarginContainer = $WorkspaceMargin/Workspace/HeroShell/OverlayRail/OverlayVBox/StartButtonFrame
@onready var start_button: Button = $WorkspaceMargin/Workspace/HeroShell/OverlayRail/OverlayVBox/StartButtonFrame/StartButton
@onready var start_button_margin: MarginContainer = $WorkspaceMargin/Workspace/HeroShell/OverlayRail/OverlayVBox/StartButtonFrame/StartButton/StartButtonMargin
@onready var start_button_vbox: VBoxContainer = $WorkspaceMargin/Workspace/HeroShell/OverlayRail/OverlayVBox/StartButtonFrame/StartButton/StartButtonMargin/StartButtonVBox
@onready var start_button_hint: Label = $WorkspaceMargin/Workspace/HeroShell/OverlayRail/OverlayVBox/StartButtonFrame/StartButton/StartButtonMargin/StartButtonVBox/AdvanceLabel
@onready var start_button_label: Label = $WorkspaceMargin/Workspace/HeroShell/OverlayRail/OverlayVBox/StartButtonFrame/StartButton/StartButtonMargin/StartButtonVBox/StartLabel

var _roster: Array = []
var _selected_id := ""
var _layout_sync_pending := false
var _last_state: Dictionary = {}
var _unlock_conditions: Dictionary = {}
var _top_tab_buttons: Array[Button] = []
var _action_buttons: Array[Button] = []
var _nav_buttons: Array[Button] = []
var _cards_spring_top: Control
var _cards_spring_bottom: Control
var _rail_scroll_controller
var _overlay_rail_blend_texture: GradientTexture2D = null

func _ready() -> void:
	theme = LTLThemeScript.shared_theme()
	_unlock_conditions = _load_unlock_conditions()
	start_button.set_meta(InteractionFXScript.META_SFX_CATEGORY, "battle_start")
	start_button.pressed.connect(func() -> void:
		if not start_button.disabled:
			start_requested.emit()
	)
	cards_scroll.gui_input.connect(_on_cards_scroll_gui_input)
	resized.connect(_queue_layout_sync)
	hero_shell.resized.connect(_queue_layout_sync)
	_apply_theme()
	_apply_locale()
	_queue_layout_sync()

func apply_state(state: Dictionary) -> void:
	_last_state = state.duplicate(true)
	_roster = state.get("leviathanRoster", []).duplicate(true)
	_selected_id = _sanitize_selected_id(str(state.get("selectedLeviathanId", "")), state)
	_apply_locale()
	_render_page(state)
	_queue_layout_sync()

func _apply_theme() -> void:
	_apply_shell_theme()
	_apply_top_bar_theme()
	_apply_global_rail_theme()
	_apply_hero_theme()
	_apply_cards_scroll_theme()
	_apply_cta_theme()
	if FULLSCREEN_HERO_LAYOUT_ENABLED:
		_apply_fullscreen_hero_layout()
	else:
		global_rail.visible = true

## New layout path (rollback: set FULLSCREEN_HERO_LAYOUT_ENABLED = false).
## Hides the left GlobalRail so HeroShell (the leviathan art) fills the
## whole workspace width; hero copy repositioning happens in
## _sync_hero_copy_margin via the same flag.
func _apply_fullscreen_hero_layout() -> void:
	global_rail.visible = false

func _apply_locale() -> void:
	brand_label.text = "Looting The Leviathan"
	leader_title.text = "Expedition Leader"
	leader_rank.text = "RANK: SCHOLAR"
	_rebuild_navigation()
	start_button_hint.text = TextCatalogScript.t("leviathan.start_hint")
	start_button_label.text = TextCatalogScript.t("leviathan.start_button")
	clear_label.text = ViewBitsScript.clear_label_text(TextCatalogScript.locale())

func _apply_shell_theme() -> void:
	backdrop.color = Color(0.82, 0.89, 0.91, 1.0)
	var top_style := _surface_style(Color(0.95, 0.91, 0.82, 0.98), Color(0.78, 0.74, 0.65, 0.22), 0, 0, 0.08)
	top_style.shadow_size = 0
	top_bar.add_theme_stylebox_override("panel", top_style)
	var hero_style := _surface_style(Color(0.0, 0.0, 0.0, 0.0), Color(0.0, 0.0, 0.0, 0.0), 0, 0, 0.0)
	hero_style.shadow_size = 0
	hero_style.shadow_offset = Vector2.ZERO
	hero_style.shadow_color = Color(0.0, 0.0, 0.0, 0.0)
	hero_style.corner_radius_top_left = 0
	hero_style.corner_radius_top_right = 0
	hero_style.corner_radius_bottom_left = 0
	hero_style.corner_radius_bottom_right = 0
	hero_shell.add_theme_stylebox_override("panel", hero_style)
	hero_shade.color = Color(0.03, 0.07, 0.09, 0.14)
	var overlay_style := _surface_style(Color(0.05, 0.08, 0.09, 0.0), Color(1.0, 1.0, 1.0, 0.0), 0, 0, 0.0)
	overlay_style.corner_radius_top_left = 0
	overlay_style.corner_radius_bottom_left = 0
	overlay_style.corner_radius_top_right = 0
	overlay_style.corner_radius_bottom_right = 0
	overlay_style.shadow_size = 0
	overlay_rail.add_theme_stylebox_override("panel", overlay_style)
	_ensure_overlay_rail_blend()
	var rail_style := _surface_style(Color(0.97, 0.93, 0.89, 0.96), Color(0.36, 0.45, 0.40, 0.10), 28, 1, 0.10)
	rail_style.corner_radius_top_left = 0
	rail_style.corner_radius_bottom_left = 0
	rail_style.corner_radius_top_right = 28
	rail_style.corner_radius_bottom_right = 28
	rail_style.shadow_size = 0
	global_rail.add_theme_stylebox_override("panel", rail_style)
func _apply_top_bar_theme() -> void:
	ViewBitsScript.apply_top_bar_theme(self, _top_tab_buttons, _action_buttons, LTLThemeScript)
func _apply_global_rail_theme() -> void:
	ViewBitsScript.apply_global_rail_theme(self, _nav_buttons, LTLThemeScript)
func _apply_hero_theme() -> void:
	ViewBitsScript.apply_hero_theme(self)
func _apply_cards_scroll_theme() -> void:
	ViewBitsScript.apply_cards_scroll_theme(self, LTLThemeScript)
func _apply_cta_theme() -> void:
	ViewBitsScript.apply_cta_theme(self, LTLThemeScript)

func _render_page(state: Dictionary) -> void:
	var selected := _selected_leviathan(state)
	_render_hero(selected, state)
	_render_cards(state)
	_refresh_cta(selected, state)

func _render_hero(selected: Dictionary, state: Dictionary) -> void:
	var locale := TextCatalogScript.locale()
	var selected_id := str(selected.get("id", ""))
	var unlocked := _is_leviathan_unlocked(selected_id, state)
	var name := str(selected.get("name", TextCatalogScript.t("leviathan.roster.title")))
	var biome := str(selected.get("biome", TextCatalogScript.t("leviathan.biome_unknown")))
	var biome_text := TextCatalogScript.t("leviathan.biome", [biome])
	hero_art.texture = LTLThemeScript.art_texture(str(selected.get("artPath", "")))
	hero_eyebrow.text = ViewBitsScript.hero_eyebrow_text(locale, unlocked, TextCatalogScript.t("leviathan.target_kicker"))
	hero_name.text = name
	hero_summary.text = ViewBitsScript.hero_summary_text(locale, name, biome_text, unlocked, TextCatalogScript.t("leviathan.target_core", [name]))
	clear_shell.visible = _is_cleared(selected_id, state)
	_clear_children(hero_facts_row)
	hero_facts_row.add_child(ViewBitsScript.build_fact_pill(LTLThemeScript, ViewBitsScript.run_chip_text(locale, int(selected.get("runCount", selected.get("runCnt", 1)))), unlocked))
	hero_facts_row.add_child(ViewBitsScript.build_fact_pill(LTLThemeScript, ViewBitsScript.stage_chip_text(locale, int(selected.get("stageCount", selected.get("stageCnt", 1)))), unlocked))
	hero_facts_row.add_child(ViewBitsScript.build_fact_pill(LTLThemeScript, biome, unlocked))

func _refresh_cta(selected: Dictionary, state: Dictionary) -> void:
	var locale := TextCatalogScript.locale()
	var unlocked := _is_leviathan_unlocked(str(selected.get("id", "")), state)
	start_button.disabled = not unlocked
	start_button_hint.text = TextCatalogScript.t("leviathan.start_hint") if unlocked else ViewBitsScript.locked_hint_text(locale)
	start_button_label.text = TextCatalogScript.t("leviathan.start_button") if unlocked else ViewBitsScript.locked_button_text(locale)
	_apply_cta_theme()

func _render_cards(state: Dictionary) -> void:
	_clear_children(cards_box)
	_cards_spring_top = Control.new()
	_cards_spring_top.name = "CardsSpringTop"
	_cards_spring_top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_cards_spring_top.custom_minimum_size = Vector2(0.0, CARD_TOP_REST_GAP)
	cards_box.add_child(_cards_spring_top)
	for leviathan in _roster:
		cards_box.add_child(_build_leviathan_card(leviathan, state))
	for preview_spec in RAIL_PREVIEW_TAIL_SPECS:
		cards_box.add_child(_build_preview_card(preview_spec))
	_cards_spring_bottom = Control.new()
	_cards_spring_bottom.name = "CardsSpringBottom"
	_cards_spring_bottom.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_cards_spring_bottom.custom_minimum_size = Vector2.ZERO
	cards_box.add_child(_cards_spring_bottom)
	if _rail_scroll_controller == null:
		_rail_scroll_controller = RailScrollControllerScript.new(self, cards_scroll, cards_box, _cards_spring_top, _cards_spring_bottom, CARD_TOP_SNAP_THRESHOLD, CARD_TOP_REST_GAP, ViewBitsScript.rail_card_drag_threshold())
	else:
		_rail_scroll_controller.refresh_springs(_cards_spring_top, _cards_spring_bottom)

func _build_preview_card(spec: Dictionary) -> PanelContainer:
	return RailCardFactoryScript.build_preview_card(LTLThemeScript, ViewBitsScript, spec, Callable(self, "_on_rail_surface_gui_input"))

func _build_leviathan_card(leviathan: Dictionary, state: Dictionary) -> Button:
	var leviathan_id := str(leviathan.get("id", ""))
	var unlocked := _is_leviathan_unlocked(leviathan_id, state)
	var cleared := _is_cleared(leviathan_id, state)
	return RailCardFactoryScript.build_leviathan_card(
		LTLThemeScript,
		TextCatalogScript,
		ViewBitsScript,
		leviathan,
		_selected_id,
		hero_shell.size.y,
		CARD_HEIGHT_RATIO,
		CARD_HEIGHT_MIN,
		CARD_HEIGHT_MAX,
		unlocked,
		cleared,
		Callable(self, "_on_leviathan_card_pressed"),
		Callable(self, "_on_rail_surface_gui_input")
	)

func _on_leviathan_card_pressed(leviathan_id: String, unlocked: bool) -> void:
	if _rail_scroll_controller != null and _rail_scroll_controller.consume_suppressed_press():
		return
	if not unlocked:
		return
	_selected_id = leviathan_id
	_last_state["selectedLeviathanId"] = leviathan_id
	leviathan_selected.emit(leviathan_id)
	_render_page(_last_state)

func _queue_layout_sync() -> void:
	if _layout_sync_pending:
		return
	if is_inside_tree() and hero_shell.size.x > 1.0 and hero_shell.size.y > 1.0:
		_sync_responsive_layout()
		return
	_layout_sync_pending = true
	call_deferred("_sync_responsive_layout")

func _sync_responsive_layout() -> void:
	_layout_sync_pending = false
	if not is_inside_tree():
		return
	var hero_size := hero_shell.size
	if hero_size.x <= 1.0 or hero_size.y <= 1.0:
		return
	global_rail.custom_minimum_size.x = clampf(size.x * GLOBAL_RAIL_WIDTH_RATIO, GLOBAL_RAIL_WIDTH_MIN, GLOBAL_RAIL_WIDTH_MAX)
	var rail_width := clampf(hero_size.x * OVERLAY_RAIL_WIDTH_RATIO, OVERLAY_RAIL_WIDTH_MIN, OVERLAY_RAIL_WIDTH_MAX)
	overlay_rail.offset_left = -rail_width
	cards_scroll.offset_left = RAIL_CONTENT_LEFT_INSET
	cards_scroll.offset_top = 0.0
	cards_scroll.offset_right = 0.0
	_sync_hero_copy_margin(rail_width)
	var button_height := clampf(hero_size.y * CTA_HEIGHT_RATIO, CTA_HEIGHT_MIN, CTA_HEIGHT_MAX)
	cards_scroll.offset_bottom = -button_height
	start_button_frame.offset_left = 0.0
	start_button_frame.offset_top = -button_height
	start_button_frame.offset_right = 0.0
	start_button_frame.offset_bottom = 0.0
	start_button_frame.custom_minimum_size.y = button_height
	start_button.custom_minimum_size.y = button_height
	start_button_margin.add_theme_constant_override("margin_top", int(round(clampf(button_height * 0.13, 12.0, 14.0))))
	start_button_margin.add_theme_constant_override("margin_bottom", int(round(clampf(button_height * 0.13, 12.0, 14.0))))
	start_button_hint.add_theme_font_size_override("font_size", int(round(clampf(button_height * 0.106, 10.0, 11.0))))
	start_button_label.add_theme_font_size_override("font_size", int(round(clampf(button_height * 0.33, 30.0, 34.0))))
	hero_name.add_theme_font_size_override("font_size", int(round(clampf(hero_size.x * 0.055, HERO_NAME_SIZE_MIN, HERO_NAME_SIZE_MAX))))
	hero_summary.add_theme_font_size_override("font_size", int(round(clampf(hero_size.x * 0.0185, HERO_SUMMARY_SIZE_MIN, HERO_SUMMARY_SIZE_MAX))))
	var card_height := clampf(hero_size.y * CARD_HEIGHT_RATIO, CARD_HEIGHT_MIN, CARD_HEIGHT_MAX)
	for child in cards_box.get_children():
		if child is Control and child != _cards_spring_top and child != _cards_spring_bottom:
			var scale := float(child.get_meta("rail_card_height_scale", 1.0))
			(child as Control).custom_minimum_size.y = round(card_height * scale)
	if _cards_spring_top != null:
		_cards_spring_top.custom_minimum_size.y = CARD_TOP_REST_GAP
	if cards_scroll.scroll_vertical <= CARD_TOP_SNAP_THRESHOLD:
		cards_scroll.scroll_vertical = 0

func _sync_hero_copy_margin(rail_width: float) -> void:
	if FULLSCREEN_HERO_LAYOUT_ENABLED:
		_sync_hero_copy_margin_fullscreen(rail_width)
		return
	_sync_hero_copy_margin_legacy(rail_width)

func _sync_hero_copy_margin_legacy(rail_width: float) -> void:
	hero_copy_margin.add_theme_constant_override("margin_left", 28)
	hero_copy_margin.add_theme_constant_override("margin_top", int(round(clampf(hero_shell.size.y * 0.30, 136.0, 212.0))))
	hero_copy_margin.add_theme_constant_override("margin_right", int(round(rail_width + 34.0)))
	hero_copy_margin.add_theme_constant_override("margin_bottom", int(round(clampf(hero_shell.size.y * 0.16, 78.0, 126.0))))

## New layout path (rollback: set FULLSCREEN_HERO_LAYOUT_ENABLED = false).
## Pins the hero copy box (name/summary/tags) to the top-left of the now
## fullscreen hero art, clear of the OverlayRail card list on the right.
func _sync_hero_copy_margin_fullscreen(rail_width: float) -> void:
	hero_copy_margin.add_theme_constant_override("margin_left", 28)
	hero_copy_margin.add_theme_constant_override("margin_top", 28)
	hero_copy_margin.add_theme_constant_override("margin_right", int(round(rail_width + 34.0)))
	hero_copy_margin.add_theme_constant_override("margin_bottom", int(round(hero_shell.size.y - 28.0 - clampf(hero_shell.size.y * 0.42, 220.0, 340.0))))

func _ensure_overlay_rail_blend() -> void:
	if overlay_rail == null:
		return
	var blend := overlay_rail.get_node_or_null("RailBlend") as TextureRect
	if blend == null:
		blend = TextureRect.new()
		blend.name = "RailBlend"
		blend.layout_mode = 1
		blend.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		blend.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		blend.stretch_mode = TextureRect.STRETCH_SCALE
		blend.mouse_filter = Control.MOUSE_FILTER_IGNORE
		overlay_rail.add_child(blend)
	blend.texture = _overlay_rail_blend_texture_resource()
	blend.offset_left = 0.0
	blend.offset_top = 0.0
	blend.offset_right = 0.0
	blend.offset_bottom = 0.0
	overlay_rail.move_child(blend, 0)

func _overlay_rail_blend_texture_resource() -> GradientTexture2D:
	if _overlay_rail_blend_texture != null:
		return _overlay_rail_blend_texture
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.18, 0.58, 1.0])
	gradient.colors = PackedColorArray([
		Color(0.05, 0.08, 0.09, 0.0),
		Color(0.05, 0.08, 0.09, 0.10),
		Color(0.05, 0.08, 0.09, 0.34),
		Color(0.05, 0.08, 0.09, 0.74),
	])
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill = GradientTexture2D.FILL_LINEAR
	texture.fill_from = Vector2(0.0, 0.5)
	texture.fill_to = Vector2(1.0, 0.5)
	_overlay_rail_blend_texture = texture
	return _overlay_rail_blend_texture

func _rebuild_navigation() -> void:
	var character_text := TextCatalogScript.t("character.page.title")
	var leviathan_text := TextCatalogScript.t("leviathan.roster.title")
	var codex_text := TextCatalogScript.t("action.codex")
	var settings_text := TextCatalogScript.t("action.settings")
	_top_tab_buttons = ViewBitsScript.replace_chrome_buttons(tabs_row, [{"name": "CharacterTabButton", "text": character_text, "actionId": "character", "kind": "top_group"}, {"name": "LeviathanTabButton", "text": leviathan_text, "actionId": "leviathan", "kind": "top_group", "active": true}, {"name": "CodexActionButton", "text": codex_text, "actionId": "codex", "kind": "top_group"}, {"name": "SettingsActionButton", "text": settings_text, "actionId": "settings", "kind": "top_group"}], self, "_handle_chrome_action", LTLThemeScript)
	_action_buttons = ViewBitsScript.replace_chrome_buttons(top_actions, [], self, "_handle_chrome_action", LTLThemeScript)
	_nav_buttons = ViewBitsScript.replace_chrome_buttons(nav_list, [{"name": "CharacterNavButton", "text": character_text, "actionId": "character", "kind": "nav"}, {"name": "LeviathanNavButton", "text": leviathan_text, "actionId": "leviathan", "kind": "nav", "active": true}, {"name": "CodexNavButton", "text": codex_text, "actionId": "codex", "kind": "nav"}, {"name": "SettingsNavButton", "text": settings_text, "actionId": "settings", "kind": "nav"}], self, "_handle_chrome_action", LTLThemeScript)
	_apply_top_bar_theme()
	_apply_global_rail_theme()

func _handle_chrome_action(action_id: String) -> void:
	match action_id:
		"character":
			return_to_character_select_requested.emit()
		"codex":
			codex_requested.emit()
		"settings":
			settings_requested.emit()
		_:
			return

func _on_rail_surface_gui_input(event: InputEvent, surface: Control) -> void:
	if _rail_scroll_controller == null:
		return
	if surface is Button:
		_rail_scroll_controller.handle_button_gui_input(surface as Button, event)
	else:
		_rail_scroll_controller.handle_preview_gui_input(surface, event)

func _on_cards_scroll_gui_input(event: InputEvent) -> void:
	if _rail_scroll_controller != null:
		_rail_scroll_controller.handle_scroll_gui_input(event)

func _selected_leviathan(state: Dictionary) -> Dictionary:
	for leviathan in _roster:
		if str(leviathan.get("id", "")) == _selected_id:
			return leviathan
	for leviathan in _roster:
		if _is_leviathan_unlocked(str(leviathan.get("id", "")), state):
			return leviathan
	return _roster[0] if not _roster.is_empty() else {}

func _sanitize_selected_id(candidate_id: String, state: Dictionary) -> String:
	for leviathan in _roster:
		if str(leviathan.get("id", "")) == candidate_id and _is_leviathan_unlocked(candidate_id, state):
			return candidate_id
	for leviathan in _roster:
		var leviathan_id := str(leviathan.get("id", ""))
		if _is_leviathan_unlocked(leviathan_id, state):
			return leviathan_id
	return str(_roster[0].get("id", "")) if not _roster.is_empty() else ""

func _is_leviathan_unlocked(leviathan_id: String, state: Dictionary) -> bool:
	var unlock_condition := str(_unlock_conditions.get(leviathan_id, "starter"))
	if unlock_condition.is_empty() or unlock_condition == "starter":
		return true
	if unlock_condition.begins_with("buy_"):
		var growth_value = state.get("growth", {})
		var growth: Dictionary = growth_value if growth_value is Dictionary else {}
		var scan_unlocks_value = growth.get("scanUnlocks", [])
		var scan_unlocks: Array = scan_unlocks_value if scan_unlocks_value is Array else []
		return scan_unlocks.has(unlock_condition)
	if unlock_condition.begins_with("clear_"):
		var progress_value = state.get("progress", {})
		var progress: Dictionary = progress_value if progress_value is Dictionary else {}
		var cleared_value = progress.get("clearedLeviathanIds", [])
		var cleared_ids: Array = cleared_value if cleared_value is Array else []
		return cleared_ids.has(unlock_condition.trim_prefix("clear_"))
	return false

func _is_cleared(leviathan_id: String, state: Dictionary) -> bool:
	var progress_value = state.get("progress", {})
	var progress: Dictionary = progress_value if progress_value is Dictionary else {}
	var cleared_value = progress.get("clearedLeviathanIds", [])
	var cleared_ids: Array = cleared_value if cleared_value is Array else []
	return cleared_ids.has(leviathan_id)

func _load_unlock_conditions() -> Dictionary:
	var file := FileAccess.open(LEVIATHAN_TABLE_PATH, FileAccess.READ)
	if file == null:
		return {}
	var json := JSON.new()
	if json.parse(file.get_as_text()) != OK:
		return {}
	var data = json.get_data()
	if not (data is Dictionary):
		return {}
	var result := {}
	for row in data.get("leviathans", []):
		if not (row is Dictionary):
			continue
		result[str(row.get("id", ""))] = str(row.get("unlockCondition", "starter"))
	return result

func _surface_style(bg: Color, border: Color, radius: int, border_width: int, shadow_alpha: float) -> StyleBoxFlat:
	return LTLThemeScript.surface_style(bg, border, radius, border_width, shadow_alpha)

func _clear_children(node: Node) -> void:
	for child in node.get_children():
		node.remove_child(child)
		child.queue_free()
