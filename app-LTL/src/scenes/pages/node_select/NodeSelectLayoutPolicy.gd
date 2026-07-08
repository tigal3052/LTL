# 怨꾩빟:
# - Responsibility: project node-select roadmap reference points into canvas-local route positions.
# - Input: canvas size, stage indices, max-stage count, candidate count, and route-history entries.
# - Output: clamped marker positions, route offset selections, and quadratic curve samples.
# - Prohibited: creating UI nodes, reading localized copy, mutating page state, or emitting signals.
#
# ?ㅽ뻾: define deterministic node-select roadmap layout math.
class_name NodeSelectLayoutPolicy
extends RefCounted

const REFERENCE_CANVAS_SIZE := Vector2(920.0, 760.0)
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

# ?ㅽ뻾: return the clamped start marker position for the current canvas.
static func start_position(canvas_size: Vector2) -> Vector2:
	return clamp_canvas_point(ref_to_canvas(START_REF, canvas_size), 36.0, HOTSPOT_TAG_DEPTH, canvas_size)

# ?ㅽ뻾: return the clamped boss marker position for the current canvas.
static func boss_position(canvas_size: Vector2) -> Vector2:
	return clamp_canvas_point(ref_to_canvas(BOSS_REF, canvas_size), 41.0, 24.0, canvas_size)

# ?ㅽ뻾: return the unclamped boss reference point used by forecast routes.
static func boss_reference_position(canvas_size: Vector2) -> Vector2:
	return ref_to_canvas(BOSS_REF, canvas_size)

# ?ㅽ뻾: project current candidate route centers along the Leviathan spine.
static func current_route_positions(stage_index: int, candidate_count: int, max_stages: int, canvas_size: Vector2) -> Array[Vector2]:
	var result: Array[Vector2] = []
	if candidate_count <= 0:
		return result
	var clamped_stage := clampi(stage_index, 1, maxi(1, max_stages - 2))
	var base := spine_stage_position(clamped_stage, max_stages, canvas_size)
	var progress := float(clamped_stage + 1) / float(maxi(2, max_stages))
	var spread_scale := lerpf(1.08, 0.84, progress)
	var used_offsets := route_offsets_for_count(candidate_count)
	for index in range(candidate_count):
		var raw_offset := used_offsets[index] if index < used_offsets.size() else Vector2.ZERO
		result.append(clamp_canvas_point(base + (raw_offset * spread_scale), 42.0, HOTSPOT_TAG_DEPTH, canvas_size))
	return result

# ?ㅽ뻾: return a point on the curved start-to-boss spine for the requested stage order.
static func spine_stage_position(stage_order: int, max_stages: int, canvas_size: Vector2) -> Vector2:
	var max_order := maxi(1, max_stages - 1)
	var clamped_order := clampi(stage_order, 0, max_order)
	if clamped_order == 0:
		return ref_to_canvas(START_REF, canvas_size)
	if clamped_order >= max_order:
		return ref_to_canvas(BOSS_REF, canvas_size)
	var t := float(clamped_order + 1) / float(max_stages + 1)
	var curve := quadratic_curve(ref_to_canvas(START_REF, canvas_size), ref_to_canvas(SPINE_CONTROL_REF, canvas_size), ref_to_canvas(BOSS_REF, canvas_size), 56)
	var point_index := clampi(int(round(t * float(curve.size() - 1))), 0, curve.size() - 1)
	return curve[point_index]

# ?ㅽ뻾: return future marker positions between the current stage and boss stage.
static func future_slot_positions(stage_index: int, max_stages: int, canvas_size: Vector2) -> Array[Vector2]:
	var result: Array[Vector2] = []
	for future_stage_order in range(stage_index + 1, max_stages - 1):
		result.append(clamp_canvas_point(spine_stage_position(future_stage_order, max_stages, canvas_size), 30.0, HOTSPOT_TAG_DEPTH, canvas_size))
	return result

# ?ㅽ뻾: choose centered offsets for the visible candidate count.
static func route_offsets_for_count(candidate_count: int) -> Array[Vector2]:
	var result: Array[Vector2] = []
	if candidate_count >= CURRENT_ROUTE_OFFSETS.size():
		for offset in CURRENT_ROUTE_OFFSETS:
			result.append(offset)
		return result
	var start_index := maxi(0, int(floor(float(CURRENT_ROUTE_OFFSETS.size() - candidate_count) * 0.5)))
	for index in range(candidate_count):
		result.append(CURRENT_ROUTE_OFFSETS[start_index + index])
	return result

# ?ㅽ뻾: project a route-history entry back to the current canvas coordinate system.
static func history_position_for_entry(entry: Dictionary, max_stages: int, canvas_size: Vector2) -> Vector2:
	var stage_order := int(entry.get("stageIndex", 0))
	if stage_order <= 0:
		return clamp_canvas_point(ref_to_canvas(START_REF, canvas_size), 36.0, HOTSPOT_TAG_DEPTH, canvas_size)
	if stage_order >= max_stages - 1:
		return clamp_canvas_point(ref_to_canvas(BOSS_REF, canvas_size), 41.0, 24.0, canvas_size)
	var route_slot := int(entry.get("routeSlotIndex", -1))
	if route_slot < 0:
		return clamp_canvas_point(spine_stage_position(stage_order, max_stages, canvas_size), 34.0, HOTSPOT_TAG_DEPTH, canvas_size)
	var positions := current_route_positions(stage_order, CURRENT_ROUTE_OFFSETS.size(), max_stages, canvas_size)
	if positions.is_empty():
		return clamp_canvas_point(spine_stage_position(stage_order, max_stages, canvas_size), 34.0, HOTSPOT_TAG_DEPTH, canvas_size)
	return positions[clampi(route_slot, 0, positions.size() - 1)]

# ?ㅽ뻾: sample points along a quadratic Bezier curve.
static func quadratic_curve(from_point: Vector2, control_point: Vector2, to_point: Vector2, steps: int) -> Array[Vector2]:
	var points: Array[Vector2] = []
	for step in range(steps + 1):
		var t := float(step) / float(maxi(1, steps))
		var inv := 1.0 - t
		points.append((inv * inv * from_point) + (2.0 * inv * t * control_point) + (t * t * to_point))
	return points

# ?ㅽ뻾: compute the route curve control point for a bend strength.
static func curve_control_point(from_point: Vector2, to_point: Vector2, bend: float) -> Vector2:
	var mid := (from_point + to_point) * 0.5
	var direction := to_point - from_point
	if direction.length() <= 0.01:
		return mid
	var normal := Vector2(-direction.y, direction.x).normalized()
	var strength := clampf(direction.length() * 0.18, 34.0, 96.0)
	return mid + (normal * strength * bend)

# ?ㅽ뻾: project reference-canvas coordinates into the active roadmap canvas.
static func ref_to_canvas(reference_point: Vector2, canvas_size: Vector2) -> Vector2:
	return Vector2(
		(reference_point.x / REFERENCE_CANVAS_SIZE.x) * canvas_size.x,
		(reference_point.y / REFERENCE_CANVAS_SIZE.y) * canvas_size.y
	)

# ?ㅽ뻾: keep a marker center within visible canvas and tag reserve margins.
static func clamp_canvas_point(point: Vector2, radius: float, reserve_bottom: float, canvas_size: Vector2) -> Vector2:
	var min_x := HOTSPOT_SAFE_MARGIN + radius
	var max_x := canvas_size.x - HOTSPOT_SAFE_MARGIN - radius
	var min_y := HOTSPOT_SAFE_MARGIN + radius
	var max_y := canvas_size.y - maxf(HOTSPOT_SAFE_MARGIN, reserve_bottom) - radius
	if max_x < min_x:
		max_x = min_x
	if max_y < min_y:
		max_y = min_y
	return Vector2(
		clampf(point.x, min_x, max_x),
		clampf(point.y, min_y, max_y)
	)
