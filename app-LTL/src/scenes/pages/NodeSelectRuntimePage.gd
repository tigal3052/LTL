extends Control

signal node_selected(index: int)

const LTLThemeScript = preload("res://src/ui/theme/LTLTheme.gd")
const TextCatalogScript = preload("res://src/ui/TextCatalog.gd")

class GlyphIcon:
	extends Control

	var icon_kind := "normal"
	var stroke_color := Color(0.96, 0.90, 0.82, 1.0)
	var stroke_width := 2.0

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var center := size * 0.5
		var width := minf(size.x, size.y)
		var radius := width * 0.33
		match icon_kind:
			"start":
				_draw_start(center, radius)
			"repair":
				_draw_repair(center, radius)
			"unknown":
				_draw_unknown(center, radius)
			"danger":
				_draw_danger(center, radius)
			"harpoon":
				_draw_harpoon(center, radius)
			"reef":
				_draw_reef(center, radius)
			"boss":
				_draw_boss(center, radius)
			_:
				_draw_normal(center, radius)

	func _draw_start(center: Vector2, radius: float) -> void:
		draw_line(center + Vector2(-radius * 0.55, -radius * 0.36), center + Vector2(-radius * 0.55, radius * 0.70), stroke_color, stroke_width, true)
		draw_line(center + Vector2(radius * 0.55, -radius * 0.36), center + Vector2(radius * 0.55, radius * 0.70), stroke_color, stroke_width, true)
		draw_line(center + Vector2(-radius * 0.88, radius * 0.70), center + Vector2(radius * 0.88, radius * 0.70), stroke_color, stroke_width, true)
		draw_line(center + Vector2(-radius * 0.82, -radius * 0.12), center + Vector2(radius * 0.82, -radius * 0.12), stroke_color, stroke_width, true)
		draw_line(center + Vector2(0.0, -radius * 0.12), center + Vector2(0.0, radius * 0.40), stroke_color, stroke_width, true)
		draw_line(center + Vector2(-radius * 0.20, radius * 0.10), center + Vector2(0.0, -radius * 0.12), stroke_color, stroke_width, true)
		draw_line(center + Vector2(radius * 0.20, radius * 0.10), center + Vector2(0.0, -radius * 0.12), stroke_color, stroke_width, true)

	func _draw_normal(center: Vector2, radius: float) -> void:
		var diamond := PackedVector2Array([
			center + Vector2(0.0, -radius),
			center + Vector2(radius * 0.90, 0.0),
			center + Vector2(0.0, radius),
			center + Vector2(-radius * 0.90, 0.0),
			center + Vector2(0.0, -radius)
		])
		draw_polyline(diamond, stroke_color, stroke_width, true)
		draw_circle(center, radius * 0.18, stroke_color)

	func _draw_repair(center: Vector2, radius: float) -> void:
		draw_arc(center + Vector2(0.0, -radius * 0.54), radius * 0.26, 0.0, TAU, 16, stroke_color, stroke_width, true)
		draw_line(center + Vector2(0.0, -radius * 0.26), center + Vector2(0.0, radius * 0.80), stroke_color, stroke_width, true)
		var left_arc := _ellipse_points(center + Vector2(0.0, radius * 0.12), Vector2(radius * 0.74, radius * 0.64), PI * 0.08, PI * 0.92, 18)
		draw_polyline(left_arc, stroke_color, stroke_width, true)
		draw_line(center + Vector2(-radius * 0.54, radius * 0.54), center + Vector2(-radius * 0.78, radius * 0.84), stroke_color, stroke_width, true)
		draw_line(center + Vector2(radius * 0.54, radius * 0.54), center + Vector2(radius * 0.78, radius * 0.84), stroke_color, stroke_width, true)

	func _draw_unknown(center: Vector2, radius: float) -> void:
		var outer := _ellipse_points(center + Vector2(-radius * 0.06, -radius * 0.04), Vector2(radius * 0.86, radius * 0.74), PI * 0.20, PI * 1.84, 22)
		draw_polyline(outer, stroke_color, stroke_width, true)
		var inner := _ellipse_points(center + Vector2(0.0, radius * 0.06), Vector2(radius * 0.42, radius * 0.34), PI * 0.24, PI * 1.72, 16)
		draw_polyline(inner, stroke_color, stroke_width, true)
		draw_circle(center + Vector2(0.0, radius * 0.48), radius * 0.08, stroke_color)

	func _draw_danger(center: Vector2, radius: float) -> void:
		var skull := PackedVector2Array([
			center + Vector2(-radius * 0.66, -radius * 0.14),
			center + Vector2(-radius * 0.46, -radius * 0.74),
			center + Vector2(0.0, -radius * 0.94),
			center + Vector2(radius * 0.46, -radius * 0.74),
			center + Vector2(radius * 0.66, -radius * 0.14),
			center + Vector2(radius * 0.52, radius * 0.44),
			center + Vector2(radius * 0.24, radius * 0.78),
			center + Vector2(-radius * 0.24, radius * 0.78),
			center + Vector2(-radius * 0.52, radius * 0.44),
			center + Vector2(-radius * 0.66, -radius * 0.14)
		])
		draw_polyline(skull, stroke_color, stroke_width, true)
		draw_circle(center + Vector2(-radius * 0.28, -radius * 0.10), radius * 0.12, stroke_color)
		draw_circle(center + Vector2(radius * 0.28, -radius * 0.10), radius * 0.12, stroke_color)
		draw_line(center + Vector2(-radius * 0.28, radius * 0.44), center + Vector2(radius * 0.28, radius * 0.44), stroke_color, stroke_width, true)

	func _draw_harpoon(center: Vector2, radius: float) -> void:
		draw_line(center + Vector2(-radius * 0.82, radius * 0.80), center + Vector2(radius * 0.74, -radius * 0.78), stroke_color, stroke_width, true)
		draw_line(center + Vector2(radius * 0.22, -radius * 0.78), center + Vector2(radius * 0.74, -radius * 0.78), stroke_color, stroke_width, true)
		draw_line(center + Vector2(radius * 0.74, -radius * 0.78), center + Vector2(radius * 0.74, -radius * 0.24), stroke_color, stroke_width, true)
		draw_line(center + Vector2(-radius * 0.34, radius * 0.34), center + Vector2(-radius * 0.08, radius * 0.88), stroke_color, stroke_width, true)
		draw_line(center + Vector2(-radius * 0.58, radius * 0.58), center + Vector2(-radius * 0.06, radius * 0.84), stroke_color, stroke_width, true)

	func _draw_reef(center: Vector2, radius: float) -> void:
		draw_line(center + Vector2(-radius * 0.42, radius * 0.86), center + Vector2(-radius * 0.24, -radius * 0.34), stroke_color, stroke_width, true)
		draw_line(center + Vector2(0.0, radius * 0.88), center + Vector2(0.0, -radius * 0.76), stroke_color, stroke_width, true)
		draw_line(center + Vector2(radius * 0.42, radius * 0.84), center + Vector2(radius * 0.58, -radius * 0.52), stroke_color, stroke_width, true)
		draw_line(center + Vector2(-radius * 0.24, -radius * 0.34), center + Vector2(-radius * 0.48, -radius * 0.76), stroke_color, stroke_width, true)
		draw_line(center + Vector2(0.0, -radius * 0.44), center + Vector2(radius * 0.22, -radius * 0.92), stroke_color, stroke_width, true)

	func _draw_boss(center: Vector2, radius: float) -> void:
		var top_arc := _ellipse_points(center, Vector2(radius, radius * 0.60), PI, TAU, 22)
		var bottom_arc := _ellipse_points(center, Vector2(radius, radius * 0.60), 0.0, PI, 22)
		draw_polyline(top_arc, stroke_color, stroke_width, true)
		draw_polyline(bottom_arc, stroke_color, stroke_width, true)
		draw_circle(center, radius * 0.24, stroke_color)
		draw_line(center + Vector2(0.0, -radius * 0.64), center + Vector2(0.0, radius * 0.64), stroke_color, stroke_width * 0.8, true)

	func _ellipse_points(center: Vector2, radii: Vector2, start_angle: float, end_angle: float, segments: int) -> PackedVector2Array:
		var points := PackedVector2Array()
		for step in range(segments + 1):
			var t := float(step) / float(maxi(1, segments))
			var angle := lerpf(start_angle, end_angle, t)
			points.append(center + Vector2(cos(angle) * radii.x, sin(angle) * radii.y))
		return points

class FutureMarkerArt:
	extends Control

	var ring_color := Color(0.88, 0.73, 0.45, 0.72)
	var fill_color := Color(0.18, 0.12, 0.09, 0.82)
	var shadow_color := Color(0.0, 0.0, 0.0, 0.24)

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var center := size * 0.5
		var radius := minf(size.x, size.y) * 0.38
		_draw_shadow(center, radius)
		draw_circle(center, radius, fill_color)
		var dash_count := 18
		for dash_index in range(dash_count):
			if dash_index % 2 != 0:
				continue
			var start_angle := (TAU * float(dash_index) / float(dash_count)) - 0.10
			var end_angle := (TAU * float(dash_index + 1) / float(dash_count)) - 0.22
			draw_arc(center, radius - 1.4, start_angle, end_angle, 7, ring_color, 2.2, true)

	func _draw_shadow(center: Vector2, radius: float) -> void:
		for step in range(5):
			var blur := radius + (2.0 * float(step))
			var alpha := shadow_color.a * (1.0 - (float(step) / 5.0))
			draw_circle(center + Vector2(0.0, radius * 0.18), blur, Color(shadow_color.r, shadow_color.g, shadow_color.b, alpha * 0.12))

const REFERENCE_CANVAS_SIZE := Vector2(920.0, 760.0)
const BOARD_BG := Color(0.11, 0.08, 0.06, 0.98)
const BOARD_BORDER := Color(0.48, 0.34, 0.22, 0.82)
const PANEL_BG := Color(0.08, 0.05, 0.04, 0.86)
const PANEL_BORDER := Color(0.76, 0.63, 0.42, 0.22)
const TEXT_PRIMARY := Color(0.95, 0.90, 0.82, 1.0)
const TEXT_MUTED := Color(0.74, 0.67, 0.58, 1.0)
const TEXT_SOFT := Color(0.80, 0.74, 0.66, 0.72)
const ROUTE_RED := Color(0.82, 0.47, 0.40, 0.88)
const ROUTE_GOLD := Color(0.90, 0.74, 0.43, 0.96)
const ROUTE_FORECAST := Color(0.85, 0.73, 0.55, 0.24)
const ROUTE_MUTED := Color(0.62, 0.54, 0.44, 0.18)
const ROUTE_GHOST := Color(0.54, 0.43, 0.33, 0.18)
const HOTSPOT_SAFE_MARGIN := 22.0
const HOTSPOT_TAG_DEPTH := 58.0

const START_REF := Vector2(178.0, 620.0)
const SPINE_CONTROL_REF := Vector2(462.0, 344.0)
const BOSS_REF := Vector2(748.0, 146.0)
const CURRENT_ROUTE_OFFSETS := [
	Vector2(-198.0, 118.0),
	Vector2(-78.0, -8.0),
	Vector2(74.0, -72.0),
	Vector2(206.0, 18.0),
	Vector2(330.0, 116.0)
]

@onready var page_backdrop: ColorRect = $PageBackdrop
@onready var hero_eyebrow: Label = $Margin/VStack/HeroSection/Eyebrow
@onready var hero_title: Label = $Margin/VStack/HeroSection/HeroTitle
@onready var board_shell: PanelContainer = $Margin/VStack/BoardShell
@onready var board_backdrop: TextureRect = $Margin/VStack/BoardShell/BoardBackdrop
@onready var board_label: Label = $Margin/VStack/BoardShell/ShellMargin/ShellVBox/BoardHead/BoardLead/BoardLabel
@onready var leviathan_title: Label = $Margin/VStack/BoardShell/ShellMargin/ShellVBox/BoardHead/BoardLead/LeviathanTitle
@onready var run_chip_label: Label = $Margin/VStack/BoardShell/ShellMargin/ShellVBox/BoardHead/TitleChips/RunChip/ChipLabel
@onready var stage_chip_label: Label = $Margin/VStack/BoardShell/ShellMargin/ShellVBox/BoardHead/TitleChips/StageChip/ChipLabel
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
	_apply_theme()
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

	hero_eyebrow.text = _hero_eyebrow_text(stage_number)
	hero_title.text = ""
	hero_title.visible = false
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

	hero_eyebrow.add_theme_font_size_override("font_size", 11)
	hero_eyebrow.add_theme_color_override("font_color", ROUTE_GOLD)
	hero_title.add_theme_font_size_override("font_size", 42)
	hero_title.add_theme_color_override("font_color", TEXT_PRIMARY)

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
		chip.add_theme_stylebox_override("panel", _panel_style(Color(0.25, 0.17, 0.11, 0.82), Color(0.77, 0.60, 0.32, 0.34), 16, 1))
		var chip_label := chip.get_node("ChipLabel") as Label
		chip_label.add_theme_font_size_override("font_size", 11)
		chip_label.add_theme_color_override("font_color", Color(0.97, 0.83, 0.60, 1.0))

func _queue_canvas_layout() -> void:
	if _canvas_layout_pending:
		return
	_canvas_layout_pending = true
	call_deferred("_rebuild_canvas")

func _rebuild_canvas() -> void:
	_canvas_layout_pending = false
	if not is_inside_tree():
		return
	if roadmap_canvas.size.x <= 1.0 or roadmap_canvas.size.y <= 1.0:
		return

	_clear_container(canvas_backdrop)
	_clear_container(stage_ruler)
	_clear_container(anatomy_backdrop)
	_clear_container(route_layer)
	_clear_container(node_layer)
	_route_buttons.clear()
	_panel_models.clear()
	_history_hotspots.clear()
	_future_hotspots.clear()
	_start_hotspots.clear()
	_boss_hotspots.clear()
	_fixed_entry_hotspots.clear()

	_layout_info_card()
	_build_canvas_backdrop()
	_build_stage_ruler()
	_build_anatomy_backdrop()

	var stage_index := _stage_index()
	var candidates := _candidates()
	var route_history := _route_history()
	var selected_index := _selected_candidate_index(candidates.size())

	var start_pos := _clamp_canvas_point(_ref_to_canvas(START_REF), 36.0, HOTSPOT_TAG_DEPTH)
	var boss_pos := _clamp_canvas_point(_ref_to_canvas(BOSS_REF), 41.0, 24.0)
	var fixed_stage := _is_fixed_stage()
	var boss_stage := _is_boss_stage()

	_register_panel_model("start", TextCatalogScript.t("node_runtime.start_mark.name"), TextCatalogScript.t("node_runtime.start_mark.body"))
	_register_panel_model("fixed", TextCatalogScript.t("node_runtime.fixed_entry.name"), TextCatalogScript.t("node_runtime.fixed_entry.body"))
	_register_panel_model("future", TextCatalogScript.t("node_runtime.future.name"), TextCatalogScript.t("node_runtime.future.body"))
	_register_panel_model("boss", TextCatalogScript.t("node_runtime.boss.name"), TextCatalogScript.t("node_runtime.boss.body"))

	if fixed_stage or route_history.is_empty():
		var start_hotspot := _add_hover_hotspot(
			"StartHotspot",
			start_pos,
			72.0,
			_tone_palette("start"),
			"start",
			"start",
			fixed_stage,
			false,
			TextCatalogScript.t("node_runtime.start_mark.name")
		)
		_start_hotspots.append(start_hotspot)
	if fixed_stage:
		_build_future_chain(start_pos)
		_default_panel_key = "start"
	elif boss_stage:
		var history_anchor := _build_history_chain(start_pos, route_history)
		_add_dotted_route("HistoryToBoss", history_anchor, boss_pos, ROUTE_RED, 5.2, 0.10, 0.78)
		_add_forecast_route("HistoryToBossSelected", history_anchor, boss_pos, ROUTE_GOLD, 3.4, 0.08)
		_default_panel_key = "boss"
	else:
		var history_anchor := _build_history_chain(start_pos, route_history)
		var route_centers := _current_route_positions(stage_index, candidates.size())
		for index in range(candidates.size()):
			var candidate: Dictionary = candidates[index]
			var center: Vector2 = route_centers[index]
			var panel_key := "route_%d" % index
			_register_panel_model(panel_key, TextCatalogScript.display_name(str(candidate.get("label", candidate.get("id", "?")))), _candidate_description(candidate))
			_add_dotted_route("PastRoute%d" % index, history_anchor, center, ROUTE_RED, 4.8, -0.12 + (0.08 * float(index)), 0.86)
			if index == selected_index:
				_add_forecast_route("SelectedRoute%d" % index, history_anchor, center, ROUTE_GOLD, 3.2, -0.08 + (0.05 * float(index)))
			var route_button := _create_route_button(index, candidate, center, index == selected_index, panel_key)
			node_layer.add_child(route_button)
			_route_buttons.append(route_button)
		var selected_route_center := route_centers[selected_index] if selected_index >= 0 and selected_index < route_centers.size() else history_anchor
		_build_future_chain(selected_route_center)
		_add_ghost_route("SelectedRouteToBoss", selected_route_center, boss_pos, ROUTE_MUTED, 2.8, 0.12)
		_default_panel_key = "route_%d" % selected_index if not candidates.is_empty() else "start"
	var boss_hotspot := _add_hover_hotspot("BossHotspot", boss_pos, 82.0, _tone_palette("boss"), "boss", "boss", boss_stage, false, TextCatalogScript.t("node_runtime.boss.name"), "Boss Core")
	_boss_hotspots.append(boss_hotspot)
	_show_panel(_default_panel_key)

func _layout_info_card() -> void:
	var card_width := clampf(roadmap_canvas.size.x * 0.235, 236.0, 272.0)
	var card_height := clampf(roadmap_canvas.size.y * 0.34, 198.0, 236.0)
	info_card.position = Vector2(64.0, 18.0)
	info_card.size = Vector2(card_width, card_height)
	info_name_label.text = TextCatalogScript.t("node_runtime.info_name_label")
	info_body_label.text = TextCatalogScript.t("node_runtime.info_body_label")

func _build_canvas_backdrop() -> void:
	var ambient_gold := TextureRect.new()
	ambient_gold.texture = _radial_spot_texture(Vector2i(320, 220), Color(0.95, 0.83, 0.66, 0.12))
	ambient_gold.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ambient_gold.stretch_mode = TextureRect.STRETCH_SCALE
	ambient_gold.position = Vector2(44.0, 22.0)
	ambient_gold.size = Vector2(296.0, 210.0)
	ambient_gold.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas_backdrop.add_child(ambient_gold)

	var ambient_coral := TextureRect.new()
	ambient_coral.texture = _radial_spot_texture(Vector2i(320, 240), Color(0.82, 0.47, 0.40, 0.10))
	ambient_coral.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ambient_coral.stretch_mode = TextureRect.STRETCH_SCALE
	ambient_coral.position = Vector2(roadmap_canvas.size.x - 342.0, 18.0)
	ambient_coral.size = Vector2(320.0, 236.0)
	ambient_coral.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas_backdrop.add_child(ambient_coral)

	var top_gloss := TextureRect.new()
	top_gloss.texture = _linear_gloss_texture(Vector2i(maxi(1, int(round(roadmap_canvas.size.x))), 180), Color(1.0, 0.97, 0.90, 0.08), Color(1.0, 0.97, 0.90, 0.0))
	top_gloss.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	top_gloss.stretch_mode = TextureRect.STRETCH_SCALE
	top_gloss.position = Vector2.ZERO
	top_gloss.size = Vector2(roadmap_canvas.size.x, 180.0)
	top_gloss.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas_backdrop.add_child(top_gloss)

	var inner_frame := PanelContainer.new()
	inner_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inner_frame.position = Vector2(14.0, 12.0)
	inner_frame.size = roadmap_canvas.size - Vector2(28.0, 24.0)
	inner_frame.add_theme_stylebox_override(
		"panel",
		_panel_style(Color(0.0, 0.0, 0.0, 0.0), Color(0.96, 0.88, 0.76, 0.06), 30, 1)
	)
	canvas_backdrop.add_child(inner_frame)

func _build_history_chain(start_pos: Vector2, route_history: Array) -> Vector2:
	if route_history.is_empty():
		return start_pos

	var previous_point := start_pos
	var last_point := start_pos
	for history_index in range(route_history.size()):
		var entry: Dictionary = route_history[history_index]
		var stage_slot := _history_position_for_entry(entry)
		if history_index > 0:
			_add_dotted_route("HistoryPath%d" % history_index, previous_point, stage_slot, ROUTE_RED, 4.8, 0.08, 0.84)
			_add_forecast_route("HistoryPathSelected%d" % history_index, previous_point, stage_slot, ROUTE_GOLD, 3.0, 0.06)
		var panel_key := "history_%d" % history_index
		_register_panel_model(panel_key, _history_entry_name(entry), _history_entry_body(entry))
		var hotspot := _add_hover_hotspot(
			"HistoryHotspot%d" % history_index,
			stage_slot,
			70.0 if int(entry.get("stageIndex", -1)) == 0 else 64.0,
			_tone_palette("start") if int(entry.get("stageIndex", -1)) == 0 else _candidate_palette(entry),
			_history_entry_icon_kind(entry),
			panel_key,
			true,
			false,
			_history_entry_name(entry),
			"완료"
		)
		_history_hotspots.append(hotspot)
		var history_sub_label := hotspot.get_node_or_null("SubLabel") as Label
		if history_sub_label != null:
			history_sub_label.text = "Cleared"
		if int(entry.get("stageIndex", -1)) == 0:
			_start_hotspots.append(hotspot)
		previous_point = stage_slot
		last_point = stage_slot
	return last_point

func _build_future_chain(from_point: Vector2) -> void:
	var future_positions := _future_slot_positions()
	var previous_point := from_point
	for future_index in range(future_positions.size()):
		var marker_point: Vector2 = future_positions[future_index]
		var line_name := "FutureRoute%d" % future_index
		if future_index == 0:
			_add_forecast_route(line_name, previous_point, marker_point, ROUTE_FORECAST, 2.6, -0.14 + (0.06 * future_index))
		else:
			_add_ghost_route(line_name, previous_point, marker_point, ROUTE_MUTED, 2.2, -0.14 + (0.06 * future_index))
		var hotspot := _add_hover_hotspot(
			"FuturePreviewHotspot%d" % future_index,
			marker_point,
			58.0,
			_tone_palette("future"),
			"future",
			"future",
			false,
			true,
			TextCatalogScript.t("node_runtime.future.name")
		)
		if future_index == 0:
			hotspot.name = "FuturePreviewHotspot"
		_future_hotspots.append(hotspot)
		previous_point = marker_point
	if not _is_boss_stage():
		_add_ghost_route("FutureToBoss", previous_point, _ref_to_canvas(BOSS_REF), ROUTE_MUTED, 2.2, 0.16)

func _current_route_positions(stage_index: int, candidate_count: int) -> Array[Vector2]:
	var result: Array[Vector2] = []
	if candidate_count <= 0:
		return result
	var clamped_stage := clampi(stage_index, 1, maxi(1, _max_stages() - 2))
	var base := _spine_stage_position(clamped_stage)
	var progress := float(clamped_stage + 1) / float(maxi(2, _max_stages()))
	var spread_scale := lerpf(1.08, 0.84, progress)
	var used_offsets := _route_offsets_for_count(candidate_count)
	for index in range(candidate_count):
		var raw_offset := used_offsets[index] if index < used_offsets.size() else Vector2.ZERO
		result.append(_clamp_canvas_point(base + (raw_offset * spread_scale), 42.0, HOTSPOT_TAG_DEPTH))
	return result

func _spine_stage_position(stage_order: int) -> Vector2:
	var max_order := maxi(1, _max_stages() - 1)
	var clamped_order := clampi(stage_order, 0, max_order)
	if clamped_order == 0:
		return _ref_to_canvas(START_REF)
	if clamped_order >= max_order:
		return _ref_to_canvas(BOSS_REF)
	var t := float(clamped_order + 1) / float(_max_stages() + 1)
	var curve := _quadratic_curve(_ref_to_canvas(START_REF), _ref_to_canvas(SPINE_CONTROL_REF), _ref_to_canvas(BOSS_REF), 56)
	var point_index := clampi(int(round(t * float(curve.size() - 1))), 0, curve.size() - 1)
	return curve[point_index]

func _future_slot_positions() -> Array[Vector2]:
	var result: Array[Vector2] = []
	for future_stage_order in range(_stage_index() + 1, _max_stages() - 1):
		result.append(_clamp_canvas_point(_spine_stage_position(future_stage_order), 30.0, HOTSPOT_TAG_DEPTH))
	return result

func _route_offsets_for_count(candidate_count: int) -> Array[Vector2]:
	var result: Array[Vector2] = []
	if candidate_count >= CURRENT_ROUTE_OFFSETS.size():
		for offset in CURRENT_ROUTE_OFFSETS:
			result.append(offset)
		return result
	var start_index := maxi(0, int(floor(float(CURRENT_ROUTE_OFFSETS.size() - candidate_count) * 0.5)))
	for index in range(candidate_count):
		result.append(CURRENT_ROUTE_OFFSETS[start_index + index])
	return result

func _history_position_for_entry(entry: Dictionary) -> Vector2:
	var stage_order := int(entry.get("stageIndex", 0))
	if stage_order <= 0:
		return _clamp_canvas_point(_ref_to_canvas(START_REF), 36.0, HOTSPOT_TAG_DEPTH)
	if stage_order >= _max_stages() - 1:
		return _clamp_canvas_point(_ref_to_canvas(BOSS_REF), 41.0, 24.0)
	var route_slot := int(entry.get("routeSlotIndex", -1))
	if route_slot < 0:
		return _clamp_canvas_point(_spine_stage_position(stage_order), 34.0, HOTSPOT_TAG_DEPTH)
	var positions := _current_route_positions(stage_order, CURRENT_ROUTE_OFFSETS.size())
	if positions.is_empty():
		return _clamp_canvas_point(_spine_stage_position(stage_order), 34.0, HOTSPOT_TAG_DEPTH)
	return positions[clampi(route_slot, 0, positions.size() - 1)]

func _history_entry_name(entry: Dictionary) -> String:
	if int(entry.get("stageIndex", -1)) == 0:
		return TextCatalogScript.t("node_runtime.fixed_entry.name")
	return TextCatalogScript.display_name(str(entry.get("label", entry.get("id", "?"))))

func _history_entry_body(entry: Dictionary) -> String:
	if int(entry.get("stageIndex", -1)) == 0:
		return TextCatalogScript.t("node_runtime.fixed_entry.body")
	return _candidate_description(entry)

func _history_entry_icon_kind(entry: Dictionary) -> String:
	if int(entry.get("stageIndex", -1)) == 0:
		return "start"
	return _candidate_icon_kind(entry)

func _build_stage_ruler() -> void:
	var markers := [
		{"text": TextCatalogScript.t("node_runtime.stage_marker.hull"), "ratio": 0.94},
		{"text": TextCatalogScript.t("node_runtime.stage_marker.spine"), "ratio": 0.72},
		{"text": TextCatalogScript.t("node_runtime.stage_marker.pockets"), "ratio": 0.45},
		{"text": TextCatalogScript.t("node_runtime.stage_marker.eye"), "ratio": 0.14}
	]
	for marker in markers:
		var y := roadmap_canvas.size.y * float(marker.get("ratio", 0.5))
		var label := Label.new()
		label.text = str(marker.get("text", ""))
		label.position = Vector2(22.0, y - 10.0)
		label.size = Vector2(96.0, 20.0)
		label.add_theme_font_size_override("font_size", 10)
		label.add_theme_color_override("font_color", Color(TEXT_SOFT.r, TEXT_SOFT.g, TEXT_SOFT.b, 0.64))
		stage_ruler.add_child(label)
		var dash := ColorRect.new()
		dash.position = Vector2(88.0, y - 1.0)
		dash.size = Vector2(28.0, 1.0)
		dash.color = Color(TEXT_SOFT.r, TEXT_SOFT.g, TEXT_SOFT.b, 0.32)
		stage_ruler.add_child(dash)

func _build_anatomy_backdrop() -> void:
	var spine := Line2D.new()
	spine.name = "SpineStroke"
	spine.width = 18.0
	spine.default_color = Color(0.94, 0.85, 0.72, 0.10)
	spine.antialiased = true
	for point in [
		Vector2(156.0, 580.0),
		Vector2(214.0, 520.0),
		Vector2(268.0, 470.0),
		Vector2(340.0, 434.0),
		Vector2(450.0, 380.0),
		Vector2(610.0, 352.0),
		Vector2(744.0, 238.0)
	]:
		spine.add_point(_ref_to_canvas(point))
	anatomy_backdrop.add_child(spine)

	for rib in [
		[Vector2(252.0, 302.0), Vector2(214.0, 332.0), Vector2(198.0, 376.0), Vector2(204.0, 436.0)],
		[Vector2(364.0, 256.0), Vector2(318.0, 304.0), Vector2(310.0, 360.0), Vector2(320.0, 438.0)],
		[Vector2(498.0, 230.0), Vector2(452.0, 288.0), Vector2(448.0, 346.0), Vector2(462.0, 430.0)],
		[Vector2(634.0, 220.0), Vector2(586.0, 290.0), Vector2(590.0, 352.0), Vector2(612.0, 438.0)],
		[Vector2(760.0, 214.0), Vector2(726.0, 286.0), Vector2(730.0, 356.0), Vector2(744.0, 438.0)]
	]:
		var rib_line := Line2D.new()
		rib_line.width = 14.0
		rib_line.default_color = Color(0.94, 0.85, 0.72, 0.06)
		rib_line.antialiased = true
		for point in rib:
			rib_line.add_point(_ref_to_canvas(point))
		anatomy_backdrop.add_child(rib_line)

	for anchor in [
		{"point": Vector2(178.0, 620.0), "color": Color(0.86, 0.64, 0.41, 0.26)},
		{"point": Vector2(456.0, 364.0), "color": Color(0.79, 0.44, 0.38, 0.24)},
		{"point": Vector2(748.0, 146.0), "color": Color(0.86, 0.64, 0.41, 0.20)}
	]:
		var marker := ColorRect.new()
		marker.position = _ref_to_canvas(anchor.get("point", Vector2.ZERO)) - Vector2(3.0, 3.0)
		marker.size = Vector2(6.0, 6.0)
		marker.color = anchor.get("color", Color.WHITE)
		anatomy_backdrop.add_child(marker)

func _create_route_button(index: int, candidate: Dictionary, center: Vector2, selected: bool, panel_key: String) -> Button:
	var button := Button.new()
	button.name = "RouteButton%d" % index
	button.text = ""
	button.focus_mode = Control.FOCUS_CLICK
	button.flat = true
	button.clip_contents = false
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.tooltip_text = _candidate_tooltip(candidate)
	var size := 82.0 if selected else 74.0
	center = _clamp_canvas_point(center, size * 0.5, HOTSPOT_TAG_DEPTH)
	button.custom_minimum_size = Vector2(size, size)
	button.size = Vector2(size, size)
	button.position = center - (button.size * 0.5)
	var clear_style := _transparent_button_style()
	button.add_theme_stylebox_override("normal", clear_style)
	button.add_theme_stylebox_override("hover", clear_style)
	button.add_theme_stylebox_override("pressed", clear_style)
	button.add_theme_stylebox_override("focus", clear_style)
	var icon_kind := _candidate_icon_kind(candidate)
	var palette := _candidate_palette(candidate)
	button.set_meta("icon_kind", icon_kind)
	button.set_meta("palette", palette.duplicate(true))
	button.set_meta("selected_visual", selected)
	_attach_hotspot_visual(button, palette, icon_kind, selected, false, false)
	_bind_hover_panel(button, panel_key)
	_attach_hotspot_tag(button, TextCatalogScript.display_name(str(candidate.get("label", candidate.get("id", "?")))))
	button.mouse_entered.connect(func() -> void:
		_refresh_hotspot_visual(button, true)
	)
	button.mouse_exited.connect(func() -> void:
		_refresh_hotspot_visual(button, false)
	)
	button.focus_entered.connect(func() -> void:
		_refresh_hotspot_visual(button, true)
	)
	button.focus_exited.connect(func() -> void:
		_refresh_hotspot_visual(button, false)
	)
	button.pressed.connect(func(route_index := index) -> void:
		_state["selectedNodeIndex"] = route_index
		_default_panel_key = "route_%d" % route_index
		_show_panel(_default_panel_key)
		_queue_canvas_layout()
		call_deferred("_emit_node_selected", route_index)
	)
	return button

func _route_button_style(candidate: Dictionary, selected: bool, hovered: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.0, 0.0, 0.0, 0.0)
	style.border_color = Color(0.0, 0.0, 0.0, 0.0)
	style.corner_radius_top_left = 24
	style.corner_radius_top_right = 24
	style.corner_radius_bottom_left = 24
	style.corner_radius_bottom_right = 24
	return style

func _transparent_button_style() -> StyleBoxFlat:
	return _route_button_style({}, false, false)

func _add_hover_hotspot(node_name: String, center: Vector2, size: float, palette: Dictionary, glyph: String, panel_key: String, selected := false, preview := false, tag_text := "", sub_text := "") -> Button:
	var hotspot := Button.new()
	hotspot.name = node_name
	hotspot.text = ""
	hotspot.focus_mode = Control.FOCUS_CLICK
	hotspot.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	hotspot.flat = true
	hotspot.clip_contents = false
	center = _clamp_canvas_point(center, size * 0.5, HOTSPOT_TAG_DEPTH if not preview else 44.0)
	hotspot.custom_minimum_size = Vector2(size, size)
	hotspot.size = Vector2(size, size)
	hotspot.position = center - (hotspot.size * 0.5)
	hotspot.add_theme_font_size_override("font_size", 26 if size < 70.0 else 30)
	hotspot.add_theme_color_override("font_color", Color(0.96, 0.90, 0.82, 1.0))
	hotspot.set_meta("icon_kind", "future" if preview else glyph)
	hotspot.set_meta("palette", palette.duplicate(true))
	hotspot.set_meta("selected_visual", selected)
	var clear_style := _transparent_button_style()
	hotspot.add_theme_stylebox_override("normal", clear_style)
	hotspot.add_theme_stylebox_override("hover", clear_style)
	hotspot.add_theme_stylebox_override("focus", clear_style)
	hotspot.add_theme_stylebox_override("pressed", clear_style)
	_attach_hotspot_visual(hotspot, palette, glyph, selected, preview, false)
	_bind_hover_panel(hotspot, panel_key)
	_attach_hotspot_tag(hotspot, tag_text, sub_text, preview)
	hotspot.mouse_entered.connect(func() -> void:
		_refresh_hotspot_visual(hotspot, true)
	)
	hotspot.mouse_exited.connect(func() -> void:
		_refresh_hotspot_visual(hotspot, false)
	)
	hotspot.focus_entered.connect(func() -> void:
		_refresh_hotspot_visual(hotspot, true)
	)
	hotspot.focus_exited.connect(func() -> void:
		_refresh_hotspot_visual(hotspot, false)
	)
	node_layer.add_child(hotspot)
	return hotspot

func _attach_hotspot_visual(host: Control, palette: Dictionary, icon_kind: String, selected: bool, preview: bool, hovered: bool) -> void:
	var existing_core := host.get_node_or_null("CoreVisual")
	if existing_core != null:
		existing_core.queue_free()
	var existing_icon := host.get_node_or_null("Icon")
	if existing_icon != null:
		existing_icon.queue_free()

	if preview:
		var preview_art := FutureMarkerArt.new()
		preview_art.name = "CoreVisual"
		preview_art.size = host.size
		preview_art.position = Vector2.ZERO
		preview_art.fill_color = palette.get("fill", Color(0.18, 0.12, 0.09, 0.82))
		preview_art.ring_color = palette.get("border", Color(0.88, 0.73, 0.45, 0.72))
		host.add_child(preview_art)
		var preview_label := Label.new()
		preview_label.name = "Icon"
		preview_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		preview_label.position = Vector2(0.0, 8.0)
		preview_label.size = Vector2(host.size.x, host.size.y - 12.0)
		preview_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		preview_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		preview_label.text = "?"
		preview_label.add_theme_font_size_override("font_size", 28)
		preview_label.add_theme_color_override("font_color", Color(0.96, 0.90, 0.82, 1.0))
		host.add_child(preview_label)
		return

	var core := TextureRect.new()
	core.name = "CoreVisual"
	core.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	core.stretch_mode = TextureRect.STRETCH_SCALE
	core.size = host.size
	core.position = Vector2.ZERO
	core.mouse_filter = Control.MOUSE_FILTER_IGNORE
	core.texture = _node_core_texture(Vector2i(maxi(1, int(round(host.size.x))), maxi(1, int(round(host.size.y)))), palette, selected, hovered)
	host.add_child(core)
	_attach_hotspot_icon(host, icon_kind, palette.get("glyph", Color(0.96, 0.90, 0.82, 1.0)))

func _refresh_hotspot_visual(host: Control, hovered: bool) -> void:
	var palette_value: Variant = host.get_meta("palette", {})
	if not (palette_value is Dictionary):
		return
	var palette: Dictionary = palette_value
	var icon_kind := str(host.get_meta("icon_kind", "normal"))
	var selected := bool(host.get_meta("selected_visual", false))
	var preview := icon_kind == "future"
	_attach_hotspot_visual(host, palette, icon_kind, selected or hovered, preview, hovered)

func _attach_hotspot_icon(host: Control, icon_kind: String, color: Color) -> void:
	var icon := GlyphIcon.new()
	icon.name = "Icon"
	icon.icon_kind = icon_kind
	icon.stroke_color = color
	icon.stroke_width = 1.9 if host.size.x < 76.0 else 2.15
	icon.size = host.size * 0.42
	icon.position = (host.size - icon.size) * 0.5
	icon.position.y -= 2.0 if host.size.x >= 72.0 else 1.0
	host.add_child(icon)

func _attach_hotspot_tag(host: Control, tag_text: String, sub_text := "", preview := false) -> void:
	if tag_text.strip_edges().is_empty():
		return
	var tag_width := clampf(82.0 + (float(tag_text.length()) * 7.2), 104.0, 140.0 if preview else 146.0)
	var local_x := (host.size.x - tag_width) * 0.5
	var min_x := -host.position.x + 12.0
	var max_x := roadmap_canvas.size.x - host.position.x - tag_width - 12.0
	local_x = clampf(local_x, min_x, max_x)
	var place_above := host.position.y + host.size.y + 56.0 > roadmap_canvas.size.y - 12.0
	var tag_y := -38.0 if place_above else host.size.y + 8.0
	var sub_y := -18.0 if place_above else host.size.y + 42.0
	var tag_panel := PanelContainer.new()
	tag_panel.name = "Tag"
	tag_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tag_panel.position = Vector2(local_x, tag_y)
	tag_panel.size = Vector2(tag_width, 30.0)
	tag_panel.add_theme_stylebox_override(
		"panel",
		_panel_style(
			Color(0.11, 0.07, 0.05, 0.94),
			Color(0.82, 0.68, 0.44, 0.18 if not preview else 0.26),
			14 if not preview else 16,
			1,
			Color(0.0, 0.0, 0.0, 0.18),
			8
		)
	)
	host.add_child(tag_panel)

	var tag_margin := MarginContainer.new()
	tag_margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	tag_margin.add_theme_constant_override("margin_left", 8)
	tag_margin.add_theme_constant_override("margin_top", 4)
	tag_margin.add_theme_constant_override("margin_right", 8)
	tag_margin.add_theme_constant_override("margin_bottom", 5)
	tag_panel.add_child(tag_margin)

	var tag_label := Label.new()
	tag_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tag_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	tag_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tag_label.text = tag_text
	tag_label.add_theme_font_size_override("font_size", 11)
	tag_label.add_theme_color_override("font_color", Color(0.95, 0.88, 0.74, 1.0))
	tag_margin.add_child(tag_label)

	if sub_text.strip_edges().is_empty():
		return
	var sub_label := Label.new()
	sub_label.name = "SubLabel"
	sub_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sub_label.position = Vector2(local_x, sub_y)
	sub_label.size = Vector2(tag_width, 14.0)
	sub_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	sub_label.text = sub_text
	sub_label.add_theme_font_size_override("font_size", 10)
	sub_label.add_theme_color_override("font_color", Color(TEXT_SOFT.r, TEXT_SOFT.g, TEXT_SOFT.b, 0.92))
	host.add_child(sub_label)

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
	var holder := Control.new()
	holder.name = name
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	route_layer.add_child(holder)
	var curve := _quadratic_curve(from_point, _curve_control_point(from_point, to_point, bend), to_point, 22)
	for point_index in range(curve.size()):
		if point_index % 2 != 0:
			continue
		var point: Vector2 = curve[point_index]
		var prev_point := curve[maxi(point_index - 1, 0)]
		var next_point := curve[mini(point_index + 1, curve.size() - 1)]
		var tangent := (next_point - prev_point).normalized()
		var dash := PanelContainer.new()
		dash.position = point - Vector2((dot_size * 2.1) * 0.5, dot_size * 0.5)
		dash.size = Vector2(dot_size * 2.1, dot_size)
		dash.rotation = tangent.angle()
		dash.add_theme_stylebox_override("panel", _panel_style(Color(color.r, color.g, color.b, color.a * alpha_scale), Color.TRANSPARENT, 999, 0))
		holder.add_child(dash)

func _add_forecast_route(name: String, from_point: Vector2, to_point: Vector2, color: Color, width: float, bend: float) -> void:
	var glow := Line2D.new()
	glow.name = "%sGlow" % name
	glow.width = width + 4.0
	glow.default_color = Color(color.r, color.g, color.b, color.a * 0.12)
	glow.antialiased = true
	glow.begin_cap_mode = Line2D.LINE_CAP_ROUND
	glow.end_cap_mode = Line2D.LINE_CAP_ROUND
	for point in _quadratic_curve(from_point, _curve_control_point(from_point, to_point, bend), to_point, 16):
		glow.add_point(point)
	route_layer.add_child(glow)

	var line := Line2D.new()
	line.name = name
	line.width = width
	line.default_color = color
	line.antialiased = true
	line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	line.end_cap_mode = Line2D.LINE_CAP_ROUND
	for point in _quadratic_curve(from_point, _curve_control_point(from_point, to_point, bend), to_point, 16):
		line.add_point(point)
	route_layer.add_child(line)

func _add_ghost_route(name: String, from_point: Vector2, to_point: Vector2, color: Color, width: float, bend: float) -> void:
	var holder := Control.new()
	holder.name = name
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	route_layer.add_child(holder)
	var curve := _quadratic_curve(from_point, _curve_control_point(from_point, to_point, bend), to_point, 20)
	for point_index in range(curve.size()):
		if point_index % 2 != 0:
			continue
		var point: Vector2 = curve[point_index]
		var prev_point := curve[maxi(point_index - 1, 0)]
		var next_point := curve[mini(point_index + 1, curve.size() - 1)]
		var tangent := (next_point - prev_point).normalized()
		var dash := PanelContainer.new()
		dash.position = point - Vector2((width * 4.0) * 0.5, width * 0.5)
		dash.size = Vector2(width * 4.0, width)
		dash.rotation = tangent.angle()
		dash.add_theme_stylebox_override("panel", _panel_style(Color(color.r, color.g, color.b, color.a * 0.82), Color.TRANSPARENT, 999, 0))
		holder.add_child(dash)

func _quadratic_curve(from_point: Vector2, control_point: Vector2, to_point: Vector2, steps: int) -> Array[Vector2]:
	var points: Array[Vector2] = []
	for step in range(steps + 1):
		var t := float(step) / float(maxi(1, steps))
		var inv := 1.0 - t
		points.append((inv * inv * from_point) + (2.0 * inv * t * control_point) + (t * t * to_point))
	return points

func _curve_control_point(from_point: Vector2, to_point: Vector2, bend: float) -> Vector2:
	var mid := (from_point + to_point) * 0.5
	var direction := to_point - from_point
	if direction.length() <= 0.01:
		return mid
	var normal := Vector2(-direction.y, direction.x).normalized()
	var strength := clampf(direction.length() * 0.18, 34.0, 96.0)
	return mid + (normal * strength * bend)

func _route_choice_center(index: int) -> Vector2:
	var centers := _current_route_positions(_stage_index(), maxi(index + 1, 1))
	return centers[clampi(index, 0, centers.size() - 1)] if not centers.is_empty() else _spine_stage_position(maxi(1, _stage_index()))

func _ref_to_canvas(reference_point: Vector2) -> Vector2:
	return Vector2(
		(reference_point.x / REFERENCE_CANVAS_SIZE.x) * roadmap_canvas.size.x,
		(reference_point.y / REFERENCE_CANVAS_SIZE.y) * roadmap_canvas.size.y
	)

func _clamp_canvas_point(point: Vector2, radius: float, reserve_bottom: float) -> Vector2:
	var min_x := HOTSPOT_SAFE_MARGIN + radius
	var max_x := roadmap_canvas.size.x - HOTSPOT_SAFE_MARGIN - radius
	var min_y := HOTSPOT_SAFE_MARGIN + radius
	var max_y := roadmap_canvas.size.y - maxf(HOTSPOT_SAFE_MARGIN, reserve_bottom) - radius
	if max_x < min_x:
		max_x = min_x
	if max_y < min_y:
		max_y = min_y
	return Vector2(
		clampf(point.x, min_x, max_x),
		clampf(point.y, min_y, max_y)
	)

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
	var risk := str(candidate.get("riskTier", "safe"))
	var node_type := str(candidate.get("nodeType", "normal"))
	if node_type == "boss" or risk == "boss":
		return _tone_palette("boss")
	if risk == "support" or node_type == "repair_event" or risk == "event" or node_type == "mysterious_crevice":
		return _tone_palette("brown")
	if risk in ["danger", "hard"] or node_type == "mixed_weakness" or node_type.find("red") >= 0:
		return _tone_palette("red")
	return _tone_palette("stage")

func _candidate_icon_kind(candidate: Dictionary) -> String:
	var node_type := str(candidate.get("nodeType", "normal"))
	var risk := str(candidate.get("riskTier", "safe"))
	if node_type == "repair_event" or risk == "support":
		return "repair"
	if node_type == "boss" or risk == "boss":
		return "boss"
	if node_type == "mixed_weakness":
		return "reef"
	if node_type == "mysterious_crevice" or risk == "unknown":
		return "unknown"
	if risk in ["danger", "hard"]:
		return "danger"
	if node_type.find("red") >= 0:
		return "harpoon"
	if node_type.find("blue") >= 0 or bool(candidate.get("isEvent", false)):
		return "reef"
	return "normal"

func _candidate_glyph(candidate: Dictionary) -> String:
	var node_type := str(candidate.get("nodeType", "normal"))
	var risk := str(candidate.get("riskTier", "safe"))
	if node_type == "repair_event" or risk == "support":
		return "+"
	if bool(candidate.get("isEvent", false)) or risk == "event":
		return "?"
	if node_type == "mixed_weakness":
		return "="
	if risk in ["danger", "hard"]:
		return "!"
	if node_type.find("blue") >= 0:
		return "~"
	if node_type.find("red") >= 0:
		return "^"
	return "o"

func _candidate_glyph_color(candidate: Dictionary) -> Color:
	return _candidate_palette(candidate).get("glyph", Color(0.96, 0.91, 0.82, 1.0))

func _candidate_description(candidate: Dictionary) -> String:
	var risk := TextCatalogScript.enum_label("risk", str(candidate.get("riskTier", "safe")))
	var reward := TextCatalogScript.enum_label("reward_bias", str(candidate.get("rewardBias", "baseline")))
	var weakness := _weakness_text(candidate)
	var hint := TextCatalogScript.hint_label(str(candidate.get("recommendedBuildHint", "")))
	return TextCatalogScript.t("node_runtime.candidate_description", [risk, weakness, reward, hint])

func _candidate_tooltip(candidate: Dictionary) -> String:
	var label := TextCatalogScript.display_name(str(candidate.get("label", candidate.get("id", "?"))))
	var risk := TextCatalogScript.enum_label("risk", str(candidate.get("riskTier", "safe")))
	var reward := TextCatalogScript.enum_label("reward_bias", str(candidate.get("rewardBias", "baseline")))
	return "%s\n%s | %s" % [label, risk, reward]

func _selected_candidate_index(candidate_count: int) -> int:
	if candidate_count <= 0:
		return 0
	return clampi(int(_state.get("selectedNodeIndex", 0)), 0, candidate_count - 1)

func _candidates() -> Array:
	var node_select_state: Variant = _node_select_state()
	if node_select_state is Dictionary:
		var nested: Variant = node_select_state.get("candidates", [])
		if nested is Array:
			return nested
	var direct: Variant = _state.get("candidates", [])
	return direct if direct is Array else []

func _node_select_state() -> Dictionary:
	var nested: Variant = _state.get("nodeSelect", {})
	return nested if nested is Dictionary else {}

func _route_history() -> Array:
	var node_select_state := _node_select_state()
	var nested: Variant = node_select_state.get("routeHistory", _state.get("routeHistory", []))
	var route_history: Array = nested.duplicate(true) if nested is Array else []
	if route_history.is_empty() and _stage_index() > 0:
		route_history.append({
			"stageIndex": 0,
			"routeSlotIndex": 0,
			"id": "fixed_entry",
			"label": TextCatalogScript.t("node_runtime.fixed_entry.name"),
			"nodeType": "normal",
			"riskTier": "safe",
			"rewardBias": "baseline",
			"recommendedBuildHint": TextCatalogScript.t("node_runtime.fixed_entry.body"),
			"weakness": []
		})
	return route_history

func _stage_index() -> int:
	return int(_state.get("stageIndex", 0))

func _stage_number() -> int:
	return _stage_index() + 1

func _max_stages() -> int:
	return maxi(1, int(_state.get("maxStages", 1)))

func _is_fixed_stage() -> bool:
	return _stage_index() <= 0

func _is_boss_stage() -> bool:
	var node_select_state := _node_select_state()
	if bool(node_select_state.get("isBossStage", false)):
		return true
	return _stage_index() >= _max_stages() - 1

func _selected_leviathan() -> Dictionary:
	return _state.get("selectedLeviathan", {})

func _leviathan_name(leviathan: Dictionary) -> String:
	return TextCatalogScript.display_name(str(leviathan.get("name", TextCatalogScript.t("node_runtime.leviathan_default"))))

func _hero_eyebrow_text(stage_number: int) -> String:
	return TextCatalogScript.t("node_runtime.hero_eyebrow.entry") if stage_number == 1 else TextCatalogScript.t("node_runtime.hero_eyebrow.pocket")

func _board_title(stage_number: int) -> String:
	if _is_fixed_stage():
		return TextCatalogScript.t("node_runtime.board_title.fixed")
	if _is_boss_stage():
		return TextCatalogScript.t("node_runtime.boss.name")
	return TextCatalogScript.t("node_runtime.board_title.branch")

func _board_hint(stage_number: int, max_stages: int) -> String:
	if _is_fixed_stage() or _is_boss_stage():
		return TextCatalogScript.t("node_runtime.board_hint.fixed", [stage_number, max_stages])
	return TextCatalogScript.t("node_runtime.board_hint.branch")

func _weakness_text(candidate: Dictionary) -> String:
	var weakness_label := str(candidate.get("weaknessLabel", ""))
	if weakness_label.is_empty():
		var weakness: Array = candidate.get("weakness", [])
		if weakness.is_empty():
			return TextCatalogScript.t("node.no_weakness")
		weakness_label = ",".join(weakness)
	var parts := weakness_label.split(",", false)
	var localized: Array[String] = []
	for part in parts:
		var value := part.strip_edges().to_lower()
		if value.is_empty():
			continue
		if value in ["red", "blue", "purple", "green"]:
			localized.append(TextCatalogScript.t("color.%s" % value))
		else:
			localized.append(part.strip_edges())
	return ", ".join(localized) if not localized.is_empty() else TextCatalogScript.t("node.no_weakness")

func _emit_node_selected(index: int) -> void:
	node_selected.emit(index)

func _panel_style(bg: Color, border: Color, radius: int, border_width: int, shadow := Color(0, 0, 0, 0), shadow_size := 0) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.border_width_left = border_width
	style.border_width_top = border_width
	style.border_width_right = border_width
	style.border_width_bottom = border_width
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	style.shadow_color = shadow
	style.shadow_size = shadow_size
	return style

func _tone_palette(tone: String) -> Dictionary:
	match tone:
		"start":
			return {
				"key": "start",
				"fill": Color(0.34, 0.25, 0.16, 0.92),
				"top": Color(0.62, 0.51, 0.32, 1.0),
				"bottom": Color(0.31, 0.23, 0.14, 1.0),
				"border": Color(0.90, 0.76, 0.47, 0.82),
				"glyph": Color(0.97, 0.91, 0.82, 1.0)
			}
		"stage":
			return {
				"key": "stage",
				"fill": Color(0.55, 0.40, 0.24, 0.96),
				"top": Color(0.87, 0.73, 0.43, 1.0),
				"bottom": Color(0.56, 0.40, 0.19, 1.0),
				"border": Color(0.95, 0.84, 0.61, 0.56),
				"glyph": Color(0.17, 0.12, 0.07, 1.0)
			}
		"red":
			return {
				"key": "red",
				"fill": Color(0.52, 0.28, 0.22, 0.96),
				"top": Color(0.79, 0.49, 0.40, 1.0),
				"bottom": Color(0.46, 0.22, 0.18, 1.0),
				"border": Color(0.96, 0.83, 0.73, 0.44),
				"glyph": Color(0.96, 0.91, 0.82, 1.0)
			}
		"boss":
			return {
				"key": "boss",
				"fill": Color(0.55, 0.29, 0.23, 0.98),
				"top": Color(0.82, 0.54, 0.45, 1.0),
				"bottom": Color(0.52, 0.25, 0.21, 1.0),
				"border": Color(0.97, 0.86, 0.75, 0.60),
				"glyph": Color(0.97, 0.91, 0.82, 1.0)
			}
		"future":
			return {
				"key": "future",
				"fill": Color(0.16, 0.11, 0.08, 0.86),
				"top": Color(0.16, 0.11, 0.08, 0.86),
				"bottom": Color(0.11, 0.08, 0.05, 0.86),
				"border": Color(0.88, 0.73, 0.45, 0.66),
				"glyph": Color(0.96, 0.90, 0.82, 1.0)
			}
		_:
			return {
				"key": "brown",
				"fill": Color(0.28, 0.19, 0.13, 0.96),
				"top": Color(0.48, 0.37, 0.25, 1.0),
				"bottom": Color(0.23, 0.17, 0.11, 1.0),
				"border": Color(0.86, 0.74, 0.57, 0.36),
				"glyph": Color(0.96, 0.91, 0.82, 1.0)
			}

func _radial_spot_texture(size: Vector2i, tint: Color) -> Texture2D:
	var key := "radial_%d_%d_%0.3f_%0.3f_%0.3f_%0.3f" % [size.x, size.y, tint.r, tint.g, tint.b, tint.a]
	if _spot_texture_cache.has(key):
		return _spot_texture_cache[key]
	var image := Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
	for y in range(size.y):
		var py := (float(y) / float(maxi(1, size.y - 1))) - 0.5
		for x in range(size.x):
			var px := (float(x) / float(maxi(1, size.x - 1))) - 0.5
			var dist := sqrt(((px / 0.9) * (px / 0.9)) + ((py / 0.7) * (py / 0.7)))
			var alpha := pow(maxf(0.0, 1.0 - dist), 2.2) * tint.a
			image.set_pixel(x, y, Color(tint.r, tint.g, tint.b, alpha))
	var texture := ImageTexture.create_from_image(image)
	_spot_texture_cache[key] = texture
	return texture

func _linear_gloss_texture(size: Vector2i, top_color: Color, bottom_color: Color) -> Texture2D:
	var key := "gloss_%d_%d_%0.3f_%0.3f_%0.3f_%0.3f_%0.3f_%0.3f_%0.3f_%0.3f" % [size.x, size.y, top_color.r, top_color.g, top_color.b, top_color.a, bottom_color.r, bottom_color.g, bottom_color.b, bottom_color.a]
	if _spot_texture_cache.has(key):
		return _spot_texture_cache[key]
	var image := Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
	for y in range(size.y):
		var t := float(y) / float(maxi(1, size.y - 1))
		var color := top_color.lerp(bottom_color, t)
		for x in range(size.x):
			image.set_pixel(x, y, color)
	var texture := ImageTexture.create_from_image(image)
	_spot_texture_cache[key] = texture
	return texture

func _node_core_texture(size: Vector2i, palette: Dictionary, selected: bool, hovered: bool) -> Texture2D:
	var key := "%s_%d_%d_%s_%s" % [str(palette.get("key", "brown")), size.x, size.y, str(selected), str(hovered)]
	if _core_texture_cache.has(key):
		return _core_texture_cache[key]
	var image := Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
	var top: Color = palette.get("top", Color(0.48, 0.37, 0.25, 1.0))
	var bottom: Color = palette.get("bottom", Color(0.23, 0.17, 0.11, 1.0))
	var border: Color = palette.get("border", ROUTE_GOLD)
	if hovered and not selected:
		top = top.lightened(0.06)
		bottom = bottom.lightened(0.04)
	var core_rect := Rect2(6.0 if selected else 4.0, 4.0 if selected else 2.0, float(size.x) - (12.0 if selected else 8.0), float(size.y) - (14.0 if selected else 10.0))
	var radius := minf(core_rect.size.x, core_rect.size.y) * 0.30
	var halo_rect := core_rect.grow(9.0)
	for y in range(size.y):
		for x in range(size.x):
			var point := Vector2(float(x) + 0.5, float(y) + 0.5)
			var color := Color(0.0, 0.0, 0.0, 0.0)
			var shadow := _ellipse_alpha(point, Vector2(float(size.x) * 0.5, core_rect.position.y + (core_rect.size.y * 0.92)), Vector2(core_rect.size.x * 0.38, core_rect.size.y * 0.12))
			if shadow > 0.0:
				color = _alpha_blend(color, Color(0.0, 0.0, 0.0, 0.24 * shadow))
			if selected:
				var halo_outer := _coverage_from_distance(_rounded_rect_distance(point, halo_rect, radius + 6.0), 1.4)
				var halo_inner := _coverage_from_distance(_rounded_rect_distance(point, core_rect.grow(1.0), radius + 1.0), 1.0)
				var halo_ring := maxf(0.0, halo_outer - halo_inner)
				if halo_ring > 0.0:
					color = _alpha_blend(color, Color(ROUTE_GOLD.r, ROUTE_GOLD.g, ROUTE_GOLD.b, 0.16 * halo_ring))
			var dist := _rounded_rect_distance(point, core_rect, radius)
			var coverage := _coverage_from_distance(dist, 1.3)
			if coverage > 0.0:
				var t := clampf((point.y - core_rect.position.y) / maxf(core_rect.size.y, 1.0), 0.0, 1.0)
				var base := top.lerp(bottom, pow(t, 0.92))
				if t < 0.44:
					base = _alpha_blend(base, Color(1.0, 0.98, 0.92, 0.16 * (1.0 - (t / 0.44))))
				if t > 0.58:
					base = _alpha_blend(base, Color(0.0, 0.0, 0.0, 0.18 * ((t - 0.58) / 0.42)))
				var border_mix := clampf(1.0 - ((-dist) / 2.0), 0.0, 1.0)
				if border_mix > 0.0:
					base = base.lerp(border, border_mix * 0.78)
				color = _alpha_blend(color, Color(base.r, base.g, base.b, coverage))
			image.set_pixel(x, y, color)
	var texture := ImageTexture.create_from_image(image)
	_core_texture_cache[key] = texture
	return texture

func _rounded_rect_distance(point: Vector2, rect: Rect2, radius: float) -> float:
	var clamped_radius := minf(radius, minf(rect.size.x, rect.size.y) * 0.5)
	var center := rect.position + (rect.size * 0.5)
	var half := (rect.size * 0.5) - Vector2.ONE * clamped_radius
	var q := Vector2(absf(point.x - center.x), absf(point.y - center.y)) - half
	var outside := Vector2(maxf(q.x, 0.0), maxf(q.y, 0.0))
	return minf(maxf(q.x, q.y), 0.0) + outside.length() - clamped_radius

func _coverage_from_distance(distance: float, feather: float) -> float:
	if distance <= 0.0:
		return 1.0
	return clampf(1.0 - (distance / feather), 0.0, 1.0)

func _ellipse_alpha(point: Vector2, center: Vector2, radii: Vector2) -> float:
	if radii.x <= 0.01 or radii.y <= 0.01:
		return 0.0
	var dx := (point.x - center.x) / radii.x
	var dy := (point.y - center.y) / radii.y
	var distance := (dx * dx) + (dy * dy)
	if distance >= 1.0:
		return 0.0
	return pow(1.0 - distance, 1.8)

func _alpha_blend(dst: Color, src: Color) -> Color:
	var out_alpha := src.a + (dst.a * (1.0 - src.a))
	if out_alpha <= 0.0001:
		return Color(0.0, 0.0, 0.0, 0.0)
	var out_red := ((src.r * src.a) + (dst.r * dst.a * (1.0 - src.a))) / out_alpha
	var out_green := ((src.g * src.a) + (dst.g * dst.a * (1.0 - src.a))) / out_alpha
	var out_blue := ((src.b * src.a) + (dst.b * dst.a * (1.0 - src.a))) / out_alpha
	return Color(out_red, out_green, out_blue, out_alpha)

func _clear_container(container: Node) -> void:
	for child in container.get_children():
		child.free()
