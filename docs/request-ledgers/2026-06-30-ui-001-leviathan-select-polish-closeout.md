# 2026-06-30 UI-001 Leviathan Select polish closeout

## Request Summary

- Align the Leviathan Select page to the approved sky / exploration / cold-stone art direction using the already approved five-step polish sequence.
- Keep page flow, data, copy, and gameplay ownership unchanged; only adjust layout proportion, surface styling, text hierarchy, roster affordance, and chrome finish.
- Close the change with focused layout/page proof plus repo-level source-map, request-analysis, and compile-check evidence.

## Preserved Invariants

- The approved `character_select -> leviathan_select -> node_select` flow remains unchanged.
- No controller, reducer, data-table, i18n-key, or gameplay-state ownership changes are introduced.
- Existing non-Leviathan pages remain outside this change set.
- Existing dirty worktree changes outside the Leviathan Select polish scope are not reverted.

## Mutable Scope

- `app-LTL/src/scenes/pages/LeviathanSelectPage.gd`
- `app-LTL/src/scenes/pages/LeviathanSelectPage.tscn`
- `docs/source-map.md`
- `docs/request-ledgers/2026-06-30-ui-001-leviathan-select-polish-closeout.md`
- `docs/project-goals/work-objectives.html`
- `docs/agent-worklog/2026-06-30-hermes-ui-001-leviathan-select-polish-closeout.md`
- `docs/agent-worklog/INDEX.md`
- `docs/agent-worklog/COMPACT.md`

## Source Map Findings

- `docs/source-map.md`
  - The live source map is the formal coverage/freshness surface and must be refreshed after the Leviathan Select page files and closeout docs change.
- `app-LTL/src/scenes/pages/LeviathanSelectPage.tscn`
  - The scene file is the runtime shell that owns Leviathan Select layout proportion, containment, and anchored presentation structure.
- `app-LTL/src/scenes/pages/LeviathanSelectPage.gd`
  - The page controller owns per-page theme overrides, text hierarchy, roster affordance styling, and responsive spacing for the Leviathan Select surface.
- `app-LTL/tests/run_main_layout_audit_contract.gd`
  - The focused layout audit runner is the proof surface for viewport-safe containment after the visual polish.
- `app-LTL/tests/run_page_scene_mapping_contract.gd`
  - The page mapping runner is the guard that this polish did not mutate page ownership or scene routing.

## Root Cause Review

- Observed symptom: Leviathan Select still read as darker, more metallic, and less legible than the approved final-goal direction and the Character Select reference surface.
- Evidence: baseline review showed a brass-leaning board, near-black target ribbon, weaker text hierarchy, and understated roster selection/hover affordance compared with the newer exploration-oriented UI direction.
- Root cause target: `app-LTL/src/scenes/pages/LeviathanSelectPage.gd`
- Supporting surface: `app-LTL/src/scenes/pages/LeviathanSelectPage.tscn` still carried matching page-local layout/theme constants from the older darker treatment.
- Rejected workaround: add new logic, copy, flow changes, or extra assets to compensate for readability and direction drift.
- Chosen fix: execute a five-step visual-only polish sequence limited to layout, surface tone, text hierarchy, roster affordance, and shared chrome consistency on Leviathan Select.

## Transition Safety Review

- no transition impact
- reason: page routing, signals, selected-leviathan data handoff, and page-scene mapping owners remain unchanged; this work only adjusts scene/theme constants on an existing page.
- guard runner: `app-LTL/tests/run_main_layout_audit_contract.gd`
- guard marker: `MAIN_LAYOUT_AUDIT_CONTRACT_OK`
- mapping runner: `app-LTL/tests/run_page_scene_mapping_contract.gd`
- mapping marker: `PAGE_SCENE_MAPPING_CONTRACT_OK`

## Feature Unit Lifecycle Plan

- Design stage: keep Leviathan Select polish approval-gated by a single visual axis at a time so layout, tone, hierarchy, affordance, and chrome can be verified independently.
- Implementation stage: confine runtime edits to `LeviathanSelectPage.gd` and `LeviathanSelectPage.tscn` instead of spreading visual state into controllers, data tables, or gameplay phases.
- Maintenance stage: future Leviathan UI passes should refresh `docs/source-map.md` and rerun layout/page contracts before claiming broader compile acceptance.
- Capsule boundary: Leviathan Select owns this presentation polish locally; page-flow ownership remains outside scope.
- Size trigger: if the same chrome rules must be repeated across more pages, extract a shared helper instead of growing page-local constants indefinitely.

## Refactor/Delete Disposition

- Keep the existing Leviathan Select page owner and polish it in place rather than replacing the page shell.
- Keep all current selection flow, roster data, and i18n surfaces intact.
- Do not delete existing page assets, text keys, or flow hooks in this closeout step.

## Verification Checklist

- Run `powershell -NoProfile -ExecutionPolicy Bypass -File LTL-harness/tools/source-map-gate.ps1 -Root . -Refresh`.
- Run `powershell -NoProfile -ExecutionPolicy Bypass -File LTL-harness/tools/source-map-gate.ps1 -Root .`.
- Run `powershell -NoProfile -ExecutionPolicy Bypass -File LTL-harness/tools/request-analysis-gate.ps1 -Ledger docs/request-ledgers/2026-06-30-ui-001-leviathan-select-polish-closeout.md -Mode pre-complete`.
- Run `powershell -NoProfile -ExecutionPolicy Bypass -File tools/invoke-godot.ps1 -ProjectPath app-LTL -Headless -Script tests/run_main_layout_audit_contract.gd`.
- Run `powershell -NoProfile -ExecutionPolicy Bypass -File tools/invoke-godot.ps1 -ProjectPath app-LTL -Headless -Script tests/run_page_scene_mapping_contract.gd`.
- Run `powershell -NoProfile -ExecutionPolicy Bypass -File tools/run-compile-check.ps1 -RequestLedger docs/request-ledgers/2026-06-30-ui-001-leviathan-select-polish-closeout.md`.
- Update the relevant objective proof in `docs/project-goals/work-objectives.html` and run `powershell -NoProfile -ExecutionPolicy Bypass -File tools/project-objectives.ps1 -Mode validate`.
- Write a shared Hermes closeout worklog, then run `powershell -NoProfile -ExecutionPolicy Bypass -File tools/agent-worklog.ps1 -Mode summarize-worklogs -Agent hermes` and `-Mode validate -Agent hermes`.

## Verification Notes

- `LTL-harness/tools/source-map-gate.ps1 -Root . -Refresh` passed with `SOURCE_MAP_REFRESH_OK: docs/source-map.md` and `SOURCE_MAP_GATE_OK`.
- `LTL-harness/tools/source-map-gate.ps1 -Root .` passed with `SOURCE_MAP_GATE_OK` after the Leviathan Select page and closeout docs were refreshed into the live map.
- `LTL-harness/tools/request-analysis-gate.ps1 -Ledger docs/request-ledgers/2026-06-30-ui-001-leviathan-select-polish-closeout.md -Mode pre-complete` passed with `REQUEST_ANALYSIS_GATE_OK` after the ledger was tightened to include an explicit root-cause target and workaround guard proof.
- `tools/invoke-godot.ps1 -ProjectPath app-LTL -Headless -Script tests/run_main_layout_audit_contract.gd` exited `0` and emitted `MAIN_LAYOUT_AUDIT_CONTRACT_OK`.
- `tools/invoke-godot.ps1 -ProjectPath app-LTL -Headless -Script tests/run_page_scene_mapping_contract.gd` exited `0` and emitted `PAGE_SCENE_MAPPING_CONTRACT_OK`.
- `tools/run-compile-check.ps1 -RequestLedger docs/request-ledgers/2026-06-30-ui-001-leviathan-select-polish-closeout.md` exited `0` and emitted `SOURCE_MAP_GATE_OK`, `REQUEST_ANALYSIS_GATE_OK`, `TEST_SIZE_GATE_OK` (legacy warnings only), `RUNTIME_SIZE_GATE_OK`, `PAGE_CONTRACT_GATE_OK`, `TRANSITION_SAFETY_GATE_OK`, `GODOT_CONTRACTS_OK`, and `Compilation Check: PASSED (GODOT_CONTRACTS_OK)`.
- `tools/project-objectives.ps1 -Mode update-status -ObjectiveId UI-001 -Status in-progress ...` emitted `PROJECT_OBJECTIVE_GATE_UPDATE_OK`, and `tools/project-objectives.ps1 -Mode validate` emitted `PROJECT_OBJECTIVE_GATE_VALIDATE_OK`.
- `tools/agent-worklog.ps1 -Mode summarize-worklogs -Agent hermes` emitted `WORKLOG_TOKEN_GATE_SUMMARY_OK`, and `tools/agent-worklog.ps1 -Mode validate -Agent hermes` emitted `WORKLOG_TOKEN_GATE_VALIDATE_OK`.
- Known Godot shutdown leak / anchor warnings still appear during broader page and compile runners, but every blocking gate returned `OK` with exit `0` for this closeout.

## Resolution Proof

- RED proof: the page still visibly lagged behind the approved UI direction because Leviathan Select retained older darker page-local layout/theme constants while Character Select and the final-goal direction had already moved toward the sky / exploration / cold-stone treatment.
- Root-cause proof: constraining the work to `LeviathanSelectPage.gd` and `LeviathanSelectPage.tscn` was sufficient to land the approved five-step polish sequence without touching page routing, data, or gameplay ownership.
- Workaround guard: the fix did not add fallback copy, flow branches, controller edits, or data-table overrides; `PAGE_SCENE_MAPPING_CONTRACT_OK` confirmed the existing page owner and route mapping stayed intact.
- Regression guard proof: after the polish, the focused layout audit still emitted `MAIN_LAYOUT_AUDIT_CONTRACT_OK` and the page mapping runner still emitted `PAGE_SCENE_MAPPING_CONTRACT_OK`, proving the runtime surface stayed layout-safe and owner-stable while the visuals changed.
- Closeout proof: the same ledger then passed `REQUEST_ANALYSIS_GATE_OK`, `SOURCE_MAP_GATE_OK`, `TRANSITION_SAFETY_GATE_OK`, `PAGE_CONTRACT_GATE_OK`, and `Compilation Check: PASSED (GODOT_CONTRACTS_OK)`, so the Leviathan Select polish closed with both focused page evidence and repo-level gate evidence.

## Artifact Ledger

- No separate artifact ledger is planned for this UI-001 closeout; the proof is expected to live in this request ledger, the refreshed source map, objective log, and shared Hermes closeout worklog.
