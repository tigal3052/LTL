# 2026-06-30 UI-001 Leviathan Select runtime overlay rail closeout

## Agent

- agent: hermes
- source: hermes
- work_unit_id: ui-001-leviathan-select-runtime-overlay-rail-closeout
- objective_ids: UI-001
- status_at_closeout: done

## Goal

- Replace the old Leviathan Select runtime shell with the approved overlay-rail ownership while preserving existing selection/start flow, then close the step with repo-native proof.

## Context Read

- `AGENTS.md`
- `.agent-harness.json`
- `docs/project-goals/final-goal.html`
- `docs/project-goals/work-objectives.html`
- `docs/agent-worklog/ACTIVE.md`
- `docs/agent-worklog/INDEX.md`
- `docs/agent-worklog/COMPACT.md`
- `docs/request-ledgers/2026-06-30-ui-001-leviathan-select-runtime-overlay-rail-closeout.md`
- `app-LTL/src/scenes/pages/LeviathanSelectPage.tscn`
- `app-LTL/src/scenes/pages/LeviathanSelectPage.gd`
- `app-LTL/tests/run_page_scene_mapping_contract.gd`
- `app-LTL/tests/run_main_layout_audit_contract.gd`

## Raw Refs

- `docs/request-ledgers/2026-06-30-ui-001-leviathan-select-runtime-overlay-rail-closeout.md`
- Hermes session tool output for focused Godot runners, source-map gate, request-analysis gate, objective update, and compile-check.

## Files Changed

- `app-LTL/src/scenes/pages/LeviathanSelectPage.tscn`: rebuilt the page shell around `TopBar + GlobalRail + HeroShell + OverlayRail + bottom CTA dock`.
- `app-LTL/src/scenes/pages/LeviathanSelectPage.gd`: rewired page-local node ownership, responsive layout sequencing, preserved selection/start signals, and moved helper-worthy view logic out of the main owner.
- `app-LTL/src/scenes/pages/leviathan_select/LeviathanSelectViewBits.gd`: extracted page-local copy/style/card helpers so the runtime owner stays under the active size cap.
- `app-LTL/tests/run_page_scene_mapping_contract.gd`: updated the page mapping contract to assert the new overlay-rail owner instead of obsolete board/ribbon paths.
- `app-LTL/tests/run_main_layout_audit_contract.gd`: rewrote Leviathan Select layout assertions around flush-left rail, full hero stage, right overlay rail, and CTA docking.
- `docs/request-ledgers/2026-06-30-ui-001-leviathan-select-runtime-overlay-rail-closeout.md`: recorded mutable scope, preserved invariants, verification notes, and execution-responsibility coverage for this runtime step.
- `docs/source-map.md`: refreshed after runtime/test/doc changes.
- `docs/project-goals/work-objectives.html`: kept `UI-001` at `in-progress` and appended proof for the completed Leviathan Select runtime step.
- `docs/agent-worklog/2026-06-30-hermes-ui-001-leviathan-select-runtime-overlay-rail-closeout.md`: this shared closeout.

## Decisions

- Page-local ownership only: keep controller/data/i18n/gameplay flow unchanged and express the approved UI direction entirely inside Leviathan Select scene/script ownership.
- Helper extraction over broader refactor: split view builders into `LeviathanSelectViewBits.gd` instead of moving presentation logic into shared runtime owners or leaving the page oversized.
- Contract realignment instead of compatibility hacks: update the mapping/layout contracts to the approved owner decision rather than preserving obsolete node paths with fake wrapper nodes.
- Objective remains broader than this step: close this work unit as done, but keep `UI-001` itself `in-progress` because the art-direction objective still spans other pages.

## Validation

- `powershell -NoProfile -ExecutionPolicy Bypass -File tools/invoke-godot.ps1 -ProjectPath app-LTL -Headless -Script tests/run_page_scene_mapping_contract.gd` -> exit `0`, `PAGE_SCENE_MAPPING_CONTRACT_OK`.
- `powershell -NoProfile -ExecutionPolicy Bypass -File tools/invoke-godot.ps1 -ProjectPath app-LTL -Headless -Script tests/run_main_layout_audit_contract.gd` -> exit `0`, `MAIN_LAYOUT_AUDIT_CONTRACT_OK`.
- `powershell -NoProfile -ExecutionPolicy Bypass -File tools/invoke-godot.ps1 -ProjectPath app-LTL -Headless -Script tests/run_main_start_flow_contract.gd` -> exit `0`, `MAIN_START_FLOW_CONTRACT_OK`.
- `powershell -NoProfile -ExecutionPolicy Bypass -File LTL-harness/tools/source-map-gate.ps1 -Root . -Refresh` -> `SOURCE_MAP_REFRESH_OK`, `SOURCE_MAP_GATE_OK`.
- `powershell -NoProfile -ExecutionPolicy Bypass -File LTL-harness/tools/request-analysis-gate.ps1 -Ledger docs/request-ledgers/2026-06-30-ui-001-leviathan-select-runtime-overlay-rail-closeout.md -Mode pre-complete` -> `REQUEST_ANALYSIS_GATE_OK`.
- `powershell -NoProfile -ExecutionPolicy Bypass -File tools/run-compile-check.ps1 -RequestLedger docs/request-ledgers/2026-06-30-ui-001-leviathan-select-runtime-overlay-rail-closeout.md` -> exit `0`, `RUNTIME_SIZE_GATE_OK`, `PAGE_CONTRACT_GATE_OK`, `TRANSITION_SAFETY_GATE_OK`, `Compilation Check: PASSED (GODOT_CONTRACTS_OK)`.
- `powershell -NoProfile -ExecutionPolicy Bypass -File tools/project-objectives.ps1 -Mode update-status -ObjectiveId UI-001 -Status in-progress ...` -> `PROJECT_OBJECTIVE_GATE_UPDATE_OK`.
- `powershell -NoProfile -ExecutionPolicy Bypass -File tools/project-objectives.ps1 -Mode validate` -> `Objectives validated: 26`, `PROJECT_OBJECTIVE_GATE_VALIDATE_OK`.

## Failures / Root Cause

- Obsolete page contracts initially failed because they still asserted the removed `BoardPanel/TargetRibbon/StartButtonFrame` owner chain; fixed by rewriting the focused mapping/layout assertions to the approved overlay-rail owner.
- The first scene pass used `HeroShell` as a `PanelContainer`, which consumed child layout and broke the intended overlay geometry; fixed by switching that owner to `Panel` so overlay nodes keep their absolute placement.
- Helper extraction introduced GDScript type-inference parse failures around `surface_style(...)`; fixed by explicitly typing the returned values as `StyleBoxFlat`.

## Follow-ups

- `UI-001` still needs the same art-direction/runtime review on Character, Story, Node, Battle, Reward, and Defeat/Clear surfaces before the broader objective can close.
- Compile-check still reports legacy oversized test warnings plus existing Godot shutdown leak/anchor warnings; they remained non-blocking because the relevant gates passed with exit `0`.
- If Leviathan Select gains more page-local rendering logic later, continue splitting nearby helpers rather than regrowing the main page owner past the runtime cap.

## Compact Summary

- Leviathan Select now uses the approved runtime shell: flush-left global rail, full hero stage, right overlay roster rail, and CTA docked to the rail bottom, without changing controller/data/i18n flow ownership.
- The page owner stayed within the runtime-size gate by extracting `LeviathanSelectViewBits.gd`, and the focused proof triad passed: `PAGE_SCENE_MAPPING_CONTRACT_OK`, `MAIN_LAYOUT_AUDIT_CONTRACT_OK`, and `MAIN_START_FLOW_CONTRACT_OK`.
- Repo closeout evidence passed with the current request ledger: source-map refresh, request-analysis, objective validation, and `tools/run-compile-check.ps1` ending in `Compilation Check: PASSED (GODOT_CONTRACTS_OK)`.
