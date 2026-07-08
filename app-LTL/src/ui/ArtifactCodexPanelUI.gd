# 계약:
# - 책임: 책 기반 아티팩트 도감 UI를 구성하고 read model을 페이지형 레이아웃으로 렌더링한다.
# - 입력: ArtifactCodexReadModel.project() 결과와 debug/section/entry 상호작용.
# - 출력: debug_toggled, section_selected, entry_selected signal과 시각적 페이지 갱신.
# - 금지: reward-table 파일 읽기, run state 직접 변경, 발견 상태 계산.
#
# 실행: define the artifact codex panel UI control.
class_name ArtifactCodexPanelUI
extends PanelContainer

signal debug_toggled(debug_all: bool)
signal entry_selected(entry_id: String)
signal section_selected(section_id: String)

const TextCatalogScript = preload("res://src/ui/TextCatalog.gd")
const BOOK_TEXTURE = preload("res://resources/UI/ItemBook.png")
const ArtifactCodexLayoutPolicyScript = preload("res://src/ui/codex/ArtifactCodexLayoutPolicy.gd")
const ArtifactCodexBookVisualFactoryScript = preload("res://src/ui/codex/ArtifactCodexBookVisualFactory.gd")

const BOOK_PIXEL_SIZE := ArtifactCodexLayoutPolicyScript.BOOK_PIXEL_SIZE

var book_center: Control
var book_aspect: Control
var book_root: Control
var spread: Control
var header_bar: HBoxContainer
var title_label: Label
var count_label: Label
var debug_check: CheckBox
var close_button: Button
var left_page: Control
var right_page: Control
var left_scroll: ScrollContainer
var right_scroll: ScrollContainer
var left_content: VBoxContainer
var right_content: VBoxContainer
var left_title_label: Label
var left_subtitle_label: Label
var hero_shell: PanelContainer
var hero_art_host: Control
var hero_badge_label: Label
var fact_row: HBoxContainer
var shape_section: VBoxContainer
var shape_title_label: Label
var shape_detail_label: Label
var shape_grid: GridContainer
var description_label: RichTextLabel
var illustration_hint_label: Label
var section_tabs: HBoxContainer
var right_summary_label: Label
var grid: GridContainer
var empty_label: Label
var last_model: Dictionary = {}
var _built := false

# 실행: construct the book shell once the node enters the tree.
func _ready() -> void:
	if _built:
		return
	_built = true
	visible = false
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	add_theme_stylebox_override("panel", _transparent_panel_style())
	_build_book_shell()
	_build_left_page()
	_build_right_page()
	apply_locale()
	call_deferred("_apply_book_layout")

# 실행: keep the spread aligned to the book image whenever the panel resizes.
func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and _built:
		call_deferred("_apply_book_layout")

# 실행: expose ratio-driven book safe-area math for deterministic tests and layout.
func book_layout_metrics_for_rect(book_rect: Rect2) -> Dictionary:
	return ArtifactCodexLayoutPolicyScript.book_layout_metrics_for_rect(book_rect)

# 실행: refresh static panel text after locale changes.
func apply_locale() -> void:
	if not _built:
		return
	title_label.text = TextCatalogScript.t("codex.title")
	debug_check.text = TextCatalogScript.t("codex.debug_all")
	close_button.text = TextCatalogScript.t("action.close")
	if not last_model.is_empty():
		render_codex(last_model)

# 실행: render a projected codex model into the book panel.
func render_codex(model: Dictionary) -> void:
	if not _built:
		_ready()
	last_model = model.duplicate(true)
	title_label.text = str(model.get("title", TextCatalogScript.t("codex.title")))
	count_label.text = TextCatalogScript.t(
		"codex.discovered_count",
		[int(model.get("discoveredCount", 0)), int(model.get("totalCount", 0))]
	)
	debug_check.set_pressed_no_signal(bool(model.get("debugAll", false)))
	_render_sections(model.get("sections", []), str(model.get("activeSection", "all")))
	_render_left_page(model.get("leftPage", {}))
	_render_right_page(model.get("rightPage", {}), str(model.get("resolvedSelectedEntryId", "")))
	call_deferred("_apply_book_layout")

# 실행: construct the global shell, overlay, book frame, and shared header.
func _build_book_shell() -> void:
	var overlay := ColorRect.new()
	overlay.name = "OverlayShade"
	overlay.color = Color(0.02, 0.015, 0.01, 0.68)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(overlay)

	book_center = Control.new()
	book_center.name = "BookCenter"
	book_center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(book_center)

	book_aspect = Control.new()
	book_aspect.name = "BookAspect"
	book_aspect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	book_center.add_child(book_aspect)

	book_root = Control.new()
	book_root.name = "BookRoot"
	book_root.size = BOOK_PIXEL_SIZE
	book_aspect.add_child(book_root)

	var book_frame := TextureRect.new()
	book_frame.name = "BookFrame"
	book_frame.texture = BOOK_TEXTURE
	book_frame.texture_filter = Control.TEXTURE_FILTER_NEAREST
	book_frame.stretch_mode = TextureRect.STRETCH_SCALE
	book_frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	book_root.add_child(book_frame)

	spread = Control.new()
	spread.name = "Spread"
	book_root.add_child(spread)

	header_bar = HBoxContainer.new()
	header_bar.name = "HeaderBar"
	header_bar.alignment = BoxContainer.ALIGNMENT_BEGIN
	header_bar.add_theme_constant_override("separation", 14)
	spread.add_child(header_bar)

	title_label = Label.new()
	title_label.name = "TitleLabel"
	title_label.add_theme_font_size_override("font_size", 30)
	title_label.add_theme_color_override("font_color", Color(0.31, 0.20, 0.09, 1.0))
	header_bar.add_child(title_label)

	count_label = Label.new()
	count_label.name = "CountLabel"
	count_label.add_theme_font_size_override("font_size", 16)
	count_label.add_theme_color_override("font_color", Color(0.41, 0.28, 0.13, 0.96))
	header_bar.add_child(count_label)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_bar.add_child(spacer)

	debug_check = CheckBox.new()
	debug_check.name = "DebugCheck"
	debug_check.add_theme_font_size_override("font_size", 12)
	debug_check.add_theme_color_override("font_color", Color(0.30, 0.22, 0.12, 0.95))
	debug_check.toggled.connect(func(enabled: bool): debug_toggled.emit(enabled))
	header_bar.add_child(debug_check)

	close_button = Button.new()
	close_button.name = "CloseButton"
	close_button.custom_minimum_size = Vector2(92.0, 20.0)
	close_button.pressed.connect(func(): visible = false)
	_style_small_action_button(close_button)
	left_page = Control.new()
	left_page.name = "LeftPage"
	spread.add_child(left_page)

	right_page = Control.new()
	right_page.name = "RightPage"
	spread.add_child(right_page)

	header_bar.add_child(close_button)
	header_bar.z_index = 3
	header_bar.top_level = false

# 실행: construct the detailed left page with its own scroll container.
func _build_left_page() -> void:
	left_scroll = ScrollContainer.new()
	left_scroll.name = "LeftScroll"
	left_scroll.follow_focus = true
	left_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	left_page.add_child(left_scroll)

	left_content = VBoxContainer.new()
	left_content.name = "LeftContent"
	left_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_content.add_theme_constant_override("separation", 14)
	left_scroll.add_child(left_content)

	left_title_label = Label.new()
	left_title_label.name = "EntryTitle"
	left_title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	left_title_label.add_theme_font_size_override("font_size", 28)
	left_title_label.add_theme_color_override("font_color", Color(0.28, 0.16, 0.07, 1.0))
	left_content.add_child(left_title_label)

	left_subtitle_label = Label.new()
	left_subtitle_label.name = "EntrySubtitle"
	left_subtitle_label.add_theme_font_size_override("font_size", 15)
	left_subtitle_label.add_theme_color_override("font_color", Color(0.44, 0.31, 0.16, 0.92))
	left_content.add_child(left_subtitle_label)

	hero_shell = PanelContainer.new()
	hero_shell.name = "HeroShell"
	hero_shell.clip_contents = true
	hero_shell.add_theme_stylebox_override("panel", _hero_frame_style())
	left_content.add_child(hero_shell)

	hero_art_host = Control.new()
	hero_art_host.name = "HeroArtHost"
	hero_art_host.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hero_shell.add_child(hero_art_host)

	hero_badge_label = Label.new()
	hero_badge_label.name = "HeroBadge"
	hero_badge_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hero_badge_label.add_theme_font_size_override("font_size", 13)
	hero_badge_label.add_theme_color_override("font_color", Color(0.42, 0.28, 0.14, 0.95))
	left_content.add_child(hero_badge_label)

	fact_row = HBoxContainer.new()
	fact_row.name = "FactRow"
	fact_row.alignment = BoxContainer.ALIGNMENT_BEGIN
	fact_row.add_theme_constant_override("separation", 8)
	left_content.add_child(fact_row)

	shape_section = VBoxContainer.new()
	shape_section.name = "ShapeSection"
	shape_section.visible = false
	shape_section.add_theme_constant_override("separation", 6)
	left_content.add_child(shape_section)

	shape_title_label = Label.new()
	shape_title_label.name = "ShapeTitle"
	shape_title_label.add_theme_font_size_override("font_size", 13)
	shape_title_label.add_theme_color_override("font_color", Color(0.36, 0.24, 0.11, 0.96))
	shape_section.add_child(shape_title_label)

	shape_detail_label = Label.new()
	shape_detail_label.name = "ShapeDetail"
	shape_detail_label.add_theme_font_size_override("font_size", 12)
	shape_detail_label.add_theme_color_override("font_color", Color(0.45, 0.33, 0.18, 0.92))
	shape_section.add_child(shape_detail_label)

	shape_grid = GridContainer.new()
	shape_grid.name = "ShapeGrid"
	shape_grid.columns = 1
	shape_grid.add_theme_constant_override("h_separation", 4)
	shape_grid.add_theme_constant_override("v_separation", 4)
	shape_section.add_child(shape_grid)

	description_label = RichTextLabel.new()
	description_label.name = "Description"
	description_label.fit_content = true
	description_label.scroll_active = false
	description_label.bbcode_enabled = false
	description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description_label.add_theme_font_size_override("normal_font_size", 15)
	description_label.add_theme_color_override("default_color", Color(0.20, 0.14, 0.08, 0.96))
	left_content.add_child(description_label)

	illustration_hint_label = Label.new()
	illustration_hint_label.name = "IllustrationHint"
	illustration_hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	illustration_hint_label.add_theme_font_size_override("font_size", 11)
	illustration_hint_label.add_theme_color_override("font_color", Color(0.48, 0.38, 0.24, 0.85))
	left_content.add_child(illustration_hint_label)

# 실행: construct the right page with tabs, summary, and a separate grid scroll container.
func _build_right_page() -> void:
	section_tabs = HBoxContainer.new()
	section_tabs.name = "SectionTabs"
	section_tabs.alignment = BoxContainer.ALIGNMENT_BEGIN
	section_tabs.add_theme_constant_override("separation", 10)
	right_page.add_child(section_tabs)

	right_summary_label = Label.new()
	right_summary_label.name = "RightSummary"
	right_summary_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	right_summary_label.add_theme_font_size_override("font_size", 15)
	right_summary_label.add_theme_color_override("font_color", Color(0.39, 0.28, 0.14, 0.96))
	right_page.add_child(right_summary_label)

	right_scroll = ScrollContainer.new()
	right_scroll.name = "RightScroll"
	right_scroll.follow_focus = true
	right_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	right_page.add_child(right_scroll)

	right_content = VBoxContainer.new()
	right_content.name = "RightContent"
	right_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_content.add_theme_constant_override("separation", 12)
	right_scroll.add_child(right_content)

	grid = GridContainer.new()
	grid.name = "EntryGrid"
	grid.columns = 3
	right_content.add_child(grid)

	empty_label = Label.new()
	empty_label.name = "EmptyLabel"
	empty_label.visible = false
	empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	empty_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	empty_label.add_theme_font_size_override("font_size", 15)
	empty_label.add_theme_color_override("font_color", Color(0.47, 0.34, 0.18, 0.94))
	right_content.add_child(empty_label)

# 실행: position every major page element inside the book safe area.
func _apply_book_layout() -> void:
	if not _built:
		return
	var fitted := _book_transform_for_viewport(size)
	book_root.position = fitted["position"]
	book_root.scale = Vector2.ONE * float(fitted["scale"])
	book_root.size = BOOK_PIXEL_SIZE

	var metrics := book_layout_metrics_for_rect(Rect2(Vector2.ZERO, BOOK_PIXEL_SIZE))
	spread.position = Vector2(float(metrics["outerLeft"]), float(metrics["outerTop"]))
	spread.size = Vector2(float(metrics["safeWidth"]), float(metrics["safeHeight"]))

	var page_width := float(metrics["pageWidth"])
	var page_height := float(metrics["pageHeight"])
	var gutter := float(metrics["gutter"])
	var page_padding_x := float(metrics["pagePaddingX"])
	var page_padding_y := float(metrics["pagePaddingY"])
	var header_height := float(metrics["headerHeight"])
	var tabs_height := float(metrics["tabsHeight"])
	var summary_height := float(metrics["summaryHeight"])
	var page_gap := float(metrics["pageGap"])
	header_bar.position = Vector2(page_padding_x, page_padding_y * 0.18)
	header_bar.size = Vector2(spread.size.x - page_padding_x * 2.0, header_height)
	var content_top := header_bar.position.y + header_height + page_gap
	var usable_page_height := maxf(0.0, page_height - content_top)

	left_page.position = Vector2(0.0, content_top)
	left_page.size = Vector2(page_width, usable_page_height)
	right_page.position = Vector2(page_width + gutter, content_top)
	right_page.size = Vector2(page_width, usable_page_height)

	left_scroll.position = Vector2(page_padding_x, page_padding_y)
	left_scroll.size = Vector2(page_width - page_padding_x * 2.0, maxf(0.0, left_page.size.y - page_padding_y * 2.0))
	left_content.custom_minimum_size.x = maxf(0.0, left_scroll.size.x - 18.0)
	left_title_label.custom_minimum_size.x = left_content.custom_minimum_size.x
	left_subtitle_label.custom_minimum_size.x = left_content.custom_minimum_size.x
	description_label.custom_minimum_size.x = left_content.custom_minimum_size.x
	illustration_hint_label.custom_minimum_size.x = left_content.custom_minimum_size.x
	hero_shell.custom_minimum_size = Vector2(left_content.custom_minimum_size.x, minf(float(metrics["heroHeight"]), left_scroll.size.y * 0.42))

	section_tabs.position = Vector2(page_padding_x, page_padding_y)
	section_tabs.size = Vector2(page_width - page_padding_x * 2.0, tabs_height)

	right_summary_label.position = Vector2(page_padding_x, section_tabs.position.y + tabs_height + page_gap * 0.35)
	right_summary_label.size = Vector2(page_width - page_padding_x * 2.0, summary_height)

	right_scroll.position = Vector2(page_padding_x, right_summary_label.position.y + summary_height + page_gap)
	right_scroll.size = Vector2(page_width - page_padding_x * 2.0, maxf(0.0, right_page.size.y - right_scroll.position.y - page_padding_y))
	right_content.custom_minimum_size.x = maxf(0.0, right_scroll.size.x - 16.0)
	grid.columns = int(metrics["gridColumns"])
	grid.add_theme_constant_override("h_separation", int(metrics["gridGap"]))
	grid.add_theme_constant_override("v_separation", int(metrics["gridGap"]))
	_resize_grid_cards(Vector2(float(metrics["cardWidth"]), float(metrics["cardHeight"])))

# 실행: rebuild the top tab row from the projected section payload.
func _render_sections(sections: Array, active_section: String) -> void:
	_clear_children(section_tabs)
	var active_payload := {}
	for section in sections:
		var payload: Dictionary = section
		if str(payload.get("id", "")) == active_section:
			active_payload = payload
		var button := Button.new()
		button.text = str(payload.get("label", ""))
		button.custom_minimum_size = Vector2(96.0, 22.0)
		_style_section_button(button, bool(payload.get("active", false)))
		button.pressed.connect(_on_section_button_pressed.bind(str(payload.get("id", ""))))
		section_tabs.add_child(button)
	if active_payload.is_empty() and not sections.is_empty():
		active_payload = sections[0]
	right_summary_label.text = TextCatalogScript.t(
		"codex.discovered_count",
		[int(active_payload.get("discoveredCount", 0)), int(active_payload.get("count", 0))]
	)

# 실행: populate the left detail page from the resolved selected entry payload.
func _render_left_page(left_page_model: Dictionary) -> void:
	left_title_label.text = str(left_page_model.get("title", TextCatalogScript.t("codex.title")))
	left_subtitle_label.text = str(left_page_model.get("subtitle", ""))
	description_label.text = str(left_page_model.get("body", TextCatalogScript.t("codex.empty")))
	hero_badge_label.text = str(left_page_model.get("badge", ""))
	hero_badge_label.visible = not hero_badge_label.text.is_empty()
	_render_fact_chips(left_page_model.get("factChips", []))
	_render_shape_info(left_page_model)
	var hero_art: Dictionary = left_page_model.get("heroArt", {})
	_render_art_placeholder(hero_art_host, hero_art, str(left_page_model.get("title", "")), true)
	var requested_path := str(hero_art.get("requestedPath", ""))
	var resolved_path := str(hero_art.get("path", ""))
	var resolved_source := str(hero_art.get("source", ""))
	if not requested_path.is_empty() and requested_path != resolved_path and resolved_source in ["fallback", "missing"]:
		illustration_hint_label.text = "%s (%s)" % [
			str(left_page_model.get("missingArtText", TextCatalogScript.t("codex.missing_art"))),
			str(hero_art.get("iconKey", ""))
		]
		illustration_hint_label.visible = true
	else:
		illustration_hint_label.visible = false

# 실행: populate the right grid page from the projected grid entries.
func _render_right_page(right_page_model: Dictionary, selected_entry_id: String) -> void:
	_clear_children(grid)
	var entries: Array = right_page_model.get("gridEntries", [])
	empty_label.text = str(right_page_model.get("emptyText", TextCatalogScript.t("codex.empty")))
	empty_label.visible = entries.is_empty()
	for entry in entries:
		var payload: Dictionary = entry
		var button := _build_entry_card(payload, str(payload.get("id", "")) == selected_entry_id)
		grid.add_child(button)

# 실행: build one right-page card with image and grade-only emphasis.
func _build_entry_card(entry: Dictionary, selected: bool) -> Button:
	return ArtifactCodexBookVisualFactoryScript.build_entry_card(entry, selected, Callable(self, "_on_entry_card_pressed"))

# 실행: render either a future real illustration or a high-quality placeholder composition.
func _render_art_placeholder(host: Control, descriptor: Dictionary, label_text: String, large: bool) -> void:
	ArtifactCodexBookVisualFactoryScript.render_art_placeholder(host, descriptor, label_text, large)

# 실행: rebuild the left-page chip strip.
func _render_fact_chips(facts: Array) -> void:
	ArtifactCodexBookVisualFactoryScript.render_fact_chips(fact_row, facts)

func _render_shape_info(left_page_model: Dictionary) -> void:
	ArtifactCodexBookVisualFactoryScript.render_shape_info(self, left_page_model)

# 실행: resize cards after the safe-area math changes with the book rect.
func _resize_grid_cards(card_size: Vector2) -> void:
	for child in grid.get_children():
		if child is Button:
			child.custom_minimum_size = card_size

# 실행: route section-button presses back to the runtime owner.
func _on_section_button_pressed(section_id: String) -> void:
	section_selected.emit(section_id)

# 실행: route card selection presses back to the runtime owner.
func _on_entry_card_pressed(entry_id: String) -> void:
	entry_selected.emit(entry_id)

# 실행: remove all previous child nodes from a container before rerendering.
func _clear_children(node: Node) -> void:
	for child in node.get_children():
		node.remove_child(child)
		child.queue_free()

# 실행: fit the native book surface inside the current viewport and return the top-left plus scale.
func _book_transform_for_viewport(view_size: Vector2) -> Dictionary:
	return ArtifactCodexLayoutPolicyScript.book_transform_for_viewport(view_size)

# 실행: style the top-right close button to match the book brass language.
func _style_small_action_button(button: Button) -> void:
	ArtifactCodexBookVisualFactoryScript.style_small_action_button(button)

# 실행: style a section tab for active and inactive states.
func _style_section_button(button: Button, active: bool) -> void:
	ArtifactCodexBookVisualFactoryScript.style_section_button(button, active)

# 실행: build the hero-frame style used on the detailed left page.
func _hero_frame_style() -> StyleBoxFlat:
	return ArtifactCodexBookVisualFactoryScript.hero_frame_style()

# 실행: return a transparent root panel style because the book art supplies the visible frame.
func _transparent_panel_style() -> StyleBoxFlat:
	return ArtifactCodexBookVisualFactoryScript.transparent_panel_style()
