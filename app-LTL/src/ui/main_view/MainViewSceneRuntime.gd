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
	var node_map_full_page := bool(layout.get("nodeMapFullPage", false))
	view.header_panel.visible = bool(layout.get("headerVisible", true))
	var chrome_margin := 0 if node_map_full_page else 16
	for margin_side in ["margin_left", "margin_top", "margin_right", "margin_bottom"]:
		view.root_margin.add_theme_constant_override(margin_side, chrome_margin)
	_apply_page_chrome_backdrop(view, page_id)
	if view.header_title_label != null:
		view.header_title_label.text = view._resolved_header_title(scene)
	view.phase_label.text = str(layout.get("phaseText", TextCatalogScript.t("phase.label", [TextCatalogScript.t("phase.unknown")])))
	view.stage_label.text = str(layout.get("stageText", TextCatalogScript.t("stage.label", [1, 1])))
	view.stage_label.visible = not view.stage_label.text.is_empty()
	if view.action_bar != null:
		view.action_bar.visible = bool(layout.get("actionBarVisible", true))
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
	if view.backpack_ui != null and view.backpack_ui.has_method("set_influence_preview_toggle_visible"):
		view.backpack_ui.set_influence_preview_toggle_visible(bool(layout.get("backpackInfluenceToggleVisible", false)))
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
	var cta_timer_present := _render_battle_cta_timer(view, layout)
	view.status_panel.render_combat_timer(str(layout.get("timerText", "00:00")), bool(layout.get("combatTimeActive", false)) and not cta_timer_present)
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

# 전투 리디자인: 전투/보상 페이지는 소프트 포커스 숲 배경(bg_canopy_ruins) 라이트 크롬,
# 그 외 페이지는 기존 다크 크롬을 유지한다.
static func _apply_page_chrome_backdrop(view, page_id: String) -> void:
	if page_id in SURFACE_PAGE_IDS:
		var texture := load("res://resources/UI/battle_redesign/bg_canopy_ruins.png") as Texture2D
		if texture != null:
			var style := StyleBoxTexture.new()
			style.texture = texture
			style.modulate_color = Color(0.96, 0.98, 0.96, 1.0)
			view.add_theme_stylebox_override("panel", style)
			return
	var dark := StyleBoxFlat.new()
	dark.bg_color = Color(0.0627, 0.0784, 0.1098, 1.0)
	view.add_theme_stylebox_override("panel", dark)

# 전투 리디자인: 보드 우측 CTA 기둥의 전투 타이머 칩을 갱신한다. 칩이 존재하면 true를 돌려
# 좌측 상태 패널 footer 타이머의 중복 표시를 막는다.
static func _render_battle_cta_timer(view, layout: Dictionary) -> bool:
	var found := false
	for page_id in ["battle", "boss_battle"]:
		var bundle: Dictionary = view._page_bundle(page_id)
		if bundle.is_empty():
			continue
		var chip := bundle.get("ctaTimerChip", null) as PanelContainer
		var label := bundle.get("ctaTimerLabel", null) as Label
		if label == null:
			continue
		found = true
		var timer_active := bool(layout.get("combatTimeActive", false))
		if chip != null:
			chip.visible = timer_active
		label.text = str(layout.get("timerText", "00:00"))
		var critical := bool(layout.get("vignetteVisible", false))
		label.add_theme_color_override(
			"font_color",
			Color(1.0, 0.42, 0.37, 1.0) if critical else Color(0.85, 0.643, 0.255, 1.0)
		)
	return found

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
	# 전투 리디자인: 배틀 진입 직후 시작 홀드 동안 CTA 기둥의 '굴착 시작' 버튼을 노출한다.
	var battle_start_hold := page_id in ["battle", "boss_battle"] and bool(scene.get("battleStartHoldActive", false))
	if view.reset_button != null:
		view.reset_button.visible = page_id not in META_PAGE_IDS
	if view.start_button != null:
		view.start_button.visible = page_id == "node_select" or battle_start_hold
	if view.claim_rewards_button != null:
		view.claim_rewards_button.visible = page_id in ["reward", "boss_reward"]
	if view.start_button != null:
		var start_ready := battle_start_hold or (page_id == "node_select" and node_select_start_ready(scene))
		var next_disabled := not start_ready
		if view.start_button.disabled != next_disabled:
			view.start_button.disabled = next_disabled
			if page_id == "node_select" and view.node_select_runtime_page != null and view.node_select_runtime_page.has_method("refresh_start_button_state"):
				view.node_select_runtime_page.refresh_start_button_state()
	var claim_disabled := (narrative_blocked or page_id not in ["reward", "boss_reward"] or show_victory_overlay or reward_ceremony_active or bool(scene.get("is_reveal_vfx_running", false)))
	if view.claim_rewards_button != null:
		view.claim_rewards_button.disabled = claim_disabled
	if view.claim_inline_button != null:
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
