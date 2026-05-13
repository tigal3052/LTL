# P0. 테스트 하네스와 로그 기반

## 목표

모든 핵심 결과를 seed와 input log로 재현할 수 있게 만드는 기반 단계입니다. 화면이 없어도 같은 입력이면 같은 결과가 나와야 합니다.

## 선행 조건

- Godot 4.3 프로젝트 생성
- GUT 설치 또는 설치 계획 확정
- `prototype/data`, `prototype/telemetry`, `tests/unit`, `tests/integration`, `tests/fixtures` 폴더 생성

## 산출물

- `PrototypeTuning.json`
- `Telemetry.gd`
- `RunSeed.gd` 또는 seed helper
- input log 포맷 문서/fixture
- replay runner 초안
- telemetry 필수 필드 테스트

## TDD 대상

- 동일 seed로 10회 실행 시 노드 생성 결과 동일
- 동일 seed + 동일 input log로 10회 replay 시 결과 동일
- telemetry 필수 필드 누락 시 테스트 실패
- replay 결과 비교 시 `result`, `clear_time_sec`, `queue_wasted`, `durability_loss_count`를 비교

## 완료 기준

- P0 fixture 2개 이상 존재: `basic_clear`, `empty_queue_repair`
- headless 테스트 명령으로 unit/integration 테스트가 실행된다
- telemetry에 필수 필드가 모두 기록된다
- 이후 P1 도메인 구현이 P0 replay runner를 사용할 수 있다
