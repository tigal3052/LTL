# 계약:
# - 책임: M4-M9 release content tables into deterministic gameplay-ready projections.
# - 입력: JSON content tables for nodes, leviathans, characters, hazards, base shop, passives, narrative, and resources.
# - 출력: validated bundles plus pure helper projections for hazard schedules, base purchases, passives, and narrative beats.
# - 금지: SceneTree/UI access, random nondeterminism, direct save-file mutation.
#
# 실행: define the release content vocabulary facade.
class_name ReleaseContentVocab
extends RefCounted

const SelectNarrativeBeatScript = preload("res://src/vocabulary/narrative/SelectNarrativeBeat.gd")

const CONTENT_PATHS := {
	"nodes": "res://src/data/node-table.json",
	"leviathans": "res://src/data/leviathan-table.json",
	"characters": "res://src/data/character-table.json",
	"hazards": "res://src/data/hazard-table.json",
	"baseShop": "res://src/data/base-shop-table.json",
	"passives": "res://src/data/passive-tree.json",
	"narrativeBeats": "res://src/data/narrative-beats.json",
	"storyScenes": "res://src/data/story-scenes.json",
	"resourceNeeds": "res://src/data/release-resource-needs.json"
}

# 실행: load all release content tables in one stable bundle.
static func load_content_bundle() -> Dictionary:
	var node_data := _load_json(CONTENT_PATHS["nodes"])
	var leviathan_data := _load_json(CONTENT_PATHS["leviathans"])
	var character_data := _load_json(CONTENT_PATHS["characters"])
	var hazard_data := _load_json(CONTENT_PATHS["hazards"])
	var shop_data := _load_json(CONTENT_PATHS["baseShop"])
	var passive_data := _load_json(CONTENT_PATHS["passives"])
	var narrative_data := _load_json(CONTENT_PATHS["narrativeBeats"])
	var story_data := _load_json(CONTENT_PATHS["storyScenes"])
	var resource_data := _load_json(CONTENT_PATHS["resourceNeeds"])
	return {
		"nodes": node_data.get("nodes", []),
		"leviathans": leviathan_data.get("leviathans", []),
		"characters": character_data.get("characters", []),
		"hazards": hazard_data.get("hazards", []),
		"baseShop": shop_data.get("items", []),
		"passives": passive_data.get("passives", []),
		"narrativeBeats": narrative_data.get("beats", []),
		"storyScenes": story_data.get("scenes", []),
		"resourceNeeds": resource_data.get("resources", [])
	}

# 실행: validate minimum release content coverage and table shape.
static func validate_content_bundle(bundle: Dictionary) -> Dictionary:
	var errors: Array[String] = []
	_require_min(bundle, "nodes", 7, errors)
	_require_min(bundle, "leviathans", 3, errors)
	_require_min(bundle, "characters", 3, errors)
	_require_min(bundle, "hazards", 4, errors)
	_require_min(bundle, "baseShop", 6, errors)
	_require_min(bundle, "passives", 9, errors)
	_require_min(bundle, "narrativeBeats", 5, errors)
	_require_min(bundle, "storyScenes", 1, errors)
	_require_min(bundle, "resourceNeeds", 18, errors)
	_require_unique_ids(bundle.get("leviathans", []), "leviathans", errors)
	_require_unique_ids(bundle.get("characters", []), "characters", errors)
	_require_unique_ids(bundle.get("hazards", []), "hazards", errors)
	_require_unique_ids(bundle.get("baseShop", []), "baseShop", errors)
	_require_unique_ids(bundle.get("passives", []), "passives", errors)
	_require_unique_ids(bundle.get("narrativeBeats", []), "narrativeBeats", errors)
	_require_unique_ids(bundle.get("storyScenes", []), "storyScenes", errors)
	_require_unique_ids(bundle.get("resourceNeeds", []), "resourceNeeds", errors)
	_validate_leviathan_fields(bundle.get("leviathans", []), errors)
	_validate_required_fields(bundle.get("characters", []), "characters", ["id", "name", "costGold", "modifiers"], errors)
	_validate_required_fields(bundle.get("hazards", []), "hazards", ["id", "warningTicks", "durationTicks", "pinDelta", "counterplay"], errors)
	_validate_required_fields(bundle.get("baseShop", []), "baseShop", ["id", "type", "costGold", "unlockId"], errors)
	_validate_required_fields(bundle.get("passives", []), "passives", ["id", "branch", "maxLevel", "costGold", "effect"], errors)
	_validate_required_fields(bundle.get("narrativeBeats", []), "narrativeBeats", ["id", "trigger", "screenId", "triggerPhase", "displayMode", "textKo", "textEn", "sideEffectFree", "skipInputAllowed", "anchorPreset", "portraitPath", "portraitSide", "visualPath", "toastVariant"], errors)
	_validate_story_scene_fields(bundle.get("storyScenes", []), errors)
	_validate_required_fields(bundle.get("resourceNeeds", []), "resourceNeeds", ["id", "path", "type", "fallback"], errors)
	return {"ok": errors.is_empty(), "errors": errors, "diagnostics": errors}

# 실행: build deterministic warning/apply/clear hazard events for a selected node.
static func schedule_hazards(seed_val: int, stage_index: int, hazards: Array, hazard_modifier: float = 1.0) -> Array:
	if hazards.is_empty():
		return []
	var rng := RandomNumberGenerator.new()
	rng.seed = int(seed_val) + int(stage_index) * 4099 + 17
	var event_count := clampi(int(ceil(3.0 * maxf(0.5, hazard_modifier))), 3, min(5, hazards.size()))
	var weighted := hazards.duplicate(true)
	weighted.sort_custom(func(a, b): return float(a.get("weight", 10.0)) > float(b.get("weight", 10.0)))
	var events := []
	var tick_cursor := 80 + int(stage_index) * 12
	for i in range(event_count):
		var index := int((rng.randi() + i) % weighted.size())
		var hazard: Dictionary = weighted[index]
		var warning_ticks := maxi(10, int(hazard.get("warningTicks", 30)))
		var duration_ticks := maxi(20, int(float(hazard.get("durationTicks", 80)) * maxf(0.8, hazard_modifier)))
		var warning_tick := tick_cursor + i * 95
		var apply_tick := warning_tick + warning_ticks
		var clear_tick := apply_tick + duration_ticks
		events.append({
			"hazardId": str(hazard.get("id", "")),
			"warningTick": warning_tick,
			"applyTick": apply_tick,
			"clearTick": clear_tick,
			"severity": clampf(float(hazard.get("severity", 1.0)) * hazard_modifier, 0.5, 2.5),
			"pinDelta": int(hazard.get("pinDelta", 0)),
			"telemetry": str(hazard.get("telemetryEvent", "hazard_applied"))
		})
	return events

# 실행: create a clean starting base state for unlock and purchase tests.
static func create_base_state(options: Dictionary = {}) -> Dictionary:
	return {
		"gold": int(options.get("gold", 0)),
		"xp": int(options.get("xp", 0)),
		"selectedCharacter": str(options.get("selectedCharacter", "miner")),
		"unlockedCharacters": options.get("unlockedCharacters", ["miner"]).duplicate(true),
		"unlockedStarterItems": options.get("unlockedStarterItems", ["starter_drill_red"]).duplicate(true),
		"scanUnlocks": options.get("scanUnlocks", []).duplicate(true),
		"purchasedPassives": options.get("purchasedPassives", {}).duplicate(true)
	}

# 실행: purchase a base shop item without mutating the incoming state.
static func purchase_base_item(state: Dictionary, item_id: String, bundle: Dictionary) -> Dictionary:
	var item := _find_by_id(bundle.get("baseShop", []), item_id)
	if item.is_empty():
		return {"ok": false, "error": "item_not_found", "state": state.duplicate(true)}
	var next := state.duplicate(true)
	var cost_gold := int(item.get("costGold", 0))
	var cost_xp := int(item.get("costXp", 0))
	if int(next.get("gold", 0)) < cost_gold or int(next.get("xp", 0)) < cost_xp:
		return {"ok": false, "error": "insufficient_funds", "state": next, "item": item}
	next["gold"] = int(next.get("gold", 0)) - cost_gold
	next["xp"] = int(next.get("xp", 0)) - cost_xp
	var unlock_id := str(item.get("unlockId", item_id))
	match str(item.get("type", "")):
		"character":
			_append_unique(next, "unlockedCharacters", unlock_id)
		"starter_item":
			_append_unique(next, "unlockedStarterItems", unlock_id)
		"scan":
			_append_unique(next, "scanUnlocks", unlock_id)
	return {"ok": true, "state": next, "item": item}

# 실행: summarize passive tree branch counts and maximum levels.
static func passive_branch_summary(passives: Array) -> Dictionary:
	var branches := {}
	for passive in passives:
		var branch := str(passive.get("branch", ""))
		if branch == "":
			continue
		if not branches.has(branch):
			branches[branch] = {"count": 0, "maxLevel": 0, "ids": []}
		branches[branch]["count"] = int(branches[branch]["count"]) + 1
		branches[branch]["maxLevel"] = maxi(int(branches[branch]["maxLevel"]), int(passive.get("maxLevel", 1)))
		branches[branch]["ids"].append(str(passive.get("id", "")))
	return branches

# 실행: project narrative beats matching state/history without side effects.
static func project_narrative_beats(state: Dictionary, beats: Array, history: Dictionary = {}) -> Array:
	var beat := SelectNarrativeBeatScript.select(state, beats, history)
	return [] if beat.is_empty() else [beat]

# 실행: load helper for JSON files.
static func _load_json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var json := JSON.new()
	if json.parse(file.get_as_text()) != OK:
		return {}
	var data = json.get_data()
	if data is Dictionary:
		return data
	return {}

# 실행: validate array length.
static func _require_min(bundle: Dictionary, key: String, expected: int, errors: Array[String]) -> void:
	var value: Array = bundle.get(key, [])
	if value.size() < expected:
		errors.append("%s needs at least %d entries, got %d" % [key, expected, value.size()])

# 실행: validate table ids.
static func _require_unique_ids(items: Array, table_name: String, errors: Array[String]) -> void:
	var seen := {}
	for item in items:
		var id := str(item.get("id", ""))
		if id == "":
			errors.append("%s has empty id" % table_name)
		elif seen.has(id):
			errors.append("%s has duplicate id %s" % [table_name, id])
		seen[id] = true

# 실행: validate required fields.
static func _validate_required_fields(items: Array, table_name: String, fields: Array, errors: Array[String]) -> void:
	for item in items:
		var id := str(item.get("id", "<missing>"))
		for field in fields:
			if not item.has(str(field)):
				errors.append("%s.%s missing %s" % [table_name, id, str(field)])

# ?ㅽ뻾: validate Leviathan fields while accepting legacy and release-count aliases.
static func _validate_leviathan_fields(items: Array, errors: Array[String]) -> void:
	_validate_required_fields(items, "leviathans", ["id", "name", "bossNodeId"], errors)
	for item in items:
		var id := str(item.get("id", "<missing>"))
		if not (item.has("stageCount") or item.has("stageCnt")):
			errors.append("leviathans.%s missing stageCount/stageCnt" % id)
		if not (item.has("runCount") or item.has("runCnt")):
			errors.append("leviathans.%s missing runCount/runCnt" % id)

# 실행: validate story scenes and nested VN step rows.
static func _validate_story_scene_fields(items: Array, errors: Array[String]) -> void:
	_validate_required_fields(items, "storyScenes", ["id", "trigger", "returnPageId", "shownOnce", "sideEffectFree", "steps"], errors)
	for item in items:
		var id := str(item.get("id", "<missing>"))
		var steps: Array = item.get("steps", []) if item.get("steps", []) is Array else []
		if steps.is_empty():
			errors.append("storyScenes.%s needs at least one step" % id)
			continue
		for index in range(steps.size()):
			var step = steps[index]
			if not (step is Dictionary):
				errors.append("storyScenes.%s.steps[%d] must be a dictionary" % [id, index])
				continue
			for field in ["speaker", "textKo", "textEn", "portraitPath", "side", "backgroundPath", "expression"]:
				if not step.has(field):
					errors.append("storyScenes.%s.steps[%d] missing %s" % [id, index, field])

# 실행: find a dictionary row by id.
static func _find_by_id(items: Array, item_id: String) -> Dictionary:
	for item in items:
		if str(item.get("id", "")) == item_id:
			return item
	return {}

# 실행: append a value to a copied array field once.
static func _append_unique(state: Dictionary, key: String, value: String) -> void:
	var list: Array = state.get(key, [])
	if not value in list:
		list.append(value)
	state[key] = list

# 실행: check whether a narrative trigger matches the current run state.
static func _beat_matches(trigger: String, state: Dictionary) -> bool:
	match trigger:
		"first_run_start":
			return str(state.get("phase", "")) == "node_select" and int(state.get("stageIndex", 0)) == 0
		"first_artifact":
			var growth: Dictionary = state.get("growth", {})
			return str(state.get("phase", "")) == "reward_loot" and not Array(growth.get("artifactDiscovery", [])).is_empty()
		"first_valid_hit":
			var combat: Dictionary = state.get("combat", {}) if state.get("combat", {}) is Dictionary else {}
			var summary: Dictionary = combat.get("summary", {}) if combat.get("summary", {}) is Dictionary else {}
			return int(summary.get("shots_hit_match", 0)) > 0
		"first_failure":
			return str(state.get("phase", "")) == "run_complete" and bool(state.get("failed", false))
		"first_clear":
			return str(state.get("phase", "")) == "run_complete" and bool(state.get("runComplete", false)) and not bool(state.get("failed", false))
		"leviathan_clear":
			return str(state.get("phase", "")) == "run_complete" and bool(state.get("runComplete", false)) and not bool(state.get("failed", false))
	return false
