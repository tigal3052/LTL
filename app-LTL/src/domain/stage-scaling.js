/**
 * 한 문장: stage index와 검증된 튜닝 사실에서 전투 난이도 값을 파생한다.
 *
 * 참조 원형:
 * - `prototype/browser-p0-p4/src/domain/stage-scaling.js`
 * - `prototype/browser-p0-p4/tests/p4_mini_run.test.js`
 *
 * 입력 사실:
 * - `stage_index(index)`는 현재 단계 번호다.
 * - `scaling_tuning(base_shield, base_health, base_time_limit)`는 시작 난이도다.
 * - `scaling_tuning(peak_delta, taper, minimum_time_limit)`는 성장 곡선의 제약이다.
 *
 * 규칙:
 * - shield와 health는 stage index가 증가할수록 감소하지 않는다.
 * - 초반 성장은 완만하고 중반 성장은 더 크며 후반 성장은 taper를 적용한다.
 * - time limit은 단계가 올라가도 configured floor 아래로 내려가지 않는다.
 * - 한 단계 증가분은 별도 질의로 테스트할 수 있어야 한다.
 *
 * 구현 순서:
 * - stage index를 0 또는 1 기준 중 하나로 명확히 정규화한다.
 * - shield, health, time limit 계산을 각각 작은 함수로 분리한다.
 * - node multiplier 적용은 node-generator에서 수행하도록 여기서는 base scaled params만 반환한다.
 *
 * 금지 규칙:
 * - 이 파일은 후보를 뽑거나 전투 결과를 판정하지 않는다.
 */
