class_name MainViewChromeRuntime
extends RefCounted

const TooltipReadModelScript = preload("res://src/ui/read_models/TooltipReadModel.gd")
const TextCatalogScript = preload("res://src/ui/TextCatalog.gd")
const ShellButtonStylerScript = preload("res://src/ui/presenters/ShellButtonStyler.gd")
const LTLThemeScript = preload("res://src/ui/theme/LTLTheme.gd")
const ArtifactTooltipUIScript = preload("res://src/ui/ArtifactTooltipUI.gd")
const GiantTimerUIScript = preload("res://src/ui/GiantTimerUI.gd")
const RewardRevealOverlayScript = preload("res://src/ui/RewardRevealOverlay.gd")
const InteractionFXScript = preload("res://src/ui/InteractionFX.gd")
const NarrativeToastScript = preload("res://src/scenes/narrative/NarrativeToast.gd")

static func install_interaction_fx(view) -> void:
	InteractionFXScript.install_tree(view)

static func apply_shell_theme(view) -> void:
	var surface := LTLThemeScript.surface_style(LTLThemeScript.SURFACE_MID)
	for page_id in view.SURFACE_PAGE_IDS:
		var bundle: Dictionary = view._page_bundle(page_id)
		if bundle.is_empty():
			continue
		_apply_surface_bundle_theme(view, page_id, bundle, surface)
	view.repair_overlay.add_theme_stylebox_override("panel", LTLThemeScript.overlay_style("warning"))
	_style_shell_buttons(view)

static func style_shell_button(view, button: Button) -> void:
	ShellButtonStylerScript.apply_button(button, view.header_actions, view.action_bar)

static func create_giant_timer(view) -> void:
	view.giant_timer_ui = GiantTimerUIScript.new()
	view.add_child(view.giant_timer_ui)
	view.giant_timer_ui.ensure_built()
	view.giant_timer_panel = view.giant_timer_ui.timer_panel
	view.giant_timer_label = view.giant_timer_ui.timer_label
	view.vignette_overlay = view.giant_timer_ui.vignette_overlay
	view.heartbeat_player = view.giant_timer_ui.heartbeat_player

static func create_reward_reveal_overlay(view) -> void:
	view.reward_reveal_overlay = RewardRevealOverlayScript.new()
	view.reward_reveal_overlay.name = "RewardRevealOverlay"
	view.reward_reveal_overlay.z_index = view.REWARD_REVEAL_OVERLAY_Z_INDEX
	view.reward_reveal_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	view.add_child(view.reward_reveal_overlay)

static func create_vignette_overlay(view) -> void:
	if view.giant_timer_ui != null:
		return

static func process(view, delta: float) -> void:
	update_tooltip_position(view)
	view.pulse_time += delta
	if view.portrait_idle != null and view.portrait_idle.visible:
		var frame_index := int(floor(view.pulse_time * 5.0)) % 20
		view.portrait_idle.texture = view._character_sprite_frame(frame_index)
		view.portrait_idle.position.y = maxf(2.0, view.portrait_placeholder.size.y - view.portrait_idle.size.y - 2.0) + sin(view.pulse_time * 2.2) * 1.5
	if view.reward_backdrop != null and view.reward_backdrop.visible:
		view.reward_backdrop.self_modulate.a = 0.24 + 0.03 * sin(view.pulse_time * 0.9)
	if view.reward_panel != null and view.reward_panel.visible:
		for button in view.reward_card_buttons:
			view._apply_reward_card_idle_transform(button)
	if view.battle_pause_active:
		return
	if view.giant_timer_ui != null and view.giant_timer_ui.has_method("process_timer"):
		view.giant_timer_ui.process_timer(delta, view.battlefield_ui)
		return

static func set_volume(view, val: float) -> void:
	view._heartbeat_volume = val
	if view.giant_timer_ui != null and view.giant_timer_ui.has_method("set_volume"):
		view.giant_timer_ui.set_volume(val)
		return

static func create_tooltip_panel(view) -> void:
	view.tooltip_panel = ArtifactTooltipUIScript.new()
	view.add_child(view.tooltip_panel)
	if view.tooltip_panel.has_method("get"):
		view.tooltip_label = view.tooltip_panel.label

static func create_narrative_toast(view) -> void:
	if view.narrative_toast != null:
		return
	view.narrative_toast = NarrativeToastScript.new()
	view.narrative_toast.anchor_left = 1.0
	view.narrative_toast.anchor_right = 1.0
	view.narrative_toast.anchor_top = 0.0
	view.narrative_toast.anchor_bottom = 0.0
	view.narrative_toast.offset_left = -464.0
	view.narrative_toast.offset_right = -24.0
	view.narrative_toast.offset_top = 86.0
	view.narrative_toast.offset_bottom = 210.0
	view.add_child(view.narrative_toast)
	view._set_descendant_mouse_filter_ignore(view.narrative_toast)

static func render_narrative(view, model: Dictionary) -> void:
	if view.narrative_toast == null:
		create_narrative_toast(view)
	if view.narrative_toast != null and view.narrative_toast.has_method("render"):
		view.narrative_toast.render(model)

static func show_artifact_tooltip(view, art) -> void:
	if view.tooltip_panel == null:
		return
	var tooltip_model: Dictionary = TooltipReadModelScript.project(art)
	_show_tooltip_model(view, tooltip_model)

static func show_reward_tooltip(view, reward: Dictionary, equipped_artifacts: Array) -> void:
	if view.tooltip_panel == null:
		return
	var tooltip_model: Dictionary = TooltipReadModelScript.project_reward_comparison(reward, equipped_artifacts, TextCatalogScript.locale())
	_show_tooltip_model(view, tooltip_model)

static func hide_artifact_tooltip(view) -> void:
	if view.tooltip_panel and view.tooltip_panel.has_method("hide_tooltip"):
		view.tooltip_panel.hide_tooltip()
		return
	if view.tooltip_panel:
		view.tooltip_panel.visible = false

static func update_tooltip_position(view) -> void:
	if view.tooltip_panel and view.tooltip_panel.has_method("update_position"):
		view.tooltip_panel.update_position(view.get_global_mouse_position())
		return
	if view.tooltip_panel and view.tooltip_panel.visible:
		var mouse_pos: Vector2 = view.get_global_mouse_position()
		view.tooltip_panel.global_position = mouse_pos + Vector2(15, 15)

static func emit_start_combat_pressed(view) -> void:
	view.start_combat_pressed.emit()

static func defer_interaction_fx_install(view) -> void:
	if not view.interaction_fx_enabled:
		return
	view.call_deferred("_install_interaction_fx")

static func _apply_surface_bundle_theme(view, page_id: String, bundle: Dictionary, surface: StyleBox) -> void:
	for key in ["statusPanel", "backpackUI", "rightSidebar", "battlefieldUI"]:
		var panel = bundle.get(key, null)
		if panel != null:
			panel.add_theme_stylebox_override("panel", surface)
	var reward_surface = bundle.get("rewardPanel", null) as PanelContainer
	if reward_surface == null:
		return
	reward_surface.add_theme_stylebox_override("panel", LTLThemeScript.surface_style(Color(0.10, 0.11, 0.13, 0.98), LTLThemeScript.BORDER_WARM, 12))
	for zone_path in [
		"RewardPanel/Margin/RewardBox/RewardBoardScroll/RewardBoard/RewardGrid/RewardsZone",
		"RewardPanel/Margin/RewardBox/RewardBoardScroll/RewardBoard/RewardGrid/WorkspaceZone",
		"RewardPanel/Margin/RewardBox/RewardBoardScroll/RewardBoard/RewardGrid/InspectorZone",
		"RewardPanel/Margin/RewardBox/RewardBoardScroll/RewardBoard/RewardGrid/RewardsZone/Margin/ZoneBox/RewardCloudBox",
		"RewardPanel/Margin/RewardBox/RewardBoardScroll/RewardBoard/RewardGrid/InspectorZone/Margin/ZoneBox/InspectorStage/FootprintCard",
		"RewardPanel/Margin/RewardBox/RewardBoardScroll/RewardBoard/BottomRow/ConfirmZone"
	]:
		var zone = view._bundle_node(page_id, zone_path) as PanelContainer
		if zone != null:
			zone.add_theme_stylebox_override("panel", LTLThemeScript.surface_style(Color(0.11, 0.14, 0.18, 0.98), LTLThemeScript.BORDER_COLD, 18, 1, 0.18))
	var discard_shell = view._bundle_node(page_id, "RewardPanel/Margin/RewardBox/RewardBoardScroll/RewardBoard/BottomRow/DiscardZone") as PanelContainer
	if discard_shell != null:
		discard_shell.add_theme_stylebox_override("panel", LTLThemeScript.surface_style(Color(0.14, 0.08, 0.09, 0.98), Color(0.68, 0.28, 0.28, 1.0), 18, 1, 0.20))
	var discard_card_panel = view._bundle_node(page_id, "RewardPanel/Margin/RewardBox/RewardBoardScroll/RewardBoard/BottomRow/DiscardZone/Margin/ZoneBox/DiscardCard") as PanelContainer
	if discard_card_panel != null:
		discard_card_panel.add_theme_stylebox_override("panel", LTLThemeScript.surface_style(Color(0.18, 0.09, 0.10, 0.98), Color(0.78, 0.34, 0.34, 1.0), 16, 1, 0.16))
	var claim_card_panel = view._bundle_node(page_id, "RewardPanel/Margin/RewardBox/RewardBoardScroll/RewardBoard/BottomRow/ConfirmZone/Margin/ZoneBox/ClaimCard") as PanelContainer
	if claim_card_panel != null:
		claim_card_panel.add_theme_stylebox_override("panel", LTLThemeScript.surface_style(Color(0.18, 0.15, 0.09, 0.98), LTLThemeScript.BORDER_WARM, 16, 1, 0.16))

static func _style_shell_buttons(view) -> void:
	for button in [view.settings_open_button, view.reset_button, view.start_button, view.hold_fire_button, view.repair_button, view.claim_rewards_button, view.claim_inline_button, view.shop_open_button, view.codex_open_button]:
		if button != null:
			style_shell_button(view, button)
	for page_id in view.ACTION_BAR_PAGE_IDS:
		var bundle: Dictionary = view._page_bundle(page_id)
		for key in ["resetButton", "startButton", "holdFireButton", "repairButton", "claimRewardsButton", "claimInlineButton"]:
			var button = bundle.get(key, null) as Button
			if button != null:
				style_shell_button(view, button)
	for key in ["shopButton", "codexButton", "settingsButton"]:
		var node_select_button := view._page_bundle("node_select").get(key, null) as Button
		if node_select_button != null:
			style_shell_button(view, node_select_button)
			if key == "shopButton":
				node_select_button.disabled = not view.SHOP_ENABLED
				node_select_button.mouse_default_cursor_shape = Control.CURSOR_FORBIDDEN if node_select_button.disabled else Control.CURSOR_POINTING_HAND

static func _show_tooltip_model(view, tooltip_model: Dictionary) -> void:
	if view.tooltip_panel != null and view.tooltip_panel.has_method("show_text"):
		view.tooltip_panel.show_text(str(tooltip_model.get("bbcode", "")))
		update_tooltip_position(view)
		return
	view.tooltip_label.text = str(tooltip_model.get("bbcode", ""))
	view.tooltip_panel.visible = true
	update_tooltip_position(view)
