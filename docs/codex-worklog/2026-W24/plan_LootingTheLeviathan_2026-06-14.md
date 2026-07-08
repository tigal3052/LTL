# Codex Worklog Plan

Workspace: LootingTheLeviathan
Date: 2026-06-14

## Active Work

Fix the battle HUD floor layout after screenshot review: move the battle tile strip and action buttons to the active-phase floor, maximize the central backpack panel while preserving its aspect ratio, and rebalance the left/right side panels so the left status rail is as narrow as practical before trimming the right rail.

## Request Summary

The latest battle screenshot shows a large unused gray gap under the tile strip and action buttons. The user wants the tile/backpack band and button area kept at the bottom, the central backpack panel enlarged to fill the remaining vertical budget without distortion, and the side panels reduced to protect the backpack. The user also requested cross-validation through graphic designer, UI designer, and frontend programmer subagents.

## Scope

- Add or update layout audit tests for combat floor anchoring, top-row height growth, backpack aspect/width priority, and side-panel width rebalance.
- Update the runtime page-shell/top-content layout calculations so `BattlePage` fills the active phase and its `TopContent` row consumes the remaining height above the battlefield strip and action bar.
- Adjust side-panel stretch behavior so the left status rail stays near its readable minimum and the right rail absorbs remaining side budget without breaking tabs.
- Keep the previous node/drill info panel behavior intact.
- Record subagent review findings and verification outcomes.

## Out Of Scope

- Combat rule changes, inventory mechanics, or node data changes.
- New bitmap asset creation.
- Broad cleanup of unrelated dirty worktree changes.
- Fixing unrelated compile/source-map gates unless directly required by this HUD layout pass.

## Steps

- Spawn read-only subagents for graphic design, UI design, and frontend/Godot implementation review.
- Update this plan before code edits.
- Tighten the combat layout audit contract and run it in RED state.
- Implement page sizing, top-content height, backpack bounds, and side-panel distribution changes.
- Integrate any material subagent feedback.
- Run focused Godot layout/read-model checks and update history/complete worklogs.

## Expected Outputs

- Updated `app-LTL/tests/run_main_layout_audit_contract.gd`
- Potential updates to `app-LTL/src/ui/MainViewRuntime.gd`
- Potential updates to `app-LTL/src/ui/SharedBackpackHostCoordinator.gd`
- Potential updates to `app-LTL/src/ui/presenters/PhaseLayoutPresenter.gd`
- Potential scene flag updates under `app-LTL/src/scenes/pages/`
- Updated dated worklog files

## Verification Method

- `powershell -NoProfile -ExecutionPolicy Bypass -File tools/invoke-godot.ps1 -ProjectPath app-LTL -Headless -Script tests/run_main_layout_audit_contract.gd`
- `powershell -NoProfile -ExecutionPolicy Bypass -File tools/invoke-godot.ps1 -ProjectPath app-LTL -Headless -Script tests/run_test_ui_read_models.gd`
- `powershell -NoProfile -ExecutionPolicy Bypass -File tools/invoke-godot.ps1 -ProjectPath app-LTL -Headless -Script tests/run_combat_layout_containment_contract.gd`
- `powershell -NoProfile -ExecutionPolicy Bypass -File tools/run-compile-check.ps1`

## Plan Change Log

- 2026-06-14: Replaced the prior node-info-only plan with the active battle HUD floor-alignment and backpack-maximization pass requested in the latest screenshot review.
