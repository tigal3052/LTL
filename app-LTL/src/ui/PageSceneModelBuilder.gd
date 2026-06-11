class_name PageSceneModelBuilder
extends RefCounted

const TextCatalogScript = preload("res://src/ui/TextCatalog.gd")
const FailureReadModelScript = preload("res://src/ui/read_models/FailureReadModel.gd")

static func project(page_id: String, scene: Dictionary, character_portrait_path: String) -> Dictionary:
	var selected_leviathan: Dictionary = scene.get("selectedLeviathan", {})
	var node_context: Dictionary = scene.get("selectedNodeContext", {})
	var stage_index := int(scene.get("stageIndex", 0)) + 1
	var max_stages := maxi(1, int(scene.get("maxStages", 1)))
	var stage_label_text := TextCatalogScript.t("stage.label", [stage_index, max_stages])
	if page_id == "defeat":
		return _defeat_page_model(scene, selected_leviathan, character_portrait_path)
	match page_id:
		"character_select":
			return scene
		"leviathan_select":
			return scene
		"node_select":
			var node_select_scene := scene.duplicate(true)
			node_select_scene["pageTitle"] = str(selected_leviathan.get("name", TextCatalogScript.t("leviathan.roster.title")))
			node_select_scene["pageSubtitle"] = _node_select_page_subtitle(stage_label_text)
			node_select_scene["pageHeroPath"] = str(selected_leviathan.get("artPath", "res://resources/Leviathan/Leviathan_turtle.png"))
			return node_select_scene
		"battle":
			return {
				"pageBadge": TextCatalogScript.t("main.page.badge.combat"),
				"pageKicker": TextCatalogScript.t("main.page.kicker.extraction"),
				"pageTitle": str(node_context.get("label", scene.get("lastNodeLabel", TextCatalogScript.display_name("Safe Scar")))),
				"pageSubtitle": TextCatalogScript.t("main.page.subtitle.battle"),
				"pageHeroPath": "res://resources/charactor/background.png"
			}
		"boss_battle":
			return {
				"pageBadge": TextCatalogScript.t("main.page.badge.boss"),
				"pageKicker": TextCatalogScript.t("main.page.kicker.final_engagement"),
				"pageTitle": str(node_context.get("label", TextCatalogScript.display_name("Spine Anchor"))),
				"pageSubtitle": TextCatalogScript.t("main.page.subtitle.boss"),
				"pageHeroPath": str(selected_leviathan.get("artPath", "res://resources/Leviathan/Leviathan_golem.png"))
			}
		"reward":
			return {
				"pageBadge": TextCatalogScript.t("main.page.badge.reward"),
				"pageKicker": TextCatalogScript.t("main.page.kicker.recovery"),
				"pageTitle": TextCatalogScript.t("main.page.title.reward"),
				"pageSubtitle": TextCatalogScript.t("main.page.subtitle.reward"),
				"pageHeroPath": "res://resources/Leviathan/Leviathan_lizard.png"
			}
		"boss_reward":
			return {
				"pageBadge": TextCatalogScript.t("main.page.badge.boss_reward"),
				"pageKicker": TextCatalogScript.t("main.page.kicker.contract_payout"),
				"pageTitle": TextCatalogScript.t("main.page.title.boss_reward"),
				"pageSubtitle": TextCatalogScript.t("main.page.subtitle.boss_reward"),
				"pageHeroPath": str(selected_leviathan.get("artPath", "res://resources/Leviathan/Leviathan_golem.png"))
			}
		"event_node":
			return {
				"pageBadge": TextCatalogScript.t("main.page.badge.event"),
				"pageKicker": TextCatalogScript.t("main.page.kicker.special_node"),
				"pageTitle": str(node_context.get("label", TextCatalogScript.display_name("Mysterious Crevice"))),
				"pageSubtitle": TextCatalogScript.t("main.page.subtitle.event"),
				"pageHeroPath": str(selected_leviathan.get("artPath", "res://resources/Leviathan/Leviathan_turtle.png"))
			}
		"clear":
			return {
				"pageTitle": TextCatalogScript.t("main.page.title.clear"),
				"pageSubtitle": TextCatalogScript.t("main.page.subtitle.clear"),
				"pageButtonText": TextCatalogScript.t("main.page.button.return_character"),
				"pageHeroPath": str(selected_leviathan.get("artPath", "res://resources/Leviathan/Leviathan_lizard.png"))
			}
	return scene

static func _defeat_page_model(scene: Dictionary, selected_leviathan: Dictionary, character_portrait_path: String) -> Dictionary:
	var failure_model: Dictionary = FailureReadModelScript.project(scene)
	var selected_character: Dictionary = scene.get("selectedCharacter", {})
	var fallback_target := str(selected_leviathan.get("name", TextCatalogScript.t("failure.run_failed.target_default")))
	var fallback_node := str(scene.get("lastNodeLabel", TextCatalogScript.t("failure.run_failed.node_default")))
	return {
		"pageEyebrow": TextCatalogScript.t("main.page.badge.defeat"),
		"pageTitle": str(failure_model.get("title", TextCatalogScript.t("main.page.title.defeat"))),
		"pageSubtitle": "",
		"pageBoardTitle": "",
		"pageBoardHint": "",
		"pageCause": str(failure_model.get("cause", TextCatalogScript.t("failure.run_failed.cause", [
			fallback_target,
			maxi(1, int(scene.get("runIndex", 0)) + 1),
			fallback_node
		]))),
		"pageTip": str(failure_model.get("tip", TextCatalogScript.t("failure.run_failed.tip"))),
		"pageButtonText": TextCatalogScript.t("action.retry"),
		"pageHeroPath": str(selected_leviathan.get("artPath", "res://resources/Leviathan/Leviathan_golem.png")),
		"pageCharacterArtPath": str(selected_character.get("portraitPath", character_portrait_path)),
		"pageStageBackdropPath": "res://resources/charactor/background.png"
	}

static func _node_select_page_subtitle(stage_label_text: String) -> String:
	return TextCatalogScript.t("main.node_select.subtitle", [stage_label_text])
