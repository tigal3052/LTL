# Codex Worklog Plan

Workspace: LootingTheLeviathan
Date: 2026-06-23

## Active Work

Boss-stage clear skips reward acquisition and goes directly to the clear page.

## Request Summary

When the final boss stage is cleared immediately before expedition completion, skip the reward acquisition/reward-board process and transition straight to the run clear screen.

## Scope

- Detect final boss-stage combat clears in the formal phase flow.
- Transition final boss clears directly to `run_complete`/clear page state.
- Preserve normal and non-final stage reward acquisition behavior.
- Preserve completion progress and M8 result unlock updates even though the final boss reward phase is skipped.
- Update focused tests and M8 vertical-slice expectations to prove the skipped final reward phase.

## Out of Scope

- Reward table, reward roll balance, artifact generation, or reward UI redesign.
- Normal stage reward acquisition changes.
- Combat damage, hazard, node generation, or backpack placement behavior changes.
- Reverting or cleaning unrelated dirty worktree changes.

## Steps

- Add a RED test showing M8 final boss clear reaches `run_complete` without opening a third reward phase.
- Add a focused phase-level guard for final boss clear versus normal clear behavior if needed.
- Refactor shared run-completion state updates into a small helper so final boss clear and reward-claim completion keep the same progress/unlock result.
- Change only the final boss clear branch in `CombatPhase`.
- Run focused Godot contract(s), `git diff --check`, and record history/completion.

## Expected Outputs

- Final boss combat clear returns a `run_complete` snapshot immediately.
- The UI page projection resolves to `clear`, not `boss_reward`, after final boss clear.
- M8 clear observes two reward phases for the two pre-boss stages, not three.
- Normal non-final combat clears still enter `reward_loot` with pending rewards.
- Completion progress and starter unlocks still apply on clear.

## Verification Method

- RED: M8 vertical-slice test fails before production changes because it expects two reward phases and immediate final completion.
- GREEN: the same test passes after the phase-flow change.
- Focused phase/runner checks verify normal clear still enters `reward_loot`.
- Static check: `git diff --check`.
- Final REQUEST RECHECK against the Korean request checklist.

## Plan Change Log

- 2026-06-23: Replaced the previous battle-backpack plan with the current boss-stage reward-skip request plan.
