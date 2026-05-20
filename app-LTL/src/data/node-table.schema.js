/**
 * 한 문장: node JSON이 노드 후보 생성과 전투 파라미터 스케일링에 사용할 수 있는 사실인지 검증한다.
 *
 * 참조 원형:
 * - `prototype/browser-p0-p4/src/data/node-table.json`
 * - `prototype/browser-p0-p4/src/domain/node-generator.js`
 *
 * 생성할 사실:
 * - `node_def(id, label)`은 노드의 식별자와 표시 이름을 나타낸다.
 * - `node_weakness(id, energy_color)`는 노드가 약점으로 받는 에너지 색상을 나타낸다.
 * - `node_weight(id, pick_weight)`는 후보 추첨 가중치를 나타낸다.
 * - `node_scaling_multiplier(id, shield_mul, health_mul)`는 단계 난이도에 곱할 값을 나타낸다.
 * - `always_offer(id)`는 기본 후보로 항상 포함될 노드를 나타낸다.
 *
 * 필수 검증:
 * - 기본 normal 노드는 정확히 하나만 항상 제공 가능해야 한다.
 * - weakness 색상은 알려진 에너지 색상이어야 한다.
 * - pick_weight는 유한한 0 이상의 수여야 한다.
 * - shield_mul과 health_mul은 0보다 큰 유한한 수여야 한다.
 *
 * 구현 순서:
 * - 항목 단위 필드 검증을 먼저 만든다.
 * - 테이블 단위 normal 노드 개수와 id 유일성을 별도 규칙으로 검사한다.
 * - 검증된 항목을 node-generator가 바로 읽을 수 있는 사실 배열로 정규화한다.
 *
 * 금지 규칙:
 * - 이 파일은 후보를 뽑거나 seed를 사용하지 않는다.
 * - 전투 hp, shield, time limit 최종값은 stage-scaling과 node-generator에서 계산한다.
 */
