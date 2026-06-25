extends "res://tests/support/UiReadModelTestSuite.gd"
func run_all_tests() -> Dictionary:
	failures.clear()
	reward_reveal_cancel_done_calls = 0
	test_reward_drill_tooltip_compares_same_color_equipped_drill()
	test_fusion_preview_tooltip_shows_before_and_after_columns()
	test_artifact_tooltip_panel_can_render_opaque_fusion_variant()
	test_reward_beacon_tooltip_does_not_show_equipped_drill_comparison()
	test_reward_relic_tooltip_does_not_show_equipped_drill_comparison()
	test_reward_read_model_uses_localized_reward_text()
	return _result()
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

func test_fusion_preview_tooltip_shows_before_and_after_columns() -> void:
	TextCatalogScript.set_locale("ko")
	var existing = ArtifactScript.new({
		"id": "ruby_a",
		"name": "Ruby Drill",
		"catalogId": "ruby_drill_common",
		"shape": [[1]],
		"energyType": "red",
		"item_type": "drill",
		"baseCooldownTicks": 90,
		"damage": 2.0,
		"grade": "common"
	})
	var incoming = ArtifactScript.new({
		"id": "ruby_b",
		"name": "Ruby Drill",
		"catalogId": "ruby_drill_common",
		"shape": [[1]],
		"energyType": "red",
		"item_type": "drill",
		"baseCooldownTicks": 90,
		"damage": 2.0,
		"grade": "common"
	})
	var model = TooltipReadModelScript.project_fusion_preview(existing, incoming, "ko")
	var text := str(model.get("bbcode", ""))
	_assert(text.contains(TextCatalogScript.t("tooltip.fusion_before", [], "ko")), "fusion tooltip shows the before-fusion column")
	_assert(text.contains(TextCatalogScript.t("tooltip.fusion_after", [], "ko")), "fusion tooltip shows the after-fusion column")
	_assert(text.contains(TextCatalogScript.display_name("Ruby Drill", "ko")), "fusion tooltip includes the fused item name")
	_assert(text.contains(TextCatalogScript.t("tooltip.cooldown", [], "ko")), "fusion tooltip compares cooldown")
	_assert(text.contains(TextCatalogScript.t("tooltip.damage", [], "ko")), "fusion tooltip compares damage")
	_assert_close(float(model.get("panelAlpha", 0.0)), 1.0, 0.001, "fusion tooltip requests an opaque comparison panel")

func test_artifact_tooltip_panel_can_render_opaque_fusion_variant() -> void:
	var tooltip = ArtifactTooltipUIScript.new()
	tooltip._ready()
	var style := tooltip.get_theme_stylebox("panel") as StyleBoxFlat
	_assert(style != null, "artifact tooltip installs a panel stylebox")
	if style != null:
		_assert_close(style.bg_color.a, 0.95, 0.001, "ordinary artifact tooltip keeps the existing near-opaque panel background")
	tooltip.show_text("fusion", {"panelAlpha": 1.0})
	style = tooltip.get_theme_stylebox("panel") as StyleBoxFlat
	_assert(style != null, "artifact tooltip keeps a panel stylebox after variant styling")
	if style != null:
		_assert_close(style.bg_color.a, 1.0, 0.001, "fusion comparison tooltip can request a strictly opaque panel background")
	tooltip.show_text("ordinary")
	style = tooltip.get_theme_stylebox("panel") as StyleBoxFlat
	if style != null:
		_assert_close(style.bg_color.a, 0.95, 0.001, "ordinary tooltip rendering resets the panel background to its default alpha")
	tooltip.free()

# ?ㅽ뻾: verify beacon rewards do not render a missing-drill comparison column.
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
