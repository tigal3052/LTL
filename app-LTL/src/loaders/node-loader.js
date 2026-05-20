/**
 * 한 문장: raw node JSON을 읽어 검증된 node facts와 진단 정보로 바꾼다.
 *
 * 입력:
 * - 파일 시스템에서 읽은 raw JSON 문자열 또는 이미 파싱된 객체를 받을 수 있다.
 * - source path 또는 source label은 오류 메시지와 telemetry trace에만 사용한다.
 *
 * 처리 순서:
 * - JSON 파싱은 node generation 규칙 밖에서 수행한다.
 * - `data/node-table.schema.js`로 id, weakness, weight, multiplier, always-offer 조건을 검증한다.
 * - weakness 배열과 pick weight를 node-generator가 읽을 수 있는 facts로 정규화한다.
 * - 검증된 facts와 diagnostics를 함께 반환한다.
 *
 * M1 검증:
 * - missing id는 구조화 오류가 된다.
 * - normal node 누락 또는 중복은 구조화 오류가 된다.
 * - invalid weakness color와 non-finite weight는 구조화 오류가 된다.
 *
 * 금지 규칙:
 * - loader는 후보를 추첨하거나 stage scaling을 계산하지 않는다.
 */
