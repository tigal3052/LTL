class_name FailureReadModel
extends RefCounted

const TextCatalogScript = preload("res://src/ui/TextCatalog.gd")

static func project(scene: Dictionary) -> Dictionary:
	var phase := str(scene.get("phase", ""))
	var failed := bool(scene.get("failed", false))
	var feedback_status := str(scene.get("feedback", {}).get("status", ""))
	var selected_leviathan: Dictionary = scene.get("selectedLeviathan", {})
	var leviathan_name := str(selected_leviathan.get("name", ""))
	var last_node := str(scene.get("lastNodeLabel", ""))
	var run_number := maxi(1, int(scene.get("runIndex", 0)) + 1)
	var fallback_target := TextCatalogScript.t("failure.run_failed.target_default")
	var fallback_node := TextCatalogScript.t("failure.run_failed.node_default")
	if phase == "run_complete" and failed:
		return {
			"mode": "run_failed",
			"accent": "danger",
			"title": TextCatalogScript.t("failure.run_failed.title"),
			"cause": TextCatalogScript.t("failure.run_failed.cause", [
				leviathan_name if not leviathan_name.is_empty() else fallback_target,
				run_number,
				last_node if not last_node.is_empty() else fallback_node
			]),
			"tip": TextCatalogScript.t("failure.run_failed.tip"),
			"showResetHint": true
		}
	if feedback_status == "repair_blocked":
		return {
			"mode": "repair_blocked",
			"accent": "warning",
			"title": TextCatalogScript.t("failure.repair_blocked.title"),
			"cause": TextCatalogScript.t("failure.repair_blocked.cause"),
			"tip": TextCatalogScript.t("failure.repair_blocked.tip"),
			"showResetHint": false
		}
	if feedback_status == "empty_queue":
		return {
			"mode": "empty_queue",
			"accent": "warning",
			"title": TextCatalogScript.t("failure.empty_queue.title"),
			"cause": TextCatalogScript.t("failure.empty_queue.cause"),
			"tip": TextCatalogScript.t("failure.empty_queue.tip"),
			"showResetHint": false
		}
	if phase == "reward_loot" and bool(scene.get("show_victory_overlay", false)) and not bool(scene.get("is_reveal_vfx_running", false)):
		return {
			"mode": "victory",
			"accent": "success",
			"title": TextCatalogScript.t("failure.victory.title"),
			"cause": TextCatalogScript.t("failure.victory.cause"),
			"tip": TextCatalogScript.t("failure.victory.tip"),
			"showResetHint": false
		}
	return {
		"mode": "hidden",
		"accent": "warning",
		"title": "",
		"cause": "",
		"tip": "",
		"showResetHint": false
	}
