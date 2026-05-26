# 계약:
# - 책임: UI 입력을 중계하고 상태 변화를 제어하며, 비즈니스 시뮬레이션 모델과 인벤토리 모델을 관리 조율한다. 임시 보충 상점 및 성장 상태를 반영한다.
# - 입력: MainUI(패시브 뷰)로부터 수신한 사용자 인터랙션 시그널.
# - 출력: 시뮬레이션 상태 변화에 따른 MainUI의 렌더링 함수 호출 및 데이터 갱신 명령.
# - 금지: 직접적인 UI 드로잉/파티클 생성/백팩 슬롯 레이아웃 구성, 직접적인 UI 컨트롤 노드 참조.

# 실행: define the main-scene controller as a Node script and declare class variables.
extends Node
const PreviewControllerScript = preload("res://src/ui/CombatScenePreviewController.gd")
const ArtifactScript = preload("res://src/models/Artifact.gd")
const RunGrowthStateScript = preload("res://src/models/RunGrowthState.gd")

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

# Progression growth state
var growth_state: RefCounted = null
var is_reveal_vfx_running: bool = false

# 실행: obtain the parent view container, wire event handlers, and bootstrap initial run state after view is ready.
func _ready() -> void:
	view = get_parent()
	if not view.is_node_ready():
		await view.ready
	inventory = InventoryModel.new(8, 8)
	
	preview_controller = PreviewControllerScript.new({"seed": 61, "maxStages": 5, "viewportWidth": 1440, "viewportHeight": 900})
	
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
	view.settings_panel.screenshake_toggled.connect(func(enabled): view.vfx_manager.shake_enabled = enabled)
	view.settings_panel.fullscreen_toggled.connect(func(toggled): DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if toggled else DisplayServer.WINDOW_MODE_WINDOWED))
	view.node_meta_clicked.connect(_on_node_meta_clicked)
	view.reward_meta_clicked.connect(_on_reward_meta_clicked)
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
				if not is_reveal_vfx_running:
					show_victory_overlay = false
					is_reveal_vfx_running = true
					view.add_log("[color=#ffd766][VFX] 레비아탄 갑각 표면의 채집 레이더가 지진 진동을 감지합니다...[/color]")
					view.battlefield_ui.start_reveal_vfx(local_rewards_list.size(), local_rewards_list, func():
						is_reveal_vfx_running = false
						view.add_log("[color=#a3be8c][VFX] 구덩이 덮개 폭파 완료! 유물 회수 트레이가 전개되었습니다.[/color]")
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

# 실행: handle interactive hover cell aiming.
func _on_cell_hovered(cell_id: String, _color_name: String) -> void:
	if str(current_scene.get("phase", "")) == "combat":
		current_scene = preview_controller.aim_cell(cell_id, _get_active_queue_color())
		_render_scene(current_scene)

# 실행: handle interactive click/fire target events, triggering decoupled view VFX.
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
	view.add_log("[color=#ffd766][아이템 발동] %s (%s) 사용![/color]" % [matched_item.name if matched_item else "익명 드릴", active_color.to_upper()])
	view.add_log("[color=#66c2cd][지형 타격] 좌표: %s | 사용 에너지: %s | 광석 타입: %s | 최종 데미지: %.1f[/color]" % [cell_id.to_upper(), active_color.to_upper(), color_name.to_upper(), damage])
	if status == "empty_queue":
		view.add_log("[color=#ff6666][경고] 에너지 큐 고갈! 드릴 가동이 중단되었습니다.[/color]")
	var hit_pos = view.get_cell_global_pos(cell_id)
	var start_pos = view.get_extractor_global_pos()
	view.trigger_resonance_beam(start_pos, hit_pos, active_color)
	view.trigger_hit_particles(hit_pos, status, active_color)
	if status in ["match", "clear"]:
		view.trigger_screenshake(0.18, 7.0)
	elif status == "mismatch":
		view.trigger_screenshake(0.12, 3.0)
	else:
		view.trigger_screenshake(0.08, 1.0)
	disabled_tiles.append(cell_id)
	get_tree().create_timer(0.5).timeout.connect(func():
		disabled_tiles.erase(cell_id)
		if str(current_scene.get("phase", "")) == "combat": _render_scene(current_scene)
	)
	_render_scene(current_scene)

# 실행: handle hold-to-fire loop ticks.
func _trigger_hold_fire() -> void:
	if not is_holding or str(current_scene.get("phase", "")) != "combat": return
	_on_cell_clicked(hold_cell_id, hold_color)
	await get_tree().create_timer(0.1).timeout
	_trigger_hold_fire()

# 실행: handle interactive node selection.
func _on_node_meta_clicked(meta: Variant) -> void:
	selected_node_index = int(meta)
	_render_scene(current_scene)

# 실행: manage placement/rotation/selection inside backpack.
func _on_backpack_slot_clicked(coord: Vector2) -> void:
	if str(current_scene.get("phase", "")) == "combat":
		view.add_log("[color=#ff6666][경고] 전투 단계에서는 백팩 내부의 아이템을 움직일 수 없습니다.[/color]"); return
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
				view.add_log("[color=#ff6666][경고] 이미 백팩에 %s색 채굴기가 존재합니다. 먼저 기존 채굴기를 제거하십시오.[/color]" % held_artifact.energy_type.to_upper())
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
				view.add_log("[color=#a3be8c][진행도] 보상 유물 획득! 골드와 경험치가 지급되었습니다.[/color]")
				
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
			view.add_log("[color=#ff6666][경고] 충돌 또는 범위를 벗어나 배치할 수 없습니다.[/color]")
		return
	var slot_id = str(inventory.grid[int(coord.y)][int(coord.x)])
	if not slot_id.is_empty() and inventory.artifacts.has(slot_id):
		held_artifact = inventory.artifacts[slot_id]
		held_from_rewards = false
		held_reward_index = -1
		inventory.remove_artifact(slot_id)
		view.add_log("[color=#ffd766][인벤토리] 유물 선택: %s (이동 또는 [R]키로 회전)[/color]" % held_artifact.name)
		view.update_backpack_ghost(held_artifact)
		view.render_backpack(inventory)
		if preview_controller.run != null: preview_controller.run.state["inventory"] = inventory.to_dict()

# 실행: handle slot hovered to show tooltip.
func _on_backpack_slot_hovered(coord: Vector2) -> void:
	if inventory == null or held_artifact != null:
		return
	var slot_id = str(inventory.grid[int(coord.y)][int(coord.x)])
	if not slot_id.is_empty() and inventory.artifacts.has(slot_id):
		view.show_artifact_tooltip(inventory.artifacts[slot_id])
	else:
		view.hide_artifact_tooltip()

# 실행: handle slot unhovered to hide tooltip.
func _on_backpack_slot_unhovered(_coord: Vector2) -> void:
	view.hide_artifact_tooltip()

# 실행: process ESC and R keyboard keys forwarded from view.
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
			view.add_log("[color=#ffd766][인벤토리] 유물 회전됨: %s[/color]" % held_artifact.name)
			view.update_backpack_ghost(held_artifact)

# 실행: render full state scene updates, delegate to sub UI systems.
func _render_scene(scene: Dictionary) -> void:
	current_scene = scene.duplicate(true)
	var phase := str(scene.get("phase", "unknown"))
	if phase != prev_phase:
		if phase == "reward_loot" and prev_phase == "combat":
			show_victory_overlay = true
			var server_rewards = scene.get("reward", {}).get("pendingRewards", [])
			local_rewards_list = server_rewards.duplicate(true)
			view.add_log("[color=#ffd766][시스템] 레비아탄 갑각 채굴 완료! 화면을 클릭해 보상을 발굴하십시오.[/color]")
			
		if phase == "node_select": view.add_log("[color=#8fa1b3][시스템] 페이즈 전환: 노드 선택. 탐사할 구역을 선택하십시오.[/color]")
		elif phase == "combat": view.add_log("[color=#8fa1b3][시스템] 페이즈 전환: 갑각 채굴 전투 돌입.[/color]")
		elif phase == "reward_loot" and not show_victory_overlay: view.add_log("[color=#8fa1b3][시스템] 페이즈 전환: 유물 회수 및 백팩 정렬.[/color]")
		elif phase == "run_complete": view.add_log("[color=#e05353][시스템] 탐사 실패! 시뮬레이터가 중단되었습니다.[/color]" if bool(scene.get("failed", false)) else "[color=#a3be8c][시스템] 탐사 완료! 유물 회수 성공.[/color]")
		prev_phase = phase
	current_scene["show_victory_overlay"] = show_victory_overlay
	current_scene["is_reveal_vfx_running"] = is_reveal_vfx_running
	if phase == "combat":
		var pin_active = bool(scene.get("hud", {}).get("pin", {}).get("active", false))
		if pin_active != prev_pin_active:
			view.add_log("[color=#e05353][방해요소 발생] 드릴 고정(Pin) 활성화! 다음 턴까지 에너지가 잠깁니다.[/color]" if pin_active else "[color=#a3be8c][방해요소 해제] 드릴 고정(Pin) 해제 완료![/color]")
			prev_pin_active = pin_active
		var hazard_sev = str(scene.get("hud", {}).get("hazard", {}).get("severity", "stable"))
		if hazard_sev != prev_hazard_severity:
			if hazard_sev in ["warning", "critical"]: view.add_log("[color=#e05353][방해요소 작동] 위험도 경보 발생! 위험 수준: %s[/color]" % hazard_sev.to_upper())
			elif hazard_sev == "stable": view.add_log("[color=#a3be8c][방해요소 해제] 위험도 등급 해제! 환경 안정화됨.[/color]")
			prev_hazard_severity = hazard_sev
	view.set_node_select_text(_node_select_summary(current_scene))
	view.render_scene(current_scene, show_victory_overlay)
	_render_battlefield(current_scene)
	view.update_action_state(current_scene, show_victory_overlay)
	_render_rewards(current_scene)

# 실행: delegate battlefield rendering to the view.
func _render_battlefield(scene: Dictionary) -> void:
	if not is_reveal_vfx_running:
		view.update_battlefield_disabled(scene, disabled_tiles)

# 실행: render the interactive reward looting list.
func _render_rewards(scene: Dictionary) -> void:
	if str(scene.get("phase", "")) != "reward_loot": return
	var server_rewards = scene.get("reward", {}).get("pendingRewards", [])
	if local_rewards_list.is_empty() and not server_rewards.is_empty():
		local_rewards_list = server_rewards.duplicate(true)
	var lines: PackedStringArray = []
	if local_rewards_list.is_empty():
		lines.append("No pending rewards left. Press 'Claim Rewards' to select your next node.")
	else:
		lines.append("Click an item to hold it, then drop it in the Discard Zone or backpack grid:\n")
		for idx in range(local_rewards_list.size()):
			var r = local_rewards_list[idx]
			var presentation = r.get("presentation", {})
			var badge = presentation.get("badge", "보상")
			lines.append("▶ [url=%d]%s x%d (%s)[/url] [color=#e5c07b][%s][/color]%s" % [idx, str(r.get("kind", "reward")), int(r.get("qty", 0)), str(r.get("rarity", "common")).to_upper(), badge, " [HOLDING]" if held_reward_index == idx else ""])
	view.set_reward_text("\n".join(lines))
	if held_artifact != null:
		if held_from_rewards:
			if held_reward_index >= 0 and held_reward_index < local_rewards_list.size():
				view.update_discard_zone("🗑 DISCARD ZONE\n[Click here to discard %s]" % str(local_rewards_list[held_reward_index].get("kind", "")), true)
		else:
			view.update_discard_zone("🗑 DISCARD ZONE\n[Click here to discard %s]" % held_artifact.name, true)
	else:
		view.update_discard_zone("🗑 DISCARD ZONE\n[Select reward or backpack item to drop here]", false)

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
	var rarity = str(item_data.get("arity", item_data.get("rarity", "common")))
	var art_name := str(item_data.get("kind", "New Artifact"))
	
	# Determine grid shapes based on name and category
	var grid_shape = [[1, 1]] if "Drill" in art_name or "Core" in art_name else ([[1], [1]] if "Lens" in art_name or "Capacitor" in art_name else ([[1, 1], [1, 1]] if "Resonance" in art_name or "Reactor" in art_name else [[1]]))
	
	# Set base cooldown and damage stats based on rarity
	var cooldown := 80
	var damage := 1.0
	if rarity == "rare":
		cooldown = 70
		damage = 1.3
	elif rarity == "epic":
		cooldown = 60
		damage = 1.6
	elif rarity == "legendary":
		cooldown = 50
		damage = 2.0
	elif rarity == "mythic":
		cooldown = 40
		damage = 2.5
		
	# Apply active cooldown modifier
	var final_cooldown = int(cooldown * growth_state.get_cooldown_modifier())
	
	# Determine if it's a beacon
	var item_type := "drill"
	var payload = item_data.get("payload", {})
	if payload.get("item_type", "") == "beacon" or "Beacon" in art_name or "beacon" in art_name:
		item_type = "beacon"
		
	var beacon_cooldown_mod = int(payload.get("beacon_cooldown_mod", 0))
	var beacon_damage_mod = float(payload.get("beacon_damage_mod", 0.0))
	if item_type == "beacon" and beacon_cooldown_mod == 0 and beacon_damage_mod == 0.0:
		if rarity == "common":
			beacon_cooldown_mod = -10
			beacon_damage_mod = 0.1
		elif rarity == "rare":
			beacon_cooldown_mod = -15
			beacon_damage_mod = 0.3
		elif rarity == "epic":
			beacon_cooldown_mod = -25
			beacon_damage_mod = 0.6
		elif rarity == "legendary":
			beacon_cooldown_mod = -30
			beacon_damage_mod = 1.0
		elif rarity == "mythic":
			beacon_cooldown_mod = -40
			beacon_damage_mod = 1.5
		
	var energy_type = str(payload.get("energy_type", payload.get("energyType", "red")))
		
	held_artifact = ArtifactScript.new({
		"id": "reward_%d" % randi(), "name": art_name, "shape": grid_shape, "energyType": energy_type,
		"baseCooldownTicks": final_cooldown, "synergy": {"type": "same_color", "value": 2},
		"damage": damage, "grade": rarity, "item_type": item_type,
		"beacon_cooldown_mod": beacon_cooldown_mod, "beacon_damage_mod": beacon_damage_mod
	})
	held_from_rewards = true
	view.add_log("[color=#ffd766][보상 선택] %s (%s) 선택됨. 백팩을 클릭해 배치하십시오.[/color]" % [art_name, rarity.to_upper()])
	_render_rewards(current_scene)
	view.update_backpack_ghost(held_artifact)

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

# 실행: start a new combat stage.
func _on_start_pressed() -> void:
	show_victory_overlay = false
	_apply_growth_modifiers()
	current_scene = preview_controller.start_combat(selected_node_index)
	_recalculate_queue_colors()
	_initialize_random_weaknesses()
	current_scene = preview_controller.get_scene()
	current_scene = preview_controller.aim_cell(str(_current_target(current_scene).get("cellId", "r0c0")), _get_active_queue_color())
	_render_scene(current_scene)

# 실행: reset run state.
func _on_reset_pressed() -> void:
	show_victory_overlay = false
	selected_node_index = 0
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

# 실행: trigger hold fire simulation.
func _on_hold_fire_pressed() -> void:
	current_scene = preview_controller.hold_fire(str(_current_target(current_scene).get("cellId", "r0c0")), _get_active_queue_color(), 2)
	_render_scene(current_scene)

# 실행: request repair on heated core.
func _on_repair_pressed() -> void:
	current_scene = preview_controller.repair()
	_render_scene(current_scene)

# 실행: claim rewards and proceed, showing confirmation warning if rewards are left.
func _on_claim_rewards_pressed() -> void:
	if not local_rewards_list.is_empty():
		view.set_confirm_overlay_visible(true)
	else:
		_proceed_to_node_select()

# 실행: confirm and proceed to node select even with remaining rewards.
func _on_confirm_proceed_pressed() -> void:
	view.set_confirm_overlay_visible(false)
	_proceed_to_node_select()

# 실행: cancel proceeding and return to reward looting.
func _on_confirm_cancel_pressed() -> void:
	view.set_confirm_overlay_visible(false)

# 실행: execute reward claim and transition.
func _proceed_to_node_select() -> void:
	current_scene = preview_controller.claim_rewards()
	local_rewards_list.clear(); held_reward_index = -1; held_artifact = null; held_from_rewards = false
	selected_node_index = 0
	view.update_backpack_ghost(null)
	_render_scene(current_scene)

# 실행: load starter backpack items.
func _load_backpack_items_into_inventory() -> void:
	inventory = InventoryModel.new(8, 8)
	var drills = ArtifactScript.get_basic_drills()
	var positions = [Vector2(1, 2), Vector2(4, 1), Vector2(2, 4), Vector2(6, 5)]
	for i in range(drills.size()):
		inventory.place_artifact(drills[i], int(positions[i].x), int(positions[i].y))
	_apply_growth_modifiers()
	if preview_controller != null and preview_controller.run != null:
		preview_controller.run.state["inventory"] = inventory.to_dict()

# 실행: cycle active item colors to fill queue.
func _recalculate_queue_colors() -> void:
	var active_colors: Array[String] = []
	for art_id in inventory.artifacts:
		var art = inventory.artifacts[art_id]
		if art.item_type == "drill":
			var c = str(art.energy_type)
			if not c in active_colors: active_colors.append(c)
	if active_colors.is_empty(): active_colors.append("red")
	var run_state = preview_controller.run.state if preview_controller and preview_controller.run else null
	if run_state and run_state.has("combat") and run_state["combat"] != null:
		run_state["combat"]["queue"]["items"] = []
		for i in range(8): run_state["combat"]["queue"]["items"].append(active_colors[i % active_colors.size()])

# 실행: setup conveyor-belt shift timer.
func _setup_shift_timer() -> void:
	shift_timer = Timer.new()
	shift_timer.wait_time = 1.0; shift_timer.autostart = true
	shift_timer.timeout.connect(_on_shift_timer_timeout)
	add_child(shift_timer)

# 실행: shift weaknesses left-to-right on timeout.
func _on_shift_timer_timeout() -> void:
	if str(current_scene.get("phase", "")) != "combat": return
	current_scene = preview_controller.run.apply_combat_input({"type": "tick", "ticks": 20})
	if str(current_scene.get("phase", "")) != "combat":
		_render_scene(current_scene); return
	var run_state = preview_controller.run.state
	var weakness_markers = run_state["combat"].get("battlefield", {}).get("weaknessMarkers", [])
	var new_markers = []
	var colors = ["red", "blue", "purple", "green"]
	for marker in weakness_markers:
		var cell_id = str(marker.get("cellId", ""))
		if cell_id.begins_with("r") and "c" in cell_id:
			var parts = cell_id.substr(1).split("c")
			var new_c = int(parts[1]) + 1
			if new_c < 10:
				new_markers.append({"cellId": "r%sc%d" % [parts[0], new_c], "color": marker.get("color", "red")})
	for r in range(3):
		new_markers.append({"cellId": "r%dc0" % r, "color": colors[randi() % 4]})
	run_state["combat"]["battlefield"]["weaknessMarkers"] = new_markers
	var inv_data = run_state.get("inventory", {})
	if inv_data is Dictionary:
		inventory = InventoryModel.new(int(inv_data.get("width", 8)), int(inv_data.get("height", 8)))
		if inv_data.has("artifacts"):
			for art_dict in inv_data["artifacts"]:
				var art = ArtifactScript.new(art_dict)
				inventory.place_artifact(art, art.x, art.y)
	_apply_growth_modifiers()
	current_scene = preview_controller.get_scene()
	_render_scene(current_scene)

# 실행: initialize weaknesses.
func _initialize_random_weaknesses() -> void:
	if not current_scene.has("combat") or current_scene["combat"] == null: return
	var run_state = preview_controller.run.state
	if not run_state.has("combat") or run_state["combat"] == null: return
	var markers = []
	var colors = ["red", "blue", "purple", "green"]
	for r in range(3):
		for c in range(10):
			markers.append({"cellId": "r%dc%d" % [r, c], "color": colors[randi() % 4]})
	run_state["combat"]["battlefield"]["weaknessMarkers"] = markers
	current_scene = preview_controller.get_scene()

# 실행: helper to get queue front color.
func _get_active_queue_color() -> String:
	var items: Array = current_scene.get("hud", {}).get("queue", {}).get("items", [])
	return str(items[0]) if not items.is_empty() else "red"

# 실행: helper to summarize node select candidates.
func _node_select_summary(scene: Dictionary) -> String:
	var lines: PackedStringArray = []
	var candidates: Array = scene.get("nodeSelect", {}).get("candidates", [])
	for idx in range(candidates.size()):
		var candidate = candidates[idx]
		var label = str(candidate.get("label", candidate.get("id", "?")))
		var weakness = str(candidate.get("weaknessLabel", ""))
		var is_selected = (idx == selected_node_index)
		var text = "%s  [%s]" % [label, weakness]
		if is_selected:
			text = "[b][color=#ffd766]▶ %s (선택됨)[/color][/b]" % text
		else:
			text = "▷ %s" % text
		lines.append("[url=%d]%s[/url]" % [idx, text])
	return "Node Select\nNo candidates available." if lines.is_empty() else "Node Select\n이동할 노드를 선택하고 게임 시작 버튼을 누르세요:\n\n" + "\n".join(lines)

# 실행: helper to get best target coordinate.
func _current_target(scene: Dictionary) -> Dictionary:
	var aim = scene.get("hud", {}).get("aim", {})
	if aim.get("cellId", null) != null and aim.get("targetColor", null) != null:
		return {"cellId": aim.get("cellId", "r0c0"), "color": aim.get("targetColor", "red")}
	for cell in scene.get("terrain", {}).get("cells", []):
		if cell.get("weakness", null) != null:
			return {"cellId": cell.get("id", "r0c0"), "color": cell.get("weakness", "red")}
	return {"cellId": "r0c0", "color": "red"}

# 실행: handle calibration shop button toggle.
func _on_shop_open_pressed() -> void:
	if is_reveal_vfx_running:
		return
	view.toggle_shop()
	view.render_shop(growth_state.to_dict())

# 실행: handle buy passive.
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
	view.add_log("[color=#a3be8c][상점] 패시브 상점 구매 완료: %s (Lvl %d)[/color]" % [passive_id, growth_state.purchased_passives[passive_id]])
	
	# Print telemetry event
	print("TELEMETRY: growth_state_changed - passive: %s, lvl: %d, cost: %d" % [passive_id, growth_state.purchased_passives[passive_id], cost])

# 실행: apply active growth modifiers (cooldown reduction, flat damage bonus).
func _apply_growth_modifiers() -> void:
	if inventory == null or growth_state == null:
		return
	var cooldown_mod = growth_state.get_cooldown_modifier()
	for art_id in inventory.artifacts:
		var art = inventory.artifacts[art_id]
		var default_base = 100
		if "ruby" in art.id or "Ruby" in art.name: default_base = 80
		elif "sapphire" in art.id or "Sapphire" in art.name: default_base = 60
		elif "emerald" in art.id or "Emerald" in art.name: default_base = 120
		elif "amethyst" in art.id or "Amethyst" in art.name: default_base = 100
		art.base_cooldown_ticks = int(default_base * cooldown_mod)
		art.current_cooldown = min(art.current_cooldown, art.base_cooldown_ticks)
		
	if preview_controller != null and preview_controller.run != null:
		var tuning = preview_controller.run.state.get("tuning", {})
		if tuning is Dictionary:
			if not tuning.has("combat"):
				tuning["combat"] = {}
			tuning["combat"]["damage_bonus"] = growth_state.get_damage_bonus()
