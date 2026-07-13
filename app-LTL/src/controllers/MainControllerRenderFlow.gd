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
const NarrativeHistoryScript = preload("res://src/models/NarrativeHistory.gd")
const SelectNarrativeBeatScript = preload("res://src/vocabulary/narrative/SelectNarrativeBeat.gd")
const MarkNarrativeSeenScript = preload("res://src/vocabulary/narrative/MarkNarrativeSeen.gd")
const NarrativeReadModelScript = preload("res://src/ui/read_models/NarrativeReadModel.gd")
const BuildNarrativeTelemetryScript = preload("res://src/vocabulary/narrative/BuildNarrativeTelemetry.gd")
const StoryHistoryScript = preload("res://src/models/StoryHistory.gd")
const SelectStorySceneScript = preload("res://src/vocabulary/story/SelectStoryScene.gd")
const StorySceneReadModelScript = preload("res://src/ui/read_models/StorySceneReadModel.gd")
const BuildStoryTelemetryScript = preload("res://src/vocabulary/story/BuildStoryTelemetry.gd")
const ReleaseContentVocabScript = preload("res://src/vocabulary/ReleaseContentVocab.gd")
const TextCatalogScript = preload("res://src/ui/TextCatalog.gd")
const RewardCeremonyPolicyScript = preload("res://src/ui/presenters/RewardCeremonyPolicy.gd")

# ?ㅽ뻾: render full state scene updates and delegate to sub UI systems.
static func render_scene(controller, scene: Dictionary) -> void:
	controller.current_scene = decorate_scene(controller, scene)
	scene = controller.current_scene
	if str(scene.get("phase", "")) == "run_complete" and not bool(scene.get("failed", false)):
		controller.campaign_progress = scene.get("progress", controller.campaign_progress).duplicate(true)
	var scene_growth_value: Variant = scene.get("growth", {})
	if str(scene.get("phase", "")) == "run_complete" and controller.growth_state != null and scene_growth_value is Dictionary:
		controller.growth_state.from_dict(scene_growth_value)
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
	controller.current_scene["battleStartHoldActive"] = controller.battle_start_hold_active
	controller.current_scene["rewardPresentationStep"] = controller.reward_presentation_step
	controller.current_scene["selectedNodeIndex"] = controller.selected_node_index
	controller.current_scene["selectedStartColor"] = controller.selected_start_color
	controller.current_scene["allowStartColorSelection"] = controller._allow_start_color_selection(controller.current_scene)
	controller.current_scene["loadoutColors"] = controller.node_map_loadout_colors_for_scene(controller.current_scene)
	sync_narrative_for_scene(controller, controller.current_scene)
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

# ??쎈뻬: select and render a side-effect-free narrative toast while recording shown-once progress separately.
static func sync_narrative_for_scene(controller, scene: Dictionary) -> void:
	var hidden_model := {"visible": false}
	scene["narrativeBlocksInput"] = false
	if controller.view == null or not controller.view.has_method("render_narrative"):
		scene["narrative"] = hidden_model
		return
	if str(scene.get("pageId", "")) == "story_scene":
		clear_narrative(controller, scene, hidden_model)
		return
	if RewardCeremonyPolicyScript.is_active_scene(scene) or controller._reward_ceremony_active():
		clear_narrative(controller, scene, hidden_model)
		return
	if controller.narrative_beats.is_empty():
		controller.narrative_beats = ReleaseContentVocabScript.load_content_bundle().get("narrativeBeats", []).duplicate(true)
	var history: Dictionary = NarrativeHistoryScript.from_progress(controller.campaign_progress)
	var beat: Dictionary = SelectNarrativeBeatScript.select(scene, controller.narrative_beats, history)
	var model: Dictionary = NarrativeReadModelScript.project(beat, TextCatalogScript.locale())
	if beat.is_empty():
		if narrative_anchor_matches(controller, scene):
			scene["narrative"] = controller.active_narrative_model.duplicate(true)
			scene["narrativeBlocksInput"] = bool(controller.active_narrative_model.get("blocksInput", false))
			controller.view.render_narrative(controller.active_narrative_model)
			sync_narrative_pause(controller, scene)
		else:
			clear_narrative(controller, scene, hidden_model)
		return
	scene["narrative"] = model.duplicate(true)
	scene["narrativeBlocksInput"] = bool(model.get("blocksInput", false))
	controller.view.render_narrative(model)
	controller.active_narrative_model = model.duplicate(true)
	controller.active_narrative_phase = str(scene.get("phase", ""))
	controller.active_narrative_stage_index = int(scene.get("stageIndex", -1))
	var beat_id := str(beat.get("id", ""))
	var screen_id := str(beat.get("screenId", ""))
	var trigger_phase := str(beat.get("triggerPhase", ""))
	var shown_once := bool(beat.get("shownOnce", true))
	controller._emit_ui_telemetry(BuildNarrativeTelemetryScript.build_selected(beat_id, screen_id, trigger_phase, shown_once))
	controller._emit_ui_telemetry(BuildNarrativeTelemetryScript.build_shown(beat_id, screen_id, trigger_phase, shown_once, 0, bool(beat.get("skipInputAllowed", true))))
	controller.campaign_progress = MarkNarrativeSeenScript.mark_seen(controller.campaign_progress, beat_id)
	scene["progress"] = controller.campaign_progress.duplicate(true)
	if controller.preview_controller != null and controller.preview_controller.run != null:
		controller.preview_controller.run.state["progress"] = controller.campaign_progress.duplicate(true)
	controller._emit_ui_telemetry(BuildNarrativeTelemetryScript.build_history_updated(beat_id, screen_id, trigger_phase, shown_once))
	sync_narrative_pause(controller, scene)

# ??쎈뻬: keep the currently visible toast stable across repeated renders of the same screen.
static func narrative_anchor_matches(controller, scene: Dictionary) -> bool:
	if not bool(controller.active_narrative_model.get("visible", false)):
		return false
	return controller.active_narrative_phase == str(scene.get("phase", "")) and controller.active_narrative_stage_index == int(scene.get("stageIndex", -1))

# ??쎈뻬: hide narrative state and clear the scene slot.
static func clear_narrative(controller, scene: Dictionary, hidden_model: Dictionary) -> void:
	controller.active_narrative_model = hidden_model.duplicate(true)
	controller.active_narrative_phase = ""
	controller.active_narrative_stage_index = -1
	scene["narrative"] = hidden_model
	scene["narrativeBlocksInput"] = false
	if controller.view != null and controller.view.has_method("render_narrative"):
		controller.view.render_narrative(hidden_model)
	sync_narrative_pause(controller, scene)

# 실행: report whether a blocking narrative currently owns gameplay input.
static func narrative_input_block_active(controller) -> bool:
	return bool(controller.active_narrative_model.get("visible", false)) and bool(controller.active_narrative_model.get("blocksInput", false))

# 실행: clear blocking narrative state after the player presses continue.
static func on_narrative_continue_requested(controller, beat_id: String) -> void:
	if not beat_id.is_empty() and beat_id != str(controller.active_narrative_model.get("beatId", "")):
		return
	controller.active_narrative_model = {"visible": false}
	controller.active_narrative_phase = ""
	controller.active_narrative_stage_index = -1
	if not controller.current_scene.is_empty():
		controller.current_scene["narrative"] = {"visible": false}
		controller.current_scene["narrativeBlocksInput"] = false
	controller._sync_battle_pause_from_overlay_visibility()
	if controller.view != null and not controller.current_scene.is_empty():
		controller.view.update_action_state(controller.current_scene, controller.show_victory_overlay)

# 실행: keep combat paused while a blocking guide narrative owns input.
static func sync_narrative_pause(controller, scene: Dictionary) -> void:
	if str(scene.get("phase", "")) == "combat" and bool(scene.get("narrativeBlocksInput", false)):
		controller._set_battle_pause_active(true)
		return
	controller._sync_battle_pause_from_overlay_visibility()

# 실행: select a full VN story scene for a safe page transition.
static func open_story_scene_for_page(controller, return_page_id: String) -> bool:
	if not controller.active_story_scene.is_empty():
		return true
	if controller.story_scenes.is_empty():
		controller.story_scenes = ReleaseContentVocabScript.load_content_bundle().get("storyScenes", []).duplicate(true)
	var state: Dictionary = controller.current_scene.duplicate(true)
	state["pageId"] = return_page_id
	var history: Dictionary = StoryHistoryScript.from_progress(controller.campaign_progress)
	var story: Dictionary = SelectStorySceneScript.select(state, controller.story_scenes, history)
	if story.is_empty():
		return false
	controller.active_story_scene = story.duplicate(true)
	controller.active_story_step_index = 0
	controller.story_return_page_id = str(story.get("returnPageId", return_page_id))
	controller.page_override_id = "story_scene"
	controller._emit_ui_telemetry(BuildStoryTelemetryScript.build_started(str(story.get("id", "")), controller.story_return_page_id, _story_step_count(story)))
	_emit_current_story_step(controller)
	return true

# 실행: progress the active full VN story scene or complete it at the last step.
static func on_story_continue_requested(controller, scene_id: String) -> void:
	if controller.active_story_scene.is_empty() or scene_id != str(controller.active_story_scene.get("id", "")):
		return
	var step_count := _story_step_count(controller.active_story_scene)
	if controller.active_story_step_index + 1 < step_count:
		controller.active_story_step_index += 1
		_emit_current_story_step(controller)
		controller._render_scene(controller.current_scene)
		return
	_complete_story_scene(controller, false)

# 실행: skip the active full VN story scene and mark it as seen.
static func on_story_skip_requested(controller, scene_id: String) -> void:
	if controller.active_story_scene.is_empty() or scene_id != str(controller.active_story_scene.get("id", "")):
		return
	_complete_story_scene(controller, true)

# 실행: finish or skip the active story scene, persist story history, and return to its owner page.
static func _complete_story_scene(controller, skipped: bool) -> void:
	var story: Dictionary = controller.active_story_scene.duplicate(true)
	var scene_id := str(story.get("id", ""))
	var return_page_id := str(story.get("returnPageId", controller.story_return_page_id))
	if skipped:
		controller._emit_ui_telemetry(BuildStoryTelemetryScript.build_skipped(scene_id, controller.active_story_step_index, return_page_id))
	else:
		controller._emit_ui_telemetry(BuildStoryTelemetryScript.build_completed(scene_id, return_page_id))
	controller.campaign_progress = StoryHistoryScript.mark_seen(controller.campaign_progress, scene_id)
	if controller.preview_controller != null and controller.preview_controller.run != null:
		controller.preview_controller.run.state["progress"] = controller.campaign_progress.duplicate(true)
	controller.active_story_scene = {}
	controller.active_story_step_index = 0
	controller.story_return_page_id = ""
	controller.page_override_id = return_page_id
	controller._render_scene(controller.current_scene)

# 실행: emit telemetry for the currently projected story step.
static func _emit_current_story_step(controller) -> void:
	if controller.active_story_scene.is_empty():
		return
	var model: Dictionary = StorySceneReadModelScript.project(controller.active_story_scene, controller.active_story_step_index, TextCatalogScript.locale())
	controller._emit_ui_telemetry(BuildStoryTelemetryScript.build_step_shown(str(model.get("sceneId", "")), int(model.get("stepIndex", 0)), str(model.get("speaker", ""))))

# 실행: count the VN steps on a selected story scene.
static func _story_step_count(story: Dictionary) -> int:
	var steps: Array = story.get("steps", []) if story.get("steps", []) is Array else []
	return steps.size()

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
	decorated["progress"] = controller.campaign_progress.duplicate(true)
	decorated["growth"] = controller.growth_state.to_dict() if controller.growth_state != null else {}
	decorated["selectedLeviathan"] = controller._selected_leviathan_data()
	decorated["selectedCharacter"] = controller._selected_character_data()
	decorated["selectedNodeContext"] = controller._selected_node_context(decorated)
	decorated["selectedNodeStartEnabled"] = controller._selected_node_start_enabled(decorated)
	decorated["nodeSelectSummary"] = str(NodeSelectReadModelScript.project(decorated, controller.selected_node_index).get("text", ""))
	decorated["pageId"] = resolve_page_id(controller, decorated)
	if str(decorated.get("pageId", "")) == "story_scene":
		decorated["storyScene"] = StorySceneReadModelScript.project(controller.active_story_scene, controller.active_story_step_index, TextCatalogScript.locale())
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
