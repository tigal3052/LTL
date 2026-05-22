# 계약:
# - 책임: stabilized root/phase snapshot에서 scene 전체가 읽을 수 있는 public read model 경계를 제공한다.
# - M0 반영: future scene/UI는 private runtime internals 대신 documented snapshot boundary만 읽는다.
# - SoT: M1 root common state contract, phase-specific snapshot contract, M0의 browser/UI coupling 제거 결정.
# - 입력: HeadlessMiniRun public snapshot, FormalContracts validation result, optional static label tables.
# - 출력: node_select/combat/reward_loot/run_complete를 모두 다룰 수 있는 scene-safe Dictionary contract.
# - 금지: private runtime leakage, SceneTree mutation, browser DOM field 의존
#
# 실행:
# - public root snapshot을 먼저 검증해 phase key와 common key가 모두 있는지 확인한다.
# - 공통 scene shell을 만든 뒤 current phase에 따라 phase-specific panel data를 분기 생성한다.
# - node_select/combat/reward_loot/run_complete별로 scene이 필요로 하는 최소 표시 필드만 고른다.
# - label table이 있으면 raw identifier를 display-safe text로 정규화한다.
# - read model 생성 중 private runtime field나 mutable reference가 섞이지 않도록 copy-safe shape로 정리한다.
# - 최종 결과는 scene 전체가 공유할 read-only Dictionary로 반환한다.
