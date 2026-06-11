# Leviathan Monument Condensed CTA Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Apply the approved `Monument Condensed` Leviathan-select direction so the target ribbon spans the hunt board and the CTA reads as a strong wide-screen progression control.

**Architecture:** Keep the existing Leviathan-select page and runtime flow, but promote the target ribbon and CTA into explicit board overlays instead of a narrow stacked footer inside the content column. Lock the approved copy and structure into contract tests first, then restyle the runtime to satisfy them.

**Tech Stack:** Godot 4 scene files (`.tscn`), GDScript runtime/theme overrides, existing Godot contract runners

---

### Task 1: Lock The Approved CTA Contract

**Files:**
- Modify: `app-LTL/tests/run_page_scene_mapping_contract.gd`
- Modify: `app-LTL/tests/run_main_layout_audit_contract.gd`

- [ ] **Step 1: Write the failing test assertions**

Add assertions that require:
- a dedicated `TargetRibbon` overlay node under `BoardPanel`
- a dedicated `StartButtonFrame` overlay node under `BoardPanel`
- CTA copy of `IMMEDIATE HANDOFF` and `LOOTING START`
- a taller CTA minimum height for the approved condensed treatment

- [ ] **Step 2: Run the focused contract tests to verify RED**

Run:
```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File ..\tools\invoke-godot.ps1 -Headless -Script tests/run_page_scene_mapping_contract.gd -Quit
```

Run:
```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File ..\tools\invoke-godot.ps1 -Headless -Script tests/run_main_layout_audit_contract.gd -Quit
```

Expected: both fail because the current Leviathan page still uses `TargetCard` and the earlier staged CTA copy/style.

### Task 2: Implement The Monument Condensed Overlay Layout

**Files:**
- Modify: `app-LTL/src/scenes/pages/LeviathanSelectPage.tscn`
- Modify: `app-LTL/src/scenes/pages/LeviathanSelectPage.gd`

- [ ] **Step 1: Replace the narrow stacked footer structure**

Promote the target ribbon and CTA from `Margin/VStack` children to explicit `BoardPanel` overlay nodes so the target lane can stretch edge-to-edge across the hunt board.

- [ ] **Step 2: Apply the approved condensed CTA styling**

Implement:
- darker industrial surface
- thin gold outline
- `Barlow Condensed`-like condensed hierarchy via font sizing/spacing choices
- `IMMEDIATE HANDOFF` kicker
- `LOOTING START` primary line

- [ ] **Step 3: Re-bind runtime references**

Update the Leviathan page script so the new overlay node paths and theme overrides stay authoritative.

### Task 3: Verify And Record

**Files:**
- Modify: `docs/codex-worklog/plan_LootingTheLeviathan_2026-06-07.md`
- Modify: `docs/codex-worklog/history_LootingTheLeviathan_2026-06-07.md`
- Modify: `docs/codex-worklog/complete_LootingTheLeviathan_2026-06-07.md`

- [ ] **Step 1: Re-run the focused contracts**

Run:
```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File ..\tools\invoke-godot.ps1 -Headless -Script tests/run_page_scene_mapping_contract.gd -Quit
```

Run:
```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File ..\tools\invoke-godot.ps1 -Headless -Script tests/run_main_layout_audit_contract.gd -Quit
```

Expected: both pass.

- [ ] **Step 2: Update worklog entries**

Record that the approved finalist was `6. Monument Condensed` and note the exact verification evidence.
