/**
 * 한 문장: canonical phase sentence가 올바른 순서로 이동하는지 검증하고 다음 phase를 질의한다.
 *
 * 참조 원형: `prototype/browser-p0-p4/src/process/stage-sentence.js`
 *
 * 질의:
 * - `assertStageFlowOrder(sentence)`는 필수 phase가 빠지거나 순서가 뒤집히면 오류를 반환한다.
 * - `nextStageTag(currentTag, facts)`는 현재 phase와 run facts에서 다음 phase 후보를 반환한다.
 * - `canTransition(fromTag, toTag, facts)`는 특정 phase 이동이 허용되는지 판정한다.
 *
 * 규칙:
 * - combat은 reward_loot보다 먼저 와야 한다.
 * - reward_loot 이후 남은 stage가 있으면 node_select로 돌아갈 수 있다.
 * - run_complete는 terminal phase이며 반복 문장 안에 포함하지 않는다.
 * - failed는 terminal phase이며 combat failure 규칙을 통해서만 진입한다.
 *
 * 구현 순서:
 * - 선언된 phase sentence의 정합성 검사를 먼저 만든다.
 * - 일반적인 다음 phase 질의와 terminal 분기를 분리한다.
 * - run-progression은 이 질의를 호출해 phase 전이를 확정한다.
 *
 * 금지 규칙:
 * - 이 파일은 전투 실패 원인을 직접 계산하지 않는다.
 */
