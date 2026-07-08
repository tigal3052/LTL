# Codex Worklog Plan

Workspace: LootingTheLeviathan
Date: 2026-06-28

## Active Work

Backpack drill art rotation performance follow-up.

## Request Summary

Implement the approved plan to remove hitching from image-backed drill rotation. The fix should keep rotated drill artwork aligned with the artifact footprint while avoiding synchronous pixel rotation, `ImageTexture` creation, cache growth, and ghost node churn on the rotation hot path. Tie the work to `BACKPACK-001`, `BACKPACK-002`, and `VERIFY-001`.

## Scope

- Add a focused backpack rotation performance contract before production changes.
- Extract oriented image placement into a small helper so the already-large renderer stays below size caps.
- Change backpack item-art placement to rotate `TextureRect` nodes around their footprint center instead of generating rotated textures during input.
- Keep existing shape rotation, placement, reward data, art assets, and `R` key echo/debounce behavior unchanged.
- Update request ledger, source-map freshness, history, and completion notes.

## Out of Scope

- Changing reward data semantics, item sizes, footprint occupancy rules, or drill image assets.
- Changing `R` key repeat/debounce policy.
- Refactoring unrelated backpack, reward, combat, objective, or EnergyToken systems.
- Git commit or push.

## Steps

- Add RED coverage for the rotation hot path: no cache growth, no ghost node churn, stable texture rect, immediate rotation/footprint update.
- Run the focused contract and confirm it fails against the current pixel-rotation/cache-miss implementation.
- Add `BackpackArtifactImagePlacement.gd` and wire renderer/UI placement through it.
- Re-run the focused contract, backpack layout contract, reward-claim board contract, source-map refresh/validation, objective validation, and compile wrapper.
- Record meaningful history and completion notes with objective ids and verification evidence.

## Expected Outputs

- New helper for transform-based artifact image placement.
- Backpack renderer/UI updates that reuse cached base display textures and rotate `TextureRect` nodes instead of generating rotated textures on the hot path.
- New focused performance contract runner and runtime-suite test coverage.
- Updated request ledger, source-map, and worklog reports.

## Verification Method

- Focused Godot contract for backpack rotation performance and cache/node stability.
- Existing backpack layout and reward claim board contracts.
- Source-map refresh/validation, objective validation, and compile wrapper with the new request ledger.

## Plan Change Log

- 2026-06-28: Worklog bootstrapped automatically by Codex hook.
- 2026-06-28: Scoped active request to rotated drill artwork alignment (`BACKPACK-001`, `VERIFY-001`).
- 2026-06-28: Re-scoped active request to the follow-up drill rotation performance fix after the pixel-rotation alignment patch exposed input hitching risk (`BACKPACK-001`, `BACKPACK-002`, `VERIFY-001`).
