class_name MainViewSceneRuntime
extends RefCounted

const TextCatalogScript = preload("res://src/ui/TextCatalog.gd")
const HudReadModelScript = preload("res://src/ui/read_models/HudReadModel.gd")
const FailureReadModelScript = preload("res://src/ui/read_models/FailureReadModel.gd")
const PhaseLayoutPresenterScript = preload("res://src/ui/presenters/PhaseLayoutPresenter.gd")
const RewardCeremonyPolicyScript = preload("res://src/ui/presenters/RewardCeremonyPolicy.gd")
const PopupOverlayHostScript = preload("res://src/ui/PopupOverlayHost.gd")

const SURFACE_PAGE_IDS := ["battle", "boss_battle", "reward", "boss_reward"]
const ACTION_BAR_PAGE_IDS := ["node_select", "battle", "boss_battle", "reward", "boss_reward"]
const META_PAGE_IDS := ["character_select", "leviathan_select", "story_scene", "clear", "defeat"]
const REWARD_REVEAL_OVERLAY_Z_INDEX := 600

static func render_scene(view, scene: Dictionary, show_victory_overlay: bool) -> void:
	view._last_rendered_scene = scene.duplicate(true)
	var layout: Dictionary = PhaseLayoutPresenterScript.project(scene, show_victory_overlay)
	var hud_model: Dictionary = HudReadModelScript.project(scene)
	var overlay_model: Dictionary = FailureReadModelScript.project(scene)
	var page_id := str(scene.get("pageId", str(scene.get("phase", "unknown"))))
	if page_id in ACTION_BAR_PAGE_IDS:
		view._activate_action_bar_bundle(page_id)
	if page_id in SURFACE_PAGE_IDS:
		view._activate_surface_bundle(page_id)
	if page_id in META_PAGE_IDS:
		overlay_model["visible"] = false
	view.header_panel.visible = bool(layout.get("headerVisible", true))
	if view.header_title_label != null:
		view.header_title_label.text = view._resolved_header_title(scene)
	view.phase_label.text = str(layout.get("phaseText", TextCatalogScript.t("phase.label", [TextCatalogScript.t("phase.unknown")])))
	view.stage_label.text = str(layout.get("stageText", TextCatalogScript.t("stage.label", [1, 1])))
	view.stage_label.visible = not view.stage_label.text.is_empty()
	view.action_bar.visible = bool(layout.get("actionBarVisible", true))
	var node_map_full_page := bool(layout.get("nodeMapFullPage", false))
	var reward_backpack_dock := bool(layout.get("rewardBackpackDock", false))
	view._apply_node_select_backpack_dock(str(layout.get("nodeSelectBackpackDock", "top")), float(layout.get("nodeMapStretchRatio", 2.1)), float(layout.get("backpackStretchRatio", 1.0)))
	view._apply_top_content_stretch(float(layout.get("leftColumnTopStretchRatio", 3.5)), float(layout.get("backpackTopStretchRatio", 6.0)), float(layout.get("rightSidebarTopStretchRatio", 2.5)))
	view.top_content.visible = bool(layout.get("topContentVisible", true))
	view.left_column.visible = bool(layout.get("sidebarsVisible", true))
	view.right_sidebar.visible = bool(layout.get("sidebarsVisible", true))
	if view.backpack_container != null:
		view.backpack_container.visible = bool(layout.get("backpackVisible", true)) or reward_backpack_dock
	view.left_column.add_theme_constant_override("separation", 12 if view.top_content.visible else 16)
	if view.backpack_container != null and node_map_full_page:
		view.backpack_container.custom_minimum_size = Vector2(view._node_select_backpack_width(), 0.0)
		view.backpack_container.ratio = 1.0
	elif view.top_content.visible:
		view._apply_top_content_backpack_bounds()
	elif view.backpack_container != null:
		view.top_content.custom_minimum_size.y = 0.0
		view.backpack_container.custom_minimum_size = Vector2.ZERO
		view.backpack_container.ratio = 1.0
	view.active_phase_container.size_flags_stretch_ratio = float(layout.get("activePhaseStretchRatio", 1.0))
	if view.battlefield_ui != null:
		view.battlefield_ui.visible = bool(layout.get("battlefieldVisible", false))
	if view.reward_panel != null:
		view.reward_panel.visible = bool(layout.get("rewardVisible", false))
	view._apply_reward_backpack_dock(reward_backpack_dock)
	if view.status_panel != null:
		view.status_panel.visible = bool(layout.get("statusVisible", false))
	view.shop_open_button.visible = bool(layout.get("shopButtonVisible", false))
	if view.backpack_ui != null and view.backpack_ui.has_method("set_cooldown_visuals_enabled"):
		view.backpack_ui.set_cooldown_visuals_enabled(bool(layout.get("backpackCooldownVisible", false)))
	if view.backpack_ui != null and view.backpack_ui.has_method("update_pin_overlays"):
		if view._backpack_reparent_pending:
			view._pending_backpack_pin_scene = scene.duplicate(true)
			view.call_deferred("_flush_pending_backpack_pin_scene")
		else:
			view.backpack_ui.update_pin_overlays(scene)
	if bool(layout.get("closeShop", false)):
		view.shop_panel.visible = false
	view.giant_timer_panel.visible = bool(layout.get("giantTimerVisible", false))
	view.giant_timer_label.text = str(layout.get("timerText", "00:00"))
	view.vignette_overlay.visible = bool(layout.get("vignetteVisible", false))
	if view.giant_timer_ui != null and view.giant_timer_ui.has_method("apply_timer_state"):
		view.giant_timer_ui.apply_timer_state(str(layout.get("timerText", "00:00")), bool(layout.get("giantTimerVisible", false)), bool(layout.get("vignetteVisible", false)))
	if bool(layout.get("combatTimeActive", false)):
		view.battlefield_ui.update_combat_time(float(layout.get("timeLeft", 0.0)), float(layout.get("timeLimit", 0.0)), true)
	else:
		view.battlefield_ui.update_combat_time(0.0, 0.0, false)
	if bool(layout.get("battlefieldVisible", false)) and not RewardCeremonyPolicyScript.is_active_scene(scene):
		view.battlefield_ui.render_battlefield(scene, [])
	view.status_panel.render_target_bars(scene)
	view.status_panel.render_extractor_label(scene)
	if view.status_panel.has_method("render_node_info"):
		view.status_panel.render_node_info(scene)
	view.status_panel.render_hud_projection(hud_model)
	view.status_panel.render_combat_timer(str(layout.get("timerText", "00:00")), bool(layout.get("combatTimeActive", false)))
	view.status_panel.render_repair_overlay(scene, view.repair_overlay, overlay_model)
	if view.right_sidebar != null and view.right_sidebar.has_method("render_scene"):
		view.right_sidebar.render_scene(scene)
	view._render_failure_backdrop(scene)
	view._render_character_status(scene)
	view._render_reward_backdrop(show_victory_overlay or str(scene.get("phase", "")) == "reward_loot")
	view._render_page_scene(scene)
	view._defer_interaction_fx_install()
	view._queue_shared_backpack_layout_sync()
	view.call_deferred("_sync_page_scene_bounds")

static func update_battlefield_disabled(view, scene: Dictionary, disabled_tiles: Array) -> void:
	view.battlefield_ui.render_battlefield(scene, disabled_tiles)

static func start_reward_reveal_vfx(view, rewards_list: Array, step_callback: Callable, callback: Callable) -> void:
	if view.reward_reveal_overlay != null and view.reward_reveal_overlay.has_method("start_reveal"):
		view.reward_reveal_done_bridge = Callable(view, "_on_reward_reveal_overlay_finished").bind(callback)
		if view.reward_reveal_overlay.has_signal("ceremony_finished") and view.reward_reveal_overlay.is_connected("ceremony_finished", view.reward_reveal_done_bridge):
			view.reward_reveal_overlay.disconnect("ceremony_finished", view.reward_reveal_done_bridge)
		if view.reward_reveal_overlay.has_signal("ceremony_finished"):
			view.reward_reveal_overlay.connect("ceremony_finished", view.reward_reveal_done_bridge, CONNECT_ONE_SHOT)
		bring_reward_reveal_overlay_to_front(view)
		view.reward_reveal_overlay.start_reveal(rewards_list, step_callback, Callable(), reward_lid_source_global_rect(view))
		return
	callback.call()

static func skip_reward_reveal_to_silhouettes(view) -> void:
	if view.reward_reveal_overlay != null and view.reward_reveal_overlay.has_method("skip_to_silhouettes"):
		view.reward_reveal_overlay.skip_to_silhouettes()

static func cancel_reward_reveal_vfx(view) -> void:
	if view.reward_reveal_overlay != null and view.reward_reveal_overlay.has_method("cancel_reveal"):
		view.reward_reveal_overlay.cancel_reveal()

static func on_reward_reveal_overlay_finished(view, next_step: String, callback: Callable) -> void:
	if not callback.is_valid():
		return
	view.reward_reveal_pending_step = next_step
	view.reward_reveal_pending_callback = callback
	view.call_deferred("_flush_reward_reveal_finished_callback")

static func flush_reward_reveal_finished_callback(view) -> void:
	if not view.reward_reveal_pending_callback.is_valid():
		return
	var callback: Callable = view.reward_reveal_pending_callback
	var next_step: String = view.reward_reveal_pending_step
	view.reward_reveal_pending_step = ""
	view.reward_reveal_pending_callback = Callable()
	callback.call_deferred(next_step)

static func bring_reward_reveal_overlay_to_front(view) -> void:
	PopupOverlayHostScript.bring_to_front(view.reward_reveal_overlay, REWARD_REVEAL_OVERLAY_Z_INDEX)

static func reward_lid_source_global_rect(view) -> Rect2:
	if view.battlefield_ui != null and view.battlefield_ui.has_method("reward_lid_source_global_rect"):
		return view.battlefield_ui.reward_lid_source_global_rect()
	var fallback_size := Vector2(96.0, 60.0)
	return Rect2(view.global_position + (view.size * 0.5) - (fallback_size * 0.5), fallback_size)

static func update_action_state(view, scene: Dictionary, show_victory_overlay: bool) -> void:
	var phase := str(scene.get("phase", "unknown"))
	var page_id := str(scene.get("pageId", phase))
	var reward_ceremony_active := RewardCeremonyPolicyScript.is_active_scene(scene)
	var narrative_blocked := bool(scene.get("narrativeBlocksInput", false))
	view.reset_button.visible = page_id not in META_PAGE_IDS
	view.start_button.visible = page_id == "node_select"
	view.hold_fire_button.visible = page_id in ["battle", "boss_battle"]
	view.repair_button.visible = page_id in ["battle", "boss_battle"]
	view.claim_rewards_button.visible = page_id in ["reward", "boss_reward"]
	view.start_button.disabled = not (page_id == "node_select" and node_select_start_ready(scene))
	view.hold_fire_button.disabled = narrative_blocked or not (phase == "combat" and bool(scene.get("hud", {}).get("aim", {}).get("canFire", false)))
	view.repair_button.disabled = narrative_blocked or not (phase == "combat" and bool(scene.get("hud", {}).get("repair", {}).get("available", false)))
	var claim_disabled := (narrative_blocked or page_id not in ["reward", "boss_reward"] or show_victory_overlay or reward_ceremony_active or bool(scene.get("is_reveal_vfx_running", false)))
	view.claim_rewards_button.disabled = claim_disabled
	view.claim_inline_button.disabled = claim_disabled

static func node_select_start_ready(scene: Dictionary) -> bool:
	if scene.has("selectedNodeStartEnabled"):
		return bool(scene.get("selectedNodeStartEnabled", false))
	if str(scene.get("phase", "")) != "node_select":
		return false
	var node_select: Dictionary = scene.get("nodeSelect", {}) if scene.get("nodeSelect", {}) is Dictionary else {}
	var candidates: Array = node_select.get("candidates", [])
	var index := int(scene.get("selectedNodeIndex", -1))
	if index < 0 or index >= candidates.size():
		return false
	var candidate: Dictionary = candidates[index]
	return node_candidate_matches_current_stage(candidate, scene) and not node_candidate_already_cleared(candidate, index, scene)

static func node_candidate_matches_current_stage(candidate: Dictionary, scene: Dictionary) -> bool:
	var stage_index := int(scene.get("stageIndex", 0))
	var max_stages := maxi(1, int(scene.get("maxStages", 1)))
	var expected_distance := maxi(0, max_stages - stage_index - 1)
	if candidate.has("finalStageDistance"):
		return int(candidate.get("finalStageDistance", expected_distance)) == expected_distance
	return true

static func node_candidate_already_cleared(candidate: Dictionary, candidate_index: int, scene: Dictionary) -> bool:
	if bool(candidate.get("cleared", false)) or str(candidate.get("status", "")) == "cleared":
		return true
	var node_select: Dictionary = scene.get("nodeSelect", {}) if scene.get("nodeSelect", {}) is Dictionary else {}
	var route_history: Array = node_select.get("routeHistory", scene.get("routeHistory", []))
	var stage_index := int(scene.get("stageIndex", 0))
	var candidate_id := str(candidate.get("id", ""))
	var candidate_hash := str(candidate.get("routeHash", ""))
	for entry in route_history:
		if not (entry is Dictionary):
			continue
		var history_entry: Dictionary = entry
		if int(history_entry.get("stageIndex", -1)) != stage_index:
			continue
		if not candidate_hash.is_empty() and str(history_entry.get("routeHash", "")) == candidate_hash:
			return true
		if not candidate_id.is_empty() and str(history_entry.get("id", "")) == candidate_id and int(history_entry.get("routeSlotIndex", -1)) == candidate_index:
			return true
	return false
