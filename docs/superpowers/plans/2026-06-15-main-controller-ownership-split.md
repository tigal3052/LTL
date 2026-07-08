# Main Controller Ownership Split Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the empty `MainController.gd` facade plus oversized `MainControllerRuntime.gd` implementation with a real scene controller and focused controller helper scripts.

**Architecture:** Keep `app-LTL/src/Main.tscn` pointed at `res://src/MainController.gd`, but make that file own the controller implementation directly. Move pure or low-coupled controller decisions into `app-LTL/src/controllers/*.gd`, and update direct tests/docs to treat `MainController.gd` as the canonical controller script.

**Tech Stack:** Godot 4.3 GDScript, existing headless Godot contract runners, PowerShell harness gates.

---

### Task 1: Add RED Ownership Contracts

**Files:**
- Modify: `app-LTL/tests/godot_contract_runner.gd`
- Modify: `app-LTL/tests/ui_read_models/ui_interaction_controller_suite.gd`

- [x] **Step 1: Write failing structural checks**

Add checks that:
- `res://src/MainController.gd` compiles as the canonical controller.
- `res://src/MainControllerRuntime.gd` is not required as a formal runtime script.
- controller helper scripts exist and compile.
- `MainController.gd` does not only contain an `extends "res://src/MainControllerRuntime.gd"` facade.

- [x] **Step 2: Run RED**

Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools/invoke-godot.ps1 -ProjectPath app-LTL -Headless -Script tests/run_test_ui_read_models.gd
```

Expected before implementation: failure naming missing controller helper scripts or the old facade/runtime split.

### Task 2: Move Controller Ownership

**Files:**
- Replace: `app-LTL/src/MainController.gd`
- Delete or retire: `app-LTL/src/MainControllerRuntime.gd`

- [x] **Step 1: Move the implementation body**

Move the current implementation from `MainControllerRuntime.gd` into `MainController.gd` so the scene script is the actual controller.

- [x] **Step 2: Remove active runtime implementation ownership**

Delete `MainControllerRuntime.gd` if all references can move safely. If a compatibility file is required, keep it tiny and non-owning; it must not contain gameplay orchestration.

### Task 3: Extract Helper Units

**Files:**
- Create: `app-LTL/src/controllers/MainControllerStartFlow.gd`
- Create: `app-LTL/src/controllers/MainControllerNodeSelection.gd`
- Create: `app-LTL/src/controllers/MainControllerCombatInput.gd`
- Create: `app-LTL/src/controllers/MainControllerAccessibilityStore.gd`
- Modify: `app-LTL/src/MainController.gd`

- [x] **Step 1: Extract start-flow helper**

Move roster row construction, fallback/placeholder roster projection, selected character/leviathan lookup, and preview options to `MainControllerStartFlow.gd`.

- [x] **Step 2: Extract node-select helper**

Move selected-node context projection, empty node context, start-enabled checks, current-stage matching, cleared-route detection, and node-context-from-dict conversion to `MainControllerNodeSelection.gd`.

- [x] **Step 3: Extract combat input helper**

Move static combat decision helpers for target-color resolution, hold-fire continuation, combat-click acceptance, damage-popup projection, and hold-fire burst count to `MainControllerCombatInput.gd`.

- [x] **Step 4: Extract accessibility persistence helper**

Move state normalization and `ConfigFile` save/load to `MainControllerAccessibilityStore.gd`.

### Task 4: Update References And Docs

**Files:**
- Modify: tests that preload `res://src/MainControllerRuntime.gd`
- Modify: `docs/architectural-gates/runtime-size-gate.md`
- Modify: `docs/source-map.md`
- Modify: `docs/request-ledgers/2026-06-15-main-controller-ownership-split.md`

- [x] **Step 1: Move direct test preloads**

Change tests to preload `res://src/MainController.gd` or the specific helper script they are testing.

- [x] **Step 2: Update gate ownership**

Remove `MainControllerRuntime.gd` from runtime-size frozen debt and add helper files only under strict caps.

- [x] **Step 3: Update source map**

Describe `MainController.gd` as the scene controller owner and add concise entries for new helper scripts.

### Task 5: Verify

**Files:**
- Modify: `docs/codex-worklog/history_LootingTheLeviathan_2026-06-15.md`
- Modify: `docs/codex-worklog/complete_LootingTheLeviathan_2026-06-15.md`

- [x] **Step 1: Run focused tests**

Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools/invoke-godot.ps1 -ProjectPath app-LTL -Headless -Script tests/run_test_ui_read_models.gd
powershell -NoProfile -ExecutionPolicy Bypass -File tools/invoke-godot.ps1 -ProjectPath app-LTL -Headless -Script tests/run_i18n_localization_smoke.gd
powershell -NoProfile -ExecutionPolicy Bypass -File tools/invoke-godot.ps1 -ProjectPath app-LTL -Headless -Script tests/run_codex_pause_timing_contract.gd
powershell -NoProfile -ExecutionPolicy Bypass -File tools/invoke-godot.ps1 -ProjectPath app-LTL -Headless -Script tests/run_main_start_flow_contract.gd
powershell -NoProfile -ExecutionPolicy Bypass -File tools/invoke-godot.ps1 -ProjectPath app-LTL -Headless -Script tests/run_node_select_start_gate_contract.gd
powershell -NoProfile -ExecutionPolicy Bypass -File tools/invoke-godot.ps1 -ProjectPath app-LTL -Headless -Script tests/run_battle_render_performance_contract.gd
```

- [x] **Step 2: Run gates**

Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File LTL-harness/tools/runtime-size-gate.ps1 -Root .
powershell -NoProfile -ExecutionPolicy Bypass -File LTL-harness/tools/source-map-gate.ps1 -Root .
powershell -NoProfile -ExecutionPolicy Bypass -File tools/run-compile-check.ps1 -RequestLedger docs/request-ledgers/2026-06-15-main-controller-ownership-split.md
```

- [x] **Step 3: Record completion**

Update the request ledger verification notes, worklog history, and completion report with exact pass/fail evidence.
