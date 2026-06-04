# 계약:
# - 책임: battlefield panel 위에 남아 있는 전투 시간 border pulse만 그린다.
# - 입력: combat time state.
# - 출력: battlefield border draw calls.
# - 금지: reward reveal orchestration, reward UI 전환, full-screen overlay 처리.
#
# 실행: define the battlefield-local combat timer overlay.
class_name BattlefieldVFX
extends Control

var is_revealing := false
var time_left := 0.0
var time_limit := 0.0
var in_combat := false
var pulse_time := 0.0
var battle_pause_active := false

# 실행: update battlefield combat timer state.
func update_combat_time(left: float, limit: float, active: bool) -> void:
	time_left = left
	time_limit = limit
	in_combat = active
	queue_redraw()

func set_battle_pause_active(active: bool) -> void:
	battle_pause_active = active
	queue_redraw()

func _process(delta: float) -> void:
	if in_combat and not battle_pause_active:
		pulse_time += delta
		queue_redraw()

func _draw() -> void:
	_draw_combat_border()

# 실행: draw the remaining combat timer border around the battlefield panel.
func _draw_combat_border() -> void:
	if not in_combat or time_limit <= 0.0:
		return
	var ratio := time_left / time_limit
	var inset := 2.0
	var width_available := size.x - 2.0 * inset
	var height_available := size.y - 2.0 * inset
	var remaining := ratio * (2.0 * width_available + 2.0 * height_available)
	var color := Color(0.25, 0.65, 0.95, 0.8)
	var line_width := 3.0
	if time_left <= 200.0:
		var pulse: float = 0.35 + 0.65 * abs(sin(pulse_time * 6.5))
		color = Color(0.9, 0.1, 0.1, 0.4 + 0.6 * pulse)
		line_width = 3.5 + pulse
	var points: Array[Vector2] = [Vector2(inset, inset), Vector2(inset + width_available, inset), Vector2(inset + width_available, inset + height_available), Vector2(inset, inset + height_available)]
	var lengths: Array[float] = [width_available, height_available, width_available, height_available]
	var directions: Array[Vector2] = [Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT, Vector2.UP]
	for index in range(4):
		if remaining <= 0.0:
			return
		var distance: float = min(remaining, lengths[index])
		draw_line(points[index], points[index] + directions[index] * distance, color, line_width)
		remaining -= distance
