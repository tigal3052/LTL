/**
 * 한 문장: artifact JSON이 인벤토리와 보상 규칙에 주입될 수 있는 사실인지 검증한다.
 *
 * 참조 원형:
 * - `prototype/browser-p0-p4/src/data/artifact-table.json`
 * - `prototype/browser-p0-p4/src/models/artifact-table.js`
 *
 * 생성할 사실:
 * - `artifact_def(id, color, shape, tags)`는 아티팩트의 고정 정의를 나타낸다.
 * - `artifact_slot_rule(id, width, height, cells, anchor)`는 배치 가능한 칸과 기준점을 나타낸다.
 * - `artifact_generation_rule(id, energy_color, interval, amount)`는 큐 생성 규칙의 입력이다.
 * - `artifact_reward_rule(id, stage_min, weight)`는 보상 후보 가중치의 입력이다.
 *
 * 필수 검증:
 * - id는 비어 있지 않고 테이블 안에서 유일해야 한다.
 * - color와 energy_color는 알려진 에너지 색상이어야 한다.
 * - shape cells는 정수 좌표이며 anchor를 기준으로 재구성 가능해야 한다.
 * - weight, interval, amount는 유한한 수이고 규칙이 요구하는 최소값을 만족해야 한다.
 *
 * 구현 순서:
 * - raw 항목 하나를 검증하는 작은 함수를 먼저 만든다.
 * - 테이블 전체의 유일성 검사는 항목 검증 뒤에 별도 함수로 수행한다.
 * - 기본값 정규화는 필수 필드 누락 검사가 끝난 뒤에만 수행한다.
 *
 * 금지 규칙:
 * - schema는 보상을 굴리거나 인벤토리 배치를 계산하지 않는다.
 * - 알 수 없는 필드는 정책에 따라 오류 또는 metadata로만 분류하고 조용히 규칙에 섞지 않는다.
 */
