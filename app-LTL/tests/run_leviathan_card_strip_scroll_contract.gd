extends SceneTree

const VIEWPORT_SIZE := Vector2i(1440, 900)
const ORIGIN_TOLERANCE := 1.0
const BASELINE_TOLERANCE := 0.5

var failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	root.size = VIEWPORT_SIZE
	var main_scene := load("res://src/Main.tscn") as PackedScene
	_assert(main_scene != null, "main scene loads for leviathan card strip scroll contract")
	if main_scene == null:
		_finish()
		return
	await _assert_card_strip_scroll(main_scene)
	_finish()

func _assert(condition: bool, label: String) -> void:
	if not condition:
		failures.append(label)

func _assert_eq(actual: Variant, expected: Variant, label: String) -> void:
	if actual != expected:
		failures.append("%s: expected %s, got %s" % [label, str(expected), str(actual)])

func _assert_approx(actual: float, expected: float, tolerance: float, label: String) -> void:
	if absf(actual - expected) > tolerance:
		failures.append("%s: expected %.2f ± %.2f, got %.2f" % [label, expected, tolerance, actual])

func _finish() -> void:
	if failures.is_empty():
		print("LEVIATHAN_CARD_STRIP_SCROLL_CONTRACT_OK")
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
	_assert(story_page != null, "story scene exists during card strip scroll contract")
	_assert(controller != null, "main controller exists during card strip scroll contract story handoff")
	if story_page == null or controller == null:
		return
	var story: Dictionary = controller.get("active_story_scene")
	var scene_id := str(story.get("id", ""))
	_assert(scene_id != "", "story scene exposes a scene id during card strip scroll contract")
	if scene_id.is_empty():
		return
	story_page.continue_requested.emit(scene_id)
	await process_frame
	story_page.continue_requested.emit(scene_id)
	await process_frame
	await process_frame
	_assert_eq(str(main_instance.get("active_page_id")), return_page_id, "story scene returns to %s for card strip scroll contract" % return_page_id)

func _instantiate_main(main_scene: PackedScene) -> Node:
	var main_instance := main_scene.instantiate()
	root.add_child(main_instance)
	await process_frame
	await process_frame
	return main_instance

func _go_to_leviathan_select(main_instance: Node) -> Node:
	await _advance_story_if_present(main_instance, "character_select")
	var character_page = main_instance.get("character_select_page")
	_assert(character_page != null, "character select page exists before card strip scroll contract")
	if character_page == null:
		return null
	character_page.color_selected.emit("purple")
	character_page.continue_requested.emit()
	await process_frame
	await process_frame
	await process_frame
	_assert_eq(str(main_instance.get("active_page_id")), "leviathan_select", "character select advances to leviathan select for card strip scroll contract")
	return main_instance.get("leviathan_select_page")

func _emit_wheel(cards_scroll: ScrollContainer, button_index: MouseButton) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = button_index
	event.pressed = true
	cards_scroll.emit_signal("gui_input", event)

func _pointer_center(control: Control) -> Vector2:
	var rect := control.get_global_rect()
	return rect.position + rect.size * 0.5

func _move_pointer(global_position: Vector2) -> void:
	var motion := InputEventMouseMotion.new()
	motion.position = global_position
	motion.global_position = global_position
	motion.relative = Vector2.ZERO
	Input.parse_input_event(motion)
	await process_frame

func _emit_left_click(control: Control) -> void:
	var target := _pointer_center(control)
	await _emit_left_click_at(target)

func _emit_left_click_at(global_position: Vector2) -> void:
	await _move_pointer(global_position)
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	press.position = global_position
	press.global_position = global_position
	Input.parse_input_event(press)
	await process_frame
	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	release.pressed = false
	release.position = global_position
	release.global_position = global_position
	Input.parse_input_event(release)
	await process_frame

func _emit_pointer_wheel(control: Control, button_index: MouseButton) -> void:
	var target := _pointer_center(control)
	await _emit_pointer_wheel_at(target, button_index)

func _emit_pointer_wheel_at(global_position: Vector2, button_index: MouseButton) -> void:
	await _move_pointer(global_position)
	var event := InputEventMouseButton.new()
	event.button_index = button_index
	event.pressed = true
	event.position = global_position
	event.global_position = global_position
	Input.parse_input_event(event)
	await process_frame

func _emit_button_wheel(button: Button, button_index: MouseButton) -> void:
	var target := _pointer_center(button)
	var local_target := button.size * 0.5
	var event := InputEventMouseButton.new()
	event.button_index = button_index
	event.pressed = true
	event.position = local_target
	event.global_position = target
	button.emit_signal("gui_input", event)
	await process_frame

func _emit_drag(button: Button, start_local: Vector2, delta: Vector2) -> void:
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	press.position = start_local
	press.global_position = button.get_global_rect().position + start_local
	button.emit_signal("gui_input", press)
	var motion := InputEventMouseMotion.new()
	motion.position = start_local + delta
	motion.global_position = button.get_global_rect().position + motion.position
	motion.relative = delta
	motion.button_mask = MOUSE_BUTTON_MASK_LEFT
	button.emit_signal("gui_input", motion)
	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	release.pressed = false
	release.position = motion.position
	release.global_position = motion.global_position
	button.emit_signal("gui_input", release)

func _max_scroll(cards_scroll: ScrollContainer) -> int:
	var bar := cards_scroll.get_v_scroll_bar()
	if bar == null:
		return 0
	return maxi(0, int(round(bar.max_value - bar.page)))

func _assert_card_strip_scroll(main_scene: PackedScene) -> void:
	var main_instance := await _instantiate_main(main_scene)
	var leviathan_page = await _go_to_leviathan_select(main_instance)
	_assert(leviathan_page != null, "leviathan select page exists for card strip scroll contract")
	if leviathan_page == null:
		main_instance.queue_free()
		await process_frame
		return
	await process_frame
	await process_frame
	var top_bar := leviathan_page.get_node_or_null("TopBar") as PanelContainer
	var overlay_vbox := leviathan_page.get_node_or_null("WorkspaceMargin/Workspace/HeroShell/OverlayRail/OverlayVBox") as Control
	var cards_scroll := leviathan_page.get_node_or_null("WorkspaceMargin/Workspace/HeroShell/OverlayRail/OverlayVBox/CardsScroll") as ScrollContainer
	var cards_box := leviathan_page.get_node_or_null("WorkspaceMargin/Workspace/HeroShell/OverlayRail/OverlayVBox/CardsScroll/CardsVBox") as VBoxContainer
	var top_spring := cards_box.get_node_or_null("CardsSpringTop") as Control if cards_box != null else null
	var bottom_spring := cards_box.get_node_or_null("CardsSpringBottom") as Control if cards_box != null else null
	var card_buttons := _card_buttons(cards_box)
	var preview_card := _first_preview_card(cards_box)
	_assert(top_bar != null, "leviathan top bar exists for card strip scroll contract")
	_assert(overlay_vbox != null, "leviathan overlay rail vbox exists for left-baseline contract checks")
	_assert(cards_scroll != null and cards_box != null, "leviathan cards scroll container exists for card strip scroll contract")
	_assert(top_spring != null and bottom_spring != null, "leviathan card strip exposes top/bottom spring nodes for overscroll bounce")
	_assert(not card_buttons.is_empty(), "leviathan card strip renders selectable roster buttons")
	_assert(preview_card != null, "leviathan card strip exposes at least one preview tail card for baseline parity checks")
	if top_bar != null and overlay_vbox != null and cards_scroll != null and top_spring != null and bottom_spring != null:
		var max_scroll := _max_scroll(cards_scroll)
		_assert(absf(cards_scroll.position.y) <= 0.5, "card strip viewport starts at the rail top instead of hiding the first real card behind a negative y offset")
		_assert_approx(cards_scroll.get_global_rect().position.x, overlay_vbox.get_global_rect().position.x, ORIGIN_TOLERANCE, "card strip viewport starts flush with the overlay rail left edge instead of drifting behind an extra inset gutter")
		var first_strip_child := cards_box.get_child(1) if cards_box.get_child_count() > 1 else null
		_assert(first_strip_child is Button, "top of the strip begins with the first real leviathan card instead of a teaser filler card")
		_assert(cards_scroll.scroll_vertical == 0, "card strip lands at its top anchor instead of opening on a partially hidden first card")
		var header_bottom := top_bar.get_global_rect().position.y + top_bar.get_global_rect().size.y
		var scroll_top := cards_scroll.get_global_rect().position.y
		_assert_approx(scroll_top, header_bottom, ORIGIN_TOLERANCE, "card strip starts exactly at the top bar bottom instead of drifting below the header baseline")
		_assert_approx(top_spring.custom_minimum_size.y, 0.0, ORIGIN_TOLERANCE, "top spring has no resting gap when the strip is parked at scroll_vertical == 0")
		if not card_buttons.is_empty():
			var first_title := _first_label_text(card_buttons[0])
			_assert(first_title == "유해갑 거북", "first selectable card stays pinned to 유해갑 거북 at the top edge")
			var first_card_top := card_buttons[0].get_global_rect().position.y
			_assert_approx(first_card_top, scroll_top, ORIGIN_TOLERANCE, "first real leviathan card starts flush with the strip top at scroll_vertical == 0")
		if card_buttons.size() >= 2:
			var first_content := card_buttons[0].get_node_or_null("CardVisualRoot/CardContentMargin") as Control
			var second_content := card_buttons[1].get_node_or_null("CardVisualRoot/CardContentMargin") as Control
			var first_strip := _selection_strip(card_buttons[0])
			var second_strip := _selection_strip(card_buttons[1])
			var selected_normal := card_buttons[0].get_theme_stylebox("normal") as StyleBoxFlat
			var selected_hover := card_buttons[0].get_theme_stylebox("hover") as StyleBoxFlat
			var unselected_normal := card_buttons[1].get_theme_stylebox("normal") as StyleBoxFlat
			var unselected_hover := card_buttons[1].get_theme_stylebox("hover") as StyleBoxFlat
			_assert(first_content != null and second_content != null, "real leviathan cards expose content margins for baseline parity checks")
			_assert(first_strip != null and second_strip != null, "selected and non-selected leviathan cards both expose a persistent strip baseline guide")
			_assert(selected_normal != null and selected_hover != null and unselected_normal != null and unselected_hover != null, "leviathan card buttons expose normal and hover styleboxes for geometry parity checks")
			_assert_approx(card_buttons[0].get_global_rect().position.x, card_buttons[1].get_global_rect().position.x, BASELINE_TOLERANCE, "selected and non-selected leviathan cards share one left shell baseline")
			if first_content != null and second_content != null:
				_assert_approx(first_content.get_global_rect().position.x, second_content.get_global_rect().position.x, BASELINE_TOLERANCE, "selected and non-selected leviathan cards share one content baseline")
			if first_strip != null and second_strip != null:
				_assert_approx(first_strip.get_global_rect().position.x, second_strip.get_global_rect().position.x, BASELINE_TOLERANCE, "selected and non-selected leviathan cards share one strip baseline")
				_assert_approx(first_strip.get_global_rect().size.x, second_strip.get_global_rect().size.x, BASELINE_TOLERANCE, "selected and non-selected leviathan cards keep one strip width contract")
			if selected_normal != null and selected_hover != null:
				_assert_eq(selected_normal.content_margin_left, selected_hover.content_margin_left, "selected leviathan hover keeps the same content-left margin as resting state")
				_assert_eq(selected_normal.border_width_left, selected_hover.border_width_left, "selected leviathan hover keeps the same left border width as resting state")
			if unselected_normal != null and unselected_hover != null:
				_assert_eq(unselected_normal.content_margin_left, unselected_hover.content_margin_left, "unselected leviathan hover keeps the same content-left margin as resting state")
				_assert_eq(unselected_normal.border_width_left, unselected_hover.border_width_left, "unselected leviathan hover keeps the same left border width as resting state")
		if preview_card != null and not card_buttons.is_empty():
			var preview_content := preview_card.get_node_or_null("CardVisualRoot/CardContentMargin") as Control
			var selected_content := card_buttons[0].get_node_or_null("CardVisualRoot/CardContentMargin") as Control
			var preview_strip := _selection_strip(preview_card)
			var selected_strip := _selection_strip(card_buttons[0])
			_assert(preview_content != null and selected_content != null, "preview and real cards expose content margins for baseline parity checks")
			_assert(preview_strip != null and selected_strip != null, "preview and real cards both expose a persistent strip baseline guide")
			_assert_approx(card_buttons[0].get_global_rect().position.x, preview_card.get_global_rect().position.x, BASELINE_TOLERANCE, "real and preview rail entries share one left shell baseline")
			if preview_content != null and selected_content != null:
				_assert_approx(selected_content.get_global_rect().position.x, preview_content.get_global_rect().position.x, BASELINE_TOLERANCE, "real and preview rail entries share one content baseline")
			if preview_strip != null and selected_strip != null:
				_assert_approx(selected_strip.get_global_rect().position.x, preview_strip.get_global_rect().position.x, BASELINE_TOLERANCE, "real and preview rail entries share one strip baseline")
				_assert_approx(selected_strip.get_global_rect().size.x, preview_strip.get_global_rect().size.x, BASELINE_TOLERANCE, "real and preview rail entries keep one strip width contract")
		if card_buttons.size() >= 2:
			var selected_before_click := str(leviathan_page.get("_selected_id"))
			await _emit_left_click(card_buttons[1])
			await process_frame
			await process_frame
			top_spring = cards_box.get_node_or_null("CardsSpringTop") as Control
			bottom_spring = cards_box.get_node_or_null("CardsSpringBottom") as Control
			card_buttons = _card_buttons(cards_box)
			preview_card = _first_preview_card(cards_box)
			max_scroll = _max_scroll(cards_scroll)
			_assert(str(leviathan_page.get("_selected_id")) != selected_before_click, "clicking a different rail card through the live pointer path changes the selected leviathan")
			_assert(cards_scroll.scroll_vertical == 0, "changing the selected rail card preserves the top scroll anchor instead of reopening on a clipped first card")
			_assert(top_spring != null and bottom_spring != null, "changing the selected rail card rebuilds valid spring nodes for top-origin checks")
			if not card_buttons.is_empty():
				var first_card_top_after_selection := card_buttons[0].get_global_rect().position.y
				var scroll_top_after_selection := cards_scroll.get_global_rect().position.y
				_assert_approx(first_card_top_after_selection, scroll_top_after_selection, ORIGIN_TOLERANCE, "changing the selected rail card keeps the first real card flush with the shared top-menu strip origin")
			if max_scroll > 0 and preview_card != null:
				var black_preview_point_after_selection := _preview_probe_point(preview_card, cards_scroll)
				var black_preview_owner_after_selection := _surface_at_point(cards_box, black_preview_point_after_selection)
				_assert(black_preview_owner_after_selection == preview_card, "reported black preview probe point resolves to the visible preview tail surface immediately after selection")
				var selected_before_black_preview_click_after_selection := str(leviathan_page.get("_selected_id"))
				await _emit_left_click_at(black_preview_point_after_selection)
				await process_frame
				await process_frame
				_assert_eq(str(leviathan_page.get("_selected_id")), selected_before_black_preview_click_after_selection, "clicking the black preview tail after selection keeps the selected leviathan unchanged")
				_assert(cards_scroll.scroll_vertical == 0, "clicking the black preview tail after selection keeps the rail parked at its top anchor")
				await _emit_pointer_wheel_at(black_preview_point_after_selection, MOUSE_BUTTON_WHEEL_DOWN)
				await process_frame
				await process_frame
				card_buttons = _card_buttons(cards_box)
				_assert(cards_scroll.scroll_vertical > 0, "wheel-down over the black preview tail immediately after selection still scrolls the rail through the live pointer path")
				if card_buttons.size() >= 2:
					var selected_card_top_after_black_preview_wheel_down_after_selection := card_buttons[1].get_global_rect().position.y
					var scroll_top_after_black_preview_wheel_down_after_selection := cards_scroll.get_global_rect().position.y
					_assert_approx(selected_card_top_after_black_preview_wheel_down_after_selection, scroll_top_after_black_preview_wheel_down_after_selection, ORIGIN_TOLERANCE, "wheel-down from the black preview tail immediately after selection snaps the selected real leviathan card to the shared top-menu strip origin")
				await _emit_pointer_wheel_at(black_preview_point_after_selection, MOUSE_BUTTON_WHEEL_UP)
				await process_frame
				await process_frame
				card_buttons = _card_buttons(cards_box)
				if not card_buttons.is_empty():
					var first_card_top_after_black_preview_round_trip_after_selection := card_buttons[0].get_global_rect().position.y
					var scroll_top_after_black_preview_round_trip_after_selection := cards_scroll.get_global_rect().position.y
					_assert(cards_scroll.scroll_vertical == 0, "wheel-up after the black preview-tail round trip immediately after selection returns the rail to scroll_vertical == 0")
					_assert_approx(first_card_top_after_black_preview_round_trip_after_selection, scroll_top_after_black_preview_round_trip_after_selection, ORIGIN_TOLERANCE, "wheel round-trip from the black preview tail immediately after selection returns the first real card to the shared top-menu strip origin")
				top_spring = cards_box.get_node_or_null("CardsSpringTop") as Control
				bottom_spring = cards_box.get_node_or_null("CardsSpringBottom") as Control
			if max_scroll > 0 and card_buttons.size() >= 2:
				await _emit_button_wheel(card_buttons[1], MOUSE_BUTTON_WHEEL_DOWN)
				await process_frame
				_assert(cards_scroll.scroll_vertical > 0, "wheel-down emitted to the hovered rail card button routes through the rail scroll owner instead of dying on the button path")
				if cards_scroll.scroll_vertical > 0:
					var selected_card_top_after_button_wheel_down := card_buttons[1].get_global_rect().position.y
					var scroll_top_after_button_wheel_down := cards_scroll.get_global_rect().position.y
					_assert_approx(selected_card_top_after_button_wheel_down, scroll_top_after_button_wheel_down, ORIGIN_TOLERANCE, "button-path wheel-down snaps the selected rail card to the shared top-menu strip origin")
				cards_scroll.scroll_vertical = 0
				await process_frame
				await _emit_pointer_wheel(card_buttons[1], MOUSE_BUTTON_WHEEL_DOWN)
				await process_frame
				_assert(cards_scroll.scroll_vertical > 0, "wheel-down over the selected rail card still scrolls the rail through the live pointer path")
				var selected_card_top_after_selection_wheel_down := card_buttons[1].get_global_rect().position.y
				var scroll_top_after_selection_wheel_down := cards_scroll.get_global_rect().position.y
				_assert_approx(selected_card_top_after_selection_wheel_down, scroll_top_after_selection_wheel_down, ORIGIN_TOLERANCE, "wheel-down over the selected rail card snaps that full card to the shared top-menu strip origin instead of leaving the previous card partially visible")
				await _emit_pointer_wheel(card_buttons[1], MOUSE_BUTTON_WHEEL_UP)
				await process_frame
				card_buttons = _card_buttons(cards_box)
				if not card_buttons.is_empty():
					var first_card_top_after_selection_round_trip := card_buttons[0].get_global_rect().position.y
					var scroll_top_after_selection_round_trip := cards_scroll.get_global_rect().position.y
					_assert(cards_scroll.scroll_vertical == 0, "wheel-up after a one-step round trip returns the rail to scroll_vertical == 0 after changing the selected card")
					_assert_approx(first_card_top_after_selection_round_trip, scroll_top_after_selection_round_trip, ORIGIN_TOLERANCE, "wheel round-trip after changing the selected card returns the first real card to the shared top-menu strip origin")
				var black_preview_point := _preview_probe_point(preview_card, cards_scroll)
				var black_preview_owner := _surface_at_point(cards_box, black_preview_point)
				_assert(black_preview_owner == preview_card, "reported black preview probe point resolves to the visible preview tail surface")
				var selected_before_black_preview_click := str(leviathan_page.get("_selected_id"))
				await _emit_left_click_at(black_preview_point)
				await process_frame
				await process_frame
				_assert_eq(str(leviathan_page.get("_selected_id")), selected_before_black_preview_click, "clicking the black preview tail keeps the selected leviathan unchanged")
				_assert(cards_scroll.scroll_vertical == 0, "clicking the black preview tail keeps the rail parked at its top anchor")
				await _emit_pointer_wheel_at(black_preview_point, MOUSE_BUTTON_WHEEL_DOWN)
				await process_frame
				await process_frame
				card_buttons = _card_buttons(cards_box)
				_assert(cards_scroll.scroll_vertical > 0, "wheel-down over the black preview tail still scrolls the rail through the live pointer path")
				if card_buttons.size() >= 2:
					var selected_card_top_after_black_preview_wheel_down := card_buttons[1].get_global_rect().position.y
					var scroll_top_after_black_preview_wheel_down := cards_scroll.get_global_rect().position.y
					_assert_approx(selected_card_top_after_black_preview_wheel_down, scroll_top_after_black_preview_wheel_down, ORIGIN_TOLERANCE, "wheel-down from the black preview tail snaps the selected real leviathan card to the shared top-menu strip origin")
				await _emit_pointer_wheel_at(black_preview_point, MOUSE_BUTTON_WHEEL_UP)
				await process_frame
				await process_frame
				card_buttons = _card_buttons(cards_box)
				if not card_buttons.is_empty():
					var first_card_top_after_black_preview_round_trip := card_buttons[0].get_global_rect().position.y
					var scroll_top_after_black_preview_round_trip := cards_scroll.get_global_rect().position.y
					_assert(cards_scroll.scroll_vertical == 0, "wheel-up after the black preview-tail round trip returns the rail to scroll_vertical == 0")
					_assert_approx(first_card_top_after_black_preview_round_trip, scroll_top_after_black_preview_round_trip, ORIGIN_TOLERANCE, "wheel round-trip from the black preview tail returns the first real card to the shared top-menu strip origin")
				top_spring = cards_box.get_node_or_null("CardsSpringTop") as Control
				bottom_spring = cards_box.get_node_or_null("CardsSpringBottom") as Control
			_emit_wheel(cards_scroll, MOUSE_BUTTON_WHEEL_UP)
			await process_frame
			_assert(cards_scroll.scroll_vertical == 0, "wheel-up overscroll after changing the selected card still clamps at the top edge")
			if top_spring != null:
				_assert(top_spring.custom_minimum_size.y > 0.0, "wheel-up overscroll after changing the selected card still triggers the top spring bounce")
			await create_timer(0.30).timeout
			card_buttons = _card_buttons(cards_box)
			if not card_buttons.is_empty():
				var first_card_top_after_selection_bounce := card_buttons[0].get_global_rect().position.y
				var scroll_top_after_selection_bounce := cards_scroll.get_global_rect().position.y
				_assert_approx(first_card_top_after_selection_bounce, scroll_top_after_selection_bounce, ORIGIN_TOLERANCE, "wheel-up recovery after changing the selected card returns the first real card to the strip origin")
		cards_scroll.scroll_vertical = 0
		await process_frame
		if not card_buttons.is_empty():
			var first_card_top_after_reset := card_buttons[0].get_global_rect().position.y
			var scroll_top_after_reset := cards_scroll.get_global_rect().position.y
			_assert_approx(first_card_top_after_reset, scroll_top_after_reset, ORIGIN_TOLERANCE, "top reset returns the first real leviathan card to the strip origin instead of leaving a resting header gap")
		_emit_wheel(cards_scroll, MOUSE_BUTTON_WHEEL_DOWN)
		await process_frame
		if max_scroll > 0:
			_assert(cards_scroll.scroll_vertical > 0, "wheel-down scroll advances the leviathan card strip through the roster when the compact strip overflows")
			if card_buttons.size() >= 2:
				var second_card_top_after_wheel_down := card_buttons[1].get_global_rect().position.y
				var scroll_top_after_wheel_down := cards_scroll.get_global_rect().position.y
				_assert_approx(second_card_top_after_wheel_down, scroll_top_after_wheel_down, ORIGIN_TOLERANCE, "wheel-down from the strip origin snaps the next full leviathan card to the header baseline instead of leaving the first card half-clipped")
		else:
			_assert(cards_scroll.scroll_vertical == 0, "compact card strip can fit the current runtime roster without forcing scroll")
		cards_scroll.scroll_vertical = 0
		await process_frame
		if max_scroll > 0 and card_buttons.size() >= 2:
			var selected_before_drag := str(leviathan_page.get("_selected_id"))
			_emit_drag(card_buttons[1], Vector2(24.0, 24.0), Vector2(0.0, -84.0))
			await process_frame
			await process_frame
			_assert(cards_scroll.scroll_vertical > 0, "dragging upward on a real rail card scrolls the strip instead of acting like a dead click-only surface")
			_assert_eq(str(leviathan_page.get("_selected_id")), selected_before_drag, "drag-scrolling a real rail card suppresses the accidental click-selection side effect")
		cards_scroll.scroll_vertical = 0
		await process_frame
		top_spring = cards_box.get_node_or_null("CardsSpringTop") as Control
		bottom_spring = cards_box.get_node_or_null("CardsSpringBottom") as Control
		_emit_wheel(cards_scroll, MOUSE_BUTTON_WHEEL_UP)
		await process_frame
		_assert(cards_scroll.scroll_vertical == 0, "wheel-up overscroll clamps at the top edge instead of leaving the overlay rail")
		_assert(top_spring.custom_minimum_size.y > 0.0, "wheel-up overscroll triggers the top spring bounce at the overlay rail edge")
		await create_timer(0.30).timeout
		if not card_buttons.is_empty():
			var first_card_top_after_bounce := card_buttons[0].get_global_rect().position.y
			var scroll_top_after_bounce := cards_scroll.get_global_rect().position.y
			_assert_approx(first_card_top_after_bounce, scroll_top_after_bounce, ORIGIN_TOLERANCE, "wheel-up recovery returns the first real leviathan card to the strip origin instead of parking it below a header gap")
		max_scroll = _max_scroll(cards_scroll)
		if max_scroll > 0:
			cards_scroll.scroll_vertical = maxi(0, max_scroll - 24)
			await process_frame
			_emit_wheel(cards_scroll, MOUSE_BUTTON_WHEEL_DOWN)
			await process_frame
			_assert(cards_scroll.scroll_vertical == max_scroll, "wheel-down from near the bottom snaps to the final anchor instead of stopping short of the leviathan card strip boundary")
			_emit_wheel(cards_scroll, MOUSE_BUTTON_WHEEL_DOWN)
			await process_frame
			_assert(bottom_spring.custom_minimum_size.y > 0.0, "wheel-down overshoot triggers the bottom spring bounce once the rail is already parked on its final anchor")
		else:
			_emit_wheel(cards_scroll, MOUSE_BUTTON_WHEEL_DOWN)
			await process_frame
			_assert(bottom_spring.custom_minimum_size.y > 0.0, "compact card strip still exposes a bottom spring bounce when wheel-down input hits the already-fitted roster")
	await _move_pointer(Vector2.ZERO)
	await process_frame
	main_instance.queue_free()
	await process_frame

func _card_buttons(cards_box: VBoxContainer) -> Array[Button]:
	var buttons: Array[Button] = []
	if cards_box == null:
		return buttons
	for child in cards_box.get_children():
		if child is Button:
			buttons.append(child)
	return buttons

func _first_preview_card(cards_box: VBoxContainer) -> PanelContainer:
	if cards_box == null:
		return null
	for child in cards_box.get_children():
		if child is PanelContainer and bool((child as PanelContainer).get_meta("leviathan_preview_card", false)):
			return child as PanelContainer
	return null

func _preview_probe_point(preview_card: PanelContainer, cards_scroll: ScrollContainer) -> Vector2:
	var scroll_rect := cards_scroll.get_global_rect()
	var preview_rect := preview_card.get_global_rect()
	var probe_y := clampf(scroll_rect.end.y - 70.0, preview_rect.position.y + 18.0, preview_rect.end.y - 18.0)
	return Vector2(scroll_rect.position.x + scroll_rect.size.x * 0.5, probe_y)

func _surface_at_point(cards_box: VBoxContainer, global_position: Vector2) -> Control:
	if cards_box == null:
		return null
	for child in cards_box.get_children():
		if child is Control and (child as Control).get_global_rect().has_point(global_position):
			return child as Control
	return null

func _selection_strip(host: Control) -> Control:
	if host == null:
		return null
	return host.get_node_or_null("CardVisualRoot/SelectionStrip") as Control

func _first_label_text(node: Node) -> String:
	for child in node.get_children():
		if child is Label and not String((child as Label).text).is_empty():
			return String((child as Label).text)
		var nested := _first_label_text(child)
		if not nested.is_empty():
			return nested
	return ""
