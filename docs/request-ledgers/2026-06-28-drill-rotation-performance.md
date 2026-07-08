# Request Constraint Ledger

## Request Summary

- Implement the approved drill rotation performance plan so image-backed drills rotate smoothly with the footprint without synchronous pixel rotation or texture generation on the rotation hot path.

## Preserved Invariants

- Preserve artifact shape rotation, placement occupancy, collision, and backpack drop rules.
- Preserve reward-table data semantics and existing drill/beacon image assets.
- Preserve the previous visual alignment fix: drill images and rotated footprints must remain directionally matched.
- Preserve existing backpack/reward UI layout, cooldown masks, influence highlighting, and shared backpack handoff.
- Preserve `R` key echo/debounce behavior.
- Do not commit or push.

## Mutable Scope

- `app-LTL/src/ui/backpack/BackpackArtifactImagePlacement.gd`
- `app-LTL/src/ui/backpack/BackpackArtifactRenderer.gd`
- `app-LTL/src/ui/BackpackUI.gd`
- `app-LTL/tests/ui_read_models/backpack_layout/ui_backpack_runtime_suite.gd`
- `app-LTL/tests/run_backpack_rotation_performance_contract.gd`
- `docs/source-map.md`
- `docs/codex-worklog/plan_LootingTheLeviathan_2026-06-28.md`
- `docs/codex-worklog/history_LootingTheLeviathan_2026-06-28.md`
- `docs/codex-worklog/complete_LootingTheLeviathan_2026-06-28.md`

## Source Map Findings

- `docs/source-map.md` maps `app-LTL/src/ui/backpack/BackpackArtifactRenderer.gd` to backpack artifact overlays, image-backed drill overlays, drag ghost geometry, and cooldown masks.
- `docs/source-map.md` maps `app-LTL/src/ui/BackpackUI.gd` to backpack grid input, artifact overlay, drag ghost, and image layer refresh ownership.
- The new helper will own image-backed artifact placement transforms so the renderer does not grow beyond the runtime size cap.

## Root Cause Review

- Observed symptom: drill image rotation now follows the footprint, but rotation is visibly hitchy.
- Evidence: `MainController._on_key_pressed(KEY_R)` rotates the held artifact and immediately calls `view.update_backpack_ghost()`. That path calls `BackpackArtifactRenderer.item_texture_for_artifact()`, whose current cache key includes normalized rotation and shape; a first visit to each orientation calls `oriented_display_texture()`, `_rotated_texture()`, `Texture2D.get_image()`, per-pixel loops, and `ImageTexture.create_from_image()` synchronously.
- Root cause target: `app-LTL/src/ui/backpack/BackpackArtifactRenderer.gd`
- Rejected workaround: debounce or suppress repeated `R` input, because the request explicitly keeps input policy unchanged and it would mask texture-generation hitching.
- Chosen fix: keep base display textures cached without rotation in the hot-path cache key, and apply rotation via `TextureRect` transform/pivot/center placement.

## Transition Safety Review

- no transition impact.
- Entry owner: no page or phase transition owner touched.
- Exit owner: no page or phase transition owner touched.
- Shared state risk: the change is limited to image placement and does not change inventory state, reward flow, page handoff, or shared backpack reparenting.
- Runner proof: `res://tests/run_reward_claim_board_contract.gd` remains the regression proof for reward/backpack docking and image containment.

## Feature Unit Lifecycle Plan

- Design stage: split transform-based item image placement into `BackpackArtifactImagePlacement.gd`.
- Implementation stage: add RED coverage for hot-path cache/node stability before changing production placement.
- Maintenance stage: keep pixel-oriented `oriented_display_texture()` only as compatibility/test helper; future live placement behavior should use the placement helper.
- Capsule boundary: renderer orchestrates item overlays; helper owns `TextureRect` transform, pivot, size, and center placement.
- Size trigger: `BackpackArtifactRenderer.gd` is already near the 500-line cap, so production logic must be moved out instead of added inline.

## Execution Responsibility Units

- Owner: `app-LTL/src/ui/backpack/BackpackArtifactRenderer.gd`
- Unit: image-backed artifact texture lookup and overlay creation.
- Extract to: `app-LTL/src/ui/backpack/BackpackArtifactImagePlacement.gd`
- Keep in owner: existing overlay, cooldown, ghost, and image-layer orchestration.
- Focused proof: `res://tests/run_backpack_rotation_performance_contract.gd`

## Runtime Performance Review

- Hot path: `KEY_R` -> `held_artifact.rotate_shape()` -> `view.update_backpack_ghost()` -> `BackpackUI.update_ghost_display()` -> item texture lookup and `TextureRect` placement.
- Risk: synchronous image pixel rotation, `ImageTexture` creation, cache misses, and ghost node churn during rotation input.
- Budget: after warm setup, repeated rotation must add zero texture-cache entries, reuse the same ghost `TextureRect`, avoid image-backed ghost children, avoid queued image refresh, and reflect rotation/footprint in one frame. Time measurement is secondary with a 60fps-safe 2ms warmed average target.

## File Size Budget

- `BackpackArtifactRenderer.gd` must stay under the existing 500-line runtime helper contract.
- `BackpackUI.gd` must stay under its existing size cap.
- New helper should remain focused and small.

## Refactor/Delete Disposition

- Refactor only image placement logic required to remove the hot-path hitch.
- Delete no files or assets.
- Do not refactor unrelated backpack, reward, combat, or objective systems.

## Verification Checklist

- `powershell -NoProfile -ExecutionPolicy Bypass -File tools/invoke-godot.ps1 -ProjectPath app-LTL -Headless -Script tests/run_backpack_rotation_performance_contract.gd`
- `powershell -NoProfile -ExecutionPolicy Bypass -File tools/invoke-godot.ps1 -ProjectPath app-LTL -Headless -Script tests/run_backpack_layout_contract.gd`
- `powershell -NoProfile -ExecutionPolicy Bypass -File tools/invoke-godot.ps1 -ProjectPath app-LTL -Headless -Script tests/run_reward_claim_board_contract.gd`
- `powershell -NoProfile -ExecutionPolicy Bypass -File LTL-harness/tools/source-map-gate.ps1 -Root . -Refresh`
- `powershell -NoProfile -ExecutionPolicy Bypass -File LTL-harness/tools/source-map-gate.ps1 -Root .`
- `powershell -NoProfile -ExecutionPolicy Bypass -File tools/project-objectives.ps1 -Mode validate`
- `powershell -NoProfile -ExecutionPolicy Bypass -File tools/run-compile-check.ps1 -RequestLedger docs/request-ledgers/2026-06-28-drill-rotation-performance.md`

## Verification Notes

- RED: `run_backpack_rotation_performance_contract.gd` first failed before implementation because `BackpackArtifactImagePlacement.gd` did not exist, rotation cache size grew from 1 to 4 across repeated rotations, and warmed average lookup/placement exceeded the 2ms budget.
- GREEN: `run_backpack_rotation_performance_contract.gd` passed with `BACKPACK_ROTATION_PERFORMANCE_CONTRACT_OK`.
- GREEN: `run_backpack_layout_contract.gd` passed with `BACKPACK_LAYOUT_CONTRACT_OK`; Godot emitted existing headless RID/resource cleanup warnings.
- GREEN: `run_reward_claim_board_contract.gd` passed with `REWARD_CLAIM_BOARD_CONTRACT_OK`; Godot emitted existing headless CanvasItem/ObjectDB leak warnings.
- GREEN: source-map refresh passed with `SOURCE_MAP_REFRESH_OK` and `SOURCE_MAP_GATE_OK`.
- GREEN: source-map validation passed with `SOURCE_MAP_GATE_OK`.
- GREEN: objective validation passed for 23 objectives with `PROJECT_OBJECTIVE_GATE_VALIDATE_OK`.
- GREEN: full compile wrapper passed with `Compilation Check: PASSED (GODOT_CONTRACTS_OK)`.

## Resolution Proof

- RED proof: `run_backpack_rotation_performance_contract.gd` failed before production changes because the helper was missing and repeated rotation grew the display texture cache from 1 to 4 while missing the warmed 2ms average budget.
- Root-cause proof: the same focused contract now passes, verifying repeated rotation uses a prepared display texture without cache growth, reuses the same ghost `TextureRect`, applies rotation immediately, and stays within the warmed 2ms average budget.
- Workaround guard: existing backpack layout and reward-claim board contracts still pass, proving the transform-based placement preserved prior image orientation, helper exposure, shared backpack docking, and item image containment behavior.

## Artifact Ledger

- No screenshots or generated visual artifacts expected.
