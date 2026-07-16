# 계약:
# - 책임: 보급 캠프 상점 오버레이의 스타일박스/라벨/카드/배지 생성 문법을 한 곳에서 제공한다.
# - 입력: 표시 문자열, read model entry payload, 색/규격 인자.
# - 출력: 구성된 Control 노드와 StyleBox.
# - 금지: read model 계산, run state 접근, 시그널 방출 로직.
#
# 실행: build shop overlay visuals with the botanical parchment grammar.
class_name ShopVisualFactory
extends RefCounted

const Typography = preload("res://src/ui/codex/CodexTypography.gd")
const InteractionFXScript = preload("res://src/ui/InteractionFX.gd")
const ASSET_ROOT := "res://resources/UI/shop_redesign"

const DEEP := Color("183a1f")
const MOSS := Color("2f5134")
const LEAF := Color("6fa15b")
const INK := Color("3b2918")
const INK_SOFT := Color("7d6b55")
const OUTLINE := Color("727971")
const GOLD_INK := Color("6b4f1c")
const XP_INK := Color("2b4b30")

# 실행: 자산 텍스처를 로드한다(에디터 임포트 전 헤드리스 실행을 위해 파일 폴백 포함).
static func texture(file: String) -> Texture2D:
	var path := "%s/%s" % [ASSET_ROOT, file]
	if ResourceLoader.exists(path):
		return load(path) as Texture2D
	var image := Image.load_from_file(ProjectSettings.globalize_path(path))
	return ImageTexture.create_from_image(image) if image != null and not image.is_empty() else null

# 실행: 9-slice 텍스처 스타일박스를 만든다.
static func texture_style(file: String, margin: int, content_margin := 0.0) -> StyleBoxTexture:
	var style := StyleBoxTexture.new()
	style.texture = texture(file)
	style.texture_margin_left = margin
	style.texture_margin_top = margin
	style.texture_margin_right = margin
	style.texture_margin_bottom = margin
	# texture_margin은 9-slice 늘림 경계일 뿐이다. content_margin을 명시하지 않으면
	# Godot이 texture_margin을 콘텐츠 패딩으로 재사용해 Button이 자동 확장된다
	# (적용 평가 r2~r5: CTA가 52 -> 76px로 부풀어 상세 패널 clip에 잘림).
	style.content_margin_left = content_margin
	style.content_margin_top = content_margin
	style.content_margin_right = content_margin
	style.content_margin_bottom = content_margin
	return style

# 실행: 평면 스타일박스를 만든다.
static func flat(bg: Color, border := Color.TRANSPARENT, border_width := 0, radius := 8) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.border_width_left = border_width
	style.border_width_top = border_width
	style.border_width_right = border_width
	style.border_width_bottom = border_width
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	return style

# 실행: 역할별 폰트를 적용한 라벨을 만든다(serif=제목/본문 한글, ui=라벨).
static func label(text: String, font_size: int, color: Color, role := "ui") -> Label:
	var node := Label.new()
	node.text = text
	node.add_theme_font_size_override("font_size", font_size)
	node.add_theme_color_override("font_color", color)
	node.add_theme_font_override("font", Typography.korean_serif_font() if role == "serif" else Typography.ui_font())
	node.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return node

# 실행: 잔액 칩(골드/경험치)을 만든다.
static func wallet_chip(icon_file: String, caption: String, value: String) -> Control:
	var chip := PanelContainer.new()
	chip.custom_minimum_size = Vector2(0, 40)
	chip.add_theme_stylebox_override("panel", _chip_style())
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	chip.add_child(row)
	var icon := TextureRect.new()
	icon.texture = texture(icon_file)
	icon.custom_minimum_size = Vector2(24, 24)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(icon)
	var caption_label := label(caption, 11, OUTLINE)
	row.add_child(caption_label)
	var value_label := label(value, 17, DEEP, "serif")
	value_label.name = "Value"
	row.add_child(value_label)
	return chip

# 실행: 카탈로그 탭 버튼을 만든다.
static func tab_button(text: String, count: int, active: bool, on_pressed: Callable) -> Button:
	var button := Button.new()
	button.text = "%s  %d" % [text, count]
	button.custom_minimum_size = Vector2(0, 34)
	button.add_theme_font_override("font", Typography.ui_font())
	button.add_theme_font_size_override("font_size", 13)
	button.add_theme_color_override("font_color", DEEP if active else Color("3f4a3f"))
	button.add_theme_color_override("font_hover_color", DEEP)
	var style := texture_style("shop_tab_active_120x28.png" if active else "shop_tab_inactive_120x28.png", 10)
	style.content_margin_left = 18
	style.content_margin_right = 18
	style.content_margin_top = 0
	style.content_margin_bottom = 0
	for state in ["normal", "hover", "pressed", "focus"]:
		button.add_theme_stylebox_override(state, style)
	button.pressed.connect(on_pressed)
	return button

# 실행: 그룹 헤더(원장 대시 구분선)를 만든다.
static func group_header(text: String) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	row.custom_minimum_size = Vector2(0, 22)
	var header := label(text, 11, MOSS)
	row.add_child(header)
	var rule := dashed_rule()
	rule.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rule.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(rule)
	return row

# 실행: 카탈로그 카드 하나를 만든다(선택/보유 상태 분기 포함).
static func entry_card(entry: Dictionary, card_size: Vector2, on_pressed: Callable) -> Button:
	var selected := bool(entry.get("selected", false))
	var owned := bool(entry.get("owned", false))
	var button := Button.new()
	button.name = "ShopEntry_%s" % str(entry.get("id", ""))
	button.custom_minimum_size = card_size
	button.text = ""
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	var card_file := "shop_item_card_selected_320x76.png" if selected else (
		"shop_item_card_owned_320x76.png" if owned else "shop_item_card_normal_320x76.png"
	)
	var style := texture_style(card_file, 22)
	for state in ["normal", "hover", "pressed", "focus"]:
		button.add_theme_stylebox_override(state, style)
	button.set_meta(InteractionFXScript.META_SKIP, true)
	button.pressed.connect(on_pressed)

	# 선택 accent 바 — 목업의 좌측 5px 바(이미지 슬라이스가 아닌 별도 레이어).
	if selected:
		var accent := ColorRect.new()
		accent.name = "SelectionAccent"
		accent.color = MOSS
		accent.position = Vector2(7, 8)
		accent.size = Vector2(5, card_size.y - 16)
		accent.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(accent)

	# 우측 가격/인장 영역(약 150px)을 비워 두고 이름/캡션은 그 왼쪽에만 배치한다(겹침 방지).
	var price_reserve := 150.0 if str(entry.get("group", "")) == "base" else 84.0
	var text_width := card_size.x - 14.0 - price_reserve
	var name_row := HBoxContainer.new()
	name_row.name = "NameRow"
	name_row.position = Vector2(14, 9)
	name_row.size = Vector2(text_width, 20)
	name_row.add_theme_constant_override("separation", 6)
	name_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(name_row)
	var name_label := label(str(entry.get("name", "")), 14, INK, "serif")
	name_label.clip_text = true
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_row.add_child(name_label)
	if int(entry.get("level", -1)) >= 0:
		name_row.add_child(_level_chip(str(entry.get("levelText", ""))))

	var caption := label(str(entry.get("caption", "")), 11, INK_SOFT)
	caption.name = "Caption"
	caption.position = Vector2(14, 33)
	caption.size = Vector2(text_width, 18)
	caption.clip_text = true
	button.add_child(caption)

	if owned:
		var seal := TextureRect.new()
		seal.name = "OwnedSeal"
		seal.texture = texture("shop_sold_seal_48.png")
		seal.position = Vector2(card_size.x - 52, (card_size.y - 40) * 0.5)
		# TextureRect는 부모가 Button(비-Container)이어도 텍스처 원본(96px)으로 확장되므로
		# custom_minimum_size와 size를 함께 고정해 카드 밖으로 넘치는 것을 막는다.
		seal.custom_minimum_size = Vector2(40, 40)
		seal.size = Vector2(40, 40)
		seal.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		seal.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		seal.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(seal)
		var seal_text := label(str(entry.get("ownedText", "")), 9, Color("786040"))
		seal_text.position = Vector2(card_size.x - 52, (card_size.y - 40) * 0.5)
		seal_text.custom_minimum_size = Vector2(40, 40)
		seal_text.size = Vector2(40, 40)
		seal_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		button.add_child(seal_text)
	else:
		var prices := HBoxContainer.new()
		prices.name = "PriceRow"
		prices.alignment = BoxContainer.ALIGNMENT_END
		prices.add_theme_constant_override("separation", 6)
		prices.position = Vector2(card_size.x - price_reserve - 2.0, (card_size.y - 21) * 0.5)
		prices.size = Vector2(price_reserve - 10.0, 21)
		prices.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(prices)
		prices.add_child(price_badge("shop_icon_gold_24.png", str(int(entry.get("costGold", 0))), false))
		if str(entry.get("group", "")) == "base":
			prices.add_child(price_badge("shop_icon_xp_24.png", str(int(entry.get("costXp", 0))), true))
	return button

# 실행: 가격 배지(정원 아이콘 + 필)를 만든다.
static func price_badge(icon_file: String, value: String, is_xp: bool) -> Control:
	var badge := PanelContainer.new()
	badge.custom_minimum_size = Vector2(0, 21)
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := flat(
		Color("e2f1e2") if is_xp else Color("faf0d6"),
		Color(0.18, 0.32, 0.19, 0.5) if is_xp else Color(0.69, 0.52, 0.17, 0.55),
		1,
		11
	)
	style.content_margin_left = 3
	style.content_margin_right = 7
	style.content_margin_top = 0
	style.content_margin_bottom = 0
	badge.add_theme_stylebox_override("panel", style)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge.add_child(row)
	var icon := TextureRect.new()
	icon.texture = texture(icon_file)
	icon.custom_minimum_size = Vector2(14, 14)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(icon)
	var value_label := label(value, 11, XP_INK if is_xp else GOLD_INK)
	row.add_child(value_label)
	return badge

# 실행: 상세 패널의 섹션 헤더(마름모 불릿 + 라벨)를 만든다.
static func detail_section_header(text: String) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	row.custom_minimum_size = Vector2(0, 18)
	var bullet := ColorRect.new()
	bullet.color = LEAF
	bullet.custom_minimum_size = Vector2(9, 9)
	bullet.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	bullet.rotation = PI * 0.25
	bullet.pivot_offset = Vector2(4.5, 4.5)
	bullet.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(bullet)
	row.add_child(label(text, 11, MOSS))
	return row

# 실행: 원장 한 줄(키 좌측 / 값 우측 + 대시 하단선)을 만든다.
static func ledger_row(key: String, value: String, width: float) -> Control:
	# Container 자동 폭 전파에 기대지 않고 절대 좌표로 배치한다(고정 캔버스 계약).
	var wrapper := Control.new()
	wrapper.custom_minimum_size = Vector2(width, 27)
	wrapper.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var key_label := label(key, 12, Color("75664f"))
	key_label.position = Vector2(0, 0)
	key_label.size = Vector2(width * 0.6, 24)
	wrapper.add_child(key_label)
	var value_label := label(value, 12, MOSS)
	value_label.position = Vector2(width * 0.4, 0)
	value_label.size = Vector2(width * 0.6, 24)
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	wrapper.add_child(value_label)
	var rule := dashed_rule()
	rule.position = Vector2(0, 25)
	rule.size = Vector2(width, 2)
	wrapper.add_child(rule)
	return wrapper

# 실행: 히어로 CTA 버튼(두꺼운 하단 보더 + 발광)을 만든다.
static func cta_button(text: String, enabled: bool, size: Vector2, on_pressed: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = size
	button.disabled = not enabled
	button.add_theme_font_override("font", Typography.korean_serif_font())
	button.add_theme_font_size_override("font_size", 16)
	button.add_theme_color_override("font_color", Color("ffffff"))
	button.add_theme_color_override("font_hover_color", Color("ffffff"))
	button.add_theme_color_override("font_disabled_color", Color(0.85, 0.88, 0.84, 0.55))
	var style := texture_style("shop_cta_hero_120x28.png", 14)
	button.add_theme_stylebox_override("normal", style)
	button.add_theme_stylebox_override("hover", style)
	button.add_theme_stylebox_override("pressed", style)
	button.add_theme_stylebox_override("focus", style)
	# 비활성(SHOP_ENABLED=false 포함) 상태에서도 CTA 형태/색을 유지하고 글자만 흐리게 한다.
	button.add_theme_stylebox_override("disabled", style)
	# 계약: 전역 InteractionFX는 disabled 컨트롤을 셰이더로 회색 탈색(gray*0.72, alpha*0.62)한다.
	# 상점 CTA는 SHOP_ENABLED=false로 상시 비활성이라 그대로 두면 진녹 CTA가 회색 판으로 렌더된다
	# (적용 평가 r2~r6에서 확인). StoryScenePage/RewardCardCloudHost 선례대로 skip 메타로 옵트아웃한다.
	button.set_meta(InteractionFXScript.META_SKIP, true)
	button.pressed.connect(on_pressed)
	return button

# 실행: 림스톤 보조 버튼(닫기)을 만든다.
static func limestone_button(text: String, size: Vector2, on_pressed: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = size
	button.add_theme_font_override("font", Typography.korean_serif_font())
	button.add_theme_font_size_override("font_size", 14)
	button.add_theme_color_override("font_color", DEEP)
	button.add_theme_color_override("font_hover_color", MOSS)
	var style := texture_style("shop_cta_limestone_120x28.png", 14)
	for state in ["normal", "hover", "pressed", "focus"]:
		button.add_theme_stylebox_override(state, style)
	button.pressed.connect(on_pressed)
	return button

# 실행: 고스트 닫기(×) 버튼을 만든다.
static func ghost_close_button(on_pressed: Callable) -> Button:
	var button := Button.new()
	button.text = "×"
	button.custom_minimum_size = Vector2(40, 40)
	button.add_theme_font_override("font", Typography.ui_font())
	button.add_theme_font_size_override("font_size", 20)
	button.add_theme_color_override("font_color", DEEP)
	var style := flat(Color(0.969, 0.945, 0.855, 0.6), Color(0.447, 0.475, 0.443, 0.45), 1, 20)
	for state in ["normal", "hover", "pressed", "focus"]:
		button.add_theme_stylebox_override(state, style)
	button.pressed.connect(on_pressed)
	return button

# 실행: 패시브 레벨 칩을 만든다.
static func _level_chip(text: String) -> Control:
	var chip := PanelContainer.new()
	chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := flat(Color(0.435, 0.631, 0.357, 0.2), Color.TRANSPARENT, 0, 9)
	style.content_margin_left = 7
	style.content_margin_right = 7
	style.content_margin_top = 2
	style.content_margin_bottom = 2
	chip.add_theme_stylebox_override("panel", style)
	chip.add_child(label(text, 10, MOSS))
	return chip

# 실행: 원장/그룹 헤더용 대시 구분선을 만든다.
static func dashed_rule() -> Control:
	var rule := HBoxContainer.new()
	rule.custom_minimum_size = Vector2(0, 2)
	rule.add_theme_constant_override("separation", 5)
	rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for _i in range(64):
		var dash := ColorRect.new()
		dash.color = Color(0.36, 0.25, 0.16, 0.32)
		dash.custom_minimum_size = Vector2(5, 1)
		dash.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		dash.mouse_filter = Control.MOUSE_FILTER_IGNORE
		rule.add_child(dash)
	rule.clip_contents = true
	return rule

# 실행: 잔액 칩 배경 스타일을 만든다.
static func _chip_style() -> StyleBoxFlat:
	var style := flat(Color(1, 1, 1, 0.72), Color(0.435, 0.631, 0.357, 0.5), 1, 20)
	style.content_margin_left = 8
	style.content_margin_right = 16
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	return style
