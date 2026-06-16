# 계약:
# - 책임: M4-M9 release-candidate content contracts cover leviathans, characters, base shop, passive tree, hazards, narrative beats, and resource slots.
# - 입력: formal JSON data tables and ReleaseContentVocab public helpers.
# - 출력: run_all_tests result dictionary with deterministic failure labels.
# - 금지: SceneTree dependence, direct UI mutation, prototype runtime dependence.
#
# 실행: define the TestReleaseContentContract class.
extends RefCounted

const ReleaseContentVocabScript = preload("res://src/vocabulary/ReleaseContentVocab.gd")
const NodeVocabScript = preload("res://src/vocabulary/NodeVocab.gd")
const RunGrowthStateScript = preload("res://src/models/RunGrowthState.gd")

var failures: Array[String] = []

# 실행: run release-content contract tests.
func run_all_tests() -> Dictionary:
	failures.clear()
	test_release_tables_validate()
	test_content_counts_support_vertical_slice()
	test_neutral_normal_node_is_safe_route()
	test_hazard_schedule_is_deterministic_and_pin_safe()
	test_base_shop_and_character_purchase_unlocks_choices()
	test_growth_state_base_purchase_serializes()
	test_passive_tree_has_three_branches_and_caps()
	test_narrative_beats_cover_m7_core_beats()
	test_narrative_beats_have_screen_and_skip_contract()
	test_narrative_beats_are_side_effect_free()
	test_resource_manifest_uses_ready_to_swap_paths()
	return {"ok": failures.is_empty(), "errors": failures}

# 실행: verify release tables load and validate as one content bundle.
func test_release_tables_validate() -> void:
	var bundle: Dictionary = ReleaseContentVocabScript.load_content_bundle()
	var validation: Dictionary = ReleaseContentVocabScript.validate_content_bundle(bundle)
	_assert(validation.get("ok", false), "release content bundle validates")

# 실행: verify minimum content counts for an external playtest candidate.
func test_content_counts_support_vertical_slice() -> void:
	var bundle: Dictionary = ReleaseContentVocabScript.load_content_bundle()
	_assert(bundle.get("leviathans", []).size() >= 3, "release content has at least three leviathans")
	_assert(bundle.get("characters", []).size() >= 3, "release content has at least three characters")
	_assert(bundle.get("baseShop", []).size() >= 6, "base shop has starter items and character unlocks")
	_assert(bundle.get("passives", []).size() >= 9, "passive tree has enough nodes for three branches")
	_assert(bundle.get("hazards", []).size() >= 3, "hazard table has freeze wind debris")
	_assert(bundle.get("narrativeBeats", []).size() >= 5, "narrative beats cover first run moments")

# 실행: verify the production normal route is a true neutral safe node.
func test_neutral_normal_node_is_safe_route() -> void:
	var bundle: Dictionary = ReleaseContentVocabScript.load_content_bundle()
	var candidates := NodeVocabScript.generate_candidates(707, 0, {"nodes": bundle.get("nodes", [])}, 5, {"maxStages": 5})
	_assert(candidates.size() >= 1, "release node candidates exist")
	var normal := _find_by_id(candidates, "normal")
	_assert(not normal.is_empty(), "release node candidates include normal")
	_assert_eq(normal.get("weakness", []), [], "normal node has no weakness and avoids mismatch traps")
	_assert_eq(str(normal.get("riskTier", "")), "safe", "normal node risk is safe")
	_assert(float(normal.get("hazardModifier", 0.0)) <= 0.7, "normal node has low hazard pressure")

# 실행: verify hazards warn before applying and never remove timer pins directly.
func test_hazard_schedule_is_deterministic_and_pin_safe() -> void:
	var bundle: Dictionary = ReleaseContentVocabScript.load_content_bundle()
	var schedule_a: Array = ReleaseContentVocabScript.schedule_hazards(9001, 2, bundle.get("hazards", []), 1.2)
	var schedule_b: Array = ReleaseContentVocabScript.schedule_hazards(9001, 2, bundle.get("hazards", []), 1.2)
	_assert_eq(schedule_a, schedule_b, "hazard schedule is deterministic")
	_assert(schedule_a.size() >= 3, "hazard schedule produces stage pressure")
	for event in schedule_a:
		_assert(event.has("warningTick"), "hazard event exposes warning tick")
		_assert(int(event.get("warningTick", 0)) < int(event.get("applyTick", 0)), "hazard warning precedes apply")
		_assert_eq(int(event.get("pinDelta", -99)), 0, "hazard event does not directly remove pins")

# 실행: verify base purchases can unlock characters and starter equipment without UI dependencies.
func test_base_shop_and_character_purchase_unlocks_choices() -> void:
	var bundle: Dictionary = ReleaseContentVocabScript.load_content_bundle()
	var state := ReleaseContentVocabScript.create_base_state({"gold": 260, "xp": 160})
	var engineer := ReleaseContentVocabScript.purchase_base_item(state, "character_engineer", bundle)
	var beacon := ReleaseContentVocabScript.purchase_base_item(engineer.get("state", {}), "starter_beacon_blue", bundle)
	_assert(engineer.get("ok", false), "engineer purchase succeeds")
	_assert(beacon.get("ok", false), "starter beacon purchase succeeds")
	var next_state: Dictionary = beacon.get("state", {})
	_assert(next_state.get("unlockedCharacters", []).has("engineer"), "engineer unlock is recorded")
	_assert(next_state.get("unlockedStarterItems", []).has("starter_beacon_blue"), "starter beacon unlock is recorded")
	_assert(int(next_state.get("gold", 0)) < 260, "base purchases spend gold")

# ?ㅽ뻾: verify live growth state can persist base-shop unlock purchases.
func test_growth_state_base_purchase_serializes() -> void:
	var bundle: Dictionary = ReleaseContentVocabScript.load_content_bundle()
	var growth = RunGrowthStateScript.new({"gold": 260, "xp": 160})
	var bought_character := growth.purchase_base_item("character_mechanic", bundle)
	var bought_scan := growth.purchase_base_item("leviathan_scan_storm", bundle)
	var snapshot: Dictionary = growth.to_dict()
	_assert_eq(bought_character, true, "growth state buys character")
	_assert_eq(bought_scan, true, "growth state buys leviathan scan")
	_assert(snapshot.get("unlockedCharacters", []).has("mechanic"), "character unlock serializes")
	_assert(snapshot.get("scanUnlocks", []).has("storm_wyvern"), "leviathan scan unlock serializes")

# 실행: verify passive tree branches are capped and produce readable modifiers.
func test_passive_tree_has_three_branches_and_caps() -> void:
	var bundle: Dictionary = ReleaseContentVocabScript.load_content_bundle()
	var branches := ReleaseContentVocabScript.passive_branch_summary(bundle.get("passives", []))
	_assert_eq(branches.keys().size(), 3, "passive tree has exactly three branches")
	for branch in ["engine", "survival", "extraction"]:
		_assert(branches.has(branch), "passive tree has %s branch" % branch)
		_assert(int(branches[branch].get("count", 0)) >= 3, "%s branch has at least three nodes" % branch)
		_assert(int(branches[branch].get("maxLevel", 0)) <= 5, "%s branch caps at five levels" % branch)

# 실행: verify narrative beats project presentation only and do not mutate replay state.
func test_narrative_beats_are_side_effect_free() -> void:
	var bundle: Dictionary = ReleaseContentVocabScript.load_content_bundle()
	var state := {"phase": "reward_loot", "stageIndex": 0, "runComplete": false, "growth": {"artifactDiscovery": ["artifact_1"]}}
	var projected := ReleaseContentVocabScript.project_narrative_beats(state, bundle.get("narrativeBeats", []), {})
	_assert(projected.size() >= 1, "narrative projection finds first artifact beat")
	_assert_eq(state.get("phase", ""), "reward_loot", "narrative projection does not mutate phase")
	_assert_eq(state.get("stageIndex", -1), 0, "narrative projection does not mutate stage")

# ?ㅽ뻾: verify M7 narrative content exposes the required core beat ids.
func test_narrative_beats_cover_m7_core_beats() -> void:
	var bundle: Dictionary = ReleaseContentVocabScript.load_content_bundle()
	var ids := {}
	for beat in bundle.get("narrativeBeats", []):
		ids[str(beat.get("id", ""))] = true
	for required_id in ["intro_contract", "first_valid_hit", "first_artifact", "first_failure", "first_clear", "hunt_tension"]:
		_assert(ids.has(required_id), "M7 narrative beat exists: %s" % required_id)

# ?ㅽ뻾: verify M7 narrative beats declare screen, display, and skip metadata.
func test_narrative_beats_have_screen_and_skip_contract() -> void:
	var bundle: Dictionary = ReleaseContentVocabScript.load_content_bundle()
	for beat in bundle.get("narrativeBeats", []):
		_assert(not str(beat.get("screenId", "")).is_empty(), "narrative beat has screenId: %s" % str(beat.get("id", "")))
		_assert(not str(beat.get("displayMode", "")).is_empty(), "narrative beat has displayMode: %s" % str(beat.get("id", "")))
		_assert(beat.has("skipInputAllowed"), "narrative beat declares skipInputAllowed: %s" % str(beat.get("id", "")))

# 실행: verify resource manifest gives exact future drop-in paths.
func test_resource_manifest_uses_ready_to_swap_paths() -> void:
	var bundle: Dictionary = ReleaseContentVocabScript.load_content_bundle()
	var manifest: Array = bundle.get("resourceNeeds", [])
	_assert(manifest.size() >= 18, "resource manifest lists enough art and audio slots")
	for item in manifest:
		var path := str(item.get("path", ""))
		_assert(path.begins_with("res://resources/"), "resource path is Godot-ready: %s" % path)
		_assert(not path.contains("*"), "resource path avoids wildcard placeholders: %s" % path)
		_assert(not str(item.get("purpose", "")).is_empty(), "resource purpose is documented")

# 실행: find one dictionary row by id.
func _find_by_id(rows: Array, id: String) -> Dictionary:
	for row in rows:
		if str(row.get("id", "")) == id:
			return row
	return {}

# 실행: append a failure label when condition is false.
func _assert(condition: bool, label: String) -> void:
	if not condition:
		failures.append(label)

# 실행: append a deterministic equality failure label when values differ.
func _assert_eq(actual: Variant, expected: Variant, label: String) -> void:
	if actual != expected:
		failures.append("%s: expected %s, got %s" % [label, str(expected), str(actual)])
