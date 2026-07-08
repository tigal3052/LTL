extends "res://tests/support/UiReadModelTestSuite.gd"
func run_all_tests() -> Dictionary:
	failures.clear()
	reward_reveal_cancel_done_calls = 0
	test_tooltip_projects_reward_dictionary()
	test_tooltip_projects_relic_reward_dictionary()
	test_tooltip_projects_effect_schema_summary()
	test_tooltip_projects_artifact_object()
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
