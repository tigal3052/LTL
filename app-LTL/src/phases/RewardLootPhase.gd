# 계약:
# - 책임: 보상 획득 페이즈(reward_loot)에서의 보상 수령, 인벤토리 유물 제거 및 다음 스테이지 전이 등의 상태 전이를 개별 관리한다.
# - 입력: 현재 페이즈 상태 Dictionary, 처리할 이벤트 Dictionary.
# - 출력: 전이된 다음 페이즈 상태 Dictionary.
# - 금지: SceneTree 접근, 직접적인 UI 렌더링.
#
# 실행: define the RewardLootPhase class identity.
class_name RewardLootPhase
extends RefCounted

# 실행: reduce reward looting events and transition to next stage node_select or run completion.
static func reduce(state: Dictionary, event: Dictionary) -> Dictionary:
	var next_state := state.duplicate(true)
	var event_type := String(event.get("type", ""))

	# 보상 수령 완료 및 스테이지 전이 처리
	if event_type == "claim_rewards" or String(event.get("input", "")) == "claim_rewards":
		var stage_idx := int(next_state.get("stageIndex", 0))
		var max_stages := int(next_state.get("maxStages", 5))
		var run_idx := int(next_state.get("runIndex", 0))
		var run_count := int(next_state.get("runCount", 1))

		if stage_idx >= max_stages - 1:
			if run_idx < run_count - 1:
				# 다음 런 진입
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
				next_state["combat"] = null
				next_state["pendingRewards"] = []
				next_state["held"] = null
				return next_state
			else:
				# 런 완전 종료
				next_state["phase"] = "run_complete"
				next_state["candidates"] = []
				next_state["pendingRewards"] = []
				next_state["combat"] = null
				next_state["held"] = null
				next_state["runComplete"] = true
				
				# 진행 상태 업데이트 (클리어 레비아탄 등록)
				var progress: Dictionary = next_state.get("progress", {"clearedLeviathanIds": []}).duplicate(true)
				var cleared_ids: Array = progress.get("clearedLeviathanIds", [])
				var levi_id: String = next_state.get("leviathanId", "training_leviathan")
				if not cleared_ids.has(levi_id):
					cleared_ids.append(levi_id)
					progress["clearedLeviathanIds"] = cleared_ids
				next_state["progress"] = progress
				return next_state
		else:
			# 다음 스테이지로 전이
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

	# 인벤토리 내 유물 제거 처리
	if event_type == "remove_inventory_artifact":
		var art_id := String(event.get("artifactId", ""))
		var inventory: Array = next_state.get("inventory", [])
		if inventory.size() <= 1 and inventory.has(art_id):
			# 마지막 남은 유물 제거 제한 계약 수립
			return next_state
		var remove_index := inventory.find(art_id)
		if remove_index >= 0:
			inventory.remove_at(remove_index)
		next_state["inventory"] = inventory
		return next_state

	return next_state
