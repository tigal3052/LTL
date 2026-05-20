/**
 * 한 문장: P0/P1 headless combat 실행을 사실과 규칙 위의 공개 질의 facade로 제공한다.
 *
 * 참조 원형: `prototype/browser-p0-p4/src/domain/run-simulator.js`
 *
 * 입력:
 * - seed는 모든 난수 stream의 시작점이다.
 * - queue_capacity는 큐 길이 규칙의 입력이다.
 * - time_limit_ticks는 전투 종료 판정의 입력이다.
 * - selected node combat params는 대상 shield, health, weakness를 만든다.
 * - inventory facts는 큐 생성 이벤트를 만든다.
 * - ordered input log는 tick 순서대로 적용할 사용자 입력이다.
 *
 * 위임 규칙:
 * - 난수는 `seeded-rng.js`에서만 만든다.
 * - 큐 변경은 `energy-queue.js`가 결정한다.
 * - 전투 입력은 `combat-resolution.js`가 결정한다.
 * - 행동 결과는 `action-result.js`가 파생한다.
 * - 요약 카운터는 `telemetry/telemetry.js`가 파생한다.
 *
 * 공개 snapshot:
 * - seed, tick, result, repairRequired, durabilityLossCount를 포함한다.
 * - queue items는 값 배열로 포함한다.
 * - targets는 weakness, shield, health, disabledUntil을 포함한다.
 * - summary는 replay regression에 필요한 필수 telemetry field를 포함한다.
 *
 * 구현 순서:
 * - 초기 combat facts를 만드는 함수를 먼저 만든다.
 * - tick마다 inventory generation, input application, timeout check를 순서대로 적용한다.
 * - 최종 snapshot은 snapshot 모듈의 public contract로만 만든다.
 */
