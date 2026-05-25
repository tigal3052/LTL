# 계약:
# - 책임: 전투 시뮬레이터 상태에 대한 순수 동사 함수들(준비, 사격 판정, 수리 적용, 시간 경과 등)을 제공한다.
# - 입력: CombatSimulator 인스턴스, 타겟 컬러, 타겟 셀 ID, 튜닝 설정 Dictionary.
# - 출력: 상태가 갱신된 CombatSimulator 인스턴스 또는 결과 정보.
# - 금지: SceneTree 접근, 자체 상태 보존 (static func만 가짐).
#
# 실행: define the CombatVocab static entry.
class_name CombatVocab
extends RefCounted

# 실행: prepare a new combat simulator instance.
static func prepare_combat(choice: Dictionary, tuning: Dictionary, queue_capacity: int) -> CombatSimulator:
	return CombatSimulator.new(choice, tuning, queue_capacity)

# 실행: fire a shot, consume energy from the queue, determine damage, and update health/shield.
static func fire_shot(sim: CombatSimulator, target_color: Variant, target_cell_id: Variant, tuning: Dictionary, inventory: InventoryModel = null) -> void:
	sim.summary_shots_fired += 1
	sim.aim_cell_id = target_cell_id
	sim.aim_target_color = target_color

	if sim.queue.is_empty():
		sim.result = "empty_queue"
		sim.summary_shots_fired_empty_queue += 1
		sim.queue_empty_shots += 1
		sim.repair_available = true
		return

	# 큐에서 맨 앞 에너지 pop
	var energy_color = sim.queue.pop_front()
	
	# base 대미지 테이블
	var base_shield := 0.5
	var base_hp := 1.2
	
	match energy_color:
		"red":
			base_shield = 0.5
			base_hp = 1.2
		"blue":
			base_shield = 1.5
			base_hp = 0.75
		"purple":
			base_shield = 0.75
			base_hp = 0.75
		"green":
			base_shield = 0.0
			base_hp = 1.0

	var damage_multiplier := 1.0
	if inventory != null:
		for art_id in inventory.artifacts:
			var art = inventory.artifacts[art_id]
			if art.energy_type == energy_color and art.item_type == "drill":
				damage_multiplier = art.damage
				break
				
	base_shield *= damage_multiplier
	base_hp *= damage_multiplier

	# 약점 색상 목록 수집
	var weakness_colors = []
	for marker in sim.weakness_markers:
		if not marker["color"] in weakness_colors:
			weakness_colors.append(marker["color"])

	# 취약 펄스 여부 판단
	var is_vulnerable_pulse = str(target_color) in weakness_colors

	var dmg_shield := base_shield
	var dmg_hp := base_hp
	var hit_type := "normal"

	if is_vulnerable_pulse:
		if energy_color == target_color:
			dmg_shield = base_shield * 1.5
			dmg_hp = base_hp * 1.5
			hit_type = "match"
		else:
			# mismatch: 고정 데미지가 아니며, 취약 펄스와의 색상 불일치 시 쉴드 x0.2배, HP x0.5배 감쇄 배율을 적용합니다.
			dmg_shield = base_shield * 0.2
			dmg_hp = base_hp * 0.5
			hit_type = "mismatch"

	# 쉴드/체력 피해 공식 적용
	var old_shield = sim.shield
	sim.shield = maxf(0.0, sim.shield - dmg_shield)
	
	# 쉴드가 0 이하가 된 경우에만 체력에 피해를 줌
	if sim.shield <= 0.0:
		sim.health = maxf(0.0, sim.health - dmg_hp)

	# 결과 판정
	var pin_active := false
	if sim.health <= 0.0:
		sim.result = "clear"
	else:
		sim.result = hit_type
		if hit_type == "mismatch":
			pin_active = true

	if hit_type == "match" or sim.result == "clear":
		sim.summary_shots_hit_match += 1
	else:
		sim.summary_shots_hit_mismatch += 1

	if pin_active:
		sim.queue_pinned_slots = 1
		sim.pin_active = true
		sim.pin_progress = 1
		sim.pin_turns_remaining = 1
	else:
		sim.queue_pinned_slots = 0
		sim.pin_active = false
		sim.pin_progress = 0
		sim.pin_turns_remaining = 0

	sim.repair_available = sim.queue.is_empty() or sim.queue_empty_shots > 0 or sim.result == "mismatch"
	sim.disabled = sim.result in ["clear", "failed", "time_over"]
	sim.aim_can_fire = not sim.disabled

# 실행: apply repair intent to fully reload the energy queue and reset pin/empty-shot states.
static func apply_repair(sim: CombatSimulator) -> void:
	sim.queue.clear()
	# 기본 4개 에너지를 채워 로드
	var colors = ["red", "blue", "purple", "green"]
	for i in range(min(4, sim.queue_capacity)):
		sim.queue.append(colors[i])
		
	sim.queue_pinned_slots = 0
	sim.queue_empty_shots = 0
	sim.pin_active = false
	sim.pin_progress = 0
	sim.pin_turns_remaining = 0
	sim.repair_progress = sim.repair_threshold
	sim.repair_active = true
	sim.repair_available = false
	sim.disabled = false
	sim.result = "active"
	sim.aim_can_fire = true

# 실행: update elapsed ticks, progress inventory energy generation, and flag time_over if limits are exceeded.
static func tick_combat(sim: CombatSimulator, ticks: int, inventory: InventoryModel = null) -> void:
	if sim.disabled:
		return
	sim.elapsed_ticks += ticks
	
	# Update pin progress based on elapsed time ratio (0% -> 4, 25% -> 3, 50% -> 2, 75% -> 1, 100% -> 0)
	var elapsed_ratio = float(sim.elapsed_ticks) / float(sim.time_limit_ticks)
	sim.pin_progress = int(clamp(4 - int(elapsed_ratio * 4), 0, 4))
	sim.pin_turns_remaining = sim.pin_progress
	sim.pin_active = sim.pin_progress < 4
	
	if elapsed_ticks_check(sim):
		return
		
	# 인벤토리 틱 진행 및 에너지 생산
	if inventory != null:
		for t in range(ticks):
			var generated_eneries = inventory.tick()
			for e in generated_eneries:
				if sim.queue.size() < sim.queue_capacity:
					sim.queue.append(str(e))
				else:
					# Wasted counter (optionally tracked)
					pass

# Helper to check time limits cleanly
static func elapsed_ticks_check(sim: CombatSimulator) -> bool:
	if sim.elapsed_ticks >= sim.time_limit_ticks:
		sim.result = "time_over"
		sim.disabled = true
		sim.aim_can_fire = false
		return true
	return false
