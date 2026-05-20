/**
 * 한 문장: mini-run에서 반복되는 canonical phase sentence를 선언한다.
 *
 * 참조 원형: `prototype/browser-p0-p4/src/process/mini-run-stage-script.js`
 *
 * 선언할 문장:
 * - `node_select`는 stage의 시작 선택 단계다.
 * - `combat_start`는 선택된 노드를 전투 facts로 바꾸는 준비 단계다.
 * - `combat`은 tick과 input log를 적용하는 실행 단계다.
 * - `combat_end`는 클리어 또는 실패 원인을 확정하는 단계다.
 * - `reward_loot`는 보상 수령 전 단계다.
 *
 * 구현 순서:
 * - phase tag 배열을 값으로 선언한다.
 * - terminal phase인 `run_complete`와 `failed`는 반복 문장 밖의 별도 선언으로 둔다.
 * - 검증과 traversal은 `stage-sentence.js`에서 수행하게 한다.
 *
 * 금지 규칙:
 * - 이 파일은 phase 전이 가능 여부를 판정하지 않는다.
 * - 이 파일은 현재 run state를 보관하지 않는다.
 */
