# 계약: selected narrative beats are projected into UI-safe dictionaries.
# 실행: choose locale text, continue affordance copy, and blocking metadata.
class_name NarrativeReadModel
extends RefCounted

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
		"blocksInput": bool(beat.get("blocksInput", false)),
		"skipInputAllowed": bool(beat.get("skipInputAllowed", true)),
		"anchorPreset": str(beat.get("anchorPreset", "bottom_center")),
		"portraitPath": str(beat.get("portraitPath", "")),
		"portraitSide": str(beat.get("portraitSide", "none")),
		"visualPath": str(beat.get("visualPath", "")),
		"toastVariant": str(beat.get("toastVariant", beat.get("displayMode", "operation_log"))),
		"continuePrompt": _continue_prompt_for_locale(locale),
		"continueIcon": ">"
	}

static func _text_key_for_locale(locale: String) -> String:
	match locale:
		"en":
			return "textEn"
	return "textKo"

static func _continue_prompt_for_locale(locale: String) -> String:
	match locale:
		"en":
			return "Click or press any key to continue"
	return "진행하려면 클릭해주세요"
