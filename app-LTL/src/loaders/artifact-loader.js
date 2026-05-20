/**
 * 한 문장: raw artifact JSON을 읽어 검증된 artifact facts와 진단 정보로 바꾼다.
 *
 * 입력:
 * - 파일 시스템에서 읽은 raw JSON 문자열 또는 이미 파싱된 객체를 받을 수 있다.
 * - source path 또는 source label은 오류 메시지에만 사용한다.
 *
 * 처리 순서:
 * - JSON 파싱은 도메인 규칙 밖에서 수행한다.
 * - `data/artifact-table.schema.js`로 필수 필드와 값 범위를 검증한다.
 * - 선택 필드는 명시 기본값으로 정규화한다.
 * - 검증된 항목을 artifact facts, diagnostics, source metadata로 반환한다.
 *
 * 실패 계약:
 * - 필수 필드 누락은 path, code, message, source를 가진 구조화 오류가 된다.
 * - 검증 실패 시 부분 facts를 rule database에 넣지 않는다.
 * - 경고는 호환성 정보를 제공하지만 ok 결과와 구분한다.
 *
 * 금지 규칙:
 * - loader는 인벤토리 배치, 보상 추첨, 에너지 생성을 수행하지 않는다.
 */
