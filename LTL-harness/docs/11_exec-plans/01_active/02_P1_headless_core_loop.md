# P1. Headless 코어 루프

## 목표

화면 없이 파동, 에너지 큐, 데미지, 타일 비활성화, 내구도/수리, 4핀 시간 압박이 동작하는 최소 전투 시뮬레이터를 만든다.

## 산출물

- `PulseModel.gd`
- `EnergyQueue.gd`
- `MiningResolver.gd`
- `RunSimulator.gd`
- `tests/unit/test_pulse_model.gd`
- `tests/unit/test_energy_queue.gd`
- `tests/unit/test_mining_resolver.gd`
- `tests/integration/test_run_simulator_replay.gd`

## TDD 대상

- 파동은 fixed tick에 따라 결정적으로 이동한다.
- 큐는 생성, 소비, 누수를 카운트한다.
- 매칭/노멀/미스매치 데미지가 사양대로 계산된다.
- 동일 타일은 피격 후 0.5초 동안 무효 처리된다.
- 빈 큐 발사 3회 누적 시 수리 상태가 된다.
- 4핀은 시간 경과 25/50/75/100%에서 소진된다.
- clear와 time_over 동시 발생 시 clear가 우선한다.

## 완료 기준

- 모든 코어 테스트가 headless로 통과한다.
- `RunSimulator`가 input log를 받아 `clear`, `time_over`, `repair_required` 결과를 재현한다.
- P2 화면 계층이 사용할 snapshot 구조가 정의되어 있다.
