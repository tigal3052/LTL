extends "res://tests/support/UiReadModelTestSuite.gd"

const InteractionSfxSynthScript = preload("res://src/ui/presenters/InteractionSfxSynth.gd")
const MainViewFeedbackRuntimeScript = preload("res://src/ui/main_view/MainViewFeedbackRuntime.gd")
const META_SFX_CATEGORY := "_ltl_interaction_sfx_category"

class FakeCombatSfxView:
	extends RefCounted
	var played_categories: Array[String] = []
	func play_interaction_sfx(category: String) -> void:
		played_categories.append(category)

class FakeCombatController:
	extends RefCounted
	var battle_pause_active := false
	var current_scene := {"phase": "combat"}
	var disabled_tiles: Array[String] = ["a1"]
	var view := FakeCombatSfxView.new()
	var cleared_tooltip := false
	func _clear_floating_tooltip() -> void:
		cleared_tooltip = true

func run_all_tests() -> Dictionary:
	failures.clear()
	test_interaction_sfx_descriptors_keep_thunder_for_combat_only()
	test_interaction_sfx_event_inventory_covers_planned_categories()
	test_interaction_sfx_event_inventory_covers_requested_categories()
	test_interaction_sfx_event_inventory_covers_separated_panel_and_fusion_categories()
	test_non_hit_sfx_gain_is_raised_without_boosting_hit_categories()
	test_interaction_sfx_distinguishes_reward_and_excavation_payoffs()
	test_interaction_fx_maps_special_button_categories()
	test_interaction_fx_maps_settings_and_codex_categories()
	test_influence_grid_uses_quieter_yellow_alpha()
	test_invalid_combat_cell_click_requests_reject_sfx()
	test_combat_hit_sfx_descriptors_include_lower_pitch_layer()
	test_item_fusion_sfx_descriptor_is_short_bright_shimmer()
	test_fusion_buildup_and_completion_synth_streams_are_distinct()
	test_item_fusion_synth_stream_uses_short_merge_duration()
	test_interaction_sfx_volume_controls_player_db()
	test_page_transition_sfx_only_when_page_changes()
	return _result()

func test_interaction_sfx_descriptors_keep_thunder_for_combat_only() -> void:
	var chrome = MainViewChromeRuntimeScript.new()
	var categories := ["ui_click", "ui_confirm", "ui_cancel", "ui_toggle", "battle_start", "starter_set_select", "menu_open", "menu_close", "page_transition", "drag_start", "drag_drop", "drag_cancel", "item_click", "item_place", "item_fusion", "typewriter_tick", "dialogue_advance", "reward_expectation", "reward_count_fanfare", "excavation_buildup", "excavation_detail_fanfare", "combat_hit", "combat_strong_hit", "combat_miss"]
	for category in categories:
		_assert(chrome.has_method("sfx_descriptor_for_category"), "chrome runtime exposes semantic SFX descriptors")
		if not chrome.has_method("sfx_descriptor_for_category"):
			return
		var descriptor: Dictionary = chrome.call("sfx_descriptor_for_category", category)
		_assert_eq(str(descriptor.get("category", "")), category, "SFX descriptor keeps the requested category id")
		_assert(float(descriptor.get("gainDb", 0.0)) <= -6.0, "SFX descriptor keeps interaction sounds below full-scale output")
		var tone_family := str(descriptor.get("toneFamily", ""))
		if category in ["combat_hit", "combat_strong_hit"]:
			_assert_eq(tone_family, "thunder", "combat hit descriptors are the only thunder-like sounds")
		else:
			_assert(tone_family != "thunder", "non-combat descriptor %s never uses thunder tone" % category)

func test_interaction_sfx_event_inventory_covers_planned_categories() -> void:
	var chrome = MainViewChromeRuntimeScript.new()
	_assert(chrome.has_method("sfx_event_inventory"), "chrome runtime exposes the planned SFX event inventory")
	if not chrome.has_method("sfx_event_inventory"):
		return
	var inventory: Array = chrome.call("sfx_event_inventory")
	var categories := []
	for event in inventory:
		if event is Dictionary:
			categories.append(str(event.get("category", "")))
	for expected in ["ui_click", "ui_confirm", "ui_cancel", "menu_open", "menu_close", "page_transition", "drag_start", "drag_drop", "drag_cancel", "item_fusion", "combat_miss", "combat_hit", "combat_strong_hit", "reward_reveal"]:
		_assert(expected in categories, "SFX inventory includes planned category %s" % expected)

func test_interaction_sfx_event_inventory_covers_requested_categories() -> void:
	var chrome = MainViewChromeRuntimeScript.new()
	_assert(chrome.has_method("sfx_event_inventory"), "chrome runtime exposes SFX inventory for requested categories")
	if not chrome.has_method("sfx_event_inventory"):
		return
	var inventory: Array = chrome.call("sfx_event_inventory")
	var categories := []
	for event in inventory:
		if event is Dictionary:
			categories.append(str(event.get("category", "")))
	for expected in ["ui_toggle", "battle_start", "starter_set_select", "item_click", "item_place", "typewriter_tick", "dialogue_advance", "reward_expectation", "reward_count_fanfare", "excavation_buildup", "excavation_detail_fanfare"]:
		_assert(expected in categories, "SFX inventory includes requested category %s" % expected)

func test_interaction_sfx_event_inventory_covers_separated_panel_and_fusion_categories() -> void:
	var chrome = MainViewChromeRuntimeScript.new()
	_assert(chrome.has_method("sfx_event_inventory"), "chrome runtime exposes SFX inventory for panel-specific categories")
	if not chrome.has_method("sfx_event_inventory"):
		return
	var inventory: Array = chrome.call("sfx_event_inventory")
	var categories := []
	for event in inventory:
		if event is Dictionary:
			categories.append(str(event.get("category", "")))
	for expected in ["settings_open", "settings_close", "codex_open", "codex_close", "fusion_buildup", "fusion_complete"]:
		_assert(expected in categories, "SFX inventory includes separated category %s" % expected)
		var descriptor: Dictionary = chrome.call("sfx_descriptor_for_category", expected)
		_assert_eq(str(descriptor.get("category", "")), expected, "%s descriptor resolves by semantic category" % expected)

func test_non_hit_sfx_gain_is_raised_without_boosting_hit_categories() -> void:
	var chrome = MainViewChromeRuntimeScript.new()
	_assert_eq(float(chrome.call("sfx_descriptor_for_category", "combat_hit").get("gainDb", 0.0)), -8.0, "combat hit gain remains at the prior tuned value")
	_assert_eq(float(chrome.call("sfx_descriptor_for_category", "combat_strong_hit").get("gainDb", 0.0)), -12.0, "strong combat hit gain remains at the prior tuned value")
	for category in ["ui_click", "ui_confirm", "ui_cancel", "ui_toggle", "battle_start", "starter_set_select", "settings_open", "settings_close", "codex_open", "codex_close", "menu_open", "menu_close", "page_transition", "drag_start", "drag_drop", "drag_cancel", "item_click", "item_place", "item_fusion", "fusion_buildup", "fusion_complete", "typewriter_tick", "dialogue_advance", "reward_expectation", "reward_count_fanfare", "excavation_buildup", "excavation_detail_fanfare", "combat_miss"]:
		var descriptor: Dictionary = chrome.call("sfx_descriptor_for_category", category)
		_assert(not descriptor.is_empty(), "%s descriptor exists for non-hit gain audit" % category)
		if descriptor.is_empty():
			continue
		_assert(float(descriptor.get("gainDb", -80.0)) >= -16.0, "%s gain is raised into the louder non-hit range" % category)

func test_interaction_sfx_distinguishes_reward_and_excavation_payoffs() -> void:
	var chrome = MainViewChromeRuntimeScript.new()
	var reward_build: Dictionary = chrome.call("sfx_descriptor_for_category", "reward_expectation")
	var reward_fanfare: Dictionary = chrome.call("sfx_descriptor_for_category", "reward_count_fanfare")
	var excavation_build: Dictionary = chrome.call("sfx_descriptor_for_category", "excavation_buildup")
	var excavation_fanfare: Dictionary = chrome.call("sfx_descriptor_for_category", "excavation_detail_fanfare")
	_assert_eq(str(reward_build.get("category", "")), "reward_expectation", "reward expectation descriptor exists")
	_assert_eq(str(reward_fanfare.get("category", "")), "reward_count_fanfare", "reward count fanfare descriptor exists")
	_assert_eq(str(excavation_build.get("category", "")), "excavation_buildup", "excavation buildup descriptor exists")
	_assert_eq(str(excavation_fanfare.get("category", "")), "excavation_detail_fanfare", "excavation detail fanfare descriptor exists")
	_assert(str(reward_build.get("toneFamily", "")) != str(excavation_build.get("toneFamily", "")), "reward and excavation buildup cues use different tone families")
	_assert(str(reward_fanfare.get("toneFamily", "")) != str(excavation_fanfare.get("toneFamily", "")), "reward and excavation fanfares are not reused")
	_assert(float(reward_fanfare.get("pitch", 1.0)) != float(excavation_fanfare.get("pitch", 1.0)), "reward and excavation fanfares have distinct pitch profiles")

func test_interaction_fx_maps_special_button_categories() -> void:
	var palette_button := Button.new()
	palette_button.name = "Palette_blue"
	_assert_eq(InteractionFXScript._sfx_category_for(palette_button), "starter_set_select", "starter set color buttons use a dedicated selection cue")
	var toggle_button := Button.new()
	toggle_button.name = "HoldFireButton"
	toggle_button.toggle_mode = true
	_assert_eq(InteractionFXScript._sfx_category_for(toggle_button), "ui_toggle", "toggle buttons use a toggle cue")
	var start_button := Button.new()
	start_button.name = "StartButton"
	start_button.text = "Start"
	_assert_eq(InteractionFXScript._sfx_category_for(start_button), "battle_start", "combat start buttons use the special start cue")
	var explicit_button := Button.new()
	explicit_button.set_meta(META_SFX_CATEGORY, "dialogue_advance")
	_assert_eq(InteractionFXScript._sfx_category_for(explicit_button), "dialogue_advance", "explicit SFX metadata overrides name-based button mapping")
	palette_button.free()
	toggle_button.free()
	start_button.free()
	explicit_button.free()

func test_interaction_fx_maps_settings_and_codex_categories() -> void:
	var settings_button := Button.new()
	settings_button.name = "SettingsOpenButton"
	settings_button.text = "Settings"
	_assert_eq(InteractionFXScript._sfx_category_for(settings_button), "settings_open", "settings buttons use a dedicated settings cue")
	var codex_button := Button.new()
	codex_button.name = "CodexOpenButton"
	codex_button.text = "Artifact Codex"
	_assert_eq(InteractionFXScript._sfx_category_for(codex_button), "codex_open", "artifact codex buttons use a dedicated codex cue")
	settings_button.free()
	codex_button.free()

func test_influence_grid_uses_quieter_yellow_alpha() -> void:
	var style: StyleBoxFlat = BackpackGridFactoryScript.influence_range_style()
	_assert(style.bg_color.a <= 0.24, "yellow influence grid fill is more transparent than the old heavy overlay")
	_assert(style.border_color.a <= 0.48, "yellow influence grid border is also softened")

func test_invalid_combat_cell_click_requests_reject_sfx() -> void:
	var controller := FakeCombatController.new()
	MainControllerCombatFlowScript.on_cell_clicked(controller, "a1", "red")
	_assert(controller.cleared_tooltip, "invalid combat clicks still clear floating tooltip")
	_assert_eq(controller.view.played_categories, ["ui_cancel"], "invalid combat cell clicks request a reject SFX instead of staying silent")

func test_combat_hit_sfx_descriptors_include_lower_pitch_layer() -> void:
	var chrome = MainViewChromeRuntimeScript.new()
	_assert(chrome.has_method("sfx_descriptors_for_category"), "chrome runtime exposes layered SFX descriptors")
	if not chrome.has_method("sfx_descriptors_for_category"):
		return
	for category in ["combat_hit", "combat_strong_hit"]:
		var layers: Array = chrome.call("sfx_descriptors_for_category", category)
		_assert(layers.size() >= 2, "%s includes a base transient and a lower body layer" % category)
		var low_layer := {}
		for layer in layers:
			if layer is Dictionary and str(layer.get("role", "")) == "low_body":
				low_layer = layer
		_assert(not low_layer.is_empty(), "%s exposes a lower-register body layer" % category)
		_assert(float(low_layer.get("pitch", 1.0)) < 0.8, "%s low body layer lowers pitch below the base hit" % category)
		_assert(float(low_layer.get("gainDb", 0.0)) <= -12.0, "%s low body layer stays tucked under the transient" % category)
		_assert(str(low_layer.get("toneFamily", "")).begins_with("thunder"), "%s low body layer remains combat thunder-family only" % category)
	for category in ["ui_click", "menu_open", "drag_start", "page_transition", "item_fusion"]:
		var layers: Array = chrome.call("sfx_descriptors_for_category", category)
		for layer in layers:
			_assert(str(layer.get("role", "")) != "low_body", "non-combat category %s never gets the low hit body layer" % category)

func test_item_fusion_sfx_descriptor_is_short_bright_shimmer() -> void:
	var chrome = MainViewChromeRuntimeScript.new()
	var descriptor: Dictionary = chrome.call("sfx_descriptor_for_category", "item_fusion")
	_assert_eq(str(descriptor.get("category", "")), "item_fusion", "fusion descriptor uses the semantic fusion category")
	_assert_eq(str(descriptor.get("toneFamily", "")), "shimmer", "fusion descriptor uses a bright shimmer family instead of combat thunder")
	_assert_eq(str(descriptor.get("streamId", "")), "synth", "fusion descriptor uses the lightweight synthesized UI stream")
	_assert(float(descriptor.get("gainDb", 0.0)) <= -6.0 and float(descriptor.get("gainDb", 0.0)) >= -12.0, "fusion descriptor is raised with the other non-hit interaction sounds")
	_assert(float(descriptor.get("pitch", 1.0)) > 1.0, "fusion descriptor lifts pitch slightly for a born-item cue")
	_assert(int(descriptor.get("cooldownMs", 0)) >= 160, "fusion descriptor rate-limits repeated merge cues")

func test_fusion_buildup_and_completion_synth_streams_are_distinct() -> void:
	var chrome = MainViewChromeRuntimeScript.new()
	var buildup: Dictionary = chrome.call("sfx_descriptor_for_category", "fusion_buildup")
	var complete: Dictionary = chrome.call("sfx_descriptor_for_category", "fusion_complete")
	_assert_eq(str(buildup.get("toneFamily", "")), "fusion_beat", "fusion buildup uses a beat-like tension cue")
	_assert_eq(str(complete.get("toneFamily", "")), "fusion_fanfare", "fusion completion uses a celebratory payoff cue")
	_assert(float(complete.get("pitch", 0.0)) > float(buildup.get("pitch", 9.0)), "fusion completion pitch lifts above the buildup")
	var buildup_stream: AudioStreamWAV = InteractionSfxSynthScript.create_stream("fusion_buildup")
	var complete_stream: AudioStreamWAV = InteractionSfxSynthScript.create_stream("fusion_complete")
	_assert(float(buildup_stream.data.size()) / float(InteractionSfxSynthScript.MIX_RATE) >= 0.32, "fusion buildup stream has enough duration for tension")
	_assert(float(complete_stream.data.size()) / float(InteractionSfxSynthScript.MIX_RATE) >= 0.24, "fusion complete stream has a short celebratory tail")

func test_item_fusion_synth_stream_uses_short_merge_duration() -> void:
	var stream: AudioStreamWAV = InteractionSfxSynthScript.create_stream("item_fusion")
	_assert(stream != null, "fusion SFX synthesizer returns a stream")
	if stream == null:
		return
	var duration := float(stream.data.size()) / float(InteractionSfxSynthScript.MIX_RATE)
	_assert(duration >= 0.16 and duration <= 0.22, "fusion SFX stream is a short merge shimmer")

func test_interaction_sfx_volume_controls_player_db() -> void:
	var view := MainViewRuntimeScript.new()
	view._create_giant_timer()
	var chrome = MainViewChromeRuntimeScript.new()
	_assert(chrome.has_method("ensure_interaction_sfx_players"), "chrome runtime creates reusable interaction SFX players")
	_assert(chrome.has_method("set_volume"), "chrome runtime applies shared sound volume")
	if not chrome.has_method("ensure_interaction_sfx_players"):
		view.free()
		return
	chrome.call("ensure_interaction_sfx_players", view)
	_assert(view.interaction_sfx_players.size() >= 2, "interaction SFX uses a reusable player pool")
	chrome.call("set_volume", view, 0.0)
	for player in view.interaction_sfx_players:
		_assert(float(player.volume_db) <= -79.0, "volume zero mutes each interaction SFX player")
	chrome.call("set_volume", view, 75.0)
	for player in view.interaction_sfx_players:
		_assert(float(player.volume_db) > -10.0 and float(player.volume_db) < 0.0, "shared volume slider applies normal SFX gain to each player")
	view.free()

func test_page_transition_sfx_only_when_page_changes() -> void:
	var view := MainViewRuntimeScript.new()
	var chrome = MainViewChromeRuntimeScript.new()
	_assert(chrome.has_method("page_transition_sfx_category"), "chrome runtime exposes a page-change SFX gate")
	if not chrome.has_method("page_transition_sfx_category"):
		view.free()
		return
	view._last_sfx_page_id = "node_select"
	_assert_eq(str(chrome.call("page_transition_sfx_category", view, "node_select")), "", "same page render does not request a page transition sound")
	_assert_eq(str(chrome.call("page_transition_sfx_category", view, "battle")), "page_transition", "new page id requests one page transition sound")
	_assert_eq(str(view._last_sfx_page_id), "battle", "page transition gate records the last sounded page id")
	view.free()
