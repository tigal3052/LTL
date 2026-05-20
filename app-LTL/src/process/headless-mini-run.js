/**
 * 한 문장: 화면 없이 mini-run 명령을 순서대로 실행하는 application process를 제공한다.
 *
 * 참조 원형: `prototype/browser-p0-p4/src/process/headless-mini-run.js`
 *
 * 공개 명령:
 * - `snapshot()`은 현재 run public snapshot을 반환한다.
 * - `selectNode(candidateIndex)`는 현재 후보 중 하나를 선택하는 전이를 요청한다.
 * - `applyCombatInput(input)`은 tick과 target_ref가 포함된 전투 입력을 적용한다.
 * - `claimRewards()`는 pending reward 수령과 다음 단계 진행을 요청한다.
 *
 * 위임 규칙:
 * - phase transition은 `domain/run-progression.js`가 결정한다.
 * - combat input은 `domain/run-simulator.js`가 적용한다.
 * - reward 생성은 `domain/reward-resolver.js`가 파생한다.
 * - telemetry summary는 `telemetry/telemetry.js`가 파생한다.
 *
 * 구현 순서:
 * - process state를 내부 facts와 event log로만 보관한다.
 * - 각 명령은 현재 phase에서 허용되는지 run-progression에 먼저 묻는다.
 * - 명령 결과는 facts 갱신과 public snapshot 반환으로 분리한다.
 *
 * 금지 규칙:
 * - 이 파일은 DOM, render, browser event를 알지 않는다.
 * - 이 파일은 세부 전투 피해량이나 보상 weight를 직접 계산하지 않는다.
 */
