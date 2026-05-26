# Comment Gate Ledger

date: 2026-05-26
task: main-decoupling
phase: implementation-approved
approval: approved
targets:
  - app-LTL/src/MainController.gd
  - app-LTL/src/ui/MainUI.gd

## Contract Summary

- `MainUI.gd` (패시브 뷰): 씬 노드 및 UI 레이아웃의 상태 표현과 사용자 입력을 오케스트레이터로 전달하는 신호(signals)와 프레젠테이션 렌더링에만 집중합니다. 비즈니스 로직이나 시뮬레이터 클래스 참조를 절대 가지지 않습니다.
- `MainController.gd` (오케스트레이터): UI에 종속되지 않고 비즈니스 시뮬레이터(`CombatScenePreviewController`) 및 인벤토리 모델(`InventoryModel`) 간의 조율만 담당합니다.

## Execution Scope

- `MainUI.gd`: `@onready var` 선언, 사용자 조작에 따른 시그널 방출, `render_scene_state`, `render_rewards_state`, `render_backpack`, VFX/화면 흔들림 대행 처리.
- `MainController.gd`: `MainUI` 시그널 수신, `preview_controller` 연동, 인벤토리 배치 연산 및 상태 업데이트 조율.

## Advancement Rule

- next_phase: runtime-verification
- required_user_request: explicit
