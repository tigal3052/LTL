# 계약:
# - 책임: UI에 표시되는 문장을 locale key 기반 동적 텍스트로 제공한다.
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
		"app.title": "레비아탄 채굴 작전",
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
		"action.proceed": "진행하기",
		"action.cancel": "취소",
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
		"node.card.base": "{0}  [{1}]  위험: {2}",
		"node.card.reward": "  보상: {0}",
		"node.card.hint": "  힌트: {0}",
		"node.selected": "> {0} (선택됨)",
		"node.no_weakness": "약점 없음",
		"node.final_distance": "최종 {0}",
		"reward.empty": "남은 보상이 없습니다. '보상 확정'을 눌러 다음 노드를 선택하세요.",
		"reward.holding": " [들고 있음]",
		"discard.idle": "버리기 구역\n[보상이나 백팩 유물을 선택한 뒤 여기에 놓으세요]",
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
		"color.green": "초록",
		"risk.safe": "안전",
		"risk.medium": "보통",
		"risk.hard": "어려움",
		"risk.danger": "위험",
		"risk.support": "지원",
		"risk.unknown": "불명",
		"risk.boss": "보스",
		"reward_bias.baseline": "기본",
		"reward_bias.red_energy": "빨강 에너지",
		"reward_bias.multi_energy": "복합 에너지",
		"reward_bias.rarity_up": "희귀도 상승",
		"reward_bias.repair": "수리",
		"reward_bias.mystery": "미확인 보상",
		"reward_bias.run_clear": "탐사 완료",
		"hint.any_stable_drill_line": "안정적인 드릴 라인",
		"hint.red_pulse_drill": "빨강 드릴 중심",
		"hint.blue_or_purple_coverage": "파랑 또는 보라 대응",
		"hint.repair_ready_queue": "수리 여유 확보",
		"hint.stabilize_damaged_route": "피해 복구 우선",
		"hint.short_volatile_encounter": "짧지만 변칙적인 전투",
		"hint.bring_mixed_coverage": "복합 약점 대응",
		"shop.title": "보정 상점",
		"shop.gold": "골드: {0}",
		"shop.xp": "경험치: {0}",
		"shop.buy": "구매",
		"shop.buy_with_cost": "구매 ({0}골드)",
		"shop.level": "레벨: {0}",
		"passive.starting_gold_boost.name": "초기 골드 증가",
		"passive.starting_gold_boost.desc": "+10 초기 골드. 비용: {0}골드 | 레벨: {1}",
		"passive.cooldown_reduction.name": "드릴 쿨타임 감소",
		"passive.cooldown_reduction.desc": "-5% 드릴 쿨타임. 비용: {0}골드 | 레벨: {1}",
		"passive.aim_damage_boost.name": "조준 피해 증가",
		"passive.aim_damage_boost.desc": "+1 고정 피해. 비용: {0}골드 | 레벨: {1}",
		"status.node": "노드: {0}",
		"status.pin": "고정: {0}",
		"status.repairing": "수리 중...",
		"status.overheated": "과열!",
		"status.normal": "정상",
		"overlay.failed.title": "탐사 실패",
		"overlay.failed.desc": "시간 제한 초과 또는 코어 파괴.\n클릭하면 다시 시작합니다.",
		"overlay.victory.title": "레비아탄 지각 채굴 완료",
		"overlay.victory.desc": "채굴 작전 성공.\n클릭하면 보상을 확인합니다.",
		"overlay.overheat.title": "채굴 드릴 치명적 오류",
		"overlay.overheat.desc": "코어가 과열되어 에너지 큐가 비었습니다.\n드릴 코어를 자동 재구축합니다...",
		"overlay.overheat.rebuilding": "코어가 과열되어 에너지 큐가 비었습니다.\n드릴 코어를 자동 재구축합니다. ({0}초 남음)",
		"confirm.unclaimed.title": "미획득 보상 경고",
		"confirm.unclaimed.desc": "아직 남은 보상이 있습니다. 그래도 진행하시겠습니까?",
		"panel.character_status": "탐사자 상태",
		"panel.profile": "[채굴자 프로필]",
		"panel.loadout": "장비 구성:\n- 기본 드릴 세트\n- 자동 수리 코어\n- 레비아탄 표면 스캐너",
		"panel.drill_node_status": "드릴 및 노드 상태",
		"panel.health": "레비아탄 체력:",
		"panel.shield": "보호막:",
		"panel.queue": "에너지 큐:",
		"panel.stage_timer": "스테이지 제한 시간:",
		"panel.drill_status": "드릴 상태:",
		"panel.backpack": "백팩 엔진 공간 (8x8 격자)",
		"panel.log": "시스템 로그와 정보",
		"panel.log.ready": "시스템 준비 완료.\n노드를 선택하고 전투를 시작하세요.",
		"panel.next_node": "다음 목표 노드",
		"panel.battlefield": "레비아탄 지각 표면 (3x10 격자)",
		"panel.rewards": "회수한 유물 / 보상"
	},
	"en": {
		"app.title": "LOOTING THE LEVIATHAN",
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
		"action.proceed": "Proceed",
		"action.cancel": "Cancel",
		"settings.title": "System Calibration",
		"settings.gameplay": "Gameplay Settings",
		"settings.screenshake": "Screenshake & Hit Flash",
		"settings.screen": "Screen Settings",
		"settings.fullscreen": "Full Screen",
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
		"node.card.base": "{0}  [{1}]  Risk: {2}",
		"node.card.reward": "  Reward: {0}",
		"node.card.hint": "  Hint: {0}",
		"node.selected": "> {0} (selected)",
		"node.no_weakness": "No Weakness",
		"node.final_distance": "Final {0}",
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
		"color.green": "Green",
		"risk.safe": "Safe",
		"risk.medium": "Medium",
		"risk.hard": "Hard",
		"risk.danger": "Danger",
		"risk.support": "Support",
		"risk.unknown": "Unknown",
		"risk.boss": "Boss",
		"reward_bias.baseline": "Baseline",
		"reward_bias.red_energy": "Red Energy",
		"reward_bias.multi_energy": "Multi Energy",
		"reward_bias.rarity_up": "Rarity Up",
		"reward_bias.repair": "Repair",
		"reward_bias.mystery": "Mystery",
		"reward_bias.run_clear": "Run Clear",
		"hint.any_stable_drill_line": "Any stable drill line",
		"hint.red_pulse_drill": "Red pulse drill",
		"hint.blue_or_purple_coverage": "Blue or purple coverage",
		"hint.repair_ready_queue": "Repair-ready queue",
		"hint.stabilize_damaged_route": "Stabilize damaged route",
		"hint.short_volatile_encounter": "Short volatile encounter",
		"hint.bring_mixed_coverage": "Bring mixed coverage",
		"shop.title": "Calibration Shop",
		"shop.gold": "Gold: {0}",
		"shop.xp": "XP: {0}",
		"shop.buy": "Buy",
		"shop.buy_with_cost": "Buy ({0} gold)",
		"shop.level": "Level: {0}",
		"passive.starting_gold_boost.name": "Starting Gold Boost",
		"passive.starting_gold_boost.desc": "+10 starting gold. Cost: {0} gold | Level: {1}",
		"passive.cooldown_reduction.name": "Drill Cooldown Reduction",
		"passive.cooldown_reduction.desc": "-5% drill cooldown. Cost: {0} gold | Level: {1}",
		"passive.aim_damage_boost.name": "Aim Damage Boost",
		"passive.aim_damage_boost.desc": "+1 fixed damage. Cost: {0} gold | Level: {1}",
		"status.node": "Node: {0}",
		"status.pin": "Pins: {0}",
		"status.repairing": "Repairing...",
		"status.overheated": "Overheated!",
		"status.normal": "Normal",
		"overlay.failed.title": "Expedition Failed",
		"overlay.failed.desc": "Time expired or the core was destroyed.\nClick to restart.",
		"overlay.victory.title": "Leviathan Crust Mining Complete",
		"overlay.victory.desc": "Mining operation succeeded.\nClick to reveal rewards.",
		"overlay.overheat.title": "Mining Drill Critical Error",
		"overlay.overheat.desc": "Core overheated. Energy queue depleted.\nRebuilding drill core automatically...",
		"overlay.overheat.rebuilding": "Core overheated. Energy queue depleted.\nRebuilding drill core automatically ({0}s remaining)...",
		"confirm.unclaimed.title": "Unclaimed Reward Warning",
		"confirm.unclaimed.desc": "Some rewards are still unclaimed. Proceed anyway?",
		"panel.character_status": "Explorer Status",
		"panel.profile": "[Miner Profile]",
		"panel.loadout": "Loadout:\n- Basic drill set\n- Auto-repair core\n- Leviathan surface scanner",
		"panel.drill_node_status": "Drill and Node Status",
		"panel.health": "Leviathan Health:",
		"panel.shield": "Shield:",
		"panel.queue": "Energy Queue:",
		"panel.stage_timer": "Stage Time Limit:",
		"panel.drill_status": "Drill Status:",
		"panel.backpack": "Backpack Engine Space (8x8 Grid)",
		"panel.log": "System Log and Info",
		"panel.log.ready": "System ready.\nSelect a node and start combat.",
		"panel.next_node": "Next Target Node",
		"panel.battlefield": "Leviathan Crust Surface (3x10 Grid)",
		"panel.rewards": "Recovered Artifacts / Rewards"
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
	var value := _strip_size_noise(raw_name)
	if loc == "en":
		return value
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
		"Azure Beacon": "청명 비콘",
		"Safe Scar": "안전한 균열",
		"Red Vein": "붉은 광맥",
		"Mixed Fault": "혼합 단층",
		"Hazard Rich": "위험 밀집지",
		"Repair Event": "수리 이벤트",
		"Spine Anchor": "척추 닻",
		"Mysterious Crevice": "신비한 균열",
		"Normal Node": "일반 노드",
		"Elite Node": "정예 노드",
		"Crimson Vein": "진홍 광맥",
		"Azure Fault": "청명 단층",
		"Violet Cluster": "보라 군집",
		"Verdant Core": "초록 핵",
		"Twin Resonance": "쌍둥이 공명"
	}
	for key in replacements:
		value = value.replace(str(key), str(replacements[key]))
	return value

# 실행: localize common descriptions and remove artifact size implementation noise.
static func display_description(raw_description: String, locale_override := "") -> String:
	var loc := locale_override if STRINGS.has(locale_override) else _locale
	var value := _strip_size_noise(raw_description).strip_edges()
	if loc == "ko":
		var replacements := {
			"Pulse support.": "주변 드릴을 주기적으로 지원합니다.",
			"A test beacon": "테스트 비콘",
			"Red pulse drill": "빨강 드릴 중심",
			"Repair-ready queue": "수리 여유 확보"
		}
		for key in replacements:
			value = value.replace(str(key), str(replacements[key]))
	return value.strip_edges()

# 실행: translate enum labels such as risk and reward bias.
static func enum_label(group: String, value: String, locale_override := "") -> String:
	return t("%s.%s" % [group, value.to_lower()], [], locale_override)

# 실행: translate common recommended build hints.
static func hint_label(raw_hint: String, locale_override := "") -> String:
	var normalized := raw_hint.strip_edges().to_lower().replace("-", " ").replace("/", " ").replace(" ", "_")
	return t("hint.%s" % normalized, [], locale_override) if STRINGS.get(locale_override if STRINGS.has(locale_override) else _locale, {}).has("hint.%s" % normalized) else raw_hint

# 실행: remove size phrases from user-facing item names and descriptions.
static func _strip_size_noise(value: String) -> String:
	var result := value
	var regex := RegEx.new()
	if regex.compile("\\b(Compact|Large|Small|Medium)\\s+\\d+x\\d+\\s+module\\.?\\s*") == OK:
		result = regex.sub(result, "", true)
	if regex.compile("\\s*\\(?\\d+x\\d+\\)?\\s*") == OK:
		result = regex.sub(result, " ", true)
	return result.replace("  ", " ").strip_edges()
