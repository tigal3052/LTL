# Codex Worklog Plan

Workspace: LootingTheLeviathan
Date: 2026-06-11

## Active Work

- Enforce small runtime implementation units after cleanup: review oversized `.gd`/`.tscn` files, split immediately tractable oversized files, and harden the harness so active runtime `.gd`/`.tscn` files default to a 500-line cap with explicit frozen debt for legacy oversized owners.

## Request Summary

- The user completed an unnecessary-code cleanup and requested a large-file review, feature-unit split, subagent review synthesis, and harness-level recurrence prevention.
- Three subagent reviews were used: large `.gd` file analysis, large `.tscn` file analysis, and harness/gate root-cause analysis.
- Immediate implementation will split `RewardVocab.gd` fallback data and `CharacterSelectPage.gd` loadout text helpers, then apply a strict active runtime 500-line gate with frozen legacy-debt exceptions for larger owners that need staged extraction.

## Scope

- `LTL-harness/tools/runtime-size-gate.ps1`
- `LTL-harness/tools/runtime-size-gate.tests.ps1`
- `docs/architectural-gates/runtime-size-gate.md`
- `docs/request-ledgers/2026-06-11-runtime-size-cap-enforcement.md`
- `docs/superpowers/plans/2026-06-11-runtime-size-cap-enforcement-plan.md`
- `app-LTL/src/vocabulary/RewardVocab.gd`
- `app-LTL/src/vocabulary/reward/DefaultMockRewards.gd`
- `app-LTL/src/scenes/pages/CharacterSelectPage.gd`
- `app-LTL/src/scenes/pages/character_select/CharacterSelectLoadoutText.gd`
- `docs/source-map.md`
- `docs/codex-worklog/*.md`

## Out of Scope

- Rewriting all legacy oversized runtime owners in one pass
- Prototype deletion or archive policy changes
- Gameplay redesign, page routing changes, or transition-handoff changes
- Commit / PR work unless explicitly requested later

## Steps

1. Capture subagent findings and finalize the small-file enforcement plan.
2. Add RED self-tests proving the current size gate lacks frozen debt semantics and `.gd`/`.tscn` 500-line global protection.
3. Implement `legacy_debt_path_caps` in the runtime size gate and update the manifest to use strict active runtime 500-line globs.
4. Split fallback reward data out of `RewardVocab.gd`.
5. Split starter loadout text/detail projection out of `CharacterSelectPage.gd`.
6. Update source-map and worklog documents.
7. Verify runtime-size self-tests, real runtime-size gate, source-map gate, focused Godot contracts, and compile check.

## Expected Outputs

- `RewardVocab.gd` and `CharacterSelectPage.gd` reduced below 500 lines through focused helper extraction.
- New helper files that each stay below 500 lines and own one responsibility.
- Runtime-size gate support for explicit frozen legacy debt plus strict active `.gd`/`.tscn` caps.
- A documented root-cause and recurrence-prevention policy for oversized implementation files.

## Verification Method

- `powershell -NoProfile -ExecutionPolicy Bypass -File LTL-harness/tools/runtime-size-gate.tests.ps1`
- `powershell -NoProfile -ExecutionPolicy Bypass -File LTL-harness/tools/runtime-size-gate.ps1 -Root .`
- `powershell -NoProfile -ExecutionPolicy Bypass -File LTL-harness/tools/source-map-gate.ps1`
- `powershell -NoProfile -ExecutionPolicy Bypass -File tools/invoke-godot.ps1 -ProjectPath app-LTL -Headless -Script tests/run_test_reward_contract.gd`
- `powershell -NoProfile -ExecutionPolicy Bypass -File tools/invoke-godot.ps1 -ProjectPath app-LTL -Headless -Script tests/run_character_select_cleanup_contract.gd`
- `powershell -NoProfile -ExecutionPolicy Bypass -File tools/run-compile-check.ps1 -RequestLedger docs/request-ledgers/2026-06-11-runtime-size-cap-enforcement.md`

## Plan Change Log

- 2026-06-11: Worklog bootstrapped automatically by Codex hook.
- 2026-06-11: Plan updated for a two-phase execution sequence: minimal gate/source-map checkpoint commit first, then runtime-separation surgery and harness hardening.
- 2026-06-11: Plan narrowed again for the next refactor wave: extract reward-board layout policy from `MainViewRuntime.gd` with test-first coverage.
- 2026-06-11: Plan narrowed once more to finish the current `MainViewRuntime.gd` helper-extraction wave and prepare a concrete line-count reduction report.
- 2026-06-11: Plan updated again for the next pass: extract page-scene model projection plus app-shell layout policy and document the remaining route to low-hundreds ownership.
- 2026-06-11: Plan updated for the next pass: extract the reward-card cloud runtime and make pre-edit request analysis enforce responsibility-unit decomposition for monitored runtime owners.
- 2026-06-11: Reward-card cloud extraction, source-map updates, and pre-edit runtime-owner responsibility gating were implemented and verified on the current workspace.
- 2026-06-11: Plan updated again for the next pass: extract shared backpack docking and deferred reparent coordination from `MainViewRuntime.gd`.
- 2026-06-11: Plan redirected to a debug-runtime cleanup audit so deletion can be staged from a live-runtime keep list instead of from editor-open or archival scenes.
- 2026-06-11: Cleanup plan corrected to preserve prototypes, define Class A as generated local residue only, and add `.gd`/`.tscn` internal deletion waves for legacy runtime code.
- 2026-06-11: First cleanup execution slice completed: file-level dead residue, stale shop declarations, source-map/test references, and generated cache/log residue were removed after verification.
- 2026-06-11: Full `.gd`/`.tscn` runtime inventory audit completed for all `app-LTL` scenes and scripts, with screenshot mismatch diagnosed as static AppShell ownership in `Main.tscn`.
- 2026-06-11: Plan switched from audit mode to execution mode for the user-requested sequence: node-map legacy removal first, AppShell page-ownership migration second, `ParticleTemplate` validation third.
- 2026-06-11: Requested execution wave completed: node-map runtime wiring removed, gameplay AppShell ownership migrated into page-shell scenes, and `ParticleTemplate` was kept with an explicit `VFXManager` wiring contract plus runtime fallback.
- 2026-06-11: Plan updated for the user's small-unit enforcement request: synthesize subagent review, split immediately tractable oversized files, and harden runtime-size gating with strict `.gd`/`.tscn` caps plus frozen legacy debt.
