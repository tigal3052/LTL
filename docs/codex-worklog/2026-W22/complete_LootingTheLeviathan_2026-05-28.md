# Codex Worklog Completion

Workspace: LootingTheLeviathan
Date: 2026-05-28

## Completion Summary

Reviewed M2 implementation state before M3, completed the pre-refactor logical capsule work, added a focused M3 reward/progression contract-gap pass, applied the latest reward-pool balance update, and then implemented M4 node routing against `LTL-harness`. The M4 update promotes deterministic node offers, final-stage boss routing, selected-node modifiers, and route read-model evidence into the formal Godot path.

## Actual Outputs

- `docs/superpowers/plans/2026-05-28-m3-pre-refactor-logical-capsules.md`
- Stabilized Godot contract wrapper and strict architecture gate behavior.
- Added thin `MainController.gd` and `MainUI.gd` facades with runtime backing scripts.
- Added backpack, reward, progression, and combat vocabulary scripts with contract tests.
- Added `BackpackOrganizePhase.gd` and stage sentence routing.
- Added `NodeSelectReadModel.gd`, `TooltipReadModel.gd`, `PhaseLayoutPresenter.gd`, and reward tray projection coverage.
- Added `CombatFeedbackPresenter.gd` for screenshake decisions.
- Added `ShopPanelUI.gd` and `ArtifactTooltipUI.gd` for dynamic UI panel ownership.
- Added `GiantTimerUI.gd` and `HeartbeatSynth.gd` for timer/vignette/heartbeat ownership.
- Removed remaining architecture view warnings by shrinking `StatusPanelUI.gd`, `BackpackUI.gd`, and `BattlefieldUI.gd`.
- Added `BackpackGridFactory.gd` and `BattlefieldVFX.gd` to hold rendering helpers and battlefield VFX.
- Removed unreachable legacy runtime blocks that duplicated extracted reward, node-select, shop, timer, heartbeat, and tooltip responsibilities.
- Fixed weakness marker shifts so repeated timer ticks use a changing deterministic step instead of the same seeded color order.
- Fixed reward rolling so stage rewards produce 2-5 choices instead of allowing a 1-item tray.
- Fixed visible Korean mojibake in runtime logs and calibration shop labels.
- Added viewport-clamped artifact tooltip positioning so reward hover panels stay on-screen near the bottom edge.
- Rebalanced reward item-type weighting so beacon rewards are favored at roughly a 40:60 drill/beacon ratio.
- Fixed backpack artifact border rendering so only the artifact perimeter draws a black outline; internal occupied faces no longer draw black grid borders.
- Wired runtime calls through reward/growth/combat/read-model capsules where the change could be verified safely.
- Added `docs/superpowers/plans/2026-05-28-m3-reward-progression-contract-gap-plan.md` with the first plan, critique, and revised plan.
- Added `BuildRewardPreview.gd` and `BuildRewardTelemetry.gd`.
- Added stable private `offer_weights_hash` and public `next_combat_modifier_preview` to deterministic reward rolls.
- Extended `RewardValidator` with cross-table rarity and positive-weight validation.
- Extended `RewardReadModel` so it exposes player-facing next-combat preview while hiding raw reward weight and offer hash.
- Added M3 contract tests for validator strictness, offer metadata, read-model privacy, and telemetry payload construction.
- Added reward-pool tests that require common, rare, epic, and legendary tiers to include both drill-like and beacon candidates.
- Removed cross-rarity beacon injection from reward roll candidate selection.
- Added common 3x2 anchor beacons and legendary 2x1 focusing beacons to the reward table.
- Added explicit rare/epic beacon shapes and lowered rare cooldown beacons from -20 ticks to -4 ticks.
- Added `docs/superpowers/specs/2026-05-28-m4-node-routing-design.md` and `docs/superpowers/plans/2026-05-28-m4-node-routing-plan.md`.
- Added formal M4 node table data at `app-LTL/src/data/node-table.json`.
- Added `ApplyNodeModifiers.gd` to translate selected node metadata into combat/reward/hazard snapshots.
- Extended `NodeVocab.gd` with deterministic route metadata, candidate count tuning, normal-node guarantee, and final-stage boss pinning.
- Extended `NodeSelectPhase.gd`, `CombatPhase.gd`, and `HeadlessMiniRun.gd` so selected node type, difficulty, reward, hazard, route hash, and source-node reward metadata flow through formal runtime state.
- Extended scene/node-select read models with risk, reward bias, build hint, final-stage distance, and route hash while hiding raw pick weights.
- Added `test_node_routing_contract.gd` and wired it into the Godot contract runner.
- Added `NodeInputAdapter.gd`, `NodeMapReadModel.gd`, and a minimal `NodeMapScene` formal path.
- Added `test_node_map_scene_smoke.gd` to verify node-map scene rendering consumes supplied read-model data and the scene does not call the route generator.
- Added `TextCatalog.gd` with Korean default, English switching, and display-name localization for common reward/drill/node names.
- Added a settings language selector and re-render path for Korean/English toggling.
- Localized main static scene text, phase/stage presenters, node/reward read models, reward discard text, tooltip labels, and status overlays.
- Added reward hover comparison for drill rewards against the currently equipped same-color drill only.
- Added backpack artifact cooldown visualization using a grey base artifact and bottom-up vivid charge overlay.
- Changed beacon behavior from permanent adjacent stat mutation to beacon-owned cooldown pulses that reduce adjacent drill current cooldown when charged.
- Extended reward reveal timing, strengthened volcano/light particles, and added repeated-click skip to the silhouette-count stage.
- Added `LTL-harness/tools/i18n-text-gate.ps1` and `LTL-harness/docs/i18n-text-enforcement.md`.
- Added generic `D:\Programming\ex_workspace\agent-harness\tools\i18n-text-gate.ps1` and `docs/i18n-text-enforcement.md` guidance.
- Updated dated worklog plan and completion notes.

## Changes From Plan

- The refactoring plan document was translated from English into Korean without changing its implementation sequence.
- Presenter/panel extraction was extended through layout/read-model/combat-feedback projection, dynamic panels, battlefield VFX, and backpack grid rendering helpers.
- Verification exposed an additional blocker in the compile wrapper/direct Godot headless path.
- The latest M3 contract-gap pass intentionally avoided reward scene polish and screenshot work so the formal runtime contract could be strengthened without broad UI churn.
- The reward-pool balance update used table expansion rather than changing the rarity-first roll architecture.
- M4 intentionally ships route/read-model contracts and selected modifier wiring without building a polished node-map scene, because the harness keeps final art polish and full world-map branching out of scope.

## Verification Results

- Latest M4 QA follow-up rerun of `powershell -NoProfile -ExecutionPolicy Bypass -File tools/run-compile-check.ps1`: passed with `GODOT_CONTRACTS_OK`; Godot still prints RID/ObjectDB leak warnings at process exit.
- Latest M4 QA follow-up rerun of `powershell -NoProfile -ExecutionPolicy Bypass -File LTL-harness/tools/i18n-text-gate.ps1`: returns `I18N_TEXT_GATE_OK`.
- Latest M4 QA follow-up rerun of `powershell -NoProfile -ExecutionPolicy Bypass -File LTL-harness/tools/milestone-gate.ps1 -TargetPlan 10_M4_node_routing.md`: returns `MILESTONE_GATE_OK`.
- Latest M4 QA follow-up rerun of `git diff --check`: no whitespace errors; LF-to-CRLF warnings only.
- `powershell -NoProfile -ExecutionPolicy Bypass -File tools/run-compile-check.ps1`: passes and prints `GODOT_CONTRACTS_OK`. Godot still prints RID/ObjectDB leak warnings at process exit.
- Latest reward-pool rerun of `powershell -NoProfile -ExecutionPolicy Bypass -File tools/run-compile-check.ps1`: passed with `GODOT_CONTRACTS_OK`; Godot still prints RID/ObjectDB leak warnings at process exit.
- `powershell -NoProfile -ExecutionPolicy Bypass -File LTL-harness/tools/architectural-gate.ps1 -ManifestPath docs/architectural-gates/m2-refactoring-gate.md`: returns `ARCHITECTURAL_GATE_OK` with no warnings.
- `powershell -NoProfile -ExecutionPolicy Bypass -File LTL-harness/tools/milestone-gate.ps1 -TargetPlan 09_M3_reward_and_progression.md`: returns `MILESTONE_GATE_OK`.
- `git diff --check`: no whitespace errors; only LF-to-CRLF warnings.
- Latest M4 rerun of `powershell -NoProfile -ExecutionPolicy Bypass -File tools/run-compile-check.ps1`: passed with `GODOT_CONTRACTS_OK`.
- Direct M4 smoke runner using `--headless --editor ... tests/godot_contract_runner.gd -- --smoke-only`: passed with `GODOT_CONTRACTS_OK`.
- Added `LTL-harness/docs/11_exec-plans/02_completed/09_M3_reward_and_progression_completed.md`.
- Latest `powershell -NoProfile -ExecutionPolicy Bypass -File LTL-harness/tools/milestone-gate.ps1 -TargetPlan 09_M3_reward_and_progression.md`: returns `MILESTONE_GATE_OK`.
- Latest `powershell -NoProfile -ExecutionPolicy Bypass -File LTL-harness/tools/milestone-gate.ps1 -TargetPlan 10_M4_node_routing.md`: returns `MILESTONE_GATE_OK`.
- Latest node-map continuation rerun of `powershell -NoProfile -ExecutionPolicy Bypass -File tools/run-compile-check.ps1`: passed with `GODOT_CONTRACTS_OK`.
- Latest node-map continuation rerun of `git diff --check`: no whitespace errors; LF-to-CRLF warnings only.
- Latest localization/reward UX rerun of `powershell -NoProfile -ExecutionPolicy Bypass -File tools/run-compile-check.ps1`: passed with `GODOT_CONTRACTS_OK`; Godot still prints RID/ObjectDB leak warnings at process exit.
- `powershell -NoProfile -ExecutionPolicy Bypass -File LTL-harness/tools/i18n-text-gate.ps1`: returns `I18N_TEXT_GATE_OK`.
- `powershell -NoProfile -ExecutionPolicy Bypass -File D:\Programming\ex_workspace\agent-harness\tools\i18n-text-gate.ps1 -Root D:\Programming\ex_workspace\agent-harness -Targets examples -AllowNoCatalog`: returns explicit `I18N_TEXT_GATE_SKIP` because the generic harness has no project catalog of its own.

## Blockers or Unverified Areas

- Runtime backing scripts remain compatibility shells for scene wiring, but the large unreachable duplicate blocks from extracted capsules have been removed.
- Existing user/source modifications were not reverted or normalized.
- Reward scene screenshot evidence and richer manual reward presentation QA were not produced in this pass.
- Plain non-editor Godot headless runner still crashes in Godot 4.3; the repository compile wrapper already uses `--editor --smoke-only` to avoid that engine-side crash.
- M4 milestone gate is now unblocked by the M3 completion document.

## Remaining Gaps

- No gate-blocking refactoring gaps remain for the M3 pre-refactor checkpoint. Further service-level decomposition of live runtime event handlers can be planned as a later architecture improvement rather than a current blocker.
- Remaining M3 visual evidence should cover reward scene screenshot, reward card readability, and reward selection to next-combat preview manual QA.
- Remaining M4 visual work should cover a real node-map scene/screenshot matrix and manual QA for candidate readability once the route panel graduates from read-model contract to polished scene.
- The minimal node-map scene now exists, but screenshot matrix and visual polish are still pending.
