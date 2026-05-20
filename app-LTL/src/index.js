/**
 * 한 문장: 정식 도메인 커널을 조립하고 외부 계층이 사용할 공개 API만 내보낸다.
 *
 * 참조 원형:
 * - `prototype/browser-p0-p4/src/process/headless-mini-run.js`
 * - `prototype/browser-p0-p4/src/domain/run-simulator.js`
 * - `prototype/browser-p0-p4/tests/p0_replay.test.js`
 *
 * 공개 질의:
 * - `createDomainKernel(config)`는 검증된 데이터, 튜닝, 규칙, 스냅샷 질의를 하나로 조립한다.
 * - `createReplayRunner(kernel)`은 input log를 화면 없이 실행한다.
 * - `createHeadlessRun(kernel)`은 노드 선택, 전투, 보상, 완료 판정을 공개 명령으로만 진행한다.
 *
 * 조립 순서:
 * - 먼저 loader가 raw JSON을 검증된 사실로 바꾼다.
 * - 그 다음 rule registry가 사실을 읽는 순수 규칙 묶음을 만든다.
 * - 그 다음 process 계층이 명령을 전이로 연결한다.
 * - 마지막으로 snapshot 계층이 외부에 노출할 값만 반환한다.
 *
 * 경계:
 * - UI와 테스트는 이 파일을 통해 정식 도메인에 접근한다.
 * - 도메인 내부 파일은 이 파일을 역으로 import하지 않는다.
 * - prototype, DOM, render, browser timing 모듈은 이 경계 안으로 들어오지 않는다.
 */
