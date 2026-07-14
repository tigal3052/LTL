# 계약:
# - 책임: Settings drawer, sound slider, screenshake, fullscreen checkbox UI 이벤트를 처리한다.
#   추가로 "탐험 수첩" 폴리오 오버레이의 시각 구성(제목 행/섹션 원장/딤 동기화)을 담당한다.
# - 입력: settings UI widgets (HSlider, CheckBoxes, Buttons), 형제 노드 SettingsDim(ColorRect).
# - 출력: volume_changed, screenshake_toggled, fullscreen_toggled, reset_requested 시그널 및 UI 상태 업데이트.
#   딤 가시성은 이 패널의 visible을 그대로 따른다(팝업 오버레이 계약: 딤은 패널 바로 뒤 층).
# - 금지: core simulator 참조, direct scene transition, 노드 경로/이름 변경(기존 @onready 계약 유지).
# 실행: define the Settings panel controller and its signals.
extends PanelContainer
const TextCatalogScript = preload("res://src/ui/TextCatalog.gd")

# 계약: 섹션 영문 보조 라벨은 스티치 원안 관례상 로케일 무관 고정 영문이므로 TextCatalog 대상이 아니다.
#   (i18n 게이트 오해 방지를 위해 상수로 분리해 의도를 명시한다.)
const SECTION_EN_LABELS := {
	"system": "SYSTEM",
	"gameplay": "GAMEPLAY",
	"screen": "DISPLAY",
	"sound": "SOUND",
}
# 계약: 수첩 카드 장식 자산(알파 경계 크롭본 — 가시 픽셀 외곽 기준 정렬).
const LeafSprigTexture = preload("res://resources/UI/settings_redesign/icon_leaf_sprig.png")
# 계약: 수첩 타이포 위계 — 제목/수치는 세리프(NotoSerifKR), 라벨/보조는 WorkSans.
const JournalSerifFont = preload("res://resources/fonts/codex/NotoSerifKR-VariableFont_wght.ttf")
const JournalLabelFont = preload("res://resources/fonts/codex/WorkSans-VariableFont_wght.ttf")
signal volume_changed(value: float)
signal screenshake_toggled(enabled: bool)
signal fullscreen_toggled(enabled: bool)
signal language_changed(locale: String)
signal reduced_flash_toggled(enabled: bool)
signal reduced_particles_toggled(enabled: bool)
signal hold_fire_assist_toggled(enabled: bool)
signal reset_requested()
signal settings_closed()

# 실행: cache settings panel subnodes.
@onready var screenshake_checkbox: CheckBox = $Center/SettingsBox/GameplaySection/ScreenshakeCheckbox
@onready var fullscreen_checkbox: CheckBox = $Center/SettingsBox/ScreenSection/FullscreenCheckbox
@onready var volume_slider: HSlider = $Center/SettingsBox/SoundSection/VolumeSlider
@onready var main_menu_button: Button = $Center/SettingsBox/ButtonsRow/MainMenuButton
@onready var close_settings_button: Button = $Center/SettingsBox/ButtonsRow/CloseSettingsButton
@onready var settings_box: VBoxContainer = $Center/SettingsBox
@onready var settings_title: Label = $Center/SettingsBox/SettingsTitle
@onready var gameplay_title: Label = $Center/SettingsBox/GameplaySection/SectionTitle
@onready var screen_title: Label = $Center/SettingsBox/ScreenSection/SectionTitle
@onready var sound_title: Label = $Center/SettingsBox/SoundSection/SectionTitle
var language_select: OptionButton
var reduced_flash_checkbox: CheckBox
var reduced_particles_checkbox: CheckBox
var hold_fire_assist_checkbox: CheckBox
var volume_value_label: Label
var _syncing_language_select := false
# 실행: 수첩 폴리오 신규 시각 노드 캐시.
var journal_title_label: Label
var journal_chip_label: Label
var volume_name_label: Label
var _settings_dim: ColorRect
var _toggle_on_tex: ImageTexture
var _toggle_off_tex: ImageTexture

# 실행: wire up signals and inputs.
func _ready() -> void:
	_cache_settings_dim()
	_create_journal_title_row()
	_create_language_selector()
	_create_accessibility_rows()
	_create_volume_value_label()
	_decorate_section_titles()
	_apply_journal_theme()
	apply_locale()

# 계약: 씬 정의 컨트롤과 스크립트 생성 컨트롤에 동일한 수첩 스킨을 적용한다.
# 실행: skin every settings control with the journal folio theme.
func _apply_journal_theme() -> void:
	_wrap_ledger_row(screenshake_checkbox)
	_wrap_ledger_row(fullscreen_checkbox)
	_wrap_ledger_row(reduced_flash_checkbox)
	_wrap_ledger_row(reduced_particles_checkbox)
	_wrap_ledger_row(hold_fire_assist_checkbox)
	_skin_ledger_checkbox(screenshake_checkbox)
	_skin_ledger_checkbox(fullscreen_checkbox)
	_skin_ledger_checkbox(reduced_flash_checkbox)
	_skin_ledger_checkbox(reduced_particles_checkbox)
	_skin_ledger_checkbox(hold_fire_assist_checkbox)
	_skin_language_select()
	close_settings_button.pressed.connect(func(): visible = false)
	main_menu_button.pressed.connect(func():
		visible = false
		reset_requested.emit()
	)
	screenshake_checkbox.toggled.connect(func(toggled: bool):
		screenshake_toggled.emit(toggled)
	)
	fullscreen_checkbox.toggled.connect(func(toggled: bool):
		fullscreen_toggled.emit(toggled)
	)
	volume_slider.value_changed.connect(func(val: float):
		_update_volume_value_label(val)
		volume_changed.emit(val)
	)
	visibility_changed.connect(func():
		_sync_dim_visibility()
		if visible:
			focus_first_control()
		else:
			settings_closed.emit()
	)
	_sync_dim_visibility()

# 실행: initialize values.
func setup(shake_enabled: bool, is_fullscreen: bool, accessibility_state: Dictionary = {}) -> void:
	screenshake_checkbox.button_pressed = shake_enabled
	fullscreen_checkbox.button_pressed = is_fullscreen
	if reduced_flash_checkbox != null:
		reduced_flash_checkbox.button_pressed = bool(accessibility_state.get("reducedFlash", false))
	if reduced_particles_checkbox != null:
		reduced_particles_checkbox.button_pressed = bool(accessibility_state.get("reducedParticles", false))
	if hold_fire_assist_checkbox != null:
		hold_fire_assist_checkbox.button_pressed = bool(accessibility_state.get("holdFireAssist", false))
	_update_volume_value_label(volume_slider.value)
	apply_locale()

# 계약: 토글/드롭다운 스킨은 씬 정의 컨트롤과 스크립트 생성 컨트롤에 동일하게 적용된다(단일 SoT).
#   토글 png는 @2x(112x56)이므로 표시 크기(56x28)로 축소한 ImageTexture를 공유한다.
# 실행: build the downscaled toggle icon textures once.
static func _scaled_toggle_texture(path: String) -> ImageTexture:
	var source: Texture2D = load(path)
	var image: Image = source.get_image()
	image.resize(56, 28, Image.INTERPOLATE_LANCZOS)
	return ImageTexture.create_from_image(image)

# 계약: 원장 행은 [키 라벨][스페이서][토글] 구조다.
#   Godot CheckBox는 체크 아이콘을 항상 텍스트 앞에 그려 icon_alignment가 듣지 않으므로,
#   카피는 형제 Label(LedgerKeyLabel)이 담당하고 CheckBox는 토글 표시/입력만 맡는다.
#   카피의 SoT는 여전히 CheckBox.text(TextCatalog 경유)이며, 라벨은 그 값을 그대로 미러링한다.
# 실행: wrap a checkbox into a ledger row with its key label on the left.
func _wrap_ledger_row(box: CheckBox) -> void:
	if box == null or box.get_parent() == null:
		return
	if box.get_parent().name == "LedgerRow":
		return
	var section := box.get_parent()
	var index := box.get_index()
	var row := HBoxContainer.new()
	row.name = "LedgerRow"
	row.add_theme_constant_override("separation", 12)
	section.add_child(row)
	section.move_child(row, index)
	var key := Label.new()
	key.name = "LedgerKeyLabel"
	key.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	key.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	key.add_theme_color_override("font_color", Color(0.172549, 0.0862745, 0.0196078, 1))
	key.add_theme_font_size_override("font_size", 15)
	key.add_theme_font_override("font", JournalLabelFont)
	row.add_child(key)
	section.remove_child(box)
	# 실행: 토글은 고정 폭 슬롯 안에 넣어 텍스트 길이와 무관하게 우측 가시 외곽이 일치하게 한다(A3).
	var slot := Control.new()
	slot.name = "LedgerToggleSlot"
	slot.custom_minimum_size = Vector2(56, 32)
	slot.size_flags_horizontal = Control.SIZE_SHRINK_END
	slot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	slot.clip_contents = true
	row.add_child(slot)
	slot.add_child(box)
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	box.size_flags_vertical = Control.SIZE_SHRINK_CENTER

# 실행: resolve the ledger key label that belongs to a checkbox (row = slot's parent).
func _ledger_key_label_for(box: CheckBox) -> Label:
	var slot := box.get_parent()
	if slot == null:
		return null
	var row := slot.get_parent()
	if row == null:
		return null
	return row.get_node_or_null("LedgerKeyLabel") as Label

# 실행: mirror each checkbox caption onto its ledger key label (CheckBox.text stays the SoT).
func _sync_ledger_key_labels() -> void:
	for box in [screenshake_checkbox, fullscreen_checkbox, reduced_flash_checkbox, reduced_particles_checkbox, hold_fire_assist_checkbox]:
		if box == null or box.get_parent() == null:
			continue
		# 실행: 체크박스는 LedgerToggleSlot 안에 있으므로 키 라벨은 조부모(LedgerRow) 아래에 있다.
		var key := _ledger_key_label_for(box)
		if key == null:
			continue
		key.text = box.text
		# 실행: 토글 옆 중복 표기를 막는다(카피는 좌측 키 라벨만 표시).
		box.tooltip_text = box.text

# 계약: 접근성 체크박스는 씬 정의 체크박스(ScreenshakeCheckbox/FullscreenCheckbox)와 동일한 원장 행 문법을 따른다.
# 실행: apply the journal ledger skin to one checkbox.
func _skin_ledger_checkbox(box: CheckBox) -> void:
	if box == null:
		return
	box.add_theme_icon_override("checked", _toggle_on_texture())
	box.add_theme_icon_override("unchecked", _toggle_off_texture())
	box.add_theme_constant_override("h_separation", 0)
	# 계약: 원장 문법 — 키(텍스트) 좌측, 컨트롤(토글) 우측.
	#   CheckBox는 아이콘을 텍스트보다 먼저 그리므로, 아이콘을 우측으로 밀려면
	#   버튼이 행 전체 폭을 차지하고(EXPAND_FILL) 텍스트가 좌측 정렬이어야 한다.
	box.alignment = HORIZONTAL_ALIGNMENT_RIGHT
	box.vertical_icon_alignment = VERTICAL_ALIGNMENT_CENTER
	box.expand_icon = false
	# 실행: 폭/정렬은 LedgerToggleSlot(고정 56px)이 결정한다.
	box.custom_minimum_size = Vector2(56, 32)
	# 실행: 카피는 좌측 키 라벨이 담당하므로 버튼 자체 텍스트는 투명 처리한다.
	#   (text 속성은 TextCatalog SoT로 유지 — 라벨 미러링/툴팁이 이 값을 읽는다.)
	for color_name in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_disabled_color"]:
		box.add_theme_color_override(color_name, Color(0, 0, 0, 0))
	box.add_theme_font_size_override("font_size", 1)
	var flat := StyleBoxEmpty.new()
	flat.content_margin_left = 6.0
	flat.content_margin_right = 6.0
	for style_name in ["normal", "hover", "pressed", "focus", "disabled"]:
		box.add_theme_stylebox_override(style_name, flat)

func _toggle_on_texture() -> ImageTexture:
	if _toggle_on_tex == null:
		_toggle_on_tex = _scaled_toggle_texture("res://resources/UI/settings_redesign/toggle_on.png")
	return _toggle_on_tex

func _toggle_off_texture() -> ImageTexture:
	if _toggle_off_tex == null:
		_toggle_off_tex = _scaled_toggle_texture("res://resources/UI/settings_redesign/toggle_off.png")
	return _toggle_off_tex

# 계약: 언어 드롭다운은 스티치 초록 필 스킨을 쓰고, 팝업 목록도 양피지 톤을 유지한다.
# 실행: apply the parchment pill skin to the language OptionButton.
func _skin_language_select() -> void:
	if language_select == null:
		return
	var pill := StyleBoxTexture.new()
	pill.texture = load("res://resources/UI/settings_redesign/dropdown_pill.png")
	pill.set_texture_margin_all(24)
	pill.content_margin_left = 20.0
	pill.content_margin_right = 44.0
	pill.content_margin_top = 12.0
	pill.content_margin_bottom = 12.0
	for style_name in ["normal", "hover", "pressed", "focus", "disabled"]:
		language_select.add_theme_stylebox_override(style_name, pill)
	language_select.add_theme_color_override("font_color", Color(0.172549, 0.0862745, 0.0196078, 1))
	language_select.add_theme_color_override("font_hover_color", Color(0.0941176, 0.227451, 0.121569, 1))
	language_select.add_theme_color_override("font_pressed_color", Color(0.0941176, 0.227451, 0.121569, 1))
	language_select.add_theme_color_override("font_focus_color", Color(0.172549, 0.0862745, 0.0196078, 1))
	language_select.add_theme_font_size_override("font_size", 14)
	language_select.add_theme_font_override("font", JournalLabelFont)
	# 실행: 필 우측 셰브론은 스킨에 그려져 있으므로 기본 화살표를 숨긴다.
	language_select.add_theme_icon_override("arrow", ImageTexture.new())

# 계약: 딤은 이 패널의 형제 노드 SettingsDim이며, 부재해도(테스트 하네스 등) 동작이 깨지지 않아야 한다.
# 실행: cache the sibling dim rect.
func _cache_settings_dim() -> void:
	var parent := get_parent()
	if parent == null:
		return
	_settings_dim = parent.get_node_or_null("SettingsDim") as ColorRect

# 계약: 딤 가시성은 패널 가시성을 그대로 따르고, 딤은 항상 패널보다 한 층 뒤에 그려진다.
# 실행: mirror panel visibility onto the dim and keep it directly beneath the panel.
func _sync_dim_visibility() -> void:
	if _settings_dim == null:
		_cache_settings_dim()
	if _settings_dim == null:
		return
	_settings_dim.visible = visible
	if not visible:
		return
	# 계약: 팝업 최상위 계약 — 딤은 게임플레이 위, 카드 바로 아래.
	#   패널의 z_index는 MainView의 PopupOverlayHost 승격이 끝난 뒤에 확정되므로,
	#   딤 승격은 같은 프레임의 승격 이후로 미뤄 항상 패널 z를 기준으로 계산한다.
	call_deferred("_promote_dim_behind_panel")

# 실행: keep the dim exactly one layer beneath the promoted panel.
func _promote_dim_behind_panel() -> void:
	if _settings_dim == null or not visible:
		return
	_settings_dim.z_index = max(z_index - 1, 0)
	var parent := get_parent()
	if parent == null or _settings_dim.get_parent() != parent:
		return
	# 실행: 형제 순서도 패널 바로 앞(=아래 층)으로 이동.
	parent.move_child(_settings_dim, max(get_index(), 1) - 1)

# 계약: 수첩 제목 행은 잎 장식(가시 픽셀 외곽 기준) + 제목 + EXPEDITION JOURNAL 칩으로 구성한다.
#   기존 SettingsTitle 노드는 "시스템 설정" 섹션 헤더로 역할이 바뀌므로 제목 행에서 재사용하지 않는다.
# 실행: build the journal title row above the existing settings box content.
func _create_journal_title_row() -> void:
	if journal_title_label != null:
		return
	var row := HBoxContainer.new()
	row.name = "JournalTitleRow"
	row.add_theme_constant_override("separation", 12)
	row.custom_minimum_size = Vector2(0, 40)
	# 실행: 잎 장식 — 알파 크롭본을 원본 비율로 두어 박스가 아닌 가시 외곽이 제목 광학 중심에 오게 한다.
	var leaf := TextureRect.new()
	leaf.name = "JournalLeaf"
	leaf.texture = LeafSprigTexture
	leaf.custom_minimum_size = Vector2(24, 28)
	leaf.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	leaf.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	leaf.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(leaf)
	journal_title_label = Label.new()
	journal_title_label.name = "JournalTitle"
	journal_title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	journal_title_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	journal_title_label.add_theme_color_override("font_color", Color(0.0941176, 0.227451, 0.121569, 1))
	journal_title_label.add_theme_font_size_override("font_size", 30)
	# 실행: 폰트를 명시하지 않으면 기본 테마 폰트가 과대 라인하이트로 행을 부풀린다.
	journal_title_label.add_theme_font_override("font", JournalSerifFont)
	journal_title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(journal_title_label)
	journal_chip_label = Label.new()
	journal_chip_label.name = "JournalChip"
	journal_chip_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	journal_chip_label.add_theme_color_override("font_color", Color(0.231373, 0.411765, 0.164706, 1))
	journal_chip_label.add_theme_font_size_override("font_size", 12)
	journal_chip_label.add_theme_font_override("font", JournalLabelFont)
	var chip_style := StyleBoxFlat.new()
	chip_style.bg_color = Color(0.909804, 0.937255, 0.819608, 0.55)
	chip_style.border_color = Color(0.231373, 0.411765, 0.164706, 0.35)
	chip_style.set_border_width_all(1)
	# 실행: 필 형태 유지하되 9999는 스타일박스 최소 높이를 부풀리므로 실제 높이 기준 반경 사용.
	chip_style.set_corner_radius_all(12)
	chip_style.content_margin_left = 12.0
	chip_style.content_margin_right = 12.0
	chip_style.content_margin_top = 4.0
	chip_style.content_margin_bottom = 4.0
	journal_chip_label.add_theme_stylebox_override("normal", chip_style)
	# 계약: 칩 카피는 스티치 관례의 고정 영문 라벨(로케일 무관).
	journal_chip_label.text = "EXPEDITION JOURNAL"
	row.add_child(journal_chip_label)
	settings_box.add_child(row)
	settings_box.move_child(row, 0)

# 계약: 각 섹션 헤더 우측에 고정 영문 보조 라벨을 붙인다(스티치 원장 문법).
# 실행: wrap each section title into a row carrying its English sub-label.
func _decorate_section_titles() -> void:
	_decorate_section_title(settings_title, "system")
	_decorate_section_title(gameplay_title, "gameplay")
	_decorate_section_title(screen_title, "screen")
	_decorate_section_title(sound_title, "sound")

func _decorate_section_title(title_label: Label, key: String) -> void:
	if title_label == null or title_label.get_parent() == null:
		return
	if title_label.get_parent().name == "SectionTitleRow":
		return
	var section := title_label.get_parent()
	var index := title_label.get_index()
	var row := HBoxContainer.new()
	row.name = "SectionTitleRow"
	row.add_theme_constant_override("separation", 8)
	row.custom_minimum_size = Vector2(0, 22)
	section.add_child(row)
	section.move_child(row, index)
	section.remove_child(title_label)
	row.add_child(title_label)
	title_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	var en := Label.new()
	en.name = "SectionTitleEn"
	en.text = str(SECTION_EN_LABELS.get(key, ""))
	en.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	en.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	en.add_theme_color_override("font_color", Color(0.258824, 0.282353, 0.254902, 0.55))
	en.add_theme_font_size_override("font_size", 11)
	en.add_theme_font_override("font", JournalLabelFont)
	row.add_child(en)

# 실행: create the language selector as a settings control.
func _create_language_selector() -> void:
	if language_select != null:
		return
	var row := HBoxContainer.new()
	row.name = "LanguageRow"
	var label := Label.new()
	label.name = "LanguageLabel"
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	# 실행: 원장 행 키 타이포(라벨 계열).
	label.add_theme_color_override("font_color", Color(0.172549, 0.0862745, 0.0196078, 1))
	label.add_theme_font_size_override("font_size", 15)
	label.add_theme_font_override("font", JournalLabelFont)
	row.add_child(label)
	language_select = OptionButton.new()
	language_select.custom_minimum_size = Vector2(300, 46)
	language_select.add_item(TextCatalogScript.t("settings.language.ko", [], "ko"), 0)
	language_select.add_item(TextCatalogScript.t("settings.language.en", [], "en"), 1)
	language_select.item_selected.connect(func(index: int):
		if _syncing_language_select:
			return
		var next_locale := _locale_for_language_index(index)
		if TextCatalogScript.locale() == next_locale:
			return
		TextCatalogScript.set_locale(next_locale)
		apply_locale()
		language_changed.emit(next_locale)
	)
	row.add_child(language_select)
	settings_box.add_child(row)
	# 계약: 언어 행은 "시스템 설정" 헤더(SettingsTitle) 바로 아래에 온다.
	#   고정 인덱스 대신 헤더 위치를 조회해 신규 제목 행 추가에도 순서가 유지되게 한다.
	settings_box.move_child(row, _system_section_row_index())

# 실행: resolve the insert index right beneath the system section header.
func _system_section_row_index() -> int:
	if settings_title == null:
		return 2
	var anchor: Node = settings_title
	# 실행: 섹션 헤더가 SectionTitleRow로 감싸졌다면 그 행이 기준이 된다.
	if anchor.get_parent() != null and anchor.get_parent().name == "SectionTitleRow":
		anchor = anchor.get_parent()
	if anchor.get_parent() != settings_box:
		return 2
	return anchor.get_index() + 1

func _create_accessibility_rows() -> void:
	if reduced_flash_checkbox != null:
		return
	reduced_flash_checkbox = CheckBox.new()
	reduced_particles_checkbox = CheckBox.new()
	hold_fire_assist_checkbox = CheckBox.new()
	$Center/SettingsBox/GameplaySection.add_child(reduced_flash_checkbox)
	$Center/SettingsBox/GameplaySection.add_child(reduced_particles_checkbox)
	$Center/SettingsBox/GameplaySection.add_child(hold_fire_assist_checkbox)
	reduced_flash_checkbox.toggled.connect(func(toggled: bool): reduced_flash_toggled.emit(toggled))
	reduced_particles_checkbox.toggled.connect(func(toggled: bool): reduced_particles_toggled.emit(toggled))
	hold_fire_assist_checkbox.toggled.connect(func(toggled: bool): hold_fire_assist_toggled.emit(toggled))

# 계약: 주 음량 행은 슬라이더 "위"에 놓이고, 좌측 이름/우측 수치의 원장 문법을 따른다(스티치 소리 설정 패널).
func _create_volume_value_label() -> void:
	if volume_value_label != null:
		return
	var row := HBoxContainer.new()
	row.name = "VolumeValueRow"
	volume_name_label = Label.new()
	volume_name_label.name = "VolumeNameLabel"
	volume_name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	volume_name_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	volume_name_label.add_theme_color_override("font_color", Color(0.172549, 0.0862745, 0.0196078, 1))
	volume_name_label.add_theme_font_size_override("font_size", 15)
	volume_name_label.add_theme_font_override("font", JournalLabelFont)
	row.add_child(volume_name_label)
	volume_value_label = Label.new()
	volume_value_label.name = "VolumeValueLabel"
	volume_value_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	# 실행: 수치는 수첩 제목 계열(세리프)로 강조한다.
	volume_value_label.add_theme_color_override("font_color", Color(0.0941176, 0.227451, 0.121569, 1))
	volume_value_label.add_theme_font_size_override("font_size", 24)
	volume_value_label.add_theme_font_override("font", JournalSerifFont)
	row.add_child(volume_value_label)
	var sound_section := $Center/SettingsBox/SoundSection
	sound_section.add_child(row)
	# 실행: 슬라이더 위로 이동(섹션 헤더 다음).
	sound_section.move_child(row, max(volume_slider.get_index(), 0))
	_update_volume_value_label(volume_slider.value)

func _update_volume_value_label(value: float) -> void:
	if volume_value_label == null:
		return
	volume_value_label.text = "%d%%" % int(round(value))

# 실행: refresh every settings label from the active text catalog.
func apply_locale() -> void:
	if settings_title == null:
		return
	settings_title.text = TextCatalogScript.t("settings.title")
	if journal_title_label != null:
		journal_title_label.text = TextCatalogScript.t("settings.journal.title")
	if volume_name_label != null:
		volume_name_label.text = TextCatalogScript.t("settings.volume.master")
	gameplay_title.text = TextCatalogScript.t("settings.gameplay")
	screenshake_checkbox.text = TextCatalogScript.t("settings.screenshake")
	if reduced_flash_checkbox != null:
		reduced_flash_checkbox.text = TextCatalogScript.t("settings.reduced_flash")
	if reduced_particles_checkbox != null:
		reduced_particles_checkbox.text = TextCatalogScript.t("settings.reduced_particles")
	if hold_fire_assist_checkbox != null:
		hold_fire_assist_checkbox.text = TextCatalogScript.t("settings.hold_fire_assist")
	screen_title.text = TextCatalogScript.t("settings.screen")
	fullscreen_checkbox.text = TextCatalogScript.t("settings.fullscreen")
	sound_title.text = TextCatalogScript.t("settings.sound")
	main_menu_button.text = TextCatalogScript.t("action.main_menu")
	close_settings_button.text = TextCatalogScript.t("action.apply_close")
	_sync_ledger_key_labels()
	if language_select != null:
		var row := language_select.get_parent()
		if row != null and row.has_node("LanguageLabel"):
			(row.get_node("LanguageLabel") as Label).text = TextCatalogScript.t("settings.language")
		language_select.set_item_text(0, TextCatalogScript.t("settings.language.ko", [], "ko"))
		language_select.set_item_text(1, TextCatalogScript.t("settings.language.en", [], "en"))
		_sync_language_select_to_locale()

func _locale_for_language_index(index: int) -> String:
	return "ko" if index == 0 else "en"

func _language_index_for_locale(locale: String) -> int:
	return 1 if locale == "en" else 0

func _sync_language_select_to_locale() -> void:
	if language_select == null:
		return
	_syncing_language_select = true
	language_select.select(_language_index_for_locale(TextCatalogScript.locale()))
	_syncing_language_select = false

func focus_first_control() -> void:
	if screenshake_checkbox != null:
		screenshake_checkbox.grab_focus()

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel"):
		visible = false
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_accept") and close_settings_button != null and close_settings_button.has_focus():
		visible = false
		get_viewport().set_input_as_handled()
