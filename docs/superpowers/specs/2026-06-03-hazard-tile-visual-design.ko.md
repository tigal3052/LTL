# 2026-06-03 Hazard Tile Visual Design

Date: 2026-06-03  
Workspace: `LootingTheLeviathan`

## 목표

`red_tile_hazard.png`, `blue_tile_hazard.png`, `purple_tile_hazard.png`, `green_tile_hazard.png` 를 전장 방해요소 UI에 적용한다.  
이번 결정에서는 기존 `warning -> active -> afterglow` 흐름을 유지하지 않고, `spawn 즉시 active` 로 단순화한다.

핵심 목표는 두 가지다.

- hazard 이미지를 기본 타일과 `같은 rect`, `같은 크기`로 정확히 overlay 한다.
- 약점 여부는 `기본 타일 alpha`, hazard 상태는 `hazard alpha` 로 읽히게 만든다.

## 최종 로직 결정

### 1. warning 상태 제거

- runtime obstacle lifecycle 에서 `warning` 상태를 제거한다.
- 새 hazard 는 생성되는 즉시 `active` 상태다.
- 기존 저장 상태나 구버전 snapshot 에 남아 있는 `warning` 은 호환성 차원에서 `active` 처럼 처리한다.

### 2. 생성, 처리, 실패 흐름

- hazard 생성: 바로 `active`
- 사용자가 처리 성공:
  - `afterglowTicks > 0` 이면 `afterglow_clear`
  - `afterglowTicks <= 0` 이면 다음 obstacle tick 에서 즉시 정리
- 처리하지 못하고 오른쪽 끝까지 이동:
  - 해당 family 의 fail effect 발동
  - 그 후 obstacle 은 battlefield 에서 제거

### 3. 오른쪽 끝 fail effect 기준

- `red`: 남은 제한 시간을 깎는다.
- `green`: Leviathan 체력을 회복한다.
- `purple`: pressure pulse 를 발동한다.
- `blue`: 기존 blue obstacle pressure 규칙은 유지하되, 별도 exit fail 수치는 추가하지 않는다.

즉, 이제 hazard 의 실질적인 위협 전달 지점은 `사전 warning` 이 아니라 `active 유지` 와 `right-edge unresolved exit` 다.

## 시각 규칙

### 1. 기본 타일 alpha

- `weakness x`: 기본 타일 alpha `0.5`
- `weakness o`: 기본 타일 alpha `1.0`

weakness 없는 칸이라도 hazard 가 올라온 경우에는 obstacle family 색 타일을 fallback base tile 로 사용해 반투명 상태를 읽을 수 있게 한다.

### 2. hazard overlay 규칙

- hazard PNG 는 기본 타일과 `같은 rect` 에 그린다.
- inset frame, 별도 작은 박스, 오프셋 배치는 쓰지 않는다.
- family 별 hazard PNG 는 아래와 같이 대응한다.
  - `red` -> `red_tile_hazard.png`
  - `blue` -> `blue_tile_hazard.png`
  - `purple` -> `purple_tile_hazard.png`
  - `green` -> `green_tile_hazard.png`

### 3. 상태별 alpha

- `active`: hazard alpha `1.0`
- `afterglow_clear`: `afterglowTicksRemaining / afterglowTicks` 비율을 사용하되 최대 alpha 는 약 `0.22`

`warning` 은 새 runtime state 로는 사용하지 않지만, 구버전 snapshot 호환을 위해 렌더링 시 `active` 와 동일하게 본다.

## 상태 매트릭스

- `weakness x / hazard x`: 기본 타일만 반투명
- `weakness x / hazard active`: 기본 타일 반투명, hazard 100%
- `weakness x / hazard afterglow`: 기본 타일 반투명, hazard 매우 약하게 잔상
- `weakness o / hazard x`: 기본 타일 100%
- `weakness o / hazard active`: 기본 타일 100%, hazard 100%
- `weakness o / hazard afterglow`: 기본 타일 100%, hazard 매우 약하게 잔상

## 렌더 순서

1. 기본 타일 texture
2. hazard overlay texture
3. active 상태 progress bar
4. queue match, hover, aimed, disabled overlay

afterglow 는 active 보다 약한 사각 윤곽과 fade-out 으로만 남기고, 별도 warning 스타일 bracket 은 사용하지 않는다.

## 코드 반영 지점

- `app-LTL/src/vocabulary/CombatVocab.gd`
  - spawn state 를 `active` 로 변경
  - warning countdown 제거
  - afterglow 0 tick 허용
  - paused obstacle tick 중에도 afterglow cleanup 은 계속 진행
  - right-edge unresolved exit 가 family fail effect 의 유일한 발동 지점이 되도록 유지
- `app-LTL/src/ui/CellView.gd`
  - base tile alpha helper 추가
  - hazard alpha helper 추가
  - family hazard PNG overlay 적용
  - 기존 procedural warning/active line art 제거

## 테스트 기준

- 새로 생성된 obstacle 이 즉시 `active` 인가
- `afterglowTicks = 0` 인 clear hazard 가 다음 tick 에 제거되는가
- `purple` hazard 가 오른쪽 끝 unresolved exit 시 pressure pulse 를 일으키는가
- `CellView` 가 weakness 여부에 따라 base tile alpha 를 다르게 계산하는가
- `CellView` 가 active 와 afterglow hazard alpha 를 분명히 다르게 계산하는가

## 결정 상태

- 채택 방향: `active-only hazard lifecycle`
- weakness 가독성 기준: `기본 타일 alpha`
- hazard 상태 가독성 기준: `hazard texture alpha`
- warning 상태: `제거`
