# 계약:
# - 책임: formal root state가 node_select -> combat -> reward_loot -> run_complete 순서로 전이하는 headless orchestration 경계를 제공한다.
# - M0 반영: 정식 root common state key와 phase record key를 M0 결정에 맞춰 고정한다.
# - SoT: browser prototype mini-run loop behavior, M0 root/phase-state decisions, M1 replay coverage list.
# - 입력: seed, leviathan/run/stage metadata, validated node data, validated reward/progress data, normalized combat event.
# - 출력: phase-safe public snapshot을 만들어 내는 headless runtime contract.
# - 포함 대상:
#   - initial root common state ownership
#   - node selection transition ownership
#   - combat result branch ownership
#   - reward resolution handoff ownership
#   - run-complete termination ownership
# - 금지: scene rendering, direct input device handling, browser object shape를 무비판적으로 복사하지 않는다.
#
# 실행:
# - constructor 또는 factory 단계에서 validated dataset과 seed policy를 묶어 root runtime shell을 초기화한다.
# - 초기화 직후 common root state를 만든 뒤 첫 phase snapshot을 node_select로 채운다.
# - node 선택 입력이 들어오면 선택 가능 여부를 가드하고 combat phase snapshot 생성으로 전이한다.
# - combat phase에서는 normalized combat event를 읽고 clear/fail/mismatch 결과를 branch-safe 형태로 판정한다.
# - clear branch는 reward_loot snapshot 생성으로 넘기고 fail branch는 run_complete 종료 snapshot으로 정리한다.
# - reward_loot phase에서는 reward claim 처리 여부를 가드한 뒤 다음 stage 또는 run_complete로 전이한다.
# - 모든 phase 전이 뒤에는 private runtime state를 다시 public snapshot으로 재구성해 외부에 노출한다.
