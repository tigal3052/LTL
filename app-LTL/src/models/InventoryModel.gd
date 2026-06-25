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
var grid: Array = [] # 2D array of String (inventory artifact key) or empty String
var artifacts: Dictionary = {} # inventory artifact key -> Artifact instance

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
	if art == null:
		return false
	var moving_key := _existing_key_for_artifact(art)
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
				var occupant := str(grid[target_y][target_x])
				if not occupant.is_empty() and occupant != moving_key:
					return false
	return true

# 실행: place an artifact in the backpack.
func place_artifact(art: Artifact, x: int, y: int) -> bool:
	if not can_place_artifact(art, x, y):
		return false
	var art_key := _placement_key_for_artifact(art)
	
	# Clear old position from grid if already placed
	for r in range(height):
		for c in range(width):
			if str(grid[r][c]) == art_key:
				grid[r][c] = ""
				
	art.x = x
	art.y = y
	var shape := art.shape
	var rows: int = shape.size()
	var cols: int = shape[0].size() if rows > 0 else 0
	for r in range(rows):
		for c in range(cols):
			if shape[r][c] == 1:
				grid[y + r][x + c] = art_key
	artifacts[art_key] = art
	calculate_synergies()
	return true

# 실행: remove an artifact from the backpack.
func remove_artifact(art_id: String) -> bool:
	var art_key := _resolve_artifact_key(art_id)
	if art_key.is_empty():
		return false
	for r in range(height):
		for c in range(width):
			if str(grid[r][c]) == art_key:
				grid[r][c] = ""
	artifacts.erase(art_key)
	calculate_synergies()
	return true

func artifact_key(art: Artifact) -> String:
	return _existing_key_for_artifact(art)

func _existing_key_for_artifact(art: Artifact) -> String:
	if art == null:
		return ""
	var declared_key := _declared_artifact_key(art)
	if not declared_key.is_empty() and artifacts.has(declared_key) and artifacts[declared_key] == art:
		return declared_key
	for art_key in artifacts:
		if artifacts[art_key] == art:
			return str(art_key)
	return ""

func _placement_key_for_artifact(art: Artifact) -> String:
	var existing_key := _existing_key_for_artifact(art)
	if not existing_key.is_empty():
		return existing_key
	var preferred_key := _declared_artifact_key(art)
	if preferred_key.is_empty():
		preferred_key = "artifact"
	if not artifacts.has(preferred_key):
		return preferred_key
	var base_key := str(art.id)
	if base_key.is_empty():
		base_key = "artifact"
	var duplicate_index := 2
	var duplicate_key := "%s#%d" % [base_key, duplicate_index]
	while artifacts.has(duplicate_key):
		duplicate_index += 1
		duplicate_key = "%s#%d" % [base_key, duplicate_index]
	art.instance_id = duplicate_key
	return duplicate_key

func _resolve_artifact_key(art_id: String) -> String:
	if artifacts.has(art_id):
		return art_id
	for art_key in artifacts:
		var art: Artifact = artifacts[art_key]
		if art != null and str(art.id) == art_id:
			return str(art_key)
	return ""

func _artifact_key_for_comparison(art: Artifact) -> String:
	var existing_key := _existing_key_for_artifact(art)
	if not existing_key.is_empty():
		return existing_key
	return _declared_artifact_key(art)

func _declared_artifact_key(art: Artifact) -> String:
	if art == null:
		return ""
	if not str(art.instance_id).is_empty():
		return str(art.instance_id)
	return str(art.id)

# 실행: get drills adjacent to the specified artifact.
func get_adjacent_drills(art: Artifact) -> Array:
	var adjacent_drills := []
	var art_key := _artifact_key_for_comparison(art)
	var occupied_cells := []
	var shape := art.shape
	var rows: int = shape.size()
	var cols: int = shape[0].size() if rows > 0 else 0
	for r in range(rows):
		for c in range(cols):
			if shape[r][c] == 1:
				occupied_cells.append(Vector2i(art.x + c, art.y + r))
				
	var neighbors := []
	for cell in occupied_cells:
		var directions = [
			Vector2i(cell.x + 1, cell.y),
			Vector2i(cell.x - 1, cell.y),
			Vector2i(cell.x, cell.y + 1),
			Vector2i(cell.x, cell.y - 1)
		]
		for dir in directions:
			if dir.x >= 0 and dir.x < width and dir.y >= 0 and dir.y < height:
				if not dir in occupied_cells and not dir in neighbors:
					neighbors.append(dir)
					
	for nb in neighbors:
		var nb_id := str(grid[nb.y][nb.x])
		if not nb_id.is_empty() and nb_id != art_key:
			var nb_art = artifacts[nb_id]
			if nb_art and nb_art.item_type == "drill":
				if not nb_art in adjacent_drills:
					adjacent_drills.append(nb_art)
	return adjacent_drills

# ?ㅽ뻾: query the artifacts linked from a relic through its non-orthogonal grammar.
func get_relic_linked_artifacts(relic: Artifact) -> Array:
	if relic == null or relic.item_type != "relic":
		return []
	var link_mode := str(relic.effect_schema.get("link_mode", "")).to_lower()
	if link_mode.is_empty():
		return []
	var offsets := []
	if link_mode == "skip_2":
		offsets = [
			Vector2i(2, 0),
			Vector2i(-2, 0),
			Vector2i(0, 2),
			Vector2i(0, -2)
		]
	elif link_mode == "crown_link":
		offsets = [
			Vector2i(1, 1),
			Vector2i(1, -1),
			Vector2i(-1, 1),
			Vector2i(-1, -1),
			Vector2i(2, 0),
			Vector2i(-2, 0),
			Vector2i(0, 2),
			Vector2i(0, -2)
		]
	else:
		offsets = [
			Vector2i(1, 1),
			Vector2i(1, -1),
			Vector2i(-1, 1),
			Vector2i(-1, -1)
		]
	var linked: Array = []
	var linked_ids := {}
	var relic_key := _artifact_key_for_comparison(relic)
	for cell in _collect_relic_target_cells(relic, offsets):
		var art_id := str(grid[cell.y][cell.x])
		if art_id.is_empty() or art_id == relic_key or linked_ids.has(art_id):
			continue
		linked_ids[art_id] = true
		linked.append(artifacts[art_id])
	return linked

# 실행: recalculate synergy cooldown reductions (adjacent identical energy type drops cooldown) and beacon effects.
func calculate_synergies() -> void:
	for art_id in artifacts:
		var art: Artifact = artifacts[art_id]
		art.synergy_cooldown_reduction = 0
		if art.item_type == "drill":
			art.damage = art.base_damage

	for art_id in artifacts:
		var art: Artifact = artifacts[art_id]
		if art.item_type != "drill":
			continue
		
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
							if not nb_id.is_empty() and nb_id != art_id:
								var nb_art: Artifact = artifacts[nb_id]
								if nb_art and nb_art.item_type == "drill" and nb_art.energy_type == art.energy_type:
									if not nb_id in adjacent_matches:
										adjacent_matches.append(nb_id)
										
		art.synergy_cooldown_reduction = adjacent_matches.size() * synergy_val

	for art_id in artifacts:
		var beacon: Artifact = artifacts[art_id]
		if beacon.item_type != "beacon" or is_zero_approx(beacon.beacon_damage_mod):
			continue
		for drill in get_adjacent_drills(beacon):
			if drill.energy_type == beacon.energy_type:
				drill.damage = maxf(0.0, drill.damage + beacon.beacon_damage_mod)

	for art_id in artifacts:
		var relic: Artifact = artifacts[art_id]
		if relic.item_type != "relic":
			continue
		if str(relic.effect_schema.get("type", "")) != "cooldown_trim":
			continue
		var trim: int = abs(int(relic.effect_schema.get("value", 0)))
		if trim <= 0:
			continue
		for linked_artifact in get_relic_linked_artifacts(relic):
			if linked_artifact is Artifact and linked_artifact.item_type == "drill":
				linked_artifact.synergy_cooldown_reduction += trim
				var effective_cooldown: int = maxi(1, int(linked_artifact.base_cooldown_ticks) - int(linked_artifact.synergy_cooldown_reduction))
				linked_artifact.current_cooldown = clampi(int(linked_artifact.current_cooldown), 0, effective_cooldown)

	# Beacon cooldown effects are applied during tick(), not as permanent stat modifiers.

# 실행: progress tick for all artifacts and return generated energies color Array.
func tick() -> Array:
	var generated: Array = []
	for art_id in artifacts:
		var art: Artifact = artifacts[art_id]
		if art.item_type == "beacon":
			if art.tick_beacon():
				_apply_beacon_pulse(art)
		else:
			var energy = art.tick()
			if energy != null:
				generated.append({
					"color": str(energy),
					"source_artifact_id": art.id,
					"source_item_type": art.item_type
				})
	return generated

# 실행: apply a charged beacon pulse to adjacent drills by reducing their current cooldown.
func _apply_beacon_pulse(beacon: Artifact) -> void:
	var delta := int(beacon.beacon_cooldown_mod)
	if delta == 0:
		return
	for drill in get_adjacent_drills(beacon):
		if drill.energy_type != beacon.energy_type:
			continue
		var effective_cooldown := maxi(1, int(drill.base_cooldown_ticks) - int(drill.synergy_cooldown_reduction))
		drill.current_cooldown = clampi(int(drill.current_cooldown) + delta, 0, effective_cooldown)

func _collect_relic_target_cells(relic: Artifact, offsets: Array) -> Array:
	var occupied_cells := _occupied_cells_for(relic)
	var occupied_lookup := {}
	for cell in occupied_cells:
		occupied_lookup[_cell_key(cell)] = true
	var targets: Array = []
	var target_lookup := {}
	for cell in occupied_cells:
		for offset in offsets:
			var target := Vector2i(cell.x + offset.x, cell.y + offset.y)
			if target.x < 0 or target.x >= width or target.y < 0 or target.y >= height:
				continue
			var target_key := _cell_key(target)
			if occupied_lookup.has(target_key) or target_lookup.has(target_key):
				continue
			target_lookup[target_key] = true
			targets.append(target)
	return targets

func _occupied_cells_for(art: Artifact) -> Array:
	var occupied_cells: Array = []
	var shape := art.shape
	var rows: int = shape.size()
	var cols: int = shape[0].size() if rows > 0 else 0
	for r in range(rows):
		for c in range(cols):
			if shape[r][c] == 1:
				occupied_cells.append(Vector2i(art.x + c, art.y + r))
	return occupied_cells

func _cell_key(cell: Vector2i) -> String:
	return "%s,%s" % [cell.x, cell.y]

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
