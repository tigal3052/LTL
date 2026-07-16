# 계약: 런 클리어(탐사 완료) 결과를 Botanical Folio 폴리오 화면으로 표시한다.
# - 책임: read-model의 제목/부제/원장 수치/히어로 아트를 양피지 폴리오 레이아웃에 렌더링하고, 복귀 CTA를 발행한다.
# - 입력: pageTitle, pageSubtitle, pageButtonText, pageHeroPath, pageLedgerTarget/Stage/Run/Contract를 가진 Dictionary.
# - 출력: return_requested 시그널(캐릭터 선택 복귀 요청).
# - 금지: 페이지 전환 결정, 런 상태 변경, 내러티브 토스트 위치/표시 제어, 게임플레이 수치 산출.
#
# 실행: define the run-clear folio page control.
extends Control

const LTLThemeScript = preload("res://src/ui/theme/LTLTheme.gd")
const STAMP_TEXTURE_PATH := "res://resources/UI/clear_redesign/stamp_investigation_complete.png"
const SEAL_GLOW_TEXTURE_PATH := "res://resources/UI/clear_redesign/radiance_glow_green.png"
const PARCHMENT_BG_PATH := "res://resources/UI/codex/v5/codex_v5_screen_parchment_bg_1440x900.png"
const STAMP_ROTATION_DEG := 12.0

signal return_requested

@export var default_eyebrow := ""
@export var default_title := ""
@export_multiline var default_subtitle := ""
@export var default_button_text := ""
@export var default_art_path := ""

@onready var page_backdrop: TextureRect = $Backdrop
@onready var eyebrow_label: Label = $Folio/Header/Eyebrow
@onready var title_label: Label = $Folio/Header/Title
@onready var subtitle_label: Label = $Folio/Header/Subtitle
@onready var ledger_panel: PanelContainer = $Folio/Bento/LedgerPanel
@onready var ledger_rows: VBoxContainer = $Folio/Bento/LedgerPanel/Margin/LedgerBox/LedgerRows
@onready var ledger_title: Label = $Folio/Bento/LedgerPanel/Margin/LedgerBox/PanelHead/PanelTitle
@onready var ledger_en_sub: Label = $Folio/Bento/LedgerPanel/Margin/LedgerBox/PanelHead/PanelEnSub
@onready var seal_panel: PanelContainer = $Folio/Bento/SealPanel
@onready var seal_glow: TextureRect = $Folio/Bento/SealPanel/Margin/SealBox/SealStage/SealGlow
@onready var seal_circle: Panel = $Folio/Bento/SealPanel/Margin/SealBox/SealStage/SealCircle
@onready var seal_check: Label = $Folio/Bento/SealPanel/Margin/SealBox/SealStage/SealCircle/SealCheck
@onready var seal_kicker: Label = $Folio/Bento/SealPanel/Margin/SealBox/SealKicker
@onready var seal_title: Label = $Folio/Bento/SealPanel/Margin/SealBox/SealTitle
@onready var seal_note: Label = $Folio/Bento/SealPanel/Margin/SealBox/SealNote
@onready var hero_band: PanelContainer = $Folio/HeroBand
@onready var hero_art: TextureRect = $Folio/HeroBand/BandClip/HeroArt
@onready var hero_caption: Label = $Folio/HeroBand/BandClip/HeroCaption
@onready var stamp_image: TextureRect = $Folio/HeroBand/BandClip/Stamp
@onready var return_button: Button = $Folio/CtaRow/ReturnButton

# 실행: wire the CTA signal and paint the folio theme once the tree is ready.
func _ready() -> void:
	return_button.pressed.connect(func() -> void: return_requested.emit())
	_apply_theme()
	_apply({})

# 실행: accept one clear-page read model from the page shell runtime.
func apply_state(state: Dictionary) -> void:
	_apply(state)

# 실행: project the read model onto header copy, ledger rows, hero art, and CTA text.
func _apply(state: Dictionary) -> void:
	eyebrow_label.text = str(state.get("pageEyebrow", default_eyebrow))
	title_label.text = str(state.get("pageTitle", default_title))
	subtitle_label.text = str(state.get("pageSubtitle", default_subtitle))
	return_button.text = str(state.get("pageButtonText", default_button_text))

	eyebrow_label.visible = not eyebrow_label.text.is_empty()
	subtitle_label.visible = not subtitle_label.text.is_empty()

	_apply_ledger(state)
	_apply_seal(state)

	var art_path := str(state.get("pageHeroPath", default_art_path))
	hero_art.texture = LTLThemeScript.art_texture(art_path) if not art_path.is_empty() else null
	hero_caption.text = str(state.get("pageHeroCaption", ""))
	hero_caption.visible = not hero_caption.text.is_empty()

# 실행: fill the expedition ledger rows from existing run state values, hiding empty entries.
func _apply_ledger(state: Dictionary) -> void:
	ledger_title.text = str(state.get("pageLedgerPanelTitle", ""))
	var entries := [
		{"key": str(state.get("pageLedgerTargetLabel", "")), "value": str(state.get("pageLedgerTarget", "")), "badge": false},
		{"key": str(state.get("pageLedgerStageLabel", "")), "value": str(state.get("pageLedgerStage", "")), "badge": false},
		{"key": str(state.get("pageLedgerRunLabel", "")), "value": str(state.get("pageLedgerRun", "")), "badge": false},
		{"key": str(state.get("pageLedgerContractLabel", "")), "value": str(state.get("pageLedgerContract", "")), "badge": true}
	]
	var row_index := 0
	for child in ledger_rows.get_children():
		var row := child as HBoxContainer
		if row == null:
			continue
		if row_index >= entries.size():
			row.visible = false
			row_index += 1
			continue
		var entry: Dictionary = entries[row_index]
		var key_label := row.get_node_or_null("RowKey") as Label
		var value_label := row.get_node_or_null("RowValue") as Label
		if key_label != null:
			key_label.text = str(entry.get("key", ""))
		if value_label != null:
			value_label.text = str(entry.get("value", ""))
			_apply_ledger_value_badge(value_label, bool(entry.get("badge", false)))
		row.visible = not str(entry.get("value", "")).is_empty()
		row_index += 1

# 실행: paint the last ledger row's value as a filled pill badge (contract-state emphasis), matching the mockup.
func _apply_ledger_value_badge(value_label: Label, is_badge: bool) -> void:
	if not is_badge:
		value_label.remove_theme_stylebox_override("normal")
		return
	var badge_style := LTLThemeScript.surface_style(LTLThemeScript.LIMESTONE_FILL, LTLThemeScript.SECONDARY, 999, 1, 0.0)
	badge_style.content_margin_left = 14.0
	badge_style.content_margin_right = 14.0
	badge_style.content_margin_top = 4.0
	badge_style.content_margin_bottom = 4.0
	value_label.add_theme_stylebox_override("normal", badge_style)

# 실행: fill the survey seal card copy.
func _apply_seal(state: Dictionary) -> void:
	seal_kicker.text = str(state.get("pageSealKicker", ""))
	seal_title.text = str(state.get("pageSealTitle", ""))
	seal_note.text = str(state.get("pageSealNote", ""))
	seal_kicker.visible = not seal_kicker.text.is_empty()
	seal_title.visible = not seal_title.text.is_empty()
	seal_note.visible = not seal_note.text.is_empty()

# 실행: paint parchment folio surfaces, ledger typography, seal, stamp, and hero CTA styles.
func _apply_theme() -> void:
	page_backdrop.texture = LTLThemeScript.art_texture(PARCHMENT_BG_PATH)

	ledger_panel.add_theme_stylebox_override("panel", LTLThemeScript.parchment_style(16, 0.45))
	seal_panel.add_theme_stylebox_override("panel", LTLThemeScript.parchment_style(16, 0.45))
	hero_band.add_theme_stylebox_override("panel", LTLThemeScript.parchment_style(16, 0.50))

	eyebrow_label.add_theme_font_size_override("font_size", 13)
	eyebrow_label.add_theme_color_override("font_color", LTLThemeScript.SECONDARY)

	title_label.add_theme_font_size_override("font_size", 46)
	title_label.add_theme_color_override("font_color", LTLThemeScript.PRIMARY)

	subtitle_label.add_theme_font_size_override("font_size", 17)
	subtitle_label.add_theme_color_override("font_color", LTLThemeScript.ON_SURFACE_VARIANT)

	ledger_title.add_theme_font_size_override("font_size", 22)
	ledger_title.add_theme_color_override("font_color", LTLThemeScript.PRIMARY)
	ledger_en_sub.add_theme_font_size_override("font_size", 11)
	ledger_en_sub.add_theme_color_override("font_color", LTLThemeScript.OUTLINE)

	for child in ledger_rows.get_children():
		var row := child as HBoxContainer
		if row == null:
			continue
		row.add_theme_stylebox_override("panel", LTLThemeScript.ledger_card_style())
		var key_label := row.get_node_or_null("RowKey") as Label
		if key_label != null:
			key_label.add_theme_font_size_override("font_size", 14)
			key_label.add_theme_color_override("font_color", LTLThemeScript.ON_SURFACE_VARIANT)
		var value_label := row.get_node_or_null("RowValue") as Label
		if value_label != null:
			value_label.add_theme_font_size_override("font_size", 18)
			value_label.add_theme_color_override("font_color", LTLThemeScript.SECONDARY)

	seal_glow.texture = LTLThemeScript.art_texture(SEAL_GLOW_TEXTURE_PATH)
	var seal_style := LTLThemeScript.surface_style(LTLThemeScript.LIMESTONE_FILL, LTLThemeScript.SECONDARY, 999, 3, 0.0)
	seal_circle.add_theme_stylebox_override("panel", seal_style)
	seal_check.add_theme_font_size_override("font_size", 54)
	seal_check.add_theme_color_override("font_color", LTLThemeScript.PRIMARY)

	seal_kicker.add_theme_font_size_override("font_size", 11)
	seal_kicker.add_theme_color_override("font_color", LTLThemeScript.OUTLINE)
	seal_title.add_theme_font_size_override("font_size", 24)
	seal_title.add_theme_color_override("font_color", LTLThemeScript.PRIMARY)
	seal_note.add_theme_font_size_override("font_size", 12)
	seal_note.add_theme_color_override("font_color", LTLThemeScript.ON_SURFACE_VARIANT)

	hero_caption.add_theme_font_size_override("font_size", 13)
	hero_caption.add_theme_color_override("font_color", LTLThemeScript.PRIMARY)
	hero_caption.add_theme_stylebox_override("normal", LTLThemeScript.limestone_style(8))

	# 이미지 외곽 기준 정렬: 스탬프 PNG는 알파 타이트 크롭본이라 박스=가시 픽셀 외곽이다.
	# 회전은 표시 단계에서만 적용해 bbox 예측 가능성을 유지한다.
	stamp_image.texture = LTLThemeScript.art_texture(STAMP_TEXTURE_PATH)
	stamp_image.pivot_offset = stamp_image.size * 0.5
	stamp_image.rotation = deg_to_rad(STAMP_ROTATION_DEG)

	return_button.focus_mode = Control.FOCUS_NONE
	return_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	return_button.add_theme_font_size_override("font_size", 16)
	return_button.add_theme_color_override("font_color", LTLThemeScript.ON_PRIMARY)
	return_button.add_theme_color_override("font_hover_color", LTLThemeScript.ON_PRIMARY)
	return_button.add_theme_color_override("font_pressed_color", LTLThemeScript.ON_PRIMARY)
	for state_name in ["normal", "hover", "pressed", "focus"]:
		var style_state: String = state_name if state_name != "focus" else "hover"
		return_button.add_theme_stylebox_override(state_name, LTLThemeScript.hero_button_style(style_state))
