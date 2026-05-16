# M0 이후 구현 핸드오프 — 프로토타입 정의 · 정식 작성 · 의사결정

## 문서 목적

`06_M0_redesign_gate.md`에서 **무엇을 유지/교체/보류할지** 정한 뒤, `07_M1`~`15_M9` 정식 구현(Godot)에 들어가기 전에 **프로토타입(app-LTL)이 무엇을 계약으로 고정해야 하는지**, **정식 쪽에서 무엇을 새로 짜야 하는지**, **아직 결정되지 않은 항목**을 한곳에 모은다.

**전제 (현재 프로토타입 스냅샷, 2026-05)**

- P0~P4 headless/브라우저 슬라이스는 `app-LTL/tests` 34개 통과.
- 브라우저 미니런은 `vocabulary/` → `phases/` → `process/` → `ui/` 구조로 분리됨 (`16_logical_capsule_refactor_plan.md`).
- Headless 루프는 `process/headless-mini-run.js` (`RunProgression` 호환 re-export).
- UI 전투는 `vocabulary/combat/*` + `phase.combat`; headless는 `RunSimulator` — **이중 경로**가 공존.

---

## M0 게이트에서 먼저 닫을 결정 (공통)

| # | 의사결정 | 선택지 / 메모 | 영향 단계 |
|---|----------|----------------|-----------|
| D0-1 | **단일 진실 소스(SoT)** | (A) headless `RunSimulator` (B) UI `fireShot`/`tickCombat` (C) 둘 다 유지·동기화 테스트 | M1, M2 |
| D0-2 | **정식 폴더·네이밍** | Godot `domain/` vs `scripts/domain/`; JS 동사명 → GDScript 메서드/시그널 매핑표 | M1 |
| D0-3 | **P0~P4 fixture 승격 목록** | 어떤 JSON replay·telemetry 필드를 GUT 회귀에 고정할지 | M0, M1, M8 |
| D0-4 | **phase 모델** | flat `tag`+형제 필드 유지 vs tag별 discriminated union | M1, M2, M3 |
| D0-5 | **미니런 스테이지 수·스케일링** | 프로토타입 5스테이지·가우시안 스케일 확정 여부 | M3, M4, M8 |
| D0-6 | **보상 스키마** | UI: `tableId`+드래그 vs headless: `kind`+`qty` — 통합 스키마 필요 | M3 |
| D0-7 | **임시 UI 제거 목록** | `lobbyTerrainRenderState`, debug mono-color, `index.html` 프로토타입 한정 | M0, M2, M6 |
| D0-8 | **기술 부채 트래커** | `00_tech-debt-tracker.md` 신설 여부·형식 | M0 |

---

## 단계별: 프로토타입에서 정의 · 정식에서 작성 · 의사결정

### M1 — 코어 도메인 안정화

| 구분 | 내용 |
|------|------|
| **프로토타입에서 정의** | 도메인 공개 API 표면: `InventoryModel`, `RunSimulator`, `HeadlessMiniRun`, `offerNodeChoices`, `rollStageRewards`, `game-tuning` 상수·틱 규칙. snapshot/telemetry **필수 필드 목록** (P0~P4 summary JSON). JSON `artifact-table` / `node-table` 스키마 + validator 규칙. replay 입력 로그 스키마 (`tick`, `target`, `input`). |
| **정식에서 작성** | Godot `domain` 모듈(또는 Autoload 아닌 순수 클래스). 데이터 로더·validator. GUT replay 회귀 스위트. **화면 없는** API 문서(기획/프로그래머용). |
| **의사결정** | D0-1 SoT. `domain/` vs `models/`+`vocabulary/` 경계를 Godot에 어떻게 옮길지. snapshot 하위 호환 정책(필드 추가만 vs breaking). |

**프로토타입 산출물 후보 (계약 고정용)**

- `src/domain/*.js` + `src/data/*.json` — M1 이전에 스키마 문서 1장(`domain-api.md` 등) 권장.
- `tests/p0_replay.test.js`, `p4_mini_run.test.js` — GUT 포팅 우선순위 fixture 목록.

---

### M2 — 전투 씬 재구성

| 구분 | 내용 |
|------|------|
| **프로토타입에서 정의** | 입력 계약: 단발 쿨다운(`SHOT_COOLDOWN_MS`), 홀드 연발(`HOLD_DELAY_MS`, `HOLD_INTERVAL_MS`), 타일 비활성 틱(`TILE_SHOT_COOLDOWN_TICKS`). 피드백 enum: `match` / `mismatch` / `empty_queue` / `invalid_cooldown`. 7:3 레이아웃·3×10 그리드 **좌표/인덱스** 규칙(0~29, row-major). pin·time·queue HUD에 필요한 **최소 상태 필드** (`phase.combat` 또는 동등). |
| **정식에서 작성** | Combat scene, terrain renderer, queue/pin/repair/hazard HUD, **input adapter**(도메인 호출만). 연출·애니메이션·사운드. |
| **의사결정** | UI 전투 로직을 Godot에서 `RunSimulator`만 쓸지, 별도 presentation layer를 둘지(D0-1). repair/hazard HUD를 M2에 넣을지 M5로 미룰지. |

**프로토타입 참조**

- `src/vocabulary/combat/*`, `src/ui/mini-run-app.js`, `src/ui/render/render-terrain.js`
- **임시:** `lobbyTerrainRenderState` — M2 전 로비/노드 UI 모델 확정 후 제거.

---

### M3 — 보상과 성장

| 구분 | 내용 |
|------|------|
| **프로토타입에서 정의** | 스테이지 클리어 → `rollStageRewards` / `rollUiRewards` **통합 보상 스키마**. 가중치 테이블(개수·색·종류). 습득 절: `held` + `placeHeld` + `pendingRewards` 비우기 → 다음 스테이지. 런 성장 상태(메타 제외): 인벤토리만 vs 별도 run buff. telemetry: 빌드 변화 추적 필드. |
| **정식에서 작성** | reward offer/selection UI flow. rarity/weight data pipeline. run-level growth state 저장. 보상 연출 최소 버전. |
| **의사결정** | D0-6 headless `kind` vs UI `tableId` 통합. 보상을 **노드 클리어 직후 자동 지급** vs **선택 UI** vs **가방 배치 필수** 중 어디까지 M3에 포함할지. `reward_loot`와 `backpack_organize` 절 분리 여부(`STAGE_SENTENCE`). |

**프로토타입 참조**

- `src/phases/reward-loot-phase.js`, `src/vocabulary/reward/*`, `src/vocabulary/backpack/*`

---

### M4 — 노드 라우팅

| 구분 | 내용 |
|------|------|
| **프로토타입에서 정의** | `node-table.json`: id, label, weakness, shield/health mul, pickWeight, alwaysOffer. `generateNodeCandidates` / `offerNodeChoices`: 시드·스테이지·후보 수(3)·normal 보장. boss/event/normal **타입 enum** (현재는 테이블 id 수준). route telemetry 필드. |
| **정식에서 작성** | node map screen. node choice model 확장(event/boss). route telemetry 수집. |
| **의사결정** | 3 vs 5 스테이지 고정(D0-5). boss 노드 스테이지 위치 규칙. event 노드를 M4에 넣을지 보류(M0). |

**프로토타입 참조**

- `src/domain/node-generator.js`, `src/data/node-table.json`, `src/phases/node-select-phase.js`

---

### M5 — 방해 요소 계층화

| 구분 | 내용 |
|------|------|
| **프로토타입에서 정의** | `HazardModel` API: freeze, break, repair. hazard **핀과 분리** 규칙. 최소 3종 hazard의 duration/target/clear 조건 표. seed 기반 hazard 스케줄(있다면). telemetry 지표 이름. |
| **정식에서 작성** | hazard table, scheduler, VFX/SFX cues, hazard HUD. |
| **의사결정** | M2 repair HUD vs M5 전담. 프로토타입 `hazard-model.js`를 SoT로 승격할지. |

**프로토타입 참조**

- `src/domain/hazard-model.js`, P3 tests

---

### M6 — UI/UX 정리

| 구분 | 내용 |
|------|------|
| **프로토타입에서 정의** | HUD 정보 우선순위(1초 식별 기준). 색상+형태 이중 인코딩 규칙(에너지 색). failure/retry/clear 화면 **상태 전이** (`gameOver`, `run_complete`). accessibility 체크리스트 초안. |
| **정식에서 작성** | 최종 HUD, tooltip/아이콘, reward presentation polish, failure/retry flow, a11y pass. |
| **의사결정** | 프로토타입 `index.html` CSS를 참고만 할지 폐기할지. mono-color 디버그 버튼 유지 여부. |

---

### M7 — 내러티브 통합

| 구분 | 내용 |
|------|------|
| **프로토타입에서 정의** | **비게임플레이** 텍스트 슬롯 ID만: intro, first_artifact, run_fail, run_clear, node_select 힌트. 전투 중 대사 금지 원칙. terminology glossary (`사냥` vs `채집`). |
| **정식에서 작성** | 시나리오 비트, UI 카피, localization 키. |
| **의사결정** | 서사가 telemetry/snapshot에 넣을 필드 있는지(없음 권장). 튜토리얼 대체 노드 선택 카피 분량. |

---

### M8 — Vertical Slice

| 구분 | 내용 |
|------|------|
| **프로토타입에서 정의** | E2E 시나리오 스크립트: 새 런 → 3(또는 5)스테이지 → clear/time_over/retry. 각 단계 **통과/실패 판정** headless로 재현 가능해야 함. known issues 템플릿. |
| **정식에서 작성** | playable build, regression suite 통합, QA report, known issues list. |
| **의사결정** | 슬라이스 범위를 M1~M6 전부 vs M1~M4만. 프로토타입 `npm test` + Godot GUT **이중 게이트** 유지 여부. |

---

### M9 — Release Candidate

| 구분 | 내용 |
|------|------|
| **프로토타입에서 정의** | telemetry/export 경로, data hash·버전 로깅 형식. 30분 플레이 체크리스트(프로토타입 URL 또는 Godot build). crash report 필드. |
| **정식에서 작성** | RC build, release notes, log path guide, bug template, regression evidence. |
| **의사결정** | RC에 프로토타입 HTML 포함 여부(보통 No). 다음 마일스톤(릴리즈 / 플레이테스트 / 콘텐츠). |

---

## 프로토타입에 지금 적어 두어야 할 계약 (체크리스트)

아래가 없으면 M1에서 Godot 구현자가 `domain` 내부를 뜯어봐야 한다.

- [ ] **도메인 snapshot JSON 스키마** (한 파일, 예시 포함)
- [ ] **이벤트 → phase 전이 표** (`choose_node`, `begin_combat`, `stage_cleared`, `claim_rewards`, …)
- [ ] **`STAGE_SENTENCE` 최종 순서** (`process/mini-run-stage-script.js`와 Godot 상태기계 1:1)
- [ ] **튜닝 상수 표** (`game-tuning.js` → 기획 수치 문서)
- [ ] **artifact-table / node-table 필드 정의**
- [ ] **보상 통합 스키마** (headless vs UI)
- [ ] **telemetry 필수 키** (P4 `mini-run-telemetry` 출력 기준)
- [ ] **SoT 결정서** (D0-1) 1페이지

---

## 정식(Godot)에서 새로 작성할 것 (프로토타입 복사 금지 목록)

| 영역 | 이유 |
|------|------|
| Scene tree, Control 레이아웃, Theme | HTML/CSS 프로토타입과 엔진 UI 불일치 |
| Input map, 포커스, a11y | 브라우저 이벤트 모델과 다름 |
| `lobbyTerrainRenderState` 등 렌더 전용 fake state | Godot 로비 씬에서 자체 처리 |
| `mini-run-app.js` monolith 성격의 DOM 바인딩 | `input adapter` + scene presenter로 재작성 |
| 디버그 전용(mono-color, freeze-test 버튼) | 개발 메뉴로 분리 또는 제거 |

**포팅·재사용 대상 (계약 동일 유지)**

- `vocabulary/*` 동사 시그니처 → GDScript 메서드명 후보
- `phases/*` reducer 규칙 → 상태기계 전이
- `data/*.json` + validator
- P0~P4 replay/headless 테스트 논리

---

## 프로토타입 잔여 임시조치 (M0에서 교체/보류 태그)

| 항목 | 위치 | M0 조치 |
|------|------|---------|
| `lobbyTerrainRenderState` | `ui/render/render-terrain.js` | M2 로비 UI 확정 후 제거 |
| UI vs headless 전투 이중 구현 | `vocabulary/combat` vs `RunSimulator` | D0-1로 하나로 수렴 또는 동기 테스트 |
| flat `phase` (`held: null` 등) | `phases/*` | M1에서 union 타입 문서화 또는 TS/GD 타입 분리 |
| `domain/run-progression.js` re-export | 호환 층 | M1 후 `HeadlessMiniRun` 직접 사용 |
| 브라우저 `index.html` 데모 | `public/` | 정식은 Godot; 데모 유지 여부 결정 |
| mono-color / freeze-test | `mini-run-app.js` | debug-only로 분류(M0 교체 목록) |

---

## 권장 작업 순서 (M0 → M1 착수)

1. **M0 결정 회의** — D0-1, D0-3, D0-6, D0-7, 폴더 구조, fixture 승격 (06 문서 완료 기준).
2. **프로토타입 계약 문서 1차** — snapshot, 이벤트 전이, 튜닝, JSON 스키마 (위 체크리스트).
3. **SoT 정렬** — UI 전투를 `RunSimulator`에 맞출지, presentation-only로 둘지; 필요 시 프로토타입 테스트 추가.
4. **M1 착수** — Godot domain + GUT replay; 브라우저는 회귀 참고용으로 유지.
5. **M2~M4** — 씬·보상·노드는 계약 고정 후 병렬 가능; M5는 M2 repair와 역할 조율 후.

---

## 관련 문서

| 문서 | 역할 |
|------|------|
| `06_M0_redesign_gate.md` | 유지/교체/보류 게이트 |
| `16_logical_capsule_refactor_plan.md` | 프로토타입 JS 구조(v2) |
| `01_P0` ~ `05_P4` | 슬라이스별 검증 범위 |
| `07_M1` ~ `15_M9` | 정식 구현 마일스톤 |

---

## 변경 이력

| 날짜 | 내용 |
|------|------|
| 2026-05-16 | 초안 — P4·v2 리팩터 반영, M1~M9 핸드오프 표 |
