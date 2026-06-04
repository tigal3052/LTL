# Codex Worklog Plan

Workspace: LootingTheLeviathan
Date: 2026-05-31

## Active Work

Move the live battlefield miner art into the dedicated `resources/UI/miner/` asset set, rename the base pose to `miner_45.png`, and make the battle title miner switch between 45/60/90 degree poses based on which battlefield columns the player attacks.

## Request Summary

The user wants the loose `app-LTL/resources/UI/miner.png` asset moved into `app-LTL/resources/UI/miner/` and renamed to `miner_45.png`, then wants the in-battle miner presentation to reuse a single on-screen slot while swapping between `miner_90.png`, `miner_60.png`, and `miner_45.png` according to the attacked battlefield column bands: columns 1-2 use 90 degrees, 3-6 use 60 degrees, and 7-10 use 45 degrees. The transition should feel intentionally polished rather than like a hard texture pop.

## Scope

- Move `app-LTL/resources/UI/miner.png` and its import metadata into `app-LTL/resources/UI/miner/miner_45.png`.
- Update Godot/UI source references so the battlefield title miner uses the new `miner_45` default asset path.
- Add deterministic column-to-pose mapping helpers for the 3x10 battlefield: columns 0-1 map to `miner_90`, 2-5 map to `miner_60`, and 6-9 map to `miner_45`.
- Trigger a polished title-miner pose change after successful combat tile clicks, with subtle easing/tint/scale changes so the swap feels natural.
- Update source-map documentation for the new tracked art assets and verify the Godot smoke suite plus source-map gate still pass.

## Out of Scope

- Re-exporting or repainting the supplied miner art.
- Reintroducing a second large lower battlefield miner overlay unless required by the current request.
- Unrelated combat balance, tile logic, or node-select layout refactors.
- Reverting unrelated existing workspace changes.

## Steps

- Add failing regression coverage for miner pose asset-path mapping by battlefield column/cell id.
- Move the base miner asset/import metadata into the `resources/UI/miner/` folder and update all source references to `miner_45`.
- Extend `BattlefieldUI.gd` with pose-selection helpers plus a polished title-miner swap animation tied to combat clicks.
- Wire the successful cell-click path to trigger the miner pose update without disturbing existing battlefield VFX.
- Update `docs/source-map.md` for the new miner and pin resource entries.
- Run direct headless Godot smoke, then the full `tools/run-compile-check.ps1`, and record the results in today's worklog files.

## Expected Outputs

- Moved `app-LTL/resources/UI/miner/miner_45.png` asset plus import metadata
- Updated `app-LTL/src/ui/BattlefieldUI.gd`
- Updated `app-LTL/src/MainControllerRuntime.gd`
- Updated `app-LTL/tests/test_ui_read_models.gd`
- Updated `docs/source-map.md`
- Updated worklog files

## Verification Method

- Run the direct headless Godot smoke command in `--smoke-only` mode to prove the new regression test fails first, then passes after implementation.
- Run `powershell -NoProfile -ExecutionPolicy Bypass -File tools/run-compile-check.ps1` after the source-map updates.
- Run `git diff --check` on the touched runtime, asset-map, and worklog files.

## Plan Change Log

- 2026-05-31: Worklog bootstrapped automatically by Codex hook.
- 2026-05-31: Replaced placeholders with a generalized planning task for request-analysis and execution gates.
- 2026-05-31: Replaced the earlier planning-only scope with the approved backpack/node-panel layout rebalance task.
- 2026-05-31: Expanded the scope after screenshot review to include the rightmost node-button click regression and node-map/detail-panel vertical rebalance.
- 2026-05-31: Follow-up request shifted from live layout edits to a visual terrain-panel comparison mockup using the newly provided `miner` and `tile` art assets.
- 2026-05-31: Follow-up request shifted to root-cause explanation for node-select sizing and a broad UI layout/test-separation refactor plan.
- 2026-05-31: Follow-up clarified the desired fix: shrink the node graph bottom gap, make detail space absorb the freed height, and size the right backpack from the same row height as the left stack.
- 2026-05-31: Active work changed to the top-content horizontal layout request: keep backpack size, widen both side panels toward it, and leave about 20px between the visible panels.
- 2026-05-31: Follow-up bugfix narrowed the issue to the top-content height mismatch: the visible backpack panel must reclaim the full available row height and become the baseline for the left and right panels.
- 2026-05-31: Active work changed again to the terrain-panel mockup; root cause investigation now targets the transparent top and bottom padding inside `tile_panel_nobg.png`.
- 2026-05-31: User approved moving from mockup to live Godot implementation for the battlefield terrain panel.
- 2026-05-31: Follow-up request changed the live battlefield composition again: shrink/move the miner into the header slot, move the countdown into the status footer, and stretch the terrain shell vertically around the 3x10 tiles.
- 2026-05-31: Active work changed to the pose-driven battlefield miner request: move the base miner asset into the `miner/` folder as `miner_45` and switch the title miner pose by attacked tile column bands.
