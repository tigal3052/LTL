extends "res://tests/support/UiReadModelTestSuite.gd"

func run_all_tests() -> Dictionary:
	failures.clear()
	reward_reveal_cancel_done_calls = 0
	test_reward_reveal_cards_conceal_identity_then_use_fixed_rarity_bursts()
	test_reward_reveal_result_stage_uses_clean_layout_and_distinct_rarity_profiles()
	test_reward_reveal_safe_area_models_stay_inside_canvas()
	test_reward_reveal_overlay_safe_layout_caps_effect_radii()
	test_reward_reveal_quantity_slots_center_even_pairs()
	test_reward_ceremony_step_contract_and_node_select_color_gate()
	test_reward_ceremony_policy_is_single_source_for_step_gates()
	test_reward_reveal_cancel_suppresses_done_callback()
	return _result()

func test_reward_reveal_cards_conceal_identity_then_use_fixed_rarity_bursts() -> void:
	var RewardRevealOverlayScript = load("res://src/ui/RewardRevealOverlay.gd")
	_assert(RewardRevealOverlayScript != null, "reward ceremony overlay script loads for card reveal phase contract")
	if RewardRevealOverlayScript == null:
		return
	_assert(RewardRevealOverlayScript.has_method("card_reveal_phase_model"), "reward ceremony overlay exposes card reveal phase model")
	if not RewardRevealOverlayScript.has_method("card_reveal_phase_model"):
		return
	var common_charge = RewardRevealOverlayScript.card_reveal_phase_model("common", 0.32, false, 4)
	var legendary_charge = RewardRevealOverlayScript.card_reveal_phase_model("legendary", 0.32, false, 4)
	var nearly_full_charge = RewardRevealOverlayScript.card_reveal_phase_model("rare", 0.95, false, 1)
	var epic_reveal = RewardRevealOverlayScript.card_reveal_phase_model("epic", 1.0, true, 0)
	var legendary_reveal = RewardRevealOverlayScript.card_reveal_phase_model("legendary", 1.0, true, 4)
	_assert_eq(bool(common_charge.get("identityVisible", true)), false, "card charge phase hides reward identity behind white light")
	_assert_eq(str(common_charge.get("cardFace", "")), "white_sealed_card", "card charge phase uses a white sealed card face")
	_assert_eq(bool(common_charge.get("rarityVisibleBeforeReveal", true)), false, "card charge phase hides rarity before reveal")
	_assert_eq(str(common_charge.get("sealedAccentTier", "")), "neutral_white", "common hidden card uses neutral white accent")
	_assert_eq(str(legendary_charge.get("sealedAccentTier", "")), "neutral_white", "legendary hidden card also uses neutral white accent")
	_assert(float(common_charge.get("shakeStrength", 0.0)) > 0.0, "card charge phase shakes before revealing identity")
	_assert_eq(bool(nearly_full_charge.get("identityVisible", true)), false, "artifact identity stays hidden until the front progress bar is fully complete")
	_assert(float(nearly_full_charge.get("progressFill", 0.0)) >= 0.94, "front progress bar can be nearly full while identity is still hidden")
	_assert(float(legendary_charge.get("shakeStrength", 0.0)) > float(common_charge.get("shakeStrength", 0.0)), "higher rarity sealed silhouettes use more energetic anticipation motion")
	_assert_eq(bool(epic_reveal.get("identityVisible", false)), true, "card reveal phase makes the reward identity readable")
	_assert_eq(str(epic_reveal.get("rarityBurstTier", "")), "epic", "epic reveal uses the epic burst tier")
	_assert_eq(str(legendary_reveal.get("rarityBurstTier", "")), "legendary", "legendary reveal uses the legendary burst tier")
	_assert_eq(bool(legendary_reveal.get("usesQueuePositionForIntensity", true)), false, "rarity burst intensity is fixed by rarity, not by queue position")
	_assert(float(legendary_reveal.get("burstStrength", 0.0)) > float(epic_reveal.get("burstStrength", 0.0)), "legendary reveal is stronger than epic because of rarity")
	_assert(RewardRevealOverlayScript.has_method("queue_marker_phase_model"), "reward ceremony overlay exposes queue marker phase model")
	if RewardRevealOverlayScript.has_method("queue_marker_phase_model"):
		var future_marker = RewardRevealOverlayScript.queue_marker_phase_model("legendary", false, false, false)
		var current_hidden_marker = RewardRevealOverlayScript.queue_marker_phase_model("epic", false, true, false)
		var revealed_marker = RewardRevealOverlayScript.queue_marker_phase_model("rare", true, false, true)
		_assert_eq(bool(future_marker.get("rarityVisible", true)), false, "future queue markers hide rarity before their reveal")
		_assert_eq(str(future_marker.get("accentTier", "")), "neutral_white", "future queue markers use neutral white accent")
		_assert_eq(bool(current_hidden_marker.get("rarityVisible", true)), false, "current hidden queue marker also hides rarity")
		_assert_eq(str(current_hidden_marker.get("accentTier", "")), "neutral_white", "current hidden queue marker uses neutral white accent")
		_assert_eq(bool(revealed_marker.get("rarityVisible", false)), true, "revealed queue markers may show their actual rarity")
		_assert_eq(str(revealed_marker.get("accentTier", "")), "rare", "revealed queue markers use the actual rarity accent")

func test_reward_reveal_result_stage_uses_clean_layout_and_distinct_rarity_profiles() -> void:
	var RewardRevealOverlayScript = load("res://src/ui/RewardRevealOverlay.gd")
	_assert(RewardRevealOverlayScript != null, "reward ceremony overlay script loads for result-stage visual profile contract")
	if RewardRevealOverlayScript == null:
		return
	_assert(RewardRevealOverlayScript.has_method("reveal_visual_profile"), "reward ceremony overlay exposes a deterministic rarity visual profile helper")
	_assert(RewardRevealOverlayScript.has_method("reward_card_layout_metrics"), "reward ceremony overlay exposes reward card layout metrics for clipping regression coverage")
	if RewardRevealOverlayScript.has_method("reveal_visual_profile"):
		var common = RewardRevealOverlayScript.reveal_visual_profile("common")
		var epic = RewardRevealOverlayScript.reveal_visual_profile("epic")
		var legendary = RewardRevealOverlayScript.reveal_visual_profile("legendary")
		var mythic = RewardRevealOverlayScript.reveal_visual_profile("mythic")
		_assert_eq(bool(common.get("showBackdropLid", true)), false, "result-stage common rewards no longer keep a giant excavation-lid texture behind the main card")
		_assert_eq(bool(epic.get("showBackdropLid", true)), false, "result-stage epic rewards also use the same clean backdrop policy")
		_assert(float(epic.get("auraStrength", 0.0)) > float(common.get("auraStrength", 0.0)), "epic rewards use a stronger aura than common rewards")
		_assert(int(epic.get("sparkCount", 0)) > int(common.get("sparkCount", 0)), "epic rewards spawn a richer particle package than common rewards")
		_assert(float(epic.get("frameGlowAlpha", 0.0)) > float(common.get("frameGlowAlpha", 0.0)), "epic rewards keep a brighter frame glow than common rewards")
		_assert(float(common.get("burstStrength", 0.0)) >= 0.45, "even common rewards still get a clearly readable burst")
		_assert(int(common.get("beamCount", 0)) >= 6, "common rewards still throw a visible beam package so disappointment reads on screen")
		_assert(int(legendary.get("beamCount", 0)) > int(epic.get("beamCount", 0)), "legendary rewards use more burst beams than epic rewards")
		_assert(float(legendary.get("screenWashAlpha", 0.0)) > float(common.get("screenWashAlpha", 0.0)), "legendary rewards push a stronger screen wash than common rewards")
		_assert(int(mythic.get("shockwaveCount", 0)) > int(legendary.get("shockwaveCount", 0)), "mythic rewards layer more shockwaves than legendary rewards")
	if RewardRevealOverlayScript.has_method("reward_card_layout_metrics"):
		var layout = RewardRevealOverlayScript.reward_card_layout_metrics(Vector2(1440.0, 900.0))
		_assert(float(layout.get("cardWidth", 0.0)) >= 540.0, "reward result card widens enough to keep localized item names from clipping")
		_assert(float(layout.get("textWidth", 0.0)) >= 300.0, "reward result card reserves a dedicated text column wide enough for rarity and item labels")
		_assert(float(layout.get("textLeft", 0.0)) >= float(layout.get("iconRight", 0.0)) + 28.0, "reward text column begins after the icon column with stable spacing")
		_assert(float(layout.get("supportY", 0.0)) > float(layout.get("nameY", 0.0)), "support text renders below the reward name instead of overlapping it")
		_assert(float(layout.get("progressY", 0.0)) > float(layout.get("cardBottom", 0.0)), "reveal progress text sits below the main card instead of colliding with it")
		_assert(float(layout.get("frontProgressY", 0.0)) > float(layout.get("cardBottom", 0.0)), "front reveal progress bar sits under the card as the primary anticipation meter")
	_assert(RewardRevealOverlayScript.has_method("reveal_queue_layout_policy"), "reward ceremony overlay exposes a layout policy for removing the rear queue card strip")
	if RewardRevealOverlayScript.has_method("reveal_queue_layout_policy"):
		var policy = RewardRevealOverlayScript.reveal_queue_layout_policy()
		_assert_eq(bool(policy.get("backgroundCardListVisible", true)), false, "individual artifact reveal removes the rear full-card silhouette list")
		_assert_eq(bool(policy.get("frontProgressBarVisible", false)), true, "individual artifact reveal uses the front progress bar as the main anticipation cue")
		_assert_eq(bool(policy.get("progressTextVisible", false)), true, "individual artifact reveal keeps current / total progress text")

func test_reward_reveal_safe_area_models_stay_inside_canvas() -> void:
	var RewardRevealOverlayScript = load("res://src/ui/RewardRevealOverlay.gd")
	_assert(RewardRevealOverlayScript != null, "reward ceremony overlay script loads for safe-area layout coverage")
	if RewardRevealOverlayScript == null:
		return
	_assert(RewardRevealOverlayScript.has_method("center_lid_layout_model"), "reward ceremony overlay exposes center lid layout for safe-area checks")
	_assert(RewardRevealOverlayScript.has_method("reward_card_layout_metrics"), "reward ceremony overlay exposes card layout metrics for safe-area checks")
	if not RewardRevealOverlayScript.has_method("center_lid_layout_model") or not RewardRevealOverlayScript.has_method("reward_card_layout_metrics"):
		return
	for canvas_size in [Vector2(1280.0, 720.0), Vector2(1440.0, 900.0), Vector2(960.0, 540.0), Vector2(854.0, 480.0)]:
		var safe_layout = RewardRevealOverlayScript.overlay_safe_layout_model(canvas_size) if RewardRevealOverlayScript.has_method("overlay_safe_layout_model") else {}
		var lid_layout = RewardRevealOverlayScript.center_lid_layout_model(canvas_size)
		var lid_rect: Rect2 = lid_layout.get("closedLidRect", Rect2())
		_assert(lid_rect.position.x >= 24.0, "reward reveal lid stays away from the left screen edge for canvas %s" % str(canvas_size))
		_assert(lid_rect.end.x <= canvas_size.x - 24.0, "reward reveal lid stays away from the right screen edge for canvas %s" % str(canvas_size))
		_assert(lid_rect.position.y >= canvas_size.y * 0.25, "reward reveal lid remains below the headline band for canvas %s" % str(canvas_size))
		_assert(lid_rect.end.y <= canvas_size.y * 0.70, "reward reveal lid remains above the lower progress band for canvas %s" % str(canvas_size))
		var metrics = RewardRevealOverlayScript.reward_card_layout_metrics(canvas_size)
		var card_size := Vector2(float(metrics.get("cardWidth", 0.0)), float(metrics.get("cardHeight", 0.0))) * 1.06
		var card_rect := Rect2(Vector2(canvas_size.x * 0.50, float(metrics.get("cardCenterY", canvas_size.y * 0.57))) - (card_size * 0.5), card_size)
		_assert(card_rect.position.x >= 24.0, "reward reveal card keeps a left safe margin for canvas %s" % str(canvas_size))
		_assert(card_rect.end.x <= canvas_size.x - 24.0, "reward reveal card keeps a right safe margin for canvas %s" % str(canvas_size))
		_assert(card_rect.position.y >= canvas_size.y * 0.28, "reward reveal card stays below the headline/subtitle block for canvas %s" % str(canvas_size))
		_assert(card_rect.end.y <= float(safe_layout.get("confirmPromptY", canvas_size.y * 0.90)) - 24.0, "reward reveal card stays above the confirm prompt lane for canvas %s" % str(canvas_size))
		var front_progress_y := float(metrics.get("frontProgressY", 0.0))
		var progress_y := float(metrics.get("progressY", 0.0))
		_assert(front_progress_y >= card_rect.end.y, "reward reveal front progress bar stays below the card for canvas %s" % str(canvas_size))
		_assert(front_progress_y + 10.0 <= float(safe_layout.get("confirmPromptY", canvas_size.y * 0.90)) - 16.0, "reward reveal front progress bar stays inside the lower safe band for canvas %s" % str(canvas_size))
		_assert(progress_y + float(metrics.get("progressFontSize", 18)) <= float(safe_layout.get("confirmPromptY", canvas_size.y * 0.90)) - 12.0, "reward reveal progress text stays above the bottom prompt lane for canvas %s" % str(canvas_size))

func test_reward_reveal_overlay_safe_layout_caps_effect_radii() -> void:
	var RewardRevealOverlayScript = load("res://src/ui/RewardRevealOverlay.gd")
	_assert(RewardRevealOverlayScript != null, "reward ceremony overlay script loads for overlay safe-layout coverage")
	if RewardRevealOverlayScript == null:
		return
	_assert(RewardRevealOverlayScript.has_method("overlay_safe_layout_model"), "reward ceremony overlay exposes a shared safe-layout model for effect containment")
	if not RewardRevealOverlayScript.has_method("overlay_safe_layout_model"):
		return
	for canvas_size in [Vector2(1280.0, 720.0), Vector2(1440.0, 900.0)]:
		var safe_layout = RewardRevealOverlayScript.overlay_safe_layout_model(canvas_size)
		var focus_center: Vector2 = safe_layout.get("focusCenter", canvas_size * 0.5)
		var safe_margin := float(safe_layout.get("safeMargin", 24.0))
		var focus_radius := float(safe_layout.get("focusMaxRadius", 0.0))
		var allowed_radius := minf(minf(focus_center.x, canvas_size.x - focus_center.x), minf(focus_center.y, canvas_size.y - focus_center.y)) - safe_margin
		_assert(focus_radius <= allowed_radius + 0.5, "reward reveal focus radius stays inside the screen-safe area for canvas %s" % str(canvas_size))
		_assert(float(safe_layout.get("headlineTitleY", 0.0)) >= safe_margin, "reward reveal title stays below the top safe margin for canvas %s" % str(canvas_size))
		_assert(float(safe_layout.get("headlineSubtitleY", 0.0)) > float(safe_layout.get("headlineTitleY", 0.0)), "reward reveal subtitle stays below the title for canvas %s" % str(canvas_size))
		_assert(float(safe_layout.get("confirmPromptY", canvas_size.y)) <= canvas_size.y - safe_margin, "reward reveal confirm prompt stays above the bottom safe margin for canvas %s" % str(canvas_size))
		var lid_layout = RewardRevealOverlayScript.center_lid_layout_model(canvas_size)
		var lid_rect: Rect2 = lid_layout.get("closedLidRect", Rect2())
		_assert_close(lid_rect.get_center().x, focus_center.x, 0.5, "reward reveal lid center aligns with the shared focus center on x for canvas %s" % str(canvas_size))
		_assert_close(lid_rect.get_center().y, focus_center.y, 0.5, "reward reveal lid center aligns with the shared focus center on y for canvas %s" % str(canvas_size))

func test_reward_reveal_quantity_slots_center_even_pairs() -> void:
	var RewardRevealOverlayScript = load("res://src/ui/RewardRevealOverlay.gd")
	_assert(RewardRevealOverlayScript != null, "reward ceremony overlay script loads for quantity-slot centering coverage")
	if RewardRevealOverlayScript == null:
		return
	var overlay = RewardRevealOverlayScript.new()
	var rects: Array = overlay.call("_quantity_slot_rects", 2, Vector2(1280.0, 720.0), Vector2(68.0, 68.0), 320.0)
	_assert_eq(rects.size(), 2, "reward reveal quantity slot helper returns two rects for the two-reward burst")
	if rects.size() == 2:
		var left_rect: Rect2 = rects[0]
		var right_rect: Rect2 = rects[1]
		var midpoint_x := (left_rect.get_center().x + right_rect.get_center().x) * 0.5
		_assert_close(midpoint_x, 640.0, 0.5, "reward reveal two-slot burst stays centered on the canvas midpoint")
	overlay.free()

func test_reward_ceremony_step_contract_and_node_select_color_gate() -> void:
	var MainControllerScript = load("res://src/MainControllerRuntime.gd")
	var NodeSelectRuntimePageScene = load("res://src/scenes/pages/NodeSelectRuntimePage.tscn")
	_assert(MainControllerScript != null, "main controller runtime loads for reward ceremony step contract")
	_assert(NodeSelectRuntimePageScene != null, "node-select runtime page scene loads for starter-color gate contract")
	if MainControllerScript != null:
		_assert(MainControllerScript.has_method("reward_presentation_step_sequence"), "main controller runtime exposes reward ceremony step sequencing")
		if MainControllerScript.has_method("reward_presentation_step_sequence"):
			_assert_eq(MainControllerScript.reward_presentation_step_sequence(), ["count_tease", "count_lock", "reveal_queue", "tray_review"], "reward ceremony steps progress through count tease, count lock, reveal queue, and tray review")
	var stage_one_layout := PhaseLayoutPresenterScript.project({"phase": "node_select", "stageIndex": 0, "maxStages": 5}, false)
	var stage_two_layout := PhaseLayoutPresenterScript.project({"phase": "node_select", "stageIndex": 1, "maxStages": 5}, false)
	_assert_eq(bool(stage_one_layout.get("allowStartColorSelection", false)), true, "stage one node select keeps the starter color picker visible")
	_assert_eq(bool(stage_two_layout.get("allowStartColorSelection", true)), false, "stage two node select hides the starter color picker contractually")
	if NodeSelectRuntimePageScene != null:
		var node_select_page = NodeSelectRuntimePageScene.instantiate()
		_assert(node_select_page != null, "node-select runtime page instantiates for starter-color gate contract")
		if node_select_page != null:
			_assert(node_select_page.has_method("start_color_chip_count"), "node-select runtime page exposes starter-color chip counts for legacy-removal coverage")
			if node_select_page.has_method("start_color_chip_count"):
				_assert_eq(int(node_select_page.call("start_color_chip_count")), 0, "node-select runtime page keeps starter color chips absent while the stage-two gate is closed")
			node_select_page.free()

# ?ㅽ뻾: verify battlefield cells keep the compact pre-M4 terrain aspect ratio.
# ?ㅽ뻾: append a failure when condition is false.
func test_reward_ceremony_policy_is_single_source_for_step_gates() -> void:
	_assert_eq(RewardCeremonyPolicyScript.step_sequence(), ["count_tease", "count_lock", "reveal_queue", "tray_review"], "reward ceremony policy owns the exact step sequence")
	_assert_eq(RewardCeremonyPolicyScript.is_active_step("count_tease"), true, "count tease is an active ceremony step")
	_assert_eq(RewardCeremonyPolicyScript.is_active_step("count_lock"), true, "count lock is an active ceremony step")
	_assert_eq(RewardCeremonyPolicyScript.is_active_step("reveal_queue"), true, "reveal queue is an active ceremony step")
	_assert_eq(RewardCeremonyPolicyScript.is_active_step("tray_review"), false, "tray review reopens reward interaction")
	_assert_eq(RewardCeremonyPolicyScript.is_active_scene({"phase": "reward_loot", "rewardPresentationStep": "count_lock"}), true, "reward loot count lock scene blocks reward tray interaction")
	_assert_eq(RewardCeremonyPolicyScript.is_active_scene({"phase": "reward_loot", "rewardPresentationStep": "tray_review"}), false, "tray review scene stops blocking reward tray interaction")
	_assert_eq(RewardCeremonyPolicyScript.allow_start_color_selection({"phase": "node_select", "stageIndex": 0}), true, "policy allows starter color selection only on stage one")
	_assert_eq(RewardCeremonyPolicyScript.allow_start_color_selection({"phase": "node_select", "stageIndex": 1}), false, "policy blocks starter color selection after stage one")

func test_reward_reveal_cancel_suppresses_done_callback() -> void:
	var RewardRevealOverlayScript = load("res://src/ui/RewardRevealOverlay.gd")
	_assert(RewardRevealOverlayScript != null, "reward ceremony overlay script loads for cancel contract")
	if RewardRevealOverlayScript == null:
		return
	reward_reveal_cancel_done_calls = 0
	var overlay = RewardRevealOverlayScript.new()
	_assert(overlay.has_method("cancel_reveal"), "reward ceremony overlay exposes a cancel API")
	if not overlay.has_method("cancel_reveal"):
		overlay.free()
		return
	overlay.size = Vector2(1440.0, 900.0)
	overlay.start_reveal(
		[{"kind": "Dust Charm", "rarity": "common", "payload": {"item_type": "relic", "energy_type": "green"}}],
		Callable(self, "_ignore_reward_reveal_step_for_cancel_contract"),
		Callable(self, "_record_reward_reveal_done_for_cancel_contract"),
		Rect2(Vector2(260.0, 620.0), Vector2(96.0, 58.0))
	)
	overlay.cancel_reveal()
	_assert_eq(reward_reveal_cancel_done_calls, 0, "canceling reward reveal does not call the completion callback")
	_assert_eq(bool(overlay.visible), false, "canceling reward reveal hides the overlay")
	_assert_eq(bool(overlay.is_revealing), false, "canceling reward reveal clears the active reveal state")
	overlay.free()

func _record_reward_reveal_done_for_cancel_contract() -> void:
	reward_reveal_cancel_done_calls += 1

func _ignore_reward_reveal_step_for_cancel_contract(_step: String) -> void:
	pass

