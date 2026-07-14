extends Control

# 계약:
# - 책임: 런 실패(defeat) 페이지 — "매달린 양피지 보드" 구도로 실패 사유/조언/재도전 CTA를 표시한다.
# - 입력: MainViewPageShellRuntime이 전달하는 read-model state(Dictionary, PageSceneModelBuilder._defeat_page_model 계약).
# - 출력: same_seed_retry_requested / new_seed_retry_requested 시그널.
# - 금지: gameplay 상태 변경, project.godot stretch 변경, 기획 카피/수치 임의 변경.
#
# 실행: fail_r4 목업(ltl_fail_redesign) 적용 — 보드는 뷰포트 우측(left 500 / width 892)에
# 배치해 좌상단 내러티브 토스트(top_left, 32~452px)와 구조적으로 겹치지 않는다.
const LTLThemeScript = preload("res://src/ui/theme/LTLTheme.gd")
const TextCatalogScript = preload("res://src/ui/TextCatalog.gd")
const DEFAULT_STAGE_BACKDROP_PATH := "res://resources/charactor/background.png"
const DEFAULT_CHARACTER_ART_PATH := "res://resources/charactor/charactor1.png"
const HEAD_ICON_PATH := "res://resources/node_select/atlas/icon_locked_roots.png"

# 계약: 목업 alpha_bounds.json 측정치를 이식한 정렬 상수(APPLY_PLAN.md 4절).
# 실행: 핀/랜턴/폴라로이드의 알파 경계를 보정해 "관통/후퇴/프레임 정합" 배치를 재현한다.
const PIN_BOX := Vector2(64.0, 64.0)
const PIN_VISIBLE_CENTER := Vector2(32.5, 27.5) # alpha bbox (16,8)-(49,47)
const PIN_PIERCE_DEPTH := 6.0 # 보드 상단면 아래로 박히는 깊이
const LANTERN_BOX := Vector2(220.0, 340.0)
const LANTERN_SCALE := 0.62
const LANTERN_VISIBLE_BOTTOM := 311.0 # alpha bbox 하단
const LANTERN_BOTTOM_Y := 792.0 # 뷰포트 기준 랜턴 가시 바닥 y좌표
const LANTERN_LEFT_X := 164.0
const POLAROID_HOLE := Rect2(26.0, 26.0, 708.0, 358.0) # 프레임 내부 구멍(가시 픽셀)
const POLAROID_BOX := Vector2(760.0, 480.0)

# 계약: 내러티브 토스트(top_left 프리셋) rect를 페이지가 침범하지 않도록 하는 회피 상수.
# 실행: MainViewChromeRuntime.layout_narrative_toast()의 top_left 분기 수치를 그대로 반영한다.
# 토스트 컴포넌트 자체는 다른 담당 범위라 건드리지 않고, 페이지가 그 영역을 비켜 앉는다.
const TOAST_LEFT := 32.0
const TOAST_WIDTH_RATIO := 0.38
const TOAST_WIDTH_MIN := 420.0
const TOAST_WIDTH_MAX := 620.0
const BOARD_TOAST_GAP := 24.0
const BOARD_RIGHT_MARGIN := 24.0
const BOARD_WIDTH_MIN := 640.0
const BOARD_TILT_DEGREES := -0.6

# 계약: 폴라로이드 사진의 세로 크롭 기준점.
# 실행: KEEP_ASPECT_COVERED는 중앙 크롭이라 세로 포트레이트(887x1774)에서 얼굴이 잘린다.
# 목업 CSS의 object-position 등가를 AtlasTexture region 상단 바이어스로 재현한다.
# 0.0 = 최상단, 1.0 = 최하단. 0.20은 머리 위 여백만 덜어내고 얼굴을 남기는 값이다.
const POLAROID_CROP_BIAS := 0.20

signal return_requested
signal same_seed_retry_requested
signal new_seed_retry_requested

@export var default_eyebrow := ""
@export var default_title := ""
@export_multiline var default_subtitle := ""
@export var default_board_title := ""
@export_multiline var default_board_hint := ""
@export_multiline var default_cause := ""
@export_multiline var default_tip := ""
@export var default_button_text := ""
@export var default_art_path := ""
@export var default_character_art_path := DEFAULT_CHARACTER_ART_PATH
@export var default_stage_backdrop_path := DEFAULT_STAGE_BACKDROP_PATH

@onready var forest_backdrop: TextureRect = $ForestBackdrop
@onready var spore_layer: TextureRect = $SporeLayer
@onready var lantern: TextureRect = $Lantern
@onready var board_rig: Control = $BoardRig
@onready var board_tilt: Control = $BoardRig/BoardTilt
@onready var board_shell: PanelContainer = $BoardRig/BoardTilt/BoardShell
@onready var head_icon: TextureRect = $BoardRig/BoardTilt/BoardShell/ShellMargin/ShellVBox/Head/HeadIcon
@onready var eyebrow_label: Label = $BoardRig/BoardTilt/BoardShell/ShellMargin/ShellVBox/Head/Eyebrow
@onready var hero_title_label: Label = $BoardRig/BoardTilt/BoardShell/ShellMargin/ShellVBox/Head/HeroTitle
@onready var hero_title_en_label: Label = $BoardRig/BoardTilt/BoardShell/ShellMargin/ShellVBox/Head/HeroTitleEn
@onready var hero_subtitle_label: Label = $BoardRig/BoardTilt/BoardShell/ShellMargin/ShellVBox/Head/HeroSubtitle
@onready var rule: Control = $BoardRig/BoardTilt/BoardShell/ShellMargin/ShellVBox/Rule
@onready var polaroid_slot: Control = $BoardRig/BoardTilt/BoardShell/ShellMargin/ShellVBox/Body/PolaroidSlot
@onready var polaroid_photo: TextureRect = $BoardRig/BoardTilt/BoardShell/ShellMargin/ShellVBox/Body/PolaroidSlot/PolaroidPhoto
@onready var polaroid_frame: TextureRect = $BoardRig/BoardTilt/BoardShell/ShellMargin/ShellVBox/Body/PolaroidSlot/PolaroidFrame
@onready var polaroid_caption: Label = $BoardRig/BoardTilt/BoardShell/ShellMargin/ShellVBox/Body/PolaroidSlot/PolaroidCaption
@onready var cause_label: Label = $BoardRig/BoardTilt/BoardShell/ShellMargin/ShellVBox/Body/LedgerColumn/CauseRow/CauseLabel
@onready var failure_cause_label: Label = $BoardRig/BoardTilt/BoardShell/ShellMargin/ShellVBox/Body/LedgerColumn/CauseRow/FailureCauseLabel
@onready var cause_rule: Control = $BoardRig/BoardTilt/BoardShell/ShellMargin/ShellVBox/Body/LedgerColumn/CauseRule
@onready var tip_label: Label = $BoardRig/BoardTilt/BoardShell/ShellMargin/ShellVBox/Body/LedgerColumn/TipRow/TipLabel
@onready var failure_tip_label: Label = $BoardRig/BoardTilt/BoardShell/ShellMargin/ShellVBox/Body/LedgerColumn/TipRow/FailureTipLabel
@onready var tip_rule: Control = $BoardRig/BoardTilt/BoardShell/ShellMargin/ShellVBox/Body/LedgerColumn/TipRule
@onready var quote_card: PanelContainer = $BoardRig/BoardTilt/BoardShell/ShellMargin/ShellVBox/Body/LedgerColumn/QuoteCard
@onready var quote_label: Label = $BoardRig/BoardTilt/BoardShell/ShellMargin/ShellVBox/Body/LedgerColumn/QuoteCard/QuoteMargin/QuoteLabel
@onready var retry_button: Button = $BoardRig/BoardTilt/BoardShell/ShellMargin/ShellVBox/CtaColumn/RetryButton
@onready var retry_sub_label: Label = $BoardRig/BoardTilt/BoardShell/ShellMargin/ShellVBox/CtaColumn/RetryButton/RetrySubLabel
@onready var new_seed_retry_button: Button = $BoardRig/BoardTilt/BoardShell/ShellMargin/ShellVBox/CtaColumn/NewSeedRetryButton
@onready var new_seed_sub_label: Label = $BoardRig/BoardTilt/BoardShell/ShellMargin/ShellVBox/CtaColumn/NewSeedRetryButton/NewSeedSubLabel
@onready var pin: TextureRect = $BoardRig/BoardTilt/Pin

func _ready() -> void:
	retry_button.pressed.connect(func() -> void: same_seed_retry_requested.emit())
	new_seed_retry_button.pressed.connect(func() -> void: new_seed_retry_requested.emit())
	_load_static_art()
	_apply_theme()
	_layout_alpha_bounds()
	_apply({})
	resized.connect(_layout_alpha_bounds)
	rule.resized.connect(rule.queue_redraw)

func apply_state(state: Dictionary) -> void:
	_apply(state)

# 계약: read-model state를 각 라벨/이미지 노드에 반영한다.
# 실행: pageBoardTitle/pageBoardHint는 빌더가 항상 ""를 반환하므로(런타임 동일 동작 유지)
# 보드 제목은 default_title(신규 defeat_halted 카피) 우선, read-model pageTitle이 있으면 그것을 우선한다.
func _apply(state: Dictionary) -> void:
	eyebrow_label.text = str(state.get("pageEyebrow", default_eyebrow))
	var board_title := str(state.get("pageTitle", ""))
	hero_title_label.text = board_title if not board_title.is_empty() else default_title
	hero_subtitle_label.text = str(state.get("pageSubtitle", default_subtitle))
	failure_cause_label.text = str(state.get("pageCause", default_cause))
	failure_tip_label.text = str(state.get("pageTip", default_tip))
	var same_seed_text := str(state.get("pageRetrySameSeedText", state.get("pageButtonText", default_button_text)))
	var new_seed_text := str(state.get("pageRetryNewSeedText", default_button_text))
	retry_button.text = ("↻  " + same_seed_text) if not same_seed_text.is_empty() else ""
	new_seed_retry_button.text = ("✦  " + new_seed_text) if not new_seed_text.is_empty() else ""
	new_seed_retry_button.visible = not new_seed_text.is_empty()
	new_seed_sub_label.visible = new_seed_retry_button.visible

	hero_subtitle_label.visible = not hero_subtitle_label.text.is_empty()

	var character_art_path := str(state.get("pageCharacterArtPath", default_character_art_path))
	var portrait := LTLThemeScript.art_texture(character_art_path) if not character_art_path.is_empty() else null
	polaroid_photo.texture = _polaroid_crop_texture(portrait)

# 계약: 폴라로이드 구멍 비율에 맞춰 인물 사진을 상단 바이어스로 크롭한 텍스처를 돌려준다.
# 실행: 원본이 구멍보다 세로로 길 때만 잘라내고, 가로가 더 길면 중앙 크롭으로 둔다.
# 크롭이 불필요하면 원본을 그대로 반환한다.
func _polaroid_crop_texture(portrait: Texture2D) -> Texture2D:
	if portrait == null:
		return null
	var src := Vector2(portrait.get_width(), portrait.get_height())
	if src.x <= 0.0 or src.y <= 0.0:
		return portrait
	var hole_aspect := POLAROID_HOLE.size.x / POLAROID_HOLE.size.y
	var src_aspect := src.x / src.y
	if src_aspect >= hole_aspect:
		return portrait
	var region_size := Vector2(src.x, src.x / hole_aspect)
	var top := (src.y - region_size.y) * POLAROID_CROP_BIAS
	return LTLThemeScript.atlas_frame(portrait, Rect2(Vector2(0.0, top), region_size))

# 계약: 목업이 고정 자산으로 쓰는 정적 요소(배경/랜턴/포자/헤더 아이콘/보드 핀/프레임/캡션/원장 라벨/인용)를 채운다.
# 실행: read-model이 매 프레임 갱신하지 않는 장식 자산은 _ready에서 1회 로드한다.
func _load_static_art() -> void:
	forest_backdrop.texture = LTLThemeScript.art_texture("res://resources/UI/fail_redesign/dark_forest_bg.png")
	spore_layer.texture = LTLThemeScript.art_texture("res://resources/UI/fail_redesign/spore_dust.png")
	lantern.texture = LTLThemeScript.art_texture("res://resources/UI/fail_redesign/lantern.png")
	pin.texture = LTLThemeScript.art_texture("res://resources/UI/fail_redesign/board_pin.png")
	polaroid_frame.texture = LTLThemeScript.art_texture("res://resources/UI/fail_redesign/polaroid_frame.png")
	head_icon.texture = LTLThemeScript.art_texture(HEAD_ICON_PATH)

	hero_title_en_label.text = TextCatalogScript.t("main.page.title.defeat_halted_en")
	cause_label.text = TextCatalogScript.t("failure.board.ledger.cause_label")
	tip_label.text = TextCatalogScript.t("failure.board.ledger.tip_label")
	quote_label.text = TextCatalogScript.t("failure.board.quote")
	polaroid_caption.text = TextCatalogScript.t("failure.board.photo_caption")
	retry_sub_label.text = TextCatalogScript.t("action.retry_same_seed_en")
	new_seed_sub_label.text = TextCatalogScript.t("action.retry_new_seed_en")

	if default_title.is_empty():
		default_title = TextCatalogScript.t("main.page.title.defeat_halted")

# 계약: 보드/핀/랜턴/폴라로이드의 알파 경계 정렬을 뷰포트 크기 변화에도 재계산한다.
# 실행: APPLY_PLAN.md 4절 공식을 이식하되, 보드 좌측 경계만 실측치로 교정한다.
# 목업(index.html)은 내러티브 토스트 우측 끝을 452px으로 보고 보드를 left:500px에 뒀으나,
# 실제 런타임 MainViewChromeRuntime.layout_narrative_toast()의 top_left 프리셋은
# width = clamp(viewport.x * 0.38, 420, 620)이라 1440px에서 547.2px가 되어
# 토스트 우측 끝이 32 + 547.2 = 579.2px이다(목업은 클램프 하한 420을 실제값으로 오인).
# 따라서 목업 좌표를 그대로 쓰면 보드 좌측 79px이 토스트 rect 아래로 들어간다.
# 토스트 폭 공식을 그대로 재현해 보드 좌측을 유도하고, 24px 간격을 띄운다.
func _layout_alpha_bounds() -> void:
	var viewport_size := get_viewport_rect().size
	var toast_width := clampf(viewport_size.x * TOAST_WIDTH_RATIO, TOAST_WIDTH_MIN, TOAST_WIDTH_MAX)
	var board_left := TOAST_LEFT + toast_width + BOARD_TOAST_GAP
	var board_top := 34.0
	# 회전 -0.6°로 우상단 모서리가 보드 높이만큼 바깥으로 밀리므로 우측 여백에서 상쇄한다.
	var board_height := viewport_size.y - board_top
	var tilt_overhang := board_height * sin(deg_to_rad(abs(BOARD_TILT_DEGREES)))
	var board_width := maxf(
		BOARD_WIDTH_MIN,
		viewport_size.x - board_left - BOARD_RIGHT_MARGIN - tilt_overhang
	)

	board_rig.position = Vector2(board_left, board_top)
	board_rig.size = Vector2(board_width, board_height)
	board_tilt.rotation = deg_to_rad(BOARD_TILT_DEGREES)

	# 핀: 가시 중심을 보드 상단면 6px 아래에 박아 "관통" 표현.
	pin.size = PIN_BOX
	pin.position = Vector2(
		board_width * 0.5 - PIN_VISIBLE_CENTER.x,
		PIN_PIERCE_DEPTH - PIN_VISIBLE_CENTER.y
	)

	# 랜턴: 0.62배 축소해 전경이 아닌 배경 광원으로 후퇴.
	var lantern_display_size := LANTERN_BOX * LANTERN_SCALE
	lantern.size = lantern_display_size
	lantern.position = Vector2(
		LANTERN_LEFT_X,
		LANTERN_BOTTOM_Y - LANTERN_VISIBLE_BOTTOM * LANTERN_SCALE
	)

	# 폴라로이드: 프레임 표시폭 기준 스케일로 내부 구멍(사진) rect를 재계산.
	var frame_display_w: float = polaroid_slot.custom_minimum_size.x
	if frame_display_w <= 0.0:
		frame_display_w = POLAROID_BOX.x
	var scale := frame_display_w / POLAROID_BOX.x
	var hole := Rect2(POLAROID_HOLE.position * scale, POLAROID_HOLE.size * scale)
	polaroid_photo.position = hole.position
	polaroid_photo.size = hole.size

# 계약: Rule 구분선을 대시 패턴으로 그린다(목업 border-top dashed 등가).
# 실행: 일반 Control은 스타일박스로 점선을 표현할 수 없어 _draw() 콜백에서 직접 그린다.
func _draw_rule() -> void:
	var width := rule.size.x
	var dash_len := 8.0
	var gap_len := 6.0
	var x := 0.0
	var color := Color(0.36, 0.25, 0.16, 0.34)
	while x < width:
		var seg_end := minf(x + dash_len, width)
		rule.draw_line(Vector2(x, 1.0), Vector2(seg_end, 1.0), color, 2.0)
		x += dash_len + gap_len

func _apply_theme() -> void:
	# 계약: 매달린 양피지 보드 스타일 — parchment-glass 반투명 + 결 텍스처는
	# StyleBoxFlat만으로 표현 가능한 범위(배경색/보더/그림자)까지 재현한다.
	var board_style := LTLThemeScript.surface_style(LTLThemeScript.PARCHMENT_GLASS, Color(LTLThemeScript.SECONDARY.r, LTLThemeScript.SECONDARY.g, LTLThemeScript.SECONDARY.b, 0.55), 16, 1, 0.62)
	board_style.shadow_size = 26
	board_style.shadow_offset = Vector2(0.0, 14.0)
	board_shell.add_theme_stylebox_override("panel", board_style)

	eyebrow_label.add_theme_font_size_override("font_size", 12)
	eyebrow_label.add_theme_color_override("font_color", LTLThemeScript.ERROR)

	hero_title_label.add_theme_font_size_override("font_size", 42)
	hero_title_label.add_theme_color_override("font_color", LTLThemeScript.PRIMARY)

	hero_title_en_label.add_theme_font_size_override("font_size", 14)
	hero_title_en_label.add_theme_color_override("font_color", LTLThemeScript.SECONDARY)

	hero_subtitle_label.add_theme_font_size_override("font_size", 15)
	hero_subtitle_label.add_theme_color_override("font_color", LTLThemeScript.ON_SURFACE_VARIANT)

	if not rule.draw.is_connected(_draw_rule):
		rule.draw.connect(_draw_rule)

	cause_label.add_theme_font_size_override("font_size", 11)
	cause_label.add_theme_color_override("font_color", LTLThemeScript.INK_MUTED)
	tip_label.add_theme_font_size_override("font_size", 11)
	tip_label.add_theme_color_override("font_color", LTLThemeScript.INK_MUTED)

	failure_cause_label.add_theme_font_size_override("font_size", 16)
	failure_cause_label.add_theme_color_override("font_color", LTLThemeScript.ON_SURFACE)
	failure_tip_label.add_theme_font_size_override("font_size", 16)
	failure_tip_label.add_theme_color_override("font_color", LTLThemeScript.SECONDARY)

	polaroid_caption.add_theme_font_size_override("font_size", 12)
	polaroid_caption.add_theme_color_override("font_color", Color(0.36, 0.25, 0.16, 0.82))

	var quote_style := LTLThemeScript.surface_style(LTLThemeScript.LIMESTONE_FILL, Color(LTLThemeScript.SECONDARY.r, LTLThemeScript.SECONDARY.g, LTLThemeScript.SECONDARY.b, 0.42), 12, 1, 0.0)
	quote_card.add_theme_stylebox_override("panel", quote_style)
	quote_label.add_theme_font_size_override("font_size", 15)
	quote_label.add_theme_color_override("font_color", Color(0.173, 0.306, 0.192, 1.0))

	retry_button.add_theme_stylebox_override("normal", LTLThemeScript.hero_button_style("normal"))
	retry_button.add_theme_stylebox_override("hover", LTLThemeScript.hero_button_style("hover"))
	retry_button.add_theme_stylebox_override("pressed", LTLThemeScript.hero_button_style("pressed"))
	retry_button.add_theme_stylebox_override("focus", LTLThemeScript.hero_button_style("hover"))
	retry_button.add_theme_font_size_override("font_size", 17)
	retry_button.add_theme_color_override("font_color", LTLThemeScript.ON_PRIMARY)
	retry_sub_label.add_theme_font_size_override("font_size", 11)
	retry_sub_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.72))

	var limestone_normal := LTLThemeScript.limestone_style(8)
	limestone_normal.border_color = LTLThemeScript.SECONDARY
	limestone_normal.border_width_bottom = 4
	var limestone_hover := LTLThemeScript.limestone_style(8)
	limestone_hover.bg_color = LTLThemeScript.SURFACE_CONTAINER_LOW.lightened(0.06)
	limestone_hover.border_color = LTLThemeScript.SECONDARY
	limestone_hover.border_width_bottom = 4
	new_seed_retry_button.add_theme_stylebox_override("normal", limestone_normal)
	new_seed_retry_button.add_theme_stylebox_override("hover", limestone_hover)
	new_seed_retry_button.add_theme_stylebox_override("pressed", limestone_normal)
	new_seed_retry_button.add_theme_stylebox_override("focus", limestone_hover)
	new_seed_retry_button.add_theme_font_size_override("font_size", 17)
	new_seed_retry_button.add_theme_color_override("font_color", LTLThemeScript.PRIMARY)
	new_seed_sub_label.add_theme_font_size_override("font_size", 11)
	new_seed_sub_label.add_theme_color_override("font_color", Color(LTLThemeScript.PRIMARY.r, LTLThemeScript.PRIMARY.g, LTLThemeScript.PRIMARY.b, 0.72))

	for button in [retry_button, new_seed_retry_button]:
		button.focus_mode = Control.FOCUS_NONE
		button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
