extends "res://tests/support/UiReadModelTestSuite.gd"

func run_all_tests() -> Dictionary:
	failures.clear()
	test_page_scene_registry_helper_exists()
	test_main_view_page_shell_runtime_helper_exists()
	test_page_scene_registry_mounts_meta_and_gameplay_pages_under_separate_hosts()
	test_page_scene_registry_toggles_host_visibility_for_active_page()
	return _result()

func test_page_scene_registry_helper_exists() -> void:
	var helper = load("res://src/ui/PageSceneRegistry.gd")
	_assert(helper != null, "page scene registry helper exists for MainViewRuntime extraction")

func test_main_view_page_shell_runtime_helper_exists() -> void:
	var helper_path := "res://src/ui/main_view/MainViewPageShellRuntime.gd"
	var HelperScript = load(helper_path)
	_assert(HelperScript != null, "MainView page shell runtime helper exists")
	if HelperScript != null:
		_assert(HelperScript.has_method("create_page_scenes"), "MainView page shell helper owns page scene creation")
		_assert(HelperScript.has_method("cache_page_shell_bundles"), "MainView page shell helper owns page shell bundle caching")
		_assert(HelperScript.has_method("capture_page_shell_bundle"), "MainView page shell helper owns page shell node capture")
		_assert(HelperScript.has_method("connect_page_shell_bundle_signals"), "MainView page shell helper owns page shell signal wiring")
		_assert(HelperScript.has_method("activate_surface_bundle"), "MainView page shell helper owns active surface assignment")
		_assert(HelperScript.has_method("render_page_scene"), "MainView page shell helper owns page scene rendering")
		_assert(HelperScript.has_method("page_scene_model"), "MainView page shell helper owns page model projection")
		_assert(_source_line_count(helper_path) <= 500, "MainView page shell helper stays within the 500-line cap")
	_assert(_source_line_count("res://src/ui/MainViewRuntime.gd") <= 1600, "MainViewRuntime delegates page shell runtime after the fourth split checkpoint")

func test_page_scene_registry_mounts_meta_and_gameplay_pages_under_separate_hosts() -> void:
	var helper = load("res://src/ui/PageSceneRegistry.gd")
	_assert(helper != null, "page scene registry helper loads for host mounting")
	if helper == null:
		return
	var meta_host: Control = helper.build_shell_host("MetaPageShellHost")
	var page_host: Control = helper.build_shell_host("PageShellHost")
	var meta_scene := Control.new()
	var battle_scene := Control.new()
	var page_scenes := {}
	helper.register_page_scene(page_scenes, "character_select", meta_scene, page_host, meta_host, ["character_select", "leviathan_select", "clear", "defeat"])
	helper.register_page_scene(page_scenes, "battle", battle_scene, page_host, meta_host, ["character_select", "leviathan_select", "clear", "defeat"])
	_assert_eq(meta_scene.get_parent(), meta_host, "meta pages mount under the dedicated meta-page host")
	_assert_eq(battle_scene.get_parent(), page_host, "gameplay pages mount under the gameplay shell host")
	_assert_eq(page_scenes.get("character_select"), meta_scene, "page scene registry stores the mounted meta page in the lookup dictionary")
	_assert_eq(page_scenes.get("battle"), battle_scene, "page scene registry stores the mounted gameplay page in the lookup dictionary")
	meta_host.free()
	page_host.free()

func test_page_scene_registry_toggles_host_visibility_for_active_page() -> void:
	var helper = load("res://src/ui/PageSceneRegistry.gd")
	_assert(helper != null, "page scene registry helper loads for visibility toggling")
	if helper == null:
		return
	var meta_ids := ["character_select", "leviathan_select", "clear", "defeat"]
	var meta_host: Control = helper.build_shell_host("MetaPageShellHost")
	var page_host: Control = helper.build_shell_host("PageShellHost")
	var meta_scene := Control.new()
	var battle_scene := Control.new()
	var page_scenes := {}
	helper.register_page_scene(page_scenes, "character_select", meta_scene, page_host, meta_host, meta_ids)
	helper.register_page_scene(page_scenes, "battle", battle_scene, page_host, meta_host, meta_ids)
	var active_meta = helper.activate_page(page_scenes, "character_select", page_host, meta_host, meta_ids)
	_assert_eq(active_meta, meta_scene, "activating a meta page returns the active scene instance")
	_assert_eq(meta_scene.visible, true, "active meta page becomes visible")
	_assert_eq(battle_scene.visible, false, "inactive gameplay page stays hidden during meta-page activation")
	_assert_eq(meta_host.visible, true, "meta host becomes visible for meta pages")
	_assert_eq(page_host.visible, false, "gameplay host hides while a meta page is active")
	var active_battle = helper.activate_page(page_scenes, "battle", page_host, meta_host, meta_ids)
	_assert_eq(active_battle, battle_scene, "activating a gameplay page returns the active scene instance")
	_assert_eq(meta_scene.visible, false, "meta page hides when gameplay page becomes active")
	_assert_eq(battle_scene.visible, true, "gameplay page becomes visible when active")
	_assert_eq(meta_host.visible, false, "meta host hides when gameplay page becomes active")
	_assert_eq(page_host.visible, true, "gameplay host becomes visible for gameplay pages")
	meta_host.free()
	page_host.free()

func _source_line_count(path: String) -> int:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return 999999
	var line_count := 0
	while not file.eof_reached():
		file.get_line()
		line_count += 1
	file.close()
	return line_count
