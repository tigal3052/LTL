# 怨꾩빟:
# - 梨낆엫: MainController??scene decoration, page id resolution, battlefield/reward rendering handoff瑜??뚯쑀?쒕떎.
# - ?낅젰: MainController context, scene snapshot dictionaries.
# - 異쒕젰: decorated current_scene, phase logs, view render calls, reward tray render model.
# - 湲덉?: view node ownership, signal connection, domain reducer rule 蹂寃?
#
# ?ㅽ뻾: define the scene render flow helper as a stateful controller delegate.
extends RefCounted

const RewardReadModelScript = preload("res://src/ui/read_models/RewardReadModel.gd")
const NodeSelectReadModelScript = preload("res://src/ui/read_models/NodeSelectReadModel.gd")
const RewardCeremonyPolicyScript = preload("res://src/ui/presenters/RewardCeremonyPolicy.gd")

# ?ㅽ뻾: render full state scene updates and delegate to sub UI systems.
static func render_scene(controller, scene: Dictionary) -> void:
	controller.current_scene = decorate_scene(controller, scene)
	scene = controller.current_scene
	if str(scene.get("phase", "")) == "run_complete" and not bool(scene.get("failed", false)):
		controller.campaign_progress = scene.get("progress", controller.campaign_progress).duplicate(true)
	controller._sync_battle_pause_from_overlay_visibility()
	var phase := str(scene.get("phase", "unknown"))
	if phase != controller.prev_phase:
		clear_floating_tooltip(controller)
		if phase != "reward_loot":
			controller.inspected_backpack_artifact = null
			controller.held_inventory_origin = Vector2(-1, -1)
		if phase == "reward_loot" and controller.prev_phase == "combat":
			controller.show_victory_overlay = false
			var server_rewards = scene.get("reward", {}).get("pendingRewards", [])
			controller.local_rewards_list = server_rewards.duplicate(true)
			controller.inspected_reward_index = -1
			controller.inspected_backpack_artifact = null
			var ceremony_steps := RewardCeremonyPolicyScript.step_sequence()
			controller.reward_presentation_step = str(ceremony_steps[0]) if not controller.local_rewards_list.is_empty() else "tray_review"
			controller.is_reveal_vfx_running = not controller.local_rewards_list.is_empty()
			controller._append_localized_log("#ffd766", "log.phase.reward_chamber_opened")
			if controller.is_reveal_vfx_running:
				controller.call_deferred("_start_reward_ceremony")
			controller._append_localized_log("#ffd766", "log.phase.leviathan_mined")

		if phase == "node_select":
			controller.selected_node_index = -1
			controller._append_localized_log("#8fa1b3", "log.phase.node_select")
		elif phase == "combat":
			controller._append_localized_log("#8fa1b3", "log.phase.combat")
		elif phase == "reward_loot" and not controller.show_victory_overlay:
			controller._append_localized_log("#8fa1b3", "log.phase.reward_loot")
		elif phase == "run_complete":
			controller._append_localized_log("#e05353" if bool(scene.get("failed", false)) else "#a3be8c", "log.phase.run_failed" if bool(scene.get("failed", false)) else "log.phase.run_complete")
		controller.prev_phase = phase
	controller.current_scene["show_victory_overlay"] = controller.show_victory_overlay
	controller.current_scene["is_reveal_vfx_running"] = controller.is_reveal_vfx_running
	controller.current_scene["rewardPresentationStep"] = controller.reward_presentation_step
	controller.current_scene["selectedNodeIndex"] = controller.selected_node_index
	controller.current_scene["selectedStartColor"] = controller.selected_start_color
	controller.current_scene["allowStartColorSelection"] = controller._allow_start_color_selection(controller.current_scene)
	controller.current_scene["loadoutColors"] = controller.node_map_loadout_colors_for_scene(controller.current_scene)
	if phase == "combat":
		var pin_active = bool(scene.get("hud", {}).get("pin", {}).get("active", false))
		if pin_active != controller.prev_pin_active:
			controller._append_localized_log("#e05353" if pin_active else "#a3be8c", "log.pin.enabled" if pin_active else "log.pin.disabled")
			controller.prev_pin_active = pin_active
		var hazard_sev = str(scene.get("hud", {}).get("hazard", {}).get("severity", "stable"))
		if hazard_sev != controller.prev_hazard_severity:
			if hazard_sev == "active":
				controller._append_localized_log("#e05353", "log.hazard.active")
			elif hazard_sev == "critical":
				controller._append_localized_log("#e05353", "log.hazard.critical")
			elif hazard_sev == "stable":
				controller._append_localized_log("#a3be8c", "log.hazard.stable")
			controller.prev_hazard_severity = hazard_sev
	controller.view.render_scene(controller.current_scene, controller.show_victory_overlay)
	render_battlefield(controller, controller.current_scene)
	controller.view.update_action_state(controller.current_scene, controller.show_victory_overlay)
	render_rewards(controller, controller.current_scene)

# ?ㅽ뻾: delegate battlefield disabled-state rendering to the view.
static func render_battlefield(controller, scene: Dictionary) -> void:
	if not controller.is_reveal_vfx_running:
		controller.view.update_battlefield_disabled(scene, controller.disabled_tiles)

# ?ㅽ뻾: render the interactive reward looting list.
static func render_rewards(controller, scene: Dictionary) -> void:
	if str(scene.get("phase", "")) != "reward_loot":
		clear_floating_tooltip(controller)
		return
	var server_rewards = scene.get("reward", {}).get("pendingRewards", [])
	if controller.local_rewards_list.is_empty() and not server_rewards.is_empty():
		controller.local_rewards_list = server_rewards.duplicate(true)
	if controller.local_rewards_list.is_empty():
		controller.inspected_reward_index = -1
	elif controller.inspected_reward_index >= controller.local_rewards_list.size():
		controller.inspected_reward_index = controller.local_rewards_list.size() - 1
	if controller.inspected_backpack_artifact != null and controller.held_artifact != controller.inspected_backpack_artifact and (controller.inventory == null or not controller.inventory.artifacts.has(str(controller.inspected_backpack_artifact.id))):
		controller.inspected_backpack_artifact = null
	var reward_model: Dictionary = RewardReadModelScript.project_tray(
		controller.local_rewards_list,
		controller.held_reward_index,
		controller.held_artifact,
		controller.held_from_rewards,
		controller.inspected_reward_index,
		controller.inspected_backpack_artifact
	)
	clear_floating_tooltip(controller)
	controller.view.render_reward_tray(reward_model)

# ?ㅽ뻾: clear the floating tooltip when its hover source is no longer authoritative.
static func clear_floating_tooltip(controller) -> void:
	if controller.view != null and controller.view.has_method("hide_artifact_tooltip"):
		controller.view.hide_artifact_tooltip()

# ?ㅽ뻾: decorate raw scene state with controller-owned view metadata.
static func decorate_scene(controller, scene: Dictionary) -> Dictionary:
	var decorated := scene.duplicate(true)
	decorated["show_victory_overlay"] = controller.show_victory_overlay
	decorated["is_reveal_vfx_running"] = controller.is_reveal_vfx_running
	decorated["rewardPresentationStep"] = controller.reward_presentation_step
	decorated["selectedNodeIndex"] = controller.selected_node_index
	decorated["selectedStartColor"] = controller.selected_start_color
	decorated["allowStartColorSelection"] = controller._allow_start_color_selection(decorated)
	decorated["loadoutColors"] = controller.node_map_loadout_colors_for_scene(decorated)
	decorated["characterRoster"] = controller.character_roster.duplicate(true)
	decorated["leviathanRoster"] = controller.leviathan_roster.duplicate(true)
	decorated["selectedLeviathanId"] = controller.selected_leviathan_id
	decorated["selectedLeviathan"] = controller._selected_leviathan_data()
	decorated["selectedCharacter"] = controller._selected_character_data()
	decorated["selectedNodeContext"] = controller._selected_node_context(decorated)
	decorated["selectedNodeStartEnabled"] = controller._selected_node_start_enabled(decorated)
	decorated["nodeSelectSummary"] = str(NodeSelectReadModelScript.project(decorated, controller.selected_node_index).get("text", ""))
	decorated["pageId"] = resolve_page_id(controller, decorated)
	return decorated

# ?ㅽ뻾: resolve the page resource id for the decorated scene.
static func resolve_page_id(controller, scene: Dictionary) -> String:
	if not controller.page_override_id.is_empty():
		return controller.page_override_id
	var phase := str(scene.get("phase", "unknown"))
	var context: Dictionary = scene.get("selectedNodeContext", {})
	if phase == "node_select":
		return "node_select"
	if phase == "combat":
		return "boss_battle" if bool(context.get("is_boss", false)) else "battle"
	if phase == "reward_loot":
		return "boss_reward" if bool(context.get("is_boss", false)) else "reward"
	if phase == "run_complete":
		return "defeat" if bool(scene.get("failed", false)) else "clear"
	return phase
