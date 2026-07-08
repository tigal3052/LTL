extends "res://tests/support/UiReadModelTestSuite.gd"

func run_all_tests() -> Dictionary:
	failures.clear()
	reward_reveal_cancel_done_calls = 0
	test_codex_panel_extracts_layout_and_book_visual_helpers()
	test_codex_book_safe_area_uses_ratios_instead_of_fixed_pixels()
	test_codex_panel_exposes_split_page_scroll_structure()
	test_codex_header_stays_inside_safe_spread_area()
	test_codex_entry_cards_keep_decorative_layers_click_through()
	test_codex_art_renderer_draws_resolved_item_pngs()
	test_codex_header_controls_use_compact_button_heights()
	test_codex_left_page_projects_shape_footprint_and_matrix()
	test_main_view_panels_runtime_helper_exists()
	test_main_view_codex_keeps_selected_entry_and_section_state()
	test_codex_debug_checkbox_projection_marks_all_entries_discovered()
	test_main_controller_can_force_codex_discovery_state()
	test_main_controller_maps_starter_color_to_codex_discoveries()
	return _result()

func test_codex_panel_extracts_layout_and_book_visual_helpers() -> void:
	var layout_helper_path := "res://src/ui/codex/ArtifactCodexLayoutPolicy.gd"
	var visual_helper_path := "res://src/ui/codex/ArtifactCodexBookVisualFactory.gd"
	var LayoutHelper = load(layout_helper_path)
	var VisualHelper = load(visual_helper_path)
	_assert(LayoutHelper != null, "codex layout policy helper exists")
	_assert(VisualHelper != null, "codex book visual factory helper exists")
	if LayoutHelper != null:
		_assert(LayoutHelper.has_method("book_layout_metrics_for_rect"), "codex layout helper owns safe-area metrics")
		_assert(LayoutHelper.has_method("book_transform_for_viewport"), "codex layout helper owns viewport fit math")
		_assert(_source_line_count(layout_helper_path) <= 500, "codex layout helper stays within the 500-line cap")
	if VisualHelper != null:
		_assert(VisualHelper.has_method("build_entry_card"), "codex visual helper owns entry card construction")
		_assert(VisualHelper.has_method("render_art_placeholder"), "codex visual helper owns art placeholder rendering")
		_assert(VisualHelper.has_method("render_shape_info"), "codex visual helper owns shape detail rendering")
		_assert(_source_line_count(visual_helper_path) <= 500, "codex visual helper stays within the 500-line cap")
	_assert(_source_line_count("res://src/ui/ArtifactCodexPanelUI.gd") <= 500, "ArtifactCodexPanelUI delegates layout and visual helpers and stays within 500 lines")

func test_main_view_panels_runtime_helper_exists() -> void:
	var helper_path := "res://src/ui/main_view/MainViewPanelsRuntime.gd"
	var Helper = load(helper_path)
	_assert(Helper != null, "main view panels runtime helper exists")
	if Helper != null:
		_assert(Helper.has_method("toggle_settings"), "panels helper owns settings panel toggling")
		_assert(Helper.has_method("toggle_artifact_codex"), "panels helper owns artifact codex visibility")
		_assert(Helper.has_method("render_artifact_codex"), "panels helper owns artifact codex projection")
		_assert(Helper.has_method("set_battle_pause_active"), "panels helper owns battle pause propagation")
		_assert(Helper.has_method("is_combat_pause_overlay_visible"), "panels helper owns popup pause overlay state")
		_assert(_source_line_count(helper_path) <= 500, "main view panels runtime helper stays within the 500-line cap")
	_assert(_source_line_count("res://src/ui/MainViewRuntime.gd") <= 1235, "MainViewRuntime delegates panel runtime responsibilities")

func test_codex_book_safe_area_uses_ratios_instead_of_fixed_pixels() -> void:
	var panel = ArtifactCodexPanelUIScript.new()
	var large_rect := Rect2(Vector2.ZERO, Vector2(1464, 1074))
	var small_rect := Rect2(Vector2.ZERO, Vector2(732, 537))
	var large_metrics: Dictionary = panel.book_layout_metrics_for_rect(large_rect)
	var small_metrics: Dictionary = panel.book_layout_metrics_for_rect(small_rect)
	_assert(float(large_metrics.get("outerLeft", 0.0)) > float(small_metrics.get("outerLeft", 0.0)), "safe area scales with available book width")
	_assert(absf((float(large_metrics.get("outerLeft", 0.0)) / large_rect.size.x) - (float(small_metrics.get("outerLeft", 0.0)) / small_rect.size.x)) < 0.01, "safe area keeps the same width ratio across sizes")

func test_codex_panel_exposes_split_page_scroll_structure() -> void:
	var panel = ArtifactCodexPanelUIScript.new()
	panel._ready()
	_assert(panel.has_method("book_layout_metrics_for_rect"), "codex panel exposes deterministic book layout metrics")
	_assert(panel.get_node_or_null("BookCenter/BookAspect/BookRoot/Spread/LeftPage/LeftScroll") != null, "left page uses its own scroll container")
	_assert(panel.get_node_or_null("BookCenter/BookAspect/BookRoot/Spread/RightPage/RightScroll") != null, "right page grid uses its own scroll container")

func test_codex_header_stays_inside_safe_spread_area() -> void:
	var panel = ArtifactCodexPanelUIScript.new()
	panel._ready()
	panel.size = Vector2(1440.0, 900.0)
	panel._apply_book_layout()
	var header = panel.get_node_or_null("BookCenter/BookAspect/BookRoot/Spread/HeaderBar") as Control
	var left_page = panel.get_node_or_null("BookCenter/BookAspect/BookRoot/Spread/LeftPage") as Control
	_assert(header != null, "codex book exposes a shared header row inside the spread")
	_assert(left_page != null, "codex book exposes a left page under the shared header row")
	if header != null and left_page != null:
		_assert(header.position.y >= 0.0, "codex header starts inside the safe spread area instead of on the leather border")
		_assert(left_page.position.y >= header.position.y + header.size.y, "codex page content begins below the shared header row")
	panel.free()

func test_codex_entry_cards_keep_decorative_layers_click_through() -> void:
	var panel = ArtifactCodexPanelUIScript.new()
	panel._ready()
	var entry := {
		"id": "reward_common_purple_drill_a",
		"name": "Test Entry",
		"visible": true,
		"rarity": "common",
		"energyType": "purple",
		"thumbArt": {"itemType": "drill", "energyType": "purple", "state": "discovered"}
	}
	var button := panel._build_entry_card(entry, false)
	var art_shell := button.get_node_or_null("CardRoot/ArtShell") as Control
	var placeholder_plate := button.get_node_or_null("CardRoot/ArtShell/ArtHost/PlaceholderPlate") as Control
	var rarity_plate := button.get_node_or_null("CardRoot/RarityPlate") as Control
	_assert(art_shell != null, "codex entry card exposes an art shell for click-through coverage")
	_assert(placeholder_plate != null, "codex entry card builds a placeholder plate when no real thumb art exists")
	_assert(rarity_plate != null, "codex entry card exposes a rarity plate for click-through coverage")
	if art_shell != null:
		_assert_eq(art_shell.mouse_filter, Control.MOUSE_FILTER_IGNORE, "entry art shell stays click-through so the full card remains tappable")
	if placeholder_plate != null:
		_assert_eq(placeholder_plate.mouse_filter, Control.MOUSE_FILTER_IGNORE, "placeholder plate stays click-through so artwork taps reach the card button")
	if rarity_plate != null:
		_assert_eq(rarity_plate.mouse_filter, Control.MOUSE_FILTER_IGNORE, "rarity plate stays click-through so the footer badge does not block the card button")
	button.free()
	panel.free()

func test_codex_art_renderer_draws_resolved_item_pngs() -> void:
	var host := Control.new()
	host.custom_minimum_size = Vector2(120.0, 120.0)
	var panel = ArtifactCodexPanelUIScript.new()
	panel._render_art_placeholder(host, {
		"path": "res://resources/items/drill/blue_drill_epic.png",
		"requestedPath": "res://resources/UI/codex/thumbs/drill_blue_epic.png",
		"itemType": "drill",
		"energyType": "blue",
		"state": "discovered",
		"iconKey": "drill_blue_epic"
	}, "Azure Epic Drill", false)
	var image := host.get_node_or_null("ResolvedArtTexture") as TextureRect
	_assert(image != null, "codex art renderer uses the resolved item PNG instead of a placeholder")
	if image != null:
		_assert(image.texture != null, "codex resolved item PNG loads into the texture rect")
		_assert_eq(int(image.stretch_mode), int(TextureRect.STRETCH_KEEP_ASPECT_CENTERED), "codex item art keeps centered aspect scaling")
	_assert(host.get_node_or_null("PlaceholderPlate") == null, "codex resolved item PNG skips the placeholder plate")
	panel.free()
	host.free()

func test_codex_header_controls_use_compact_button_heights() -> void:
	var panel = ArtifactCodexPanelUIScript.new()
	panel._ready()
	panel._render_sections([
		{"id": "all", "label": "?꾩껜", "count": 4, "discoveredCount": 1, "active": true},
		{"id": "drill", "label": "?쒕┫", "count": 2, "discoveredCount": 1, "active": false}
	], "all")
	var close_button := panel.close_button as Button
	var tab_button := panel.section_tabs.get_child(0) as Button
	_assert(close_button != null, "codex header exposes a close button for compact-height checks")
	_assert(tab_button != null, "codex header exposes section buttons for compact-height checks")
	if close_button != null:
		_assert(float(close_button.custom_minimum_size.y) <= 22.0, "codex close button uses a slimmer height instead of the previous chunky pill")
	if tab_button != null:
		_assert(float(tab_button.custom_minimum_size.y) <= 24.0, "codex section tabs use a compact height on the right page")
	panel.free()

func test_codex_left_page_projects_shape_footprint_and_matrix() -> void:
	var reward_table := {
		"rewards": [{
			"id": "reward_common_purple_drill_a",
			"rarity": "common",
			"payload": {
				"item_type": "drill",
				"energy_type": "purple",
				"shape": [[1, 1], [1, 0]]
			},
			"text": {
				"name": {"ko": "蹂대옃鍮??ㅽ깭???덈뱾", "en": "Violet Static Needle"},
				"description": {"ko": "?뚯뒪???ㅻ챸", "en": "Test description"}
			},
			"presentation": {"icon": "drill_purple_common", "description": "Test description"}
		}]
	}
	var model: Dictionary = ArtifactCodexReadModelScript.project(reward_table, {"artifactDiscovery": ["reward_common_purple_drill_a"]}, false, "ko")
	var left_page: Dictionary = model.get("leftPage", {})
	_assert_eq(left_page.get("shapeFootprintText", ""), TextCatalogScript.t("codex.shape_footprint", [2, 2], "ko"), "codex left page reports the backpack footprint bounds for the selected artifact")
	_assert_eq(left_page.get("shapeCellCountText", ""), TextCatalogScript.t("codex.shape_cells", [3], "ko"), "codex left page reports how many backpack cells are actually occupied")
	_assert_eq(left_page.get("shapeMatrix", []), [[1, 1], [1, 0]], "codex left page preserves the raw artifact shape matrix for visual rendering")

func test_main_view_codex_keeps_selected_entry_and_section_state() -> void:
	var view = MainViewRuntimeScript.new()
	_assert(view.has_method("_on_codex_entry_selected"), "main view exposes codex entry-selection handler")
	_assert(view.has_method("_on_codex_section_selected"), "main view exposes codex section-selection handler")
	view.free()

func test_codex_debug_checkbox_projection_marks_all_entries_discovered() -> void:
	var reward_table := {
		"rewards": [
			{
				"id": "reward_common_red_drill_a",
				"rarity": "common",
				"payload": {"item_type": "drill", "energy_type": "red", "shape": [[1]]},
				"text": {
					"name": {"en": "Red Drill"},
					"description": {"en": "Found drill"}
				},
				"presentation": {"icon": "drill_red_common", "description": "Found drill"}
			},
			{
				"id": "reward_rare_blue_drill_a",
				"rarity": "rare",
				"payload": {"item_type": "drill", "energy_type": "blue", "shape": [[1]]},
				"text": {
					"name": {"en": "Blue Drill"},
					"description": {"en": "Hidden drill"}
				},
				"presentation": {"icon": "drill_blue_rare", "description": "Hidden drill"}
			}
		]
	}
	var growth_state := {"artifactDiscovery": ["reward_common_red_drill_a"]}
	var normal_model: Dictionary = ArtifactCodexReadModelScript.project(reward_table, growth_state, false, "en")
	var debug_model: Dictionary = ArtifactCodexReadModelScript.project(reward_table, growth_state, true, "en")

	_assert_eq(int(normal_model.get("discoveredCount", 0)), 1, "normal codex only counts discovered entries")
	_assert_eq(int(normal_model.get("visibleCount", 0)), 1, "normal codex only reveals discovered entries")
	_assert_eq(int(debug_model.get("discoveredCount", 0)), 2, "debug checkbox projection activates every codex entry as discovered")
	_assert_eq(int(debug_model.get("visibleCount", 0)), 2, "debug checkbox projection reveals every codex entry")
	var debug_entries: Array = debug_model.get("entries", [])
	for entry in debug_entries:
		_assert(bool(entry.get("discovered", false)), "debug checkbox projection marks %s discovered" % str(entry.get("id", "")))

func test_main_controller_can_force_codex_discovery_state() -> void:
	_assert(MainControllerScript != null, "main controller loads for codex debug discovery helper")
	if MainControllerScript == null:
		return
	var reward_table := {
		"rewards": [
			{"id": "drill_red_common"},
			{"catalogId": "beacon_blue_rare"},
			"skip-me",
			{"id": ""}
		]
	}
	var growth_state := {"artifactDiscovery": ["drill_red_common"], "gold": 77}
	var normal_state: Dictionary = MainControllerScript.codex_growth_state_for_debug(growth_state, reward_table, false)
	var forced_state: Dictionary = MainControllerScript.codex_growth_state_for_debug(growth_state, reward_table, true)
	_assert_eq(normal_state.get("artifactDiscovery", []), ["drill_red_common"], "codex debug discovery helper keeps the original discovery list when disabled")
	_assert_eq(forced_state.get("artifactDiscovery", []), ["drill_red_common", "beacon_blue_rare"], "codex debug discovery helper appends each reward id once when enabled")
	_assert_eq(int(forced_state.get("gold", 0)), 77, "codex debug discovery helper preserves unrelated growth fields")

func test_main_controller_maps_starter_color_to_codex_discoveries() -> void:
	_assert(MainControllerScript != null, "main controller loads for starter codex discovery mapping")
	if MainControllerScript == null:
		return
	var reward_table := {
		"rewards": [
			{"id": "reward_common_red_drill_a", "tags": ["starter_safe"], "payload": {"item_type": "drill", "energy_type": "red"}},
			{"id": "reward_common_red_beacon_a", "tags": ["starter_safe"], "payload": {"item_type": "beacon", "energy_type": "red"}},
			{"id": "reward_common_blue_drill_a", "tags": ["starter_safe"], "payload": {"item_type": "drill", "energy_type": "blue"}},
			{"id": "reward_common_blue_beacon_a", "tags": ["starter_safe"], "payload": {"item_type": "beacon", "energy_type": "blue"}},
			{"id": "reward_common_purple_drill_a", "tags": ["starter_safe"], "payload": {"item_type": "drill", "energy_type": "purple"}},
			{"id": "reward_common_purple_beacon_a", "tags": ["starter_safe"], "payload": {"item_type": "beacon", "energy_type": "purple"}},
			{"id": "reward_common_green_drill_a", "tags": ["starter_safe"], "payload": {"item_type": "drill", "energy_type": "green"}},
			{"id": "reward_common_green_beacon_a", "tags": ["starter_safe"], "payload": {"item_type": "beacon", "energy_type": "green"}},
			{"id": "reward_common_red_drill_b", "tags": ["starter_safe"], "payload": {"item_type": "drill", "energy_type": "red"}}
		]
	}
	var growth_state := {"artifactDiscovery": ["already_found"]}
	var discovered_state: Dictionary = MainControllerScript.codex_growth_state_with_starter_discoveries(growth_state, reward_table, "red")
	_assert_eq(
		discovered_state.get("artifactDiscovery", []),
		[
			"already_found",
			"reward_common_red_drill_a",
			"reward_common_red_beacon_a",
			"reward_common_blue_drill_a",
			"reward_common_blue_beacon_a",
			"reward_common_purple_drill_a",
			"reward_common_purple_beacon_a",
			"reward_common_green_drill_a",
			"reward_common_green_beacon_a"
		],
		"starter codex discovery sync reveals the four basic drill and beacon color pairs exactly once"
	)

func _source_line_count(path: String) -> int:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return 999999
	var text := file.get_as_text()
	file.close()
	return text.split("\n").size()

