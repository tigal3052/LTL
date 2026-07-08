class_name BackpackFusionVFX
extends RefCounted

const RING_COLORS := [
	Color(1.0, 0.82, 0.28, 0.95),
	Color(0.48, 1.0, 0.58, 0.80),
	Color(1.0, 1.0, 1.0, 0.70)
]
const SILHOUETTE_FILL_ALPHA := 0.54
const RESULT_FILL_ALPHA := 0.72

static func sound_category() -> String:
	return "item_fusion"

static func sound_categories() -> Array:
	return ["fusion_buildup", "fusion_complete"]

static func silhouette_merge_profile() -> Dictionary:
	return {
		"readability": "two_items_become_one",
		"soundCategory": sound_category(),
		"soundCategories": sound_categories(),
		"stages": ["existing_silhouette", "incoming_silhouette", "converge", "birth_burst", "result_reveal"]
	}

static func play(owner, art) -> void:
	if owner == null or art == null:
		return
	if owner.artifact_image_layer == null or not owner.has_method("_artifact_footprint_rect_in_layer"):
		return
	var rect: Rect2 = owner._artifact_footprint_rect_in_layer(art)
	if rect.size.x <= 1.0 or rect.size.y <= 1.0:
		return
	var root := Control.new()
	root.name = "BackpackFusionVFX"
	root.clip_contents = false
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.position = rect.position
	root.size = rect.size
	root.pivot_offset = rect.size * 0.5
	root.z_index = 90
	owner.artifact_image_layer.add_child(root)
	var energy_color := _energy_color(str(art.energy_type))
	var existing := _add_item_silhouette(root, art, "FusionExistingSilhouette", -1, energy_color)
	var incoming := _add_item_silhouette(root, art, "FusionIncomingSilhouette", 1, energy_color)
	var result := _add_item_silhouette(root, art, "FusionResultReveal", 0, Color(1.0, 0.91, 0.44, 1.0), RESULT_FILL_ALPHA)
	_add_convergence_beam(root, -1, energy_color)
	_add_convergence_beam(root, 1, energy_color)
	_add_merge_sparks(root, rect.size)
	for index in range(RING_COLORS.size()):
		_add_ring(root, RING_COLORS[index], index)
	_animate(root, existing, incoming, result)

static func _add_item_silhouette(root: Control, art, node_name: String, side: int, color: Color, fill_alpha: float = SILHOUETTE_FILL_ALPHA) -> Control:
	var shape := _normalized_shape(art)
	var columns := _shape_columns(shape)
	var rows := maxi(1, shape.size())
	var cell_extent := minf(root.size.x / float(maxi(1, columns)), root.size.y / float(rows))
	cell_extent = clampf(cell_extent, 10.0, 42.0)
	var item_size := Vector2(float(columns) * cell_extent, float(rows) * cell_extent)
	var holder := Control.new()
	holder.name = node_name
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.size = item_size
	holder.pivot_offset = item_size * 0.5
	holder.position = _centered_position(root.size, item_size) + Vector2(float(side) * root.size.x * 0.58, 0.0)
	holder.scale = Vector2.ONE * (0.92 if side != 0 else 0.42)
	holder.rotation = float(side) * 0.08
	holder.modulate = Color(1.0, 1.0, 1.0, 0.0 if side == 0 else 0.92)
	root.add_child(holder)
	for row in range(shape.size()):
		if not shape[row] is Array:
			continue
		var shape_row: Array = shape[row]
		for column in range(shape_row.size()):
			if int(shape_row[column]) != 1:
				continue
			var cell := Panel.new()
			cell.mouse_filter = Control.MOUSE_FILTER_IGNORE
			cell.position = Vector2(float(column) * cell_extent, float(row) * cell_extent)
			cell.size = Vector2.ONE * maxf(4.0, cell_extent - 2.0)
			cell.add_theme_stylebox_override("panel", _silhouette_style(color, fill_alpha, side == 0))
			holder.add_child(cell)
	return holder

static func _add_convergence_beam(root: Control, side: int, color: Color) -> void:
	var beam := ColorRect.new()
	beam.name = "FusionConvergenceBeam"
	beam.mouse_filter = Control.MOUSE_FILTER_IGNORE
	beam.color = Color(color.r, color.g, color.b, 0.62)
	beam.size = Vector2(maxf(18.0, root.size.x * 0.28), maxf(4.0, root.size.y * 0.08))
	beam.position = Vector2(root.size.x * 0.5 + float(side) * root.size.x * 0.34 - beam.size.x * 0.5, root.size.y * 0.5 - beam.size.y * 0.5)
	beam.pivot_offset = beam.size * 0.5
	beam.rotation = 0.16 * float(side)
	root.add_child(beam)

static func _add_ring(root: Control, color: Color, index: int) -> void:
	var panel := Panel.new()
	panel.name = "FusionImpactRing"
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.modulate = Color(color.r, color.g, color.b, 0.0)
	panel.add_theme_stylebox_override("panel", _ring_style(color, 2 + index))
	panel.scale = Vector2.ONE * (0.70 + float(index) * 0.08)
	panel.pivot_offset = root.size * 0.5
	root.add_child(panel)

static func _add_merge_sparks(root: Control, size: Vector2) -> void:
	for side in [-1, 1]:
		var spark := ColorRect.new()
		spark.name = "FusionMergeSpark"
		spark.mouse_filter = Control.MOUSE_FILTER_IGNORE
		spark.color = Color(1.0, 0.88, 0.44, 0.92)
		spark.size = Vector2(maxf(10.0, size.x * 0.22), maxf(4.0, size.y * 0.07))
		spark.position = Vector2((size.x * 0.5) + float(side) * size.x * 0.42 - spark.size.x * 0.5, size.y * 0.5 - spark.size.y * 0.5)
		spark.pivot_offset = spark.size * 0.5
		spark.rotation = 0.18 * float(side)
		root.add_child(spark)

static func _animate(root: Control, existing: Control, incoming: Control, result: Control) -> void:
	var tween := root.create_tween()
	var center_existing := _centered_position(root.size, existing.size) + Vector2(-root.size.x * 0.04, 0.0)
	var center_incoming := _centered_position(root.size, incoming.size) + Vector2(root.size.x * 0.04, 0.0)
	var center_result := _centered_position(root.size, result.size)
	root.modulate = Color(1.0, 1.0, 1.0, 0.0)
	tween.tween_property(root, "modulate:a", 1.0, 0.05)
	tween.parallel().tween_property(existing, "position", center_existing, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(incoming, "position", center_incoming, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(existing, "scale", Vector2.ONE * 1.06, 0.18).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(incoming, "scale", Vector2.ONE * 1.06, 0.18).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(existing, "rotation", 0.0, 0.18)
	tween.parallel().tween_property(incoming, "rotation", 0.0, 0.18)
	for child in root.get_children():
		var child_control := child as Control
		if child_control == null:
			continue
		if child_control.name == "FusionConvergenceBeam" or child_control.name == "FusionMergeSpark":
			tween.parallel().tween_property(child_control, "position:x", root.size.x * 0.5 - child_control.size.x * 0.5, 0.18).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_interval(0.03)
	tween.tween_property(result, "position", center_result, 0.01)
	tween.parallel().tween_property(result, "modulate:a", 1.0, 0.08).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(result, "scale", Vector2.ONE * 1.18, 0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(existing, "modulate:a", 0.0, 0.10)
	tween.parallel().tween_property(incoming, "modulate:a", 0.0, 0.10)
	for effect_child in root.get_children():
		var effect_control := effect_child as Control
		if effect_control == null:
			continue
		if effect_control.name == "FusionImpactRing":
			tween.parallel().tween_property(effect_control, "modulate:a", 1.0, 0.06)
			tween.parallel().tween_property(effect_control, "scale", effect_control.scale * 1.42, 0.20).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		elif effect_control.name == "FusionConvergenceBeam" or effect_control.name == "FusionMergeSpark":
			tween.parallel().tween_property(effect_control, "modulate:a", 0.0, 0.12)
	tween.tween_interval(0.12)
	tween.tween_property(root, "scale", Vector2.ONE * 1.12, 0.18).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(root, "modulate:a", 0.0, 0.18).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.tween_callback(root.queue_free)

static func _normalized_shape(art) -> Array:
	if art != null and art.shape is Array and not art.shape.is_empty():
		return art.shape
	return [[1]]

static func _shape_columns(shape: Array) -> int:
	var columns := 1
	for row in shape:
		if row is Array:
			var shape_row: Array = row
			columns = maxi(columns, shape_row.size())
	return columns

static func _centered_position(container_size: Vector2, child_size: Vector2) -> Vector2:
	return (container_size - child_size) * 0.5

static func _energy_color(energy_type: String) -> Color:
	match energy_type.to_lower():
		"red":
			return Color(1.0, 0.34, 0.28, 1.0)
		"blue":
			return Color(0.32, 0.60, 1.0, 1.0)
		"purple":
			return Color(0.74, 0.36, 1.0, 1.0)
		"green":
			return Color(0.42, 1.0, 0.52, 1.0)
	return Color(1.0, 0.86, 0.36, 1.0)

static func _silhouette_style(color: Color, fill_alpha: float, result: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(color.r, color.g, color.b, fill_alpha)
	style.border_color = Color(1.0, 0.96, 0.72, 0.96) if result else Color(color.r, color.g, color.b, 0.92)
	style.set_border_width_all(2 if result else 1)
	style.set_corner_radius_all(4)
	return style

static func _ring_style(color: Color, width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(color.r, color.g, color.b, 0.05)
	style.border_color = color
	style.set_border_width_all(width)
	style.set_corner_radius_all(6)
	return style
