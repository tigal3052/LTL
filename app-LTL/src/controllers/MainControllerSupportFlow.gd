# 怨꾩빟:
# - 梨낆엫: MainController??shop, codex, growth modifiers, accessibility persistence support ?먮쫫???뚯쑀?쒕떎.
# - ?낅젰: MainController context, shop purchase ids/costs, accessibility state dictionaries.
# - 異쒕젰: view menu toggles, run growth state mutation, telemetry/log calls, ConfigFile persistence results.
# - 湲덉?: combat/reward flow ownership, view scene registry, shop enablement policy 蹂寃?
#
# ?ㅽ뻾: define the menu/growth/accessibility helper as a stateful controller delegate.
extends RefCounted

const BuildRewardTelemetryScript = preload("res://src/vocabulary/reward/BuildRewardTelemetry.gd")
const CodexDiscoveryStateScript = preload("res://src/vocabulary/reward/CodexDiscoveryState.gd")
const ApplyGrowthModifiersScript = preload("res://src/vocabulary/progression/ApplyGrowthModifiers.gd")
const MainControllerDisplayTextScript = preload("res://src/controllers/MainControllerDisplayText.gd")

# ?ㅽ뻾: handle calibration shop button toggle.
static func on_shop_open_pressed(controller, shop_enabled: bool) -> void:
	if controller._reward_ceremony_active():
		return
	if not shop_enabled:
		if controller.view != null and controller.view.has_method("set_shop_visible"):
			controller.view.set_shop_visible(false)
		if controller.view != null and controller.view.has_method("render_shop"):
			controller.view.render_shop(controller.growth_state.to_dict())
		return
	controller.view.toggle_shop()
	controller.view.render_shop(controller.growth_state.to_dict())

# ?ㅽ뻾: open the artifact codex with play-history discovery data.
static func on_codex_open_pressed(controller) -> void:
	if controller._reward_ceremony_active():
		return
	var reward_table := load_reward_table_for_codex()
	controller.view.toggle_artifact_codex(
		reward_table,
		codex_growth_state_for_view(controller, reward_table),
		false
	)

# ?ㅽ뻾: load the reward table for the codex menu without changing reward RNG state.
static func load_reward_table_for_codex() -> Dictionary:
	var path := "res://src/data/reward-table.json"
	if not FileAccess.file_exists(path):
		return {"rewards": []}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {"rewards": []}
	var parsed = JSON.parse_string(file.get_as_text())
	return parsed if parsed is Dictionary else {"rewards": []}

# ?ㅽ뻾: build codex growth state with starter discoveries and debug visibility.
static func codex_growth_state_for_view(controller, reward_table: Dictionary) -> Dictionary:
	var starter_growth := CodexDiscoveryStateScript.with_starter_discoveries(controller.growth_state.to_dict(), reward_table, controller.selected_start_color)
	return CodexDiscoveryStateScript.for_debug(starter_growth, reward_table, controller.codex_force_all_discovered)

# ?ㅽ뻾: toggle debug discovery visibility and refresh an open codex.
static func toggle_codex_force_all_discovered(controller) -> void:
	controller.codex_force_all_discovered = not controller.codex_force_all_discovered
	controller._append_localized_log("#c8a96b", "log.debug.codex_discovery_toggle", [MainControllerDisplayTextScript.toggle_state_label(controller.codex_force_all_discovered)])
	if not (controller.view.has_method("is_artifact_codex_visible") and controller.view.is_artifact_codex_visible()):
		return
	var reward_table: Dictionary = controller.view.current_codex_reward_table.duplicate(true)
	if reward_table.is_empty():
		reward_table = load_reward_table_for_codex()
	var codex_growth := codex_growth_state_for_view(controller, reward_table)
	controller.view.render_artifact_codex(reward_table, codex_growth, bool(controller.view.current_codex_debug_all))

# ?ㅽ뻾: handle passive shop purchases.
static func on_buy_passive(controller, passive_id: String, cost: int, shop_enabled: bool) -> void:
	if not shop_enabled:
		_close_disabled_shop(controller)
		return
	var before_growth: Dictionary = controller.growth_state.to_dict()
	var next_s = controller.preview_controller.run.apply_combat_input({
		"type": "purchase_passive",
		"passiveId": passive_id,
		"cost": cost
	})
	var after_growth: Dictionary = next_s.get("growth", {}).duplicate(true)
	controller.growth_state.from_dict(after_growth)
	controller.current_scene = controller.preview_controller.get_scene()
	apply_growth_modifiers(controller)
	controller.view.render_backpack(controller.inventory)
	controller._render_scene(controller.current_scene)
	controller.view.render_shop(controller.growth_state.to_dict())
	controller._append_localized_log("#a3be8c", "log.shop.passive_purchased", [
		MainControllerDisplayTextScript.passive_display_label(passive_id),
		controller.growth_state.purchased_passives[passive_id]
	])

	var telemetry := BuildRewardTelemetryScript.build_growth_state_changed("passive_purchase", before_growth, after_growth)
	telemetry["passive_id"] = passive_id
	telemetry["level"] = controller.growth_state.purchased_passives[passive_id]
	telemetry["cost"] = cost
	controller._emit_ui_telemetry(telemetry)

# ?ㅽ뻾: handle base shop item or character purchases.
static func on_buy_base_item(controller, item_id: String, shop_enabled: bool) -> void:
	if not shop_enabled:
		_close_disabled_shop(controller)
		return
	var before_growth: Dictionary = controller.growth_state.to_dict()
	if not controller.growth_state.purchase_base_item(item_id):
		controller._append_localized_log("#bf616a", "log.shop.base_purchase_failed", [MainControllerDisplayTextScript.base_shop_item_display_label(item_id)])
		controller.view.render_shop(controller.growth_state.to_dict())
		return
	if controller.preview_controller != null and controller.preview_controller.run != null:
		controller.preview_controller.run.state["growth"] = controller.growth_state.to_dict()
	controller.current_scene["growth"] = controller.growth_state.to_dict()
	controller.view.render_shop(controller.growth_state.to_dict())
	controller._render_scene(controller.current_scene)
	controller._append_localized_log("#a3be8c", "log.shop.base_purchase_complete", [MainControllerDisplayTextScript.base_shop_item_display_label(item_id)])
	controller._emit_ui_telemetry({
		"event": "base_shop_purchase",
		"item_id": item_id,
		"gold_delta": int(controller.growth_state.to_dict().get("gold", 0)) - int(before_growth.get("gold", 0)),
		"xp_delta": int(controller.growth_state.to_dict().get("xp", 0)) - int(before_growth.get("xp", 0))
	})

# ?ㅽ뻾: apply active growth modifiers to inventory and tuning.
static func apply_growth_modifiers(controller) -> void:
	if controller.inventory == null or controller.growth_state == null:
		return
	if controller.preview_controller != null and controller.preview_controller.run != null:
		var tuning = controller.preview_controller.run.state.get("tuning", {})
		if tuning is Dictionary:
			ApplyGrowthModifiersScript.apply(controller.inventory, controller.growth_state, tuning)

# ?ㅽ뻾: apply accessibility settings to the VFX manager.
static func apply_accessibility_state(controller) -> void:
	if controller.view == null or controller.view.vfx_manager == null:
		return
	if controller.view.vfx_manager.has_method("set_accessibility_state"):
		controller.view.vfx_manager.set_accessibility_state(controller.accessibility_state)
		return
	controller.view.vfx_manager.shake_enabled = bool(controller.accessibility_state.get("screenshake", true))

# ?ㅽ뻾: persist accessibility settings to a ConfigFile path.
static func save_accessibility_state_to_path(path: String, section: String, state: Dictionary) -> int:
	var config := ConfigFile.new()
	var normalized := normalized_accessibility_state(state)
	for key in normalized.keys():
		config.set_value(section, key, normalized[key])
	return config.save(path)

# ?ㅽ뻾: load accessibility settings from a ConfigFile path.
static func load_accessibility_state_from_path(path: String, section: String) -> Dictionary:
	var config := ConfigFile.new()
	var result := config.load(path)
	if result != OK:
		return normalized_accessibility_state({})
	return normalized_accessibility_state({
		"screenshake": config.get_value(section, "screenshake", true),
		"reducedFlash": config.get_value(section, "reducedFlash", false),
		"reducedParticles": config.get_value(section, "reducedParticles", false),
		"holdFireAssist": config.get_value(section, "holdFireAssist", false)
	})

# ?ㅽ뻾: coerce optional accessibility keys into the stable runtime state shape.
static func normalized_accessibility_state(state: Dictionary = {}) -> Dictionary:
	return {
		"screenshake": bool(state.get("screenshake", true)),
		"reducedFlash": bool(state.get("reducedFlash", false)),
		"reducedParticles": bool(state.get("reducedParticles", false)),
		"holdFireAssist": bool(state.get("holdFireAssist", false))
	}

# ?ㅽ뻾: force disabled shop UI closed without mutating run state.
static func _close_disabled_shop(controller) -> void:
	if controller.view != null and controller.view.has_method("set_shop_visible"):
		controller.view.set_shop_visible(false)
	if controller.view != null and controller.view.has_method("render_shop"):
		controller.view.render_shop(controller.growth_state.to_dict())
