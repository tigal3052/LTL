class_name ItemArtResolver
extends RefCounted

const DRILL_ITEM_ROOT := "res://resources/items/drill"
# Keep the source asset folder spelling: the supplied beacon PNGs live under `becon`.
const BEACON_ITEM_ROOT := "res://resources/items/becon"

static func drill_texture_path(energy_type: String, grade: String) -> String:
	var color := energy_type.to_lower().strip_edges()
	var art_grade := normalized_grade(grade)
	if color.is_empty() or art_grade.is_empty():
		return ""
	return "%s/%s_drill_%s.png" % [DRILL_ITEM_ROOT, color, art_grade]

static func drill_texture_path_for_visual_id(visual_id: String) -> String:
	var key := visual_id.to_lower().strip_edges()
	if key.is_empty():
		return ""
	if key.begins_with("res://"):
		return key
	if key.contains("_drill_"):
		return "%s/%s.png" % [DRILL_ITEM_ROOT, key]
	if not key.begins_with("drill_"):
		return ""
	var parts := key.split("_")
	if parts.size() < 3:
		return ""
	var color := str(parts[1])
	var prefix := "drill_%s_" % color
	var art_key := key.substr(prefix.length())
	if color.is_empty() or art_key.is_empty():
		return ""
	return "%s/%s_drill_%s.png" % [DRILL_ITEM_ROOT, color, art_key]

static func drill_texture_candidates(visual_id: String, energy_type: String, grade: String) -> Array:
	var paths: Array = []
	_append_unique(paths, drill_texture_path_for_visual_id(visual_id))
	_append_unique(paths, drill_texture_path(energy_type, grade))
	return paths

static func beacon_texture_path(energy_type: String, grade: String) -> String:
	var color := energy_type.to_lower().strip_edges()
	var art_grade := normalized_beacon_grade(grade)
	if color.is_empty() or art_grade.is_empty():
		return ""
	return "%s/%s_becon_%s.png" % [BEACON_ITEM_ROOT, color, art_grade]

static func beacon_texture_path_for_visual_id(visual_id: String) -> String:
	var key := visual_id.to_lower().strip_edges()
	if key.is_empty():
		return ""
	if key.begins_with("res://"):
		return key
	if key.contains("_becon_"):
		return "%s/%s.png" % [BEACON_ITEM_ROOT, key]
	if not key.begins_with("beacon_"):
		return ""
	var parts := key.split("_")
	if parts.size() < 3:
		return ""
	var color := str(parts[1])
	var prefix := "beacon_%s_" % color
	var art_key := key.substr(prefix.length())
	if color.is_empty() or art_key.is_empty():
		return ""
	return "%s/%s_becon_%s.png" % [BEACON_ITEM_ROOT, color, normalized_beacon_grade(art_key)]

static func beacon_texture_candidates(visual_id: String, energy_type: String, grade: String) -> Array:
	var paths: Array = []
	var color := energy_type.to_lower().strip_edges()
	_append_unique(paths, beacon_texture_path_for_visual_id(visual_id))
	_append_unique(paths, beacon_texture_path(color, grade))
	for fallback_grade in beacon_fallback_grades(grade):
		_append_unique(paths, beacon_texture_path(color, fallback_grade))
	return paths

static func item_texture_candidates(item_type: String, visual_id: String, energy_type: String, grade: String) -> Array:
	match item_type.to_lower().strip_edges():
		"drill":
			return drill_texture_candidates(visual_id, energy_type, grade)
		"beacon":
			return beacon_texture_candidates(visual_id, energy_type, grade)
	return []

static func normalized_grade(grade: String) -> String:
	var art_grade := grade.to_lower().strip_edges()
	if art_grade == "basic":
		return "common"
	return art_grade

static func normalized_beacon_grade(grade: String) -> String:
	var art_grade := grade.to_lower().strip_edges()
	if art_grade == "basic" or art_grade == "starter":
		return "start"
	return art_grade

static func beacon_fallback_grades(grade: String) -> Array[String]:
	match normalized_beacon_grade(grade):
		"start":
			return ["common", "00"]
		"common":
			return ["start", "00"]
		"rare":
			return ["rare2", "common", "start", "00"]
		"rare2":
			return ["rare", "common", "start", "00"]
		"epic":
			return ["rare2", "rare", "common", "start", "00"]
		"legendary":
			return ["epic2", "epic", "rare2", "rare", "common", "start", "00"]
		"mythic":
			return ["legendary", "epic2", "epic", "rare2", "rare", "common", "start", "00"]
	return ["common", "start", "00"]

static func _append_unique(paths: Array, path: String) -> void:
	if path.is_empty() or paths.has(path):
		return
	paths.append(path)
