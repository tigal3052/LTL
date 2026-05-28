# 계약:
# - 책임: formal contract validator, replay regression, snapshot boundary 검증을 한 번에 실행하는 headless test runner 진입점 계약을 제공한다.
# - 입력: test fixture set, FormalContracts public API, HeadlessMiniRun public API, ReplayProcess public API, read model public API.
# - 출력: suite pass/fail result, failing contract identifiers, deterministic verification summary를 제공하는 runner contract.
# - 금지: production rule 우회, scene reconstruction 의존, browser/node test harness 의존
#
# 실행: define a SceneTree-based headless contract runner.
extends SceneTree

# 실행: list formal scripts that must exist before the suite can run.
const REQUIRED_SCRIPTS := [
	"res://src/domain/FormalContracts.gd",
	"res://src/process/HeadlessMiniRun.gd",
	"res://src/process/CombatInputAdapter.gd",
	"res://src/process/ReplayProcess.gd",
	"res://src/ui/SceneReadModel.gd",
	"res://src/ui/CombatSceneModel.gd",
	"res://src/ui/CombatScenePreviewController.gd",
	"res://src/tools/FormalReplayRunner.gd",
	"res://src/validation/RewardValidator.gd",
	"res://src/models/RunGrowthState.gd",
	"res://src/ui/read_models/RewardReadModel.gd",
	"res://src/ui/read_models/TooltipReadModel.gd",
	"res://src/ui/read_models/NodeSelectReadModel.gd",
	"res://src/ui/presenters/PhaseLayoutPresenter.gd",
	"res://src/ui/presenters/CombatFeedbackPresenter.gd",
	"res://src/ui/presenters/HeartbeatSynth.gd",
	"res://src/ui/presenters/BackpackGridFactory.gd",
	"res://src/MainController.gd",
	"res://src/ui/SettingsPanelUI.gd",
	"res://src/ui/BackpackUI.gd",
	"res://src/ui/BattlefieldUI.gd",
	"res://src/ui/BattlefieldVFX.gd",
	"res://src/ui/StatusPanelUI.gd",
	"res://src/ui/ShopPanelUI.gd",
	"res://src/ui/ArtifactTooltipUI.gd",
	"res://src/ui/GiantTimerUI.gd",
	"res://src/ui/LogConsoleUI.gd",
	"res://src/ui/VFXManager.gd",
	"res://src/ui/MainUI.gd",
	"res://src/MainControllerRuntime.gd",
	"res://src/ui/MainViewRuntime.gd",
	# 신규 Logical Capsule 리팩토링 스크립트 목록 추가
	"res://src/models/Artifact.gd",
	"res://src/models/InventoryModel.gd",
	"res://src/models/CombatSimulator.gd",
	"res://src/models/HazardModel.gd",
	"res://src/vocabulary/CombatVocab.gd",
	"res://src/vocabulary/BackpackVocab.gd",
	"res://src/vocabulary/NodeVocab.gd",
	"res://src/vocabulary/RewardVocab.gd",
	"res://src/process/MiniRunStageScript.gd",
	"res://src/phases/PhaseReducers.gd",
	"res://src/phases/NodeSelectPhase.gd",
	"res://src/phases/CombatStartPhase.gd",
	"res://src/phases/CombatPhase.gd",
	"res://src/phases/CombatEndPhase.gd",
	"res://src/phases/RewardLootPhase.gd",
	"res://src/phases/BackpackOrganizePhase.gd",
	"res://src/phases/RunCompletePhase.gd",
	"res://src/vocabulary/backpack/PickUpFromInventory.gd",
	"res://src/vocabulary/backpack/PickUpFromRewardTray.gd",
	"res://src/vocabulary/backpack/RotateHeld.gd",
	"res://src/vocabulary/backpack/PlaceHeld.gd",
	"res://src/vocabulary/backpack/DiscardHeld.gd",
	"res://src/vocabulary/backpack/RecalculateSynergy.gd",
	"res://src/vocabulary/reward/CreateArtifactFromReward.gd",
	"res://src/vocabulary/reward/ApplyRewardEffect.gd",
	"res://src/vocabulary/reward/BuildRewardPreview.gd",
	"res://src/vocabulary/reward/BuildRewardTelemetry.gd",
	"res://src/vocabulary/progression/ApplyGrowthModifiers.gd",
	"res://src/vocabulary/combat/RecalculateQueueColors.gd",
	"res://src/vocabulary/combat/ShiftWeaknessMarkers.gd",
	"res://src/vocabulary/node/ApplyNodeModifiers.gd"
]

# 실행: list formal scene resources that must exist for the M2 app entry path.
const REQUIRED_SCENES := ["res://src/Main.tscn"]

# 실행: list scripts that must retain contract and execution comments.
const COMMENTED_SCRIPTS := [
	"res://src/domain/FormalContracts.gd",
	"res://src/process/HeadlessMiniRun.gd",
	"res://src/process/CombatInputAdapter.gd",
	"res://src/process/ReplayProcess.gd",
	"res://src/ui/SceneReadModel.gd",
	"res://src/ui/CombatSceneModel.gd",
	"res://src/ui/CombatScenePreviewController.gd",
	"res://src/tools/FormalReplayRunner.gd",
	"res://src/validation/RewardValidator.gd",
	"res://src/models/RunGrowthState.gd",
	"res://src/ui/read_models/RewardReadModel.gd",
	"res://src/ui/read_models/TooltipReadModel.gd",
	"res://src/ui/read_models/NodeSelectReadModel.gd",
	"res://src/ui/presenters/PhaseLayoutPresenter.gd",
	"res://src/ui/presenters/CombatFeedbackPresenter.gd",
	"res://src/ui/presenters/HeartbeatSynth.gd",
	"res://src/ui/presenters/BackpackGridFactory.gd",
	"res://src/MainController.gd",
	"res://src/ui/SettingsPanelUI.gd",
	"res://src/ui/BackpackUI.gd",
	"res://src/ui/BattlefieldUI.gd",
	"res://src/ui/BattlefieldVFX.gd",
	"res://src/ui/StatusPanelUI.gd",
	"res://src/ui/ShopPanelUI.gd",
	"res://src/ui/ArtifactTooltipUI.gd",
	"res://src/ui/GiantTimerUI.gd",
	"res://src/ui/LogConsoleUI.gd",
	"res://src/ui/VFXManager.gd",
	"res://src/ui/MainUI.gd",
	"res://src/MainControllerRuntime.gd",
	"res://src/ui/MainViewRuntime.gd",
	"res://src/models/Artifact.gd",
	"res://src/models/InventoryModel.gd",
	"res://src/models/CombatSimulator.gd",
	"res://src/models/HazardModel.gd",
	"res://src/vocabulary/CombatVocab.gd",
	"res://src/vocabulary/BackpackVocab.gd",
	"res://src/vocabulary/NodeVocab.gd",
	"res://src/vocabulary/RewardVocab.gd",
	"res://src/process/MiniRunStageScript.gd",
	"res://src/phases/PhaseReducers.gd",
	"res://src/phases/NodeSelectPhase.gd",
	"res://src/phases/CombatStartPhase.gd",
	"res://src/phases/CombatPhase.gd",
	"res://src/phases/CombatEndPhase.gd",
	"res://src/phases/RewardLootPhase.gd",
	"res://src/phases/BackpackOrganizePhase.gd",
	"res://src/phases/RunCompletePhase.gd",
	"res://src/vocabulary/backpack/PickUpFromInventory.gd",
	"res://src/vocabulary/backpack/PickUpFromRewardTray.gd",
	"res://src/vocabulary/backpack/RotateHeld.gd",
	"res://src/vocabulary/backpack/PlaceHeld.gd",
	"res://src/vocabulary/backpack/DiscardHeld.gd",
	"res://src/vocabulary/backpack/RecalculateSynergy.gd",
	"res://src/vocabulary/reward/CreateArtifactFromReward.gd",
	"res://src/vocabulary/reward/ApplyRewardEffect.gd",
	"res://src/vocabulary/reward/BuildRewardPreview.gd",
	"res://src/vocabulary/reward/BuildRewardTelemetry.gd",
	"res://src/vocabulary/progression/ApplyGrowthModifiers.gd",
	"res://src/vocabulary/combat/RecalculateQueueColors.gd",
	"res://src/vocabulary/combat/ShiftWeaknessMarkers.gd",
	"res://src/vocabulary/node/ApplyNodeModifiers.gd"
]

# 실행: collect deterministic suite failure labels.
var failures: Array[String] = []
var smoke_only: bool = false

# 실행: run script existence and compilation checks, comment checks, contract checks, and exit with suite status.
func _init() -> void:
	smoke_only = _is_smoke_only()
	for script_path in REQUIRED_SCRIPTS:
		_assert(ResourceLoader.exists(script_path), "missing Godot formal script: %s" % script_path)
		if ResourceLoader.exists(script_path):
			var script = load(script_path)
			_assert(script != null, "failed to compile script: %s" % script_path)
	if not smoke_only:
		for scene_path in REQUIRED_SCENES:
			_assert(ResourceLoader.exists(scene_path), "missing Godot formal scene: %s" % scene_path)
	if failures.is_empty():
		_assert_comment_harness()
		_run_contracts()
	if failures.is_empty():
		print("GODOT_CONTRACTS_OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

# 실행: verify each formal script still carries contract and execution markers.
func _assert_comment_harness() -> void:
	for script_path in COMMENTED_SCRIPTS:
		var file := FileAccess.open(script_path, FileAccess.READ)
		_assert(file != null, "comment harness cannot read script: %s" % script_path)
		if file == null:
			continue
		var text := file.get_as_text()
		_assert(text.contains("# 계약:"), "missing contract header comment: %s" % script_path)
		_assert(text.contains("# 실행:"), "missing executable sentence comments: %s" % script_path)

# 실행: load formal scripts and run validator, progression, adapter, read-model, and replay tests.
func _run_contracts() -> void:
	var FormalContractsScript = _load_script("res://src/domain/FormalContracts.gd")
	var HeadlessMiniRunScript = _load_script("res://src/process/HeadlessMiniRun.gd")
	var CombatInputAdapterScript = _load_script("res://src/process/CombatInputAdapter.gd")
	var ReplayProcessScript = _load_script("res://src/process/ReplayProcess.gd")
	var SceneReadModelScript = _load_script("res://src/ui/SceneReadModel.gd")
	var CombatSceneModelScript = _load_script("res://src/ui/CombatSceneModel.gd")
	var CombatScenePreviewControllerScript = _load_script("res://src/ui/CombatScenePreviewController.gd")
	var FormalReplayRunnerScript = _load_script("res://src/tools/FormalReplayRunner.gd")
	var MainControllerScript = _load_script("res://src/MainController.gd")
	if not failures.is_empty():
		return
	_test_contract_validators(FormalContractsScript.new())
	_test_headless_progression(HeadlessMiniRunScript)
	_test_stage_sentence_and_backpack_phase()
	_assert(MainControllerScript != null, "main controller script loads")
	_test_adapter_and_read_models(HeadlessMiniRunScript, CombatInputAdapterScript, SceneReadModelScript.new(), CombatSceneModelScript.new(), CombatScenePreviewControllerScript)
	_test_replay_paths(ReplayProcessScript.new(), FormalReplayRunnerScript.new())
	_test_reward_and_progression_contracts()
	_test_backpack_vocab_contracts()
	_test_combat_vocab_contracts()
	_test_node_routing_contracts()
	_test_ui_read_model_contracts()
	if not smoke_only:
		_test_main_scene_instantiation()

# ?ㅽ뻾: detect the smoke-only runner mode used by the compile wrapper.
func _is_smoke_only() -> bool:
	for arg in OS.get_cmdline_user_args():
		if String(arg) == "--smoke-only":
			return true
	return false

# 실행: verify validator failure surfaces for missing required fields.
func _test_contract_validators(contracts) -> void:
	var artifact_validation: Dictionary = contracts.validate_artifact_table({"artifacts": [{"name": "Pulse Drill", "shape": [[1]], "energyType": "red", "baseCooldownTicks": 4, "synergy": "pair", "keyword": "burst"}]})
	_assert_eq(artifact_validation["ok"], false, "artifact validator rejects missing id")
	_assert_eq(artifact_validation["errors"][0]["path"], "artifacts[0].id", "artifact validator reports id path")
	var node_validation: Dictionary = contracts.validate_node_table({"nodes": [_elite_node()]})
	_assert_eq(node_validation["ok"], false, "node validator rejects table without normal node")
	_assert_eq(node_validation["errors"][0]["code"], "missing_normal_node", "node validator reports missing normal node")
	var progress_validation: Dictionary = contracts.validate_progress_state({})
	_assert_eq(progress_validation["ok"], false, "progress validator rejects missing cleared ids")
	_assert_eq(progress_validation["errors"][0]["path"], "clearedLeviathanIds", "progress validator reports cleared ids path")

# 실행: verify node_select, combat, reward_loot, and next-stage transitions via logical capsules.
func _test_headless_progression(HeadlessMiniRunScript) -> void:
	var run = HeadlessMiniRunScript.new({"seed": 7, "maxStages": 2, "runCount": 1, "nodeTable": _node_table(), "tuning": {"stageScaling": {"baseHealth": 3.2}}})
	var initial: Dictionary = run.snapshot()
	_assert_eq(initial["phase"], "node_select", "headless run starts in node_select")
	_assert_eq(initial["stageIndex"], 0, "headless run starts at stage 0")
	_assert(initial["candidates"].size() >= 1, "headless run exposes candidates")
	var combat_start: Dictionary = run.select_node(0)
	_assert_eq(combat_start["phase"], "combat", "select node enters combat")
	_assert_eq(combat_start["combat"]["result"], "active", "combat starts active")
	var reward: Dictionary = run.apply_combat_input({"type": "resolve", "outcome": "clear"})
	_assert_eq(reward["phase"], "reward_loot", "clear enters reward_loot")
	var next_stage: Dictionary = run.claim_rewards()
	_assert_eq(next_stage["phase"], "node_select", "reward claim advances to node_select")
	_assert_eq(next_stage["stageIndex"], 1, "reward claim increments stage")

# ?ㅽ뻾: verify the stage sentence exposes backpack organization as its own phase boundary.
func _test_stage_sentence_and_backpack_phase() -> void:
	var MiniRunStageScript = _load_script("res://src/process/MiniRunStageScript.gd")
	var BackpackOrganizePhaseScript = _load_script("res://src/phases/BackpackOrganizePhase.gd")
	if not failures.is_empty():
		return
	_assert(MiniRunStageScript.STAGE_SENTENCE.has("backpack_organize"), "stage sentence includes backpack_organize")
	var state = {
		"seed": 1,
		"phase": "backpack_organize",
		"stageIndex": 0,
		"maxStages": 2,
		"runIndex": 0,
		"runCount": 1,
		"inventory": {},
		"progress": {"clearedLeviathanIds": []},
		"nodeTable": _normal_only_table(),
		"candidateCount": 1,
		"tuning": {},
		"pendingRewards": [],
		"held": null,
		"combat": null
	}
	var next_state = BackpackOrganizePhaseScript.reduce(state, {"type": "finish_organize"})
	_assert_eq(next_state["phase"], "node_select", "backpack organize finish enters node_select")

# 실행: verify adapter normalization, combat layout projection, and preview-controller scene flow.
func _test_adapter_and_read_models(HeadlessMiniRunScript, CombatInputAdapterScript, scene_read_model, combat_scene_model, CombatScenePreviewControllerScript) -> void:
	var run = HeadlessMiniRunScript.new({"seed": 31, "maxStages": 1, "queueCapacity": 0, "nodeTable": _normal_only_table()})
	var adapter = CombatInputAdapterScript.new(run)
	adapter.select_node(0)
	var normalized: Dictionary = adapter.normalize_input({"input": "click", "target": 0}, run.snapshot())
	_assert_eq(normalized["ok"], true, "adapter normalizes click input")
	var empty_queue: Dictionary = run.apply_combat_input(normalized["event"])
	_assert_eq(empty_queue["combat"]["result"], "empty_queue", "empty queue click reports empty_queue")
	var repaired: Dictionary = adapter.request_repair()
	_assert_eq(repaired["combat"]["repair"]["active"], true, "repair activates repair state")
	_assert_eq(repaired["combat"]["queue"]["loaded"], repaired["combat"]["queue"]["capacity"], "repair reloads queue capacity")
	var combat_run = HeadlessMiniRunScript.new({"seed": 41, "maxStages": 1, "nodeTable": _normal_only_table()})
	combat_run.select_node(0)
	combat_run.apply_combat_input({"type": "aim", "targetCellId": "r0c0", "targetColor": "red"})
	var scene: Dictionary = combat_scene_model.create(combat_run.snapshot(), {"viewportWidth": 1600, "viewportHeight": 900})
	_assert_eq(scene["layout"]["top"]["height"], 630, "combat scene uses 7:3 top layout")
	_assert_eq(scene["layout"]["bottom"]["height"], 270, "combat scene uses 7:3 bottom layout")
	_assert_eq(scene["terrain"]["cells"].size(), 30, "combat scene has 30 cells")
	_assert_eq(scene["terrain"]["cells"][0]["id"], "r0c0", "combat scene first cell id")
	_assert_eq(scene["terrain"]["cells"][29]["id"], "r2c9", "combat scene last cell id")
	_assert_eq(scene["terrain"]["cells"][0]["aimed"], true, "combat scene marks aimed cell")
	_assert_eq(scene["hud"]["queue"]["loaded"], 8, "combat scene HUD exposes queue state")
	var read_model: Dictionary = scene_read_model.create(combat_run.snapshot())
	_assert_eq(read_model["phase"], "combat", "scene read model exposes combat phase")
	var hold_fire_run = HeadlessMiniRunScript.new({"seed": 53, "maxStages": 1, "nodeTable": _normal_only_table(), "tuning": {"stageScaling": {"baseShield": 0.0, "baseHealth": 1.0}}})
	var hold_fire_adapter = CombatInputAdapterScript.new(hold_fire_run)
	hold_fire_adapter.select_node(0)
	var reward_snapshot: Dictionary = hold_fire_adapter.hold_fire("r0c0", "red", 2)
	_assert_eq(reward_snapshot["phase"], "reward_loot", "hold fire reaches reward_loot through the formal adapter path")
	var preview_controller = CombatScenePreviewControllerScript.new({"seed": 61, "maxStages": 1, "tuning": {"stageScaling": {"baseShield": 0.0, "baseHealth": 1.0}}})
	var initial_scene: Dictionary = preview_controller.get_scene()
	_assert_eq(initial_scene["phase"], "node_select", "preview controller starts at node_select")
	_assert(initial_scene["nodeSelect"]["candidates"].size() >= 1, "preview controller exposes node-select candidates")
	var combat_scene: Dictionary = preview_controller.start_combat(0)
	_assert_eq(combat_scene["phase"], "combat", "preview controller enters combat")
	var reward_scene: Dictionary = preview_controller.hold_fire("r0c0", "red", 2)
	_assert_eq(reward_scene["phase"], "reward_loot", "preview controller reaches reward_loot")
	_assert(reward_scene["reward"]["pendingRewards"].size() >= 1, "preview controller exposes pending rewards")
	var complete_scene: Dictionary = preview_controller.claim_rewards()
	_assert_eq(complete_scene["phase"], "run_complete", "preview controller reaches run_complete")

# 실행: verify direct replay payloads and promoted prototype fixture batch execution.
func _test_replay_paths(replay_process, replay_runner) -> void:
	var replay: Dictionary = replay_process.run_replay({"seed": 21, "maxStages": 1, "nodeTable": _node_table(), "inputLog": [{"type": "select_node", "index": 0}, {"type": "resolve", "outcome": "clear"}, {"type": "claim_rewards"}]})
	_assert_eq(replay["summary"]["phase"], "run_complete", "formal replay reaches run_complete")
	_assert_eq(replay["summary"]["runComplete"], true, "formal replay marks run complete")
	var fixture_replay: Dictionary = replay_process.run_replay({"seed": 20260513, "node": {"shield": 0.75, "health": 0.0, "weakness": ["red"]}, "inputLog": [{"tick": 1, "target": 0, "input": "click"}, {"tick": 2, "input": "claim_rewards"}]})
	_assert_eq(fixture_replay["summary"]["phase"], "run_complete", "prototype-style replay reaches run_complete")
	var replay_report: Dictionary = replay_runner.run_all({"fixturePaths": ["res://prototype/browser-p0-p4/tests/fixtures/input_logs/basic_clear.json", "res://prototype/browser-p0-p4/tests/fixtures/input_logs/empty_queue_repair.json"]})
	_assert_eq(replay_report["fixtureCount"], 2, "formal replay runner counts fixtures")

# 실행: load and run reward and progression unit tests.
func _test_reward_and_progression_contracts() -> void:
	var TestRewardContractClass = load("res://tests/test_reward_contract.gd")
	_assert(TestRewardContractClass != null, "test reward contract loads")
	var tester = TestRewardContractClass.new()
	var test_res = tester.run_all_tests()
	_assert(test_res["ok"], "reward unit tests passed")
	if not test_res["ok"]:
		for err in test_res["errors"]:
			failures.append("Reward test failed: %s" % err)

# ?ㅽ뻾: load and run backpack vocabulary unit tests.
func _test_backpack_vocab_contracts() -> void:
	var TestBackpackVocabClass = load("res://tests/test_backpack_vocab.gd")
	_assert(TestBackpackVocabClass != null, "test backpack vocab loads")
	if TestBackpackVocabClass == null:
		return
	var tester = TestBackpackVocabClass.new()
	var test_res = tester.run_all_tests()
	_assert(test_res["ok"], "backpack vocabulary unit tests passed")
	if not test_res["ok"]:
		for err in test_res["errors"]:
			failures.append("Backpack vocab test failed: %s" % err)

# ?ㅽ뻾: load and run combat utility vocabulary unit tests.
func _test_combat_vocab_contracts() -> void:
	var TestCombatVocabClass = load("res://tests/test_combat_vocab.gd")
	_assert(TestCombatVocabClass != null, "test combat vocab loads")
	if TestCombatVocabClass == null:
		return
	var tester = TestCombatVocabClass.new()
	var test_res = tester.run_all_tests()
	_assert(test_res["ok"], "combat vocabulary unit tests passed")
	if not test_res["ok"]:
		for err in test_res["errors"]:
			failures.append("Combat vocab test failed: %s" % err)

# ?ㅽ뻾: load and run UI read model unit tests.
func _test_node_routing_contracts() -> void:
	var TestNodeRoutingClass = load("res://tests/test_node_routing_contract.gd")
	_assert(TestNodeRoutingClass != null, "test node routing contract loads")
	if TestNodeRoutingClass == null:
		return
	var tester = TestNodeRoutingClass.new()
	var test_res = tester.run_all_tests()
	_assert(test_res["ok"], "node routing contract tests passed")
	if not test_res["ok"]:
		for err in test_res["errors"]:
			failures.append("Node routing test failed: %s" % err)

# 실행: load and run UI read model unit tests.
func _test_ui_read_model_contracts() -> void:
	var TestUiReadModelsClass = load("res://tests/test_ui_read_models.gd")
	_assert(TestUiReadModelsClass != null, "test ui read models loads")
	if TestUiReadModelsClass == null:
		return
	var tester = TestUiReadModelsClass.new()
	var test_res = tester.run_all_tests()
	_assert(test_res["ok"], "ui read model unit tests passed")
	if not test_res["ok"]:
		for err in test_res["errors"]:
			failures.append("UI read model test failed: %s" % err)

# 실행: verify that the main scene can load and instantiate without ready runtime errors.
func _test_main_scene_instantiation() -> void:
	var MainScene = load("res://src/Main.tscn")
	_assert(MainScene != null, "main scene resource loaded successfully")
	if MainScene != null:
		var main_instance = MainScene.instantiate()
		_assert(main_instance != null, "main scene instantiated successfully")
		if main_instance != null:
			root.add_child(main_instance)
			root.remove_child(main_instance)
			main_instance.queue_free()

# 실행: return a node table containing normal and elite nodes.
func _node_table() -> Dictionary:
	return {"nodes": [_normal_node(), _elite_node()]}

# 실행: return a node table containing only the normal node.
func _normal_only_table() -> Dictionary:
	return {"nodes": [_normal_node()]}

# 실행: return the required normal node fixture.
func _normal_node() -> Dictionary:
	return {"id": "normal", "label": "Normal Node", "nodeType": "normal", "riskTier": "safe", "weakness": ["red"], "pickWeight": 1, "shieldMul": 1, "healthMul": 1, "alwaysOffer": true, "rewardBias": "baseline", "recommendedBuildHint": "Any stable drill line", "difficultyModifier": 1.0, "rewardModifier": 1.0, "hazardModifier": 1.0}

# 실행: return an elite node fixture used by negative validator tests.
func _elite_node() -> Dictionary:
	return {"id": "elite", "label": "Elite Node", "nodeType": "weakness_blue", "riskTier": "medium", "weakness": ["blue"], "pickWeight": 2, "shieldMul": 1.2, "healthMul": 1.3, "rewardBias": "blue_energy", "recommendedBuildHint": "Blue shield cracking", "difficultyModifier": 1.1, "rewardModifier": 1.15, "hazardModifier": 1.0}

# 실행: append a failure label when a condition is false.
func _assert(condition: bool, label: String) -> void:
	if not condition:
		failures.append(label)

# 실행: append a deterministic equality failure label when values differ.
func _assert_eq(actual: Variant, expected: Variant, label: String) -> void:
	if actual != expected:
		failures.append("%s: expected %s, got %s" % [label, str(expected), str(actual)])

# 실행: load and validate a script resource before instantiating it.
func _load_script(script_path: String):
	var script = load(script_path)
	if script == null:
		failures.append("failed to load script: %s" % script_path)
		return null
	if not script.can_instantiate():
		failures.append("script cannot instantiate: %s" % script_path)
		return null
	return script
