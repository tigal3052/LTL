# 계약:
# - 책임: M1 formal data contract와 public snapshot contract를 검증하는 진입점을 제공한다.
# - M0 반영: 정식 SoT로 승격할 artifact/node/reward/leviathan/progress/root snapshot/phase snapshot 경계를 고정한다.
# - SoT: `LTL-harness/docs/11_exec-plans/01_active/06_M0_redesign_gate.md`, `LTL-harness/docs/11_exec-plans/01_active/07_M1_core_domain_stabilization.md`, `app-LTL/prototype/browser-p0-p4/src/data/*.json`.
# - 입력: loader 또는 fixture가 제공하는 raw Dictionary/Array와 public snapshot Dictionary.
# - 출력: contract validity 판정, normalized contract shape, human-readable diagnostics를 생성하는 public API.
# - 포함 대상:
#   - artifact required/optional field contract
#   - node required/optional field contract
#   - reward required/optional field contract
#   - leviathan master data contract
#   - progress/save contract
#   - root common state contract
#   - phase-specific snapshot contract
# - 금지: SceneTree 접근, Node 생성, replay 실행, scene/UI label 가공, browser presentation field 승격
#
# 실행:
# - raw 입력을 contract 종류별 entry function에서 받는다.
# - 입력 shape를 artifact/node/reward/leviathan/progress/root/phase 단위로 분기한다.
# - 각 분기에서 required key, optional key, enum-like value, nested collection shape를 정규화한다.
# - 정규화 중 발견된 문제를 stable diagnostic list에 누적한다.
# - diagnostic 누적 결과를 바탕으로 success/failure verdict와 normalized snapshot을 함께 반환한다.
# - root snapshot 검증은 common key 검증 후 phase-specific key 검증으로 이어지는 2단계 순서를 유지한다.
# - phase snapshot 검증은 node_select/combat/reward_loot/run_complete를 분리해 phase leakage를 막는다.
