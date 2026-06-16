# 怨꾩빟:
# - Responsibility: project selected narrative beats into compact UI-safe dictionaries.
# - Input: selected narrative beat dictionaries and locale names.
# - Output: visible/hidden narrative models for non-blocking toast or page slots.
# - Forbidden: beat selection, progress writes, telemetry, SceneTree access.
#
# ?ㅽ뻾: define narrative UI read-model projection.
class_name NarrativeReadModel
extends RefCounted

# ?ㅽ뻾: project a selected beat into locale-specific UI text.
static func project(beat: Dictionary, locale: String = "ko") -> Dictionary:
	if beat.is_empty():
		return {"visible": false}
	var text_key := _text_key_for_locale(locale)
	return {
		"visible": true,
		"beatId": str(beat.get("id", "")),
		"speaker": str(beat.get("speaker", "")),
		"text": str(beat.get(text_key, beat.get("textKo", ""))),
		"displayMode": str(beat.get("displayMode", "toast")),
		"screenId": str(beat.get("screenId", "")),
		"triggerPhase": str(beat.get("triggerPhase", "")),
		"shownOnce": bool(beat.get("shownOnce", true)),
		"skipInputAllowed": bool(beat.get("skipInputAllowed", true))
	}

# ??쎈뻬: choose the narrative data key for the active locale without embedding UI copy in code.
static func _text_key_for_locale(locale: String) -> String:
	match locale:
		"en":
			return "textEn"
	return "textKo"
