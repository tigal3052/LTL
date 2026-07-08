# Comment Gate Ledger

date: 2026-05-22
task: m0-m1-implementation-approved
phase: implementation-approved
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

- M0/M1 formal path implementation now follows the strict comment-first implementation rule.
- Each executable source block is directly guarded by one non-empty `실행:` sentence.
- Documentation-only files remain outside the implementation-approved target list.

## Execution Scope

- `FormalContracts.gd`: validators, tuning merge, snapshot validation, clone/coerce helpers.
- `HeadlessMiniRun.gd`: root initialization, snapshots, phase transitions, combat resolution, rewards, and helper state creation.
- `ReplayProcess.gd`: payload/file replay, event dispatch, summary projection, and prototype-style fixture adaptation.
- `CombatInputAdapter.gd`: raw input normalization and convenience run adapters.
- `SceneReadModel.gd`: public snapshot validation and scene-safe projection.
- `CombatSceneModel.gd`: combat-only layout, terrain, HUD, target, and feedback projection.
- `FormalReplayRunner.gd`: fixture discovery and aggregate replay verdicts.
- `godot_contract_runner.gd`: headless contract suite entrypoint.

## Advancement Rule

- next_phase: runtime-verification
- required_user_request: explicit
