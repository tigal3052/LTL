# 怨꾩빟:
# - Responsibility: build node-select hotspot visuals, tags, palettes, style boxes, and generated textures.
# - Input: route palette dictionaries, target controls, canvas size, and caller-owned texture caches.
# - Output: styled controls, generated Texture2D instances, and reusable StyleBoxFlat values.
# - Prohibited: changing route selection state, rebuilding roadmap topology, or emitting page signals.
#
# ?ㅽ뻾: define reusable node-select visual construction helpers.
class_name NodeSelectVisualFactory
extends RefCounted

const GlyphIconScript = preload("res://src/scenes/pages/node_select/GlyphIcon.gd")
const FutureMarkerArtScript = preload("res://src/scenes/pages/node_select/FutureMarkerArt.gd")

const ROUTE_GOLD := Color(0.90, 0.74, 0.43, 0.96)
const TEXT_SOFT := Color(0.80, 0.74, 0.66, 0.72)
const ICON_PATHS := {
	"normal": "res://resources/node_select/atlas/icon_battle_gate.png",
	"danger": "res://resources/node_select/atlas/icon_battle_gate.png",
	"harpoon": "res://resources/node_select/atlas/icon_battle_gate.png",
	"repair": "res://resources/node_select/atlas/icon_camp_seed.png",
	"reef": "res://resources/node_select/atlas/icon_reward_geode.png",
	"unknown": "res://resources/node_select/atlas/icon_event_leaf.png",
	"start": "res://resources/node_select/atlas/icon_event_leaf.png",
	"future": "res://resources/node_select/atlas/icon_locked_roots.png",
	"boss": "res://resources/node_select/atlas/icon_boss_crest.png"
}

# ?ㅽ뻾: create the transparent route button style used by roadmap markers.
static func route_button_style(_candidate: Dictionary = {}, _selected := false, _hovered := false) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.0, 0.0, 0.0, 0.0)
	style.border_color = Color(0.0, 0.0, 0.0, 0.0)
	style.corner_radius_top_left = 24
	style.corner_radius_top_right = 24
	style.corner_radius_bottom_left = 24
	style.corner_radius_bottom_right = 24
	return style

# ?ㅽ뻾: return the shared fully transparent button style.
static func transparent_button_style() -> StyleBoxFlat:
	return route_button_style({}, false, false)

# ?ㅽ뻾: attach the core visual and icon for a node-select hotspot.
static func attach_hotspot_visual(host: Control, palette: Dictionary, icon_kind: String, selected: bool, preview: bool, hovered: bool, core_texture_cache: Dictionary) -> void:
	var existing_core := host.get_node_or_null("CoreVisual")
	if existing_core != null:
		existing_core.queue_free()
	var existing_icon := host.get_node_or_null("Icon")
	if existing_icon != null:
		existing_icon.queue_free()

	var frame := PanelContainer.new()
	frame.name = "CoreVisual"
	frame.size = host.size
	frame.position = Vector2.ZERO
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var frame_bg := Color(0.92, 0.86, 0.62, 0.88) if selected else Color(0.72, 0.70, 0.60, 0.62)
	var frame_border := Color(0.25, 0.70, 0.38, 0.92) if selected or hovered else Color(0.25, 0.36, 0.24, 0.34)
	if preview:
		frame_bg = Color(0.42, 0.38, 0.30, 0.56)
		frame_border = Color(0.18, 0.20, 0.16, 0.46)
	frame.add_theme_stylebox_override("panel", panel_style(frame_bg, frame_border, 14, 2 if selected else 1, Color(0.0, 0.0, 0.0, 0.20), 8 if selected or hovered else 3))
	host.add_child(frame)

	var icon := TextureRect.new()
	icon.name = "Icon"
	icon.set_meta("atlas_icon_kind", icon_kind)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.texture = _load_runtime_texture(str(ICON_PATHS.get(icon_kind, ICON_PATHS.get("normal"))))
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	var inset := host.size * (0.10 if selected else 0.13)
	icon.position = inset
	icon.size = host.size - (inset * 2.0)
	icon.self_modulate = Color(1.0, 1.0, 1.0, 1.0 if selected or hovered else 0.82)
	host.add_child(icon)
	return

# ?ㅽ뻾: refresh a hotspot while preserving the caller's visual state metadata contract.
static func refresh_hotspot_visual(host: Control, hovered: bool, core_texture_cache: Dictionary) -> void:
	var palette_value: Variant = host.get_meta("palette", {})
	var active_palette_value: Variant = host.get_meta("active_palette", palette_value)
	if not (palette_value is Dictionary) or not (active_palette_value is Dictionary):
		return
	var palette: Dictionary = active_palette_value
	var icon_kind := str(host.get_meta("icon_kind", "normal"))
	var selected := bool(host.get_meta("selected_visual", false))
	var preview := icon_kind == "future"
	var display_palette := palette if selected or preview else muted_palette(palette)
	host.set_meta("palette", display_palette.duplicate(true))
	attach_hotspot_visual(host, display_palette, icon_kind, selected, preview, hovered, core_texture_cache)

# ?ㅽ뻾: attach the glyph icon control for a concrete route hotspot.
static func _load_runtime_texture(path: String) -> Texture2D:
	var file_path := ProjectSettings.globalize_path(path)
	if FileAccess.file_exists(file_path):
		var image := Image.load_from_file(file_path)
		if image != null and not image.is_empty():
			return ImageTexture.create_from_image(image)
	var loaded := load(path)
	return loaded if loaded is Texture2D else null

# ?ㅽ뻾: attach the glyph icon control for a concrete route hotspot.
static func attach_hotspot_icon(host: Control, icon_kind: String, color: Color) -> void:
	var icon := GlyphIconScript.new()
	icon.name = "Icon"
	icon.icon_kind = icon_kind
	icon.stroke_color = color
	icon.stroke_width = 1.9 if host.size.x < 76.0 else 2.15
	icon.size = host.size * 0.42
	icon.position = (host.size - icon.size) * 0.5
	icon.position.y -= 2.0 if host.size.x >= 72.0 else 1.0
	host.add_child(icon)

# ?ㅽ뻾: attach the readable label tag for a node-select hotspot.
static func attach_hotspot_tag(host: Control, tag_text: String, sub_text := "", preview := false, canvas_size := Vector2.ZERO) -> void:
	if tag_text.strip_edges().is_empty():
		return
	var tag_width := clampf(82.0 + (float(tag_text.length()) * 7.2), 104.0, 140.0 if preview else 146.0)
	var local_x := (host.size.x - tag_width) * 0.5
	var min_x := -host.position.x + 12.0
	var max_x := canvas_size.x - host.position.x - tag_width - 12.0
	local_x = clampf(local_x, min_x, max_x)
	var place_above := host.position.y + host.size.y + 56.0 > canvas_size.y - 12.0
	var tag_y := -38.0 if place_above else host.size.y + 8.0
	var sub_y := -18.0 if place_above else host.size.y + 42.0
	var tag_panel := PanelContainer.new()
	tag_panel.name = "Tag"
	tag_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tag_panel.position = Vector2(local_x, tag_y)
	tag_panel.size = Vector2(tag_width, 30.0)
	tag_panel.add_theme_stylebox_override(
		"panel",
		panel_style(
			Color(0.11, 0.07, 0.05, 0.94),
			Color(0.82, 0.68, 0.44, 0.18 if not preview else 0.26),
			14 if not preview else 16,
			1,
			Color(0.0, 0.0, 0.0, 0.18),
			8
		)
	)
	host.add_child(tag_panel)

	var tag_margin := MarginContainer.new()
	tag_margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	tag_margin.add_theme_constant_override("margin_left", 8)
	tag_margin.add_theme_constant_override("margin_top", 4)
	tag_margin.add_theme_constant_override("margin_right", 8)
	tag_margin.add_theme_constant_override("margin_bottom", 5)
	tag_panel.add_child(tag_margin)

	var tag_label := Label.new()
	tag_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tag_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	tag_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tag_label.text = tag_text
	tag_label.add_theme_font_size_override("font_size", 11)
	tag_label.add_theme_color_override("font_color", Color(0.95, 0.88, 0.74, 1.0))
	tag_margin.add_child(tag_label)

	if sub_text.strip_edges().is_empty():
		return
	var sub_label := Label.new()
	sub_label.name = "SubLabel"
	sub_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sub_label.position = Vector2(local_x, sub_y)
	sub_label.size = Vector2(tag_width, 14.0)
	sub_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	sub_label.text = sub_text
	sub_label.add_theme_font_size_override("font_size", 10)
	sub_label.add_theme_color_override("font_color", Color(TEXT_SOFT.r, TEXT_SOFT.g, TEXT_SOFT.b, 0.92))
	host.add_child(sub_label)

# ?ㅽ뻾: build a reusable flat panel style for route surfaces.
static func panel_style(bg: Color, border: Color, radius: int, border_width: int, shadow := Color(0, 0, 0, 0), shadow_size := 0) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.border_width_left = border_width
	style.border_width_top = border_width
	style.border_width_right = border_width
	style.border_width_bottom = border_width
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	style.shadow_color = shadow
	style.shadow_size = shadow_size
	return style

# ?ㅽ뻾: return the palette dictionary for a roadmap tone id.
static func tone_palette(tone: String) -> Dictionary:
	match tone:
		"start":
			return {"key": "start", "fill": Color(0.34, 0.25, 0.16, 0.92), "top": Color(0.62, 0.51, 0.32, 1.0), "bottom": Color(0.31, 0.23, 0.14, 1.0), "border": Color(0.90, 0.76, 0.47, 0.82), "glyph": Color(0.97, 0.91, 0.82, 1.0)}
		"stage":
			return {"key": "stage", "fill": Color(0.55, 0.40, 0.24, 0.96), "top": Color(0.87, 0.73, 0.43, 1.0), "bottom": Color(0.56, 0.40, 0.19, 1.0), "border": Color(0.95, 0.84, 0.61, 0.56), "glyph": Color(0.17, 0.12, 0.07, 1.0)}
		"red":
			return {"key": "red", "fill": Color(0.52, 0.28, 0.22, 0.96), "top": Color(0.79, 0.49, 0.40, 1.0), "bottom": Color(0.46, 0.22, 0.18, 1.0), "border": Color(0.96, 0.83, 0.73, 0.44), "glyph": Color(0.96, 0.91, 0.82, 1.0)}
		"boss":
			return {"key": "boss", "fill": Color(0.55, 0.29, 0.23, 0.98), "top": Color(0.82, 0.54, 0.45, 1.0), "bottom": Color(0.52, 0.25, 0.21, 1.0), "border": Color(0.97, 0.86, 0.75, 0.60), "glyph": Color(0.97, 0.91, 0.82, 1.0)}
		"future":
			return {"key": "future", "fill": Color(0.16, 0.11, 0.08, 0.86), "top": Color(0.16, 0.11, 0.08, 0.86), "bottom": Color(0.11, 0.08, 0.05, 0.86), "border": Color(0.88, 0.73, 0.45, 0.66), "glyph": Color(0.96, 0.90, 0.82, 1.0)}
		_:
			return {"key": "brown", "fill": Color(0.28, 0.19, 0.13, 0.96), "top": Color(0.48, 0.37, 0.25, 1.0), "bottom": Color(0.23, 0.17, 0.11, 1.0), "border": Color(0.86, 0.74, 0.57, 0.36), "glyph": Color(0.96, 0.91, 0.82, 1.0)}

# ?ㅽ뻾: return the muted palette used for historic and inactive route markers.
static func muted_palette(source: Dictionary) -> Dictionary:
	return {
		"key": "%s_muted" % str(source.get("key", "muted")),
		"fill": Color(0.32, 0.29, 0.27, 0.92),
		"top": Color(0.56, 0.52, 0.49, 0.90),
		"bottom": Color(0.30, 0.27, 0.25, 0.94),
		"border": Color(0.74, 0.70, 0.66, 0.26),
		"glyph": Color(0.92, 0.89, 0.85, 0.94)
	}

# ?ㅽ뻾: generate or reuse the radial ambient spot texture.
static func radial_spot_texture(size: Vector2i, tint: Color, spot_texture_cache: Dictionary) -> Texture2D:
	var key := "radial_%d_%d_%0.3f_%0.3f_%0.3f_%0.3f" % [size.x, size.y, tint.r, tint.g, tint.b, tint.a]
	if spot_texture_cache.has(key):
		return spot_texture_cache[key]
	var image := Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
	for y in range(size.y):
		var py := (float(y) / float(maxi(1, size.y - 1))) - 0.5
		for x in range(size.x):
			var px := (float(x) / float(maxi(1, size.x - 1))) - 0.5
			var dist := sqrt(((px / 0.9) * (px / 0.9)) + ((py / 0.7) * (py / 0.7)))
			var alpha := pow(maxf(0.0, 1.0 - dist), 2.2) * tint.a
			image.set_pixel(x, y, Color(tint.r, tint.g, tint.b, alpha))
	var texture := ImageTexture.create_from_image(image)
	spot_texture_cache[key] = texture
	return texture

# ?ㅽ뻾: generate or reuse the vertical gloss texture.
static func linear_gloss_texture(size: Vector2i, top_color: Color, bottom_color: Color, spot_texture_cache: Dictionary) -> Texture2D:
	var key := "gloss_%d_%d_%0.3f_%0.3f_%0.3f_%0.3f_%0.3f_%0.3f_%0.3f_%0.3f" % [size.x, size.y, top_color.r, top_color.g, top_color.b, top_color.a, bottom_color.r, bottom_color.g, bottom_color.b, bottom_color.a]
	if spot_texture_cache.has(key):
		return spot_texture_cache[key]
	var image := Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
	for y in range(size.y):
		var t := float(y) / float(maxi(1, size.y - 1))
		var color := top_color.lerp(bottom_color, t)
		for x in range(size.x):
			image.set_pixel(x, y, color)
	var texture := ImageTexture.create_from_image(image)
	spot_texture_cache[key] = texture
	return texture

# ?ㅽ뻾: generate or reuse the node core texture for a palette and state.
static func node_core_texture(size: Vector2i, palette: Dictionary, selected: bool, hovered: bool, core_texture_cache: Dictionary) -> Texture2D:
	var key := "%s_%d_%d_%s_%s" % [str(palette.get("key", "brown")), size.x, size.y, str(selected), str(hovered)]
	if core_texture_cache.has(key):
		return core_texture_cache[key]
	var image := Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
	var top: Color = palette.get("top", Color(0.48, 0.37, 0.25, 1.0))
	var bottom: Color = palette.get("bottom", Color(0.23, 0.17, 0.11, 1.0))
	var border: Color = palette.get("border", ROUTE_GOLD)
	if hovered and not selected:
		top = top.lightened(0.06)
		bottom = bottom.lightened(0.04)
	var core_rect := Rect2(6.0 if selected else 4.0, 4.0 if selected else 2.0, float(size.x) - (12.0 if selected else 8.0), float(size.y) - (14.0 if selected else 10.0))
	var radius := minf(core_rect.size.x, core_rect.size.y) * 0.30
	var halo_rect := core_rect.grow(9.0)
	for y in range(size.y):
		for x in range(size.x):
			var point := Vector2(float(x) + 0.5, float(y) + 0.5)
			var color := Color(0.0, 0.0, 0.0, 0.0)
			var shadow := ellipse_alpha(point, Vector2(float(size.x) * 0.5, core_rect.position.y + (core_rect.size.y * 0.92)), Vector2(core_rect.size.x * 0.38, core_rect.size.y * 0.12))
			if shadow > 0.0:
				color = alpha_blend(color, Color(0.0, 0.0, 0.0, 0.24 * shadow))
			if selected:
				var halo_outer := coverage_from_distance(rounded_rect_distance(point, halo_rect, radius + 6.0), 1.4)
				var halo_inner := coverage_from_distance(rounded_rect_distance(point, core_rect.grow(1.0), radius + 1.0), 1.0)
				var halo_ring := maxf(0.0, halo_outer - halo_inner)
				if halo_ring > 0.0:
					color = alpha_blend(color, Color(ROUTE_GOLD.r, ROUTE_GOLD.g, ROUTE_GOLD.b, 0.16 * halo_ring))
			var dist := rounded_rect_distance(point, core_rect, radius)
			var coverage := coverage_from_distance(dist, 1.3)
			if coverage > 0.0:
				var t := clampf((point.y - core_rect.position.y) / maxf(core_rect.size.y, 1.0), 0.0, 1.0)
				var base := top.lerp(bottom, pow(t, 0.92))
				if t < 0.44:
					base = alpha_blend(base, Color(1.0, 0.98, 0.92, 0.16 * (1.0 - (t / 0.44))))
				if t > 0.58:
					base = alpha_blend(base, Color(0.0, 0.0, 0.0, 0.18 * ((t - 0.58) / 0.42)))
				var border_mix := clampf(1.0 - ((-dist) / 2.0), 0.0, 1.0)
				if border_mix > 0.0:
					base = base.lerp(border, border_mix * 0.78)
				color = alpha_blend(color, Color(base.r, base.g, base.b, coverage))
			image.set_pixel(x, y, color)
	var texture := ImageTexture.create_from_image(image)
	core_texture_cache[key] = texture
	return texture

static func rounded_rect_distance(point: Vector2, rect: Rect2, radius: float) -> float:
	var clamped_radius := minf(radius, minf(rect.size.x, rect.size.y) * 0.5)
	var center := rect.position + (rect.size * 0.5)
	var half := (rect.size * 0.5) - Vector2.ONE * clamped_radius
	var q := Vector2(absf(point.x - center.x), absf(point.y - center.y)) - half
	var outside := Vector2(maxf(q.x, 0.0), maxf(q.y, 0.0))
	return minf(maxf(q.x, q.y), 0.0) + outside.length() - clamped_radius

static func coverage_from_distance(distance: float, feather: float) -> float:
	if distance <= 0.0:
		return 1.0
	return clampf(1.0 - (distance / feather), 0.0, 1.0)

static func ellipse_alpha(point: Vector2, center: Vector2, radii: Vector2) -> float:
	if radii.x <= 0.01 or radii.y <= 0.01:
		return 0.0
	var dx := (point.x - center.x) / radii.x
	var dy := (point.y - center.y) / radii.y
	var distance := (dx * dx) + (dy * dy)
	if distance >= 1.0:
		return 0.0
	return pow(1.0 - distance, 1.8)

static func alpha_blend(dst: Color, src: Color) -> Color:
	var out_alpha := src.a + (dst.a * (1.0 - src.a))
	if out_alpha <= 0.0001:
		return Color(0.0, 0.0, 0.0, 0.0)
	var out_red := ((src.r * src.a) + (dst.r * dst.a * (1.0 - src.a))) / out_alpha
	var out_green := ((src.g * src.a) + (dst.g * dst.a * (1.0 - src.a))) / out_alpha
	var out_blue := ((src.b * src.a) + (dst.b * dst.a * (1.0 - src.a))) / out_alpha
	return Color(out_red, out_green, out_blue, out_alpha)
