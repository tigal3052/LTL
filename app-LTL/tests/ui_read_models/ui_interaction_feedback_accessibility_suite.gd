extends "res://tests/support/UiReadModelTestSuite.gd"

func run_all_tests() -> Dictionary:
	failures.clear()
	test_backpack_drag_feedback_preserves_slot_visuals_while_dragging()
	test_backpack_drag_feedback_restores_slot_modulate_after_reward_drop()
	test_backpack_drag_feedback_restores_slot_alpha_after_reward_drop()
	test_interaction_fx_preserves_container_layout_children()
	test_interaction_fx_skips_shader_on_panel_slots()
	test_hold_fire_stops_when_overload_repair_starts()
	test_main_controller_hold_fire_assist_expands_burst()
	test_main_controller_accessibility_state_persists_to_config()
	test_combat_clicks_block_while_repair_or_aim_lock_is_active()
	test_main_scene_wires_hit_particle_template()
	test_vfx_manager_accessibility_state_toggles_flash_and_particles()
	return _result()

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

# ??쎈뻬: verify hover polish never translates children that are owned by layout containers.
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
	var stopped := MainControllerCombatFlowScript.should_continue_hold_fire({
		"phase": "combat",
		"feedback": {"status": "empty_queue"},
		"hud": {"repair": {"active": true}, "queue": {"items": []}}
	}, true)
	var active := MainControllerCombatFlowScript.should_continue_hold_fire({
		"phase": "combat",
		"feedback": {"status": "match"},
		"hud": {"repair": {"active": false}, "queue": {"items": ["red"]}}
	}, true)
	_assert_eq(stopped, false, "hold-fire stops once overload repair begins")
	_assert_eq(active, true, "hold-fire continues only while combat can actually keep firing")

func test_main_controller_hold_fire_assist_expands_burst() -> void:
	_assert_eq(MainControllerCombatFlowScript.hold_fire_burst_count({}), 2, "hold-fire assist keeps the default two-shot burst when accessibility assist is off")
	_assert_eq(MainControllerCombatFlowScript.hold_fire_burst_count({"holdFireAssist": true}), 4, "hold-fire assist expands the burst window for accessibility mode")

func test_main_controller_accessibility_state_persists_to_config() -> void:
	var MainControllerScript = load("res://src/MainController.gd")
	_assert(MainControllerScript != null, "main controller loads for accessibility persistence")
	if MainControllerScript == null:
		return
	var writer = MainControllerScript.new()
	var reader = MainControllerScript.new()
	_assert(writer.has_method("save_accessibility_state_to_path"), "main controller exposes a config-save helper for accessibility state")
	_assert(reader.has_method("load_accessibility_state_from_path"), "main controller exposes a config-load helper for accessibility state")
	if not writer.has_method("save_accessibility_state_to_path") or not reader.has_method("load_accessibility_state_from_path"):
		writer.free()
		reader.free()
		return
	var save_path := "user://tmp-accessibility-settings.cfg"
	writer.accessibility_state = {
		"screenshake": false,
		"reducedFlash": true,
		"reducedParticles": true,
		"holdFireAssist": true
	}
	var save_result := int(writer.call("save_accessibility_state_to_path", save_path))
	_assert_eq(save_result, OK, "accessibility-state helper saves the config file successfully")
	var loaded: Dictionary = reader.call("load_accessibility_state_from_path", save_path)
	_assert_eq(loaded.get("screenshake", true), false, "persisted accessibility state restores screenshake")
	_assert_eq(loaded.get("reducedFlash", false), true, "persisted accessibility state restores reduced flash")
	_assert_eq(loaded.get("reducedParticles", false), true, "persisted accessibility state restores reduced particles")
	_assert_eq(loaded.get("holdFireAssist", false), true, "persisted accessibility state restores hold-fire assist")
	writer.free()
	reader.free()

func test_combat_clicks_block_while_repair_or_aim_lock_is_active() -> void:
	var blocked := MainControllerCombatFlowScript.can_accept_combat_click({
		"phase": "combat",
		"hud": {"repair": {"active": true}, "aim": {"canFire": false}}
	}, "r0c0", [])
	var ready := MainControllerCombatFlowScript.can_accept_combat_click({
		"phase": "combat",
		"hud": {"repair": {"active": false}, "aim": {"canFire": true}}
	}, "r0c0", [])
	_assert_eq(blocked, false, "combat clicks stop while overload repair is active")
	_assert_eq(ready, true, "combat clicks resume only when aim can fire again")

func test_main_scene_wires_hit_particle_template() -> void:
	var MainScene = load("res://src/Main.tscn")
	_assert(MainScene != null, "main scene loads for hit-particle template wiring contract")
	if MainScene == null:
		return
	var main_instance = MainScene.instantiate()
	_assert(main_instance != null, "main scene instantiates for hit-particle template wiring contract")
	if main_instance == null:
		return
	var particle_template = main_instance.get_node_or_null("ParticleTemplate") as CPUParticles2D
	var vfx_manager = main_instance.get_node_or_null("VFXManager") as Node2D
	var scene_text := FileAccess.get_file_as_string("res://src/Main.tscn")
	_assert(particle_template != null, "main scene keeps the particle template node for hit-particle bursts")
	_assert(vfx_manager != null, "main scene exposes the VFX manager for hit-particle bursts")
	_assert(scene_text.contains("particle_template = NodePath(\"../ParticleTemplate\")"), "main scene serializes the VFXManager particle_template wiring to the shared ParticleTemplate node")
	main_instance.free()

func test_vfx_manager_accessibility_state_toggles_flash_and_particles() -> void:
	var vfx = VFXManagerScript.new()
	vfx.set_accessibility_state({
		"screenshake": false,
		"reducedFlash": true,
		"reducedParticles": true
	})
	_assert_eq(vfx.shake_enabled, false, "vfx accessibility state can disable screenshake")
	_assert_eq(vfx.flash_enabled, false, "vfx accessibility state converts reduced flash into dimmed beam flashes")
	_assert_eq(vfx.particles_enabled, false, "vfx accessibility state can suppress particles entirely")
	vfx.free()
