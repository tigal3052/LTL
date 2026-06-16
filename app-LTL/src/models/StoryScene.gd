# 계약: Full VN story scene dictionaries are validated and normalized before runtime projection.
# 실행: define pure helpers for story scene content rows.
class_name StoryScene
extends RefCounted

const REQUIRED_FIELDS := ["id", "trigger", "returnPageId", "shownOnce", "sideEffectFree", "steps"]
const REQUIRED_STEP_FIELDS := ["speaker", "textKo", "textEn", "portraitPath", "side", "backgroundPath", "expression"]

# 실행: return true when a scene row has the minimum story contract.
static func is_valid(scene: Variant) -> bool:
	if not (scene is Dictionary):
		return false
	for field in REQUIRED_FIELDS:
		if not scene.has(field):
			return false
	if str(scene.get("id", "")).is_empty() or not bool(scene.get("sideEffectFree", false)):
		return false
	var steps: Array = scene.get("steps", []) if scene.get("steps", []) is Array else []
	if steps.is_empty():
		return false
	for step in steps:
		if not _step_is_valid(step):
			return false
	return true

# 실행: clone a story scene row and normalize optional runtime defaults.
static func normalized(scene: Dictionary) -> Dictionary:
	var next := scene.duplicate(true)
	next["shownOnce"] = bool(next.get("shownOnce", true))
	next["sideEffectFree"] = bool(next.get("sideEffectFree", true))
	next["returnPageId"] = str(next.get("returnPageId", "leviathan_select"))
	var normalized_steps: Array = []
	for step_value in next.get("steps", []):
		if not (step_value is Dictionary):
			continue
		var step: Dictionary = step_value.duplicate(true)
		step["side"] = _normalized_side(str(step.get("side", "left")))
		step["expression"] = str(step.get("expression", "neutral"))
		normalized_steps.append(step)
	next["steps"] = normalized_steps
	return next

# 실행: validate one VN dialogue step row.
static func _step_is_valid(step: Variant) -> bool:
	if not (step is Dictionary):
		return false
	for field in REQUIRED_STEP_FIELDS:
		if not step.has(field):
			return false
	return str(step.get("side", "")) in ["left", "right"]

# 실행: keep side values inside the two supported portrait slots.
static func _normalized_side(side: String) -> String:
	if side == "right":
		return "right"
	return "left"
