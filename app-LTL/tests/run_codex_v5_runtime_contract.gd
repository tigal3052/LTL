extends SceneTree

const VIEWPORT_SIZE := Vector2i(1440, 900)
const LayoutPolicy = preload("res://src/ui/codex/ArtifactCodexLayoutPolicy.gd")
const ReadModel = preload("res://src/ui/read_models/ArtifactCodexReadModel.gd")
const CodexPanel = preload("res://src/ui/ArtifactCodexPanelUI.gd")

var failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	root.size = VIEWPORT_SIZE
	_assert_layout_contract()
	_assert_query_contract()
	await _assert_v5_tree_contract()
	if failures.is_empty():
		print("CODEX_V5_RUNTIME_CONTRACT_OK")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)

func _assert_layout_contract() -> void:
	var policy = LayoutPolicy.new()
	_assert(policy.has_method("canvas_transform_for_viewport"), "V5 layout policy exposes canvas transform")
	if policy.has_method("canvas_transform_for_viewport"):
		var native: Dictionary = policy.call("canvas_transform_for_viewport", Vector2(1440, 900))
		_assert_eq(native.get("position", Vector2(-1, -1)), Vector2.ZERO, "1440x900 V5 canvas starts at origin")
		_assert_eq(native.get("scale", -1.0), 1.0, "1440x900 V5 canvas is 1x")

func _assert_query_contract() -> void:
	var table := {"rewards": [_reward("red", "common", "drill"), _reward("blue", "rare", "beacon")]}
	var reader = ReadModel.new()
	_assert(reader.has_method("project_v5"), "model exposes V5 taxonomy and sort projection")
	if not reader.has_method("project_v5"):
		return
	var model: Dictionary = reader.call("project_v5", table, {"artifactDiscovery": ["red"]}, false, "en", "", "all", "backpack_items", "catalog")
	_assert_eq(str(model.get("activeTaxonomyId", "")), "backpack_items", "model owns independent backpack taxonomy state")
	_assert_eq((model.get("taxonomies", []) as Array).size(), 5, "model exposes five taxonomy tabs")
	_assert_eq((model.get("sortOptions", []) as Array).size(), 3, "model exposes catalog/name/rarity sorting")
	var empty_model: Dictionary = reader.call("project_v5", table, {}, false, "en", "", "all", "flora", "catalog")
	_assert_eq((empty_model.get("rightPage", {}) as Dictionary).get("gridEntries", []).size(), 0, "empty taxonomy remains a deterministic empty result")
	var drill_model: Dictionary = reader.call("project_v5", table, {}, true, "en", "", "drill", "backpack_items", "catalog")
	var drill_entries: Array = (drill_model.get("rightPage", {}) as Dictionary).get("gridEntries", [])
	_assert_eq(drill_entries.size(), 1, "section selection filters the V5 catalog grid")
	_assert_eq(str((drill_entries[0] as Dictionary).get("itemType", "")), "drill", "section-filtered card matches selected section")
	var sorted_table := {"rewards": [_reward("zulu", "legendary", "drill"), _reward("alpha", "common", "drill")]}
	var name_model: Dictionary = reader.call("project_v5", sorted_table, {}, true, "en", "", "all", "backpack_items", "name")
	var name_entries: Array = (name_model.get("rightPage", {}) as Dictionary).get("gridEntries", [])
	_assert_eq(str((name_entries[0] as Dictionary).get("name", "")), "alpha", "name sort changes the visible card order")

func _assert_v5_tree_contract() -> void:
	var panel := CodexPanel.new()
	root.add_child(panel)
	await process_frame
	_assert(panel.get_node_or_null("CodexViewport/DesignCanvas/CatalogRegion") != null, "V5 panel owns catalog region")
	_assert(panel.get_node_or_null("CodexViewport/DesignCanvas/DetailRegion") != null, "V5 panel owns detail region")
	_assert(panel.get_node_or_null("BookCenter") == null, "V5 panel retires book center")
	var canvas := panel.get_node_or_null("CodexViewport/DesignCanvas") as Control
	if canvas != null:
		_assert_eq(canvas.size, Vector2(1440, 900), "V5 canvas has exact 1440x900 design size")
	var sample := {"rewards": [_reward("zulu", "legendary", "drill"), _reward("alpha", "common", "drill")]}
	panel.render_codex(ReadModel.project_v5(sample, {}, true, "en"))
	var sort_dropdown := panel.get_node_or_null("CodexViewport/DesignCanvas/CatalogRegion/FilterTabs/SortDropdown") as Button
	_assert(sort_dropdown != null and not sort_dropdown.disabled, "V5 shows an enabled texture-backed sort dropdown")
	var close := panel.get_node_or_null("CodexViewport/DesignCanvas/TopBar/CloseButton") as Button
	_assert(close != null and close.size.y == 38.0, "V5 close control keeps the reference-sized 38px target")
	panel.queue_free()

func _reward(id: String, rarity: String, item_type: String) -> Dictionary:
	return {"id": id, "rarity": rarity, "payload": {"item_type": item_type, "energy_type": id, "shape": [[1]], "base_cooldown_ticks": 30, "damage": 2.0}, "text": {"name": {"en": id}, "description": {"en": id}}, "presentation": {"icon": id}}

func _assert(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

func _assert_eq(actual: Variant, expected: Variant, message: String) -> void:
	if actual != expected:
		failures.append("%s: expected %s, got %s" % [message, str(expected), str(actual)])
