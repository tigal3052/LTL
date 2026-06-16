# 怨꾩빟:
# - 梨낆엫: MainController??_ready bootstrap, view signal wiring, initial render/timer setup???뚯쑀?쒕떎.
# - ?낅젰: MainController node context and parent MainUI view.
# - 異쒕젰: initialized controller fields, connected UI signals, initial scene render, process/timer activation.
# - 湲덉?: runtime gameplay rules, render helper ownership, signal names 蹂寃?
#
# ?ㅽ뻾: define the main-scene bootstrap helper as a stateful controller delegate.
extends RefCounted

const InventoryModelScript = preload("res://src/models/InventoryModel.gd")
const RunGrowthStateScript = preload("res://src/models/RunGrowthState.gd")

# ?ㅽ뻾: obtain the parent view, wire event handlers, and bootstrap initial run state after view readiness.
static func ready(controller) -> void:
	controller.view = controller.get_parent()
	if not controller.view.is_node_ready():
		await controller.view.ready
	controller.accessibility_state = controller.load_accessibility_state_from_path()
	controller.inventory = InventoryModelScript.new(8, 8)
	controller.character_roster = controller._load_character_roster()
	var selected_character: Dictionary = controller._selected_character_data()
	controller.selected_character_id = str(selected_character.get("id", controller.selected_character_id))
	controller.leviathan_roster = controller._load_leviathan_roster()
	if not controller.leviathan_roster.is_empty():
		controller.selected_leviathan_id = str(controller.leviathan_roster[0].get("id", controller.selected_leviathan_id))

	randomize()
	controller._rebuild_preview_controller(randi() & 0x7fffffff)

	var default_growth = controller.preview_controller.run.state.get("growth", {})
	controller.growth_state = RunGrowthStateScript.new(default_growth)
	controller.campaign_progress = controller.preview_controller.run.state.get("progress", {"clearedLeviathanIds": []}).duplicate(true)

	controller._load_backpack_items_into_inventory()
	_connect_view_signals(controller)
	controller.view.setup_backpack_slots()
	controller.view.render_backpack(controller.inventory)
	controller._apply_accessibility_state()
	controller.view.setup_settings(
		bool(controller.accessibility_state.get("screenshake", true)),
		DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN,
		controller.accessibility_state
	)
	controller.current_scene = controller.preview_controller.reset()
	controller._recalculate_queue_colors()
	controller._render_scene(controller.current_scene)
	controller._setup_shift_timer()
	controller.set_process(true)

# ?ㅽ뻾: connect MainUI signals to scene-facing controller wrappers.
static func _connect_view_signals(controller) -> void:
	controller.view.reset_pressed.connect(controller._on_reset_pressed)
	controller.view.start_combat_pressed.connect(controller._on_start_pressed)
	controller.view.hold_fire_pressed.connect(controller._on_hold_fire_pressed)
	controller.view.repair_pressed.connect(controller._on_repair_pressed)
	controller.view.claim_rewards_pressed.connect(controller._on_claim_rewards_pressed)
	controller.view.confirm_proceed_pressed.connect(controller._on_confirm_proceed_pressed)
	controller.view.confirm_cancel_pressed.connect(controller._on_confirm_cancel_pressed)
	controller.view.settings_open_pressed.connect(func(): controller.view.toggle_settings())
	if controller.view.has_signal("combat_overlay_pause_visibility_changed"):
		controller.view.combat_overlay_pause_visibility_changed.connect(controller._on_combat_overlay_pause_visibility_changed)
	controller.view.loadout_color_selected.connect(controller._on_loadout_color_selected)
	if controller.view.has_signal("character_continue_pressed"):
		controller.view.character_continue_pressed.connect(controller._on_character_continue_pressed)
	if controller.view.has_signal("character_selected"):
		controller.view.character_selected.connect(controller._on_character_selected)
	if controller.view.has_signal("leviathan_selected"):
		controller.view.leviathan_selected.connect(controller._on_leviathan_selected)
	if controller.view.has_signal("looting_start_pressed"):
		controller.view.looting_start_pressed.connect(controller._on_looting_start_pressed)
	if controller.view.has_signal("return_to_character_select_pressed"):
		controller.view.return_to_character_select_pressed.connect(controller._on_return_to_character_select_pressed)
	controller.view.settings_panel.reset_requested.connect(controller._on_reset_pressed)
	controller.view.settings_panel.language_changed.connect(controller._on_language_changed)
	controller.view.settings_panel.screenshake_toggled.connect(func(enabled):
		controller.accessibility_state["screenshake"] = enabled
		controller._apply_accessibility_state()
		controller.save_accessibility_state_to_path()
	)
	if controller.view.settings_panel.has_signal("reduced_flash_toggled"):
		controller.view.settings_panel.reduced_flash_toggled.connect(func(enabled):
			controller.accessibility_state["reducedFlash"] = enabled
			controller._apply_accessibility_state()
			controller.save_accessibility_state_to_path()
		)
	if controller.view.settings_panel.has_signal("reduced_particles_toggled"):
		controller.view.settings_panel.reduced_particles_toggled.connect(func(enabled):
			controller.accessibility_state["reducedParticles"] = enabled
			controller._apply_accessibility_state()
			controller.save_accessibility_state_to_path()
		)
	if controller.view.settings_panel.has_signal("hold_fire_assist_toggled"):
		controller.view.settings_panel.hold_fire_assist_toggled.connect(func(enabled):
			controller.accessibility_state["holdFireAssist"] = enabled
			controller.save_accessibility_state_to_path()
		)
	controller.view.settings_panel.fullscreen_toggled.connect(func(toggled): DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if toggled else DisplayServer.WINDOW_MODE_WINDOWED))
	controller.view.node_meta_clicked.connect(controller._on_node_meta_clicked)
	controller.view.reward_meta_clicked.connect(controller._on_reward_meta_inspect_clicked)
	controller.view.reward_meta_hovered.connect(controller._on_reward_meta_hovered)
	controller.view.reward_meta_unhovered.connect(controller._on_reward_meta_unhovered)
	controller.view.reward_meta_drag_started.connect(controller._on_reward_meta_drag_started_v2)
	controller.view.reward_meta_drop_requested.connect(controller._on_reward_meta_drop_requested_v2)
	controller.view.reward_meta_discard_requested.connect(controller._on_reward_meta_discard_requested_v2)
	controller.view.reward_meta_drag_canceled.connect(controller._on_reward_meta_drag_canceled_v2)
	controller.view.discard_zone_input.connect(controller._on_discard_zone_input)

	controller.view.shop_open_pressed.connect(controller._on_shop_open_pressed)
	controller.view.codex_open_pressed.connect(controller._on_codex_open_pressed)
	controller.view.buy_passive.connect(controller._on_buy_passive)
	controller.view.buy_base_item.connect(controller._on_buy_base_item)

	controller.view.repair_overlay_input.connect(func(ev):
		if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
			var phase = str(controller.current_scene.get("phase", ""))
			if phase == "run_complete" and bool(controller.current_scene.get("failed", false)):
				controller._on_reset_pressed()
	)
	controller.view.backpack_slot_clicked.connect(controller._on_backpack_slot_clicked)
	controller.view.backpack_slot_hovered.connect(controller._on_backpack_slot_hovered)
	controller.view.backpack_slot_unhovered.connect(controller._on_backpack_slot_unhovered)
	if controller.view.has_signal("backpack_slot_drag_started"):
		controller.view.backpack_slot_drag_started.connect(controller._on_backpack_slot_drag_started)
	if controller.view.has_signal("backpack_slot_drop_requested"):
		controller.view.backpack_slot_drop_requested.connect(controller._on_backpack_slot_drop_requested)
	if controller.view.has_signal("backpack_slot_discard_requested"):
		controller.view.backpack_slot_discard_requested.connect(controller._on_backpack_slot_discard_requested)
	if controller.view.has_signal("backpack_slot_drag_canceled"):
		controller.view.backpack_slot_drag_canceled.connect(controller._on_backpack_slot_drag_canceled)
	controller.view.cell_hovered.connect(controller._on_cell_hovered)
	controller.view.cell_clicked.connect(controller._on_cell_clicked)
	controller.view.cell_pressed.connect(func(cid, col):
		controller.is_holding = true
		controller.hold_cell_id = cid
		controller.hold_color = col
		controller._trigger_hold_fire()
	)
	controller.view.cell_released.connect(func(): controller.is_holding = false)
	controller.view.key_pressed.connect(controller._on_key_pressed)
