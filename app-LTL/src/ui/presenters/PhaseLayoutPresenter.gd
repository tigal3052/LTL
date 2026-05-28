# 계약:
# - 책임: scene snapshot과 overlay flag를 화면 visibility/timer label 모델로 변환한다.
# - 입력: scene Dictionary, victory overlay flag.
# - 출력: UI node에 적용 가능한 primitive Dictionary.
# - 금지: Control node 생성, SceneTree 접근, gameplay state 변경.
#
# 실행: define a stateless presenter for main phase layout.
class_name PhaseLayoutPresenter
extends RefCounted

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
	return {
		"phaseText": "Phase: %s" % phase.capitalize(),
		"stageText": "Stage %d / %d" % [int(scene.get("stageIndex", 0)) + 1, maxi(1, int(scene.get("maxStages", 1)))],
		"nodeSelectVisible": phase == "node_select",
		"battlefieldVisible": phase == "combat" or (phase == "reward_loot" and show_victory),
		"rewardVisible": phase == "reward_loot" and not show_victory,
		"statusVisible": phase == "combat" or (phase == "reward_loot" and show_victory),
		"shopButtonVisible": phase == "node_select",
		"closeShop": phase != "node_select",
		"giantTimerVisible": phase == "combat",
		"timerText": "%02d:%02d" % [minutes, seconds],
		"timeLeft": time_left,
		"timeLimit": time_limit,
		"vignetteVisible": phase == "combat" and time_left <= 200.0,
		"combatTimeActive": phase == "combat"
	}
