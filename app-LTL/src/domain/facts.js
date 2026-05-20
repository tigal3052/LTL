/**
 * 한 문장: LTL 정식 도메인에서 사용할 사실 이름과 값 모양을 한곳에 고정한다.
 *
 * 목적:
 * - 테스트, loader, rule, replay가 서로 다른 사실 이름을 만들지 못하게 한다.
 * - 사실은 입력 데이터이며 규칙은 사실을 읽어 질의와 전이를 파생한다는 경계를 분명히 한다.
 *
 * 사실 묶음:
 * - `run_fact`는 seed, run_id, max_stages, queue_capacity를 담는다.
 * - `stage_fact`는 stage_index, phase, selected_node_id, completion flag를 담는다.
 * - `node_fact`는 후보, 약점 색상, 가중치, 스케일된 전투 파라미터를 담는다.
 * - `combat_fact`는 tick, time_limit, shield, health, disabled_until을 담는다.
 * - `queue_fact`는 큐 항목, 생성 이벤트, 소비 이벤트, 낭비 이벤트를 담는다.
 * - `inventory_fact`는 아티팩트 배치, held item, synergy tag를 담는다.
 * - `reward_fact`는 pending reward, claimed reward, reward source를 담는다.
 * - `telemetry_fact`는 필수 요약 필드와 event counter를 담는다.
 *
 * 구현 순서:
 * - 먼저 평범한 불변 record factory를 만든다.
 * - 각 factory는 필드 이름과 기본값을 한곳에서만 정한다.
 * - 반복되는 검색 코드가 테스트에서 드러날 때만 query helper를 추가한다.
 *
 * 금지 규칙:
 * - 이 파일은 게임 규칙을 판정하지 않는다.
 * - 사실 이름을 문자열로 흩뿌리지 말고 이 파일의 vocabulary를 참조한다.
 */
