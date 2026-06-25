extends Control

const LTLThemeScript = preload("res://src/ui/theme/LTLTheme.gd")
const TextCatalogScript = preload("res://src/ui/TextCatalog.gd")
const InteractionFXScript = preload("res://src/ui/InteractionFX.gd")
const CTA_BUTTON_HEIGHT_RATIO := 0.082
const CTA_BUTTON_HEIGHT_MIN := 68.0
const CTA_BUTTON_HEIGHT_MAX := 74.0
const CTA_BOTTOM_OFFSET_RATIO := 0.021
const CTA_BOTTOM_OFFSET_MIN := 16.0
const CTA_BOTTOM_OFFSET_MAX := 20.0
const CTA_SIDE_OFFSET_RATIO := 0.013
const CTA_SIDE_OFFSET_MIN := 14.0
const CTA_SIDE_OFFSET_MAX := 20.0
const CTA_INNER_VERTICAL_MARGIN_MIN := 8
const CTA_INNER_VERTICAL_MARGIN_MAX := 10

signal start_requested
signal leviathan_selected(leviathan_id: String)

@onready var roster_panel: PanelContainer = $Margin/Layout/RosterPanel
@onready var roster_title: Label = $Margin/Layout/RosterPanel/Margin/RosterBox/RosterTitle
@onready var roster_box: VBoxContainer = $Margin/Layout/RosterPanel/Margin/RosterBox/RosterList
@onready var board_panel: Panel = $Margin/Layout/BoardPanel
@onready var hero_art: TextureRect = $Margin/Layout/BoardPanel/HeroArt
@onready var kicker_label: Label = $Margin/Layout/BoardPanel/Margin/VStack/Kicker
@onready var name_label: Label = $Margin/Layout/BoardPanel/Margin/VStack/LeviathanName
@onready var structure_label: Label = $Margin/Layout/BoardPanel/Margin/VStack/RunStructure
@onready var biome_label: Label = $Margin/Layout/BoardPanel/Margin/VStack/BiomeLabel
@onready var target_ribbon: PanelContainer = $Margin/Layout/BoardPanel/TargetRibbon
@onready var target_kicker: Label = $Margin/Layout/BoardPanel/TargetRibbon/TargetRibbonMargin/TargetRibbonCenter/TargetRibbonStack/TargetKicker
@onready var target_label: Label = $Margin/Layout/BoardPanel/TargetRibbon/TargetRibbonMargin/TargetRibbonCenter/TargetRibbonStack/TargetLabel
@onready var clear_stamp: Label = $Margin/Layout/BoardPanel/TargetRibbon/TargetRibbonMargin/ClearStamp
@onready var start_button_frame: MarginContainer = $Margin/Layout/BoardPanel/StartButtonFrame
@onready var start_button: Button = $Margin/Layout/BoardPanel/StartButtonFrame/StartButton
@onready var start_button_margin: MarginContainer = $Margin/Layout/BoardPanel/StartButtonFrame/StartButton/StartButtonMargin
@onready var start_button_stack: VBoxContainer = $Margin/Layout/BoardPanel/StartButtonFrame/StartButton/StartButtonMargin/StartButtonCenter/StartButtonStack
@onready var start_button_hint: Label = $Margin/Layout/BoardPanel/StartButtonFrame/StartButton/StartButtonMargin/StartButtonCenter/StartButtonStack/AdvanceLabel
@onready var start_button_label: Label = $Margin/Layout/BoardPanel/StartButtonFrame/StartButton/StartButtonMargin/StartButtonCenter/StartButtonStack/StartLabel

var _roster: Array = []
var _selected_id := ""
var _buttons: Dictionary = {}
var _layout_sync_pending := false

func _ready() -> void:
	start_button.set_meta(InteractionFXScript.META_SFX_CATEGORY, "battle_start")
	start_button.pressed.connect(func() -> void: start_requested.emit())
	resized.connect(_queue_layout_sync)
	board_panel.resized.connect(_queue_layout_sync)
	_apply_theme()
	_apply_locale()
	_queue_layout_sync()

func _apply_theme() -> void:
	_apply_shell_theme()
	_apply_header_theme()
	_apply_target_ribbon_theme()
	_apply_start_button_theme()

func _apply_shell_theme() -> void:
	var roster_style := LTLThemeScript.surface_style(Color(0.07, 0.08, 0.10, 0.94), Color(0.19, 0.22, 0.27, 0.96), 0, 1, 0.24)
	roster_style.shadow_size = 20
	roster_style.shadow_color = Color(0.0, 0.0, 0.0, 0.28)
	roster_style.shadow_offset = Vector2(0.0, 10.0)
	roster_panel.add_theme_stylebox_override("panel", roster_style)

	var board_style := LTLThemeScript.surface_style(Color(0.04, 0.05, 0.06, 0.94), Color(0.29, 0.24, 0.15, 0.92), 0, 1, 0.34)
	board_style.shadow_size = 28
	board_style.shadow_color = Color(0.0, 0.0, 0.0, 0.34)
	board_style.shadow_offset = Vector2(0.0, 16.0)
	board_panel.add_theme_stylebox_override("panel", board_style)
	hero_art.self_modulate = Color(1.0, 1.0, 1.0, 0.74)

func _apply_header_theme() -> void:
	roster_title.add_theme_color_override("font_color", Color(0.95, 0.93, 0.89, 1.0))
	kicker_label.add_theme_font_size_override("font_size", 13)
	kicker_label.add_theme_color_override("font_color", Color(0.93, 0.78, 0.45, 0.92))
	name_label.add_theme_font_size_override("font_size", 34)
	name_label.add_theme_color_override("font_color", Color(0.98, 0.98, 0.96, 1.0))
	name_label.add_theme_color_override("font_outline_color", Color(0.03, 0.04, 0.05, 0.72))
	name_label.add_theme_constant_override("outline_size", 1)
	structure_label.add_theme_font_size_override("font_size", 17)
	structure_label.add_theme_color_override("font_color", Color(0.92, 0.90, 0.84, 0.96))
	biome_label.add_theme_font_size_override("font_size", 17)
	biome_label.add_theme_color_override("font_color", Color(0.90, 0.92, 0.95, 0.90))

func _apply_locale() -> void:
	roster_title.text = TextCatalogScript.t("leviathan.roster.title")
	target_kicker.text = TextCatalogScript.t("leviathan.target_kicker")
	start_button_hint.text = TextCatalogScript.t("leviathan.start_hint")
	start_button_label.text = TextCatalogScript.t("leviathan.start_button")

func _apply_target_ribbon_theme() -> void:
	var ribbon := StyleBoxFlat.new()
	ribbon.bg_color = Color(0.01, 0.01, 0.01, 0.46)
	ribbon.border_color = Color(1.0, 1.0, 1.0, 0.08)
	ribbon.border_width_top = 1
	ribbon.border_width_bottom = 1
	target_ribbon.add_theme_stylebox_override("panel", ribbon)

	target_kicker.add_theme_font_size_override("font_size", 10)
	target_kicker.add_theme_color_override("font_color", Color(0.92, 0.95, 0.98, 0.80))
	target_label.add_theme_font_size_override("font_size", 31)
	target_label.add_theme_color_override("font_color", Color(0.98, 0.99, 1.0, 1.0))
	target_label.add_theme_color_override("font_outline_color", Color(0.02, 0.02, 0.03, 0.55))
	target_label.add_theme_constant_override("outline_size", 1)
	clear_stamp.add_theme_color_override("font_color", Color(0.89, 0.37, 0.34, 0.92))
	clear_stamp.rotation_degrees = -6.0

func _apply_start_button_theme() -> void:
	start_button.focus_mode = Control.FOCUS_NONE
	start_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

	var normal := _metal_button_style(Color(0.09, 0.10, 0.12, 0.98), Color(0.94, 0.81, 0.46, 0.78), Color(0.0, 0.0, 0.0, 0.40))
	var hover := _metal_button_style(Color(0.12, 0.14, 0.17, 0.99), Color(0.98, 0.87, 0.56, 0.92), Color(0.0, 0.0, 0.0, 0.46))
	var pressed := _metal_button_style(Color(0.06, 0.07, 0.09, 0.98), Color(0.82, 0.67, 0.34, 0.86), Color(0.0, 0.0, 0.0, 0.32))
	var disabled := _metal_button_style(Color(0.10, 0.11, 0.13, 0.72), Color(0.48, 0.45, 0.40, 0.58), Color(0.0, 0.0, 0.0, 0.18))

	start_button.add_theme_stylebox_override("normal", normal)
	start_button.add_theme_stylebox_override("hover", hover)
	start_button.add_theme_stylebox_override("pressed", pressed)
	start_button.add_theme_stylebox_override("focus", hover)
	start_button.add_theme_stylebox_override("disabled", disabled)

	start_button_hint.add_theme_font_size_override("font_size", 11)
	start_button_hint.add_theme_color_override("font_color", Color(0.97, 0.85, 0.55, 0.98))
	start_button_label.add_theme_font_size_override("font_size", 31)
	start_button_label.add_theme_color_override("font_color", Color(0.99, 0.97, 0.90, 1.0))
	start_button_label.add_theme_color_override("font_outline_color", Color(0.02, 0.02, 0.03, 0.66))
	start_button_label.add_theme_constant_override("outline_size", 1)

func _metal_button_style(bg_color: Color, border_color: Color, shadow_color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_color = border_color
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.shadow_size = 22
	style.shadow_color = shadow_color
	style.shadow_offset = Vector2(0.0, 8.0)
	return style

func apply_state(state: Dictionary) -> void:
	_roster = state.get("leviathanRoster", []).duplicate(true)
	_selected_id = str(state.get("selectedLeviathanId", ""))
	_apply_locale()
	_sync_roster()
	_render_selected(state)
	_queue_layout_sync()

func _sync_roster() -> void:
	for child in roster_box.get_children():
		child.queue_free()
	_buttons.clear()
	for leviathan in _roster:
		var button := Button.new()
		var leviathan_id := str(leviathan.get("id", ""))
		button.text = str(leviathan.get("name", leviathan_id))
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.pressed.connect(func() -> void:
			_selected_id = leviathan_id
			_refresh_roster_highlight()
			leviathan_selected.emit(leviathan_id)
		)
		roster_box.add_child(button)
		_buttons[leviathan_id] = button
	_refresh_roster_highlight()

func _refresh_roster_highlight() -> void:
	for leviathan_id in _buttons.keys():
		var button: Button = _buttons[leviathan_id]
		_apply_roster_button_theme(button, leviathan_id == _selected_id)

func _apply_roster_button_theme(button: Button, selected: bool) -> void:
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.custom_minimum_size = Vector2(0, 38)
	button.add_theme_font_size_override("font_size", 17)

	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.11, 0.12, 0.15, 0.18)
	normal.border_color = Color(0.0, 0.0, 0.0, 0.0)
	if selected:
		normal.bg_color = Color(0.17, 0.19, 0.24, 0.88)
		normal.border_color = Color(0.93, 0.78, 0.42, 0.92)
		normal.border_width_left = 3
		normal.border_width_top = 1
		normal.border_width_right = 1
		normal.border_width_bottom = 1

	var hover := normal.duplicate()
	hover.bg_color = Color(0.18, 0.20, 0.25, 0.92) if selected else Color(0.14, 0.15, 0.18, 0.44)
	if not selected:
		hover.border_color = Color(0.55, 0.50, 0.40, 0.24)
		hover.border_width_left = 1
		hover.border_width_top = 1
		hover.border_width_right = 1
		hover.border_width_bottom = 1

	var pressed := hover.duplicate()
	pressed.bg_color = Color(0.13, 0.14, 0.17, 0.98) if selected else Color(0.12, 0.13, 0.16, 0.54)

	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("focus", hover)
	button.add_theme_color_override("font_color", Color(0.98, 0.97, 0.94, 1.0) if selected else Color(0.82, 0.83, 0.85, 0.96))

func _render_selected(state: Dictionary) -> void:
	var selected := {}
	for leviathan in _roster:
		if str(leviathan.get("id", "")) == _selected_id:
			selected = leviathan
			break
	if selected.is_empty() and not _roster.is_empty():
		selected = _roster[0]
		_selected_id = str(selected.get("id", ""))
		_refresh_roster_highlight()
	name_label.text = str(selected.get("name", TextCatalogScript.t("node_runtime.leviathan_default")))
	structure_label.text = TextCatalogScript.t("leviathan.run_structure", [int(selected.get("runCount", selected.get("runCnt", 1))), int(selected.get("stageCount", selected.get("stageCnt", 1)))])
	biome_label.text = TextCatalogScript.t("leviathan.biome", [str(selected.get("biome", TextCatalogScript.t("leviathan.biome_unknown")))])
	target_kicker.text = TextCatalogScript.t("leviathan.target_kicker")
	target_label.text = TextCatalogScript.t("leviathan.target_core", [str(selected.get("name", TextCatalogScript.t("node_runtime.leviathan_default")))])
	var cleared_ids: Array = state.get("progress", {}).get("clearedLeviathanIds", [])
	clear_stamp.visible = cleared_ids.has(str(selected.get("id", "")))
	var art_path := str(selected.get("artPath", ""))
	hero_art.texture = LTLThemeScript.art_texture(art_path) if not art_path.is_empty() else null

func _queue_layout_sync() -> void:
	if _layout_sync_pending:
		return
	_layout_sync_pending = true
	call_deferred("_sync_responsive_layout")

func _sync_responsive_layout() -> void:
	_layout_sync_pending = false
	if not is_inside_tree():
		return
	var board_height := board_panel.size.y
	var board_width := board_panel.size.x
	if board_height <= 1.0 or board_width <= 1.0:
		return
	# Keep the CTA proportional to the board height while preserving a readable range.
	var button_height := clampf(board_height * CTA_BUTTON_HEIGHT_RATIO, CTA_BUTTON_HEIGHT_MIN, CTA_BUTTON_HEIGHT_MAX)
	var bottom_offset := clampf(board_height * CTA_BOTTOM_OFFSET_RATIO, CTA_BOTTOM_OFFSET_MIN, CTA_BOTTOM_OFFSET_MAX)
	var side_offset := clampf(board_width * CTA_SIDE_OFFSET_RATIO, CTA_SIDE_OFFSET_MIN, CTA_SIDE_OFFSET_MAX)
	var inner_vertical_margin := int(round(clampf(button_height * 0.12, float(CTA_INNER_VERTICAL_MARGIN_MIN), float(CTA_INNER_VERTICAL_MARGIN_MAX))))
	start_button_frame.offset_left = side_offset
	start_button_frame.offset_right = -side_offset
	start_button_frame.offset_bottom = -bottom_offset
	start_button_frame.offset_top = -(bottom_offset + button_height)
	start_button.custom_minimum_size.y = button_height
	start_button_margin.add_theme_constant_override("margin_top", inner_vertical_margin)
	start_button_margin.add_theme_constant_override("margin_bottom", inner_vertical_margin)
	start_button_stack.add_theme_constant_override("separation", 0 if button_height <= 71.0 else 1)
