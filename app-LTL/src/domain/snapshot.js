/**
 * 한 문장: 내부 facts를 화면, replay, 테스트가 읽을 수 있는 public snapshot으로 변환한다.
 *
 * 참조 원형:
 * - `prototype/browser-p0-p4/src/domain/run-simulator.js#snapshot`
 * - `prototype/browser-p0-p4/src/process/headless-mini-run.js#snapshot`
 *
 * snapshot family:
 * - `combat_snapshot`은 전투 tick, 결과, 큐, 대상, 요약 카운터를 노출한다.
 * - `stage_snapshot`은 phase, selected node, candidates, pending rewards를 노출한다.
 * - `run_snapshot`은 stage index, run_complete, failed, seed를 노출한다.
 * - `replay_summary`는 fixture 비교에 필요한 최종 결과만 노출한다.
 * - `telemetry_summary`는 운영/QA 필수 필드를 노출한다.
 *
 * 호환 규칙:
 * - M1은 기존 P0-P4 테스트가 소비하는 필드를 유지한다.
 * - 필드 이름을 바꿔야 하면 migration note와 compatibility adapter를 먼저 만든다.
 * - 선택 필드가 누락될 수 있으면 schema 또는 tuning에서 명시 기본값을 제공한다.
 *
 * 구현 순서:
 * - 내부 facts에서 public field 하나를 만드는 작은 질의를 먼저 만든다.
 * - snapshot family별 조립 함수는 세부 계산을 반복하지 않고 작은 질의만 호출한다.
 * - 반환 객체는 외부에서 변경해도 내부 facts에 영향을 주지 않게 값 복사한다.
 *
 * 금지 규칙:
 * - snapshot 모듈은 전투, 보상, 단계 진행을 새로 판정하지 않는다.
 */
