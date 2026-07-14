# 계약: 토스트/확인 다이얼로그 3종(info 토스트, 내러티브 토스트, 확인 오버레이)의 시각 토큰 SoT.
# - 책임: Botanical Glassmorphism 팔레트/스타일박스/텍스처/배치 상수를 한 곳에서 제공한다.
# - 입력: 없음(정적 상수와 팩토리 함수만 노출).
# - 출력: StyleBox, Texture2D, 배치 규칙 Vector2.
# - 금지: 노드 트리 조작, 시그널 배선, 문자열 카피 소유(카피는 TextCatalog가 SoT).
#
# 실행: define shared visual tokens for the toast/confirm surfaces.
class_name ToastRedesignTheme
extends RefCounted

# 실행: Botanical Glassmorphism 팔레트 — DESIGN.md 토큰 범위.
const PRIMARY := Color(0.094, 0.227, 0.122, 1.0)          # #183A1F 심록
const PRIMARY_PRESSED := Color(0.071, 0.157, 0.102, 1.0)  # #12281A CTA 하단 보더
const SECONDARY := Color(0.231, 0.412, 0.165, 1.0)        # #3B692A 잎green(진)
const LEAF := Color(0.435, 0.631, 0.357, 1.0)             # #6FA15B 잎green
const LIMESTONE := Color(0.910, 0.937, 0.820, 1.0)        # #E8EFD1 석회암
const LIMESTONE_BORDER := Color(0.608, 0.690, 0.471, 1.0) # #9BB078 림스톤 CTA 하단
const SOIL := Color(0.173, 0.086, 0.020, 1.0)             # #2C1605 흙갈색 텍스트
const OUTLINE := Color(0.447, 0.475, 0.443, 1.0)          # #727971 보조 텍스트
const MSG_TEXT := Color(0.216, 0.251, 0.184, 1.0)         # #37402F 메시지 본문
const CARET := Color(0.788, 0.573, 0.169, 1.0)            # #C9922B 진행 캐럿
const DIM := Color(0.055, 0.094, 0.067, 0.72)             # 확인 오버레이 딤

# 실행: 코너 밴드 배치 규칙 — 내러티브 토스트가 페이지 콘텐츠를 덮던 문제의 SoT.
const CORNER_MARGIN := Vector2(40.0, 40.0)
const STACK_GAP := 12.0
const INFO_TOAST_SIZE := Vector2(372.0, 84.0)
const NARRATIVE_TOAST_SIZE := Vector2(436.0, 124.0)
const CONFIRM_CARD_WIDTH := 576.0

# 실행: 레이어 규칙 — 토스트는 팝업 오버레이보다 아래, 게임플레이보다 위.
const TOAST_Z_OFFSET := -10

# 실행: 9-slice 좌측 마진은 accent 바(6px) + 라운드(6px)를 늘리지 않도록 12px 이상.
const TOAST_MARGIN_LEFT := 12
const TOAST_MARGIN_OTHER := 12
const CONFIRM_MARGIN := 24

const ConfirmCardTexture = preload("res://resources/UI/toast_redesign/confirm_card_576x352.png")
const InfoToastTexture = preload("res://resources/UI/toast_redesign/toast_card_info_372x84.png")
const NarrativeToastTexture = preload("res://resources/UI/toast_redesign/toast_card_narrative_436x112.png")
const BadgeWarnTexture = preload("res://resources/UI/toast_redesign/badge_warn_96.png")
const BadgeTraceTexture = preload("res://resources/UI/toast_redesign/badge_trace_72.png")
const BadgeSpeakerTexture = preload("res://resources/UI/toast_redesign/badge_speaker_72.png")
const CoffeeStainSmallTexture = preload("res://resources/UI/toast_redesign/coffee_stain_150.png")
const CoffeeStainLargeTexture = preload("res://resources/UI/toast_redesign/coffee_stain_240.png")

# 실행: 토스트 레이어 z-index를 팝업 오버레이 기준으로 산출한다.
static func toast_z_index(popup_overlay_z: int) -> int:
	return popup_overlay_z + TOAST_Z_OFFSET

# 실행: info 토스트 양피지 카드(좌측 accent 바가 구워진 텍스처) 스타일박스.
static func info_toast_style() -> StyleBoxTexture:
	return _toast_texture_style(InfoToastTexture)

# 실행: 내러티브 토스트 양피지 카드 스타일박스.
static func narrative_toast_style() -> StyleBoxTexture:
	return _toast_texture_style(NarrativeToastTexture)

# 실행: 확인 다이얼로그 양피지 카드 스타일박스.
static func confirm_card_style() -> StyleBoxTexture:
	var style := StyleBoxTexture.new()
	style.texture = ConfirmCardTexture
	style.texture_margin_left = CONFIRM_MARGIN
	style.texture_margin_top = CONFIRM_MARGIN
	style.texture_margin_right = CONFIRM_MARGIN
	style.texture_margin_bottom = CONFIRM_MARGIN
	return style

# 실행: 확인 오버레이 딤 배경(게임플레이를 가리되 완전 차단하지 않음).
static func confirm_dim_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = DIM
	return style

# 실행: 카드 내부 림스톤 메시지 패널.
static func limestone_message_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(LIMESTONE.r, LIMESTONE.g, LIMESTONE.b, 0.72)
	style.border_color = Color(LEAF.r, LEAF.g, LEAF.b, 0.34)
	style.set_border_width_all(1)
	style.set_corner_radius_all(10)
	style.content_margin_left = 22
	style.content_margin_top = 20
	style.content_margin_right = 22
	style.content_margin_bottom = 20
	return style

# 실행: 화자 배지 칩(정원 pill).
static func speaker_chip_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.722, 0.933, 0.627, 0.80)
	style.border_color = Color(SECONDARY.r, SECONDARY.g, SECONDARY.b, 0.45)
	style.set_border_width_all(1)
	style.set_corner_radius_all(9999)
	style.content_margin_left = 9
	style.content_margin_top = 2
	style.content_margin_right = 9
	style.content_margin_bottom = 2
	return style

# 실행: 진녹 히어로 CTA — 두꺼운 하단 보더(4px)로 눌리는 촉감, 그림자 대신 발광.
static func hero_cta_style(pressed: bool = false) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = PRIMARY
	style.border_color = PRIMARY_PRESSED
	style.border_width_bottom = 0 if pressed else 4
	style.set_corner_radius_all(8)
	style.content_margin_left = 26
	style.content_margin_right = 26
	style.content_margin_top = 12
	style.content_margin_bottom = 12 if pressed else 8
	style.shadow_color = Color(LEAF.r, LEAF.g, LEAF.b, 0.42)
	style.shadow_size = 10
	return style

# 실행: 림스톤 보조 CTA.
static func limestone_cta_style(pressed: bool = false) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = LIMESTONE
	style.border_color = LIMESTONE_BORDER
	style.set_border_width_all(1)
	style.border_width_bottom = 1 if pressed else 4
	style.set_corner_radius_all(8)
	style.content_margin_left = 26
	style.content_margin_right = 26
	style.content_margin_top = 12
	style.content_margin_bottom = 12 if pressed else 9
	return style

# 실행: 자동 소멸 진행 바 배경/전경.
static func timer_track_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(LEAF.r, LEAF.g, LEAF.b, 0.22)
	style.set_corner_radius_all(2)
	return style

static func timer_fill_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = SECONDARY
	style.set_corner_radius_all(2)
	return style

# 실행: 원형 배지의 알파 패딩을 역보정해 가시 원 외곽이 슬롯 경계와 맞도록 렌더 사각형을 넓힌다.
# 계약: 정렬 기준은 박스 규격이 아니라 이미지 가시 픽셀 외곽(알파 경계)이다.
static func badge_visual_rect(texture: Texture2D, slot_size: float) -> Rect2:
	var pad := _alpha_pad_ratio(texture)
	if pad <= 0.0:
		return Rect2(Vector2.ZERO, Vector2(slot_size, slot_size))
	# 가시 폭 비율 = 1 - 2*pad. 슬롯을 이 비율로 나눠 렌더 크기를 키우고 절반씩 밀어낸다.
	var visible_ratio := 1.0 - pad * 2.0
	if visible_ratio <= 0.0:
		return Rect2(Vector2.ZERO, Vector2(slot_size, slot_size))
	var render_size := slot_size / visible_ratio
	var offset := -(render_size - slot_size) * 0.5
	return Rect2(Vector2(offset, offset), Vector2(render_size, render_size))

# 실행: 배지 텍스처별 알파 패딩 비율(생성 시 3% 패드 규약, 측정값 96px→2px, 72px→1px).
static func _alpha_pad_ratio(texture: Texture2D) -> float:
	if texture == null:
		return 0.0
	var width := float(texture.get_width())
	if width <= 0.0:
		return 0.0
	# 계약: icon_badge()가 int(size*0.03) 패드를 남기므로 실제 픽셀 패드를 폭으로 나눈다.
	var pad_px := float(int(width * 0.03))
	return pad_px / width

# 실행: 토스트 텍스처 스타일박스 공통 — accent 바를 늘리지 않는 9-slice 마진.
static func _toast_texture_style(texture: Texture2D) -> StyleBoxTexture:
	var style := StyleBoxTexture.new()
	style.texture = texture
	style.texture_margin_left = TOAST_MARGIN_LEFT
	style.texture_margin_top = TOAST_MARGIN_OTHER
	style.texture_margin_right = TOAST_MARGIN_OTHER
	style.texture_margin_bottom = TOAST_MARGIN_OTHER
	return style
