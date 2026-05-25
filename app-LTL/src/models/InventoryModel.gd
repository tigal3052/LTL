# 계약:
# - 책임: 백팩 2D 그리드 내 유물들의 배치 및 인접 시너지(쿨타임 감소) 계산을 관리하는 사물 모델 계약을 제공한다.
# - 입력: 그리드 가로/세로 크기, 유물 목록.
# - 출력: 배치 타당성 여부, 배치된 유물들의 스냅샷 및 시너지 결과.
# - 금지: SceneTree 접근, 직접적인 UI 렌더링.
#
# 실행: define the InventoryModel class identity.
class_name InventoryModel
extends RefCounted
# 실행: store backpack dimensions and placed artifacts.
# 8x8은 백팩의 '최대 규격'입니다. 게임 초반엔 2x2와 같이 작은 크기로 시작하며,
# 현재 테스트 및 데모 편의를 위해 8x8 최대 규격을 디폴트로 지정해둔 상태입니다.
var width: int = 8
var height: int = 8
var grid: Array = [] # 2D array of String (artifact_id) or empty String
var artifacts: Dictionary = {} # artifact_id -> Artifact instance

# 실행: initialize the backpack grid size.
func _init(w: int = 8, h: int = 8) -> void:
	width = w
	height = h
	grid = []
	for r in range(height):
		var row: Array = []
		for c in range(width):
			row.append("")
		grid.append(row)

# 실행: check if an artifact shape can fit at coordinates.
func can_place_artifact(art: Artifact, x: int, y: int) -> bool:
	var shape := art.shape
	var rows: int = shape.size()
	var cols: int = shape[0].size() if rows > 0 else 0
	for r in range(rows):
		for c in range(cols):
			if shape[r][c] == 1:
				var target_x := x + c
				var target_y := y + r
				if target_x < 0 or target_x >= width or target_y < 0 or target_y >= height:
					return false
				if grid[target_y][target_x] != "" and grid[target_y][target_x] != art.id:
					return false
	return true

# 실행: place an artifact in the backpack.
func place_artifact(art: Artifact, x: int, y: int) -> bool:
	if not can_place_artifact(art, x, y):
		return false
	
	# Clear old position from grid if already placed
	for r in range(height):
		for c in range(width):
			if grid[r][c] == art.id:
				grid[r][c] = ""
				
	art.x = x
	art.y = y
	var shape := art.shape
	var rows: int = shape.size()
	var cols: int = shape[0].size() if rows > 0 else 0
	for r in range(rows):
		for c in range(cols):
			if shape[r][c] == 1:
				grid[y + r][x + c] = art.id
	artifacts[art.id] = art
	calculate_synergies()
	return true

# 실행: remove an artifact from the backpack.
func remove_artifact(art_id: String) -> bool:
	if not artifacts.has(art_id):
		return false
	for r in range(height):
		for c in range(width):
			if grid[r][c] == art_id:
				grid[r][c] = ""
	artifacts.erase(art_id)
	calculate_synergies()
	return true

# 실행: recalculate synergy cooldown reductions (adjacent identical energy type drops cooldown).
func calculate_synergies() -> void:
	for art_id in artifacts:
		var art: Artifact = artifacts[art_id]
		art.synergy_cooldown_reduction = 0

	for art_id in artifacts:
		var art: Artifact = artifacts[art_id]
		
		# synergy 설정을 파싱하거나 디폴트 same_color 적용
		var synergy_type := "same_color"
		var synergy_val := 2
		
		if not art.synergy.is_empty():
			var json = JSON.new()
			if json.parse(art.synergy) == OK:
				var data = json.get_data()
				if data is Dictionary:
					synergy_type = data.get("type", "same_color")
					synergy_val = int(data.get("value", 2))
		
		if synergy_type != "same_color":
			continue
			
		var adjacent_matches := []
		var shape := art.shape
		var rows: int = shape.size()
		var cols: int = shape[0].size() if rows > 0 else 0
		
		for r in range(rows):
			for c in range(cols):
				if shape[r][c] == 1:
					var gy := art.y + r
					var gx := art.x + c
					var neighbors := [
						Vector2i(gx + 1, gy),
						Vector2i(gx - 1, gy),
						Vector2i(gx, gy + 1),
						Vector2i(gx, gy - 1)
					]
					for nb in neighbors:
						if nb.x >= 0 and nb.x < width and nb.y >= 0 and nb.y < height:
							var nb_id := str(grid[nb.y][nb.x])
							if not nb_id.is_empty() and nb_id != art.id:
								var nb_art: Artifact = artifacts[nb_id]
								if nb_art and nb_art.energy_type == art.energy_type:
									if not nb_id in adjacent_matches:
										adjacent_matches.append(nb_id)
										
		art.synergy_cooldown_reduction = adjacent_matches.size() * synergy_val

# 실행: progress tick for all artifacts and return generated energies color Array.
func tick() -> Array:
	var generated: Array = []
	for art_id in artifacts:
		var art: Artifact = artifacts[art_id]
		var energy = art.tick()
		if energy != null:
			generated.append(str(energy))
	return generated

# 실행: export inventory state to a clean dictionary snapshot.
func to_dict() -> Dictionary:
	var snapshot_artifacts: Array = []
	for art_id in artifacts:
		snapshot_artifacts.append(artifacts[art_id].to_dict())
	return {
		"width": width,
		"height": height,
		"grid": grid.duplicate(true),
		"artifacts": snapshot_artifacts
	}
