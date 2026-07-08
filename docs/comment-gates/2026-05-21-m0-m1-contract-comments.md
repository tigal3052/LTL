# Comment Gate Ledger

date: 2026-05-21
task: m0-m1-contract-comments
phase: execution-only
approval: approved
targets:
  - app-LTL/src/domain/FormalContracts.gd
  - app-LTL/src/process/HeadlessMiniRun.gd
  - app-LTL/src/process/ReplayProcess.gd
  - app-LTL/src/process/CombatInputAdapter.gd
  - app-LTL/src/ui/SceneReadModel.gd
  - app-LTL/src/ui/CombatSceneModel.gd
  - app-LTL/src/tools/FormalReplayRunner.gd
  - app-LTL/tests/godot_contract_runner.gd

## Contract Summary

- M0 fixes which contracts are promoted from the browser prototype into the formal Godot path.
- M1 stabilizes those contracts as GDScript-authored validators, replay orchestration, root and phase snapshots, and UI-safe read models.
- Prototype browser code is reference-only behavior SoT.
- The quarantined Godot attempt is structure reference only and must not be copied back into the formal path.

## Execution Sentence List

- `FormalContracts.gd` will validate and normalize formal data and public snapshot contracts.
- `HeadlessMiniRun.gd` will own deterministic root-state progression across node select, combat, reward, and run completion.
- `ReplayProcess.gd` will replay fixture input logs through the formal headless run and emit regression-facing results.
- `CombatInputAdapter.gd` will translate replay or scene input into the combat event shape accepted by the headless runtime.
- `SceneReadModel.gd` will expose a scene-safe public read model from stabilized root and phase snapshots.
- `CombatSceneModel.gd` will expose combat-only presentation data without leaking private domain internals.
- `FormalReplayRunner.gd` will run deterministic replay smoke scenarios for headless verification.
- `godot_contract_runner.gd` will run the formal validator, replay, and snapshot contract suite in headless Godot.

## Detailed Execution Scope

- `FormalContracts.gd`
  - Declare required and optional key sets per contract kind.
  - Validate raw entries and snapshot boundaries.
  - Shape diagnostics into loader/test-friendly results.
- `HeadlessMiniRun.gd`
  - Build initial root state from seed and formal inputs.
  - Advance node-select, combat, reward, and run-complete transitions with phase guards.
  - Expose only public snapshot fields.
- `ReplayProcess.gd`
  - Parse fixture intake, validate ordering, and prepare deterministic runtime state.
  - Replay normalized inputs and collect step/final regression evidence.
  - Compare replay-visible results against expected assertions.
- `CombatInputAdapter.gd`
  - Classify raw input kinds.
  - Normalize tick/target/input fields.
  - Emit guard diagnostics for invalid combat events.
- `SceneReadModel.gd`
  - Project shared root fields first.
  - Project phase-specific render data next.
  - Remove private or browser-era leakage before exposing the model.
- `CombatSceneModel.gd`
  - Shape combat HUD, target, queue, and feedback data.
  - Return safe empty/invalid-phase models when combat data is unavailable.
- `FormalReplayRunner.gd`
  - Select smoke fixtures, execute replay loop, accumulate failures, and shape aggregate output.
- `godot_contract_runner.gd`
  - Run validator cases, replay matrix cases, snapshot boundary cases, and read-model leakage cases.

## Forbidden Dependencies

- SceneTree mutation inside domain or replay contract files
- Browser or Node runtime APIs
- Direct reads from `prototype/**` or `_quarantine*/**` at runtime
- UI labels, DOM concepts, or presentation-only browser fields in formal contracts
- Hidden global randomness; all randomness must stay seed-driven

## Verification Commands

```powershell
& '.\LTL-harness\tools\comment-first-gate.ps1' `
  -Mode comment-only `
  -Root '.' `
  -Targets @(
    'app-LTL/src/domain/FormalContracts.gd',
    'app-LTL/src/process/HeadlessMiniRun.gd',
    'app-LTL/src/process/ReplayProcess.gd',
    'app-LTL/src/process/CombatInputAdapter.gd',
    'app-LTL/src/ui/SceneReadModel.gd',
    'app-LTL/src/ui/CombatSceneModel.gd',
    'app-LTL/src/tools/FormalReplayRunner.gd',
    'app-LTL/tests/godot_contract_runner.gd'
  )
```

## User Approval

- User request history:
  - contract comments first
  - execution comments later
- Current approval applies to the execution-only phase for the listed files.

## Advancement Rule

- current_phase_owner: execution-comments-complete
- next_phase: implementation
- required_user_request: explicit implementation request
