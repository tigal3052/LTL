# 怨꾩빟:
# - Responsibility: build non-interactive node-select roadmap backdrop, ruler, anatomy, and route-line visuals.
# - Input: target layers, canvas size, marker labels, route geometry, colors, and shared texture caches.
# - Output: child Control, TextureRect, ColorRect, PanelContainer, and Line2D nodes on the supplied layers.
# - Prohibited: creating clickable route buttons, mutating page state, or resolving localized copy keys.
#
# ?ㅽ뻾: define reusable node-select roadmap rendering helpers.
class_name NodeSelectRoadmapRenderer
extends RefCounted

const NodeSelectLayoutPolicyScript = preload("res://src/scenes/pages/node_select/NodeSelectLayoutPolicy.gd")
const NodeSelectVisualFactoryScript = preload("res://src/scenes/pages/node_select/NodeSelectVisualFactory.gd")

const TEXT_SOFT := Color(0.80, 0.74, 0.66, 0.72)

# ?ㅽ뻾: build ambient textures and the inner frame behind the roadmap canvas.
static func build_canvas_backdrop(canvas_backdrop: Control, canvas_size: Vector2, spot_texture_cache: Dictionary) -> void:
	var ambient_gold := TextureRect.new()
	ambient_gold.texture = NodeSelectVisualFactoryScript.radial_spot_texture(Vector2i(320, 220), Color(0.95, 0.83, 0.66, 0.12), spot_texture_cache)
	ambient_gold.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ambient_gold.stretch_mode = TextureRect.STRETCH_SCALE
	ambient_gold.position = Vector2(44.0, 22.0)
	ambient_gold.size = Vector2(296.0, 210.0)
	ambient_gold.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas_backdrop.add_child(ambient_gold)

	var ambient_coral := TextureRect.new()
	ambient_coral.texture = NodeSelectVisualFactoryScript.radial_spot_texture(Vector2i(320, 240), Color(0.82, 0.47, 0.40, 0.10), spot_texture_cache)
	ambient_coral.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ambient_coral.stretch_mode = TextureRect.STRETCH_SCALE
	ambient_coral.position = Vector2(canvas_size.x - 342.0, 18.0)
	ambient_coral.size = Vector2(320.0, 236.0)
	ambient_coral.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas_backdrop.add_child(ambient_coral)

	var top_gloss := TextureRect.new()
	top_gloss.texture = NodeSelectVisualFactoryScript.linear_gloss_texture(Vector2i(maxi(1, int(round(canvas_size.x))), 180), Color(1.0, 0.97, 0.90, 0.08), Color(1.0, 0.97, 0.90, 0.0), spot_texture_cache)
	top_gloss.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	top_gloss.stretch_mode = TextureRect.STRETCH_SCALE
	top_gloss.position = Vector2.ZERO
	top_gloss.size = Vector2(canvas_size.x, 180.0)
	top_gloss.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas_backdrop.add_child(top_gloss)

	var inner_frame := PanelContainer.new()
	inner_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inner_frame.position = Vector2(14.0, 12.0)
	inner_frame.size = canvas_size - Vector2(28.0, 24.0)
	inner_frame.add_theme_stylebox_override(
		"panel",
		NodeSelectVisualFactoryScript.panel_style(Color(0.0, 0.0, 0.0, 0.0), Color(0.96, 0.88, 0.76, 0.06), 30, 1)
	)
	canvas_backdrop.add_child(inner_frame)

# ?ㅽ뻾: build static stage ruler labels and guide dashes.
static func build_stage_ruler(stage_ruler: Control, canvas_size: Vector2, markers: Array) -> void:
	for marker in markers:
		var y := canvas_size.y * float(marker.get("ratio", 0.5))
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

# ?ㅽ뻾: build the faint Leviathan anatomy silhouette under route markers.
static func build_anatomy_backdrop(anatomy_backdrop: Control, canvas_size: Vector2) -> void:
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
		spine.add_point(NodeSelectLayoutPolicyScript.ref_to_canvas(point, canvas_size))
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
			rib_line.add_point(NodeSelectLayoutPolicyScript.ref_to_canvas(point, canvas_size))
		anatomy_backdrop.add_child(rib_line)

	for anchor in [
		{"point": Vector2(178.0, 620.0), "color": Color(0.86, 0.64, 0.41, 0.26)},
		{"point": Vector2(456.0, 364.0), "color": Color(0.79, 0.44, 0.38, 0.24)},
		{"point": Vector2(748.0, 146.0), "color": Color(0.86, 0.64, 0.41, 0.20)}
	]:
		var marker := ColorRect.new()
		marker.position = NodeSelectLayoutPolicyScript.ref_to_canvas(anchor.get("point", Vector2.ZERO), canvas_size) - Vector2(3.0, 3.0)
		marker.size = Vector2(6.0, 6.0)
		marker.color = anchor.get("color", Color.WHITE)
		anatomy_backdrop.add_child(marker)

# ?ㅽ뻾: add a dotted route made of rounded dash panels.
static func add_dotted_route(route_layer: Control, name: String, from_point: Vector2, to_point: Vector2, color: Color, dot_size: float, bend: float, alpha_scale := 1.0) -> void:
	var holder := Control.new()
	holder.name = name
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	route_layer.add_child(holder)
	var curve := NodeSelectLayoutPolicyScript.quadratic_curve(from_point, NodeSelectLayoutPolicyScript.curve_control_point(from_point, to_point, bend), to_point, 22)
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
		dash.add_theme_stylebox_override("panel", NodeSelectVisualFactoryScript.panel_style(Color(color.r, color.g, color.b, color.a * alpha_scale), Color.TRANSPARENT, 999, 0))
		holder.add_child(dash)

# ?ㅽ뻾: add a solid forecast route line with a soft glow stroke.
static func add_forecast_route(route_layer: Control, name: String, from_point: Vector2, to_point: Vector2, color: Color, width: float, bend: float) -> void:
	var glow := Line2D.new()
	glow.name = "%sGlow" % name
	glow.width = width + 4.0
	glow.default_color = Color(color.r, color.g, color.b, color.a * 0.12)
	glow.antialiased = true
	glow.begin_cap_mode = Line2D.LINE_CAP_ROUND
	glow.end_cap_mode = Line2D.LINE_CAP_ROUND
	for point in NodeSelectLayoutPolicyScript.quadratic_curve(from_point, NodeSelectLayoutPolicyScript.curve_control_point(from_point, to_point, bend), to_point, 16):
		glow.add_point(point)
	route_layer.add_child(glow)

	var line := Line2D.new()
	line.name = name
	line.width = width
	line.default_color = color
	line.antialiased = true
	line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	line.end_cap_mode = Line2D.LINE_CAP_ROUND
	for point in NodeSelectLayoutPolicyScript.quadratic_curve(from_point, NodeSelectLayoutPolicyScript.curve_control_point(from_point, to_point, bend), to_point, 16):
		line.add_point(point)
	route_layer.add_child(line)

# ?ㅽ뻾: add a muted ghost route made of elongated dash panels.
static func add_ghost_route(route_layer: Control, name: String, from_point: Vector2, to_point: Vector2, color: Color, width: float, bend: float) -> void:
	var holder := Control.new()
	holder.name = name
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	route_layer.add_child(holder)
	var curve := NodeSelectLayoutPolicyScript.quadratic_curve(from_point, NodeSelectLayoutPolicyScript.curve_control_point(from_point, to_point, bend), to_point, 20)
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
		dash.add_theme_stylebox_override("panel", NodeSelectVisualFactoryScript.panel_style(Color(color.r, color.g, color.b, color.a * 0.82), Color.TRANSPARENT, 999, 0))
		holder.add_child(dash)
