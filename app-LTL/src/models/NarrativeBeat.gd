# 怨꾩빟:
# - Responsibility: validate and normalize narrative beat dictionaries for side-effect-free UI projection.
# - Input: narrative beat content rows loaded from release content data.
# - Output: cloned dictionaries with stable M7 narrative metadata defaults.
# - Forbidden: SceneTree access, progress mutation, combat/reward reducer mutation.
#
# ?ㅽ뻾: define helpers for M7 narrative beat content rows.
class_name NarrativeBeat
extends RefCounted

const REQUIRED_FIELDS := ["id", "trigger", "screenId", "triggerPhase", "displayMode", "textKo", "textEn", "sideEffectFree", "skipInputAllowed"]

# ?ㅽ뻾: return true when a content row has all fields needed for runtime projection.
static func is_valid(beat: Variant) -> bool:
	if not (beat is Dictionary):
		return false
	for field in REQUIRED_FIELDS:
		if not beat.has(field):
			return false
	return not str(beat.get("id", "")).is_empty() and bool(beat.get("sideEffectFree", false))

# ?ㅽ뻾: clone a beat row and normalize optional runtime defaults.
static func normalized(beat: Dictionary) -> Dictionary:
	var next := beat.duplicate(true)
	next["shownOnce"] = bool(next.get("shownOnce", true))
	next["skipInputAllowed"] = bool(next.get("skipInputAllowed", true))
	return next
