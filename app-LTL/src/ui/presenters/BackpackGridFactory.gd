# 계약:
# - 책임: backpack grid slot과 artifact/ghost overlay용 style/control 생성을 제공한다.
# - 입력: texture map, slot coordinate, artifact energy/shape 정보.
# - 출력: BackpackUI가 배치할 Control/StyleBox.
# - 금지: inventory 변경, controller 접근, signal emit 직접 수행.
#
# 실행: define backpack grid UI factory helpers.
class_name BackpackGridFactory
extends RefCounted

# 실행: build a border texture cell.
static func border_cell(texture: Texture2D) -> TextureRect:
	var rect := TextureRect.new()
	rect.custom_minimum_size = Vector2(16, 16)
	rect.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rect.size_flags_vertical = Control.SIZE_EXPAND_FILL
	rect.texture = texture
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_SCALE
	return rect

# 실행: build an inner backpack slot with overlay child.
static func inner_slot(texture: Texture2D) -> Panel:
	var slot := Panel.new()
	slot.custom_minimum_size = Vector2(16, 16)
	slot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slot.size_flags_vertical = Control.SIZE_EXPAND_FILL
	slot.self_modulate = Color(0.95, 0.90, 0.82, 0.65)
	var bg_style := StyleBoxTexture.new()
	bg_style.texture = texture
	slot.add_theme_stylebox_override("panel", bg_style)
	var overlay := Panel.new()
	overlay.name = "Overlay"
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	slot.add_child(overlay)
	return slot

# 실행: produce a filled artifact overlay style.
static func artifact_style(energy_type: String, alpha: float, edges := {}) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = energy_color(energy_type, alpha)
	style.border_width_left = 1 if bool(edges.get("left", true)) else 0
	style.border_width_top = 1 if bool(edges.get("top", true)) else 0
	style.border_width_right = 1 if bool(edges.get("right", true)) else 0
	style.border_width_bottom = 1 if bool(edges.get("bottom", true)) else 0
	style.border_color = Color.BLACK
	return style

# 실행: return which sides of a shape cell are on the artifact perimeter.
static func artifact_edge_mask(shape: Array, row: int, column: int) -> Dictionary:
	return {
		"left": not _shape_filled(shape, row, column - 1),
		"top": not _shape_filled(shape, row - 1, column),
		"right": not _shape_filled(shape, row, column + 1),
		"bottom": not _shape_filled(shape, row + 1, column)
	}

# 실행: check whether a shape coordinate is occupied by the same artifact.
static func _shape_filled(shape: Array, row: int, column: int) -> bool:
	if row < 0 or row >= shape.size():
		return false
	var shape_row = shape[row]
	if not shape_row is Array or column < 0 or column >= shape_row.size():
		return false
	return int(shape_row[column]) == 1

# 실행: map artifact energy type to backpack color.
static func energy_color(energy_type: String, alpha: float) -> Color:
	match energy_type:
		"red": return Color(0.85, 0.25, 0.25, alpha)
		"blue": return Color(0.25, 0.50, 0.85, alpha)
		"purple": return Color(0.65, 0.25, 0.85, alpha)
		"green": return Color(0.25, 0.75, 0.35, alpha)
	return Color(1, 1, 1, alpha)

# 실행: calculate a 10x10 texture border slice number.
static func border_slice(row: int, column: int) -> int:
	if row == 0:
		return 1 if column == 0 else (3 if column == 9 else 2)
	if row == 9:
		return 7 if column == 0 else (9 if column == 9 else 8)
	return 4 if column == 0 else (6 if column == 9 else 5)
