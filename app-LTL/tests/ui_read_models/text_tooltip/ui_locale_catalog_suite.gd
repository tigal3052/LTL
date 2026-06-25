extends "res://tests/support/UiReadModelTestSuite.gd"
func run_all_tests() -> Dictionary:
	failures.clear()
	reward_reveal_cancel_done_calls = 0
	test_text_catalog_switches_korean_and_english()
	test_text_catalog_loads_external_locale_json()
	test_text_catalog_korean_names_are_readable()
	test_main_view_locale_runtime_helper_exists()
	test_main_controller_character_roster_reloads_from_locale_catalog()
	test_main_controller_leviathan_roster_reloads_from_locale_catalog()
	return _result()
# ?ㅽ뻾: verify UI strings come from a locale-aware text catalog.
func test_text_catalog_switches_korean_and_english() -> void:
	TextCatalogScript.set_locale("ko")
	_assert_eq(TextCatalogScript.t("action.start"), "채굴 시작", "korean text catalog start label")
	_assert_eq(TextCatalogScript.t("item.relic"), "유물", "korean text catalog relic label")
	TextCatalogScript.set_locale("en")
	_assert_eq(TextCatalogScript.t("action.start"), "Start Mining", "english text catalog start label")
	_assert_eq(TextCatalogScript.t("item.relic"), "Relic", "english text catalog relic label")
	TextCatalogScript.set_locale("ko")

# ?ㅽ뻾: verify the text catalog is backed by external locale JSON files.
# ?ㅽ뻾: verify the text catalog is backed by external locale JSON files.
func test_text_catalog_loads_external_locale_json() -> void:
	var catalog = TextCatalogScript.new()
	_assert(catalog.has_method("catalog_source_path"), "text catalog exposes locale JSON source paths")
	_assert(catalog.has_method("debug_catalog"), "text catalog exposes loaded locale catalogs for regression checks")
	if not catalog.has_method("catalog_source_path") or not catalog.has_method("debug_catalog"):
		return
	var ko_path := str(catalog.call("catalog_source_path", "ko"))
	var en_path := str(catalog.call("catalog_source_path", "en"))
	_assert(ko_path.ends_with("text-ko.json"), "korean locale catalog resolves to text-ko.json")
	_assert(en_path.ends_with("text-en.json"), "english locale catalog resolves to text-en.json")
	var ko_catalog: Dictionary = catalog.call("debug_catalog", "ko")
	var en_catalog: Dictionary = catalog.call("debug_catalog", "en")
	_assert(ko_catalog.has("strings"), "korean locale catalog exposes a strings block")
	_assert(en_catalog.has("strings"), "english locale catalog exposes a strings block")
	_assert(ko_catalog.has("characters"), "korean locale catalog exposes character text blocks")
	_assert(en_catalog.has("leviathans"), "english locale catalog exposes leviathan text blocks")
	_assert_eq(str(ko_catalog.get("strings", {}).get("action.start", "")), "채굴 시작", "korean locale JSON contains the start action label")
	_assert_eq(str(en_catalog.get("strings", {}).get("settings.title", "")), "System Calibration", "english locale JSON contains the settings title")

# ?ㅽ뻾: verify Korean display-name mappings are readable.
# ?ㅽ뻾: verify Korean display-name mappings are readable.
func test_text_catalog_korean_names_are_readable() -> void:
	TextCatalogScript.set_locale("ko")
	_assert_eq(TextCatalogScript.display_name("Safe Scar"), "안전한 균열", "safe scar korean display name")
	_assert_eq(TextCatalogScript.display_name("Ruby Drill"), "루비 드릴", "ruby drill korean display name")

func test_main_view_locale_runtime_helper_exists() -> void:
	var helper_path := "res://src/ui/main_view/MainViewLocaleRuntime.gd"
	var Helper = load(helper_path)
	_assert(Helper != null, "main view locale runtime helper exists")
	if Helper != null:
		_assert(Helper.has_method("apply_locale"), "locale helper owns main view text application")
		_assert(Helper.has_method("set_label_text"), "locale helper owns direct label text updates")
		_assert(Helper.has_method("set_bundle_label_text"), "locale helper owns page bundle label text updates")
		_assert(Helper.has_method("resolved_header_title"), "locale helper owns header title resolution")
		_assert(_source_line_count(helper_path) <= 500, "main view locale runtime helper stays within the 500-line cap")
	_assert(_source_line_count("res://src/ui/MainViewRuntime.gd") <= 1135, "MainViewRuntime delegates locale responsibilities")

# ?ㅽ뻾: verify character roster projections rebuild from the active locale catalog.
# ?ㅽ뻾: verify character roster projections rebuild from the active locale catalog.
func test_main_controller_character_roster_reloads_from_locale_catalog() -> void:
	var controller = MainControllerScript.new()
	TextCatalogScript.set_locale("ko")
	var korean_roster: Array = controller.call("_load_character_roster")
	TextCatalogScript.set_locale("en")
	var english_roster: Array = controller.call("_load_character_roster")
	_assert(korean_roster.size() > 0, "character roster projects at least one localized row")
	_assert(english_roster.size() > 0, "character roster projects at least one english row")
	if korean_roster.is_empty() or english_roster.is_empty():
		controller.free()
		TextCatalogScript.set_locale("ko")
		return
	_assert_eq(str(korean_roster[0].get("name", "")), TextCatalogScript.character_text("miner", "name", "", "ko"), "character roster uses Korean catalog text when locale is ko")
	_assert_eq(str(english_roster[0].get("name", "")), TextCatalogScript.character_text("miner", "name", "", "en"), "character roster uses English catalog text when locale is en")
	_assert(str(korean_roster[0].get("name", "")) != str(english_roster[0].get("name", "")), "character roster rebuild changes player-facing text across locales")
	controller.free()
	TextCatalogScript.set_locale("ko")

# ?ㅽ뻾: verify leviathan roster projections rebuild from the active locale catalog.
# ?ㅽ뻾: verify leviathan roster projections rebuild from the active locale catalog.
func test_main_controller_leviathan_roster_reloads_from_locale_catalog() -> void:
	var controller = MainControllerScript.new()
	TextCatalogScript.set_locale("ko")
	var korean_roster: Array = controller.call("_load_leviathan_roster")
	TextCatalogScript.set_locale("en")
	var english_roster: Array = controller.call("_load_leviathan_roster")
	_assert(korean_roster.size() > 0, "leviathan roster projects at least one localized row")
	_assert(english_roster.size() > 0, "leviathan roster projects at least one english row")
	if korean_roster.is_empty() or english_roster.is_empty():
		controller.free()
		TextCatalogScript.set_locale("ko")
		return
	_assert_eq(str(korean_roster[0].get("name", "")), TextCatalogScript.leviathan_text("ossuary_tortoise", "name", "", "ko"), "leviathan roster uses Korean catalog text when locale is ko")
	_assert_eq(str(english_roster[0].get("name", "")), TextCatalogScript.leviathan_text("ossuary_tortoise", "name", "", "en"), "leviathan roster uses English catalog text when locale is en")
	_assert_eq(str(korean_roster[0].get("biome", "")), TextCatalogScript.leviathan_text("ossuary_tortoise", "biome", "", "ko"), "leviathan biome uses Korean catalog text when locale is ko")
	_assert_eq(str(english_roster[0].get("biome", "")), TextCatalogScript.leviathan_text("ossuary_tortoise", "biome", "", "en"), "leviathan biome uses English catalog text when locale is en")
	controller.free()
	TextCatalogScript.set_locale("ko")

# ?ㅽ뻾: verify reward drill tooltips compare only the equipped drill with the same energy color.
func _source_line_count(path: String) -> int:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return 999999
	var text := file.get_as_text()
	file.close()
	return text.split("\n").size()
