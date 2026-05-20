/**
 * 한 문장: 기존 mining resolver 호출 표면을 유지하되 실제 판정은 combat-resolution 규칙에 위임한다.
 *
 * 참조 원형:
 * - `prototype/browser-p0-p4/src/domain/mining-resolver.js`
 * - `prototype/browser-p0-p4/tests/p1_core_loop.test.js`
 *
 * 호환 입력:
 * - energy color, target state, tick, tuning 값은 예전 테스트가 넘기던 형태로 받을 수 있다.
 * - 입력은 내부에서 formal combat facts로 변환한다.
 *
 * 호환 출력:
 * - outcome은 match, normal, mismatch, empty_queue, invalid_target 중 하나로 맞춘다.
 * - damage와 target_after는 combat-resolution 결과를 그대로 전달한다.
 * - counter delta는 telemetry가 다시 계산할 수 있는 event fact 형태로 보존한다.
 *
 * 구현 순서:
 * - legacy input을 combat facts로 바꾸는 adapter 함수를 만든다.
 * - combat-resolution의 공개 질의를 호출한다.
 * - 반환 모양만 legacy 계약에 맞게 재포장한다.
 *
 * 금지 규칙:
 * - 피해량, 약점 비교, 쿨다운 규칙을 이 파일에 중복 구현하지 않는다.
 * - M1 이후 직접 호출자가 사라지면 이 파일은 제거 가능한 compatibility layer로 유지한다.
 */
