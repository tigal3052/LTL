extends RefCounted

const EnergyTempoBalanceScript = preload("res://src/balance/EnergyTempoBalance.gd")

static func for_debug(base_growth_state: Dictionary, reward_table: Dictionary, force_all_discovered: bool) -> Dictionary:
	var codex_growth := base_growth_state.duplicate(true)
	if not force_all_discovered:
		return codex_growth
	var discovered_ids: Array = codex_growth.get("artifactDiscovery", []).duplicate(true)
	var discovered_lookup := {}
	for entry_id in discovered_ids:
		discovered_lookup[str(entry_id)] = true
	for reward in reward_table.get("rewards", []):
		if not (reward is Dictionary):
			continue
		var reward_id := str(reward.get("id", reward.get("catalogId", "")))
		if reward_id.is_empty() or discovered_lookup.has(reward_id):
			continue
		discovered_lookup[reward_id] = true
		discovered_ids.append(reward_id)
	codex_growth["artifactDiscovery"] = discovered_ids
	return codex_growth

static func starter_discovery_ids_for_color(reward_table: Dictionary, _start_color: String) -> Array:
	var discovery_ids: Array = []
	var claimed_types := {}
	for color in EnergyTempoBalanceScript.VALID_COLORS:
		claimed_types[color] = {}
	for reward in reward_table.get("rewards", []):
		if not (reward is Dictionary):
			continue
		var tags = reward.get("tags", [])
		if not (tags is Array) or not tags.has("starter_safe"):
			continue
		var payload: Dictionary = reward.get("payload", {})
		var energy_type := str(payload.get("energy_type", "")).to_lower()
		if not (energy_type in EnergyTempoBalanceScript.VALID_COLORS):
			continue
		var item_type := str(payload.get("item_type", "")).to_lower()
		if not claimed_types.has(energy_type):
			claimed_types[energy_type] = {}
		if not (item_type in ["drill", "beacon"]) or claimed_types[energy_type].has(item_type):
			continue
		var reward_id := str(reward.get("id", reward.get("catalogId", "")))
		if reward_id.is_empty():
			continue
		claimed_types[energy_type][item_type] = true
		discovery_ids.append(reward_id)
	return discovery_ids

static func with_starter_discoveries(base_growth_state: Dictionary, reward_table: Dictionary, start_color: String) -> Dictionary:
	var codex_growth := base_growth_state.duplicate(true)
	var discovered_ids: Array = codex_growth.get("artifactDiscovery", []).duplicate(true)
	var discovered_lookup := {}
	for entry_id in discovered_ids:
		discovered_lookup[str(entry_id)] = true
	for starter_id in starter_discovery_ids_for_color(reward_table, start_color):
		var normalized_id := str(starter_id)
		if normalized_id.is_empty() or discovered_lookup.has(normalized_id):
			continue
		discovered_lookup[normalized_id] = true
		discovered_ids.append(normalized_id)
	codex_growth["artifactDiscovery"] = discovered_ids
	return codex_growth
