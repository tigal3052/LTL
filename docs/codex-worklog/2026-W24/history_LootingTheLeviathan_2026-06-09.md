# Codex Worklog History

Workspace: LootingTheLeviathan
Date: 2026-06-09

No implementation history has been recorded yet.
## 2026-06-09 transition-safety-gate-hardening

- Intent: Turn the reward ceremony -> reward tray crash diagnosis into a durable harness policy that forces post-transition stability proof.
- Files or areas touched: `app-LTL/tests/run_reward_handoff_contract.gd`, `LTL-harness/docs/transition-safety-gate.md`, `docs/request-ledgers/2026-06-09-transition-safety-gate.md`, `docs/artifact-ledgers/2026-06-09-transition-safety-gate.md`.
- Summary: Strengthened the reward handoff runner so it now waits through a tray-review settle window and reasserts page ownership, reward-step ownership, reveal-VFX shutdown, reward-panel visibility, and shared-backpack docking stability across multiple frames instead of treating a one-frame handoff as sufficient proof. Recorded the successful gate reruns in the request and artifact ledgers and confirmed the compile-check chain still passes with transition safety in the blocking path.
- Plan impact: Closed the requested harness-policy slice; remaining failures are outside this scope.
- Verification status: `REQUEST_ANALYSIS_GATE_OK`, `REWARD_HANDOFF_CONTRACT_OK`, `TRANSITION_SAFETY_GATE_OK`, and `Compilation Check: PASSED (GODOT_CONTRACTS_OK)` all reran successfully. `tools/run-ltl-quality-gate.ps1` still fails on the pre-existing architectural rule violation in `app-LTL/src/ui/StatusPanelUI.gd`.
## 2026-06-09 reward-board-layout-investigation

- Intent: Identify why reward selection changes make the cleanup board reflow vertically and push the bottom action row off-screen.
- Files or areas touched: `app-LTL/src/ui/MainViewRuntime.gd`, `app-LTL/src/Main.tscn`, `app-LTL/tests/test_reward_claim_board_contract.gd`, `app-LTL/tests/ui_read_models/ui_backpack_layout_suite.gd`, `app-LTL/tests/run_main_layout_audit_contract.gd`, `docs/codex-worklog/plan_LootingTheLeviathan_2026-06-09.md`.
- Summary: Confirmed the current reward-board sync logic only normalizes widths; it does not pin the shared visible board height across the reward deck, workspace host, inspector, and bottom action row. Existing reward-board tests cover width containment and coarse viewport containment but do not assert equalized top-zone heights or stable bottom-row placement across inspection changes.
- Plan impact: Established the concrete RED target for the next change set.
- Verification status: Baseline `tests/run_reward_claim_board_contract.gd` currently exits successfully before the new regression coverage is added.

## 2026-06-09 reward-board-layout-fix

- Intent: Stabilize the reward cleanup board so reward selection no longer changes the active-screen layout footprint.
- Files or areas touched: `app-LTL/src/ui/MainViewRuntime.gd`, `app-LTL/src/Main.tscn`, `app-LTL/tests/test_reward_claim_board_contract.gd`.
- Summary: Added richer reward-board metrics and containment assertions in the reward claim board contract, then updated the runtime reward-board sync to compute a fixed visible top-zone/body split from the live scroll viewport. The runtime now normalizes top-zone heights across reward deck/workspace/inspector shells, assigns a stable bottom-row height for discard/confirm, resets reward-board scroll offset, and sizes the shared backpack host against the fixed workspace body. The scene defaults were also tightened so the left reward zone starts with the same minimum height as the middle/right zones and the bottom action zones fill their shared row.
- Plan impact: Completed the implementation step without expanding scope beyond the reward cleanup board.
- Verification status: `tools/invoke-godot.ps1` with `tests/run_reward_claim_board_contract.gd` exited `0`; `tools/invoke-godot.ps1` with `tests/run_main_layout_audit_contract.gd` exited `0`.

## 2026-06-09 reward-board-layout-rework

- Intent: Correct the failed first fix by tracing the live click path and targeting the actual layout inflation source.
- Files or areas touched: `app-LTL/src/ui/MainViewRuntime.gd`, `docs/codex-worklog/plan_LootingTheLeviathan_2026-06-09.md`, `docs/codex-worklog/complete_LootingTheLeviathan_2026-06-09.md`.
- Summary: Reconfirmed that reward-card click only rerenders inspector state, then measured the reward board under a controlled probe. The real failure was `InspectorStage` minimum height exploding when longer relic copy wrapped, which in turn pushed the outer reward board taller than the visible panel. Reworked the runtime to install internal scroll shells for reward-cloud content, inspector content, and discard/claim cards so child minimum sizes stop resizing the outer board. The reward-board layout sync now also falls back to the reward panel's visible height when the scroll viewport is unresolved and re-equalizes the top three zones and bottom row against the post-wrapper minimums.
- Plan impact: Superseded the earlier "fixed" status; the reward-board work remains in verification until a stable full reward-board contract run is available again.
- Verification status: `tools/invoke-godot.ps1` with `tests/run_reward_inspector_stability_contract.gd` exited `0`. A one-off direct reward-tray probe confirmed that reward deck/workspace/inspector heights now stay fixed across card clicks in a controlled render path. Full headless reward-board contract runs currently trigger a Godot signal-11 crash during broader flow simulation, so end-to-end automated confirmation is still incomplete.

## 2026-06-09 reward-ceremony-to-board crash diagnosis

- Intent: Review the reported live freeze/exit when the reward ceremony hands off to the reward cleanup board.
- Files or areas touched: `app-LTL/src/MainControllerRuntime.gd`, `app-LTL/src/ui/MainViewRuntime.gd`, `app-LTL/src/ui/RewardRevealOverlay.gd`, `app-LTL/tests/test_reward_claim_board_contract.gd`, `app-LTL/tests/run_reward_claim_board_contract.gd`.
- Summary: Confirmed that the ceremony-only path still passes its focused contract (`REWARD_CEREMONY_CONTRACT_OK`) and the reward-inspector stability runner also passes, so the failure is not in the reveal overlay itself. The broader reward-board contract still behaves in two distinct bad ways: a clean direct reward-board render fails layout containment assertions because the outer board still grows beyond the visible scroll viewport, and a broader flow simulation that first boots the normal page flow then renders the reward board crashes the engine with signal 11. That split strongly points to the reward-board handoff and layout/reparent transition, not reward generation or ceremony sequencing, as the current root-cause area.
- Plan impact: Clarified the next fix scope to transition-safe reward-board entry, especially the shared backpack reparent/layout sync path and the remaining reward-board minimum-size inflation.
- Verification status: `tools/invoke-godot.ps1` with `tests/run_reward_ceremony_contract.gd -Quit` printed `REWARD_CEREMONY_CONTRACT_OK`; `tests/run_reward_inspector_stability_contract.gd -Quit` printed `REWARD_INSPECTOR_STABILITY_CONTRACT_OK`; `tests/run_reward_claim_board_contract.gd` without `-Quit` crashed with signal 11 / exit `-1073741819`.
## 2026-06-09 00:01:48

<!-- codex-worklog-signature: 8718b9f895f03eaf0637f75e7cbc076f4ffe9041086cb18c1405e82b9e1377bb -->

- Intent: Workspace files changed through Codex tooling.
- Tool: Bash
- Files or areas touched:
``text
 M LTL-harness/00_AGENTS.md
 M LTL-harness/tools/i18n-text-gate.ps1
 D app-LTL/resources/UI/charactor/background.png
 D app-LTL/resources/UI/charactor/background.png.import
 D app-LTL/resources/UI/charactor/charactor1.png
 D app-LTL/resources/UI/charactor/charactor1.png.import
 D app-LTL/resources/UI/charactor/charactor1_ss.png
 D app-LTL/resources/UI/charactor/charactor1_ss.png.import
 D app-LTL/resources/UI/charactor/charactor_backpack.png
 D app-LTL/resources/UI/charactor/charactor_backpack.png.import
 M app-LTL/src/Main.tscn
 M app-LTL/src/MainControllerRuntime.gd
 M app-LTL/src/data/character-table.json
 M app-LTL/src/data/release-resource-needs.json
 M app-LTL/src/models/Artifact.gd
 M app-LTL/src/phases/BackpackOrganizePhase.gd
 M app-LTL/src/phases/NodeSelectPhase.gd
 M app-LTL/src/phases/RewardLootPhase.gd
 M app-LTL/src/process/HeadlessMiniRun.gd
 M app-LTL/src/scenes/node_map/NodeMapScene.gd
 M app-LTL/src/ui/BackpackUI.gd
 M app-LTL/src/ui/BattlefieldUI.gd
 M app-LTL/src/ui/CellView.gd
 M app-LTL/src/ui/CombatScenePreviewController.gd
 M app-LTL/src/ui/MainViewRuntime.gd
 M app-LTL/src/ui/RewardRevealOverlay.gd
 M app-LTL/src/ui/SceneReadModel.gd
 M app-LTL/src/ui/SettingsPanelUI.gd
 M app-LTL/src/ui/ShopPanelUI.gd
 M app-LTL/src/ui/StatusPanelUI.gd
``
- Summary: Review the plan and current diff for semantic details; keep this entry compressed if later updates touch the same area.
- Verification: Not recorded by hook. Update this after running checks.

## 2026-06-09 00:01:48

<!-- codex-worklog-signature: 8718b9f895f03eaf0637f75e7cbc076f4ffe9041086cb18c1405e82b9e1377bb -->

- Intent: Workspace files changed through Codex tooling.
- Tool: Bash
- Files or areas touched:
``text
 M LTL-harness/00_AGENTS.md
 M LTL-harness/tools/i18n-text-gate.ps1
 D app-LTL/resources/UI/charactor/background.png
 D app-LTL/resources/UI/charactor/background.png.import
 D app-LTL/resources/UI/charactor/charactor1.png
 D app-LTL/resources/UI/charactor/charactor1.png.import
 D app-LTL/resources/UI/charactor/charactor1_ss.png
 D app-LTL/resources/UI/charactor/charactor1_ss.png.import
 D app-LTL/resources/UI/charactor/charactor_backpack.png
 D app-LTL/resources/UI/charactor/charactor_backpack.png.import
 M app-LTL/src/Main.tscn
 M app-LTL/src/MainControllerRuntime.gd
 M app-LTL/src/data/character-table.json
 M app-LTL/src/data/release-resource-needs.json
 M app-LTL/src/models/Artifact.gd
 M app-LTL/src/phases/BackpackOrganizePhase.gd
 M app-LTL/src/phases/NodeSelectPhase.gd
 M app-LTL/src/phases/RewardLootPhase.gd
 M app-LTL/src/process/HeadlessMiniRun.gd
 M app-LTL/src/scenes/node_map/NodeMapScene.gd
 M app-LTL/src/ui/BackpackUI.gd
 M app-LTL/src/ui/BattlefieldUI.gd
 M app-LTL/src/ui/CellView.gd
 M app-LTL/src/ui/CombatScenePreviewController.gd
 M app-LTL/src/ui/MainViewRuntime.gd
 M app-LTL/src/ui/RewardRevealOverlay.gd
 M app-LTL/src/ui/SceneReadModel.gd
 M app-LTL/src/ui/SettingsPanelUI.gd
 M app-LTL/src/ui/ShopPanelUI.gd
 M app-LTL/src/ui/StatusPanelUI.gd
``
- Summary: Review the plan and current diff for semantic details; keep this entry compressed if later updates touch the same area.
- Verification: Not recorded by hook. Update this after running checks.

## 2026-06-09 01:22:26

<!-- codex-worklog-signature: 9a94c92b026f3ad9c1843821951e32a75dcdcd8e923c39f42d69e5c595135d5c -->

- Intent: Workspace files changed through Codex tooling.
- Tool: apply_patch
- Files or areas touched:
``text
 M LTL-harness/00_AGENTS.md
 M LTL-harness/tools/i18n-text-gate.ps1
 D app-LTL/resources/UI/charactor/background.png
 D app-LTL/resources/UI/charactor/background.png.import
 D app-LTL/resources/UI/charactor/charactor1.png
 D app-LTL/resources/UI/charactor/charactor1.png.import
 D app-LTL/resources/UI/charactor/charactor1_ss.png
 D app-LTL/resources/UI/charactor/charactor1_ss.png.import
 D app-LTL/resources/UI/charactor/charactor_backpack.png
 D app-LTL/resources/UI/charactor/charactor_backpack.png.import
 M app-LTL/src/Main.tscn
 M app-LTL/src/MainControllerRuntime.gd
 M app-LTL/src/data/character-table.json
 M app-LTL/src/data/release-resource-needs.json
 M app-LTL/src/models/Artifact.gd
 M app-LTL/src/phases/BackpackOrganizePhase.gd
 M app-LTL/src/phases/NodeSelectPhase.gd
 M app-LTL/src/phases/RewardLootPhase.gd
 M app-LTL/src/process/HeadlessMiniRun.gd
 M app-LTL/src/scenes/node_map/NodeMapScene.gd
 M app-LTL/src/ui/BackpackUI.gd
 M app-LTL/src/ui/BattlefieldUI.gd
 M app-LTL/src/ui/CellView.gd
 M app-LTL/src/ui/CombatScenePreviewController.gd
 M app-LTL/src/ui/MainViewRuntime.gd
 M app-LTL/src/ui/RewardRevealOverlay.gd
 M app-LTL/src/ui/SceneReadModel.gd
 M app-LTL/src/ui/SettingsPanelUI.gd
 M app-LTL/src/ui/ShopPanelUI.gd
 M app-LTL/src/ui/StatusPanelUI.gd
``
- Summary: Review the plan and current diff for semantic details; keep this entry compressed if later updates touch the same area.
- Verification: Not recorded by hook. Update this after running checks.

## 2026-06-09 10:12:40

<!-- codex-worklog-signature: 7a09e5ef5c66a4864abd00f240320a1197e01e1cf24e4504b88074664d41e04a -->

- Intent: Workspace files changed through Codex tooling.
- Tool: unknown
- Files or areas touched:
``text
 M LTL-harness/00_AGENTS.md
 M LTL-harness/tools/i18n-text-gate.ps1
 D app-LTL/resources/UI/charactor/background.png
 D app-LTL/resources/UI/charactor/background.png.import
 D app-LTL/resources/UI/charactor/charactor1.png
 D app-LTL/resources/UI/charactor/charactor1.png.import
 D app-LTL/resources/UI/charactor/charactor1_ss.png
 D app-LTL/resources/UI/charactor/charactor1_ss.png.import
 D app-LTL/resources/UI/charactor/charactor_backpack.png
 D app-LTL/resources/UI/charactor/charactor_backpack.png.import
 M app-LTL/src/Main.tscn
 M app-LTL/src/MainControllerRuntime.gd
 M app-LTL/src/data/character-table.json
 M app-LTL/src/data/release-resource-needs.json
 M app-LTL/src/models/Artifact.gd
 M app-LTL/src/phases/BackpackOrganizePhase.gd
 M app-LTL/src/phases/NodeSelectPhase.gd
 M app-LTL/src/phases/RewardLootPhase.gd
 M app-LTL/src/process/HeadlessMiniRun.gd
 M app-LTL/src/scenes/node_map/NodeMapScene.gd
 M app-LTL/src/ui/BackpackUI.gd
 M app-LTL/src/ui/BattlefieldUI.gd
 M app-LTL/src/ui/CellView.gd
 M app-LTL/src/ui/CombatScenePreviewController.gd
 M app-LTL/src/ui/MainViewRuntime.gd
 M app-LTL/src/ui/RewardRevealOverlay.gd
 M app-LTL/src/ui/SceneReadModel.gd
 M app-LTL/src/ui/SettingsPanelUI.gd
 M app-LTL/src/ui/ShopPanelUI.gd
 M app-LTL/src/ui/StatusPanelUI.gd
``
- Summary: Review the plan and current diff for semantic details; keep this entry compressed if later updates touch the same area.
- Verification: Not recorded by hook. Update this after running checks.

## 2026-06-09 source-map-request-mapping

- Intent: Verify whether the harness only generated/validated `docs/source-map.md` or also used it while mapping relevant source for new user requests, then harden the missing request-analysis link.
- Files or areas touched: `LTL-harness/tools/request-analysis-gate.ps1`, `LTL-harness/tools/request-analysis-gate.tests.ps1`, `LTL-harness/tools/request-source-map.ps1`, `LTL-harness/tools/request-source-map.tests.ps1`, `LTL-harness/docs/request-analysis-execution-gate.md`, `LTL-harness/docs/templates/request-constraint-ledger-template.md`, `LTL-harness/00_AGENTS.md`, `LTL-harness/README.md`, `tools/run-ltl-quality-gate.ps1`, `docs/request-ledgers/2026-06-02-refactor-harness-quality-gate.md`, `docs/request-ledgers/2026-06-07-character-select-layout-containment.md`, `docs/request-ledgers/2026-06-07-page-contract-harness-hardening.md`, `docs/request-ledgers/2026-06-08-test-suite-size-gate.md`, `docs/request-ledgers/2026-06-09-source-map-request-mapping.md`, `docs/artifact-ledgers/2026-06-09-source-map-request-mapping.md`, `docs/source-map.md`.
- Summary: Confirmed that the live source map was previously treated as a completeness/maintenance gate but not as an explicit request-analysis input. Added a new `request-source-map` helper, made `Source Map Findings` mandatory in request ledgers, updated the harness docs/templates to require source-map lookup before mutable scope is locked, and registered the new helper plus revised responsibilities in the live source map.
- Plan impact: Added a harness-side recurrence-prevention layer without moving the shared source-map SoT out of `docs/source-map.md`.
- Verification status: `request-analysis-gate.ps1 -Mode pre-edit` passed on the new ledger, `request-analysis-gate.tests.ps1` passed, `request-source-map.tests.ps1` passed, and a live `request-source-map.ps1 -Keyword source-map` query returned the expected harness candidate files. The broader `source-map-gate.ps1 -Root .` check remains blocked by unrelated pre-existing source-map drift in the dirty workspace.

## 2026-06-09 source-map-drift-cleanup

- Intent: Execute the next requested step by bringing the live source map back in sync with the current formal tree so the repository-wide source-map gate could pass again.
- Files or areas touched: `docs/source-map.md`, `docs/request-ledgers/2026-06-09-source-map-drift-cleanup.md`, `docs/artifact-ledgers/2026-06-09-source-map-drift-cleanup.md`, `docs/codex-worklog/plan_LootingTheLeviathan_2026-06-09.md`, `docs/codex-worklog/complete_LootingTheLeviathan_2026-06-09.md`.
- Summary: Traced the remaining gate failure to real formal-source drift rather than a bad exclusion rule. Added the full defeat-art bundle and import metadata, the missing Leviathan drake art, the new i18n catalogs, the missing defeat-page controller entry, and the missing formal test runners/test file to `docs/source-map.md`, while preserving the earlier hand-written responsibility notes for already-tracked files.
- Plan impact: Completed the follow-up cleanup without expanding into runtime or harness-script behavior changes.
- Verification status: `LTL-harness/tools/source-map-gate.ps1 -Root .` passed with `SOURCE_MAP_GATE_OK`, and `git diff --check` passed for the touched docs/reporting files with line-ending warnings only.

## 2026-06-09 dirty-worktree-batching-audit

- Intent: Classify the remaining dirty workspace after the source-map recovery so future staging or follow-up execution can separate related work more safely.
- Files or areas touched: `docs/codex-worklog/plan_LootingTheLeviathan_2026-06-09.md`, `docs/codex-worklog/history_LootingTheLeviathan_2026-06-09.md`, `docs/codex-worklog/complete_LootingTheLeviathan_2026-06-09.md`, plus read-only inspection of `docs/source-map.md`, recent request ledgers, plans, and the current git diff.
- Summary: Used `git status --short`, `git diff --stat`, and targeted `request-source-map` queries for `leviathan`, `node select`, `reward`, and `i18n` to map the remaining changes back to their source responsibilities. The remaining dirt clusters into four main streams: (1) harness and source-governance work under `LTL-harness/**`, `tools/**`, `docs/request-ledgers/**`, and `docs/source-map.md`; (2) M6 runtime/page work spanning `Main.tscn`, `MainControllerRuntime.gd`, `MainViewRuntime.gd`, page scenes, moved character/Leviathan assets, theme, and i18n catalogs; (3) formal test-structure work centered on `test_ui_read_models.gd`, new `tests/ui_read_models/**`, `tests/support/**`, and the related contract runners; and (4) design/worklog evidence under `docs/mockups/**`, `docs/superpowers/**`, and dated worklogs. The highest-risk shared hotspots are `app-LTL/src/ui/MainViewRuntime.gd`, `app-LTL/src/MainControllerRuntime.gd`, `app-LTL/src/Main.tscn`, `app-LTL/tests/run_main_layout_audit_contract.gd`, `app-LTL/tests/run_main_start_flow_contract.gd`, and `docs/source-map.md`, because they bridge multiple feature streams at once.
- Plan impact: The next execution pass should avoid treating the worktree as one change. A practical batching order is harness/source-governance first, formal test-structure second, runtime/page shell third, then docs/mockup evidence last, with the shared hotspot files reviewed deliberately before staging.
- Verification status: `git status --short` and `git diff --stat` were inspected successfully; `request-source-map.ps1` returned relevant mapped candidates for `leviathan`, `node select`, `reward`, and `i18n`; `git diff --check` on today's worklog files passed with existing LF/CRLF warnings only.

## 2026-06-09 transition-safety-gate-design

- Intent: Convert the reward ceremony to reward-board crash diagnosis into a harness-level recurrence-prevention policy before further implementation work.
- Files or areas touched: `docs/superpowers/specs/2026-06-09-transition-safety-gate-design.ko.md`, `docs/codex-worklog/plan_LootingTheLeviathan_2026-06-09.md`, `docs/codex-worklog/history_LootingTheLeviathan_2026-06-09.md`, plus read-only inspection of `LTL-harness/tools/request-analysis-gate.ps1`, `LTL-harness/docs/request-analysis-execution-gate.md`, `LTL-harness/docs/templates/request-constraint-ledger-template.md`, and `LTL-harness/tools/page-contract-gate.ps1`.
- Summary: Wrote the approved design note for a dedicated transition-safety gate that makes transition review mandatory in request ledgers, registers baseline transitions such as `meta.start_flow`, `page.scene_mapping`, `reward.ceremony`, and the currently missing `reward.handoff`, and promotes crash-string plus success-marker validation into a blocking verification layer. The self-review also surfaced one concrete reason this policy matters: the existing page-contract gate already enforces a success marker for `page.scene_mapping`, but its `run_main_start_flow_contract.gd` invocation still relies on exit code only even though the runner emits `MAIN_START_FLOW_CONTRACT_OK`. The transition-safety design now explicitly requires marker-based proof normalization when legacy coverage is reused.
- Plan impact: The next step should be implementation planning and harness wiring only after the written design checkpoint is reviewed.
- Verification status: `git diff --check` passed for the updated plan/spec files, and manual inspection confirmed the live page-contract gate/start-flow runner mismatch that the design now addresses.

## 2026-06-09 harness-batch-closure-audit

- Intent: Test whether the recommended first batch, harness/source-governance, could actually stand alone or whether it already depends on files from the other dirty-worktree streams.
- Files or areas touched: `docs/codex-worklog/plan_LootingTheLeviathan_2026-06-09.md`, `docs/codex-worklog/history_LootingTheLeviathan_2026-06-09.md`, `docs/codex-worklog/complete_LootingTheLeviathan_2026-06-09.md`, plus read-only inspection of `LTL-harness/**`, `tools/run-*.ps1`, `app-LTL/tests/**`, `app-LTL/src/data/i18n/**`, `app-LTL/src/scenes/pages/**`, and `docs/mockups/**`.
- Summary: The first batch is not actually independent yet. `tools/run-compile-check.ps1` now wires `test-size-gate.ps1` and `page-contract-gate.ps1`; those in turn require split test files under `app-LTL/tests/ui_read_models/**` and `app-LTL/tests/support/**`, page-contract runners such as `run_page_scene_mapping_contract.gd`, `run_main_start_flow_contract.gd`, and `run_main_layout_audit_contract.gd`, the page scenes under `app-LTL/src/scenes/pages/**`, and the approved mockups under `docs/mockups/m6-*.html`. The expanded `i18n-text-gate.ps1` also hard-depends on `app-LTL/src/data/i18n/text-ko.json`, `app-LTL/src/data/i18n/text-en.json`, and a matching `TextCatalog.gd` route. In other words, the current harness/governance batch closes over parts of the test, runtime/page, i18n, and mockup bundles.
- Plan impact: The earlier simple batch order needs one refinement. The next safe split is either (a) a broader "governance plus dependency closure" batch that intentionally includes the page-contract/test-size/i18n/mockup surfaces it references, or (b) a stricter reduced harness-only batch that defers the new gate wiring until the dependent runtime/test surfaces are staged together.
- Verification status: `git status --short` confirmed the dependent paths are also dirty or newly added, `rg` across `LTL-harness/**` and `tools/**` confirmed the concrete cross-batch path references, and `git ls-files` showed the new gate/helper files still need deliberate staging rather than assuming they are already part of a committed tracked base.

## 2026-06-09 leviathan-cta-contract-follow-up

- Intent: Use the newly exposed compile/page-contract blockers to distinguish a narrow stale-test problem from broader runtime drift, then repair only the narrow blocker that was safe to fix in place.
- Files or areas touched: `app-LTL/tests/run_page_scene_mapping_contract.gd`, `app-LTL/src/data/i18n/text-en.json`, `docs/source-map.md`, `docs/codex-worklog/history_LootingTheLeviathan_2026-06-09.md`, `docs/codex-worklog/complete_LootingTheLeviathan_2026-06-09.md`.
- Summary: Traced the first `page-contract-gate` failure to a stale page-scene mapping contract that still assumed raw static CTA text on `LeviathanSelectPage`, even though the live runtime now sources that copy through `TextCatalog`. Reworked the contract so it still verifies the page structure in-scene but checks the approved English CTA wording through `TextCatalog` instead of empty pre-ready label nodes, and aligned `text-en.json` with the approved `IMMEDIATE HANDOFF` / `LOOTING START` copy. While re-running the fast compile path, also fixed a newly exposed source-map drift entry by mapping `docs/superpowers/specs/2026-06-09-transition-safety-gate-design.ko.md`.
- Plan impact: Recovered the narrow structural blocker without attempting the much broader UI-read-model localization drift that still fails the page-semantics contract.
- Verification status: `tests/run_page_scene_mapping_contract.gd` now prints `PAGE_SCENE_MAPPING_CONTRACT_OK`; `source-map-gate.ps1 -Root .` is back to `SOURCE_MAP_GATE_OK`; `tools/run-compile-check.ps1` now advances past source-map and test-size checks but still stops at the known broader `page semantics contract` failures inside `run_test_ui_read_models.gd`.

## 2026-06-09 page-semantics-and-fast-compile-recovery

- Intent: Clear the broader page-semantics blocker without broad runtime edits, then finish the fast compile path by separating transition-ledger validation from the generic no-impact compile default.
- Files or areas touched: `app-LTL/tests/ui_read_models/ui_text_tooltip_suite.gd`, `app-LTL/tests/ui_read_models/ui_phase_layout_suite.gd`, `app-LTL/tests/ui_read_models/ui_codex_reward_board_suite.gd`, `app-LTL/tests/ui_read_models/ui_defeat_visual_suite.gd`, `app-LTL/tests/run_main_start_flow_contract.gd`, `app-LTL/tests/run_reward_handoff_contract.gd`, `app-LTL/src/ui/read_models/RewardReadModel.gd`, `docs/source-map.md`, `tools/run-compile-check.ps1`, `docs/codex-worklog/plan_LootingTheLeviathan_2026-06-09.md`.
- Summary: Updated stale or mojibake UI read-model expectations so they assert the current `TextCatalog`-driven locale contract instead of corrupted literal strings. The repaired suites now use explicit Korean locale setup, catalog-backed reward/tooltip labels, and current defeat/phase text. Added the missing transition-safety and request-ledger file-map entries to `docs/source-map.md`, normalized `run_main_start_flow_contract.gd` so its success marker is emitted under the real multi-frame runner path, added a focused `run_reward_handoff_contract.gd` proof script for the still-crashing reward ceremony -> tray review boundary, restored formal comment headers for `RewardReadModel.gd`, and changed `tools/run-compile-check.ps1` to default back to the generic no-transition-impact harness ledger instead of the transition-safety implementation ledger.
- Plan impact: The fast compile path is green again without pretending the explicit `reward.handoff` runtime crash is solved. Transition-specific verification still needs the dedicated transition ledger and currently exposes the known signal-11 failure on the reward handoff path.
- Verification status: `tests/run_test_ui_read_models.gd` -> `UI_READ_MODEL_TESTS_OK`; `LTL-harness/tools/page-contract-gate.tests.ps1` -> `PAGE_CONTRACT_GATE_TESTS_OK`; `LTL-harness/tools/source-map-gate.ps1 -Root .` -> `SOURCE_MAP_GATE_OK`; `LTL-harness/tools/transition-safety-gate.ps1 -Ledger docs/request-ledgers/2026-06-02-refactor-harness-quality-gate.md` -> `TRANSITION_SAFETY_GATE_OK`; `tools/run-compile-check.ps1` -> `Compilation Check: PASSED (GODOT_CONTRACTS_OK)`. A focused manual run of `tests/run_reward_handoff_contract.gd` without `-Quit` still reproduces the known `signal 11` crash immediately after `REWARD_HANDOFF_STEP: finishing_overlay`.

## 2026-06-09 reward-handoff-crash-fix

- Intent: Eliminate the remaining reward ceremony -> tray review crash without regressing the newly recovered transition-safety and compile gates.
- Files or areas touched: `app-LTL/src/MainControllerRuntime.gd`, `app-LTL/src/ui/MainViewRuntime.gd`, `app-LTL/src/ui/RewardRevealOverlay.gd`, `docs/codex-worklog/plan_LootingTheLeviathan_2026-06-09.md`, `docs/codex-worklog/history_LootingTheLeviathan_2026-06-09.md`, `docs/codex-worklog/complete_LootingTheLeviathan_2026-06-09.md`.
- Summary: Reproduced the live crash at the exact overlay-finish boundary, confirmed the real failure path was the reward ceremony completion handoff rather than the test harness, then repaired the callback plumbing so `RewardRevealOverlay` emits a `ceremony_finished("tray_review")` signal, `MainViewRuntime` bridges that signal back to the controller with a deferred callback flush, and `MainControllerRuntime` performs its tray-review render through a no-argument deferred helper after one process frame. The remaining hang after that fix came from reward-board layout feedback loops during shared-backpack docking, so the view now ignores reward-host shared-backpack resync requests and only re-runs viewport shell synchronization when the actual viewport size changes instead of every internal `NOTIFICATION_RESIZED`.
- Plan impact: The explicit `reward.handoff` transition is no longer a known failure and can stay inside the formal transition-safety gate instead of being treated as a diagnostic-only manual repro.
- Verification status: `tools/invoke-godot.ps1 ... tests/run_reward_handoff_contract.gd -Headless` -> `REWARD_HANDOFF_CONTRACT_OK`; `LTL-harness/tools/transition-safety-gate.ps1 -Ledger docs/request-ledgers/2026-06-09-transition-safety-gate.md` -> `TRANSITION_SAFETY_GATE_OK`; `tools/run-compile-check.ps1` -> `Compilation Check: PASSED (GODOT_CONTRACTS_OK)`.

## 2026-06-09 reward-board-width-drift-hardening

- Intent: Diagnose why alternating reward-card clicks kept pushing the reward cleanup page to the right, then convert the fix into a blocking harness rule instead of a one-off runtime patch.
- Files or areas touched: `app-LTL/src/ui/MainViewRuntime.gd`, `app-LTL/src/Main.tscn`, `app-LTL/tests/test_reward_claim_board_contract.gd`, `app-LTL/tests/run_reward_claim_board_contract.gd`, `app-LTL/tests/ui_read_models/ui_backpack_layout_suite.gd`, `LTL-harness/tools/page-contract-gate.ps1`, `docs/codex-worklog/plan_LootingTheLeviathan_2026-06-09.md`, `docs/codex-worklog/history_LootingTheLeviathan_2026-06-09.md`, `docs/codex-worklog/complete_LootingTheLeviathan_2026-06-09.md`.
- Summary: Rebuilt the stale reward-board contract around the live reward/tray render path and confirmed the real drift came from self-referential width math: `_sync_reward_board_layout()` was deriving new zone minimum widths from the already-grown `reward_grid.size.x`, so each inspection click could ratchet the board wider. Long inspector titles could also widen the split because the `InspectorName` scene node still fit content instead of wrapping. The runtime now derives reward-board widths from the viewport-safe app-shell width, forces the reward-board/grid minimum widths back onto that viewport-based budget, and applies wrap/fill policies to reward inspector text so content growth stays inside the fixed split columns. The harness side now runs a dedicated `reward claim board contract` inside `page-contract-gate.ps1`, with live alternation, verbose-name containment, and a viewport matrix (`1280x720`, `1440x900`, `1920x1080`) so the board must stay fixed across common aspect ratios as well as content changes.
- Plan impact: The reward-board containment bug is now covered by the normal page-contract gate rather than depending on manual visual inspection or stale private tests.
- Verification status: `tools/invoke-godot.ps1 ... tests/run_reward_claim_board_contract.gd -Headless` -> `REWARD_CLAIM_BOARD_CONTRACT_OK`; `LTL-harness/tools/page-contract-gate.ps1 -Root . -GodotPath D:\Programming\godot_workspace\bin\Godot_v4.3-stable_win64_console.exe` -> `PAGE_CONTRACT_GATE_OK`; `git diff --check -- app-LTL/src/ui/MainViewRuntime.gd app-LTL/src/Main.tscn app-LTL/tests/test_reward_claim_board_contract.gd app-LTL/tests/run_reward_claim_board_contract.gd app-LTL/tests/ui_read_models/ui_backpack_layout_suite.gd LTL-harness/tools/page-contract-gate.ps1 docs/codex-worklog/plan_LootingTheLeviathan_2026-06-09.md docs/codex-worklog/history_LootingTheLeviathan_2026-06-09.md docs/codex-worklog/complete_LootingTheLeviathan_2026-06-09.md` passed with line-ending warnings only.

## 2026-06-09 reward-tray-shell-copy-cleanup

- Intent: Fix the reward-tray panel mismatch the user kept seeing, switch the header title to the selected Leviathan name, and remove the extra helper copy in the inspector/discard/confirm zones.
- Files or areas touched: `app-LTL/src/ui/MainViewRuntime.gd`, `app-LTL/src/data/i18n/text-ko.json`, `app-LTL/src/data/i18n/text-en.json`, `app-LTL/tests/test_reward_claim_board_contract.gd`, `app-LTL/tests/ui_read_models/ui_codex_reward_board_suite.gd`, `docs/codex-worklog/plan_LootingTheLeviathan_2026-06-09.md`.
- Summary: Restored the reward workspace shell as the visible middle panel by keeping its outer title shell/border active during reward-tray docking, reusing the backpack title copy on that shell, and hiding the docked backpack panel's inner title so the middle lane no longer presents as a shorter duplicate panel. The main header now resolves to the selected Leviathan name when available. The requested helper copy was removed from the Korean and English reward-board catalogs, including the inspector hint/kicker, discard hint/inner heading, confirm hint, ready-state claim body, and the duplicated discard-zone lead line.
- Plan impact: Completed the requested UI cleanup without broadening back into unrelated reward-board refactors.
- Verification status: `tools/invoke-godot.ps1 ... tests/run_test_ui_read_models.gd -Headless -Quit` -> `UI_READ_MODEL_TESTS_OK`; `tools/invoke-godot.ps1 ... tests/run_reward_claim_board_contract.gd -Headless` -> `REWARD_CLAIM_BOARD_CONTRACT_OK`; `git diff --check -- app-LTL/src/ui/MainViewRuntime.gd app-LTL/src/data/i18n/text-ko.json app-LTL/src/data/i18n/text-en.json app-LTL/tests/test_reward_claim_board_contract.gd app-LTL/tests/ui_read_models/ui_codex_reward_board_suite.gd docs/codex-worklog/plan_LootingTheLeviathan_2026-06-09.md docs/codex-worklog/history_LootingTheLeviathan_2026-06-09.md docs/codex-worklog/complete_LootingTheLeviathan_2026-06-09.md` exited `0` with an existing LF/CRLF warning on `app-LTL/src/ui/MainViewRuntime.gd`.
