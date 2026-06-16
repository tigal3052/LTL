# 怨꾩빟:
# - Responsibility: build stable telemetry payloads for narrative selection, display, skip, and history updates.
# - Input: selected beat metadata and display facts.
# - Output: plain dictionaries for the controller telemetry emitter.
# - Forbidden: printing, persistence, UI mutation, or direct analytics transport.
#
# ?ㅽ뻾: define narrative telemetry payload builders.
class_name BuildNarrativeTelemetry
extends RefCounted

# ?ㅽ뻾: build a narrative selected event payload.
static func build_selected(beat_id: String, screen_id: String, trigger_phase: String, shown_once: bool) -> Dictionary:
	return _base("narrative_beat_selected", beat_id, screen_id, trigger_phase, shown_once, 0, false)

# ?ㅽ뻾: build a narrative shown event payload.
static func build_shown(beat_id: String, screen_id: String, trigger_phase: String, shown_once: bool, display_duration_ms: int, skip_input: bool) -> Dictionary:
	return _base("narrative_beat_shown", beat_id, screen_id, trigger_phase, shown_once, display_duration_ms, skip_input)

# ?ㅽ뻾: build a narrative skipped event payload.
static func build_skipped(beat_id: String, screen_id: String, trigger_phase: String, shown_once: bool, skip_input: bool) -> Dictionary:
	return _base("narrative_beat_skipped", beat_id, screen_id, trigger_phase, shown_once, 0, skip_input)

# ?ㅽ뻾: build a narrative history updated event payload.
static func build_history_updated(beat_id: String, screen_id: String, trigger_phase: String, shown_once: bool) -> Dictionary:
	return _base("narrative_history_updated", beat_id, screen_id, trigger_phase, shown_once, 0, false)

# ?ㅽ뻾: build the common narrative telemetry payload shape.
static func _base(event_name: String, beat_id: String, screen_id: String, trigger_phase: String, shown_once: bool, duration_ms: int, skip_input: bool) -> Dictionary:
	return {
		"event": event_name,
		"beat_id": beat_id,
		"screen_id": screen_id,
		"trigger_phase": trigger_phase,
		"shown_once": shown_once,
		"display_duration_ms": duration_ms,
		"skip_input": skip_input
	}
