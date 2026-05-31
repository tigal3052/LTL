# 계약:
# - 책임: Apply subtle shader/tween interaction feedback to clickable, draggable, and blocked UI controls.
# - 입력: Control tree roots and individual Control nodes.
# - 출력: Installed CanvasItem materials, cursor shapes, hover/press tweens, and ripple parameters.
# - 금지: Gameplay state mutation, domain model mutation, network access.
#
# 실행: define reusable UI interaction effects inspired by GodotShaders 3D-hover and glow-ripple canvas-item patterns.
class_name InteractionFX
extends RefCounted

const InteractionCuePresenterScript = preload("res://src/ui/presenters/InteractionCuePresenter.gd")
const META_INSTALLED := "_ltl_interaction_fx_installed"
const META_ORIGINAL_POS := "_ltl_interaction_fx_original_pos"
const META_ORIGINAL_SELF_MODULATE := "_ltl_interaction_fx_original_self_modulate"
const META_SKIP := "_ltl_skip_interaction_fx"

const SHADER_CODE := """
shader_type canvas_item;

uniform float hover_strength : hint_range(0.0, 1.0) = 0.0;
uniform float press_strength : hint_range(0.0, 1.0) = 0.0;
uniform float disabled_strength : hint_range(0.0, 1.0) = 0.0;
uniform vec4 accent_color : source_color = vec4(0.53, 0.75, 0.82, 1.0);
uniform vec2 ripple_center = vec2(0.5, 0.5);
uniform vec2 hover_center = vec2(0.5, 0.5);
uniform float ripple_time : hint_range(0.0, 1.0) = 1.0;

void fragment() {
	vec4 base = texture(TEXTURE, UV) * COLOR;
	vec2 p = UV - vec2(0.5);
	float box_edge = 1.0 - smoothstep(0.32, 0.52, max(abs(p.x), abs(p.y)));
	float scan = sin((UV.y + TIME * 0.35) * 72.0) * 0.5 + 0.5;
	float pointer_light = 1.0 - smoothstep(0.0, 0.68, distance(UV, hover_center));
	float glow = hover_strength * (0.12 + scan * 0.035) + press_strength * 0.07;
	float ripple_dist = distance(UV, ripple_center);
	float ripple = smoothstep(0.045, 0.0, abs(ripple_dist - ripple_time * 0.58)) * max(0.0, 1.0 - ripple_time);
	base.rgb += accent_color.rgb * (box_edge * glow + pointer_light * hover_strength * 0.10 + ripple * 0.24);
	float gray = dot(base.rgb, vec3(0.299, 0.587, 0.114));
	base.rgb = mix(base.rgb, vec3(gray) * 0.72, disabled_strength * 0.62);
	base.a *= 1.0 - disabled_strength * 0.38;
	COLOR = base;
}
"""

# 실행: install effects on every interactive descendant under a root node.
static func install_tree(root: Node) -> void:
	if root == null:
		return
	if root is Control:
		install_control(root)
	for child in root.get_children():
		install_tree(child)

# 실행: install effects on one control when it can receive mouse interaction.
static func install_control(control: Control) -> void:
	if control == null:
		return
	if bool(control.get_meta(META_SKIP, false)):
		return
	if bool(control.get_meta(META_INSTALLED, false)):
		_sync_control_state(control)
		return
	if not _is_interactive(control):
		return
	control.set_meta(META_INSTALLED, true)
	control.set_meta(META_ORIGINAL_POS, control.position)
	control.set_meta(META_ORIGINAL_SELF_MODULATE, control.self_modulate)
	control.mouse_default_cursor_shape = _cursor_for(control)
	control.pivot_offset = control.size * 0.5
	if _supports_shader_material(control) and control.material == null:
		control.material = _new_material(_accent_for(control))
	control.mouse_entered.connect(func(): _apply_state(control, true, false))
	control.mouse_exited.connect(func(): _apply_state(control, false, false))
	control.gui_input.connect(func(event: InputEvent): _handle_gui_input(control, event))
	_apply_state(control, false, false)

# 실행: apply drag feedback to a control such as backpack slots or discard/drop areas.
static func apply_drag_feedback(control: Control, is_dragging: bool, can_drop: bool) -> void:
	if control == null:
		return
	if not control.has_meta(META_ORIGINAL_SELF_MODULATE):
		control.set_meta(META_ORIGINAL_SELF_MODULATE, control.self_modulate)
	var cue: Dictionary = InteractionCuePresenterScript.project_drag_state(is_dragging, can_drop)
	control.mouse_default_cursor_shape = _cursor_from_name(str(cue.get("cursor", "arrow")))
	if _supports_shader_material(control) and control.material == null:
		control.material = _new_material(_color_from_hex(str(cue.get("outlineColor", "#88c0d0"))))
	var mat := control.material as ShaderMaterial
	if mat != null:
		mat.set_shader_parameter("accent_color", _color_from_hex(str(cue.get("outlineColor", "#88c0d0"))))
		mat.set_shader_parameter("hover_strength", float(cue.get("alpha", 0.0)))
		mat.set_shader_parameter("press_strength", 0.0 if can_drop else 0.45)
	else:
		var base_modulate: Color = control.get_meta(META_ORIGINAL_SELF_MODULATE, control.self_modulate)
		if not is_dragging:
			control.self_modulate = base_modulate
		else:
			var accent := _color_from_hex(str(cue.get("outlineColor", "#88c0d0")))
			control.self_modulate = base_modulate.lerp(accent, 0.12 if can_drop else 0.20)
	var target_scale := Vector2.ONE * float(cue.get("scale", 1.0))
	if not is_dragging:
		control.modulate.a = 1.0
	_tween_control(control, target_scale, control.position, 1.0)

# 실행: react to mouse press/release with tactile compression and ripple.
static func _handle_gui_input(control: Control, event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		_set_hover_center(control, event.position)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_set_ripple(control, event.position)
			_apply_state(control, true, true)
		else:
			_apply_state(control, control.get_global_rect().has_point(control.get_global_mouse_position()), false)

# 실행: update shader/tween state for hover, press, and disabled variants.
static func _apply_state(control: Control, hovered: bool, pressed: bool) -> void:
	var disabled := _is_disabled(control)
	var cue: Dictionary = InteractionCuePresenterScript.project_control_state({"hovered": hovered, "pressed": pressed, "disabled": disabled})
	control.mouse_default_cursor_shape = _cursor_from_name(str(cue.get("cursor", "arrow")))
	if _supports_shader_material(control) and control.material == null:
		control.material = _new_material(_accent_for(control))
	var mat := control.material as ShaderMaterial
	if mat != null:
		mat.set_shader_parameter("hover_strength", float(cue.get("glow", 0.0)))
		mat.set_shader_parameter("press_strength", 1.0 if pressed else 0.0)
		mat.set_shader_parameter("disabled_strength", float(cue.get("shaderDisabled", 0.0)))
		mat.set_shader_parameter("accent_color", _color_from_hex(str(cue.get("outlineColor", "#88c0d0"))))
	else:
		var base_modulate: Color = control.get_meta(META_ORIGINAL_SELF_MODULATE, control.self_modulate)
		var adjusted := base_modulate
		if disabled:
			adjusted = adjusted.darkened(0.28)
		elif pressed:
			adjusted = adjusted.darkened(0.08)
		elif hovered:
			adjusted = adjusted.lerp(Color.WHITE, 0.10)
		control.self_modulate = adjusted
	var base_pos: Vector2 = control.get_meta(META_ORIGINAL_POS, control.position)
	var target_pos := base_pos + Vector2(0.0, -float(cue.get("lift", 0.0)))
	var target_scale := Vector2.ONE * float(cue.get("scale", 1.0))
	_tween_control(control, target_scale, target_pos, float(cue.get("alpha", 1.0)))

# 실행: start a short click ripple in UV space.
static func _set_ripple(control: Control, local_pos: Vector2) -> void:
	var mat := control.material as ShaderMaterial
	if mat == null:
		return
	var uv := Vector2(0.5, 0.5)
	if control.size.x > 0.0 and control.size.y > 0.0:
		uv = Vector2(clampf(local_pos.x / control.size.x, 0.0, 1.0), clampf(local_pos.y / control.size.y, 0.0, 1.0))
	mat.set_shader_parameter("ripple_center", uv)
	mat.set_shader_parameter("ripple_time", 0.0)
	var tween := control.create_tween()
	tween.tween_property(mat, "shader_parameter/ripple_time", 1.0, 0.42).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

# 실행: update hover light origin from local mouse position.
static func _set_hover_center(control: Control, local_pos: Vector2) -> void:
	var mat := control.material as ShaderMaterial
	if mat == null:
		return
	var uv := Vector2(0.5, 0.5)
	if control.size.x > 0.0 and control.size.y > 0.0:
		uv = Vector2(clampf(local_pos.x / control.size.x, 0.0, 1.0), clampf(local_pos.y / control.size.y, 0.0, 1.0))
	mat.set_shader_parameter("hover_center", uv)

# 실행: refresh dynamic disabled/cursor state for controls already installed.
static func _sync_control_state(control: Control) -> void:
	control.mouse_default_cursor_shape = _cursor_for(control)
	var mat := control.material as ShaderMaterial
	if mat != null:
		mat.set_shader_parameter("disabled_strength", 1.0 if _is_disabled(control) else 0.0)
		if _is_disabled(control):
			mat.set_shader_parameter("hover_strength", 0.0)
			mat.set_shader_parameter("press_strength", 0.0)
	else:
		var base_modulate: Color = control.get_meta(META_ORIGINAL_SELF_MODULATE, control.self_modulate)
		control.self_modulate = base_modulate.darkened(0.28) if _is_disabled(control) else base_modulate

# 실행: animate scale, lift, and alpha without changing layout minimum sizes.
static func _tween_control(control: Control, target_scale: Vector2, target_pos: Vector2, target_alpha: float) -> void:
	var tween := control.create_tween()
	tween.set_parallel(true)
	tween.tween_property(control, "scale", target_scale, 0.11).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	if can_translate_control(control):
		tween.tween_property(control, "position", target_pos, 0.11).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(control, "modulate:a", target_alpha, 0.12).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

# 실행: keep container-managed children on their layout position to avoid grid collapse.
static func can_translate_control(control: Control) -> bool:
	if control == null:
		return false
	return not (control.get_parent() is Container)

# 실행: detect controls that represent an action, selection, drag target, or click target.
static func _is_interactive(control: Control) -> bool:
	if bool(control.get_meta(META_SKIP, false)):
		return false
	if control is Button:
		return true
	if control is Slider:
		return true
	if control is LineEdit:
		return true
	if control is OptionButton:
		return true
	if control.mouse_filter == Control.MOUSE_FILTER_STOP and control.get_signal_connection_list("gui_input").size() > 0:
		return true
	if control.get_signal_connection_list("mouse_entered").size() > 0 or control.get_signal_connection_list("gui_input").size() > 0:
		return control.mouse_filter != Control.MOUSE_FILTER_IGNORE
	return false

# 실행: detect disabled state for common interactive controls.
static func _is_disabled(control: Control) -> bool:
	if control is BaseButton:
		return bool(control.disabled)
	if control is Slider:
		return not control.editable
	if control is LineEdit:
		return not control.editable
	return false

# 실행: choose a cursor before hover state projection runs.
static func _cursor_for(control: Control) -> int:
	return Control.CURSOR_FORBIDDEN if _is_disabled(control) else Control.CURSOR_POINTING_HAND

static func _supports_shader_material(control: Control) -> bool:
	if control == null:
		return false
	return control is BaseButton or control is Slider or control is LineEdit or control is OptionButton or control is TextureRect

# 실행: map stable cursor vocabulary into Godot cursor constants.
static func _cursor_from_name(name: String) -> int:
	match name:
		"pointing_hand":
			return Control.CURSOR_POINTING_HAND
		"forbidden":
			return Control.CURSOR_FORBIDDEN
		"can_drop":
			return Control.CURSOR_CAN_DROP
	return Control.CURSOR_ARROW

# 실행: create a shader material from the embedded UI feedback shader.
static func _new_material(accent: Color) -> ShaderMaterial:
	var shader := Shader.new()
	shader.code = SHADER_CODE
	var mat := ShaderMaterial.new()
	mat.shader = shader
	mat.set_shader_parameter("accent_color", accent)
	mat.set_shader_parameter("ripple_time", 1.0)
	mat.set_shader_parameter("hover_center", Vector2(0.5, 0.5))
	return mat

# 실행: choose an accent color from button text or control naming.
static func _accent_for(control: Control) -> Color:
	var name_text := str(control.name).to_lower()
	if control is Button:
		name_text += " " + str(control.text).to_lower()
	if name_text.contains("cancel") or name_text.contains("discard") or name_text.contains("reset"):
		return Color("#bf616a")
	if name_text.contains("start") or name_text.contains("confirm") or name_text.contains("claim"):
		return Color("#a3be8c")
	if name_text.contains("repair") or name_text.contains("shop"):
		return Color("#ebcb8b")
	return Color("#88c0d0")

# 실행: parse hex strings defensively.
static func _color_from_hex(value: String) -> Color:
	if value.begins_with("#") and value.length() >= 7:
		return Color(value)
	return Color("#88c0d0")
