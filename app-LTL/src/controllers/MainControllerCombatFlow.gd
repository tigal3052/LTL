# 怨꾩빟:
# - 梨낆엫: MainController???꾪닾 ?대깽?? ??대㉧, hold-fire, ?쇱떆?뺤?지, terrain shift瑜??뚯쑀?쒕떎.
# - ?낅젰: MainController context, combat cell id/color, process delta, timer callbacks.
# - 異쒕젰: controller combat scene mutation, queue recalculation, VFX/log calls, pause/timer state changes.
# - 湲덉?: scene-facing signal names, combat reducer rule 蹂寃? reward/backpack ownership 蹂寃?
#
# ?ㅽ뻾: define the combat runtime flow helper as a stateful controller delegate.
extends RefCounted

const ArtifactScript = preload("res://src/models/Artifact.gd")
const InventoryModelScript = preload("res://src/models/InventoryModel.gd")
const TextCatalogScript = preload("res://src/ui/TextCatalog.gd")
const CombatFeedbackPresenterScript = preload("res://src/ui/presenters/CombatFeedbackPresenter.gd")
const EnergyTempoBalanceScript = preload("res://src/balance/EnergyTempoBalance.gd")
const RecalculateQueueColorsScript = preload("res://src/vocabulary/combat/RecalculateQueueColors.gd")
const MainControllerDisplayTextScript = preload("res://src/controllers/MainControllerDisplayText.gd")

# ?ㅽ뻾: read the active queue color from a scene snapshot.
static func active_queue_color(scene: Dictionary) -> String:
	var hud: Dictionary = scene.get("hud", {}) if scene.get("hud", {}) is Dictionary else {}
	var queue: Dictionary = hud.get("queue", {}) if hud.get("queue", {}) is Dictionary else {}
	var items: Array = queue.get("items", []) if queue.get("items", []) is Array else []
	if items.is_empty():
		return "red"
	return str(items[0].get("color", "")) if items[0] is Dictionary else str(items[0])

# ?ㅽ뻾: choose the best current target from explicit aim data or terrain weakness fallback.
static func current_target(scene: Dictionary) -> Dictionary:
	var hud: Dictionary = scene.get("hud", {}) if scene.get("hud", {}) is Dictionary else {}
	var aim: Dictionary = hud.get("aim", {}) if hud.get("aim", {}) is Dictionary else {}
	if aim.get("cellId", null) != null and aim.get("targetColor", null) != null:
		return {"cellId": aim.get("cellId", "r0c0"), "color": aim.get("targetColor", "red")}
	var terrain: Dictionary = scene.get("terrain", {}) if scene.get("terrain", {}) is Dictionary else {}
	var cells: Array = terrain.get("cells", []) if terrain.get("cells", []) is Array else []
	for cell in cells:
		if cell is Dictionary and cell.get("weakness", null) != null:
			return {"cellId": cell.get("id", "r0c0"), "color": cell.get("weakness", "red")}
	return {"cellId": "r0c0", "color": "red"}

# ?ㅽ뻾: resolve the color that should be sent to combat targeting.
static func resolve_target_color_for_interaction(cell_color_name: String, queue_color: String) -> String:
	var resolved_cell_color := str(cell_color_name)
	if resolved_cell_color.is_empty() or resolved_cell_color == "normal":
		return str(queue_color)
	return resolved_cell_color

# ?ㅽ뻾: decide whether hold-fire should continue after the current combat snapshot.
static func should_continue_hold_fire(scene: Dictionary, holding: bool) -> bool:
	if not holding:
		return false
	if str(scene.get("phase", "")) != "combat":
		return false
	if str(scene.get("feedback", {}).get("status", "")) == "empty_queue":
		return false
	var hud: Dictionary = scene.get("hud", {})
	if bool(hud.get("repair", {}).get("active", false)):
		return false
	if not bool(hud.get("aim", {}).get("canFire", true)):
		return false
	var queue_items: Array = hud.get("queue", {}).get("items", [])
	return not queue_items.is_empty()

# ?ㅽ뻾: decide whether a combat click can be accepted for a cell.
static func can_accept_combat_click(scene: Dictionary, cell_id: String, disabled: Array[String]) -> bool:
	if str(scene.get("phase", "")) != "combat":
		return false
	if cell_id in disabled:
		return false
	var hud: Dictionary = scene.get("hud", {})
	if bool(hud.get("repair", {}).get("active", false)):
		return false
	return bool(hud.get("aim", {}).get("canFire", true))

# ?ㅽ뻾: project shield and health deltas into VFX popup events.
static func build_damage_popup_events(prev_target: Dictionary, next_target: Dictionary, hit_tile_color: String, fallback_color: String = "", status: String = "") -> Array:
	if status == "empty_queue":
		return []
	var shield_damage := maxf(0.0, float(prev_target.get("shield", 0.0)) - float(next_target.get("shield", 0.0)))
	var health_damage := maxf(0.0, float(prev_target.get("health", 0.0)) - float(next_target.get("health", 0.0)))
	var resolved_color := hit_tile_color if not hit_tile_color.is_empty() and hit_tile_color != "normal" else fallback_color
	if resolved_color.is_empty():
		resolved_color = "red"
	var events: Array = []
	if shield_damage > 0.0:
		events.append({"channel": "shield", "amount": shield_damage, "color": resolved_color, "prefix": "SP"})
	if health_damage > 0.0:
		events.append({"channel": "health", "amount": health_damage, "color": resolved_color, "prefix": "HP"})
	return events

# ?ㅽ뻾: choose the hold-fire burst count from accessibility state.
static func hold_fire_burst_count(state: Dictionary = {}) -> int:
	return 4 if bool(state.get("holdFireAssist", false)) else 2

# ?ㅽ뻾: advance delayed disabled-tile releases while combat is not paused.
static func process(controller, delta: float) -> void:
	if controller.battle_pause_active:
		return
	tick_disabled_tile_release_queue(controller, delta)

# ?ㅽ뻾: handle interactive hover cell aiming.
static func on_cell_hovered(controller, cell_id: String, color_name: String) -> void:
	if controller.battle_pause_active:
		return
	if str(controller.current_scene.get("phase", "")) == "combat":
		controller._clear_floating_tooltip()
		controller.current_scene = controller.preview_controller.aim_cell(
			cell_id,
			resolve_target_color_for_interaction(color_name, active_queue_color(controller.current_scene))
		)
		controller._render_scene(controller.current_scene)

# ?ㅽ뻾: handle interactive click/fire target events, triggering decoupled view VFX.
static func on_cell_clicked(controller, cell_id: String, color_name: String) -> void:
	if controller.battle_pause_active:
		return
	controller._clear_floating_tooltip()
	if not can_accept_combat_click(controller.current_scene, cell_id, controller.disabled_tiles):
		return
	var active_color = active_queue_color(controller.current_scene)
	var target_color = resolve_target_color_for_interaction(color_name, active_color)
	var prev_target: Dictionary = controller.current_scene.get("targetPanel", {}).duplicate(true)
	var prev_shield = float(prev_target.get("shield", 0.0))
	var prev_health = float(prev_target.get("health", 0.0))
	controller.current_scene = controller.preview_controller.fire(cell_id, target_color)
	var next_target: Dictionary = controller.current_scene.get("targetPanel", {}).duplicate(true)
	var shield_damage := maxf(0.0, prev_shield - float(next_target.get("shield", 0.0)))
	var health_damage := maxf(0.0, prev_health - float(next_target.get("health", 0.0)))
	var damage := shield_damage + health_damage
	var status = str(controller.current_scene.get("feedback", {}).get("status", "active"))
	var popup_events := build_damage_popup_events(prev_target, next_target, color_name, active_color, status)
	var matched_item = null
	for art_id in controller.inventory.artifacts:
		var art = controller.inventory.artifacts[art_id]
		if str(art.energy_type) == active_color and art.item_type == "drill":
			matched_item = art
			break
	controller._append_localized_log(
		"#ffd766",
		"log.combat.item_activated",
		[
			MainControllerDisplayTextScript.artifact_display_name(matched_item) if matched_item else TextCatalogScript.t("log.inventory.unknown_drill"),
			MainControllerDisplayTextScript.display_color_name(active_color)
		]
	)
	controller._append_localized_log(
		"#66c2cd",
		"log.combat.hit_result",
		[
			cell_id.to_upper(),
			MainControllerDisplayTextScript.display_color_name(active_color),
			MainControllerDisplayTextScript.display_color_name(color_name),
			"%.1f" % damage
		]
	)
	if status == "empty_queue":
		controller._append_localized_log("#ff6666", "log.combat.empty_queue")
	if not should_continue_hold_fire(controller.current_scene, controller.is_holding):
		controller.is_holding = false
	var hit_pos = controller.view.get_cell_global_pos(cell_id)
	var start_pos = controller.view.get_extractor_global_pos()
	controller.view.trigger_resonance_beam(start_pos, hit_pos, active_color)
	controller.view.trigger_hit_particles(hit_pos, status, active_color)
	controller.view.trigger_damage_popups(popup_events)
	var shake_feedback: Dictionary = CombatFeedbackPresenterScript.project_screenshake(status)
	controller.view.trigger_screenshake(float(shake_feedback.get("duration", 0.08)), float(shake_feedback.get("magnitude", 1.0)))
	controller.disabled_tiles.append(cell_id)
	schedule_disabled_tile_release(controller, cell_id, 0.5)
	controller._render_scene(controller.current_scene)
	if status != "empty_queue" and controller.view.battlefield_ui != null and controller.view.battlefield_ui.has_method("play_miner_pose_for_cell"):
		controller.view.battlefield_ui.play_miner_pose_for_cell(cell_id)

# ?ㅽ뻾: handle hold-to-fire loop ticks.
static func trigger_hold_fire(controller) -> void:
	if controller.battle_pause_active:
		controller.is_holding = false
		return
	if not should_continue_hold_fire(controller.current_scene, controller.is_holding):
		controller.is_holding = false
		return
	on_cell_clicked(controller, controller.hold_cell_id, controller.hold_color)
	if not should_continue_hold_fire(controller.current_scene, controller.is_holding):
		controller.is_holding = false
		return
	await controller.get_tree().create_timer(0.1).timeout
	trigger_hold_fire(controller)

# ?ㅽ뻾: remember a cell cooldown before it can accept another click.
static func schedule_disabled_tile_release(controller, cell_id: String, duration: float) -> void:
	var remaining := maxf(0.0, duration)
	for entry in controller._disabled_tile_release_queue:
		if str(entry.get("cellId", "")) == cell_id:
			entry["remaining"] = remaining
			return
	controller._disabled_tile_release_queue.append({
		"cellId": cell_id,
		"remaining": remaining
	})

# ?ㅽ뻾: release cells whose short click cooldown has elapsed.
static func tick_disabled_tile_release_queue(controller, delta: float) -> void:
	var did_release := false
	for index in range(controller._disabled_tile_release_queue.size() - 1, -1, -1):
		var entry: Dictionary = controller._disabled_tile_release_queue[index]
		var next_remaining := float(entry.get("remaining", 0.0)) - maxf(0.0, delta)
		if next_remaining > 0.0:
			entry["remaining"] = next_remaining
			controller._disabled_tile_release_queue[index] = entry
			continue
		controller._disabled_tile_release_queue.remove_at(index)
		controller.disabled_tiles.erase(str(entry.get("cellId", "")))
		did_release = true
	if did_release and str(controller.current_scene.get("phase", "")) == "combat":
		controller._render_scene(controller.current_scene)

# ?ㅽ뻾: trigger a burst-style hold fire simulation.
static func on_hold_fire_pressed(controller) -> void:
	if controller.battle_pause_active:
		return
	var target := current_target(controller.current_scene)
	controller.current_scene = controller.preview_controller.hold_fire(
		str(target.get("cellId", "r0c0")),
		resolve_target_color_for_interaction(
			str(target.get("color", "")),
			active_queue_color(controller.current_scene)
		),
		hold_fire_burst_count(controller.accessibility_state)
	)
	controller._render_scene(controller.current_scene)

# ?ㅽ뻾: request repair on heated core.
static func on_repair_pressed(controller) -> void:
	if controller.battle_pause_active:
		return
	controller.current_scene = controller.preview_controller.repair()
	controller._render_scene(controller.current_scene)

# ?ㅽ뻾: cycle active item colors to fill queue.
static func recalculate_queue_colors(controller) -> void:
	var run_state = controller.preview_controller.run.state if controller.preview_controller and controller.preview_controller.run else null
	if run_state and run_state.has("combat") and run_state["combat"] != null:
		var queue_state: Dictionary = run_state["combat"].get("queue", {})
		var capacity := int(queue_state.get("capacity", EnergyTempoBalanceScript.DEFAULT_QUEUE_CAPACITY))
		var loaded_count := int(queue_state.get("items", []).size())
		if not queue_state.has("items"):
			loaded_count = EnergyTempoBalanceScript.initial_queue_loaded_count(capacity)
		var queue_result: Dictionary = RecalculateQueueColorsScript.recalculate(controller.inventory, capacity, loaded_count)
		run_state["combat"]["queue"]["items"] = queue_result.get("items", [])

# ?ㅽ뻾: synchronize combat pause state when the overlay visibility changes.
static func on_combat_overlay_pause_visibility_changed(controller, _active: bool) -> void:
	sync_battle_pause_from_overlay_visibility(controller)

# ?ㅽ뻾: derive combat pause from the current overlay and phase.
static func sync_battle_pause_from_overlay_visibility(controller) -> void:
	var overlay_visible := false
	if controller.view != null and controller.view.has_method("is_combat_pause_overlay_visible"):
		overlay_visible = bool(controller.view.is_combat_pause_overlay_visible())
	set_battle_pause_active(controller, overlay_visible and str(controller.current_scene.get("phase", "")) == "combat")

# ?ㅽ뻾: apply the combat pause state to timers, holds, and view state.
static func set_battle_pause_active(controller, active: bool) -> void:
	if controller.battle_pause_active == active:
		return
	controller.battle_pause_active = active
	if active:
		controller.is_holding = false
		set_shift_timer_paused(controller, true)
	else:
		set_shift_timer_paused(controller, false)
	if controller.view != null and controller.view.has_method("set_battle_pause_active"):
		controller.view.set_battle_pause_active(active)

# ?ㅽ뻾: pause or resume the terrain shift timer without changing its steady interval.
static func set_shift_timer_paused(controller, paused: bool) -> void:
	if controller.shift_timer == null:
		return
	if paused:
		controller.shift_timer.paused = true
		return
	controller.shift_timer.paused = false
	if controller.shift_timer.is_stopped():
		controller.shift_timer.wait_time = controller.TERRAIN_SHIFT_SECONDS
		controller.shift_timer.start(controller.TERRAIN_SHIFT_SECONDS)

# ?ㅽ뻾: setup conveyor-belt shift timer.
static func setup_shift_timer(controller) -> void:
	controller.shift_timer = Timer.new()
	controller.shift_timer.wait_time = controller.TERRAIN_SHIFT_SECONDS
	controller.shift_timer.autostart = true
	controller.shift_timer.timeout.connect(controller._on_shift_timer_timeout)
	controller.add_child(controller.shift_timer)

# ?ㅽ뻾: shift weaknesses left-to-right on timeout.
static func on_shift_timer_timeout(controller) -> void:
	if controller.battle_pause_active:
		return
	if str(controller.current_scene.get("phase", "")) != "combat":
		return
	var colors := EnergyTempoBalanceScript.terrain_color_palette()
	controller.weakness_shift_step += 1
	controller.current_scene = controller.preview_controller.run.apply_combat_input({
		"type": "shift_battlefield",
		"ticks": controller.TERRAIN_SHIFT_TICKS,
		"shiftSeed": int(controller.preview_controller.run.state.get("seed", randi())),
		"shiftStep": controller.weakness_shift_step,
		"colors": colors
	})
	if str(controller.current_scene.get("phase", "")) != "combat":
		controller._render_scene(controller.current_scene)
		return
	var run_state = controller.preview_controller.run.state
	var inv_data = run_state.get("inventory", {})
	if inv_data is Dictionary:
		controller.inventory = InventoryModelScript.new(int(inv_data.get("width", 8)), int(inv_data.get("height", 8)))
		if inv_data.has("artifacts"):
			for art_dict in inv_data["artifacts"]:
				var art = ArtifactScript.new(art_dict)
				controller.inventory.place_artifact(art, art.x, art.y)
	controller._apply_growth_modifiers()
	controller.view.render_backpack(controller.inventory)
	controller.current_scene = controller.preview_controller.get_scene()
	controller._render_scene(controller.current_scene)

# ?ㅽ뻾: initialize weakness markers for a fresh combat scene.
static func ensure_combat_terrain_markers(controller) -> void:
	if not controller.current_scene.has("combat") or controller.current_scene["combat"] == null:
		return
	var run_state = controller.preview_controller.run.state
	if not run_state.has("combat") or run_state["combat"] == null:
		return
	var battlefield: Dictionary = run_state["combat"].get("battlefield", {})
	if not battlefield.get("weaknessMarkers", []).is_empty():
		return
	var run_seed := 1
	if controller.preview_controller != null and controller.preview_controller.run != null:
		run_seed = int(controller.preview_controller.run.state.get("seed", 1))
	run_state["combat"]["battlefield"]["weaknessMarkers"] = EnergyTempoBalanceScript.terrain_markers(
		int(battlefield.get("rows", 3)),
		int(battlefield.get("columns", 10)),
		run_seed,
		controller.weakness_shift_step
	)
	controller.current_scene = controller.preview_controller.get_scene()
