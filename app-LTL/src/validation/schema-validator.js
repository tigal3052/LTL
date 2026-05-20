/**
 * 한 문장: data loader와 replay fixture가 공통으로 사용하는 구조화 검증 결과를 만든다.
 *
 * 결과 모양:
 * - `ok`는 검증 통과 여부다.
 * - `facts`는 ok일 때만 규칙에 주입할 정규화 사실을 담는다.
 * - `errors`는 path, code, message, source를 가진 차단 오류 목록이다.
 * - `warnings`는 실행은 가능하지만 호환성 주의가 필요한 항목이다.
 *
 * 규칙:
 * - 필수 field 검사는 기본값 정규화보다 먼저 실행한다.
 * - unknown field 정책은 schema마다 reject, warn, metadata 중 하나로 명시한다.
 * - 숫자 field는 NaN과 Infinity를 거부한다.
 * - 검증은 raw input을 변경하지 않는다.
 *
 * 구현 순서:
 * - field path를 만드는 작은 helper를 먼저 만든다.
 * - required, enum, finite number, array, object 검사를 각각 분리한다.
 * - schema별 validator는 공통 helper를 조합해 facts와 diagnostics를 만든다.
 *
 * M1 검증:
 * - JSON required-field omission test를 먼저 작성한다.
 * - snapshot backward compatibility test에서 missing optional field 기본값을 확인한다.
 */
