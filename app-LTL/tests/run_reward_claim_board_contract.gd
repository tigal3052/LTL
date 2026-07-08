extends SceneTree

const VIEWPORT_SIZES := [
	Vector2i(1280, 720),
	Vector2i(1440, 900),
	Vector2i(1920, 1080)
]

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var TestClass = load("res://tests/test_reward_claim_board_contract.gd")
	if TestClass == null:
		push_error("Reward claim board contract runner failed to load res://tests/test_reward_claim_board_contract.gd")
		quit(1)
		return
	for viewport_size in VIEWPORT_SIZES:
		root.size = viewport_size
		await process_frame
		var tester = TestClass.new()
		var result: Dictionary = await tester.run_all_tests()
		if bool(result.get("ok", false)):
			continue
		for failure in result.get("errors", []):
			push_error("Reward claim board contract failed at %s: %s" % [str(viewport_size), failure])
		await process_frame
		quit(1)
		return
	print("REWARD_CLAIM_BOARD_CONTRACT_OK")
	await process_frame
	quit(0)
