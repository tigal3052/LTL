extends "res://src/ui/main_view/MainViewRuntimeState.gd"
# 계약: main UI facade keeps the controller-facing view API while feature helpers own large runtime responsibilities.
# 실행: delegate lifecycle, render, layout, panel, feedback, and backpack calls to focused helpers.
# 怨꾩빟: keep the controller-facing main view API while extracted helpers own feature-sized runtime work.
# ?ㅽ뻾: delegate lifecycle, render, layout, panel, feedback, and backpack calls to focused helpers.
const BackpackPinLayoutPolicyScript = preload("res://src/ui/presenters/BackpackPinLayoutPolicy.gd")
const MainViewRewardRuntimeScript = preload("res://src/ui/main_view/MainViewRewardRuntime.gd")
const MainViewPresentationRuntimeScript = preload("res://src/ui/main_view/MainViewPresentationRuntime.gd")
const MainViewRewardLayoutRuntimeScript = preload("res://src/ui/main_view/MainViewRewardLayoutRuntime.gd")
const MainViewPageShellRuntimeScript = preload("res://src/ui/main_view/MainViewPageShellRuntime.gd")
const MainViewAppShellRuntimeScript = preload("res://src/ui/main_view/MainViewAppShellRuntime.gd")
const MainViewSceneRuntimeScript = preload("res://src/ui/main_view/MainViewSceneRuntime.gd")
const MainViewPanelsRuntimeScript = preload("res://src/ui/main_view/MainViewPanelsRuntime.gd")
const MainViewLocaleRuntimeScript = preload("res://src/ui/main_view/MainViewLocaleRuntime.gd")
const MainViewChromeRuntimeScript = preload("res://src/ui/main_view/MainViewChromeRuntime.gd")
const MainViewBackpackRuntimeScript = preload("res://src/ui/main_view/MainViewBackpackRuntime.gd")
const MainViewFeedbackRuntimeScript = preload("res://src/ui/main_view/MainViewFeedbackRuntime.gd")
const MainViewLifecycleRuntimeScript = preload("res://src/ui/main_view/MainViewLifecycleRuntime.gd")
static func node_select_backpack_width_for_row(row_size: Vector2, map_min_width: float) -> float:
	return MainViewBackpackRuntimeScript.node_select_backpack_width_for_row(row_size, map_min_width)
static func top_content_backpack_horizontal_flags() -> int:
	return MainViewBackpackRuntimeScript.top_content_backpack_horizontal_flags()
static func top_content_side_horizontal_flags() -> int:
	return MainViewBackpackRuntimeScript.top_content_side_horizontal_flags()
static func top_content_backpack_slot_extent_for_height(target_height: float) -> float:
	return BackpackPinLayoutPolicyScript.top_content_slot_extent_for_height(target_height)
static func top_content_backpack_pin_side_outset_for_height(target_height: float) -> float:
	return BackpackPinLayoutPolicyScript.top_content_side_outset_for_height(target_height)
static func top_content_backpack_width_for_height(target_height: float) -> float:
	return BackpackPinLayoutPolicyScript.top_content_width_for_height(target_height)
static func top_content_backpack_ratio_for_height(target_height: float) -> float:
	return BackpackPinLayoutPolicyScript.top_content_ratio_for_height(target_height)
static func resolved_top_content_backpack_height(row_height: float, min_row_height: float, _current_backpack_height: float) -> float:
	return BackpackPinLayoutPolicyScript.resolved_top_content_height(row_height, min_row_height)
static func popup_overlay_z_index() -> int:
	return POPUP_OVERLAY_Z_INDEX
static func reward_reveal_overlay_z_index() -> int:
	return REWARD_REVEAL_OVERLAY_Z_INDEX
func _ready() -> void:
	MainViewLifecycleRuntimeScript.ready(self)
func _apply_shared_split_layout_text_policies() -> void:
	MainViewLifecycleRuntimeScript.apply_shared_split_layout_text_policies(self)
func _apply_wrapping_label_policy(label: Label) -> void:
	MainViewLifecycleRuntimeScript.apply_wrapping_label_policy(label)
func _apply_wrapping_rich_text_policy(label: RichTextLabel) -> void:
	MainViewLifecycleRuntimeScript.apply_wrapping_rich_text_policy(label)
func _notification(what: int) -> void:
	MainViewLifecycleRuntimeScript.handle_notification(self, what)
func _queue_viewport_shell_sync() -> void:
	MainViewLifecycleRuntimeScript.queue_viewport_shell_sync(self)
func _sync_viewport_shell_bounds() -> void:
	MainViewLifecycleRuntimeScript.sync_viewport_shell_bounds(self)
func _input(event: InputEvent) -> void:
	MainViewLifecycleRuntimeScript.input(self, event)
func _unhandled_input(event: InputEvent) -> void:
	MainViewLifecycleRuntimeScript.unhandled_input(self, event)
func setup_settings(shake_enabled: bool, is_fullscreen: bool, accessibility_state: Dictionary = {}) -> void:
	MainViewPanelsRuntimeScript.setup_settings(self, shake_enabled, is_fullscreen, accessibility_state)
func setup_backpack_slots() -> void:
	MainViewBackpackRuntimeScript.setup_backpack_slots(self)
func _create_shared_backpack() -> void:
	MainViewBackpackRuntimeScript.create_shared_backpack(self)
func _connect_shared_backpack_signals() -> void:
	MainViewBackpackRuntimeScript.connect_shared_backpack_signals(self)
func render_backpack(inventory) -> void:
	MainViewBackpackRuntimeScript.render_backpack(self, inventory)
func update_backpack_ghost(artifact) -> void:
	MainViewBackpackRuntimeScript.update_backpack_ghost(self, artifact)
func toggle_settings() -> void:
	MainViewPanelsRuntimeScript.toggle_settings(self)
func set_settings_visible(val: bool) -> void:
	MainViewPanelsRuntimeScript.set_settings_visible(self, val)
func is_settings_visible() -> bool:
	return MainViewPanelsRuntimeScript.is_settings_visible(self)
func toggle_shop() -> void:
	MainViewPanelsRuntimeScript.toggle_shop(self)
func set_shop_visible(val: bool) -> void:
	MainViewPanelsRuntimeScript.set_shop_visible(self, val)
func is_shop_visible() -> bool:
	return MainViewPanelsRuntimeScript.is_shop_visible(self)
func toggle_artifact_codex(reward_table: Dictionary, growth_state: Dictionary, debug_all: bool = false) -> void:
	MainViewPanelsRuntimeScript.toggle_artifact_codex(self, reward_table, growth_state, debug_all)
func set_artifact_codex_visible(val: bool) -> void:
	MainViewPanelsRuntimeScript.set_artifact_codex_visible(self, val)
func is_artifact_codex_visible() -> bool:
	return MainViewPanelsRuntimeScript.is_artifact_codex_visible(self)
func is_combat_pause_overlay_visible() -> bool:
	return MainViewPanelsRuntimeScript.is_combat_pause_overlay_visible(self)
func is_battle_pause_active() -> bool:
	return battle_pause_active
func set_battle_pause_active(active: bool) -> void:
	MainViewPanelsRuntimeScript.set_battle_pause_active(self, active)
func _promote_popup_overlay_when_visible(overlay: Control) -> void:
	MainViewPanelsRuntimeScript.promote_popup_overlay_when_visible(self, overlay)
func _bring_popup_overlay_to_front(overlay: Control) -> void:
	MainViewPanelsRuntimeScript.bring_popup_overlay_to_front(self, overlay)
func _emit_combat_overlay_pause_visibility_changed() -> void:
	MainViewPanelsRuntimeScript.emit_combat_overlay_pause_visibility_changed(self)
func render_scene(scene: Dictionary, show_victory_overlay: bool) -> void:
	MainViewSceneRuntimeScript.render_scene(self, scene, show_victory_overlay)
func update_battlefield_disabled(scene: Dictionary, disabled_tiles: Array) -> void:
	MainViewSceneRuntimeScript.update_battlefield_disabled(self, scene, disabled_tiles)
func start_reward_reveal_vfx(rewards_list: Array, step_callback: Callable, callback: Callable) -> void:
	MainViewSceneRuntimeScript.start_reward_reveal_vfx(self, rewards_list, step_callback, callback)
func skip_reward_reveal_to_silhouettes() -> void:
	MainViewSceneRuntimeScript.skip_reward_reveal_to_silhouettes(self)
func cancel_reward_reveal_vfx() -> void:
	MainViewSceneRuntimeScript.cancel_reward_reveal_vfx(self)
func _on_reward_reveal_overlay_finished(next_step: String, callback: Callable) -> void:
	MainViewSceneRuntimeScript.on_reward_reveal_overlay_finished(self, next_step, callback)
func _flush_reward_reveal_finished_callback() -> void:
	MainViewSceneRuntimeScript.flush_reward_reveal_finished_callback(self)
func _bring_reward_reveal_overlay_to_front() -> void:
	MainViewSceneRuntimeScript.bring_reward_reveal_overlay_to_front(self)
func update_action_state(scene: Dictionary, show_victory_overlay: bool) -> void:
	MainViewSceneRuntimeScript.update_action_state(self, scene, show_victory_overlay)
func set_confirm_overlay_visible(val: bool) -> void:
	MainViewFeedbackRuntimeScript.set_confirm_overlay_visible(self, val)
func add_log(message: String) -> void:
	MainViewFeedbackRuntimeScript.add_log(self, message)
func update_discard_zone(label_text: String, is_active: bool) -> void:
	MainViewFeedbackRuntimeScript.update_discard_zone(self, label_text, is_active)
func get_cell_global_pos(cell_id: String) -> Vector2:
	return MainViewFeedbackRuntimeScript.get_cell_global_pos(self, cell_id)
func get_extractor_global_pos() -> Vector2:
	return MainViewFeedbackRuntimeScript.get_extractor_global_pos(self)
func get_health_bar_global_pos() -> Vector2:
	return MainViewFeedbackRuntimeScript.get_health_bar_global_pos(self)
func get_shield_bar_global_pos() -> Vector2:
	return MainViewFeedbackRuntimeScript.get_shield_bar_global_pos(self)
func trigger_resonance_beam(start_pos: Vector2, hit_pos: Vector2, color: String) -> void:
	MainViewFeedbackRuntimeScript.trigger_resonance_beam(self, start_pos, hit_pos, color)
func trigger_hit_particles(hit_pos: Vector2, status: String, color: String) -> void:
	MainViewFeedbackRuntimeScript.trigger_hit_particles(self, hit_pos, status, color)
func trigger_damage_popups(events: Array) -> void:
	MainViewFeedbackRuntimeScript.trigger_damage_popups(self, events)
func trigger_screenshake(duration: float, magnitude: float) -> void:
	MainViewFeedbackRuntimeScript.trigger_screenshake(self, duration, magnitude)
func render_reward_tray(model: Dictionary) -> void:
	MainViewRewardRuntimeScript.render_reward_tray(self, model)
func set_reward_text(val: String) -> void:
	MainViewRewardRuntimeScript.set_reward_text(self, val)
func _wire_reward_card_interactions(button: Button, index: int) -> void:
	MainViewRewardRuntimeScript.wire_reward_card_interactions(self, button, index)
func _queue_reward_card_float_layout() -> void:
	MainViewRewardRuntimeScript.queue_reward_card_float_layout(self)
func reward_card_anchor_bounds(cloud_size: Vector2, card_size: Vector2) -> Rect2:
	return MainViewRewardRuntimeScript.reward_card_anchor_bounds(cloud_size, card_size)
func clamp_reward_card_anchor(cloud_size: Vector2, card_size: Vector2, anchor: Vector2) -> Vector2:
	return MainViewRewardRuntimeScript.clamp_reward_card_anchor(cloud_size, card_size, anchor)
func _layout_reward_float_cards() -> void:
	MainViewRewardRuntimeScript.layout_reward_float_cards(self)
func _apply_reward_card_idle_transform(button: Control) -> void:
	MainViewRewardRuntimeScript.apply_reward_card_idle_transform(self, button)
func _end_reward_drag_tracking() -> void:
	MainViewRewardRuntimeScript.end_reward_drag_tracking(self)
func _update_reward_drag_card_position() -> void:
	MainViewRewardRuntimeScript.update_reward_drag_card_position(self)
func _commit_reward_card_manual_anchor(index: int) -> void:
	MainViewRewardRuntimeScript.commit_reward_card_manual_anchor(self, index)
func _begin_backpack_drag_tracking(origin_coord: Vector2) -> void:
	MainViewRewardRuntimeScript.begin_backpack_drag_tracking(self, origin_coord)
func _end_backpack_drag_tracking() -> void:
	MainViewRewardRuntimeScript.end_backpack_drag_tracking(self)
func reward_footprint_layout_policy(shape_matrix: Array) -> Dictionary:
	return MainViewRewardRuntimeScript.reward_footprint_layout_policy(shape_matrix)
func _set_descendant_mouse_filter_ignore(node: Node) -> void:
	for child in node.get_children():
		var control = child as Control
		if control != null:
			control.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_set_descendant_mouse_filter_ignore(child)
func apply_locale() -> void:
	MainViewLocaleRuntimeScript.apply_locale(self)
func _set_rich_text(path: String, text: String) -> void:
	MainViewLocaleRuntimeScript.set_rich_text(self, path, text)
func _create_shop_panel() -> void:
	MainViewPanelsRuntimeScript.create_shop_panel(self)
func _create_artifact_codex_panel() -> void:
	MainViewPanelsRuntimeScript.create_artifact_codex_panel(self)
func _create_page_scenes() -> void:
	MainViewPageShellRuntimeScript.create_page_scenes(self)
func _page_bundle(page_id: String) -> Dictionary:
	return MainViewPageShellRuntimeScript.page_bundle(self, page_id)
func _active_surface_bundle() -> Dictionary:
	return MainViewPageShellRuntimeScript.active_surface_bundle(self)
func bundle_node(page_id: String, path: String = "") -> Node:
	return MainViewPageShellRuntimeScript.bundle_node(self, page_id, path)
func current_surface_node(path: String = "") -> Node:
	return MainViewPageShellRuntimeScript.current_surface_node(self, path)
func current_action_bar_node(path: String = "") -> Node:
	return MainViewPageShellRuntimeScript.current_action_bar_node(self, path)
func _bundle_node(page_id: String, path: String = "") -> Node:
	return MainViewPageShellRuntimeScript.bundle_node(self, page_id, path)
func _cache_page_shell_bundles() -> void:
	MainViewPageShellRuntimeScript.cache_page_shell_bundles(self)
func _connect_page_shell_bundle_signals() -> void:
	MainViewPageShellRuntimeScript.connect_page_shell_bundle_signals(self)
func _activate_action_bar_bundle(page_id: String) -> void:
	MainViewPageShellRuntimeScript.activate_action_bar_bundle(self, page_id)
func _activate_surface_bundle(page_id: String) -> void:
	MainViewPageShellRuntimeScript.activate_surface_bundle(self, page_id)
func _sync_page_scene_bounds() -> void:
	MainViewPageShellRuntimeScript.sync_page_scene_bounds(self)
func _render_page_scene(scene: Dictionary) -> void:
	MainViewPageShellRuntimeScript.render_page_scene(self, scene)
func _page_scene_model(page_id: String, scene: Dictionary) -> Dictionary:
	return MainViewPageShellRuntimeScript.page_scene_model(page_id, scene)
func _install_character_presentation() -> void:
	MainViewPresentationRuntimeScript.install_character_presentation(self)
func _layout_character_presentation() -> void:
	MainViewPresentationRuntimeScript.layout_character_presentation(self)
func _character_sprite_frame(index: int) -> Texture2D:
	return MainViewPresentationRuntimeScript.character_sprite_frame(index)
func _install_reward_backdrop() -> void:
	MainViewPresentationRuntimeScript.install_reward_backdrop(self)
func _render_reward_backdrop(active: bool) -> void:
	MainViewPresentationRuntimeScript.render_reward_backdrop(self, active)
func _install_failure_backdrop() -> void:
	MainViewPresentationRuntimeScript.install_failure_backdrop(self)
func _render_failure_backdrop(scene: Dictionary) -> void:
	MainViewPresentationRuntimeScript.render_failure_backdrop(self, scene)
func _render_character_status(scene: Dictionary) -> void:
	MainViewPresentationRuntimeScript.render_character_status(self, scene)
func _apply_node_select_backpack_dock(dock: String, map_ratio: float, backpack_ratio: float) -> void:
	MainViewRewardLayoutRuntimeScript.apply_node_select_backpack_dock(self, dock, map_ratio, backpack_ratio)
func _node_select_backpack_width() -> float:
	return MainViewRewardLayoutRuntimeScript.node_select_backpack_width(self)
func _sync_node_select_backpack_width() -> void:
	MainViewRewardLayoutRuntimeScript.sync_node_select_backpack_width(self)
func _apply_reward_backpack_dock(dock_to_board: bool) -> void:
	MainViewRewardLayoutRuntimeScript.apply_reward_backpack_dock(self, dock_to_board)
func _queue_reward_board_layout_sync() -> void:
	if _reward_board_layout_sync_pending:
		return
	_reward_board_layout_sync_pending = true
	call_deferred("_sync_reward_board_layout")
func _install_reward_zone_scroll_shells() -> void:
	MainViewRewardLayoutRuntimeScript.install_reward_zone_scroll_shells(self)
func _install_reward_inspector_scroll_shell() -> void:
	MainViewRewardLayoutRuntimeScript.install_reward_inspector_scroll_shell(self)
func _sync_reward_board_layout() -> void:
	MainViewRewardLayoutRuntimeScript.sync_reward_board_layout(self)
func _reward_board_available_width() -> float:
	return MainViewRewardLayoutRuntimeScript.reward_board_available_width(self)
func _reward_board_layout_targets(scroll_height: float) -> Dictionary:
	return MainViewRewardLayoutRuntimeScript.reward_board_layout_targets(self, scroll_height)
func _reward_zone_body_target_height(zone: Control, body: Control, target_height: float, fallback_min: float) -> float:
	return MainViewRewardLayoutRuntimeScript.reward_zone_body_target_height(zone, body, target_height, fallback_min)
func _set_custom_minimum_size_if_changed(control: Control, next_size: Vector2, epsilon: float = 0.5) -> void:
	MainViewRewardLayoutRuntimeScript.set_custom_minimum_size_if_changed(control, next_size, epsilon)
func _reward_backpack_panel_dimensions_for_host(host_size: Vector2) -> Vector2:
	return MainViewRewardLayoutRuntimeScript.reward_backpack_panel_dimensions_for_host(self, host_size)
func _set_reward_workspace_title_state(dock_to_board: bool) -> void:
	MainViewRewardLayoutRuntimeScript.set_reward_workspace_title_state(self, dock_to_board)
func _resolved_header_title(scene: Dictionary) -> String:
	return MainViewLocaleRuntimeScript.resolved_header_title(scene)
func _max_safe_active_phase_height() -> float:
	return MainViewAppShellRuntimeScript.max_safe_active_phase_height(self)
func _top_content_backpack_height() -> float:
	return MainViewAppShellRuntimeScript.top_content_backpack_height(self)
func _top_content_backpack_width() -> float:
	return MainViewAppShellRuntimeScript.top_content_backpack_width(self)
func _apply_top_content_backpack_bounds() -> void:
	MainViewAppShellRuntimeScript.apply_top_content_backpack_bounds(self)
func _viewport_safe_app_shell_size() -> Vector2:
	return MainViewAppShellRuntimeScript.viewport_safe_app_shell_size(self)
func _viewport_safe_width_for_control(control: Control, fallback_width: float) -> float:
	return MainViewAppShellRuntimeScript.viewport_safe_width_for_control(self, control, fallback_width)
func _sync_top_content_backpack_layout() -> void:
	MainViewAppShellRuntimeScript.sync_top_content_backpack_layout(self)
func _queue_shared_backpack_layout_sync() -> void:
	MainViewAppShellRuntimeScript.queue_shared_backpack_layout_sync(self)
func _sync_shared_backpack_layout() -> void:
	MainViewAppShellRuntimeScript.sync_shared_backpack_layout(self)
func render_shop(growth_state: Dictionary) -> void:
	MainViewPanelsRuntimeScript.render_shop(self, growth_state)
func render_artifact_codex(reward_table: Dictionary, growth_state: Dictionary, debug_all: bool = false) -> void:
	MainViewPanelsRuntimeScript.render_artifact_codex(self, reward_table, growth_state, debug_all)
func _on_codex_debug_toggled(debug_all: bool) -> void:
	MainViewPanelsRuntimeScript.on_codex_debug_toggled(self, debug_all)
func _on_codex_entry_selected(entry_id: String) -> void:
	MainViewPanelsRuntimeScript.on_codex_entry_selected(self, entry_id)
func _on_codex_section_selected(section_id: String) -> void:
	MainViewPanelsRuntimeScript.on_codex_section_selected(self, section_id)
func _rerender_current_codex() -> void:
	MainViewPanelsRuntimeScript.rerender_current_codex(self)
func _install_interaction_fx() -> void:
	MainViewChromeRuntimeScript.install_interaction_fx(self)
func _apply_shell_theme() -> void:
	MainViewChromeRuntimeScript.apply_shell_theme(self)
func _style_shell_button(button: Button) -> void:
	MainViewChromeRuntimeScript.style_shell_button(self, button)
func _apply_top_content_stretch(left_ratio: float, backpack_ratio: float, right_ratio: float) -> void:
	MainViewAppShellRuntimeScript.apply_top_content_stretch(self, left_ratio, backpack_ratio, right_ratio)
func _create_giant_timer() -> void:
	MainViewChromeRuntimeScript.create_giant_timer(self)
func _create_reward_reveal_overlay() -> void:
	MainViewChromeRuntimeScript.create_reward_reveal_overlay(self)
func _create_vignette_overlay() -> void:
	MainViewChromeRuntimeScript.create_vignette_overlay(self)
func _process(delta: float) -> void:
	MainViewChromeRuntimeScript.process(self, delta)
func set_volume(val: float) -> void:
	MainViewChromeRuntimeScript.set_volume(self, val)
func _create_tooltip_panel() -> void:
	MainViewChromeRuntimeScript.create_tooltip_panel(self)
func show_artifact_tooltip(art) -> void:
	MainViewChromeRuntimeScript.show_artifact_tooltip(self, art)
func show_reward_tooltip(reward: Dictionary, equipped_artifacts: Array) -> void:
	MainViewChromeRuntimeScript.show_reward_tooltip(self, reward, equipped_artifacts)
func hide_artifact_tooltip() -> void:
	MainViewChromeRuntimeScript.hide_artifact_tooltip(self)
func _emit_start_combat_pressed() -> void:
	MainViewChromeRuntimeScript.emit_start_combat_pressed(self)
func _defer_interaction_fx_install() -> void:
	MainViewChromeRuntimeScript.defer_interaction_fx_install(self)
func _schedule_backpack_reparent(target_parent: Node, target_index: int = -1) -> void:
	MainViewBackpackRuntimeScript.schedule_backpack_reparent(self, target_parent, target_index)
func _commit_backpack_reparent() -> void:
	MainViewBackpackRuntimeScript.commit_backpack_reparent(self)
func _flush_pending_backpack_pin_scene() -> void:
	MainViewBackpackRuntimeScript.flush_pending_backpack_pin_scene(self)
func _queue_backpack_artifact_image_refresh() -> void:
	MainViewBackpackRuntimeScript.queue_artifact_image_refresh(self)
