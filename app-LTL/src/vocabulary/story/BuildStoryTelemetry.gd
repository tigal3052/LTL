# 계약: Story scene telemetry payloads use stable event names and primitive values.
# 실행: define telemetry builders for VN story page progress.
class_name BuildStoryTelemetry
extends RefCounted

# 실행: build a story scene started payload.
static func build_started(scene_id: String, return_page_id: String, step_count: int) -> Dictionary:
	return {
		"event": "story_scene_started",
		"scene_id": scene_id,
		"return_page_id": return_page_id,
		"step_count": step_count
	}

# 실행: build a story step shown payload.
static func build_step_shown(scene_id: String, step_index: int, speaker: String) -> Dictionary:
	return {
		"event": "story_step_shown",
		"scene_id": scene_id,
		"step_index": step_index,
		"speaker": speaker
	}

# 실행: build a story scene skipped payload.
static func build_skipped(scene_id: String, step_index: int, return_page_id: String) -> Dictionary:
	return {
		"event": "story_scene_skipped",
		"scene_id": scene_id,
		"step_index": step_index,
		"return_page_id": return_page_id
	}

# 실행: build a story scene completed payload.
static func build_completed(scene_id: String, return_page_id: String) -> Dictionary:
	return {
		"event": "story_scene_completed",
		"scene_id": scene_id,
		"return_page_id": return_page_id
	}
