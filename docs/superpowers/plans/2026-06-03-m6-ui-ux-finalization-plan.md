# M6 UI/UX Finalization Implementation Plan

> **Refresh note (2026-06-04):** This June 3 plan captured the milestone intent, but parts of its file map and sequencing are now stale against the live tree. Use [`docs/superpowers/plans/2026-06-04-m6-ui-ux-finalization-refresh-plan.md`](D:/Programming/ex_workspace/LootingTheLeviathan/docs/superpowers/plans/2026-06-04-m6-ui-ux-finalization-refresh-plan.md) as the execution source of truth for current-source work.

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Turn the current M2-M5 combat, reward, node-map, and backpack systems into a readable, repeatable, accessibility-aware UI stack, while treating the codex-book redesign as a deliberate follow-on slice instead of the first blocking deliverable.

**Architecture:** Keep M6 inside the formal Godot path under `app-LTL/src/**` and make the UI a pure consumer of read models and presenters. Use a `core M6` boundary for playable-loop surfaces (`combat HUD`, `reward ceremony`, `node map`, `backpack organize`, `failure/retry`, `accessibility`, `QA evidence`) and a `stretch M6` boundary for meta-collection surfaces such as the artifact codex book UI.

**Tech Stack:** Godot 4.3, GDScript, Control-tree UI composition, `ui/read_models`, `ui/presenters`, existing Godot contract runners and scene smoke patterns.

---

## Scope Boundary

### Core M6

- Restore a clean verification baseline after the current M5/codex gate failures.
- Lock the combat HUD and feedback hierarchy so hazard/pulse/reward information is readable within one second.
- Finalize reward ceremony presentation and its handoff back to the reward tray and backpack flow.
- Finish the node-map, backpack organize, and failure/retry surfaces.
- Add accessibility controls, screenshot/scene-bounds QA, and a stable UI theme/style guide.

### Stretch M6

- Execute the approved artifact codex book redesign after core-loop surfaces are green, or in parallel only if it does not delay the core M6 exit criteria.
- Fold in additional release-art hooks from `docs/release-visual-quality-upgrade-plan.md` once the layout contracts are stable.

### Out Of Scope

- New combat rules, new hazard families, or new reward-balance systems beyond what is needed to restore the verification baseline.
- M7 narrative integration, M8 vertical-slice packaging, or M9 release-candidate work.
- Asset-production work that can remain on fallback art paths without blocking layout or readability validation.

## Task 1: Re-establish The M5/M6 Verification Baseline

**Files:**
- Modify: `docs/source-map.md`
- Modify: `app-LTL/tests/test_reward_contract.gd`
- Modify: `app-LTL/tests/test_ui_read_models.gd`
- Modify: `app-LTL/tests/test_combat_vocab.gd`
- Modify: the minimum required runtime files surfaced by those failures under `app-LTL/src/**`
- Possibly create later, only after green verification: `LTL-harness/docs/11_exec-plans/02_completed/11_M5_hazard_hierarchy_completed.md`

- [ ] **Step 1: Reproduce the current blockers exactly**

Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File LTL-harness/tools/milestone-gate.ps1 -TargetPlan 12_M6_ui_ux_finalization.md -Root D:\Programming\ex_workspace\LootingTheLeviathan
git diff --check
& 'D:\Programming\godot_workspace\bin\Godot_v4.3-stable_win64_console.exe' --headless --path 'D:\Programming\ex_workspace\LootingTheLeviathan\app-LTL' --script tests/godot_contract_runner.gd --disable-crash-handler --quit
powershell -NoProfile -ExecutionPolicy Bypass -File tools/run-compile-check.ps1
```

Expected today:

- milestone gate fails because `11_M5_hazard_hierarchy_completed.md` does not exist yet
- full contract runner fails on:
  - `ArtifactCodexReadModel.project(...)` arity mismatch in `test_reward_contract.gd`
  - invalid class-level `has_method()` calls in `test_ui_read_models.gd`
  - obstacle family rotation regression in `test_combat_vocab.gd`
- compile check fails early on `SOURCE_MAP_GATE_FAIL` for `ItemBook.png`

- [ ] **Step 2: Fix the repository-gate and parse-blocker layer before adding new M6 features**

Concrete work:

- add the missing `ItemBook.png` source-map entries
- either implement the codex projector signature used by the current tests or temporarily narrow the tests so the suite parses cleanly
- replace invalid class-level `has_method()` assertions with instance-safe checks
- keep this step focused on restoring a runnable suite, not on expanding feature scope

- [ ] **Step 3: Resolve or explicitly defer the remaining M5-specific failure**

Concrete work:

- re-run `tests/test_combat_vocab.gd`
- inspect `CombatVocab.shift_battlefield(...)` family ordering versus the M5 "all four families rotate under low pressure" contract
- either fix the runtime so four successive low-pressure waves expose four distinct families or narrow the contract/spec if the shipped M5 slice intentionally differs

- [ ] **Step 4: Re-run the baseline and capture fresh evidence**

Run:

```powershell
& 'D:\Programming\godot_workspace\bin\Godot_v4.3-stable_win64_console.exe' --headless --path 'D:\Programming\ex_workspace\LootingTheLeviathan\app-LTL' --script tests/godot_contract_runner.gd --disable-crash-handler --quit
powershell -NoProfile -ExecutionPolicy Bypass -File tools/run-compile-check.ps1
git diff --check
```

Expected:

- `GODOT_CONTRACTS_OK`
- compile/source-map gate passes
- no whitespace errors

- [ ] **Step 5: Close M5 only if the rerun evidence is clean**

If Step 4 is green:

- write `LTL-harness/docs/11_exec-plans/02_completed/11_M5_hazard_hierarchy_completed.md`
- summarize what the actual M5 slice includes, what was intentionally deferred, and the exact verification evidence

If Step 4 is not green:

- leave M5 open
- record blockers in the worklog and carry them forward as explicit M6 preflight debt

## Task 2: Lock The Combat HUD Readability Contract

**Files:**
- Modify: `app-LTL/src/ui/presenters/PhaseLayoutPresenter.gd`
- Modify: `app-LTL/src/ui/StatusPanelUI.gd`
- Modify: `app-LTL/src/ui/BattlefieldUI.gd`
- Modify: `app-LTL/src/ui/BattlefieldVFX.gd`
- Modify: `app-LTL/src/ui/TextCatalog.gd`
- Create or modify as needed: `app-LTL/src/ui/read_models/HudReadModel.gd`
- Modify: `app-LTL/tests/test_ui_read_models.gd`
- Create: `app-LTL/tests/test_ui_scene_smoke.gd`

- [ ] **Step 1: Add failing tests for one-second readability and non-color-only cues**

Tests must prove:

- the front queue item, weakness/mismatch, pin pressure, repair state, and hazard warning are all present in the HUD contract
- pulse/hazard/reward cues can be distinguished by icon, shape, border, or pattern, not only by color
- minimum-resolution layouts do not overlap text, timer, and combat chrome

- [ ] **Step 2: Introduce or tighten a HUD projection boundary**

Concrete work:

- keep `PhaseLayoutPresenter` and any new `HudReadModel` as the only source of HUD visibility and label state
- do not let scene code recompute combat or hazard logic
- centralize status icon and cue selection instead of spreading it across multiple UI controls

- [ ] **Step 3: Finalize battlefield/status/timer hierarchy**

Concrete work:

- ensure the timer, pin pressure, front-queue energy, and hazard warning remain readable during combat and reward-adjacent transitions
- preserve the existing reward-ceremony rule that the final combat snapshot stays visible during active ceremony beats
- add accessible cue variants for muted or audio-off usage

- [ ] **Step 4: Verify HUD contracts and smoke coverage**

Run:

```powershell
& 'D:\Programming\godot_workspace\bin\Godot_v4.3-stable_win64_console.exe' --headless --path 'D:\Programming\ex_workspace\LootingTheLeviathan\app-LTL' --script tests/run_test_ui_read_models.gd --quit
& 'D:\Programming\godot_workspace\bin\Godot_v4.3-stable_win64_console.exe' --headless --path 'D:\Programming\ex_workspace\LootingTheLeviathan\app-LTL' --script tests/godot_contract_runner.gd --disable-crash-handler --quit
```

Expected:

- `UI_READ_MODEL_TESTS_OK`
- `GODOT_CONTRACTS_OK`

## Task 3: Finish Reward Ceremony And Reward-Tray Handoff

**Files:**
- Modify: `app-LTL/src/ui/RewardRevealOverlay.gd`
- Modify: `app-LTL/src/ui/MainViewRuntime.gd`
- Modify: `app-LTL/src/ui/read_models/RewardReadModel.gd`
- Modify: `app-LTL/src/ui/presenters/RewardCeremonyPolicy.gd`
- Modify: `app-LTL/src/scenes/node_map/NodeMapScene.gd`
- Modify: `app-LTL/tests/run_reward_ceremony_contract.gd`
- Modify: `app-LTL/tests/test_ui_read_models.gd`

- [ ] **Step 1: Use the approved June 1 reward-ceremony spec as the source of truth**

Required behaviors:

- `count_tease -> count_lock -> reveal_queue -> tray_review`
- player-confirmed progression through the ceremony
- low-to-high rarity reveal order
- rarity VFX fixed by actual rarity tier
- tray and backpack interaction blocked until `tray_review`

- [ ] **Step 2: Add failing regression tests for the missing ceremony rules**

Tests must cover:

- no auto-dismiss before player confirm
- quantity bands `1-2`, `3`, `4-5`
- reveal-queue ordering
- tray and backpack input ownership
- stage 2+ node select no longer exposing starter color selection

- [ ] **Step 3: Keep presentation state explicit and localized**

Concrete work:

- keep ceremony step ownership in `MainViewRuntime` or controller-facing runtime state
- keep visibility rules in `RewardCeremonyPolicy`
- keep visuals in `RewardRevealOverlay`
- do not let tray or backpack widgets guess ceremony ownership from ad-hoc booleans

- [ ] **Step 4: Verify reward ceremony contracts**

Run:

```powershell
& 'D:\Programming\godot_workspace\bin\Godot_v4.3-stable_win64_console.exe' --headless --path 'D:\Programming\ex_workspace\LootingTheLeviathan\app-LTL' --script tests/run_reward_ceremony_contract.gd --quit
& 'D:\Programming\godot_workspace\bin\Godot_v4.3-stable_win64_console.exe' --headless --path 'D:\Programming\ex_workspace\LootingTheLeviathan\app-LTL' --script tests/godot_contract_runner.gd --disable-crash-handler --quit
```

Expected:

- `REWARD_CEREMONY_CONTRACT_OK`
- `GODOT_CONTRACTS_OK`

## Task 4: Finalize Node Map, Backpack Organize, And Failure/Retry Surfaces

**Files:**
- Modify: `app-LTL/src/scenes/node_map/NodeMapScene.gd`
- Modify: `app-LTL/src/ui/read_models/NodeMapReadModel.gd`
- Modify: `app-LTL/src/ui/BackpackUI.gd`
- Modify: `app-LTL/src/ui/InteractionFX.gd`
- Modify: `app-LTL/src/ui/presenters/BackpackPinLayoutPolicy.gd`
- Create: `app-LTL/src/ui/read_models/FailureReadModel.gd`
- Create: `app-LTL/src/scenes/failure/FailureRetryScene.tscn`
- Modify: `app-LTL/src/ui/MainViewRuntime.gd`
- Modify: `app-LTL/tests/test_ui_read_models.gd`
- Modify or create: `app-LTL/tests/test_ui_scene_smoke.gd`

- [ ] **Step 1: Add failing tests for three user-facing questions**

The UI must answer:

- which node is safest or riskiest and why
- what changed in the backpack or reward organization step
- why the run failed and what the next retry tip is

- [ ] **Step 2: Lock the node-map and backpack readability pass**

Concrete work:

- keep node risk, reward, and bias information compact and comparable
- preserve the approved backpack pin geometry and removal-order behavior
- keep drag-valid, drag-blocked, disabled, repair-locked, and hover states mechanically distinct

- [ ] **Step 3: Add a failure/retry surface with telemetry-safe read models**

Concrete work:

- project a primary failure cause plus one next-try hint
- keep retry and exit focus order explicit for keyboard or controller use
- do not let failure UI mutate the run-state reducers directly

- [ ] **Step 4: Verify loop-surface smoke coverage**

Run:

```powershell
& 'D:\Programming\godot_workspace\bin\Godot_v4.3-stable_win64_console.exe' --headless --path 'D:\Programming\ex_workspace\LootingTheLeviathan\app-LTL' --script tests/test_ui_scene_smoke.gd --quit
& 'D:\Programming\godot_workspace\bin\Godot_v4.3-stable_win64_console.exe' --headless --path 'D:\Programming\ex_workspace\LootingTheLeviathan\app-LTL' --script tests/godot_contract_runner.gd --disable-crash-handler --quit
```

Expected:

- new scene smoke runner passes
- full contract runner stays green

## Task 5: Accessibility, Theme, And Screenshot QA Matrix

**Files:**
- Create: `app-LTL/src/ui/theme/LTLTheme.tres`
- Modify: `app-LTL/src/ui/SettingsPanelUI.gd`
- Modify: `app-LTL/src/ui/TextCatalog.gd`
- Modify: `app-LTL/src/ui/MainViewRuntime.gd`
- Modify or create: screenshot or smoke helpers under `app-LTL/tests/**`
- Create: `docs/ui-style-guide.md`

- [ ] **Step 1: Add failing coverage for accessibility persistence and bounds checks**

Tests must prove:

- accessibility toggles persist
- tooltip placement clamps inside the viewport
- 1280x720, 1440x900, 1920x1080, and 16:10 bounds do not overlap critical text or icon zones

- [ ] **Step 2: Introduce the stable theme and option surfaces**

Concrete work:

- centralize button, panel, and icon styling in `LTLTheme.tres`
- expose reduced shake, flash, and particle-intensity options
- preserve the "hold-fire assist" decision as an explicit settings-level toggle if approved

- [ ] **Step 3: Capture and review the screenshot matrix**

Artifacts required:

- combat HUD
- reward ceremony and tray review
- node map
- backpack organize
- failure/retry surface

- [ ] **Step 4: Write the style guide and known-issue summary**

The guide must record:

- frame language
- icon or pattern usage for non-color-only cues
- minimum readability rules
- accepted fallback-art behavior
- known UI issues by severity

## Task 6: Stretch Slice - Artifact Codex Book UI

**Files:**
- Execute later against the detailed plan in `docs/superpowers/plans/2026-06-03-artifact-codex-book-implementation-plan.md`

- [ ] **Step 1: Promote codex-book into active execution only after Task 1 is green**

Guardrails:

- do not let codex-book parse or source-map work keep the full suite permanently red
- keep codex-book state ownership in `MainViewRuntime` and read-model projection layers
- preserve the approved `ItemBook.png`, left-detail/right-grid, ratio-safe-area, and page-local-scroll rules

- [ ] **Step 2: Decide whether codex-book is a core M6 deliverable or a post-core M6 slice**

Recommended default:

- core M6 exit does not depend on codex-book
- codex-book proceeds in parallel or immediately after core M6 verification turns green

## Verification Summary

Core M6 is ready to call complete only when all of the following are true:

- M5 closure evidence is clean enough that the M6 milestone is not blocked on prior-phase uncertainty
- `UI_READ_MODEL_TESTS_OK`, `REWARD_CEREMONY_CONTRACT_OK`, and `GODOT_CONTRACTS_OK` all pass on the same current tree
- source-map and compile gates pass
- screenshot matrix exists for supported resolutions
- accessibility and failure/retry evidence is recorded
- any remaining gaps are explicitly listed as known issues instead of being silently deferred
