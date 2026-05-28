# 계약:
# - 책임: Main scene에 붙는 안정적인 controller 진입점으로 남고 실제 orchestration은 runtime base script에 위임한다.
# - 입력: MainUI facade에서 방출되는 사용자 intent signal.
# - 출력: runtime base가 처리한 scene state/rendering update.
# - 금지: gameplay 계산, raw run state 직접 변경, reward/artifact 생성, UI text 합성.
#
# 실행: keep the scene-facing controller script as a thin facade.
extends "res://src/MainControllerRuntime.gd"
