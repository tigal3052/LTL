extends "res://tests/support/UiReadModelTestSuite.gd"

func run_all_tests() -> Dictionary:
	failures.clear()
	test_page_scene_model_builder_script_exists()
	test_page_scene_model_builder_projects_node_select_copy()
	test_page_scene_model_builder_projects_defeat_wireframe_fields()
	return _result()

func test_page_scene_model_builder_script_exists() -> void:
	var script = load("res://src/ui/PageSceneModelBuilder.gd")
	_assert(script != null, "page scene model builder helper exists for MainViewRuntime extraction")

func test_page_scene_model_builder_projects_node_select_copy() -> void:
	var script = load("res://src/ui/PageSceneModelBuilder.gd")
	_assert(script != null, "page scene model builder helper loads for node-select projection")
	if script == null:
		return
	TextCatalogScript.set_locale("ko")
	var model: Dictionary = script.project("node_select", {
		"stageIndex": 1,
		"maxStages": 5,
		"selectedLeviathan": {
			"name": "Basalt Ray",
			"artPath": "res://resources/Leviathan/Leviathan_turtle.png"
		}
	}, "res://resources/charactor/charactor1.png")
	_assert_eq(str(model.get("pageTitle", "")), "Basalt Ray", "node-select page model uses the selected leviathan name as the page title")
	_assert_eq(str(model.get("pageSubtitle", "")), TextCatalogScript.t("main.node_select.subtitle", [TextCatalogScript.t("stage.label", [2, 5], "ko")], "ko"), "node-select page model formats the staged subtitle through the text catalog")
	_assert_eq(str(model.get("pageHeroPath", "")), "res://resources/Leviathan/Leviathan_turtle.png", "node-select page model projects the selected leviathan art path")

func test_page_scene_model_builder_projects_defeat_wireframe_fields() -> void:
	var script = load("res://src/ui/PageSceneModelBuilder.gd")
	_assert(script != null, "page scene model builder helper loads for defeat projection")
	if script == null:
		return
	TextCatalogScript.set_locale("ko")
	var model: Dictionary = script.project("defeat", {
		"phase": "run_complete",
		"failed": true,
		"runIndex": 2,
		"lastNodeLabel": "Storm Wyvern",
		"selectedLeviathan": {
			"name": "Ossuary Tortoise",
			"artPath": "res://resources/Leviathan/Leviathan_lizard.png"
		},
		"selectedCharacter": {"portraitPath": "res://resources/charactor/charactor1.png"}
	}, "res://resources/charactor/charactor1.png")
	_assert_eq(str(model.get("pageEyebrow", "")), TextCatalogScript.t("main.page.badge.defeat", [], "ko"), "defeat page model keeps the defeat eyebrow copy")
	_assert_eq(str(model.get("pageCause", "")), TextCatalogScript.t("failure.run_failed.cause", ["Ossuary Tortoise", 3, "Storm Wyvern"], "ko"), "defeat page model formats the failure cause from leviathan name, run number, and node label")
	_assert_eq(str(model.get("pageButtonText", "")), TextCatalogScript.t("action.retry", [], "ko"), "defeat page model uses the retry CTA")
	_assert_eq(str(model.get("pageCharacterArtPath", "")), "res://resources/charactor/charactor1.png", "defeat page model projects the selected character portrait")
