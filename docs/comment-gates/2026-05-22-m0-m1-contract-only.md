# Comment Gate Ledger

date: 2026-05-22
task: m0-m1-contract-only-redesign
phase: contract-only
approval: approved
targets:
  - app-LTL/src/README.md
  - app-LTL/src/domain/FormalContracts.gd
  - app-LTL/src/process/HeadlessMiniRun.gd
  - app-LTL/src/process/ReplayProcess.gd
  - app-LTL/src/process/CombatInputAdapter.gd
  - app-LTL/src/process/RunProgressionM0DesignNote.md
  - app-LTL/src/ui/SceneReadModel.gd
  - app-LTL/src/ui/CombatSceneModel.gd
  - app-LTL/src/tools/FormalReplayRunner.gd
  - app-LTL/tests/godot_contract_runner.gd

## Contract Summary

- M0 fixes the formal file layout, responsibility split, and promotion surface from the browser prototype.
- M1 defines the formal contract boundaries for validators, replay orchestration, root/phase snapshots, and UI-safe read models.
- This pass is limited to design comments only and intentionally stops before execution comments.

## Execution Scope

- Not yet approved.
- Future execution comments must be requested explicitly in a later ledger phase.

## Advancement Rule

- next_phase: execution-only
- required_user_request: explicit
