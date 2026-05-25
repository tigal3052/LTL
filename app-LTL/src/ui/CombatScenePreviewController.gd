# 계약:
# - 책임: formal headless combat runtime과 scene projection을 묶어 M2 preview/main 진입점이 사용할 scene-safe 합성 상태를 제공한다.
# - 입력: preview seed, viewport size, stage count, optional node table override.
# - 출력: node_select/combat/reward_loot/run_complete를 모두 포괄하는 read-only preview scene Dictionary.
# - 금지: combat rule 재구현, SceneTree 직접 조작, prototype runtime 참조
#
# 실행: define the combat-scene preview controller class identity.
class_name CombatScenePreviewController
extends RefCounted

# 실행: preload the formal runtime, adapter, and scene projection dependencies.
const HeadlessMiniRunScript = preload("res://src/process/HeadlessMiniRun.gd")
const CombatInputAdapterScript = preload("res://src/process/CombatInputAdapter.gd")
const CombatSceneModelScript = preload("res://src/ui/CombatSceneModel.gd")
const SceneReadModelScript = preload("res://src/ui/SceneReadModel.gd")

# 실행: store preview configuration and the current formal runtime handles.
var seed: int = 53
var viewport_width: int = 1440
var viewport_height: int = 1080
var max_stages: int = 1
var node_table_override: Dictionary = {}
var init_options: Dictionary = {}
var run
var adapter
var scene_model := CombatSceneModelScript.new()
var read_model_builder := SceneReadModelScript.new()

# 실행: initialize preview configuration and bootstrap the first node-select scene.
func _init(options: Dictionary = {}) -> void:
	init_options = options.duplicate(true)
	seed = int(options.get("seed", 53))
	viewport_width = int(options.get("viewportWidth", 1440))
	viewport_height = int(options.get("viewportHeight", 1080))
	max_stages = maxi(1, int(options.get("maxStages", 1)))
	node_table_override = options.get("nodeTable", {}).duplicate(true)
	reset()

# 실행: combine the public read model and combat scene model into one preview scene surface.
func get_scene() -> Dictionary:
	var snapshot: Dictionary = run.snapshot()
	var read_model: Dictionary = read_model_builder.create(snapshot)
	var scene: Dictionary = scene_model.create(snapshot, {"viewportWidth": viewport_width, "viewportHeight": viewport_height})
	var reward_state: Dictionary = read_model.get("reward", {"pendingRewards": [], "held": null})
	scene["ok"] = read_model.get("ok", false)
	scene["diagnostics"] = read_model.get("diagnostics", []).duplicate(true)
	scene["stageIndex"] = read_model.get("stageIndex", -1)
	scene["maxStages"] = read_model.get("maxStages", -1)
	scene["runIndex"] = read_model.get("runIndex", -1)
	scene["runCount"] = read_model.get("runCount", -1)
	scene["runComplete"] = read_model.get("runComplete", false)
	scene["failed"] = read_model.get("failed", false)
	scene["failureReason"] = read_model.get("failureReason", "")
	scene["inventory"] = read_model.get("inventory", []).duplicate(true)
	scene["nodeSelect"] = {"candidates": read_model.get("candidates", []).duplicate(true)}
	scene["reward"] = reward_state.duplicate(true)
	scene["progress"] = read_model.get("progress", {}).duplicate(true)
	scene["combat"] = read_model.get("combat", null)
	return scene

# 실행: advance the preview runtime from node-select into combat.
func start_combat(index: int = 0) -> Dictionary:
	adapter.select_node(index)
	return get_scene()

# 실행: project an aim intent through the formal combat adapter and return the new scene.
func aim_cell(cell_id: String, target_color: String = "red") -> Dictionary:
	adapter.aim_at(cell_id, target_color)
	return get_scene()

# 실행: project a single-fire intent through the formal combat adapter and return the new scene.
func fire(cell_id: String, target_color: String = "red") -> Dictionary:
	adapter.fire(cell_id, target_color)
	return get_scene()

# 실행: project hold-fire ticks through the formal combat adapter and return the new scene.
func hold_fire(cell_id: String, target_color: String = "red", repeat: int = 1) -> Dictionary:
	adapter.hold_fire(cell_id, target_color, repeat)
	return get_scene()

# 실행: project repair intent through the formal combat adapter and return the new scene.
func repair() -> Dictionary:
	adapter.request_repair()
	return get_scene()

# 실행: claim rewards through the formal adapter and return the resulting scene.
func claim_rewards() -> Dictionary:
	adapter.claim_rewards()
	return get_scene()

# 실행: rebuild the formal runtime and adapter from the preview configuration.
func reset() -> Dictionary:
	var run_opts := {"seed": seed, "maxStages": max_stages, "nodeTable": _node_table()}
	if init_options.has("tuning"):
		run_opts["tuning"] = init_options["tuning"]
	if init_options.has("queueCapacity"):
		run_opts["queueCapacity"] = init_options["queueCapacity"]
	run = HeadlessMiniRunScript.new(run_opts)
	adapter = CombatInputAdapterScript.new(run)
	return get_scene()

# 실행: use an override table when provided or fall back to the deterministic preview node table.
func _node_table() -> Dictionary:
	if not node_table_override.is_empty():
		return node_table_override.duplicate(true)
	return {"nodes": [{"id": "normal", "label": "Normal Node", "weakness": ["red"], "pickWeight": 1, "shieldMul": 1, "healthMul": 1, "alwaysOffer": true}, {"id": "elite", "label": "Elite Node", "weakness": ["blue"], "pickWeight": 1, "shieldMul": 1.15, "healthMul": 1.2}]}
