# 계약:
# - 책임: combat vocab split suite 공통 fixture와 assertion helper를 제공한다.
# - 입력: suite별 CombatSimulator/Inventory fixture 요청.
# - 출력: failures 배열에 누적되는 deterministic assertion 결과.
# - 금지: SceneTree/UI/controller 상태 접근.
extends RefCounted
const ArtifactScript = preload("res://src/models/Artifact.gd")
const InventoryScript = preload("res://src/models/InventoryModel.gd")
const CombatSimulatorScript = preload("res://src/models/CombatSimulator.gd")
const CombatVocabScript = preload("res://src/vocabulary/CombatVocab.gd")
const RecalculateQueueColorsScript = preload("res://src/vocabulary/combat/RecalculateQueueColors.gd")
const ShiftWeaknessMarkersScript = preload("res://src/vocabulary/combat/ShiftWeaknessMarkers.gd")
const CombatObstacleDefinitionsScript = preload("res://src/vocabulary/combat/CombatObstacleDefinitions.gd")
const ApplyNodeModifiersScript = preload("res://src/vocabulary/node/ApplyNodeModifiers.gd")
const HeadlessMiniRunScript = preload("res://src/process/HeadlessMiniRun.gd")
var failures: Array[String] = []
# 실행: create a deterministic drill artifact.
func _artifact(id: String, energy: String) -> Artifact:
	return ArtifactScript.new({"id": id, "name": id, "shape": [[1]], "energyType": energy, "item_type": "drill", "baseCooldownTicks": 10})
func _relic(id: String, name: String, effect_schema: Dictionary, shape: Array = [[1]]) -> Artifact:
	return ArtifactScript.new({
		"id": id,
		"name": name,
		"shape": shape,
		"energyType": "",
		"item_type": "relic",
		"baseCooldownTicks": 1,
		"damage": 0.0,
		"effect_schema": effect_schema
	})
# 실행: create a combat simulator with a single queued energy.
# 실행: create a combat simulator with a single queued energy.
func _sim_with_queue(energy: String, shield: float, health: float) -> CombatSimulator:
	var sim = CombatSimulatorScript.new({"combat": {"shield": shield, "health": health, "maxShield": shield, "maxHealth": health, "weakness": [energy]}}, {}, 8)
	sim.queue.clear()
	sim.queue.append(energy)
	sim.aim_can_fire = true
	return sim
func _sim_with_spawn_profile(spawn_profile: Dictionary, allowed_families: Array) -> CombatSimulator:
	return CombatSimulatorScript.new({
		"combat": {
			"shield": 10.0,
			"health": 10.0,
			"maxShield": 10.0,
			"maxHealth": 10.0,
			"hazard": {
				"allowedFamilies": allowed_families,
				"spawn": spawn_profile
			}
		}
	}, {}, 8)
func _obstacle(id: String, family: String, cell_id: String, overrides: Dictionary = {}) -> Dictionary:
	var obstacle := {
		"id": id,
		"family": family,
		"requiredColor": family,
		"cellId": cell_id,
		"state": "active",
		"progress": 0,
		"clearProgress": 2,
		"warningTicks": 20,
		"warningTicksRemaining": int(overrides.get("warningTicks", 20)),
		"afterglowTicksRemaining": 0,
		"pulseIntervalTicks": int(overrides.get("pulseIntervalTicks", 20)),
		"pulseTicksRemaining": int(overrides.get("pulseTicksRemaining", 20)),
		"timeCutTicks": int(overrides.get("timeCutTicks", 240)),
		"healAmount": float(overrides.get("healAmount", 1.0))
	}
	for key in overrides.keys():
		obstacle[key] = overrides[key]
	return obstacle
func _first_obstacle_feedback_event(sim: CombatSimulator) -> Dictionary:
	var battlefield: Dictionary = sim.to_dict().get("battlefield", {})
	var events: Array = battlefield.get("obstacleFeedbackEvents", [])
	_assert(not events.is_empty(), "obstacle exit failure emits feedback events")
	if events.is_empty():
		return {}
	return events[0] as Dictionary
func _source_line_count(path: String) -> int:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return -1
	var count := 0
	while not file.eof_reached():
		file.get_line()
		count += 1
	return count
# 실행: append a failure when condition is false.
# 실행: append a failure when condition is false.
func _assert(condition: bool, msg: String) -> void:
	if not condition:
		failures.append(msg)
# 실행: append a deterministic equality failure when values differ.
# 실행: append a deterministic equality failure when values differ.
func _assert_eq(actual: Variant, expected: Variant, msg: String) -> void:
	if actual != expected:
		failures.append("%s: expected %s, got %s" % [msg, str(expected), str(actual)])
