# 계약: Story scene progress history is stored separately from narrative beat and clear progress.
# 실행: define immutable story history helpers.
class_name StoryHistory
extends RefCounted

# 실행: convert progress story ids into a lookup dictionary.
static func from_progress(progress: Dictionary) -> Dictionary:
	var seen := {}
	var ids: Array = progress.get("storySeenSceneIds", []) if progress.get("storySeenSceneIds", []) is Array else []
	for scene_id in ids:
		seen[str(scene_id)] = true
	return seen

# 실행: return a copied progress dictionary with one story scene id recorded once.
static func mark_seen(progress: Dictionary, scene_id: String) -> Dictionary:
	var next := progress.duplicate(true)
	var seen_ids: Array = next.get("storySeenSceneIds", []).duplicate(true) if next.get("storySeenSceneIds", []) is Array else []
	if not seen_ids.has(scene_id):
		seen_ids.append(scene_id)
	next["storySeenSceneIds"] = seen_ids
	return next
