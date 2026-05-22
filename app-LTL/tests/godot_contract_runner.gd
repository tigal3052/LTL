# 계약:
# - 책임: formal contract validator, replay regression, snapshot boundary 검증을 한 번에 실행하는 headless test runner 진입점 계약을 제공한다.
# - M0 반영: P1~P4 fixture 중 승격된 범위의 결과와 snapshot boundary를 formal test suite surface로 묶는다.
# - SoT: M1 TDD targets, comment-first gate ledger, Godot formal stack enforcement.
# - 입력: test fixture set, FormalContracts public API, HeadlessMiniRun public API, ReplayProcess public API, read model public API.
# - 출력: suite pass/fail result, failing contract identifiers, deterministic verification summary를 제공하는 runner contract.
# - 포함 대상:
#   - validator success/failure case surface
#   - replay matrix surface
#   - snapshot boundary surface
#   - read-model leakage surface
# - 금지: production rule 우회, scene reconstruction 의존, browser/node test harness 의존
#
# 실행:
# - test fixture registry를 읽고 validator/replay/snapshot/read-model 그룹으로 케이스를 분류한다.
# - validator 그룹은 valid/invalid raw data fixture를 FormalContracts API에 순서대로 전달한다.
# - replay 그룹은 FormalReplayRunner 또는 ReplayProcess를 통해 fixture matrix를 실행한다.
# - snapshot 그룹은 HeadlessMiniRun public snapshot이 phase boundary를 지키는지 확인한다.
# - read-model 그룹은 SceneReadModel과 CombatSceneModel이 private runtime field를 노출하지 않는지 확인한다.
# - 그룹별 결과를 suite summary로 합치고 failing identifier와 diagnostics를 deterministic 순서로 정리한다.
