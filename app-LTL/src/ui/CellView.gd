# 계약:
# - 책임: battlefield cell 하나를 실제 색상 타일로 렌더링하고 마우스 입력 signal을 중계한다.
# - 입력: id/row/column/weakness/aimed 상태와 disabled tile id 목록.
# - 출력: texture-backed tile draw, hover/press/aim overlay, interaction signal.
# - 금지: combat state 직접 변경, controller 우회 호출.
#
# 실행: define the CellView as a texture-backed Button control.
class_name CellView
extends Button

const RED_TILE_TEXTURE := preload("res://resources/UI/tile/red_tile.png")
const BLUE_TILE_TEXTURE := preload("res://resources/UI/tile/blue_tile.png")
const GREEN_TILE_TEXTURE := preload("res://resources/UI/tile/green_tile.png")
const PURPLE_TILE_TEXTURE := preload("res://resources/UI/tile/purple_tile.png")
const RED_HAZARD_TEXTURE := preload("res://resources/UI/tile/red_tile_hazard.png")
const BLUE_HAZARD_TEXTURE := preload("res://resources/UI/tile/blue_tile_hazard.png")
const GREEN_HAZARD_TEXTURE := preload("res://resources/UI/tile/green_tile_hazard.png")
const PURPLE_HAZARD_TEXTURE := preload("res://resources/UI/tile/purple_tile_hazard.png")

signal cell_hovered(cell_id, weakness_color)
signal cell_clicked(cell_id, weakness_color)
signal cell_held(cell_id, weakness_color)
signal cell_pressed(cell_id, weakness_color)
signal cell_released()

# 방해요소 아트의 '줄기 프레임'(덩굴/가시 사각형) 중심선이 원본 이미지에서 차지하는 비율 rect.
# 각 hazard PNG(1132x348)의 알파 밴드 중앙값으로 측정 — 코너 화염/결정/버섯이 프레임 위로 솟아 있어
# 프레임 중심선을 타일 테두리에 정렬하면 이미지 전체가 타일 위쪽으로 상승한다.
const HAZARD_FRAME_FRACTIONS := {
	"red": Rect2(0.0420, 0.2500, 0.9134, 0.5891),
	"blue": Rect2(0.0477, 0.2342, 0.9006, 0.5675),
	"green": Rect2(0.0769, 0.1868, 0.8582, 0.6365),
	"purple": Rect2(0.0671, 0.2687, 0.8653, 0.5316)
}
const HAZARD_FRAME_FRACTION_FALLBACK := Rect2(0.05, 0.24, 0.90, 0.56)

# mockup .cell.c-* 그라디언트 틴트 페어 (상단 라이트 → 하단 딥, 알파 0.45 계열)
const TILE_TINT_LIGHT := {
	"red": Color("#e5989b"),
	"blue": Color("#a2d2ff"),
	"green": Color("#a7c957"),
	"purple": Color("#cdb4db")
}
const TILE_TINT_DEEP := {
	"red": Color("#b85667"),
	"blue": Color("#6290c8"),
	"green": Color("#6a994e"),
	"purple": Color("#b5838d")
}
const TILE_BORDER_COLOR := Color(0.173, 0.086, 0.02, 0.20)
const TILE_EMPTY_FILL := Color(0.118, 0.149, 0.118, 0.35)

var cell_id: String = ""
var row: int = 0
var column: int = 0
var weakness: Variant = null
var queue_match: bool = false
var active_queue_color: String = ""
var aimed: bool = false
var is_disabled_tile: bool = false
var hover_active: bool = false
var press_active: bool = false
var obstacle: Dictionary = {}
var obstacle_anim_time: float = 0.0
var battle_pause_active: bool = false
var hazard_overlay: TextureRect
var hazard_topfx: Control

# 실행: initialize the compact non-square tile button shell and interaction hooks.
func _ready() -> void:
	custom_minimum_size = Vector2(41, 26)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	mouse_filter = MouseFilter.MOUSE_FILTER_PASS
	focus_mode = FocusMode.FOCUS_NONE

	var empty_style := StyleBoxEmpty.new()
	add_theme_stylebox_override("normal", empty_style)
	add_theme_stylebox_override("hover", empty_style)
	add_theme_stylebox_override("pressed", empty_style)
	add_theme_stylebox_override("focus", empty_style)
	add_theme_stylebox_override("disabled", empty_style)

	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	_install_hazard_layers()
	set_process(true)

# 실행: 셀보다 사방으로 크게 그려지는 hazard 텍스처 레이어와 그 위 진행 바 레이어를 설치한다.
# 오버레이는 z_index 상향으로 인접 타일 기본면 위에 그려지고(목업 DOM 후순위 등가),
# 진행 바는 더 높은 z로 인접 hazard 오버레이에도 가려지지 않는다.
func _install_hazard_layers() -> void:
	if hazard_overlay != null:
		return
	hazard_overlay = TextureRect.new()
	hazard_overlay.name = "HazardOverlay"
	hazard_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hazard_overlay.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	hazard_overlay.stretch_mode = TextureRect.STRETCH_SCALE
	hazard_overlay.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	hazard_overlay.z_index = 2
	hazard_overlay.visible = false
	add_child(hazard_overlay)
	hazard_topfx = Control.new()
	hazard_topfx.name = "HazardTopFx"
	hazard_topfx.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hazard_topfx.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hazard_topfx.z_index = 5
	hazard_topfx.visible = false
	hazard_topfx.draw.connect(_draw_hazard_topfx)
	add_child(hazard_topfx)

func _process(delta: float) -> void:
	if not obstacle.is_empty() and not battle_pause_active:
		obstacle_anim_time += delta
		queue_redraw()

func set_battle_pause_active(active: bool) -> void:
	battle_pause_active = active
	queue_redraw()

# 실행: project mouse press/release events into battlefield cell signals.
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		var color_str := str(weakness) if weakness else "normal"
		if event.pressed:
			press_active = true
			if is_disabled_tile:
				mouse_default_cursor_shape = Control.CURSOR_FORBIDDEN
				queue_redraw()
				return
			emit_signal("cell_clicked", cell_id, color_str)
			emit_signal("cell_pressed", cell_id, color_str)
		else:
			press_active = false
			emit_signal("cell_released")
		queue_redraw()

# 실행: draw the real tile art plus queue, hover, aim, and disabled overlays.
func _draw() -> void:
	_sync_hazard_overlay()
	var tile_rect := Rect2(Vector2.ZERO, size)
	var display_color := _display_tile_color()
	var tile_texture := _tile_texture_for_color(display_color)
	var base_alpha := base_tile_alpha_for(weakness, queue_match, not active_queue_color.is_empty())
	if tile_texture != null:
		var tile_modulate := Color(1.0, 1.0, 1.0, base_alpha)
		if is_disabled_tile:
			tile_modulate = Color(0.42, 0.42, 0.42, maxf(0.72, base_alpha))
		_draw_tile_texture_cover(tile_texture, tile_rect, tile_modulate)
		_draw_tile_chrome(tile_rect, display_color, base_alpha)
	else:
		_draw_empty_tile(tile_rect)

	if not obstacle.is_empty():
		_draw_obstacle_underlay(tile_rect)

	if hover_active and not is_disabled_tile:
		draw_rect(tile_rect.grow(-4.0), Color(1.0, 1.0, 1.0, 0.05), true)
		if press_active:
			draw_circle(Vector2(size.x / 2.0, size.y / 2.0), minf(size.x, size.y) * 0.34, Color(1.0, 1.0, 1.0, 0.12))
	elif hover_active and is_disabled_tile:
		draw_rect(tile_rect.grow(-4.0), Color(0.82, 0.2, 0.2, 0.08), true)

	if aimed and not is_disabled_tile:
		var scope_color := Color(0.95, 0.75, 0.25, 0.9)
		var center := Vector2(size.x / 2.0, size.y / 2.0)
		var scope_size := minf(size.x, size.y) * 0.25
		draw_line(center + Vector2(-scope_size * 1.5, 0), center + Vector2(-scope_size * 0.8, 0), scope_color, 2.0)
		draw_line(center + Vector2(scope_size * 0.8, 0), center + Vector2(scope_size * 1.5, 0), scope_color, 2.0)
		draw_line(center + Vector2(0, -scope_size * 1.5), center + Vector2(0, -scope_size * 0.8), scope_color, 2.0)
		draw_line(center + Vector2(0, scope_size * 0.8), center + Vector2(0, scope_size * 1.5), scope_color, 2.0)
		draw_arc(center, scope_size, 0, 2 * PI, 16, scope_color, 1.5)
		draw_arc(center, scope_size * 1.4, 0, 2 * PI, 16, scope_color.lightened(0.2), 0.75)

	if is_disabled_tile:
		draw_rect(tile_rect, Color(0, 0, 0, 0.35), true)
		draw_line(Vector2(5, 5), Vector2(15, 15), Color(0.4, 0.1, 0.1, 0.5), 1.5)
		draw_line(Vector2(size.x - 15, size.y - 15), Vector2(size.x - 5, size.y - 5), Color(0.4, 0.1, 0.1, 0.5), 1.5)

# 실행: mockup background-size: cover 등가 — 정사각 타일 아트를 셀 비율로 중앙 크롭해 그린다.
# 셀에 맞춰 눌러 그리면 벽돌처럼 보이므로, 위아래를 잘라내고 원본 질감 비율을 유지한다.
func _draw_tile_texture_cover(texture: Texture2D, rect: Rect2, tile_modulate: Color) -> void:
	var tex_size := Vector2(texture.get_size())
	if tex_size.x <= 0.0 or tex_size.y <= 0.0 or rect.size.x <= 0.0 or rect.size.y <= 0.0:
		return
	var cover_scale := maxf(rect.size.x / tex_size.x, rect.size.y / tex_size.y)
	var src_size := rect.size / cover_scale
	var src_pos := (tex_size - src_size) * 0.5
	draw_texture_rect_region(texture, rect, Rect2(src_pos, src_size), tile_modulate)

# 실행: mockup .cell 크롬 — 색 그라디언트 틴트(상단 라이트→하단 딥) + 1px 다크 보더 + 하단 인셋 음영.
func _draw_tile_chrome(tile_rect: Rect2, display_color: String, base_alpha: float) -> void:
	if is_disabled_tile:
		return
	var light: Color = TILE_TINT_LIGHT.get(display_color, Color(1, 1, 1))
	var deep: Color = TILE_TINT_DEEP.get(display_color, Color(0.5, 0.5, 0.5))
	if TILE_TINT_LIGHT.has(display_color):
		var tint_alpha := 0.30 * base_alpha
		var points := PackedVector2Array([
			tile_rect.position,
			Vector2(tile_rect.end.x, tile_rect.position.y),
			tile_rect.end,
			Vector2(tile_rect.position.x, tile_rect.end.y)
		])
		var colors := PackedColorArray([
			Color(light.r, light.g, light.b, tint_alpha),
			Color(light.r, light.g, light.b, tint_alpha),
			Color(deep.r, deep.g, deep.b, tint_alpha),
			Color(deep.r, deep.g, deep.b, tint_alpha)
		])
		draw_polygon(points, colors)
	# 인셋 음영: 하단 2px 다크 밴드 + 상단 1px 라이트 밴드 (mockup inset box-shadow 등가)
	draw_rect(Rect2(Vector2(tile_rect.position.x + 1.0, tile_rect.end.y - 3.0), Vector2(tile_rect.size.x - 2.0, 2.0)), Color(0, 0, 0, 0.22 * base_alpha), true)
	draw_rect(Rect2(tile_rect.position + Vector2(1.0, 1.0), Vector2(tile_rect.size.x - 2.0, 1.0)), Color(1, 1, 1, 0.12 * base_alpha), true)
	draw_rect(tile_rect.grow(-0.5), TILE_BORDER_COLOR, false, 1.0)

# 실행: 색이 없는 빈 셀 — mockup .cell.c-none (짙은 반투명 + 내부 음영).
func _draw_empty_tile(tile_rect: Rect2) -> void:
	var fill := TILE_EMPTY_FILL
	if is_disabled_tile:
		fill = Color(fill.r, fill.g, fill.b, 0.28)
	draw_rect(tile_rect, fill, true)
	draw_rect(tile_rect.grow(-0.5), Color(0, 0, 0, 0.25), false, 1.0)

# 실행: enable hover state and notify the controller when the cursor enters.
func _on_mouse_entered() -> void:
	hover_active = true
	mouse_default_cursor_shape = Control.CURSOR_FORBIDDEN if is_disabled_tile else Control.CURSOR_POINTING_HAND
	emit_signal("cell_hovered", cell_id, str(weakness) if weakness else "normal")
	queue_redraw()

# 실행: clear hover/press state and release any held pointer interaction.
func _on_mouse_exited() -> void:
	hover_active = false
	if press_active:
		emit_signal("cell_released")
	press_active = false
	queue_redraw()

# 실행: store the latest battlefield cell snapshot and refresh the draw state.
func configure(cell_data: Dictionary, disabled_tiles: Array) -> void:
	cell_id = cell_data.get("id", "")
	row = int(cell_data.get("row", 0))
	column = int(cell_data.get("column", 0))
	weakness = cell_data.get("weakness", null)
	queue_match = bool(cell_data.get("queueMatch", false))
	active_queue_color = str(cell_data.get("activeQueueColor", ""))
	aimed = bool(cell_data.get("aimed", false))
	obstacle = cell_data.get("obstacle", {}).duplicate(true) if cell_data.get("obstacle", null) is Dictionary else {}
	is_disabled_tile = cell_id in disabled_tiles
	mouse_default_cursor_shape = Control.CURSOR_FORBIDDEN if is_disabled_tile else Control.CURSOR_POINTING_HAND
	queue_redraw()

# 실행: expose the readability alpha split between active weak tiles and all other cells.
static func base_tile_alpha_for(weakness_value: Variant, display_or_queue_match: Variant = "", active_queue_color_or_has_queue: Variant = "") -> float:
	if display_or_queue_match is bool or active_queue_color_or_has_queue is bool:
		var queue_match_value := bool(display_or_queue_match)
		var has_active_queue_color := bool(active_queue_color_or_has_queue)
		if not has_active_queue_color:
			return 0.5
		return 1.0 if queue_match_value else 0.5
	var resolved_display_color := str(display_or_queue_match)
	var active_queue_color := str(active_queue_color_or_has_queue)
	if resolved_display_color.is_empty() and weakness_value != null:
		resolved_display_color = str(weakness_value)
	if not active_queue_color.is_empty() and not resolved_display_color.is_empty():
		return 1.0 if resolved_display_color == active_queue_color else 0.5
	if weakness_value == null:
		return 0.5
	return 0.5 if str(weakness_value).is_empty() else 1.0

# 실행: expose the hazard overlay alpha split for active and afterglow states.
static func hazard_alpha_for(obstacle_data: Dictionary) -> float:
	if obstacle_data.is_empty():
		return 0.0
	var state := str(obstacle_data.get("state", "active"))
	if state in ["warning", "active"]:
		return 1.0
	if state == "afterglow_clear":
		var total := float(maxi(1, int(obstacle_data.get("afterglowTicks", 12))))
		var remaining := float(maxi(0, int(obstacle_data.get("afterglowTicksRemaining", 0))))
		return clampf((remaining / total) * 0.22, 0.0, 0.22)
	return 0.0

static func hazard_frame_margin_for(_family: String, _state: String) -> float:
	return 0.0

# 실행: hazard 이미지의 줄기 프레임 중심선을 타일 테두리에 정렬한 오버레이 rect(셀 로컬 좌표)를 계산한다.
# 코너 오브젝트(불/얼음/버섯/연기)는 프레임 위쪽 여백에 있으므로 결과 rect는 타일 위로 더 크게 상승한다.
static func hazard_overlay_rect_for(family: String, cell_size: Vector2) -> Rect2:
	var frame_frac: Rect2 = HAZARD_FRAME_FRACTIONS.get(family, HAZARD_FRAME_FRACTION_FALLBACK)
	if frame_frac.size.x <= 0.0 or frame_frac.size.y <= 0.0:
		frame_frac = HAZARD_FRAME_FRACTION_FALLBACK
	var overlay_size := Vector2(cell_size.x / frame_frac.size.x, cell_size.y / frame_frac.size.y)
	var overlay_position := Vector2(
		-frame_frac.position.x * overlay_size.x,
		-frame_frac.position.y * overlay_size.y
	)
	return Rect2(overlay_position, overlay_size)

static func active_hazard_fill_alpha_for(family: String, pulse: float) -> float:
	var alpha := 0.09 + 0.05 * pulse
	if family == "green":
		return alpha * 0.35
	return alpha

# 실행: choose the visible base tile color, falling back to the obstacle family when the cell itself has no weakness.
func _display_tile_color() -> String:
	if weakness != null and not str(weakness).is_empty():
		return str(weakness)
	if not obstacle.is_empty():
		return str(obstacle.get("requiredColor", obstacle.get("family", "")))
	return ""

# 실행: map color names to the imported weakness tile textures.
static func _tile_texture_for_color(color_name: String) -> Texture2D:
	match color_name:
		"red":
			return RED_TILE_TEXTURE
		"blue":
			return BLUE_TILE_TEXTURE
		"green":
			return GREEN_TILE_TEXTURE
		"purple":
			return PURPLE_TILE_TEXTURE
	return null

# 실행: map family color names to the imported hazard overlay textures.
static func _hazard_texture_for_color(color_name: String) -> Texture2D:
	match color_name:
		"red":
			return RED_HAZARD_TEXTURE
		"blue":
			return BLUE_HAZARD_TEXTURE
		"green":
			return GREEN_HAZARD_TEXTURE
		"purple":
			return PURPLE_HAZARD_TEXTURE
	return null

# 실행: map energy color names to the overlay highlight colors.
func _energy_color(color_name: String, alpha: float) -> Color:
	match color_name:
		"red":
			return Color(0.95, 0.32, 0.28, alpha)
		"blue":
			return Color(0.30, 0.58, 0.95, alpha)
		"green":
			return Color(0.30, 0.82, 0.42, alpha)
		"purple":
			return Color(0.72, 0.34, 0.92, alpha)
	return Color(1.0, 1.0, 1.0, alpha)

# 실행: hazard 활성 시 타일 내부에 옅은 계열색 필만 깐다(텍스처는 별도 오버레이 레이어).
func _draw_obstacle_underlay(tile_rect: Rect2) -> void:
	var state := str(obstacle.get("state", "active"))
	if state == "warning":
		state = "active"
	if state != "active":
		return
	var family := str(obstacle.get("family", ""))
	var base_color := _energy_color(family, 1.0)
	var pulse: float = 0.55 + 0.45 * abs(sin(obstacle_anim_time * 5.0))
	var active_fill_alpha := active_hazard_fill_alpha_for(family, pulse)
	draw_rect(tile_rect.grow(-1.0), Color(base_color.r, base_color.g, base_color.b, active_fill_alpha), true)

# 실행: hazard 텍스처를 줄기 프레임이 타일 테두리를 감싸도록 앵커링된 TextureRect 레이어로 씌운다.
func _sync_hazard_overlay() -> void:
	if hazard_overlay == null:
		return
	var family := str(obstacle.get("family", ""))
	var state := str(obstacle.get("state", "active"))
	if state == "warning":
		state = "active"
	var hazard_texture := _hazard_texture_for_color(family)
	var hazard_alpha := hazard_alpha_for(obstacle)
	if obstacle.is_empty() or hazard_texture == null or hazard_alpha <= 0.0:
		hazard_overlay.visible = false
		if hazard_topfx != null:
			hazard_topfx.visible = false
		return
	var pulse: float = 0.55 + 0.45 * abs(sin(obstacle_anim_time * 5.0))
	var overlay_alpha := hazard_alpha
	if state == "active":
		overlay_alpha = clampf(hazard_alpha * (0.93 + 0.07 * pulse), 0.0, 1.0)
	var overlay_rect := hazard_overlay_rect_for(family, size)
	hazard_overlay.texture = hazard_texture
	hazard_overlay.position = overlay_rect.position
	hazard_overlay.size = overlay_rect.size
	hazard_overlay.modulate = Color(1.0, 1.0, 1.0, overlay_alpha)
	hazard_overlay.visible = true
	if hazard_topfx != null:
		hazard_topfx.visible = state == "active"
		hazard_topfx.queue_redraw()

# 실행: hazard 진행 바를 오버레이보다 위 레이어에 그린다 (인접 오버레이 겹침에도 판독 유지).
func _draw_hazard_topfx() -> void:
	if hazard_topfx == null or obstacle.is_empty():
		return
	var state := str(obstacle.get("state", "active"))
	if state == "warning":
		state = "active"
	if state != "active":
		return
	var family := str(obstacle.get("family", ""))
	var base_color := _energy_color(family, 1.0)
	var clear_progress := maxi(1, int(obstacle.get("clearProgress", 2)))
	var progress_ratio := clampf(float(obstacle.get("progress", 0)) / float(clear_progress), 0.0, 1.0)
	var tile_rect := Rect2(Vector2.ZERO, hazard_topfx.size)
	var inner := tile_rect.grow(-5.0)
	var full_rect := Rect2(Vector2(inner.position.x, tile_rect.end.y - 6.0), Vector2(inner.size.x, 3.0))
	var bar_rect := Rect2(full_rect.position, Vector2(inner.size.x * progress_ratio, 3.0))
	hazard_topfx.draw_rect(full_rect, Color(0, 0, 0, 0.28), true)
	hazard_topfx.draw_rect(bar_rect, Color(base_color.r, base_color.g, base_color.b, 0.92), true)

# 큐 매칭/비매칭 프레임은 제거됨 — 판독은 base_tile_alpha_for의 알파 이분(1.0/0.5)만으로 유지한다.
