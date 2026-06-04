# 계약:
# - 책임: 새로 생성된 전장 타일만 대상으로 장애물 스폰 후보를 결정하고, 확률/허용 색상/중복 점유 방지 규칙만 담당한다.
# - 입력: CombatSimulator 스냅샷, hazard 메타데이터, seed/shift 정보.
# - 출력: {cellId, family} Dictionary Array.
# - 금지: 장애물 효과 수치 계산, UI 접근, 전투 결과 판정.
#
# 실행: define the new-tile obstacle spawn helper.
class_name SpawnNewTileObstacles
extends RefCounted

const EnergyTempoBalanceScript = preload("res://src/balance/EnergyTempoBalance.gd")

# 실행: roll obstacle spawn requests for the inserted tiles of one battlefield shift.
static func roll_shift_wave(sim, seed_val: int, shift_step: int, hazard_modifier: float) -> Array:
	var candidates := shift_inserted_cell_ids(int(sim.battlefield_rows))
	var profile := _normalized_profile(sim, hazard_modifier)
	return _roll_requests(sim, candidates, profile, seed_val, shift_step, false)

# 실행: roll obstacle spawn requests for the initial combat board seeding pass.
static func roll_initial_wave(sim, seed_val: int, hazard_modifier: float) -> Array:
	var candidates := initial_cell_ids(int(sim.battlefield_rows), int(sim.battlefield_cols))
	var profile := _normalized_profile(sim, hazard_modifier)
	return _roll_requests(sim, candidates, profile, seed_val, 0, true)

# 실행: list the newly inserted left-column tile ids for one shift wave.
static func shift_inserted_cell_ids(rows: int) -> Array:
	var ids: Array = []
	for row in range(maxi(0, rows)):
		ids.append("r%dc0" % row)
	return ids

# 실행: list every tile id on the initial board so combat-start seeding can apply a capped probability pass.
static func initial_cell_ids(rows: int, columns: int) -> Array:
	var ids: Array = []
	for row in range(maxi(0, rows)):
		for column in range(maxi(0, columns)):
			ids.append("r%dc%d" % [row, column])
	return ids

# 실행: normalize one hazard spawn profile from combat hazard metadata and node defaults.
static func _normalized_profile(sim, hazard_modifier: float) -> Dictionary:
	var hazard: Dictionary = sim.hazard_snapshot if sim.hazard_snapshot is Dictionary else {}
	var spawn: Dictionary = hazard.get("spawn", {}) if hazard.get("spawn", {}) is Dictionary else {}
	var tier := str(hazard.get("tier", "safe"))
	var allowed_families := EnergyTempoBalanceScript.normalized_colors(
		spawn.get("allowedFamilies", hazard.get("allowedFamilies", sim.obstacle_allowed_families)),
		true
	)
	if allowed_families.is_empty():
		allowed_families = EnergyTempoBalanceScript.normalized_colors([], true)
	return {
		"chance": clampf(float(spawn.get("chance", _default_spawn_chance(tier, hazard_modifier))), 0.0, 1.0),
		"maxPerShift": maxi(0, int(spawn.get("maxPerShift", _default_max_per_shift(tier, hazard_modifier)))),
		"maxInitialSpawns": maxi(0, int(spawn.get("maxInitialSpawns", _default_max_initial_spawns(tier, hazard_modifier)))),
		"allowedFamilies": allowed_families
	}

# 실행: roll deterministic spawn requests while enforcing chance, caps, and occupied-cell blocking.
static func _roll_requests(sim, candidate_cell_ids: Array, profile: Dictionary, seed_val: int, wave_step: int, initial_wave: bool) -> Array:
	var allowed_families: Array = profile.get("allowedFamilies", [])
	if allowed_families.is_empty():
		return []
	var chance := float(profile.get("chance", 0.0))
	var limit := int(profile.get("maxInitialSpawns", 0)) if initial_wave else int(profile.get("maxPerShift", 0))
	if chance <= 0.0 or limit <= 0:
		return []

	var occupied := _occupied_cells(sim)
	var ordered_candidates := _ordered_candidate_cell_ids(candidate_cell_ids, seed_val, wave_step, "initial" if initial_wave else "shift")
	var family_rotation := posmod(seed_val + wave_step + (13 if initial_wave else 7), allowed_families.size())
	var requests: Array = []
	for index in range(ordered_candidates.size()):
		if requests.size() >= limit:
			break
		var cell_id := str(ordered_candidates[index])
		if occupied.has(cell_id):
			continue
		var roll := _chance_roll(seed_val, wave_step, cell_id, initial_wave)
		if roll > chance:
			continue
		var family := str(allowed_families[(family_rotation + requests.size()) % allowed_families.size()])
		requests.append({"cellId": cell_id, "family": family})
		occupied[cell_id] = true
	return requests

# 실행: build a deterministic candidate order so capped initial spawns do not always cluster in the same cells.
static func _ordered_candidate_cell_ids(candidate_cell_ids: Array, seed_val: int, wave_step: int, mode: String) -> Array:
	var weighted: Array = []
	for cell_id in candidate_cell_ids:
		weighted.append({
			"cellId": str(cell_id),
			"score": int(hash("%d:%d:%s:%s" % [seed_val, wave_step, mode, str(cell_id)])) & 0x7fffffff
		})
	weighted.sort_custom(func(a, b):
		if int(a["score"]) == int(b["score"]):
			return str(a["cellId"]) < str(b["cellId"])
		return int(a["score"]) < int(b["score"])
	)
	var ordered: Array = []
	for entry in weighted:
		ordered.append(str(entry["cellId"]))
	return ordered

# 실행: derive a stable 0.0-1.0 chance roll per tile candidate.
static func _chance_roll(seed_val: int, wave_step: int, cell_id: String, initial_wave: bool) -> float:
	var rng := RandomNumberGenerator.new()
	rng.seed = int(hash("%d:%d:%s:%s" % [seed_val, wave_step, "initial" if initial_wave else "shift", cell_id])) & 0x7fffffff
	return rng.randf()

# 실행: collect occupied cells so one tile never receives more than one spawned obstacle.
static func _occupied_cells(sim) -> Dictionary:
	var occupied := {}
	for obstacle in sim.obstacles:
		if obstacle is Dictionary:
			occupied[str(obstacle.get("cellId", ""))] = true
	return occupied

# 실행: provide a conservative default spawn chance for nodes without an explicit override.
static func _default_spawn_chance(tier: String, hazard_modifier: float) -> float:
	var chance := 0.22 + maxf(0.0, hazard_modifier - 1.0) * 0.22
	match tier:
		"safe":
			chance = minf(chance, 0.18)
		"support":
			chance = minf(chance, 0.20)
		"hard":
			chance = maxf(chance, 0.32)
		"danger":
			chance = maxf(chance, 0.45)
		"boss":
			chance = maxf(chance, 0.60)
	return clampf(chance, 0.0, 1.0)

# 실행: provide a default per-shift spawn cap for nodes without an explicit override.
static func _default_max_per_shift(tier: String, hazard_modifier: float) -> int:
	var cap := 1
	if tier in ["hard", "danger"] or hazard_modifier >= 1.25:
		cap = 2
	if tier == "boss" or hazard_modifier >= 1.55:
		cap = 3
	return cap

# 실행: provide a default initial-board spawn cap for nodes without an explicit override.
static func _default_max_initial_spawns(tier: String, hazard_modifier: float) -> int:
	var cap := 1
	if tier == "hard" or hazard_modifier >= 1.15:
		cap = 2
	if tier == "danger" or hazard_modifier >= 1.35:
		cap = 3
	if tier == "boss":
		cap = 5
	return cap
