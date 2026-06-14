extends RefCounted

const ArtifactScript = preload("res://src/models/Artifact.gd")
const InventoryScript = preload("res://src/models/InventoryModel.gd")
const TooltipReadModelScript = preload("res://src/ui/read_models/TooltipReadModel.gd")
const TextCatalogScript = preload("res://src/ui/TextCatalog.gd")
const NodeSelectReadModelScript = preload("res://src/ui/read_models/NodeSelectReadModel.gd")
const RewardReadModelScript = preload("res://src/ui/read_models/RewardReadModel.gd")
const ArtifactCodexReadModelScript = preload("res://src/ui/read_models/ArtifactCodexReadModel.gd")
const PhaseLayoutPresenterScript = preload("res://src/ui/presenters/PhaseLayoutPresenter.gd")
const RewardCeremonyPolicyScript = preload("res://src/ui/presenters/RewardCeremonyPolicy.gd")
const CombatFeedbackPresenterScript = preload("res://src/ui/presenters/CombatFeedbackPresenter.gd")
const ArtifactCodexPanelUIScript = preload("res://src/ui/ArtifactCodexPanelUI.gd")
const ArtifactTooltipUIScript = preload("res://src/ui/ArtifactTooltipUI.gd")
const BackpackGridFactoryScript = preload("res://src/ui/presenters/BackpackGridFactory.gd")
const CombatSceneModelScript = preload("res://src/ui/CombatSceneModel.gd")
const InteractionCuePresenterScript = preload("res://src/ui/presenters/InteractionCuePresenter.gd")
const BackpackUIScript = preload("res://src/ui/BackpackUI.gd")
const InteractionFXScript = preload("res://src/ui/InteractionFX.gd")
const BattlefieldVFXScript = preload("res://src/ui/BattlefieldVFX.gd")
const BattlefieldUIScript = preload("res://src/ui/BattlefieldUI.gd")
const CellViewScript = preload("res://src/ui/CellView.gd")
const HazardModelScript = preload("res://src/models/HazardModel.gd")
const StatusPanelUIScript = preload("res://src/ui/StatusPanelUI.gd")
const HudReadModelScript = preload("res://src/ui/read_models/HudReadModel.gd")
const FailureReadModelScript = preload("res://src/ui/read_models/FailureReadModel.gd")
const VFXManagerScript = preload("res://src/ui/VFXManager.gd")
const MainControllerRuntimeScript = preload("res://src/MainControllerRuntime.gd")
const MainViewRuntimeScript = preload("res://src/ui/MainViewRuntime.gd")

var failures: Array[String] = []
var reward_reveal_cancel_done_calls := 0

func _result() -> Dictionary:
	return {"ok": failures.is_empty(), "errors": failures}

func _record_reward_reveal_done_for_cancel_contract() -> void:
	reward_reveal_cancel_done_calls += 1

func _ignore_reward_reveal_step_for_cancel_contract(_step: String) -> void:
	pass

func _assert(condition: bool, msg: String) -> void:
	if not condition:
		failures.append(msg)

func _assert_eq(actual: Variant, expected: Variant, msg: String) -> void:
	if actual != expected:
		failures.append("%s: expected %s, got %s" % [msg, str(expected), str(actual)])

func _assert_close(actual: float, expected: float, tolerance: float, msg: String) -> void:
	if absf(actual - expected) > tolerance:
		failures.append("%s: expected %.4f, got %.4f" % [msg, expected, actual])

func _runtime_bundle_node(main_instance: Node, page_id: String, path: String = "") -> Node:
	if main_instance == null or not main_instance.has_method("bundle_node"):
		return null
	return main_instance.call("bundle_node", page_id, path)

func _runtime_current_surface_node(main_instance: Node, path: String = "") -> Node:
	if main_instance == null or not main_instance.has_method("current_surface_node"):
		return null
	return main_instance.call("current_surface_node", path)

func _runtime_current_action_bar_node(main_instance: Node, path: String = "") -> Node:
	if main_instance == null or not main_instance.has_method("current_action_bar_node"):
		return null
	return main_instance.call("current_action_bar_node", path)
