# M8. Vertical Slice

## 목표

시작, 전투, 보상, 노드 선택, 성장, 실패/재도전을 한 흐름으로 플레이 가능한 세로 조각을 완성한다.

## 산출물

- playable vertical slice build
- regression suite
- QA report
- known issues list

## QA 대상

- 새 런 시작부터 3스테이지 종료까지 진행 가능
- clear/time_over/retry flow 정상
- 보상 선택 후 다음 전투 반영
- telemetry export 정상

## 완료 기준

- 내부 플레이 3회 이상에서 진행 불능 버그가 없다.
- P0~M7 핵심 회귀 테스트가 통과한다.
