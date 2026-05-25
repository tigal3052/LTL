# 계약:
# - 책임: combat phase에서 제한된 public presentation state를 별도 read model로 조립한다.
# - 입력: combat phase public snapshot, optional label/lookup tables.
# - 출력: combat HUD, target panel, queue panel, feedback rendering에 필요한 read-only data contract.
# - 금지: combat progression mutation, reward state 접근, browser render ordering 가정
#
# 실행: define the combat scene model class identity.
class_name CombatSceneModel
extends RefCounted

# 실행: preload the scene read model used to sanitize run snapshots.
const SceneReadModelScript = preload("res://src/ui/SceneReadModel.gd")

# 실행: create a read model builder for combat scene projection.
var read_model_builder := SceneReadModelScript.new()

# 실행: create a combat-only scene model or a guard-failure surface for other phases.
func create(run_snapshot: Dictionary, options: Dictionary = {}) -> Dictionary:
	var read_model: Dictionary = read_model_builder.create(run_snapshot, options)
	var layout := _create_layout(int(options.get("viewportWidth", 1920)), int(options.get("viewportHeight", 1080)))
	if read_model.get("phase", "") != "combat" or read_model.get("combat", null) == null:
		return {"ok": false, "phase": read_model.get("phase", "unknown"), "layout": layout, "terrain": {"rows": 0, "columns": 0, "cells": []}, "hud": {}, "targetPanel": {}, "feedback": {"status": "not_in_combat"}}
	var combat: Dictionary = read_model["combat"]
	var terrain := _create_terrain(combat, layout)
	return {"ok": true, "phase": read_model["phase"], "lastNodeLabel": read_model.get("lastNodeLabel", ""), "layout": layout, "terrain": terrain, "hud": _create_hud(combat), "targetPanel": _create_target_panel(combat), "feedback": _create_feedback(combat)}

# 실행: compute stable top, bottom, and battlefield frame layout rectangles.
func _create_layout(viewport_width: int, viewport_height: int) -> Dictionary:
	var top_height := roundi(viewport_height * 0.7)
	var bottom_height := viewport_height - top_height
	var character_width := roundi(viewport_width * 0.3)
	return {"viewport": {"width": viewport_width, "height": viewport_height}, "top": {"x": 0, "y": 0, "width": viewport_width, "height": top_height}, "bottom": {"x": 0, "y": top_height, "width": viewport_width, "height": bottom_height}, "topPanels": {"character": {"x": 0, "y": 0, "width": character_width, "height": top_height}, "backpack": {"x": character_width, "y": 0, "width": viewport_width - character_width, "height": top_height}}, "battlefieldFrame": {"x": 0, "y": top_height, "width": viewport_width, "height": bottom_height}}

# 실행: turn battlefield markers into positioned terrain cells.
func _create_terrain(combat: Dictionary, layout: Dictionary) -> Dictionary:
	var battlefield: Dictionary = combat.get("battlefield", {})
	var rows := maxi(1, int(battlefield.get("rows", 3)))
	var columns := maxi(1, int(battlefield.get("columns", 10)))
	var markers: Dictionary = {}
	var aimed_cell = combat.get("aim", {}).get("cellId", null)
	for marker in battlefield.get("weaknessMarkers", []):
		markers[marker.get("cellId", "")] = marker.get("color", null)
	var frame: Dictionary = layout["battlefieldFrame"]
	var cell_width := int(frame["width"] / columns)
	var cell_height := int(frame["height"] / rows)
	var cells: Array = []
	for row in range(rows):
		for column in range(columns):
			var cell_id := "r%dc%d" % [row, column]
			cells.append({"id": cell_id, "row": row, "column": column, "x": frame["x"] + column * cell_width, "y": frame["y"] + row * cell_height, "width": cell_width, "height": cell_height, "weakness": markers.get(cell_id, null), "aimed": cell_id == aimed_cell})
	return {"rows": rows, "columns": columns, "cells": cells}

# 실행: project combat queue, pin, repair, hazard, aim, and disabled state into HUD data.
func _create_hud(combat: Dictionary) -> Dictionary:
	return {"queue": combat.get("queue", {}).duplicate(true), "pin": combat.get("pin", {}).duplicate(true), "repair": combat.get("repair", {}).duplicate(true), "hazard": combat.get("hazard", {}).duplicate(true), "aim": combat.get("aim", {}).duplicate(true), "disabled": combat.get("disabled", false)}

# 실행: project target weakness, health, shield, and timer values.
func _create_target_panel(combat: Dictionary) -> Dictionary:
	return {"weakness": _clone_array(combat.get("weakness", [])), "health": combat.get("health", 0.0), "shield": combat.get("shield", 0.0), "maxHealth": combat.get("maxHealth", 0.0), "maxShield": combat.get("maxShield", 0.0), "timeLimitTicks": combat.get("timeLimitTicks", 0)}

# 실행: project combat result into feedback flags and summary data.
func _create_feedback(combat: Dictionary) -> Dictionary:
	var result := String(combat.get("result", "active"))
	return {"status": result, "mismatch": result == "mismatch", "emptyQueue": result == "empty_queue", "summary": combat.get("summary", {}).duplicate(true)}

# 실행: clone arrays safely and coerce non-array values to empty arrays.
func _clone_array(value: Variant) -> Array:
	return value.duplicate(true) if value is Array else []
