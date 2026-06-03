# Codex Worklog Plan

Workspace: LootingTheLeviathan
Date: 2026-06-03

## Active Work

Fix the reported M5 live regressions around obstacle family distribution, battlefield shift cadence, queue-token color rendering, relic reward surfacing, and obstacle visual identity.

Provide a graphics-direction consultation for the artifact codex book UI by reviewing `ItemBook.png` together with the existing tile, pin, backpack, and log-panel assets.

## Request Summary

- Make `red`, `blue`, `purple`, and `green` obstacles appear fairly instead of red monopolizing low-pressure spawns.
- Restore battlefield movement to every `1.5` seconds even after a non-terminal shot changes combat feedback.
- Restore visible energy colors in the queue panel after the move to dictionary queue tokens.
- Make stage-clear rewards actually surface the new `relic` items alongside drills and beacons.
- Deepen obstacle visuals per family using sub-agent discussion and reflect that direction in the cell renderer.
- Review the current codex-adjacent UI art language and deliver a text-only decoration direction for a future book-style codex pass.

## Scope

- Inspect the runtime path for obstacle spawn ordering, shift gating, reward rolls, and queue rendering.
- Patch combat/UI code so obstacle waves rotate families and timer-based battlefield shifts continue after transient shot results.
- Patch reward rolling so same-rarity relics are guaranteed to surface when a generated tray includes eligible relic candidates.
- Strengthen obstacle rendering in `src/ui/CellView.gd` with family-specific silhouettes, state cues, and clearer afterglow feedback.
- Update regression tests for queue-token dictionaries, shift cadence, and obstacle-family rotation.

## Out of Scope

- Reverting unrelated dirty-worktree changes already present in the repository.
- Expanding the relic table into new `epic+` content tiers beyond the approved launch slice.
- Returning to the earlier codex UI redesign thread for implementation in this pass. A graphics-only direction review is allowed.

## Steps

- Inspect the obstacle spawn loop, shift reducer gate, reward roll path, and queue panel renderer.
- Integrate sub-agent findings for obstacle runtime diagnosis and family-specific visual treatment.
- Patch combat/UI/reward code and add focused regression coverage for family rotation and post-shot shifts.
- Run targeted plus full Godot verification and record any runtime blockers if the engine crashes before contracts execute.
- Review `ItemBook.png`, tile/pin/book-adjacent assets, and existing codex mockups to produce book-decoration guidance without touching runtime code.

## Expected Outputs

- Fairer four-family obstacle spawning in the live combat runtime
- Restored `1.5s / 30 tick` battlefield shift behavior after non-terminal shots
- Queue panel rendering that reads dictionary queue tokens correctly
- Stage rewards that can visibly include launch relics
- Stronger red/blue/purple/green obstacle overlays in the battlefield cells
- A graphics-system recommendation for codex hero/detail framing, thumbnail states, rarity treatment, and visual consistency rules
- Updated worklog files for 2026-06-03

## Verification Method

- Focused start-flow contract run through `tests/run_start_option_contract.gd`
- Broad regression run through `tests/godot_contract_runner.gd`
- `git diff --check` for whitespace regressions
- If Godot crashes before executing contracts, record the native exit code and treat automated verification as blocked
- For the codex direction review, inspect the existing UI PNG assets plus `docs/mockups/codex-book-approaches.html` and summarize the resulting art principles.

## Plan Change Log

- 2026-06-03: Re-scoped the stale codex UI note back to the requested M5 regression fixes and obstacle visual pass.
- 2026-06-03: Added a consultation-only codex decoration review based on `ItemBook.png` and current UI assets; no runtime or scene implementation is included in this note.
