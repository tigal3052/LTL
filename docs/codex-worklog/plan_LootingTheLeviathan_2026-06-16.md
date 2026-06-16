# Codex Worklog Plan

Workspace: LootingTheLeviathan
Date: 2026-06-16

## Active Work

Checkpoint and push the current M6 implementation state, then use
`docs/superpowers/plans/2026-06-13-m7-narrative-integration-replan.ko.md`
to mark M6 complete and finish M7 narrative integration.

## Request Summary

The user asked to first commit and push the current state, then complete M6
handling and implement M7 from the existing M7 narrative integration replan.
The checkpoint commit was created and pushed before any M7 implementation edits.

## Scope

- Preserve the pushed checkpoint as the clean boundary before M7 work.
- Read the M7 replan and adapt it to the current split controller/runtime
  architecture.
- Add M7 narrative beat data contracts, selection/history capsules,
  read-model projection, telemetry payloads, non-blocking UI rendering, and
  page-model pass-through where needed.
- Update M6 completion documentation if the repository still has M6 items that
  need explicit completion/signoff state.
- Add or update focused Godot contract coverage for narrative trigger selection,
  shown-once history, replay invariance, telemetry payloads, and required data
  shape.
- Run the available compile/quality gates and record exact verification results.

## Out Of Scope

- Reworking unrelated M4-M6 UI, backpack, combat, reward, or harness code.
- Reverting the user's checkpointed changes.
- Large copy rewrites outside the M7 terminology and narrative surfaces.
- Creating a new branch or worktree after the user requested this branch's
  current state to be committed and pushed.

## Steps

- Inspect current architecture and compare it with the M7 replan.
- Add RED tests for narrative content shape and pure selection/history behavior.
- Implement minimal narrative data/model/history/selection/telemetry capsules.
- Wire narrative projection into the current controller/view split without
  changing combat, reward, node generation, or phase reducer results.
- Add non-blocking narrative toast rendering and page-model narrative pass-through.
- Update M6/M7 docs and worklog history.
- Run focused checks, `tools/run-compile-check.ps1`, `tools/run-ltl-quality-gate.ps1`,
  and `git diff --check` where feasible.

## Expected Outputs

- Current checkpoint commit remains pushed to
  `codex/m4-m9-release-quality-implementation`.
- Six M7 core narrative beats exist with screen/display/skip metadata.
- Narrative seen state is stored separately from combat/reward domain outputs.
- Narrative selection is side-effect-free and shown-once aware.
- Runtime can show a non-blocking narrative surface and emit narrative telemetry.
- M6 completion docs and M7 manual signoff docs reflect the current status.

## Verification Method

- RED/GREEN focused Godot contract additions around M7 narrative behavior.
- `powershell -NoProfile -ExecutionPolicy Bypass -File tools/run-compile-check.ps1`
- `powershell -NoProfile -ExecutionPolicy Bypass -File tools/run-ltl-quality-gate.ps1`
- `git diff --check`

## Plan Change Log

- 2026-06-16: Replaced the reward-drop regression plan with the user's requested
  checkpoint, M6 completion, and M7 narrative integration plan. Checkpoint commit
  `d02e6e0` was pushed before this plan update.
- 2026-06-16: M7 implementation reached green verification; final step is to
  commit and push the M7 implementation bundle.
