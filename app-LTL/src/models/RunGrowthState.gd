# 계약:
# - 책임: 런 수준의 성장 및 패시브/재화 상태를 관리하고, 이를 수식에 반영할 보조 변경자(Modifiers) 수치를 제공한다.
# - 입력: 초기 상태 Dictionary 또는 획득한 보상/재화 델타.
# - 출력: 현재 패시브 강화 효과가 반영된 변경자 값(시작 골드 부스트, 쿨타임 감소비, 데미지 보너스).
# - 금지: SceneTree 참조, UI 컨트롤 직접 접근.
#
# 실행: define the RunGrowthState class.
class_name RunGrowthState
extends RefCounted

const ReleaseContentVocabScript = preload("res://src/vocabulary/ReleaseContentVocab.gd")

var gold: int = 100
var xp: int = 0
var purchased_passives: Dictionary = {
	"starting_gold_boost": 0,
	"cooldown_reduction": 0,
	"aim_damage_boost": 0
}
var selected_character: String = "miner"
var unlocked_characters: Array = ["miner"]
var unlocked_starter_items: Array = ["starter_drill_red"]
var scan_unlocks: Array = []
var temporary_modifiers: Dictionary = {}
var run_modifiers: Dictionary = {}
var reward_history: Array = []

# 실행: initialize with default values.
func _init(data: Dictionary = {}) -> void:
	from_dict(data)

# 실행: load state from a dictionary.
func from_dict(data: Dictionary) -> void:
	gold = int(data.get("gold", 100))
	xp = int(data.get("xp", 0))
	
	var passives = data.get("purchasedPassives", {})
	if passives is Dictionary:
		for k in purchased_passives.keys():
			if passives.has(k):
				purchased_passives[k] = int(passives[k])
		for k in passives.keys():
			if not purchased_passives.has(k):
				purchased_passives[k] = int(passives[k])

	selected_character = str(data.get("selectedCharacter", selected_character))
	var characters = data.get("unlockedCharacters", unlocked_characters)
	if characters is Array:
		unlocked_characters = characters.duplicate(true)
	var starter_items = data.get("unlockedStarterItems", unlocked_starter_items)
	if starter_items is Array:
		unlocked_starter_items = starter_items.duplicate(true)
	var scans = data.get("scanUnlocks", scan_unlocks)
	if scans is Array:
		scan_unlocks = scans.duplicate(true)
				
	var temp_mods = data.get("temporaryModifiers", {})
	if temp_mods is Dictionary:
		temporary_modifiers = temp_mods.duplicate(true)
		
	var run_mods = data.get("runModifiers", {})
	if run_mods is Dictionary:
		run_modifiers = run_mods.duplicate(true)
		
	var history = data.get("rewardHistory", [])
	if history is Array:
		reward_history = history.duplicate(true)

# 실행: export state to a dictionary.
func to_dict() -> Dictionary:
	return {
		"gold": gold,
		"xp": xp,
		"purchasedPassives": purchased_passives.duplicate(true),
		"selectedCharacter": selected_character,
		"unlockedCharacters": unlocked_characters.duplicate(true),
		"unlockedStarterItems": unlocked_starter_items.duplicate(true),
		"scanUnlocks": scan_unlocks.duplicate(true),
		"temporaryModifiers": temporary_modifiers.duplicate(true),
		"runModifiers": run_modifiers.duplicate(true),
		"rewardHistory": reward_history.duplicate(true)
	}

# 실행: get total starting gold including passive boost.
func get_starting_gold() -> int:
	return 100 + int(purchased_passives.get("starting_gold_boost", 0)) * 10

# 실행: get multiplier for drill cooldown reduction (e.g. 0.95, 0.90).
func get_cooldown_modifier() -> float:
	var lvl = int(purchased_passives.get("cooldown_reduction", 0))
	return clampf(1.0 - (lvl * 0.05), 0.5, 1.0)

# 실행: get base aim damage bonus (adds flat amount to mining damage).
func get_damage_bonus() -> float:
	return float(purchased_passives.get("aim_damage_boost", 0)) * 1.0

# 실행: add gold currency.
func add_gold(amount: int) -> void:
	gold = max(0, gold + amount)

# 실행: add xp.
func add_xp(amount: int) -> void:
	xp = max(0, xp + amount)

# 실행: purchase a passive upgrade if gold is sufficient.
func purchase_passive(passive_id: String, cost: int) -> bool:
	if not purchased_passives.has(passive_id):
		return false
	if gold >= cost:
		gold -= cost
		purchased_passives[passive_id] = purchased_passives[passive_id] + 1
		return true
	return false

# ?ㅽ뻾: purchase a release base shop item and persist its unlock.
func purchase_base_item(item_id: String, bundle: Dictionary = {}) -> bool:
	var content := bundle
	if content.is_empty():
		content = ReleaseContentVocabScript.load_content_bundle()
	var result: Dictionary = ReleaseContentVocabScript.purchase_base_item(to_dict(), item_id, content)
	if not bool(result.get("ok", false)):
		return false
	from_dict(result.get("state", {}))
	return true
