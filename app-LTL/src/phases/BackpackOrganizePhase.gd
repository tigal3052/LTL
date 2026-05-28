# 계약:
# - 책임: reward_loot 이후 backpack 정리 단계에서 다음 node_select 또는 run_complete로 전이한다.
# - 입력: backpack_organize phase state와 finish_organize event.
# - 출력: 다음 phase state Dictionary.
# - 금지: UI 접근, reward roll, combat simulation.
#
# 실행: define the BackpackOrganizePhase reducer.
class_name BackpackOrganizePhase
extends RefCounted

# 실행: reduce backpack organization events into the next formal phase.
static func reduce(state: Dictionary, event: Dictionary) -> Dictionary:
	var next_state := state.duplicate(true)
	var event_type := String(event.get("type", ""))
	if event_type != "finish_organize":
		return next_state
	return _advance_after_organize(next_state)

# 실행: advance to the next stage node selection or run completion.
static func _advance_after_organize(next_state: Dictionary) -> Dictionary:
	var stage_idx := int(next_state.get("stageIndex", 0))
	var max_stages := int(next_state.get("maxStages", 5))
	var run_idx := int(next_state.get("runIndex", 0))
	var run_count := int(next_state.get("runCount", 1))
	if stage_idx >= max_stages - 1:
		if run_idx < run_count - 1:
			next_state["runIndex"] = run_idx + 1
			next_state["stageIndex"] = 0
			next_state["phase"] = "node_select"
			next_state["candidates"] = NodeVocab.generate_candidates(
				int(next_state.get("seed", 1)),
				0,
				next_state.get("nodeTable", {}),
				int(next_state.get("candidateCount", 3)),
				next_state.get("tuning", {})
			)
		else:
			next_state["phase"] = "run_complete"
			next_state["candidates"] = []
			next_state["runComplete"] = true
			var progress: Dictionary = next_state.get("progress", {"clearedLeviathanIds": []}).duplicate(true)
			var cleared_ids: Array = progress.get("clearedLeviathanIds", [])
			var levi_id: String = next_state.get("leviathanId", "training_leviathan")
			if not cleared_ids.has(levi_id):
				cleared_ids.append(levi_id)
				progress["clearedLeviathanIds"] = cleared_ids
			next_state["progress"] = progress
	else:
		next_state["stageIndex"] = stage_idx + 1
		next_state["phase"] = "node_select"
		next_state["candidates"] = NodeVocab.generate_candidates(
			int(next_state.get("seed", 1)),
			stage_idx + 1,
			next_state.get("nodeTable", {}),
			int(next_state.get("candidateCount", 3)),
			next_state.get("tuning", {})
		)
	next_state["combat"] = null
	next_state["pendingRewards"] = []
	next_state["held"] = null
	return next_state
