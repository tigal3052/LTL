extends "res://tests/support/UiReadModelTestSuite.gd"

func run_all_tests() -> Dictionary:
	failures.clear()
	reward_reveal_cancel_done_calls = 0
	test_tooltip_projects_reward_dictionary()
	test_tooltip_projects_relic_reward_dictionary()
	test_tooltip_projects_effect_schema_summary()
	test_tooltip_projects_artifact_object()
	test_text_catalog_switches_korean_and_english()
	test_text_catalog_loads_external_locale_json()
	test_text_catalog_korean_names_are_readable()
	test_main_controller_character_roster_reloads_from_locale_catalog()
	test_main_controller_leviathan_roster_reloads_from_locale_catalog()
	test_reward_drill_tooltip_compares_same_color_equipped_drill()
	test_reward_beacon_tooltip_does_not_show_equipped_drill_comparison()
	test_reward_relic_tooltip_does_not_show_equipped_drill_comparison()
	test_reward_read_model_uses_localized_reward_text()
	return _result()

func test_tooltip_projects_reward_dictionary() -> void:
	TextCatalogScript.set_locale("en")
	var reward = {
		"kind": "Azure Beacon",
		"rarity": "rare",
		"payload": {"item_type": "beacon", "energy_type": "blue", "beacon_cooldown_mod": -12, "beacon_damage_mod": 0.4},
		"presentation": {"description": "A test beacon"}
	}
	var model = TooltipReadModelScript.project(reward)
	_assert_eq(model["name"], "Azure Beacon", "tooltip reward name")
	_assert_eq(model["itemType"], "beacon", "tooltip reward item type")
	_assert_eq(model["energyType"], "blue", "tooltip reward energy")
	_assert(str(model["bbcode"]).contains("Azure Beacon"), "tooltip bbcode includes name")
	_assert(str(model["bbcode"]).contains("Beacon pulse effect"), "tooltip bbcode includes beacon effects")
	TextCatalogScript.set_locale("ko")

# ?ㅽ뻾: verify relic reward dictionaries project without color text and expose link metadata.
func test_tooltip_projects_relic_reward_dictionary() -> void:
	TextCatalogScript.set_locale("en")
	var reward = {
		"kind": "Breach Seal",
		"rarity": "common",
		"text": {
			"name": {"ko": "균열 봉인", "en": "Breach Seal"},
			"description": {
				"ko": "?媛곸꽑?쇰줈 ?곌껐???쒕┫??泥??μ븷臾??寃⑹뿉 吏꾪뻾??+1???뷀빀?덈떎.",
				"en": "Adds +1 obstacle progress to the first hit from its diagonally linked drill each combat."
			}
		},
		"payload": {
			"item_type": "relic",
			"energy_type": "",
			"effect_schema": {
				"version": 1,
				"link_mode": "diagonal_1",
				"trigger": "on_obstacle_hit",
				"type": "obstacle_progress_bonus",
				"summary": "Linked drill gains +1 progress on its first obstacle hit each combat.",
				"summary_i18n": {
					"ko": "?곌껐???쒕┫??泥??μ븷臾??寃⑹? ?꾪닾??吏꾪뻾??+1???살뒿?덈떎.",
					"en": "Linked drill gains +1 progress on its first obstacle hit each combat."
				}
			}
		},
		"presentation": {"description": "Fallback relic description"}
	}
	var model = TooltipReadModelScript.project(reward)
	var text := str(model["bbcode"])
	_assert_eq(model["itemType"], "relic", "tooltip relic reward item type")
	_assert_eq(model["energyType"], "", "tooltip relic reward stays colorless")
	_assert(text.contains("Breach Seal"), "relic tooltip includes localized name")
	_assert(text.contains("Common - Relic"), "relic tooltip includes rarity and relic type")
	_assert(text.contains("Relic Link: Diagonal Link"), "relic tooltip includes user-facing link label")
	_assert(text.contains("Linked drill gains +1 progress"), "relic tooltip includes localized effect summary")
	_assert(not text.contains("Energy:"), "relic tooltip hides energy label")
	_assert(not text.contains("Cooldown:"), "relic tooltip hides cooldown label")
	TextCatalogScript.set_locale("ko")

# ?ㅽ뻾: verify Artifact object tooltip data.
func test_tooltip_projects_effect_schema_summary() -> void:
	TextCatalogScript.set_locale("en")
	var reward = {
		"kind": "Overheat Beacon",
		"rarity": "epic",
		"payload": {
			"item_type": "beacon",
			"energy_type": "red",
			"beacon_cooldown_mod": 2,
			"beacon_damage_mod": 0.9,
			"effect_schema": {"version": 1, "trigger": "on_pulse", "type": "overheat_bank", "summary": "Delays the drill, then doubles the next hit."}
		},
		"presentation": {"description": "Red risk beacon"}
	}
	var model = TooltipReadModelScript.project(reward)
	_assert(str(model["bbcode"]).contains("Delays the drill, then doubles the next hit."), "tooltip bbcode includes effect schema summary")
	TextCatalogScript.set_locale("ko")

func test_tooltip_projects_artifact_object() -> void:
	TextCatalogScript.set_locale("ko")
	var artifact = ArtifactScript.new({"id": "ruby", "name": "Ruby Drill", "shape": [[1]], "energyType": "red", "item_type": "drill", "baseCooldownTicks": 80, "damage": 1.5, "grade": "basic"})
	var model = TooltipReadModelScript.project(artifact)
	var bbcode := str(model["bbcode"])
	_assert_eq(model["name"], "루비 드릴", "tooltip artifact name")
	_assert_eq(model["itemType"], "drill", "tooltip artifact item type")
	_assert(bbcode.contains("%s: 80 T" % TextCatalogScript.t("tooltip.cooldown", [], "ko")), "tooltip bbcode includes cooldown")
	_assert(bbcode.contains(TextCatalogScript.t("tooltip.damage", [], "ko")), "tooltip bbcode includes damage")

# ?ㅽ뻾: verify UI strings come from a locale-aware text catalog.
func test_text_catalog_switches_korean_and_english() -> void:
	TextCatalogScript.set_locale("ko")
	_assert_eq(TextCatalogScript.t("action.start"), "전투 시작", "korean text catalog start label")
	_assert_eq(TextCatalogScript.t("item.relic"), "유물", "korean text catalog relic label")
	TextCatalogScript.set_locale("en")
	_assert_eq(TextCatalogScript.t("action.start"), "Start Combat", "english text catalog start label")
	_assert_eq(TextCatalogScript.t("item.relic"), "Relic", "english text catalog relic label")
	TextCatalogScript.set_locale("ko")

# ?ㅽ뻾: verify the text catalog is backed by external locale JSON files.
func test_text_catalog_loads_external_locale_json() -> void:
	var catalog = TextCatalogScript.new()
	_assert(catalog.has_method("catalog_source_path"), "text catalog exposes locale JSON source paths")
	_assert(catalog.has_method("debug_catalog"), "text catalog exposes loaded locale catalogs for regression checks")
	if not catalog.has_method("catalog_source_path") or not catalog.has_method("debug_catalog"):
		return
	var ko_path := str(catalog.call("catalog_source_path", "ko"))
	var en_path := str(catalog.call("catalog_source_path", "en"))
	_assert(ko_path.ends_with("text-ko.json"), "korean locale catalog resolves to text-ko.json")
	_assert(en_path.ends_with("text-en.json"), "english locale catalog resolves to text-en.json")
	var ko_catalog: Dictionary = catalog.call("debug_catalog", "ko")
	var en_catalog: Dictionary = catalog.call("debug_catalog", "en")
	_assert(ko_catalog.has("strings"), "korean locale catalog exposes a strings block")
	_assert(en_catalog.has("strings"), "english locale catalog exposes a strings block")
	_assert(ko_catalog.has("characters"), "korean locale catalog exposes character text blocks")
	_assert(en_catalog.has("leviathans"), "english locale catalog exposes leviathan text blocks")
	_assert_eq(str(ko_catalog.get("strings", {}).get("action.start", "")), "전투 시작", "korean locale JSON contains the start action label")
	_assert_eq(str(en_catalog.get("strings", {}).get("settings.title", "")), "System Calibration", "english locale JSON contains the settings title")

# ?ㅽ뻾: verify Korean display-name mappings are readable.
func test_text_catalog_korean_names_are_readable() -> void:
	TextCatalogScript.set_locale("ko")
	_assert_eq(TextCatalogScript.display_name("Safe Scar"), "안전한 균열", "safe scar korean display name")
	_assert_eq(TextCatalogScript.display_name("Ruby Drill"), "루비 드릴", "ruby drill korean display name")

# ?ㅽ뻾: verify character roster projections rebuild from the active locale catalog.
func test_main_controller_character_roster_reloads_from_locale_catalog() -> void:
	var controller = MainControllerRuntimeScript.new()
	TextCatalogScript.set_locale("ko")
	var korean_roster: Array = controller.call("_load_character_roster")
	TextCatalogScript.set_locale("en")
	var english_roster: Array = controller.call("_load_character_roster")
	_assert(korean_roster.size() > 0, "character roster projects at least one localized row")
	_assert(english_roster.size() > 0, "character roster projects at least one english row")
	if korean_roster.is_empty() or english_roster.is_empty():
		controller.free()
		TextCatalogScript.set_locale("ko")
		return
	_assert_eq(str(korean_roster[0].get("name", "")), TextCatalogScript.character_text("miner", "name", "", "ko"), "character roster uses Korean catalog text when locale is ko")
	_assert_eq(str(english_roster[0].get("name", "")), TextCatalogScript.character_text("miner", "name", "", "en"), "character roster uses English catalog text when locale is en")
	_assert(str(korean_roster[0].get("name", "")) != str(english_roster[0].get("name", "")), "character roster rebuild changes player-facing text across locales")
	controller.free()
	TextCatalogScript.set_locale("ko")

# ?ㅽ뻾: verify leviathan roster projections rebuild from the active locale catalog.
func test_main_controller_leviathan_roster_reloads_from_locale_catalog() -> void:
	var controller = MainControllerRuntimeScript.new()
	TextCatalogScript.set_locale("ko")
	var korean_roster: Array = controller.call("_load_leviathan_roster")
	TextCatalogScript.set_locale("en")
	var english_roster: Array = controller.call("_load_leviathan_roster")
	_assert(korean_roster.size() > 0, "leviathan roster projects at least one localized row")
	_assert(english_roster.size() > 0, "leviathan roster projects at least one english row")
	if korean_roster.is_empty() or english_roster.is_empty():
		controller.free()
		TextCatalogScript.set_locale("ko")
		return
	_assert_eq(str(korean_roster[0].get("name", "")), TextCatalogScript.leviathan_text("ossuary_tortoise", "name", "", "ko"), "leviathan roster uses Korean catalog text when locale is ko")
	_assert_eq(str(english_roster[0].get("name", "")), TextCatalogScript.leviathan_text("ossuary_tortoise", "name", "", "en"), "leviathan roster uses English catalog text when locale is en")
	_assert_eq(str(korean_roster[0].get("biome", "")), TextCatalogScript.leviathan_text("ossuary_tortoise", "biome", "", "ko"), "leviathan biome uses Korean catalog text when locale is ko")
	_assert_eq(str(english_roster[0].get("biome", "")), TextCatalogScript.leviathan_text("ossuary_tortoise", "biome", "", "en"), "leviathan biome uses English catalog text when locale is en")
	controller.free()
	TextCatalogScript.set_locale("ko")

# ?ㅽ뻾: verify reward drill tooltips compare only the equipped drill with the same energy color.
func test_reward_drill_tooltip_compares_same_color_equipped_drill() -> void:
	TextCatalogScript.set_locale("ko")
	var red_drill = ArtifactScript.new({"id": "red_now", "name": "Current Ruby Drill", "shape": [[1]], "energyType": "red", "item_type": "drill", "baseCooldownTicks": 80, "damage": 1.5, "grade": "basic"})
	var blue_drill = ArtifactScript.new({"id": "blue_now", "name": "Current Sapphire Drill", "shape": [[1]], "energyType": "blue", "item_type": "drill", "baseCooldownTicks": 60, "damage": 1.2, "grade": "basic"})
	var reward = {
		"kind": "Reward Ruby Drill",
		"rarity": "rare",
		"text": {
			"name": {"ko": "보상 루비 드릴", "en": "Reward Ruby Drill"},
			"description": {"ko": "붉은 보상 드릴", "en": "Red reward drill"}
		},
		"payload": {"item_type": "drill", "energy_type": "red", "base_cooldown_ticks": 70, "damage": 1.8},
		"presentation": {"description": "Red reward drill"}
	}
	var model = TooltipReadModelScript.project_reward_comparison(reward, [blue_drill, red_drill], "ko")
	var text := str(model["bbcode"])
	_assert(text.contains(TextCatalogScript.t("tooltip.reward_artifact", [], "ko")), "comparison shows reward column")
	_assert(text.contains(TextCatalogScript.t("tooltip.equipped_artifact", [], "ko")), "comparison shows equipped column")
	_assert(text.contains(TextCatalogScript.reward_name(reward, "ko")), "comparison shows localized reward name")
	_assert(text.contains(TextCatalogScript.display_name("Current Ruby Drill", "ko")), "comparison uses same color drill")
	_assert(not text.contains(TextCatalogScript.display_name("Current Sapphire Drill", "ko")), "comparison excludes other color drill")
	_assert(text.contains(TextCatalogScript.t("tooltip.cooldown", [], "ko")), "comparison localizes cooldown label")

# ?ㅽ뻾: verify beacon rewards do not render a missing-drill comparison column.
func test_reward_beacon_tooltip_does_not_show_equipped_drill_comparison() -> void:
	TextCatalogScript.set_locale("ko")
	var red_drill = ArtifactScript.new({"id": "red_now", "name": "Current Ruby Drill", "shape": [[1]], "energyType": "red", "item_type": "drill", "baseCooldownTicks": 80, "damage": 1.5, "grade": "basic"})
	var reward = {"kind": "Amplifying Cooldown Beacon", "rarity": "rare", "payload": {"item_type": "beacon", "energy_type": "red", "beacon_cooldown_mod": -12, "beacon_damage_mod": 0.4}, "presentation": {"description": "Compact 1x1 module. Pulse support."}}
	var model = TooltipReadModelScript.project_reward_comparison(reward, [red_drill], "ko")
	var text := str(model["bbcode"])
	_assert(text.contains(TextCatalogScript.reward_name(reward, "ko")), "beacon tooltip shows reward item")
	_assert(not text.contains(TextCatalogScript.t("tooltip.equipped_artifact", [], "ko")), "beacon tooltip does not show equipped column")
	_assert(not text.contains(TextCatalogScript.t("tooltip.no_same_color_drill", [], "ko")), "beacon tooltip does not show missing drill message")
	_assert(not text.contains("1x1"), "beacon tooltip hides size clutter")

# ?ㅽ뻾: verify relic rewards also bypass drill comparison UI and stay colorless.
func test_reward_relic_tooltip_does_not_show_equipped_drill_comparison() -> void:
	TextCatalogScript.set_locale("ko")
	var red_drill = ArtifactScript.new({"id": "red_now", "name": "Current Ruby Drill", "shape": [[1]], "energyType": "red", "item_type": "drill", "baseCooldownTicks": 80, "damage": 1.5, "grade": "basic"})
	var reward = {
		"kind": "Warning Bell",
		"rarity": "common",
		"text": {
			"name": {"ko": "경고 종", "en": "Warning Bell"},
			"description": {"ko": "??移??꾩썙 ?곌껐???쒕┫??愿?ы븯???μ븷臾?寃쎄퀬 ?쒓컙???섎┰?덈떎.", "en": "Extends warning time for obstacles touched by its one-gap linked drill."}
		},
		"payload": {
			"item_type": "relic",
			"energy_type": "",
			"effect_schema": {
				"version": 1,
				"link_mode": "skip_2",
				"trigger": "on_obstacle_warning",
				"type": "warning_extension",
				"summary": "Linked obstacle warnings last longer.",
				"summary_i18n": {
					"ko": "?곌껐???μ븷臾?寃쎄퀬 ?쒓컙????湲멸쾶 ?좎??⑸땲??",
					"en": "Linked obstacle warnings last longer."
				}
			}
		},
		"presentation": {"description": "Fallback relic description"}
	}
	var model = TooltipReadModelScript.project_reward_comparison(reward, [red_drill], "ko")
	var text := str(model["bbcode"])
	_assert(text.contains(TextCatalogScript.reward_name(reward, "ko")), "relic tooltip shows reward item")
	_assert(text.contains("%s: %s" % [TextCatalogScript.t("tooltip.relic_link", [], "ko"), TextCatalogScript.t("relic_link.skip_2", [], "ko")]), "relic tooltip shows localized link label")
	_assert(not text.contains(TextCatalogScript.t("tooltip.equipped_artifact", [], "ko")), "relic tooltip does not show equipped comparison column")
	_assert(not text.contains(TextCatalogScript.t("tooltip.energy", [], "ko")), "relic tooltip does not show energy label")

# ?ㅽ뻾: verify node select read model formats selected candidates.
func test_reward_read_model_uses_localized_reward_text() -> void:
	var reward = {
		"kind": "Crimson Test Beacon",
		"rarity": "epic",
		"text": {
			"name": {"ko": "吏꾪솉 ?쒗뿕 鍮꾩퐯", "en": "Crimson Test Beacon"},
			"description": {"ko": "?쒗뿕??鍮꾩퐯 ?ㅻ챸", "en": "Test beacon description"}
		},
		"payload": {"item_type": "beacon", "energy_type": "red"},
		"presentation": {"description": "fallback description", "badge": "epic red beacon"}
	}
	TextCatalogScript.set_locale("ko")
	var ko_model = RewardReadModelScript.project(reward)
	TextCatalogScript.set_locale("en")
	var en_model = RewardReadModelScript.project(reward)
	_assert_eq(str(ko_model.get("kind", "")), "吏꾪솉 ?쒗뿕 鍮꾩퐯", "reward read model uses Korean localized name")
	_assert_eq(str(en_model.get("kind", "")), "Crimson Test Beacon", "reward read model uses English localized name")
	_assert_eq(str(ko_model.get("presentation", {}).get("description", "")), "?쒗뿕??鍮꾩퐯 ?ㅻ챸", "reward read model uses Korean localized description")
	_assert_eq(str(en_model.get("presentation", {}).get("description", "")), "Test beacon description", "reward read model uses English localized description")
	TextCatalogScript.set_locale("ko")

