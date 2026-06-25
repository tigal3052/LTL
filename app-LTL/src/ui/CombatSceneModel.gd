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
	if not read_model.get("phase", "") in ["combat", "reward_loot"] or read_model.get("combat", null) == null:
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
	var obstacles_by_cell: Dictionary = {}
	var aimed_cell = combat.get("aim", {}).get("cellId", null)
	var queue_items: Array = combat.get("queue", {}).get("items", [])
	var active_queue_color := ""
	if not queue_items.is_empty():
		active_queue_color = str(queue_items[0].get("color", "")) if queue_items[0] is Dictionary else str(queue_items[0])
	for marker in battlefield.get("weaknessMarkers", []):
		if marker is Dictionary:
			markers[str(marker.get("cellId", ""))] = marker.duplicate(true)
	for obstacle in battlefield.get("obstacles", []):
		if obstacle is Dictionary:
			obstacles_by_cell[str(obstacle.get("cellId", ""))] = obstacle.duplicate(true)
	var frame: Dictionary = layout["battlefieldFrame"]
	var cell_height := int(frame["height"] / rows)
	var cell_width := int(frame["width"] / columns)
	var cells: Array = []
	for row in range(rows):
		for column in range(columns):
			var cell_id := "r%dc%d" % [row, column]
			var marker: Dictionary = markers.get(cell_id, {})
			var weakness = marker.get("color", null) if not marker.is_empty() else null
			var all_energy_weakness := bool(marker.get("allEnergyWeakness", false))
			var obstacle: Variant = obstacles_by_cell.get(cell_id, null)
			cells.append({
				"id": cell_id,
				"row": row,
				"column": column,
				"x": frame["x"] + column * cell_width,
				"y": frame["y"] + row * cell_height,
				"width": cell_width,
				"height": cell_height,
				"weakness": weakness,
				"queueMatch": all_energy_weakness or (not active_queue_color.is_empty() and str(weakness) == active_queue_color),
				"activeQueueColor": active_queue_color,
				"aimed": cell_id == aimed_cell,
				"obstacle": obstacle
			})
	return {"rows": rows, "columns": columns, "cells": cells, "activeQueueColor": active_queue_color}

# 실행: project combat queue, pin, repair, hazard, aim, and disabled state into HUD data.
func _create_hud(combat: Dictionary) -> Dictionary:
	var battlefield: Dictionary = combat.get("battlefield", {})
	var global_debuffs := _global_terrain_debuffs(battlefield.get("terrainDebuffs", []))
	var global_buffs := _global_terrain_buffs(battlefield.get("terrainBuffs", []))
	return {
		"queue": combat.get("queue", {}).duplicate(true),
		"pin": combat.get("pin", {}).duplicate(true),
		"repair": combat.get("repair", {}).duplicate(true),
		"hazard": combat.get("hazard", {}).duplicate(true),
		"aim": combat.get("aim", {}).duplicate(true),
		"terrainDebuffs": global_debuffs,
		"terrainBuffs": global_buffs,
		"purplePressure": _create_purple_pressure(global_debuffs, global_buffs),
		"obstacleFeedbackEvents": _clone_array(battlefield.get("obstacleFeedbackEvents", [])),
		"disabled": combat.get("disabled", false)
	}

# 실행: keep terrain debuffs as global HUD status instead of per-cell state.
func _global_terrain_debuffs(value: Variant) -> Array:
	var result: Array = []
	if not value is Array:
		return result
	for debuff in value:
		if not debuff is Dictionary:
			continue
		var copy: Dictionary = debuff.duplicate(true)
		if not copy.has("scope"):
			copy["scope"] = "global"
		if str(copy.get("scope", "")) == "global":
			result.append(copy)
	return result

func _global_terrain_buffs(value: Variant) -> Array:
	var result: Array = []
	if not value is Array:
		return result
	for buff in value:
		if not buff is Dictionary:
			continue
		var copy: Dictionary = buff.duplicate(true)
		if not copy.has("scope"):
			copy["scope"] = "global"
		if str(copy.get("scope", "")) == "global":
			result.append(copy)
	return result

func _create_purple_pressure(global_debuffs: Array, global_buffs: Array) -> Dictionary:
	var stack_count := 0
	for debuff in global_debuffs:
		if debuff is Dictionary and str(debuff.get("effect", "")) == "weakened_terrain":
			stack_count += maxi(1, int(debuff.get("stacks", 1)))
	var buff_count := 0
	for buff in global_buffs:
		if buff is Dictionary and str(buff.get("effect", "")) == "fortified_terrain":
			buff_count += maxi(1, int(buff.get("stacks", 1)))
	return {
		"stackCount": stack_count,
		"buffCount": buff_count,
		"active": stack_count > 0 or buff_count > 0
	}

# 실행: project target weakness, health, shield, and timer values.
func _create_target_panel(combat: Dictionary) -> Dictionary:
	return {"weakness": _clone_array(combat.get("weakness", [])), "health": combat.get("health", 0.0), "shield": combat.get("shield", 0.0), "maxHealth": combat.get("maxHealth", 0.0), "maxShield": combat.get("maxShield", 0.0), "timeLimitTicks": combat.get("timeLimitTicks", 0), "elapsedTicks": combat.get("elapsedTicks", 0)}

# 실행: project combat result into feedback flags and summary data.
func _create_feedback(combat: Dictionary) -> Dictionary:
	var result := String(combat.get("result", "active"))
	return {"status": result, "mismatch": result == "mismatch", "emptyQueue": result == "empty_queue", "summary": combat.get("summary", {}).duplicate(true)}

# 실행: clone arrays safely and coerce non-array values to empty arrays.
func _clone_array(value: Variant) -> Array:
	return value.duplicate(true) if value is Array else []
