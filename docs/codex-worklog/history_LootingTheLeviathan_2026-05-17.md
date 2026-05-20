# Codex Worklog History

Workspace: LootingTheLeviathan
Date: 2026-05-17

## Prototype recovery and harness guard

- Intent: Correct the previous source-touching mistake, restore the missing browser prototype from git history, and prevent future direct edits to preserved prototype files.
- Files or areas touched:
  - `LTL-harness/00_AGENTS.md`
  - `app-LTL/prototype/browser-p0-p4/**`
  - root-level `app-LTL/prototype` Godot files removed
  - `docs/codex-worklog/*_LootingTheLeviathan_2026-05-17.md`
- Summary: Reverted the previous source comment edits to HEAD, restored `app-LTL/prototype/browser-p0-p4/**` from commit `2b4fdcd`, removed root Godot prototype files that are unrelated to the browser `index.html`, and added a rule that `app-LTL/prototype/**` is a preservation area that must not be directly edited for new implementation, refactoring, comment cleanup, or file moves.
- Verification: `npm.cmd test` passed 36 tests in `app-LTL/prototype/browser-p0-p4`; `git diff --check` passed; a file search found no `.gd` or `.tscn` files remaining under `app-LTL/prototype`.

## M1 comment-first source skeleton

- Intent: Replace the current formal `app-LTL/src` implementation with a clean comment-first skeleton that can guide immediate logic-based programming for M1 core domain stabilization.
- Files or areas touched:
  - `app-LTL/src/**`
  - `docs/codex-worklog/plan_LootingTheLeviathan_2026-05-17.md`
  - `docs/codex-worklog/history_LootingTheLeviathan_2026-05-17.md`
  - `docs/codex-worklog/complete_LootingTheLeviathan_2026-05-17.md`
- Summary: Removed the existing implementation bodies from the formal source path and rebuilt `src` as a module map for facts, rules, queries, loaders, validation, replay, telemetry, snapshots, run progression, and compatibility adapters. The preserved browser P0-P4 prototype was used only as a read-only reference, in line with the harness guard.
- Verification: `rg --files app-LTL/src` confirmed the new skeleton tree; `git diff --check -- app-LTL/src docs/codex-worklog/plan_LootingTheLeviathan_2026-05-17.md` passed; `node --check` passed for every new `.js` file under `app-LTL/src`.

## Harness rollback recovery

- Intent: Restore the comment-first and logic-based programming rules that were lost when harness files were rolled back through git.
- Files or areas touched:
  - `agent-harness/00_AGENTS.md`
  - `LTL-harness/00_AGENTS.md`
  - `docs/codex-worklog/*_LootingTheLeviathan_2026-05-17.md`
- Summary: Replaced the shared harness entrypoint with the supplied pre-rollback SoT, logic-based programming, comment, planning, Ready, and Done rules. Replaced the LTL harness entrypoint with a project-specific version that includes those same rules plus LTL domain guidance for prototype preservation, seed-driven reproducibility, and fact/rule/query decomposition.
- Verification: `git diff --check -- agent-harness/00_AGENTS.md LTL-harness/00_AGENTS.md docs/codex-worklog` passed; `Select-String` confirmed `Document Structure`, `Workflow Gates`, `Out Of Scope`, and quick-start sections are present.

## Harness document structure update

- Intent: Restore the missing `Document Structure` section and bring back the generic harness operational sections that were trimmed too aggressively.
- Files or areas touched:
  - `agent-harness/00_AGENTS.md`
  - `LTL-harness/00_AGENTS.md`
  - `docs/codex-worklog/*_LootingTheLeviathan_2026-05-17.md`
- Summary: Updated the generic harness to include quick start, document map, workflow gates, implementation gate, verification gate, release gate, out-of-scope list, and notes while preserving the SoT/comment/logic-first rules. Added an LTL-specific document map covering `LTL-harness/docs/**`, `app-LTL/src`, `app-LTL/tests`, and the preserved `app-LTL/prototype/browser-p0-p4` path.
- Verification: `git diff --check -- agent-harness/00_AGENTS.md LTL-harness/00_AGENTS.md docs/codex-worklog` passed; `Select-String` confirmed `Document Structure`, `Workflow Gates`, `Out Of Scope`, and quick-start sections are present.

## M1 logic-unit comment rewrite

- Intent: Rewrite the formal `app-LTL/src` skeleton comments so M1 implementation can proceed directly by logic-based programming without touching the preserved prototype.
- Files or areas touched:
  - `app-LTL/src/**`
  - `docs/codex-worklog/*_LootingTheLeviathan_2026-05-17.md`
- Summary: Replaced broad English skeleton comments with Korean logic-unit comments organized by one-sentence purpose, reference prototype path, facts, rules, queries, transitions, implementation order, and boundary constraints. Kept the source tree comment-only and updated `app-LTL/src/README.md` with the intended implementation sequence.
- Verification: `node --check` passed for all JavaScript files under `app-LTL/src`; `Select-String` found no top-level `export`, `import`, `function`, `const`, `let`, `var`, or `class` declarations; `git diff --check -- app-LTL/src docs/codex-worklog` passed.

## Action result TDD implementation

- Intent: Implement only `app-LTL/src/action-result.js` from its logic-unit comments while keeping the rest of the M1 skeleton untouched.
- Files or areas touched:
  - `app-LTL/src/action-result.js`
  - `app-LTL/tests/action_result.test.js`
  - `docs/codex-worklog/*_LootingTheLeviathan_2026-05-17.md`
- Summary: Added focused Node test coverage for invalid-target priority, empty-queue feedback, hit labels, no-op behavior, counter diffs, target reference resolution, and mutation safety. Implemented pure action-result helpers plus a compatibility path for the earlier summary-diff call shape.
- Verification: First focused test run failed because `deriveActionResult` was not exported; after implementation, `node --test tests/action_result.test.js` passed 6/6. `node --check src/action-result.js` passed. `git diff --check -- app-LTL/src/action-result.js app-LTL/tests/action_result.test.js docs/codex-worklog` passed. Full `npm.cmd test` ran 45 tests with 42 passing and 3 failing because other skeleton files still lack exports: `Telemetry`, `EnergyQueue`, and `CombatController`.

## Executable comment rule tightening

- Intent: Fix the harness rule gap that allowed broad design comments to drift away from the actual implementation.
- Files or areas touched:
  - `LTL-harness/00_AGENTS.md`
  - `docs/codex-worklog/*_LootingTheLeviathan_2026-05-17.md`
- Summary: Strengthened logic-based programming and comment rules so function-body comments must be executable sentences that map one-to-one to the immediately following code line or block. Added contract header comments as a separate category that cannot replace implementation comments, banned vague non-translatable comment verbs, added good/bad examples, and updated Ready/Done to require executable comment/code correspondence.
- Verification: `Select-String` confirmed the new executable sentence, direct implementation comment, contract header comment, Ready, and Done language is present. `git diff --check -- LTL-harness/00_AGENTS.md docs/codex-worklog` passed.

## Three-step comment workflow and action-result revert

- Intent: Adjust the harness so design comments are a required first step but cannot be mistaken for implementation-ready comments, then revert the previous `action-result.js` implementation experiment.
- Files or areas touched:
  - `LTL-harness/00_AGENTS.md`
  - `app-LTL/src/action-result.js`
  - `app-LTL/tests/action_result.test.js`
  - `docs/codex-worklog/*_LootingTheLeviathan_2026-05-17.md`
- Summary: Changed the harness flow to `1. 설계기반 주석 작성 -> 2. 실행 문장 주석 작성 -> 3. 주석기반 프로그래밍 구현`. Clarified that design comments are allowed in headers/contracts but must be translated into executable sentence comments before implementation. Reverted `action-result.js` to the design-comment-only skeleton and removed the focused test file created for the reverted implementation pass.
- Verification: `node --check src/action-result.js` passed from `app-LTL`; `git diff --check -- LTL-harness/00_AGENTS.md app-LTL/src/action-result.js app-LTL/tests/action_result.test.js docs/codex-worklog` passed; `Select-String` confirmed the three-step workflow wording; `Test-Path app-LTL/tests/action_result.test.js` returned `False`.

## 2026-05-17 21:43:32

<!-- codex-worklog-signature: 0e7f8baa4bb864239141e79aaf61dd8c7400c2b81ac450b8ff95b1aefcc1c3a9 -->

- Intent: Workspace files changed through Codex tooling.
- Tool: apply_patch
- Files or areas touched:
``text
 M LTL-harness/00_AGENTS.md
D  app-LTL/prototype/PrototypeController.gd
D  app-LTL/prototype/PrototypeMain.tscn
A  app-LTL/prototype/browser-p0-p4/package.json
A  app-LTL/prototype/browser-p0-p4/public/index.html
A  app-LTL/prototype/browser-p0-p4/src/action-result.js
A  app-LTL/prototype/browser-p0-p4/src/combat-controller.js
A  app-LTL/prototype/browser-p0-p4/src/data/artifact-table.json
A  app-LTL/prototype/browser-p0-p4/src/data/node-table.json
A  app-LTL/prototype/browser-p0-p4/src/domain/energy-queue.js
A  app-LTL/prototype/browser-p0-p4/src/domain/game-tuning.js
A  app-LTL/prototype/browser-p0-p4/src/domain/hazard-model.js
A  app-LTL/prototype/browser-p0-p4/src/domain/inventory-model.js
A  app-LTL/prototype/browser-p0-p4/src/domain/mining-resolver.js
A  app-LTL/prototype/browser-p0-p4/src/domain/node-generator.js
A  app-LTL/prototype/browser-p0-p4/src/domain/reward-resolver.js
A  app-LTL/prototype/browser-p0-p4/src/domain/run-progression.js
A  app-LTL/prototype/browser-p0-p4/src/domain/run-simulator.js
A  app-LTL/prototype/browser-p0-p4/src/domain/seeded-rng.js
A  app-LTL/prototype/browser-p0-p4/src/domain/stage-scaling.js
A  app-LTL/prototype/browser-p0-p4/src/models/artifact-table.js
A  app-LTL/prototype/browser-p0-p4/src/models/combat-simulator.js
A  app-LTL/prototype/browser-p0-p4/src/models/inventory.js
A  app-LTL/prototype/browser-p0-p4/src/phases/combat-end-phase.js
A  app-LTL/prototype/browser-p0-p4/src/phases/combat-phase.js
A  app-LTL/prototype/browser-p0-p4/src/phases/combat-start-phase.js
A  app-LTL/prototype/browser-p0-p4/src/phases/node-select-phase.js
A  app-LTL/prototype/browser-p0-p4/src/phases/phase-tags.js
A  app-LTL/prototype/browser-p0-p4/src/phases/reduce-mini-run-phase.js
A  app-LTL/prototype/browser-p0-p4/src/phases/reward-loot-phase.js
``
- Summary: Review the plan and current diff for semantic details; keep this entry compressed if later updates touch the same area.
- Verification: Not recorded by hook. Update this after running checks.

## 2026-05-17 21:51:30

<!-- codex-worklog-signature: ac05a6cb8c74e66ebfa21f9f848221442a27ef4a3872455954360931f3bf93f9 -->

- Intent: Workspace files changed through Codex tooling.
- Tool: Bash
- Files or areas touched:
``text
 M LTL-harness/00_AGENTS.md
 D app-LTL/prototype/PrototypeController.gd
 D app-LTL/prototype/PrototypeMain.tscn
 D app-LTL/prototype/data/PrototypeTuning.json
 D app-LTL/prototype/domain/EnergyQueue.gd
 D app-LTL/prototype/domain/MiningResolver.gd
 D app-LTL/prototype/domain/RunSimulator.gd
 D app-LTL/prototype/domain/SeededRng.gd
 D app-LTL/prototype/telemetry/Telemetry.gd
 D app-LTL/prototype/tools/replay_runner.gd
?? app-LTL/prototype/browser-p0-p4/
?? docs/codex-worklog/complete_LootingTheLeviathan_2026-05-17.md
?? docs/codex-worklog/history_LootingTheLeviathan_2026-05-17.md
?? docs/codex-worklog/plan_LootingTheLeviathan_2026-05-17.md
``
- Summary: Review the plan and current diff for semantic details; keep this entry compressed if later updates touch the same area.
- Verification: Not recorded by hook. Update this after running checks.

## 2026-05-17 21:53:06

<!-- codex-worklog-signature: b73a5bfe40c9e51ca74ecb2bd3abe617c5893975090c64aab381a8556e000d6d -->

- Intent: Workspace files changed through Codex tooling.
- Tool: apply_patch
- Files or areas touched:
``text
 M LTL-harness/00_AGENTS.md
 D app-LTL/prototype/PrototypeController.gd
 D app-LTL/prototype/PrototypeMain.tscn
 D app-LTL/prototype/data/PrototypeTuning.json
 D app-LTL/prototype/domain/EnergyQueue.gd
 D app-LTL/prototype/domain/MiningResolver.gd
 D app-LTL/prototype/domain/RunSimulator.gd
 D app-LTL/prototype/domain/SeededRng.gd
 D app-LTL/prototype/telemetry/Telemetry.gd
 D app-LTL/prototype/tools/replay_runner.gd
?? app-LTL/prototype/browser-p0-p4/
?? docs/codex-worklog/complete_LootingTheLeviathan_2026-05-17.md
?? docs/codex-worklog/history_LootingTheLeviathan_2026-05-17.md
?? docs/codex-worklog/plan_LootingTheLeviathan_2026-05-17.md
``
- Summary: Review the plan and current diff for semantic details; keep this entry compressed if later updates touch the same area.
- Verification: Not recorded by hook. Update this after running checks.

## 2026-05-17 21:55:12

<!-- codex-worklog-signature: 2e228a5f7993d35a7f95546264c80cc192e3285bd5fcd4ea9fd4dce4301f29ab -->

- Intent: Workspace files changed through Codex tooling.
- Tool: apply_patch
- Files or areas touched:
``text
 M LTL-harness/00_AGENTS.md
 D app-LTL/prototype/PrototypeController.gd
 D app-LTL/prototype/PrototypeMain.tscn
 D app-LTL/prototype/data/PrototypeTuning.json
 D app-LTL/prototype/domain/EnergyQueue.gd
 D app-LTL/prototype/domain/MiningResolver.gd
 D app-LTL/prototype/domain/RunSimulator.gd
 D app-LTL/prototype/domain/SeededRng.gd
 D app-LTL/prototype/telemetry/Telemetry.gd
 D app-LTL/prototype/tools/replay_runner.gd
 M app-LTL/src/action-result.js
 M app-LTL/src/combat-controller.js
 M app-LTL/src/domain/energy-queue.js
 M app-LTL/src/domain/mining-resolver.js
 M app-LTL/src/domain/run-simulator.js
 M app-LTL/src/domain/seeded-rng.js
 M app-LTL/src/telemetry/telemetry.js
 M app-LTL/src/tools/replay-runner.js
?? app-LTL/prototype/browser-p0-p4/
?? app-LTL/src/README.md
?? app-LTL/src/data/
?? app-LTL/src/domain/combat-resolution.js
?? app-LTL/src/domain/facts.js
?? app-LTL/src/domain/game-tuning.js
?? app-LTL/src/domain/inventory-model.js
?? app-LTL/src/domain/node-generator.js
?? app-LTL/src/domain/reward-resolver.js
?? app-LTL/src/domain/rules.js
?? app-LTL/src/domain/run-progression.js
?? app-LTL/src/domain/snapshot.js
``
- Summary: Review the plan and current diff for semantic details; keep this entry compressed if later updates touch the same area.
- Verification: Not recorded by hook. Update this after running checks.

## 2026-05-17 23:05:49

<!-- codex-worklog-signature: 53e542c2390ff99f41fa8462bd6eb2925b71976094313f0f671e0452ae8d7329 -->

- Intent: Workspace files changed through Codex tooling.
- Tool: unknown
- Files or areas touched:
``text
 M LTL-harness/00_AGENTS.md
 D app-LTL/prototype/PrototypeController.gd
 D app-LTL/prototype/PrototypeMain.tscn
 D app-LTL/prototype/data/PrototypeTuning.json
 D app-LTL/prototype/domain/EnergyQueue.gd
 D app-LTL/prototype/domain/MiningResolver.gd
 D app-LTL/prototype/domain/RunSimulator.gd
 D app-LTL/prototype/domain/SeededRng.gd
 D app-LTL/prototype/telemetry/Telemetry.gd
 D app-LTL/prototype/tools/replay_runner.gd
 M app-LTL/src/action-result.js
 M app-LTL/src/combat-controller.js
 M app-LTL/src/domain/energy-queue.js
 M app-LTL/src/domain/mining-resolver.js
 M app-LTL/src/domain/run-simulator.js
 M app-LTL/src/domain/seeded-rng.js
 M app-LTL/src/telemetry/telemetry.js
 M app-LTL/src/tools/replay-runner.js
?? app-LTL/prototype/browser-p0-p4/
?? app-LTL/src/README.md
?? app-LTL/src/data/
?? app-LTL/src/domain/combat-resolution.js
?? app-LTL/src/domain/facts.js
?? app-LTL/src/domain/game-tuning.js
?? app-LTL/src/domain/inventory-model.js
?? app-LTL/src/domain/node-generator.js
?? app-LTL/src/domain/reward-resolver.js
?? app-LTL/src/domain/rules.js
?? app-LTL/src/domain/run-progression.js
?? app-LTL/src/domain/snapshot.js
``
- Summary: Review the plan and current diff for semantic details; keep this entry compressed if later updates touch the same area.
- Verification: Not recorded by hook. Update this after running checks.

## 2026-05-17 23:07:01

<!-- codex-worklog-signature: 740e816dac03407619359d707bdcee6f121e8f5ec07ebdfbb92ecdaf22d10a68 -->

- Intent: Workspace files changed through Codex tooling.
- Tool: apply_patch
- Files or areas touched:
``text
 M LTL-harness/00_AGENTS.md
 M agent-harness/00_AGENTS.md
 D app-LTL/prototype/PrototypeController.gd
 D app-LTL/prototype/PrototypeMain.tscn
 D app-LTL/prototype/data/PrototypeTuning.json
 D app-LTL/prototype/domain/EnergyQueue.gd
 D app-LTL/prototype/domain/MiningResolver.gd
 D app-LTL/prototype/domain/RunSimulator.gd
 D app-LTL/prototype/domain/SeededRng.gd
 D app-LTL/prototype/telemetry/Telemetry.gd
 D app-LTL/prototype/tools/replay_runner.gd
 M app-LTL/src/action-result.js
 M app-LTL/src/combat-controller.js
 M app-LTL/src/domain/energy-queue.js
 M app-LTL/src/domain/mining-resolver.js
 M app-LTL/src/domain/run-simulator.js
 M app-LTL/src/domain/seeded-rng.js
 M app-LTL/src/telemetry/telemetry.js
 M app-LTL/src/tools/replay-runner.js
?? app-LTL/prototype/browser-p0-p4/
?? app-LTL/src/README.md
?? app-LTL/src/data/
?? app-LTL/src/domain/combat-resolution.js
?? app-LTL/src/domain/facts.js
?? app-LTL/src/domain/game-tuning.js
?? app-LTL/src/domain/inventory-model.js
?? app-LTL/src/domain/node-generator.js
?? app-LTL/src/domain/reward-resolver.js
?? app-LTL/src/domain/rules.js
?? app-LTL/src/domain/run-progression.js
``
- Summary: Review the plan and current diff for semantic details; keep this entry compressed if later updates touch the same area.
- Verification: Not recorded by hook. Update this after running checks.

## 2026-05-17 23:07:47

<!-- codex-worklog-signature: b9dfe3722442a0a6f99788dd483f0ea45fb63e9c224ee079e5c9308fd0309932 -->

- Intent: Workspace files changed through Codex tooling.
- Tool: Bash
- Files or areas touched:
``text
 M LTL-harness/00_AGENTS.md
 M agent-harness/00_AGENTS.md
 D app-LTL/prototype/PrototypeController.gd
 D app-LTL/prototype/PrototypeMain.tscn
 D app-LTL/prototype/data/PrototypeTuning.json
 D app-LTL/prototype/domain/EnergyQueue.gd
 D app-LTL/prototype/domain/MiningResolver.gd
 D app-LTL/prototype/domain/RunSimulator.gd
 D app-LTL/prototype/domain/SeededRng.gd
 D app-LTL/prototype/telemetry/Telemetry.gd
 D app-LTL/prototype/tools/replay_runner.gd
 M app-LTL/src/action-result.js
 M app-LTL/src/combat-controller.js
 M app-LTL/src/domain/energy-queue.js
 M app-LTL/src/domain/mining-resolver.js
 M app-LTL/src/domain/run-simulator.js
 M app-LTL/src/domain/seeded-rng.js
 M app-LTL/src/telemetry/telemetry.js
 M app-LTL/src/tools/replay-runner.js
?? app-LTL/prototype/browser-p0-p4/
?? app-LTL/src/README.md
?? app-LTL/src/data/
?? app-LTL/src/domain/combat-resolution.js
?? app-LTL/src/domain/facts.js
?? app-LTL/src/domain/game-tuning.js
?? app-LTL/src/domain/inventory-model.js
?? app-LTL/src/domain/node-generator.js
?? app-LTL/src/domain/reward-resolver.js
?? app-LTL/src/domain/rules.js
?? app-LTL/src/domain/run-progression.js
``
- Summary: Review the plan and current diff for semantic details; keep this entry compressed if later updates touch the same area.
- Verification: Not recorded by hook. Update this after running checks.

## 2026-05-17 23:40:41

<!-- codex-worklog-signature: b494c80dd0fe47c12a22506d9a64ce50cad603a0be3fcd3324e4862e94595467 -->

- Intent: Workspace files changed through Codex tooling.
- Tool: unknown
- Files or areas touched:
``text
 M LTL-harness/00_AGENTS.md
 M agent-harness/00_AGENTS.md
 D app-LTL/prototype/PrototypeController.gd
 D app-LTL/prototype/PrototypeMain.tscn
 D app-LTL/prototype/data/PrototypeTuning.json
 D app-LTL/prototype/domain/EnergyQueue.gd
 D app-LTL/prototype/domain/MiningResolver.gd
 D app-LTL/prototype/domain/RunSimulator.gd
 D app-LTL/prototype/domain/SeededRng.gd
 D app-LTL/prototype/telemetry/Telemetry.gd
 D app-LTL/prototype/tools/replay_runner.gd
 M app-LTL/src/action-result.js
 M app-LTL/src/combat-controller.js
 M app-LTL/src/domain/energy-queue.js
 M app-LTL/src/domain/mining-resolver.js
 M app-LTL/src/domain/run-simulator.js
 M app-LTL/src/domain/seeded-rng.js
 M app-LTL/src/telemetry/telemetry.js
 M app-LTL/src/tools/replay-runner.js
?? app-LTL/prototype/browser-p0-p4/
?? app-LTL/src/README.md
?? app-LTL/src/data/
?? app-LTL/src/domain/combat-resolution.js
?? app-LTL/src/domain/facts.js
?? app-LTL/src/domain/game-tuning.js
?? app-LTL/src/domain/inventory-model.js
?? app-LTL/src/domain/node-generator.js
?? app-LTL/src/domain/reward-resolver.js
?? app-LTL/src/domain/rules.js
?? app-LTL/src/domain/run-progression.js
``
- Summary: Review the plan and current diff for semantic details; keep this entry compressed if later updates touch the same area.
- Verification: Not recorded by hook. Update this after running checks.
