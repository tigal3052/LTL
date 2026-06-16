# 怨꾩빟:
# - 梨낆엫: backpack combat pin overlay count, layout, and removal VFX runtime helpers.
# - ?낅젰: BackpackUI owner state, combat HUD pin scene data, and grid cell geometry.
# - 異쒕젰: pin node setup, layout positions, visibility state, and local removal tweens.
# - 湲덉?: inventory mutation, artifact rendering, and non-pin backpack slot input.
#
# ?ㅽ뻾: provide focused pin overlay behavior for BackpackUI without owning inventory state.
class_name BackpackPinOverlayRuntime
extends RefCounted

const BackpackPinLayoutPolicyScript = preload("res://src/ui/presenters/BackpackPinLayoutPolicy.gd")
const PIN_1_TEXTURE := preload("res://resources/UI/pin/pin_1.png")
const PIN_2_TEXTURE := preload("res://resources/UI/pin/pin_2.png")
const PIN_3_TEXTURE := preload("res://resources/UI/pin/pin_3.png")
const PIN_4_TEXTURE := preload("res://resources/UI/pin/pin_4.png")
const BACKPACK_BASE_SIDE_MARGIN := 16
const PIN_REMOVAL_ANTICIPATION_SECONDS := 0.07
const PIN_REMOVAL_PULL_SECONDS := 0.20
const PIN_REMOVAL_PULL_RATIO := 0.45
const PIN_REMOVAL_ROTATION_DEGREES := 18.0
const PIN_REMOVAL_ANTICIPATION_SCALE := 0.92
const PIN_Z_INDEX := 24
const PIN_LAYOUT_SETTLE_FRAMES := 8
const PIN_VISIBLE_REGIONS := [
	Rect2(211, 237, 863, 655),
	Rect2(328, 237, 863, 655),
	Rect2(328, 230, 863, 655),
	Rect2(211, 230, 863, 655)
]

static func setup(owner) -> void:
	if owner.pin_overlay_canvas == null:
		owner.pin_overlay_canvas = Control.new()
		owner.pin_overlay_canvas.name = "PinOverlayCanvas"
		owner.pin_overlay_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
		owner.pin_overlay_canvas.clip_contents = false
		owner.pin_overlay_canvas.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		owner.add_child(owner.pin_overlay_canvas)
	else:
		for child in owner.pin_overlay_canvas.get_children():
			child.queue_free()
	owner.pin_nodes.clear()
	var textures: Array[Texture2D] = [PIN_1_TEXTURE, PIN_2_TEXTURE, PIN_3_TEXTURE, PIN_4_TEXTURE]
	for index in range(textures.size()):
		var pin := TextureRect.new()
		pin.name = "Pin%d" % [index + 1]
		var atlas := AtlasTexture.new()
		atlas.atlas = textures[index]
		atlas.region = visible_region_for_index(index)
		pin.texture = atlas
		pin.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		pin.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
		pin.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		pin.mouse_filter = Control.MOUSE_FILTER_IGNORE
		pin.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
		pin.top_level = false
		pin.z_index = PIN_Z_INDEX
		pin.visible = false
		owner.pin_overlay_canvas.add_child(pin)
		owner.pin_nodes.append(pin)

static func update(owner, scene: Dictionary) -> void:
	var phase := str(scene.get("phase", ""))
	var pin_state: Dictionary = scene.get("hud", {}).get("pin", {})
	owner.pin_shell_active = phase == "combat"
	var next_visible_count := visible_count(phase == "combat", float(pin_state.get("progress", 0.0)))
	if phase != "combat":
		owner.pin_shell_active = false
		owner.pin_layout_retry_budget = 0
		owner.pin_live_layout_retry_budget = 0
		apply_pin_shell_gutter(owner, 0.0)
		reset_vfx_state(owner)
		owner.visible_pin_count_value = 0
		for index in range(owner.pin_nodes.size()):
			owner.pin_nodes[index].visible = false
		prime_layout_settle(owner)
		return
	if owner.pin_state_initialized:
		for removed_index in removed_indices(owner.visible_pin_count_value, next_visible_count):
			play_removed_vfx(owner, removed_index)
	else:
		owner.pin_state_initialized = true
	owner.visible_pin_count_value = next_visible_count
	for index in range(owner.pin_nodes.size()):
		if is_visible(index, owner.visible_pin_count_value, owner.pin_nodes.size()):
			reset_pin_visual(owner.pin_nodes[index])
			owner.pin_nodes[index].visible = true
		elif not owner.pin_nodes[index].has_meta("pin_removing"):
			owner.pin_nodes[index].visible = false
	prime_layout_settle(owner)

static func visible_count(active: bool, progress: float) -> int:
	if not active:
		return 0
	var pin_val := clampf(progress, 0.0, 100.0)
	if pin_val >= 100.0:
		return 4
	if pin_val >= 75.0:
		return 3
	if pin_val >= 50.0:
		return 2
	if pin_val >= 25.0:
		return 1
	return 0

static func corner_specs() -> Array:
	return [
		{"name": "Pin1", "column": 0, "row": 0, "horizontal": "left", "vertical": "center"},
		{"name": "Pin2", "column": 9, "row": 0, "horizontal": "right", "vertical": "center"},
		{"name": "Pin3", "column": 9, "row": 9, "horizontal": "right", "vertical": "center"},
		{"name": "Pin4", "column": 0, "row": 9, "horizontal": "left", "vertical": "center"}
	]

static func visible_region_for_index(index: int) -> Rect2:
	if index < 0 or index >= PIN_VISIBLE_REGIONS.size():
		return PIN_VISIBLE_REGIONS[0]
	return PIN_VISIBLE_REGIONS[index]

static func shell_side_margin_for_outset(side_outset: float, shell_active: bool) -> int:
	if not shell_active:
		return BACKPACK_BASE_SIDE_MARGIN
	return BACKPACK_BASE_SIDE_MARGIN + int(round(side_outset))

static func visible_indices(visible_count_value: int, total_count: int = 4) -> Array:
	var safe_total := maxi(0, total_count)
	var safe_count := clampi(visible_count_value, 0, safe_total)
	var start_index := safe_total - safe_count
	var indices: Array = []
	for index in range(start_index, safe_total):
		indices.append(index)
	return indices

static func is_visible(index: int, visible_count_value: int, total_count: int = 4) -> bool:
	return visible_indices(visible_count_value, total_count).has(index)

static func pull_direction_for_index(index: int) -> Vector2:
	match index:
		0:
			return Vector2(-1, -1).normalized()
		1:
			return Vector2(1, -1).normalized()
		2:
			return Vector2(1, 1).normalized()
		3:
			return Vector2(-1, 1).normalized()
		_:
			return Vector2.ZERO

static func removal_vfx_profile_for_index(index: int, pin_extent: float) -> Dictionary:
	return {
		"direction": pull_direction_for_index(index),
		"anticipationDuration": PIN_REMOVAL_ANTICIPATION_SECONDS,
		"pullDuration": PIN_REMOVAL_PULL_SECONDS,
		"pullDistance": maxf(0.0, pin_extent) * PIN_REMOVAL_PULL_RATIO,
		"rotationDegrees": PIN_REMOVAL_ROTATION_DEGREES,
		"anticipationScale": PIN_REMOVAL_ANTICIPATION_SCALE,
		"fadeToAlpha": 0.0,
		"localOnly": true
	}

static func removed_indices(previous_count: int, next_count: int) -> Array:
	var previous_indices: Array = visible_indices(previous_count)
	var next_indices: Array = visible_indices(next_count)
	var removed: Array = []
	for index in previous_indices:
		if not next_indices.has(index):
			removed.append(index)
	return removed

static func apply_grid_shell_layout_policy(owner) -> void:
	if owner.backpack_grid_mock == null:
		return
	owner.backpack_grid_mock.size_flags_horizontal = owner.backpack_grid_horizontal_flags()
	apply_pin_shell_gutter(owner, 0.0)

static func apply_pin_shell_gutter(owner, side_outset: float) -> bool:
	if owner.backpack_margin == null:
		return false
	var next_margin := shell_side_margin_for_outset(side_outset, owner.pin_shell_active)
	var changed := false
	if owner.backpack_margin.get_theme_constant("margin_left") != next_margin:
		owner.backpack_margin.add_theme_constant_override("margin_left", next_margin)
		changed = true
	if owner.backpack_margin.get_theme_constant("margin_right") != next_margin:
		owner.backpack_margin.add_theme_constant_override("margin_right", next_margin)
		changed = true
	return changed

static func layout(owner) -> void:
	if owner.backpack_grid_mock == null or owner.backpack_grid_mock.get_child_count() == 0 or owner.pin_nodes.is_empty():
		return
	apply_grid_shell_layout_policy(owner)
	var specs := corner_specs()
	var target_side_outset := 0.0
	for index in range(mini(owner.pin_nodes.size(), specs.size())):
		var spec: Dictionary = specs[index]
		var cell_rect := grid_cell_rect_local(owner, int(spec.get("column", 0)), int(spec.get("row", 0)))
		if cell_rect.size.x <= 0.0 or cell_rect.size.y <= 0.0:
			continue
		target_side_outset = maxf(target_side_outset, owner.pin_side_outset_for_slot_extent(owner.pin_slot_extent_for_cell_rect(cell_rect)))
	var gutter_changed := apply_pin_shell_gutter(owner, target_side_outset)
	if gutter_changed:
		if owner.pin_layout_retry_budget < 3:
			owner.pin_layout_retry_budget += 1
			queue_layout(owner)
	else:
		owner.pin_layout_retry_budget = 0
	for index in range(mini(owner.pin_nodes.size(), specs.size())):
		var pin: TextureRect = owner.pin_nodes[index] as TextureRect
		var spec: Dictionary = specs[index]
		var cell_rect := grid_cell_rect_local(owner, int(spec.get("column", 0)), int(spec.get("row", 0)))
		if cell_rect.size.x <= 0.0 or cell_rect.size.y <= 0.0:
			pin.visible = false
			continue
		var slot_extent: float = owner.pin_slot_extent_for_cell_rect(cell_rect)
		var grid_overlap: float = owner.pin_grid_overlap_for_slot_extent(slot_extent)
		pin.size = owner.pin_display_size_for_slot_extent(slot_extent)
		pin.pivot_offset = pin.size * 0.5
		var anchor: Vector2 = corner_anchor_for_rect(cell_rect, spec)
		if not pin.has_meta("pin_removing"):
			pin.position = position_for_anchor(anchor, pin.size, spec, grid_overlap)
		pin.z_index = PIN_Z_INDEX
		if is_visible(index, owner.visible_pin_count_value, owner.pin_nodes.size()):
			pin.visible = true
		elif not pin.has_meta("pin_removing"):
			pin.visible = false

static func grid_cell_rect_local(owner, column: int, row: int) -> Rect2:
	var cell: Control = owner._grid_cell(column, row) as Control
	if cell == null:
		return Rect2()
	var local_canvas: CanvasItem = owner.pin_overlay_canvas if owner.pin_overlay_canvas != null else owner
	var local_origin: Vector2 = local_canvas.get_global_transform_with_canvas().affine_inverse() * cell.get_global_transform_with_canvas().origin
	return Rect2(local_origin, cell.size)

static func queue_layout(owner) -> void:
	if owner.pin_layout_queued:
		return
	if not owner.is_inside_tree():
		owner.call_deferred("_layout_pin_overlays")
		return
	owner.pin_layout_queued = true
	owner.call_deferred("_run_queued_pin_layout")

static func prime_layout_settle(owner) -> void:
	owner.pin_live_layout_retry_budget = max(owner.pin_live_layout_retry_budget, PIN_LAYOUT_SETTLE_FRAMES)
	queue_layout(owner)

static func run_queued_pin_layout(owner) -> void:
	await owner.get_tree().process_frame
	owner.pin_layout_queued = false
	layout(owner)
	if pins_need_live_layout_retry(owner) and owner.pin_live_layout_retry_budget < 4:
		owner.pin_live_layout_retry_budget += 1
		queue_layout(owner)
		return
	owner.pin_live_layout_retry_budget = 0

static func pins_need_live_layout_retry(owner) -> bool:
	var specs := corner_specs()
	for index in range(mini(owner.pin_nodes.size(), specs.size())):
		var pin: TextureRect = owner.pin_nodes[index] as TextureRect
		var spec: Dictionary = specs[index]
		if pin == null or (not pin.visible and not pin.has_meta("pin_removing")):
			continue
		var cell_rect := grid_cell_rect_local(owner, int(spec.get("column", 0)), int(spec.get("row", 0)))
		if cell_rect.size.x <= 0.0 or cell_rect.size.y <= 0.0:
			continue
		var slot_extent: float = owner.pin_slot_extent_for_cell_rect(cell_rect)
		var expected_size: Vector2 = owner.pin_display_size_for_slot_extent(slot_extent)
		var expected_anchor := corner_anchor_for_rect(cell_rect, spec)
		var expected_position := position_for_anchor(expected_anchor, expected_size, spec, owner.pin_grid_overlap_for_slot_extent(slot_extent))
		if pin.size.distance_to(expected_size) > 0.5:
			return true
		if not pin.has_meta("pin_removing") and pin.position.distance_to(expected_position) > 1.0:
			return true
	return false

static func corner_anchor_for_rect(layout_rect: Rect2, spec: Dictionary) -> Vector2:
	var horizontal := str(spec.get("horizontal", "left"))
	var vertical := str(spec.get("vertical", "top"))
	return Vector2(
		layout_rect.position.x if horizontal == "left" else layout_rect.end.x,
		layout_rect.position.y if vertical == "top" else (layout_rect.end.y if vertical == "bottom" else layout_rect.position.y + (layout_rect.size.y * 0.5))
	)

static func position_for_anchor(anchor: Vector2, pin_size: Vector2, spec: Dictionary, grid_overlap: float) -> Vector2:
	var horizontal := str(spec.get("horizontal", "left"))
	var vertical := str(spec.get("vertical", "top"))
	var x := anchor.x + grid_overlap - pin_size.x if horizontal == "left" else anchor.x - grid_overlap
	var y := anchor.y + grid_overlap - pin_size.y if vertical == "top" else (anchor.y - grid_overlap if vertical == "bottom" else anchor.y - (pin_size.y * 0.5))
	return Vector2(x, y)

static func reset_pin_visual(pin: TextureRect) -> void:
	if pin == null:
		return
	pin.remove_meta("pin_removing")
	pin.modulate = Color(1, 1, 1, 1)
	pin.scale = Vector2.ONE
	pin.rotation_degrees = 0.0

static func reset_vfx_state(owner) -> void:
	owner.pin_state_initialized = false
	for key in owner.pin_removal_tweens.keys():
		var tween = owner.pin_removal_tweens[key]
		if tween != null and tween is Tween:
			tween.kill()
	owner.pin_removal_tweens.clear()
	for pin in owner.pin_nodes:
		reset_pin_visual(pin as TextureRect)

static func play_removed_vfx(owner, index: int) -> void:
	if index < 0 or index >= owner.pin_nodes.size():
		return
	var pin: TextureRect = owner.pin_nodes[index] as TextureRect
	if pin == null:
		return
	if owner.pin_removal_tweens.has(index):
		var previous_tween = owner.pin_removal_tweens[index]
		if previous_tween != null and previous_tween is Tween:
			previous_tween.kill()
	var pin_extent := maxf(pin.size.x, pin.size.y)
	var profile := removal_vfx_profile_for_index(index, pin_extent)
	var direction: Vector2 = profile.get("direction", Vector2.ZERO)
	var pull_distance := float(profile.get("pullDistance", 0.0))
	var anticipation_seconds := float(profile.get("anticipationDuration", 0.06))
	var pull_seconds := float(profile.get("pullDuration", 0.18))
	var rotation_degrees := float(profile.get("rotationDegrees", 16.0))
	var base_position: Vector2 = pin.position
	pin.set_meta("pin_removing", true)
	pin.visible = true
	pin.modulate = Color(1, 1, 1, 1)
	pin.scale = Vector2.ONE
	var tween: Tween = owner.create_tween().bind_node(pin)
	owner.pin_removal_tweens[index] = tween
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(pin, "scale", Vector2.ONE * float(profile.get("anticipationScale", 0.94)), anticipation_seconds)
	tween.parallel().tween_property(pin, "rotation_degrees", -rotation_degrees * 0.35, anticipation_seconds)
	tween.tween_property(pin, "position", base_position + direction * pull_distance, pull_seconds)
	tween.parallel().tween_property(pin, "rotation_degrees", rotation_degrees, pull_seconds)
	tween.parallel().tween_property(pin, "modulate:a", float(profile.get("fadeToAlpha", 0.0)), pull_seconds)
	tween.finished.connect(func():
		owner.pin_removal_tweens.erase(index)
		reset_pin_visual(pin)
		pin.visible = is_visible(index, owner.visible_pin_count_value, owner.pin_nodes.size())
		owner.call_deferred("_layout_pin_overlays")
	)
