# 계약:
# - 책임: formal headless combat runtime과 scene projection을 묶어 M2 preview/main 진입점이 사용할 scene-safe 합성 상태를 제공한다.
# - 입력: preview seed, viewport size, stage count, optional node table override.
# - 출력: node_select/combat/reward_loot/run_complete를 모두 렌더링할 수 있는 read-only preview scene Dictionary.
# - 금지: combat rule 재구현, SceneTree 직접 조작, prototype runtime 참조.
#
# 실행: define the combat-scene preview controller class identity.
class_name CombatScenePreviewController
extends RefCounted

const HeadlessMiniRunScript = preload("res://src/process/HeadlessMiniRun.gd")
const CombatInputAdapterScript = preload("res://src/process/CombatInputAdapter.gd")
const CombatSceneModelScript = preload("res://src/ui/CombatSceneModel.gd")
const SceneReadModelScript = preload("res://src/ui/SceneReadModel.gd")

var seed: int = 53
var viewport_width: int = 1440
var viewport_height: int = 1080
var max_stages: int = 1
var run_count: int = 1
var start_color: String = "red"
var leviathan_id: String = "ossuary_tortoise"
var progress_state: Dictionary = {"clearedLeviathanIds": []}
var node_table_override: Dictionary = {}
var init_options: Dictionary = {}
var run
var adapter
var scene_model := CombatSceneModelScript.new()
var read_model_builder := SceneReadModelScript.new()

func _init(options: Dictionary = {}) -> void:
	init_options = options.duplicate(true)
	seed = int(options.get("seed", 53))
	viewport_width = int(options.get("viewportWidth", 1440))
	viewport_height = int(options.get("viewportHeight", 1080))
	max_stages = maxi(1, int(options.get("maxStages", 1)))
	run_count = maxi(1, int(options.get("runCount", 1)))
	start_color = str(options.get("startColor", "red"))
	leviathan_id = str(options.get("leviathanId", "ossuary_tortoise"))
	progress_state = options.get("progress", {"clearedLeviathanIds": []}).duplicate(true)
	node_table_override = options.get("nodeTable", {}).duplicate(true)
	reset()

func get_scene() -> Dictionary:
	var snapshot: Dictionary = run.snapshot()
	var read_model: Dictionary = read_model_builder.create(snapshot)
	var scene: Dictionary = scene_model.create(snapshot, {"viewportWidth": viewport_width, "viewportHeight": viewport_height})
	var reward_state: Dictionary = read_model.get("reward", {"pendingRewards": [], "held": null})
	scene["ok"] = read_model.get("ok", false)
	scene["diagnostics"] = read_model.get("diagnostics", []).duplicate(true)
	scene["stageIndex"] = read_model.get("stageIndex", -1)
	scene["maxStages"] = read_model.get("maxStages", -1)
	scene["leviathanId"] = snapshot.get("leviathanId", leviathan_id)
	scene["runIndex"] = read_model.get("runIndex", -1)
	scene["runCount"] = read_model.get("runCount", -1)
	scene["runComplete"] = read_model.get("runComplete", false)
	scene["failed"] = read_model.get("failed", false)
	scene["failureReason"] = read_model.get("failureReason", "")
	scene["inventory"] = read_model.get("inventory", []).duplicate(true)
	scene["nodeSelect"] = {
		"candidates": read_model.get("candidates", []).duplicate(true),
		"routeHistory": read_model.get("routeHistory", []).duplicate(true),
		"futureUnknownCount": int(read_model.get("futureUnknownCount", 0)),
		"isBossStage": bool(read_model.get("isBossStage", false)),
		"isFixedStartStage": bool(read_model.get("isFixedStartStage", false))
	}
	scene["routeHistory"] = scene["nodeSelect"]["routeHistory"].duplicate(true)
	scene["futureUnknownCount"] = int(scene["nodeSelect"].get("futureUnknownCount", 0))
	scene["reward"] = reward_state.duplicate(true)
	scene["growth"] = read_model.get("growth", {}).duplicate(true)
	scene["progress"] = read_model.get("progress", {}).duplicate(true)
	scene["combat"] = read_model.get("combat", null)
	return scene

func start_combat(index: int = 0) -> Dictionary:
	adapter.select_node(index)
	return get_scene()

func aim_cell(cell_id: String, target_color: String = "red") -> Dictionary:
	adapter.aim_at(cell_id, target_color)
	return get_scene()

func fire(cell_id: String, target_color: String = "red") -> Dictionary:
	adapter.fire(cell_id, target_color)
	return get_scene()

func hold_fire(cell_id: String, target_color: String = "red", repeat: int = 1) -> Dictionary:
	adapter.hold_fire(cell_id, target_color, repeat)
	return get_scene()

func claim_rewards() -> Dictionary:
	adapter.claim_rewards()
	return get_scene()

func reset() -> Dictionary:
	var run_opts := {
		"seed": seed,
		"maxStages": max_stages,
		"runCount": run_count,
		"nodeTable": _node_table(),
		"startColor": start_color,
		"leviathanId": leviathan_id,
		"progress": progress_state.duplicate(true)
	}
	if init_options.has("tuning"):
		run_opts["tuning"] = init_options["tuning"]
	if init_options.has("queueCapacity"):
		run_opts["queueCapacity"] = init_options["queueCapacity"]
	if init_options.has("growth"):
		run_opts["growth"] = init_options["growth"].duplicate(true) if init_options["growth"] is Dictionary else {}
	run = HeadlessMiniRunScript.new(run_opts)
	adapter = CombatInputAdapterScript.new(run)
	return get_scene()

func set_start_color(color: String) -> Dictionary:
	start_color = color
	return reset()

func _node_table() -> Dictionary:
	if not node_table_override.is_empty():
		return node_table_override.duplicate(true)
	var file := FileAccess.open("res://src/data/node-table.json", FileAccess.READ)
	if file != null:
		var json := JSON.new()
		if json.parse(file.get_as_text()) == OK:
			var data = json.get_data()
			if data is Dictionary and data.has("nodes"):
				return data
	return {
		"nodes": [
			{"id": "normal", "label": "Safe Scar", "nodeType": "normal", "riskTier": "safe", "weakness": [], "pickWeight": 1, "shieldMul": 1.0, "healthMul": 1.0, "alwaysOffer": true, "rewardBias": "baseline", "recommendedBuildHint": "Any stable drill line", "difficultyModifier": 1.0, "rewardModifier": 1.0, "hazardModifier": 1.0}
		]
	}
