# 계약:
# - 책임: Main.tscn에 연결된 top-level view facade로 남고 실제 view 구성은 runtime base script에 위임한다.
# - 입력: Godot control input과 controller의 render 명령.
# - 출력: runtime base가 제공하는 signal forwarding과 rendering facade method.
# - 금지: 큰 dynamic panel 생성, gameplay state mutation, phase별 domain decision.
#
# 실행: keep the scene-facing UI script as a thin facade.
extends "res://src/ui/MainViewRuntime.gd"
