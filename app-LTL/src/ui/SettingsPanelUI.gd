# 계약:
# - 책임: Settings drawer, sound slider, screenshake, fullscreen checkbox UI 이벤트를 처리한다.
# - 입력: settings UI widgets (HSlider, CheckBoxes, Buttons).
# - 출력: volume_changed, screenshake_toggled, fullscreen_toggled, reset_requested 시그널 및 UI 상태 업데이트.
# - 금지: core simulator 참조, direct scene transition.
# 실행: define the Settings panel controller and its signals.
extends PanelContainer
signal volume_changed(value: float)
signal screenshake_toggled(enabled: bool)
signal fullscreen_toggled(enabled: bool)
signal reset_requested()

# 실행: cache settings panel subnodes.
@onready var screenshake_checkbox: CheckBox = $Center/SettingsBox/GameplaySection/ScreenshakeCheckbox
@onready var fullscreen_checkbox: CheckBox = $Center/SettingsBox/ScreenSection/FullscreenCheckbox
@onready var volume_slider: HSlider = $Center/SettingsBox/SoundSection/VolumeSlider
@onready var main_menu_button: Button = $Center/SettingsBox/ButtonsRow/MainMenuButton
@onready var close_settings_button: Button = $Center/SettingsBox/ButtonsRow/CloseSettingsButton

# 실행: wire up signals and inputs.
func _ready() -> void:
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
