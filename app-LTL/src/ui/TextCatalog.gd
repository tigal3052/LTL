# 계약:
# - 책임: UI에 표시되는 문장을 locale key 기반 동적 텍스트로 변환하는 단일 카탈로그 경계를 제공한다.
# - 입력: text key, locale, 선택적 format 인자.
# - 출력: 현재 locale에 맞는 표시 문자열.
# - 금지: gameplay 상태 변경, Control node 직접 접근, 파일 시스템 접근.
#
# 실행: define the locale-aware text catalog.
class_name TextCatalog
extends RefCounted

static var _locale: String = "ko"

const STRINGS := {
	"ko": {
		"action.start": "전투 시작",
		"action.reset": "탐사 초기화",
		"action.hold_fire": "연속 발사",
		"action.repair": "수리 시작",
		"action.claim_rewards": "보상 확정",
		"action.settings": "설정",
		"action.shop": "상점",
		"action.close": "닫기",
		"action.main_menu": "메인 메뉴",
		"action.apply_close": "적용 후 닫기",
		"settings.title": "시스템 설정",
		"settings.gameplay": "플레이 설정",
		"settings.screenshake": "화면 흔들림과 피격 섬광",
		"settings.screen": "화면 설정",
		"settings.fullscreen": "전체 화면",
		"settings.sound": "소리 설정",
		"settings.language": "언어",
		"settings.language.ko": "한국어",
		"settings.language.en": "English",
		"phase.label": "단계: {0}",
		"phase.unknown": "알 수 없음",
		"phase.node_select": "노드 선택",
		"phase.combat": "전투",
		"phase.reward_loot": "보상 정리",
		"phase.run_complete": "탐사 종료",
		"stage.label": "스테이지 {0} / {1}",
		"node.select.empty": "노드 선택\n선택 가능한 후보가 없습니다.",
		"node.select.header": "노드 선택\n경로를 고른 뒤 전투 시작을 누르세요:\n\n{0}",
		"node.card": "{0}  [{1}]  위험: {2}  보상: {3}",
		"node.selected": "> {0} (선택됨)",
		"reward.empty": "남은 보상이 없습니다. '보상 확정'을 눌러 다음 노드를 선택하세요.",
		"reward.holding": " [들고 있음]",
		"discard.idle": "버리기 구역\n[보상이나 백팩 아이템을 선택한 뒤 여기에 놓으세요]",
		"discard.active": "버리기 구역\n[클릭하면 {0}을(를) 버립니다]",
		"tooltip.energy": "에너지",
		"tooltip.cooldown": "쿨타임",
		"tooltip.damage": "피해",
		"tooltip.synergy_cdr": "시너지 쿨감",
		"tooltip.beacon_effects": "비콘 충전 효과",
		"tooltip.reward_artifact": "보상 유물",
		"tooltip.equipped_artifact": "현재 장착",
		"tooltip.no_same_color_drill": "같은 색상 장착 드릴 없음",
		"rarity.basic": "기본",
		"rarity.common": "일반",
		"rarity.rare": "희귀",
		"rarity.epic": "영웅",
		"rarity.legendary": "전설",
		"rarity.mythic": "신화",
		"item.drill": "드릴",
		"item.beacon": "비콘",
		"color.red": "빨강",
		"color.blue": "파랑",
		"color.purple": "보라",
		"color.green": "초록"
	},
	"en": {
		"action.start": "Start Combat",
		"action.reset": "Reset Run",
		"action.hold_fire": "Hold Fire",
		"action.repair": "Initiate Repair",
		"action.claim_rewards": "Claim Rewards",
		"action.settings": "Settings",
		"action.shop": "Shop",
		"action.close": "Close",
		"action.main_menu": "Main Menu",
		"action.apply_close": "Apply & Close",
		"settings.title": "System Calibration",
		"settings.gameplay": "Gameplay Settings",
		"settings.screenshake": "Enable Screenshake & Hit Flash",
		"settings.screen": "Screen Settings",
		"settings.fullscreen": "Full Screen Mode",
		"settings.sound": "Sound Settings",
		"settings.language": "Language",
		"settings.language.ko": "한국어",
		"settings.language.en": "English",
		"phase.label": "Phase: {0}",
		"phase.unknown": "Unknown",
		"phase.node_select": "Node Select",
		"phase.combat": "Combat",
		"phase.reward_loot": "Reward Loot",
		"phase.run_complete": "Run Complete",
		"stage.label": "Stage {0} / {1}",
		"node.select.empty": "Node Select\nNo candidates available.",
		"node.select.header": "Node Select\nChoose a route, then press Start:\n\n{0}",
		"node.card": "{0}  [{1}]  Risk: {2}  Reward: {3}",
		"node.selected": "> {0} (selected)",
		"reward.empty": "No pending rewards left. Press 'Claim Rewards' to select your next node.",
		"reward.holding": " [HOLDING]",
		"discard.idle": "DISCARD ZONE\n[Select reward or backpack item to drop here]",
		"discard.active": "DISCARD ZONE\n[Click here to discard {0}]",
		"tooltip.energy": "Energy",
		"tooltip.cooldown": "Cooldown",
		"tooltip.damage": "Damage",
		"tooltip.synergy_cdr": "Synergy CDR",
		"tooltip.beacon_effects": "Beacon pulse effect",
		"tooltip.reward_artifact": "Reward Artifact",
		"tooltip.equipped_artifact": "Equipped",
		"tooltip.no_same_color_drill": "No same-color equipped drill",
		"rarity.basic": "Basic",
		"rarity.common": "Common",
		"rarity.rare": "Rare",
		"rarity.epic": "Epic",
		"rarity.legendary": "Legendary",
		"rarity.mythic": "Mythic",
		"item.drill": "Drill",
		"item.beacon": "Beacon",
		"color.red": "Red",
		"color.blue": "Blue",
		"color.purple": "Purple",
		"color.green": "Green"
	}
}

# 실행: set the active locale with Korean fallback.
static func set_locale(locale: String) -> void:
	_locale = locale if STRINGS.has(locale) else "ko"

# 실행: return the active locale.
static func locale() -> String:
	return _locale

# 실행: resolve a key and replace numbered placeholders.
static func t(key: String, args: Array = [], locale_override: String = "") -> String:
	var loc := locale_override if STRINGS.has(locale_override) else _locale
	var table: Dictionary = STRINGS.get(loc, STRINGS["ko"])
	var value := str(table.get(key, STRINGS["ko"].get(key, key)))
	for i in range(args.size()):
		value = value.replace("{%d}" % i, str(args[i]))
	return value

# 실행: localize common data-driven item and node names for display.
static func display_name(raw_name: String, locale_override := "") -> String:
	var loc := locale_override if STRINGS.has(locale_override) else _locale
	if loc == "en":
		return raw_name
	var value := raw_name
	var replacements := {
		"Ruby Drill": "루비 드릴",
		"Sapphire Drill": "사파이어 드릴",
		"Amethyst Drill": "자수정 드릴",
		"Emerald Drill": "에메랄드 드릴",
		"Crimson Drill Core": "진홍 드릴 코어",
		"Azure Drill Core": "청명 드릴 코어",
		"Violet Drill Core": "보랏빛 드릴 코어",
		"Verdant Drill Core": "초록 드릴 코어",
		"Rapid Fuel Condenser": "고속 연료 응축기",
		"Resonance Magnet": "공명 자석",
		"Shield Repair Bot": "보호막 수리 봇",
		"Amplifying Cooldown Beacon": "쿨타임 증폭 비콘",
		"Unstable Overcharge Beacon": "불안정 과충전 비콘",
		"Anchor Beacon": "고정 비콘",
		"Legendary Focusing Beacon": "전설 집중 비콘",
		"Safe Scar": "안전한 균열",
		"Red Vein": "붉은 광맥",
		"Mixed Fault": "혼합 단층",
		"Hazard Rich": "위험 밀집지",
		"Repair Event": "수리 이벤트",
		"Spine Anchor": "척추 닻",
		"Normal Node": "일반 노드",
		"Elite Node": "정예 노드"
	}
	for key in replacements:
		value = value.replace(str(key), str(replacements[key]))
	var colors := {"(Red)": "(빨강)", "(Blue)": "(파랑)", "(Purple)": "(보라)", "(Green)": "(초록)"}
	for color_key in colors:
		value = value.replace(str(color_key), str(colors[color_key]))
	return value
