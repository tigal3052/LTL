# 계약:
# - 책임: scene snapshot과 overlay flag를 화면 visibility/timer label 모델로 변환한다.
# - 입력: scene Dictionary, victory overlay flag.
# - 출력: UI node에 적용 가능한 primitive Dictionary.
# - 금지: Control node 생성, SceneTree 접근, gameplay state 변경.
#
# 실행: define a stateless presenter for main phase layout.
class_name PhaseLayoutPresenter
extends RefCounted
const TextCatalogScript = preload("res://src/ui/TextCatalog.gd")

# 실행: project scene state into phase visibility and timer properties.
static func project(scene: Dictionary, show_victory_overlay: bool) -> Dictionary:
	var phase := str(scene.get("phase", "unknown"))
	var is_reveal_vfx_running := bool(scene.get("is_reveal_vfx_running", false))
	var show_victory := show_victory_overlay or is_reveal_vfx_running
	var target: Dictionary = scene.get("targetPanel", {})
	var time_limit := float(target.get("timeLimitTicks", 2400.0))
	var elapsed := float(target.get("elapsedTicks", 0.0))
	var time_left = max(0.0, time_limit - elapsed)
	var seconds_left := int(time_left / 20.0)
	var minutes := seconds_left / 60
	var seconds := seconds_left % 60
	var phase_label := TextCatalogScript.t("phase.%s" % phase)
	var is_node_select := phase == "node_select"
	return {
		"phaseText": TextCatalogScript.t("phase.label", [phase_label]),
		"stageText": TextCatalogScript.t("stage.label", [int(scene.get("stageIndex", 0)) + 1, maxi(1, int(scene.get("maxStages", 1)))]),
		"nodeSelectVisible": is_node_select,
		"nodeMapFullPage": is_node_select,
		"activePhaseStretchRatio": 7.0 if is_node_select else 1.0,
		"topContentVisible": not is_node_select,
		"backpackVisible": true,
		"backpackCooldownVisible": phase == "combat",
		"sidebarsVisible": not is_node_select,
		"leftColumnTopStretchRatio": 2.45,
		"backpackTopStretchRatio": 0.0,
		"rightSidebarTopStretchRatio": 2.35,
		"nodeSelectBackpackDock": "right" if is_node_select else "top",
		"nodeMapStretchRatio": 1.00,
		"backpackStretchRatio": 0.00,
		"battlefieldVisible": phase == "combat" or (phase == "reward_loot" and show_victory),
		"rewardVisible": phase == "reward_loot" and not show_victory,
		"statusVisible": phase == "combat" or (phase == "reward_loot" and show_victory),
		"shopButtonVisible": is_node_select,
		"closeShop": not is_node_select,
		"giantTimerVisible": phase == "combat",
		"timerText": "%02d:%02d" % [minutes, seconds],
		"timeLeft": time_left,
		"timeLimit": time_limit,
		"vignetteVisible": phase == "combat" and time_left <= 200.0,
		"combatTimeActive": phase == "combat"
	}
