# 怨꾩빟:
# - Responsibility: select the first side-effect-free narrative beat matching the current scene state and history.
# - Input: scene/read-model state dictionaries, release content beat rows, and seen-beat lookup dictionaries.
# - Output: a cloned matching beat dictionary or an empty dictionary.
# - Forbidden: progress writes, telemetry writes, UI rendering, reducer state mutation.
#
# ?ㅽ뻾: define pure narrative beat selection.
class_name SelectNarrativeBeat
extends RefCounted

const NarrativeBeatScript = preload("res://src/models/NarrativeBeat.gd")

# ?ㅽ뻾: choose the first valid unseen beat that matches the current scene state.
static func select(state: Dictionary, beats: Array, history: Dictionary = {}) -> Dictionary:
	for beat_value in beats:
		if not NarrativeBeatScript.is_valid(beat_value):
			continue
		var beat: Dictionary = NarrativeBeatScript.normalized(beat_value)
		var beat_id := str(beat.get("id", ""))
		if bool(beat.get("shownOnce", true)) and bool(history.get(beat_id, false)):
			continue
		if _matches(str(beat.get("trigger", "")), state):
			return beat
	return {}

# ?ㅽ뻾: match narrative trigger names against scene state without mutating it.
static func _matches(trigger: String, state: Dictionary) -> bool:
	match trigger:
		"first_run_start":
			return str(state.get("phase", "")) == "node_select" and int(state.get("stageIndex", 0)) == 0
		"first_valid_hit":
			var combat := _dict_from(state.get("combat", {}))
			var summary := _dict_from(combat.get("summary", {}))
			return int(summary.get("shots_hit_match", 0)) > 0
		"first_artifact":
			var growth := _dict_from(state.get("growth", {}))
			return str(state.get("phase", "")) == "reward_loot" and not _array_from(growth.get("artifactDiscovery", [])).is_empty()
		"first_failure":
			return str(state.get("phase", "")) == "run_complete" and bool(state.get("failed", false))
		"first_clear":
			return str(state.get("phase", "")) == "run_complete" and bool(state.get("runComplete", false)) and not bool(state.get("failed", false))
		"leviathan_clear":
			return str(state.get("phase", "")) == "run_complete" and bool(state.get("runComplete", false)) and not bool(state.get("failed", false))
	return false

# ?ㅽ뻾: coerce a variant into a dictionary for defensive trigger matching.
static func _dict_from(value: Variant) -> Dictionary:
	return value if value is Dictionary else {}

# ?ㅽ뻾: coerce a variant into an array for defensive trigger matching.
static func _array_from(value: Variant) -> Array:
	return value if value is Array else []
