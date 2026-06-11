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

# 실행: wire up signals and inputs.
func _ready() -> void:
	_create_language_selector()
	_create_accessibility_rows()
	_create_volume_value_label()
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
		_update_volume_value_label(val)
		volume_changed.emit(val)
	)
	visibility_changed.connect(func():
		if visible:
			focus_first_control()
		else:
			settings_closed.emit()
	)

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

func _create_volume_value_label() -> void:
	if volume_value_label != null:
		return
	var row := HBoxContainer.new()
	row.name = "VolumeValueRow"
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(spacer)
	volume_value_label = Label.new()
	volume_value_label.name = "VolumeValueLabel"
	row.add_child(volume_value_label)
	$Center/SettingsBox/SoundSection.add_child(row)
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
	if language_select != null:
		var row := language_select.get_parent()
		if row != null and row.has_node("LanguageLabel"):
			(row.get_node("LanguageLabel") as Label).text = TextCatalogScript.t("settings.language")
		language_select.set_item_text(0, TextCatalogScript.t("settings.language.ko", [], "ko"))
		language_select.set_item_text(1, TextCatalogScript.t("settings.language.en", [], "en"))
		language_select.selected = 0 if TextCatalogScript.locale() == "ko" else 1

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
