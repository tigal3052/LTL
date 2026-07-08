# 2026-07-03 Leviathan preview-tail owner fix

## Agent

- agent: hermes
- source: tui
- work_unit_id: hermes-2026-07-03-leviathan-preview-tail-owner-fix
- objective_ids: UI-001, VERIFY-001
- status_at_closeout: done

## Goal

- Fix the Leviathan Select right-rail black preview-tail scroll regression by proving the reported input-owner split, unifying the preview surface with the real rail-card scroll owner, and re-running the focused/runtime/style/harness checks.

## Context Read

- `docs/agent-worklog/ACTIVE.md`
- `docs/agent-worklog/INDEX.md`
- `docs/agent-worklog/COMPACT.md`
- `docs/project-goals/final-goal.html`
- `docs/project-goals/work-objectives.html`
- `docs/source-map.md`
- `.hermes/plans/2026-07-03_172419-leviathan-black-gap-input-owner-replan.md`
- `docs/agent-worklog/2026-07-03-hermes-ui-001-leviathan-top-origin-owner-fix-closeout.md`

## Raw Refs

- none

## Files Changed

- `app-LTL/src/scenes/pages/leviathan_select/LeviathanSelectRailScrollController.gd`: added a shared surface-input path so preview-tail surfaces and real card buttons step wheel/drag through the same rail owner handling.
- `app-LTL/src/scenes/pages/leviathan_select/LeviathanSelectRailCardFactory.gd`: promoted preview tail cards from `MOUSE_FILTER_IGNORE` to a live GUI-input surface and connected them to the shared page callback.
- `app-LTL/src/scenes/pages/LeviathanSelectPage.gd`: wired real cards and preview cards through one rail-surface GUI-input callback; removed an unused preview-art helper and trimmed blank lines to stay inside the runtime-size cap.
- `app-LTL/tests/run_leviathan_card_strip_scroll_contract.gd`: strengthened the focused contract with the reported black preview-tail repro, point-owner probing, click-no-op assertions, and round-trip top-origin checks.
- `docs/project-goals/work-objectives.html`: logged the UI-001 follow-up proof for the preview-tail owner fix.
- `docs/source-map.md`: refreshed source-map coverage/fingerprint after source, test, plan, and objective-log edits.
- `docs/agent-worklog/2026-07-03-hermes-ui-001-leviathan-preview-tail-owner-fix-closeout.md`: recorded this shared closeout.

## Decisions

- Treat the reported black gap as a visible placeholder surface with the wrong input owner, not as empty space or a scroll-math bug.
- Keep the production fix minimal: reuse the existing rail scroll controller and feed preview-tail input into the same owner path instead of changing layout constants or scene hierarchy.
- Keep the validation stack page-local first, then finish with the existing compile wrapper using the relevant Leviathan request ledger rather than the stale default ledger path.

## Validation

- `powershell -NoProfile -ExecutionPolicy Bypass -File 'D:/Programming/ex_workspace/LootingTheLeviathan/tools/invoke-godot.ps1' -Headless -Script 'D:/Programming/ex_workspace/LootingTheLeviathan/app-LTL/tests/run_leviathan_card_strip_scroll_contract.gd'` -> RED before the fix after the new black preview-tail repro was added, with wheel/round-trip top-origin assertions failing once the reported region entered the sequence.
- `powershell -NoProfile -ExecutionPolicy Bypass -File 'D:/Programming/ex_workspace/LootingTheLeviathan/tools/invoke-godot.ps1' -Headless -Script 'D:/Programming/ex_workspace/LootingTheLeviathan/app-LTL/tests/run_leviathan_card_strip_scroll_contract.gd'` -> `LEVIATHAN_CARD_STRIP_SCROLL_CONTRACT_OK` after the owner-unification fix.
- `powershell -NoProfile -ExecutionPolicy Bypass -File 'D:/Programming/ex_workspace/LootingTheLeviathan/tools/invoke-godot.ps1' -Headless -Script 'D:/Programming/ex_workspace/LootingTheLeviathan/app-LTL/tests/run_leviathan_select_runtime_contract.gd'` -> `LEVIATHAN_SELECT_RUNTIME_CONTRACT_OK` (still emits the pre-existing ObjectDB leak warning on exit, exit code 0).
- `powershell -NoProfile -ExecutionPolicy Bypass -File 'D:/Programming/ex_workspace/LootingTheLeviathan/tools/invoke-godot.ps1' -Headless -Script 'D:/Programming/ex_workspace/LootingTheLeviathan/app-LTL/tests/run_leviathan_rail_cta_style_audit.gd'` -> `LEVIATHAN_RAIL_CTA_STYLE_AUDIT_OK`.
- `powershell -NoProfile -ExecutionPolicy Bypass -File 'D:/Programming/ex_workspace/LootingTheLeviathan/LTL-harness/tools/source-map-gate.ps1' -Root 'D:/Programming/ex_workspace/LootingTheLeviathan' -Refresh` -> `SOURCE_MAP_REFRESH_OK` and `SOURCE_MAP_GATE_OK`.
- `powershell -NoProfile -ExecutionPolicy Bypass -File 'D:/Programming/ex_workspace/LootingTheLeviathan/tools/run-compile-check.ps1' -RequestLedger 'docs/request-ledgers/2026-07-01-ui-001-leviathan-select-selected-card-shell-and-drag.md'` -> `REQUEST_ANALYSIS_GATE_OK`, `RUNTIME_SIZE_GATE_OK`, `PAGE_CONTRACT_GATE_OK`, `TRANSITION_SAFETY_GATE_OK`, and `Compilation Check: PASSED (GODOT_CONTRACTS_OK)`; the wrapper still prints pre-existing Godot RID/ObjectDB/resource leak warnings during contract shutdown.

## Failures / Root Cause

- The user-reported "black empty space" was not empty: it was the visible `LOCK` preview tail rendered by `LeviathanSelectRailCardFactory.gd` with `mouse_filter = IGNORE`, so wheel input fell through to a different owner path than the real rail-card buttons. That owner split let the selected-card/top-origin invariant break after interaction from the preview region. The fix makes preview-tail cards live input surfaces and routes them through the same shared rail scroll-owner logic as the real cards.
- `tools/run-compile-check.ps1` with no explicit ledger still points at a default request ledger that fails modern request-analysis requirements (`Root Cause Review` missing). This task used the relevant Leviathan request ledger explicitly so verification could complete without mutating unrelated historical request artifacts.

## Follow-ups

- The focused/runtime/compile runners still emit existing Godot leak warnings (`ObjectDB`, `CanvasItem`, RID/resource leak noise) on exit even when the contracts pass; that harness noise remains worth isolating separately.
- `app-LTL/tests/run_leviathan_card_strip_scroll_contract.gd` is now 463 lines and remains a legacy size-gate warning surface if this area is touched again.

## Compact Summary

- The reported black gap was actually a visible `LOCK` preview tail with `mouse_filter = IGNORE`, so wheel input bypassed the shared rail-card owner and drifted the top-origin invariant after selection.
- Minimal production fix: preview-tail cards are now live GUI-input surfaces wired into the same scroll controller path as real rail-card buttons.
- The focused strip contract now proves the preview-tail path, and the post-fix stack passed `LEVIATHAN_CARD_STRIP_SCROLL_CONTRACT_OK`, `LEVIATHAN_SELECT_RUNTIME_CONTRACT_OK`, `LEVIATHAN_RAIL_CTA_STYLE_AUDIT_OK`, refreshed source-map validation, and compile-check with the relevant Leviathan request ledger.
