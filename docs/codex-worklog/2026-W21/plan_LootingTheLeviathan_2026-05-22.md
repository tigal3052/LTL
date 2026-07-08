# Codex Worklog Plan

Workspace: LootingTheLeviathan
Date: 2026-05-22

## Active Work

- Replace the temporary JSON-debug main screen with an actual M2 combat preview surface on top of the formal Godot runtime.

## Request Summary

- The user asked to execute M2 implementation.
- This pass should complete the missing combat-scene preview/main entry path on the formal Godot runtime instead of reviving prototype runtime code.
- The implementation must stay inside `app-LTL/src/**`, `app-LTL/tests/**`, and worklog/comment-gate documents unless verification reveals a scoped gap.
- Follow-up issue: running the main scene currently prints raw scene JSON instead of rendering an actual combat preview UI.

## Scope

- Extend `app-LTL/tests/godot_contract_runner.gd` to freeze the formal M2 preview/main expectations.
- Implement `src/ui/CombatScenePreviewController.gd`, `src/MainController.gd`, and `src/Main.tscn`.
- Adjust `SceneReadModel.gd` and `CombatSceneModel.gd` only where the new M2 contract requires additional scene-facing data or stricter projection behavior.
- Preserve replay and headless behavior without editing `prototype/**`.
- Replace the text-dump main scene with concrete UI nodes and controller rendering logic for combat-preview state, action buttons, and phase-aware panels.

## Out of Scope

- Restoring browser runtime code or moving logic back under `prototype/**`
- Reworking combat rules beyond the public input/read-model boundary required by M2
- Editing quarantine sources except as read-only references
- Broad harness redesign unrelated to this M2 implementation slice
- Shipping full production art, animation, or non-preview flow polish

## Steps

- Review the active M2 plan, current formal GDScript modules, and quarantine preview/controller references.
- Update the Godot contract runner so M2 requires the preview controller and main scene path.
- Implement the missing preview/main files and any minimal supporting model changes under `src/**`.
- Re-run Godot headless verification plus prototype-diff checks.
- Record the baseline crash/failure state and post-fix verification results in today’s worklog files.
- Add a regression test that fails while the main scene is still a raw JSON text dump.
- Replace the debug-only `RichTextLabel` surface with an actual preview layout and state renderer.

## Expected Outputs

- Formal M2 preview/main files under `app-LTL/src/**`
- Expanded M2 contract coverage in `app-LTL/tests/godot_contract_runner.gd`
- Updated 2026-05-22 worklog files with baseline and verification notes
- A main scene that renders preview panels instead of dumping serialized JSON

## Verification Method

- Run the Godot headless contract suite from `app-LTL/tests/godot_contract_runner.gd`.
- Run `git diff --check` to catch patch hygiene issues.
- Run `git diff -- app-LTL/prototype/browser-p0-p4` to prove the prototype path stayed untouched.
- Record any remaining Godot runtime crash/blocker if the headless suite still cannot complete.
- Run a textual main-scene regression test that verifies the JSON-dump implementation is gone and the expected preview nodes exist.

## Plan Change Log

- 2026-05-22: Worklog bootstrapped automatically by Codex hook.
- 2026-05-22: User requested a fresh M0/M1 formal scaffold under the corrected harness and clarified that the first pass must stop at the contract-only design-comment stage.
- 2026-05-22: User then requested the next execution-only pass for the same target set.
- 2026-05-22: User then requested implementation based on the approved design and execution comments.
- 2026-05-22: User reported a Godot parse error in `FormalContracts.gd`; follow-up scope is limited to compile-safety fixes while preserving strict comment/code gate compliance.
- 2026-05-22: User requested M2 implementation execution; scope moved from M0/M1 scaffold stabilization to formal combat-scene preview/main completion.
- 2026-05-22: User reported that the main screen still shows text output; follow-up scope is now the preview UI renderer rather than entry-path scaffolding alone.
