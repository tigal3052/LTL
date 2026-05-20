/**
 * 한 문장: 아티팩트 배치와 시너지 상태를 순수 사실로 표현하고 큐 생성 규칙의 입력을 만든다.
 *
 * 참조 원형:
 * - `prototype/browser-p0-p4/src/domain/inventory-model.js`
 * - `prototype/browser-p0-p4/src/vocabulary/backpack/*`
 *
 * 사실:
 * - `inventory_grid(width, height)`는 백팩의 경계를 나타낸다.
 * - `artifact_instance(instance_id, artifact_id)`는 획득한 개별 아티팩트를 나타낸다.
 * - `artifact_placed(instance_id, x, y, rotation)`은 배치된 위치와 회전을 나타낸다.
 * - `artifact_held(instance_id)`는 커서 또는 임시 슬롯에 들린 항목을 나타낸다.
 * - `synergy_active(instance_id, synergy_id)`는 현재 배치에서 파생된 시너지를 나타낸다.
 *
 * 규칙:
 * - `can_place`는 shape cell이 grid 경계 안에 있고 다른 배치와 충돌하지 않을 때 참이다.
 * - `place_transition`은 held item을 placed fact로 바꾸고 기존 fact를 값으로 교체한다.
 * - `discard_transition`은 held item 또는 placed item을 제거 사실로 바꾼다.
 * - `queue_generation_from_inventory`는 tick과 배치 사실에서 에너지 생성 이벤트를 파생한다.
 * - `recalculate_synergy`는 인접, tag, 색상 조건을 읽어 synergy facts를 다시 만든다.
 *
 * 구현 순서:
 * - shape cell을 실제 grid 좌표로 펼치는 질의를 먼저 만든다.
 * - 충돌 판정과 경계 판정을 별도 함수로 만든다.
 * - 배치 전이는 기존 inventory facts를 직접 바꾸지 않고 새 facts를 반환한다.
 *
 * 금지 규칙:
 * - drag/drop 화면 상태는 이 파일의 사실이 아니다.
 * - 이 파일은 보상 추첨이나 전투 피해를 결정하지 않는다.
 */
