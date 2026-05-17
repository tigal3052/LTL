# M0 출구 및 M1 착수 전 결정 문서

> 목적: 현재 브라우저 프로토타입 기준으로 무엇이 이미 검증되었고, 사용자가 M1 착수 전에 무엇을 결정해야 하는지 기획/코드 관점으로 풀어서 정리한다.
>
> 현재 기준 SoT는 `app-LTL/public/index.html`에서 실제로 플레이한 경로다.
> 검증 기준 URL은 `http://localhost:5173/public` 이다.

---

## 1. 먼저 결론: 사용자가 지금 해야 할 일

### 기획 관점에서 결정할 것
1. 현재 브라우저 프로토타입에서 확인한 규칙 중 무엇을 “정식 규칙”으로 확정할지 결정한다.
2. 5노드 테스트를 임시 검증 구조로 볼지, 실제 최소 플레이 길이로 볼지 결정한다.
3. 보상 규칙 중 현재 구현된 것과 아직 미구현인 것을 나눠서, M1에서 어디까지 구현할지 결정한다.
4. 디버그 UI와 실제 게임 UI를 어디서 나눌지 결정한다.
5. phase를 어떤 단위로 record화할지 결정한다.

### 코드 관점에서 결정할 것
1. 브라우저 SoT를 검증하는 fixture/replay 세트를 무엇으로 고정할지 결정한다.
2. Godot가 읽을 데이터 파일의 스키마를 어디까지 고정할지 결정한다.
3. 브라우저 전용 임시 표현과 실제 규칙 데이터를 분리할지 결정한다.
4. phase별 공통 상태와 phase 전용 상태를 어디에 둘지 결정한다.
5. 보상, 노드, 유물 데이터를 JSON 기반으로 고정할지, 일부를 코드 상수로 둘지 결정한다.

---

## 2. 현재 프로토타입 SoT가 무엇인가

현재 프로토타입의 실제 기준은 아래 경로다.

- 진입점: `app-LTL/public/index.html`
- UI 조립과 입력 처리: `app-LTL/src/ui/mini-run-app.js`
- 런 진행 문장: `app-LTL/src/process/mini-run-stage-script.js`
- phase tag 정의: `app-LTL/src/phases/phase-tags.js`
- 전투 규칙: `app-LTL/src/vocabulary/combat/fire-shot.js`

즉, 지금 기준은 “headless 테스트 코드”가 아니라 “브라우저에서 실제로 눌러보며 확인한 규칙”이다.

### 현재 브라우저에서 확인된 핵심 흐름
- 노드 선택
- 전투 시작
- 전투 진행
- 전투 종료
- 보상 획득
- 보상 정리 후 다음 스테이지 진행

`STAGE_SENTENCE` 기준 문장 순서는 다음과 같다.

- `node_select`
- `combat_start`
- `combat`
- `combat_end`
- `reward_loot`
- `backpack_organize`

---

## 3. 전문용어 설명

이 문서에서 쓰는 용어를 현재 LTL 코드 기준으로 설명하면 아래와 같다.

### 3-1. SoT
SoT는 “이 규칙을 가장 믿을 수 있는 기준 원천이 어디인가”를 뜻한다.

현재 문맥에서는:

- 브라우저 플레이에서 확인한 규칙이 SoT다.
- 예: 전투 발사 규칙은 `fireShot()`이 SoT다.
- 예: 시간 진행과 큐 생성 규칙은 `tickCombat()`가 SoT다.

즉, 나중에 Godot로 옮길 때는 화면을 베끼는 게 아니라 이 규칙들을 옮겨야 한다.

### 3-2. 데이터 로더
데이터 로더는 “Godot가 JSON 같은 데이터 파일을 읽어서 게임에서 쓸 수 있는 상태로 바꾸는 코드”를 뜻한다.

현재 브라우저 프로토타입에서 그 대상이 되는 대표 데이터는:

- 유물 데이터: `app-LTL/src/data/artifact-table.json`
- 노드 데이터: `app-LTL/src/data/node-table.json`

Godot에서는 이런 파일을 읽어:

- 유물 정의 객체로 만들고
- 노드 후보 생성에 쓰고
- 잘못된 필드가 있으면 에러를 내야 한다

그래서 “데이터 로더 기준 스키마 고정”은

- JSON에 어떤 필드가 반드시 있어야 하는지
- 어떤 필드는 선택인지
- 어떤 필드는 브라우저 임시 표현이라 버릴 수 있는지

를 먼저 정하자는 뜻이다.

### 3-3. 스키마
스키마는 “이 데이터가 어떤 모양이어야 하는가”를 뜻한다.

예를 들어 현재 유물 데이터는 대략 이런 구조를 가진다.

- `id`
- `name`
- `shape`
- `energyType`
- `baseCooldownTicks`
- `synergy`

노드 데이터는 대략 이런 구조를 가진다.

- `id`
- `label`
- `weakness`
- `pickWeight`
- `shieldMul`
- `healthMul`
- `alwaysOffer`

즉, 스키마 고정은 “이런 필드들을 Godot에서도 정식 입력 형식으로 인정할지 결정하는 것”이다.

### 3-4. fixture
fixture는 “테스트에 사용하는 고정 입력 데이터 묶음”이다.

현재 코드 기준 fixture 예시는:

- `app-LTL/tests/fixtures/input_logs/basic_clear.json`
- `app-LTL/tests/fixtures/input_logs/empty_queue_repair.json`

이 파일들은 seed, node 설정, inputLog를 묶어둔 “고정 테스트 시나리오”다.

즉, fixture는 “테스트용 저장된 입력 사례”라고 생각하면 된다.

### 3-5. replay
replay는 “저장된 입력 기록을 다시 재생해서 같은 결과가 나오는지 확인하는 것”이다.

현재 코드 기준 replay는:

- `app-LTL/src/tools/replay-runner.js`
- `runReplay()`
- `runReplayFile()`

그리고 입력 기록은 이런 식이다.

- `tick`
- `target`
- `input`

즉, replay는 “이 tick에 이 타일을 클릭했다”를 다시 흉내 내서 결과가 같은지 보는 것이다.

### 3-6. 브라우저 SoT 검증
브라우저 SoT 검증은 “브라우저에서 실제로 확인한 동작이 fixture/replay/headless 테스트 결과와 일치하는지 확인하는 것”이다.

예를 들어:

- 브라우저에서 빨강 약점 노드가 한 발에 클리어되었다
- 그러면 fixture에서도 같은 seed, 같은 node 설정, 같은 입력 기록으로 result가 `clear`가 나와야 한다

즉, replay/fixture는 독립 규칙이 아니라 브라우저 결과를 따라가야 한다.

### 3-7. phase record
phase record는 “특정 phase에서만 필요한 상태 묶음”이다.

예:

- `node_select`에서는 후보 노드 목록이 중요하다
- `combat`에서는 queue, terrain, time, hp/shield가 중요하다
- `reward_loot`에서는 pendingRewards, held, inventory가 중요하다

현재는 `tag` 중심으로 phase를 나누고 있지만, M1 전에는 각 tag가 어떤 전용 상태 묶음을 가져야 하는지 더 명확히 정해야 한다.

---

## 4. M0 출구에서 이미 확인된 것

현재 브라우저 프로토타입 기준으로 확인되었다고 볼 수 있는 것:

- `index.html`에서 게임 진입 가능
- 노드 선택 UI가 뜬다
- 전투 시작 버튼으로 combat 진입 가능
- 전투 중 queue, time, pin, node 체력/실드가 갱신된다
- 보상 tray와 claim 흐름이 존재한다
- reset/restart가 가능하다

즉, “한 사이클 플레이”는 확인되었다.

하지만 아직 결정되지 않은 것:

- Godot 데이터 로더가 읽을 최종 데이터 형식
- replay/fixture를 어떤 시나리오까지 정식 검증 세트로 삼을지
- phase 상태 구조를 어떻게 고정할지
- 브라우저 디버그 UI 중 무엇을 버릴지
- 보상 규칙 중 어디까지 정식 구현 범위로 볼지

---

## 5. M0 출구에서 사용자가 결정해야 할 것

아래는 “결정 항목 / 왜 필요한가 / 사용자가 실제로 답해야 하는 질문” 형태로 정리한 목록이다.

### G0-1. 브라우저 SoT 범위 고정

왜 필요한가:

- 지금은 브라우저에서 본 규칙이 기준이지만, 어디까지를 정식 규칙으로 인정할지 문서가 부족하다.
- Godot 이식 시 “브라우저 임시 표현”까지 옮기면 안 된다.

사용자가 답해야 할 질문:

- 전투 판정 규칙은 현재 브라우저 규칙을 그대로 정식 규칙으로 볼 것인가?
- 현재 5노드 미니런은 테스트 축약판인가, 실제 최소 플레이 구조인가?
- 현재 브라우저에서 보이는 queue/time/pin 흐름은 그대로 유지할 것인가?

코드 기준 근거:

- `mini-run-app.js`
- `mini-run-stage-script.js`
- `fire-shot.js`

### G0-2. fixture/replay 승격 목록 확정

왜 필요한가:

- 지금 fixture는 일부만 있고, “이 정도면 브라우저 검증을 대체할 수 있다”는 기준이 없다.
- M1 이후에는 Godot에서도 같은 시나리오가 재현되어야 한다.

사용자가 답해야 할 질문:

- 최소 몇 개의 대표 시나리오를 정식 fixture로 승격할 것인가?
- 어떤 상황이 반드시 포함되어야 하는가?

권장 포함 시나리오:

- 1발 clear
- empty queue로 repair pressure 발생
- mismatch 공격
- reward claim 후 다음 stage 진입
- 마지막 stage clear 후 run complete

현재 코드 기준 근거:

- `tests/fixtures/input_logs/basic_clear.json`
- `tests/fixtures/input_logs/empty_queue_repair.json`
- `tests/p0_replay.test.js`
- `src/tools/replay-runner.js`

### G0-3. 데이터 로더 기준 스키마 고정

왜 필요한가:

- Godot는 브라우저처럼 JS 객체를 즉석에서 쓰지 않고, 파일을 읽어 검증해야 한다.
- 필수 필드를 먼저 정하지 않으면 loader/validator부터 흔들린다.

사용자가 답해야 할 질문:

- 유물 데이터에서 필수 필드는 무엇인가?
- 노드 데이터에서 필수 필드는 무엇인가?
- 브라우저 임시 전용 필드는 무엇인가?
- Godot에서만 새로 필요한 필드는 무엇인가?

현재 기준으로 최소 고정 대상:

- 유물: `id`, `name`, `shape`, `energyType`, `baseCooldownTicks`
- 노드: `id`, `label`, `weakness`, `pickWeight`, `shieldMul`, `healthMul`

현재 코드 기준 근거:

- `src/data/artifact-table.json`
- `src/data/node-table.json`
- `src/phases/node-select-phase.js`

### G0-4. phase record 구조 고정

왜 필요한가:

- 지금은 `tag`로 phase 구분은 되지만, 각 phase 상태 경계가 충분히 문서화되지 않았다.
- Godot state machine으로 옮길 때 가장 많이 흔들릴 수 있는 부분이다.

사용자가 답해야 할 질문:

- run 전체 공통 상태로 항상 남길 값은 무엇인가?
- combat에서만 필요한 값은 무엇인가?
- reward_loot에서만 필요한 값은 무엇인가?

권장 구분:

- 루트 공통 상태: `seed`, `stageIndex`, `maxStages`, `inventory`
- node_select 전용: `candidates`
- combat 전용: `combat`
- reward_loot 전용: `pendingRewards`, `held`, `lastClearWeakness`, `lastNodeLabel`

현재 코드 기준 근거:

- `src/phases/node-select-phase.js`
- `src/phases/reward-loot-phase.js`
- `src/phases/phase-tags.js`

### G0-5. 임시 UI 제거/격리 목록 확정

왜 필요한가:

- 현재 브라우저에는 게임 규칙과 관계없는 디버그 표현이 섞여 있다.
- 이걸 구분하지 않으면 Godot 포팅 범위가 불필요하게 커진다.

사용자가 답해야 할 질문:

- 실제 게임에도 필요한 UI는 무엇인가?
- 개발 중에만 필요한 디버그 UI는 무엇인가?
- 완전히 버릴 UI는 무엇인가?

현재 브라우저 기준 분류 예시:

- 디버그 전용: `freeze-test`, `mono-color-mode`, `output`, `dev-hint`
- 표현 전용: `ghost`, `floating-text`, DOM overlay
- 본편 핵심 UI: terrain, backpack, queue, hp/shield, reward tray

### G0-6. 보상 스키마 + 미구현 범위 확정

왜 필요한가:

- 현재 reward는 UI chip 중심 구현과 stage reward 개념이 섞여 있다.
- 나중에 relic/random selection/보상 종류 확장이 들어오면 지금 구조가 바로 흔들릴 수 있다.

사용자가 답해야 할 질문:

- 현재 M1에서 구현할 보상은 “유물 선택”까지만인가?
- 돈, 랜덤 3택, 유물 희귀도 같은 요소는 지금 설계만 할 것인가?
- reward data를 코드 상수로 둘지 JSON으로 뺄지 결정할 것인가?

현재 코드 기준 근거:

- `src/vocabulary/reward/roll-ui-rewards.js`
- `src/vocabulary/reward/roll-stage-rewards.js`
- `src/phases/reward-loot-phase.js`

---

## 6. M1 착수 전 문서로 남겨야 할 것

아래는 실제로 “문서 파일”로 있어야 M1이 덜 흔들리는 항목이다.

### 필수 문서
- 브라우저 SoT 선언 문서
- fixture 승격 목록 문서
- Godot 데이터 로더 스키마 문서
- phase record 구조 문서
- 임시 UI 제거/격리 목록 문서
- 보상 스키마 통합 문서
- 기술 부채 분리 문서

### 문서마다 반드시 들어가야 할 내용

`브라우저 SoT 선언 문서`
- 현재 기준 URL
- 실제 규칙 SoT 함수
- 브라우저 전용 임시 요소

`fixture 승격 목록 문서`
- fixture 이름
- seed
- node 설정
- inputLog
- 기대 result
- 기대 summary 핵심 필드

`Godot 데이터 로더 스키마 문서`
- 필수 필드
- 권장 필드
- 옵션 필드
- 브라우저 전용 필드
- 예시 JSON

`phase record 구조 문서`
- phase tag 목록
- 루트 공통 상태
- phase별 전용 상태
- phase 전이 이벤트

`임시 UI 제거 문서`
- 유지
- 디버그 모드 격리
- 삭제

`보상 스키마 문서`
- 현재 구현된 reward flow
- 미구현 reward 종류
- M1 구현 범위
- 이후 확장 포인트

---

## 7. M1 착수 체크리스트

- [ ] 브라우저 SoT를 한 문장으로 설명할 수 있다.
- [ ] 전투 규칙 SoT 함수가 무엇인지 말할 수 있다.
- [ ] fixture와 replay가 각각 무엇을 의미하는지 설명할 수 있다.
- [ ] 최소 fixture 승격 목록이 정리되어 있다.
- [ ] 유물/노드 데이터 스키마의 필수 필드가 정리되어 있다.
- [ ] phase별 공통 상태와 전용 상태가 나뉘어 있다.
- [ ] 디버그 UI와 실제 UI가 구분되어 있다.
- [ ] 보상 스키마의 현재 범위와 미구현 범위가 분리되어 있다.

---

## 8. 실무적으로 추천하는 바로 다음 순서

1. `fixture/replay 용어와 승격 대상` 문서를 먼저 쓴다.
2. `artifact/node 데이터 로더 스키마` 문서를 쓴다.
3. `phase record 구조` 문서를 쓴다.
4. `임시 UI 제거 목록` 문서를 쓴다.
5. `보상 스키마 통합` 문서를 쓴다.

이 순서가 좋은 이유는:

- fixture가 있어야 브라우저 SoT를 다른 환경에서 검증할 수 있고
- 스키마가 있어야 Godot loader를 만들 수 있고
- phase 구조가 있어야 state machine을 만들 수 있기 때문이다.
