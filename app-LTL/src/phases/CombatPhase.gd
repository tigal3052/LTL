# 계약:
# - 책임: 전투 중 페이즈(combat)에서의 공격, 조준, 수리, 전투 종료 전이 등의 상태 전이를 개별 관리한다.
# - 입력: 현재 페이즈 상태 Dictionary, 처리할 이벤트 Dictionary.
# - 출력: 전이된 다음 페이즈 상태 Dictionary.
# - 금지: SceneTree 접근, 직접적인 UI 드로잉.
#
# 실행: define the CombatPhase class identity.
class_name CombatPhase
extends RefCounted

const ArtifactScript = preload("res://src/models/Artifact.gd")

# 실행: reduce combat inputs, update simulator state, and evaluate completion or failure transitions.
static func reduce(state: Dictionary, event: Dictionary) -> Dictionary:
	var next_state := state.duplicate(true)
	
	# Dictionary로부터 임시 InventoryModel 인스턴스 복원
	var inv_data = next_state.get("inventory", {})
	var inv: InventoryModel = null
	if inv_data is Dictionary:
		inv = InventoryModel.new(int(inv_data.get("width", 8)), int(inv_data.get("height", 8)))
		if inv_data.has("artifacts"):
			for art_dict in inv_data["artifacts"]:
				var art = ArtifactScript.new(art_dict)
				inv.place_artifact(art, art.x, art.y)
				
	var combat_dict: Dictionary = next_state.get("combat", {})
	if combat_dict.is_empty():
		return state

	# Dictionary로부터 임시 CombatSimulator 인스턴스 복원
	var dummy_choice := {
		"combat": {
			"shield": combat_dict.get("shield", 0.0),
			"health": combat_dict.get("health", 0.0),
			"maxShield": combat_dict.get("maxShield", combat_dict.get("shield", 0.0)),
			"maxHealth": combat_dict.get("maxHealth", combat_dict.get("health", 0.0)),
			"timeLimitTicks": combat_dict.get("timeLimitTicks", 2400),
			"weakness": []
		}
	}
	var sim := CombatVocab.prepare_combat(dummy_choice, next_state.get("tuning", {}), int(combat_dict.get("queue", {}).get("capacity", 8)))
	
	# 세부 상태 필드 복사
	sim.result = str(combat_dict.get("result", "active"))
	sim.shield = float(combat_dict.get("shield", 0.0))
	sim.health = float(combat_dict.get("health", 0.0))
	sim.max_shield = float(combat_dict.get("maxShield", sim.shield))
	sim.max_health = float(combat_dict.get("maxHealth", sim.health))
	sim.time_limit_ticks = int(combat_dict.get("timeLimitTicks", 2400))
	sim.elapsed_ticks = int(combat_dict.get("elapsedTicks", 0))
	sim.disabled = bool(combat_dict.get("disabled", false))
	
	var q_data: Dictionary = combat_dict.get("queue", {})
	sim.queue = []
	if q_data.has("items"):
		for item in q_data["items"]:
			sim.queue.append(str(item))
	sim.queue_pinned_slots = int(q_data.get("pinnedSlots", 0))
	sim.queue_empty_shots = int(q_data.get("emptyShots", 0))
	
	var p_data: Dictionary = combat_dict.get("pin", {})
	sim.pin_active = bool(p_data.get("active", false))
	sim.pin_progress = int(p_data.get("progress", 4))
	sim.pin_turns_remaining = int(p_data.get("turnsRemaining", 4))
	
	var r_data: Dictionary = combat_dict.get("repair", {})
	sim.repair_threshold = int(r_data.get("threshold", 3))
	sim.repair_progress = int(r_data.get("progress", 0))
	sim.repair_active = bool(r_data.get("active", false))
	sim.repair_available = bool(r_data.get("available", true))
	
	var a_data: Dictionary = combat_dict.get("aim", {})
	sim.aim_cell_id = a_data.get("cellId", null)
	sim.aim_target_color = a_data.get("targetColor", null)
	sim.aim_can_fire = bool(a_data.get("canFire", true))
	
	var b_data: Dictionary = combat_dict.get("battlefield", {})
	sim.battlefield_rows = int(b_data.get("rows", 3))
	sim.battlefield_cols = int(b_data.get("columns", 10))
	sim.weakness_markers = b_data.get("weaknessMarkers", []).duplicate(true)
	
	var s_data: Dictionary = combat_dict.get("summary", {})
	sim.summary_shots_fired = int(s_data.get("shots_fired", 0))
	sim.summary_shots_hit_match = int(s_data.get("shots_hit_match", 0))
	sim.summary_shots_hit_mismatch = int(s_data.get("shots_hit_mismatch", 0))
	sim.summary_shots_fired_empty_queue = int(s_data.get("shots_fired_empty_queue", 0))

	var event_type := str(event.get("type", ""))

	# 조준(aim) 처리
	if event_type == "aim":
		sim.aim_cell_id = event.get("targetCellId", null)
		sim.aim_target_color = event.get("targetColor", null)
		sim.aim_can_fire = not sim.disabled
		next_state["combat"] = sim.to_dict()
		return next_state

	# 수리(repair) 처리
	if event_type == "repair":
		CombatVocab.apply_repair(sim)
		next_state["combat"] = sim.to_dict()
		return next_state

	# 사격(fire) 또는 틱(hold_fire_tick), 직접 해결(resolve) 처리
	var is_shot := event_type in ["fire", "hold_fire_tick", "resolve"] or event.has("targetColor")
	if is_shot:
		if event_type == "resolve":
			sim.result = str(event.get("outcome", "active"))
			sim.summary_shots_fired = 1
			sim.summary_shots_hit_match = 1 if sim.result == "clear" else 0
			sim.summary_shots_hit_mismatch = 1 if sim.result == "mismatch" else 0
			sim.summary_shots_fired_empty_queue = 1 if sim.result == "empty_queue" else 0
			sim.disabled = sim.result in ["clear", "failed", "time_over"]
		else:
			var target_color = event.get("targetColor", sim.aim_target_color)
			var target_cell_id = event.get("targetCellId", sim.aim_cell_id)
			CombatVocab.fire_shot(sim, target_color, target_cell_id, next_state.get("tuning", {}).get("combat", {}), inv)

	# 시간 경과 처리 (인풋이 tick 혹은 hold_fire_tick 일 때 틱을 경과시킴)
	if event_type == "hold_fire_tick":
		CombatVocab.tick_combat(sim, 2, inv) # 기본 2틱 증가
	elif event_type == "tick":
		CombatVocab.tick_combat(sim, int(event.get("ticks", 1)), inv)

	# 방해 요소 상태 갱신
	var hazard := HazardModel.new()
	hazard.update_state(sim.health, sim.queue_empty_shots, sim.result, sim.max_health)
	
	# 최종 시뮬레이터 상태 딕셔너리로 내보내기
	var next_combat := sim.to_dict()
	next_combat["hazard"] = hazard.to_dict()
	next_state["combat"] = next_combat
	
	if inv != null:
		next_state["inventory"] = inv.to_dict()

	# 결과 판정에 따른 페이즈 전이 처리
	if sim.result == "clear":
		next_state["phase"] = "reward_loot"
		next_state["pendingRewards"] = RewardVocab.roll_stage_rewards(
			int(state.get("seed", 1)),
			int(state.get("stageIndex", 0)),
			_get_weakness_colors(sim.weakness_markers),
			state.get("tuning", {})
		)
		next_state["held"] = null
	elif sim.result in ["time_over", "failed"]:
		next_state["phase"] = "run_complete"
		next_state["failed"] = true
		next_state["runComplete"] = true
		next_state["failureReason"] = sim.result

	return next_state

# 실행: extract weakness colors from battlefield markers.
static func _get_weakness_colors(markers: Array) -> Array:
	var colors: Array = []
	for marker in markers:
		colors.append(marker.get("color", "red"))
	return colors
