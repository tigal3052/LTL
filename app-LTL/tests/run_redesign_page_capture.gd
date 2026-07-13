# 계약: 리디자인 비교용 페이지 캡처 러너 — m6 캡처 러너를 상속해 clear/boss_reward/settings/shop/toast 페이지 드라이브를 추가한다.
# 계약: 출력물은 무시 경로(.tmp-redesign/**)에 저장하는 것을 기본으로 하며, 성공 마커는 M6_INTERNAL_CAPTURED를 그대로 재사용한다.
extends "res://tests/run_m6_visual_capture.gd"

# 실행: 신규 페이지 id를 우선 처리하고, 나머지는 부모 드라이브로 위임한다.
func _drive_to_page(main_instance: Node, page_id: String) -> bool:
	match page_id:
		"boss_battle":
			return await _go_to_boss_battle(main_instance)
		"boss_reward":
			return await _go_to_boss_reward(main_instance)
		"clear":
			return await _go_to_clear(main_instance)
		"settings":
			return await _go_to_settings_overlay(main_instance)
		"shop":
			return await _go_to_shop_overlay(main_instance)
		"toast":
			return await _go_to_toast_overlay(main_instance)
		_:
			return await super._drive_to_page(main_instance, page_id)

# 실행: 리디자인 캡처 체인은 단일 런 레비아탄(ossuary_tortoise)을 선택해 보스/클리어 도달 경로를 짧게 유지한다.
func _go_to_node_select(main_instance: Node) -> bool:
	if not await _go_to_leviathan_select(main_instance):
		return false
	var leviathan_page = main_instance.get("leviathan_select_page")
	if leviathan_page == null:
		_fail("leviathan page missing before redesign node-select visual capture")
		return false
	leviathan_page.leviathan_selected.emit("ossuary_tortoise")
	leviathan_page.start_requested.emit()
	await _settle_frames(5)
	return _expect_active(main_instance, "node_select", "node_select")

# 실행: 첫 보상 페이지 이후 노드 선택을 반복 진행해 보스 전투 페이지까지 도달한다.
func _go_to_boss_battle(main_instance: Node) -> bool:
	if not await _go_to_reward(main_instance):
		return false
	var controller = main_instance.get_node_or_null("MainController")
	if controller == null:
		_fail("controller missing before boss-battle visual capture")
		return false
	for _attempt in range(6):
		controller.call("_proceed_to_node_select")
		await _settle_frames(6)
		if not _expect_active(main_instance, "node_select", "boss-battle node_select loop"):
			return false
		var scene: Dictionary = controller.get("current_scene")
		var is_boss := bool(scene.get("nodeSelect", {}).get("isBossStage", false))
		_press_current_node(main_instance, 0, "boss-battle visual capture")
		await _settle_frames(2)
		var start_button = main_instance.get("start_button")
		if start_button == null:
			_fail("start button missing during boss-battle visual capture")
			return false
		start_button.pressed.emit()
		await _settle_frames(8)
		if is_boss:
			return _expect_active(main_instance, "boss_battle", "boss_battle")
		if not _expect_active(main_instance, "battle", "boss-battle intermediate battle"):
			return false
		controller.preview_controller.run.apply_combat_input({"type": "resolve", "outcome": "clear"})
		controller.call("_render_scene", controller.preview_controller.get_scene())
		await _settle_frames(5)
		var reward_reveal_overlay = main_instance.get_node_or_null("RewardRevealOverlay")
		if reward_reveal_overlay != null:
			await _finish_reward_ceremony(controller, reward_reveal_overlay)
		await _settle_frames(12)
	_fail("boss stage not reached within attempt budget")
	return false

# 실행: 보스 전투를 클리어 처리해 보스 보상 페이지에 도달한다.
func _go_to_boss_reward(main_instance: Node) -> bool:
	if not await _go_to_boss_battle(main_instance):
		return false
	var controller = main_instance.get_node_or_null("MainController")
	controller.preview_controller.run.apply_combat_input({"type": "resolve", "outcome": "clear"})
	controller.call("_render_scene", controller.preview_controller.get_scene())
	await _settle_frames(5)
	var reward_reveal_overlay = main_instance.get_node_or_null("RewardRevealOverlay")
	if reward_reveal_overlay != null:
		await _finish_reward_ceremony(controller, reward_reveal_overlay)
	await _settle_frames(24)
	return _expect_active(main_instance, "boss_reward", "boss_reward")

# 실행: 보스 보상 이후 진행을 트리거해 런 클리어 페이지에 도달한다.
func _go_to_clear(main_instance: Node) -> bool:
	if not await _go_to_boss_reward(main_instance):
		return false
	var controller = main_instance.get_node_or_null("MainController")
	controller.call("_proceed_to_node_select")
	await _settle_frames(8)
	return _expect_active(main_instance, "clear", "clear")

# 실행: 노드 선택 배경 위에서 설정 오버레이를 연다.
func _go_to_settings_overlay(main_instance: Node) -> bool:
	if not await _go_to_node_select(main_instance):
		return false
	if main_instance.has_method("toggle_settings"):
		main_instance.call("toggle_settings")
	else:
		_fail("main view lacks toggle_settings for settings visual capture")
		return false
	await _settle_frames(6)
	return true

# 실행: 노드 선택 배경 위에서 상점 패널을 강제로 표시한다(SHOP_ENABLED=false 우회 캡처).
func _go_to_shop_overlay(main_instance: Node) -> bool:
	if not await _go_to_node_select(main_instance):
		return false
	var shop_panel = main_instance.get("shop_panel")
	if shop_panel == null:
		_fail("shop panel missing for shop visual capture")
		return false
	shop_panel.visible = true
	if shop_panel.get_parent() != null:
		shop_panel.get_parent().move_child(shop_panel, shop_panel.get_parent().get_child_count() - 1)
	await _settle_frames(6)
	return true

# 실행: 노드 선택 배경 위에서 정보 토스트와 확인 오버레이를 함께 표시한다.
func _go_to_toast_overlay(main_instance: Node) -> bool:
	if not await _go_to_node_select(main_instance):
		return false
	if main_instance.has_method("show_info_toast"):
		main_instance.call("show_info_toast", "새 흔적을 발견했습니다", 30.0)
	else:
		_fail("main view lacks show_info_toast for toast visual capture")
		return false
	var confirm_overlay = main_instance.get_node_or_null("ConfirmOverlay")
	if confirm_overlay != null:
		confirm_overlay.visible = true
	await _settle_frames(6)
	return true
