extends SceneTree

const TextCatalogScript = preload("res://src/ui/TextCatalog.gd")
const MainControllerScript = preload("res://src/MainController.gd")
const HudReadModelScript = preload("res://src/ui/read_models/HudReadModel.gd")
const FailureReadModelScript = preload("res://src/ui/read_models/FailureReadModel.gd")
const LTLThemeScript = preload("res://src/ui/theme/LTLTheme.gd")

var failures: Array[String] = []

func _init() -> void:
	_run()
	if failures.is_empty():
		print("I18N_LOCALIZATION_SMOKE_OK")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)

func _run() -> void:
	var catalog = TextCatalogScript.new()
	_assert(catalog.has_method("catalog_source_path"), "TextCatalog exposes catalog_source_path")
	_assert(catalog.has_method("debug_catalog"), "TextCatalog exposes debug_catalog")
	if catalog.has_method("catalog_source_path"):
		_assert(str(catalog.call("catalog_source_path", "ko")).ends_with("text-ko.json"), "Korean locale path points to text-ko.json")
		_assert(str(catalog.call("catalog_source_path", "en")).ends_with("text-en.json"), "English locale path points to text-en.json")
	if catalog.has_method("debug_catalog"):
		var ko_catalog: Dictionary = catalog.call("debug_catalog", "ko")
		var en_catalog: Dictionary = catalog.call("debug_catalog", "en")
		_assert(ko_catalog.has("strings"), "Korean catalog has strings")
		_assert(en_catalog.has("strings"), "English catalog has strings")
	TextCatalogScript.set_locale("ko")
	_assert_eq(TextCatalogScript.t("action.start"), "채굴 시작", "Korean start action resolves from catalog")
	TextCatalogScript.set_locale("en")
	_assert_eq(TextCatalogScript.t("action.start"), "Start Mining", "English start action resolves from catalog")
	var controller = MainControllerScript.new()
	TextCatalogScript.set_locale("ko")
	var korean_roster: Array = controller.call("_load_character_roster")
	var korean_leviathans: Array = controller.call("_load_leviathan_roster")
	TextCatalogScript.set_locale("en")
	var english_roster: Array = controller.call("_load_character_roster")
	var english_leviathans: Array = controller.call("_load_leviathan_roster")
	_assert(korean_roster.size() > 0, "Korean character roster loads")
	_assert(english_roster.size() > 0, "English character roster loads")
	_assert_eq(str(korean_roster[0].get("name", "")), "심해 구명병", "Korean roster name localizes")
	_assert_eq(str(english_roster[0].get("name", "")), "Anchor Miner", "English roster name localizes")
	_assert_eq(str(korean_leviathans[0].get("name", "")), "유해갑 거북", "Korean leviathan name localizes")
	_assert_eq(str(english_leviathans[0].get("biome", "")), "calcified shell", "English leviathan biome localizes")
	controller.free()
	TextCatalogScript.set_locale("en")
	var hud_model := HudReadModelScript.project({
		"hud": {
			"queue": {"items": ["green", "blue", "purple"], "loaded": 3, "capacity": 8},
			"aim": {"canFire": true},
			"repair": {"active": false},
			"pin": {"progress": 20.0},
			"hazard": {"active": true, "severity": "active", "label": "green", "obstacleCount": 2}
		},
		"feedback": {"status": "match"},
		"targetPanel": {"weakness": ["green"]}
	})
	_assert_eq(str(hud_model.get("repair", {}).get("label", "")), "Strained", "HUD repair label localizes to English")
	TextCatalogScript.set_locale("ko")
	hud_model = HudReadModelScript.project({
		"hud": {
			"queue": {"items": ["green", "blue", "purple"], "loaded": 3, "capacity": 8},
			"aim": {"canFire": true},
			"repair": {"active": false},
			"pin": {"progress": 20.0},
			"hazard": {"active": true, "severity": "active", "label": "green", "obstacleCount": 2}
		},
		"feedback": {"status": "match"},
		"targetPanel": {"weakness": ["green"]}
	})
	_assert_eq(str(hud_model.get("hazard", {}).get("summary", "")), "포자 침식 x2", "HUD hazard summary localizes to Korean")
	TextCatalogScript.set_locale("en")
	var failure_model := FailureReadModelScript.project({
		"phase": "run_complete",
		"failed": true,
		"lastNodeLabel": "Storm Spine",
		"stageIndex": 2,
		"maxStages": 4
	})
	_assert_eq(str(failure_model.get("title", "")), "Expedition Failed", "Failure read model title localizes to English")
	TextCatalogScript.set_locale("ko")
	failure_model = FailureReadModelScript.project({
		"phase": "run_complete",
		"failed": true,
		"lastNodeLabel": "폭풍 척추",
		"stageIndex": 2,
		"maxStages": 4
	})
	_assert(str(failure_model.get("cause", "")).contains("폭풍 척추"), "Failure read model Korean cause keeps the localized node label")
	var shared_theme := LTLThemeScript.shared_theme()
	_assert(shared_theme != null, "Shared theme loads")
	_assert(shared_theme.default_font != null, "Shared theme provides a default font")

func _assert(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

func _assert_eq(actual, expected, message: String) -> void:
	if actual != expected:
		failures.append("%s: expected %s, got %s" % [message, str(expected), str(actual)])
