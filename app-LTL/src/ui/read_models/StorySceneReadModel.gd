# 계약: StorySceneReadModel projects story-scene data into primitive UI fields without mutating run state.
# 실행: define locale-aware projection for the shared story-frame page.
class_name StorySceneReadModel
extends RefCounted

const TextCatalogScript = preload("res://src/ui/TextCatalog.gd")
const StorySceneFrameBitsScript = preload("res://src/scenes/pages/story_scene/StorySceneFrameBits.gd")
const TEXT_FIELDS := {"en": "textEn", "ko": "textKo"}

# 실행: project the selected story scene and step index into one UI-safe model.
static func project(scene: Dictionary, step_index: int = 0, locale: String = "ko") -> Dictionary:
	if scene.is_empty():
		return {"visible": false}
	var steps: Array = scene.get("steps", []) if scene.get("steps", []) is Array else []
	if steps.is_empty():
		return {"visible": false}
	var index := clampi(step_index, 0, steps.size() - 1)
	var step: Dictionary = steps[index] if steps[index] is Dictionary else {}
	var text_key := str(TEXT_FIELDS.get(locale, "textKo"))
	var speaker := str(step.get("speaker", ""))
	return {
		"visible": true,
		"sceneId": str(scene.get("id", "")),
		"returnPageId": str(scene.get("returnPageId", "")),
		"stepIndex": index,
		"stepCount": steps.size(),
		"speaker": speaker,
		"text": str(step.get(text_key, step.get("textKo", ""))),
		"portraitPath": str(step.get("portraitPath", "")),
		"side": str(step.get("side", "left")),
		"backgroundPath": str(step.get("backgroundPath", "")),
		"expression": str(step.get("expression", "neutral")),
		"frame": StorySceneFrameBitsScript.project_frame(scene.get("frame", {}), step.get("presentation", {}), speaker),
		"continueText": TextCatalogScript.t("story.continue", [], locale),
		"skipText": TextCatalogScript.t("story.skip", [], locale)
	}
