# 계약:
# - 책임: MainController의 reward tray와 backpack artifact interaction 흐름을 소유한다.
# - 입력: MainController context, reward meta, backpack coordinates, discard input events.
# - 출력: controller state mutation, inventory/reward render handoff, telemetry/log updates.
# - 금지: scene-facing signal registration, combat reducer rule 변경, page id 변경.
#
# 실행: define the reward/backpack flow helper as a stateful controller delegate.
extends RefCounted

const CreateArtifactFromRewardScript = preload("res://src/vocabulary/reward/CreateArtifactFromReward.gd")
const BuildRewardTelemetryScript = preload("res://src/vocabulary/reward/BuildRewardTelemetry.gd")
const MainControllerDisplayTextScript = preload("res://src/controllers/MainControllerDisplayText.gd")

# 실행: place the currently held artifact into the backpack and apply reward effects when needed.
static func place_held_artifact_at(controller, coord: Vector2) -> bool:
	if controller.held_artifact == null:
		return false
	if controller.held_artifact.item_type == "drill":
		var has_same_color := false
		for art_id in controller.inventory.artifacts:
			var art = controller.inventory.artifacts[art_id]
			if art.item_type == "drill" and art.energy_type == controller.held_artifact.energy_type and art.id != controller.held_artifact.id:
				has_same_color = true
				break
		if has_same_color:
			controller._append_localized_log("#ff6666", "log.inventory.duplicate_drill", [MainControllerDisplayTextScript.display_color_name(str(controller.held_artifact.energy_type))])
			return false
	if not controller.inventory.can_place_artifact(controller.held_artifact, int(coord.x), int(coord.y)):
		controller._append_localized_log("#ff6666", "log.inventory.invalid_placement")
		return false

	var placed_artifact = controller.held_artifact
	var before_growth: Dictionary = controller.growth_state.to_dict()
	var placed_artifact_id := str(placed_artifact.id)
	var claimed_reward_index: int = int(controller.held_reward_index)
	controller.inventory.place_artifact(placed_artifact, int(coord.x), int(coord.y))
	controller._append_localized_log("#a3be8c", "log.inventory.artifact_placed", [MainControllerDisplayTextScript.artifact_display_name(placed_artifact)])
	controller.inspected_reward_index = -1
	controller.inspected_backpack_artifact = placed_artifact

	if controller.held_from_rewards and claimed_reward_index >= 0 and claimed_reward_index < controller.local_rewards_list.size():
		var reward_data = controller.local_rewards_list[claimed_reward_index]
		var next_s = controller.preview_controller.run.apply_combat_input({
			"type": "claim_reward_effect",
			"reward": reward_data
		})
		var after_growth: Dictionary = next_s.get("growth", {}).duplicate(true)
		controller.growth_state.from_dict(after_growth)
		controller.current_scene = next_s
		controller._append_localized_log("#a3be8c", "log.progress.reward_claimed")
		controller._emit_ui_telemetry(
			BuildRewardTelemetryScript.build_reward_selected(
				controller._selected_node_context(),
				reward_data,
				{
					"inventory_diff": {"added": [placed_artifact_id]},
					"gold_delta": int(after_growth.get("gold", 0)) - int(before_growth.get("gold", 0)),
					"xp_delta": int(after_growth.get("xp", 0)) - int(before_growth.get("xp", 0))
				}
			)
		)
		controller.local_rewards_list.remove_at(claimed_reward_index)
		sync_reward_inspection_after_removal(controller, claimed_reward_index)
		if controller.preview_controller.run != null:
			controller.preview_controller.run.state["pendingRewards"] = controller.local_rewards_list.duplicate(true)

	controller.held_reward_index = -1
	controller.held_from_rewards = false
	controller.held_artifact = null
	controller.held_inventory_origin = Vector2(-1, -1)
	controller.view.update_backpack_ghost(null)

	controller._apply_growth_modifiers()
	controller.view.render_backpack(controller.inventory)
	if controller.preview_controller.run != null:
		controller.preview_controller.run.state["inventory"] = controller.inventory.to_dict()
	controller._recalculate_queue_colors()
	controller.current_scene = controller.preview_controller.get_scene()
	controller._render_scene(controller.current_scene)
	return true

# 실행: clear the current reward/backpack drag hold.
static func clear_reward_drag_hold(controller) -> void:
	controller.held_reward_index = -1
	controller.held_from_rewards = false
	controller.held_artifact = null
	controller.held_inventory_origin = Vector2(-1, -1)
	controller.view.update_backpack_ghost(null)

# 실행: keep reward inspection index stable after reward list removal.
static func sync_reward_inspection_after_removal(controller, removed_index: int) -> void:
	if controller.inspected_reward_index == removed_index:
		controller.inspected_reward_index = -1
	elif controller.inspected_reward_index > removed_index:
		controller.inspected_reward_index -= 1

# 실행: discard the currently held reward artifact from the reward tray.
static func discard_current_held_reward(controller) -> void:
	var discarded_reward_data: Dictionary = {}
	if controller.held_reward_index >= 0 and controller.held_reward_index < controller.local_rewards_list.size():
		discarded_reward_data = controller.local_rewards_list[controller.held_reward_index].duplicate(true)
	if controller.held_reward_index >= 0 and controller.held_reward_index < controller.local_rewards_list.size():
		controller.local_rewards_list.remove_at(controller.held_reward_index)
		sync_reward_inspection_after_removal(controller, controller.held_reward_index)
		if controller.preview_controller.run != null:
			controller.preview_controller.run.state["pendingRewards"] = controller.local_rewards_list.duplicate(true)
	controller._emit_ui_telemetry({
		"event": "reward_discarded",
		"source": "reward_tray",
		"reward_id": str(discarded_reward_data.get("rewardId", "")),
		"artifact_id": str(controller.held_artifact.id),
		"artifact_name": str(controller.held_artifact.name)
	})
	clear_reward_drag_hold(controller)
	controller.current_scene = controller.preview_controller.get_scene()
	controller._render_scene(controller.current_scene)

# 실행: decide whether backpack drag rearrange is active on the reward board.
static func reward_board_drag_rearrange_active(controller) -> bool:
	return str(controller.current_scene.get("phase", "")) == "reward_loot" and not controller._reward_ceremony_active()

# 실행: return the artifact occupying a backpack coordinate.
static func artifact_at_coord(controller, coord: Vector2):
	if controller.inventory == null:
		return null
	if coord.x < 0.0 or coord.y < 0.0:
		return null
	if int(coord.y) >= controller.inventory.grid.size() or int(coord.x) >= controller.inventory.grid[int(coord.y)].size():
		return null
	var slot_id := str(controller.inventory.grid[int(coord.y)][int(coord.x)])
	if slot_id.is_empty() or not controller.inventory.artifacts.has(slot_id):
		return null
	return controller.inventory.artifacts[slot_id]

# 실행: discard the currently held inventory artifact.
static func discard_current_held_inventory_artifact(controller) -> void:
	if controller.held_artifact == null or controller.held_from_rewards:
		return
	controller._append_localized_log("#e05353", "log.inventory.discarded", [MainControllerDisplayTextScript.artifact_display_name(controller.held_artifact)])
	controller._emit_ui_telemetry({
		"event": "reward_discarded",
		"source": "backpack",
		"artifact_id": str(controller.held_artifact.id),
		"artifact_name": str(controller.held_artifact.name)
	})
	controller.inspected_backpack_artifact = null
	controller.held_inventory_origin = Vector2(-1, -1)
	controller.held_artifact = null
	controller.held_from_rewards = false
	controller.held_reward_index = -1
	controller.view.update_backpack_ghost(null)
	if controller.preview_controller.run != null:
		controller.preview_controller.run.state["inventory"] = controller.inventory.to_dict()
	controller._recalculate_queue_colors()
	controller.current_scene = controller.preview_controller.get_scene()
	controller._render_scene(controller.current_scene)

# 실행: restore a canceled inventory drag to its original coordinate.
static func restore_held_inventory_drag(controller) -> void:
	if controller.held_artifact == null or controller.held_from_rewards:
		return
	if controller.held_inventory_origin.x >= 0.0 and controller.held_inventory_origin.y >= 0.0:
		controller.inventory.place_artifact(controller.held_artifact, int(controller.held_inventory_origin.x), int(controller.held_inventory_origin.y))
	controller.inspected_backpack_artifact = controller.held_artifact
	controller.held_artifact = null
	controller.held_from_rewards = false
	controller.held_reward_index = -1
	controller.held_inventory_origin = Vector2(-1, -1)
	controller.view.update_backpack_ghost(null)
	controller.view.render_backpack(controller.inventory)
	if controller.preview_controller.run != null:
		controller.preview_controller.run.state["inventory"] = controller.inventory.to_dict()
	controller.current_scene = controller.preview_controller.get_scene()
	controller._render_scene(controller.current_scene)

# 실행: handle a backpack slot click.
static func on_backpack_slot_clicked(controller, coord: Vector2) -> void:
	if str(controller.current_scene.get("phase", "")) == "combat":
		controller._append_localized_log("#ff6666", "log.inventory.combat_locked")
		return
	if controller._reward_ceremony_active():
		return
	if reward_board_drag_rearrange_active(controller):
		if controller.held_artifact != null:
			return
		var inspected_artifact = artifact_at_coord(controller, coord)
		if inspected_artifact == null:
			return
		controller.inspected_reward_index = -1
		controller.inspected_backpack_artifact = inspected_artifact
		controller._clear_floating_tooltip()
		controller._render_rewards(controller.current_scene)
		return

	if controller.held_artifact != null:
		place_held_artifact_at(controller, coord)
		return
	var slot_artifact = artifact_at_coord(controller, coord)
	if slot_artifact != null:
		controller.held_artifact = slot_artifact
		controller.held_from_rewards = false
		controller.held_reward_index = -1
		controller.inspected_reward_index = -1
		controller.inspected_backpack_artifact = null
		controller.inventory.remove_artifact(str(slot_artifact.id))
		controller._append_localized_log("#ffd766", "log.inventory.artifact_selected", [MainControllerDisplayTextScript.artifact_display_name(controller.held_artifact)])
		controller.view.update_backpack_ghost(controller.held_artifact)
		controller.view.render_backpack(controller.inventory)
		if controller.preview_controller.run != null:
			controller.preview_controller.run.state["inventory"] = controller.inventory.to_dict()

# 실행: start a backpack drag on the reward board.
static func on_backpack_slot_drag_started(controller, coord: Vector2) -> void:
	if not reward_board_drag_rearrange_active(controller) or controller.held_artifact != null:
		return
	var dragged_artifact = artifact_at_coord(controller, coord)
	if dragged_artifact == null:
		return
	controller.inspected_reward_index = -1
	controller.inspected_backpack_artifact = dragged_artifact
	controller.held_artifact = dragged_artifact
	controller.held_from_rewards = false
	controller.held_reward_index = -1
	controller.held_inventory_origin = coord
	controller.inventory.remove_artifact(str(dragged_artifact.id))
	controller._append_localized_log("#ffd766", "log.inventory.artifact_selected", [MainControllerDisplayTextScript.artifact_display_name(controller.held_artifact)])
	controller.view.update_backpack_ghost(controller.held_artifact)
	controller.view.render_backpack(controller.inventory)
	if controller.preview_controller.run != null:
		controller.preview_controller.run.state["inventory"] = controller.inventory.to_dict()
	controller._render_rewards(controller.current_scene)

# 실행: drop a backpack drag.
static func on_backpack_slot_drop_requested(controller, _origin_coord: Vector2, coord: Vector2) -> void:
	if controller.held_artifact == null or controller.held_from_rewards:
		return
	if place_held_artifact_at(controller, coord):
		return
	restore_held_inventory_drag(controller)

# 실행: discard a dragged backpack artifact.
static func on_backpack_slot_discard_requested(controller, _origin_coord: Vector2) -> void:
	if controller.held_artifact == null or controller.held_from_rewards:
		return
	discard_current_held_inventory_artifact(controller)

# 실행: cancel a dragged backpack artifact.
static func on_backpack_slot_drag_canceled(controller, _origin_coord: Vector2) -> void:
	if controller.held_artifact == null or controller.held_from_rewards:
		return
	restore_held_inventory_drag(controller)

# 실행: show a backpack artifact tooltip.
static func on_backpack_slot_hovered(controller, coord: Vector2) -> void:
	if controller.inventory == null or controller.held_artifact != null:
		return
	var slot_id = str(controller.inventory.grid[int(coord.y)][int(coord.x)])
	if not slot_id.is_empty() and controller.inventory.artifacts.has(slot_id):
		controller.view.show_artifact_tooltip(controller.inventory.artifacts[slot_id])
	else:
		controller._clear_floating_tooltip()

# 실행: clear a backpack slot tooltip.
static func on_backpack_slot_unhovered(controller, _coord: Vector2) -> void:
	controller._clear_floating_tooltip()

# 실행: return current inventory artifacts as an array for tooltip comparison.
static func equipped_artifacts(controller) -> Array:
	var result: Array = []
	if controller.inventory == null:
		return result
	for art_id in controller.inventory.artifacts:
		result.append(controller.inventory.artifacts[art_id])
	return result

# 실행: show a reward tooltip.
static func on_reward_meta_hovered(controller, meta: Variant) -> void:
	if controller.local_rewards_list.is_empty():
		return
	var idx := int(meta)
	if idx >= 0 and idx < controller.local_rewards_list.size():
		controller.view.show_reward_tooltip(controller.local_rewards_list[idx], equipped_artifacts(controller))

# 실행: clear a reward tooltip.
static func on_reward_meta_unhovered(controller, _meta: Variant) -> void:
	controller._clear_floating_tooltip()

# 실행: cancel legacy reward drag selection.
static func on_reward_meta_drag_canceled(controller, meta: Variant) -> void:
	if not controller.held_from_rewards or controller.held_artifact == null or controller.held_reward_index != int(meta):
		return
	controller.held_artifact = null
	controller.held_from_rewards = false
	controller.held_reward_index = -1
	controller.view.update_backpack_ghost(null)
	controller._append_localized_log("#ffd766", "log.reward.selection_cleared")
	controller._render_rewards(controller.current_scene)

# 실행: select and package an artifact reward.
static func on_reward_meta_clicked(controller, meta: Variant) -> void:
	if controller._reward_ceremony_active():
		return
	var clicked_idx := int(meta)
	if controller.held_from_rewards and controller.held_reward_index == clicked_idx and controller.held_artifact != null:
		controller.held_artifact = null
		controller.held_from_rewards = false
		controller.held_reward_index = -1
		controller.view.update_backpack_ghost(null)
		controller._append_localized_log("#ffd766", "log.reward.selection_cleared")
		controller._render_rewards(controller.current_scene)
		return
	if clicked_idx < 0 or clicked_idx >= controller.local_rewards_list.size():
		return

	controller.inspected_backpack_artifact = null
	controller.held_reward_index = clicked_idx
	var item_data = controller.local_rewards_list[controller.held_reward_index]
	var create_result: Dictionary = CreateArtifactFromRewardScript.create(item_data, controller.growth_state)
	if bool(create_result.get("ok", false)):
		controller.held_artifact = create_result["artifact"]
		controller.held_from_rewards = true
		controller._append_localized_log("#ffd766", "log.reward.selection_picked", [
			MainControllerDisplayTextScript.artifact_display_name(controller.held_artifact),
			MainControllerDisplayTextScript.artifact_rarity_label(controller.held_artifact.grade)
		])
		controller._render_rewards(controller.current_scene)
		controller.view.update_backpack_ghost(controller.held_artifact)
		return

# 실행: inspect an artifact reward.
static func on_reward_meta_inspect_clicked(controller, meta: Variant) -> void:
	if controller._reward_ceremony_active():
		return
	var clicked_idx := int(meta)
	if clicked_idx < 0 or clicked_idx >= controller.local_rewards_list.size():
		return
	controller.inspected_backpack_artifact = null
	controller.inspected_reward_index = clicked_idx
	controller._render_rewards(controller.current_scene)

# 실행: start a reward-card drag.
static func on_reward_meta_drag_started_v2(controller, meta: Variant) -> void:
	if controller._reward_ceremony_active() or controller.held_artifact != null:
		return
	var dragged_idx := int(meta)
	if dragged_idx < 0 or dragged_idx >= controller.local_rewards_list.size():
		return
	controller.inspected_backpack_artifact = null
	controller.inspected_reward_index = dragged_idx
	controller.held_reward_index = dragged_idx
	var item_data = controller.local_rewards_list[controller.held_reward_index]
	var create_result: Dictionary = CreateArtifactFromRewardScript.create(item_data, controller.growth_state)
	if bool(create_result.get("ok", false)):
		controller.held_artifact = create_result["artifact"]
		controller.held_from_rewards = true
		controller._append_localized_log("#ffd766", "log.reward.selection_picked", [
			MainControllerDisplayTextScript.artifact_display_name(controller.held_artifact),
			MainControllerDisplayTextScript.artifact_rarity_label(controller.held_artifact.grade)
		])
		controller.view.update_backpack_ghost(controller.held_artifact)

# 실행: drop a reward-card artifact into the backpack.
static func on_reward_meta_drop_requested_v2(controller, meta: Variant, coord: Vector2) -> void:
	if controller._reward_ceremony_active():
		return
	if controller.held_artifact == null or not controller.held_from_rewards or controller.held_reward_index != int(meta):
		return
	if place_held_artifact_at(controller, coord):
		return
	clear_reward_drag_hold(controller)
	controller._render_rewards(controller.current_scene)

# 실행: discard a reward-card artifact.
static func on_reward_meta_discard_requested_v2(controller, meta: Variant) -> void:
	if controller._reward_ceremony_active():
		return
	if controller.held_artifact == null or not controller.held_from_rewards or controller.held_reward_index != int(meta):
		return
	discard_current_held_reward(controller)

# 실행: cancel a reward-card drag.
static func on_reward_meta_drag_canceled_v2(controller, meta: Variant) -> void:
	if controller.held_artifact == null or not controller.held_from_rewards or controller.held_reward_index != int(meta):
		return
	clear_reward_drag_hold(controller)
	controller._render_rewards(controller.current_scene)

# 실행: route discard-zone clicks to the active held artifact source.
static func on_discard_zone_input(controller, event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if controller._reward_ceremony_active():
			return
		if controller.held_artifact != null:
			if controller.held_from_rewards:
				discard_current_held_reward(controller)
			else:
				discard_current_held_inventory_artifact(controller)
