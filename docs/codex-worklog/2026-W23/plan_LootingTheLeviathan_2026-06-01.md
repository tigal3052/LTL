# Codex Worklog Plan

Workspace: LootingTheLeviathan
Date: 2026-06-01

## Active Work

Use sub-agent root-cause analysis to rebuild the backpack pin and battlefield miner placement around trimmed visible regions and live Godot layout metrics, then verify the real placement behavior.

## Request Summary

The user reported that the earlier pin/miner fix did not improve the live game at all and explicitly asked for a sub-agent discussion across UI, Godot-engine, and graphic-design viewpoints. That analysis converged on the real root cause: both the backpack pin art and the miner pose art are being laid out from full PNG canvases with large transparent padding, while the backpack pin size math also uses whole-grid estimates instead of live corner-cell metrics. This pass must apply that root-cause diagnosis, trim the visible regions used for layout, keep the pins tied to `backpack_1/3/7/9`, move the miner art to the true upper-right panel edge, and report the tested results.

## Scope

- Re-anchor the backpack pins to the exact requested border tiles rather than the broader outer grid corners.
- Reduce the displayed pin footprint so the art no longer sprawls across multiple backpack cells.
- Reposition the battlefield miner overlay to the panel's upper-right edge while preserving pose switching.
- Preserve the existing combat-only visibility, pin-count mapping, removal order, and removal VFX behavior unless the follow-up placement fix requires a narrow supporting change.
- Add or update focused UI layout contracts that guard the corrected pin sizing/placement model and the new miner placement policy.
- Record the request change, implementation, and verification evidence in today's worklog.

## Out of Scope

- Reverting unrelated dirty-worktree changes.
- Redesigning the pin art, miner art, pin timing, or wider combat UX beyond the placement correction.
- Reworking starter-option flow, reward ceremony behavior, or other already-dirty subsystems that are unrelated to the screenshoted pin/miner placement bug.

## Steps

- Record the sub-agent consensus root cause in the worklog and convert it into failing regression tests before further production edits.
- Trim the backpack pin textures to their visible regions, derive displayed pin size from the trimmed silhouette, and keep corner placement anchored to the requested `backpack_1/3/7/9` side centers using live cell rects.
- Trim the miner pose textures to their visible regions, keep the shared title miner aligned to the panel's top-right edge, and re-layout after pose swaps so `45/60/90` each stay visually attached.
- Re-run the focused UI contract suite, the broad Godot runner, and an additional runtime probe for actual pin/miner geometry evidence if the engine environment allows it.
- Update the June 1 plan, history, and completion notes with the root cause, implementation, and verification results.

## Expected Outputs

- Updated `app-LTL/src/ui/BackpackUI.gd`
- Updated `app-LTL/src/ui/BattlefieldUI.gd`
- Updated `app-LTL/tests/test_ui_read_models.gd`
- Updated `docs/codex-worklog/plan_LootingTheLeviathan_2026-06-01.md`
- Updated `docs/codex-worklog/history_LootingTheLeviathan_2026-06-01.md`
- Updated `docs/codex-worklog/complete_LootingTheLeviathan_2026-06-01.md`

## Verification Method

- RED-first focused preload/UI path: `tests/run_test_ui_read_models.gd` must fail first on the new trimmed-region and resized-layout contracts, then print `UI_READ_MODEL_TESTS_OK` after the fix.
- Broad regression path: `tests/godot_contract_runner.gd` must still print `GODOT_CONTRACTS_OK`.
- If feasible in the local engine environment, run an additional runtime probe that captures live pin/miner placement evidence beyond pure math/unit assertions.
- Diff hygiene is limited to the touched files; existing LF/CRLF normalization warnings are acceptable if no whitespace errors are introduced.

## Plan Change Log

- 2026-06-01: Replaced the earlier starter-option freeze investigation plan with the newly reported screenshot-based backpack pin placement regression.
- 2026-06-01: Re-scoped verification to the focused UI read-model contract because this request targets `BackpackUI` geometry rather than the controller start-flow path.
- 2026-06-01: Expanded the active bugfix scope after the user's follow-up screenshot to include smaller pin sizing, explicit `backpack_1/3/7/9` side anchors, and top-right miner placement in `BattlefieldUI`.
- 2026-06-01: Replaced the earlier geometry-only assumption with the confirmed root cause from UI, Godot, and graphic-design sub-agents: full-canvas transparent padding plus whole-grid pin sizing were masking the real visual bug.
