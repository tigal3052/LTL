# 계약:
# - 책임: UI interaction states into visual cue values that communicate affordance, press, drag, and blocked actions.
# - 입력: hovered/pressed/disabled/drag dictionaries from UI controls.
# - 출력: scale, lift, glow, alpha, cursor, outline, and drop-state dictionaries for render scripts.
# - 금지: SceneTree access, tween creation, direct Control mutation.
#
# 실행: define pure interaction cue projection helpers.
class_name InteractionCuePresenter
extends RefCounted

# 실행: project one clickable control state into visual feedback values.
static func project_control_state(state: Dictionary) -> Dictionary:
	var disabled := bool(state.get("disabled", false))
	var pressed := bool(state.get("pressed", false)) and not disabled
	var hovered := bool(state.get("hovered", false)) and not disabled
	if disabled:
		return {
			"scale": 1.0,
			"lift": 0.0,
			"glow": 0.0,
			"alpha": 0.46,
			"cursor": "forbidden",
			"outlineColor": "#5b3236",
			"shaderDisabled": 1.0
		}
	if pressed:
		return {
			"scale": 0.985,
			"lift": -1.0,
			"glow": 0.38,
			"alpha": 1.0,
			"cursor": "pointing_hand",
			"outlineColor": "#ffd766",
			"shaderDisabled": 0.0
		}
	if hovered:
		return {
			"scale": 1.018,
			"lift": 2.0,
			"glow": 0.62,
			"alpha": 1.0,
			"cursor": "pointing_hand",
			"outlineColor": "#88c0d0",
			"shaderDisabled": 0.0
		}
	return {
		"scale": 1.0,
		"lift": 0.0,
		"glow": 0.08,
		"alpha": 0.92,
		"cursor": "arrow",
		"outlineColor": "#344050",
		"shaderDisabled": 0.0
	}

# 실행: project drag/drop feedback so valid and blocked outcomes are visually distinct.
static func project_drag_state(is_dragging: bool, can_drop: bool) -> Dictionary:
	if not is_dragging:
		return {
			"dropState": "idle",
			"scale": 1.0,
			"alpha": 0.0,
			"outlineColor": "#344050",
			"cursor": "arrow"
		}
	if can_drop:
		return {
			"dropState": "valid",
			"scale": 1.04,
			"alpha": 0.36,
			"outlineColor": "#a3be8c",
			"cursor": "can_drop"
		}
	return {
		"dropState": "blocked",
		"scale": 0.98,
		"alpha": 0.42,
		"outlineColor": "#bf616a",
		"cursor": "forbidden"
	}

# 실행: map cursor names to Godot cursor constants through a tiny stable vocabulary.
static func cursor_name_for_control(disabled: bool, can_interact: bool) -> String:
	if disabled:
		return "forbidden"
	return "pointing_hand" if can_interact else "arrow"
