# 계약:
# - 책임: Settings drawer, sound slider, screenshake, fullscreen checkbox UI 이벤트를 처리한다.
# - 입력: settings UI widgets (HSlider, CheckBoxes, Buttons).
# - 출력: volume_changed, screenshake_toggled, fullscreen_toggled, reset_requested 시그널 및 UI 상태 업데이트.
# - 금지: core simulator 참조, direct scene transition.
# 실행: define the Settings panel controller and its signals.
extends PanelContainer
const TextCatalogScript = preload("res://src/ui/TextCatalog.gd")
signal volume_changed(value: float)
signal screenshake_toggled(enabled: bool)
signal fullscreen_toggled(enabled: bool)
signal language_changed(locale: String)
signal reset_requested()

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

# 실행: wire up signals and inputs.
func _ready() -> void:
	_create_language_selector()
	apply_locale()
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
		volume_changed.emit(val)
	)

# 실행: initialize values.
func setup(shake_enabled: bool, is_fullscreen: bool) -> void:
	screenshake_checkbox.button_pressed = shake_enabled
	fullscreen_checkbox.button_pressed = is_fullscreen
	apply_locale()

# 실행: create the language selector as a settings control.
func _create_language_selector() -> void:
	if language_select != null:
		return
	var row := HBoxContainer.new()
	row.name = "LanguageRow"
	var label := Label.new()
	label.name = "LanguageLabel"
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(label)
	language_select = OptionButton.new()
	language_select.add_item(TextCatalogScript.t("settings.language.ko", [], "ko"), 0)
	language_select.add_item(TextCatalogScript.t("settings.language.en", [], "en"), 1)
	language_select.item_selected.connect(func(index: int):
		var next_locale := "ko" if index == 0 else "en"
		TextCatalogScript.set_locale(next_locale)
		apply_locale()
		language_changed.emit(next_locale)
	)
	row.add_child(language_select)
	settings_box.add_child(row)
	settings_box.move_child(row, 2)

# 실행: refresh every settings label from the active text catalog.
func apply_locale() -> void:
	if settings_title == null:
		return
	settings_title.text = TextCatalogScript.t("settings.title")
	gameplay_title.text = TextCatalogScript.t("settings.gameplay")
	screenshake_checkbox.text = TextCatalogScript.t("settings.screenshake")
	screen_title.text = TextCatalogScript.t("settings.screen")
	fullscreen_checkbox.text = TextCatalogScript.t("settings.fullscreen")
	sound_title.text = TextCatalogScript.t("settings.sound")
	main_menu_button.text = TextCatalogScript.t("action.main_menu")
	close_settings_button.text = TextCatalogScript.t("action.apply_close")
	if language_select != null:
		var row := language_select.get_parent()
		if row != null and row.has_node("LanguageLabel"):
			(row.get_node("LanguageLabel") as Label).text = TextCatalogScript.t("settings.language")
		language_select.selected = 0 if TextCatalogScript.locale() == "ko" else 1
