# 계약:
# - 책임: 개별 유물의 상태(ID, 이름, 모양, 쿨타임, 시너지 키워드 등) 및 회전을 관리하는 사물 모델 계약을 제공한다.
# - 입력: 유물 속성 정보 Dictionary.
# - 출력: 유물의 상태 조회 및 회전된 형상 데이터.
# - 금지: SceneTree 접근, 타 유물 상태 직접 변경.
#
# 실행: define the Artifact class identity.
class_name Artifact
extends RefCounted

# 실행: store individual artifact attributes.
var id: String = ""
var name: String = ""
var shape: Array = []
var energy_type: String = ""
var base_cooldown_ticks: int = 1
var effective_cooldown: int = 1
var synergy: String = ""
var keyword: String = ""
var damage: float = 1.0
var grade: String = "basic"
var item_type: String = "drill"

# 실행: store dynamic placement and status states.
var x: int = 0
var y: int = 0
var rotation: int = 0 # 0, 90, 180, 270
var current_cooldown: int = 100
var synergy_cooldown_reduction: int = 0
var is_broken: bool = false
var freeze_ticks: int = 0

# 실행: initialize the artifact with raw table dictionary.
func _init(data: Dictionary) -> void:
	id = str(data.get("id", ""))
	name = str(data.get("name", ""))
	shape = data.get("shape", [[1]]).duplicate(true)
	energy_type = str(data.get("energyType", ""))
	base_cooldown_ticks = maxi(1, int(data.get("baseCooldownTicks", 100)))
	effective_cooldown = base_cooldown_ticks
	
	# Load raw synergy config if present
	var synergy_raw = data.get("synergy", "")
	if synergy_raw is Dictionary:
		synergy = JSON.stringify(synergy_raw)
	else:
		synergy = str(synergy_raw)
		
	keyword = str(data.get("keyword", ""))
	damage = float(data.get("damage", 1.0))
	grade = str(data.get("grade", "basic"))
	item_type = str(data.get("item_type", data.get("itemType", "drill")))
	x = int(data.get("x", 0))
	y = int(data.get("y", 0))
	rotation = int(data.get("rotation", 0))
	current_cooldown = int(data.get("currentCooldown", base_cooldown_ticks))
	synergy_cooldown_reduction = int(data.get("synergyCooldownReduction", 0))
	is_broken = bool(data.get("isBroken", false))
	freeze_ticks = int(data.get("freezeTicks", 0))

# 실행: progress the cooldown tick and return generated energy color if ready.
func tick() -> Variant:
	if is_broken:
		return null
	if freeze_ticks > 0:
		freeze_ticks -= 1
		return null
	if item_type == "beacon":
		return null
		
	current_cooldown -= 1
	if current_cooldown <= 0:
		current_cooldown = maxi(1, base_cooldown_ticks - synergy_cooldown_reduction)
		return energy_type
	return null

# 실행: rotate the artifact shape 90 degrees clockwise and update rotation state.
func rotate_shape() -> void:
	var rows: int = shape.size()
	var cols: int = shape[0].size() if rows > 0 else 0
	var rotated: Array = []
	for c in range(cols):
		var new_row: Array = []
		for r in range(rows - 1, -1, -1):
			new_row.append(shape[r][c])
		rotated.append(new_row)
	shape = rotated
	rotation = (rotation + 90) % 360

# 실행: export the artifact state to a clean dictionary snapshot.
func to_dict() -> Dictionary:
	return {
		"id": id,
		"name": name,
		"shape": shape.duplicate(true),
		"energyType": energy_type,
		"baseCooldownTicks": base_cooldown_ticks,
		"effectiveCooldown": maxi(1, base_cooldown_ticks - synergy_cooldown_reduction),
		"synergy": synergy,
		"keyword": keyword,
		"x": x,
		"y": y,
		"rotation": rotation,
		"currentCooldown": current_cooldown,
		"synergyCooldownReduction": synergy_cooldown_reduction,
		"isBroken": is_broken,
		"freezeTicks": freeze_ticks,
		"damage": damage,
		"grade": grade,
		"item_type": item_type,
		"itemType": item_type
	}

# 실행: generate static default drills
static func get_basic_drills() -> Array:
	var ArtifactScript = load("res://src/models/Artifact.gd")
	var ruby = ArtifactScript.new({
		"id": "drill_ruby",
		"name": "Ruby Drill",
		"shape": [[1], [1], [1]],
		"energyType": "red",
		"baseCooldownTicks": 80,
		"damage": 1.5,
		"grade": "Basic",
		"item_type": "drill"
	})
	var sapphire = ArtifactScript.new({
		"id": "drill_sapphire",
		"name": "Sapphire Drill",
		"shape": [[1], [1]],
		"energyType": "blue",
		"baseCooldownTicks": 60,
		"damage": 1.2,
		"grade": "Basic",
		"item_type": "drill"
	})
	var amethyst = ArtifactScript.new({
		"id": "drill_amethyst",
		"name": "Amethyst Drill",
		"shape": [[1, 1], [1, 0]],
		"energyType": "purple",
		"baseCooldownTicks": 100,
		"damage": 1.0,
		"grade": "Basic",
		"item_type": "drill"
	})
	var emerald = ArtifactScript.new({
		"id": "drill_emerald",
		"name": "Emerald Drill",
		"shape": [[1, 1], [1, 1]],
		"energyType": "green",
		"baseCooldownTicks": 120,
		"damage": 0.8,
		"grade": "Basic",
		"item_type": "drill"
	})
	return [ruby, sapphire, amethyst, emerald]
