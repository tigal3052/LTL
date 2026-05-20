/**
 * 한 문장: 한 번의 전투 입력이 큐, 대상, 피해, 쿨다운, 클리어 상태를 어떻게 바꾸는지 결정한다.
 *
 * 참조 원형:
 * - `prototype/browser-p0-p4/src/vocabulary/combat/calculate-damage.js`
 * - `prototype/browser-p0-p4/src/domain/mining-resolver.js`
 *
 * 입력 사실:
 * - `combat_phase(active)`는 전투 입력을 받을 수 있는 단계인지 나타낸다.
 * - `target_state(target_ref, shield, health, disabled_until, weaknesses)`는 대상의 현재 내구 상태다.
 * - `queue_front(energy_color)`는 이번 사격에 소비될 에너지다.
 * - `attempted_input(click, tick, target_ref)`는 사용자의 사격 시도다.
 * - `combat_tuning(...)`은 피해량과 쿨다운 규칙의 데이터 입력이다.
 *
 * 규칙:
 * - `valid_target`은 대상이 존재하고 현재 tick에 비활성화 상태가 아닐 때 참이다.
 * - `consumable_shot`은 combat 단계, click 입력, 비어 있지 않은 큐가 모두 참일 때 성립한다.
 * - `damage_type`은 queue_front 색상과 target weakness를 비교해 match, normal, mismatch 중 하나가 된다.
 * - `target_after`는 shield 피해를 먼저 적용하고 남은 피해만 health에 적용한다.
 * - 같은 tick에 clear와 time_over가 함께 파생되면 clear가 우선한다.
 *
 * 전이 출력:
 * - `shot_resolution(outcome, damage, queue_delta, target_delta)`는 한 발의 결과를 설명한다.
 * - `combat_transition(before_snapshot, after_snapshot)`는 공개 스냅샷 생성에 필요한 전후 상태를 설명한다.
 *
 * 구현 순서:
 * - 대상 유효성, 큐 소비 가능성, 피해 타입을 각각 한 문장 함수로 만든다.
 * - 피해량 계산은 튜닝 사실과 damage_type만 읽도록 만든다.
 * - 대상 내구도 적용과 전투 종료 판정을 별도 함수로 분리한다.
 *
 * 금지 규칙:
 * - 이 파일은 입력 로그를 읽거나 보상을 생성하지 않는다.
 * - 이 파일은 action result 문구와 telemetry 카운터를 직접 만들지 않는다.
 */
