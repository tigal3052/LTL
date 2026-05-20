/**
 * 한 문장: replay 가능한 event facts에서 필수 run summary와 counters를 파생한다.
 *
 * 참조 원형:
 * - `prototype/browser-p0-p4/src/telemetry/telemetry.js`
 * - `prototype/browser-p0-p4/tests/p0_replay.test.js`
 *
 * 필수 field 묶음:
 * - identity는 run_id, seed, stage_index, node_type을 포함한다.
 * - combat result는 result, elapsed_ticks, time_limit_ticks를 포함한다.
 * - shots는 shots_fired, match, normal, mismatch, empty_queue, invalid_target을 포함한다.
 * - queue는 generated, consumed, wasted를 포함한다.
 * - repair는 durability_loss_count와 repair_required를 포함한다.
 * - progression은 stage_cleared, rewards_claimed, run_complete를 포함한다.
 *
 * 규칙:
 * - 필수 field는 값이 0이더라도 항상 존재한다.
 * - counter는 replay 가능한 event facts에서 다시 계산한다.
 * - 같은 facts는 항상 같은 summary를 만든다.
 * - summary 생성은 action result 문구와 분리한다.
 *
 * 구현 순서:
 * - event type별 counter 질의를 먼저 만든다.
 * - 필수 field 기본값을 한곳에서 만든다.
 * - public telemetry summary는 기본값 위에 파생 counter를 덮어써서 만든다.
 *
 * 금지 규칙:
 * - telemetry는 전투 결과를 판정하지 않고 이미 발생한 event facts만 읽는다.
 */
