# 2026-06-30 UI-001 Leviathan Select runtime overlay rail closeout

## Request Summary

- Replace the old Leviathan Select split board/ribbon layout with the approved runtime structure: flush left global rail, full hero stage, right overlay roster rail, and CTA docked to the rail bottom.
- Keep page routing, selection/start flow, data ownership, i18n keys, and gameplay behavior unchanged while moving the visual ownership into the page-local scene/script.
- Close the runtime step with focused Godot proof plus repo-level source-map, request-analysis, objective, and compile-check evidence.

## Preserved Invariants

- The approved `character_select -> leviathan_select -> node_select` flow remains unchanged.
- No controller, reducer, data-table, i18n-key, or gameplay-state ownership changes are introduced.
- The Leviathan Select page still owns only page-local presentation; non-Leviathan pages remain outside this change set.
- Existing dirty worktree changes outside this Leviathan Select runtime step are not reverted.

## Mutable Scope

- `app-LTL/src/scenes/pages/LeviathanSelectPage.tscn`
- `app-LTL/src/scenes/pages/LeviathanSelectPage.gd`
- `app-LTL/src/scenes/pages/leviathan_select/LeviathanSelectViewBits.gd`
- `app-LTL/tests/run_page_scene_mapping_contract.gd`
- `app-LTL/tests/run_main_layout_audit_contract.gd`
- `docs/source-map.md`
- `docs/request-ledgers/2026-06-30-ui-001-leviathan-select-runtime-overlay-rail-closeout.md`
- `docs/project-goals/work-objectives.html`
- `docs/agent-worklog/2026-06-30-hermes-ui-001-leviathan-select-runtime-overlay-rail-closeout.md`
- `docs/agent-worklog/INDEX.md`
- `docs/agent-worklog/COMPACT.md`

## Source Map Findings

- `docs/source-map.md`
  - The live source map is the freshness/coverage surface and must be refreshed after the Leviathan Select scene, helper, tests, and closeout docs change.
- `app-LTL/src/scenes/pages/LeviathanSelectPage.tscn`
  - The scene now owns the full-screen chrome layout and the structural shift from bottom ribbon CTA to right overlay rail CTA.
- `app-LTL/src/scenes/pages/LeviathanSelectPage.gd`
  - The page script owns selection rendering, unlock projection, responsive spacing, and preserved start/select signal wiring.
- `app-LTL/src/scenes/pages/leviathan_select/LeviathanSelectViewBits.gd`
  - The extracted helper owns page-local card/pill/copy/style builders so the page owner stays under the runtime size cap.
- `app-LTL/tests/run_page_scene_mapping_contract.gd`
  - The page mapping runner is the owner-stability guard for the new top bar / hero / overlay rail scene structure.
- `app-LTL/tests/run_main_layout_audit_contract.gd`
  - The layout audit runner is the viewport/geometry guard for flush-left rail, full hero, right overlay rail, and bottom CTA docking.

## Root Cause Review

- Observed symptom: the approved Leviathan Select mockup direction was still not represented in runtime because the scene continued to own a split board + bottom ribbon + detached CTA structure.
- Evidence: runtime ownership still depended on `BoardPanel/TargetRibbon/StartButtonFrame`, while the approved mockup and follow-up approval moved emphasis to a full hero stage with a right overlay roster rail and CTA docked inside that rail.
- Root cause target: `app-LTL/src/scenes/pages/LeviathanSelectPage.tscn`
- Rejected workaround: fake the new look with shallow color tweaks, controller-side conditionals, or data/i18n expansion while leaving the old scene ownership intact.
- Chosen fix: rebuild the page-local scene ownership around the approved overlay rail structure, preserve the existing start/select signals, and extract page-local view-builder helpers so the runtime owner remains under size gate.

## Transition Safety Review

- no transition impact
- reason: routing, selected-leviathan handoff, and start-request flow stay on the existing controller contract; only page-local scene ownership, helper extraction, and layout guards changed.
- flow runner: `app-LTL/tests/run_main_start_flow_contract.gd`
- flow marker: `MAIN_START_FLOW_CONTRACT_OK`
- mapping runner: `app-LTL/tests/run_page_scene_mapping_contract.gd`
- mapping marker: `PAGE_SCENE_MAPPING_CONTRACT_OK`
- layout runner: `app-LTL/tests/run_main_layout_audit_contract.gd`
- layout marker: `MAIN_LAYOUT_AUDIT_CONTRACT_OK`

## Feature Unit Lifecycle Plan

- Design stage: keep the change scoped to Leviathan Select runtime ownership only, so the approved overlay-rail structure lands without reopening broader UI-001 direction decisions for other pages.
- Implementation stage: confine structural runtime edits to the Leviathan Select scene/script and extract only page-local view-builder helpers instead of pushing presentation logic into controllers, data tables, or shared gameplay owners.
- Maintenance stage: future Leviathan Select iterations should update the two focused contracts and refresh `docs/source-map.md` before claiming compile-level acceptance.
- Capsule boundary: Leviathan Select owns this full-page chrome/layout presentation locally; controller flow and gameplay eligibility remain outside the capsule.
- Size trigger: if more page-local rendering logic is added beyond this helper extraction, split additional card/copy/theming helpers instead of regrowing `LeviathanSelectPage.gd` past the active cap.

## Execution Responsibility Units

- Owner: `app-LTL/src/scenes/pages/LeviathanSelectPage.gd`
  - Unit: node wiring, state-to-view projection, unlock/selection refresh, and responsive layout sequencing for the Leviathan Select page owner.
  - Extract to: `app-LTL/src/scenes/pages/leviathan_select/LeviathanSelectViewBits.gd`
  - Focused proof: `app-LTL/tests/run_main_layout_audit_contract.gd`

## Refactor/Delete Disposition

- Keep the Leviathan Select page owner in place and refactor it by extraction rather than replacing page flow ownership.
- Keep existing controller/data/i18n surfaces intact; do not delete gameplay hooks or expand data schemas for this runtime step.
- Retain the new `LeviathanSelectViewBits.gd` helper as the page-local extraction target that keeps the main page owner under the active size gate.

## Verification Checklist

- Run `powershell -NoProfile -ExecutionPolicy Bypass -File tools/invoke-godot.ps1 -ProjectPath app-LTL -Headless -Script tests/run_page_scene_mapping_contract.gd`.
- Run `powershell -NoProfile -ExecutionPolicy Bypass -File tools/invoke-godot.ps1 -ProjectPath app-LTL -Headless -Script tests/run_main_layout_audit_contract.gd`.
- Run `powershell -NoProfile -ExecutionPolicy Bypass -File tools/invoke-godot.ps1 -ProjectPath app-LTL -Headless -Script tests/run_main_start_flow_contract.gd`.
- Run `powershell -NoProfile -ExecutionPolicy Bypass -File LTL-harness/tools/source-map-gate.ps1 -Root . -Refresh`.
- Run `powershell -NoProfile -ExecutionPolicy Bypass -File LTL-harness/tools/request-analysis-gate.ps1 -Ledger docs/request-ledgers/2026-06-30-ui-001-leviathan-select-runtime-overlay-rail-closeout.md -Mode pre-complete`.
- Run `powershell -NoProfile -ExecutionPolicy Bypass -File tools/run-compile-check.ps1 -RequestLedger docs/request-ledgers/2026-06-30-ui-001-leviathan-select-runtime-overlay-rail-closeout.md`.
- Update the relevant proof note in `docs/project-goals/work-objectives.html` and run `powershell -NoProfile -ExecutionPolicy Bypass -File tools/project-objectives.ps1 -Mode validate`.
- Write a Hermes closeout worklog, then run `powershell -NoProfile -ExecutionPolicy Bypass -File tools/agent-worklog.ps1 -Mode summarize-worklogs -Agent hermes` and `-Mode validate -Agent hermes`.

## Verification Notes

- `tools/invoke-godot.ps1 -ProjectPath app-LTL -Headless -Script tests/run_page_scene_mapping_contract.gd` exited `0` and emitted `PAGE_SCENE_MAPPING_CONTRACT_OK` after the scene contract was moved from the legacy ribbon owner to the new top-bar/hero/overlay-rail owner.
- `tools/invoke-godot.ps1 -ProjectPath app-LTL -Headless -Script tests/run_main_layout_audit_contract.gd` exited `0` and emitted `MAIN_LAYOUT_AUDIT_CONTRACT_OK` after the runtime layout contract was rewritten around flush-left rail, full hero stage, right overlay rail width, and bottom CTA docking.
- `tools/invoke-godot.ps1 -ProjectPath app-LTL -Headless -Script tests/run_main_start_flow_contract.gd` exited `0` and emitted `MAIN_START_FLOW_CONTRACT_OK`, proving the preserved selection/start flow still hands off correctly after the scene ownership change.

## Resolution Proof

- RED proof: the approved overlay-rail direction could not land while Leviathan Select still structurally depended on the old board/ribbon/start-frame scene owner.
- Root-cause proof: replacing the scene owner with `TopBar + GlobalRail + HeroShell + OverlayRail` and extracting `LeviathanSelectViewBits.gd` was sufficient to make the new runtime structure real while keeping `LeviathanSelectPage.gd` under the active source cap.
- Workaround guard: the fix did not add controller-side presentation hacks, data-schema growth, or new flow branches; the same runtime still passes `PAGE_SCENE_MAPPING_CONTRACT_OK`, `MAIN_LAYOUT_AUDIT_CONTRACT_OK`, and `MAIN_START_FLOW_CONTRACT_OK` under the preserved flow contract.

## Artifact Ledger

- No separate artifact ledger is planned for this runtime step; proof lives in this request ledger, the refreshed source map, the focused Godot runners, the objective note, and the Hermes closeout worklog.
