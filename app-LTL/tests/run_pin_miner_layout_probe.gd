extends SceneTree

var failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var MainScene = load("res://src/Main.tscn")
	_assert(MainScene != null, "main scene resource loads for pin/miner runtime probe")
	if MainScene == null:
		_finish()
		return

	var main_instance = MainScene.instantiate()
	_assert(main_instance != null, "main scene instantiates for pin/miner runtime probe")
	if main_instance == null:
		_finish()
		return

	root.add_child(main_instance)
	await process_frame
	await process_frame

	var node_map_scene = main_instance.node_map_scene
	_assert(node_map_scene != null, "node map scene exists for runtime probe")
	if node_map_scene != null:
		node_map_scene.press_color_button(0)
		if node_map_scene.map_node_count() > 0:
			node_map_scene.press_node_button(0)
	await process_frame
	await process_frame

	main_instance.start_button.pressed.emit()
	await process_frame
	await process_frame

	var backpack_ui = main_instance.backpack_ui
	var battlefield_ui = main_instance.battlefield_ui
	_assert(backpack_ui != null, "backpack ui exists in runtime probe")
	_assert(battlefield_ui != null, "battlefield ui exists in runtime probe")
	if backpack_ui == null or battlefield_ui == null:
		main_instance.queue_free()
		await process_frame
		_finish()
		return

	if backpack_ui.backpack_grid_mock.get_child_count() == 0:
		backpack_ui.setup_grid_slots()
	backpack_ui.update_pin_overlays({"phase": "combat", "hud": {"pin": {"progress": 100.0}}})
	for _frame in range(30):
		await process_frame
	backpack_ui.call("_layout_pin_overlays")
	await process_frame

	var pin_specs: Array = backpack_ui.pin_corner_specs()
	for index in range(mini(backpack_ui.pin_nodes.size(), pin_specs.size())):
		var pin := backpack_ui.pin_nodes[index] as TextureRect
		var spec: Dictionary = pin_specs[index]
		var cell_rect: Rect2 = backpack_ui.pin_grid_cell_rect_local(int(spec.get("column", 0)), int(spec.get("row", 0)))
		_assert(pin != null, "pin node exists for runtime probe index %d" % index)
		if pin == null:
			continue
		_assert(pin.visible, "pin_%d is visible in combat runtime probe" % [index + 1])
		_assert(pin.texture is AtlasTexture, "pin_%d uses a trimmed atlas texture in the live scene" % [index + 1])
		_assert(pin.size.y <= cell_rect.size.y * 1.15 + 0.5, "pin_%d stays near a one-slot-tall footprint in the live scene (pin=%s cell=%s)" % [index + 1, str(pin.size), str(cell_rect.size)])
		if int(spec.get("row", 0)) == 0:
			_assert(absf(pin.position.y - cell_rect.position.y) <= 1.5, "pin_%d sits on the top edge of its requested border tile in the live scene (pin_y=%.3f cell_y=%.3f)" % [index + 1, pin.position.y, cell_rect.position.y])
		else:
			var bottom_edge := pin.position.y + pin.size.y
			_assert(absf(bottom_edge - cell_rect.end.y) <= 1.5, "pin_%d sits on the bottom edge of its requested border tile in the live scene (pin_bottom=%.3f cell_bottom=%.3f)" % [index + 1, bottom_edge, cell_rect.end.y])
		if str(spec.get("horizontal", "")) == "left":
			_assert(pin.position.x < cell_rect.position.x, "pin_%d extends outward from the left side of its requested border tile (pin_x=%.3f cell_x=%.3f)" % [index + 1, pin.position.x, cell_rect.position.x])
		else:
			_assert(pin.position.x + pin.size.x > cell_rect.end.x, "pin_%d extends outward from the right side of its requested border tile (pin_right=%.3f cell_right=%.3f)" % [index + 1, pin.position.x + pin.size.x, cell_rect.end.x])

	battlefield_ui.play_miner_pose_for_cell("r0c1")
	await create_timer(0.12).timeout
	for _frame in range(4):
		await process_frame

	var title_miner := battlefield_ui.title_miner as TextureRect
	var visual_root := battlefield_ui.battlefield_visual_root as Control
	_assert(title_miner != null, "title miner exists in runtime probe")
	_assert(visual_root != null, "battlefield visual root exists in runtime probe")
	if title_miner != null and visual_root != null:
		_assert(title_miner.texture is AtlasTexture, "title miner uses a trimmed atlas texture after the live pose swap")
		var left_edge := title_miner.position.x
		_assert(absf(title_miner.position.y) <= 0.5, "title miner sits on the top edge of the battlefield visual root in the live scene")
		_assert(absf(left_edge) <= 0.5, "title miner hugs the left edge of the battlefield visual root in the live scene")

	main_instance.queue_free()
	await process_frame
	_finish()

func _assert(condition: bool, label: String) -> void:
	if not condition:
		failures.append(label)

func _finish() -> void:
	if failures.is_empty():
		print("PIN_MINER_LAYOUT_PROBE_OK")
		call_deferred("quit", 0)
		return
	for failure in failures:
		push_error(failure)
	call_deferred("quit", 1)
