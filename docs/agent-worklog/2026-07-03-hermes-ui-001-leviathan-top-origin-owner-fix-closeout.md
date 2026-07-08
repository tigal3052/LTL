# 2026-07-03 Leviathan top-origin owner fix

## Agent

- agent: hermes
- source: tui
- work_unit_id: hermes-2026-07-03-leviathan-top-origin-owner-fix
- objective_ids: UI-001, VERIFY-001
- status_at_closeout: done

## Goal

- Fix the Leviathan Select right-rail top-origin regression by proving the button-path wheel owner gap, applying the smallest owner-unification change, and re-running the focused/runtime/layout checks.

## Context Read

- `docs/agent-worklog/ACTIVE.md`
- `docs/agent-worklog/INDEX.md`
- `docs/agent-worklog/COMPACT.md`
- `docs/project-goals/final-goal.html`
- `docs/project-goals/work-objectives.html`
- `docs/source-map.md`
- `.hermes/plans/2026-07-03_165111-leviathan-top-origin-root-cause-plan.md`

## Raw Refs

- none

## Files Changed

- `app-LTL/src/scenes/pages/leviathan_select/LeviathanSelectRailScrollController.gd`: route wheel input through the hovered rail-card button owner too, and centralize GUI-event acceptance so button and scroll-container paths share one handled-state rule.
- `app-LTL/tests/run_leviathan_card_strip_scroll_contract.gd`: strengthen the focused contract with real pointer click coverage, a failing button-path wheel RED, and shared top-menu strip-origin wording for the recovered invariant.
- `docs/source-map.md`: refresh source-map fingerprints after the source/test edits.
- `docs/agent-worklog/2026-07-03-hermes-ui-001-leviathan-top-origin-owner-fix-closeout.md`: record the shared closeout.

## Decisions

- Treat the regression as an owner split, not a layout-metric bug: the hovered card button had drag ownership, but wheel ownership still lived only on the `ScrollContainer` path.
- Keep the production fix minimal by mirroring wheel handling into `handle_button_gui_input(...)` and reusing one `_accept_gui_event(...)` helper instead of reworking scene structure or scroll math.
- Keep validation focused on Leviathan contracts already tied to this page family instead of broad repo-wide compile/test passes.

## Validation

- `powershell -NoProfile -ExecutionPolicy Bypass -File 'D:/Programming/ex_workspace/LootingTheLeviathan/tools/invoke-godot.ps1' -Headless -Script 'D:/Programming/ex_workspace/LootingTheLeviathan/app-LTL/tests/run_leviathan_card_strip_scroll_contract.gd'` -> RED before the fix with `ERROR: wheel-down emitted to the hovered rail card button routes through the rail scroll owner instead of dying on the button path`.
- `powershell -NoProfile -ExecutionPolicy Bypass -File 'D:/Programming/ex_workspace/LootingTheLeviathan/tools/invoke-godot.ps1' -Headless -Script 'D:/Programming/ex_workspace/LootingTheLeviathan/app-LTL/tests/run_leviathan_card_strip_scroll_contract.gd'` -> `LEVIATHAN_CARD_STRIP_SCROLL_CONTRACT_OK` after the fix.
- `for script in app-LTL/tests/run_leviathan_card_strip_scroll_contract.gd app-LTL/tests/run_leviathan_select_runtime_contract.gd app-LTL/tests/run_leviathan_rail_cta_style_audit.gd app-LTL/tests/run_main_layout_audit_contract.gd; do powershell -NoProfile -ExecutionPolicy Bypass -File 'D:/Programming/ex_workspace/LootingTheLeviathan/tools/invoke-godot.ps1' -Headless -Script "D:/Programming/ex_workspace/LootingTheLeviathan/$script"; done` -> `LEVIATHAN_CARD_STRIP_SCROLL_CONTRACT_OK`, `LEVIATHAN_SELECT_RUNTIME_CONTRACT_OK`, `LEVIATHAN_RAIL_CTA_STYLE_AUDIT_OK`, `MAIN_LAYOUT_AUDIT_CONTRACT_OK` (runtime/layout scripts still print pre-existing Godot leak warnings on exit, but returned exit code 0).
- `powershell -NoProfile -ExecutionPolicy Bypass -File 'D:/Programming/ex_workspace/LootingTheLeviathan/LTL-harness/tools/source-map-gate.ps1' -Root . -Refresh` -> `SOURCE_MAP_REFRESH_OK` and `SOURCE_MAP_GATE_OK`.

## Failures / Root Cause

- `wheel-down emitted to the hovered rail card button routes through the rail scroll owner instead of dying on the button path`: the focused RED showed that `handle_button_gui_input(...)` only handled drag suppression/ownership, while wheel stepping existed only in `handle_scroll_gui_input(...)`. That split let the button path miss the rail snap owner. The fix adds wheel handling and handled-state acceptance to the button path too.

## Follow-ups

- Existing `run_leviathan_select_runtime_contract.gd` / `run_main_layout_audit_contract.gd` runs still emit Godot ObjectDB / CanvasItem leak warnings at exit; they did not fail this task, but the harness noise remains worth isolating separately.

## Compact Summary

- The real owner gap was not card geometry; it was wheel ownership split between hovered rail buttons and the scroll container.
- The focused Leviathan strip contract now proves the bug with a RED button-path wheel assertion, then verifies the recovered shared top-menu strip-origin behavior through both button-path and live-pointer wheel input.
- Minimal production change: `LeviathanSelectRailScrollController.gd` now steps wheel input from the rail-card button path and uses one `_accept_gui_event(...)` helper for button + scroll owners; focused/runtime/layout Leviathan checks all passed after the fix.
