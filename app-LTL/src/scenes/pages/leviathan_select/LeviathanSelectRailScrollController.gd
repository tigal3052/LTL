class_name LeviathanSelectRailScrollController
extends RefCounted

var _host: Control
var _cards_scroll: ScrollContainer
var _cards_box: VBoxContainer
var _cards_spring_top: Control
var _cards_spring_bottom: Control
var _top_snap_threshold: int
var _top_rest_gap: float
var _drag_threshold: float
var _bounce_tween: Tween
var _drag_tracking := false
var _drag_started := false
var _drag_origin_y := 0.0
var _drag_last_y := 0.0
var _suppress_next_press_until_msec := 0
var _drag_started_on_button := false

func _init(host: Control, cards_scroll: ScrollContainer, cards_box: VBoxContainer, cards_spring_top: Control, cards_spring_bottom: Control, top_snap_threshold: int, top_rest_gap: float, drag_threshold: float) -> void:
	_host = host
	_cards_scroll = cards_scroll
	_cards_box = cards_box
	_cards_spring_top = cards_spring_top
	_cards_spring_bottom = cards_spring_bottom
	_top_snap_threshold = top_snap_threshold
	_top_rest_gap = top_rest_gap
	_drag_threshold = drag_threshold

func refresh_springs(cards_spring_top: Control, cards_spring_bottom: Control) -> void:
	_cards_spring_top = cards_spring_top
	_cards_spring_bottom = cards_spring_bottom
	reset_bounce()

func handle_button_gui_input(button: Button, event: InputEvent) -> void:
	_handle_surface_gui_input(button, event, true)

func handle_preview_gui_input(preview_surface: Control, event: InputEvent) -> void:
	_handle_surface_gui_input(preview_surface, event, false)

func _handle_surface_gui_input(surface: Control, event: InputEvent, started_on_button: bool) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			step_scroll(-1)
			_accept_gui_event(surface)
			return
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			step_scroll(1)
			_accept_gui_event(surface)
			return
	if _handle_drag_input(event, started_on_button):
		_accept_gui_event(surface)

func handle_scroll_gui_input(event: InputEvent) -> void:
	if _handle_drag_input(event, false):
		_accept_gui_event(_cards_scroll)
		return
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			step_scroll(-1)
			_accept_gui_event(_cards_scroll)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			step_scroll(1)
			_accept_gui_event(_cards_scroll)
	elif event is InputEventPanGesture and absf(event.delta.y) > 0.0:
		_apply_scroll_delta(int(round(event.delta.y * 28.0)), true)
		_accept_gui_event(_cards_scroll)

func _accept_gui_event(control: Control) -> void:
	if control != null:
		control.accept_event()
	if _host != null and _host.get_viewport() != null:
		_host.get_viewport().set_input_as_handled()

func consume_suppressed_press() -> bool:
	if _suppress_next_press_until_msec <= 0:
		return false
	if Time.get_ticks_msec() > _suppress_next_press_until_msec:
		_suppress_next_press_until_msec = 0
		return false
	_suppress_next_press_until_msec = 0
	return true

func reset_top_snap_if_needed() -> void:
	_normalize_top_origin_if_needed()

func reset_bounce() -> void:
	if is_instance_valid(_bounce_tween):
		_bounce_tween.kill()
	_set_card_spring(_cards_spring_top, _top_rest_gap)
	_set_card_spring(_cards_spring_bottom, 0.0)

func _handle_drag_input(event: InputEvent, started_on_button: bool) -> bool:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_begin_drag(event.global_position.y, started_on_button)
			return false
		var did_drag := _drag_started
		_end_drag()
		return did_drag
	if event is InputEventMouseMotion and _drag_tracking and (event.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0:
		return _update_drag(event.global_position.y)
	return false

func _begin_drag(pointer_y: float, started_on_button: bool) -> void:
	_drag_tracking = true
	_drag_started = false
	_drag_origin_y = pointer_y
	_drag_last_y = pointer_y
	_drag_started_on_button = started_on_button

func _update_drag(pointer_y: float) -> bool:
	if not _drag_tracking:
		return false
	var total_delta := pointer_y - _drag_origin_y
	if not _drag_started:
		if absf(total_delta) < _drag_threshold:
			return false
		_drag_started = true
		if _drag_started_on_button:
			_suppress_next_press_until_msec = Time.get_ticks_msec() + 200
	var step_delta := pointer_y - _drag_last_y
	_drag_last_y = pointer_y
	if is_zero_approx(step_delta):
		return false
	return _apply_scroll_delta(-int(round(step_delta)), false)

func _end_drag() -> void:
	var did_drag := _drag_started
	_drag_tracking = false
	_drag_started = false
	_drag_started_on_button = false
	if did_drag and _cards_scroll.scroll_vertical <= _top_snap_threshold:
		_normalize_top_origin_if_needed()

func _set_scroll_clamped(value: int) -> bool:
	var bar := _cards_scroll.get_v_scroll_bar()
	if bar == null:
		return false
	var max_scroll := maxi(0, int(round(bar.max_value - bar.page)))
	var next_value := clampi(value, 0, max_scroll)
	var moved := next_value != _cards_scroll.scroll_vertical
	_cards_scroll.scroll_vertical = next_value
	return moved

func step_scroll(direction: int) -> void:
	if direction == 0:
		return
	var bar := _cards_scroll.get_v_scroll_bar()
	if bar == null:
		return
	var max_scroll := maxi(0, int(round(bar.max_value - bar.page)))
	var current_value := _cards_scroll.scroll_vertical
	var target_value := current_value
	var anchors := _scroll_anchors(max_scroll)
	if direction > 0:
		for anchor in anchors:
			if anchor > current_value:
				target_value = anchor
				break
		if target_value == current_value:
			target_value = max_scroll
	else:
		for index in range(anchors.size() - 1, -1, -1):
			var anchor := anchors[index]
			if anchor < current_value:
				target_value = anchor
				break
		if target_value <= _top_snap_threshold:
			target_value = 0
	var moved := _set_scroll_clamped(target_value)
	if moved:
		return
	if direction < 0 and current_value == 0:
		_bounce(-1)
	elif direction > 0 and current_value == max_scroll:
		_bounce(1)

func _scroll_anchors(max_scroll: int) -> Array[int]:
	var anchors: Array[int] = [0, max_scroll]
	var top_offset := _cards_spring_top.custom_minimum_size.y if _cards_spring_top != null else 0.0
	for child in _cards_box.get_children():
		if child == _cards_spring_top or child == _cards_spring_bottom:
			continue
		if child is Control:
			var anchor := clampi(int(round((child as Control).position.y - top_offset)), 0, max_scroll)
			anchors.append(anchor)
	anchors.sort()
	var deduped: Array[int] = []
	for anchor in anchors:
		if deduped.is_empty() or deduped[-1] != anchor:
			deduped.append(anchor)
	return deduped

func _apply_scroll_delta(delta: int, emit_bounce: bool) -> bool:
	if delta == 0:
		return false
	var bar := _cards_scroll.get_v_scroll_bar()
	if bar == null:
		return false
	var max_scroll := maxi(0, int(round(bar.max_value - bar.page)))
	var current_value := _cards_scroll.scroll_vertical
	var requested_value := current_value + delta
	var next_value := clampi(requested_value, 0, max_scroll)
	if delta < 0 and next_value <= _top_snap_threshold:
		next_value = 0
	var moved := _set_scroll_clamped(next_value)
	var hit_edge := false
	if max_scroll == 0:
		hit_edge = true
	elif delta < 0:
		hit_edge = next_value == 0 and requested_value < 0
	elif delta > 0:
		hit_edge = next_value == max_scroll and requested_value > max_scroll
	if emit_bounce and hit_edge:
		_bounce(-1 if delta < 0 else 1)
	return moved

func _normalize_top_origin_if_needed() -> void:
	if _cards_scroll.scroll_vertical <= _top_snap_threshold:
		_cards_scroll.scroll_vertical = 0

func _bounce(direction: int) -> void:
	var spring := _cards_spring_top if direction < 0 else _cards_spring_bottom
	if spring == null:
		return
	if is_instance_valid(_bounce_tween):
		_bounce_tween.kill()
	_set_card_spring(_cards_spring_top, _top_rest_gap)
	_set_card_spring(_cards_spring_bottom, 0.0)
	var rest_height := _top_rest_gap if spring == _cards_spring_top else 0.0
	_bounce_tween = _host.create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_bounce_tween.tween_property(spring, "custom_minimum_size", Vector2(0.0, rest_height + 18.0), 0.10)
	_bounce_tween.tween_property(spring, "custom_minimum_size", Vector2(0.0, rest_height), 0.14)

func _set_card_spring(spring: Control, height: float) -> void:
	if spring == null:
		return
	spring.custom_minimum_size = Vector2(0.0, height)
	_cards_box.queue_sort()
