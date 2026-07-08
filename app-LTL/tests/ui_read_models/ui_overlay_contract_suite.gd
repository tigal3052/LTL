extends "res://tests/support/UiReadModelTestSuite.gd"

func run_all_tests() -> Dictionary:
	failures.clear()
	reward_reveal_cancel_done_calls = 0
	test_popup_overlay_host_helper_exists()
	test_main_view_exposes_fullscreen_reward_reveal_api()
	test_popup_overlay_host_promotes_controls_to_front()
	test_popup_overlay_host_ignores_hidden_overlays()
	test_popup_overlay_host_projects_pause_visibility()
	test_main_view_promotes_popup_overlays_above_combat_layers()
	test_main_view_moves_reward_reveal_overlay_to_front_with_control_api()
	return _result()

func test_popup_overlay_host_helper_exists() -> void:
	var helper = load("res://src/ui/PopupOverlayHost.gd")
	_assert(helper != null, "popup overlay host helper exists for MainViewRuntime extraction")

func test_main_view_exposes_fullscreen_reward_reveal_api() -> void:
	var MainViewRuntimeScript = load("res://src/ui/MainViewRuntime.gd")
	_assert(MainViewRuntimeScript != null, "main view runtime loads for fullscreen reward reveal api")
	if MainViewRuntimeScript == null:
		return
	var runtime = MainViewRuntimeScript.new()
	_assert(runtime != null, "main view runtime instantiates for fullscreen reward reveal api")
	if runtime == null:
		return
	_assert(runtime.has_method("start_reward_reveal_vfx"), "main view runtime exposes a fullscreen reward reveal start api")
	_assert(runtime.has_method("skip_reward_reveal_to_silhouettes"), "main view runtime keeps the reveal skip api available")
	runtime.free()

func test_popup_overlay_host_promotes_controls_to_front() -> void:
	var helper = load("res://src/ui/PopupOverlayHost.gd")
	_assert(helper != null, "popup overlay host helper loads for front-order behavior")
	if helper == null:
		return
	var parent := Control.new()
	var overlay := Control.new()
	var combat_popup := Control.new()
	combat_popup.z_index = 200
	parent.add_child(overlay)
	parent.add_child(combat_popup)
	helper.bring_to_front(overlay, 500)
	_assert_eq(parent.get_child(parent.get_child_count() - 1), overlay, "popup overlay helper moves the overlay to the last sibling position")
	_assert_eq(int(overlay.z_index), 500, "popup overlay helper assigns the requested z-index")
	parent.free()

func test_popup_overlay_host_ignores_hidden_overlays() -> void:
	var helper = load("res://src/ui/PopupOverlayHost.gd")
	_assert(helper != null, "popup overlay host helper loads for hidden overlay behavior")
	if helper == null:
		return
	var parent := Control.new()
	var overlay := Control.new()
	var blocker := Control.new()
	overlay.visible = false
	parent.add_child(overlay)
	parent.add_child(blocker)
	helper.promote_when_visible(overlay, 500)
	_assert_eq(parent.get_child(0), overlay, "hidden popup overlay does not reorder siblings")
	parent.free()

func test_popup_overlay_host_projects_pause_visibility() -> void:
	var helper = load("res://src/ui/PopupOverlayHost.gd")
	_assert(helper != null, "popup overlay host helper loads for pause-visibility projection")
	if helper == null:
		return
	_assert_eq(bool(helper.pause_overlay_visible(false, false, false)), false, "pause overlay helper stays false when every popup is hidden")
	_assert_eq(bool(helper.pause_overlay_visible(true, false, false)), true, "pause overlay helper becomes true when settings is visible")
	_assert_eq(bool(helper.pause_overlay_visible(false, true, false)), true, "pause overlay helper becomes true when codex is visible")
	_assert_eq(bool(helper.pause_overlay_visible(false, false, true)), true, "pause overlay helper becomes true when repair overlay is visible")

func test_main_view_promotes_popup_overlays_above_combat_layers() -> void:
	var MainViewRuntimeScript = load("res://src/ui/MainViewRuntime.gd")
	_assert(MainViewRuntimeScript != null, "main view runtime loads for popup overlay top-layer contract")
	if MainViewRuntimeScript == null:
		return
	var runtime = MainViewRuntimeScript.new()
	_assert(runtime != null, "main view runtime instantiates for popup overlay top-layer contract")
	if runtime == null:
		return
	_assert(runtime.has_method("_bring_popup_overlay_to_front"), "main view runtime exposes a popup overlay front-order helper")
	if not runtime.has_method("_bring_popup_overlay_to_front"):
		runtime.free()
		return
	var parent := Control.new()
	var overlay := Control.new()
	var combat_popup := Control.new()
	combat_popup.z_index = 200
	parent.add_child(overlay)
	parent.add_child(combat_popup)
	runtime.call("_bring_popup_overlay_to_front", overlay)
	_assert_eq(parent.get_child(parent.get_child_count() - 1), overlay, "popup overlay moves to the front by reordering control siblings")
	_assert(int(overlay.z_index) > int(combat_popup.z_index), "popup overlay claims a higher z-index than combat HUD and damage popups")
	parent.free()
	runtime.free()

func test_main_view_moves_reward_reveal_overlay_to_front_with_control_api() -> void:
	var MainViewRuntimeScript = load("res://src/ui/MainViewRuntime.gd")
	_assert(MainViewRuntimeScript != null, "main view runtime loads for overlay front-order contract")
	if MainViewRuntimeScript == null:
		return
	var runtime = MainViewRuntimeScript.new()
	_assert(runtime != null, "main view runtime instantiates for overlay front-order contract")
	if runtime == null:
		return
	_assert(runtime.has_method("_bring_reward_reveal_overlay_to_front"), "main view runtime exposes a helper that brings the reward reveal overlay to the front")
	if not runtime.has_method("_bring_reward_reveal_overlay_to_front"):
		runtime.free()
		return
	var parent := Control.new()
	var overlay := Control.new()
	var blocker := Control.new()
	blocker.z_index = 200
	parent.add_child(overlay)
	parent.add_child(blocker)
	runtime.reward_reveal_overlay = overlay
	runtime.call("_bring_reward_reveal_overlay_to_front")
	_assert_eq(parent.get_child(parent.get_child_count() - 1), overlay, "reward reveal overlay moves to the front by reordering control siblings")
	_assert(int(overlay.z_index) > int(blocker.z_index), "reward reveal overlay claims a higher z-index than combat HUD and damage popups")
	parent.free()
	runtime.free()

