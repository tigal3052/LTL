# Contract:
# - Responsibility: centralize reward ceremony step order and interaction gate policy.
# - Input: reward presentation step or scene snapshot.
# - Output: step sequence, active-state checks, and starter loadout color-selection checks.
# - Prohibited: Control node access, reward list mutation, or overlay callback invocation.
#
# Execute: define the reward ceremony policy as a stateless presenter helper.
class_name RewardCeremonyPolicy
extends RefCounted

const STEPS := ["count_tease", "count_lock", "reveal_queue", "tray_review"]

# Execute: return a copy of the canonical ceremony step sequence.
static func step_sequence() -> Array:
	return STEPS.duplicate()

# Execute: decide whether a step blocks reward tray and backpack interaction.
static func is_active_step(step: String) -> bool:
	return step != "" and step != "tray_review"

# Execute: decide whether a scene is in an active reward ceremony step.
static func is_active_scene(scene: Dictionary) -> bool:
	return str(scene.get("phase", "")) == "reward_loot" and is_active_step(str(scene.get("rewardPresentationStep", "")))

# Execute: decide whether node-select may show starter loadout color controls.
static func allow_start_color_selection(scene: Dictionary) -> bool:
	return str(scene.get("phase", "")) == "node_select" and int(scene.get("stageIndex", 0)) == 0
