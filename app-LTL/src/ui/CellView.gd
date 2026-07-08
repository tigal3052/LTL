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

# 실행: initialize the compact non-square tile button shell and interaction hooks.
func _ready() -> void:
	custom_minimum_size = Vector2(41, 36)
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
	set_process(true)

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
	var tile_rect := Rect2(Vector2.ZERO, size)
	var display_color := _display_tile_color()
	var tile_texture := _tile_texture_for_color(display_color)
	var base_alpha := base_tile_alpha_for(weakness, queue_match, not active_queue_color.is_empty())
	if tile_texture != null:
		var tile_modulate := Color(1.0, 1.0, 1.0, base_alpha)
		if is_disabled_tile:
			tile_modulate = Color(0.42, 0.42, 0.42, maxf(0.72, base_alpha))
		draw_texture_rect(tile_texture, tile_rect, false, tile_modulate)
	else:
		var fill_alpha := 0.20 + base_alpha * 0.24
		if is_disabled_tile:
			fill_alpha = 0.28
		draw_rect(tile_rect, Color(0.12, 0.16, 0.2, fill_alpha), true)

	if not obstacle.is_empty():
		_draw_obstacle_overlay(tile_rect)

	if not active_queue_color.is_empty() and weakness != null and not str(weakness).is_empty() and not is_disabled_tile:
		if queue_match:
			_draw_match_frame(tile_rect, active_queue_color)
		else:
			_draw_mismatch_frame(tile_rect)

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

static func hazard_texture_margin_for(family: String, state: String) -> float:
	if state == "active":
		return 4.0 if family == "green" else 3.25
	if state == "afterglow_clear":
		return 1.25
	return 0.0

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

func _draw_obstacle_overlay(tile_rect: Rect2) -> void:
	var family := str(obstacle.get("family", ""))
	var state := str(obstacle.get("state", "active"))
	if state == "warning":
		state = "active"
	var base_color := _energy_color(family, 1.0)
	var pulse: float = 0.55 + 0.45 * abs(sin(obstacle_anim_time * 5.0))
	var progress_ratio := 0.0
	var clear_progress := maxi(1, int(obstacle.get("clearProgress", 2)))
	progress_ratio = clampf(float(obstacle.get("progress", 0)) / float(clear_progress), 0.0, 1.0)
	var inner := tile_rect.grow(-5.0)
	var hazard_alpha := hazard_alpha_for(obstacle)
	var hazard_texture := _hazard_texture_for_color(family)
	var hazard_texture_rect := tile_rect.grow(hazard_texture_margin_for(family, state))
	var hazard_fill_rect := tile_rect.grow(-1.0)
	var active_fill_alpha := active_hazard_fill_alpha_for(family, pulse)
	if hazard_texture != null and hazard_alpha > 0.0:
		var overlay_alpha := hazard_alpha
		if state == "active":
			overlay_alpha = clampf(hazard_alpha * (0.93 + 0.07 * pulse), 0.0, 1.0)
			draw_rect(hazard_fill_rect, Color(base_color.r, base_color.g, base_color.b, active_fill_alpha), true)
		draw_texture_rect(hazard_texture, hazard_texture_rect, false, Color(1.0, 1.0, 1.0, overlay_alpha))
	if state == "active":
		_draw_obstacle_progress_bar(inner, tile_rect, Color(base_color.r, base_color.g, base_color.b, 0.92), progress_ratio)

func _draw_obstacle_progress_bar(inner: Rect2, tile_rect: Rect2, color: Color, progress_ratio: float) -> void:
	var full_rect := Rect2(Vector2(inner.position.x, tile_rect.end.y - 6.0), Vector2(inner.size.x, 3.0))
	var bar_rect := Rect2(full_rect.position, Vector2(inner.size.x * progress_ratio, 3.0))
	draw_rect(full_rect, Color(0, 0, 0, 0.28), true)
	draw_rect(bar_rect, color, true)

func _draw_match_frame(tile_rect: Rect2, color_name: String) -> void:
	var accent := _energy_color(color_name, 0.95)
	var inner := tile_rect.grow(-2.5)
	draw_rect(inner, Color(accent.r, accent.g, accent.b, 0.10), false, 2.0)
	var notch := 7.0
	draw_line(inner.position, inner.position + Vector2(notch, 0.0), accent, 2.0)
	draw_line(inner.position, inner.position + Vector2(0.0, notch), accent, 2.0)
	draw_line(Vector2(inner.end.x, inner.position.y), Vector2(inner.end.x - notch, inner.position.y), accent, 2.0)
	draw_line(Vector2(inner.end.x, inner.position.y), Vector2(inner.end.x, inner.position.y + notch), accent, 2.0)
	draw_line(Vector2(inner.position.x, inner.end.y), Vector2(inner.position.x + notch, inner.end.y), accent, 2.0)
	draw_line(Vector2(inner.position.x, inner.end.y), Vector2(inner.position.x, inner.end.y - notch), accent, 2.0)
	draw_line(inner.end, inner.end + Vector2(-notch, 0.0), accent, 2.0)
	draw_line(inner.end, inner.end + Vector2(0.0, -notch), accent, 2.0)

func _draw_mismatch_frame(tile_rect: Rect2) -> void:
	var accent := Color(1.0, 0.88, 0.58, 0.70)
	var inner := tile_rect.grow(-3.0)
	draw_line(inner.position + Vector2(0.0, 4.0), inner.position + Vector2(10.0, 0.0), accent, 1.6)
	draw_line(inner.end + Vector2(-10.0, 0.0), inner.end + Vector2(0.0, -4.0), accent, 1.6)
	draw_line(Vector2(inner.position.x + 4.0, inner.end.y), Vector2(inner.position.x + 12.0, inner.end.y - 4.0), accent, 1.6)
	draw_line(Vector2(inner.end.x - 12.0, inner.position.y + 4.0), Vector2(inner.end.x - 2.0, inner.position.y), accent, 1.6)
