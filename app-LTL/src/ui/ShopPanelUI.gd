# 계약:
# - 책임: 보급 캠프 상점 오버레이(카탈로그 + 상세)를 1440x900 고정 캔버스로 조합하고 read model을 렌더링한다.
# - 입력: growth state Dictionary와 탭/카드/구매/닫기 입력.
# - 출력: buy_passive(passive_id, cost), buy_base_item(item_id), entry_selected(entry_id) signal과 패널 visibility.
# - 금지: run state 직접 변경, MainController 직접 접근, combat/reward 규칙 계산, 가격·효과 수치 재정의.
#
# 실행: define the supply-camp shop overlay control.
class_name ShopPanelUI
extends PanelContainer

signal buy_passive(passive_id: String, cost: int)
signal buy_base_item(item_id: String)
signal entry_selected(entry_id: String)

const TextCatalogScript = preload("res://src/ui/TextCatalog.gd")
const ReleaseContentVocabScript = preload("res://src/vocabulary/ReleaseContentVocab.gd")
const ShopReadModelScript = preload("res://src/ui/read_models/ShopReadModel.gd")
const Layout = preload("res://src/ui/shop/ShopLayoutPolicy.gd")
const Visual = preload("res://src/ui/shop/ShopVisualFactory.gd")

# 계약: SHOP_ENABLED는 기획 결정(상점 비활성)이며 시각 리디자인 작업 범위 밖이다. 변경 금지.
const SHOP_ENABLED := false

const PASSIVES := [
	{"id": "starting_gold_boost", "base_cost": 50, "step": 50},
	{"id": "cooldown_reduction", "base_cost": 75, "step": 75},
	{"id": "aim_damage_boost", "base_cost": 100, "step": 100}
]

var design_canvas: Control
var title_label: Label
var kicker_label: Label
var location_label: Label
var gold_chip: Control
var xp_chip: Control
var close_button: Button
var footer_close_button: Button
var footer_hint_label: Label
var tabs_row: HBoxContainer
var catalog_grid: GridContainer
var detail_region: Control
var detail_badge: Label
var detail_title: Label
var detail_subtitle: Label
var detail_hero: TextureRect
var detail_effect_header: Control
var detail_effect_label: Label
var detail_notes_header: Control
var detail_notes_label: Label
var detail_ledger: VBoxContainer
var detail_cost_caption: Label
var detail_cost_row: HBoxContainer
var detail_cta: Button

var base_shop_items: Array = []
var current_state: Dictionary = {}
var current_selected_entry_id: String = ""
var current_active_section: String = "passive"
var last_model: Dictionary = {}
var _built := false

# 실행: 오버레이 셸을 한 번만 구성한다.
func _ready() -> void:
	if _built:
		return
	_built = true
	visible = false
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	add_theme_stylebox_override("panel", Visual.flat(Color.TRANSPARENT))
	base_shop_items = ReleaseContentVocabScript.load_content_bundle().get("baseShop", [])
	_build_shell()
	apply_locale()
	call_deferred("_apply_canvas_layout")

# 실행: 뷰포트 크기가 바뀌면 고정 캔버스를 다시 맞춘다.
func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and _built:
		call_deferred("_apply_canvas_layout")

# 실행: locale 변경 후 정적 텍스트와 현재 상태를 다시 렌더링한다.
func apply_locale() -> void:
	if not _built:
		return
	kicker_label.text = TextCatalogScript.t("shop.camp_kicker")
	title_label.text = TextCatalogScript.t("shop.camp_title")
	location_label.text = TextCatalogScript.t("shop.camp_location")
	footer_hint_label.text = TextCatalogScript.t("shop.detail.hint")
	footer_close_button.text = TextCatalogScript.t("action.close")
	render_shop(current_state)

# 실행: growth state를 read model로 투영해 오버레이 전체를 렌더링한다.
func render_shop(growth_state: Dictionary) -> void:
	if not _built:
		_ready()
	current_state = growth_state.duplicate(true)
	var model := ShopReadModelScript.project(
		current_state,
		PASSIVES,
		base_shop_items,
		current_selected_entry_id,
		current_active_section,
		SHOP_ENABLED
	)
	last_model = model
	current_selected_entry_id = str(model.get("resolvedSelectedEntryId", ""))
	current_active_section = str(model.get("activeSection", "passive"))
	_render_wallet(model)
	_render_tabs(model.get("sections", []))
	_render_catalog(model.get("entries", []))
	_render_detail(model.get("detail", {}))

# 실행: 카탈로그 탭을 전환한다(표시 전용 상태).
func select_section(section_id: String) -> void:
	if current_active_section == section_id:
		return
	current_active_section = section_id
	render_shop(current_state)

# 실행: 카탈로그 항목을 선택해 상세 패널을 갱신한다(표시 전용 상태).
func select_entry(entry_id: String) -> void:
	if current_selected_entry_id == entry_id:
		return
	current_selected_entry_id = entry_id
	entry_selected.emit(entry_id)
	render_shop(current_state)

# 실행: 딤 배경 + 양피지 오버레이 카드 + 헤더/카탈로그/상세/푸터를 구성한다.
func _build_shell() -> void:
	var shade := TextureRect.new()
	shade.name = "OverlayShade"
	shade.texture = Visual.texture("shop_dim_backdrop_1440x900.png")
	shade.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	shade.stretch_mode = TextureRect.STRETCH_SCALE
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(shade)

	var viewport := Control.new()
	viewport.name = "ShopViewport"
	viewport.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	viewport.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(viewport)

	design_canvas = Control.new()
	design_canvas.name = "DesignCanvas"
	design_canvas.size = Layout.DESIGN_SIZE
	design_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	viewport.add_child(design_canvas)

	var regions: Dictionary = Layout.regions()
	var card_rect: Rect2 = regions["overlayCard"]
	# Panel(비-Container)을 쓰는 이유: PanelContainer는 자식을 콘텐츠 rect로 강제 리사이즈해
	# 절대 좌표 기반 1440x900 캔버스 기하를 파괴한다(codex v5 선례).
	var card := Panel.new()
	card.name = "OverlayCard"
	card.position = card_rect.position
	card.size = card_rect.size
	card.add_theme_stylebox_override("panel", Visual.texture_style("shop_overlay_card_640x800.png", 44))
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	design_canvas.add_child(card)

	_build_header(regions["header"])
	_build_catalog(regions["catalog"])
	_build_detail(regions["detail"])
	_build_footer(regions["footer"])

# 실행: 헤더(kicker/제목/위치 + 잔액 칩 + 닫기 ×)를 구성한다.
func _build_header(rect: Rect2) -> void:
	var header := Control.new()
	header.name = "Header"
	header.position = rect.position
	header.size = rect.size
	header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	design_canvas.add_child(header)

	kicker_label = Visual.label("", 12, Visual.LEAF)
	kicker_label.name = "Kicker"
	kicker_label.position = Vector2(0, 0)
	kicker_label.size = Vector2(500, 16)
	header.add_child(kicker_label)

	title_label = Visual.label("", 40, Visual.DEEP, "serif")
	title_label.name = "Title"
	title_label.position = Vector2(-2, 18)
	title_label.size = Vector2(500, 48)
	header.add_child(title_label)

	location_label = Visual.label("", 15, Color("5c3f2a"), "serif")
	location_label.name = "Location"
	location_label.position = Vector2(0, 70)
	location_label.size = Vector2(600, 22)
	header.add_child(location_label)

	var wallet := HBoxContainer.new()
	wallet.name = "Wallet"
	wallet.alignment = BoxContainer.ALIGNMENT_END
	wallet.add_theme_constant_override("separation", 10)
	wallet.position = Vector2(rect.size.x - 420, 8)
	wallet.size = Vector2(420, 40)
	header.add_child(wallet)

	gold_chip = Visual.wallet_chip("shop_icon_gold_24.png", TextCatalogScript.t("shop.gold_caption"), "0")
	gold_chip.name = "GoldChip"
	wallet.add_child(gold_chip)
	xp_chip = Visual.wallet_chip("shop_icon_xp_24.png", TextCatalogScript.t("shop.xp_caption"), "0")
	xp_chip.name = "XpChip"
	wallet.add_child(xp_chip)
	close_button = Visual.ghost_close_button(func(): visible = false)
	close_button.name = "CloseButton"
	wallet.add_child(close_button)

	var rule := Visual.dashed_rule()
	rule.name = "HeaderRule"
	rule.position = Vector2(0, rect.size.y + 6)
	rule.size = Vector2(rect.size.x, 2)
	header.add_child(rule)

# 실행: 카탈로그(탭 + 2열 카드 그리드 + 잎 워터마크)를 구성한다.
func _build_catalog(rect: Rect2) -> void:
	var catalog := Control.new()
	catalog.name = "CatalogRegion"
	catalog.position = rect.position
	catalog.size = rect.size
	catalog.mouse_filter = Control.MOUSE_FILTER_IGNORE
	design_canvas.add_child(catalog)

	tabs_row = HBoxContainer.new()
	tabs_row.name = "CatalogTabs"
	tabs_row.add_theme_constant_override("separation", 6)
	tabs_row.position = Vector2(0, 0)
	tabs_row.size = Vector2(rect.size.x, 34)
	catalog.add_child(tabs_row)

	var list_panel := Panel.new()
	list_panel.name = "CatalogPanel"
	list_panel.position = Vector2(0, 46)
	list_panel.size = Vector2(rect.size.x, rect.size.y - 46)
	list_panel.add_theme_stylebox_override("panel", Visual.texture_style("shop_catalog_panel_380x560.png", 30))
	list_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	catalog.add_child(list_panel)

	var watermark := TextureRect.new()
	watermark.name = "LeafWatermark"
	watermark.texture = Visual.texture("shop_leaf_watermark_150.png")
	watermark.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	watermark.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	watermark.modulate = Color(1, 1, 1, 0.16)
	watermark.position = Vector2(list_panel.size.x - 176, list_panel.size.y - 168)
	watermark.size = Vector2(150, 150)
	watermark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	list_panel.add_child(watermark)

	var metrics: Dictionary = Layout.catalog_grid_metrics()
	var padding: Vector2 = metrics["padding"]
	catalog_grid = GridContainer.new()
	catalog_grid.name = "CatalogGrid"
	catalog_grid.columns = int(metrics["columns"])
	catalog_grid.add_theme_constant_override("h_separation", int(metrics["hSeparation"]))
	catalog_grid.add_theme_constant_override("v_separation", int(metrics["vSeparation"]))
	catalog_grid.position = padding
	catalog_grid.size = Vector2(list_panel.size.x - padding.x * 2.0, list_panel.size.y - padding.y * 2.0)
	list_panel.add_child(catalog_grid)

# 실행: 상세 패널(배지/제목/히어로/Effect/Field Notes/원장/CTA)을 구성한다.
func _build_detail(rect: Rect2) -> void:
	detail_region = Control.new()
	detail_region.name = "DetailRegion"
	detail_region.position = rect.position
	detail_region.size = rect.size
	detail_region.clip_contents = true
	detail_region.mouse_filter = Control.MOUSE_FILTER_IGNORE
	design_canvas.add_child(detail_region)

	var panel := Panel.new()
	panel.name = "DetailPanel"
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.add_theme_stylebox_override("panel", Visual.texture_style("shop_detail_panel_560x740.png", 32))
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	detail_region.add_child(panel)

	var inner := 20.0
	var content_width := rect.size.x - inner * 2.0

	var badge_shell := PanelContainer.new()
	badge_shell.name = "DetailBadge"
	badge_shell.position = Vector2(inner, inner)
	var badge_style := Visual.flat(Color(0.722, 0.933, 0.627, 0.55), Color.TRANSPARENT, 0, 10)
	badge_style.content_margin_left = 12
	badge_style.content_margin_right = 12
	badge_style.content_margin_top = 4
	badge_style.content_margin_bottom = 4
	badge_shell.add_theme_stylebox_override("panel", badge_style)
	badge_shell.mouse_filter = Control.MOUSE_FILTER_IGNORE
	detail_region.add_child(badge_shell)
	detail_badge = Visual.label("", 11, Visual.MOSS)
	badge_shell.add_child(detail_badge)

	detail_title = Visual.label("", 29, Visual.DEEP, "serif")
	detail_title.name = "DetailTitle"
	detail_title.position = Vector2(inner, 54)
	detail_title.size = Vector2(content_width, 38)
	detail_region.add_child(detail_title)

	detail_subtitle = Visual.label("", 12, Visual.OUTLINE)
	detail_subtitle.name = "DetailSubtitle"
	detail_subtitle.position = Vector2(inner, 94)
	detail_subtitle.size = Vector2(content_width, 18)
	detail_region.add_child(detail_subtitle)

	# 히어로: 가시 픽셀 외곽이 프레임 내곽을 채우도록 COVERED 스케일 + 클립(A3 정렬 요구).
	var hero_shell := Control.new()
	hero_shell.name = "HeroShell"
	hero_shell.position = Vector2(inner, 118)
	hero_shell.size = Vector2(content_width, 168)
	hero_shell.clip_contents = true
	hero_shell.mouse_filter = Control.MOUSE_FILTER_IGNORE
	detail_region.add_child(hero_shell)
	var hero_bg := ColorRect.new()
	hero_bg.name = "HeroPlate"
	hero_bg.color = Color("241f14")
	hero_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hero_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hero_shell.add_child(hero_bg)
	detail_hero = TextureRect.new()
	detail_hero.name = "HeroArt"
	detail_hero.texture = Visual.texture("shop_hero_seed_280x280.png")
	detail_hero.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	detail_hero.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	detail_hero.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	detail_hero.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hero_shell.add_child(detail_hero)
	var hero_caption := Visual.label(TextCatalogScript.t("shop.detail.figure"), 10, Color("e8e2cf"), "serif")
	hero_caption.name = "HeroCaption"
	hero_caption.position = Vector2(content_width - 178, 144)
	hero_caption.size = Vector2(170, 16)
	hero_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hero_shell.add_child(hero_caption)

	detail_effect_header = Visual.detail_section_header("")
	detail_effect_header.name = "EffectHeader"
	detail_effect_header.position = Vector2(inner, 296)
	detail_effect_header.size = Vector2(content_width, 18)
	detail_region.add_child(detail_effect_header)

	detail_effect_label = Visual.label("", 13, Color("3a2c1c"), "serif")
	detail_effect_label.name = "EffectText"
	detail_effect_label.position = Vector2(inner, 318)
	detail_effect_label.size = Vector2(content_width, 42)
	detail_effect_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail_effect_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	detail_region.add_child(detail_effect_label)

	detail_notes_header = Visual.detail_section_header("")
	detail_notes_header.name = "NotesHeader"
	detail_notes_header.position = Vector2(inner, 362)
	detail_notes_header.size = Vector2(content_width, 18)
	detail_region.add_child(detail_notes_header)

	detail_notes_label = Visual.label("", 12, Color("6a5747"), "serif")
	detail_notes_label.name = "NotesText"
	detail_notes_label.position = Vector2(inner, 384)
	detail_notes_label.size = Vector2(content_width, 44)
	detail_notes_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail_notes_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	detail_region.add_child(detail_notes_label)

	detail_ledger = VBoxContainer.new()
	detail_ledger.name = "DetailLedger"
	detail_ledger.add_theme_constant_override("separation", 0)
	detail_ledger.position = Vector2(inner, 432)
	detail_ledger.size = Vector2(content_width, 81)
	detail_ledger.custom_minimum_size = Vector2(content_width, 81)
	detail_region.add_child(detail_ledger)

	var cost_shell := Panel.new()
	cost_shell.name = "CostShell"
	cost_shell.position = Vector2(inner, 512)
	cost_shell.size = Vector2(content_width - 190, 56)
	cost_shell.add_theme_stylebox_override("panel", Visual.flat(Color(0.910, 0.937, 0.820, 0.7), Color(0.435, 0.631, 0.357, 0.45), 1, 8))
	cost_shell.mouse_filter = Control.MOUSE_FILTER_IGNORE
	detail_region.add_child(cost_shell)
	detail_cost_caption = Visual.label("", 10, Visual.OUTLINE)
	detail_cost_caption.name = "CostCaption"
	detail_cost_caption.position = Vector2(14, 8)
	detail_cost_caption.size = Vector2(160, 14)
	cost_shell.add_child(detail_cost_caption)
	detail_cost_row = HBoxContainer.new()
	detail_cost_row.name = "CostRow"
	detail_cost_row.add_theme_constant_override("separation", 14)
	detail_cost_row.position = Vector2(14, 24)
	detail_cost_row.size = Vector2(content_width - 220, 26)
	detail_cost_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cost_shell.add_child(detail_cost_row)

	detail_cta = Visual.cta_button("", false, Vector2(176, 52), func(): _on_cta_pressed())
	detail_cta.name = "DetailCta"
	detail_cta.position = Vector2(rect.size.x - inner - 176, 514)
	detail_cta.size = Vector2(176, 52)
	detail_region.add_child(detail_cta)

# 실행: 푸터(선택 힌트 + 닫기)를 구성한다.
func _build_footer(rect: Rect2) -> void:
	var footer := Control.new()
	footer.name = "Footer"
	footer.position = rect.position
	footer.size = rect.size
	footer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	design_canvas.add_child(footer)

	footer_hint_label = Visual.label("", 12, Visual.OUTLINE)
	footer_hint_label.name = "FooterHint"
	footer_hint_label.position = Vector2(0, 0)
	footer_hint_label.size = Vector2(700, rect.size.y)
	footer.add_child(footer_hint_label)

	footer_close_button = Visual.limestone_button("", Vector2(150, 42), func(): visible = false)
	footer_close_button.name = "FooterCloseButton"
	footer_close_button.position = Vector2(rect.size.x - 150, 0)
	footer_close_button.size = Vector2(150, 42)
	footer.add_child(footer_close_button)

# 실행: 헤더 잔액 칩 값을 갱신한다.
func _render_wallet(model: Dictionary) -> void:
	_set_chip_value(gold_chip, str(int(model.get("gold", 0))))
	_set_chip_value(xp_chip, str(int(model.get("xp", 0))))

# 실행: 카탈로그 탭을 다시 만든다.
func _render_tabs(sections: Array) -> void:
	_clear(tabs_row)
	for section in sections:
		var data: Dictionary = section
		var section_id := str(data.get("id", ""))
		tabs_row.add_child(Visual.tab_button(
			str(data.get("label", "")),
			int(data.get("count", 0)),
			bool(data.get("active", false)),
			func(): select_section(section_id)
		))

# 실행: 활성 탭 그룹의 항목만 2열 그리드로 렌더링한다(런타임 탭 계약).
func _render_catalog(entries: Array) -> void:
	_clear(catalog_grid)
	var metrics: Dictionary = Layout.catalog_grid_metrics()
	var card_size: Vector2 = metrics["cardSize"]
	for entry in entries:
		var data: Dictionary = entry
		if str(data.get("group", "")) != current_active_section:
			continue
		var payload := data.duplicate(true)
		payload["ownedText"] = TextCatalogScript.t("shop.owned_seal")
		var entry_id := str(data.get("id", ""))
		catalog_grid.add_child(Visual.entry_card(payload, card_size, func(): select_entry(entry_id)))

# 실행: 우측 상세 패널을 선택 항목 payload로 갱신한다.
func _render_detail(detail: Dictionary) -> void:
	if bool(detail.get("empty", true)):
		detail_region.visible = false
		return
	detail_region.visible = true
	detail_badge.text = str(detail.get("badge", ""))
	detail_title.text = str(detail.get("title", ""))
	detail_subtitle.text = str(detail.get("subtitle", ""))
	_set_section_header(detail_effect_header, TextCatalogScript.t("shop.detail.effect"))
	detail_effect_label.text = str(detail.get("effectText", ""))
	_set_section_header(detail_notes_header, TextCatalogScript.t("shop.detail.field_notes"))
	detail_notes_label.text = str(detail.get("fieldNotes", ""))
	detail_cost_caption.text = TextCatalogScript.t("shop.detail.cost_label")

	# 원장 폭은 레이아웃 전 size.x가 0이므로 region 기하에서 직접 계산한다.
	var ledger_width: float = float(Layout.regions()["detail"].size.x) - 40.0
	_clear(detail_ledger)
	for row in detail.get("ledger", []):
		var pair: Dictionary = row
		detail_ledger.add_child(Visual.ledger_row(str(pair.get("label", "")), str(pair.get("value", "")), ledger_width))

	_clear(detail_cost_row)
	detail_cost_row.add_child(_cost_amount("shop_icon_gold_24.png", str(int(detail.get("costGold", 0)))))
	if bool(detail.get("showXpCost", false)):
		detail_cost_row.add_child(_cost_amount("shop_icon_xp_24.png", str(int(detail.get("costXp", 0)))))

	detail_cta.text = str(detail.get("ctaText", ""))
	detail_cta.disabled = not bool(detail.get("ctaEnabled", false))

# 실행: 상세 CTA를 눌렀을 때 그룹에 맞는 구매 시그널을 방출한다.
func _on_cta_pressed() -> void:
	if not SHOP_ENABLED:
		return
	var detail: Dictionary = last_model.get("detail", {})
	if bool(detail.get("empty", true)) or not bool(detail.get("ctaEnabled", false)):
		return
	var entry_id := str(detail.get("entryId", ""))
	if str(detail.get("group", "")) == "passive":
		buy_passive.emit(entry_id, int(detail.get("costGold", 0)))
	else:
		buy_base_item.emit(entry_id)

# 실행: 필요 자원 표기 한 칸(아이콘 + 수치)을 만든다.
func _cost_amount(icon_file: String, value: String) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var icon := TextureRect.new()
	icon.texture = Visual.texture(icon_file)
	icon.custom_minimum_size = Vector2(18, 18)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(icon)
	row.add_child(Visual.label(value, 19, Visual.DEEP, "serif"))
	return row

# 실행: 잔액 칩의 값 라벨만 갱신한다.
func _set_chip_value(chip: Control, value: String) -> void:
	if chip == null:
		return
	var value_label := chip.find_child("Value", true, false)
	if value_label is Label:
		(value_label as Label).text = value

# 실행: 섹션 헤더의 텍스트 라벨만 갱신한다.
func _set_section_header(header: Control, text: String) -> void:
	if header == null:
		return
	for child in header.get_children():
		if child is Label:
			(child as Label).text = text
			return

# 실행: 고정 캔버스를 현재 뷰포트에 맞춘다.
func _apply_canvas_layout() -> void:
	if design_canvas == null:
		return
	var fitted: Dictionary = Layout.canvas_transform_for_viewport(size)
	design_canvas.position = fitted["position"]
	design_canvas.scale = Vector2.ONE * float(fitted["scale"])
	design_canvas.size = Layout.DESIGN_SIZE

# 실행: 컨테이너의 기존 자식을 제거한다.
func _clear(node: Node) -> void:
	if node == null:
		return
	for child in node.get_children():
		node.remove_child(child)
		child.queue_free()

# 실행: ESC로 오버레이를 닫는다(팝업 계약).
func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel"):
		visible = false
		get_viewport().set_input_as_handled()
