extends RefCounted
const TextCatalogScript = preload("res://src/ui/TextCatalog.gd")
# ?ㅽ뻾: load and localize the character roster with stable fallback rows.
static func load_character_roster(character_table_path: String, portrait_path: String) -> Array:
	var fallback_ids := [
		{"id": "miner", "name": "Anchor Miner", "unlocked": true},
		{"id": "engineer", "name": "Pulse Engineer", "unlocked": false},
		{"id": "mechanic", "name": "Hull Mechanic", "unlocked": false}
	]
	var file := FileAccess.open(character_table_path, FileAccess.READ)
	if file == null:
		return _fallback_character_rows(fallback_ids, portrait_path)
	var json := JSON.new()
	if json.parse(file.get_as_text()) != OK:
		return _fallback_character_rows(fallback_ids, portrait_path)
	var data = json.get_data()
	if not (data is Dictionary):
		return _fallback_character_rows(fallback_ids, portrait_path)
	var result: Array = []
	for character in data.get("characters", []):
		if not (character is Dictionary):
			continue
		var character_id := str(character.get("id", ""))
		if character_id.is_empty():
			continue
		result.append(
			build_character_row(
				character_id,
				str(character.get("name", character_id)),
				str(character.get("portrait", portrait_path)),
				bool(character.get("unlocked", false)),
				portrait_path
			)
		)
	return append_character_placeholder_slots(result if not result.is_empty() else [], portrait_path)
# ?ㅽ뻾: build fallback character rows from inline defaults.
# ?ㅽ뻾: build fallback character rows from inline defaults.
static func _fallback_character_rows(fallback_ids: Array, portrait_path: String) -> Array:
	var rows: Array = []
	for entry in fallback_ids:
		rows.append(build_character_row(str(entry.get("id", "")), str(entry.get("name", "")), portrait_path, bool(entry.get("unlocked", false)), portrait_path))
	return append_character_placeholder_slots(rows, portrait_path)
# ?ㅽ뻾: build one localized character roster row.
# ?ㅽ뻾: build one localized character roster row.
static func build_character_row(character_id: String, fallback_name: String, portrait_path: String, selectable: bool, default_portrait_path: String) -> Dictionary:
	return {
		"id": character_id,
		"name": TextCatalogScript.character_text(character_id, "name", fallback_name),
		"role": TextCatalogScript.character_text(character_id, "role", ""),
		"rosterMeta": TextCatalogScript.character_text(character_id, "rosterMeta", ""),
		"rosterLongCopy": TextCatalogScript.character_text(character_id, "rosterLongCopy", ""),
		"description": TextCatalogScript.character_text(character_id, "description", ""),
		"heroLine": TextCatalogScript.character_text(character_id, "heroLine", ""),
		"portraitPath": portrait_path if not portrait_path.is_empty() else default_portrait_path,
		"selectable": selectable,
		"locked": not selectable,
		"summary": TextCatalogScript.character_text(character_id, "summary", ""),
		"tags": TextCatalogScript.character_tags(character_id),
		"accentColor": character_accent(character_id)
	}
# ?ㅽ뻾: choose the visual accent color for one character id.
# ?ㅽ뻾: choose the visual accent color for one character id.
static func character_accent(character_id: String) -> String:
	match character_id:
		"miner":
			return "red"
		"engineer", "bulk_diver":
			return "blue"
		"mechanic", "pressure_cartographer":
			return "green"
		"future_trawler":
			return "purple"
	return "red"
# ?ㅽ뻾: pad the roster with future character placeholders.
# ?ㅽ뻾: pad the roster with future character placeholders.
static func append_character_placeholder_slots(base_roster: Array, portrait_path: String) -> Array:
	var roster := base_roster.duplicate(true)
	var placeholders := [
		build_character_row("future_trawler", "Future Trawler", portrait_path, false, portrait_path),
		build_character_row("bulk_diver", "Bulk Diver", portrait_path, false, portrait_path),
		build_character_row("pressure_cartographer", "Pressure Cartographer", portrait_path, false, portrait_path)
	]
	var index := 0
	while roster.size() < 6 and index < placeholders.size():
		roster.append(placeholders[index].duplicate(true))
		index += 1
	return roster
# ?ㅽ뻾: load and localize the leviathan roster with stable fallback rows.
# ?ㅽ뻾: find the selected character row or fallback to the first selectable row.
static func selected_character_data(character_roster: Array, selected_character_id: String, portrait_path: String) -> Dictionary:
	for character in character_roster:
		if str(character.get("id", "")) == selected_character_id:
			return character.duplicate(true)
	for character in character_roster:
		if bool(character.get("selectable", false)):
			return character.duplicate(true)
	return {
		"id": selected_character_id,
		"name": TextCatalogScript.character_text(selected_character_id, "name", "Anchor Miner"),
		"role": TextCatalogScript.character_text(selected_character_id, "role", ""),
		"rosterMeta": TextCatalogScript.character_text(selected_character_id, "rosterMeta", ""),
		"rosterLongCopy": TextCatalogScript.character_text(selected_character_id, "rosterLongCopy", ""),
		"description": TextCatalogScript.character_text(selected_character_id, "description", ""),
		"heroLine": TextCatalogScript.character_text(selected_character_id, "heroLine", ""),
		"portraitPath": portrait_path,
		"selectable": true,
		"locked": false,
		"summary": TextCatalogScript.character_text(selected_character_id, "summary", ""),
		"tags": TextCatalogScript.character_tags(selected_character_id),
		"accentColor": "red"
	}
# ?ㅽ뻾: build preview-controller options from current start-flow selections.
