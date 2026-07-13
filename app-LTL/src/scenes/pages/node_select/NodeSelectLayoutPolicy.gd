# 怨꾩빟:
# - Responsibility: project node-select roadmap reference points into canvas-local route positions.
# - Input: canvas size, stage indices, max-stage count, candidate count, and route-history entries.
# - Output: clamped marker positions, route offset selections, and quadratic curve samples.
# - Prohibited: creating UI nodes, reading localized copy, mutating page state, or emitting signals.
#
# ?ㅽ뻾: define deterministic node-select roadmap layout math.
class_name NodeSelectLayoutPolicy
extends RefCounted

const HOTSPOT_SAFE_MARGIN := 22.0
const HOTSPOT_TAG_DEPTH := 58.0
const GRID_LEFT_RATIO := 0.378     # 좌측 정보 패널(≈0.32까지) 회피
const GRID_RIGHT_RATIO := 0.9375
const GRID_BOTTOM_RATIO := 0.757   # stage 0 (좌하단)
const GRID_TOP_RATIO := 0.169      # 마지막 stage (우상단, 보스)
const CAND_TOP_RATIO := 0.157
const CAND_BOTTOM_RATIO := 0.80
const REFERENCE_CANVAS_SIZE := Vector2(920.0, 760.0)

# ?ㅽ뻾: project a stage order onto the evenly spaced start-to-boss grid.
static func stage_grid_position(stage_order: int, max_stages: int, canvas_size: Vector2) -> Vector2:
	var max_order := maxi(1, max_stages - 1)
	var t := float(clampi(stage_order, 0, max_order)) / float(max_order)
	return Vector2(
		canvas_size.x * lerpf(GRID_LEFT_RATIO, GRID_RIGHT_RATIO, t),
		canvas_size.y * lerpf(GRID_BOTTOM_RATIO, GRID_TOP_RATIO, t)
	)

# ?ㅽ뻾: return the clamped start marker position for the current canvas.
static func start_position(canvas_size: Vector2) -> Vector2:
	return clamp_canvas_point(Vector2(canvas_size.x * GRID_LEFT_RATIO, canvas_size.y * GRID_BOTTOM_RATIO), 36.0, HOTSPOT_TAG_DEPTH, canvas_size)

# ?ㅽ뻾: return the clamped boss marker position for the current canvas.
static func boss_position(canvas_size: Vector2) -> Vector2:
	return clamp_canvas_point(Vector2(canvas_size.x * GRID_RIGHT_RATIO, canvas_size.y * GRID_TOP_RATIO), 41.0, 24.0, canvas_size)

# ?ㅽ뻾: return the unclamped boss reference point used by forecast routes.
static func boss_reference_position(canvas_size: Vector2) -> Vector2:
	return Vector2(canvas_size.x * GRID_RIGHT_RATIO, canvas_size.y * GRID_TOP_RATIO)

# ?ㅽ뻾: project current candidate route centers into an evenly spaced vertical column at the stage's grid x.
static func current_route_positions(stage_index: int, candidate_count: int, max_stages: int, canvas_size: Vector2) -> Array[Vector2]:
	var result: Array[Vector2] = []
	if candidate_count <= 0:
		return result
	var x := stage_grid_position(stage_index, max_stages, canvas_size).x
	for index in range(candidate_count):
		var t := 0.5 if candidate_count == 1 else float(index) / float(candidate_count - 1)
		var y := canvas_size.y * lerpf(CAND_TOP_RATIO, CAND_BOTTOM_RATIO, t)
		result.append(clamp_canvas_point(Vector2(x, y), 42.0, HOTSPOT_TAG_DEPTH, canvas_size))
	return result

# ?ㅽ뻾: return a point on the evenly spaced start-to-boss grid for the requested stage order.
static func spine_stage_position(stage_order: int, max_stages: int, canvas_size: Vector2) -> Vector2:
	return stage_grid_position(stage_order, max_stages, canvas_size)

# ?ㅽ뻾: return future marker positions between the current stage and boss stage.
static func future_slot_positions(stage_index: int, max_stages: int, canvas_size: Vector2) -> Array[Vector2]:
	var result: Array[Vector2] = []
	for future_stage_order in range(stage_index + 1, max_stages - 1):
		result.append(clamp_canvas_point(spine_stage_position(future_stage_order, max_stages, canvas_size), 30.0, HOTSPOT_TAG_DEPTH, canvas_size))
	return result

# ?ㅽ뻾: project a route-history entry back to the current canvas coordinate system.
static func history_position_for_entry(entry: Dictionary, max_stages: int, canvas_size: Vector2) -> Vector2:
	var stage_order := int(entry.get("stageIndex", 0))
	var radius := 36.0 if stage_order <= 0 else (41.0 if stage_order >= max_stages - 1 else 34.0)
	return clamp_canvas_point(stage_grid_position(stage_order, max_stages, canvas_size), radius, HOTSPOT_TAG_DEPTH, canvas_size)

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

# ?ㅽ뻾: project static reference-canvas decoration coordinates into the active roadmap canvas.
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
