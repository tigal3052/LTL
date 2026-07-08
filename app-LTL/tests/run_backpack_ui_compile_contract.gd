# 계약:
# - 책임: BackpackUI 스크립트가 독립적으로 컴파일되고 핀 오버레이 헬퍼를 유지하는지 검증한다.
# - 입력: `BackpackUI.gd` preload 결과와 최소 인스턴스.
# - 출력: 성공 시 `BACKPACK_UI_COMPILE_CONTRACT_OK`, 실패 시 오류와 종료 코드 1.
# - 금지: 메인 씬 로딩, 전투 상태 변경, 보상 연출 관련 우회 검증.
#
# 실행: preload와 최소 인스턴스로 BackpackUI 핀 헬퍼 계약을 검증한다.
extends SceneTree

const BackpackUIScript = preload("res://src/ui/BackpackUI.gd")

func _init() -> void:
	if BackpackUIScript == null:
		push_error("backpack ui compile contract failed to preload BackpackUI.gd")
		quit(1)
		return
	var backpack_ui = BackpackUIScript.new()
	if backpack_ui == null:
		push_error("backpack ui compile contract failed to instantiate BackpackUI.gd")
		quit(1)
		return
	if not backpack_ui.has_method("_setup_pin_overlays"):
		push_error("backpack ui compile contract missing _setup_pin_overlays helper")
		backpack_ui.free()
		quit(1)
		return
	if not backpack_ui.has_method("_layout_pin_overlays"):
		push_error("backpack ui compile contract missing _layout_pin_overlays helper")
		backpack_ui.free()
		quit(1)
		return
	backpack_ui.free()
	print("BACKPACK_UI_COMPILE_CONTRACT_OK")
	quit(0)
