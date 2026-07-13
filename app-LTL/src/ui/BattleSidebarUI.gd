extends PanelContainer

const TextCatalogScript = preload("res://src/ui/TextCatalog.gd")
const LTLThemeScript = preload("res://src/ui/theme/LTLTheme.gd")
const HudReadModelScript = preload("res://src/ui/read_models/HudReadModel.gd")
const BackpackPinOverlayRuntimeScript = preload("res://src/ui/backpack/BackpackPinOverlayRuntime.gd")
const PIN_STOCK_SLOT_COUNT := 4
const PIN_ICON_PATHS := [
	"res://resources/UI/pin/pin_1.png",
	"res://resources/UI/pin/pin_2.png",
	"res://resources/UI/pin/pin_3.png",
	"res://resources/UI/pin/pin_4.png"
]

@onready var explorer_tab_button: Button = $Margin/SidebarBox/TabRow/ExplorerTabButton
@onready var log_info_tab_button: Button = $Margin/SidebarBox/TabRow/LogInfoTabButton
@onready var explorer_content: Control = $Margin/SidebarBox/TabViewport/ExplorerContent
@onready var log_content: Control = $Margin/SidebarBox/TabViewport/LogContent
@onready var character_title: Label = $Margin/SidebarBox/TabViewport/ExplorerContent/Margin/CharacterBox/CharacterTitle
@onready var character_box: VBoxContainer = $Margin/SidebarBox/TabViewport/ExplorerContent/Margin/CharacterBox
@onready var log_title: Label = $Margin/SidebarBox/TabViewport/LogContent/Margin/LogBox/LogTitle

var _active_tab := "explorer"
var pin_progress_title: Label
var pin_progress_bar: ProgressBar
var pin_progress_value: Label
var drill_status_title: Label
var drill_status_value: Label
var field_status_title: Label
var field_status_value: Label
var pin_stock_title: Label
var pin_stock_slots: Array[TextureRect] = []

func _ready() -> void:
	explorer_tab_button.pressed.connect(func() -> void:
		_set_active_tab("explorer")
	)
	log_info_tab_button.pressed.connect(func() -> void:
		_set_active_tab("log")
	)
	_install_pin_section()
	_apply_shell_theme()
	apply_locale()
	_set_active_tab("explorer")

func apply_locale() -> void:
	explorer_tab_button.text = TextCatalogScript.t("panel.tab.explorer")
	log_info_tab_button.text = TextCatalogScript.t("panel.tab.log_info")
	character_title.text = TextCatalogScript.t("panel.character_status")
	log_title.text = TextCatalogScript.t("panel.log")
	if pin_progress_title != null:
		pin_progress_title.text = TextCatalogScript.t("panel.pin_status")
	if drill_status_title != null:
		drill_status_title.text = TextCatalogScript.t("panel.drill_status")
	if field_status_title != null:
		field_status_title.text = TextCatalogScript.t("status.field")
	if pin_stock_title != null:
		pin_stock_title.text = TextCatalogScript.t("panel.pin_stock")

# 실행: 전투 HUD 스냅샷을 탐험가 탭 하단 PIN/드릴/필드 요약으로 투영한다 (mockup 탐험가 탭 하단).
func render_scene(scene: Dictionary) -> void:
	if pin_progress_bar == null:
		return
	if str(scene.get("phase", "")) != "combat":
		return
	var model: Dictionary = HudReadModelScript.project(scene)
	var pin: Dictionary = model.get("pin", {})
	var progress := clampf(float(pin.get("progress", 0.0)), 0.0, 100.0)
	pin_progress_bar.max_value = 100.0
	pin_progress_bar.value = progress
	pin_progress_bar.show_percentage = false
	pin_progress_value.text = "%d%%" % int(round(progress))
	var repair: Dictionary = model.get("repair", {})
	drill_status_value.text = str(repair.get("label", TextCatalogScript.t("hud.repair.stable")))
	drill_status_value.add_theme_color_override("font_color", _stage_color(str(repair.get("stage", "stable"))))
	field_status_value.text = _field_status_text(model)
	var visible_pins := BackpackPinOverlayRuntimeScript.visible_count(bool(pin.get("active", true)), progress)
	for index in range(pin_stock_slots.size()):
		var slot := pin_stock_slots[index]
		if slot != null:
			slot.self_modulate = Color(1, 1, 1, 1.0) if index < visible_pins else Color(1, 1, 1, 0.22)

# 실행: 탐험가 탭 하단에 PIN 진행/드릴 상태/필드 상태/고정석 재고 섹션을 구성한다.
func _install_pin_section() -> void:
	if character_box == null or pin_progress_bar != null:
		return
	character_box.add_child(_section_separator())
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 8)
	character_box.add_child(head)
	pin_progress_title = _section_label(11, LTLThemeScript.INK_PRIMARY)
	pin_progress_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(pin_progress_title)
	pin_progress_value = _section_label(11, Color(0.604, 0.435, 0.113, 1.0))
	head.add_child(pin_progress_value)
	pin_progress_bar = ProgressBar.new()
	pin_progress_bar.custom_minimum_size = Vector2(0, 12)
	pin_progress_bar.show_percentage = false
	pin_progress_bar.add_theme_stylebox_override("fill", LTLThemeScript.value_bar_fill(LTLThemeScript.WARNING_GOLD))
	pin_progress_bar.add_theme_stylebox_override("background", LTLThemeScript.value_bar_background(Color(0.851, 0.824, 0.765, 1.0)))
	character_box.add_child(pin_progress_bar)
	var drill_row := HBoxContainer.new()
	drill_row.add_theme_constant_override("separation", 8)
	character_box.add_child(drill_row)
	drill_status_title = _section_label(11, LTLThemeScript.INK_MUTED)
	drill_status_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	drill_row.add_child(drill_status_title)
	drill_status_value = _section_label(12, LTLThemeScript.SECONDARY)
	drill_row.add_child(drill_status_value)
	var field_row := HBoxContainer.new()
	field_row.add_theme_constant_override("separation", 8)
	character_box.add_child(field_row)
	field_status_title = _section_label(11, LTLThemeScript.INK_MUTED)
	field_status_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	field_row.add_child(field_status_title)
	field_status_value = _section_label(12, Color(0.482, 0.29, 0.62, 1.0))
	field_row.add_child(field_status_value)
	character_box.add_child(_section_separator())
	pin_stock_title = _section_label(10, LTLThemeScript.INK_MUTED)
	character_box.add_child(pin_stock_title)
	var stock_row := HBoxContainer.new()
	stock_row.add_theme_constant_override("separation", 8)
	character_box.add_child(stock_row)
	for index in range(PIN_STOCK_SLOT_COUNT):
		var slot_shell := PanelContainer.new()
		slot_shell.custom_minimum_size = Vector2(46, 46)
		slot_shell.add_theme_stylebox_override("panel", LTLThemeScript.limestone_style(8))
		var icon := TextureRect.new()
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		var icon_path: String = PIN_ICON_PATHS[index % PIN_ICON_PATHS.size()]
		if ResourceLoader.exists(icon_path):
			# 코너 핀과 동일한 실측 트림 창으로 잘라 재고 슬롯 안에 꽉 차게 표시한다.
			var atlas := AtlasTexture.new()
			atlas.atlas = load(icon_path)
			atlas.region = BackpackPinOverlayRuntimeScript.visible_region_for_index(index)
			icon.texture = atlas
		slot_shell.add_child(icon)
		stock_row.add_child(slot_shell)
		pin_stock_slots.append(icon)

func _section_separator() -> Control:
	var line := Panel.new()
	line.custom_minimum_size = Vector2(0, 1)
	var style := StyleBoxFlat.new()
	style.bg_color = LTLThemeScript.OUTLINE_VARIANT
	line.add_theme_stylebox_override("panel", style)
	return line

func _section_label(font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label

func _stage_color(stage: String) -> Color:
	match stage:
		"stable":
			return LTLThemeScript.SECONDARY
		"strained":
			return Color(0.604, 0.435, 0.113, 1.0)
		"critical", "repair_required":
			return LTLThemeScript.ERROR
	return LTLThemeScript.INK_MUTED

func _field_status_text(model: Dictionary) -> String:
	var parts: Array[String] = []
	var hazard: Dictionary = model.get("hazard", {})
	if bool(hazard.get("active", false)):
		parts.append(str(hazard.get("summary", hazard.get("label", ""))))
	var pressure: Dictionary = model.get("purplePressure", {})
	var stack_count := int(pressure.get("stackCount", 0))
	var buff_count := int(pressure.get("buffCount", 0))
	if stack_count > 0:
		parts.append(TextCatalogScript.t("status.purple.weakened", [stack_count]))
	if buff_count > 0:
		parts.append(TextCatalogScript.t("status.purple.buff", [buff_count]))
	if parts.is_empty():
		return TextCatalogScript.t("hud.hazard.stable")
	return " | ".join(parts)

func _set_active_tab(tab_name: String) -> void:
	_active_tab = tab_name
	explorer_content.visible = tab_name == "explorer"
	log_content.visible = tab_name == "log"
	_refresh_tab_styles()

func _refresh_tab_styles() -> void:
	_style_tab_button(explorer_tab_button, _active_tab == "explorer")
	_style_tab_button(log_info_tab_button, _active_tab == "log")

# 전투 리디자인: 야장(野帳) 탭 — 라이트 탭(활성 = 석회암 채움 + 골드 보더) (mockup .tab-btn 준거)
func _style_tab_button(button: Button, active: bool) -> void:
	var normal := LTLThemeScript.surface_style(
		LTLThemeScript.SURFACE_CONTAINER_LOWEST,
		LTLThemeScript.OUTLINE_VARIANT,
		8,
		1,
		0.04
	)
	var hover := LTLThemeScript.surface_style(
		Color(0.976, 0.965, 0.918, 1.0),
		Color(0.545, 0.588, 0.518, 1.0),
		8,
		1,
		0.06
	)
	var selected := LTLThemeScript.surface_style(
		LTLThemeScript.LIMESTONE_FILL,
		LTLThemeScript.WARNING_GOLD,
		8,
		1,
		0.10
	)
	button.add_theme_stylebox_override("normal", selected if active else normal)
	button.add_theme_stylebox_override("hover", hover if not active else selected)
	button.add_theme_stylebox_override("pressed", selected)
	button.add_theme_stylebox_override("focus", selected if active else hover)
	button.add_theme_font_size_override("font_size", 13)
	var font_color := LTLThemeScript.PRIMARY if active else LTLThemeScript.ON_SURFACE_VARIANT
	button.add_theme_color_override("font_color", font_color)
	button.add_theme_color_override("font_hover_color", LTLThemeScript.PRIMARY)
	button.add_theme_color_override("font_pressed_color", LTLThemeScript.PRIMARY)
	button.add_theme_color_override("font_focus_color", font_color)
	button.custom_minimum_size = Vector2(0.0, 36.0)

func _apply_shell_theme() -> void:
	add_theme_stylebox_override("panel", LTLThemeScript.parchment_style())
	for shell in [explorer_content, log_content]:
		if shell is PanelContainer:
			shell.add_theme_stylebox_override("panel", LTLThemeScript.ledger_card_style(LTLThemeScript.OUTLINE_VARIANT, 10))
