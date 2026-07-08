extends "res://tests/support/UiReadModelTestSuite.gd"

func run_all_tests() -> Dictionary:
	failures.clear()
	reward_reveal_cancel_done_calls = 0
	test_node_select_projects_candidates()
	test_node_select_omits_baseline_reward_noise()
	test_reward_tray_projects_lines_and_discard_zone()
	test_reward_tray_inspector_uses_rolled_reward_payload_stats()
	test_reward_tray_empty_inspector_reserves_stable_shell()
	test_reward_tray_backpack_inspector_localizes_starter_loadout_artifact()
	test_reward_tray_backpack_inspector_falls_back_to_primary_stats_when_description_is_missing()
	test_reward_tray_relic_inspector_uses_not_applicable_energy_and_expanded_effect()
	test_reward_board_helper_copy_is_removed()
	return _result()

func test_node_select_projects_candidates() -> void:
	TextCatalogScript.set_locale("ko")
	var scene = {"nodeSelect": {"candidates": [{"id": "normal", "label": "Normal Node", "weaknessLabel": "red"}, {"id": "elite", "label": "Elite Node", "weaknessLabel": "blue"}]}}
	var model = NodeSelectReadModelScript.project(scene, 1)
	_assert(str(model["text"]).contains(TextCatalogScript.display_name("Elite Node", "ko")), "node select includes candidate label")
	_assert(str(model["text"]).contains("[url=1]"), "node select includes candidate link")
	_assert(str(model["text"]).contains("color=#ffd766"), "node select highlights selected candidate")

# 실행: verify baseline node cards do not repeat low-signal reward fields.
func test_node_select_omits_baseline_reward_noise() -> void:
	TextCatalogScript.set_locale("ko")
	var scene = {"nodeSelect": {"candidates": [
		{"id": "normal", "label": "Safe Scar", "weaknessLabel": "red", "riskTier": "safe", "rewardBias": "baseline", "recommendedBuildHint": ""},
		{"id": "hazard", "label": "Hazard Rich", "weaknessLabel": "green", "riskTier": "danger", "rewardBias": "rarity_up", "recommendedBuildHint": "Repair-ready queue"}
	]}}
	var text := str(NodeSelectReadModelScript.project(scene, 0)["text"])
	_assert(text.contains(TextCatalogScript.display_name("Safe Scar", "ko")), "node select localizes baseline label")
	_assert(not text.contains(TextCatalogScript.t("node.card.reward", [TextCatalogScript.enum_label("reward_bias", "baseline", "ko")], "ko")), "baseline node omits baseline reward noise")
	_assert(text.contains(TextCatalogScript.t("node.card.reward", [TextCatalogScript.enum_label("reward_bias", "rarity_up", "ko")], "ko")), "non-baseline node keeps reward bias")

# 실행: verify reward tray read model formats reward lines and discard state.
func test_reward_tray_projects_lines_and_discard_zone() -> void:
	var rewards := [{
		"kind": "Ruby Drill",
		"rarity": "rare",
		"qty": 1,
		"presentation": {"badge": "instant"},
		"payload": {"item_type": "drill", "energy_type": "red", "shape": [[1, 1]]}
	}]
	var held = ArtifactScript.new({"id": "held", "name": "Held Drill", "shape": [[1]], "energyType": "red", "item_type": "drill"})
	var model = RewardReadModelScript.project_tray(rewards, 0, held, true)
	_assert_eq(int(model.get("remainingCount", -1)), 1, "reward tray tracks the remaining reward count")
	_assert_eq(model.get("cards", []).size(), 1, "reward tray projects one card instead of a plain text list")
	var first_card: Dictionary = model.get("cards", [])[0]
	_assert_eq(bool(first_card.get("selected", false)), true, "reward tray marks the selected reward card")
	_assert_eq(str(first_card.get("itemType", "")), "drill", "reward tray keeps the projected item type on each card")
	_assert_eq(int(first_card.get("occupiedCellCount", 0)), 2, "reward tray projects backpack footprint cell count per card")
	var inspector: Dictionary = model.get("inspector", {})
	_assert_eq(bool(inspector.get("empty", true)), false, "reward tray opens the fixed inspector when a reward is selected")
	_assert_eq(str(inspector.get("name", "")), str(first_card.get("name", "")), "reward tray inspector uses the selected reward title")
	_assert_eq(model["discardActive"], true, "reward tray discard active when held")
	_assert(str(model["discardText"]).contains(str(first_card.get("name", ""))), "reward tray discard text uses the selected reward name")

func test_reward_tray_inspector_uses_rolled_reward_payload_stats() -> void:
	TextCatalogScript.set_locale("en")
	var rewards := [{
		"kind": "Rolled Ruby Drill",
		"rarity": "rare",
		"qty": 1,
		"payload": {
			"item_type": "drill",
			"energy_type": "red",
			"shape": [[1]],
			"base_cooldown_ticks": 64,
			"damage": 7.7,
			"roll_quality": 92,
			"stat_roll": {"quality": 92, "base_damage": 6.8, "base_cooldown_ticks": 72}
		},
		"text": {"name": {"en": "Rolled Ruby Drill", "ko": "Rolled Ruby Drill"}, "description": {"en": "", "ko": ""}},
		"presentation": {"description": ""}
	}]
	var model = RewardReadModelScript.project_tray(rewards, -1, null, false, 0, null)
	var inspector: Dictionary = model.get("inspector", {})
	var effect_fact := _fact_by_label(inspector.get("facts", []), TextCatalogScript.t("reward.board.fact.effect"))
	var effect_value := str(effect_fact.get("value", ""))
	_assert(effect_value.contains("32"), "reward inspector cooldown comes from the rolled payload after tempo scaling")
	_assert(effect_value.contains("7.7"), "reward inspector damage comes from the rolled payload")
	TextCatalogScript.set_locale("ko")

func test_reward_tray_empty_inspector_reserves_stable_shell() -> void:
	var rewards := [{
		"kind": "Violet Static Needle",
		"rarity": "common",
		"qty": 1,
		"payload": {"item_type": "drill", "energy_type": "purple", "shape": [[1, 1], [1, 0]]},
		"text": {
			"name": {"ko": "보랏빛 스태틱 니들", "en": "Violet Static Needle"},
			"description": {
				"ko": "보랏빛 스태틱 니들 · 일반 드릴 유물입니다. 보라 계열은 표식, 메아리, 약화 지형, 위치 연계를 다룹니다.",
				"en": "A common purple drill artifact focused on marks, echoes, weakened terrain, and positional links."
			}
		}
	}]
	var model = RewardReadModelScript.project_tray(rewards, -1, null, false, -1, null)
	var inspector: Dictionary = model.get("inspector", {})
	_assert_eq(bool(inspector.get("empty", false)), true, "reward tray starts with the fixed inspector in its empty state before selection")
	_assert_eq(inspector.get("facts", []).size(), 3, "empty reward inspector keeps the three visible fact slots so the board does not reflow when selection appears")
	var empty_shape: Array = inspector.get("shapeMatrix", [])
	_assert_eq(empty_shape.size(), 2, "empty reward inspector keeps a two-row footprint shell")
	if empty_shape.size() >= 1:
		_assert_eq((empty_shape[0] as Array).size(), 4, "empty reward inspector keeps a four-column footprint shell")

func test_reward_tray_backpack_inspector_localizes_starter_loadout_artifact() -> void:
	TextCatalogScript.set_locale("ko")
	var starter_loadout: Array = ArtifactScript.get_starter_loadout("purple")
	_assert(starter_loadout.size() >= 1, "starter loadout exposes at least one artifact for backpack inspector projection")
	if starter_loadout.is_empty():
		return
	var model = RewardReadModelScript.project_tray([], -1, null, false, -1, starter_loadout[0])
	var inspector: Dictionary = model.get("inspector", {})
	_assert_eq(str(inspector.get("name", "")), "보라 시작 드릴", "starter backpack artifact inspector uses localized title text instead of the raw English fallback")
	_assert(not str(inspector.get("summary", "")).is_empty(), "starter backpack artifact inspector keeps a non-empty summary so the right panel does not collapse")
	TextCatalogScript.set_locale("ko")

func test_reward_tray_backpack_inspector_falls_back_to_primary_stats_when_description_is_missing() -> void:
	TextCatalogScript.set_locale("en")
	var artifact = ArtifactScript.new({
		"id": "fallback_stat_drill",
		"name": "Fallback Stat Drill",
		"shape": [[1]],
		"energyType": "purple",
		"baseCooldownTicks": 50,
		"damage": 1.4,
		"grade": "basic",
		"item_type": "drill"
	})
	var model = RewardReadModelScript.project_tray([], -1, null, false, -1, artifact)
	var inspector: Dictionary = model.get("inspector", {})
	var summary := str(inspector.get("summary", ""))
	_assert(summary.contains("Cooldown"), "artifacts without lore text fall back to a stat summary instead of leaving the inspector blank")
	_assert(summary.contains("Damage"), "artifact stat fallback keeps the key drill stats readable in the inspector summary")
	TextCatalogScript.set_locale("ko")

func test_reward_tray_relic_inspector_uses_not_applicable_energy_and_expanded_effect() -> void:
	TextCatalogScript.set_locale("en")
	var effect_copy := "Connected drills receive the next-step repair finish bonus."
	var rewards := [{
		"kind": "Repair Relay Coil",
		"rarity": "common",
		"qty": 1,
		"presentation": {"badge": "common relic"},
		"payload": {
			"item_type": "relic",
			"energy_type": "",
			"shape": [[1]],
			"effect_schema": {
				"link_mode": "diagonal_1",
				"summary_i18n": {"en": effect_copy, "ko": effect_copy}
			}
		},
		"text": {
			"name": {"en": "Repair Relay Coil", "ko": "Repair Relay Coil"},
			"description": {"en": effect_copy, "ko": effect_copy}
		}
	}]
	var model = RewardReadModelScript.project_tray(rewards, -1, null, false, 0, null)
	var inspector: Dictionary = model.get("inspector", {})
	var facts: Array = inspector.get("facts", [])
	var labels := _fact_labels(facts)
	var energy_fact := _fact_by_label(facts, TextCatalogScript.t("reward.board.fact.energy"))
	var effect_fact := _fact_by_label(facts, TextCatalogScript.t("reward.board.fact.effect"))
	_assert_eq(facts.size(), 3, "relic reward inspector removes the source fact so the effect panel can use that area")
	_assert(not labels.has(TextCatalogScript.t("reward.board.fact.source")), "relic reward inspector omits the source fact label")
	_assert_eq(str(energy_fact.get("value", "")), TextCatalogScript.t("reward.board.fact.energy.none"), "relic reward inspector marks energy as not applicable instead of copying effect text")
	_assert(str(effect_fact.get("value", "")).contains(effect_copy), "relic reward inspector keeps the long effect text in the effect fact")
	_assert_eq(int(effect_fact.get("layoutColumns", 1)), 2, "relic reward inspector marks the effect fact as a two-column panel")
	TextCatalogScript.set_locale("ko")

func test_reward_board_helper_copy_is_removed() -> void:
	TextCatalogScript.set_locale("en")
	_assert_eq(TextCatalogScript.t("reward.board.mode_pill"), "", "english reward board mode pill copy removed")
	_assert_eq(TextCatalogScript.t("reward.board.cloud_note"), "", "english reward board reward-cloud helper copy removed")
	_assert_eq(TextCatalogScript.t("reward.board.rewards_zone.hint"), "", "english reward board reward-cloud hint copy removed")
	_assert_eq(TextCatalogScript.t("reward.board.workspace_zone.hint"), "", "english reward board workspace placement-area hint copy removed")
	_assert_eq(TextCatalogScript.t("reward.board.inspector_zone.hint"), "", "english reward board inspector hint copy removed")
	_assert_eq(TextCatalogScript.t("reward.board.discard_zone.hint"), "", "english reward board discard hint copy removed")
	_assert_eq(TextCatalogScript.t("reward.board.confirm_zone.hint"), "", "english reward board confirm hint copy removed")
	_assert_eq(TextCatalogScript.t("reward.board.inspector.kicker"), "", "english reward board inspector kicker removed")
	_assert_eq(TextCatalogScript.t("reward.board.discard_card_title"), "", "english reward board discard card title removed")
	_assert_eq(TextCatalogScript.t("reward.board.claim_ready"), "", "english reward board ready-state claim body removed")
	_assert(not TextCatalogScript.t("discard.idle").contains("Discard Zone"), "english discard idle copy drops the duplicate discard-zone heading")
	_assert(not TextCatalogScript.t("discard.active", ["Test Artifact"]).contains("Discard Zone"), "english discard active copy drops the duplicate discard-zone heading")
	TextCatalogScript.set_locale("ko")
	_assert_eq(TextCatalogScript.t("reward.board.mode_pill"), "", "korean reward board mode pill copy removed")
	_assert_eq(TextCatalogScript.t("reward.board.cloud_note"), "", "korean reward board reward-cloud helper copy removed")
	_assert_eq(TextCatalogScript.t("reward.board.rewards_zone.hint"), "", "korean reward board reward-cloud hint copy removed")
	_assert_eq(TextCatalogScript.t("reward.board.workspace_zone.hint"), "", "korean reward board workspace placement-area hint copy removed")
	_assert_eq(TextCatalogScript.t("reward.board.inspector_zone.hint"), "", "korean reward board inspector hint copy removed")
	_assert_eq(TextCatalogScript.t("reward.board.discard_zone.hint"), "", "korean reward board discard hint copy removed")
	_assert_eq(TextCatalogScript.t("reward.board.confirm_zone.hint"), "", "korean reward board confirm hint copy removed")
	_assert_eq(TextCatalogScript.t("reward.board.inspector.kicker"), "", "korean reward board inspector kicker removed")
	_assert_eq(TextCatalogScript.t("reward.board.discard_card_title"), "", "korean reward board discard card title removed")
	_assert_eq(TextCatalogScript.t("reward.board.claim_ready"), "", "korean reward board ready-state claim body removed")
	_assert(not TextCatalogScript.t("discard.idle").contains("버리기 구역"), "korean discard idle copy drops the duplicate discard-zone heading")
	_assert(not TextCatalogScript.t("discard.active", ["테스트 유물"]).contains("버리기 구역"), "korean discard active copy drops the duplicate discard-zone heading")
	TextCatalogScript.set_locale("ko")

func _fact_by_label(facts: Array, label: String) -> Dictionary:
	for fact in facts:
		if fact is Dictionary and str(fact.get("label", "")) == label:
			return fact
	return {}

func _fact_labels(facts: Array) -> Array:
	var labels: Array = []
	for fact in facts:
		if fact is Dictionary:
			labels.append(str(fact.get("label", "")))
	return labels
