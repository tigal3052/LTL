# M1. Core Domain Stabilization

## Goal

Promote the browser-verified prototype rules into formal, engine-agnostic domain contracts so the next implementation stage can consume stable APIs, JSON schemas, replay fixtures, and phase/state records without depending on browser-only internals.

## Inputs

- `docs/11_exec-plans/02_completed/01_P0_test_harness_and_logs_completed.md`
- `docs/11_exec-plans/02_completed/02_P1_headless_core_loop_completed.md`
- `docs/11_exec-plans/02_completed/03_P2_combat_control_slice_completed.md`
- `docs/11_exec-plans/02_completed/04_P3_backpack_and_hazard_slice_completed.md`
- `docs/11_exec-plans/02_completed/05_P4_mini_run_and_scaling_completed.md`
- `docs/11_exec-plans/02_completed/06_M0_redesign_gate_completed.md`
- `docs/00_tech-debt-tracker.md`
- browser SoT code in `app-LTL/src/*`

## Why This Milestone Exists

P0~P4 proved that the prototype loop works, but M0 also confirmed that several contracts are still implicit, browser-shaped, or incomplete:

- replay coverage is below the redesigned gate matrix
- loader-facing schemas are not formalized
- reward/progression data is still prototype-shaped
- root and phase state are only partially stabilized
- UI consumers still risk reaching into internal structures

M1 exists to stabilize those boundaries before larger engine or scene work continues.

## Deliverables

- formal domain-facing JSON schemas and validators for:
  - artifacts
  - nodes
  - rewards
  - leviathans
  - progress/save data
- promoted replay regression suite that covers the M0 fixture matrix
- stabilized root/phase state contract and snapshot shape
- domain API documentation for screen/scene consumers
- updated technical-debt tracker entries reflecting what M1 resolves vs defers

## Explicit Non-Goals

- full Godot scene reconstruction
- final reward-page visuals or terrain-to-reward transition implementation
- full progression/meta growth loop implementation
- narrative systems

## Contract Baseline From M0

### Browser SoT kept

- browser combat rules remain the M1 source-of-truth baseline
- `queue / time / pin` combat rhythm remains intact

### Mini-run structure reclassified

- current 5-stage browser loop is test-scale only
- final Leviathan-driven structure must come from master data:
  - 4~6 stages per mini-run
  - 3~5 mini-runs per Leviathan
  - each mini-run final stage is a boss stage

### Required schema decisions

- artifact required fields:
  - `id`
  - `name`
  - `shape`
  - `energyType`
  - `baseCooldownTicks`
  - `synergy`
  - `keyword`
- node required fields:
  - `id`
  - `label`
  - `weakness`
  - `pickWeight`
  - `shieldMul`
  - `healthMul`
- node optional field:
  - `alwaysOffer`
- Leviathan master fields:
  - `id`
  - `name`
  - `stageCnt`
  - `runCnt`
- progress/save fields:
  - `clearedLeviathanIds`

### Required phase-state decisions

- root common state:
  - `seed`
  - `stageIndex`
  - `maxStages`
  - `inventory`
  - `leviathanId`
  - `runIndex`
- `node_select` phase:
  - `candidates`
- `combat` phase:
  - `combat`
- `reward_loot` phase:
  - `pendingRewards`
  - `held`
  - `lastNodeLabel`

### Required replay/fixture decisions

Promoted M1 replay/fixture coverage must include:

- one-shot clear
- empty-queue repair pressure
- mismatch attack
- reward claim to next stage
- final stage clear to run complete
- run-complete branching
  - Leviathan clear end
  - next run progression
- reward-phase last-artifact removal guard

## Task Breakdown

### Task 1. Freeze and document formal data contracts

- Create formal JSON schema docs or validator-backed shape definitions for:
  - artifacts
  - nodes
  - rewards
  - leviathans
  - progress/save
- Move reward data out of code constants into JSON-backed structures where the contract now requires it.
- Ensure browser-only presentation fields are excluded from formal loader input.

### Task 2. Add loader/validator coverage

- Add validators that fail when required fields are missing.
- Add fixture-level tests for invalid artifact/node/reward/leviathan/progress inputs.
- Make validator failures readable enough that future Godot-side loaders can mirror the same contract.

### Task 3. Promote replay regression coverage to the M0 matrix

- Extend fixture inputs and replay assertions until all gate-approved scenarios are represented.
- Keep replay as a browser-SoT follower, not a parallel rule source.
- Add summary-level assertions where the gate decisions expect them.

### Task 4. Stabilize root and phase-state contracts

- Align domain/runtime state with the M0 root common state and per-phase state boundaries.
- Remove or isolate prototype-only state that leaks browser implementation details into core logic.
- Add snapshot backward-compatibility tests so downstream consumers can depend on a stable read model.

### Task 5. Stabilize domain API boundaries

- Provide a documented domain-facing API or snapshot contract so future scene/UI code can render state without inspecting private internals.
- Mark deprecated aliases and browser-era compatibility shims explicitly.
- Reduce direct coupling between renderers/controllers and low-level domain object internals.

### Task 6. Record what stays deferred

- Update `docs/00_tech-debt-tracker.md` when M1 closes tasks.
- Carry forward deferred items that remain intentionally out of scope:
  - full meta progression implementation
  - final Godot reward/overlay scene composition
  - narrative systems

## Suggested Implementation Order

1. formalize artifact/node/leviathan/progress/reward schemas
2. add validator tests for missing required fields
3. promote replay fixtures to the redesign-gate matrix
4. align root/phase state and snapshot output
5. publish domain API/snapshot documentation
6. reconcile the tech-debt tracker

## TDD Targets

- replay regression covers every promoted M0 fixture scenario
- JSON validators reject missing required fields
- root snapshot preserves the stabilized contract
- phase-specific records expose only the intended phase data
- browser-facing consumers can render through the documented API/snapshot contract without reading hidden internals

## Completion Criteria

- all promoted replay scenarios exist and pass
- validator coverage exists for every formal data contract
- the stabilized root/phase state contract is reflected in runtime snapshots
- reward, leviathan, and progress data boundaries are no longer implicit
- future UI/scene code can consume a documented domain API instead of poking through browser prototype state
- the tech-debt tracker clearly distinguishes what M1 resolved vs deferred

## Exit Evidence

- green automated tests for replay, validation, and snapshot compatibility
- updated milestone docs and tracker
- explicit references from the implementation back to the M0 redesign-gate decisions
