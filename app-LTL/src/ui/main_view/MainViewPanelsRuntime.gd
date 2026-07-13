class_name MainViewPanelsRuntime
extends RefCounted

const ShopPanelUIScript = preload("res://src/ui/ShopPanelUI.gd")
const PopupOverlayHostScript = preload("res://src/ui/PopupOverlayHost.gd")
const ArtifactCodexPanelUIScript = preload("res://src/ui/ArtifactCodexPanelUI.gd")
const ArtifactCodexReadModelScript = preload("res://src/ui/read_models/ArtifactCodexReadModel.gd")

static func setup_settings(view, shake_enabled: bool, is_fullscreen: bool, accessibility_state: Dictionary = {}) -> void:
	view.settings_panel.setup(shake_enabled, is_fullscreen, accessibility_state)
	view.apply_locale()

static func toggle_settings(view) -> void:
	view.settings_panel.visible = not view.settings_panel.visible
	if view.settings_panel.visible:
		view.settings_panel.apply_locale()
		view.shop_panel.visible = false
		view.set_artifact_codex_visible(false)
		if view.settings_panel.has_method("focus_first_control"):
			view.settings_panel.focus_first_control()
	else:
		view.settings_open_button.grab_focus()

static func set_settings_visible(view, val: bool) -> void:
	view.settings_panel.visible = val
	if not val:
		view.settings_open_button.grab_focus()

static func is_settings_visible(view) -> bool:
	return view.settings_panel.visible

static func toggle_shop(view) -> void:
	if not view.SHOP_ENABLED:
		view.shop_panel.visible = false
		return
	view.shop_panel.visible = not view.shop_panel.visible
	if view.shop_panel.visible:
		view.settings_panel.visible = false
		view.set_artifact_codex_visible(false)

static func set_shop_visible(view, val: bool) -> void:
	view.shop_panel.visible = val and view.SHOP_ENABLED

static func is_shop_visible(view) -> bool:
	return view.shop_panel.visible

static func toggle_artifact_codex(view, reward_table: Dictionary, growth_state: Dictionary, debug_all: bool = false) -> void:
	if view.codex_panel == null:
		return
	view.current_codex_reward_table = reward_table.duplicate(true)
	view.current_codex_growth_state = growth_state.duplicate(true)
	view.current_codex_debug_all = debug_all
	view.codex_panel.visible = not view.codex_panel.visible
	if view.codex_panel.visible:
		view.settings_panel.visible = false
		view.shop_panel.visible = false
		render_artifact_codex(view, view.current_codex_reward_table, view.current_codex_growth_state, view.current_codex_debug_all)

static func set_artifact_codex_visible(view, val: bool) -> void:
	if view.codex_panel != null:
		view.codex_panel.visible = val

static func is_artifact_codex_visible(view) -> bool:
	return view.codex_panel != null and view.codex_panel.visible

static func is_combat_pause_overlay_visible(view) -> bool:
	return PopupOverlayHostScript.pause_overlay_visible(
		is_settings_visible(view),
		is_artifact_codex_visible(view),
		view.repair_overlay != null and view.repair_overlay.visible
	)

static func set_battle_pause_active(view, active: bool) -> void:
	if view.battle_pause_active == active:
		return
	view.battle_pause_active = active
	for bundle in view.page_shell_bundles.values():
		var battlefield_panel = bundle.get("battlefieldUI", null)
		if battlefield_panel != null and battlefield_panel.has_method("set_battle_pause_active"):
			battlefield_panel.set_battle_pause_active(active)
	if view.backpack_ui != null and view.backpack_ui.has_method("set_battle_pause_active"):
		view.backpack_ui.set_battle_pause_active(active)
	if view.giant_timer_ui != null and view.giant_timer_ui.has_method("set_battle_pause_active"):
		view.giant_timer_ui.set_battle_pause_active(active)
	if view.vfx_manager != null and view.vfx_manager.has_method("set_battle_pause_active"):
		view.vfx_manager.set_battle_pause_active(active)

static func promote_popup_overlay_when_visible(view, overlay: Control) -> void:
	PopupOverlayHostScript.promote_when_visible(overlay, view.popup_overlay_z_index())

static func bring_popup_overlay_to_front(view, overlay: Control) -> void:
	PopupOverlayHostScript.bring_to_front(overlay, view.popup_overlay_z_index())

static func emit_combat_overlay_pause_visibility_changed(view) -> void:
	var active: bool = is_combat_pause_overlay_visible(view)
	if active == view._last_combat_pause_overlay_visible:
		return
	view._last_combat_pause_overlay_visible = active
	view.combat_overlay_pause_visibility_changed.emit(active)

static func create_shop_panel(view) -> void:
	view.shop_panel = ShopPanelUIScript.new()
	view.shop_panel.buy_passive.connect(func(passive_id, cost): view.buy_passive.emit(passive_id, cost))
	view.shop_panel.buy_base_item.connect(func(item_id): view.buy_base_item.emit(item_id))
	view.shop_panel.visibility_changed.connect(func():
		view._promote_popup_overlay_when_visible(view.shop_panel)
		_play_menu_visibility_sfx(view, view.shop_panel)
	)
	view.add_child(view.shop_panel)

static func create_artifact_codex_panel(view) -> void:
	view.codex_panel = ArtifactCodexPanelUIScript.new()
	view.codex_panel.debug_toggled.connect(view._on_codex_debug_toggled)
	view.codex_panel.entry_selected.connect(view._on_codex_entry_selected)
	view.codex_panel.section_selected.connect(view._on_codex_section_selected)
	if view.codex_panel.has_signal("taxonomy_selected"):
		view.codex_panel.taxonomy_selected.connect(view._on_codex_taxonomy_selected)
	if view.codex_panel.has_signal("sort_selected"):
		view.codex_panel.sort_selected.connect(view._on_codex_sort_selected)
	view.codex_panel.visibility_changed.connect(func():
		view._promote_popup_overlay_when_visible(view.codex_panel)
		view._emit_combat_overlay_pause_visibility_changed()
		_play_menu_visibility_sfx(view, view.codex_panel)
	)
	view.add_child(view.codex_panel)

static func render_shop(view, growth_state: Dictionary) -> void:
	if view.shop_panel != null and view.shop_panel.has_method("render_shop"):
		view.shop_panel.render_shop(growth_state)
		view._defer_interaction_fx_install()
		return

static func render_artifact_codex(view, reward_table: Dictionary, growth_state: Dictionary, debug_all: bool = false) -> void:
	if view.codex_panel == null or not view.codex_panel.has_method("render_codex"):
		return
	view.current_codex_reward_table = reward_table.duplicate(true)
	view.current_codex_growth_state = growth_state.duplicate(true)
	view.current_codex_debug_all = debug_all
	var model: Dictionary = ArtifactCodexReadModelScript.project_v5(
		view.current_codex_reward_table,
		view.current_codex_growth_state,
		view.current_codex_debug_all,
		"",
		view.current_codex_selected_entry_id,
		view.current_codex_active_section,
		view.current_codex_active_taxonomy_id,
		view.current_codex_sort_id
	)
	view.current_codex_selected_entry_id = str(model.get("resolvedSelectedEntryId", ""))
	view.current_codex_active_section = str(model.get("activeSection", "all"))
	view.current_codex_active_taxonomy_id = str(model.get("activeTaxonomyId", "backpack_items"))
	view.current_codex_sort_id = str(model.get("activeSortId", "catalog"))
	view.codex_panel.render_codex(model)
	view._defer_interaction_fx_install()

static func on_codex_debug_toggled(view, debug_all: bool) -> void:
	view.current_codex_debug_all = debug_all
	if view.current_codex_reward_table.is_empty():
		return
	view.call_deferred("_rerender_current_codex")

static func on_codex_entry_selected(view, entry_id: String) -> void:
	view.current_codex_selected_entry_id = entry_id
	if view.current_codex_reward_table.is_empty():
		return
	view.call_deferred("_rerender_current_codex")

static func on_codex_section_selected(view, section_id: String) -> void:
	view.current_codex_active_section = section_id
	if view.current_codex_reward_table.is_empty():
		return
	view.call_deferred("_rerender_current_codex")

static func on_codex_taxonomy_selected(view, taxonomy_id: String) -> void:
	view.current_codex_active_taxonomy_id = taxonomy_id
	if not view.current_codex_reward_table.is_empty():
		view.call_deferred("_rerender_current_codex")

static func on_codex_sort_selected(view, sort_id: String) -> void:
	view.current_codex_sort_id = sort_id
	if not view.current_codex_reward_table.is_empty():
		view.call_deferred("_rerender_current_codex")

static func rerender_current_codex(view) -> void:
	if view.current_codex_reward_table.is_empty():
		return
	render_artifact_codex(view, view.current_codex_reward_table, view.current_codex_growth_state, view.current_codex_debug_all)

static func _play_menu_visibility_sfx(view, overlay: Control) -> void:
	if view == null or overlay == null or not view.has_method("play_interaction_sfx"):
		return
	if overlay == view.codex_panel:
		view.play_interaction_sfx("codex_open" if overlay.visible else "codex_close")
		return
	view.play_interaction_sfx("menu_open" if overlay.visible else "menu_close")
