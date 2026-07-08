extends SceneTree

const VIEWPORT_SIZE := Vector2i(1440, 900)

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	DisplayServer.window_set_size(VIEWPORT_SIZE)
	DisplayServer.window_set_position(Vector2i(0, 0))
	root.size = VIEWPORT_SIZE
	var MainScene = load("res://src/Main.tscn")
	if MainScene == null:
		push_error("main scene failed to load for leviathan-select visual hold")
		quit(1)
		return
	var main_instance = MainScene.instantiate()
	root.add_child(main_instance)
	await process_frame
	await process_frame
	await process_frame
	var character_page = main_instance.get("character_select_page")
	if character_page == null:
		push_error("character select page missing for leviathan-select visual hold")
		quit(1)
		return
	character_page.color_selected.emit("purple")
	character_page.continue_requested.emit()
	await process_frame
	await process_frame
	while true:
		await process_frame
