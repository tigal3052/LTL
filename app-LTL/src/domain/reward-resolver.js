/**
 * 한 문장: 클리어된 전투 단계의 사실에서 pending reward 목록을 재현 가능하게 파생한다.
 *
 * 참조 원형:
 * - `prototype/browser-p0-p4/src/domain/reward-resolver.js`
 * - `prototype/browser-p0-p4/src/vocabulary/reward/*`
 *
 * 입력 사실:
 * - `stage_cleared(stage_index, node_id, cleared_weaknesses)`는 보상 생성의 원인이다.
 * - `reward_count_weight(count, weight)`는 보상 개수 추첨표다.
 * - `reward_kind_weight(kind, weight)`는 보상 종류 추첨표다.
 * - `reward_color(color)`는 보상 색상 후보 목록이다.
 * - `weakness_bonus(color, bonus_weight)`는 클리어한 약점 색상 보너스다.
 *
 * 규칙:
 * - 보상 개수는 seed, stage, node에서 파생한 stream으로 weighted pick한다.
 * - 각 보상 kind는 reward index별 sub-seed로 weighted pick한다.
 * - 클리어한 약점 색상은 색상 weight에 보너스를 더한다.
 * - reward id는 seed, stage, reward index로 만든 안정적인 값이어야 한다.
 *
 * 구현 순서:
 * - reward count를 먼저 결정한다.
 * - reward index별로 kind와 color를 독립 sub-seed로 결정한다.
 * - pending reward fact를 만들고 claim 전이는 run-progression에 맡긴다.
 *
 * 금지 규칙:
 * - 이 파일은 인벤토리에 보상을 배치하지 않는다.
 * - 이 파일은 UI 보상 카드 문구를 만들지 않는다.
 */
