class_name HudReadModel
extends RefCounted

const TextCatalogScript = preload("res://src/ui/TextCatalog.gd")

static func project(scene: Dictionary) -> Dictionary:
	var hud: Dictionary = scene.get("hud", {})
	var queue: Dictionary = hud.get("queue", {})
	var items: Array = queue.get("items", [])
	var now_color := _queue_color(items, 0)
	var next_color := _queue_color(items, 1)
	var reserve_count := maxi(0, items.size() - 2)
	var feedback_status := str(scene.get("feedback", {}).get("status", "active"))
	var repair_stage := _repair_stage(hud, feedback_status)
	var hazard: Dictionary = hud.get("hazard", {})
	var hazard_family := str(hazard.get("label", "stable"))
	var hazard_count := int(hazard.get("obstacleCount", 0))
	var target_weakness: Array = scene.get("targetPanel", {}).get("weakness", []).duplicate(true) if scene.get("targetPanel", {}).get("weakness", []) is Array else []
	var queue_match := not now_color.is_empty() and target_weakness.has(now_color)
	return {
		"queue": {
			"nowColor": now_color,
			"nextColor": next_color,
			"reserveCount": reserve_count,
			"loaded": int(queue.get("loaded", items.size())),
			"capacity": int(queue.get("capacity", max(items.size(), 1))),
			"queueMatch": queue_match
		},
		"aim": {
			"canFire": bool(hud.get("aim", {}).get("canFire", false)),
			"cellId": str(hud.get("aim", {}).get("cellId", "")),
			"targetColor": str(hud.get("aim", {}).get("targetColor", ""))
		},
		"repair": {
			"stage": repair_stage,
			"label": _repair_stage_label(repair_stage),
			"active": bool(hud.get("repair", {}).get("active", false))
		},
		"hazard": {
			"active": bool(hazard.get("active", false)),
			"severity": str(hazard.get("severity", "stable")),
			"family": hazard_family,
			"familyLabel": _hazard_family_label(hazard_family),
			"obstacleCount": hazard_count,
			"summary": _hazard_summary(hazard_family, hazard_count, str(hazard.get("severity", "stable")))
		},
		"purplePressure": hud.get("purplePressure", {}).duplicate(true),
		"feedback": {
			"status": feedback_status,
			"isMismatch": feedback_status == "mismatch",
			"isEmptyQueue": feedback_status == "empty_queue",
			"isRepairBlocked": feedback_status == "repair_blocked",
			"isDisabledTarget": feedback_status == "disabled_target"
		}
	}

static func _queue_color(items: Array, index: int) -> String:
	if index < 0 or index >= items.size():
		return ""
	var item = items[index]
	return str(item.get("color", "")) if item is Dictionary else str(item)

static func _repair_stage(hud: Dictionary, feedback_status: String) -> String:
	if feedback_status == "repair_blocked":
		return "repair_required"
	if bool(hud.get("repair", {}).get("active", false)):
		return "repair_required"
	var loaded := int(hud.get("queue", {}).get("loaded", 0))
	var pin_progress := float(hud.get("pin", {}).get("progress", 0.0))
	if loaded <= 0:
		return "critical"
	if pin_progress >= 75.0:
		return "strained"
	if bool(hud.get("hazard", {}).get("active", false)):
		return "critical" if str(hud.get("hazard", {}).get("severity", "stable")) == "critical" else "strained"
	return "stable"

static func _repair_stage_label(stage: String) -> String:
	return TextCatalogScript.t("hud.repair.%s" % stage)

static func _hazard_family_label(family: String) -> String:
	return TextCatalogScript.t("hud.hazard.%s" % family)

static func _hazard_summary(family: String, obstacle_count: int, severity: String) -> String:
	if severity == "stable":
		return TextCatalogScript.t("hud.hazard.clear")
	var family_text := _hazard_family_label(family)
	return "%s x%d" % [family_text, maxi(1, obstacle_count)]
