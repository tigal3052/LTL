# Contract:
# - Responsibility: cache image-backed artifact display textures and apply oriented TextureRect placement.
# - Input: BackpackUI-like owner cache, Artifact data, footprint rects, and TextureRect nodes.
# - Output: cached display textures and center-pivoted item art transforms.
# - Forbidden: inventory mutation, reward flow changes, or keyboard input policy changes.
#
# Execution: keep live rotation paths on cached textures and cheap Control transforms.
class_name BackpackArtifactImagePlacement
extends RefCounted

const ArtifactClass = preload("res://src/models/Artifact.gd")
const GridFactory = preload("res://src/ui/presenters/BackpackGridFactory.gd")
const LTLThemeScript = preload("res://src/ui/theme/LTLTheme.gd")
const DRILL_VISIBLE_ALPHA_THRESHOLD := 0.02
const DRILL_VISIBLE_PADDING_RATIO := 0.03

static func display_texture_for_artifact(owner, art: ArtifactClass) -> Texture2D:
	if owner == null or art == null:
		return null
	var item_type := str(art.item_type).to_lower().strip_edges()
	var texture_paths: Array = GridFactory.item_texture_candidates(item_type, str(art.visual_id), str(art.energy_type), str(art.grade))
	for texture_path in texture_paths:
		var cache_key := "%s|%s|display" % [item_type, texture_path]
		if owner.drill_texture_cache.has(cache_key):
			return owner.drill_texture_cache[cache_key]
		var texture := drill_display_texture(LTLThemeScript.art_texture(texture_path))
		if texture != null:
			owner.drill_texture_cache[cache_key] = texture
			return texture
	return null

static func apply_item_image_placement(image: TextureRect, texture: Texture2D, footprint_rect: Rect2, use_global_position: bool = false) -> void:
	apply_oriented_item_image_placement(image, texture, footprint_rect, 0, use_global_position)

static func apply_oriented_item_image_placement(image: TextureRect, texture: Texture2D, footprint_rect: Rect2, rotation_degrees: int, use_global_position: bool = false) -> void:
	if image == null:
		return
	var rotation := _normalized_rotation(rotation_degrees)
	var display_size := Vector2(footprint_rect.size.y, footprint_rect.size.x) if rotation in [90, 270] else footprint_rect.size
	image.texture = texture
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	image.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	image.size = display_size
	image.pivot_offset = display_size * 0.5
	image.rotation_degrees = float(rotation)
	var origin := footprint_rect.get_center() - image.pivot_offset
	if use_global_position:
		image.global_position = origin
	else:
		image.position = origin

static func reset_item_image_transform(image: TextureRect) -> void:
	if image == null:
		return
	image.texture = null
	image.size = Vector2.ZERO
	image.pivot_offset = Vector2.ZERO
	image.rotation_degrees = 0.0

static func drill_display_texture(texture: Texture2D, shape: Array = []) -> Texture2D:
	if texture == null:
		return null
	var image := texture.get_image()
	if image == null or image.is_empty():
		return texture
	var region := _visible_alpha_region(image, DRILL_VISIBLE_ALPHA_THRESHOLD)
	if region.size.x <= 0 or region.size.y <= 0:
		return texture
	var display_region := _centered_display_region(image, region, _shape_aspect(shape, float(texture.get_width()) / float(texture.get_height())))
	if display_region.size.x >= float(texture.get_width()) * 0.98 and display_region.size.y >= float(texture.get_height()) * 0.98:
		return texture
	var atlas := AtlasTexture.new()
	atlas.atlas = texture
	atlas.region = display_region
	return atlas

static func _centered_display_region(image: Image, visible_region: Rect2i, target_aspect: float) -> Rect2:
	var padding := maxi(2, int(round(maxf(float(visible_region.size.x), float(visible_region.size.y)) * DRILL_VISIBLE_PADDING_RATIO)))
	var left := float(maxi(0, visible_region.position.x - padding))
	var top := float(maxi(0, visible_region.position.y - padding))
	var right := float(mini(image.get_width(), visible_region.position.x + visible_region.size.x + padding))
	var bottom := float(mini(image.get_height(), visible_region.position.y + visible_region.size.y + padding))
	var center := Vector2(float(image.get_width()), float(image.get_height())) * 0.5
	var aspect := maxf(0.01, target_aspect)
	var half_width := maxf(center.x - left, right - center.x)
	var half_height := maxf(center.y - top, bottom - center.y)
	if half_width / maxf(1.0, half_height) < aspect:
		half_width = half_height * aspect
	else:
		half_height = half_width / aspect
	var max_half_width := minf(center.x, float(image.get_width()) - center.x)
	var max_half_height := minf(center.y, float(image.get_height()) - center.y)
	if half_width > max_half_width:
		half_width = max_half_width
		half_height = minf(max_half_height, half_width / aspect)
	if half_height > max_half_height:
		half_height = max_half_height
		half_width = minf(max_half_width, half_height * aspect)
	return Rect2(center - Vector2(half_width, half_height), Vector2(half_width * 2.0, half_height * 2.0))

static func _shape_aspect(shape: Array, fallback: float) -> float:
	var rows := maxi(1, shape.size())
	var columns := 0
	for row in shape:
		if row is Array:
			var row_cells: Array = row
			columns = maxi(columns, row_cells.size())
	if columns <= 0:
		return fallback
	return float(columns) / float(rows)

static func _visible_alpha_region(image: Image, alpha_threshold: float) -> Rect2i:
	var min_x := image.get_width()
	var min_y := image.get_height()
	var max_x := -1
	var max_y := -1
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			if image.get_pixel(x, y).a <= alpha_threshold:
				continue
			min_x = mini(min_x, x)
			min_y = mini(min_y, y)
			max_x = maxi(max_x, x)
			max_y = maxi(max_y, y)
	if max_x < min_x or max_y < min_y:
		return Rect2i()
	return Rect2i(min_x, min_y, max_x - min_x + 1, max_y - min_y + 1)

static func _normalized_rotation(rotation_degrees: int) -> int:
	var rotation := rotation_degrees % 360
	if rotation < 0:
		rotation += 360
	return int(round(float(rotation) / 90.0)) * 90 % 360
