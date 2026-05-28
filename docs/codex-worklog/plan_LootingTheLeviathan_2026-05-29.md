# Codex Worklog Plan

Workspace: LootingTheLeviathan
Date: 2026-05-29

## Active Work

Fix follow-up UI QA issues: artifact cooldown must render as a continuously shrinking translucent black mask, purple terrain debuff tiles must read as a status marker instead of a new terrain background, and reward/artifact labels must not expose size/version/color implementation tags.

## Request Summary

- Cooldown fill still appears to step around one-second backend snapshots.
- Purple energy debuff rendering looks like a new purple terrain tile.
- Item names still expose raw tags such as `v2` and `(Red)`.

## Scope

- Add regression tests for cooldown mask math and item tag stripping.
- Update `BackpackUI` to animate cooldown from frame delta instead of only easing between backend snapshots.
- Render cooldown as a translucent black mask that shrinks away as energy recharges.
- Tone down purple terrain debuff visuals to a small marker/crack overlay.
- Strip size/version/color tags from user-facing item labels and artifact names.

## Out of Scope

- No full balance pass beyond the requested color identity rules.
- No new art assets for the parchment panel.
- No broader combat node generation redesign.

## Steps

- Write failing UI/name regression tests.
- Implement cooldown mask helper functions and continuous frame display.
- Sanitize reward-created artifact names and reward reveal silhouette labels.
- Replace purple full-tile haze with a compact debuff marker.
- Run Godot contract checks, i18n gate if text keys change, and `git diff --check`.

## Expected Outputs

- Smooth black cooldown mask drain.
- Clear explanation and subtler visual for purple terrain debuffs.
- Clean user-facing artifact names without size/version/color tags.
- Updated worklog and verification notes.

## Verification Method

- `powershell -NoProfile -ExecutionPolicy Bypass -File tools/run-compile-check.ps1`
- `git diff --check`

## Plan Change Log

- 2026-05-29: Worklog bootstrapped automatically by Codex hook.
- 2026-05-29: Re-scoped to follow-up M4 UI QA: cooldown mask smoothing, purple debuff readability, and item label cleanup.
