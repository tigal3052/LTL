# 계약:
# - 책임: scene snapshot과 overlay flag를 받아 화면 가시성/타이머 label 모델로 변환한다.
# - 입력: scene Dictionary, victory overlay flag.
# - 출력: UI node에 적용 가능한 primitive Dictionary.
# - 금지: Control node 생성, SceneTree 접근, gameplay state 변경.
#
# 실행: define a stateless presenter for main phase layout.
class_name PhaseLayoutPresenter
extends RefCounted

const TextCatalogScript = preload("res://src/ui/TextCatalog.gd")
const RewardCeremonyPolicyScript = preload("res://src/ui/presenters/RewardCeremonyPolicy.gd")

static func project(scene: Dictionary, _show_victory_overlay: bool) -> Dictionary:
	var phase := str(scene.get("phase", "unknown"))
	var explicit_page_id := scene.has("pageId")
	var page_id := _effective_page_id(scene, phase)
	var reward_ceremony_active := RewardCeremonyPolicyScript.is_active_scene(scene)
	var target: Dictionary = scene.get("targetPanel", {})
	var time_limit := float(target.get("timeLimitTicks", 2400.0))
	var elapsed := float(target.get("elapsedTicks", 0.0))
	var time_left = max(0.0, time_limit - elapsed)
	var seconds_left := int(time_left / 20.0)
	var minutes := seconds_left / 60
	var seconds := seconds_left % 60
	var phase_label := _page_label(page_id, phase, explicit_page_id)
	var meta_page := page_id in ["character_select", "leviathan_select", "story_scene", "defeat", "clear"]
	var is_node_select := page_id == "node_select"
	var combat_page := page_id in ["battle", "boss_battle"]
	var reward_page := page_id in ["reward", "boss_reward"]
	var allow_start_color_selection := RewardCeremonyPolicyScript.allow_start_color_selection(scene)
	return {
		"phaseText": TextCatalogScript.t("phase.label", [phase_label]),
		"stageText": "" if meta_page else TextCatalogScript.t("stage.label", [int(scene.get("stageIndex", 0)) + 1, maxi(1, int(scene.get("maxStages", 1)))]),
		"headerVisible": not meta_page and not is_node_select,
		"nodeSelectVisible": is_node_select,
		"nodeMapFullPage": is_node_select,
		"activePhaseStretchRatio": 7.0 if is_node_select else 1.0,
		"topContentVisible": combat_page or reward_ceremony_active,
		"backpackVisible": combat_page or reward_ceremony_active,
		"backpackCooldownVisible": phase == "combat" and combat_page,
		"sidebarsVisible": combat_page or reward_ceremony_active,
		"leftColumnTopStretchRatio": 0.0,
		"backpackTopStretchRatio": 0.0,
		"rightSidebarTopStretchRatio": 1.0,
		"nodeSelectBackpackDock": "hidden" if is_node_select else "top",
		"rewardBackpackDock": reward_page and not reward_ceremony_active,
		"allowStartColorSelection": allow_start_color_selection,
		"nodeMapStretchRatio": 0.0 if is_node_select else 1.00,
		"backpackStretchRatio": 0.00,
		"battlefieldVisible": combat_page or reward_ceremony_active,
		"rewardVisible": reward_page and not reward_ceremony_active,
		"statusVisible": combat_page or reward_ceremony_active,
		"shopButtonVisible": false,
		"closeShop": not is_node_select,
		"actionBarVisible": not meta_page and not reward_page,
		"giantTimerVisible": false,
		"timerText": "%02d:%02d" % [minutes, seconds],
		"timeLeft": time_left,
		"timeLimit": time_limit,
		"vignetteVisible": phase == "combat" and combat_page and time_left <= 200.0,
		"combatTimeActive": combat_page or reward_ceremony_active
	}

static func _effective_page_id(scene: Dictionary, phase: String) -> String:
	if scene.has("pageId"):
		return str(scene.get("pageId", phase))
	match phase:
		"combat":
			return "battle"
		"reward_loot":
			return "reward"
		"run_complete":
			return "defeat" if bool(scene.get("failed", false)) else "clear"
		_:
			return phase

static func _page_label(page_id: String, phase: String, explicit_page_id: bool) -> String:
	if not explicit_page_id:
		return TextCatalogScript.t("phase.%s" % phase)
	match page_id:
		"character_select":
			return "Character Select"
		"leviathan_select":
			return "Leviathan Select"
		"story_scene":
			return "Story"
		"node_select":
			return TextCatalogScript.t("phase.node_select")
		"battle":
			return "Battle"
		"boss_battle":
			return "Boss Battle"
		"reward":
			return TextCatalogScript.t("phase.reward_loot")
		"boss_reward":
			return "Boss Reward"
		"defeat":
			return "Defeat"
		"clear":
			return "Run Clear"
		_:
			return TextCatalogScript.t("phase.%s" % phase)
