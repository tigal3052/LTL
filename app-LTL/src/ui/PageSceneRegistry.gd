extends RefCounted

const PageShellHostScript = preload("res://src/ui/PageShellHost.gd")

static func build_shell_host(host_name: String) -> Control:
	var host := PageShellHostScript.new()
	host.name = host_name
	host.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	host.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	host.size_flags_vertical = Control.SIZE_EXPAND_FILL
	host.mouse_filter = Control.MOUSE_FILTER_PASS
	return host

static func is_meta_page(page_id: String, meta_page_ids: Array) -> bool:
	return page_id in meta_page_ids

static func register_page_scene(page_scenes: Dictionary, page_id: String, page_scene: Node, page_shell_host: Control, meta_page_shell_host: Control, meta_page_ids: Array) -> void:
	if page_scene == null:
		return
	page_scene.name = "%sPageShell" % page_id.capitalize()
	if page_scene is Control:
		page_scene.anchor_left = 0.0
		page_scene.anchor_top = 0.0
		page_scene.anchor_right = 0.0
		page_scene.anchor_bottom = 0.0
		page_scene.offset_left = 0.0
		page_scene.offset_top = 0.0
		page_scene.offset_right = 0.0
		page_scene.offset_bottom = 0.0
		page_scene.grow_horizontal = Control.GROW_DIRECTION_END
		page_scene.grow_vertical = Control.GROW_DIRECTION_END
		page_scene.visible = false
	var host := page_shell_host
	if is_meta_page(page_id, meta_page_ids):
		host = meta_page_shell_host
	host.add_child(page_scene)
	page_scenes[page_id] = page_scene

static func activate_page(page_scenes: Dictionary, page_id: String, page_shell_host: Control, meta_page_shell_host: Control, meta_page_ids: Array) -> Node:
	for scene_id in page_scenes.keys():
		var page_scene = page_scenes.get(scene_id)
		if page_scene != null:
			page_scene.visible = scene_id == page_id
	var meta_page_active := is_meta_page(page_id, meta_page_ids)
	if meta_page_shell_host != null:
		meta_page_shell_host.visible = meta_page_active
		if meta_page_active:
			meta_page_shell_host.move_to_front()
	if page_shell_host != null:
		page_shell_host.visible = not meta_page_active and not page_id.is_empty()
	return page_scenes.get(page_id)
