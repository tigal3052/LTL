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
var catalog_id: String = ""
var fusion_key: String = ""
var instance_id: String = ""
var visual_id: String = ""
var roll_quality: int = -1
var stat_roll: Dictionary = {}
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
	catalog_id = str(data.get("catalogId", data.get("catalog_id", "")))
	fusion_key = str(data.get("fusionKey", data.get("fusion_key", "")))
	instance_id = str(data.get("instanceId", data.get("instance_id", "")))
	visual_id = str(data.get("visualId", data.get("visual_id", "")))
	roll_quality = int(data.get("rollQuality", data.get("roll_quality", -1)))
	var roll_data = data.get("statRoll", data.get("stat_roll", {}))
	stat_roll = roll_data.duplicate(true) if roll_data is Dictionary else {}
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
		"catalogId": catalog_id,
		"fusionKey": fusion_key,
		"instanceId": instance_id,
		"visualId": visual_id,
		"visual_id": visual_id,
		"rollQuality": roll_quality,
		"roll_quality": roll_quality,
		"statRoll": stat_roll.duplicate(true),
		"stat_roll": stat_roll.duplicate(true),
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
		"damage": 1.9,
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
		"damage": 1.55,
		"grade": "Basic",
		"item_type": "drill"
	})
	var amethyst = ArtifactScript.new({
		"id": "drill_amethyst",
		"name": "Amethyst Drill",
		"shape": [[1, 1], [1, 0]],
		"energyType": "purple",
		"baseCooldownTicks": EnergyTempoBalanceScript.native_cooldown_ticks(110),
		"nativeBaseCooldownTicks": EnergyTempoBalanceScript.native_cooldown_ticks(110),
		"damage": 0.85,
		"grade": "Basic",
		"item_type": "drill"
	})
	var emerald = ArtifactScript.new({
		"id": "drill_emerald",
		"name": "Emerald Drill",
		"shape": [[1, 1], [1, 1]],
		"energyType": "green",
		"baseCooldownTicks": EnergyTempoBalanceScript.native_cooldown_ticks(70),
		"nativeBaseCooldownTicks": EnergyTempoBalanceScript.native_cooldown_ticks(70),
		"damage": 1.35,
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
	var beacon_text := _starter_text_block(color, "beacon")
	var beacon_profile := _starter_beacon_profile(color)
	var beacon = Artifact.new({
		"id": "starter_%s_beacon" % color,
		"name": "%s Starter Beacon" % color.capitalize(),
		"shape": [[1]],
		"energyType": color,
		"baseCooldownTicks": EnergyTempoBalanceScript.native_cooldown_ticks(int(beacon_profile.get("cooldown", 90))),
		"nativeBaseCooldownTicks": EnergyTempoBalanceScript.native_cooldown_ticks(int(beacon_profile.get("cooldown", 90))),
		"damage": 0.0,
		"grade": "Basic",
		"item_type": "beacon",
		"beaconCooldownMod": EnergyTempoBalanceScript.scaled_beacon_cooldown_mod(int(beacon_profile.get("cooldownMod", -4))),
		"beaconDamageMod": float(beacon_profile.get("damageMod", 0.3)),
		"text": beacon_text,
		"keyword": _starter_keyword(beacon_text)
	})
	return [drill, beacon]

# 실행: keep unsupported start colors deterministic instead of producing empty inventories.
static func get_starter_loadout_positions() -> Array:
	return [Vector2(2, 2), Vector2(3, 2)]

static func _starter_drill_from(base_drill: Artifact) -> Artifact:
	var drill_text := _starter_text_block(base_drill.energy_type, "drill")
	return Artifact.new({
		"id": "starter_%s_drill" % base_drill.energy_type,
		"name": "%s Starter Drill" % base_drill.energy_type.capitalize(),
		"shape": [[1]],
		"energyType": base_drill.energy_type,
		"baseCooldownTicks": base_drill.base_cooldown_ticks,
		"nativeBaseCooldownTicks": base_drill.native_base_cooldown_ticks,
		"damage": base_drill.base_damage,
		"grade": base_drill.grade,
		"item_type": "drill",
		"text": drill_text,
		"keyword": _starter_keyword(drill_text)
	})

static func _starter_beacon_profile(color: String) -> Dictionary:
	match _normalized_start_color(color):
		"red":
			return {"cooldown": 82, "cooldownMod": -5, "damageMod": 0.35}
		"blue":
			return {"cooldown": 78, "cooldownMod": -5, "damageMod": 0.45}
		"purple":
			return {"cooldown": 104, "cooldownMod": -2, "damageMod": 0.18}
		"green":
			return {"cooldown": 82, "cooldownMod": -5, "damageMod": 0.35}
	return {"cooldown": 82, "cooldownMod": -5, "damageMod": 0.35}

static func _normalized_start_color(start_color: String) -> String:
	var color := start_color.to_lower()
	if color in ["red", "blue", "purple", "green"]:
		return color
	return "red"

static func _starter_text_block(color: String, item_type: String) -> Dictionary:
	var color_key := _normalized_start_color(color)
	var ko_color: String = {"red": "붉은", "blue": "푸른", "purple": "보라", "green": "초록"}.get(color_key, "붉은")
	var en_color: String = {"red": "Red", "blue": "Blue", "purple": "Purple", "green": "Green"}.get(color_key, "Red")
	var ko_identity: String = {
		"red": "붉은 계열은 높은 피해와 과열 압박, 지연 후 폭발 보상을 다룹니다.",
		"blue": "푸른 계열은 보호막 제어와 주기 안정화, 완만한 운영을 다룹니다.",
		"purple": "보라 계열은 표식, 메아리, 약화 지형, 위치 연계를 다룹니다.",
		"green": "초록 계열은 지속 화력, 회복 흐름, 넓은 점유를 다룹니다."
	}.get(color_key, "붉은 계열은 높은 피해와 과열 압박, 지연 후 폭발 보상을 다룹니다.")
	var en_identity: String = {
		"red": "focuses on high damage, overheat pressure, and delay-for-burst rewards.",
		"blue": "focuses on shield control, steady cooldown pacing, and safer sequencing.",
		"purple": "focuses on marks, echoes, weakened terrain, and positional links.",
		"green": "focuses on sustained output, recovery flow, and broad board coverage."
	}.get(color_key, "focuses on high damage, overheat pressure, and delay-for-burst rewards.")
	if item_type == "beacon":
		return {
			"name": {"ko": "%s 시작 비콘" % ko_color, "en": "%s Starter Beacon" % en_color},
			"description": {
				"ko": "%s 시작 비콘 · 기본 비콘 유물입니다. %s 인접한 같은 색 유물의 쿨타임과 피해 보정을 조절해 시작 드릴을 안정적으로 보조합니다." % [ko_color, ko_identity],
				"en": "%s Starter Beacon · A basic beacon artifact that %s It supports adjacent same-color artifacts with cooldown and damage tuning for the opening backpack layout." % [en_color, en_identity]
			}
		}
	return {
		"name": {"ko": "%s 시작 드릴" % ko_color, "en": "%s Starter Drill" % en_color},
		"description": {
			"ko": "%s 시작 드릴 · 기본 드릴 유물입니다. %s 직접 공격과 같은 색 에너지 생산의 기본 흐름을 익히기 위한 시작 장비입니다." % [ko_color, ko_identity],
			"en": "%s Starter Drill · A basic drill artifact that %s It teaches the opening loop of direct attacks and same-color energy generation." % [en_color, en_identity]
		}
	}

static func _starter_keyword(text_block: Dictionary) -> String:
	var descriptions = text_block.get("description", {})
	if descriptions is Dictionary:
		var english := str(descriptions.get("en", descriptions.get("ko", ""))).strip_edges()
		if not english.is_empty():
			return english
	return ""
