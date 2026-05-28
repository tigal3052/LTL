# 계약:
# - 책임: battlefield weakness marker를 오른쪽으로 한 칸 이동하고 왼쪽 열에 deterministic marker를 삽입한다.
# - 입력: marker Array, rows, columns, seed, color palette.
# - 출력: { ok, markers, code } dictionary.
# - 금지: run state 직접 변경, UI 접근, timer 접근.
#
# 실행: define the ShiftWeaknessMarkers vocabulary function holder.
class_name ShiftWeaknessMarkers
extends RefCounted

# 실행: shift existing markers and create a seeded left-column marker per row.
static func shift(markers: Array, rows: int = 3, columns: int = 10, seed_val: int = 1, colors: Array = ["red", "blue", "purple", "green"], step: int = 0) -> Dictionary:
	var next_markers: Array = []
	for marker in markers:
		var cell_id := str(marker.get("cellId", ""))
		if cell_id.begins_with("r") and "c" in cell_id:
			var parts := cell_id.substr(1).split("c")
			if parts.size() == 2:
				var row := int(parts[0])
				var new_column := int(parts[1]) + 1
				if new_column < columns:
					next_markers.append({"cellId": "r%dc%d" % [row, new_column], "color": marker.get("color", "red")})
	var palette := colors.duplicate(true)
	if palette.is_empty():
		palette = ["red"]
	for row in range(maxi(0, rows)):
		var color_index: int = abs(int(seed_val) + int(step) * 31 + row * 17) % palette.size()
		next_markers.append({"cellId": "r%dc0" % row, "color": str(palette[color_index])})
	return {"ok": true, "code": "shifted", "markers": next_markers}
