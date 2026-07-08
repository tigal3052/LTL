# Codex Worklog Completion

Workspace: LootingTheLeviathan
Date: 2026-05-29

## M4-M9 Release Content Pass

- Added `ReleaseContentVocab` as a deterministic release-content facade for M4-M9 tables, hazard scheduling, base purchases, passive branch summaries, and narrative projection.
- Added content tables for leviathans, characters, hazards, base shop unlocks, passive tree branches, narrative beats, and resource manifest paths.
- Connected base-shop purchases into the live shop panel and `RunGrowthState` serialization for characters, starter items, and leviathan scans.
- Tuned the normal node into a true safe neutral route, added the mysterious crevice event node, and adjusted combat color profiles toward the reviewed red/blue/green/purple roles.
- Added release contract tests and connected them to the Godot contract runner.
- Documented drop-in final-art/audio paths in `docs/release-resource-needs.md`.
- Verification: `powershell -NoProfile -ExecutionPolicy Bypass -File tools/run-compile-check.ps1` passed with `SOURCE_MAP_GATE_OK` and `GODOT_CONTRACTS_OK`; `git diff --check` returned no whitespace errors.

## External Shader UI Affordance Pass

- Added `InteractionCuePresenter` so hover, press, disabled, valid-drag, and blocked-drag cues are testable as pure UI contracts.
- Added `InteractionFX`, a project-local Godot CanvasItem shader/tween layer inspired by GodotShaders hover and click-ripple examples.
- Installed shared interaction effects through `MainViewRuntime`, backpack slots, shop/buttons, and dynamic controls.
- Added mouse-position glow tracking and disabled-state refresh so rerendered buttons keep correct affordance cues.
- Updated backpack drag/drop feedback to use real inventory placement rules, with invalid slots showing blocked-state feedback.
- Added battlefield cell forbidden-hover and press feedback so blocked actions read differently from valid clicks.
- Repaired the backpack layout regression by preventing position tweens on `Container`-managed children such as grid slots.
- Documented external shader references and license handling in `docs/external-ui-shader-sources.md`.
- Verification: `powershell -NoProfile -ExecutionPolicy Bypass -File tools/run-compile-check.ps1` passed with `SOURCE_MAP_GATE_OK` and `GODOT_CONTRACTS_OK`; `git diff --check` returned no whitespace errors.

## Completion Summary

- Promoted the replay fixture JSON files into the formal Godot test path at `app-LTL/tests/fixtures/input_logs/`.
- Added a formal replay runner regression test and switched the formal replay runner plus contract runner away from prototype fixture paths.
- Preserved the full prototype tree, while deleting the quarantined source copy and empty placeholder directories that do not affect the current source.
- Regenerated `docs/source-map.md` so the source-map gate reflects the new formal fixtures and removed quarantine path.

## Verification Results

- Red check: direct Godot runner failed first because `FormalReplayRunner` still returned `res://prototype/browser-p0-p4/tests/fixtures/input_logs/*`, proving the new regression test was effective.
- Green check: direct Godot runner passed after fixture promotion and reference updates, with `GODOT_CONTRACTS_OK`.
- Full verification: `powershell -NoProfile -ExecutionPolicy Bypass -File tools/run-compile-check.ps1` passed, including `SOURCE_MAP_GATE_OK` and `GODOT_CONTRACTS_OK`.
- Reference scans over `app-LTL/src` and `app-LTL/tests` found no remaining `prototype/browser-p0-p4/tests/fixtures/input_logs` or `_quarantine` references.
- `git diff --check` reported only LF-to-CRLF warnings and no whitespace errors.

## Remaining Gaps

- Existing Godot RID/ObjectDB/resource leak warnings still print at process exit during compile verification; they predate this fixture-path change and were not addressed in this pass.
- Local generated directories such as `.godot-user/` and `app-LTL/.godot/` were not targeted because verification recreates them.

## Source Map Responsibility Refinement Addendum

- Clarified the purpose of the separate directory tree: it is a quick hierarchy scan, while `File Map` is the authoritative responsibility list.
- Split multi-function source files into multiple feature-level bullets, especially controller/runtime, model, UI, process, vocabulary facade, and contract runner files.
- Verification passed: `LTL-harness/tools/source-map-gate.ps1 -Root .` returned `SOURCE_MAP_GATE_OK`; `git diff --check` returned exit 0 with line-ending warnings only.

## M4 Node Map Loadout Balance Addendum

- Added a dedicated node-map selection page inside the live `node_select` UI path, with clickable route nodes, route details, start-color controls, and durability display.
- Fixed the manual-QA regression where the old prototype "next target node" list remained visible and overlapped the new map UI; `node_select` now hides the old title/list and combat top content, then renders the map through `NodeMapPageRoot`.
- Fixed the color-selection rerender regression where route text could disappear after choosing red/blue/purple/green by immediately removing old generated controls instead of deferring them with `queue_free()`.
- Fixed the follow-up locked-object error by deferring `color_selected` emission until after the clicked color button finishes emitting.
- Fixed the matching locked-object error on node selection by deferring `node_selected` emission until after the clicked map node finishes emitting.
- Replaced long text-card node selection with a `RunMapCanvas` visual graph: START and CORE anchors, route connection lines, and compact selectable candidate node chips with full details kept below the map.
- Added selected-node visual differentiation with a selected marker and brighter node chip state.
- Kept the backpack visible during node-select prep so starter artifacts can be picked up, moved, and rotated before combat.
- Moved the default starter drill and beacon to adjacent cells so beacon support can matter in stage one.
- Corrected the terrain-size interpretation: removed the cell-ratio forcing and restored combat active-phase stretch while keeping the node-map page expanded.
- Made offered node candidate shield/health match the documented stage durability table instead of multiplying visible HP/shield by route-specific modifiers.
- Changed default/start loadout to one selected-color drill plus one same-color starter beacon; red is the deterministic default for headless contracts.
- Rebalanced base stage durability to `30, 42, 62, 88, 124` using the documented curve `30 * pow(1.43, stage_index)` with tuned practical targets and a stage-varying shield share.
- Changed terrain weakness marker movement from `1.0` seconds to `1.5` seconds.
- Added contract coverage for node-map controls, starter loadout composition, the five-stage durability curve, and the marker movement interval.
- Verification passed: `powershell -NoProfile -ExecutionPolicy Bypass -File tools/run-compile-check.ps1` returned `SOURCE_MAP_GATE_OK` and `GODOT_CONTRACTS_OK`; `git diff --check` returned exit 0 with LF-to-CRLF warnings only.

## M4 Manual QA Correction Addendum

- Fixed non-red starter loadouts by making the starter drill a compact one-cell selected-color drill, paired with one one-cell selected-color beacon.
- Fixed headless/default runtime drift so start colors and adjacent starter placement match the live controller path.
- Fixed the actual selected-node combat durability path by removing the old `50/50` default tuning injection; the selected combat snapshot now uses the documented stage table.
- Fixed cooldown mask backtracking during terrain-shift rerenders by preserving the visual cooldown when a stale backend snapshot is larger than the currently displayed value.
- Corrected terrain panel sizing by restoring combat `ActivePhaseContainer` stretch to the prior default and reserving the expanded stretch for node-map selection only.
- Verification passed: `powershell -NoProfile -ExecutionPolicy Bypass -File tools/run-compile-check.ps1` returned `SOURCE_MAP_GATE_OK` and `GODOT_CONTRACTS_OK`; `git diff --check` returned exit 0 with LF-to-CRLF warnings only.

## UI Direction Pass

- Applied a supervised UI direction pass using feedback from UI art, UX layout, interaction design, and game direction perspectives.
- Converted the node-select screen into a more legible tactical-briefing layout with clearer hierarchy, larger route targets, and better map/backpack balance.
- Unified panel and command-button materials in `MainViewRuntime.gd`, upgraded `ShopPanelUI.gd` into sectioned cards, and restyled `StatusPanelUI.gd` bars for faster combat readability.
- Fixed the backpack regression caused by interaction tweening on `Container`-managed children and added a regression test to keep the layout stable.

## M4 Manual QA Gameplay/Layout Addendum

- Changed node-select layout so the node map uses the left side and the backpack is docked on the right, reducing empty vertical space in the selection screen.
- Synced combat backend time with the visible backpack cooldown animation by advancing `30` combat ticks per `1.5` second terrain shift at the existing `20` ticks/sec visual cadence.
- Confirmed beacon cooldown pulses affect real energy generation with a regression test where an adjacent beacon makes a drill generate energy before its base cooldown.
- Replaced the shifted terrain color arithmetic with per-row seeded random draws so newly inserted tiles do not repeat the diagonal color pattern.
- Buffed purple by making it damage shield and HP together, scale from uncapped global terrain-debuff stacks, and keep incrementing those stacks.
- Reduced red HP damage from the old near-5 HP burst at 1.5 drill damage to a lower but still HP-leaning profile.
- Verification passed: `powershell -NoProfile -ExecutionPolicy Bypass -File tools/run-compile-check.ps1` returned `SOURCE_MAP_GATE_OK` and `GODOT_CONTRACTS_OK`; `git diff --check` returned exit 0 with LF-to-CRLF warnings only.

## Manual QA UI Recovery Pass

- Tightened node-map chip width, map-canvas height, and row spacing so route candidates no longer overlap and the selection panel reads like a deliberate graph.
- Prevented shader-material hover effects from being installed on stylebox-driven backpack slot panels, restoring normal idle artifact readability instead of black slot fills.
- Increased shell button minimum widths for header and action-bar controls so shop/settings/combat actions share a stable sizing standard.
- Shifted more combat and reward width into the backpack by reducing side-column stretch ratios.
- Blocked combat clicks while repair is active or aim is disabled, preventing automatic repair from being restarted by stale tile input.
- Extended reward reveal pacing with a silhouette pause and rolling rarity phase before the final reward identity locks in.
- Added `docs/release-visual-quality-upgrade-plan.md` to define the next release-art pass: shell backgrounds, authored panel frames, gameplay surface art, reward reveal assets, and audio drop-in paths.
- Verification: `powershell -NoProfile -ExecutionPolicy Bypass -File tools/run-compile-check.ps1` passed with `SOURCE_MAP_GATE_OK` and `GODOT_CONTRACTS_OK`; `git diff --check` pending rerun after documentation updates.

## Game Studio Node-Select / Backpack Follow-Up

- Rebuilt the node-select graph around a `START + 5 choices` layout, removed the `CORE` label, and made `NodeMapScene` rerender from the real allocated width after resize so chips stop clipping when the backpack is docked beside the map.
- Shifted the node-select split further toward the map by raising `nodeMapStretchRatio`, lowering the docked backpack ratio, and reducing the backpack minimum width.
- Disabled generic hover wobble on backpack slots by opting them out of `InteractionFX` while preserving drag/drop validity cues and pointer affordance.
- Added explicit `stageHealthTotals` alongside stage durability totals so stages 1-3 ramp harder against reward snowballing, then taper through stages 4-5.
- Updated contract tests to lock the new node-map and stage-scaling behavior in place.
- Verification: `powershell -NoProfile -ExecutionPolicy Bypass -File tools/run-compile-check.ps1` passed with `SOURCE_MAP_GATE_OK` and `GODOT_CONTRACTS_OK`; `git diff --check` should be rerun after this worklog update.
