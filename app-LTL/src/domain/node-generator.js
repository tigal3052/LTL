/**
 * 한 문장: seed, stage, node table, scaling facts에서 재현 가능한 노드 후보 목록을 파생한다.
 *
 * 참조 원형:
 * - `prototype/browser-p0-p4/src/domain/node-generator.js`
 * - `prototype/browser-p0-p4/tests/p4_mini_run.test.js`
 *
 * 입력 사실:
 * - `run_seed(seed)`는 후보 추첨의 루트 seed다.
 * - `stage_index(index)`는 현재 단계 번호다.
 * - `node_def(id, label)`는 후보가 될 수 있는 노드 정의다.
 * - `node_weight(id, weight)`는 기본 추첨 가중치다.
 * - `always_offer(id)`는 항상 첫 후보에 들어갈 기본 노드다.
 * - `node_weakness(id, energy_color)`는 후보 snapshot에 노출할 약점이다.
 * - `scaled_combat_params(stage_index, shield, health, time_limit_ticks)`는 stage-scaling 결과다.
 *
 * 규칙:
 * - normal/default 노드는 항상 첫 번째 후보가 된다.
 * - 추가 후보는 seed에서 파생한 stream으로 중복 없이 weighted pick한다.
 * - 후보의 shield, health, time_limit은 stage scaling과 node multiplier를 조합해 만든다.
 * - 같은 seed와 stage는 항상 같은 candidate id 순서를 반환한다.
 *
 * 구현 순서:
 * - always offer 후보를 먼저 확정한다.
 * - 남은 후보 pool과 weight table을 만든다.
 * - seeded weighted pick without replacement를 별도 질의로 만든다.
 * - 각 후보에 scaled combat params와 weakness facts를 붙인다.
 *
 * 금지 규칙:
 * - 이 파일은 노드 선택 전이를 수행하지 않는다.
 * - 이 파일은 전투 결과나 보상 결과를 읽지 않는다.
 */
