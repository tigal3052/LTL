extends "res://tests/support/UiReadModelTestSuite.gd"
func run_all_tests() -> Dictionary:
	failures.clear()
	test_backpack_ui_extracts_pin_and_artifact_runtime_helpers()
	test_backpack_fusion_vfx_helper_and_method_exist()
	test_backpack_fusion_vfx_profile_describes_two_silhouettes_merging()
	test_main_view_backpack_runtime_helper_exists()
	test_main_view_backpack_runtime_requests_fusion_sfx_before_vfx()
	test_shared_backpack_scene_composes_one_engine_panel()
	return _result()
func test_backpack_ui_extracts_pin_and_artifact_runtime_helpers() -> void:
	var pin_helper_path := "res://src/ui/backpack/BackpackPinOverlayRuntime.gd"
	var artifact_helper_path := "res://src/ui/backpack/BackpackArtifactRenderer.gd"
	var PinHelper = load(pin_helper_path)
	var ArtifactHelper = load(artifact_helper_path)
	_assert(PinHelper != null, "backpack pin overlay runtime helper exists")
	_assert(ArtifactHelper != null, "backpack artifact renderer helper exists")
	if PinHelper != null:
		_assert(PinHelper.has_method("visible_count"), "pin helper owns pin count mapping")
		_assert(PinHelper.has_method("layout"), "pin helper owns pin overlay layout")
		_assert(_source_line_count(pin_helper_path) <= 500, "pin helper stays within the 500-line cap")
	if ArtifactHelper != null:
		_assert(ArtifactHelper.has_method("render_items"), "artifact helper owns backpack item rendering")
		_assert(ArtifactHelper.has_method("control_rect_in_layer_space"), "artifact helper owns transformed rect math")
		_assert(_source_line_count(artifact_helper_path) <= 500, "artifact helper stays within the 500-line cap")
	_assert(_source_line_count("res://src/ui/BackpackUI.gd") <= 500, "BackpackUI delegates runtime helpers and stays within 500 lines")
func test_backpack_fusion_vfx_helper_and_method_exist() -> void:
	var helper_path := "res://src/ui/backpack/BackpackFusionVFX.gd"
	var Helper = load(helper_path)
	var backpack_ui = BackpackUIScript.new()
	_assert(Helper != null, "backpack fusion VFX helper exists")
	if Helper != null:
		_assert(Helper.has_method("play"), "backpack fusion VFX helper owns merge animation playback")
		_assert(_source_line_count(helper_path) <= 500, "backpack fusion VFX helper stays within the 500-line cap")
	_assert(backpack_ui.has_method("play_fusion_effect"), "BackpackUI exposes fusion effect playback without owning the animation details")
func test_backpack_fusion_vfx_profile_describes_two_silhouettes_merging() -> void:
	var helper_path := "res://src/ui/backpack/BackpackFusionVFX.gd"
	var Helper = load(helper_path)
	_assert(Helper != null, "backpack fusion VFX helper loads for silhouette profile contract")
	if Helper == null:
		return
	_assert(Helper.has_method("silhouette_merge_profile"), "fusion VFX exposes a testable silhouette-merge profile")
	_assert(Helper.has_method("sound_category"), "fusion VFX exposes its matching semantic sound category")
	if not Helper.has_method("silhouette_merge_profile"):
		return
	var profile: Dictionary = Helper.call("silhouette_merge_profile")
	var stages: Array = profile.get("stages", [])
	for expected in ["existing_silhouette", "incoming_silhouette", "converge", "birth_burst", "result_reveal"]:
		_assert(expected in stages, "fusion VFX profile includes %s stage" % expected)
	_assert_eq(str(profile.get("readability", "")), "two_items_become_one", "fusion VFX profile documents the A + A -> B read")
	if Helper.has_method("sound_category"):
		_assert_eq(str(Helper.call("sound_category")), "item_fusion", "fusion VFX maps to the item_fusion SFX category")
	if Helper.has_method("sound_categories"):
		_assert_eq(Helper.call("sound_categories"), ["fusion_buildup", "fusion_complete"], "fusion VFX exposes buildup and completion SFX categories")
func test_main_view_backpack_runtime_helper_exists() -> void:
	var helper_path := "res://src/ui/main_view/MainViewBackpackRuntime.gd"
	var Helper = load(helper_path)
	_assert(Helper != null, "main view backpack runtime helper exists")
	if Helper != null:
		_assert(Helper.has_method("create_shared_backpack"), "backpack helper owns the single shared backpack scene creation")
		_assert(Helper.has_method("connect_shared_backpack_signals"), "backpack helper owns one-time shared backpack signal wiring")
		_assert(Helper.has_method("setup_backpack_slots"), "backpack helper owns page backpack slot setup")
		_assert(Helper.has_method("render_backpack"), "backpack helper owns page backpack item rendering")
		_assert(Helper.has_method("schedule_backpack_reparent"), "backpack helper owns shared backpack reparent scheduling")
		_assert(Helper.has_method("commit_backpack_reparent"), "backpack helper owns shared backpack reparent commit")
		_assert(Helper.has_method("flush_pending_backpack_pin_scene"), "backpack helper owns delayed pin-scene flushing")
		_assert(_source_line_count(helper_path) <= 500, "main view backpack runtime helper stays within the 500-line cap")
	_assert(_source_line_count("res://src/ui/MainViewRuntime.gd") <= 965, "MainViewRuntime delegates shared backpack runtime responsibilities")
func test_main_view_backpack_runtime_requests_fusion_sfx_before_vfx() -> void:
	var Helper = load("res://src/ui/main_view/MainViewBackpackRuntime.gd")
	_assert(Helper != null, "main view backpack runtime loads for fusion SFX contract")
	if Helper == null:
		return
	var view := FusionRuntimeSpyView.new()
	var artifact = ArtifactScript.new({"id": "fusion_probe", "shape": [[1]], "energyType": "red", "item_type": "drill"})
	Helper.call("play_fusion_effect", view, artifact)
	_assert_eq(view.sfx_categories, ["fusion_buildup", "fusion_complete"], "fusion playback requests buildup and completion SFX cues")
	_assert_eq(view.backpack_ui.played_artifacts.size(), 1, "fusion playback still delegates to BackpackUI visual effect")
	_assert_eq(view.backpack_ui.played_artifacts[0], artifact, "fusion playback delegates the fused artifact to BackpackUI")
func test_shared_backpack_scene_composes_one_engine_panel() -> void:
	var SharedBackpackScene = load("res://src/scenes/pages/shells/SharedBackpack.tscn")
	var BackpackUIScript = load("res://src/ui/BackpackUI.gd")
	_assert(SharedBackpackScene != null, "shared backpack scene exists so page shells can host one live backpack instance")
	_assert(BackpackUIScript != null, "backpack ui script loads for shared backpack scene contract")
	if SharedBackpackScene == null:
		return
	var shared = SharedBackpackScene.instantiate()
	_assert(shared is AspectRatioContainer, "shared backpack scene root is the AspectRatioContainer moved between hosts")
	var engine_panel = shared.get_node_or_null("BackpackEnginePanel")
	_assert(engine_panel != null, "shared backpack scene owns exactly one BackpackEnginePanel child")
	if engine_panel != null and BackpackUIScript != null:
		_assert(engine_panel.get_script() == BackpackUIScript, "shared backpack engine panel uses the production BackpackUI script")
	if shared != null:
		shared.free()
func _source_line_count(path: String) -> int:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return 999999
	var text := file.get_as_text()
	file.close()
	return text.split("\n").size()
class FusionRuntimeSpyBackpack:
	extends RefCounted
	var played_artifacts: Array = []
	func play_fusion_effect(artifact) -> void:
		played_artifacts.append(artifact)
class FusionRuntimeSpyView:
	extends RefCounted
	var backpack_ui := FusionRuntimeSpyBackpack.new()
	var sfx_categories: Array = []
	func play_interaction_sfx(category: String) -> void:
		sfx_categories.append(category)
