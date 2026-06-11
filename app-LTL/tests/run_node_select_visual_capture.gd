extends SceneTree

func _init() -> void:
	call_deferred("_fail_fast")

func _fail_fast() -> void:
	push_error("run_node_select_visual_capture.gd is retired because the headless dummy renderer can leave stale screenshots behind. Use tools/capture-node-select-runtime.ps1 for live-window node-select QA.")
	await process_frame
	quit(1)
