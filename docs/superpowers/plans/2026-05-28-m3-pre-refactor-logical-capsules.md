# M3 사전 리팩토링 논리 캡슐 구현 계획

> **에이전트 작업자 필수 지침:** 이 계획을 작업 단위로 구현할 때는 반드시 `superpowers:subagent-driven-development`(권장) 또는 `superpowers:executing-plans`를 사용한다. 진행 추적을 위해 단계는 체크박스(`- [ ]`) 문법을 사용한다.

**목표:** M3 보상/진행도 구현에 들어가기 전에 `MainController.gd`와 `MainUI.gd`를 얇은 조립 셸로 줄이고, 게임플레이 의사결정을 테스트 가능한 논리 기반 캡슐로 이동한다.

**아키텍처:** 작은 vocabulary 함수와 phase reducer를 핵심 논리 단위로 사용한다. `Artifact`, `InventoryModel`, `CombatSimulator`, view node처럼 정체성이나 내부 불변식이 안정적으로 필요한 명사에는 OOP를 유지한다. UI node는 사용자 의도를 signal로 방출하고 read model을 렌더링한다. controller는 의도를 phase event로 번역한 뒤 기능별 presenter에 위임한다.

**기술 스택:** Godot 4.3 GDScript, `app-LTL/src/process` 아래의 기존 headless runtime, `app-LTL/src/phases` 아래의 phase reducer, `app-LTL/src/vocabulary` 아래의 vocabulary 함수, Godot contract runner 테스트.

---

## 검토 결과

M2는 시각적/구조적으로 유용하지만, 아키텍처 마일스톤으로는 깔끔하게 완료됐다고 보기 어렵다.

- `app-LTL/src/MainController.gd`는 아키텍처 게이트 출력 기준 662줄이며, 여전히 input router, reward presenter, inventory placement service, growth service, telemetry printer, combat timer mutator, queue recalculator, VFX state manager, log author 역할을 동시에 수행한다.
- `app-LTL/src/ui/MainUI.gd`는 아키텍처 게이트 출력 기준 756줄이며, 하나의 view script 안에서 shop UI, giant timer UI, heartbeat audio, tooltip content, phase visibility, VFX positioning을 모두 만든다.
- M2 게이트는 `ARCHITECTURAL_GATE_OK`를 반환하지만, 그 전에 `MainController.gd`, `MainUI.gd`, `BattlefieldUI.gd`, `BackpackUI.gd`, `StatusPanelUI.gd`가 threshold를 초과한다는 경고를 낸다. M3 전에 이 상태를 soft fail로 취급한다.
- M2 완료 문서에는 "Remaining Gaps: None"이라고 되어 있지만, 현재 소스에는 M3 성격의 reward/growth/shop logic이 M2 scene 파일 안에 포함되어 있다.
- compile wrapper인 `tools/run-compile-check.ps1`는 현재 Godot 실행 전 `Start-Process`가 중복 `Path/PATH` environment key를 받아 실패한다. 직접 Godot headless 실행도 signal 11로 crash하므로, 안정적인 테스트 명령 없이 M3로 넘어가면 안 된다.

## 경계 규칙

- `MainController.gd` 목표: 180줄 미만. signal binding, 현재 scene snapshot 보관, feature coordinator로 dispatch만 허용한다. reward 계산, raw run state mutation, artifact 생성, UI text 합성은 금지한다.
- `MainUI.gd` 목표: 220줄 미만. top-level node reference 보유, raw UI control을 signal에 연결, subview로 위임만 허용한다. 큰 dynamic panel 생성, tooltip stats 합성, layout presenter를 거치지 않은 phase-specific visibility 결정은 금지한다.
- `ui/*UI.gd` 목표: domain decision이 없는 재사용 component가 아닌 한 150줄 미만.
- 모든 gameplay verb는 `vocabulary/<domain>/<Verb>.gd` 또는 집중된 기존 vocabulary 파일에 둔다.
- 모든 phase transition은 `phases/<PhaseName>.gd`에 둔다.
- scene에 노출되는 모든 projection은 `ui/read_models/*ReadModel.gd`에 둔다.
- UI 전용 composition panel은 `ui/panels` 또는 `ui/widgets` 아래의 독립 view node script로 둔다.
- process/runtime layer 밖에서 `preview_controller.run.state[...]`에 직접 쓰는 것을 금지한다.

## 목표 파일 구조

- Modify: `app-LTL/src/MainController.gd`
- Modify: `app-LTL/src/ui/MainUI.gd`
- Modify: `app-LTL/src/process/HeadlessMiniRun.gd`
- Modify: `app-LTL/src/process/CombatInputAdapter.gd`
- Modify: `app-LTL/src/process/MiniRunStageScript.gd`
- Modify: `app-LTL/src/phases/PhaseReducers.gd`
- Modify: `app-LTL/src/phases/RewardLootPhase.gd`
- Create: `app-LTL/src/phases/BackpackOrganizePhase.gd`
- Create: `app-LTL/src/vocabulary/backpack/PickUpFromInventory.gd`
- Create: `app-LTL/src/vocabulary/backpack/PickUpFromRewardTray.gd`
- Create: `app-LTL/src/vocabulary/backpack/RotateHeld.gd`
- Create: `app-LTL/src/vocabulary/backpack/PlaceHeld.gd`
- Create: `app-LTL/src/vocabulary/backpack/DiscardHeld.gd`
- Create: `app-LTL/src/vocabulary/backpack/RecalculateSynergy.gd`
- Create: `app-LTL/src/vocabulary/reward/CreateArtifactFromReward.gd`
- Create: `app-LTL/src/vocabulary/reward/ApplyRewardEffect.gd`
- Create: `app-LTL/src/vocabulary/progression/ApplyGrowthModifiers.gd`
- Create: `app-LTL/src/vocabulary/combat/RecalculateQueueColors.gd`
- Create: `app-LTL/src/vocabulary/combat/ShiftWeaknessMarkers.gd`
- Create: `app-LTL/src/ui/read_models/NodeSelectReadModel.gd`
- Modify: `app-LTL/src/ui/read_models/RewardReadModel.gd`
- Create: `app-LTL/src/ui/read_models/BackpackReadModel.gd`
- Create: `app-LTL/src/ui/read_models/ShopReadModel.gd`
- Create: `app-LTL/src/ui/read_models/TooltipReadModel.gd`
- Create: `app-LTL/src/ui/panels/ShopPanelUI.gd`
- Create: `app-LTL/src/ui/panels/GiantTimerUI.gd`
- Create: `app-LTL/src/ui/panels/ArtifactTooltipUI.gd`
- Create: `app-LTL/src/ui/presenters/PhaseLayoutPresenter.gd`
- Create: `app-LTL/src/ui/presenters/RewardPresenter.gd`
- Create: `app-LTL/src/ui/presenters/CombatFeedbackPresenter.gd`
- Create: `app-LTL/src/ui/presenters/BackpackInteractionPresenter.gd`
- Modify: `app-LTL/tests/godot_contract_runner.gd`
- Modify: `app-LTL/tests/test_reward_contract.gd`
- Create: `app-LTL/tests/test_backpack_vocab.gd`
- Create: `app-LTL/tests/test_main_scene_boundary.gd`

## Task 1: 검증 경로 안정화

**Files:**
- Modify: `tools/run-compile-check.ps1`
- Modify: `app-LTL/tests/godot_contract_runner.gd`

- [ ] compile wrapper를 수정해 중복 environment key 실패 없이 Godot을 실행하게 한다. 문서화된 실행 방식은 `-NoProfile -ExecutionPolicy Bypass`를 유지한다.
- [ ] full headless scene path가 crash할 때도 전체 scene을 열지 않고 script만 load하는 smoke-only contract runner mode를 추가한다.
- [ ] `powershell -NoProfile -ExecutionPolicy Bypass -File tools/run-compile-check.ps1`를 실행한다.
- [ ] 기대 결과: 명령이 exit code 0으로 종료되고 `GODOT_CONTRACTS_OK`를 출력한다.
- [ ] commit message: `test: stabilize godot contract runner`.

## Task 2: 논리 이동 전 경계 게이트 추가

**Files:**
- Modify: `docs/architectural-gates/m2-refactoring-gate.md`
- Modify: 기존 gate가 warning threshold에서 실패할 수 없다면 `LTL-harness/tools/architectural-gate.ps1`

- [ ] 현재 size warning을 `MainController.gd`와 `MainUI.gd`에 대한 hard failure로 전환한다.
- [ ] UI/controller 파일에 대한 raw runtime write 금지 패턴을 추가한다: `run.state[`, `pendingRewards`, `claim_reward_effect`, `purchase_passive`, `Button.new`, `PanelContainer.new`, `AudioStreamWAV.new`.
- [ ] gate를 실행해 현재 코드에서 실패하는지 확인한다.
- [ ] 통과시키기 위해 gate를 약화하지 않는다. 이후 task들이 코드를 gate에 맞춰야 한다.
- [ ] commit message: `test: enforce main scene boundary gate`.

## Task 3: Backpack Vocabulary 추출

**Files:**
- Create files under `app-LTL/src/vocabulary/backpack/`
- Modify: `app-LTL/src/phases/RewardLootPhase.gd`
- Create: `app-LTL/tests/test_backpack_vocab.gd`

- [ ] `MainController.gd`에 있는 duplicate placement check를 `PlaceHeld.gd`로 이동한다.
- [ ] grid에서 item을 집는 동작을 `PickUpFromInventory.gd`로 이동한다.
- [ ] reward tray에서 item을 집는 동작을 `PickUpFromRewardTray.gd`로 이동한다.
- [ ] rotation 동작을 `RotateHeld.gd`로 이동한다.
- [ ] discard 동작을 `DiscardHeld.gd`로 이동한다.
- [ ] placement 이후 synergy calculation을 `RecalculateSynergy.gd`로 이동한다.
- [ ] 테스트는 collision, out-of-bounds placement, duplicate drill-color guard, successful placement 이후에만 reward가 제거되는지, last-artifact guard를 다뤄야 한다.
- [ ] commit message: `refactor: extract backpack vocabulary`.

## Task 4: Reward Loot와 Backpack Organize Phase 분리

**Files:**
- Modify: `app-LTL/src/process/MiniRunStageScript.gd`
- Modify: `app-LTL/src/phases/PhaseReducers.gd`
- Modify: `app-LTL/src/phases/RewardLootPhase.gd`
- Create: `app-LTL/src/phases/BackpackOrganizePhase.gd`
- Modify: `app-LTL/src/process/HeadlessMiniRun.gd`
- Modify: `app-LTL/src/process/CombatInputAdapter.gd`

- [ ] `STAGE_SENTENCE`가 `reward_loot` 뒤에 `backpack_organize`를 포함하게 한다.
- [ ] `reward_loot`는 pending reward tray state와 held-from-reward state만 책임진다.
- [ ] `backpack_organize`는 reward pickup 이후 inventory movement와 node selection 이전의 선택적 cleanup을 책임진다.
- [ ] item을 들고 있거나 inventory decision이 남아 있으면 `finish_loot`가 `backpack_organize`로 전환하고, 그렇지 않으면 `node_select` 또는 `run_complete`로 전환하게 한다.
- [ ] 테스트는 `reward_loot -> backpack_organize -> node_select`를 다뤄야 한다.
- [ ] commit message: `refactor: split loot and backpack phases`.

## Task 5: Reward Artifact와 Growth Logic 추출

**Files:**
- Create: `app-LTL/src/vocabulary/reward/CreateArtifactFromReward.gd`
- Create: `app-LTL/src/vocabulary/reward/ApplyRewardEffect.gd`
- Create: `app-LTL/src/vocabulary/progression/ApplyGrowthModifiers.gd`
- Modify: `app-LTL/src/phases/RewardLootPhase.gd`
- Modify: `app-LTL/src/models/RunGrowthState.gd`
- Modify: `app-LTL/tests/test_reward_contract.gd`

- [ ] reward-to-artifact conversion을 `MainController.gd` 밖으로 이동한다.
- [ ] name substring 기반 shape detection을 payload/table-driven artifact field로 대체한다.
- [ ] rarity 기반 gold/xp calculation을 `RewardLootPhase.gd`에서 `ApplyRewardEffect.gd`로 이동한다.
- [ ] cooldown/damage modifier application을 `MainController.gd`에서 `ApplyGrowthModifiers.gd`로 이동한다.
- [ ] 테스트는 artifact shape, item type, energy type, cooldown, damage, beacon modifier, gold/xp gain, reward history를 검증해야 한다.
- [ ] commit message: `refactor: extract reward and growth vocabulary`.

## Task 6: Combat Utility Vocabulary 추출

**Files:**
- Create: `app-LTL/src/vocabulary/combat/RecalculateQueueColors.gd`
- Create: `app-LTL/src/vocabulary/combat/ShiftWeaknessMarkers.gd`
- Modify: `app-LTL/src/phases/CombatPhase.gd`
- Modify: `app-LTL/src/MainController.gd`

- [ ] queue-color recalculation을 `MainController.gd` 밖으로 이동한다.
- [ ] shifting weakness marker behavior를 `_on_shift_timer_timeout` 밖으로 이동한다.
- [ ] 가능한 경우 random marker mutation을 seeded state input으로 대체한다.
- [ ] controller timer는 `tick` event만 emit해야 하며, combat phase가 marker movement를 처리한다.
- [ ] 테스트는 deterministic marker shifting과 inventory 기반 queue color calculation을 검증해야 한다.
- [ ] commit message: `refactor: extract combat utility vocabulary`.

## Task 7: Read Model과 Presenter 추출

**Files:**
- Create/modify read models under `app-LTL/src/ui/read_models/`
- Create presenters under `app-LTL/src/ui/presenters/`
- Modify: `app-LTL/src/MainController.gd`
- Modify: `app-LTL/src/ui/MainUI.gd`

- [ ] node select rich text generation을 `NodeSelectReadModel.gd`로 이동한다.
- [ ] reward text/discard-zone text generation을 `RewardReadModel.gd`와 `RewardPresenter.gd`로 이동한다.
- [ ] tooltip stat text를 `TooltipReadModel.gd`로 이동한다.
- [ ] phase visibility decision을 `PhaseLayoutPresenter.gd`로 이동한다.
- [ ] combat log와 screenshake decision을 `CombatFeedbackPresenter.gd`로 이동한다.
- [ ] Main controller는 snapshot과 event를 전달해야 하며, BBCode string을 formatting하지 않아야 한다.
- [ ] commit message: `refactor: extract scene read models and presenters`.

## Task 8: Dynamic UI Panel 추출

**Files:**
- Create: `app-LTL/src/ui/panels/ShopPanelUI.gd`
- Create: `app-LTL/src/ui/panels/GiantTimerUI.gd`
- Create: `app-LTL/src/ui/panels/ArtifactTooltipUI.gd`
- Modify: `app-LTL/src/ui/MainUI.gd`
- Modify: `app-LTL/src/Main.tscn`

- [ ] shop panel creation과 render behavior를 `ShopPanelUI.gd`로 이동한다.
- [ ] timer/vignette/heartbeat behavior를 `GiantTimerUI.gd`로 이동한다.
- [ ] tooltip panel creation과 positioning을 `ArtifactTooltipUI.gd`로 이동한다.
- [ ] `Main.tscn`에 scene-owned child node를 두는 방식을 우선한다. dynamic creation은 각 panel script 내부에만 둔다.
- [ ] `MainUI.gd`는 panel method와 signal을 노출하되 panel 내부를 직접 구성하지 않아야 한다.
- [ ] commit message: `refactor: split main ui panels`.

## Task 9: MainController 얇게 만들기

**Files:**
- Modify: `app-LTL/src/MainController.gd`

- [ ] `_ready` signal wiring은 유지한다.
- [ ] 작은 `dispatch_ui_event(event)` 또는 동등한 bridge를 유지한다.
- [ ] reward list ownership, held artifact mutation, growth mutation, shop purchase mutation, direct runtime state write, BBCode formatting을 제거한다.
- [ ] 모든 gameplay change는 `CombatScenePreviewController` 또는 `HeadlessMiniRun`의 public method를 통해 route한다.
- [ ] 180줄 미만을 목표로 한다.
- [ ] commit message: `refactor: reduce main controller to composition shell`.

## Task 10: MainUI 얇게 만들기

**Files:**
- Modify: `app-LTL/src/ui/MainUI.gd`

- [ ] top-level node reference와 signal forwarding은 유지한다.
- [ ] shop, timer, tooltip, reward panel, status panel, backpack panel, battlefield panel, settings panel behavior를 위임한다.
- [ ] 큰 dynamic UI builder를 이 파일에서 제거한다.
- [ ] 220줄 미만을 목표로 한다.
- [ ] commit message: `refactor: reduce main ui to composition shell`.

## Task 11: 최종 M3 준비 게이트

**Files:**
- Modify: `docs/architectural-gates/m2-refactoring-gate.md`
- Modify: M3 진입 기준을 명시적으로 갱신해야 한다면 `LTL-harness/docs/11_exec-plans/01_active/09_M3_reward_and_progression.md`

- [ ] architecture gate를 실행하고 `MainController.gd`와 `MainUI.gd`에 warning이 없도록 요구한다.
- [ ] compile/contract check를 실행한다.
- [ ] reward, backpack, phase-transition test를 실행한다.
- [ ] remaining accepted risk를 나열하는 짧은 M3 readiness note를 추가한다.
- [ ] commit message: `docs: record m3 refactor readiness`.

## M3 진입 기준

- `MainController.gd`는 composition/dispatch shell 역할만 한다.
- `MainUI.gd`는 top-level view facade 역할만 한다.
- UI/controller 파일이 `preview_controller.run.state`에 직접 쓰지 않는다.
- reward selection, reward effect, backpack placement, queue recalculation, weakness shifting, growth modifier가 각각 독립적으로 test 가능한 vocabulary function이다.
- `reward_loot`와 `backpack_organize`는 별도 phase tag이거나, 의도적으로 합친 경우에도 별도 reducer와 별도 test를 가진다.
- Godot contract verification은 안정적이고 반복 가능하다.
- architecture gate는 boundary regression이 생기면 warning을 출력하고 OK를 반환하는 대신 실패한다.

## 실행 권장사항

위 순서대로 진행한다. 시각적 정리부터 시작하지 않는다. 첫 번째 실질적 승리는 test command와 architecture gate를 신뢰 가능하게 만드는 것이다. 그렇지 않으면 리팩토링이 겉으로만 깨끗해 보이고 같은 coupling을 조용히 보존할 수 있다.
