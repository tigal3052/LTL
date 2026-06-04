# 계약:
# - 책임: UI read model이 raw domain data를 표시 가능한 text contract로 변환하는지 검증한다.
# - 입력: reward dictionary, Artifact object, node candidate dictionaries.
# - 출력: tooltip lines와 bbcode text.
# - 금지: Control node 생성, SceneTree 접근, gameplay 상태 변경.
#
# 실행: define the TestUiReadModels class.
extends RefCounted

const ArtifactScript = preload("res://src/models/Artifact.gd")
const InventoryScript = preload("res://src/models/InventoryModel.gd")
const TooltipReadModelScript = preload("res://src/ui/read_models/TooltipReadModel.gd")
const TextCatalogScript = preload("res://src/ui/TextCatalog.gd")
const NodeSelectReadModelScript = preload("res://src/ui/read_models/NodeSelectReadModel.gd")
const RewardReadModelScript = preload("res://src/ui/read_models/RewardReadModel.gd")
const ArtifactCodexReadModelScript = preload("res://src/ui/read_models/ArtifactCodexReadModel.gd")
const PhaseLayoutPresenterScript = preload("res://src/ui/presenters/PhaseLayoutPresenter.gd")
const RewardCeremonyPolicyScript = preload("res://src/ui/presenters/RewardCeremonyPolicy.gd")
const CombatFeedbackPresenterScript = preload("res://src/ui/presenters/CombatFeedbackPresenter.gd")
const ArtifactCodexPanelUIScript = preload("res://src/ui/ArtifactCodexPanelUI.gd")
const ArtifactTooltipUIScript = preload("res://src/ui/ArtifactTooltipUI.gd")
const BackpackGridFactoryScript = preload("res://src/ui/presenters/BackpackGridFactory.gd")
const CombatSceneModelScript = preload("res://src/ui/CombatSceneModel.gd")
const InteractionCuePresenterScript = preload("res://src/ui/presenters/InteractionCuePresenter.gd")
const BackpackUIScript = preload("res://src/ui/BackpackUI.gd")
const InteractionFXScript = preload("res://src/ui/InteractionFX.gd")
const BattlefieldVFXScript = preload("res://src/ui/BattlefieldVFX.gd")
const BattlefieldUIScript = preload("res://src/ui/BattlefieldUI.gd")
const CellViewScript = preload("res://src/ui/CellView.gd")
const HazardModelScript = preload("res://src/models/HazardModel.gd")
const StatusPanelUIScript = preload("res://src/ui/StatusPanelUI.gd")
const VFXManagerScript = preload("res://src/ui/VFXManager.gd")
const MainControllerRuntimeScript = preload("res://src/MainControllerRuntime.gd")
const MainViewRuntimeScript = preload("res://src/ui/MainViewRuntime.gd")
const NodeMapSceneScript = preload("res://src/scenes/node_map/NodeMapScene.gd")

var failures: Array[String] = []
var reward_reveal_cancel_done_calls := 0

# 실행: run all UI read model tests.
func run_all_tests() -> Dictionary:
	failures.clear()
	test_tooltip_projects_reward_dictionary()
	test_tooltip_projects_relic_reward_dictionary()
	test_tooltip_projects_effect_schema_summary()
	test_tooltip_projects_artifact_object()
	test_text_catalog_switches_korean_and_english()
	test_text_catalog_korean_names_are_readable()
	test_reward_drill_tooltip_compares_same_color_equipped_drill()
	test_reward_beacon_tooltip_does_not_show_equipped_drill_comparison()
	test_reward_relic_tooltip_does_not_show_equipped_drill_comparison()
	test_reward_read_model_uses_localized_reward_text()
	test_codex_book_safe_area_uses_ratios_instead_of_fixed_pixels()
	test_codex_panel_exposes_split_page_scroll_structure()
	test_codex_header_stays_inside_safe_spread_area()
	test_codex_entry_cards_keep_decorative_layers_click_through()
	test_codex_header_controls_use_compact_button_heights()
	test_codex_left_page_projects_shape_footprint_and_matrix()
	test_main_view_codex_keeps_selected_entry_and_section_state()
	test_main_controller_can_force_codex_discovery_state()
	test_main_controller_maps_starter_color_to_codex_discoveries()
	test_node_select_projects_candidates()
	test_node_select_omits_baseline_reward_noise()
	test_reward_tray_projects_lines_and_discard_zone()
	test_phase_layout_projects_visibility_and_timer()
	test_reward_ceremony_keeps_final_combat_snapshot_live()
	test_node_select_layout_is_full_page()
	test_node_select_layout_uses_map_backpack_split()
	test_node_select_layout_reuses_palette_when_start_panel_is_hidden()
	test_node_select_backpack_width_tracks_left_stack_height()
	test_node_select_backpack_width_delegates_to_shared_layout_policy()
	test_top_content_backpack_uses_fixed_width_policy()
	test_top_content_backpack_width_tracks_full_row_height()
	test_top_content_backpack_width_ignores_available_space_clamp()
	test_top_content_backpack_height_uses_single_row_source()
	test_backpack_pin_contract_maps_count_and_corner_order()
	test_top_content_backpack_width_uses_slot_scaled_pin_overhang()
	test_backpack_pin_layout_policy_unifies_backpack_and_main_width_math()
	test_backpack_grid_keeps_expand_fill_layout_with_shell_gutter()
	test_backpack_shell_gutter_uses_side_margin_overhang_only_in_combat()
	test_main_scene_backpack_grid_uses_shell_gutter_layout()
	test_main_scene_shared_layout_text_nodes_do_not_fit_content()
	test_main_scene_reward_tray_row_expands_to_keep_discard_zone_inside_panel()
	test_main_ui_load_chain_survives_reward_reveal_preloads()
	test_backpack_pin_nodes_stay_in_backpack_local_canvas()
	test_backpack_pin_nodes_live_under_overlay_canvas()
	test_backpack_pin_nodes_use_trimmed_atlas_regions()
	test_backpack_pin_corner_anchor_helper_uses_requested_side_centers()
	test_backpack_pin_display_size_stays_small_relative_to_one_slot()
	test_backpack_pin_visibility_removes_in_requested_order()
	test_backpack_pin_vfx_contract_is_localized_pullout()
	test_phase_layout_hides_floating_battlefield_timer()
	test_phase_layout_gives_backpack_more_space_in_combat_and_reward()
	test_phase_layout_hides_backpack_cooldown_visuals_outside_combat()
	test_battlefield_layout_uses_top_left_header_miner_overlay()
	test_cell_view_uses_tile_alpha_for_weakness_readability()
	test_cell_view_uses_active_queue_color_for_tile_alpha_readability()
	test_combat_scene_projects_all_energy_weakness_as_highlighted_tiles()
	test_cell_view_projects_hazard_alpha_by_state()
	test_cell_view_removes_colored_hazard_frame()
	test_cell_view_maps_green_family_to_green_hazard_texture()
	test_cell_view_expands_green_hazard_overlay_and_softens_fill()
	test_hazard_model_uses_active_severity_for_live_obstacles()
	test_hazard_model_stays_stable_without_live_obstacles()
	test_battlefield_maps_columns_to_miner_pose_assets()
	test_battlefield_miner_pose_assets_use_trimmed_regions()
	test_main_scene_uses_header_miner_and_status_timer_footer()
	test_main_scene_status_panel_uses_two_row_energy_queue()
	test_battlefield_lane_overlay_keeps_shell_visible_through_transparent_tiles()
	test_combat_feedback_projects_screenshake()
	test_tooltip_position_clamps_to_viewport()
	test_backpack_artifact_edges_omit_internal_borders()
	test_backpack_drag_ghost_matches_grid_visual_scale_and_fill()
	test_backpack_cooldown_charge_ratio_changes_with_current_cooldown()
	test_backpack_cooldown_charge_ratio_smoothly_interpolates()
	test_backpack_cooldown_mask_ratio_decreases_with_frame_time()
	test_backpack_cooldown_display_does_not_backtrack_on_snapshot_refresh()
	test_main_controller_uses_terrain_shift_interval()
	test_main_controller_syncs_combat_ticks_to_shift_interval()
	test_main_controller_prefers_clicked_cell_color_for_targeting()
	test_main_controller_starter_loadout_positions_are_adjacent()
	test_phase_layout_restores_combat_active_phase_height()
	test_text_catalog_strips_item_implementation_tags()
	test_combat_scene_projects_global_debuff_and_queue_match()
	test_main_scene_exposes_purple_status_row()
	test_main_controller_projects_split_damage_popups_using_tile_color()
	test_vfx_manager_popup_palette_tracks_tile_color()
	test_interaction_cues_distinguish_hover_press_drag_and_disabled()
	test_backpack_drop_feedback_uses_real_placement_rules()
	test_backpack_hover_fx_stays_off()
	test_backpack_drag_feedback_preserves_slot_visuals_while_dragging()
	test_backpack_drag_feedback_restores_slot_modulate_after_reward_drop()
	test_backpack_drag_feedback_restores_slot_alpha_after_reward_drop()
	test_interaction_fx_preserves_container_layout_children()
	test_interaction_fx_skips_shader_on_panel_slots()
	test_hold_fire_stops_when_overload_repair_starts()
	test_combat_clicks_block_while_repair_or_aim_lock_is_active()
	test_main_view_exposes_fullscreen_reward_reveal_api()
	test_main_view_promotes_popup_overlays_above_combat_layers()
	test_main_view_moves_reward_reveal_overlay_to_front_with_control_api()
	test_reward_reveal_overlay_uses_cinematic_hero_contract_and_keeps_legacy_backup()
	return {"ok": failures.is_empty(), "errors": failures}

func run_reward_ceremony_tests() -> Dictionary:
	failures.clear()
	test_reward_reveal_presentation_requires_confirm_and_sorted_reveal_queue()
	test_reward_reveal_quantity_tease_uses_three_bands()
	test_reward_reveal_count_tease_hides_exact_count_and_uses_band_preview()
	test_reward_reveal_mined_lid_pops_from_terrain_before_count_burst()
	test_reward_reveal_cards_conceal_identity_then_use_fixed_rarity_bursts()
	test_reward_reveal_result_stage_uses_clean_layout_and_distinct_rarity_profiles()
	test_reward_reveal_safe_area_models_stay_inside_canvas()
	test_reward_reveal_overlay_safe_layout_caps_effect_radii()
	test_reward_reveal_quantity_slots_center_even_pairs()
	test_reward_ceremony_policy_is_single_source_for_step_gates()
	test_reward_reveal_cancel_suppresses_done_callback()
	test_reward_ceremony_step_contract_and_node_select_color_gate()
	return {"ok": failures.is_empty(), "errors": failures}

# 실행: verify reward dictionary tooltip data.
func test_tooltip_projects_reward_dictionary() -> void:
	TextCatalogScript.set_locale("en")
	var reward = {
		"kind": "Azure Beacon",
		"rarity": "rare",
		"payload": {"item_type": "beacon", "energy_type": "blue", "beacon_cooldown_mod": -12, "beacon_damage_mod": 0.4},
		"presentation": {"description": "A test beacon"}
	}
	var model = TooltipReadModelScript.project(reward)
	_assert_eq(model["name"], "Azure Beacon", "tooltip reward name")
	_assert_eq(model["itemType"], "beacon", "tooltip reward item type")
	_assert_eq(model["energyType"], "blue", "tooltip reward energy")
	_assert(str(model["bbcode"]).contains("Azure Beacon"), "tooltip bbcode includes name")
	_assert(str(model["bbcode"]).contains("Beacon pulse effect"), "tooltip bbcode includes beacon effects")
	TextCatalogScript.set_locale("ko")

# 실행: verify relic reward dictionaries project without color text and expose link metadata.
func test_tooltip_projects_relic_reward_dictionary() -> void:
	TextCatalogScript.set_locale("en")
	var reward = {
		"kind": "Breach Seal",
		"rarity": "common",
		"text": {
			"name": {"ko": "균열 봉인장", "en": "Breach Seal"},
			"description": {
				"ko": "대각선으로 연결된 드릴의 첫 장애물 타격에 진행도 +1을 더합니다.",
				"en": "Adds +1 obstacle progress to the first hit from its diagonally linked drill each combat."
			}
		},
		"payload": {
			"item_type": "relic",
			"energy_type": "",
			"effect_schema": {
				"version": 1,
				"link_mode": "diagonal_1",
				"trigger": "on_obstacle_hit",
				"type": "obstacle_progress_bonus",
				"summary": "Linked drill gains +1 progress on its first obstacle hit each combat.",
				"summary_i18n": {
					"ko": "연결된 드릴의 첫 장애물 타격은 전투당 진행도 +1을 얻습니다.",
					"en": "Linked drill gains +1 progress on its first obstacle hit each combat."
				}
			}
		},
		"presentation": {"description": "Fallback relic description"}
	}
	var model = TooltipReadModelScript.project(reward)
	var text := str(model["bbcode"])
	_assert_eq(model["itemType"], "relic", "tooltip relic reward item type")
	_assert_eq(model["energyType"], "", "tooltip relic reward stays colorless")
	_assert(text.contains("Breach Seal"), "relic tooltip includes localized name")
	_assert(text.contains("Common - Relic"), "relic tooltip includes rarity and relic type")
	_assert(text.contains("Relic Link: Diagonal Link"), "relic tooltip includes user-facing link label")
	_assert(text.contains("Linked drill gains +1 progress"), "relic tooltip includes localized effect summary")
	_assert(not text.contains("Energy:"), "relic tooltip hides energy label")
	_assert(not text.contains("Cooldown:"), "relic tooltip hides cooldown label")
	TextCatalogScript.set_locale("ko")

# 실행: verify Artifact object tooltip data.
func test_tooltip_projects_effect_schema_summary() -> void:
	TextCatalogScript.set_locale("en")
	var reward = {
		"kind": "Overheat Beacon",
		"rarity": "epic",
		"payload": {
			"item_type": "beacon",
			"energy_type": "red",
			"beacon_cooldown_mod": 2,
			"beacon_damage_mod": 0.9,
			"effect_schema": {"version": 1, "trigger": "on_pulse", "type": "overheat_bank", "summary": "Delays the drill, then doubles the next hit."}
		},
		"presentation": {"description": "Red risk beacon"}
	}
	var model = TooltipReadModelScript.project(reward)
	_assert(str(model["bbcode"]).contains("Delays the drill, then doubles the next hit."), "tooltip bbcode includes effect schema summary")
	TextCatalogScript.set_locale("ko")

func test_tooltip_projects_artifact_object() -> void:
	var artifact = ArtifactScript.new({"id": "ruby", "name": "Ruby Drill", "shape": [[1]], "energyType": "red", "item_type": "drill", "baseCooldownTicks": 80, "damage": 1.5, "grade": "basic"})
	var model = TooltipReadModelScript.project(artifact)
	_assert_eq(model["name"], "루비 드릴", "tooltip artifact name")
	_assert_eq(model["itemType"], "drill", "tooltip artifact item type")
	_assert(str(model["bbcode"]).contains("쿨타임: 80 T"), "tooltip bbcode includes cooldown")
	_assert(str(model["bbcode"]).contains("피해"), "tooltip bbcode includes damage")

# 실행: verify UI strings come from a locale-aware text catalog.
func test_text_catalog_switches_korean_and_english() -> void:
	TextCatalogScript.set_locale("ko")
	_assert_eq(TextCatalogScript.t("action.start"), "전투 시작", "korean text catalog start label")
	_assert_eq(TextCatalogScript.t("item.relic"), "유물", "korean text catalog relic label")
	TextCatalogScript.set_locale("en")
	_assert_eq(TextCatalogScript.t("action.start"), "Start Combat", "english text catalog start label")
	_assert_eq(TextCatalogScript.t("item.relic"), "Relic", "english text catalog relic label")
	TextCatalogScript.set_locale("ko")

# 실행: verify Korean display-name mappings are readable.
func test_text_catalog_korean_names_are_readable() -> void:
	TextCatalogScript.set_locale("ko")
	_assert_eq(TextCatalogScript.display_name("Safe Scar"), "안전한 균열", "safe scar korean display name")
	_assert_eq(TextCatalogScript.display_name("Ruby Drill"), "루비 드릴", "ruby drill korean display name")

# 실행: verify reward drill tooltips compare only the equipped drill with the same energy color.
func test_reward_drill_tooltip_compares_same_color_equipped_drill() -> void:
	var red_drill = ArtifactScript.new({"id": "red_now", "name": "현재 루비 드릴", "shape": [[1]], "energyType": "red", "item_type": "drill", "baseCooldownTicks": 80, "damage": 1.5, "grade": "basic"})
	var blue_drill = ArtifactScript.new({"id": "blue_now", "name": "현재 사파이어 드릴", "shape": [[1]], "energyType": "blue", "item_type": "drill", "baseCooldownTicks": 60, "damage": 1.2, "grade": "basic"})
	var reward = {"kind": "보상 루비 드릴", "rarity": "rare", "payload": {"item_type": "drill", "energy_type": "red", "base_cooldown_ticks": 70, "damage": 1.8}, "presentation": {"description": "빨간 보상 드릴"}}
	var model = TooltipReadModelScript.project_reward_comparison(reward, [blue_drill, red_drill], "ko")
	_assert(str(model["bbcode"]).contains("보상 유물"), "comparison shows reward column")
	_assert(str(model["bbcode"]).contains("현재 장착"), "comparison shows equipped column")
	_assert(str(model["bbcode"]).contains("현재 루비 드릴"), "comparison uses same color drill")
	_assert(not str(model["bbcode"]).contains("현재 사파이어 드릴"), "comparison excludes other color drill")
	_assert(str(model["bbcode"]).contains("쿨타임"), "comparison localizes cooldown label")

# 실행: verify beacon rewards do not render a missing-drill comparison column.
func test_reward_beacon_tooltip_does_not_show_equipped_drill_comparison() -> void:
	var red_drill = ArtifactScript.new({"id": "red_now", "name": "현재 루비 드릴", "shape": [[1]], "energyType": "red", "item_type": "drill", "baseCooldownTicks": 80, "damage": 1.5, "grade": "basic"})
	var reward = {"kind": "Amplifying Cooldown Beacon", "rarity": "rare", "payload": {"item_type": "beacon", "energy_type": "red", "beacon_cooldown_mod": -12, "beacon_damage_mod": 0.4}, "presentation": {"description": "Compact 1x1 module. Pulse support."}}
	var model = TooltipReadModelScript.project_reward_comparison(reward, [red_drill], "ko")
	var text := str(model["bbcode"])
	_assert(text.contains("쿨타임 증폭 비콘"), "beacon tooltip shows reward item")
	_assert(not text.contains("현재 장착"), "beacon tooltip does not show equipped column")
	_assert(not text.contains("같은 색상 장착 드릴 없음"), "beacon tooltip does not show missing drill message")
	_assert(not text.contains("1x1"), "beacon tooltip hides size clutter")

# 실행: verify relic rewards also bypass drill comparison UI and stay colorless.
func test_reward_relic_tooltip_does_not_show_equipped_drill_comparison() -> void:
	var red_drill = ArtifactScript.new({"id": "red_now", "name": "현재 루비 드릴", "shape": [[1]], "energyType": "red", "item_type": "drill", "baseCooldownTicks": 80, "damage": 1.5, "grade": "basic"})
	var reward = {
		"kind": "Warning Bell",
		"rarity": "common",
		"text": {
			"name": {"ko": "경고 종", "en": "Warning Bell"},
			"description": {"ko": "한 칸 띄워 연결된 드릴이 관여하는 장애물 경고 시간을 늘립니다.", "en": "Extends warning time for obstacles touched by its one-gap linked drill."}
		},
		"payload": {
			"item_type": "relic",
			"energy_type": "",
			"effect_schema": {
				"version": 1,
				"link_mode": "skip_2",
				"trigger": "on_obstacle_warning",
				"type": "warning_extension",
				"summary": "Linked obstacle warnings last longer.",
				"summary_i18n": {
					"ko": "연결된 장애물 경고 시간이 더 길게 유지됩니다.",
					"en": "Linked obstacle warnings last longer."
				}
			}
		},
		"presentation": {"description": "Fallback relic description"}
	}
	var model = TooltipReadModelScript.project_reward_comparison(reward, [red_drill], "ko")
	var text := str(model["bbcode"])
	_assert(text.contains("경고 종"), "relic tooltip shows reward item")
	_assert(text.contains("유물 연결: 한 칸 띄운 연결"), "relic tooltip shows localized link label")
	_assert(not text.contains("현재 장착"), "relic tooltip does not show equipped comparison column")
	_assert(not text.contains("에너지"), "relic tooltip does not show energy label")

# 실행: verify node select read model formats selected candidates.
func test_reward_read_model_uses_localized_reward_text() -> void:
	var reward = {
		"kind": "Crimson Test Beacon",
		"rarity": "epic",
		"text": {
			"name": {"ko": "진홍 시험 비콘", "en": "Crimson Test Beacon"},
			"description": {"ko": "시험용 비콘 설명", "en": "Test beacon description"}
		},
		"payload": {"item_type": "beacon", "energy_type": "red"},
		"presentation": {"description": "fallback description", "badge": "epic red beacon"}
	}
	TextCatalogScript.set_locale("ko")
	var ko_model = RewardReadModelScript.project(reward)
	TextCatalogScript.set_locale("en")
	var en_model = RewardReadModelScript.project(reward)
	_assert_eq(str(ko_model.get("kind", "")), "진홍 시험 비콘", "reward read model uses Korean localized name")
	_assert_eq(str(en_model.get("kind", "")), "Crimson Test Beacon", "reward read model uses English localized name")
	_assert_eq(str(ko_model.get("presentation", {}).get("description", "")), "시험용 비콘 설명", "reward read model uses Korean localized description")
	_assert_eq(str(en_model.get("presentation", {}).get("description", "")), "Test beacon description", "reward read model uses English localized description")
	TextCatalogScript.set_locale("ko")

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

func test_codex_header_controls_use_compact_button_heights() -> void:
	var panel = ArtifactCodexPanelUIScript.new()
	panel._ready()
	panel._render_sections([
		{"id": "all", "label": "전체", "count": 4, "discoveredCount": 1, "active": true},
		{"id": "drill", "label": "드릴", "count": 2, "discoveredCount": 1, "active": false}
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
				"name": {"ko": "보랏빛 스태틱 니들", "en": "Violet Static Needle"},
				"description": {"ko": "테스트 설명", "en": "Test description"}
			},
			"presentation": {"icon": "drill_purple_common", "description": "Test description"}
		}]
	}
	var model: Dictionary = ArtifactCodexReadModelScript.project(reward_table, {"artifactDiscovery": ["reward_common_purple_drill_a"]}, false, "ko")
	var left_page: Dictionary = model.get("leftPage", {})
	_assert_eq(left_page.get("shapeFootprintText", ""), "2x2 칸", "codex left page reports the backpack footprint bounds for the selected artifact")
	_assert_eq(left_page.get("shapeCellCountText", ""), "실칸 3", "codex left page reports how many backpack cells are actually occupied")
	_assert_eq(left_page.get("shapeMatrix", []), [[1, 1], [1, 0]], "codex left page preserves the raw artifact shape matrix for visual rendering")

func test_main_view_codex_keeps_selected_entry_and_section_state() -> void:
	var view = MainViewRuntimeScript.new()
	_assert(view.has_method("_on_codex_entry_selected"), "main view exposes codex entry-selection handler")
	_assert(view.has_method("_on_codex_section_selected"), "main view exposes codex section-selection handler")
	view.free()

func test_main_controller_can_force_codex_discovery_state() -> void:
	_assert(MainControllerRuntimeScript != null, "main controller runtime loads for codex debug discovery helper")
	if MainControllerRuntimeScript == null:
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
	var normal_state: Dictionary = MainControllerRuntimeScript.codex_growth_state_for_debug(growth_state, reward_table, false)
	var forced_state: Dictionary = MainControllerRuntimeScript.codex_growth_state_for_debug(growth_state, reward_table, true)
	_assert_eq(normal_state.get("artifactDiscovery", []), ["drill_red_common"], "codex debug discovery helper keeps the original discovery list when disabled")
	_assert_eq(forced_state.get("artifactDiscovery", []), ["drill_red_common", "beacon_blue_rare"], "codex debug discovery helper appends each reward id once when enabled")
	_assert_eq(int(forced_state.get("gold", 0)), 77, "codex debug discovery helper preserves unrelated growth fields")

func test_main_controller_maps_starter_color_to_codex_discoveries() -> void:
	_assert(MainControllerRuntimeScript != null, "main controller runtime loads for starter codex discovery mapping")
	if MainControllerRuntimeScript == null:
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
	var discovered_state: Dictionary = MainControllerRuntimeScript.codex_growth_state_with_starter_discoveries(growth_state, reward_table, "red")
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

func test_node_select_projects_candidates() -> void:
	var scene = {"nodeSelect": {"candidates": [{"id": "normal", "label": "Normal Node", "weaknessLabel": "red"}, {"id": "elite", "label": "Elite Node", "weaknessLabel": "blue"}]}}
	var model = NodeSelectReadModelScript.project(scene, 1)
	_assert(str(model["text"]).contains("정예 노드"), "node select includes candidate label")
	_assert(str(model["text"]).contains("[url=1]"), "node select includes candidate link")
	_assert(str(model["text"]).contains("color=#ffd766"), "node select highlights selected candidate")

# 실행: verify baseline node cards do not repeat low-signal reward fields.
func test_node_select_omits_baseline_reward_noise() -> void:
	var scene = {"nodeSelect": {"candidates": [
		{"id": "normal", "label": "Safe Scar", "weaknessLabel": "red", "riskTier": "safe", "rewardBias": "baseline", "recommendedBuildHint": ""},
		{"id": "hazard", "label": "Hazard Rich", "weaknessLabel": "green", "riskTier": "danger", "rewardBias": "rarity_up", "recommendedBuildHint": "Repair-ready queue"}
	]}}
	var text := str(NodeSelectReadModelScript.project(scene, 0)["text"])
	_assert(text.contains("안전한 균열"), "node select localizes baseline label")
	_assert(not text.contains("보상: 기본"), "baseline node omits baseline reward noise")
	_assert(text.contains("보상: 희귀도 상승"), "non-baseline node keeps reward bias")

# 실행: verify reward tray read model formats reward lines and discard state.
func test_reward_tray_projects_lines_and_discard_zone() -> void:
	var rewards := [{"kind": "Ruby Drill", "rarity": "rare", "qty": 1, "presentation": {"badge": "즉시"}}]
	var held = ArtifactScript.new({"id": "held", "name": "Held Drill", "shape": [[1]], "energyType": "red", "item_type": "drill"})
	var model = RewardReadModelScript.project_tray(rewards, 0, held, true)
	_assert(str(model["text"]).contains("루비 드릴"), "reward tray includes reward kind")
	_assert(str(model["text"]).contains("들고 있음"), "reward tray marks held reward")
	_assert_eq(model["discardActive"], true, "reward tray discard active when held")
	_assert(str(model["discardText"]).contains("루비 드릴"), "reward tray discard text uses reward kind")

# 실행: verify phase layout presenter emits visibility and timer model.
func test_phase_layout_projects_visibility_and_timer() -> void:
	var scene := {"phase": "combat", "stageIndex": 1, "maxStages": 3, "targetPanel": {"timeLimitTicks": 1200.0, "elapsedTicks": 400.0}}
	var model = PhaseLayoutPresenterScript.project(scene, false)
	_assert_eq(model["phaseText"], "단계: 전투", "phase layout text")
	_assert_eq(model["stageText"], "스테이지 2 / 3", "phase layout stage text")
	_assert_eq(model["battlefieldVisible"], true, "phase layout battlefield visible")
	_assert_eq(model["rewardVisible"], false, "phase layout reward hidden during combat")
	_assert_eq(model["timerText"], "00:40", "phase layout timer text")
	_assert_eq(model["combatTimeActive"], true, "phase layout combat time active")

# 실행: verify node selection owns the available page instead of sharing prototype side panels.
# 실행: verify active reward ceremony beats keep the final combat snapshot visible until tray review begins.
func test_reward_ceremony_keeps_final_combat_snapshot_live() -> void:
	var ceremony_scene := {
		"phase": "reward_loot",
		"rewardPresentationStep": "count_lock",
		"targetPanel": {
			"timeLimitTicks": 480.0,
			"elapsedTicks": 420.0
		}
	}
	var ceremony_layout = PhaseLayoutPresenterScript.project(ceremony_scene, false)
	_assert_eq(ceremony_layout["battlefieldVisible"], true, "reward ceremony keeps battlefield visible")
	_assert_eq(ceremony_layout["statusVisible"], true, "reward ceremony keeps status panel visible")
	_assert_eq(ceremony_layout["rewardVisible"], false, "reward tray stays hidden during active ceremony beats")
	_assert_eq(ceremony_layout["combatTimeActive"], true, "reward ceremony keeps the final combat timer visible")
	_assert_eq(ceremony_layout["timerText"], "00:03", "reward ceremony timer reflects the latest dynamic limit")
	_assert_eq(StatusPanelUIScript.should_render_status_scene(ceremony_scene), true, "status panel keeps rendering during active reward ceremony beats")

	var tray_review_scene := ceremony_scene.duplicate(true)
	tray_review_scene["rewardPresentationStep"] = "tray_review"
	var tray_review_layout = PhaseLayoutPresenterScript.project(tray_review_scene, false)
	_assert_eq(tray_review_layout["rewardVisible"], true, "tray review reopens the reward panel after the ceremony")
	_assert_eq(tray_review_layout["statusVisible"], false, "tray review hides the combat status panel again")
	_assert_eq(tray_review_layout["combatTimeActive"], false, "tray review hides the combat timer again")
	_assert_eq(StatusPanelUIScript.should_render_status_scene(tray_review_scene), false, "status panel stops rendering after the active ceremony ends")

# ?ㅽ뻾: verify node selection owns the available page instead of sharing prototype side panels.
func test_node_select_layout_is_full_page() -> void:
	var model = PhaseLayoutPresenterScript.project({"phase": "node_select", "stageIndex": 0, "maxStages": 5}, false)
	_assert_eq(model["nodeSelectVisible"], true, "node select panel visible")
	_assert_eq(model["nodeMapFullPage"], true, "node map page requests full-page layout")
	_assert_eq(model["topContentVisible"], false, "node map page moves backpack into the map layout")
	_assert_eq(model["backpackVisible"], true, "node map page keeps backpack available for starter placement")
	_assert_eq(model["sidebarsVisible"], false, "node map page hides nonessential sidebars")
	_assert_eq(model["statusVisible"], false, "node map page hides combat target status")

# 실행: verify node selection requests a left map / right backpack layout.
func test_node_select_layout_uses_map_backpack_split() -> void:
	var model = PhaseLayoutPresenterScript.project({"phase": "node_select", "stageIndex": 0, "maxStages": 5}, false)
	_assert_eq(model["nodeSelectBackpackDock"], "right", "node map docks backpack on the right")
	_assert_eq(float(model["nodeMapStretchRatio"]), 1.0, "node map consumes the flexible remaining row width")
	_assert_eq(float(model["backpackStretchRatio"]), 0.0, "node-select backpack remains fixed-width and right-docked")

func test_node_select_layout_reuses_palette_when_start_panel_is_hidden() -> void:
	var controller = MainControllerRuntimeScript.new()
	_assert(controller.has_method("node_map_loadout_colors_for_scene"), "main controller exposes one node-map loadout palette source")
	if controller.has_method("node_map_loadout_colors_for_scene"):
		_assert_eq(controller.call("node_map_loadout_colors_for_scene", {"phase": "node_select", "stageIndex": 1, "allowStartColorSelection": false}), ["red", "blue", "purple", "green"], "stage two keeps the same node-map palette data while the start panel is hidden")
	controller.free()
	var stage_one_layout := PhaseLayoutPresenterScript.project({"phase": "node_select", "stageIndex": 0, "maxStages": 5}, false)
	var stage_two_layout := PhaseLayoutPresenterScript.project({"phase": "node_select", "stageIndex": 1, "maxStages": 5}, false)
	_assert_eq(stage_one_layout.get("nodeMapFullPage", false), stage_two_layout.get("nodeMapFullPage", true), "node select keeps the same full-page layout shell across stages")
	_assert_eq(stage_one_layout.get("nodeSelectBackpackDock", ""), stage_two_layout.get("nodeSelectBackpackDock", ""), "node select keeps the same backpack dock across stages")

func test_node_select_backpack_width_tracks_left_stack_height() -> void:
	var MainViewRuntimeScript = load("res://src/ui/MainViewRuntime.gd")
	_assert(MainViewRuntimeScript != null, "main view runtime loads for node-select backpack sizing")
	if MainViewRuntimeScript == null:
		return
	_assert(MainViewRuntimeScript.has_method("node_select_backpack_width_for_row"), "main view runtime exposes node-select backpack sizing policy")
	if not MainViewRuntimeScript.has_method("node_select_backpack_width_for_row"):
		return
	var roomy_width := float(MainViewRuntimeScript.node_select_backpack_width_for_row(Vector2(1260, 704), 460.0))
	_assert_eq(roomy_width, 704.0, "roomy node-select layout sizes the backpack from the left stack height")
	var constrained_width := float(MainViewRuntimeScript.node_select_backpack_width_for_row(Vector2(980, 704), 460.0))
	_assert_eq(constrained_width, 500.0, "constrained node-select layout preserves map width before matching backpack height")

func test_node_select_backpack_width_delegates_to_shared_layout_policy() -> void:
	var MainViewRuntimeScript = load("res://src/ui/MainViewRuntime.gd")
	var BackpackPinLayoutPolicyScript = load("res://src/ui/presenters/BackpackPinLayoutPolicy.gd")
	_assert(MainViewRuntimeScript != null, "main view runtime loads for shared node-select backpack policy")
	_assert(BackpackPinLayoutPolicyScript != null, "backpack pin layout policy script exists for shared node-select backpack width math")
	if MainViewRuntimeScript == null or BackpackPinLayoutPolicyScript == null:
		return
	_assert(BackpackPinLayoutPolicyScript.has_method("node_select_width_for_row"), "shared backpack policy exposes node-select width math")
	if not BackpackPinLayoutPolicyScript.has_method("node_select_width_for_row"):
		return
	var row_size := Vector2(1260.0, 704.0)
	var map_min_width := 460.0
	_assert_close(
		float(MainViewRuntimeScript.node_select_backpack_width_for_row(row_size, map_min_width)),
		float(BackpackPinLayoutPolicyScript.node_select_width_for_row(row_size, map_min_width)),
		0.001,
		"main view delegates node-select backpack width math to the shared layout policy"
	)

func test_top_content_backpack_uses_fixed_width_policy() -> void:
	var MainViewRuntimeScript = load("res://src/ui/MainViewRuntime.gd")
	_assert(MainViewRuntimeScript != null, "main view runtime loads for top-content backpack sizing policy")
	if MainViewRuntimeScript == null:
		return
	_assert(MainViewRuntimeScript.has_method("top_content_backpack_horizontal_flags"), "main view runtime exposes top-content backpack horizontal flag policy")
	_assert(MainViewRuntimeScript.has_method("top_content_side_horizontal_flags"), "main view runtime exposes top-content side-panel horizontal flag policy")
	if not MainViewRuntimeScript.has_method("top_content_backpack_horizontal_flags") or not MainViewRuntimeScript.has_method("top_content_side_horizontal_flags"):
		return
	_assert_eq(int(MainViewRuntimeScript.top_content_backpack_horizontal_flags()), int(Control.SIZE_SHRINK_CENTER), "top-content backpack stays fixed-width and centered instead of consuming expand width")
	_assert_eq(int(MainViewRuntimeScript.top_content_side_horizontal_flags()), int(Control.SIZE_EXPAND_FILL), "top-content side panels keep expand-fill behavior so they absorb the freed width")

func test_top_content_backpack_width_tracks_full_row_height() -> void:
	var MainViewRuntimeScript = load("res://src/ui/MainViewRuntime.gd")
	_assert(MainViewRuntimeScript != null, "main view runtime loads for top-content backpack height-baseline policy")
	if MainViewRuntimeScript == null:
		return
	_assert(MainViewRuntimeScript.has_method("top_content_backpack_width_for_height"), "main view runtime exposes top-content backpack width-from-height policy")
	if not MainViewRuntimeScript.has_method("top_content_backpack_width_for_height"):
		return
	_assert_close(float(MainViewRuntimeScript.top_content_backpack_width_for_height(548.0)), 638.779695, 0.001, "top-content backpack width follows the trimmed pin silhouette rather than the old padded canvas width")
	_assert_close(float(MainViewRuntimeScript.top_content_backpack_width_for_height(680.0)), 793.388977, 0.001, "larger rows still add only the trimmed pin outsets on both sides of the square grid baseline")

func test_top_content_backpack_width_ignores_available_space_clamp() -> void:
	var MainViewRuntimeScript = load("res://src/ui/MainViewRuntime.gd")
	var BackpackPinLayoutPolicyScript = load("res://src/ui/presenters/BackpackPinLayoutPolicy.gd")
	_assert(MainViewRuntimeScript != null, "main view runtime loads for backpack-priority top-content width policy")
	_assert(BackpackPinLayoutPolicyScript != null, "backpack pin layout policy loads for backpack-priority top-content width policy")
	if MainViewRuntimeScript == null or BackpackPinLayoutPolicyScript == null:
		return
	_assert(MainViewRuntimeScript.has_method("top_content_backpack_width_for_height"), "main view runtime exposes the height-derived top-content backpack width policy")
	_assert(MainViewRuntimeScript.has_method("top_content_backpack_ratio_for_height"), "main view runtime exposes the height-derived top-content backpack ratio policy")
	if not MainViewRuntimeScript.has_method("top_content_backpack_width_for_height") or not MainViewRuntimeScript.has_method("top_content_backpack_ratio_for_height"):
		return
	var desired_width := float(MainViewRuntimeScript.top_content_backpack_width_for_height(680.0))
	_assert(not MainViewRuntimeScript.has_method("top_content_backpack_width_for_available"), "main runtime no longer exposes an available-width clamp that can shrink the priority backpack panel first")
	_assert(not MainViewRuntimeScript.has_method("top_content_backpack_ratio_for_size"), "main runtime no longer exposes clamped-width ratio math for the top-content backpack")
	_assert(not BackpackPinLayoutPolicyScript.has_method("top_content_width_for_available"), "shared backpack policy no longer exposes an available-width clamp for top-content backpack sizing")
	_assert(not BackpackPinLayoutPolicyScript.has_method("top_content_ratio_for_size"), "shared backpack policy no longer exposes clamped-width ratio math for top-content backpack sizing")
	_assert_close(desired_width, 793.388977, 0.001, "constrained rows still preserve the intended height-derived backpack width")
	_assert_close(float(MainViewRuntimeScript.top_content_backpack_ratio_for_height(680.0)), desired_width / 680.0, 0.001, "top-content backpack ratio stays tied to the priority height-derived width")

func test_top_content_backpack_height_uses_single_row_source() -> void:
	var MainViewRuntimeScript = load("res://src/ui/MainViewRuntime.gd")
	_assert(MainViewRuntimeScript != null, "main view runtime loads for single-source top-content backpack height policy")
	if MainViewRuntimeScript == null:
		return
	_assert(MainViewRuntimeScript.has_method("resolved_top_content_backpack_height"), "main view runtime exposes the resolved top-content backpack height helper")
	if not MainViewRuntimeScript.has_method("resolved_top_content_backpack_height"):
		return
	_assert_eq(
		float(MainViewRuntimeScript.resolved_top_content_backpack_height(548.0, 420.0, 760.0)),
		548.0,
		"reward/backpack layout height follows the shared top-content row height instead of feeding back from the current backpack height"
	)
	_assert_eq(
		float(MainViewRuntimeScript.resolved_top_content_backpack_height(0.0, 420.0, 760.0)),
		420.0,
		"shared top-content backpack height falls back to the row minimum height when the live row has not been laid out yet"
	)

func test_top_content_backpack_width_uses_slot_scaled_pin_overhang() -> void:
	var MainViewRuntimeScript = load("res://src/ui/MainViewRuntime.gd")
	var backpack_ui = BackpackUIScript.new()
	_assert(MainViewRuntimeScript != null, "main view runtime loads for slot-scaled pin width policy")
	if MainViewRuntimeScript == null:
		return
	_assert(backpack_ui.has_method("pin_slot_extent_for_grid_extent"), "backpack exposes slot extent helper for pin sizing")
	_assert(backpack_ui.has_method("pin_display_extent_for_slot_extent"), "backpack exposes slot-scaled pin display helper")
	_assert(backpack_ui.has_method("pin_side_outset_for_slot_extent"), "backpack exposes slot-scaled side outset helper")
	_assert(MainViewRuntimeScript.has_method("top_content_backpack_pin_side_outset_for_height"), "main view exposes top-content pin side outset helper")
	if not backpack_ui.has_method("pin_slot_extent_for_grid_extent") or not backpack_ui.has_method("pin_side_outset_for_slot_extent") or not MainViewRuntimeScript.has_method("top_content_backpack_pin_side_outset_for_height"):
		return
	var grid_extent := 548.0
	var slot_extent := float(backpack_ui.call("pin_slot_extent_for_grid_extent", grid_extent))
	var pin_extent := float(backpack_ui.call("pin_display_extent_for_slot_extent", slot_extent))
	var side_outset := float(backpack_ui.call("pin_side_outset_for_slot_extent", slot_extent))
	var main_side_outset := float(MainViewRuntimeScript.top_content_backpack_pin_side_outset_for_height(grid_extent))
	var width := float(MainViewRuntimeScript.top_content_backpack_width_for_height(grid_extent))
	_assert_close(slot_extent, 53.0, 0.001, "548px grid resolves to a 10-column slot extent with 2px separators")
	_assert(pin_extent < 120.0, "pin display extent is slot-scaled rather than 30 percent of the whole grid")
	_assert_close(main_side_outset, side_outset, 0.001, "main view and backpack agree on pin side outset")
	_assert_close(width, grid_extent + side_outset * 2.0, 0.001, "top-content backpack width adds only left and right pin outsets")
	_assert(width < 712.4, "top-content backpack no longer uses the old broad 30 percent full-grid width")

func test_backpack_pin_layout_policy_unifies_backpack_and_main_width_math() -> void:
	var MainViewRuntimeScript = load("res://src/ui/MainViewRuntime.gd")
	var BackpackPinLayoutPolicyScript = load("res://src/ui/presenters/BackpackPinLayoutPolicy.gd")
	var backpack_ui = BackpackUIScript.new()
	_assert(BackpackPinLayoutPolicyScript != null, "backpack pin layout policy script exists so repeated pin sizing math has a single owner")
	_assert(MainViewRuntimeScript != null, "main view runtime loads for shared backpack pin policy contract")
	if BackpackPinLayoutPolicyScript == null or MainViewRuntimeScript == null:
		return
	_assert(BackpackPinLayoutPolicyScript.has_method("slot_extent_for_grid_extent"), "pin policy exposes shared slot extent math")
	_assert(BackpackPinLayoutPolicyScript.has_method("top_content_width_for_height"), "pin policy exposes top-content width math")
	if not BackpackPinLayoutPolicyScript.has_method("slot_extent_for_grid_extent") or not BackpackPinLayoutPolicyScript.has_method("top_content_width_for_height"):
		return
	var grid_extent := 548.0
	var policy_slot := float(BackpackPinLayoutPolicyScript.slot_extent_for_grid_extent(grid_extent))
	var policy_outset := float(BackpackPinLayoutPolicyScript.side_outset_for_grid_extent(grid_extent))
	var policy_width := float(BackpackPinLayoutPolicyScript.top_content_width_for_height(grid_extent))
	_assert_close(float(backpack_ui.call("pin_slot_extent_for_grid_extent", grid_extent)), policy_slot, 0.001, "backpack delegates slot extent math to the shared pin policy")
	_assert_close(float(backpack_ui.call("pin_side_outset_for_grid_extent", grid_extent)), policy_outset, 0.001, "backpack delegates side-outset math to the shared pin policy")
	_assert_close(float(MainViewRuntimeScript.top_content_backpack_width_for_height(grid_extent)), policy_width, 0.001, "main view delegates top-content width math to the shared pin policy")

func test_backpack_grid_keeps_expand_fill_layout_with_shell_gutter() -> void:
	var backpack_ui = BackpackUIScript.new()
	_assert(backpack_ui.has_method("backpack_grid_horizontal_flags"), "backpack exposes grid horizontal sizing policy")
	if not backpack_ui.has_method("backpack_grid_horizontal_flags"):
		return
	_assert_eq(int(backpack_ui.call("backpack_grid_horizontal_flags")), int(Control.SIZE_EXPAND_FILL), "backpack grid keeps expand-fill layout so only shell margins create the pin gutter")

func test_backpack_shell_gutter_uses_side_margin_overhang_only_in_combat() -> void:
	var backpack_ui = BackpackUIScript.new()
	_assert(backpack_ui.has_method("pin_shell_side_margin_for_outset"), "backpack exposes side-margin gutter helper for combat pin shell")
	if not backpack_ui.has_method("pin_shell_side_margin_for_outset"):
		return
	_assert_eq(int(backpack_ui.call("pin_shell_side_margin_for_outset", 24.4, false)), 16, "non-combat backpack keeps the base side margin with no pin gutter")
	_assert_eq(int(backpack_ui.call("pin_shell_side_margin_for_outset", 24.4, true)), 40, "combat backpack converts pin overhang into extra side margin gutter")

func test_main_scene_backpack_grid_uses_shell_gutter_layout() -> void:
	var MainScene = load("res://src/Main.tscn")
	_assert(MainScene != null, "main scene loads for backpack shell gutter layout contract")
	if MainScene == null:
		return
	var main_instance = MainScene.instantiate()
	_assert(main_instance != null, "main scene instantiates for backpack shell gutter layout contract")
	if main_instance == null:
		return
	var grid = main_instance.get_node_or_null("RootMargin/AppShell/TopContent/BackpackContainer/BackpackEnginePanel/Margin/EngineBox/GridMock") as GridContainer
	_assert(grid != null, "main scene exposes the backpack grid node")
	if grid != null:
		_assert_eq(int(grid.size_flags_horizontal), int(Control.SIZE_EXPAND_FILL), "main scene grid remains expand-fill and relies on shell margins for pin gutter spacing")
	main_instance.queue_free()

func test_main_scene_shared_layout_text_nodes_do_not_fit_content() -> void:
	var MainScene = load("res://src/Main.tscn")
	_assert(MainScene != null, "main scene loads for shared split-layout text policy")
	if MainScene == null:
		return
	var main_instance = MainScene.instantiate()
	_assert(main_instance != null, "main scene instantiates for shared split-layout text policy")
	if main_instance == null:
		return
	var node_select_text = main_instance.get_node_or_null("RootMargin/AppShell/ActivePhaseContainer/NodeSelectPanel/Margin/NodeSelectBox/NodeSelectText") as RichTextLabel
	var reward_text = main_instance.get_node_or_null("RootMargin/AppShell/ActivePhaseContainer/RewardPanel/Margin/RewardBox/RewardRow/RewardText") as RichTextLabel
	_assert(node_select_text != null, "main scene exposes the node-select text view")
	_assert(reward_text != null, "main scene exposes the reward text view")
	if node_select_text != null:
		_assert_eq(bool(node_select_text.fit_content), false, "node-select text does not content-fit inside the shared screen shell")
		_assert_eq(int(node_select_text.autowrap_mode), int(TextServer.AUTOWRAP_WORD_SMART), "node-select text wraps inside the shared screen shell")
	if reward_text != null:
		_assert_eq(bool(reward_text.fit_content), false, "reward text does not content-fit and resize sibling panels")
		_assert_eq(int(reward_text.autowrap_mode), int(TextServer.AUTOWRAP_WORD_SMART), "reward text wraps before it can push the discard zone off-screen")
	main_instance.queue_free()

func test_main_scene_reward_tray_row_expands_to_keep_discard_zone_inside_panel() -> void:
	var MainScene = load("res://src/Main.tscn")
	_assert(MainScene != null, "main scene loads for reward tray row expansion policy")
	if MainScene == null:
		return
	var main_instance = MainScene.instantiate()
	_assert(main_instance != null, "main scene instantiates for reward tray row expansion policy")
	if main_instance == null:
		return
	var reward_box = main_instance.get_node_or_null("RootMargin/AppShell/ActivePhaseContainer/RewardPanel/Margin/RewardBox") as VBoxContainer
	var reward_row = main_instance.get_node_or_null("RootMargin/AppShell/ActivePhaseContainer/RewardPanel/Margin/RewardBox/RewardRow") as HBoxContainer
	var reward_text = main_instance.get_node_or_null("RootMargin/AppShell/ActivePhaseContainer/RewardPanel/Margin/RewardBox/RewardRow/RewardText") as RichTextLabel
	var discard_zone = main_instance.get_node_or_null("RootMargin/AppShell/ActivePhaseContainer/RewardPanel/Margin/RewardBox/RewardRow/DiscardZone") as PanelContainer
	_assert(reward_box != null, "main scene exposes the reward tray box container")
	_assert(reward_row != null, "main scene exposes the reward tray row container")
	_assert(reward_text != null, "main scene exposes the reward tray text surface")
	_assert(discard_zone != null, "main scene exposes the reward tray discard zone")
	if reward_box != null:
		_assert_eq(int(reward_box.size_flags_vertical), int(Control.SIZE_EXPAND_FILL), "reward tray box expands vertically so the row can use the remaining panel height")
	if reward_row != null:
		_assert_eq(int(reward_row.size_flags_horizontal), int(Control.SIZE_EXPAND_FILL), "reward tray row expands horizontally so it stays constrained to the reward panel width")
		_assert_eq(int(reward_row.size_flags_vertical), int(Control.SIZE_EXPAND_FILL), "reward tray row expands vertically instead of collapsing into a shallow strip")
	if reward_text != null:
		_assert_eq(int(reward_text.size_flags_vertical), int(Control.SIZE_EXPAND_FILL), "reward tray text surface expands vertically and scrolls inside the panel instead of shrinking the row")
	if discard_zone != null:
		_assert_eq(int(discard_zone.size_flags_vertical), int(Control.SIZE_EXPAND_FILL), "reward tray discard zone stretches with the row height so it remains centered and fully visible")
	main_instance.queue_free()

func test_main_ui_load_chain_survives_reward_reveal_preloads() -> void:
	var RewardRevealOverlayScript = load("res://src/ui/RewardRevealOverlay.gd")
	_assert(RewardRevealOverlayScript != null, "reward reveal overlay compiles so main-view preloads do not break the main UI inheritance chain")
	if RewardRevealOverlayScript == null:
		return
	var MainViewRuntimeScript = load("res://src/ui/MainViewRuntime.gd")
	_assert(MainViewRuntimeScript != null, "main view runtime compiles after the reward reveal overlay preload chain resolves cleanly")
	if MainViewRuntimeScript == null:
		return
	var MainUIScript = load("res://src/ui/MainUI.gd")
	_assert(MainUIScript != null, "main ui facade compiles through the main-view runtime preload chain without parser-resolution failure")

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

func test_phase_layout_hides_floating_battlefield_timer() -> void:
	var model = PhaseLayoutPresenterScript.project({"phase": "combat", "stageIndex": 0, "maxStages": 5, "targetPanel": {"timeLimitTicks": 1200.0, "elapsedTicks": 200.0}}, false)
	_assert_eq(model["combatTimeActive"], true, "combat layout still exposes the countdown as active combat state")
	_assert_eq(model["giantTimerVisible"], false, "combat layout no longer shows the floating battlefield timer above the terrain strip")

func test_phase_layout_gives_backpack_more_space_in_combat_and_reward() -> void:
	var combat = PhaseLayoutPresenterScript.project({"phase": "combat", "stageIndex": 0, "maxStages": 5}, false)
	var reward = PhaseLayoutPresenterScript.project({"phase": "reward_loot", "stageIndex": 0, "maxStages": 5}, false)
	_assert_eq(float(combat.get("leftColumnTopStretchRatio", 0.0)), 2.0, "combat left status column compresses before the priority backpack panel")
	_assert_eq(float(combat.get("backpackTopStretchRatio", -1.0)), 0.0, "combat backpack container no longer consumes horizontal stretch width")
	_assert_eq(float(combat.get("rightSidebarTopStretchRatio", 0.0)), 1.55, "combat log sidebar compresses before the priority backpack panel")
	_assert_eq(float(reward.get("backpackTopStretchRatio", -1.0)), 0.0, "reward layout also keeps the backpack fixed-width instead of stretching its slot")
	_assert(float(combat.get("leftColumnTopStretchRatio", 0.0)) > 0.0, "combat layout leaves remaining horizontal width to the side panels")
	_assert(float(combat.get("rightSidebarTopStretchRatio", 0.0)) > 0.0, "combat layout leaves remaining horizontal width to the log sidebar")
	_assert(float(combat.get("leftColumnTopStretchRatio", 0.0)) > float(combat.get("rightSidebarTopStretchRatio", 0.0)), "combat keeps the drill/status side slightly wider than the log side because it owns the queue and bars")

func test_phase_layout_hides_backpack_cooldown_visuals_outside_combat() -> void:
	var node_select = PhaseLayoutPresenterScript.project({"phase": "node_select", "stageIndex": 0, "maxStages": 5}, false)
	var reward = PhaseLayoutPresenterScript.project({"phase": "reward_loot", "stageIndex": 0, "maxStages": 5}, false)
	var combat = PhaseLayoutPresenterScript.project({"phase": "combat", "stageIndex": 0, "maxStages": 5}, false)
	_assert_eq(bool(node_select.get("backpackCooldownVisible", true)), false, "node-select hides cooldown darkness so the starter loadout stays readable")
	_assert_eq(bool(reward.get("backpackCooldownVisible", true)), false, "reward layout hides cooldown darkness while reorganizing loot")
	_assert_eq(bool(combat.get("backpackCooldownVisible", false)), true, "combat keeps cooldown darkness visible")

# 실행: verify combat feedback presenter converts hit status to screenshake.
func test_battlefield_layout_uses_top_left_header_miner_overlay() -> void:
	var battlefield_ui = BattlefieldUIScript.new()
	_assert(battlefield_ui.has_method("layout_metrics_for_board"), "battlefield ui exposes deterministic terrain layout metrics for regression tests")
	if not battlefield_ui.has_method("layout_metrics_for_board"):
		return
	var metrics: Dictionary = battlefield_ui.call("layout_metrics_for_board", Vector2(1280.0, 220.0))
	var shell_rect: Rect2 = metrics.get("shellRect", Rect2())
	var grid_rect: Rect2 = metrics.get("gridRect", Rect2())
	var header_miner_rect: Rect2 = metrics.get("headerMinerRect", Rect2())
	_assert(abs(header_miner_rect.position.x - 0.0) < 0.1, "header miner now hugs the panel's left edge")
	_assert(abs(header_miner_rect.position.y - 0.0) < 0.1, "header miner now touches the top edge of the battlefield panel")
	_assert(abs(shell_rect.position.x - 20.0) < 0.1, "terrain shell keeps its left margin instead of shifting right to make a miner column")
	_assert(abs(shell_rect.position.y - 8.0) < 0.1, "battlefield shell shifts upward by about 12px so the miner sits closer to the panel ceiling")
	_assert(abs((1280.0 - shell_rect.end.x) - 20.0) < 0.1, "battlefield shell keeps a symmetric right margin while the miner overlays above it")
	_assert(abs((220.0 - shell_rect.end.y) - 8.0) < 0.1, "battlefield shell extends downward by the same amount it moved upward so the tile panel stays vertically balanced")
	_assert(grid_rect.size.y >= 140.0, "battlefield grid gains extra vertical room after the shell expands upward and downward")
	_assert(abs(float(metrics.get("headerMinerWidth", 0.0)) - (1280.0 * 0.1425)) < 0.1, "header miner uses about half of the previous battlefield miner width ratio")

func test_cell_view_uses_tile_alpha_for_weakness_readability() -> void:
	_assert(abs(float(CellViewScript.base_tile_alpha_for(null)) - 0.5) < 0.01, "non-weakness tiles render semi-transparent")
	_assert(abs(float(CellViewScript.base_tile_alpha_for("red")) - 1.0) < 0.01, "weakness tiles render fully opaque")

func test_cell_view_uses_active_queue_color_for_tile_alpha_readability() -> void:
	_assert(abs(float(CellViewScript.base_tile_alpha_for("purple", "purple", "purple")) - 1.0) < 0.01, "queue-matching tiles stay fully opaque")
	_assert(abs(float(CellViewScript.base_tile_alpha_for("red", "red", "purple")) - 0.5) < 0.01, "nonmatching colored tiles fade when another queue color is active")
	_assert(abs(float(CellViewScript.base_tile_alpha_for(null, "blue", "purple")) - 0.5) < 0.01, "nonmatching fallback obstacle tiles also fade against the active queue color")

func test_combat_scene_projects_all_energy_weakness_as_highlighted_tiles() -> void:
	var model = CombatSceneModelScript.new()
	var snapshot := {
		"phase": "combat",
		"stageIndex": 0,
		"maxStages": 1,
		"runIndex": 0,
		"runCount": 1,
		"combat": {
			"result": "active",
			"weakness": ["green"],
			"shield": 10.0,
			"health": 10.0,
			"maxShield": 10.0,
			"maxHealth": 10.0,
			"queue": {
				"capacity": 2,
				"loaded": 2,
				"items": [
					{"color": "green", "source_artifact_id": "starter_green_drill", "source_item_type": "drill"},
					{"color": "red", "source_artifact_id": "starter_red_drill", "source_item_type": "drill"}
				]
			},
			"pin": {},
			"repair": {},
			"hazard": {},
			"aim": {"cellId": "r0c0", "canFire": true},
			"battlefield": {
				"rows": 1,
				"columns": 2,
				"weaknessMarkers": [
					{"cellId": "r0c0", "color": "green"},
					{"cellId": "r0c1", "color": "red", "allEnergyWeakness": true}
				],
				"terrainDebuffs": [],
				"terrainBuffs": []
			}
		}
	}
	var scene: Dictionary = model.create(snapshot, {"viewportWidth": 400, "viewportHeight": 200})
	_assert_eq(scene["terrain"]["cells"][0].get("queueMatch", false), true, "baseline matching tile stays highlighted")
	_assert_eq(scene["terrain"]["cells"][1].get("queueMatch", false), true, "all-energy weakness tiles stay highlighted even when their color differs from the active queue")
	_assert_eq(scene["terrain"]["cells"][1].get("weakness", ""), "red", "all-energy weakness projection keeps the cell's original color")

func test_cell_view_projects_hazard_alpha_by_state() -> void:
	_assert(abs(float(CellViewScript.hazard_alpha_for({"state": "active"})) - 1.0) < 0.01, "active hazards render fully opaque")
	_assert(float(CellViewScript.hazard_alpha_for({"state": "afterglow_clear", "afterglowTicksRemaining": 3, "afterglowTicks": 12})) < 0.3, "afterglow hazards render as faint residue")
	_assert_eq(float(CellViewScript.hazard_alpha_for({})), 0.0, "missing hazard state renders with no hazard overlay alpha")

func test_cell_view_removes_colored_hazard_frame() -> void:
	_assert_eq(float(CellViewScript.hazard_frame_margin_for("red", "active")), 0.0, "active hazards no longer reserve a colored outer frame margin")
	_assert_eq(float(CellViewScript.hazard_frame_margin_for("green", "active")), 0.0, "green hazards also remove the old outer frame margin")
	_assert_eq(float(CellViewScript.hazard_frame_margin_for("purple", "afterglow_clear")), 0.0, "afterglow hazards keep no colored outline margin")

func test_cell_view_maps_green_family_to_green_hazard_texture() -> void:
	var green_hazard_texture = CellViewScript._hazard_texture_for_color("green")
	_assert(green_hazard_texture != null, "green hazard family resolves to a dedicated texture")
	_assert_eq(green_hazard_texture, CellViewScript.GREEN_HAZARD_TEXTURE, "green hazards use green_tile_hazard.png instead of a shared fallback")

func test_cell_view_expands_green_hazard_overlay_and_softens_fill() -> void:
	_assert(float(CellViewScript.hazard_texture_margin_for("green", "active")) > float(CellViewScript.hazard_texture_margin_for("red", "active")), "green hazards expand farther so the vine frame stays readable at combat scale")
	_assert(float(CellViewScript.active_hazard_fill_alpha_for("green", 0.8)) < float(CellViewScript.active_hazard_fill_alpha_for("red", 0.8)), "green hazards keep a lighter active fill so the hazard artwork is not washed out")

func test_hazard_model_uses_active_severity_for_live_obstacles() -> void:
	var model = HazardModelScript.new()
	model.update_state(10.0, 0, "active", 10.0, [{"family": "green", "state": "active"}], 0.0)
	_assert_eq(model.severity, "active", "live hazards no longer project a warning severity tier")
	_assert_eq(model.label, "green", "live hazard label keeps the leading family")

func test_hazard_model_stays_stable_without_live_obstacles() -> void:
	var model = HazardModelScript.new()
	model.update_state(1.0, 2, "active", 10.0, [], 0.0)
	_assert_eq(model.severity, "stable", "hazard severity stays stable when no live obstacles exist")
	_assert_eq(model.active, false, "hazard model deactivates when the battlefield has no live hazards")

func test_battlefield_maps_columns_to_miner_pose_assets() -> void:
	var battlefield_ui = BattlefieldUIScript.new()
	_assert(battlefield_ui.has_method("miner_pose_asset_path_for_column"), "battlefield ui exposes a deterministic miner pose mapper for click-column reactions")
	_assert(battlefield_ui.has_method("miner_pose_asset_path_for_cell_id"), "battlefield ui exposes a cell-id miner pose mapper for combat click routing")
	if not battlefield_ui.has_method("miner_pose_asset_path_for_column") or not battlefield_ui.has_method("miner_pose_asset_path_for_cell_id"):
		return
	_assert_eq(String(battlefield_ui.call("miner_pose_asset_path_for_column", 0)), "res://resources/UI/miner/miner_90.png", "leftmost column uses the 90-degree miner pose")
	_assert_eq(String(battlefield_ui.call("miner_pose_asset_path_for_column", 1)), "res://resources/UI/miner/miner_90.png", "second column still uses the 90-degree miner pose")
	_assert_eq(String(battlefield_ui.call("miner_pose_asset_path_for_column", 2)), "res://resources/UI/miner/miner_60.png", "third column switches to the 60-degree miner pose")
	_assert_eq(String(battlefield_ui.call("miner_pose_asset_path_for_column", 5)), "res://resources/UI/miner/miner_60.png", "sixth column keeps the 60-degree miner pose")
	_assert_eq(String(battlefield_ui.call("miner_pose_asset_path_for_column", 6)), "res://resources/UI/miner/miner_45.png", "seventh column switches back to the shallow 45-degree miner pose")
	_assert_eq(String(battlefield_ui.call("miner_pose_asset_path_for_column", 9)), "res://resources/UI/miner/miner_45.png", "rightmost column keeps the 45-degree miner pose")
	_assert_eq(String(battlefield_ui.call("miner_pose_asset_path_for_cell_id", "r0c1")), "res://resources/UI/miner/miner_90.png", "cell ids in the left two columns map to the 90-degree pose")
	_assert_eq(String(battlefield_ui.call("miner_pose_asset_path_for_cell_id", "r1c4")), "res://resources/UI/miner/miner_60.png", "middle-band cell ids map to the 60-degree pose")
	_assert_eq(String(battlefield_ui.call("miner_pose_asset_path_for_cell_id", "r2c8")), "res://resources/UI/miner/miner_45.png", "right-band cell ids map to the 45-degree pose")
	_assert_eq(String(battlefield_ui.call("miner_pose_asset_path_for_cell_id", "bad-id")), "res://resources/UI/miner/miner_45.png", "invalid cell ids fall back to the default 45-degree pose")

func test_battlefield_miner_pose_assets_use_trimmed_regions() -> void:
	var battlefield_ui = BattlefieldUIScript.new()
	_assert(battlefield_ui.has_method("_texture_for_miner_pose_path"), "battlefield ui keeps the pose-texture resolver available for trimmed miner regions")
	if not battlefield_ui.has_method("_texture_for_miner_pose_path"):
		return
	var expected_regions := {
		"res://resources/UI/miner/miner_45.png": Rect2(91, 201, 1311, 612),
		"res://resources/UI/miner/miner_60.png": Rect2(298, 80, 709, 1024),
		"res://resources/UI/miner/miner_90.png": Rect2(510, 59, 234, 1140)
	}
	for asset_path in expected_regions.keys():
		var atlas := battlefield_ui.call("_texture_for_miner_pose_path", asset_path) as AtlasTexture
		_assert(atlas != null, "battlefield miner pose %s uses a trimmed atlas texture so pose padding cannot push the visible drill away from the panel edge" % asset_path)
		if atlas != null:
			_assert_eq(atlas.region, expected_regions[asset_path], "battlefield miner pose %s trims to the measured visible bounds before layout" % asset_path)

func test_main_scene_uses_header_miner_and_status_timer_footer() -> void:
	var MainScene = load("res://src/Main.tscn")
	_assert(MainScene != null, "main scene resource loads for battlefield layout structure test")
	if MainScene == null:
		return
	var main_instance = MainScene.instantiate()
	_assert(main_instance != null, "main scene instantiates for battlefield layout structure test")
	if main_instance == null:
		return
	var header_miner = main_instance.get_node_or_null("RootMargin/AppShell/ActivePhaseContainer/BattlefieldPanel/Margin/BattlefieldBox/BattlefieldVisualRoot/TitleMiner") as TextureRect
	_assert(header_miner != null, "battlefield title area now uses a miner texture instead of plain text")
	var lower_overlay_miner = main_instance.get_node_or_null("RootMargin/AppShell/ActivePhaseContainer/BattlefieldPanel/Margin/BattlefieldBox/BattlefieldVisualRoot/MinerVisual")
	_assert(lower_overlay_miner == null, "battlefield visual root no longer keeps the old lower-left miner overlay")
	var footer_margin = main_instance.get_node_or_null("RootMargin/AppShell/TopContent/LeftColumn/StatusPanel/Margin/StatusBox/CombatTimerFooterMargin") as MarginContainer
	_assert(footer_margin != null, "status panel exposes a dedicated footer margin for the relocated combat timer")
	if footer_margin != null:
		_assert_eq(footer_margin.get_theme_constant("margin_bottom"), 10, "status timer footer now sits closer to the panel floor with about 10px bottom breathing room")
	var footer_timer = main_instance.get_node_or_null("RootMargin/AppShell/TopContent/LeftColumn/StatusPanel/Margin/StatusBox/CombatTimerFooterMargin/CombatTimerFooter/CombatTimerLabel") as Label
	_assert(footer_timer != null, "status panel includes a large footer countdown label")
	if footer_timer != null:
		_assert_eq(footer_timer.get_theme_font_size("font_size"), 36, "status footer countdown now uses the requested 36px size")
	main_instance.queue_free()

func test_main_scene_status_panel_uses_two_row_energy_queue() -> void:
	var MainScene = load("res://src/Main.tscn")
	_assert(MainScene != null, "main scene resource loads for status queue layout structure test")
	if MainScene == null:
		return
	var main_instance = MainScene.instantiate()
	_assert(main_instance != null, "main scene instantiates for status queue layout structure test")
	if main_instance == null:
		return
	var visual_queue_box = main_instance.get_node_or_null("RootMargin/AppShell/TopContent/LeftColumn/StatusPanel/Margin/StatusBox/QueueRow/VisualQueueBox") as GridContainer
	_assert(visual_queue_box != null, "status panel energy queue uses a grid so sixteen slots wrap into two rows")
	if visual_queue_box != null:
		_assert_eq(visual_queue_box.columns, 8, "status panel energy queue uses eight columns, yielding two rows for the default sixteen-slot capacity")
		_assert_eq(visual_queue_box.get_theme_constant("h_separation"), 6, "status panel energy queue keeps compact horizontal gem spacing")
		_assert_eq(visual_queue_box.get_theme_constant("v_separation"), 4, "status panel energy queue keeps compact vertical row spacing")
	main_instance.queue_free()

func test_main_scene_exposes_purple_status_row() -> void:
	var MainScene = load("res://src/Main.tscn")
	_assert(MainScene != null, "main scene resource loads for purple status row contract")
	if MainScene == null:
		return
	var main_instance = MainScene.instantiate()
	_assert(main_instance != null, "main scene instantiates for purple status row contract")
	if main_instance == null:
		return
	var purple_row = main_instance.get_node_or_null("RootMargin/AppShell/TopContent/LeftColumn/StatusPanel/Margin/StatusBox/StatusFooterSpacer/PurpleStatusRow") as HBoxContainer
	_assert(purple_row != null, "status panel now exposes the purple status row inside the footer spacer lane")
	_assert(main_instance.get_node_or_null("RootMargin/AppShell/TopContent/LeftColumn/StatusPanel/Margin/StatusBox/PurpleStatusRow") == null, "purple status row no longer sits in the main VBox flow where it could grow combat layout height")
	var purple_value = main_instance.get_node_or_null("RootMargin/AppShell/TopContent/LeftColumn/StatusPanel/Margin/StatusBox/StatusFooterSpacer/PurpleStatusRow/PurpleStatusValue") as Label
	_assert(purple_value != null, "purple status row exposes a value label for reduction and stack text")
	main_instance.queue_free()

func test_battlefield_lane_overlay_keeps_shell_visible_through_transparent_tiles() -> void:
	var battlefield_ui = BattlefieldUIScript.new()
	_assert(battlefield_ui.has_method("lane_overlay_color"), "battlefield ui exposes the terrain lane overlay color for transparency regression coverage")
	if not battlefield_ui.has_method("lane_overlay_color"):
		return
	var lane_color: Color = battlefield_ui.call("lane_overlay_color")
	_assert(lane_color.a <= 0.25, "terrain lane overlay stays faint enough that transparent tile edges reveal the stone shell instead of reading as black backing")

func test_combat_feedback_projects_screenshake() -> void:
	var match_feedback = CombatFeedbackPresenterScript.project_screenshake("match")
	var mismatch_feedback = CombatFeedbackPresenterScript.project_screenshake("mismatch")
	var empty_feedback = CombatFeedbackPresenterScript.project_screenshake("empty_queue")
	_assert_eq(match_feedback["duration"], 0.18, "match shake duration")
	_assert_eq(match_feedback["magnitude"], 7.0, "match shake magnitude")
	_assert_eq(mismatch_feedback["duration"], 0.12, "mismatch shake duration")
	_assert_eq(mismatch_feedback["magnitude"], 3.0, "mismatch shake magnitude")
	_assert_eq(empty_feedback["duration"], 0.08, "empty shake duration")
	_assert_eq(empty_feedback["magnitude"], 1.0, "empty shake magnitude")

# 실행: verify floating tooltip stays within the visible viewport.
func test_tooltip_position_clamps_to_viewport() -> void:
	var pos = ArtifactTooltipUIScript.clamped_position(Vector2(790, 590), Vector2(240, 120), Vector2(800, 600), Vector2(15, 15), 8.0)
	_assert_eq(pos, Vector2(552, 472), "tooltip clamps bottom-right overflow")
	var top_left = ArtifactTooltipUIScript.clamped_position(Vector2(-20, -10), Vector2(240, 120), Vector2(800, 600), Vector2(15, 15), 8.0)
	_assert_eq(top_left, Vector2(8, 8), "tooltip clamps top-left overflow")

# 실행: verify multi-cell artifacts only draw black borders on the outer perimeter.
func test_backpack_artifact_edges_omit_internal_borders() -> void:
	var shape := [[1, 1], [1, 0]]
	var top_left_edges: Dictionary = BackpackGridFactoryScript.artifact_edge_mask(shape, 0, 0)
	_assert_eq(top_left_edges, {"left": true, "top": true, "right": false, "bottom": false}, "top-left L artifact cell has only outer borders")
	var top_right_edges: Dictionary = BackpackGridFactoryScript.artifact_edge_mask(shape, 0, 1)
	_assert_eq(top_right_edges, {"left": false, "top": true, "right": true, "bottom": true}, "top-right L artifact cell hides shared left border")
	var style := BackpackGridFactoryScript.artifact_style("red", 0.75, top_left_edges)
	_assert_eq(style.border_width_left, 1, "outer left border is visible")
	_assert_eq(style.border_width_top, 1, "outer top border is visible")
	_assert_eq(style.border_width_right, 0, "internal right border is hidden")
	_assert_eq(style.border_width_bottom, 0, "internal bottom border is hidden")

# 실행: verify a picked-up backpack item keeps the same slot-sized visual language instead of shrinking into a different ghost tile.
func test_backpack_drag_ghost_matches_grid_visual_scale_and_fill() -> void:
	var backpack_ui = BackpackUIScript.new()
	_assert(backpack_ui.has_method("ghost_cell_size_for_slot"), "backpack ui exposes a ghost cell sizing helper tied to grid slot size")
	_assert(backpack_ui.has_method("artifact_fill_alpha"), "backpack ui exposes one artifact fill alpha shared by grid and drag ghost")
	if not backpack_ui.has_method("ghost_cell_size_for_slot") or not backpack_ui.has_method("artifact_fill_alpha"):
		return
	var slot_size := Vector2(46.0, 46.0)
	_assert_eq(backpack_ui.call("ghost_cell_size_for_slot", slot_size), slot_size, "selected backpack items keep the same slot-sized footprint when rendered as a ghost")
	_assert_eq(float(backpack_ui.call("artifact_fill_alpha")), 0.32, "selected backpack items keep the same fill alpha as the in-grid artifact overlay")

# 실행: verify cooldown charge ratio changes as the artifact cooldown ticks down.
func test_backpack_cooldown_charge_ratio_changes_with_current_cooldown() -> void:
	var early := BackpackGridFactoryScript.cooldown_charge_ratio(75, 100, 0)
	var late := BackpackGridFactoryScript.cooldown_charge_ratio(25, 100, 0)
	_assert(early < late, "cooldown charge ratio increases as cooldown decreases")
	_assert_eq(early, 0.25, "early cooldown charge ratio")
	_assert_eq(late, 0.75, "late cooldown charge ratio")

# 실행: verify the UI helper eases cooldown fill instead of snapping to the target.
func test_backpack_cooldown_charge_ratio_smoothly_interpolates() -> void:
	var eased := BackpackGridFactoryScript.smooth_charge_ratio(0.2, 0.8, 0.1, 3.0)
	_assert(eased > 0.2, "smooth cooldown ratio moves upward")
	_assert(eased < 0.8, "smooth cooldown ratio does not snap to target")

# ?ㅽ뻾: verify the visible cooldown mask drains continuously from frame time.
func test_backpack_cooldown_mask_ratio_decreases_with_frame_time() -> void:
	var remaining := BackpackGridFactoryScript.cooldown_remaining_ratio(75, 100, 0)
	var advanced := BackpackGridFactoryScript.advance_visual_cooldown(75.0, 0.25, 20.0)
	_assert_eq(remaining, 0.75, "cooldown remaining mask ratio")
	_assert_eq(advanced, 70.0, "visual cooldown advances by frame delta")
	_assert(BackpackGridFactoryScript.cooldown_remaining_ratio(int(advanced), 100, 0) < remaining, "mask shrinks as frame time advances")

# 실행: verify terrain marker movement cadence leaves more room after player target selection.
# 실행: verify model refreshes cannot make an active cooldown mask grow again.
func test_backpack_cooldown_display_does_not_backtrack_on_snapshot_refresh() -> void:
	var stable := BackpackGridFactoryScript.stable_cooldown_display(45.0, 60.0, 80)
	_assert_eq(stable, 45.0, "stale backend refresh does not increase displayed cooldown")
	var reduced := BackpackGridFactoryScript.stable_cooldown_display(45.0, 30.0, 80)
	_assert_eq(reduced, 30.0, "backend cooldown reductions still apply")
	var reset := BackpackGridFactoryScript.stable_cooldown_display(0.0, 80.0, 80)
	_assert_eq(reset, 80.0, "freshly fired drill cooldown can reset to full")

func test_main_controller_uses_terrain_shift_interval() -> void:
	var MainControllerScript = load("res://src/MainControllerRuntime.gd")
	_assert(MainControllerScript != null, "main controller runtime loads")
	if MainControllerScript == null:
		return
	_assert_eq(float(MainControllerScript.TERRAIN_SHIFT_SECONDS), 1.5, "terrain marker shift interval is 1.5 seconds")

# 실행: verify backend cooldown ticks use the same 20 ticks/sec cadence as backpack animation.
func test_main_controller_syncs_combat_ticks_to_shift_interval() -> void:
	var MainControllerScript = load("res://src/MainControllerRuntime.gd")
	_assert(MainControllerScript != null, "main controller runtime loads for shift tick sync")
	if MainControllerScript == null:
		return
	_assert_eq(int(MainControllerScript.TERRAIN_SHIFT_TICKS), 30, "1.5 second shift advances 30 combat ticks")

func test_main_controller_prefers_clicked_cell_color_for_targeting() -> void:
	_assert_eq(MainControllerRuntimeScript.resolve_target_color_for_interaction("blue", "red"), "blue", "click targeting uses the clicked tile color instead of the active queue color")
	_assert_eq(MainControllerRuntimeScript.resolve_target_color_for_interaction("green", "purple"), "green", "hover and hold targeting preserve the actual cell color")
	_assert_eq(MainControllerRuntimeScript.resolve_target_color_for_interaction("normal", "red"), "red", "normal fallback still uses the active queue color when a cell exposes no color")
	_assert_eq(MainControllerRuntimeScript.resolve_target_color_for_interaction("", "purple"), "purple", "empty cell-color input falls back to the active queue color")

# 실행: verify starter drill and beacon begin adjacent so stage-one cooldown support can work.
func test_main_controller_starter_loadout_positions_are_adjacent() -> void:
	var MainControllerScript = load("res://src/MainControllerRuntime.gd")
	_assert(MainControllerScript != null, "main controller runtime loads for starter positions")
	if MainControllerScript == null:
		return
	var positions: Array = MainControllerScript.STARTER_LOADOUT_POSITIONS
	_assert_eq(positions.size(), 2, "starter loadout exposes two positions")
	var delta: Vector2 = positions[0] - positions[1]
	_assert_eq(int(abs(delta.x) + abs(delta.y)), 1, "starter drill and beacon begin orthogonally adjacent")

# ?ㅽ뻾: verify reward names hide version, color, and size implementation tags.
# 실행: verify the expanded active phase is limited to the node-map page.
func test_phase_layout_restores_combat_active_phase_height() -> void:
	var node_model = PhaseLayoutPresenterScript.project({"phase": "node_select", "stageIndex": 0, "maxStages": 5}, false)
	var combat_model = PhaseLayoutPresenterScript.project({"phase": "combat", "stageIndex": 0, "maxStages": 5}, false)
	_assert_eq(float(node_model.get("activePhaseStretchRatio", 0.0)), 7.0, "node map can expand active phase")
	_assert_eq(float(combat_model.get("activePhaseStretchRatio", 0.0)), 1.0, "combat restores previous active phase height")

func test_text_catalog_strips_item_implementation_tags() -> void:
	TextCatalogScript.set_locale("en")
	_assert_eq(TextCatalogScript.display_name("Crimson Drill Core v2 (Red)"), "Crimson Drill Core", "display name strips version and color tag")
	_assert_eq(TextCatalogScript.display_name("Anchor Beacon 3x2"), "Anchor Beacon", "display name strips size tag")
	_assert_eq(TextCatalogScript.display_description("Beacon: Large 3x2 module that pulses. (Green)"), "Beacon: that pulses.", "description strips module and color tag")
	TextCatalogScript.set_locale("ko")

# 실행: verify terrain debuffs are global HUD status and current queue color marks matching cells.
func test_combat_scene_projects_global_debuff_and_queue_match() -> void:
	var model = CombatSceneModelScript.new()
	var snapshot := {
		"phase": "combat",
		"stageIndex": 0,
		"maxStages": 1,
		"runIndex": 0,
		"runCount": 1,
		"combat": {
			"result": "active",
			"weakness": ["green"],
			"shield": 10.0,
			"health": 10.0,
			"maxShield": 10.0,
			"maxHealth": 10.0,
			"queue": {
				"capacity": 2,
				"loaded": 2,
				"items": [
					{"color": "green", "source_artifact_id": "starter_green_drill", "source_item_type": "drill"},
					{"color": "red", "source_artifact_id": "starter_red_drill", "source_item_type": "drill"}
				]
			},
			"pin": {},
			"repair": {},
			"hazard": {},
			"aim": {"cellId": "r0c0", "canFire": true},
			"battlefield": {
				"rows": 1,
				"columns": 2,
				"weaknessMarkers": [{"cellId": "r0c0", "color": "green"}, {"cellId": "r0c1", "color": "red"}],
				"terrainDebuffs": [{"scope": "global", "effect": "weakened_terrain", "energy": "purple", "stacks": 2}],
				"terrainBuffs": [{"scope": "global", "effect": "fortified_terrain", "energy": "purple", "stacks": 1}]
			}
		}
	}
	var scene: Dictionary = model.create(snapshot, {"viewportWidth": 400, "viewportHeight": 200})
	_assert_eq(scene["terrain"].get("activeQueueColor", ""), "green", "terrain exposes active queue color")
	_assert_eq(scene["terrain"]["cells"][0].get("queueMatch", false), true, "matching weakness cell is highlighted")
	_assert_eq(scene["terrain"]["cells"][1].get("queueMatch", true), false, "nonmatching weakness cell is not highlighted")
	_assert(not scene["terrain"]["cells"][0].has("terrainDebuff"), "terrain debuff is not attached to individual cells")
	_assert_eq(scene["hud"].get("terrainDebuffs", []).size(), 1, "hud exposes global terrain debuffs")
	_assert_eq(scene["hud"]["terrainDebuffs"][0].get("stacks", 0), 2, "hud keeps global terrain debuff stacks")
	_assert_eq(scene["hud"].get("terrainBuffs", []).size(), 1, "hud also exposes global purple terrain buffs")
	_assert_eq(scene["hud"]["terrainBuffs"][0].get("stacks", 0), 1, "hud keeps global purple terrain buff stacks")
	_assert_eq(scene["hud"].get("purplePressure", {}).get("stackCount", 0), 2, "hud exposes purple weakened stack count separately")
	_assert_eq(scene["hud"].get("purplePressure", {}).get("buffCount", 0), 1, "hud exposes purple fortified stack count separately")
	_assert_eq(scene["hud"].get("purplePressure", {}).get("active", false), true, "purple pressure flag turns on when weakened or fortified stacks are active")

func test_main_controller_projects_split_damage_popups_using_tile_color() -> void:
	var events: Array = MainControllerRuntimeScript.build_damage_popup_events(
		{"shield": 2.4, "health": 10.0},
		{"shield": 1.6, "health": 9.1},
		"purple",
		"green",
		"match"
	)
	_assert_eq(events.size(), 2, "split damage popups include separate shield and hp entries")
	_assert_eq(str(events[0].get("channel", "")), "shield", "shield popup is emitted first")
	_assert(abs(float(events[0].get("amount", 0.0)) - 0.8) < 0.001, "shield popup keeps exact shield damage")
	_assert_eq(str(events[0].get("color", "")), "purple", "shield popup color follows the hit tile color")
	_assert_eq(str(events[1].get("channel", "")), "health", "health popup is emitted second")
	_assert(abs(float(events[1].get("amount", 0.0)) - 0.9) < 0.001, "health popup keeps exact hp damage")
	_assert_eq(str(events[1].get("color", "")), "purple", "health popup color also follows the hit tile color")
	var fallback_events: Array = MainControllerRuntimeScript.build_damage_popup_events(
		{"shield": 1.0, "health": 10.0},
		{"shield": 0.5, "health": 10.0},
		"normal",
		"green",
		"match"
	)
	_assert_eq(str(fallback_events[0].get("color", "")), "green", "normal tiles fall back to the active shot color for popup tint")
	var empty_events: Array = MainControllerRuntimeScript.build_damage_popup_events(
		{"shield": 1.0, "health": 10.0},
		{"shield": 1.0, "health": 10.0},
		"red",
		"red",
		"empty_queue"
	)
	_assert_eq(empty_events.size(), 0, "empty queue does not spawn damage popups")

func test_vfx_manager_popup_palette_tracks_tile_color() -> void:
	var purple_palette: Dictionary = VFXManagerScript.popup_palette_for_color("purple")
	var blue_palette: Dictionary = VFXManagerScript.popup_palette_for_color("blue")
	_assert(purple_palette.has("fill"), "popup palette exposes a fill color")
	_assert(purple_palette.has("shadow"), "popup palette exposes a shadow color")
	_assert_eq(purple_palette.get("fontSize", 0), 20, "natural popup style keeps the shared 20px base font size")
	_assert(purple_palette.get("fill", Color.WHITE) != blue_palette.get("fill", Color.WHITE), "popup fill color changes with the hit tile color")

# ?ㅽ뻾: verify interactive UI cues communicate affordance and rejection states.
func test_interaction_cues_distinguish_hover_press_drag_and_disabled() -> void:
	var idle := InteractionCuePresenterScript.project_control_state({"hovered": false, "pressed": false, "disabled": false})
	var hover := InteractionCuePresenterScript.project_control_state({"hovered": true, "pressed": false, "disabled": false})
	var pressed := InteractionCuePresenterScript.project_control_state({"hovered": true, "pressed": true, "disabled": false})
	var disabled := InteractionCuePresenterScript.project_control_state({"hovered": true, "pressed": false, "disabled": true})
	var drag_ok := InteractionCuePresenterScript.project_drag_state(true, true)
	var drag_blocked := InteractionCuePresenterScript.project_drag_state(true, false)
	_assert(float(hover.get("glow", 0.0)) > float(idle.get("glow", 0.0)), "hover raises glow affordance")
	_assert(float(pressed.get("scale", 1.0)) < float(hover.get("scale", 1.0)), "press compresses hovered control")
	_assert_eq(disabled.get("cursor", ""), "forbidden", "disabled control reports forbidden cursor")
	_assert(float(disabled.get("alpha", 1.0)) < float(idle.get("alpha", 1.0)), "disabled control is visually dimmer")
	_assert_eq(drag_ok.get("dropState", ""), "valid", "valid drag reports accept state")
	_assert_eq(drag_blocked.get("dropState", ""), "blocked", "invalid drag reports blocked state")
	_assert(str(drag_blocked.get("outlineColor", "")).contains("bf616a"), "invalid drag uses red rejection outline")

# ?ㅽ뻾: verify backpack drag affordance follows the same placement rules as inventory.
func test_backpack_drop_feedback_uses_real_placement_rules() -> void:
	var inventory = InventoryScript.new(8, 8)
	var placed = ArtifactScript.new({"id": "placed_red", "name": "Placed Red", "shape": [[1]], "energyType": "red", "item_type": "drill"})
	var held = ArtifactScript.new({"id": "held_blue", "name": "Held Blue", "shape": [[1, 1]], "energyType": "blue", "item_type": "beacon"})
	inventory.place_artifact(placed, 0, 0)
	_assert_eq(BackpackUIScript.can_drop_artifact(inventory, held, 2, 2), true, "empty space accepts dragged artifact")
	_assert_eq(BackpackUIScript.can_drop_artifact(inventory, held, 0, 0), false, "occupied slot blocks dragged artifact")
	_assert_eq(BackpackUIScript.can_drop_artifact(inventory, held, 7, 7), false, "out of bounds shape blocks dragged artifact")

func test_backpack_hover_fx_stays_off() -> void:
	_assert_eq(BackpackUIScript.slot_hover_fx_enabled(), false, "backpack slots keep hover wobble disabled so inventory readability stays stable")

func test_backpack_drag_feedback_preserves_slot_visuals_while_dragging() -> void:
	var slot := Panel.new()
	var original_self := Color(0.95, 0.90, 0.82, 0.65)
	var original_modulate := Color(1.0, 1.0, 1.0, 1.0)
	slot.self_modulate = original_self
	slot.modulate = original_modulate
	InteractionFXScript.apply_drag_feedback(slot, true, false)
	_assert_eq(slot.self_modulate, original_self, "backpack slot drag feedback keeps the slot background tint unchanged while dragging")
	_assert_eq(slot.modulate.a, original_modulate.a, "backpack slot drag feedback keeps the slot alpha unchanged while dragging")

func test_backpack_drag_feedback_restores_slot_modulate_after_reward_drop() -> void:
	var slot := Panel.new()
	var original := Color(0.95, 0.90, 0.82, 0.65)
	slot.self_modulate = original
	InteractionFXScript.apply_drag_feedback(slot, true, false)
	InteractionFXScript.apply_drag_feedback(slot, false, true)
	_assert_eq(slot.self_modulate, original, "backpack slot drag feedback restores the original slot tint after reward placement")

func test_backpack_drag_feedback_restores_slot_alpha_after_reward_drop() -> void:
	var slot := Panel.new()
	slot.modulate = Color(1.0, 1.0, 1.0, 1.0)
	InteractionFXScript.apply_drag_feedback(slot, true, true)
	InteractionFXScript.apply_drag_feedback(slot, false, true)
	_assert_eq(slot.modulate.a, 1.0, "backpack slot drag feedback resets slot alpha immediately after reward placement")
	_assert_eq(slot.modulate.a, 1.0, "backpack slot drag feedback keeps slot alpha visible after reward placement")

# ?ㅽ뻾: verify hover polish never translates children that are owned by layout containers.
func test_interaction_fx_preserves_container_layout_children() -> void:
	var grid := GridContainer.new()
	var slot := Panel.new()
	grid.add_child(slot)
	var floating := Panel.new()
	_assert_eq(InteractionFXScript.can_translate_control(slot), false, "grid child keeps container-owned position")
	_assert_eq(InteractionFXScript.can_translate_control(floating), true, "free control can use lift translation")

func test_interaction_fx_skips_shader_on_panel_slots() -> void:
	_assert_eq(InteractionFXScript._supports_shader_material(Panel.new()), false, "panel-based slots keep stylebox rendering instead of shader materials")
	_assert_eq(InteractionFXScript._supports_shader_material(Button.new()), true, "buttons still use shader-backed cues")

func test_hold_fire_stops_when_overload_repair_starts() -> void:
	var stopped := MainControllerRuntimeScript.should_continue_hold_fire({
		"phase": "combat",
		"feedback": {"status": "empty_queue"},
		"hud": {"repair": {"active": true}, "queue": {"items": []}}
	}, true)
	var active := MainControllerRuntimeScript.should_continue_hold_fire({
		"phase": "combat",
		"feedback": {"status": "match"},
		"hud": {"repair": {"active": false}, "queue": {"items": ["red"]}}
	}, true)
	_assert_eq(stopped, false, "hold-fire stops once overload repair begins")
	_assert_eq(active, true, "hold-fire continues only while combat can actually keep firing")

func test_combat_clicks_block_while_repair_or_aim_lock_is_active() -> void:
	var blocked := MainControllerRuntimeScript.can_accept_combat_click({
		"phase": "combat",
		"hud": {"repair": {"active": true}, "aim": {"canFire": false}}
	}, "r0c0", [])
	var ready := MainControllerRuntimeScript.can_accept_combat_click({
		"phase": "combat",
		"hud": {"repair": {"active": false}, "aim": {"canFire": true}}
	}, "r0c0", [])
	_assert_eq(blocked, false, "combat clicks stop while overload repair is active")
	_assert_eq(ready, true, "combat clicks resume only when aim can fire again")

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

func test_reward_reveal_overlay_uses_cinematic_hero_contract_and_keeps_legacy_backup() -> void:
	TextCatalogScript.set_locale("en")
	var RewardRevealOverlayScript = load("res://src/ui/RewardRevealOverlay.gd")
	_assert(RewardRevealOverlayScript != null, "fullscreen reward reveal overlay script exists")
	if RewardRevealOverlayScript != null:
		_assert(RewardRevealOverlayScript.has_method("reveal_timing_profile"), "reward reveal overlay exposes timing profile")
		_assert(RewardRevealOverlayScript.has_method("build_presentation_model"), "reward reveal overlay exposes a presentation model helper")
		if RewardRevealOverlayScript.has_method("reveal_timing_profile"):
			var profile = RewardRevealOverlayScript.reveal_timing_profile()
			_assert(float(profile.get("heroHold", 0.0)) >= 0.8, "cinematic reward reveal holds the hero item long enough to read")
			_assert(float(profile.get("fadeOut", 1.0)) <= 0.45, "cinematic reward reveal exits quickly so the reward tray can return promptly")
		if RewardRevealOverlayScript.has_method("build_presentation_model"):
			var presentation = RewardRevealOverlayScript.build_presentation_model([
				{"kind": "Ruby Drill", "rarity": "rare", "payload": {"item_type": "drill", "energy_type": "red"}},
				{"kind": "Azure Beacon", "rarity": "common", "payload": {"item_type": "beacon", "energy_type": "blue"}},
				{"kind": "Apex Crown", "rarity": "legendary", "payload": {"item_type": "relic", "energy_type": "purple"}}
			])
			_assert_eq(str(presentation.get("heroName", "")), "Apex Crown", "presentation model picks the highest-rarity reward as the cinematic hero")
			_assert_eq(int(presentation.get("extraCount", -1)), 2, "presentation model keeps the remaining rewards available for the tray that returns after the cinematic")
	var LegacyRewardRevealScript = load("res://src/ui/legacy/LegacyRewardRevealOverlay.gd")
	_assert(LegacyRewardRevealScript != null, "legacy reward reveal backup script exists")
	if LegacyRewardRevealScript != null and LegacyRewardRevealScript.has_method("reveal_timing_profile"):
		var legacy_profile = LegacyRewardRevealScript.reveal_timing_profile()
		_assert(float(legacy_profile.get("silhouetteHold", 0.0)) >= 1.2, "legacy reveal backup preserves the previous silhouette-hold contract for easy comparison or disposal later")
	TextCatalogScript.set_locale("ko")

func test_reward_reveal_presentation_requires_confirm_and_sorted_reveal_queue() -> void:
	TextCatalogScript.set_locale("en")
	var RewardRevealOverlayScript = load("res://src/ui/RewardRevealOverlay.gd")
	_assert(RewardRevealOverlayScript != null, "reward ceremony overlay script loads for presentation contract")
	if RewardRevealOverlayScript == null or not RewardRevealOverlayScript.has_method("build_presentation_model"):
		TextCatalogScript.set_locale("ko")
		return
	var presentation = RewardRevealOverlayScript.build_presentation_model([
		{"kind": "Apex Crown", "rarity": "legendary", "payload": {"item_type": "relic", "energy_type": "purple"}},
		{"kind": "Dust Charm", "rarity": "common", "payload": {"item_type": "relic", "energy_type": "green"}},
		{"kind": "Ruby Drill", "rarity": "epic", "payload": {"item_type": "drill", "energy_type": "red"}},
		{"kind": "Azure Beacon", "rarity": "rare", "payload": {"item_type": "beacon", "energy_type": "blue"}}
	])
	_assert_eq(bool(presentation.get("requiresConfirm", false)), true, "reward ceremony presentation requires explicit player confirmation before the cinematic can finish")
	_assert_eq(presentation.get("revealOrderNames", []), ["Dust Charm", "Azure Beacon", "Ruby Drill", "Apex Crown"], "reward ceremony reveal order sorts rewards from low rarity to high rarity")
	_assert_eq(presentation.get("revealOrderRarityVfx", []), ["common", "rare", "epic", "legendary"], "reward ceremony uses fixed rarity VFX tiers that match the real reveal order")
	if RewardRevealOverlayScript.has_method("reveal_timing_profile"):
		var timing = RewardRevealOverlayScript.reveal_timing_profile()
		_assert(float(timing.get("countTeaseSmall", 0.0)) >= 2.7, "count tease holds long enough for a 2-second white-hot front-tile climax")
		_assert(float(timing.get("countTeaseStandard", 0.0)) >= 2.9, "standard count tease keeps a longer escalation before the burst")
		_assert(float(timing.get("countTeaseJackpot", 0.0)) >= 3.1, "jackpot count tease gives the strongest quantity beat time to register")
		_assert(float(timing.get("countLockHold", 0.0)) >= 1.6, "count burst/opening has enough time to read as an explosion rather than a quick cut")
		_assert(float(timing.get("revealCommon", 0.0)) >= 3.0, "common artifact reveal keeps at least 3 seconds of anticipation")
		_assert(float(timing.get("revealRare", 0.0)) >= 3.4, "rare artifact reveal gets a longer anticipation beat than common")
		_assert(float(timing.get("revealEpic", 0.0)) >= 4.0, "epic artifact reveal holds around 4 seconds before identity")
		_assert(float(timing.get("revealLegendary", 0.0)) >= 4.6, "legendary artifact reveal approaches the 5-second anticipation ceiling")
		_assert(float(timing.get("revealLegendary", 99.0)) <= 5.0, "legendary artifact reveal stays within the requested 3-5 second range")
	TextCatalogScript.set_locale("ko")

func test_reward_reveal_quantity_tease_uses_three_bands() -> void:
	TextCatalogScript.set_locale("en")
	var RewardRevealOverlayScript = load("res://src/ui/RewardRevealOverlay.gd")
	_assert(RewardRevealOverlayScript != null, "reward ceremony overlay script loads for quantity tease band contract")
	if RewardRevealOverlayScript == null or not RewardRevealOverlayScript.has_method("build_presentation_model"):
		TextCatalogScript.set_locale("ko")
		return
	_assert_eq(str(RewardRevealOverlayScript.build_presentation_model([{"kind": "One", "rarity": "common"}]).get("quantityTeaseBand", "")), "small", "one reward uses the compact 1-2 reward tease band")
	_assert_eq(str(RewardRevealOverlayScript.build_presentation_model([{"kind": "One", "rarity": "common"}, {"kind": "Two", "rarity": "rare"}]).get("quantityTeaseBand", "")), "small", "two rewards still use the compact 1-2 reward tease band")
	_assert_eq(str(RewardRevealOverlayScript.build_presentation_model([{"kind": "One", "rarity": "common"}, {"kind": "Two", "rarity": "rare"}, {"kind": "Three", "rarity": "epic"}]).get("quantityTeaseBand", "")), "standard", "three rewards use the dedicated middle tease band")
	_assert_eq(str(RewardRevealOverlayScript.build_presentation_model([{"kind": "One", "rarity": "common"}, {"kind": "Two", "rarity": "rare"}, {"kind": "Three", "rarity": "epic"}, {"kind": "Four", "rarity": "legendary"}]).get("quantityTeaseBand", "")), "jackpot", "four rewards use the 4-5 jackpot tease band")
	_assert_eq(str(RewardRevealOverlayScript.build_presentation_model([{"kind": "One", "rarity": "common"}, {"kind": "Two", "rarity": "rare"}, {"kind": "Three", "rarity": "epic"}, {"kind": "Four", "rarity": "legendary"}, {"kind": "Five", "rarity": "mythic"}]).get("quantityTeaseBand", "")), "jackpot", "five rewards also use the 4-5 jackpot tease band")
	TextCatalogScript.set_locale("ko")

func test_reward_reveal_count_tease_hides_exact_count_and_uses_band_preview() -> void:
	var RewardRevealOverlayScript = load("res://src/ui/RewardRevealOverlay.gd")
	_assert(RewardRevealOverlayScript != null, "reward ceremony overlay script loads for count tease concealment contract")
	if RewardRevealOverlayScript == null:
		return
	_assert(RewardRevealOverlayScript.has_method("count_tease_preview_model"), "reward ceremony overlay exposes a count tease preview helper")
	if not RewardRevealOverlayScript.has_method("count_tease_preview_model"):
		return
	var one = RewardRevealOverlayScript.count_tease_preview_model(1)
	var two = RewardRevealOverlayScript.count_tease_preview_model(2)
	var three = RewardRevealOverlayScript.count_tease_preview_model(3)
	var four = RewardRevealOverlayScript.count_tease_preview_model(4)
	var five = RewardRevealOverlayScript.count_tease_preview_model(5)
	_assert_eq(bool(one.get("exactCountVisible", true)), false, "count tease keeps the exact reward count hidden for a single reward")
	_assert_eq(bool(two.get("exactCountVisible", true)), false, "count tease keeps the exact reward count hidden for the 1-2 reward band")
	_assert_eq(bool(three.get("exactCountVisible", true)), false, "count tease keeps the exact reward count hidden for the 3 reward band")
	_assert_eq(int(one.get("previewLidCount", 0)), 1, "count tease uses a single sealed chamber silhouette instead of exposing exact reward slots")
	_assert_eq(int(two.get("previewLidCount", 0)), 1, "two rewards still keep a single sealed chamber silhouette during tease")
	_assert_eq(int(three.get("previewLidCount", 0)), 1, "three rewards still keep a single sealed chamber silhouette during tease")
	_assert_eq(int(four.get("previewLidCount", 0)), 1, "four rewards still keep a single sealed chamber silhouette during tease")
	_assert_eq(int(five.get("previewLidCount", 0)), 1, "five rewards still keep a single sealed chamber silhouette during tease")
	_assert_eq(int(one.get("visibleRewardTokenCount", -1)), 0, "count tease never draws reward tokens before the burst")
	_assert_eq(int(two.get("visibleRewardTokenCount", -1)), 0, "two rewards still hide all reward tokens during tease")
	_assert_eq(int(three.get("visibleRewardTokenCount", -1)), 0, "three rewards do not leak the exact count through three visible lights")
	_assert_eq(int(four.get("visibleRewardTokenCount", -1)), 0, "four rewards do not leak the exact count before the burst")
	_assert_eq(int(five.get("visibleRewardTokenCount", -1)), 0, "five rewards do not leak the exact count before the burst")
	_assert_eq(str(one.get("countClueStyle", "")), "single_terrain_lid_charge", "count tease uses the terrain lid as the only visible clue")
	_assert_eq(str(three.get("countClueStyle", "")), "single_terrain_lid_charge", "middle-band count tease still uses one charged terrain lid")
	_assert_eq(str(five.get("countClueStyle", "")), "single_terrain_lid_charge", "jackpot-band count tease still uses one charged terrain lid")

func test_reward_reveal_mined_lid_pops_from_terrain_before_count_burst() -> void:
	var RewardRevealOverlayScript = load("res://src/ui/RewardRevealOverlay.gd")
	_assert(RewardRevealOverlayScript != null, "reward ceremony overlay script loads for mined-lid motion contract")
	if RewardRevealOverlayScript == null:
		return
	_assert(RewardRevealOverlayScript.has_method("center_lid_layout_model"), "reward ceremony overlay exposes center lid layout model")
	_assert(RewardRevealOverlayScript.has_method("mined_lid_motion_model"), "reward ceremony overlay exposes mined lid motion model")
	_assert(RewardRevealOverlayScript.has_method("count_burst_model"), "reward ceremony overlay exposes count burst model")
	_assert(RewardRevealOverlayScript.has_method("count_burst_animation_model"), "reward ceremony overlay exposes count burst animation model")
	var closed_lid := Rect2()
	if RewardRevealOverlayScript.has_method("center_lid_layout_model"):
		var layout = RewardRevealOverlayScript.center_lid_layout_model(Vector2(1440.0, 900.0))
		closed_lid = layout.get("closedLidRect", Rect2())
		_assert(float(layout.get("aspectRatio", 0.0)) > 5.0, "center lid keeps the wide terrain tile aspect instead of collapsing into a tall plaque")
		_assert(closed_lid.size.x > closed_lid.size.y * 5.0, "center lid remains a long horizontal tile so the bottom edge does not look clipped")
	if RewardRevealOverlayScript.has_method("mined_lid_motion_model"):
		var source_rect := Rect2(Vector2(260.0, 620.0), Vector2(96.0, 58.0))
		var motion = RewardRevealOverlayScript.mined_lid_motion_model(source_rect, Vector2(1440.0, 900.0), 0.35, 3)
		var climax_motion = RewardRevealOverlayScript.mined_lid_motion_model(source_rect, Vector2(1440.0, 900.0), 0.86, 3)
		var final_motion = RewardRevealOverlayScript.mined_lid_motion_model(source_rect, Vector2(1440.0, 900.0), 1.0, 3)
		_assert_eq(str(motion.get("texturePath", "")), "res://resources/UI/tile/tile_panel_nobg.png", "mined lid uses the terrain tile texture as the popped source")
		_assert_eq(str(motion.get("sourceRole", "")), "terrain_lid_clone", "mined lid is a cloned terrain lid, not the real battlefield tile")
		_assert_eq(bool(motion.get("preservesBattlefield", false)), true, "mined lid animation does not move the real battlefield UI")
		_assert_eq(bool(motion.get("exactCountVisible", true)), false, "mined lid motion hides exact count while charging")
		_assert_eq(bool(motion.get("identityVisible", true)), false, "mined lid motion hides item identity while charging")
		_assert(float(motion.get("sparkRate", 0.0)) > float(motion.get("baseSparkRate", 999.0)), "mined lid spark rate accelerates during charge")
		_assert(float(motion.get("currentRect", Rect2()).position.y) < source_rect.position.y, "mined lid moves upward from the terrain toward the center")
		_assert_eq(str(motion.get("drawOrder", "")), "halo_behind_lid_front_flash", "mined lid draw order keeps the halo behind and redraws the terrain tile in front")
		_assert(float(climax_motion.get("frontTileFlashAlpha", 0.0)) >= 0.75, "count tease climax makes the tile image itself flash white-hot")
		_assert(float(final_motion.get("highlightHoldSeconds", 0.0)) >= 2.0, "count tease model reserves at least two seconds for the high-intensity hold")
		_assert_eq(final_motion.get("targetRect", Rect2()), closed_lid, "count tease target rect matches the shared closed lid layout")
	if RewardRevealOverlayScript.has_method("count_burst_model"):
		var burst = RewardRevealOverlayScript.count_burst_model(4)
		_assert_eq(bool(burst.get("exactCountVisible", false)), true, "count burst is the first state allowed to show exact count")
		_assert_eq(int(burst.get("rewardTokenCount", 0)), 4, "count burst reveals the real reward count")
		_assert_eq(str(burst.get("quantityBand", "")), "jackpot", "count burst keeps the 4-5 jackpot band")
		var overflow_burst = RewardRevealOverlayScript.count_burst_model(6)
		_assert_eq(int(overflow_burst.get("rewardTokenCount", 0)), 6, "count burst keeps the real count even if a future table exceeds five rewards")
		_assert_eq(int(overflow_burst.get("visualTokenCount", 0)), 5, "count burst clamps only the visual token layout to five")
	if RewardRevealOverlayScript.has_method("count_burst_animation_model"):
		var burst_start = RewardRevealOverlayScript.count_burst_animation_model(Vector2(1440.0, 900.0), 0.0, 3)
		var burst_mid = RewardRevealOverlayScript.count_burst_animation_model(Vector2(1440.0, 900.0), 0.65, 3)
		_assert_eq(burst_start.get("closedLidRect", Rect2()), closed_lid, "count burst starts from the same closed lid rect as the tease")
		_assert_eq(float(burst_start.get("orbRevealAlpha", 1.0)), 0.0, "orbs are still hidden at the very start of count burst")
		_assert_eq(str(burst_mid.get("openingStyle", "")), "upward_cap_pop_explosion", "count burst pops the lid upward instead of opening as side doors")
		_assert(float(burst_mid.get("lidCapOffset", Vector2.ZERO).y) < -float(closed_lid.size.y), "popped lid cap travels upward far enough to read as flying off")
		_assert(absf(float(burst_mid.get("lidCapRotationDegrees", 0.0))) >= 18.0, "popped lid cap rotates while flying away")
		_assert(int(burst_mid.get("fragmentCount", 0)) >= 12, "count burst throws enough fragments to feel like a seal explosion")
		_assert(float(burst_mid.get("orbRevealAlpha", 0.0)) > 0.4, "orbs become visible while the lid is popping away")
		_assert(float(burst_mid.get("orbRiseDistance", 0.0)) > 0.0, "orbs rise out of the lid instead of appearing statically in place")
		_assert_eq(str(burst_mid.get("orbMotionStyle", "")), "buoyant_arc_silhouette", "reward orb silhouettes use a buoyant arc instead of a static popup")

func test_reward_reveal_cards_conceal_identity_then_use_fixed_rarity_bursts() -> void:
	var RewardRevealOverlayScript = load("res://src/ui/RewardRevealOverlay.gd")
	_assert(RewardRevealOverlayScript != null, "reward ceremony overlay script loads for card reveal phase contract")
	if RewardRevealOverlayScript == null:
		return
	_assert(RewardRevealOverlayScript.has_method("card_reveal_phase_model"), "reward ceremony overlay exposes card reveal phase model")
	if not RewardRevealOverlayScript.has_method("card_reveal_phase_model"):
		return
	var common_charge = RewardRevealOverlayScript.card_reveal_phase_model("common", 0.32, false, 4)
	var legendary_charge = RewardRevealOverlayScript.card_reveal_phase_model("legendary", 0.32, false, 4)
	var nearly_full_charge = RewardRevealOverlayScript.card_reveal_phase_model("rare", 0.95, false, 1)
	var epic_reveal = RewardRevealOverlayScript.card_reveal_phase_model("epic", 1.0, true, 0)
	var legendary_reveal = RewardRevealOverlayScript.card_reveal_phase_model("legendary", 1.0, true, 4)
	_assert_eq(bool(common_charge.get("identityVisible", true)), false, "card charge phase hides reward identity behind white light")
	_assert_eq(str(common_charge.get("cardFace", "")), "white_sealed_card", "card charge phase uses a white sealed card face")
	_assert_eq(bool(common_charge.get("rarityVisibleBeforeReveal", true)), false, "card charge phase hides rarity before reveal")
	_assert_eq(str(common_charge.get("sealedAccentTier", "")), "neutral_white", "common hidden card uses neutral white accent")
	_assert_eq(str(legendary_charge.get("sealedAccentTier", "")), "neutral_white", "legendary hidden card also uses neutral white accent")
	_assert(float(common_charge.get("shakeStrength", 0.0)) > 0.0, "card charge phase shakes before revealing identity")
	_assert_eq(bool(nearly_full_charge.get("identityVisible", true)), false, "artifact identity stays hidden until the front progress bar is fully complete")
	_assert(float(nearly_full_charge.get("progressFill", 0.0)) >= 0.94, "front progress bar can be nearly full while identity is still hidden")
	_assert(float(legendary_charge.get("shakeStrength", 0.0)) > float(common_charge.get("shakeStrength", 0.0)), "higher rarity sealed silhouettes use more energetic anticipation motion")
	_assert_eq(bool(epic_reveal.get("identityVisible", false)), true, "card reveal phase makes the reward identity readable")
	_assert_eq(str(epic_reveal.get("rarityBurstTier", "")), "epic", "epic reveal uses the epic burst tier")
	_assert_eq(str(legendary_reveal.get("rarityBurstTier", "")), "legendary", "legendary reveal uses the legendary burst tier")
	_assert_eq(bool(legendary_reveal.get("usesQueuePositionForIntensity", true)), false, "rarity burst intensity is fixed by rarity, not by queue position")
	_assert(float(legendary_reveal.get("burstStrength", 0.0)) > float(epic_reveal.get("burstStrength", 0.0)), "legendary reveal is stronger than epic because of rarity")
	_assert(RewardRevealOverlayScript.has_method("queue_marker_phase_model"), "reward ceremony overlay exposes queue marker phase model")
	if RewardRevealOverlayScript.has_method("queue_marker_phase_model"):
		var future_marker = RewardRevealOverlayScript.queue_marker_phase_model("legendary", false, false, false)
		var current_hidden_marker = RewardRevealOverlayScript.queue_marker_phase_model("epic", false, true, false)
		var revealed_marker = RewardRevealOverlayScript.queue_marker_phase_model("rare", true, false, true)
		_assert_eq(bool(future_marker.get("rarityVisible", true)), false, "future queue markers hide rarity before their reveal")
		_assert_eq(str(future_marker.get("accentTier", "")), "neutral_white", "future queue markers use neutral white accent")
		_assert_eq(bool(current_hidden_marker.get("rarityVisible", true)), false, "current hidden queue marker also hides rarity")
		_assert_eq(str(current_hidden_marker.get("accentTier", "")), "neutral_white", "current hidden queue marker uses neutral white accent")
		_assert_eq(bool(revealed_marker.get("rarityVisible", false)), true, "revealed queue markers may show their actual rarity")
		_assert_eq(str(revealed_marker.get("accentTier", "")), "rare", "revealed queue markers use the actual rarity accent")

func test_reward_reveal_result_stage_uses_clean_layout_and_distinct_rarity_profiles() -> void:
	var RewardRevealOverlayScript = load("res://src/ui/RewardRevealOverlay.gd")
	_assert(RewardRevealOverlayScript != null, "reward ceremony overlay script loads for result-stage visual profile contract")
	if RewardRevealOverlayScript == null:
		return
	_assert(RewardRevealOverlayScript.has_method("reveal_visual_profile"), "reward ceremony overlay exposes a deterministic rarity visual profile helper")
	_assert(RewardRevealOverlayScript.has_method("reward_card_layout_metrics"), "reward ceremony overlay exposes reward card layout metrics for clipping regression coverage")
	if RewardRevealOverlayScript.has_method("reveal_visual_profile"):
		var common = RewardRevealOverlayScript.reveal_visual_profile("common")
		var epic = RewardRevealOverlayScript.reveal_visual_profile("epic")
		var legendary = RewardRevealOverlayScript.reveal_visual_profile("legendary")
		var mythic = RewardRevealOverlayScript.reveal_visual_profile("mythic")
		_assert_eq(bool(common.get("showBackdropLid", true)), false, "result-stage common rewards no longer keep a giant excavation-lid texture behind the main card")
		_assert_eq(bool(epic.get("showBackdropLid", true)), false, "result-stage epic rewards also use the same clean backdrop policy")
		_assert(float(epic.get("auraStrength", 0.0)) > float(common.get("auraStrength", 0.0)), "epic rewards use a stronger aura than common rewards")
		_assert(int(epic.get("sparkCount", 0)) > int(common.get("sparkCount", 0)), "epic rewards spawn a richer particle package than common rewards")
		_assert(float(epic.get("frameGlowAlpha", 0.0)) > float(common.get("frameGlowAlpha", 0.0)), "epic rewards keep a brighter frame glow than common rewards")
		_assert(float(common.get("burstStrength", 0.0)) >= 0.45, "even common rewards still get a clearly readable burst")
		_assert(int(common.get("beamCount", 0)) >= 6, "common rewards still throw a visible beam package so disappointment reads on screen")
		_assert(int(legendary.get("beamCount", 0)) > int(epic.get("beamCount", 0)), "legendary rewards use more burst beams than epic rewards")
		_assert(float(legendary.get("screenWashAlpha", 0.0)) > float(common.get("screenWashAlpha", 0.0)), "legendary rewards push a stronger screen wash than common rewards")
		_assert(int(mythic.get("shockwaveCount", 0)) > int(legendary.get("shockwaveCount", 0)), "mythic rewards layer more shockwaves than legendary rewards")
	if RewardRevealOverlayScript.has_method("reward_card_layout_metrics"):
		var layout = RewardRevealOverlayScript.reward_card_layout_metrics(Vector2(1440.0, 900.0))
		_assert(float(layout.get("cardWidth", 0.0)) >= 540.0, "reward result card widens enough to keep localized item names from clipping")
		_assert(float(layout.get("textWidth", 0.0)) >= 300.0, "reward result card reserves a dedicated text column wide enough for rarity and item labels")
		_assert(float(layout.get("textLeft", 0.0)) >= float(layout.get("iconRight", 0.0)) + 28.0, "reward text column begins after the icon column with stable spacing")
		_assert(float(layout.get("supportY", 0.0)) > float(layout.get("nameY", 0.0)), "support text renders below the reward name instead of overlapping it")
		_assert(float(layout.get("progressY", 0.0)) > float(layout.get("cardBottom", 0.0)), "reveal progress text sits below the main card instead of colliding with it")
		_assert(float(layout.get("frontProgressY", 0.0)) > float(layout.get("cardBottom", 0.0)), "front reveal progress bar sits under the card as the primary anticipation meter")
	_assert(RewardRevealOverlayScript.has_method("reveal_queue_layout_policy"), "reward ceremony overlay exposes a layout policy for removing the rear queue card strip")
	if RewardRevealOverlayScript.has_method("reveal_queue_layout_policy"):
		var policy = RewardRevealOverlayScript.reveal_queue_layout_policy()
		_assert_eq(bool(policy.get("backgroundCardListVisible", true)), false, "individual artifact reveal removes the rear full-card silhouette list")
		_assert_eq(bool(policy.get("frontProgressBarVisible", false)), true, "individual artifact reveal uses the front progress bar as the main anticipation cue")
		_assert_eq(bool(policy.get("progressTextVisible", false)), true, "individual artifact reveal keeps current / total progress text")

func test_reward_reveal_safe_area_models_stay_inside_canvas() -> void:
	var RewardRevealOverlayScript = load("res://src/ui/RewardRevealOverlay.gd")
	_assert(RewardRevealOverlayScript != null, "reward ceremony overlay script loads for safe-area layout coverage")
	if RewardRevealOverlayScript == null:
		return
	_assert(RewardRevealOverlayScript.has_method("center_lid_layout_model"), "reward ceremony overlay exposes center lid layout for safe-area checks")
	_assert(RewardRevealOverlayScript.has_method("reward_card_layout_metrics"), "reward ceremony overlay exposes card layout metrics for safe-area checks")
	if not RewardRevealOverlayScript.has_method("center_lid_layout_model") or not RewardRevealOverlayScript.has_method("reward_card_layout_metrics"):
		return
	for canvas_size in [Vector2(1280.0, 720.0), Vector2(1440.0, 900.0), Vector2(960.0, 540.0), Vector2(854.0, 480.0)]:
		var safe_layout = RewardRevealOverlayScript.overlay_safe_layout_model(canvas_size) if RewardRevealOverlayScript.has_method("overlay_safe_layout_model") else {}
		var lid_layout = RewardRevealOverlayScript.center_lid_layout_model(canvas_size)
		var lid_rect: Rect2 = lid_layout.get("closedLidRect", Rect2())
		_assert(lid_rect.position.x >= 24.0, "reward reveal lid stays away from the left screen edge for canvas %s" % str(canvas_size))
		_assert(lid_rect.end.x <= canvas_size.x - 24.0, "reward reveal lid stays away from the right screen edge for canvas %s" % str(canvas_size))
		_assert(lid_rect.position.y >= canvas_size.y * 0.25, "reward reveal lid remains below the headline band for canvas %s" % str(canvas_size))
		_assert(lid_rect.end.y <= canvas_size.y * 0.70, "reward reveal lid remains above the lower progress band for canvas %s" % str(canvas_size))
		var metrics = RewardRevealOverlayScript.reward_card_layout_metrics(canvas_size)
		var card_size := Vector2(float(metrics.get("cardWidth", 0.0)), float(metrics.get("cardHeight", 0.0))) * 1.06
		var card_rect := Rect2(Vector2(canvas_size.x * 0.50, float(metrics.get("cardCenterY", canvas_size.y * 0.57))) - (card_size * 0.5), card_size)
		_assert(card_rect.position.x >= 24.0, "reward reveal card keeps a left safe margin for canvas %s" % str(canvas_size))
		_assert(card_rect.end.x <= canvas_size.x - 24.0, "reward reveal card keeps a right safe margin for canvas %s" % str(canvas_size))
		_assert(card_rect.position.y >= canvas_size.y * 0.28, "reward reveal card stays below the headline/subtitle block for canvas %s" % str(canvas_size))
		_assert(card_rect.end.y <= float(safe_layout.get("confirmPromptY", canvas_size.y * 0.90)) - 24.0, "reward reveal card stays above the confirm prompt lane for canvas %s" % str(canvas_size))
		var front_progress_y := float(metrics.get("frontProgressY", 0.0))
		var progress_y := float(metrics.get("progressY", 0.0))
		_assert(front_progress_y >= card_rect.end.y, "reward reveal front progress bar stays below the card for canvas %s" % str(canvas_size))
		_assert(front_progress_y + 10.0 <= float(safe_layout.get("confirmPromptY", canvas_size.y * 0.90)) - 16.0, "reward reveal front progress bar stays inside the lower safe band for canvas %s" % str(canvas_size))
		_assert(progress_y + float(metrics.get("progressFontSize", 18)) <= float(safe_layout.get("confirmPromptY", canvas_size.y * 0.90)) - 12.0, "reward reveal progress text stays above the bottom prompt lane for canvas %s" % str(canvas_size))

func test_reward_reveal_overlay_safe_layout_caps_effect_radii() -> void:
	var RewardRevealOverlayScript = load("res://src/ui/RewardRevealOverlay.gd")
	_assert(RewardRevealOverlayScript != null, "reward ceremony overlay script loads for overlay safe-layout coverage")
	if RewardRevealOverlayScript == null:
		return
	_assert(RewardRevealOverlayScript.has_method("overlay_safe_layout_model"), "reward ceremony overlay exposes a shared safe-layout model for effect containment")
	if not RewardRevealOverlayScript.has_method("overlay_safe_layout_model"):
		return
	for canvas_size in [Vector2(1280.0, 720.0), Vector2(1440.0, 900.0)]:
		var safe_layout = RewardRevealOverlayScript.overlay_safe_layout_model(canvas_size)
		var focus_center: Vector2 = safe_layout.get("focusCenter", canvas_size * 0.5)
		var safe_margin := float(safe_layout.get("safeMargin", 24.0))
		var focus_radius := float(safe_layout.get("focusMaxRadius", 0.0))
		var allowed_radius := minf(minf(focus_center.x, canvas_size.x - focus_center.x), minf(focus_center.y, canvas_size.y - focus_center.y)) - safe_margin
		_assert(focus_radius <= allowed_radius + 0.5, "reward reveal focus radius stays inside the screen-safe area for canvas %s" % str(canvas_size))
		_assert(float(safe_layout.get("headlineTitleY", 0.0)) >= safe_margin, "reward reveal title stays below the top safe margin for canvas %s" % str(canvas_size))
		_assert(float(safe_layout.get("headlineSubtitleY", 0.0)) > float(safe_layout.get("headlineTitleY", 0.0)), "reward reveal subtitle stays below the title for canvas %s" % str(canvas_size))
		_assert(float(safe_layout.get("confirmPromptY", canvas_size.y)) <= canvas_size.y - safe_margin, "reward reveal confirm prompt stays above the bottom safe margin for canvas %s" % str(canvas_size))
		var lid_layout = RewardRevealOverlayScript.center_lid_layout_model(canvas_size)
		var lid_rect: Rect2 = lid_layout.get("closedLidRect", Rect2())
		_assert_close(lid_rect.get_center().x, focus_center.x, 0.5, "reward reveal lid center aligns with the shared focus center on x for canvas %s" % str(canvas_size))
		_assert_close(lid_rect.get_center().y, focus_center.y, 0.5, "reward reveal lid center aligns with the shared focus center on y for canvas %s" % str(canvas_size))

func test_reward_reveal_quantity_slots_center_even_pairs() -> void:
	var RewardRevealOverlayScript = load("res://src/ui/RewardRevealOverlay.gd")
	_assert(RewardRevealOverlayScript != null, "reward ceremony overlay script loads for quantity-slot centering coverage")
	if RewardRevealOverlayScript == null:
		return
	var overlay = RewardRevealOverlayScript.new()
	var rects: Array = overlay.call("_quantity_slot_rects", 2, Vector2(1280.0, 720.0), Vector2(68.0, 68.0), 320.0)
	_assert_eq(rects.size(), 2, "reward reveal quantity slot helper returns two rects for the two-reward burst")
	if rects.size() == 2:
		var left_rect: Rect2 = rects[0]
		var right_rect: Rect2 = rects[1]
		var midpoint_x := (left_rect.get_center().x + right_rect.get_center().x) * 0.5
		_assert_close(midpoint_x, 640.0, 0.5, "reward reveal two-slot burst stays centered on the canvas midpoint")
	overlay.free()

func test_reward_ceremony_step_contract_and_node_select_color_gate() -> void:
	var MainControllerScript = load("res://src/MainControllerRuntime.gd")
	_assert(MainControllerScript != null, "main controller runtime loads for reward ceremony step contract")
	if MainControllerScript != null:
		_assert(MainControllerScript.has_method("reward_presentation_step_sequence"), "main controller runtime exposes reward ceremony step sequencing")
		if MainControllerScript.has_method("reward_presentation_step_sequence"):
			_assert_eq(MainControllerScript.reward_presentation_step_sequence(), ["count_tease", "count_lock", "reveal_queue", "tray_review"], "reward ceremony steps progress through count tease, count lock, reveal queue, and tray review")
	var stage_one_layout := PhaseLayoutPresenterScript.project({"phase": "node_select", "stageIndex": 0, "maxStages": 5}, false)
	var stage_two_layout := PhaseLayoutPresenterScript.project({"phase": "node_select", "stageIndex": 1, "maxStages": 5}, false)
	_assert_eq(bool(stage_one_layout.get("allowStartColorSelection", false)), true, "stage one node select keeps the starter color picker visible")
	_assert_eq(bool(stage_two_layout.get("allowStartColorSelection", true)), false, "stage two node select hides the starter color picker contractually")
	var node_map_scene = NodeMapSceneScript.new()
	node_map_scene.render({
		"stageText": "Stage 2",
		"selectedColor": "red",
		"loadoutColors": ["red", "blue", "purple", "green"],
		"allowStartColorSelection": false,
		"cards": []
	})
	_assert_eq(node_map_scene.loadout_color_count(), 0, "node map scene does not render starter color buttons when the contract disables them")
	node_map_scene.free()

# 실행: verify battlefield cells keep the compact pre-M4 terrain aspect ratio.
# 실행: append a failure when condition is false.
func test_reward_ceremony_policy_is_single_source_for_step_gates() -> void:
	_assert_eq(RewardCeremonyPolicyScript.step_sequence(), ["count_tease", "count_lock", "reveal_queue", "tray_review"], "reward ceremony policy owns the exact step sequence")
	_assert_eq(RewardCeremonyPolicyScript.is_active_step("count_tease"), true, "count tease is an active ceremony step")
	_assert_eq(RewardCeremonyPolicyScript.is_active_step("count_lock"), true, "count lock is an active ceremony step")
	_assert_eq(RewardCeremonyPolicyScript.is_active_step("reveal_queue"), true, "reveal queue is an active ceremony step")
	_assert_eq(RewardCeremonyPolicyScript.is_active_step("tray_review"), false, "tray review reopens reward interaction")
	_assert_eq(RewardCeremonyPolicyScript.is_active_scene({"phase": "reward_loot", "rewardPresentationStep": "count_lock"}), true, "reward loot count lock scene blocks reward tray interaction")
	_assert_eq(RewardCeremonyPolicyScript.is_active_scene({"phase": "reward_loot", "rewardPresentationStep": "tray_review"}), false, "tray review scene stops blocking reward tray interaction")
	_assert_eq(RewardCeremonyPolicyScript.allow_start_color_selection({"phase": "node_select", "stageIndex": 0}), true, "policy allows starter color selection only on stage one")
	_assert_eq(RewardCeremonyPolicyScript.allow_start_color_selection({"phase": "node_select", "stageIndex": 1}), false, "policy blocks starter color selection after stage one")

func test_reward_reveal_cancel_suppresses_done_callback() -> void:
	var RewardRevealOverlayScript = load("res://src/ui/RewardRevealOverlay.gd")
	_assert(RewardRevealOverlayScript != null, "reward ceremony overlay script loads for cancel contract")
	if RewardRevealOverlayScript == null:
		return
	reward_reveal_cancel_done_calls = 0
	var overlay = RewardRevealOverlayScript.new()
	_assert(overlay.has_method("cancel_reveal"), "reward ceremony overlay exposes a cancel API")
	if not overlay.has_method("cancel_reveal"):
		overlay.free()
		return
	overlay.size = Vector2(1440.0, 900.0)
	overlay.start_reveal(
		[{"kind": "Dust Charm", "rarity": "common", "payload": {"item_type": "relic", "energy_type": "green"}}],
		Callable(self, "_ignore_reward_reveal_step_for_cancel_contract"),
		Callable(self, "_record_reward_reveal_done_for_cancel_contract"),
		Rect2(Vector2(260.0, 620.0), Vector2(96.0, 58.0))
	)
	overlay.cancel_reveal()
	_assert_eq(reward_reveal_cancel_done_calls, 0, "canceling reward reveal does not call the completion callback")
	_assert_eq(bool(overlay.visible), false, "canceling reward reveal hides the overlay")
	_assert_eq(bool(overlay.is_revealing), false, "canceling reward reveal clears the active reveal state")
	overlay.free()

func _record_reward_reveal_done_for_cancel_contract() -> void:
	reward_reveal_cancel_done_calls += 1

func _ignore_reward_reveal_step_for_cancel_contract(_step: String) -> void:
	pass

func _assert(condition: bool, msg: String) -> void:
	if not condition:
		failures.append(msg)

# 실행: append a deterministic equality failure when values differ.
func _assert_eq(actual: Variant, expected: Variant, msg: String) -> void:
	if actual != expected:
		failures.append("%s: expected %s, got %s" % [msg, str(expected), str(actual)])

func _assert_close(actual: float, expected: float, tolerance: float, msg: String) -> void:
	if absf(actual - expected) > tolerance:
		failures.append("%s: expected %.4f, got %.4f" % [msg, expected, actual])
