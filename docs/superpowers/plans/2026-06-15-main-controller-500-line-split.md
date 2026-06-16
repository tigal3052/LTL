# Main Controller 500-Line Split Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Reduce `app-LTL/src/MainController.gd` to roughly 500 lines through verified feature splits, then consolidate overly small `MainController*.gd` helpers into feature-sized units.

**Architecture:** Keep `MainController.gd` as the `Main.tscn` scene-facing Node script and signal entry point. Move cohesive stateful flows into controller helpers that receive the controller as context, then later merge tiny pure helpers into the nearest feature owner once the large stateful splits are stable.

**Tech Stack:** Godot 4.3 GDScript, existing headless Godot contract runners, PowerShell harness gates.

---

### Task 1: Reward/Backpack Flow Split

**Files:**
- Create: `app-LTL/src/controllers/MainControllerRewardBackpackFlow.gd`
- Modify: `app-LTL/src/MainController.gd`
- Modify: `app-LTL/tests/ui_read_models/ui_interaction_controller_suite.gd`
- Modify: `app-LTL/tests/godot_contract_runner.gd`

- [x] **Step 1: Write the failing test**

Add a UI read-model structural test that loads `res://src/controllers/MainControllerRewardBackpackFlow.gd`, requires `MainController.gd` to preload it, requires reward/backpack entry points to delegate to it, and requires `MainController.gd` to be below the first split budget after this split.

- [x] **Step 2: Run RED**

Run:
```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools/invoke-godot.ps1 -ProjectPath app-LTL -Headless -Script tests/run_test_ui_read_models.gd
```

Expected before implementation: failure naming the missing reward/backpack flow helper and line-budget/delegation checks.

- [x] **Step 3: Implement reward/backpack flow**

Move reward/backpack drag, placement, discard, hover, reward-tray selection, and discard-zone logic into `MainControllerRewardBackpackFlow.gd`. Keep existing `MainController.gd` method names as signal/test wrappers that delegate to the helper.

- [x] **Step 4: Run GREEN**

Run:
```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools/invoke-godot.ps1 -ProjectPath app-LTL -Headless -Script tests/run_test_ui_read_models.gd
powershell -NoProfile -ExecutionPolicy Bypass -File tools/invoke-godot.ps1 -ProjectPath app-LTL -Headless -Script tests/run_main_start_flow_contract.gd
powershell -NoProfile -ExecutionPolicy Bypass -File tools/invoke-godot.ps1 -ProjectPath app-LTL -Headless -Script tests/godot_contract_runner.gd
```

Expected after implementation: `UI_READ_MODEL_TESTS_OK`, `MAIN_START_FLOW_CONTRACT_OK`, and `GODOT_CONTRACTS_OK`.

Result: reward/backpack flow is split into `MainControllerRewardBackpackFlow.gd`; the current `MainController.gd` line count is 1120, so the next rounds must use larger feature ownership moves rather than small helper extraction.

### Task 2: Combat Runtime Flow Split

**Files:**
- Create or consolidate: `app-LTL/src/controllers/MainControllerCombatFlow.gd`
- Modify: `app-LTL/src/MainController.gd`
- Modify: focused controller tests and contract runner lists

- [x] **Step 1: Write the failing test**

Add a structural test that requires combat click, hold-fire, timer, terrain marker, queue recalculation, and pause orchestration to delegate to the combat flow helper, and lowers the `MainController.gd` line budget again.

- [x] **Step 2: Run RED**

Run `run_test_ui_read_models.gd`; expected failure names the missing combat flow delegation and line budget.

- [x] **Step 3: Implement combat flow**

Move combat runtime orchestration from `MainController.gd` to `MainControllerCombatFlow.gd`. Keep pure combat input decisions inside the combat feature unit or merge `MainControllerCombatInput.gd` into it during final consolidation if doing so improves ownership.

- [x] **Step 4: Run GREEN**

Run UI read models, codex pause timing, battle render performance, node-select start gate, and full Godot contracts.

Result: combat runtime flow is split into `MainControllerCombatFlow.gd`; `MainController.gd` is 937 lines after this round, so further feature splits are still required.

### Task 3: Start/Scene/Support Flow Split

**Files:**
- Create or consolidate: `app-LTL/src/controllers/MainControllerRunFlow.gd`
- Create or consolidate: `app-LTL/src/controllers/MainControllerRenderFlow.gd`
- Create or consolidate: `app-LTL/src/controllers/MainControllerSupportFlow.gd`
- Create or consolidate: `app-LTL/src/controllers/MainControllerBootstrapFlow.gd`
- Modify: `app-LTL/src/MainController.gd`
- Modify: tests and source map

- [x] **Step 1: Write the failing test**

Add structural tests for start/reset/loadout/character/leviathan transition delegation and lower `MainController.gd` toward the 500-line target.

- [x] **Step 2: Implement and verify**

Move start/reset/loadout transition handlers and render/decorate handoff only where ownership remains clear. Run start-flow, i18n, node-select, UI read-model, and full Godot contracts.

Result: run, render, support, and bootstrap ownership moved into feature-sized helpers. `MainController.gd` reached 497 lines after the flow split and later 393 lines after helper consolidation.

### Task 4: Helper Consolidation And Final Gates

**Files:**
- Modify: `app-LTL/src/controllers/MainController*.gd`
- Modify: `docs/source-map.md`
- Modify: `docs/architectural-gates/runtime-size-gate.md`
- Modify: `docs/request-ledgers/2026-06-15-main-controller-ownership-split.md`
- Modify: worklog files

- [x] **Step 1: Consolidate tiny helpers**

Merge small helpers into feature-sized owners when they belong together, for example display/projection/combat-input helpers into combat or scene flow only if the resulting file remains clear and below caps.

- [x] **Step 2: Update gates and docs**

Set the new `MainController.gd` frozen cap to the verified line count near 500, map all final helper responsibilities, and update contract runner lists.

- [x] **Step 3: Final verification**

Run focused Godot contracts, full Godot contract runner, source-map gate, request-analysis gate, runtime-size gate, compile wrapper, and `git diff --check`. If runtime-size remains blocked by unrelated `MainViewRuntime.gd`, record that blocker without weakening this goal's evidence.

Result: merged the small start/node-selection helpers into `MainControllerRunFlow.gd`, combat input and scene projection into `MainControllerCombatFlow.gd`, and accessibility persistence into `MainControllerSupportFlow.gd`; deleted the obsolete helper files. `MainController.gd` is 393 lines, all final `MainController*.gd` helpers are below 500 lines, source-map/request-analysis/test-size/UI/Godot contract checks passed, and the broad compile wrapper is blocked only by the unrelated pre-existing `MainViewRuntime.gd` runtime-size cap breach.
