/**
 * 한 문장: 작은 규칙 모듈들을 이름 있는 rule set으로 묶어 테스트와 커널 조립이 같은 경계를 쓰게 한다.
 *
 * rule set:
 * - `validation_rules`는 table, tuning, replay fixture 필수 조건을 검사한다.
 * - `node_offer_rules`는 후보 생성과 stage-scaled combat params를 파생한다.
 * - `combat_rules`는 입력, 큐, 대상, 피해, 쿨다운, 전투 결과를 파생한다.
 * - `stage_rules`는 phase transition과 run completion을 파생한다.
 * - `reward_rules`는 pending reward와 claimed reward 전이를 파생한다.
 * - `telemetry_rules`는 event counter와 필수 summary field를 파생한다.
 * - `snapshot_rules`는 내부 사실을 public snapshot으로 바꾼다.
 *
 * 구현 순서:
 * - 처음에는 custom rule engine 없이 순수 함수 목록으로 구성한다.
 * - 각 rule set은 필요한 facts와 반환 facts를 명시한다.
 * - 통합 테스트에서 반복 조립이 많아질 때만 registry helper를 추가한다.
 *
 * 금지 규칙:
 * - registry는 규칙의 세부 로직을 직접 담지 않는다.
 * - rule set 이름은 테스트 fixture와 문서에서 같은 이름으로 사용한다.
 */
