/**
 * 한 문장: 게임 튜닝 값을 전역 상수가 아니라 명시적 사실로 주입하기 위해 검증한다.
 *
 * 참조 원형:
 * - `prototype/browser-p0-p4/src/domain/game-tuning.js`
 * - `prototype/browser-p0-p4/src/tuning/mini-run-config.js`
 *
 * 생성할 사실:
 * - `combat_tuning(base_match_damage, normal_damage, mismatch_penalty, cooldown_ticks)`
 * - `queue_tuning(capacity_default, repair_threshold, generation_interval)`
 * - `stage_scaling_tuning(base_shield, base_health, base_time_limit, curve)`
 * - `reward_tuning(count_weights, kind_weights, weakness_bonus)`
 *
 * 필수 검증:
 * - 모든 숫자는 finite 값이어야 하며 문서화된 범위 안에 있어야 한다.
 * - 가중치 배열은 최소 하나 이상의 양수 weight를 가져야 한다.
 * - snapshot 호환에 필요한 기본값은 암묵적으로 만들지 말고 schema에 명시한다.
 *
 * 구현 순서:
 * - 튜닝 그룹별 검증 함수를 만든다.
 * - 각 그룹을 사실 목록으로 정규화한다.
 * - 누락된 선택 필드는 명시적 기본값 사실로 보강하고 경고를 남긴다.
 *
 * 금지 규칙:
 * - 이 파일은 튜닝 값을 사용해 전투, 보상, 단계를 계산하지 않는다.
 * - 규칙 모듈은 raw tuning 객체를 직접 읽지 않고 검증된 사실만 읽는다.
 */
