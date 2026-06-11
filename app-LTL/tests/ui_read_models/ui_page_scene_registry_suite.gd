extends "res://tests/support/UiReadModelTestSuite.gd"

func run_all_tests() -> Dictionary:
	failures.clear()
	test_page_scene_registry_helper_exists()
	test_page_scene_registry_mounts_meta_and_gameplay_pages_under_separate_hosts()
	test_page_scene_registry_toggles_host_visibility_for_active_page()
	return _result()

func test_page_scene_registry_helper_exists() -> void:
	var helper = load("res://src/ui/PageSceneRegistry.gd")
	_assert(helper != null, "page scene registry helper exists for MainViewRuntime extraction")

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
