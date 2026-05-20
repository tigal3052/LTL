/**
 * 한 문장: seed를 받은 모든 규칙이 같은 입력에서 같은 난수열을 얻도록 한다.
 *
 * 참조 원형:
 * - `prototype/browser-p0-p4/src/domain/seeded-rng.js`
 * - `prototype/browser-p0-p4/tests/p0_replay.test.js`
 *
 * 규칙:
 * - 모든 난수는 명시적 numeric seed 또는 파생 sub-seed를 입력으로 받는다.
 * - 도메인 모듈은 `Math.random`을 직접 호출하지 않는다.
 * - node offer, queue generation, reward roll, replay compatibility는 서로 다른 stream label을 가진다.
 * - 같은 root seed와 같은 label은 항상 같은 sub-stream을 만든다.
 *
 * 공개 API:
 * - `next()`는 0 이상 1 미만의 수를 반환한다.
 * - `nextInt(maxExclusive)`는 0 이상 maxExclusive 미만의 정수를 반환한다.
 * - `fork(labelOrNumber)`는 독립적인 deterministic stream을 반환한다.
 * - `weightedPick(entries)`는 weight table과 현재 stream으로 하나의 항목을 고른다.
 *
 * 구현 순서:
 * - seed 정규화와 내부 상태 생성을 분리한다.
 * - next와 nextInt를 먼저 검증한다.
 * - fork와 weightedPick은 replay fixture가 요구하는 순서가 고정된 뒤에 추가한다.
 *
 * 금지 규칙:
 * - 시간, 브라우저 상태, 전역 랜덤 값은 seed에 섞지 않는다.
 */
