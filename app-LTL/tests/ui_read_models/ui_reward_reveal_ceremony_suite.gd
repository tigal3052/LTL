extends "res://tests/support/UiReadModelTestSuite.gd"

func run_all_tests() -> Dictionary:
	failures.clear()
	reward_reveal_cancel_done_calls = 0
	test_reward_reveal_extracts_model_helpers_for_first_size_split()
	test_reward_reveal_overlay_uses_cinematic_hero_contract_and_removes_legacy_backup()
	test_reward_reveal_presentation_requires_confirm_and_sorted_reveal_queue()
	test_reward_reveal_quantity_tease_uses_three_bands()
	test_reward_reveal_count_tease_hides_exact_count_and_uses_band_preview()
	test_reward_reveal_mined_lid_pops_from_terrain_before_count_burst()
	test_reward_reveal_count_tease_auto_advances_to_count_lock()
	return _result()

func test_reward_reveal_extracts_model_helpers_for_first_size_split() -> void:
	var presentation_helper_path := "res://src/ui/reward_reveal/RewardRevealPresentationModel.gd"
	var layout_helper_path := "res://src/ui/reward_reveal/RewardRevealLayoutPolicy.gd"
	var animation_helper_path := "res://src/ui/reward_reveal/RewardRevealAnimationModels.gd"
	var ceremony_renderer_path := "res://src/ui/reward_reveal/RewardRevealCeremonyRenderer.gd"
	var effect_renderer_path := "res://src/ui/reward_reveal/RewardRevealEffectRenderer.gd"
	_assert(FileAccess.file_exists(presentation_helper_path), "reward reveal presentation model helper exists")
	_assert(FileAccess.file_exists(layout_helper_path), "reward reveal layout policy helper exists")
	_assert(FileAccess.file_exists(animation_helper_path), "reward reveal animation model helper exists")
	_assert(FileAccess.file_exists(ceremony_renderer_path), "reward reveal ceremony renderer helper exists")
	_assert(FileAccess.file_exists(effect_renderer_path), "reward reveal effect renderer helper exists")
	if FileAccess.file_exists(presentation_helper_path):
		var PresentationHelper = load(presentation_helper_path)
		_assert(PresentationHelper != null, "reward reveal presentation helper loads")
		_assert(PresentationHelper.has_method("build_presentation_model"), "presentation helper owns reward presentation projection")
		_assert(PresentationHelper.has_method("rarity_accent"), "presentation helper owns rarity accent mapping")
		_assert(PresentationHelper.has_method("energy_accent"), "presentation helper owns energy accent mapping")
		_assert(_source_line_count(presentation_helper_path) <= 500, "presentation helper stays within the 500-line cap")
	if FileAccess.file_exists(layout_helper_path):
		var LayoutHelper = load(layout_helper_path)
		_assert(LayoutHelper != null, "reward reveal layout helper loads")
		_assert(LayoutHelper.has_method("overlay_safe_layout_model"), "layout helper owns safe-area overlay layout")
		_assert(LayoutHelper.has_method("reward_card_layout_metrics"), "layout helper owns reward card metrics")
		_assert(LayoutHelper.has_method("quantity_slot_rects"), "layout helper owns quantity-slot rect layout")
		_assert(_source_line_count(layout_helper_path) <= 500, "layout helper stays within the 500-line cap")
	if FileAccess.file_exists(animation_helper_path):
		var AnimationHelper = load(animation_helper_path)
		_assert(AnimationHelper != null, "reward reveal animation helper loads")
		_assert(AnimationHelper.has_method("count_tease_preview_model"), "animation helper owns count tease preview model")
		_assert(AnimationHelper.has_method("mined_lid_motion_model"), "animation helper owns mined-lid motion model")
		_assert(AnimationHelper.has_method("card_reveal_phase_model"), "animation helper owns card reveal phase model")
		_assert(_source_line_count(animation_helper_path) <= 500, "animation helper stays within the 500-line cap")
	if FileAccess.file_exists(ceremony_renderer_path):
		var CeremonyRenderer = load(ceremony_renderer_path)
		_assert(CeremonyRenderer != null, "reward reveal ceremony renderer loads")
		_assert(CeremonyRenderer.has_method("draw_count_tease"), "ceremony renderer owns count tease drawing")
		_assert(CeremonyRenderer.has_method("draw_count_lock"), "ceremony renderer owns count lock drawing")
		_assert(CeremonyRenderer.has_method("draw_reveal_queue"), "ceremony renderer owns reveal queue drawing")
		_assert(CeremonyRenderer.has_method("draw_reward_panel"), "ceremony renderer owns reward panel drawing")
		_assert(_source_line_count(ceremony_renderer_path) <= 500, "ceremony renderer stays within the 500-line cap")
	if FileAccess.file_exists(effect_renderer_path):
		var EffectRenderer = load(effect_renderer_path)
		_assert(EffectRenderer != null, "reward reveal effect renderer loads")
		_assert(EffectRenderer.has_method("draw_mined_lid_charge"), "effect renderer owns mined lid charge drawing")
		_assert(EffectRenderer.has_method("draw_count_burst_animation"), "effect renderer owns count burst drawing")
		_assert(EffectRenderer.has_method("draw_rarity_burst"), "effect renderer owns rarity burst drawing")
		_assert(EffectRenderer.has_method("draw_lid_slot"), "effect renderer owns lid-slot drawing")
		_assert(_source_line_count(effect_renderer_path) <= 500, "effect renderer stays within the 500-line cap")
	_assert(_source_line_count("res://src/ui/RewardRevealOverlay.gd") <= 500, "RewardRevealOverlay delegates model and renderer helpers and stays within 500 lines")

func test_reward_reveal_overlay_uses_cinematic_hero_contract_and_removes_legacy_backup() -> void:
	TextCatalogScript.set_locale("en")
	var RewardRevealOverlayScript = load("res://src/ui/RewardRevealOverlay.gd")
	_assert(RewardRevealOverlayScript != null, "fullscreen reward reveal overlay script exists")
	if RewardRevealOverlayScript != null:
		_assert(RewardRevealOverlayScript.has_method("reveal_timing_profile"), "reward reveal overlay exposes timing profile")
		_assert(RewardRevealOverlayScript.has_method("build_presentation_model"), "reward reveal overlay exposes a presentation model helper")
		if RewardRevealOverlayScript.has_method("reveal_timing_profile"):
			var profile = RewardRevealOverlayScript.reveal_timing_profile()
			_assert(float(profile.get("heroHold", 0.0)) >= 0.8, "cinematic reward reveal holds the hero item long enough to read")
			_assert(float(profile.get("fadeOut", 1.0)) <= 0.45, "cinematic reward reveal exits quickly so the reward tray can return promptly")
		if RewardRevealOverlayScript.has_method("build_presentation_model"):
			var presentation = RewardRevealOverlayScript.build_presentation_model([
				{"kind": "Ruby Drill", "rarity": "rare", "payload": {"item_type": "drill", "energy_type": "red"}},
				{"kind": "Azure Beacon", "rarity": "common", "payload": {"item_type": "beacon", "energy_type": "blue"}},
				{"kind": "Apex Crown", "rarity": "legendary", "payload": {"item_type": "relic", "energy_type": "purple"}}
			])
			_assert_eq(str(presentation.get("heroName", "")), "Apex Crown", "presentation model picks the highest-rarity reward as the cinematic hero")
			_assert_eq(int(presentation.get("extraCount", -1)), 2, "presentation model keeps the remaining rewards available for the tray that returns after the cinematic")
	_assert(not ResourceLoader.exists("res://src/ui/legacy/LegacyRewardRevealOverlay.gd"), "legacy reward reveal backup has been removed after the cinematic overlay became the only runtime owner")
	TextCatalogScript.set_locale("ko")

func test_reward_reveal_presentation_requires_confirm_and_sorted_reveal_queue() -> void:
	TextCatalogScript.set_locale("en")
	var RewardRevealOverlayScript = load("res://src/ui/RewardRevealOverlay.gd")
	_assert(RewardRevealOverlayScript != null, "reward ceremony overlay script loads for presentation contract")
	if RewardRevealOverlayScript == null or not RewardRevealOverlayScript.has_method("build_presentation_model"):
		TextCatalogScript.set_locale("ko")
		return
	var presentation = RewardRevealOverlayScript.build_presentation_model([
		{"kind": "Apex Crown", "rarity": "legendary", "payload": {"item_type": "relic", "energy_type": "purple"}},
		{"kind": "Dust Charm", "rarity": "common", "payload": {"item_type": "relic", "energy_type": "green"}},
		{"kind": "Ruby Drill", "rarity": "epic", "payload": {"item_type": "drill", "energy_type": "red"}},
		{"kind": "Azure Beacon", "rarity": "rare", "payload": {"item_type": "beacon", "energy_type": "blue"}}
	])
	_assert_eq(bool(presentation.get("requiresConfirm", false)), true, "reward ceremony presentation requires explicit player confirmation before the cinematic can finish")
	_assert_eq(presentation.get("revealOrderNames", []), ["Dust Charm", "Azure Beacon", "Ruby Drill", "Apex Crown"], "reward ceremony reveal order sorts rewards from low rarity to high rarity")
	_assert_eq(presentation.get("revealOrderRarityVfx", []), ["common", "rare", "epic", "legendary"], "reward ceremony uses fixed rarity VFX tiers that match the real reveal order")
	if RewardRevealOverlayScript.has_method("reveal_timing_profile"):
		var timing = RewardRevealOverlayScript.reveal_timing_profile()
		_assert(float(timing.get("countTeaseSmall", 0.0)) >= 2.7, "count tease holds long enough for a 2-second white-hot front-tile climax")
		_assert(float(timing.get("countTeaseStandard", 0.0)) >= 2.9, "standard count tease keeps a longer escalation before the burst")
		_assert(float(timing.get("countTeaseJackpot", 0.0)) >= 3.1, "jackpot count tease gives the strongest quantity beat time to register")
		_assert(float(timing.get("countLockHold", 0.0)) >= 1.6, "count burst/opening has enough time to read as an explosion rather than a quick cut")
		_assert(float(timing.get("revealCommon", 0.0)) >= 3.0, "common artifact reveal keeps at least 3 seconds of anticipation")
		_assert(float(timing.get("revealRare", 0.0)) >= 3.4, "rare artifact reveal gets a longer anticipation beat than common")
		_assert(float(timing.get("revealEpic", 0.0)) >= 4.0, "epic artifact reveal holds around 4 seconds before identity")
		_assert(float(timing.get("revealLegendary", 0.0)) >= 4.6, "legendary artifact reveal approaches the 5-second anticipation ceiling")
		_assert(float(timing.get("revealLegendary", 99.0)) <= 5.0, "legendary artifact reveal stays within the requested 3-5 second range")
	TextCatalogScript.set_locale("ko")

func test_reward_reveal_quantity_tease_uses_three_bands() -> void:
	TextCatalogScript.set_locale("en")
	var RewardRevealOverlayScript = load("res://src/ui/RewardRevealOverlay.gd")
	_assert(RewardRevealOverlayScript != null, "reward ceremony overlay script loads for quantity tease band contract")
	if RewardRevealOverlayScript == null or not RewardRevealOverlayScript.has_method("build_presentation_model"):
		TextCatalogScript.set_locale("ko")
		return
	_assert_eq(str(RewardRevealOverlayScript.build_presentation_model([{"kind": "One", "rarity": "common"}]).get("quantityTeaseBand", "")), "small", "one reward uses the compact 1-2 reward tease band")
	_assert_eq(str(RewardRevealOverlayScript.build_presentation_model([{"kind": "One", "rarity": "common"}, {"kind": "Two", "rarity": "rare"}]).get("quantityTeaseBand", "")), "small", "two rewards still use the compact 1-2 reward tease band")
	_assert_eq(str(RewardRevealOverlayScript.build_presentation_model([{"kind": "One", "rarity": "common"}, {"kind": "Two", "rarity": "rare"}, {"kind": "Three", "rarity": "epic"}]).get("quantityTeaseBand", "")), "standard", "three rewards use the dedicated middle tease band")
	_assert_eq(str(RewardRevealOverlayScript.build_presentation_model([{"kind": "One", "rarity": "common"}, {"kind": "Two", "rarity": "rare"}, {"kind": "Three", "rarity": "epic"}, {"kind": "Four", "rarity": "legendary"}]).get("quantityTeaseBand", "")), "jackpot", "four rewards use the 4-5 jackpot tease band")
	_assert_eq(str(RewardRevealOverlayScript.build_presentation_model([{"kind": "One", "rarity": "common"}, {"kind": "Two", "rarity": "rare"}, {"kind": "Three", "rarity": "epic"}, {"kind": "Four", "rarity": "legendary"}, {"kind": "Five", "rarity": "mythic"}]).get("quantityTeaseBand", "")), "jackpot", "five rewards also use the 4-5 jackpot tease band")
	TextCatalogScript.set_locale("ko")

func test_reward_reveal_count_tease_hides_exact_count_and_uses_band_preview() -> void:
	var RewardRevealOverlayScript = load("res://src/ui/RewardRevealOverlay.gd")
	_assert(RewardRevealOverlayScript != null, "reward ceremony overlay script loads for count tease concealment contract")
	if RewardRevealOverlayScript == null:
		return
	_assert(RewardRevealOverlayScript.has_method("count_tease_preview_model"), "reward ceremony overlay exposes a count tease preview helper")
	if not RewardRevealOverlayScript.has_method("count_tease_preview_model"):
		return
	var one = RewardRevealOverlayScript.count_tease_preview_model(1)
	var two = RewardRevealOverlayScript.count_tease_preview_model(2)
	var three = RewardRevealOverlayScript.count_tease_preview_model(3)
	var four = RewardRevealOverlayScript.count_tease_preview_model(4)
	var five = RewardRevealOverlayScript.count_tease_preview_model(5)
	_assert_eq(bool(one.get("exactCountVisible", true)), false, "count tease keeps the exact reward count hidden for a single reward")
	_assert_eq(bool(two.get("exactCountVisible", true)), false, "count tease keeps the exact reward count hidden for the 1-2 reward band")
	_assert_eq(bool(three.get("exactCountVisible", true)), false, "count tease keeps the exact reward count hidden for the 3 reward band")
	_assert_eq(int(one.get("previewLidCount", 0)), 1, "count tease uses a single sealed chamber silhouette instead of exposing exact reward slots")
	_assert_eq(int(two.get("previewLidCount", 0)), 1, "two rewards still keep a single sealed chamber silhouette during tease")
	_assert_eq(int(three.get("previewLidCount", 0)), 1, "three rewards still keep a single sealed chamber silhouette during tease")
	_assert_eq(int(four.get("previewLidCount", 0)), 1, "four rewards still keep a single sealed chamber silhouette during tease")
	_assert_eq(int(five.get("previewLidCount", 0)), 1, "five rewards still keep a single sealed chamber silhouette during tease")
	_assert_eq(int(one.get("visibleRewardTokenCount", -1)), 0, "count tease never draws reward tokens before the burst")
	_assert_eq(int(two.get("visibleRewardTokenCount", -1)), 0, "two rewards still hide all reward tokens during tease")
	_assert_eq(int(three.get("visibleRewardTokenCount", -1)), 0, "three rewards do not leak the exact count through three visible lights")
	_assert_eq(int(four.get("visibleRewardTokenCount", -1)), 0, "four rewards do not leak the exact count before the burst")
	_assert_eq(int(five.get("visibleRewardTokenCount", -1)), 0, "five rewards do not leak the exact count before the burst")
	_assert_eq(str(one.get("countClueStyle", "")), "single_terrain_lid_charge", "count tease uses the terrain lid as the only visible clue")
	_assert_eq(str(three.get("countClueStyle", "")), "single_terrain_lid_charge", "middle-band count tease still uses one charged terrain lid")
	_assert_eq(str(five.get("countClueStyle", "")), "single_terrain_lid_charge", "jackpot-band count tease still uses one charged terrain lid")

func test_reward_reveal_mined_lid_pops_from_terrain_before_count_burst() -> void:
	var RewardRevealOverlayScript = load("res://src/ui/RewardRevealOverlay.gd")
	_assert(RewardRevealOverlayScript != null, "reward ceremony overlay script loads for mined-lid motion contract")
	if RewardRevealOverlayScript == null:
		return
	_assert(RewardRevealOverlayScript.has_method("center_lid_layout_model"), "reward ceremony overlay exposes center lid layout model")
	_assert(RewardRevealOverlayScript.has_method("mined_lid_motion_model"), "reward ceremony overlay exposes mined lid motion model")
	_assert(RewardRevealOverlayScript.has_method("count_burst_model"), "reward ceremony overlay exposes count burst model")
	_assert(RewardRevealOverlayScript.has_method("count_burst_animation_model"), "reward ceremony overlay exposes count burst animation model")
	var closed_lid := Rect2()
	if RewardRevealOverlayScript.has_method("center_lid_layout_model"):
		var layout = RewardRevealOverlayScript.center_lid_layout_model(Vector2(1440.0, 900.0))
		closed_lid = layout.get("closedLidRect", Rect2())
		_assert(float(layout.get("aspectRatio", 0.0)) > 5.0, "center lid keeps the wide terrain tile aspect instead of collapsing into a tall plaque")
		_assert(closed_lid.size.x > closed_lid.size.y * 5.0, "center lid remains a long horizontal tile so the bottom edge does not look clipped")
	if RewardRevealOverlayScript.has_method("mined_lid_motion_model"):
		var source_rect := Rect2(Vector2(260.0, 620.0), Vector2(96.0, 58.0))
		var motion = RewardRevealOverlayScript.mined_lid_motion_model(source_rect, Vector2(1440.0, 900.0), 0.35, 3)
		var climax_motion = RewardRevealOverlayScript.mined_lid_motion_model(source_rect, Vector2(1440.0, 900.0), 0.86, 3)
		var final_motion = RewardRevealOverlayScript.mined_lid_motion_model(source_rect, Vector2(1440.0, 900.0), 1.0, 3)
		_assert_eq(str(motion.get("texturePath", "")), "res://resources/UI/tile/tile_panel_nobg.png", "mined lid uses the terrain tile texture as the popped source")
		_assert_eq(str(motion.get("sourceRole", "")), "terrain_lid_clone", "mined lid is a cloned terrain lid, not the real battlefield tile")
		_assert_eq(bool(motion.get("preservesBattlefield", false)), true, "mined lid animation does not move the real battlefield UI")
		_assert_eq(bool(motion.get("exactCountVisible", true)), false, "mined lid motion hides exact count while charging")
		_assert_eq(bool(motion.get("identityVisible", true)), false, "mined lid motion hides item identity while charging")
		_assert(float(motion.get("sparkRate", 0.0)) > float(motion.get("baseSparkRate", 999.0)), "mined lid spark rate accelerates during charge")
		_assert(float(motion.get("currentRect", Rect2()).position.y) < source_rect.position.y, "mined lid moves upward from the terrain toward the center")
		_assert_eq(str(motion.get("drawOrder", "")), "halo_behind_lid_front_flash", "mined lid draw order keeps the halo behind and redraws the terrain tile in front")
		_assert(float(climax_motion.get("frontTileFlashAlpha", 0.0)) >= 0.75, "count tease climax makes the tile image itself flash white-hot")
		_assert(float(final_motion.get("highlightHoldSeconds", 0.0)) >= 2.0, "count tease model reserves at least two seconds for the high-intensity hold")
		_assert_eq(final_motion.get("targetRect", Rect2()), closed_lid, "count tease target rect matches the shared closed lid layout")
	if RewardRevealOverlayScript.has_method("count_burst_model"):
		var burst = RewardRevealOverlayScript.count_burst_model(4)
		_assert_eq(bool(burst.get("exactCountVisible", false)), true, "count burst is the first state allowed to show exact count")
		_assert_eq(int(burst.get("rewardTokenCount", 0)), 4, "count burst reveals the real reward count")
		_assert_eq(str(burst.get("quantityBand", "")), "jackpot", "count burst keeps the 4-5 jackpot band")
		var overflow_burst = RewardRevealOverlayScript.count_burst_model(6)
		_assert_eq(int(overflow_burst.get("rewardTokenCount", 0)), 6, "count burst keeps the real count even if a future table exceeds five rewards")
		_assert_eq(int(overflow_burst.get("visualTokenCount", 0)), 5, "count burst clamps only the visual token layout to five")
	if RewardRevealOverlayScript.has_method("count_burst_animation_model"):
		var burst_start = RewardRevealOverlayScript.count_burst_animation_model(Vector2(1440.0, 900.0), 0.0, 3)
		var burst_mid = RewardRevealOverlayScript.count_burst_animation_model(Vector2(1440.0, 900.0), 0.65, 3)
		_assert_eq(burst_start.get("closedLidRect", Rect2()), closed_lid, "count burst starts from the same closed lid rect as the tease")
		_assert_eq(float(burst_start.get("orbRevealAlpha", 1.0)), 0.0, "orbs are still hidden at the very start of count burst")
		_assert_eq(str(burst_mid.get("openingStyle", "")), "upward_cap_pop_explosion", "count burst pops the lid upward instead of opening as side doors")
		_assert(float(burst_mid.get("lidCapOffset", Vector2.ZERO).y) < -float(closed_lid.size.y), "popped lid cap travels upward far enough to read as flying off")
		_assert(absf(float(burst_mid.get("lidCapRotationDegrees", 0.0))) >= 18.0, "popped lid cap rotates while flying away")
		_assert(int(burst_mid.get("fragmentCount", 0)) >= 12, "count burst throws enough fragments to feel like a seal explosion")
		_assert(float(burst_mid.get("orbRevealAlpha", 0.0)) > 0.4, "orbs become visible while the lid is popping away")
		_assert(float(burst_mid.get("orbRiseDistance", 0.0)) > 0.0, "orbs rise out of the lid instead of appearing statically in place")
		_assert_eq(str(burst_mid.get("orbMotionStyle", "")), "buoyant_arc_silhouette", "reward orb silhouettes use a buoyant arc instead of a static popup")

func test_reward_reveal_count_tease_auto_advances_to_count_lock() -> void:
	var RewardRevealOverlayScript = load("res://src/ui/RewardRevealOverlay.gd")
	_assert(RewardRevealOverlayScript != null, "reward ceremony overlay script loads for count-tease auto-advance contract")
	if RewardRevealOverlayScript == null:
		return
	var overlay = RewardRevealOverlayScript.new()
	overlay.size = Vector2(1440.0, 900.0)
	overlay.start_reveal(
		[
			{"kind": "Dust Charm", "rarity": "common", "payload": {"item_type": "relic", "energy_type": "green"}},
			{"kind": "Ruby Drill", "rarity": "rare", "payload": {"item_type": "drill", "energy_type": "red"}}
		],
		Callable(),
		Callable(),
		Rect2(Vector2(260.0, 620.0), Vector2(96.0, 58.0))
	)
	var timing = RewardRevealOverlayScript.reveal_timing_profile()
	_assert_eq(str(overlay.current_step), "count_tease", "reward reveal starts on the lid-opening count tease")
	overlay.call("_process", float(timing.get("countTeaseSmall", 2.8)) + 0.05)
	_assert_eq(str(overlay.current_step), "count_lock", "count tease auto-advances into the item-count burst without confirm input")
	_assert_eq(bool(overlay.readable), false, "auto-entered count lock starts its burst animation instead of showing a continue prompt")
	overlay.call("_process", float(timing.get("countLockHold", 1.8)) + 0.05)
	_assert_eq(str(overlay.current_step), "count_lock", "count lock still waits for confirm after the burst becomes readable")
	_assert_eq(bool(overlay.readable), true, "count lock becomes readable before the card reveal confirmation")
	overlay.free()

func _source_line_count(path: String) -> int:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return 999999
	var line_count := 0
	while not file.eof_reached():
		file.get_line()
		line_count += 1
	file.close()
	return line_count

