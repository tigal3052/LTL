/**
 * 한 문장: fixture input log를 정식 headless domain에 흘려보내 deterministic regression 결과를 만든다.
 *
 * 참조 원형:
 * - `prototype/browser-p0-p4/src/tools/replay-runner.js`
 * - `prototype/browser-p0-p4/tests/fixtures/input_logs/*`
 *
 * 입력:
 * - replay fixture path 또는 이미 로드된 fixture object를 받는다.
 * - seed, node, stage, queue capacity, inventory, tuning override를 명시적으로 받는다.
 * - input log entries는 tick 순서로 정렬되어 있어야 한다.
 *
 * 출력:
 * - final public snapshot은 snapshot 모듈에서 만든 값이다.
 * - telemetry summary는 telemetry 모듈에서 만든 값이다.
 * - validation diagnostics는 fixture와 data loader 검증 결과를 포함한다.
 * - optional event trace는 regression diffing에만 사용한다.
 *
 * 규칙:
 * - 같은 seed와 같은 input log는 같은 final snapshot과 summary를 만든다.
 * - fixture loading은 simulation보다 먼저 필수 field를 검증한다.
 * - CLI 출력, 파일 경로, process exit 처리는 이 도구 계층에만 둔다.
 *
 * 구현 순서:
 * - fixture 검증과 정규화를 먼저 수행한다.
 * - createHeadlessRun 또는 createReplayRunner 공개 API로만 simulation을 실행한다.
 * - 결과 비교는 public snapshot과 telemetry summary만 사용한다.
 */
