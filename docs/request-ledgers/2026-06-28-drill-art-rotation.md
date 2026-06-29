# Request Constraint Ledger

## Request Summary

- Fix rotated drill artifacts so image-backed drill art rotates with the rotated footprint shape, especially L/G-shaped drills.

## Preserved Invariants

- Preserve artifact placement, shape occupancy, collision, and rotation rules.
- Preserve reward-table data semantics and existing drill/beacon image assets.
- Preserve existing backpack/reward UI layout and cooldown mask behavior.
- Do not commit or push.

## Mutable Scope

- `app-LTL/src/ui/backpack/BackpackArtifactRenderer.gd`
- `app-LTL/tests/ui_read_models/backpack_layout/ui_backpack_runtime_suite.gd`
- `docs/source-map.md`
- `docs/codex-worklog/plan_LootingTheLeviathan_2026-06-28.md`
- `docs/codex-worklog/history_LootingTheLeviathan_2026-06-28.md`
- `docs/codex-worklog/complete_LootingTheLeviathan_2026-06-28.md`

## Source Map Findings

- `docs/source-map.md` maps `app-LTL/src/ui/backpack/BackpackArtifactRenderer.gd` to backpack artifact overlays, image-backed drill overlays, drag ghost geometry, and cooldown masks.
- `docs/source-map.md` maps `app-LTL/src/ui/BackpackUI.gd` to backpack grid input, artifact overlay, drag ghost, and image layer refresh ownership.
- `docs/source-map.md` maps `app-LTL/src/models/Artifact.gd` to artifact state, shape, placement, and rotation ownership.

## Root Cause Review

- Observed symptom: L/G-shaped drill footprints rotated, but their rendered drill image kept the original art direction.
- Evidence: `Artifact.rotate_shape()` changes both `shape` and `rotation`, while `BackpackArtifactRenderer.item_texture_for_artifact()` previously cropped/scaled item art by the current shape but did not orient the texture pixels by `art.rotation`.
- Root cause target: `app-LTL/src/ui/backpack/BackpackArtifactRenderer.gd`
- Rejected workaround: rotate or replace the PNG assets, or only change the `TextureRect` node rotation in a way that can enlarge the global rect and break existing slot containment tests.
- Chosen fix: generate an oriented display texture by rotating source item pixels in 90-degree steps before the existing visible-region crop and footprint placement.

## Transition Safety Review

- no transition impact.
- Entry owner: no page or phase transition owner touched.
- Exit owner: no page or phase transition owner touched.
- Shared state risk: the change is limited to image texture generation and does not change inventory state, reward flow, page handoff, or shared backpack reparenting.
- Runner proof: `res://tests/run_reward_claim_board_contract.gd` keeps reward/backpack docking and image containment covered.

## Feature Unit Lifecycle Plan

- Design stage: keep the fix inside `BackpackArtifactRenderer.gd`, the existing image-backed artifact rendering unit.
- Implementation stage: add a focused RED test for oriented display texture generation before changing production texture generation.
- Maintenance stage: future art-placement changes should extend the oriented texture helper or split image processing out before growing the renderer past its cap.
- Capsule boundary: public static `oriented_display_texture(texture, shape, rotation_degrees)` returns a display texture; pixel rotation and cache-key details remain private helpers.
- Size trigger: `BackpackArtifactRenderer.gd` is 497 lines after implementation against the 500-line strict cap, so the next non-trivial renderer behavior should split to a helper before adding more logic.

## Execution Responsibility Units

- Owner: `app-LTL/src/ui/backpack/BackpackArtifactRenderer.gd`
- Unit: image-backed artifact display texture orientation and placement.
- Extract to: `app-LTL/src/ui/backpack/BackpackArtifactImageTexture.gd`
- Keep in owner: existing overlay, cooldown, ghost, and image-layer orchestration for this narrow patch.
- Focused proof: `res://tests/run_backpack_layout_contract.gd`

## Runtime Performance Review

- Not a high-frequency combat tick/input path in the request-analysis gate list.
- Texture rotation occurs only when an item display texture is generated and is cached by item type, texture path, normalized rotation, and shape.

## File Size Budget

- `app-LTL/src/ui/backpack/BackpackArtifactRenderer.gd`: 497 lines, cap 500, final shape stays under cap; future non-trivial image logic should extract to `app-LTL/src/ui/backpack/BackpackArtifactImageTexture.gd`.

## Refactor/Delete Disposition

- Keep the existing backpack renderer owner and add only the smallest texture-orientation helper.
- Refactor no unrelated backpack, reward, or artifact systems.
- Delete no files or assets.

## Verification Checklist

- `powershell -NoProfile -ExecutionPolicy Bypass -File tools/invoke-godot.ps1 -ProjectPath app-LTL -Headless -Script res://tests/run_backpack_layout_contract.gd`
- `powershell -NoProfile -ExecutionPolicy Bypass -File tools/invoke-godot.ps1 -ProjectPath app-LTL -Headless -Script res://tests/run_reward_claim_board_contract.gd`
- `powershell -NoProfile -ExecutionPolicy Bypass -File LTL-harness/tools/source-map-gate.ps1 -Root . -Refresh`
- `powershell -NoProfile -ExecutionPolicy Bypass -File LTL-harness/tools/source-map-gate.ps1 -Root .`
- `powershell -NoProfile -ExecutionPolicy Bypass -File tools/project-objectives.ps1 -Mode validate`
- `powershell -NoProfile -ExecutionPolicy Bypass -File tools/run-compile-check.ps1 -RequestLedger docs/request-ledgers/2026-06-28-drill-art-rotation.md`

## Verification Notes

- RED: `run_backpack_layout_contract.gd` failed before implementation with `artifact helper exposes oriented display texture generation`.
- Focused GREEN: `run_backpack_layout_contract.gd` passed with `BACKPACK_LAYOUT_CONTRACT_OK`; Godot emitted existing headless RID/resource cleanup warnings.
- Regression GREEN: `run_reward_claim_board_contract.gd` passed with `REWARD_CLAIM_BOARD_CONTRACT_OK`; Godot emitted existing headless CanvasItem leak warnings.
- Source-map refresh and source-map validation passed.
- Objective validation passed for 21 objectives.
- Full compile/check wrapper passed with `Compilation Check: PASSED (GODOT_CONTRACTS_OK)` when run with this ledger; the wrapper still emitted existing Godot headless leak warnings and legacy oversized test-file warnings.

## Resolution Proof

- RED proof: the new backpack runtime test failed before production changes because `BackpackArtifactRenderer.gd` had no oriented display texture helper.
- Root-cause proof: the same focused contract now verifies a 90-degree pixel rotation and passes with `BACKPACK_LAYOUT_CONTRACT_OK`.
- Workaround guard: reward-claim board contracts still pass, proving the fix did not rely on node rotation that would break existing image containment and docking behavior.

## Artifact Ledger

- No screenshots or generated visual artifacts were created.
