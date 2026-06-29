extends "res://tests/support/UiReadModelTestSuite.gd"
func run_all_tests() -> Dictionary:
	failures.clear()
	test_backpack_ui_extracts_pin_and_artifact_runtime_helpers()
	test_drill_display_texture_rotates_with_artifact_rotation()
	test_drill_rotation_hot_path_uses_prepared_texture_without_cache_miss()
	test_backpack_fusion_vfx_helper_and_method_exist()
	test_backpack_fusion_vfx_profile_describes_two_silhouettes_merging()
	test_main_view_backpack_runtime_helper_exists()
	test_main_view_backpack_runtime_requests_fusion_sfx_before_vfx()
	test_shared_backpack_scene_composes_one_engine_panel()
	return _result()
func run_rotation_performance_tests() -> Dictionary:
	failures.clear()
	test_drill_rotation_hot_path_uses_prepared_texture_without_cache_miss()
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
func test_drill_display_texture_rotates_with_artifact_rotation() -> void:
	var helper_path := "res://src/ui/backpack/BackpackArtifactRenderer.gd"
	var Helper = load(helper_path)
	_assert(Helper != null, "backpack artifact renderer loads for drill image rotation contract")
	if Helper == null:
		return
	_assert(Helper.has_method("oriented_display_texture"), "artifact helper exposes oriented display texture generation")
	if not Helper.has_method("oriented_display_texture"):
		return
	var rotated := Helper.call("oriented_display_texture", _asymmetric_texture(), [[1, 1, 1], [0, 0, 1]], 90) as Texture2D
	_assert(rotated != null, "oriented display texture returns a rotated texture")
	if rotated == null:
		return
	var image: Image = rotated.get_image()
	_assert_eq(image.get_width(), 3, "90 degree drill display texture swaps source height into width")
	_assert_eq(image.get_height(), 2, "90 degree drill display texture swaps source width into height")
	_assert_color_close(image.get_pixel(2, 0), Color(1, 0, 0, 1), "90 degree drill image moves the original top-left pixel to the top-right")
	_assert_color_close(image.get_pixel(2, 1), Color(0, 1, 0, 1), "90 degree drill image keeps the original top-right pixel on the rotated right edge")
	_assert_color_close(image.get_pixel(0, 0), Color(0, 0, 1, 1), "90 degree drill image moves the original bottom-left pixel to the rotated top-left")
func test_drill_rotation_hot_path_uses_prepared_texture_without_cache_miss() -> void:
	var renderer_path := "res://src/ui/backpack/BackpackArtifactRenderer.gd"
	var placement_path := "res://src/ui/backpack/BackpackArtifactImagePlacement.gd"
	var Renderer = load(renderer_path)
	var Placement = load(placement_path)
	_assert(Renderer != null, "backpack artifact renderer loads for rotation hot-path contract")
	_assert(Placement != null, "backpack artifact image placement helper exists for transform-based rotation")
	if Renderer == null:
		return
	var owner := RotationHotPathOwner.new()
	var art = ArtifactScript.new({
		"id": "rotation_hot_path_probe",
		"shape": [[1], [1], [1]],
		"energyType": "red",
		"grade": "common",
		"item_type": "drill"
	})
	var texture := Renderer.call("item_texture_for_artifact", owner, art) as Texture2D
	_assert(texture != null, "rotation hot-path probe resolves an image-backed drill texture")
	if texture == null:
		return
	var prepared_cache_size := owner.drill_texture_cache.size()
	var image := TextureRect.new()
	var image_id := image.get_instance_id()
	var start_usec := Time.get_ticks_usec()
	for index in range(20):
		art.rotate_shape()
		var next_texture := Renderer.call("item_texture_for_artifact", owner, art) as Texture2D
		_assert(next_texture != null, "rotation hot-path texture remains available at step %d" % index)
		_assert_eq(owner.drill_texture_cache.size(), prepared_cache_size, "rotation hot path reuses prepared display texture without cache miss at step %d" % index)
		_assert_eq(image.get_instance_id(), image_id, "rotation hot path reuses the same ghost TextureRect at step %d" % index)
		if Placement != null and next_texture != null:
			var footprint := Rect2(Vector2(8, 12), _footprint_for_shape(art.shape))
			Placement.call("apply_oriented_item_image_placement", image, next_texture, footprint, int(art.rotation), false)
			var expected_size := _oriented_rect_size(footprint.size, int(art.rotation))
			_assert_close(float(image.rotation_degrees), float(art.rotation), 0.001, "rotation hot path applies the artifact rotation immediately at step %d" % index)
			_assert_close(image.size.x, expected_size.x, 0.001, "rotation hot path keeps oriented ghost width stable at step %d" % index)
			_assert_close(image.size.y, expected_size.y, 0.001, "rotation hot path keeps oriented ghost height stable at step %d" % index)
	var average_usec := float(Time.get_ticks_usec() - start_usec) / 20.0
	_assert(average_usec <= 2000.0, "rotation hot path stays under a 2ms warmed average, got %.2f usec" % average_usec)
	image.free()
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
func _asymmetric_texture() -> Texture2D:
	var image := Image.create(2, 3, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 1))
	image.set_pixel(0, 0, Color(1, 0, 0, 1))
	image.set_pixel(1, 0, Color(0, 1, 0, 1))
	image.set_pixel(0, 2, Color(0, 0, 1, 1))
	return ImageTexture.create_from_image(image)
func _footprint_for_shape(shape: Array) -> Vector2:
	var rows: int = shape.size()
	var columns: int = shape[0].size() if rows > 0 and shape[0] is Array else 1
	return Vector2(float(columns) * 24.0, float(rows) * 24.0)
func _oriented_rect_size(size: Vector2, rotation_degrees: int) -> Vector2:
	var rotation := ((rotation_degrees % 360) + 360) % 360
	return Vector2(size.y, size.x) if rotation in [90, 270] else size
func _assert_color_close(actual: Color, expected: Color, msg: String) -> void:
	if actual.is_equal_approx(expected):
		return
	failures.append("%s: expected %s, got %s" % [msg, str(expected), str(actual)])
class RotationHotPathOwner:
	extends RefCounted
	var drill_texture_cache: Dictionary = {}
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
