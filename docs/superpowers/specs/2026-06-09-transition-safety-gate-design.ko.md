# 2026-06-09 Transition Safety Gate Design

Date: 2026-06-09  
Workspace: `LootingTheLeviathan`

## Goal

Promote transition stability review from an optional debugging habit into a blocking harness policy.

The immediate trigger is the live reward flow failure where the reward ceremony itself passes focused checks, but the handoff into the reward cleanup board still crashes or destabilizes the layout. This design turns that lesson into a reusable gate for every page or phase transition that can carry shared UI state, layout reparenting, or flow ownership changes.

## Problem Statement

The current harness already blocks several adjacent risks:

- request-analysis coverage for scope and verification planning
- page-contract coverage for scene ownership and viewport containment
- compile and quality gates for script validity and main contract runners

What is still missing is a first-class transition review layer. A flow can pass a focused page or overlay contract and still fail at the handoff boundary between two states. The reward ceremony to reward board failure is the concrete example:

- `reward.ceremony` proof passes
- reward inspector stability proof passes
- broader reward-board entry flow still hits layout overflow or native crash risk during the handoff

The gap is not "missing tests" in the abstract. The gap is that no blocking policy currently forces transition-affecting work to declare which handoff changed, what shared state moves across that boundary, and which runner proves the handoff itself is stable.

## Decision

Create a dedicated transition-safety source of truth and a blocking transition-safety gate.

This is separate from the architectural gate. Architectural ownership rules stay where they are, but transition safety gets its own registry, its own request-analysis requirement, and its own verification script so the policy is explicit and easier to extend.

## Ownership Split

- `LTL-harness/docs/transition-safety-gate.md`: source of truth for the rule, registry shape, failure conditions, and verification expectations
- `LTL-harness/tools/transition-safety-gate.ps1`: blocking gate that validates request-ledger coverage and executes the mapped transition proofs
- `LTL-harness/tools/transition-safety-gate.tests.ps1`: self-tests for the gate script behavior
- `LTL-harness/docs/request-analysis-execution-gate.md`: records that transition review is now a required request-analysis stage for transition-affecting work
- `LTL-harness/docs/templates/request-constraint-ledger-template.md`: exposes the new ledger section so authors cannot "forget" the review structure
- `tools/run-compile-check.ps1` and `tools/run-ltl-quality-gate.ps1`: keep the transition-safety gate in the blocking path

## Required Request-Ledger Policy

Every non-trivial request that changes a page, phase, overlay handoff, scene remap, shared host reparent, or state-driven visibility transition must include a `Transition Safety Review` section in its request ledger.

That section must contain one of two shapes:

1. Transition impact exists

- touched transition ids
- entry owner
- exit owner
- shared state or shared layout handoff risks
- required runner or contract path
- expected success marker
- notes on whether coverage already exists or must be added in the same change

2. No transition impact

- explicit statement that the request does not alter any runtime handoff boundary
- short reason explaining why the work is transition-neutral

The gate must fail if the section is missing, empty, or left in placeholder form for work that touches transition-relevant surfaces.

## Required Gate Behavior

The new gate must enforce all of the following:

1. Ledger enforcement

- If the request is transition-affecting, `Transition Safety Review` is required before completion.
- The section must name at least one transition id or explicitly declare `no transition impact`.
- The section must reference at least one runnable proof when a transition is touched.

2. Proof enforcement

- A transition is not considered covered unless its mapped runner executes and emits the expected success marker.
- Exit code success alone is insufficient.
- Existing runner reuse is allowed only when that runner explicitly proves the transition boundary in question.
- Existing coverage that currently relies on exit code only must be normalized to marker-required proof in the new transition registry path.

3. Hard failure signals

The gate must fail immediately if runner output contains any of the following:

- `CrashHandlerException`
- `signal 11`
- `SCRIPT ERROR`
- `Parse Error`
- `Failed to load script`

4. Aggregated blocking role

- `tools/run-compile-check.ps1` must keep this gate in the pre-compile blocking path for relevant work.
- `tools/run-ltl-quality-gate.ps1` must keep this gate in the broader blocking verification path.
- Transition-affecting work is not complete unless the transition-safety gate passes.

## Baseline Transition Registry

The initial source of truth should register the current critical boundaries that already have, or should have, dedicated runners.

### `meta.start_flow`

- Transition: boot to live start page shell
- Existing runner: `app-LTL/tests/run_main_start_flow_contract.gd`
- Expected marker: `MAIN_START_FLOW_CONTRACT_OK`
- Purpose: prove the app can enter the main flow shell without breaking the initial page ownership contract

### `page.scene_mapping`

- Transition: read-model page id to runtime scene owner resolution
- Existing runner: `app-LTL/tests/run_page_scene_mapping_contract.gd`
- Expected marker: `PAGE_SCENE_MAPPING_CONTRACT_OK`
- Purpose: prove page ownership does not silently drift during scene/token remaps

### `reward.ceremony`

- Transition: combat clear into reward reveal ceremony
- Existing runner: `app-LTL/tests/run_reward_ceremony_contract.gd`
- Expected marker: `REWARD_CEREMONY_CONTRACT_OK`
- Purpose: prove ceremony sequencing, reveal ordering, and focused reward reveal behavior

### `reward.handoff`

- Transition: reward ceremony completion into reward cleanup board / tray review ready state
- Existing runner: new dedicated runner required
- Expected marker: new marker defined with the runner, for example `REWARD_HANDOFF_CONTRACT_OK`
- Purpose: prove the full handoff boundary, including page switch, shared backpack docking/reparent, inspector-ready board layout, and crash-free board entry

The registry format should make it easy to add future transitions such as shop entry, codex overlay return, event resolution exit, boss reward entry, and defeat recovery flow.

## Reward Handoff Motivation

The reward crash is the example this gate is designed to catch earlier.

Current evidence shows:

- `reward.ceremony` passes
- reward inspector-focused stability passes
- broader reward board entry still fails in a more realistic flow

That means the unstable unit is not just a page and not just a component. It is the boundary between states. The new gate formalizes the rule that a boundary with shared state handoff must own a boundary-level proof.

## Requested Implementation Shape

The follow-up implementation should make these concrete changes:

1. Documentation

- add `LTL-harness/docs/transition-safety-gate.md`
- update `LTL-harness/docs/request-analysis-execution-gate.md`
- update `LTL-harness/docs/templates/request-constraint-ledger-template.md`
- update `LTL-harness/00_AGENTS.md`
- update `LTL-harness/README.md`

2. Script layer

- add `LTL-harness/tools/transition-safety-gate.ps1`
- add `LTL-harness/tools/transition-safety-gate.tests.ps1`
- wire the gate into `tools/run-compile-check.ps1`
- wire the gate into `tools/run-ltl-quality-gate.ps1`

3. Runner layer

- keep existing transition proofs for `meta.start_flow`, `page.scene_mapping`, and `reward.ceremony`
- add a new reward-handoff runner that drives the full combat-clear to tray-review-ready path and proves the success marker without native crash or script load failure

## Verification Targets

The implementation is only acceptable if all of the following are true:

- request-analysis gate structure includes transition review requirements
- request ledger template exposes `Transition Safety Review`
- transition-safety gate self-tests pass
- transition-safety gate fails on crash strings, parse/script-load errors, and missing markers
- transition-safety gate passes on a valid covered transition
- legacy contract reuse does not silently downgrade into exit-code-only success when the transition registry expects a marker
- `tools/run-compile-check.ps1` and `tools/run-ltl-quality-gate.ps1` both treat the gate as blocking
- reward-handoff coverage exists as a dedicated proof instead of relying on ceremony-only success

## Non-Goals

- This design does not claim the current reward-handoff runtime crash is fixed yet.
- This design does not merge transition safety into the existing architectural gate.
- This design does not require every trivial text change to run transition proofs when the request is explicitly transition-neutral.

## Review Checklist

- Does the policy clearly separate page stability from transition stability?
- Does the ledger requirement make the handoff risk visible before implementation ends?
- Does the baseline registry include the current reward-handoff gap explicitly?
- Are the blocking conditions strict enough to catch native crash output and silent marker-missing false positives?

If these answers stay "yes", the next step is implementation planning and harness wiring.
