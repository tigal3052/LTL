extends PanelContainer

const TextCatalogScript = preload("res://src/ui/TextCatalog.gd")
const LTLThemeScript = preload("res://src/ui/theme/LTLTheme.gd")

@onready var explorer_tab_button: Button = $Margin/SidebarBox/TabRow/ExplorerTabButton
@onready var log_info_tab_button: Button = $Margin/SidebarBox/TabRow/LogInfoTabButton
@onready var explorer_content: Control = $Margin/SidebarBox/TabViewport/ExplorerContent
@onready var log_content: Control = $Margin/SidebarBox/TabViewport/LogContent
@onready var character_title: Label = $Margin/SidebarBox/TabViewport/ExplorerContent/Margin/CharacterBox/CharacterTitle
@onready var log_title: Label = $Margin/SidebarBox/TabViewport/LogContent/Margin/LogBox/LogTitle

var _active_tab := "explorer"

func _ready() -> void:
	explorer_tab_button.pressed.connect(func() -> void:
		_set_active_tab("explorer")
	)
	log_info_tab_button.pressed.connect(func() -> void:
		_set_active_tab("log")
	)
	_apply_shell_theme()
	apply_locale()
	_set_active_tab("explorer")

func apply_locale() -> void:
	explorer_tab_button.text = TextCatalogScript.t("panel.tab.explorer")
	log_info_tab_button.text = TextCatalogScript.t("panel.tab.log_info")
	character_title.text = TextCatalogScript.t("panel.character_status")
	log_title.text = TextCatalogScript.t("panel.log")

func render_scene(_scene: Dictionary) -> void:
	pass

func _set_active_tab(tab_name: String) -> void:
	_active_tab = tab_name
	explorer_content.visible = tab_name == "explorer"
	log_content.visible = tab_name == "log"
	_refresh_tab_styles()

func _refresh_tab_styles() -> void:
	_style_tab_button(explorer_tab_button, _active_tab == "explorer")
	_style_tab_button(log_info_tab_button, _active_tab == "log")

func _style_tab_button(button: Button, active: bool) -> void:
	var normal := LTLThemeScript.surface_style(
		Color(0.10, 0.13, 0.17, 0.98),
		Color(0.24, 0.31, 0.39, 1.0),
		12,
		1,
		0.12
	)
	var hover := LTLThemeScript.surface_style(
		Color(0.13, 0.17, 0.23, 0.98),
		Color(0.37, 0.47, 0.58, 1.0),
		12,
		1,
		0.16
	)
	var selected := LTLThemeScript.surface_style(
		Color(0.16, 0.20, 0.27, 0.98),
		Color(0.73, 0.58, 0.30, 1.0),
		12,
		1,
		0.18
	)
	button.add_theme_stylebox_override("normal", selected if active else normal)
	button.add_theme_stylebox_override("hover", hover if not active else selected)
	button.add_theme_stylebox_override("pressed", selected)
	button.add_theme_stylebox_override("focus", selected if active else hover)
	button.add_theme_font_size_override("font_size", 13)
	button.add_theme_color_override("font_color", LTLThemeScript.TEXT_PRIMARY)
	button.add_theme_color_override("font_hover_color", LTLThemeScript.TEXT_PRIMARY)
	button.add_theme_color_override("font_pressed_color", LTLThemeScript.TEXT_PRIMARY)
	button.add_theme_color_override("font_focus_color", LTLThemeScript.TEXT_PRIMARY)
	button.custom_minimum_size = Vector2(0.0, 36.0)

func _apply_shell_theme() -> void:
	add_theme_stylebox_override("panel", LTLThemeScript.surface_style(LTLThemeScript.SURFACE_MID))
	for shell in [explorer_content, log_content]:
		if shell is PanelContainer:
			shell.add_theme_stylebox_override("panel", LTLThemeScript.surface_style(
				Color(0.09, 0.12, 0.16, 0.98),
				Color(0.26, 0.34, 0.44, 1.0),
				16,
				1,
				0.12
			))
