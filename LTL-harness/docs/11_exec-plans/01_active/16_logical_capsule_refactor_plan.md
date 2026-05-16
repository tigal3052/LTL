# 논리 단위 프로그래밍 리팩터링 계획 (v2)

## 이전 계획(v1)에서 버리는 것

| v1 요소 | 왜 제거하는가 |
|---------|----------------|
| `RunContext` 공유 객체 | 단계마다 필요한 데이터·함수가 다름. 모든 필드를 한 객체에 넣으면 **겉만 캡슐, 속은 전역 상태**가 됨 |
| `RunCapsule` 클래스 + `canEnter` / `handle` | OOP 껍데기. 기존 if/else를 클래스로 옮긴 것에 가깝고 **언어화**가 아님 |
| `RunFlowOrchestrator.dispatch` | 범용 명령 버스는 디버깅·타입 추론·흐름 읽기를 어렵게 함 |
| 진행 단계용 상속 트리 | 유물 **특성**에는 클래스가 맞지만, **스테이지 진행**에는 맞지 않음 |

---

## 논리 단위 프로그래밍이란 (이 프로젝트에서의 정의)

1. **전체 플레이를 하나의 언어(문장)로 쓴다**  
   예: `노드를 고른다 → 전투를 시작한다 → 전투한다 → 전투가 끝난다 → 보상을 얻는다 → 가방을 정리한다 → (다음) 노드를 고른다`

2. **언어의 각 절(절=논리 단위)은 함수다**  
   함수 이름은 기획/플레이 용어와 같다 (`offerNodeChoices`, `startCombat`, `pickUpItem`).

3. **절 안의 세부 동작도 같은 방식의 함수다**  
   `placeItem` 안에서 `canPlaceOnGrid`, `occupyCells`, `recalculateSynergy` 처럼 **더 작은 동사**로만 나뉜다.

4. **단계 간 데이터는 “넘겨주는 값”으로만 연결한다**  
   이전 단계의 **반환값**이 다음 단계의 **인자**가 된다. 공통 컨텍스트 객체에 넣지 않는다.

5. **객체지향은 “사물”에만 쓴다**  
   - 유물 → `Artifact` 인스턴스, `Inventory`  
   - 전투 시뮬 → `RunSimulator`  
   - 진행 **절차**는 클래스가 아니라 **함수 조합**으로 표현한다.

---

## 목표 플로우 (언어 문장)

```
[스테이지 루프 × 5]
  노드 선택
  → 전투 시작
  → 전투
  → 전투 종료
  → 보상 습득
  → 가방 정리
  → (다음 스테이지) 노드 선택
[런 종료]
```

순서를 바꾸려면 **이 문장을 정의한 한 파일**만 수정한다.  
예: `보상 습득`과 `가방 정리`의 순서를 바꾸면, 함수 연결 순서만 바꾼다.

---

## 코드 구조: “언어 사전 + 문장 조립 + 사물 모델”

```
app-LTL/src/
  models/                    # 사물 (OOP 허용)
    artifact.js              # Artifact, InventoryModel
    combat-simulator.js      # RunSimulator (기존 domain 이동·정리)
  vocabulary/                # 동사 사전 (논리 단위 함수)
    node/
      offer-node-choices.js
      choose-node.js
    combat/
      prepare-combat.js
      start-combat.js
      fire-shot.js
      tick-combat.js
      end-combat.js
    reward/
      roll-stage-rewards.js
    backpack/
      pick-up-item.js
      rotate-held-item.js
      place-held-item.js
      discard-held-item.js
      recalculate-synergy.js
  phases/                    # 절(단계) — 입·출력 타입이 고정
    node-select-phase.js
    combat-start-phase.js
    combat-phase.js
    combat-end-phase.js
    reward-loot-phase.js
    backpack-organize-phase.js
  process/                   # 문장(플로우 조립) — 순서 변경은 여기만
    mini-run-stage-script.js
  tuning/
    game-tuning.js
  data/
    artifact-table.json
    node-table.json
```

**핵심:** `vocabulary/` = 작은 동사, `phases/` = 플레이어가 인지하는 절, `process/` = 절을 이어 붙인 문장.

---

## 단계별 상태: 공유 컨텍스트 대신 “태그 + 필요한 필드만”

각 진행 단계는 **자기 타입**만 가진다. (판별 가능한 합 타입 / tagged record)

```js
// phases/types.js — 개념 예시

/** 노드 선택 절 */
// { tag: "node_select", stageIndex, seed, inventory, candidates }

/** 전투 준비 절 (노드 확정, Start 대기) */
// { tag: "combat_start", stageIndex, seed, inventory, chosenNode }

/** 전투 절 */
// { tag: "combat", simulator, inventory }

/** 전투 종료 절 (결과·보상 롤 직전) */
// { tag: "combat_end", outcome, inventory, clearedWeakness }

/** 보상 습득 절 */
// { tag: "reward_loot", inventory, pendingRewards, stageIndex, seed }

/** 가방 정리 절 (선택: loot와 합칠 수 있음) */
// { tag: "backpack_organize", inventory }
```

전이는 **한 함수 = 한 문장 조각**:

```js
// chooseNode(nodeSelectPhase, candidateIndex) -> combatStartPhase
// startCombat(combatStartPhase) -> combatPhase
// resolveCombat(combatPhase, lastInput) -> combatEndPhase | combatPhase
// rollRewards(combatEndPhase) -> rewardLootPhase
// finishLoot(rewardLootPhase) -> nodeSelectPhase | runCompletePhase
```

UI·테스트는 `phase.tag`로 분기하되, **각 tag마다 다른 reduce 함수**를 호출한다.  
`switch(phase) { case 'loot': reduceLoot(phase, event) }` — phase 객체 전체를 다음 함수에 넘김.

---

## 1. `process/` — 플로우는 “함수 연결 목록”

```js
// process/mini-run-stage-script.js

import { enterNodeSelect } from "../phases/node-select-phase.js";
import { enterCombatStart } from "../phases/combat-start-phase.js";
// ...

/**
 * 한 스테이지의 절 순서. 순서 변경은 이 배열만 수정.
 * 각 항목은 (이전 phase) => 다음 phase 를 반환하는 enter* 가 아니라
 * “절 이름”으로 reduce 체인을 만든다.
 */
export const STAGE_SENTENCE = [
  "node_select",
  "combat_start",
  "combat",
  "combat_end",
  "reward_loot",
  "backpack_organize"   // 지금은 reward_loot에 통합해도 됨 — 문장에만 남겨 둠
];

/** 보상 습득 ↔ 가방 정리 순서 바꾸기 예시 */
export const STAGE_SENTENCE_ALT = [
  "node_select",
  "combat_start",
  "combat",
  "combat_end",
  "backpack_organize",
  "reward_loot"
];
```

실행기는 단순히:

```js
function advanceSentence(currentPhase, event) {
  const reducer = REDUCERS[currentPhase.tag];
  return reducer(currentPhase, event);
}
```

`REDUCERS`는 **tag별 함수 맵**. 공통 인터페이스를 억지로 맞출 필요 없음.  
타입이 다르면 **반환 시 다음 tag의 phase 객체를 새로 만들어** 넘긴다.

---

## 2. `vocabulary/` — 가방 예시 (세부 동작 단위)

가방 정리·보상 습득은 같은 동사 사전을 **공유**하지만, **상태 객체는 절마다 따로** 둔다.

| 함수 (동사) | 입력 | 출력 | 하는 일 |
|-------------|------|------|---------|
| `pickUpFromInventory` | `inventory, x, y` | `{ inventory, held }` | 칸에서 유물 들기 |
| `pickUpFromRewardTray` | `pendingRewards, rewardId` | `{ pendingRewards, held }` | 보상 칩에서 들기 |
| `rotateHeld` | `held` | `held` | 90° 회전 |
| `placeHeld` | `inventory, held, x, y` | `{ inventory, held? }` | 배치 시도 |
| `discardHeld` | `inventory, held, source` | `inventory` | 휴지통 |
| `recalculateSynergy` | `inventory` | `inventory` | 인접 동색 쿨 감소 재계산 |

`reward_loot` 절의 reduce:

```js
function reduceRewardLoot(phase, event) {
  if (event.type === "pick_up_reward") {
    const { pendingRewards, held } = pickUpFromRewardTray(phase.pendingRewards, event.rewardId);
    return { ...phase, pendingRewards, held };
  }
  if (event.type === "place" && phase.held) {
    const { inventory, held } = placeHeld(phase.inventory, phase.held, event.x, event.y);
    let pending = phase.pendingRewards;
    if (held === null && event.fromReward) { /* 보상 목록에서 제거 */ }
    return { ...phase, inventory: recalculateSynergy(inventory), held, pendingRewards: pending };
  }
  // ...
}
```

**인벤토리 모델 클래스는 유지.** 절차 로직은 함수로만 쌓는다.

---

## 3. `vocabulary/` — 전투 예시

| 함수 | 입력 | 출력 |
|------|------|------|
| `prepareCombat` | `chosenNode, stageIndex, seed` | `RunSimulator` (초기화만) |
| `startCombat` | `simulator` | `simulator` (gameStarted 플래그는 UI가 아닌 phase에) |
| `fireShot` | `simulator, input` | `simulator` |
| `tickCombat` | `simulator, inventory` | `{ simulator, energies }` |
| `readCombatOutcome` | `simulator` | `"clear" \| "time_over" \| "running"` |

`combat` 절은 `simulator`와 `inventory`만 들고 있으면 된다.  
`pendingRewards`나 `candidates`는 **알 필요 없음**.

---

## 4. 유물: 클래스는 “유물”에만

```js
// models/artifact.js — 유지·정리
class Artifact { tick(); effectiveCooldown; rotateShape(); }
class InventoryModel { placeArtifact(); removeArtifact(); calculateSynergies(); }
```

- **하지 않을 것:** `NodeSelectPhase extends Phase` 같은 상속
- **할 것:** 유물 데이터는 `artifact-table.json`, 행동은 `vocabulary/backpack/*`

---

## 5. UI (`index.html`) 역할

UI는 **문장 실행기에 이벤트만 넘긴다.**

```js
// 의사 코드
let phase = startMiniRun({ seed, maxStages: 5, inventory });

function onClick(nodeIndex) {
  phase = advanceSentence(phase, { type: "choose_node", index: nodeIndex });
  render(phase);  // tag별 render 함수 분리
}

function onBackpackMouseDown(x, y) {
  if (phase.tag !== "reward_loot" && phase.tag !== "backpack_organize") return;
  phase = advanceSentence(phase, { type: "pick_up", x, y });
  render(phase);
}
```

`render(phase)`도 tag별:

```js
const RENDER = {
  node_select: renderNodeSelect,
  combat: renderCombat,
  reward_loot: renderRewardLoot
};
RENDER[phase.tag](phase);
```

렌더러는 **읽기 전용**. phase를 수정하지 않는다.

---

## 6. 기존 모듈 매핑

| 기존 | 리팩터 후 |
|------|-----------|
| `node-generator.js` | `vocabulary/node/offer-node-choices.js` |
| `run-simulator.js` | `models/combat-simulator.js` + `vocabulary/combat/*` |
| `reward-resolver.js` | `vocabulary/reward/roll-stage-rewards.js` |
| `inventory-model.js` | `models/inventory.js` |
| `run-progression.js` | **삭제** → `process/mini-run-stage-script.js` + `phases/*` |
| `index.html` 인라인 로직 | `phases/*` + `vocabulary/*` 호출로 축소 |

---

## 7. 마이그레이션 단계 (실행 순서)

### Step 1 — 동사 사전 추출 (가방부터)

- [ ] `pickUpFromInventory`, `placeHeld`, `rotateHeld`, `discardHeld`, `recalculateSynergy` 를 `vocabulary/backpack/` 로 분리
- [ ] `index.html`에서 해당 블록 제거 → import 호출
- [ ] P3 테스트는 vocabulary를 직접 호출하도록 유지

### Step 2 — 전투 동사 분리

- [ ] `fireShot`, `tickCombat` 등 추출
- [ ] 사격 쿨다운(280ms) 등은 `vocabulary/combat/input-guard.js` 한곳

### Step 3 — 절(phase) 타입 도입

- [ ] `miniRun.phase` 문자열 + 거대 `state` → `phase` tagged 객체로 교체
- [ ] tag별 `reduceX(phase, event)` 파일 생성
- [ ] 한 번에 하나의 tag만 활성 — **다른 tag 필드를 state 루트에 두지 않음**

### Step 4 — 문장 조립 (`process/`)

- [ ] `STAGE_SENTENCE` 배열로 5스테이지 루프 정의
- [ ] 스테이지 클리어 시 `enterNodeSelect`로 phase 재생성 (inventory만 계승)

### Step 5 — UI 렌더 분리

- [ ] `render/` 또는 `ui/` 에 tag별 렌더 함수
- [ ] `index.html`은 이벤트 바인딩 + `advanceSentence` 호출만

### Step 6 — 순서 변경 검증

- [ ] `STAGE_SENTENCE`에서 `reward_loot` / `backpack_organize` 스왑 테스트 1개
- [ ] 문서화: “플로우 변경 = `process/mini-run-stage-script.js`만 편집”

---

## 8. 테스트 전략 (언어 단위에 맞게)

| 테스트 | 내용 |
|--------|------|
| 동사 | `placeHeld` 충돌 시 실패, `recalculateSynergy` 인접 1개 −2틱 |
| 절 | `reduceRewardLoot` — pending 비우면 `finishLoot` 가능 |
| 문장 | headless: 이벤트 시퀀스로 5스테이지 자동 클리어 (기존 P4) |
| 순서 | `STAGE_SENTENCE_ALT` 로 통합 테스트 1개 |

테스트도 `dispatch` 버스 대신 **이벤트를 순서대로 reduce**:

```js
let p = enterNodeSelect({ seed: 9, stageIndex: 0, inventory });
p = reduceNodeSelect(p, { type: "choose", index: 0 });
p = reduceCombatStart(p, { type: "start" });
p = reduceCombat(p, { type: "shot", target: 0 });
// ...
```

---

## 9. 완료 기준

- [ ] `RunContext` / `RunFlowOrchestrator` / `Capsule` 클래스 **도입하지 않음**
- [ ] 플로우 순서가 `process/mini-run-stage-script.js` (또는 동급 한 파일)에만 있음
- [ ] 각 절은 **자기 phase 타입**만 가짐 (tag + 해당 필드)
- [ ] 가방·전투·보상 동작은 `vocabulary/*` 함수로만 구현
- [ ] `Artifact` / `InventoryModel` 은 사물 모델로만 유지
- [ ] P0–P4 + 절/동사 단위 테스트 green
- [ ] `index.html`에 phase별 거대 switch는 **render / reduce로 분리**되어 읽을 수 있음

---

## 10. 설계 판단 기록

| 질문 | 결정 |
|------|------|
| loot와 organize를 나눌까? | 문장에는 둘 다 쓸 수 있게. 구현 초기엔 `reward_loot` 절 하나에 동사만 나눠도 됨 |
| 이벤트 타입은 공통화? | `choose_node`, `start_combat`, `pick_up` 등 **문자열 literal**로 충분. 거대 Command 유니온은 나중에 |
| Godot 포팅 | 동사 함수명 = GDScript 메서드/시그널 이름 후보로 유지 |
| 튜닝 | `game-tuning.js` 유지 (5초, 시너지 0.1초/인접) |

---

## 부록: v1 대비 철학 요약

```
v1:  모든 것 → RunContext → Capsule.handle()
v2:  문장(process) → 절(phases, tag별 state) → 동사(vocabulary) → 사물(models)
```

유지보수 시나리오:

- **“보상을 가방 정리 뒤로”** → `STAGE_SENTENCE` 배열에서 두 문자열 위치 교환  
- **“배치 시 충돌 규칙 변경”** → `vocabulary/backpack/place-held-item.js` 만 수정  
- **“쿨타임 6초로”** → `game-tuning.js` 만 수정  

각 변경이 **한 파일·한 함수**에 국한되는 것이 목표다.
