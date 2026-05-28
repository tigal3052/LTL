# M4 Node Routing Design

## Request

Implement M4 by referencing `LTL-harness`, including an initial design, a critique of that design, a revised implementation plan, and the implementation itself.

## Initial Design

M4 should promote the prototype node-routing contract into the formal Godot path without moving runtime code back into `prototype/**`. The smallest stable shape is:

- `NodeVocab.gd` remains the deterministic node offer SoT.
- `NodeSelectPhase.gd` remains the only phase reducer that converts a selected candidate into combat state.
- A formal node table under `app-LTL/src/data/node-table.json` carries node type, risk, weakness, reward, hazard, and boss metadata.
- A small `ApplyNodeModifiers.gd` vocabulary capsule translates selected node metadata into combat-safe modifiers.
- Read models expose player-facing node type/risk/reward/hint fields, but hide generator internals.

## Critique

The first design is intentionally conservative, but it has weak spots:

- Only adding fields to candidate dictionaries could make routing look implemented while combat still ignores modifiers.
- Final-stage boss placement can conflict with the existing normal-node guarantee if the implementation replaces normal with boss.
- A node-map scene is listed in the harness plan, but adding a full scene now would broaden the blast radius and risk mixing UI polish with formal routing contracts.
- Telemetry events are required by M4, but the current codebase does not yet have a shared telemetry sink in the formal path.
- Existing M3 reward changes are already dirty in the worktree, so M4 edits must avoid rewriting reward internals.

## Revised Design

The revised design keeps M4 formal and testable:

- Candidate generation guarantees a normal/safe node on every stage and additionally pins a boss candidate on the final stage.
- Node metadata is normalized at generation time: `nodeType`, `riskTier`, `rewardBias`, `recommendedBuildHint`, `difficultyModifier`, `rewardModifier`, `hazardModifier`, `finalStageDistance`, and `routeHash`.
- `ApplyNodeModifiers.apply(choice, tuning)` creates combat fields from node metadata and stores explicit `node`, `hazard`, and `rewardModifier` snapshots on combat state.
- `NodeSelectPhase.reduce` calls the modifier capsule before constructing `CombatSimulator`, then preserves route metadata on the combat dictionary.
- `SceneReadModel` and `NodeSelectReadModel` expose node-map-like readable fields without adding a new scene yet.
- M4 telemetry is represented as deterministic payload dictionaries on candidate offer and selected-node snapshots; a later shared telemetry sink can consume the same shape.

## Implementation Plan

1. Add `test_node_routing_contract.gd` and wire it into `godot_contract_runner.gd`.
2. Verify the new tests fail before production changes.
3. Add the formal node table and node modifier vocabulary capsule.
4. Extend `NodeVocab`, `NodeSelectPhase`, `HeadlessMiniRun`, and read models.
5. Re-run the focused Godot contract suite and compile wrapper.

## Verification

- Focused red/green check: Godot headless contract runner.
- Full local compile check: `powershell -NoProfile -ExecutionPolicy Bypass -File tools/run-compile-check.ps1`.
- Diff sanity: `git diff --check`.
