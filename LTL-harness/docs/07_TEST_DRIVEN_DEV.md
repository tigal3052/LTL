# Test-Driven Development (TDD) 전략

구현(Exec-Plans)에 들어가기 전에 반드시 참조해야 할 원칙입니다.
- **순수 로직 분리**: 파동 이동, 큐 생성, 데미지 등은 GUT를 활용하여 화면 없이 테스트 가능하게 작성합니다.
- **테스트 우선 (Test-First)**: 마일스톤 진입 시 실패하는 단위 테스트를 먼저 작성하고 최소 구현으로 통과시킵니다.

## TDD 루프

1. 마일스톤 문서에서 완료 기준 하나를 고른다.
2. 해당 기준을 실패하는 GUT 테스트로 작성한다.
3. 최소 구현으로 통과시킨다.
4. seed/replay/telemetry가 영향을 받는지 확인한다.
5. 필요한 경우 데이터 기본값과 문서를 갱신한다.

## 테스트 계층

| 계층 | 위치 | 대상 |
|---|---|---|
| Unit | `tests/unit` | PulseModel, EnergyQueue, MiningResolver, InventoryModel, NodeGenerator |
| Integration | `tests/integration` | RunSimulator, input log replay, telemetry field completeness |
| Scene smoke | `tests/integration` 또는 수동 QA | PrototypeMain, hover, hold fire, HUD state binding |

## 필수 테스트 계약

- 같은 seed의 노드 생성 결과는 항상 같다.
- 같은 seed와 input log의 run result는 항상 같다.
- telemetry 필수 필드는 누락되지 않는다.
- 큐 생성/소비/누수 카운트는 음수가 되지 않는다.
- 타일 비활성화 시간(`0.5초`) 동안 재발사는 무효 판정된다.
- 빈 큐 발사 3회 누적 시 수리 상태가 된다.
- 4핀은 시간 경과로만 소진된다.

## 테스트 fixture 명명

- `fixtures/seeds/basic_seed_1234.json`
- `fixtures/input_logs/basic_clear.json`
- `fixtures/input_logs/empty_queue_repair.json`
- `fixtures/expected_runs/basic_clear_expected.json`

fixture는 사람이 읽을 수 있어야 하며, 실패했을 때 무엇이 바뀌었는지 diff로 판단 가능해야 합니다.
