/**
 * 한 문장: 생성된 에너지가 큐에 들어가고 소비되며 넘칠 때 버려지는 과정을 결정적으로 모델링한다.
 *
 * 참조 원형: `prototype/browser-p0-p4/src/domain/energy-queue.js`
 *
 * 사실:
 * - `queue_capacity(run_id, capacity)`는 큐가 보관할 수 있는 최대 에너지 수다.
 * - `queue_item(run_id, position, energy_color)`는 현재 큐의 보이는 순서를 나타낸다.
 * - `energy_generated(tick, source_id, energy_color)`는 인벤토리나 보상 효과가 만든 에너지다.
 * - `energy_consumed(tick, energy_color)`는 전투 입력이 소비한 에너지다.
 * - `queue_stat(run_id, generated | consumed | wasted, count)`는 리플레이 요약에 필요한 카운터다.
 *
 * 규칙:
 * - `can_push`는 현재 큐 길이가 capacity보다 작을 때 참이다.
 * - `push_energy`는 can_push가 참이면 맨 뒤에 에너지를 추가한다.
 * - `waste_energy`는 can_push가 거짓이면 큐를 바꾸지 않고 wasted 카운터 입력 사실을 만든다.
 * - `consume_front`는 큐 앞 에너지를 제거하고 consumed 카운터 입력 사실을 만든다.
 * - 같은 seed, inventory, tick에서는 generation event 순서가 항상 같아야 한다.
 *
 * 구현 순서:
 * - 큐를 읽기 전용 값 배열로 정규화하는 질의를 만든다.
 * - push, waste, consume을 각각 전이 함수로 분리한다.
 * - generated, consumed, wasted 카운터는 가능한 한 event facts에서 다시 계산한다.
 *
 * 금지 규칙:
 * - 큐 스냅샷은 참조 공유가 아니라 값 복사로 반환한다.
 * - 이 파일은 어떤 아티팩트가 에너지를 생성하는지 직접 판단하지 않는다.
 */
