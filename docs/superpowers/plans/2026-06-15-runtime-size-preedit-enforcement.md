# Runtime Size Pre-Edit Enforcement Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the 500-line runtime size rule block risky implementation plans before editing, not only at completion.

**Architecture:** Extend the request-analysis pre-edit gate so runtime size caps from `docs/architectural-gates/runtime-size-gate.md` are resolved for paths listed in a request ledger's `Mutable Scope`. Exact debt/path caps and strict glob caps both produce monitored owners; any touched capped owner must declare a concrete execution responsibility unit, extraction target, and focused proof before implementation begins.

**Tech Stack:** PowerShell harness scripts, Markdown request ledgers, existing request-analysis self-tests.

---

### Task 1: Lock Glob-Capped Owner Coverage With RED

**Files:**
- Modify: `LTL-harness/tools/request-analysis-gate.tests.ps1`
- Test: `LTL-harness/tools/request-analysis-gate.tests.ps1`

- [x] Add a negative fixture whose `Mutable Scope` touches `app-LTL/src/scenes/pages/CharacterSelectPage.gd` without `Execution Responsibility Units`.
- [x] Add a positive fixture for the same glob-capped owner with `Unit`, `Extract to`, and `Focused proof`.
- [x] Run the request-analysis self-test and confirm RED: the negative fixture currently passes because the gate ignores `strict_glob_caps`.

### Task 2: Enforce Strict Glob Caps During Pre-Edit

**Files:**
- Modify: `LTL-harness/tools/request-analysis-gate.ps1`
- Test: `LTL-harness/tools/request-analysis-gate.tests.ps1`

- [x] Parse `strict_glob_caps` from `docs/architectural-gates/runtime-size-gate.md`.
- [x] Match backticked mutable-scope paths against exact caps and near-cap glob caps.
- [x] Require `Execution Responsibility Units` for every matched monitored runtime path.
- [x] Keep current exact legacy debt behavior unchanged.
- [x] Run the request-analysis self-test and confirm GREEN.

### Task 3: Document The Earlier Gate Point

**Files:**
- Modify: `LTL-harness/docs/request-analysis-execution-gate.md`
- Modify: `LTL-harness/docs/templates/request-constraint-ledger-template.md`
- Modify: `LTL-harness/00_AGENTS.md`

- [x] State that glob-capped runtime source and scene files are monitored at pre-edit time.
- [x] Add a compact file-size budget note to the ledger template.
- [x] Clarify that touching any capped runtime owner requires an execution unit and extraction target before implementation.

### Task 4: Verify And Report

**Files:**
- Modify: `docs/codex-worklog/plan_LootingTheLeviathan_2026-06-15.md`
- Modify: `docs/codex-worklog/history_LootingTheLeviathan_2026-06-15.md`
- Modify: `docs/codex-worklog/complete_LootingTheLeviathan_2026-06-15.md`

- [x] Run `powershell -NoProfile -ExecutionPolicy Bypass -File LTL-harness/tools/request-analysis-gate.tests.ps1`.
- [x] Run `powershell -NoProfile -ExecutionPolicy Bypass -File LTL-harness/tools/request-analysis-gate.ps1 -Ledger docs/request-ledgers/2026-06-11-runtime-size-cap-enforcement.md -Mode pre-edit` and report any existing ledger gaps honestly.
- [x] Run `powershell -NoProfile -ExecutionPolicy Bypass -File LTL-harness/tools/runtime-size-gate.tests.ps1`.
- [x] Update the worklog with implementation and verification results.
