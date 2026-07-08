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
		return _with_narrative(_defeat_page_model(scene, selected_leviathan, character_portrait_path), scene)
	match page_id:
		"character_select":
			return scene
		"leviathan_select":
			return scene
		"story_scene":
			return {
				"storyScene": scene.get("storyScene", {"visible": false})
			}
		"node_select":
			var node_select_scene := scene.duplicate(true)
			node_select_scene["pageTitle"] = str(selected_leviathan.get("name", TextCatalogScript.t("leviathan.roster.title")))
			node_select_scene["pageSubtitle"] = ""
			node_select_scene["pageHeroPath"] = str(selected_leviathan.get("artPath", "res://resources/Leviathan/Leviathan_turtle.png"))
			return _with_narrative(node_select_scene, scene)
		"battle":
			return _with_narrative({
				"pageBadge": TextCatalogScript.t("main.page.badge.combat"),
				"pageKicker": TextCatalogScript.t("main.page.kicker.extraction"),
				"pageTitle": str(node_context.get("label", scene.get("lastNodeLabel", TextCatalogScript.display_name("Safe Scar")))),
				"pageSubtitle": TextCatalogScript.t("main.page.subtitle.battle"),
				"pageHeroPath": "res://resources/charactor/background.png"
			}, scene)
		"boss_battle":
			return _with_narrative({
				"pageBadge": TextCatalogScript.t("main.page.badge.boss"),
				"pageKicker": TextCatalogScript.t("main.page.kicker.final_engagement"),
				"pageTitle": str(node_context.get("label", TextCatalogScript.display_name("Spine Anchor"))),
				"pageSubtitle": TextCatalogScript.t("main.page.subtitle.boss"),
				"pageHeroPath": str(selected_leviathan.get("artPath", "res://resources/Leviathan/Leviathan_golem.png"))
			}, scene)
		"reward":
			return _with_narrative({
				"pageBadge": TextCatalogScript.t("main.page.badge.reward"),
				"pageKicker": TextCatalogScript.t("main.page.kicker.recovery"),
				"pageTitle": TextCatalogScript.t("main.page.title.reward"),
				"pageSubtitle": TextCatalogScript.t("main.page.subtitle.reward"),
				"pageHeroPath": "res://resources/Leviathan/Leviathan_lizard.png"
			}, scene)
		"boss_reward":
			return _with_narrative({
				"pageBadge": TextCatalogScript.t("main.page.badge.boss_reward"),
				"pageKicker": TextCatalogScript.t("main.page.kicker.contract_payout"),
				"pageTitle": TextCatalogScript.t("main.page.title.boss_reward"),
				"pageSubtitle": TextCatalogScript.t("main.page.subtitle.boss_reward"),
				"pageHeroPath": str(selected_leviathan.get("artPath", "res://resources/Leviathan/Leviathan_golem.png"))
			}, scene)
		"event_node":
			return _with_narrative({
				"pageBadge": TextCatalogScript.t("main.page.badge.event"),
				"pageKicker": TextCatalogScript.t("main.page.kicker.special_node"),
				"pageTitle": str(node_context.get("label", TextCatalogScript.display_name("Mysterious Crevice"))),
				"pageSubtitle": TextCatalogScript.t("main.page.subtitle.event"),
				"pageHeroPath": str(selected_leviathan.get("artPath", "res://resources/Leviathan/Leviathan_turtle.png"))
			}, scene)
		"clear":
			return _with_narrative({
				"pageTitle": TextCatalogScript.t("main.page.title.clear"),
				"pageSubtitle": TextCatalogScript.t("main.page.subtitle.clear"),
				"pageButtonText": TextCatalogScript.t("main.page.button.return_character"),
				"pageHeroPath": str(selected_leviathan.get("artPath", "res://resources/Leviathan/Leviathan_lizard.png"))
			}, scene)
	return scene

static func refresh_inactive_meta_page_models(page_scenes: Dictionary, meta_page_ids: Array, active_id: String, scene: Dictionary, character_portrait_path: String) -> void:
	for page_id in meta_page_ids:
		if page_id == active_id:
			continue
		var page_scene = page_scenes.get(page_id, null)
		if page_scene == null or not page_scene.has_method("apply_state"):
			continue
		page_scene.apply_state(project(page_id, scene, character_portrait_path))

static func _defeat_page_model(scene: Dictionary, selected_leviathan: Dictionary, character_portrait_path: String) -> Dictionary:
	var failure_model: Dictionary = FailureReadModelScript.project(scene)
	var selected_character: Dictionary = scene.get("selectedCharacter", {})
	var fallback_target := str(selected_leviathan.get("name", TextCatalogScript.t("failure.run_failed.target_default")))
	var fallback_node := str(scene.get("lastNodeLabel", TextCatalogScript.t("failure.run_failed.node_default")))
	var retry_options: Array = failure_model.get("retryOptions", [])
	var same_seed_label := TextCatalogScript.t("action.retry_same_seed")
	var new_seed_label := TextCatalogScript.t("action.retry_new_seed")
	for option in retry_options:
		if not (option is Dictionary):
			continue
		if str(option.get("id", "")) == "same_seed":
			same_seed_label = str(option.get("label", same_seed_label))
		elif str(option.get("id", "")) == "new_seed":
			new_seed_label = str(option.get("label", new_seed_label))
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
		"pageRetrySameSeedText": same_seed_label,
		"pageRetryNewSeedText": new_seed_label,
		"pageRetryOptions": retry_options.duplicate(true),
		"pageHeroPath": str(selected_leviathan.get("artPath", "res://resources/Leviathan/Leviathan_golem.png")),
		"pageCharacterArtPath": str(selected_character.get("portraitPath", character_portrait_path)),
		"pageStageBackdropPath": "res://resources/charactor/background.png"
	}

static func _with_narrative(model: Dictionary, scene: Dictionary) -> Dictionary:
	var next := model.duplicate(true)
	var narrative_value = scene.get("narrative", {"visible": false})
	next["narrative"] = narrative_value.duplicate(true) if narrative_value is Dictionary else {"visible": false}
	return next

static func _node_select_page_subtitle(stage_label_text: String) -> String:
	return TextCatalogScript.t("main.node_select.subtitle", [stage_label_text])
