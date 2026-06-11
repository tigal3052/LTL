# Request Constraint Ledger

## Request Summary

- Audit whether M6 is truly complete on the current dirty tree.
- Repair the immediate false-green quality-gate path and source-map drift.
- Create a checkpoint commit for that minimal fix set.
- Continue with a larger active-runtime separation pass plus harness hardening so oversized runtime files stop regressing.

## Preserved Invariants

- `app-LTL/src/MainController.gd` and `app-LTL/src/ui/MainUI.gd` remain thin scene-facing facades unless a later approved refactor explicitly changes the scene entry strategy.
- Existing page ids and approved mockup-backed page ownership stay stable while gate enforcement is tightened.
- Source-map, transition-safety, i18n, and compile orchestration stay additive; this request repairs and strengthens them rather than replacing them.
- Prototype archives under `app-LTL/prototype/**` remain archival reference material, not active runtime ownership.

## Mutable Scope

- `docs/source-map.md`
- `LTL-harness/tools/page-contract-gate.ps1`
- `LTL-harness/tools/runtime-size-gate.ps1`
- `LTL-harness/tools/runtime-size-gate.tests.ps1`
- `docs/architectural-gates/runtime-size-gate.md`
- `docs/architectural-gates/warning-refactor-gate.md`
- `docs/architectural-gates/release-blocking-gate.md`
- `docs/superpowers/plans/2026-06-11-runtime-owner-separation-plan.md`
- `tools/run-compile-check.ps1`
- `tools/run-ltl-quality-gate.ps1`
- `docs/request-ledgers/2026-06-11-m6-gate-fix-runtime-surgery.md`
- `docs/codex-worklog/plan_LootingTheLeviathan_2026-06-11.md`
- `docs/codex-worklog/history_LootingTheLeviathan_2026-06-11.md`
- active-runtime files touched during the post-checkpoint separation pass
- harness manifests and/or gate scripts touched during the post-checkpoint recurrence-prevention pass

## Source Map Findings

- `docs/source-map.md`
  - The live map currently misses the newly added formal reward and tile sound assets, which blocks the repository-level source-map gate even before compile smoke runs.
- `LTL-harness/tools/page-contract-gate.ps1`
  - The gate currently accepts the layout-audit runner without requiring `MAIN_LAYOUT_AUDIT_CONTRACT_OK`, so `-Quit` can hide a real layout failure behind exit code `0`.
- `app-LTL/src/Main.tscn`
  - The live scene still enters through the thin facade scripts, so runtime ownership analysis must distinguish scene-entry wrappers from the large runtime implementation files they extend.
- `app-LTL/src/ui/MainViewRuntime.gd`
  - The active runtime currently owns page registration, popup creation, theme projection, shared backpack sizing, reward-board layout, and overlay coordination, making it the main runtime-separation pressure point.
- `app-LTL/src/MainControllerRuntime.gd`
  - The active runtime controller remains the orchestration owner for page flow and combat/reward transitions, so any size-gate hardening must point at this file rather than only the thin facade.

## Transition Safety Review

- no transition impact for the initial source-map plus gate-fix checkpoint
- transition review will be updated if the later runtime-separation pass changes page routing, ownership boundaries, or reward/combat handoff behavior

## Refactor/Delete Disposition

- Keep live runtime files and separate their responsibilities through extraction and clearer ownership boundaries rather than deleting active code paths blindly.
- Keep legacy/archive files that are explicitly archival, but make the active/runtime boundary obvious in documentation and gate coverage.
- Repair harness enforcement so active runtime surfaces are the monitored targets, not only the 8-line scene-entry wrappers.

## Verification Checklist

- Run `powershell -NoProfile -ExecutionPolicy Bypass -File LTL-harness/tools/request-analysis-gate.ps1 -Ledger docs/request-ledgers/2026-06-11-m6-gate-fix-runtime-surgery.md -Mode pre-edit`
- Run `powershell -NoProfile -ExecutionPolicy Bypass -File LTL-harness/tools/source-map-gate.ps1 -Root .`
- Run `powershell -NoProfile -ExecutionPolicy Bypass -File tools/invoke-godot.ps1 -ProjectPath app-LTL -Headless -Script tests/run_main_layout_audit_contract.gd`
- Run `powershell -NoProfile -ExecutionPolicy Bypass -File LTL-harness/tools/page-contract-gate.ps1 -Root . -GodotPath D:\Programming\godot_workspace\bin\Godot_v4.3-stable_win64_console.exe`
- Run `powershell -NoProfile -ExecutionPolicy Bypass -File tools/run-compile-check.ps1`
- Run additional post-checkpoint runtime-surgery verification commands for any newly extracted active-runtime helpers or new harness gates
- Run `powershell -NoProfile -ExecutionPolicy Bypass -File LTL-harness/tools/request-analysis-gate.ps1 -Ledger docs/request-ledgers/2026-06-11-m6-gate-fix-runtime-surgery.md -Mode pre-complete -RequireArtifactLedger`

## Verification Notes

- 2026-06-11 checkpoint verification restored the blocked path and confirmed:
  - `SOURCE_MAP_GATE_OK`
  - `MAIN_LAYOUT_AUDIT_CONTRACT_OK`
  - `REWARD_CLAIM_BOARD_CONTRACT_OK`
  - `PAGE_CONTRACT_GATE_OK`
  - `TRANSITION_SAFETY_GATE_OK`
  - `Compilation Check: PASSED (GODOT_CONTRACTS_OK)`
- The checkpoint is now honest again: the page-contract gate no longer false-passes the layout audit, and the live runtime has been adjusted so the revealed layout regressions pass formal containment.
- Phase-2 work is still pending for oversized active-runtime separation and blocking harness coverage.
- Phase-2 implementation will freeze the current oversized runtime owners with dedicated caps, enforce sub-600 line page leaves, and document which legacy/archive surfaces are intentionally excluded from active-runtime ownership.
- Phase-2 root cause is now confirmed:
  - the older size manifests primarily watched thin scene-entry facades or single-directory view globs
  - the real active owners such as `MainControllerRuntime.gd`, `MainViewRuntime.gd`, `NodeMapScene.gd`, and `NodeSelectRuntimePage.gd` were not under a dedicated blocking cap
- Phase-2 verification now also confirms:
  - `RUNTIME_SIZE_GATE_TESTS_OK`
  - `RUNTIME_SIZE_GATE_OK`
  - `Compilation Check: PASSED (GODOT_CONTRACTS_OK)`
  - `LTL_QUALITY_GATE_OK`
- The recurrence-prevention fix is now active in both `tools/run-compile-check.ps1` and `tools/run-ltl-quality-gate.ps1`, so future growth on the monitored active owners fails before completion.
- Follow-up refactor wave now confirms:
  - `MainViewRuntime.gd` delegates reward-board width, height-target, zone-chrome, and docked-backpack sizing math to a dedicated presenter helper instead of keeping that pure layout policy inline.
  - `tools/invoke-godot.ps1 -ProjectPath app-LTL -Headless -Script tests/run_test_ui_read_models.gd` -> `UI_READ_MODEL_TESTS_OK`
  - `tools/run-compile-check.ps1` still passes after the extraction.
  - `tools/run-ltl-quality-gate.ps1` still passes after the extraction.
- Final helper-extraction wave now also confirms:
  - `MainViewRuntime.gd` delegates popup overlay front-order and pause-visibility projection to `PopupOverlayHost.gd`.
  - `MainViewRuntime.gd` delegates page-shell host creation, meta-versus-gameplay mounting, and active-page visibility toggling to `PageSceneRegistry.gd`.
  - `MainViewRuntime.gd` measured 2524 lines at the start of the runtime-owner refactor pass, 2497 lines after reward-board layout extraction, and 2480 lines after the final page/overlay extraction.
- Follow-up helper-extraction wave now also confirms:
  - `MainViewRuntime.gd` delegates page-scene copy and defeat wireframe projection to `PageSceneModelBuilder.gd`.
  - `MainViewRuntime.gd` delegates safe shell, active-phase, top-content, and reward backpack height-budget math to `AppShellLayoutPolicy.gd`.
  - `tools/invoke-godot.ps1 -ProjectPath app-LTL -Headless -Script tests/run_test_ui_read_models.gd` -> `UI_READ_MODEL_TESTS_OK` after the new extractions.
  - `MainViewRuntime.gd` measured 2375 lines after the page-model and app-shell policy extraction wave, down from the previous committed 2480-line state.

## Artifact Ledger

- Verification output for this request will be tracked in `docs/artifact-ledgers/2026-06-11-m6-gate-fix-runtime-surgery.md`.
