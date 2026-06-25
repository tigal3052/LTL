extends Control

signal node_selected(index: int)
signal settings_requested
signal shop_requested
signal codex_requested

const LTLThemeScript = preload("res://src/ui/theme/LTLTheme.gd")
const TextCatalogScript = preload("res://src/ui/TextCatalog.gd")
const NodeSelectContentModelScript = preload("res://src/scenes/pages/node_select/NodeSelectContentModel.gd")
const NodeSelectLayoutPolicyScript = preload("res://src/scenes/pages/node_select/NodeSelectLayoutPolicy.gd")
const NodeSelectRoadmapComposerScript = preload("res://src/scenes/pages/node_select/NodeSelectRoadmapComposer.gd")
const NodeSelectRoadmapRendererScript = preload("res://src/scenes/pages/node_select/NodeSelectRoadmapRenderer.gd")
const NodeSelectVisualFactoryScript = preload("res://src/scenes/pages/node_select/NodeSelectVisualFactory.gd")
const InteractionFXScript = preload("res://src/ui/InteractionFX.gd")

const BOARD_BG := Color(0.11, 0.08, 0.06, 0.98)
const BOARD_BORDER := Color(0.48, 0.34, 0.22, 0.82)
const PANEL_BG := Color(0.08, 0.05, 0.04, 0.86)
const PANEL_BORDER := Color(0.76, 0.63, 0.42, 0.22)
const TEXT_PRIMARY := Color(0.95, 0.90, 0.82, 1.0)
const TEXT_MUTED := Color(0.74, 0.67, 0.58, 1.0)
const ROUTE_GOLD := Color(0.90, 0.74, 0.43, 0.96)
const SHOP_ENABLED := false

@onready var page_backdrop: ColorRect = $PageBackdrop
@onready var board_shell: PanelContainer = $Margin/VStack/BoardShell
@onready var board_backdrop: TextureRect = $Margin/VStack/BoardShell/BoardBackdrop
@onready var board_label: Label = $Margin/VStack/BoardShell/ShellMargin/ShellVBox/BoardHead/BoardLead/BoardLabel
@onready var leviathan_title: Label = $Margin/VStack/BoardShell/ShellMargin/ShellVBox/BoardHead/BoardLead/LeviathanTitle
@onready var run_chip_label: Label = $Margin/VStack/BoardShell/ShellMargin/ShellVBox/BoardHead/TitleChips/RunChip/ChipLabel
@onready var stage_chip_label: Label = $Margin/VStack/BoardShell/ShellMargin/ShellVBox/BoardHead/TitleChips/StageChip/ChipLabel
@onready var shop_button: Button = $Margin/VStack/BoardShell/ShellMargin/ShellVBox/BoardHead/TitleChips/ShopButton
@onready var codex_button: Button = $Margin/VStack/BoardShell/ShellMargin/ShellVBox/BoardHead/TitleChips/CodexButton
@onready var settings_button: Button = $Margin/VStack/BoardShell/ShellMargin/ShellVBox/BoardHead/TitleChips/SettingsButton
@onready var reset_button: Button = $Margin/VStack/ActionBar/ResetButton
@onready var start_button: Button = $Margin/VStack/ActionBar/StartButton
@onready var roadmap_frame: PanelContainer = $Margin/VStack/BoardShell/ShellMargin/ShellVBox/BoardBody/RoadmapFrame
@onready var roadmap_canvas: Control = $Margin/VStack/BoardShell/ShellMargin/ShellVBox/BoardBody/RoadmapFrame/FrameMargin/FrameVBox/RoadmapCanvas
@onready var canvas_backdrop: ColorRect = $Margin/VStack/BoardShell/ShellMargin/ShellVBox/BoardBody/RoadmapFrame/FrameMargin/FrameVBox/RoadmapCanvas/CanvasBackdrop
@onready var anatomy_backdrop: Control = $Margin/VStack/BoardShell/ShellMargin/ShellVBox/BoardBody/RoadmapFrame/FrameMargin/FrameVBox/RoadmapCanvas/AnatomyBackdrop
@onready var stage_ruler: Control = $Margin/VStack/BoardShell/ShellMargin/ShellVBox/BoardBody/RoadmapFrame/FrameMargin/FrameVBox/RoadmapCanvas/StageRuler
@onready var info_card: PanelContainer = $Margin/VStack/BoardShell/ShellMargin/ShellVBox/BoardBody/RoadmapFrame/FrameMargin/FrameVBox/RoadmapCanvas/InfoCard
@onready var info_name_label: Label = $Margin/VStack/BoardShell/ShellMargin/ShellVBox/BoardBody/RoadmapFrame/FrameMargin/FrameVBox/RoadmapCanvas/InfoCard/InfoMargin/InfoVBox/InfoNameLabel
@onready var info_name: Label = $Margin/VStack/BoardShell/ShellMargin/ShellVBox/BoardBody/RoadmapFrame/FrameMargin/FrameVBox/RoadmapCanvas/InfoCard/InfoMargin/InfoVBox/InfoName
@onready var info_body_label: Label = $Margin/VStack/BoardShell/ShellMargin/ShellVBox/BoardBody/RoadmapFrame/FrameMargin/FrameVBox/RoadmapCanvas/InfoCard/InfoMargin/InfoVBox/InfoBodyLabel
@onready var info_body: Label = $Margin/VStack/BoardShell/ShellMargin/ShellVBox/BoardBody/RoadmapFrame/FrameMargin/FrameVBox/RoadmapCanvas/InfoCard/InfoMargin/InfoVBox/InfoBody
@onready var route_layer: Control = $Margin/VStack/BoardShell/ShellMargin/ShellVBox/BoardBody/RoadmapFrame/FrameMargin/FrameVBox/RoadmapCanvas/RouteLayer
@onready var node_layer: Control = $Margin/VStack/BoardShell/ShellMargin/ShellVBox/BoardBody/RoadmapFrame/FrameMargin/FrameVBox/RoadmapCanvas/NodeLayer

var _state: Dictionary = {}
var _route_buttons: Array[Button] = []
var _panel_models: Dictionary = {}
var _default_panel_key := ""
var _canvas_layout_pending := false
var _history_hotspots: Array[Control] = []
var _future_hotspots: Array[Control] = []
var _start_hotspots: Array[Control] = []
var _boss_hotspots: Array[Control] = []
var _fixed_entry_hotspots: Array[Control] = []
var _core_texture_cache: Dictionary = {}
var _spot_texture_cache: Dictionary = {}

func _ready() -> void:
	start_button.set_meta(InteractionFXScript.META_SFX_CATEGORY, "battle_start")
	_apply_theme()
	_wire_toolbar_actions()
	_apply_action_copy()
	roadmap_canvas.resized.connect(_queue_canvas_layout)
	apply_state({})

func apply_state(state: Dictionary) -> void:
	_state = state.duplicate(true)
	_render_copy()
	_queue_canvas_layout()

func route_button_count() -> int:
	return _route_buttons.size()

func press_route_button(index: int) -> void:
	if index < 0 or index >= _route_buttons.size():
		return
	_route_buttons[index].pressed.emit()

func press_start_marker() -> void:
	if _start_hotspots.is_empty():
		return
	_start_hotspots[0].pressed.emit()

func press_boss_marker() -> void:
	if _boss_hotspots.is_empty():
		return
	_boss_hotspots[0].pressed.emit()

func start_color_chip_count() -> int:
	return 0

func history_marker_count() -> int:
	return _history_hotspots.size()

func future_marker_count() -> int:
	return _future_hotspots.size()

func start_marker_count() -> int:
	return _start_hotspots.size()

func boss_marker_count() -> int:
	return _boss_hotspots.size()

func fixed_entry_marker_count() -> int:
	return _fixed_entry_hotspots.size()

func current_unknown_route_count() -> int:
	var total := 0
	for button in _route_buttons:
		if str(button.get_meta("icon_kind", "")) == "future":
			total += 1
	return total

func _render_copy() -> void:
	var stage_number := _stage_number()
	var max_stages := _max_stages()
	var leviathan := _selected_leviathan()
	var run_count := maxi(1, int(leviathan.get("runCount", _state.get("runCount", 1))))
	var run_index := mini(run_count, maxi(1, int(_state.get("runIndex", 0)) + 1))
	var art_path := str(_state.get("pageHeroPath", leviathan.get("artPath", "")))

	board_label.text = ""
	board_label.visible = false
	leviathan_title.text = _leviathan_name(leviathan)
	leviathan_title.visible = true
	run_chip_label.text = TextCatalogScript.t("node_runtime.run_chip", [run_index, run_count])
	stage_chip_label.text = TextCatalogScript.t("node_runtime.stage_chip", [stage_number, max_stages])
	info_name_label.text = TextCatalogScript.t("node_runtime.info_name_label")
	info_body_label.text = TextCatalogScript.t("node_runtime.info_body_label")
	board_backdrop.texture = LTLThemeScript.art_texture(art_path) if not art_path.is_empty() else null

func _apply_theme() -> void:
	page_backdrop.color = Color(0.04, 0.06, 0.09, 1.0)

	board_shell.add_theme_stylebox_override("panel", _panel_style(BOARD_BG, BOARD_BORDER, 30, 1, Color(0.0, 0.0, 0.0, 0.34), 34))
	roadmap_frame.add_theme_stylebox_override("panel", _panel_style(Color(0.16, 0.11, 0.08, 0.92), Color(0.71, 0.56, 0.37, 0.14), 28, 1, Color(0.0, 0.0, 0.0, 0.18), 12))
	info_card.add_theme_stylebox_override("panel", _panel_style(PANEL_BG, PANEL_BORDER, 22, 1, Color(0.0, 0.0, 0.0, 0.24), 20))
	board_backdrop.self_modulate = Color(1.0, 0.94, 0.88, 0.11)
	canvas_backdrop.color = Color(0.15, 0.10, 0.08, 0.95)

	board_label.add_theme_font_size_override("font_size", 11)
	board_label.add_theme_color_override("font_color", Color(0.92, 0.82, 0.62, 0.82))
	leviathan_title.add_theme_font_size_override("font_size", 48)
	leviathan_title.add_theme_color_override("font_color", TEXT_PRIMARY)

	info_name_label.add_theme_font_size_override("font_size", 11)
	info_name_label.add_theme_color_override("font_color", ROUTE_GOLD)
	info_name.add_theme_font_size_override("font_size", 27)
	info_name.add_theme_color_override("font_color", TEXT_PRIMARY)
	info_body_label.add_theme_font_size_override("font_size", 11)
	info_body_label.add_theme_color_override("font_color", ROUTE_GOLD)
	info_body.add_theme_font_size_override("font_size", 13)
	info_body.add_theme_color_override("font_color", TEXT_MUTED)

	for chip in [
		$Margin/VStack/BoardShell/ShellMargin/ShellVBox/BoardHead/TitleChips/RunChip,
		$Margin/VStack/BoardShell/ShellMargin/ShellVBox/BoardHead/TitleChips/StageChip
	]:
		var chip_style := _panel_style(Color(0.25, 0.17, 0.11, 0.82), Color(0.77, 0.60, 0.32, 0.34), 16, 1)
		chip_style.content_margin_left = 18
		chip_style.content_margin_right = 18
		chip_style.content_margin_top = 8
		chip_style.content_margin_bottom = 8
		chip.add_theme_stylebox_override("panel", chip_style)
		var chip_label := chip.get_node("ChipLabel") as Label
		chip_label.add_theme_font_size_override("font_size", 11)
		chip_label.add_theme_color_override("font_color", Color(0.97, 0.83, 0.60, 1.0))

	for utility_button in [shop_button, codex_button, settings_button]:
		utility_button.focus_mode = Control.FOCUS_CLICK
		utility_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		utility_button.custom_minimum_size = Vector2(112.0, 42.0)
		utility_button.add_theme_stylebox_override("normal", _panel_style(Color(0.22, 0.15, 0.10, 0.84), Color(0.75, 0.58, 0.31, 0.30), 16, 1, Color(0.0, 0.0, 0.0, 0.18), 10))
		utility_button.add_theme_stylebox_override("hover", _panel_style(Color(0.29, 0.20, 0.13, 0.92), Color(0.88, 0.71, 0.41, 0.48), 16, 1, Color(0.0, 0.0, 0.0, 0.22), 12))
		utility_button.add_theme_stylebox_override("pressed", _panel_style(Color(0.18, 0.12, 0.08, 0.94), Color(0.63, 0.48, 0.25, 0.40), 16, 1, Color(0.0, 0.0, 0.0, 0.14), 8))
		utility_button.add_theme_stylebox_override("focus", _panel_style(Color(0.29, 0.20, 0.13, 0.92), Color(0.88, 0.71, 0.41, 0.48), 16, 1, Color(0.0, 0.0, 0.0, 0.22), 12))
		utility_button.add_theme_font_size_override("font_size", 14)
		utility_button.add_theme_color_override("font_color", TEXT_PRIMARY)
	shop_button.disabled = not SHOP_ENABLED
	shop_button.mouse_default_cursor_shape = Control.CURSOR_FORBIDDEN if shop_button.disabled else Control.CURSOR_POINTING_HAND

func _queue_canvas_layout() -> void:
	if _canvas_layout_pending:
		return
	_canvas_layout_pending = true
	call_deferred("_rebuild_canvas")

func _wire_toolbar_actions() -> void:
	shop_button.pressed.connect(func() -> void:
		if not SHOP_ENABLED:
			return
		shop_requested.emit()
	)
	codex_button.pressed.connect(func() -> void:
		codex_requested.emit()
	)
	settings_button.pressed.connect(func() -> void:
		settings_requested.emit()
	)

func _apply_action_copy() -> void:
	shop_button.text = TextCatalogScript.t("action.shop")
	codex_button.text = TextCatalogScript.t("action.codex")
	settings_button.text = TextCatalogScript.t("action.settings")
	reset_button.text = TextCatalogScript.t("action.reset")
	start_button.text = TextCatalogScript.t("action.start")

func _rebuild_canvas() -> void:
	NodeSelectRoadmapComposerScript.rebuild_canvas(self)

func _layout_info_card() -> void:
	var card_width := clampf(roadmap_canvas.size.x * 0.235, 236.0, 272.0)
	var card_height := clampf(roadmap_canvas.size.y * 0.34, 198.0, 236.0)
	info_card.position = Vector2(64.0, 18.0)
	info_card.size = Vector2(card_width, card_height)
	info_name_label.text = TextCatalogScript.t("node_runtime.info_name_label")
	info_body_label.text = TextCatalogScript.t("node_runtime.info_body_label")

func _build_canvas_backdrop() -> void:
	NodeSelectRoadmapRendererScript.build_canvas_backdrop(canvas_backdrop, roadmap_canvas.size, _spot_texture_cache)

func _build_history_chain(start_pos: Vector2, route_history: Array) -> Vector2:
	return NodeSelectRoadmapComposerScript.build_history_chain(self, start_pos, route_history)

func _build_future_chain(from_point: Vector2) -> void:
	NodeSelectRoadmapComposerScript.build_future_chain(self, from_point)

func _current_route_positions(stage_index: int, candidate_count: int) -> Array[Vector2]:
	return NodeSelectLayoutPolicyScript.current_route_positions(stage_index, candidate_count, _max_stages(), roadmap_canvas.size)

func _spine_stage_position(stage_order: int) -> Vector2:
	return NodeSelectLayoutPolicyScript.spine_stage_position(stage_order, _max_stages(), roadmap_canvas.size)

func _future_slot_positions() -> Array[Vector2]:
	return NodeSelectLayoutPolicyScript.future_slot_positions(_stage_index(), _max_stages(), roadmap_canvas.size)

func _history_position_for_entry(entry: Dictionary) -> Vector2:
	return NodeSelectLayoutPolicyScript.history_position_for_entry(entry, _max_stages(), roadmap_canvas.size)

func _history_entry_name(entry: Dictionary) -> String:
	return NodeSelectContentModelScript.history_entry_name(entry)

func _history_entry_body(entry: Dictionary) -> String:
	return NodeSelectContentModelScript.history_entry_body(entry)

func _history_entry_icon_kind(entry: Dictionary) -> String:
	return NodeSelectContentModelScript.history_entry_icon_kind(entry)

func _build_stage_ruler() -> void:
	var markers := [
		{"text": TextCatalogScript.t("node_runtime.stage_marker.hull"), "ratio": 0.94},
		{"text": TextCatalogScript.t("node_runtime.stage_marker.spine"), "ratio": 0.72},
		{"text": TextCatalogScript.t("node_runtime.stage_marker.pockets"), "ratio": 0.45},
		{"text": TextCatalogScript.t("node_runtime.stage_marker.eye"), "ratio": 0.14}
	]
	NodeSelectRoadmapRendererScript.build_stage_ruler(stage_ruler, roadmap_canvas.size, markers)

func _build_anatomy_backdrop() -> void:
	NodeSelectRoadmapRendererScript.build_anatomy_backdrop(anatomy_backdrop, roadmap_canvas.size)

func _create_route_button(index: int, candidate: Dictionary, center: Vector2, selected: bool, panel_key: String) -> Button:
	return NodeSelectRoadmapComposerScript.create_route_button(self, index, candidate, center, selected, panel_key)

func _toggle_node_selection(index: int, selected_panel_key: String) -> void:
	var next_index := -1 if int(_state.get("selectedNodeIndex", -1)) == index else index
	_state["selectedNodeIndex"] = next_index
	_default_panel_key = selected_panel_key if next_index >= 0 else _unselected_default_panel_key()
	_show_panel(_default_panel_key)
	_queue_canvas_layout()
	call_deferred("_emit_node_selected", next_index)

func _unselected_default_panel_key() -> String:
	if _is_boss_stage():
		return "boss"
	if _is_fixed_stage():
		return "start"
	return "start"

func _route_button_style(candidate: Dictionary, selected: bool, hovered: bool) -> StyleBoxFlat:
	return NodeSelectVisualFactoryScript.route_button_style(candidate, selected, hovered)

func _transparent_button_style() -> StyleBoxFlat:
	return NodeSelectVisualFactoryScript.transparent_button_style()

func _add_hover_hotspot(node_name: String, center: Vector2, size: float, palette: Dictionary, glyph: String, panel_key: String, selected := false, preview := false, tag_text := "", sub_text := "") -> Button:
	return NodeSelectRoadmapComposerScript.add_hover_hotspot(self, node_name, center, size, palette, glyph, panel_key, selected, preview, tag_text, sub_text)

func _attach_hotspot_visual(host: Control, palette: Dictionary, icon_kind: String, selected: bool, preview: bool, hovered: bool) -> void:
	NodeSelectVisualFactoryScript.attach_hotspot_visual(host, palette, icon_kind, selected, preview, hovered, _core_texture_cache)

func _refresh_hotspot_visual(host: Control, hovered: bool) -> void:
	NodeSelectVisualFactoryScript.refresh_hotspot_visual(host, hovered, _core_texture_cache)

func _attach_hotspot_icon(host: Control, icon_kind: String, color: Color) -> void:
	NodeSelectVisualFactoryScript.attach_hotspot_icon(host, icon_kind, color)

func _attach_hotspot_tag(host: Control, tag_text: String, sub_text := "", preview := false) -> void:
	NodeSelectVisualFactoryScript.attach_hotspot_tag(host, tag_text, sub_text, preview, roadmap_canvas.size)

func _bind_hover_panel(control: Control, panel_key: String) -> void:
	control.mouse_entered.connect(func() -> void:
		_show_panel(panel_key)
	)
	control.mouse_exited.connect(func() -> void:
		_show_panel(_default_panel_key)
	)
	control.focus_entered.connect(func() -> void:
		_show_panel(panel_key)
	)
	control.focus_exited.connect(func() -> void:
		_show_panel(_default_panel_key)
	)

func _add_dotted_route(name: String, from_point: Vector2, to_point: Vector2, color: Color, dot_size: float, bend: float, alpha_scale := 1.0) -> void:
	NodeSelectRoadmapRendererScript.add_dotted_route(route_layer, name, from_point, to_point, color, dot_size, bend, alpha_scale)

func _add_forecast_route(name: String, from_point: Vector2, to_point: Vector2, color: Color, width: float, bend: float) -> void:
	NodeSelectRoadmapRendererScript.add_forecast_route(route_layer, name, from_point, to_point, color, width, bend)

func _add_ghost_route(name: String, from_point: Vector2, to_point: Vector2, color: Color, width: float, bend: float) -> void:
	NodeSelectRoadmapRendererScript.add_ghost_route(route_layer, name, from_point, to_point, color, width, bend)

func _route_choice_center(index: int) -> Vector2:
	var centers := _current_route_positions(_stage_index(), maxi(index + 1, 1))
	return centers[clampi(index, 0, centers.size() - 1)] if not centers.is_empty() else _spine_stage_position(maxi(1, _stage_index()))

func _clamp_canvas_point(point: Vector2, radius: float, reserve_bottom: float) -> Vector2:
	return NodeSelectLayoutPolicyScript.clamp_canvas_point(point, radius, reserve_bottom, roadmap_canvas.size)

func _register_panel_model(key: String, name_text: String, body_text: String) -> void:
	_panel_models[key] = {
		"name": name_text,
		"body": body_text
	}

func _show_panel(panel_key: String) -> void:
	var resolved_key := panel_key
	if resolved_key.is_empty() or not _panel_models.has(resolved_key):
		resolved_key = _default_panel_key
	if resolved_key.is_empty() or not _panel_models.has(resolved_key):
		info_name.text = ""
		info_body.text = ""
		return
	var model: Dictionary = _panel_models[resolved_key]
	info_name.text = str(model.get("name", ""))
	info_body.text = str(model.get("body", ""))

func _candidate_palette(candidate: Dictionary) -> Dictionary:
	return NodeSelectContentModelScript.candidate_palette(candidate)

func _candidate_icon_kind(candidate: Dictionary) -> String:
	return NodeSelectContentModelScript.candidate_icon_kind(candidate)

func _candidate_description(candidate: Dictionary) -> String:
	return NodeSelectContentModelScript.candidate_description(candidate)

func _candidate_tooltip(candidate: Dictionary) -> String:
	return NodeSelectContentModelScript.candidate_tooltip(candidate)

func _selected_candidate_index(candidate_count: int) -> int:
	return NodeSelectContentModelScript.selected_candidate_index(_state, candidate_count)

func _candidates() -> Array:
	return NodeSelectContentModelScript.candidates(_state)

func _node_select_state() -> Dictionary:
	return NodeSelectContentModelScript.node_select_state(_state)

func _route_history() -> Array:
	return NodeSelectContentModelScript.route_history(_state, _stage_index())

func _stage_index() -> int:
	return NodeSelectContentModelScript.stage_index(_state)

func _stage_number() -> int:
	return NodeSelectContentModelScript.stage_number(_state)

func _max_stages() -> int:
	return NodeSelectContentModelScript.max_stages(_state)

func _is_fixed_stage() -> bool:
	return NodeSelectContentModelScript.is_fixed_stage(_state)

func _is_boss_stage() -> bool:
	return NodeSelectContentModelScript.is_boss_stage(_state)

func _selected_leviathan() -> Dictionary:
	return NodeSelectContentModelScript.selected_leviathan(_state)

func _leviathan_name(leviathan: Dictionary) -> String:
	return NodeSelectContentModelScript.leviathan_name(leviathan)

func _weakness_text(candidate: Dictionary) -> String:
	return NodeSelectContentModelScript.weakness_text(candidate)

func _emit_node_selected(index: int) -> void:
	node_selected.emit(index)

func _panel_style(bg: Color, border: Color, radius: int, border_width: int, shadow := Color(0, 0, 0, 0), shadow_size := 0) -> StyleBoxFlat:
	return NodeSelectVisualFactoryScript.panel_style(bg, border, radius, border_width, shadow, shadow_size)

func _tone_palette(tone: String) -> Dictionary:
	return NodeSelectVisualFactoryScript.tone_palette(tone)

func _muted_palette(source: Dictionary) -> Dictionary:
	return NodeSelectVisualFactoryScript.muted_palette(source)

func _clear_container(container: Node) -> void:
	for child in container.get_children():
		container.remove_child(child)
		child.queue_free()
