# Reward Cloud And Runtime Responsibility Gate Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Split the reward-card cloud runtime out of `MainViewRuntime.gd` and make pre-edit harness checks require responsibility-unit decomposition when a large runtime owner is touched.

**Architecture:** Keep `MainViewRuntime.gd` as the composition root, but move reward-card cloud rendering, floating layout, and drag-anchor behavior into a dedicated runtime helper. Strengthen the existing request-analysis pre-edit gate so any ledger that touches a monitored large runtime owner must declare the execution responsibility unit, companion helper path, and focused proof path before implementation begins.

**Tech Stack:** Godot 4.3 GDScript, split UI read-model suites, PowerShell harness gates, Markdown request/worklog docs.

---

### Task 1: Add failing reward-cloud helper tests

**Files:**
- Create: `D:\Programming\ex_workspace\LootingTheLeviathan\app-LTL\tests\ui_read_models\ui_reward_card_cloud_host_suite.gd`
- Modify: `D:\Programming\ex_workspace\LootingTheLeviathan\app-LTL\tests\test_ui_read_models.gd`
- Test: `D:\Programming\ex_workspace\LootingTheLeviathan\app-LTL\tests\run_test_ui_read_models.gd`

- [ ] **Step 1: Write the failing test**
- [ ] **Step 2: Run `tools/invoke-godot.ps1 -ProjectPath app-LTL -Headless -Script tests/run_test_ui_read_models.gd` and confirm it fails because `RewardCardCloudHost.gd` does not exist**
- [ ] **Step 3: Implement the minimal helper and delegate `MainViewRuntime.gd` to it**
- [ ] **Step 4: Re-run the same UI suite and confirm `UI_READ_MODEL_TESTS_OK`**

### Task 2: Add failing pre-edit responsibility-gate tests

**Files:**
- Modify: `D:\Programming\ex_workspace\LootingTheLeviathan\LTL-harness\tools\request-analysis-gate.tests.ps1`
- Modify: `D:\Programming\ex_workspace\LootingTheLeviathan\LTL-harness\tools\request-analysis-gate.ps1`
- Modify: `D:\Programming\ex_workspace\LootingTheLeviathan\LTL-harness\docs\request-analysis-execution-gate.md`
- Modify: `D:\Programming\ex_workspace\LootingTheLeviathan\LTL-harness\docs\templates\request-constraint-ledger-template.md`
- Modify: `D:\Programming\ex_workspace\LootingTheLeviathan\LTL-harness\00_AGENTS.md`

- [ ] **Step 1: Add a failing fixture where `Mutable Scope` touches `app-LTL/src/ui/MainViewRuntime.gd` without an `Execution Responsibility Units` section**
- [ ] **Step 2: Run `powershell -NoProfile -ExecutionPolicy Bypass -File LTL-harness/tools/request-analysis-gate.tests.ps1` and confirm it fails on the missing runtime-owner unit coverage**
- [ ] **Step 3: Implement the gate rule and documentation updates**
- [ ] **Step 4: Re-run the same self-test and confirm `REQUEST_ANALYSIS_GATE_TESTS_OK`**

### Task 3: Re-verify and publish the split

**Files:**
- Modify: `D:\Programming\ex_workspace\LootingTheLeviathan\docs\source-map.md`
- Modify: `D:\Programming\ex_workspace\LootingTheLeviathan\docs\request-ledgers\2026-06-11-m6-gate-fix-runtime-surgery.md`
- Modify: `D:\Programming\ex_workspace\LootingTheLeviathan\docs\codex-worklog\plan_LootingTheLeviathan_2026-06-11.md`
- Modify: `D:\Programming\ex_workspace\LootingTheLeviathan\docs\codex-worklog\history_LootingTheLeviathan_2026-06-11.md`
- Modify: `D:\Programming\ex_workspace\LootingTheLeviathan\docs\codex-worklog\complete_LootingTheLeviathan_2026-06-11.md`

- [ ] **Step 1: Run `powershell -NoProfile -ExecutionPolicy Bypass -File LTL-harness/tools/request-analysis-gate.ps1 -Ledger docs/request-ledgers/2026-06-11-m6-gate-fix-runtime-surgery.md -Mode pre-edit`**
- [ ] **Step 2: Run `powershell -NoProfile -ExecutionPolicy Bypass -File tools/invoke-godot.ps1 -ProjectPath app-LTL -Headless -Script tests/run_test_ui_read_models.gd`**
- [ ] **Step 3: Run `powershell -NoProfile -ExecutionPolicy Bypass -File tools/run-compile-check.ps1`**
- [ ] **Step 4: Run `powershell -NoProfile -ExecutionPolicy Bypass -File tools/run-ltl-quality-gate.ps1 -RequestLedger docs/request-ledgers/2026-06-11-m6-gate-fix-runtime-surgery.md -ArtifactLedger docs/artifact-ledgers/2026-06-11-m6-gate-fix-runtime-surgery.md`**
- [ ] **Step 5: Commit and push the verified result**
