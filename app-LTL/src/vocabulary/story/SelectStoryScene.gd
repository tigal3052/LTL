# 계약: Story scene selection is a side-effect-free projection over scene/page state and story history.
# 실행: define the pure story scene selector.
class_name SelectStoryScene
extends RefCounted

const StorySceneScript = preload("res://src/models/StoryScene.gd")

# 실행: choose the first valid unseen story scene matching the current safe transition state.
static func select(state: Dictionary, scenes: Array, history: Dictionary = {}) -> Dictionary:
	for scene_value in scenes:
		if not StorySceneScript.is_valid(scene_value):
			continue
		var scene: Dictionary = StorySceneScript.normalized(scene_value)
		var scene_id := str(scene.get("id", ""))
		if bool(scene.get("shownOnce", true)) and bool(history.get(scene_id, false)):
			continue
		if _matches(str(scene.get("trigger", "")), state):
			return scene
	return {}

# 실행: match story triggers only at non-combat safe page transitions.
static func _matches(trigger: String, state: Dictionary) -> bool:
	match trigger:
		"before_character_select":
			return str(state.get("pageId", "")) == "character_select"
		"after_character_confirm":
			return str(state.get("pageId", "")) == "leviathan_select"
	return false
