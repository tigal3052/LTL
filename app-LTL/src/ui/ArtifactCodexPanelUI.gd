# 계약:
# - 책임: V5 도감 overlay를 1440x900 캔버스로 조합하고 read model을 표시한다.
# - 입력: ArtifactCodexReadModel의 V5 projection 및 사용자 선택 신호.
# - 출력: debug_toggled, entry_selected, section_selected, taxonomy_selected, sort_selected.
# - 금지: reward table 직접 읽기와 run state 변경.
#
# 실행: V5 parchment catalog and detail overlay control.
class_name ArtifactCodexPanelUI
extends PanelContainer

signal debug_toggled(debug_all: bool)
signal entry_selected(entry_id: String)
signal section_selected(section_id: String)
signal taxonomy_selected(taxonomy_id: String)
signal sort_selected(sort_id: String)

const TextCatalog = preload("res://src/ui/TextCatalog.gd")
const Layout = preload("res://src/ui/codex/ArtifactCodexLayoutPolicy.gd")
const Typography = preload("res://src/ui/codex/CodexTypography.gd")
const V5_ROOT := "res://resources/UI/codex/v5"
const SORT_CONTROL_SIZE := Vector2(126, 28)
const SORT_POPUP_SIZE := Vector2i(126, 92)
const DETAIL_OBSERVATION_POS := Vector2(364, 323)
const DETAIL_OBSERVATION_SIZE := Vector2(168, 76)
const DETAIL_FACT_LABEL_WIDTH := 132.0

var design_canvas: Control
var catalog_region: Control
var detail_region: Control
var title_label: Label
var count_label: Label
var close_button: Button
var debug_check: CheckBox
var taxonomy_tabs: HBoxContainer
var filter_tabs: HBoxContainer
var entry_grid: GridContainer
var empty_label: Label
var detail_title: Label
var detail_subtitle: Label
var detail_status: Label
var hero_art_host: Control
var observation_label: Label
var facts_box: VBoxContainer
var description_label: RichTextLabel
var sort_popup: PopupMenu
var last_model: Dictionary = {}
var _built := false

func _ready() -> void:
	if _built: return
	_built = true
	visible = false
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	add_theme_stylebox_override("panel", _flat(Color.TRANSPARENT))
	_build_shell()
	call_deferred("_apply_canvas_layout")

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and _built: call_deferred("_apply_canvas_layout")

func book_layout_metrics_for_rect(rect: Rect2) -> Dictionary:
	return Layout.book_layout_metrics_for_rect(rect)

func apply_locale() -> void:
	if last_model.is_empty(): return
	render_codex(last_model)

func render_codex(model: Dictionary) -> void:
	if not _built: _ready()
	last_model = model.duplicate(true)
	title_label.text = str(model.get("title", TextCatalog.t("codex.title")))
	count_label.text = TextCatalog.t("codex.discovered_count", [int(model.get("discoveredCount", 0)), int(model.get("totalCount", 0))])
	debug_check.set_pressed_no_signal(bool(model.get("debugAll", false)))
	_render_taxonomies(model.get("sections", []), str(model.get("activeSection", "all")))
	_render_filters(model.get("sections", []), str(model.get("activeSection", "all")), model.get("sortOptions", []))
	_render_entries((model.get("rightPage", {}) as Dictionary).get("gridEntries", []), str(model.get("resolvedSelectedEntryId", "")))
	_render_detail(model.get("leftPage", {}))
	call_deferred("_apply_canvas_layout")

func _build_shell() -> void:
	var shade := ColorRect.new()
	shade.name = "OverlayShade"
	shade.color = Color(0.05, 0.035, 0.02, 0.45)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	var viewport := Control.new()
	viewport.name = "CodexViewport"
	viewport.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(viewport)
	design_canvas = Control.new()
	design_canvas.name = "DesignCanvas"
	design_canvas.size = Layout.DESIGN_SIZE
	viewport.add_child(design_canvas)
	var bg := TextureRect.new()
	bg.name = "ParchmentBackground"
	bg.texture = _texture("codex_v5_screen_parchment_bg_1440x900.png")
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_SCALE
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	design_canvas.add_child(bg)
	_build_topbar()
	_build_catalog()
	_build_detail()

func _build_topbar() -> void:
	# PanelContainer would resize every direct child to its content rect, destroying the absolute 1440x80 chrome geometry.
	var top := Panel.new()
	top.name = "TopBar"
	top.position = Vector2(0, 0); top.size = Vector2(1440, 80)
	top.add_theme_stylebox_override("panel", _flat(Color(1, 0.975, 0.94, 0.94), Color(0.25, 0.35, 0.25, 0.16), 0, 0, 0, 1))
	design_canvas.add_child(top)
	var brand := _label("Looting The Leviathan", 34, Color("183a1f"), "serif")
	brand.name = "Brand"; brand.position = Vector2(40, 17); brand.size = Vector2(430, 46); top.add_child(brand)
	var version := _label("Field Journal v1.0.4", 12, Color("727971"))
	version.name = "Version"; version.position = Vector2(480, 28); version.size = Vector2(150, 25); version.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; version.add_theme_stylebox_override("normal", _flat(Color(1, 1, 1, 0.42), Color(0.45, 0.47, 0.44, 0.32), 1, 1, 1, 1)); top.add_child(version)
	var nav := HBoxContainer.new(); nav.name = "ContextNav"; nav.position = Vector2(645, 20); nav.size = Vector2(390, 42); nav.alignment = BoxContainer.ALIGNMENT_CENTER; nav.add_theme_constant_override("separation", 28); top.add_child(nav)
	title_label = _label(TextCatalog.t("codex.title"), 14, Color("183a1f")); title_label.name = "CodexNavLabel"; title_label.visible = false; top.add_child(title_label)
	for label_text in ["캐릭터 선택", "레비아탄 선택", TextCatalog.t("codex.title"), "설정"]:
		var nav_label := _label(label_text, 14, Color("183a1f") if label_text == TextCatalog.t("codex.title") else Color("444840")); nav_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; nav_label.custom_minimum_size = Vector2(72, 36); nav.add_child(nav_label)
	debug_check = CheckBox.new(); debug_check.name = "DebugCheck"; debug_check.visible = false; debug_check.toggled.connect(func(v): debug_toggled.emit(v)); top.add_child(debug_check)
	close_button = Button.new(); close_button.name = "CloseButton"; close_button.text = "×"; close_button.position = Vector2(1350, 20); close_button.size = Vector2(48, 38); close_button.add_theme_font_size_override("font_size", 24); close_button.add_theme_color_override("font_color", Color("183a1f")); close_button.add_theme_stylebox_override("normal", _flat(Color.TRANSPARENT)); close_button.pressed.connect(func(): visible = false); top.add_child(close_button)

func _build_catalog() -> void:
	catalog_region = Control.new(); catalog_region.name = "CatalogRegion"; catalog_region.position = Vector2(40, 118); catalog_region.size = Vector2(740, 750); design_canvas.add_child(catalog_region)
	var kicker := _label("EXPLORATION ALMANAC", 13, Color("316428")); kicker.position = Vector2(0, 0); kicker.size = Vector2(400, 20); catalog_region.add_child(kicker)
	var heading := _label(TextCatalog.t("codex.title"), 56, Color("043f28"), "serif"); heading.position = Vector2(0, 18); heading.size = Vector2(470, 70); catalog_region.add_child(heading)
	var subtitle := _label("Recovered artifact field journal", 18, Color("3a2c1c"), "serif"); subtitle.position = Vector2(2, 88); subtitle.size = Vector2(500, 28); catalog_region.add_child(subtitle)
	var count_kicker := _label("TOTAL DISCOVERED", 12, Color("6d6b62")); count_kicker.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT; count_kicker.position = Vector2(500, 14); count_kicker.size = Vector2(220, 20); catalog_region.add_child(count_kicker)
	count_label = _label("", 30, Color("275e23"), "serif"); count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT; count_label.position = Vector2(500, 35); count_label.size = Vector2(220, 42); catalog_region.add_child(count_label)
	var panel := TextureRect.new(); panel.name = "ListPanel"; panel.texture = _texture("codex_v5_list_panel_bg_1480x1216.png"); panel.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; panel.stretch_mode = TextureRect.STRETCH_SCALE; panel.position = Vector2(0, 144); panel.size = Vector2(740, 606); panel.mouse_filter = Control.MOUSE_FILTER_IGNORE; catalog_region.add_child(panel)
	taxonomy_tabs = HBoxContainer.new(); taxonomy_tabs.name = "TaxonomyTabs"; taxonomy_tabs.position = Vector2(42, 170); taxonomy_tabs.size = Vector2(650, 38); taxonomy_tabs.add_theme_constant_override("separation", 28); catalog_region.add_child(taxonomy_tabs)
	filter_tabs = HBoxContainer.new(); filter_tabs.name = "FilterTabs"; filter_tabs.position = Vector2(42, 218); filter_tabs.size = Vector2(650, 30); filter_tabs.add_theme_constant_override("separation", 8); catalog_region.add_child(filter_tabs)
	var scroll := ScrollContainer.new(); scroll.name = "CatalogScroll"; scroll.position = Vector2(38, 265); scroll.size = Vector2(674, 465); scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED; _style_scrollbar(scroll.get_v_scroll_bar()); catalog_region.add_child(scroll)
	entry_grid = GridContainer.new(); entry_grid.name = "EntryGrid"; entry_grid.columns = 2; entry_grid.add_theme_constant_override("h_separation", 18); entry_grid.add_theme_constant_override("v_separation", 14); scroll.add_child(entry_grid)
	empty_label = _label(TextCatalog.t("codex.empty"), 16, Color("6d6b62")); empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; empty_label.custom_minimum_size = Vector2(620, 80); entry_grid.add_child(empty_label)

func _build_detail() -> void:
	detail_region = Control.new(); detail_region.name = "DetailRegion"; detail_region.position = Vector2(804, 118); detail_region.size = Vector2(596, 750); detail_region.clip_contents = true; design_canvas.add_child(detail_region)
	var panel := TextureRect.new(); panel.name = "DetailPanel"; panel.texture = _texture("codex_v5_detail_panel_bg_1192x1448.png"); panel.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; panel.stretch_mode = TextureRect.STRETCH_SCALE; panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); panel.mouse_filter = Control.MOUSE_FILTER_IGNORE; detail_region.add_child(panel)
	detail_status = _label("", 11, Color("316428")); detail_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; detail_status.position = Vector2(350, 42); detail_status.size = Vector2(170, 22); detail_region.add_child(detail_status)
	detail_title = _label("", 36, Color("183a1f")); detail_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; detail_title.position = Vector2(45, 70); detail_title.size = Vector2(510, 45); detail_region.add_child(detail_title)
	detail_subtitle = _label("", 16, Color("4d3218")); detail_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; detail_subtitle.position = Vector2(45, 115); detail_subtitle.size = Vector2(510, 25); detail_region.add_child(detail_subtitle)
	var hero_frame := TextureRect.new(); hero_frame.texture = _texture("codex_v5_detail_hero_frame_1080x584.png"); hero_frame.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; hero_frame.stretch_mode = TextureRect.STRETCH_SCALE; hero_frame.position = Vector2(28, 145); hero_frame.size = Vector2(540, 292); hero_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE; detail_region.add_child(hero_frame)
	hero_art_host = Control.new(); hero_art_host.name = "HeroArtHost"; hero_art_host.position = Vector2(150, 175); hero_art_host.size = Vector2(280, 230); detail_region.add_child(hero_art_host)
	var observation_note := TextureRect.new(); observation_note.name = "ObservationNote"; observation_note.texture = _texture("codex_v5_observation_note_296x140.png"); observation_note.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; observation_note.stretch_mode = TextureRect.STRETCH_SCALE; observation_note.position = DETAIL_OBSERVATION_POS; observation_note.size = DETAIL_OBSERVATION_SIZE; observation_note.mouse_filter = Control.MOUSE_FILTER_IGNORE; detail_region.add_child(observation_note)
	observation_label = _label("", 11, Color("4f3929")); observation_label.name = "ObservationText"; observation_label.position = Vector2(376, 331); observation_label.size = Vector2(145, 60); observation_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; observation_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP; observation_label.mouse_filter = Control.MOUSE_FILTER_IGNORE; detail_region.add_child(observation_label)
	var facts_frame := TextureRect.new(); facts_frame.texture = _texture("codex_v5_facts_panel_bg_1080x428.png"); facts_frame.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; facts_frame.stretch_mode = TextureRect.STRETCH_SCALE; facts_frame.position = Vector2(28, 440); facts_frame.size = Vector2(540, 214); facts_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE; detail_region.add_child(facts_frame)
	facts_box = VBoxContainer.new(); facts_box.name = "Facts"; facts_box.position = Vector2(70, 462); facts_box.size = Vector2(455, 174); facts_box.add_theme_constant_override("separation", 3); detail_region.add_child(facts_box)
	description_label = RichTextLabel.new(); description_label.name = "FlavorText"; description_label.bbcode_enabled = false; description_label.fit_content = false; description_label.scroll_active = true; description_label.position = Vector2(78, 670); description_label.size = Vector2(438, 54); description_label.add_theme_font_override("normal_font", Typography.korean_serif_font()); description_label.add_theme_font_size_override("normal_font_size", 13); description_label.add_theme_color_override("default_color", Color("564334")); description_label.add_theme_stylebox_override("normal", _flat(Color.TRANSPARENT)); _style_scrollbar(description_label.get_v_scroll_bar()); detail_region.add_child(description_label)

func _render_taxonomies(sections: Array, active_section: String) -> void:
	_clear(taxonomy_tabs)
	for section in sections:
		var data: Dictionary = section; var active := str(data.get("id", "")) == active_section; var b := _text_button(str(data.get("label", "")), active, Vector2(112, 30)); var tab_style := _flat(Color.TRANSPARENT, Color("3b692a") if active else Color.TRANSPARENT, 0, 0, 0, 3 if active else 0); tab_style.corner_radius_top_left = 0; tab_style.corner_radius_top_right = 0; tab_style.corner_radius_bottom_left = 0; tab_style.corner_radius_bottom_right = 0; b.add_theme_stylebox_override("normal", tab_style); b.add_theme_stylebox_override("hover", tab_style); b.add_theme_stylebox_override("pressed", tab_style); b.pressed.connect(func(): section_selected.emit(str(data.get("id", "")))); taxonomy_tabs.add_child(b)

func _render_filters(sections: Array, active_section: String, sort_options: Array) -> void:
	_clear(filter_tabs)
	for section in sections:
		var data: Dictionary = section; var b := _text_button(str(data.get("label", "")), str(data.get("id", "")) == active_section, Vector2(80, 28)); b.pressed.connect(func(): section_selected.emit(str(data.get("id", "")))); filter_tabs.add_child(b)
	for option in sort_options:
		var data: Dictionary = option
		if bool(data.get("active", false)):
			var sort := _text_button("정렬: %s ▾" % _sort_label(str(data.get("id", "catalog"))), true, SORT_CONTROL_SIZE); sort.name = "SortDropdown"; sort.add_theme_stylebox_override("normal", _texture_style("codex_v5_sort_dropdown_280x64.png")); sort.add_theme_stylebox_override("hover", _texture_style("codex_v5_sort_dropdown_280x64.png")); sort.add_theme_stylebox_override("pressed", _texture_style("codex_v5_sort_dropdown_280x64.png")); sort.pressed.connect(func(): _show_sort_popup(sort, sort_options)); filter_tabs.add_child(sort); break

func _sort_label(sort_id: String) -> String:
	return {"catalog": "도감", "name": "이름", "rarity": "희귀도"}.get(sort_id, "도감")

func _show_sort_popup(anchor: Control, options: Array) -> void:
	if sort_popup == null:
		sort_popup = PopupMenu.new(); sort_popup.name = "SortPopup"; sort_popup.add_theme_font_override("font", Typography.ui_font()); sort_popup.add_theme_font_size_override("font_size", 12); sort_popup.add_theme_color_override("font_color", Color("3b2918")); sort_popup.add_theme_color_override("font_hover_color", Color("183a1f")); sort_popup.add_theme_stylebox_override("panel", _flat(Color("f4ead1"), Color("786b50"), 1, 4, 4, 4)); sort_popup.add_theme_stylebox_override("hover", _flat(Color("dce8c8"))); design_canvas.add_child(sort_popup)
		sort_popup.id_pressed.connect(func(id: int): sort_selected.emit(str(sort_popup.get_item_metadata(id))))
	sort_popup.clear()
	for option in options:
		var data: Dictionary = option; var index := sort_popup.item_count; sort_popup.add_item(_sort_label(str(data.get("id", "catalog")))); sort_popup.set_item_metadata(index, str(data.get("id", "catalog")))
	sort_popup.position = Vector2i(anchor.global_position + Vector2(0, anchor.size.y)); sort_popup.size = SORT_POPUP_SIZE; sort_popup.popup()

func _render_entries(entries: Array, selected_id: String) -> void:
	_clear(entry_grid)
	if entries.is_empty():
		var empty := _label(TextCatalog.t("codex.empty"), 16, Color("6d6b62")); empty.name = "EmptyCatalog"; empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; empty.custom_minimum_size = Vector2(620, 80); entry_grid.add_child(empty); return
	for item in entries:
		var entry: Dictionary = item; entry_grid.add_child(_entry_card(entry, str(entry.get("id", "")) == selected_id))

func _build_entry_card(entry: Dictionary, selected: bool) -> Button:
	return _entry_card(entry, selected)

func _render_art_placeholder(host: Control, descriptor: Dictionary, _label_text: String = "", _large: bool = false) -> void:
	_clear(host)
	var image := TextureRect.new()
	image.name = "ResolvedArtTexture"
	image.texture = _art_texture(descriptor)
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	image.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if image.texture == null:
		image.name = "PlaceholderPlate"
	host.add_child(image)

func _entry_card(entry: Dictionary, selected: bool) -> Button:
	var button := Button.new(); button.name = "Entry_%s" % str(entry.get("id", "")); button.custom_minimum_size = Vector2(304, 102); button.text = ""; button.add_theme_stylebox_override("normal", _texture_style("codex_v5_card_selected_608x204.png" if selected else ("codex_v5_card_locked_608x204.png" if not bool(entry.get("visible", false)) else "codex_v5_card_normal_608x204.png"))); button.pressed.connect(func(): entry_selected.emit(str(entry.get("id", ""))))
	var thumb := TextureRect.new(); thumb.texture = _texture("codex_v5_locked_thumb_152x152.png") if not bool(entry.get("visible", false)) else _art_texture(entry.get("thumbArt", {})); thumb.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; thumb.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED; thumb.position = Vector2(12, 13); thumb.size = Vector2(76, 76); thumb.mouse_filter = Control.MOUSE_FILTER_IGNORE; button.add_child(thumb)
	var name := _label(str(entry.get("name", "")), 13, Color("3b2918")); name.position = Vector2(104, 20); name.size = Vector2(175, 30); name.mouse_filter = Control.MOUSE_FILTER_IGNORE; button.add_child(name)
	var rarity := _label(str(entry.get("rarity", "")).capitalize(), 12, Color("8b7666")); rarity.position = Vector2(104, 54); rarity.size = Vector2(175, 25); rarity.mouse_filter = Control.MOUSE_FILTER_IGNORE; button.add_child(rarity)
	return button

func _render_detail(data: Dictionary) -> void:
	detail_title.text = str(data.get("title", TextCatalog.t("codex.title"))); detail_subtitle.text = str(data.get("subtitle", "")); detail_status.text = "CATALOGED" if not bool(data.get("empty", true)) else ""; description_label.text = str(data.get("body", "")); observation_label.text = "Observations:\n피해 %.1f / 쿨타임 %d" % [float(data.get("baseDamage", 0.0)), int(data.get("baseCooldownTicks", 0))]; _clear(hero_art_host); _clear(facts_box)
	var art := _art_texture(data.get("heroArt", {})); if art != null:
		var image := TextureRect.new(); image.texture = art; image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED; image.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); hero_art_host.add_child(image)
	facts_box.add_child(_label("▣ Physical Properties", 15, Color("183a1f"), "serif"))
	for pair in [["Class", str(data.get("subtitle", ""))], ["Type", str(data.get("shapeItemType", ""))], ["Shape Configuration", str(data.get("shapeFootprintText", ""))], ["Occupancy Matrix", str(data.get("shapeCellCountText", ""))], ["Cooldown", "%d ticks" % int(data.get("baseCooldownTicks", 0))], ["Base Damage", "%.1f" % float(data.get("baseDamage", 0.0))]]:
		facts_box.add_child(_fact_row(str(pair[0]), str(pair[1])))

func _style_scrollbar(bar: VScrollBar) -> void:
	bar.custom_minimum_size.x = 16.0; bar.add_theme_constant_override("grabber_min_size", 46)
	var invisible := _flat(Color.TRANSPARENT); bar.add_theme_stylebox_override("scroll", invisible); bar.add_theme_stylebox_override("scroll_focus", invisible); bar.add_theme_stylebox_override("grabber", invisible); bar.add_theme_stylebox_override("grabber_highlight", invisible); bar.add_theme_stylebox_override("grabber_pressed", invisible)
	var token := TextureRect.new(); token.name = "CodexScrollToken"; token.texture = _texture("codex_v5_scroll_relic_token.png"); token.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; token.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED; token.size = Vector2(18, 48); token.position.x = -1.0; token.mouse_filter = Control.MOUSE_FILTER_IGNORE; bar.add_child(token)
	bar.value_changed.connect(func(_value: float): _position_scroll_token(bar, token)); bar.resized.connect(func(): _position_scroll_token(bar, token)); bar.changed.connect(func(): _position_scroll_token(bar, token)); call_deferred("_position_scroll_token", bar, token)

func _position_scroll_token(bar: VScrollBar, token: TextureRect) -> void:
	if not is_instance_valid(bar) or not is_instance_valid(token): return
	var available := maxf(0.0, bar.size.y - token.size.y); var span := maxf(0.0, bar.max_value - bar.page); token.position.y = available * (bar.value / span) if span > 0.0 else 0.0

func _scroll_token_style() -> StyleBoxTexture:
	var style := StyleBoxTexture.new(); style.texture = _texture("codex_v5_scroll_relic_token.png"); return style

func _fact_row(label_text: String, value_text: String) -> HBoxContainer:
	var row := HBoxContainer.new(); row.custom_minimum_size = Vector2(455, 18); row.add_theme_constant_override("separation", 10)
	var label := _label(label_text, 12, Color("75664f")); label.custom_minimum_size = Vector2(DETAIL_FACT_LABEL_WIDTH, 18); row.add_child(label)
	var value := _label(value_text, 12, Color("3b2918")); value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT; value.size_flags_horizontal = Control.SIZE_EXPAND_FILL; row.add_child(value)
	return row

func _apply_canvas_layout() -> void:
	if design_canvas == null: return
	var fitted := Layout.canvas_transform_for_viewport(size); design_canvas.position = fitted["position"]; design_canvas.scale = Vector2.ONE * float(fitted["scale"]); design_canvas.size = Layout.DESIGN_SIZE

func _texture(file: String) -> Texture2D:
	var path := "%s/%s" % [V5_ROOT, file]
	if ResourceLoader.exists(path):
		return load(path) as Texture2D
	var image := Image.load_from_file(ProjectSettings.globalize_path(path))
	return ImageTexture.create_from_image(image) if image != null and not image.is_empty() else null

func _art_texture(descriptor: Dictionary) -> Texture2D:
	var path := str(descriptor.get("path", "")); return load(path) as Texture2D if not path.is_empty() and ResourceLoader.exists(path) else null

func _label(text: String, font_size: int, color: Color, role := "ui") -> Label:
	var node := Label.new(); node.text = text; node.add_theme_font_size_override("font_size", font_size); node.add_theme_color_override("font_color", color)
	if role == "serif": node.add_theme_font_override("font", Typography.korean_serif_font())
	else: node.add_theme_font_override("font", Typography.ui_font())
	node.vertical_alignment = VERTICAL_ALIGNMENT_CENTER; return node

func _text_button(text: String, active: bool, minimum: Vector2) -> Button:
	var node := Button.new(); node.text = text; node.custom_minimum_size = minimum; node.add_theme_font_override("font", Typography.ui_font()); node.add_theme_font_size_override("font_size", 12); node.add_theme_color_override("font_color", Color("285322") if active else Color("292f29"))
	if minimum.x >= 80.0:
		var chip_style := _texture_style("codex_v5_chip_active_240x56.png" if active else "codex_v5_chip_inactive_240x56.png")
		node.add_theme_stylebox_override("normal", chip_style); node.add_theme_stylebox_override("hover", chip_style); node.add_theme_stylebox_override("pressed", chip_style); node.add_theme_stylebox_override("focus", chip_style)
	else:
		node.add_theme_stylebox_override("normal", _flat(Color.TRANSPARENT, Color("183a1f") if active else Color.TRANSPARENT, 0, 0, 0, 3 if active else 0))
	return node

func _texture_style(file: String) -> StyleBoxTexture:
	var style := StyleBoxTexture.new(); style.texture = _texture(file); return style

func _flat(bg: Color, border := Color.TRANSPARENT, top := 0, left := 0, right := 0, bottom := 0) -> StyleBoxFlat:
	var style := StyleBoxFlat.new(); style.bg_color = bg; style.border_color = border; style.border_width_top = top; style.border_width_left = left; style.border_width_right = right; style.border_width_bottom = bottom; style.corner_radius_top_left = 5; style.corner_radius_top_right = 5; style.corner_radius_bottom_left = 5; style.corner_radius_bottom_right = 5; return style

func _clear(node: Node) -> void:
	for child in node.get_children(): node.remove_child(child); child.queue_free()
