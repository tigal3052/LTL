/**
 * 한 문장: 화면 또는 도구의 명령을 정식 도메인 질의와 전이 호출로만 전달하는 얇은 어댑터를 제공한다.
 *
 * 참조 원형:
 * - `prototype/browser-p0-p4/src/combat-controller.js`
 * - `prototype/browser-p0-p4/src/ui/mini-run-app.js`
 *
 * 입력 명령:
 * - `select_node(candidate_index)`는 선택 인덱스를 도메인의 노드 선택 전이로 넘긴다.
 * - `combat_input(tick, target_ref, input_id)`는 전투 입력 사실을 생성해 전투 전이에 넘긴다.
 * - `claim_rewards()`는 보상 수령 전이를 요청한다.
 * - `request_snapshot()`은 현재 공개 스냅샷 질의를 요청한다.
 *
 * 위임 질의:
 * - 단계 상태는 `domain/run-progression.js`가 판단한다.
 * - 전투 입력 결과는 `domain/run-simulator.js`와 `domain/combat-resolution.js`가 판단한다.
 * - 보상 생성과 수령은 `domain/reward-resolver.js`가 판단한다.
 * - 표시용 결과와 텔레메트리는 `action-result.js`와 `telemetry/telemetry.js`가 파생한다.
 *
 * 구현 순서:
 * - UI 입력 객체를 도메인 명령 객체로 바꾸는 변환 함수를 먼저 만든다.
 * - 각 명령을 커널의 공개 API 하나에만 연결한다.
 * - 커널 응답에서 화면이 읽어도 되는 공개 스냅샷만 반환한다.
 *
 * 금지 규칙:
 * - 이 파일은 피해량, 큐 변경, 쿨다운, 수리 요구, 단계 진행, 보상, 텔레메트리 필드를 직접 결정하지 않는다.
 * - DOM, 렌더링, 브라우저 타이머 의존은 정식 도메인 안으로 들여오지 않는다.
 */
