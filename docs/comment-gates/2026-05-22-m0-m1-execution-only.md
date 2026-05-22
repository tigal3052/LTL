# Comment Gate Ledger

date: 2026-05-22
task: m0-m1-execution-only-redesign
phase: execution-only
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

- M0 formal path decisions remain fixed: `domain/`, `process/`, `ui/`, `tools/`, `tests/` are the promoted Godot-side scaffold for the browser prototype handoff.
- M1 boundaries remain unchanged: data validation, headless phase progression, replay orchestration, and UI-safe read models are separate responsibilities.
- This pass preserves all contract comments and adds execution-order comments only.

## Execution Scope

- `README.md`: documents the cross-folder execution order for future implementation blocks.
- `FormalContracts.gd`: raw input routing, contract-family normalization, diagnostics accumulation, and verdict/snapshot return order.
- `HeadlessMiniRun.gd`: root initialization, phase transition guards, branch handling, and public snapshot refresh order.
- `ReplayProcess.gd`: fixture normalization, replay step iteration, adapter/runtime handoff, trace collection, and final verdict comparison order.
- `CombatInputAdapter.gd`: action extraction, intent normalization, guard validation, and normalized combat event return order.
- `RunProgressionM0DesignNote.md`: promotion/removal/defer mapping for the execution-only implementation surface.
- `SceneReadModel.gd`: root snapshot validation, phase-specific read-model branching, and copy-safe output assembly order.
- `CombatSceneModel.gd`: combat-only read-model block assembly and mismatch feedback surface order.
- `FormalReplayRunner.gd`: fixture discovery, replay batch execution, aggregate summary accumulation, and report shaping order.
- `godot_contract_runner.gd`: validator/replay/snapshot/read-model test group execution and deterministic suite summary order.

## Advancement Rule

- next_phase: implementation-approved
- required_user_request: explicit
- implementation_rule: code may be added only after a separate implementation approval request.
