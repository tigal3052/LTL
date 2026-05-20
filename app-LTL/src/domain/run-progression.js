/**
 * 한 문장: P4 mini-run 흐름을 phase sentence에 맞춘 전이 규칙으로 표현한다.
 *
 * 참조 원형:
 * - `prototype/browser-p0-p4/src/process/headless-mini-run.js`
 * - `prototype/browser-p0-p4/src/domain/run-progression.js`
 *
 * 반복 문장:
 * - `node_select`는 후보를 보여주고 선택 입력을 기다린다.
 * - `combat_start`는 선택된 노드의 전투 facts를 초기화한다.
 * - `combat`은 입력 로그와 tick에 따라 전투 전이를 수행한다.
 * - `combat_end`는 클리어, 실패, 수리 요구를 확정한다.
 * - `reward_loot`는 pending reward를 표시하고 claim 전이를 기다린다.
 * - 다음 단계가 있으면 다시 `node_select`, 없으면 `run_complete`가 된다.
 *
 * 규칙:
 * - `select_node`는 node_select에서만 combat_start 또는 combat으로 이동한다.
 * - `combat_clear`는 combat에서 combat_end와 reward_loot로 이어지는 사실을 만든다.
 * - `time_over` 또는 `repair_required`는 combat에서 failed terminal로 이동한다.
 * - `claim_rewards`는 reward_loot에서 다음 stage 또는 run_complete로 이동한다.
 *
 * 스냅샷 요구:
 * - 공개 snapshot은 phase, candidates, rewards, selected node, flags, nested combat state를 포함한다.
 * - 공개 snapshot은 내부 facts 배열이나 mutable 객체를 그대로 노출하지 않는다.
 *
 * 구현 순서:
 * - phase transition이 허용되는지 판정하는 질의를 먼저 만든다.
 * - 각 명령이 추가하거나 교체하는 stage facts를 별도 전이 함수로 만든다.
 * - 마지막에 snapshot 모듈을 통해 외부 표시 값을 파생한다.
 */
