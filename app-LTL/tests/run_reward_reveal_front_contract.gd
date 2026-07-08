# 계약:
# - 책임: reward reveal overlay가 Control 호환 front-order API로 맨 앞으로 올라오는지 국소적으로 검증한다.
# - 입력: `MainViewRuntime`의 reward reveal overlay front helper.
# - 출력: 성공 시 `REWARD_REVEAL_FRONT_CONTRACT_OK`, 실패 시 오류와 종료 코드 1.
# - 금지: unrelated UI suite 실행, gameplay state mutation, broader contract masking.
#
# 실행: verify the reward reveal overlay front-order helper in isolation.
extends SceneTree

# 실행: construct a minimal runtime and ensure the overlay moves above its sibling.
func _init() -> void:
	var MainViewRuntimeScript = load("res://src/ui/MainViewRuntime.gd")
	if MainViewRuntimeScript == null:
		push_error("reward reveal front contract failed to load MainViewRuntime.gd")
		quit(1)
		return
	var runtime = MainViewRuntimeScript.new()
	var parent := Control.new()
	var overlay := Control.new()
	var blocker := Control.new()
	parent.add_child(overlay)
	parent.add_child(blocker)
	runtime.reward_reveal_overlay = overlay
	if not runtime.has_method("_bring_reward_reveal_overlay_to_front"):
		push_error("reward reveal front contract missing _bring_reward_reveal_overlay_to_front helper")
		parent.free()
		runtime.free()
		quit(1)
		return
	runtime.call("_bring_reward_reveal_overlay_to_front")
	if parent.get_child(parent.get_child_count() - 1) != overlay:
		push_error("reward reveal front contract failed to move overlay above sibling controls")
		parent.free()
		runtime.free()
		quit(1)
		return
	parent.free()
	runtime.free()
	print("REWARD_REVEAL_FRONT_CONTRACT_OK")
	quit(0)
