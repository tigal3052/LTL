class_name LTLTheme
extends RefCounted

const SURFACE_DARK := Color(0.05, 0.07, 0.10, 0.95)
const SURFACE_MID := Color(0.10, 0.13, 0.17, 0.96)
const SURFACE_LIGHT := Color(0.16, 0.20, 0.24, 0.98)
const BORDER_COLD := Color(0.28, 0.36, 0.44, 1.0)
const BORDER_WARM := Color(0.58, 0.46, 0.24, 1.0)
const TEXT_PRIMARY := Color(0.93, 0.95, 0.97, 1.0)
const TEXT_MUTED := Color(0.67, 0.74, 0.80, 1.0)
const TEXT_DANGER := Color(0.96, 0.48, 0.44, 1.0)
const TEXT_SUCCESS := Color(0.64, 0.86, 0.61, 1.0)
const TEXT_WARNING := Color(0.95, 0.75, 0.25, 1.0)
const TEXT_PURPLE := Color(0.72, 0.42, 0.95, 1.0)

static var _shared_theme: Theme = null

static func surface_style(bg_color: Color, border_color: Color = BORDER_COLD, radius: int = 12, border_width: int = 1, shadow_alpha: float = 0.20) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_color = border_color
	style.border_width_left = border_width
	style.border_width_top = border_width
	style.border_width_right = border_width
	style.border_width_bottom = border_width
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	style.shadow_size = 8
	style.shadow_color = Color(0.0, 0.0, 0.0, shadow_alpha)
	return style

static func shared_theme() -> Theme:
	if _shared_theme != null:
		return _shared_theme
	var theme := Theme.new()
	var system_font := SystemFont.new()
	system_font.font_names = PackedStringArray([
		"Malgun Gothic",
		"맑은 고딕",
		"Noto Sans CJK KR",
		"Noto Sans KR",
		"Apple SD Gothic Neo",
		"NanumGothic",
		"Segoe UI",
		"Arial Unicode MS"
	])
	theme.default_font = system_font
	theme.default_font_size = 16
	_shared_theme = theme
	return _shared_theme

static func overlay_style(accent: String = "warning") -> StyleBoxFlat:
	var bg := Color(0.05, 0.06, 0.08, 0.92)
	var border := BORDER_WARM
	if accent == "danger":
		bg = Color(0.09, 0.04, 0.04, 0.94)
		border = Color(0.72, 0.22, 0.20, 1.0)
	elif accent == "success":
		bg = Color(0.05, 0.08, 0.06, 0.94)
		border = Color(0.36, 0.62, 0.30, 1.0)
	return surface_style(bg, border, 18, 2, 0.30)

static func value_bar_fill(fill_color: Color) -> StyleBoxFlat:
	var fill := StyleBoxFlat.new()
	fill.bg_color = fill_color
	fill.corner_radius_top_left = 8
	fill.corner_radius_top_right = 8
	fill.corner_radius_bottom_left = 8
	fill.corner_radius_bottom_right = 8
	return fill

static func value_bar_background(bg_color: Color) -> StyleBoxFlat:
	var bg := StyleBoxFlat.new()
	bg.bg_color = bg_color
	bg.corner_radius_top_left = 8
	bg.corner_radius_top_right = 8
	bg.corner_radius_bottom_left = 8
	bg.corner_radius_bottom_right = 8
	bg.content_margin_left = 2
	bg.content_margin_top = 2
	bg.content_margin_right = 2
	bg.content_margin_bottom = 2
	return bg

static func accent_color(color_name: String) -> Color:
	match color_name:
		"red":
			return Color(0.90, 0.25, 0.25, 1.0)
		"blue":
			return Color(0.25, 0.50, 0.90, 1.0)
		"green":
			return Color(0.25, 0.75, 0.35, 1.0)
		"purple":
			return Color(0.65, 0.25, 0.85, 1.0)
	return TEXT_MUTED

static func art_texture(path: String) -> Texture2D:
	if path.is_empty():
		return null
	var lower_path := path.to_lower()
	if lower_path.ends_with(".png") or lower_path.ends_with(".jpg") or lower_path.ends_with(".jpeg") or lower_path.ends_with(".webp"):
		var file_path := ProjectSettings.globalize_path(path)
		if FileAccess.file_exists(file_path):
			var image := Image.load_from_file(file_path)
			if image != null and not image.is_empty():
				return ImageTexture.create_from_image(image)
	var loaded := load(path)
	return loaded if loaded is Texture2D else null

static func atlas_frame(texture: Texture2D, region: Rect2) -> Texture2D:
	if texture == null:
		return null
	var atlas := AtlasTexture.new()
	atlas.atlas = texture
	atlas.region = region
	return atlas
