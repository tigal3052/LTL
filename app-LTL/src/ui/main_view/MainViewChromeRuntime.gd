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
const InteractionSfxSynthScript = preload("res://src/ui/presenters/InteractionSfxSynth.gd")
const TileHitStream = preload("res://resources/sound/tile_hit.wav")
const TileStrongHitStream = preload("res://resources/sound/tile_hit2.wav")
const TileMissStream = preload("res://resources/sound/tile_miss.wav")

const REWARD_INSPECTOR_PANEL_Z_INDEX := 16

static func install_interaction_fx(view) -> void:
	InteractionFXScript.install_tree(view, Callable(view, "play_interaction_sfx"))

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
	ensure_interaction_sfx_players(view)

static func create_reward_reveal_overlay(view) -> void:
	view.reward_reveal_overlay = RewardRevealOverlayScript.new()
	view.reward_reveal_overlay.name = "RewardRevealOverlay"
	view.reward_reveal_overlay.z_index = view.REWARD_REVEAL_OVERLAY_Z_INDEX
	view.reward_reveal_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	view.add_child(view.reward_reveal_overlay)
	if view.reward_reveal_overlay.has_signal("interaction_sfx_requested"):
		view.reward_reveal_overlay.connect("interaction_sfx_requested", func(category: String) -> void:
			view.play_interaction_sfx(category)
		)

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
	view._interaction_sfx_volume = val
	if view.giant_timer_ui != null and view.giant_timer_ui.has_method("set_volume"):
		view.giant_timer_ui.set_volume(val)
	_update_interaction_sfx_volume(view)

static func create_tooltip_panel(view) -> void:
	view.tooltip_panel = ArtifactTooltipUIScript.new()
	view.add_child(view.tooltip_panel)
	if view.tooltip_panel.has_method("get"):
		view.tooltip_label = view.tooltip_panel.label

static func create_narrative_toast(view) -> void:
	if view.narrative_toast != null:
		return
	view.narrative_toast = NarrativeToastScript.new()
	view.add_child(view.narrative_toast)
	view.narrative_toast.continue_requested.connect(func(beat_id: String):
		view.narrative_continue_requested.emit(beat_id)
	)
	if view.narrative_toast.has_signal("interaction_sfx_requested"):
		view.narrative_toast.connect("interaction_sfx_requested", func(category: String) -> void:
			view.play_interaction_sfx(category)
		)
	view.narrative_toast.set_as_top_level(true)
	layout_narrative_toast(view)

static func render_narrative(view, model: Dictionary) -> void:
	view.narrative_toast_model = model.duplicate(true)
	if view.narrative_toast == null:
		create_narrative_toast(view)
	if view.narrative_toast != null and view.narrative_toast.has_method("render"):
		view.narrative_toast.render(model)
		layout_narrative_toast(view)

# 실행: position the story surface outside PanelContainer layout ownership.
static func layout_narrative_toast(view) -> void:
	if view.narrative_toast == null or not view.is_inside_tree():
		return
	var model: Dictionary = view.narrative_toast_model if view.narrative_toast_model is Dictionary else {}
	var anchor_preset := str(model.get("anchorPreset", "bottom_center"))
	var viewport_size: Vector2 = Vector2(view.get_tree().root.size)
	if viewport_size.x <= 1.0 or viewport_size.y <= 1.0:
		viewport_size = view.size
	var view_origin: Vector2 = view.get_global_rect().position
	var story_width := clampf(viewport_size.x * 0.58, 560.0, 860.0)
	var story_height := clampf(viewport_size.y * 0.42, 320.0, 420.0)
	var story_pos := Vector2((viewport_size.x - story_width) * 0.5, viewport_size.y - story_height - clampf(viewport_size.y * 0.09, 64.0, 96.0))
	match anchor_preset:
		"top_left":
			story_width = clampf(viewport_size.x * 0.38, 420.0, 620.0)
			story_height = clampf(viewport_size.y * 0.34, 260.0, 340.0)
			story_pos = Vector2(32.0, clampf(viewport_size.y * 0.10, 58.0, 92.0))
		"combat_right":
			story_width = clampf(viewport_size.x * 0.34, 420.0, 560.0)
			story_height = clampf(viewport_size.y * 0.38, 280.0, 380.0)
			story_pos = Vector2(viewport_size.x - story_width - 32.0, (viewport_size.y - story_height) * 0.52)
		"boss_bottom":
			story_width = clampf(viewport_size.x * 0.72, 680.0, 1000.0)
			story_height = clampf(viewport_size.y * 0.44, 330.0, 440.0)
			story_pos = Vector2((viewport_size.x - story_width) * 0.5, viewport_size.y - story_height - 42.0)
	story_pos.x = clampf(story_pos.x, 24.0, maxf(24.0, viewport_size.x - story_width - 24.0))
	story_pos.y = clampf(story_pos.y, 24.0, maxf(24.0, viewport_size.y - story_height - 24.0))
	view.narrative_toast.global_position = view_origin + story_pos
	view.narrative_toast.size = Vector2(story_width, story_height)

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

static func show_fusion_tooltip(view, existing_artifact, incoming_artifact) -> void:
	if view.tooltip_panel == null:
		return
	var tooltip_model: Dictionary = TooltipReadModelScript.project_fusion_preview(existing_artifact, incoming_artifact, TextCatalogScript.locale())
	if bool(tooltip_model.get("ok", false)):
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

static func ensure_interaction_sfx_players(view, player_count: int = 6) -> void:
	if view.interaction_sfx_players.size() >= player_count:
		_update_interaction_sfx_volume(view)
		return
	for index in range(view.interaction_sfx_players.size(), player_count):
		var player := AudioStreamPlayer.new()
		player.name = "InteractionSfxPlayer%d" % index
		view.add_child(player)
		view.interaction_sfx_players.append(player)
	_update_interaction_sfx_volume(view)

static func play_interaction_sfx(view, category: String) -> void:
	var descriptors := sfx_descriptors_for_category(category)
	if descriptors.is_empty():
		return
	var cooldown_descriptor: Dictionary = descriptors[0]
	if _sfx_on_cooldown(view, cooldown_descriptor):
		return
	ensure_interaction_sfx_players(view, maxi(6, descriptors.size()))
	for descriptor_value in descriptors:
		if descriptor_value is Dictionary:
			_play_sfx_descriptor(view, descriptor_value)

static func page_transition_sfx_category(view, page_id: String) -> String:
	if page_id.is_empty():
		return ""
	if view._last_sfx_page_id.is_empty():
		view._last_sfx_page_id = page_id
		return ""
	if view._last_sfx_page_id == page_id:
		return ""
	view._last_sfx_page_id = page_id
	return "page_transition"

static func sfx_descriptor_for_category(category: String) -> Dictionary:
	match category:
		"ui_click":
			return _descriptor(category, "soft", "synth", -12.0, 1.0, 45)
		"ui_confirm":
			return _descriptor(category, "soft", "synth", -10.0, 1.03, 55)
		"ui_cancel":
			return _descriptor(category, "soft", "synth", -12.0, 0.92, 55)
		"ui_toggle":
			return _descriptor(category, "switch", "synth", -11.0, 0.97, 70)
		"battle_start":
			return _descriptor(category, "start_impact", "synth", -7.0, 0.86, 220)
		"starter_set_select":
			return _descriptor(category, "selector", "synth", -10.0, 1.04, 90)
		"settings_open":
			return _descriptor(category, "settings_chime", "synth", -10.0, 1.0, 160)
		"settings_close":
			return _descriptor(category, "settings_chime", "synth", -12.0, 0.88, 160)
		"codex_open":
			return _descriptor(category, "codex_page", "synth", -10.0, 0.96, 180)
		"codex_close":
			return _descriptor(category, "codex_page", "synth", -12.0, 0.82, 180)
		"menu_open":
			return _descriptor(category, "soft", "synth", -12.0, 1.0, 160)
		"menu_close":
			return _descriptor(category, "soft", "synth", -13.0, 0.95, 160)
		"page_transition":
			return _descriptor(category, "soft", "synth", -14.0, 1.0, 220)
		"drag_start":
			return _descriptor(category, "soft", "synth", -14.0, 0.88, 130)
		"drag_drop":
			return _descriptor(category, "soft", "synth", -11.0, 1.02, 130)
		"drag_cancel":
			return _descriptor(category, "dry", "synth", -13.0, 0.82, 130)
		"item_click":
			return _descriptor(category, "item_tick", "synth", -11.0, 1.0, 70)
		"item_place":
			return _descriptor(category, "item_socket", "synth", -9.0, 0.92, 120)
		"item_fusion":
			return _descriptor(category, "shimmer", "synth", -10.0, 1.06, 180)
		"fusion_buildup":
			return _descriptor(category, "fusion_beat", "synth", -8.0, 0.92, 420)
		"fusion_complete":
			return _descriptor(category, "fusion_fanfare", "synth", -6.0, 1.18, 260)
		"typewriter_tick":
			return _descriptor(category, "typewriter", "synth", -16.0, 1.0, 12)
		"dialogue_advance":
			return _descriptor(category, "dialogue", "synth", -10.0, 0.94, 120)
		"reward_expectation":
			return _descriptor(category, "reward_build", "synth", -9.0, 0.88, 650)
		"reward_count_fanfare":
			return _descriptor(category, "reward_fanfare", "synth", -6.0, 1.08, 420)
		"excavation_buildup":
			return _descriptor(category, "excavation_build", "synth", -10.0, 0.74, 520)
		"excavation_detail_fanfare":
			return _descriptor(category, "excavation_fanfare", "synth", -7.0, 0.92, 420)
		"combat_hit":
			return _descriptor(category, "thunder", "tile_hit", -8.0, 1.0, 90)
		"combat_strong_hit":
			return _descriptor(category, "thunder", "tile_hit2", -12.0, 0.98, 260)
		"combat_miss":
			return _descriptor(category, "dry", "tile_miss", -12.0, 1.0, 80)
	return {}

static func sfx_descriptors_for_category(category: String) -> Array:
	var base := sfx_descriptor_for_category(category)
	if base.is_empty():
		return []
	match category:
		"combat_hit":
			return [
				base,
				_descriptor(category, "thunder_low", "tile_hit", -15.0, 0.64, 90, "low_body")
			]
		"combat_strong_hit":
			return [
				base,
				_descriptor(category, "thunder_low", "tile_hit", -14.0, 0.58, 260, "low_body")
			]
	return [base]

static func sfx_event_inventory() -> Array:
	return [
		{"category": "ui_click", "event": "neutral control press", "implemented": true},
		{"category": "ui_confirm", "event": "positive action press", "implemented": true},
		{"category": "ui_cancel", "event": "cancel/back/destructive press", "implemented": true},
		{"category": "ui_toggle", "event": "toggle or mode-switch control press", "implemented": true},
		{"category": "battle_start", "event": "combat or looting start press", "implemented": true},
		{"category": "starter_set_select", "event": "starter-set color selection press", "implemented": true},
		{"category": "settings_open", "event": "settings panel opens", "implemented": true},
		{"category": "settings_close", "event": "settings panel closes", "implemented": true},
		{"category": "codex_open", "event": "artifact codex opens", "implemented": true},
		{"category": "codex_close", "event": "artifact codex closes", "implemented": true},
		{"category": "menu_open", "event": "blocking panel opens", "implemented": true},
		{"category": "menu_close", "event": "blocking panel closes", "implemented": true},
		{"category": "page_transition", "event": "actual page id changes", "implemented": true},
		{"category": "drag_start", "event": "reward/backpack drag pickup", "implemented": true},
		{"category": "drag_drop", "event": "valid reward/backpack drop", "implemented": true},
		{"category": "drag_cancel", "event": "canceled reward/backpack drop", "implemented": true},
		{"category": "item_click", "event": "reward card or backpack item click", "implemented": true},
		{"category": "item_place", "event": "artifact placement succeeds", "implemented": true},
		{"category": "item_fusion", "event": "duplicate item synthesis succeeds", "implemented": true},
		{"category": "fusion_buildup", "event": "exact-overlap item synthesis buildup beat", "implemented": true},
		{"category": "fusion_complete", "event": "exact-overlap item synthesis completion fanfare", "implemented": true},
		{"category": "typewriter_tick", "event": "one or more dialogue characters reveal", "implemented": true},
		{"category": "dialogue_advance", "event": "dialogue continue input", "implemented": true},
		{"category": "reward_expectation", "event": "reward acquisition ceremony buildup", "implemented": true},
		{"category": "reward_count_fanfare", "event": "reward artifact count reveal", "implemented": true},
		{"category": "excavation_buildup", "event": "excavation result progress fill", "implemented": true},
		{"category": "excavation_detail_fanfare", "event": "excavation detail reveal", "implemented": true},
		{"category": "combat_miss", "event": "combat miss or non-match", "implemented": true},
		{"category": "combat_hit", "event": "combat match hit with low body layer", "implemented": true},
		{"category": "combat_strong_hit", "event": "health-damaging combat hit with low body layer", "implemented": true},
		{"category": "reward_reveal", "event": "reward ceremony beats reserved for reward assets", "implemented": false, "reserved": true}
	]

static func _descriptor(category: String, tone_family: String, stream_id: String, gain_db: float, pitch: float, cooldown_ms: int, role: String = "base") -> Dictionary:
	return {
		"category": category,
		"toneFamily": tone_family,
		"streamId": stream_id,
		"gainDb": gain_db,
		"pitch": pitch,
		"cooldownMs": cooldown_ms,
		"role": role
	}

static func _play_sfx_descriptor(view, descriptor: Dictionary) -> void:
	if view.interaction_sfx_players.is_empty():
		return
	var player: AudioStreamPlayer = view.interaction_sfx_players[view._interaction_sfx_next_player % view.interaction_sfx_players.size()]
	view._interaction_sfx_next_player = (view._interaction_sfx_next_player + 1) % max(1, view.interaction_sfx_players.size())
	player.stream = _stream_for_sfx_category(view, descriptor)
	if player.stream == null:
		return
	player.volume_db = _volume_db(view._interaction_sfx_volume) + float(descriptor.get("gainDb", -18.0))
	player.pitch_scale = float(descriptor.get("pitch", 1.0))
	player.play()
	_record_sfx_event(view, descriptor)

static func _stream_for_sfx_category(view, descriptor: Dictionary) -> AudioStream:
	var stream_id := str(descriptor.get("streamId", "synth"))
	match stream_id:
		"tile_hit":
			return TileHitStream
		"tile_hit2":
			return TileStrongHitStream
		"tile_miss":
			return TileMissStream
	var cache_key := "%s:%s" % [stream_id, str(descriptor.get("category", ""))]
	if not view.interaction_sfx_streams.has(cache_key):
		view.interaction_sfx_streams[cache_key] = InteractionSfxSynthScript.create_stream(str(descriptor.get("category", "")))
	return view.interaction_sfx_streams.get(cache_key, null)

static func _update_interaction_sfx_volume(view) -> void:
	for player in view.interaction_sfx_players:
		if player != null:
			player.volume_db = _volume_db(view._interaction_sfx_volume)

static func _volume_db(value: float) -> float:
	if value <= 0.0:
		return -80.0
	return linear_to_db(clampf(value, 0.0, 100.0) / 100.0)

static func _sfx_on_cooldown(view, descriptor: Dictionary) -> bool:
	var category := str(descriptor.get("category", ""))
	var now := Time.get_ticks_msec()
	var last := int(view._interaction_sfx_last_msec.get(category, -1000000))
	var cooldown_ms := int(descriptor.get("cooldownMs", 0))
	if now - last < cooldown_ms:
		return true
	view._interaction_sfx_last_msec[category] = now
	return false

static func _record_sfx_event(view, descriptor: Dictionary) -> void:
	view.interaction_sfx_events.append(descriptor.duplicate(true))
	while view.interaction_sfx_events.size() > 32:
		view.interaction_sfx_events.pop_front()

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
		"RewardPanel/Margin/RewardBox/RewardBoardScroll/RewardBoard/RewardGrid/RewardsZone/Margin/ZoneBox/RewardCloudBox",
		"RewardPanel/Margin/RewardBox/RewardBoardScroll/RewardBoard/RewardGrid/InspectorZone/Margin/ZoneBox/InspectorStage/FootprintCard",
		"RewardPanel/Margin/RewardBox/RewardBoardScroll/RewardBoard/BottomRow/ConfirmZone"
	]:
		var zone = view._bundle_node(page_id, zone_path) as PanelContainer
		if zone != null:
			zone.add_theme_stylebox_override("panel", LTLThemeScript.surface_style(Color(0.11, 0.14, 0.18, 0.98), LTLThemeScript.BORDER_COLD, 18, 1, 0.18))
	var inspector_zone = view._bundle_node(page_id, "RewardPanel/Margin/RewardBox/RewardBoardScroll/RewardBoard/RewardGrid/InspectorZone") as PanelContainer
	if inspector_zone != null:
		inspector_zone.z_index = REWARD_INSPECTOR_PANEL_Z_INDEX
		inspector_zone.add_theme_stylebox_override("panel", LTLThemeScript.surface_style(Color(0.11, 0.14, 0.18, 1.0), LTLThemeScript.BORDER_COLD, 18, 1, 0.18))
	var discard_shell = view._bundle_node(page_id, "RewardPanel/Margin/RewardBox/RewardBoardScroll/RewardBoard/BottomRow/DiscardZone") as PanelContainer
	if discard_shell != null:
		discard_shell.add_theme_stylebox_override("panel", LTLThemeScript.surface_style(Color(0.14, 0.08, 0.09, 0.98), Color(0.68, 0.28, 0.28, 1.0), 18, 1, 0.20))
	var discard_card_panel = view._bundle_node(page_id, "RewardPanel/Margin/RewardBox/RewardBoardScroll/RewardBoard/BottomRow/DiscardZone/Margin/ZoneBox/DiscardCard") as PanelContainer
	if discard_card_panel != null:
		discard_card_panel.add_theme_stylebox_override("panel", LTLThemeScript.surface_style(Color(0.18, 0.09, 0.10, 0.98), Color(0.78, 0.34, 0.34, 1.0), 16, 1, 0.16))

static func _style_shell_buttons(view) -> void:
	for button in [view.settings_open_button, view.reset_button, view.start_button, view.claim_rewards_button, view.claim_inline_button, view.shop_open_button, view.codex_open_button]:
		if button != null:
			style_shell_button(view, button)
	for page_id in view.ACTION_BAR_PAGE_IDS:
		var bundle: Dictionary = view._page_bundle(page_id)
		for key in ["resetButton", "startButton", "claimRewardsButton", "claimInlineButton"]:
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
		view.tooltip_panel.show_text(str(tooltip_model.get("bbcode", "")), tooltip_model)
		update_tooltip_position(view)
		return
	view.tooltip_label.text = str(tooltip_model.get("bbcode", ""))
	view.tooltip_panel.visible = true
	update_tooltip_position(view)
