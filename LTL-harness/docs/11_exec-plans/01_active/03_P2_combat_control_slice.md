# P2. 전투 조작 슬라이스

## 목표

플레이어가 7:3 화면에서 3x10 지형을 읽고 직접 조준/발사하는 체감을 검증한다.

## 산출물

- `PrototypeMain.tscn`
- `PrototypeController.gd`
- `PrototypeHUD.gd`
- 3x10 terrain view
- queue/pin/repair HUD
- scene smoke 테스트 또는 수동 QA 체크리스트

## TDD/QA 대상

- hover 시 항상 셀 1개만 target 된다.
- 클릭 1회가 input log 1개와 shot 1개로 기록된다.
- hold fire는 0.1초 간격을 지킨다.
- 비활성 타일 피격은 HUD에서 무효 피드백을 준다.
- 큐가 비면 발사 실패와 내구도 손실 피드백을 준다.

## 완료 기준

- 모든 셀 hover/클릭이 도메인 좌표와 일치한다.
- P1 replay fixture를 화면 입력 없이도 계속 통과한다.
- 1분짜리 수동 플레이에서 clear 또는 time_over가 정상 발생한다.
