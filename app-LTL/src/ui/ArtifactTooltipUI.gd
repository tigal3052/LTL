# 계약:
# - 책임: artifact tooltip floating panel의 생성, 표시, 숨김, 위치 갱신을 캡슐화한다.
# - 입력: tooltip bbcode text와 mouse/global position.
# - 출력: visible 상태와 RichTextLabel 표시.
# - 금지: tooltip 내용 계산, inventory 접근, gameplay state 변경.
#
# 실행: define the artifact tooltip panel UI control.
class_name ArtifactTooltipUI
extends PanelContainer

var label: RichTextLabel

# 실행: construct the tooltip panel and label.
func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_as_top_level(true)
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.10, 0.12, 0.95)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.24, 0.35, 0.50, 0.9)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_right = 8
	style.corner_radius_bottom_left = 8
	style.content_margin_left = 12
	style.content_margin_top = 10
	style.content_margin_right = 12
	style.content_margin_bottom = 10
	add_theme_stylebox_override("panel", style)
	label = RichTextLabel.new()
	label.fit_content = true
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size = Vector2(240, 0)
	label.bbcode_enabled = true
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(label)

# 실행: show the provided bbcode text.
func show_text(bbcode_text: String) -> void:
	if label == null:
		return
	label.text = bbcode_text
	visible = true

# 실행: hide the tooltip panel.
func hide_tooltip() -> void:
	visible = false

# 실행: position the tooltip near the cursor.
func update_position(global_mouse_pos: Vector2) -> void:
	if visible:
		var panel_size := size
		var min_size := get_combined_minimum_size()
		panel_size.x = maxf(panel_size.x, min_size.x)
		panel_size.y = maxf(panel_size.y, min_size.y)
		global_position = clamped_position(global_mouse_pos, panel_size, get_viewport_rect().size)

# 실행: calculate a viewport-clamped floating tooltip position.
static func clamped_position(global_mouse_pos: Vector2, panel_size: Vector2, viewport_size: Vector2, offset := Vector2(15, 15), margin := 8.0) -> Vector2:
	var desired := global_mouse_pos + offset
	var max_x := maxf(margin, viewport_size.x - panel_size.x - margin)
	var max_y := maxf(margin, viewport_size.y - panel_size.y - margin)
	return Vector2(clampf(desired.x, margin, max_x), clampf(desired.y, margin, max_y))
