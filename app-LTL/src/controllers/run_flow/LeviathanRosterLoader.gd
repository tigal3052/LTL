extends RefCounted
const TextCatalogScript = preload("res://src/ui/TextCatalog.gd")

const DEFAULT_ART_PATH_BY_ID := {
	"ossuary_tortoise": "res://resources/Leviathan/Leviathan_turtle.png",
	"storm_wyvern": "res://resources/Leviathan/Leviathan_lizard.png",
	"sky_mireu": "res://resources/Leviathan/Leviathan_golem.png",
	"leviathan_drake": "res://resources/Leviathan/Leviathan_drake.png",
}

# ?ㅽ뻾: load and localize the leviathan roster with stable fallback rows.
static func load_leviathan_roster(leviathan_table_path: String) -> Array:
	var file := FileAccess.open(leviathan_table_path, FileAccess.READ)
	if file == null:
		return [
			build_leviathan_row("ossuary_tortoise", "Ossuary Tortoise", "calcified shell", 3, 1, "res://resources/Leviathan/Leviathan_turtle.png"),
			build_leviathan_row("storm_wyvern", "Storm Wyvern", "storm membrane", 4, 2, "res://resources/Leviathan/Leviathan_lizard.png"),
			build_leviathan_row("sky_mireu", "Sky Mireu", "living aurora", 5, 3, "res://resources/Leviathan/Leviathan_golem.png"),
			build_leviathan_row("leviathan_drake", "Drake", "unknown waters", 0, 0, "res://resources/Leviathan/Leviathan_drake.png")
		]
	var json := JSON.new()
	if json.parse(file.get_as_text()) != OK:
		return []
	var data = json.get_data()
	if not (data is Dictionary):
		return []
	var result: Array = []
	for leviathan in data.get("leviathans", []):
		if not (leviathan is Dictionary):
			continue
		var leviathan_id := str(leviathan.get("id", ""))
		var fallback_art_path := str(DEFAULT_ART_PATH_BY_ID.get(leviathan_id, "res://resources/Leviathan/Leviathan_turtle.png"))
		result.append(
			build_leviathan_row(
				leviathan_id,
				str(leviathan.get("name", leviathan_id)),
				str(leviathan.get("biome", "")),
				int(leviathan.get("stageCount", leviathan.get("stageCnt", 3))),
				int(leviathan.get("runCount", leviathan.get("runCnt", 1))),
				str(leviathan.get("artPath", fallback_art_path))
			)
		)
	return result
# ?ㅽ뻾: build one localized leviathan roster row.
# ?ㅽ뻾: build one localized leviathan roster row.
static func build_leviathan_row(leviathan_id: String, fallback_name: String, fallback_biome: String, stage_count: int, run_count: int, art_path: String) -> Dictionary:
	return {
		"id": leviathan_id,
		"name": TextCatalogScript.leviathan_text(leviathan_id, "name", fallback_name),
		"stageCount": stage_count,
		"runCount": run_count,
		"biome": TextCatalogScript.leviathan_text(leviathan_id, "biome", fallback_biome),
		"artPath": art_path
	}
# ?ㅽ뻾: find the selected leviathan row or use the first available row.
# ?ㅽ뻾: find the selected leviathan row or use the first available row.
static func selected_leviathan_data(leviathan_roster: Array, selected_leviathan_id: String) -> Dictionary:
	for leviathan in leviathan_roster:
		if str(leviathan.get("id", "")) == selected_leviathan_id:
			return leviathan.duplicate(true)
	return leviathan_roster[0].duplicate(true) if not leviathan_roster.is_empty() else {}
# ?ㅽ뻾: find the selected character row or fallback to the first selectable row.
