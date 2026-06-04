# 계약:
# - 책임: 개별 유물의 상태(ID, 이름, 모양, 쿨타임, 시너지 키워드 등) 및 회전을 관리하는 사물 모델 계약을 제공한다.
# - 입력: 유물 속성 정보 Dictionary.
# - 출력: 유물의 상태 조회 및 회전된 형상 데이터.
# - 금지: SceneTree 접근, 타 유물 상태 직접 변경.
#
# 실행: define the Artifact class identity.
class_name Artifact
extends RefCounted

const EnergyTempoBalanceScript = preload("res://src/balance/EnergyTempoBalance.gd")

# 실행: store individual artifact attributes.
var id: String = ""
var name: String = ""
var shape: Array = []
var energy_type: String = ""
var base_cooldown_ticks: int = 1
var native_base_cooldown_ticks: int = 1
var effective_cooldown: int = 1
var synergy: String = ""
var keyword: String = ""
var damage: float = 1.0
var base_damage: float = 1.0
var grade: String = "basic"
var item_type: String = "drill"
var beacon_cooldown_mod: int = 0
var beacon_damage_mod: float = 0.0
var effect_schema: Dictionary = {}
var text: Dictionary = {}

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
	base_cooldown_ticks = maxi(1, int(data.get("baseCooldownTicks", data.get("base_cooldown_ticks", 100))))
	native_base_cooldown_ticks = maxi(1, int(data.get("nativeBaseCooldownTicks", data.get("native_base_cooldown_ticks", base_cooldown_ticks))))
	effective_cooldown = base_cooldown_ticks
	
	# Load raw synergy config if present
	var synergy_raw = data.get("synergy", "")
	if synergy_raw is Dictionary:
		synergy = JSON.stringify(synergy_raw)
	else:
		synergy = str(synergy_raw)
		
	keyword = str(data.get("keyword", ""))
	base_damage = float(data.get("base_damage", data.get("baseDamage", data.get("damage", 1.0))))
	damage = base_damage
	grade = str(data.get("grade", "basic"))
	item_type = str(data.get("item_type", data.get("itemType", "drill")))
	beacon_cooldown_mod = int(data.get("beacon_cooldown_mod", data.get("beaconCooldownMod", 0)))
	beacon_damage_mod = float(data.get("beacon_damage_mod", data.get("beaconDamageMod", 0.0)))
	var schema = data.get("effect_schema", data.get("effectSchema", {}))
	effect_schema = schema.duplicate(true) if schema is Dictionary else {}
	var localized_text = data.get("text", {})
	text = localized_text.duplicate(true) if localized_text is Dictionary else {}
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
	if item_type == "beacon" or item_type == "relic":
		return null
		
	current_cooldown -= 1
	if current_cooldown <= 0:
		current_cooldown = maxi(1, base_cooldown_ticks - synergy_cooldown_reduction)
		return energy_type
	return null

# 실행: progress a beacon cooldown and report whether its pulse is ready.
func tick_beacon() -> bool:
	if is_broken or item_type != "beacon":
		return false
	if freeze_ticks > 0:
		freeze_ticks -= 1
		return false
	current_cooldown -= 1
	if current_cooldown <= 0:
		current_cooldown = maxi(1, base_cooldown_ticks)
		return true
	return false

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
		"nativeBaseCooldownTicks": native_base_cooldown_ticks,
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
		"base_damage": base_damage,
		"grade": grade,
		"item_type": item_type,
		"itemType": item_type,
		"native_base_cooldown_ticks": native_base_cooldown_ticks,
		"beacon_cooldown_mod": beacon_cooldown_mod,
		"beacon_damage_mod": beacon_damage_mod,
		"effect_schema": effect_schema.duplicate(true),
		"text": text.duplicate(true)
	}

# 실행: generate static default drills
static func get_basic_drills() -> Array:
	var ArtifactScript = load("res://src/models/Artifact.gd")
	var ruby = ArtifactScript.new({
		"id": "drill_ruby",
		"name": "Ruby Drill",
		"shape": [[1], [1], [1]],
		"energyType": "red",
		"baseCooldownTicks": EnergyTempoBalanceScript.native_cooldown_ticks(80),
		"nativeBaseCooldownTicks": EnergyTempoBalanceScript.native_cooldown_ticks(80),
		"damage": 1.5,
		"grade": "Basic",
		"item_type": "drill"
	})
	var sapphire = ArtifactScript.new({
		"id": "drill_sapphire",
		"name": "Sapphire Drill",
		"shape": [[1], [1]],
		"energyType": "blue",
		"baseCooldownTicks": EnergyTempoBalanceScript.native_cooldown_ticks(60),
		"nativeBaseCooldownTicks": EnergyTempoBalanceScript.native_cooldown_ticks(60),
		"damage": 1.2,
		"grade": "Basic",
		"item_type": "drill"
	})
	var amethyst = ArtifactScript.new({
		"id": "drill_amethyst",
		"name": "Amethyst Drill",
		"shape": [[1, 1], [1, 0]],
		"energyType": "purple",
		"baseCooldownTicks": EnergyTempoBalanceScript.native_cooldown_ticks(100),
		"nativeBaseCooldownTicks": EnergyTempoBalanceScript.native_cooldown_ticks(100),
		"damage": 1.0,
		"grade": "Basic",
		"item_type": "drill"
	})
	var emerald = ArtifactScript.new({
		"id": "drill_emerald",
		"name": "Emerald Drill",
		"shape": [[1, 1], [1, 1]],
		"energyType": "green",
		"baseCooldownTicks": EnergyTempoBalanceScript.native_cooldown_ticks(120),
		"nativeBaseCooldownTicks": EnergyTempoBalanceScript.native_cooldown_ticks(120),
		"damage": 0.8,
		"grade": "Basic",
		"item_type": "drill"
	})
	return [ruby, sapphire, amethyst, emerald]

# 실행: generate one selected-color drill and one adjacent support beacon for a new run.
static func get_starter_loadout(start_color: String = "red") -> Array:
	var color := _normalized_start_color(start_color)
	var base_drill = null
	for candidate in get_basic_drills():
		if candidate.energy_type == color:
			base_drill = candidate
			break
	if base_drill == null:
		base_drill = get_basic_drills()[0]
	var drill = _starter_drill_from(base_drill)
	var beacon = Artifact.new({
		"id": "starter_%s_beacon" % color,
		"name": "%s Starter Beacon" % color.capitalize(),
		"shape": [[1]],
		"energyType": color,
		"baseCooldownTicks": EnergyTempoBalanceScript.native_cooldown_ticks(90),
		"nativeBaseCooldownTicks": EnergyTempoBalanceScript.native_cooldown_ticks(90),
		"damage": 0.0,
		"grade": "Basic",
		"item_type": "beacon",
		"beaconCooldownMod": EnergyTempoBalanceScript.scaled_beacon_cooldown_mod(-4),
		"beaconDamageMod": 0.4
	})
	return [drill, beacon]

# 실행: keep unsupported start colors deterministic instead of producing empty inventories.
static func get_starter_loadout_positions() -> Array:
	return [Vector2(2, 2), Vector2(3, 2)]

static func _starter_drill_from(base_drill: Artifact) -> Artifact:
	return Artifact.new({
		"id": "starter_%s_drill" % base_drill.energy_type,
		"name": "%s Starter Drill" % base_drill.energy_type.capitalize(),
		"shape": [[1]],
		"energyType": base_drill.energy_type,
		"baseCooldownTicks": base_drill.base_cooldown_ticks,
		"nativeBaseCooldownTicks": base_drill.native_base_cooldown_ticks,
		"damage": base_drill.base_damage,
		"grade": base_drill.grade,
		"item_type": "drill"
	})

static func _normalized_start_color(start_color: String) -> String:
	var color := start_color.to_lower()
	if color in ["red", "blue", "purple", "green"]:
		return color
	return "red"
