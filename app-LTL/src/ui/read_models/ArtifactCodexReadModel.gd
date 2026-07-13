# 계약:
# - 책임: reward-table artifact data와 성장 상태를 북 형태 도감 read model로 변환한다.
# - 입력: reward table Dictionary, growth state Dictionary, debug_all flag, locale, selected entry id, active section id.
# - 출력: { title, text, entries, sections, leftPage, rightPage, resolvedSelectedEntryId, activeSection, totalCount, discoveredCount, visibleCount } dictionary.
# - 금지: FileAccess, UI node 생성, run state 변경.
#
# 실행: define the artifact codex read-model projector.
class_name ArtifactCodexReadModel
extends RefCounted

const TextCatalogScript = preload("res://src/ui/TextCatalog.gd")
const ArtifactCodexArtResolverScript = preload("res://src/ui/ArtifactCodexArtResolver.gd")
const RewardCatalogOrderScript = preload("res://src/vocabulary/reward/RewardCatalogOrder.gd")
const SECTION_IDS := ["all", "drill", "beacon", "relic"]

# 실행: project artifact table rows into a localized codex book model.
static func project(
	reward_table: Dictionary,
	growth_state: Dictionary = {},
	debug_all: bool = false,
	locale := "",
	selected_entry_id := "",
	active_section := "all"
) -> Dictionary:
	var rewards: Array = RewardCatalogOrderScript.sort_rewards(reward_table.get("rewards", []))
	var discovered_lookup := _discovered_lookup(growth_state)
	var entries: Array = []
	for reward in rewards:
		if not (reward is Dictionary):
			continue
		entries.append(_project_entry(reward, discovered_lookup, debug_all, locale))
	var normalized_section := _normalize_section(active_section)
	var grid_entries := _filter_entries_for_section(entries, normalized_section)
	var resolved_selected_entry_id := _resolve_selected_entry_id(grid_entries, selected_entry_id)
	var selected_entry := _entry_by_id(entries, resolved_selected_entry_id)
	var discovered_count := _count_discovered(entries)
	var visible_count := _count_visible(entries)
	return {
		"title": TextCatalogScript.t("codex.title", [], locale),
		"text": _legacy_text(entries, locale),
		"entries": entries,
		"sections": _project_sections(entries, normalized_section, locale),
		"leftPage": _project_left_page(selected_entry, locale),
		"rightPage": {
			"gridEntries": grid_entries,
			"gridColumns": 3,
			"emptyText": TextCatalogScript.t("codex.empty", [], locale),
			"selectedEntryId": resolved_selected_entry_id
		},
		"resolvedSelectedEntryId": resolved_selected_entry_id,
		"activeSection": normalized_section,
		"totalCount": entries.size(),
		"discoveredCount": discovered_count,
		"visibleCount": visible_count,
		"debugAll": debug_all
	}

# 실행: turn one reward row into a codex entry.
static func _project_entry(reward: Dictionary, discovered_lookup: Dictionary, debug_all: bool, locale: String) -> Dictionary:
	var reward_id := str(reward.get("id", reward.get("catalogId", "")))
	var payload: Dictionary = reward.get("payload", {})
	var presentation: Dictionary = reward.get("presentation", {})
	var item_type := str(payload.get("item_type", "drill")).to_lower()
	var energy_type := str(payload.get("energy_type", "")).to_lower()
	var shape_matrix := _normalized_shape(payload.get("shape", [[1]]))
	var shape_bounds := _shape_bounds(shape_matrix)
	var occupied_cell_count := _shape_cell_count(shape_matrix)
	var is_discovered := debug_all or discovered_lookup.has(reward_id)
	var is_revealed := is_discovered
	var rarity := str(reward.get("rarity", "common")).to_lower()
	var display_name := TextCatalogScript.reward_name(reward, locale) if is_revealed else TextCatalogScript.t("codex.undiscovered", [], locale)
	var description := TextCatalogScript.reward_description(reward, locale)
	var display_description := description if is_revealed else TextCatalogScript.t("codex.locked_body", [], locale)
	var fact_chips := [
		TextCatalogScript.enum_label("rarity", rarity, locale),
		TextCatalogScript.t("item.%s" % item_type, [], locale),
		TextCatalogScript.t("codex.state.discovered" if is_revealed else "codex.state.locked", [], locale)
	]
	if not energy_type.is_empty():
		fact_chips.insert(2, TextCatalogScript.enum_label("color", energy_type, locale))
	var icon_key := str(presentation.get("icon", reward_id))
	var state_line := TextCatalogScript.t("codex.locked_hint", [], locale)
	if is_revealed:
		state_line = str(description)
	var badge := str(presentation.get("badge", "")).strip_edges()
	return {
		"id": reward_id,
		"section": item_type,
		"visible": is_revealed,
		"discovered": is_discovered,
		"name": display_name,
		"description": description,
		"displayDescription": display_description,
		"detailText": state_line,
		"rarity": rarity,
		"rarityPips": _rarity_pips(rarity),
		"itemType": item_type,
		"energyType": energy_type,
		"shapeMatrix": shape_matrix,
		"shapeBounds": shape_bounds,
		"occupiedCellCount": occupied_cell_count,
		"baseCooldownTicks": int(payload.get("base_cooldown_ticks", 0)),
		"baseDamage": float(payload.get("damage", 0.0)),
		"debug": debug_all,
		"iconKey": icon_key,
		"badge": badge,
		"factChips": fact_chips,
		"heroArt": ArtifactCodexArtResolverScript.descriptor_for_reward(reward, "hero", is_revealed),
		"thumbArt": ArtifactCodexArtResolverScript.descriptor_for_reward(reward, "thumb", is_revealed)
	}

# 실행: produce the tab payloads for top-level sections.
static func _project_sections(entries: Array, active_section: String, locale: String) -> Array:
	var sections: Array = []
	for section_id in SECTION_IDS:
		var section_entries := _filter_entries_for_section(entries, section_id)
		var discovered_count := _count_discovered(section_entries)
		sections.append({
			"id": section_id,
			"label": TextCatalogScript.t("codex.section.%s" % section_id, [], locale),
			"count": section_entries.size(),
			"discoveredCount": discovered_count,
			"active": section_id == active_section
		})
	return sections

# 실행: build the left-page payload from the resolved selection.
static func _project_left_page(selected_entry: Dictionary, locale: String) -> Dictionary:
	if selected_entry.is_empty():
		return {
			"title": TextCatalogScript.t("codex.title", [], locale),
			"subtitle": "",
			"body": TextCatalogScript.t("codex.empty", [], locale),
			"factChips": [],
			"heroArt": {},
			"empty": true
		}
	var rarity_label := TextCatalogScript.enum_label("rarity", str(selected_entry.get("rarity", "")), locale)
	var type_label := TextCatalogScript.t("item.%s" % str(selected_entry.get("itemType", "drill")), [], locale)
	var shape_matrix: Array = selected_entry.get("shapeMatrix", [])
	var shape_bounds: Dictionary = selected_entry.get("shapeBounds", {})
	var shape_width := int(shape_bounds.get("width", 0))
	var shape_height := int(shape_bounds.get("height", 0))
	return {
		"id": str(selected_entry.get("id", "")),
		"title": str(selected_entry.get("name", "")),
		"subtitle": "%s • %s" % [rarity_label, type_label],
		"body": str(selected_entry.get("displayDescription", "")),
		"detailText": str(selected_entry.get("detailText", "")),
		"factChips": selected_entry.get("factChips", []),
		"badge": str(selected_entry.get("badge", "")),
		"heroArt": selected_entry.get("heroArt", {}),
		"shapeTitle": TextCatalogScript.t("codex.shape", [], locale),
		"shapeFootprintText": TextCatalogScript.t("codex.shape_footprint", [shape_width, shape_height], locale),
		"shapeCellCountText": TextCatalogScript.t("codex.shape_cells", [int(selected_entry.get("occupiedCellCount", 0))], locale),
		"shapeMatrix": shape_matrix.duplicate(true),
		"shapeItemType": str(selected_entry.get("itemType", "")),
		"shapeEnergyType": str(selected_entry.get("energyType", "")),
		"baseCooldownTicks": int(selected_entry.get("baseCooldownTicks", 0)),
		"baseDamage": float(selected_entry.get("baseDamage", 0.0)),
		"missingArtText": TextCatalogScript.t("codex.missing_art", [], locale),
		"empty": false
	}

# 실행: keep the legacy text-mode fallback for contract coverage and debug visibility.
static func _legacy_text(entries: Array, locale: String) -> String:
	var lines := PackedStringArray()
	for entry in entries:
		if not (entry is Dictionary):
			continue
		var is_discovered := bool(entry.get("discovered", false))
		var is_visible := bool(entry.get("visible", false))
		var status := "DEBUG" if is_visible and not is_discovered else ("FOUND" if is_discovered else "LOCKED")
		var energy_label := "-"
		if not str(entry.get("energyType", "")).is_empty():
			energy_label = TextCatalogScript.enum_label("color", str(entry.get("energyType", "")), locale)
		lines.append("[%s] %s / %s / %s - %s" % [
			status,
			str(entry.get("rarity", "")).to_upper(),
			energy_label,
			TextCatalogScript.t("item.%s" % str(entry.get("itemType", "drill")), [], locale),
			str(entry.get("name", ""))
		])
		if is_visible and not str(entry.get("description", "")).is_empty():
			lines.append("  %s" % str(entry.get("description", "")))
	return "\n".join(lines) if not lines.is_empty() else TextCatalogScript.t("codex.empty", [], locale)

# 실행: turn discovery history into a fast lookup dictionary.
static func _discovered_lookup(growth_state: Dictionary) -> Dictionary:
	var discovered := {}
	for entry_id in growth_state.get("artifactDiscovery", []):
		discovered[str(entry_id)] = true
	return discovered

# 실행: clamp incoming section ids to the supported set.
static func _normalize_section(active_section: String) -> String:
	var normalized := active_section.to_lower()
	return normalized if normalized in SECTION_IDS else "all"

# 실행: filter entries to the active section while preserving canonical catalog order.
static func _filter_entries_for_section(entries: Array, section_id: String) -> Array:
	if section_id == "all":
		return entries.duplicate(true)
	var filtered: Array = []
	for entry in entries:
		if str(entry.get("section", "")) == section_id:
			filtered.append(entry)
	return filtered

# 실행: preserve the current selection when still valid, otherwise fall back to the first visible card in canonical section order.
static func _resolve_selected_entry_id(entries: Array, selected_entry_id: String) -> String:
	if not selected_entry_id.is_empty():
		for entry in entries:
			if str(entry.get("id", "")) == selected_entry_id:
				return selected_entry_id
	if entries.is_empty():
		return ""
	return str(entries[0].get("id", ""))

# 실행: find one projected entry by id.
static func _entry_by_id(entries: Array, entry_id: String) -> Dictionary:
	for entry in entries:
		if str(entry.get("id", "")) == entry_id:
			return entry
	return {}

# 실행: count discovered entries for top-level summaries.
static func _count_discovered(entries: Array) -> int:
	var count := 0
	for entry in entries:
		if bool(entry.get("discovered", false)):
			count += 1
	return count

# 실행: count currently visible entries, respecting debug unlock mode.
static func _count_visible(entries: Array) -> int:
	var count := 0
	for entry in entries:
		if bool(entry.get("visible", false)):
			count += 1
	return count

static func _normalized_shape(raw_shape: Variant) -> Array:
	if not (raw_shape is Array) or raw_shape.is_empty():
		return [[1]]
	var width := 0
	for row in raw_shape:
		if row is Array:
			width = maxi(width, row.size())
	if width <= 0:
		return [[1]]
	var normalized: Array = []
	for row in raw_shape:
		var source_row: Array = row if row is Array else []
		var normalized_row: Array = []
		for column_index in range(width):
			var filled := column_index < source_row.size() and bool(source_row[column_index])
			normalized_row.append(1 if filled else 0)
		normalized.append(normalized_row)
	return normalized if not normalized.is_empty() else [[1]]

static func _shape_bounds(shape_matrix: Array) -> Dictionary:
	var width := 0
	for row in shape_matrix:
		if row is Array:
			width = maxi(width, row.size())
	return {"width": width, "height": shape_matrix.size()}

static func _shape_cell_count(shape_matrix: Array) -> int:
	var occupied := 0
	for row in shape_matrix:
		if not (row is Array):
			continue
		for cell in row:
			if bool(cell):
				occupied += 1
	return occupied

# 실행: map rarity ids to a compact pip count for the right-grid badge.
static func _rarity_pips(rarity: String) -> int:
	match rarity:
		"common": return 1
		"rare": return 2
		"epic": return 3
		"legendary": return 4
		"mythic": return 5
		_: return 1

# V5 keeps the gameplay discovery projection above, then adds display-only taxonomy and sorting state.
static func project_v5(reward_table: Dictionary, growth_state: Dictionary = {}, debug_all: bool = false, locale := "", selected_entry_id := "", active_section := "all", active_taxonomy_id := "backpack_items", sort_id := "catalog") -> Dictionary:
	var base := project(reward_table, growth_state, debug_all, locale, selected_entry_id, active_section)
	var normalized_taxonomy := _normalize_v5_taxonomy(active_taxonomy_id)
	var normalized_sort := _normalize_v5_sort(sort_id)
	var all_entries: Array = base.get("entries", [])
	var section_entries: Array = (base.get("rightPage", {}) as Dictionary).get("gridEntries", [])
	var filtered: Array = []
	for entry in section_entries:
		if _entry_matches_v5_taxonomy(entry, normalized_taxonomy):
			filtered.append(entry)
	_sort_v5_entries(filtered, normalized_sort)
	var resolved := _resolve_selected_entry_id(filtered, selected_entry_id)
	var selected := _entry_by_id(all_entries, resolved)
	base["activeTaxonomyId"] = normalized_taxonomy
	base["activeSortId"] = normalized_sort
	base["taxonomies"] = _project_v5_taxonomies(all_entries, normalized_taxonomy, locale)
	base["sortOptions"] = _project_v5_sort_options(normalized_sort, locale)
	base["rightPage"] = {"gridEntries": filtered, "gridColumns": 2, "emptyText": TextCatalogScript.t("codex.empty", [], locale), "selectedEntryId": resolved}
	base["leftPage"] = _project_left_page(selected, locale)
	base["resolvedSelectedEntryId"] = resolved
	return base

static func _normalize_v5_taxonomy(value: String) -> String:
	return value if value in ["backpack_items", "leviathan_traces", "flora", "minerals", "ruin_patterns"] else "backpack_items"

static func _normalize_v5_sort(value: String) -> String:
	return value if value in ["catalog", "name", "rarity"] else "catalog"

static func _entry_matches_v5_taxonomy(entry: Dictionary, taxonomy: String) -> bool:
	if taxonomy == "backpack_items":
		return str(entry.get("itemType", "")) in ["drill", "beacon", "relic"]
	return false

static func _project_v5_taxonomies(entries: Array, active_id: String, locale: String) -> Array:
	var fallback := {"backpack_items": "Backpack Items", "leviathan_traces": "Leviathan Traces", "flora": "Flora", "minerals": "Minerals", "ruin_patterns": "Ruin Patterns"}
	var result: Array = []
	for id in ["leviathan_traces", "flora", "minerals", "ruin_patterns", "backpack_items"]:
		var count := 0
		for entry in entries:
			if _entry_matches_v5_taxonomy(entry, id): count += 1
		result.append({"id": id, "label": TextCatalogScript.t("codex.taxonomy.%s" % id, [], locale) if TextCatalogScript.t("codex.taxonomy.%s" % id, [], locale) != "codex.taxonomy.%s" % id else fallback[id], "count": count, "active": id == active_id})
	return result

static func _project_v5_sort_options(active_id: String, _locale: String) -> Array:
	return [{"id": "catalog", "label": "Catalog", "active": active_id == "catalog"}, {"id": "name", "label": "Name", "active": active_id == "name"}, {"id": "rarity", "label": "Rarity", "active": active_id == "rarity"}]

static func _sort_v5_entries(entries: Array, sort_id: String) -> void:
	if sort_id == "catalog": return
	entries.sort_custom(func(a: Dictionary, b: Dictionary):
		if sort_id == "name": return str(a.get("name", "")) < str(b.get("name", ""))
		var ranks := {"common": 0, "rare": 1, "epic": 2, "legendary": 3, "mythic": 4}
		var rank_a := int(ranks.get(str(a.get("rarity", "common")), 0))
		var rank_b := int(ranks.get(str(b.get("rarity", "common")), 0))
		return rank_a < rank_b if rank_a != rank_b else str(a.get("name", "")) < str(b.get("name", ""))
	)
