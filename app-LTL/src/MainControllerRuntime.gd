# 계약:
# - 梨낆엫: UI ?낅젰??以묎퀎?섍퀬 ?곹깭 蹂?붾? ?쒖뼱?섎ŉ, 鍮꾩쫰?덉뒪 ?쒕??덉씠??紐⑤뜽怨??몃깽?좊━ 紐⑤뜽??愿由?議곗쑉?쒕떎. ?꾩떆 蹂댁땐 ?곸젏 諛??깆옣 ?곹깭瑜?諛섏쁺?쒕떎.
# - ?낅젰: MainUI(?⑥떆釉?酉?濡쒕????섏떊???ъ슜???명꽣?숈뀡 ?쒓렇??
# - 異쒕젰: ?쒕??덉씠???곹깭 蹂?붿뿉 ?곕Ⅸ MainUI???뚮뜑留??⑥닔 ?몄텧 諛??곗씠??媛깆떊 紐낅졊.
# - 湲덉?: 吏곸젒?곸씤 UI ?쒕줈???뚰떚???앹꽦/諛깊뙥 ?щ’ ?덉씠?꾩썐 援ъ꽦, 吏곸젒?곸씤 UI 而⑦듃濡??몃뱶 李몄“.

# 실행: define the main-scene controller as a Node script and declare class variables.
extends Node
const PreviewControllerScript = preload("res://src/ui/CombatScenePreviewController.gd")
const ArtifactScript = preload("res://src/models/Artifact.gd")
const RunGrowthStateScript = preload("res://src/models/RunGrowthState.gd")
const CreateArtifactFromRewardScript = preload("res://src/vocabulary/reward/CreateArtifactFromReward.gd")
const ApplyGrowthModifiersScript = preload("res://src/vocabulary/progression/ApplyGrowthModifiers.gd")
const RecalculateQueueColorsScript = preload("res://src/vocabulary/combat/RecalculateQueueColors.gd")
const ShiftWeaknessMarkersScript = preload("res://src/vocabulary/combat/ShiftWeaknessMarkers.gd")
const NodeSelectReadModelScript = preload("res://src/ui/read_models/NodeSelectReadModel.gd")
const RewardReadModelScript = preload("res://src/ui/read_models/RewardReadModel.gd")
const CombatFeedbackPresenterScript = preload("res://src/ui/presenters/CombatFeedbackPresenter.gd")

var view
var preview_controller
var current_scene: Dictionary = {}
var disabled_tiles: Array[String] = []
var is_holding: bool = false
var hold_cell_id: String = ""
var hold_color: String = ""
var shift_timer: Timer
var inventory: InventoryModel = null
var held_artifact = null
var held_from_rewards: bool = false
var held_reward_index: int = -1
var local_rewards_list: Array = []
var prev_phase: String = ""
var prev_pin_active: bool = false
var prev_hazard_severity: String = "stable"
var show_victory_overlay: bool = false
var selected_node_index: int = 0
var weakness_shift_step: int = 0

# Progression growth state
var growth_state: RefCounted = null
var is_reveal_vfx_running: bool = false

# ?ㅽ뻾: obtain the parent view container, wire event handlers, and bootstrap initial run state after view is ready.
func _ready() -> void:
	view = get_parent()
	if not view.is_node_ready():
		await view.ready
	inventory = InventoryModel.new(8, 8)

	randomize()
	preview_controller = PreviewControllerScript.new({"seed": randi() & 0x7fffffff, "maxStages": 5, "viewportWidth": 1440, "viewportHeight": 900})

	# Load default growth state
	var default_growth = preview_controller.run.state.get("growth", {})
	growth_state = RunGrowthStateScript.new(default_growth)

	_load_backpack_items_into_inventory()

	view.reset_pressed.connect(_on_reset_pressed)
	view.start_combat_pressed.connect(_on_start_pressed)
	view.hold_fire_pressed.connect(_on_hold_fire_pressed)
	view.repair_pressed.connect(_on_repair_pressed)
	view.claim_rewards_pressed.connect(_on_claim_rewards_pressed)
	view.confirm_proceed_pressed.connect(_on_confirm_proceed_pressed)
	view.confirm_cancel_pressed.connect(_on_confirm_cancel_pressed)
	view.settings_open_pressed.connect(func(): view.toggle_settings())
	view.settings_panel.reset_requested.connect(_on_reset_pressed)
	view.settings_panel.language_changed.connect(func(_locale): _render_scene(current_scene))
	view.settings_panel.screenshake_toggled.connect(func(enabled): view.vfx_manager.shake_enabled = enabled)
	view.settings_panel.fullscreen_toggled.connect(func(toggled): DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if toggled else DisplayServer.WINDOW_MODE_WINDOWED))
	view.node_meta_clicked.connect(_on_node_meta_clicked)
	view.reward_meta_clicked.connect(_on_reward_meta_clicked)
	view.reward_meta_hovered.connect(_on_reward_meta_hovered)
	view.reward_meta_unhovered.connect(_on_reward_meta_unhovered)
	view.discard_zone_input.connect(_on_discard_zone_input)

	# Calibration shop connections
	view.shop_open_pressed.connect(_on_shop_open_pressed)
	view.buy_passive.connect(_on_buy_passive)

	view.repair_overlay_input.connect(func(ev):
		if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
			var phase = str(current_scene.get("phase", ""))
			if phase == "run_complete" and bool(current_scene.get("failed", false)):
				_on_reset_pressed()
			elif phase == "reward_loot" and show_victory_overlay:
				if is_reveal_vfx_running:
					view.skip_reward_reveal_to_silhouettes()
				else:
					show_victory_overlay = false
					is_reveal_vfx_running = true
					view.add_log("[color=#ffd766][VFX] 레비아탄 갑각이 흔들립니다. 보상층이 드러나고 있습니다...[/color]")
					view.battlefield_ui.start_reveal_vfx(local_rewards_list.size(), local_rewards_list, func():
						is_reveal_vfx_running = false
						view.add_log("[color=#a3be8c][VFX] 갑각 파쇄 완료! 보상 회수 단계가 열렸습니다.[/color]")
						_render_scene(current_scene)
					)
					_render_scene(current_scene)
	)
	view.backpack_slot_clicked.connect(_on_backpack_slot_clicked)
	view.backpack_slot_hovered.connect(_on_backpack_slot_hovered)
	view.backpack_slot_unhovered.connect(_on_backpack_slot_unhovered)
	view.cell_hovered.connect(_on_cell_hovered)
	view.cell_clicked.connect(_on_cell_clicked)
	view.cell_pressed.connect(func(cid, col): is_holding = true; hold_cell_id = cid; hold_color = col; _trigger_hold_fire())
	view.cell_released.connect(func(): is_holding = false)
	view.key_pressed.connect(_on_key_pressed)
	view.setup_backpack_slots()
	view.render_backpack(inventory)
	view.setup_settings(view.vfx_manager.shake_enabled, DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN)
	current_scene = preview_controller.reset()
	_recalculate_queue_colors()
	_render_scene(current_scene)
	_setup_shift_timer()

# ?ㅽ뻾: handle interactive hover cell aiming.
func _on_cell_hovered(cell_id: String, _color_name: String) -> void:
	if str(current_scene.get("phase", "")) == "combat":
		current_scene = preview_controller.aim_cell(cell_id, _get_active_queue_color())
		_render_scene(current_scene)

# ?ㅽ뻾: handle interactive click/fire target events, triggering decoupled view VFX.
func _on_cell_clicked(cell_id: String, color_name: String) -> void:
	if str(current_scene.get("phase", "")) != "combat" or cell_id in disabled_tiles:
		return
	var prev_shield = float(current_scene.get("targetPanel", {}).get("shield", 0.0))
	var prev_health = float(current_scene.get("targetPanel", {}).get("health", 0.0))
	var active_color = _get_active_queue_color()
	current_scene = preview_controller.fire(cell_id, active_color)
	var damage = (prev_shield - float(current_scene.get("targetPanel", {}).get("shield", 0.0))) + (prev_health - float(current_scene.get("targetPanel", {}).get("health", 0.0)))
	var status = str(current_scene.get("feedback", {}).get("status", "active"))
	var matched_item = null
	for art_id in inventory.artifacts:
		var art = inventory.artifacts[art_id]
		if str(art.energy_type) == active_color and art.item_type == "drill":
			matched_item = art; break
	view.add_log("[color=#ffd766][아이템 발동] %s (%s) 사용![/color]" % [matched_item.name if matched_item else "알 수 없는 드릴", active_color.to_upper()])
	view.add_log("[color=#66c2cd][타격 좌표: %s | 에너지: %s | 광석 타입: %s | 최종 피해: %.1f][/color]" % [cell_id.to_upper(), active_color.to_upper(), color_name.to_upper(), damage])
	if status == "empty_queue":
		view.add_log("[color=#ff6666][경고] 에너지 큐가 비어 드릴 가동이 중단되었습니다.[/color]")
	var hit_pos = view.get_cell_global_pos(cell_id)
	var start_pos = view.get_extractor_global_pos()
	view.trigger_resonance_beam(start_pos, hit_pos, active_color)
	view.trigger_hit_particles(hit_pos, status, active_color)
	var shake_feedback: Dictionary = CombatFeedbackPresenterScript.project_screenshake(status)
	view.trigger_screenshake(float(shake_feedback.get("duration", 0.08)), float(shake_feedback.get("magnitude", 1.0)))
	disabled_tiles.append(cell_id)
	get_tree().create_timer(0.5).timeout.connect(func():
		disabled_tiles.erase(cell_id)
		if str(current_scene.get("phase", "")) == "combat": _render_scene(current_scene)
	)
	_render_scene(current_scene)

# ?ㅽ뻾: handle hold-to-fire loop ticks.
func _trigger_hold_fire() -> void:
	if not is_holding or str(current_scene.get("phase", "")) != "combat": return
	_on_cell_clicked(hold_cell_id, hold_color)
	await get_tree().create_timer(0.1).timeout
	_trigger_hold_fire()

# ?ㅽ뻾: handle interactive node selection.
func _on_node_meta_clicked(meta: Variant) -> void:
	selected_node_index = int(meta)
	_render_scene(current_scene)

# ?ㅽ뻾: manage placement/rotation/selection inside backpack.
func _on_backpack_slot_clicked(coord: Vector2) -> void:
	if str(current_scene.get("phase", "")) == "combat":
		view.add_log("[color=#ff6666][경고] 전투 중에는 백팩 아이템을 이동할 수 없습니다.[/color]"); return
	if is_reveal_vfx_running:
		return

	if held_artifact != null:
		if held_artifact.item_type == "drill":
			var has_same_color := false
			for art_id in inventory.artifacts:
				var art = inventory.artifacts[art_id]
				if art.item_type == "drill" and art.energy_type == held_artifact.energy_type and art.id != held_artifact.id:
					has_same_color = true
					break
			if has_same_color:
				view.add_log("[color=#ff6666][경고] 이미 백팩에 %s 드릴이 있습니다. 기존 드릴을 먼저 제거하세요.[/color]" % held_artifact.energy_type.to_upper())
				return

		if inventory.can_place_artifact(held_artifact, int(coord.x), int(coord.y)):
			inventory.place_artifact(held_artifact, int(coord.x), int(coord.y))
			view.add_log("[color=#a3be8c][인벤토리] 유물 배치 완료: %s[/color]" % held_artifact.name)

			if held_from_rewards and held_reward_index >= 0 and held_reward_index < local_rewards_list.size():
				var reward_data = local_rewards_list[held_reward_index]

				# Claim reward effect to update gold, xp, and history in growth state
				var next_s = preview_controller.run.apply_combat_input({
					"type": "claim_reward_effect",
					"reward": reward_data
				})
				growth_state.from_dict(next_s.get("growth", {}))
				current_scene = next_s
				view.add_log("[color=#a3be8c][진행] 보상 유물 획득! 골드와 경험치가 지급되었습니다.[/color]")

				# Print telemetry event
				print("TELEMETRY: reward_selected - reward_id: %s, growth: %s" % [reward_data.get("rewardId", ""), JSON.stringify(growth_state.to_dict())])

				local_rewards_list.remove_at(held_reward_index)
				if preview_controller.run != null:
					preview_controller.run.state["pendingRewards"] = local_rewards_list.duplicate(true)

			held_reward_index = -1; held_from_rewards = false; held_artifact = null
			view.update_backpack_ghost(null)

			_apply_growth_modifiers()
			view.render_backpack(inventory)
			if preview_controller.run != null:
				preview_controller.run.state["inventory"] = inventory.to_dict()
			_recalculate_queue_colors()
			current_scene = preview_controller.get_scene()
			_render_scene(current_scene)
		else:
			view.add_log("[color=#ff6666][경고] 충돌 또는 범위 초과로 배치할 수 없습니다.[/color]")
		return
	var slot_id = str(inventory.grid[int(coord.y)][int(coord.x)])
	if not slot_id.is_empty() and inventory.artifacts.has(slot_id):
		held_artifact = inventory.artifacts[slot_id]
		held_from_rewards = false
		held_reward_index = -1
		inventory.remove_artifact(slot_id)
		view.add_log("[color=#ffd766][인벤토리] 유물 선택: %s (이동 또는 [R] 회전)[/color]" % held_artifact.name)
		view.update_backpack_ghost(held_artifact)
		view.render_backpack(inventory)
		if preview_controller.run != null: preview_controller.run.state["inventory"] = inventory.to_dict()

# ?ㅽ뻾: handle slot hovered to show tooltip.
func _on_backpack_slot_hovered(coord: Vector2) -> void:
	if inventory == null or held_artifact != null:
		return
	var slot_id = str(inventory.grid[int(coord.y)][int(coord.x)])
	if not slot_id.is_empty() and inventory.artifacts.has(slot_id):
		view.show_artifact_tooltip(inventory.artifacts[slot_id])
	else:
		view.hide_artifact_tooltip()

# ?ㅽ뻾: handle slot unhovered to hide tooltip.
func _on_backpack_slot_unhovered(_coord: Vector2) -> void:
	view.hide_artifact_tooltip()

# ?ㅽ뻾: handle reward item hovered to show tooltip.
func _on_reward_meta_hovered(meta: Variant) -> void:
	if local_rewards_list.is_empty():
		return
	var idx := int(meta)
	if idx >= 0 and idx < local_rewards_list.size():
		view.show_reward_tooltip(local_rewards_list[idx], _equipped_artifacts())

# ?ㅽ뻾: handle reward item unhovered to hide tooltip.
func _on_reward_meta_unhovered(_meta: Variant) -> void:
	view.hide_artifact_tooltip()

# ?ㅽ뻾: process ESC and R keyboard keys forwarded from view.
func _on_key_pressed(keycode: int) -> void:
	if keycode == KEY_ESCAPE:
		if view.is_shop_visible():
			view.set_shop_visible(false)
		else:
			view.toggle_settings()
	elif keycode == KEY_R:
		if held_artifact != null:
			if str(current_scene.get("phase", "")) == "combat" or (str(current_scene.get("phase", "")) == "reward_loot" and show_victory_overlay): return
			held_artifact.rotate_shape()
			view.add_log("[color=#ffd766][인벤토리] 유물 회전: %s[/color]" % held_artifact.name)
			view.update_backpack_ghost(held_artifact)

# ?ㅽ뻾: render full state scene updates, delegate to sub UI systems.
func _render_scene(scene: Dictionary) -> void:
	current_scene = scene.duplicate(true)
	var phase := str(scene.get("phase", "unknown"))
	if phase != prev_phase:
		if phase == "reward_loot" and prev_phase == "combat":
			show_victory_overlay = true
			var server_rewards = scene.get("reward", {}).get("pendingRewards", [])
			local_rewards_list = server_rewards.duplicate(true)
			view.add_log("[color=#ffd766][시스템] 레비아탄 갑각 채굴 완료! 화면을 클릭해 보상을 확인하세요.[/color]")

		if phase == "node_select": view.add_log("[color=#8fa1b3][시스템] 페이즈 전환: 노드 선택. 탐사할 구역을 선택하세요.[/color]")
		elif phase == "combat": view.add_log("[color=#8fa1b3][시스템] 페이즈 전환: 갑각 채굴 전투 돌입.[/color]")
		elif phase == "reward_loot" and not show_victory_overlay: view.add_log("[color=#8fa1b3][시스템] 페이즈 전환: 유물 회수 및 백팩 정리.[/color]")
		elif phase == "run_complete": view.add_log("[color=#e05353][시스템] 탐사 실패! 레비아탄이 중단되었습니다.[/color]" if bool(scene.get("failed", false)) else "[color=#a3be8c][시스템] 탐사 완료! 유물 회수 성공.[/color]")
		prev_phase = phase
	current_scene["show_victory_overlay"] = show_victory_overlay
	current_scene["is_reveal_vfx_running"] = is_reveal_vfx_running
	if phase == "combat":
		var pin_active = bool(scene.get("hud", {}).get("pin", {}).get("active", false))
		if pin_active != prev_pin_active:
			view.add_log("[color=#e05353][방해요소 발생] 드릴 고정(Pin) 활성화. 다음 턴까지 에너지가 잠깁니다.[/color]" if pin_active else "[color=#a3be8c][방해요소 해제] 드릴 고정(Pin) 해제 완료![/color]")
			prev_pin_active = pin_active
		var hazard_sev = str(scene.get("hud", {}).get("hazard", {}).get("severity", "stable"))
		if hazard_sev != prev_hazard_severity:
			if hazard_sev in ["warning", "critical"]: view.add_log("[color=#e05353][방해요소 작동] 위험도 경보 발생! 위험 수준: %s[/color]" % hazard_sev.to_upper())
			elif hazard_sev == "stable": view.add_log("[color=#a3be8c][방해요소 해제] 위험도 등급 해제! 환경 안정화.[/color]")
			prev_hazard_severity = hazard_sev
	view.set_node_select_text(_node_select_summary(current_scene))
	view.render_scene(current_scene, show_victory_overlay)
	_render_battlefield(current_scene)
	view.update_action_state(current_scene, show_victory_overlay)
	_render_rewards(current_scene)

# ?ㅽ뻾: delegate battlefield rendering to the view.
func _render_battlefield(scene: Dictionary) -> void:
	if not is_reveal_vfx_running:
		view.update_battlefield_disabled(scene, disabled_tiles)

# ?ㅽ뻾: render the interactive reward looting list.
func _render_rewards(scene: Dictionary) -> void:
	if str(scene.get("phase", "")) != "reward_loot": return
	var server_rewards = scene.get("reward", {}).get("pendingRewards", [])
	if local_rewards_list.is_empty() and not server_rewards.is_empty():
		local_rewards_list = server_rewards.duplicate(true)
	var reward_model: Dictionary = RewardReadModelScript.project_tray(local_rewards_list, held_reward_index, held_artifact, held_from_rewards)
	view.set_reward_text(str(reward_model.get("text", "")))
	view.update_discard_zone(str(reward_model.get("discardText", "")), bool(reward_model.get("discardActive", false)))

# 실행: select and package artifact reward.
func _on_reward_meta_clicked(meta: Variant) -> void:
	if is_reveal_vfx_running:
		return
	var clicked_idx := int(meta)
	if held_from_rewards and held_reward_index == clicked_idx and held_artifact != null:
		held_artifact = null
		held_from_rewards = false
		held_reward_index = -1
		view.update_backpack_ghost(null)
		view.add_log("[color=#ffd766][보상 선택] 선택 해제되었습니다.[/color]")
		_render_rewards(current_scene)
		return

	held_reward_index = clicked_idx
	var item_data = local_rewards_list[held_reward_index]
	var create_result: Dictionary = CreateArtifactFromRewardScript.create(item_data, growth_state)
	if bool(create_result.get("ok", false)):
		held_artifact = create_result["artifact"]
		held_from_rewards = true
		view.add_log("[color=#ffd766][보상 선택] %s (%s) 선택됨. 백팩에 배치하세요.[/color]" % [held_artifact.name, str(held_artifact.grade).to_upper()])
		_render_rewards(current_scene)
		view.update_backpack_ghost(held_artifact)
		return

# 실행: drop and delete selected reward or backpack item.
func _on_discard_zone_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if is_reveal_vfx_running:
			return
		if held_artifact != null:
			if held_from_rewards:
				if held_reward_index >= 0 and held_reward_index < local_rewards_list.size():
					local_rewards_list.remove_at(held_reward_index)
					if preview_controller.run != null:
						preview_controller.run.state["pendingRewards"] = local_rewards_list.duplicate(true)

				# Log telemetry event
				print("TELEMETRY: reward_discarded - index: %d, name: %s" % [held_reward_index, held_artifact.name])

				held_reward_index = -1; held_artifact = null; held_from_rewards = false
				view.update_backpack_ghost(null)
				current_scene = preview_controller.get_scene()
				_render_scene(current_scene)
			else:
				view.add_log("[color=#e05353][인벤토리] 백팩 유물 폐기 완료: %s[/color]" % held_artifact.name)

				# Log telemetry event
				print("TELEMETRY: reward_discarded - name: %s" % held_artifact.name)

				held_artifact = null; held_from_rewards = false; held_reward_index = -1
				view.update_backpack_ghost(null)
				if preview_controller.run != null:
					preview_controller.run.state["inventory"] = inventory.to_dict()
				_recalculate_queue_colors()
				current_scene = preview_controller.get_scene()
				_render_scene(current_scene)

# ?ㅽ뻾: start a new combat stage.
func _on_start_pressed() -> void:
	show_victory_overlay = false
	weakness_shift_step = 0
	_apply_growth_modifiers()
	current_scene = preview_controller.start_combat(selected_node_index)
	_recalculate_queue_colors()
	_initialize_random_weaknesses()
	current_scene = preview_controller.get_scene()
	current_scene = preview_controller.aim_cell(str(_current_target(current_scene).get("cellId", "r0c0")), _get_active_queue_color())
	_render_scene(current_scene)

# ?ㅽ뻾: reset run state.
func _on_reset_pressed() -> void:
	show_victory_overlay = false
	selected_node_index = 0
	weakness_shift_step = 0
	randomize()
	preview_controller.seed = randi() & 0x7fffffff
	current_scene = preview_controller.reset()
	disabled_tiles.clear(); local_rewards_list.clear(); held_reward_index = -1; held_artifact = null; held_from_rewards = false
	view.set_confirm_overlay_visible(false)
	view.update_backpack_ghost(null)

	# Apply growth passive starting gold values
	growth_state.gold = growth_state.get_starting_gold()
	growth_state.xp = 0
	preview_controller.run.state["growth"] = growth_state.to_dict()

	_load_backpack_items_into_inventory()
	view.render_backpack(inventory)
	_recalculate_queue_colors()
	_render_scene(current_scene)

# ?ㅽ뻾: trigger hold fire simulation.
func _on_hold_fire_pressed() -> void:
	current_scene = preview_controller.hold_fire(str(_current_target(current_scene).get("cellId", "r0c0")), _get_active_queue_color(), 2)
	_render_scene(current_scene)

# ?ㅽ뻾: request repair on heated core.
func _on_repair_pressed() -> void:
	current_scene = preview_controller.repair()
	_render_scene(current_scene)

# ?ㅽ뻾: claim rewards and proceed, showing confirmation warning if rewards are left.
func _on_claim_rewards_pressed() -> void:
	if not local_rewards_list.is_empty():
		view.set_confirm_overlay_visible(true)
	else:
		_proceed_to_node_select()

# ?ㅽ뻾: confirm and proceed to node select even with remaining rewards.
func _on_confirm_proceed_pressed() -> void:
	view.set_confirm_overlay_visible(false)
	_proceed_to_node_select()

# ?ㅽ뻾: cancel proceeding and return to reward looting.
func _on_confirm_cancel_pressed() -> void:
	view.set_confirm_overlay_visible(false)

# ?ㅽ뻾: execute reward claim and transition.
func _proceed_to_node_select() -> void:
	current_scene = preview_controller.claim_rewards()
	local_rewards_list.clear(); held_reward_index = -1; held_artifact = null; held_from_rewards = false
	selected_node_index = 0
	view.update_backpack_ghost(null)
	_render_scene(current_scene)

# ?ㅽ뻾: load starter backpack items.
func _load_backpack_items_into_inventory() -> void:
	inventory = InventoryModel.new(8, 8)
	var drills = ArtifactScript.get_basic_drills()
	var positions = [Vector2(1, 2), Vector2(4, 1), Vector2(2, 4), Vector2(6, 5)]
	for i in range(drills.size()):
		inventory.place_artifact(drills[i], int(positions[i].x), int(positions[i].y))
	_apply_growth_modifiers()
	if preview_controller != null and preview_controller.run != null:
		preview_controller.run.state["inventory"] = inventory.to_dict()

# ?ㅽ뻾: cycle active item colors to fill queue.
func _recalculate_queue_colors() -> void:
	var run_state = preview_controller.run.state if preview_controller and preview_controller.run else null
	if run_state and run_state.has("combat") and run_state["combat"] != null:
		var capacity := int(run_state["combat"].get("queue", {}).get("capacity", 8))
		var queue_result: Dictionary = RecalculateQueueColorsScript.recalculate(inventory, capacity)
		run_state["combat"]["queue"]["items"] = queue_result.get("items", [])

# ?ㅽ뻾: setup conveyor-belt shift timer.
func _setup_shift_timer() -> void:
	shift_timer = Timer.new()
	shift_timer.wait_time = 1.0; shift_timer.autostart = true
	shift_timer.timeout.connect(_on_shift_timer_timeout)
	add_child(shift_timer)

# ?ㅽ뻾: shift weaknesses left-to-right on timeout.
func _on_shift_timer_timeout() -> void:
	if str(current_scene.get("phase", "")) != "combat": return
	current_scene = preview_controller.run.apply_combat_input({"type": "tick", "ticks": 20})
	if str(current_scene.get("phase", "")) != "combat":
		_render_scene(current_scene); return
	var run_state = preview_controller.run.state
	var weakness_markers = run_state["combat"].get("battlefield", {}).get("weaknessMarkers", [])
	var colors = ["red", "blue", "purple", "green"]
	weakness_shift_step += 1
	var shift_result: Dictionary = ShiftWeaknessMarkersScript.shift(weakness_markers, 3, 10, int(run_state.get("seed", randi())), colors, weakness_shift_step)
	run_state["combat"]["battlefield"]["weaknessMarkers"] = shift_result.get("markers", [])
	var inv_data = run_state.get("inventory", {})
	if inv_data is Dictionary:
		inventory = InventoryModel.new(int(inv_data.get("width", 8)), int(inv_data.get("height", 8)))
		if inv_data.has("artifacts"):
			for art_dict in inv_data["artifacts"]:
				var art = ArtifactScript.new(art_dict)
				inventory.place_artifact(art, art.x, art.y)
	_apply_growth_modifiers()
	view.render_backpack(inventory)
	current_scene = preview_controller.get_scene()
	_render_scene(current_scene)

# ?ㅽ뻾: initialize weaknesses.
func _initialize_random_weaknesses() -> void:
	if not current_scene.has("combat") or current_scene["combat"] == null: return
	var run_state = preview_controller.run.state
	if not run_state.has("combat") or run_state["combat"] == null: return
	var markers = []
	var colors = ["red", "blue", "purple", "green"]
	weakness_shift_step = 0
	for r in range(3):
		for c in range(10):
			markers.append({"cellId": "r%dc%d" % [r, c], "color": colors[randi() % 4]})
	run_state["combat"]["battlefield"]["weaknessMarkers"] = markers
	current_scene = preview_controller.get_scene()

# ?ㅽ뻾: helper to get queue front color.
func _get_active_queue_color() -> String:
	var items: Array = current_scene.get("hud", {}).get("queue", {}).get("items", [])
	return str(items[0]) if not items.is_empty() else "red"

# 실행: return current inventory artifacts as an array for tooltip comparison.
func _equipped_artifacts() -> Array:
	var result: Array = []
	if inventory == null:
		return result
	for art_id in inventory.artifacts:
		result.append(inventory.artifacts[art_id])
	return result

# ?ㅽ뻾: helper to summarize node select candidates.
func _node_select_summary(scene: Dictionary) -> String:
	return str(NodeSelectReadModelScript.project(scene, selected_node_index).get("text", ""))

# 실행: helper to get best target coordinate.
func _current_target(scene: Dictionary) -> Dictionary:
	var aim = scene.get("hud", {}).get("aim", {})
	if aim.get("cellId", null) != null and aim.get("targetColor", null) != null:
		return {"cellId": aim.get("cellId", "r0c0"), "color": aim.get("targetColor", "red")}
	for cell in scene.get("terrain", {}).get("cells", []):
		if cell.get("weakness", null) != null:
			return {"cellId": cell.get("id", "r0c0"), "color": cell.get("weakness", "red")}
	return {"cellId": "r0c0", "color": "red"}

# ?ㅽ뻾: handle calibration shop button toggle.
func _on_shop_open_pressed() -> void:
	if is_reveal_vfx_running:
		return
	view.toggle_shop()
	view.render_shop(growth_state.to_dict())

# ?ㅽ뻾: handle buy passive.
func _on_buy_passive(passive_id: String, cost: int) -> void:
	var next_s = preview_controller.run.apply_combat_input({
		"type": "purchase_passive",
		"passiveId": passive_id,
		"cost": cost
	})
	growth_state.from_dict(next_s.get("growth", {}))
	current_scene = next_s
	_apply_growth_modifiers()
	view.render_backpack(inventory)
	_render_scene(current_scene)
	view.render_shop(growth_state.to_dict())
	view.add_log("[color=#a3be8c][상점] 패시브 구매 완료: %s (Lv %d)[/color]" % [passive_id, growth_state.purchased_passives[passive_id]])

	# Print telemetry event
	print("TELEMETRY: growth_state_changed - passive: %s, lvl: %d, cost: %d" % [passive_id, growth_state.purchased_passives[passive_id], cost])

# ?ㅽ뻾: apply active growth modifiers (cooldown reduction, flat damage bonus).
func _apply_growth_modifiers() -> void:
	if inventory == null or growth_state == null:
		return
	if preview_controller != null and preview_controller.run != null:
		var tuning = preview_controller.run.state.get("tuning", {})
		if tuning is Dictionary:
			ApplyGrowthModifiersScript.apply(inventory, growth_state, tuning)
