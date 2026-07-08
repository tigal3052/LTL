extends SceneTree

const VIEWPORT_SIZE := Vector2i(1440, 900)

var failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	root.size = VIEWPORT_SIZE
	var main_scene := load("res://src/Main.tscn") as PackedScene
	_assert(main_scene != null, "main scene loads for leviathan-select runtime contract")
	if main_scene == null:
		_finish()
		return
	await _assert_leviathan_select_runtime(main_scene)
	_finish()

func _assert(condition: bool, label: String) -> void:
	if not condition:
		failures.append(label)

func _assert_eq(actual: Variant, expected: Variant, label: String) -> void:
	if actual != expected:
		failures.append("%s: expected %s, got %s" % [label, str(expected), str(actual)])

func _finish() -> void:
	if failures.is_empty():
		print("LEVIATHAN_SELECT_RUNTIME_CONTRACT_OK")
		call_deferred("quit", 0)
		return
	for failure in failures:
		push_error(failure)
	call_deferred("quit", 1)

func _advance_story_if_present(main_instance: Node, return_page_id: String) -> void:
	if str(main_instance.get("active_page_id")) != "story_scene":
		return
	var story_page = main_instance.get("story_scene_page")
	var controller = main_instance.get_node_or_null("MainController")
	_assert(story_page != null, "story scene exists during leviathan runtime contract")
	_assert(controller != null, "main controller exists during leviathan runtime contract story handoff")
	if story_page == null or controller == null:
		return
	var story: Dictionary = controller.get("active_story_scene")
	var scene_id := str(story.get("id", ""))
	_assert(scene_id != "", "story scene exposes a scene id during leviathan runtime contract")
	if scene_id.is_empty():
		return
	story_page.continue_requested.emit(scene_id)
	await process_frame
	story_page.continue_requested.emit(scene_id)
	await process_frame
	await process_frame
	_assert_eq(str(main_instance.get("active_page_id")), return_page_id, "story scene returns to %s for leviathan runtime contract" % return_page_id)

func _instantiate_main(main_scene: PackedScene) -> Node:
	var main_instance := main_scene.instantiate()
	root.add_child(main_instance)
	await process_frame
	await process_frame
	return main_instance

func _go_to_leviathan_select(main_instance: Node) -> Node:
	await _advance_story_if_present(main_instance, "character_select")
	var character_page = main_instance.get("character_select_page")
	_assert(character_page != null, "character select page exists before leviathan runtime checks")
	if character_page == null:
		return null
	character_page.color_selected.emit("purple")
	character_page.continue_requested.emit()
	await process_frame
	await process_frame
	await process_frame
	_assert_eq(str(main_instance.get("active_page_id")), "leviathan_select", "character select advances to leviathan select for runtime checks")
	return main_instance.get("leviathan_select_page")

func _card_buttons(cards_box: Node) -> Array[Button]:
	var buttons: Array[Button] = []
	for child in cards_box.get_children():
		if child is Button:
			buttons.append(child as Button)
	return buttons

func _assert_leviathan_select_runtime(main_scene: PackedScene) -> void:
	var main_instance := await _instantiate_main(main_scene)
	var controller = main_instance.get_node_or_null("MainController")
	_assert(controller != null, "main controller exists for leviathan runtime checks")
	if controller == null:
		main_instance.queue_free()
		await process_frame
		return
	var leviathan_page = await _go_to_leviathan_select(main_instance)
	_assert(leviathan_page != null, "leviathan select page exists for runtime checks")
	if leviathan_page == null:
		main_instance.queue_free()
		await process_frame
		return
	await process_frame
	await process_frame
	var hero_shell := leviathan_page.get_node_or_null("WorkspaceMargin/Workspace/HeroShell") as Control
	var hero_eyebrow_shell := leviathan_page.get_node_or_null("WorkspaceMargin/Workspace/HeroShell/HeroCopyMargin/HeroCopyBox/HeroEyebrowShell") as Control
	var hero_name := leviathan_page.get_node_or_null("WorkspaceMargin/Workspace/HeroShell/HeroCopyMargin/HeroCopyBox/HeroName") as Label
	_assert(hero_shell != null, "leviathan hero shell exists for runtime checks")
	_assert(hero_eyebrow_shell != null, "leviathan target eyebrow shell exists for runtime checks")
	_assert(hero_name != null, "leviathan hero name exists for runtime checks")
	if hero_shell != null and hero_eyebrow_shell != null and hero_name != null:
		var hero_rect := hero_shell.get_global_rect()
		var eyebrow_rect := hero_eyebrow_shell.get_global_rect()
		var name_rect := hero_name.get_global_rect()
		_assert(eyebrow_rect.end.y <= name_rect.position.y, "target eyebrow shell stays above the leviathan title block")
		_assert(eyebrow_rect.position.y - hero_rect.position.y >= 120.0, "target eyebrow shell is lowered away from the hero top edge")
	var top_character_button := leviathan_page.get_node_or_null("TopBar/TopBarMargin/TopBarRow/BrandRow/TabsRow/CharacterTabButton") as Button
	var top_leviathan_button := leviathan_page.get_node_or_null("TopBar/TopBarMargin/TopBarRow/BrandRow/TabsRow/LeviathanTabButton") as Button
	var codex_action_button := leviathan_page.get_node_or_null("TopBar/TopBarMargin/TopBarRow/BrandRow/TabsRow/CodexActionButton") as Button
	var settings_action_button := leviathan_page.get_node_or_null("TopBar/TopBarMargin/TopBarRow/BrandRow/TabsRow/SettingsActionButton") as Button
	var left_character_button := leviathan_page.get_node_or_null("WorkspaceMargin/Workspace/GlobalRail/RailMargin/RailVBox/NavList/CharacterNavButton") as Button
	var left_leviathan_button := leviathan_page.get_node_or_null("WorkspaceMargin/Workspace/GlobalRail/RailMargin/RailVBox/NavList/LeviathanNavButton") as Button
	var left_codex_button := leviathan_page.get_node_or_null("WorkspaceMargin/Workspace/GlobalRail/RailMargin/RailVBox/NavList/CodexNavButton") as Button
	var left_settings_button := leviathan_page.get_node_or_null("WorkspaceMargin/Workspace/GlobalRail/RailMargin/RailVBox/NavList/SettingsNavButton") as Button
	_assert(top_character_button != null and top_leviathan_button != null, "top chrome exposes real character/leviathan index buttons")
	_assert(codex_action_button != null and settings_action_button != null, "top chrome exposes real codex/settings buttons inside the shared button group")
	if top_character_button != null and top_leviathan_button != null and codex_action_button != null and settings_action_button != null:
		var top_group_parent := top_character_button.get_parent()
		_assert(top_group_parent == top_leviathan_button.get_parent() and top_group_parent == codex_action_button.get_parent() and top_group_parent == settings_action_button.get_parent(), "top chrome keeps character/leviathan/codex/settings inside one shared button group")
	_assert(left_character_button != null and left_leviathan_button != null and left_codex_button != null and left_settings_button != null, "left rail exposes real index-map buttons")
	var settings_panel = main_instance.get("settings_panel") as Control
	var codex_panel = main_instance.get("codex_panel") as Control
	if codex_action_button != null:
		codex_action_button.pressed.emit()
		await process_frame
		await process_frame
		_assert(codex_panel != null and codex_panel.visible, "top-right codex button opens the shared codex overlay")
	if settings_action_button != null:
		settings_action_button.pressed.emit()
		await process_frame
		await process_frame
		_assert(settings_panel != null and settings_panel.visible, "top-right settings button opens the shared settings overlay")
		_assert(codex_panel == null or not codex_panel.visible, "settings button hides the codex overlay when settings opens")
	var start_button := leviathan_page.get_node_or_null("WorkspaceMargin/Workspace/HeroShell/OverlayRail/OverlayVBox/StartButtonFrame/StartButton") as Button
	var accent_strip := start_button.get_node_or_null("AccentStrip") as ColorRect if start_button != null else null
	var arrow_label := start_button.get_node_or_null("ArrowLabel") as Label if start_button != null else null
	_assert(accent_strip != null and arrow_label != null, "start button includes accent-strip and arrow chrome")
	if arrow_label != null:
		_assert_eq(arrow_label.text, "↗", "start button arrow chrome uses the emphasized launch glyph")
	var cards_scroll := leviathan_page.get_node_or_null("WorkspaceMargin/Workspace/HeroShell/OverlayRail/OverlayVBox/CardsScroll") as ScrollContainer
	var cards_box := leviathan_page.get_node_or_null("WorkspaceMargin/Workspace/HeroShell/OverlayRail/OverlayVBox/CardsScroll/CardsVBox") as VBoxContainer
	_assert(cards_scroll != null and cards_box != null, "leviathan cards scroll container exists for bounce checks")
	if cards_scroll != null and cards_box != null:
		var bar := cards_scroll.get_v_scroll_bar()
		var max_scroll := maxi(0, int(round(bar.max_value - bar.page))) if bar != null else 0
		var wheel_down := InputEventMouseButton.new()
		wheel_down.button_index = MOUSE_BUTTON_WHEEL_DOWN
		wheel_down.pressed = true
		cards_scroll.emit_signal("gui_input", wheel_down)
		await process_frame
		if max_scroll > 0:
			_assert(cards_scroll.scroll_vertical > 0, "wheel-down scroll advances the overlay roster when the leviathan rail exceeds the compact strip viewport")
			var scrolled_buttons := _card_buttons(cards_box)
			if scrolled_buttons.size() >= 2:
				var second_card_top_after_wheel_down := scrolled_buttons[1].get_global_rect().position.y
				var scroll_top_after_wheel_down := cards_scroll.get_global_rect().position.y
				_assert(absf(second_card_top_after_wheel_down - scroll_top_after_wheel_down) <= 1.0, "wheel-down from the overlay rail origin snaps the next full leviathan card to the header baseline instead of leaving the previous top card half-clipped")
		else:
			_assert(cards_scroll.scroll_vertical == 0, "compact rail layout can fit the current starter roster without forcing scroll at the canonical viewport")
		cards_scroll.scroll_vertical = 0
		await process_frame
		var wheel_up := InputEventMouseButton.new()
		wheel_up.button_index = MOUSE_BUTTON_WHEEL_UP
		wheel_up.pressed = true
		cards_scroll.emit_signal("gui_input", wheel_up)
		await process_frame
		var top_spring := cards_box.get_node_or_null("CardsSpringTop") as Control
		_assert(top_spring != null and top_spring.custom_minimum_size.y > 0.0, "wheel-up overscroll triggers a top spring bounce at the overlay rail edge")
		await create_timer(0.30).timeout
		bar = cards_scroll.get_v_scroll_bar()
		max_scroll = maxi(0, int(round(bar.max_value - bar.page))) if bar != null else 0
		var bottom_spring := cards_box.get_node_or_null("CardsSpringBottom") as Control
		if max_scroll > 0:
			cards_scroll.scroll_vertical = maxi(0, max_scroll - 24)
			await process_frame
			cards_scroll.emit_signal("gui_input", wheel_down)
			await process_frame
			_assert(cards_scroll.scroll_vertical == max_scroll, "wheel-down from near the bottom snaps to the final overlay rail anchor instead of stopping short of the roster boundary")
			cards_scroll.emit_signal("gui_input", wheel_down)
			await process_frame
			_assert(bottom_spring != null and bottom_spring.custom_minimum_size.y > 0.0, "wheel-down overshoot triggers a bottom spring bounce once the overlay rail is already parked on its final anchor")
		else:
			cards_scroll.emit_signal("gui_input", wheel_down)
			await process_frame
			_assert(bottom_spring != null and bottom_spring.custom_minimum_size.y > 0.0, "compact rail layout still exposes a bottom spring bounce when wheel-down input hits the already-fitted roster")
		var card_buttons := _card_buttons(cards_box)
		_assert(card_buttons.size() >= 4, "leviathan roster renders the starter trio plus the locked placeholder card in runtime contract")
		if card_buttons.size() >= 4:
			_assert(not card_buttons[0].disabled, "ossuary tortoise stays selectable in the starter leviathan roster")
			_assert(not card_buttons[1].disabled, "storm wyvern is currently part of the selectable starter/runtime roster")
			_assert(not card_buttons[2].disabled, "sky mireu is currently part of the selectable starter/runtime roster")
			_assert(card_buttons[3].disabled, "drake remains the locked placeholder at the tail of the leviathan roster")
	if top_character_button != null:
		top_character_button.pressed.emit()
		await process_frame
		await process_frame
		await _advance_story_if_present(main_instance, "character_select")
		_assert_eq(str(main_instance.get("active_page_id")), "character_select", "top character index button returns to character select")
	leviathan_page = await _go_to_leviathan_select(main_instance)
	if leviathan_page != null:
		left_character_button = leviathan_page.get_node_or_null("WorkspaceMargin/Workspace/GlobalRail/RailMargin/RailVBox/NavList/CharacterNavButton") as Button
		left_codex_button = leviathan_page.get_node_or_null("WorkspaceMargin/Workspace/GlobalRail/RailMargin/RailVBox/NavList/CodexNavButton") as Button
		if left_codex_button != null:
			left_codex_button.pressed.emit()
			await process_frame
			await process_frame
			_assert(codex_panel != null and codex_panel.visible, "left codex index button opens the shared codex overlay")
		if left_character_button != null:
			left_character_button.pressed.emit()
			await process_frame
			await process_frame
			await _advance_story_if_present(main_instance, "character_select")
			_assert_eq(str(main_instance.get("active_page_id")), "character_select", "left character index button returns to character select")
	main_instance.queue_free()
	await process_frame
