extends "res://tests/support/UiReadModelTestSuite.gd"

func run_all_tests() -> Dictionary:
	failures.clear()
	reward_reveal_cancel_done_calls = 0
	test_backpack_pin_contract_maps_count_and_corner_order()
	test_backpack_pin_nodes_stay_in_backpack_local_canvas()
	test_backpack_pin_nodes_live_under_overlay_canvas()
	test_backpack_pin_nodes_use_trimmed_atlas_regions()
	test_backpack_pin_corner_anchor_helper_uses_requested_side_centers()
	test_backpack_pin_display_size_stays_small_relative_to_one_slot()
	test_backpack_pin_visibility_removes_in_requested_order()
	test_backpack_pin_vfx_contract_is_localized_pullout()
	return _result()

func test_backpack_pin_contract_maps_count_and_corner_order() -> void:
	var backpack_ui = BackpackUIScript.new()
	_assert(backpack_ui.has_method("pin_visible_count"), "backpack ui exposes deterministic pin-count mapping for the combat HUD")
	_assert(backpack_ui.has_method("pin_corner_specs"), "backpack ui exposes deterministic pin corner ordering for the overlay art")
	_assert(backpack_ui.has_method("_setup_pin_overlays"), "backpack ui keeps the pin overlay setup helper so ready-time initialization cannot regress")
	_assert(backpack_ui.has_method("_layout_pin_overlays"), "backpack ui keeps the pin overlay layout helper so corner pins can be repositioned after resize")
	if not backpack_ui.has_method("pin_visible_count") or not backpack_ui.has_method("pin_corner_specs") or not backpack_ui.has_method("_setup_pin_overlays") or not backpack_ui.has_method("_layout_pin_overlays"):
		return
	_assert_eq(int(backpack_ui.call("pin_visible_count", true, 100.0)), 4, "active pin hazard with full progress keeps all four backpack pins visible")
	_assert_eq(int(backpack_ui.call("pin_visible_count", true, 74.9)), 2, "pin count drops one by one as progress crosses the quarter thresholds")
	backpack_ui.call("update_pin_overlays", {"phase": "combat", "hud": {"pin": {"active": false, "progress": 100.0}}})
	_assert_eq(int(backpack_ui.visible_pin_count_value), 4, "combat backpack pins stay visible from progress even when the transient mismatch pin flag is currently false")
	backpack_ui.call("update_pin_overlays", {"phase": "reward_loot", "hud": {"pin": {"active": false, "progress": 100.0}}})
	_assert_eq(int(backpack_ui.visible_pin_count_value), 0, "non-combat phases hide the backpack corner pins entirely")
	var corner_specs: Array = backpack_ui.call("pin_corner_specs")
	_assert_eq(corner_specs.size(), 4, "backpack pin overlay defines exactly four corner specs")
	_assert_eq(corner_specs[0], {"name": "Pin1", "column": 0, "row": 0, "horizontal": "left", "vertical": "center"}, "pin_1 anchors to the left side of backpack_1")
	_assert_eq(corner_specs[1], {"name": "Pin2", "column": 9, "row": 0, "horizontal": "right", "vertical": "center"}, "pin_2 anchors to the right side of backpack_3")
	_assert_eq(corner_specs[2], {"name": "Pin3", "column": 9, "row": 9, "horizontal": "right", "vertical": "center"}, "pin_3 anchors to the right side of backpack_9")
	_assert_eq(corner_specs[3], {"name": "Pin4", "column": 0, "row": 9, "horizontal": "left", "vertical": "center"}, "pin_4 anchors to the left side of backpack_7")

func test_backpack_pin_nodes_stay_in_backpack_local_canvas() -> void:
	var backpack_ui = BackpackUIScript.new()
	_assert(backpack_ui.has_method("_setup_pin_overlays"), "backpack ui keeps the pin overlay builder for local-canvas layout checks")
	if not backpack_ui.has_method("_setup_pin_overlays"):
		return
	backpack_ui.call("_setup_pin_overlays")
	_assert_eq(backpack_ui.pin_nodes.size(), 4, "backpack builds exactly four pin nodes for combat layout")
	if backpack_ui.pin_nodes.is_empty():
		return
	_assert_eq(bool((backpack_ui.pin_nodes[0] as TextureRect).top_level), false, "backpack pins stay in the backpack local canvas so corner placement cannot drift across other HUD panels")

func test_backpack_pin_nodes_live_under_overlay_canvas() -> void:
	var backpack_ui = BackpackUIScript.new()
	_assert(backpack_ui.has_method("_setup_pin_overlays"), "backpack ui keeps the pin overlay builder for overlay-canvas parenting checks")
	if not backpack_ui.has_method("_setup_pin_overlays"):
		return
	backpack_ui.call("_setup_pin_overlays")
	_assert_eq(backpack_ui.pin_nodes.size(), 4, "backpack builds exactly four pin nodes for overlay-canvas parenting checks")
	if backpack_ui.pin_nodes.is_empty():
		return
	var parent := (backpack_ui.pin_nodes[0] as TextureRect).get_parent()
	_assert(parent != backpack_ui, "backpack pins no longer live directly under the PanelContainer, which would force them to full-rect container sizing")
	_assert(parent is Control, "backpack pins mount under a non-container control canvas so explicit size and position survive runtime layout")

func test_backpack_pin_nodes_use_trimmed_atlas_regions() -> void:
	var backpack_ui = BackpackUIScript.new()
	_assert(backpack_ui.has_method("_setup_pin_overlays"), "backpack ui keeps the pin overlay builder for trimmed-region checks")
	if not backpack_ui.has_method("_setup_pin_overlays"):
		return
	backpack_ui.call("_setup_pin_overlays")
	var expected_regions := [
		Rect2(211, 237, 863, 655),
		Rect2(328, 237, 863, 655),
		Rect2(328, 230, 863, 655),
		Rect2(211, 230, 863, 655)
	]
	for index in range(mini(backpack_ui.pin_nodes.size(), expected_regions.size())):
		var pin := backpack_ui.pin_nodes[index] as TextureRect
		_assert(pin != null, "backpack pin node exists for trimmed atlas-region validation")
		if pin == null:
			continue
		var atlas := pin.texture as AtlasTexture
		_assert(atlas != null, "backpack pin_%d uses a trimmed atlas texture so transparent padding cannot distort layout" % [index + 1])
		if atlas != null:
			_assert_eq(atlas.region, expected_regions[index], "backpack pin_%d trims to the measured visible bounds before size and anchor math run" % [index + 1])

func test_backpack_pin_corner_anchor_helper_uses_requested_side_centers() -> void:
	var backpack_ui = BackpackUIScript.new()
	_assert(backpack_ui.has_method("pin_corner_anchor_for_rect"), "backpack ui exposes a rect-based corner anchor helper for pin placement")
	if not backpack_ui.has_method("pin_corner_anchor_for_rect") or not backpack_ui.has_method("pin_corner_specs"):
		return
	var grid_rect := Rect2(Vector2(120.0, 80.0), Vector2(32.0, 32.0))
	var specs: Array = backpack_ui.call("pin_corner_specs")
	_assert_eq(backpack_ui.call("pin_corner_anchor_for_rect", grid_rect, specs[0]), Vector2(120.0, 96.0), "pin_1 anchor snaps to the left-center of backpack_1")
	_assert_eq(backpack_ui.call("pin_corner_anchor_for_rect", grid_rect, specs[1]), Vector2(152.0, 96.0), "pin_2 anchor snaps to the right-center of backpack_3")
	_assert_eq(backpack_ui.call("pin_corner_anchor_for_rect", grid_rect, specs[2]), Vector2(152.0, 96.0), "pin_3 anchor snaps to the right-center of backpack_9")
	_assert_eq(backpack_ui.call("pin_corner_anchor_for_rect", grid_rect, specs[3]), Vector2(120.0, 96.0), "pin_4 anchor snaps to the left-center of backpack_7")

func test_backpack_pin_display_size_stays_small_relative_to_one_slot() -> void:
	var backpack_ui = BackpackUIScript.new()
	_assert(backpack_ui.has_method("pin_display_size_for_slot_extent"), "backpack exposes a concrete display-size helper for the smaller pin art")
	if not backpack_ui.has_method("pin_display_size_for_slot_extent"):
		return
	var pin_size: Vector2 = backpack_ui.call("pin_display_size_for_slot_extent", 53.0)
	_assert_close(pin_size.x, 69.830534, 0.001, "trimmed pin width now follows the visible silhouette instead of the padded PNG canvas")
	_assert_close(pin_size.y, 53.0, 0.001, "trimmed pin height now fits roughly one live grid slot")

func test_backpack_pin_visibility_removes_in_requested_order() -> void:
	var backpack_ui = BackpackUIScript.new()
	_assert(backpack_ui.has_method("pin_visible_indices"), "backpack exposes deterministic visible pin index mapping")
	_assert(backpack_ui.has_method("pin_is_visible"), "backpack exposes per-index pin visibility helper")
	if not backpack_ui.has_method("pin_visible_indices") or not backpack_ui.has_method("pin_is_visible"):
		return
	_assert_eq(backpack_ui.call("pin_visible_indices", 4), [0, 1, 2, 3], "all pins visible at full count")
	_assert_eq(backpack_ui.call("pin_visible_indices", 3), [1, 2, 3], "pin_1 is removed first")
	_assert_eq(backpack_ui.call("pin_visible_indices", 2), [2, 3], "pin_2 is removed second")
	_assert_eq(backpack_ui.call("pin_visible_indices", 1), [3], "pin_3 is removed third")
	_assert_eq(backpack_ui.call("pin_visible_indices", 0), [], "pin_4 is removed last")
	_assert_eq(bool(backpack_ui.call("pin_is_visible", 0, 3)), false, "pin_1 hidden when three pins remain")
	_assert_eq(bool(backpack_ui.call("pin_is_visible", 3, 1)), true, "pin_4 remains when one pin remains")

func test_backpack_pin_vfx_contract_is_localized_pullout() -> void:
	var backpack_ui = BackpackUIScript.new()
	_assert(backpack_ui.has_method("pin_pull_direction_for_index"), "backpack exposes pull direction helper for pin removal VFX")
	_assert(backpack_ui.has_method("pin_removal_vfx_profile_for_index"), "backpack exposes deterministic removal VFX profile")
	if not backpack_ui.has_method("pin_pull_direction_for_index") or not backpack_ui.has_method("pin_removal_vfx_profile_for_index"):
		return
	_assert_eq(backpack_ui.call("pin_pull_direction_for_index", 0), Vector2(-1, -1).normalized(), "pin_1 pulls out toward the top-left")
	_assert_eq(backpack_ui.call("pin_pull_direction_for_index", 1), Vector2(1, -1).normalized(), "pin_2 pulls out toward the top-right")
	_assert_eq(backpack_ui.call("pin_pull_direction_for_index", 2), Vector2(1, 1).normalized(), "pin_3 pulls out toward the bottom-right")
	_assert_eq(backpack_ui.call("pin_pull_direction_for_index", 3), Vector2(-1, 1).normalized(), "pin_4 pulls out toward the bottom-left")
	var profile: Dictionary = backpack_ui.call("pin_removal_vfx_profile_for_index", 0, 80.0)
	_assert_close(float(profile.get("anticipationDuration", 0.0)), 0.07, 0.001, "pin removal anticipation stays short but readable")
	_assert_close(float(profile.get("pullDuration", 0.0)), 0.20, 0.001, "pin removal pull is visible enough to read")
	_assert_close(float(profile.get("pullDistance", 0.0)), 36.0, 0.001, "pin removal pull distance scales visibly from displayed pin size")
	_assert_eq(float(profile.get("fadeToAlpha", 1.0)), 0.0, "removed pin fades out")
	_assert_eq(bool(profile.get("localOnly", false)), true, "pin removal VFX is localized rather than screen shake")
