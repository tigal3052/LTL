# 계약: StorySceneFrameBits centralizes shared story-frame metadata defaults and normalization.
# 수행: define reusable frame and step-presentation helpers for story scenes.
class_name StorySceneFrameBits
extends RefCounted

const DEFAULT_FRAME := {
	"chromeMode": "minimal",
	"chromeTitle": "",
	"dialogueVariant": "expedition_journal",
	"speakerTagVariant": "leaf_tab",
	"speakerTagText": "",
	"scrimOpacity": 0.42,
	"portraitScale": 1.0,
	"portraitOffsetX": 0.0,
	"portraitOffsetY": 0.0
}

const FRAME_REQUIRED_FIELDS := ["chromeMode", "dialogueVariant", "speakerTagVariant"]
const SUPPORTED_CHROME_MODES := ["minimal", "standard"]
const SUPPORTED_DIALOGUE_VARIANTS := ["expedition_journal"]
const SUPPORTED_SPEAKER_TAG_VARIANTS := ["leaf_tab"]

# 수행: normalize scene-level frame defaults for shared story-scene rendering.
static func normalized_scene_frame(frame_value: Variant) -> Dictionary:
	var next := DEFAULT_FRAME.duplicate(true)
	if not (frame_value is Dictionary):
		return next
	var frame: Dictionary = frame_value
	next["chromeMode"] = _one_of(str(frame.get("chromeMode", next["chromeMode"])), SUPPORTED_CHROME_MODES, str(DEFAULT_FRAME["chromeMode"]))
	next["chromeTitle"] = str(frame.get("chromeTitle", next["chromeTitle"]))
	next["dialogueVariant"] = _one_of(str(frame.get("dialogueVariant", next["dialogueVariant"])), SUPPORTED_DIALOGUE_VARIANTS, str(DEFAULT_FRAME["dialogueVariant"]))
	next["speakerTagVariant"] = _one_of(str(frame.get("speakerTagVariant", next["speakerTagVariant"])), SUPPORTED_SPEAKER_TAG_VARIANTS, str(DEFAULT_FRAME["speakerTagVariant"]))
	if frame.has("speakerTagText"):
		next["speakerTagText"] = str(frame.get("speakerTagText", ""))
	if frame.has("scrimOpacity"):
		next["scrimOpacity"] = clampf(float(frame.get("scrimOpacity", next["scrimOpacity"])), 0.0, 0.85)
	if frame.has("portraitScale"):
		next["portraitScale"] = clampf(float(frame.get("portraitScale", next["portraitScale"])), 0.70, 1.20)
	if frame.has("portraitOffsetX"):
		next["portraitOffsetX"] = float(frame.get("portraitOffsetX", next["portraitOffsetX"]))
	if frame.has("portraitOffsetY"):
		next["portraitOffsetY"] = float(frame.get("portraitOffsetY", next["portraitOffsetY"]))
	return next

# 수행: normalize per-step presentation overrides without mutating the source row.
static func normalized_step_presentation(presentation_value: Variant) -> Dictionary:
	var next: Dictionary = {}
	if not (presentation_value is Dictionary):
		return next
	var presentation: Dictionary = presentation_value
	if presentation.has("speakerTagText"):
		next["speakerTagText"] = str(presentation.get("speakerTagText", ""))
	if presentation.has("scrimOpacity"):
		next["scrimOpacity"] = clampf(float(presentation.get("scrimOpacity", DEFAULT_FRAME["scrimOpacity"])), 0.0, 0.85)
	if presentation.has("portraitScale"):
		next["portraitScale"] = clampf(float(presentation.get("portraitScale", DEFAULT_FRAME["portraitScale"])), 0.70, 1.20)
	if presentation.has("portraitOffsetX"):
		next["portraitOffsetX"] = float(presentation.get("portraitOffsetX", 0.0))
	if presentation.has("portraitOffsetY"):
		next["portraitOffsetY"] = float(presentation.get("portraitOffsetY", 0.0))
	return next

# 수행: merge scene and step metadata into one runtime-ready frame payload.
static func project_frame(scene_frame_value: Variant, presentation_value: Variant, speaker: String) -> Dictionary:
	var next := normalized_scene_frame(scene_frame_value)
	var presentation := normalized_step_presentation(presentation_value)
	for key in presentation.keys():
		next[key] = presentation[key]
	if str(next.get("speakerTagText", "")).is_empty():
		next["speakerTagText"] = speaker
	return next

# 수행: validate that a scene-level frame dictionary declares the supported shared-frame contract.
static func scene_frame_errors(frame_value: Variant) -> Array[String]:
	var errors: Array[String] = []
	if not (frame_value is Dictionary):
		errors.append("must be a dictionary")
		return errors
	var frame: Dictionary = frame_value
	for field in FRAME_REQUIRED_FIELDS:
		if not frame.has(field):
			errors.append("missing %s" % field)
	var chrome_mode := str(frame.get("chromeMode", ""))
	if not chrome_mode.is_empty() and not (chrome_mode in SUPPORTED_CHROME_MODES):
		errors.append("unsupported chromeMode %s" % chrome_mode)
	var dialogue_variant := str(frame.get("dialogueVariant", ""))
	if not dialogue_variant.is_empty() and not (dialogue_variant in SUPPORTED_DIALOGUE_VARIANTS):
		errors.append("unsupported dialogueVariant %s" % dialogue_variant)
	var speaker_tag_variant := str(frame.get("speakerTagVariant", ""))
	if not speaker_tag_variant.is_empty() and not (speaker_tag_variant in SUPPORTED_SPEAKER_TAG_VARIANTS):
		errors.append("unsupported speakerTagVariant %s" % speaker_tag_variant)
	return errors

# 수행: validate that each step declares a presentation dictionary, even when it only uses defaults.
static func step_presentation_errors(presentation_value: Variant) -> Array[String]:
	var errors: Array[String] = []
	if not (presentation_value is Dictionary):
		errors.append("must be a dictionary")
	return errors

static func _one_of(value: String, options: Array, fallback: String) -> String:
	return value if value in options else fallback
