extends SceneTree

const MainControllerRuntimeScript = preload("res://src/MainControllerRuntime.gd")
const TERRAIN_SHIFT_SECONDS := 1.5

var failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var controller = MainControllerRuntimeScript.new()
	var timer := Timer.new()
	timer.wait_time = TERRAIN_SHIFT_SECONDS
	root.add_child(timer)
	controller.set("shift_timer", timer)
	_assert(timer != null, "terrain shift timer exists for codex pause timing contract")
	if timer == null:
		controller.free()
		await process_frame
		await _finish()
		return

	timer.wait_time = TERRAIN_SHIFT_SECONDS
	timer.start(TERRAIN_SHIFT_SECONDS)
	await create_timer(0.08).timeout
	var remaining_before_pause: float = timer.time_left
	_assert(remaining_before_pause > 0.0 and remaining_before_pause < TERRAIN_SHIFT_SECONDS, "terrain timer has partial progress before codex pause")

	controller.call("_set_battle_pause_active", true)
	await create_timer(0.08).timeout
	controller.call("_set_battle_pause_active", false)
	await process_frame

	_assert_close(timer.wait_time, TERRAIN_SHIFT_SECONDS, 0.001, "resuming from codex keeps the steady terrain interval instead of repeating the saved remainder")
	_assert(timer.time_left > 0.0 and timer.time_left <= remaining_before_pause + 0.05, "resuming from codex continues from the saved remaining terrain time")

	timer.queue_free()
	controller.free()
	await process_frame
	await _finish()

func _assert(condition: bool, label: String) -> void:
	if not condition:
		failures.append(label)

func _assert_close(actual: float, expected: float, tolerance: float, label: String) -> void:
	if absf(actual - expected) > tolerance:
		failures.append("%s: expected %.3f, got %.3f" % [label, expected, actual])

func _finish() -> void:
	if failures.is_empty():
		print("CODEX_PAUSE_TIMING_CONTRACT_OK")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)
