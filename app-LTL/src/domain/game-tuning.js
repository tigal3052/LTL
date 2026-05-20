/**
 * 한 문장: 검증된 튜닝 사실을 도메인 규칙이 읽기 쉬운 형태로 제공한다.
 *
 * 참조 원형:
 * - `prototype/browser-p0-p4/src/domain/game-tuning.js`
 * - `prototype/browser-p0-p4/src/tuning/mini-run-config.js`
 *
 * 입력:
 * - raw tuning 객체는 loader 또는 schema validator를 통과하기 전까지 규칙에 전달하지 않는다.
 * - 검증된 tuning facts만 combat, queue, stage, reward 규칙의 입력이 된다.
 *
 * 질의:
 * - `combatTuning(facts)`는 피해량과 쿨다운에 필요한 값만 반환한다.
 * - `queueTuning(facts)`는 큐 용량, 생성 간격, 수리 임계값만 반환한다.
 * - `stageScalingTuning(facts)`는 단계 난이도 계산에 필요한 곡선 값만 반환한다.
 * - `rewardTuning(facts)`는 보상 개수, 종류, 색상 가중치만 반환한다.
 *
 * 구현 순서:
 * - validation/schema-validator를 통해 raw tuning을 검증한다.
 * - schema가 만든 사실을 그룹별 read model로 정리한다.
 * - 반환 값은 freeze 또는 clone으로 보호해 규칙이 공유 설정을 변경하지 못하게 한다.
 *
 * 금지 규칙:
 * - 이 파일은 튜닝 기본값을 암묵적으로 추측하지 않는다.
 * - 이 파일은 stage, reward, combat 결과를 직접 계산하지 않는다.
 */
