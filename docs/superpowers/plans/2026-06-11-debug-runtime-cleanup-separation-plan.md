# Debug Runtime Cleanup Separation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Separate the live debug-runtime sources from generated residue, preserved prototypes, dead helper leftovers, and internal `.gd`/`.tscn` legacy code so cleanup can proceed without breaking the actual Godot run path.

**Architecture:** Use `app-LTL/project.godot -> app-LTL/src/Main.tscn -> MainControllerRuntime.gd -> MainViewRuntime.gd -> registered page scenes` as the only source of truth. Cleanup happens in rings: generated local artifacts first, prototype/archive policy second, file-level dead residue third, then internal runtime/scene code only after ownership is proven and Godot contracts are updated.

**Tech Stack:** Godot 4.3, GDScript, `.tscn` scenes, PowerShell, `rg`, existing Godot contract runners and harness docs.

---

## Current Audit Snapshot

- Live debug entry is `app-LTL/project.godot`, which sets `run/main_scene="res://src/Main.tscn"`.
- `app-LTL/src/ui/MainViewRuntime.gd` currently registers these active page scenes:
  - `character_select`
  - `leviathan_select`
  - `node_select`
  - `battle`
  - `boss_battle`
  - `reward`
  - `boss_reward`
  - `event_node`
  - `defeat`
  - `clear`
- `app-LTL/tests/run_main_start_flow_contract.gd` proves the live flow starts at `character_select`, moves through `leviathan_select`, then exercises `node_select`, `battle`, `reward`, `defeat`, and clear/boss-return paths.
- `app-LTL/tests/run_page_scene_mapping_contract.gd` still uses the HTML mockups in `docs/mockups/**` as mapping contracts, so those mockups are not cleanup junk yet.
- `rg` shows no active runtime or project entry references to `app-LTL/prototype/**`; prototype paths now appear only in docs and one test assertion that confirms the formal path does not use them.
- User decision: keep `app-LTL/prototype/**`. Treat it as preserved prototype reference, not deletion residue.
- `app-LTL/src/ui/legacy/LegacyRewardRevealOverlay.gd` was deleted after a red/green UI read-model contract update proved the cinematic `RewardRevealOverlay.gd` is the only remaining owner.
- `app-LTL/src/data/rarity-table.json` was deleted after reference scans showed no active runtime loader.
- `NodeMapScene.gd`, `NodeMapScene.tscn`, and `NodeMapReadModel.gd` look like retired node-select surfaces, but they are still wired into `MainViewRuntime.gd`, `SharedBackpackHostCoordinator.gd`, and several tests/probes. Do not delete them until the node-select page has one proven owner.
- `Main.tscn` still contains app-shell era nodes such as `LeftSidebar`, `RightSidebar`, `ActionBar`, `RepairOverlay`, `ConfirmOverlay`, `SettingsPanel`, `ParticleTemplate`, and `GridMock`. Some are still active, so each node must be classified as keep, migrate, or delete before editing the scene.
- `MainViewRuntime.gd` contains likely stale shop fields (`shop_gold_label`, `shop_xp_label`, `shop_buttons`, `shop_labels`, `current_shop_state`) and debug-only Codex reveal state (`CODEX_FORCE_DISCOVERED_KEY`, `codex_force_all_discovered`, `current_codex_debug_all`). These are internal cleanup candidates, not file-level delete candidates.
- Largest immediate generated residue found during this audit:
  - `app-LTL/.godot/` about 48.46 MB
  - `.godot-user/` about 2.56 MB

## Deletion Approval Boundary

No destructive delete command should run until the user approves the exact candidate set for that wave. This plan only prepares the execution order and proof requirements.

## Keep List

- Keep `app-LTL/project.godot`.
- Keep `app-LTL/src/Main.tscn`, `app-LTL/src/MainController.gd`, `app-LTL/src/MainControllerRuntime.gd`, `app-LTL/src/ui/MainUI.gd`, and `app-LTL/src/ui/MainViewRuntime.gd`.
- Keep all currently registered page scenes under `app-LTL/src/scenes/pages/**`, including `ClearPage.tscn` and its dependency `OutcomePage.tscn`.
- Keep active runtime helpers under `app-LTL/src/ui/**`, `app-LTL/src/ui/presenters/**`, `app-LTL/src/ui/read_models/**`, `app-LTL/src/phases/**`, `app-LTL/src/process/**`, `app-LTL/src/models/**`, and `app-LTL/src/vocabulary/**` unless a later per-file reference scan proves they are dead.
- Keep `app-LTL/tests/run_main_start_flow_contract.gd`, `app-LTL/tests/run_main_layout_audit_contract.gd`, `app-LTL/tests/run_page_scene_mapping_contract.gd`, and `app-LTL/tests/run_test_ui_read_models.gd` as the minimum runtime-survival proof set.
- Keep `docs/mockups/**` and `docs/source-map.md` for now because the current page-scene and source-map gates still rely on them.
- Keep `app-LTL/prototype/**` as preserved prototype reference material. It should be documented as out-of-runtime, but not deleted in this cleanup track.

## Delete Candidate Classes

### Class A: Generated Local Residue

Meaning: Class A is not source code and not historical design material. It means local generated output, editor/import cache, temporary Godot folders, or logs that can be recreated and should not influence runtime behavior.

These are safe-first candidates because they are ignored, recreated, or log-only:

- `app-LTL/.godot/`
- `.godot-user/`
- `.tmp-godot-crash-probe/`
- `.tmp-godot-logs/`
- `godot-contracts.log`
- `reward-ceremony-contract.log`
- `reward-ceremony-red2.log`
- `reward-ceremony-red3.log`

### Class B: Preserved Prototype Archive

These are not in the live debug path, but the user explicitly wants prototypes retained:

- `app-LTL/prototype/**`

Policy:

- Do not delete prototype files.
- Do mark them as out-of-runtime in source-map/worklog/docs if any current wording implies they are active implementation.
- Do not use prototype files as the basis for runtime cleanup unless the user explicitly asks to revive a prototype feature.

### Class C: Tracked Archive Residue Requiring Separate Approval

These are not in the live debug path and are not covered by the prototype keep decision:

- `docs/comment-gates/backups/**`

### Class D: Completed File-Level Legacy Or Dead Deletions

These were removed in the current execution slice after baseline tests, a focused red test where applicable, source-map cleanup, and post-delete contract verification:

- `app-LTL/src/ui/legacy/LegacyRewardRevealOverlay.gd`
- `app-LTL/src/data/rarity-table.json`
- `app-LTL/tests/inspect_img.gd`
- `app-LTL/resources/UI/backpack.png`
- `app-LTL/resources/UI/backpack.png.import`

### Class E: Internal `.gd` / `.tscn` Cleanup Candidates

These are not simple file deletions. They require deleting functions, fields, node subtrees, signal connections, tests, or read-model glue after proving which owner should remain:

- Retired node-map path:
  - `app-LTL/src/ui/MainViewRuntime.gd` `NodeMapReadModelScript`, `NodeMapSceneScript`, `node_map_scene`, `node_select_map_host`, `_create_node_map_scene()`, node-map render/rerender calls.
  - `app-LTL/src/scenes/node_map/NodeMapScene.gd`
  - `app-LTL/src/scenes/node_map/NodeMapScene.tscn`
  - `app-LTL/src/ui/read_models/NodeMapReadModel.gd`
  - related tests/probes that still require the standalone legacy node map.
- App-shell scene residue in `app-LTL/src/Main.tscn`:
  - classify `LeftSidebar`, `RightSidebar`, `ActionBar`, `RepairOverlay`, `ConfirmOverlay`, `SettingsPanel`, `ParticleTemplate`, `GridMock`.
  - keep or migrate active nodes; delete only node subtrees whose behavior has moved to page scenes or dedicated UI owners.
- Stale `MainViewRuntime.gd` fields:
  - likely delete after compile proof: `shop_gold_label`, `shop_xp_label`, `shop_buttons`, `shop_labels`, `current_shop_state`.
  - verify before touching: `interaction_fx_enabled`, `log_console`, `portrait_label`, reward inspector labels, and any callback-connected functions.
- Debug-only Codex reveal path:
  - decide whether F8/show-all discovery is still a desired debug feature.
  - if not, remove `CODEX_FORCE_DISCOVERED_KEY`, `codex_force_all_discovered`, `_toggle_codex_force_all_discovered()`, `current_codex_debug_all`, `ArtifactCodexPanelUI.debug_toggled`, `codex.debug_all`, and `log.debug.codex_discovery_toggle`.

## Current Execution Slice

Completed in this slice:

- Baseline verification before deletion:
  - `powershell -NoProfile -ExecutionPolicy Bypass -File LTL-harness/tools/source-map-gate.ps1`
  - `powershell -NoProfile -ExecutionPolicy Bypass -File tools/run-compile-check.ps1`
- Red test before deletion:
  - `app-LTL/tests/ui_read_models/ui_reward_reveal_ceremony_suite.gd` now asserts `res://src/ui/legacy/LegacyRewardRevealOverlay.gd` no longer exists.
  - `powershell -NoProfile -ExecutionPolicy Bypass -File tools/invoke-godot.ps1 -ProjectPath app-LTL -Headless -Script tests/run_test_ui_read_models.gd` failed before deletion with the expected legacy-file-present assertion.
- Tracked source deletion and companion cleanup:
  - Deleted `app-LTL/src/ui/legacy/LegacyRewardRevealOverlay.gd`.
  - Removed its required-script entries from `app-LTL/tests/godot_contract_runner.gd`.
  - Deleted `app-LTL/src/data/rarity-table.json`.
  - Deleted `app-LTL/tests/inspect_img.gd`.
  - Deleted `app-LTL/resources/UI/backpack.png`.
  - Deleted `app-LTL/resources/UI/backpack.png.import`.
  - Removed deleted path entries from `docs/source-map.md`.
  - Removed declaration-only stale shop fields from `app-LTL/src/ui/MainViewRuntime.gd`.
- Verification after tracked source deletion:
  - `powershell -NoProfile -ExecutionPolicy Bypass -File tools/invoke-godot.ps1 -ProjectPath app-LTL -Headless -Script tests/run_test_ui_read_models.gd` -> `UI_READ_MODEL_TESTS_OK`
  - `powershell -NoProfile -ExecutionPolicy Bypass -File LTL-harness/tools/source-map-gate.ps1` -> `SOURCE_MAP_GATE_OK`
  - `powershell -NoProfile -ExecutionPolicy Bypass -File tools/run-compile-check.ps1` -> `Compilation Check: PASSED (GODOT_CONTRACTS_OK)`
- Generated residue cleanup after tracked-source verification:
  - Deleted `app-LTL/.godot/`, `.godot-user/`, `.tmp-godot-crash-probe/`, `.tmp-godot-logs/`, and root reward/Godot log files.
  - Confirmed each generated residue path is now missing.
  - Re-ran `LTL-harness/tools/source-map-gate.ps1` after generated cleanup -> `SOURCE_MAP_GATE_OK`.
  - Did not rerun Godot after generated cleanup because Godot would recreate `app-LTL/.godot/`; the full Godot verification immediately preceded generated cleanup.

Defer for a later internal-ownership pass:

- `app-LTL/prototype/**`: preserved by user decision.
- `docs/comment-gates/backups/**`: separate archive decision needed.
- `NodeMapScene.gd`, `NodeMapScene.tscn`, `NodeMapReadModel.gd`: still runtime/test-wired; node-select ownership proof must come first.
- `Main.tscn` app-shell nodes: still partly active or contract-referenced; classify per-node before edits.
- Codex F8/debug-all reveal path: spans controller, UI, read model, i18n, and tests; remove only as a single explicit debug-feature decision.

## Task 1: Freeze The Live Debug Boundary

**Files:**
- Read: `app-LTL/project.godot`
- Read: `app-LTL/src/Main.tscn`
- Read: `app-LTL/src/MainControllerRuntime.gd`
- Read: `app-LTL/src/ui/MainViewRuntime.gd`
- Read: `app-LTL/tests/run_main_start_flow_contract.gd`
- Read: `app-LTL/tests/run_page_scene_mapping_contract.gd`

- [ ] **Step 1: Confirm the project main scene**

Run:

```powershell
Select-String -Path 'app-LTL/project.godot' -Pattern 'run/main_scene'
```

Expected: `run/main_scene="res://src/Main.tscn"`.

- [ ] **Step 2: Confirm the live page registration list**

Run:

```powershell
rg -n "_register_page_scene|CharacterSelectPageScene|ClearPageScene" app-LTL/src/ui/MainViewRuntime.gd
```

Expected: all currently live debug pages are registered from `MainViewRuntime.gd`.

- [ ] **Step 3: Confirm the live page flow proof**

Run:

```powershell
rg -n "active_page_id|character_select|leviathan_select|node_select|battle|reward|defeat" app-LTL/tests/run_main_start_flow_contract.gd
```

Expected: the contract explicitly proves the live debug flow through the current page set.

## Task 2: Delete Class A Generated Residue First

**Files:**
- Delete after approval: Class A paths
- Test: `git status --short`

- [ ] **Step 1: Ask for deletion approval for Class A**

Approval set:

```text
app-LTL/.godot/
.godot-user/
.tmp-godot-crash-probe/
.tmp-godot-logs/
godot-contracts.log
reward-ceremony-contract.log
reward-ceremony-red2.log
reward-ceremony-red3.log
```

Expected: explicit user approval before deletion.

- [ ] **Step 2: Delete the approved generated residue**

Run only after approval:

```powershell
Remove-Item -LiteralPath 'app-LTL\.godot' -Recurse -Force
Remove-Item -LiteralPath '.godot-user' -Recurse -Force
Remove-Item -LiteralPath '.tmp-godot-crash-probe' -Recurse -Force
Remove-Item -LiteralPath '.tmp-godot-logs' -Recurse -Force
Remove-Item -LiteralPath 'godot-contracts.log' -Force
Remove-Item -LiteralPath 'reward-ceremony-contract.log' -Force
Remove-Item -LiteralPath 'reward-ceremony-red2.log' -Force
Remove-Item -LiteralPath 'reward-ceremony-red3.log' -Force
```

Expected: only ignored/generated residue disappears; tracked source files remain untouched.

- [ ] **Step 3: Verify no tracked source damage**

Run:

```powershell
git status --short
```

Expected: no unexpected tracked-source deletions.

## Task 3: Preserve Prototype And Mark Runtime Boundary

**Files:**
- Keep: `app-LTL/prototype/**`
- Modify during execution if needed: `docs/source-map.md`, relevant docs/tests that imply prototypes are active runtime

- [ ] **Step 1: Reconfirm prototypes are not in the live runtime**

Run:

```powershell
rg -n "prototype/godot-p0|PrototypeMain|prototype/browser-p0-p4|browser-p0-p4" app-LTL/src app-LTL/tests app-LTL/project.godot
```

Expected: no runtime or project entry references; only doc/test-only references are acceptable.

- [ ] **Step 2: Record the prototype keep policy**

Required policy:

```text
app-LTL/prototype/** is preserved reference material.
It is not part of the current debug runtime.
It is not a cleanup deletion target in this pass.
```

Expected: source-map/worklog wording no longer mixes prototype files with live runtime ownership.

- [ ] **Step 3: Treat non-prototype archives separately**

Run:

```powershell
rg -n "docs/comment-gates/backups|comment-gates/backups" docs app-LTL
```

Expected: `docs/comment-gates/backups/**` gets its own approval decision. Do not bundle it with prototype retention or runtime source cleanup.

## Task 4: Remove Class D File-Level Legacy Or Dead Residue

**Files:**
- Candidate delete after approval: `app-LTL/src/ui/legacy/LegacyRewardRevealOverlay.gd`
- Candidate delete after approval: `app-LTL/src/data/rarity-table.json`
- Optional candidate set: `app-LTL/tests/inspect_img.gd`, `app-LTL/resources/UI/backpack.png`, `app-LTL/resources/UI/backpack.png.import`

- [ ] **Step 1: Reconfirm legacy helper is test-only**

Run:

```powershell
rg -n "LegacyRewardRevealOverlay|ui/legacy/LegacyRewardRevealOverlay.gd" app-LTL/src app-LTL/tests app-LTL/project.godot
```

Expected: references stay in tests only, not the live runtime. If deleting, remove the test requirement and source-map/doc inventory in the same wave.

- [ ] **Step 2: Reconfirm `rarity-table.json` is file-level dead residue only**

Run:

```powershell
rg -n "src/data/rarity-table.json|rarity-table.json" .
```

Expected: matches appear only in docs/worklog unless new runtime usage is intentionally introduced. Do not delete `RewardValidator` methods just because this JSON file is unused; validator methods still have inline test coverage.

- [ ] **Step 3: Decide whether `backpack.png` is archival source art or dead residue**

Run:

```powershell
rg -n "inspect_img.gd|backpack.png" app-LTL/src app-LTL/tests docs
```

Expected: only diagnostic or documentation references remain. If the team still wants the atlas as art source, keep it; otherwise delete it together with `inspect_img.gd`.

## Task 5: Internal Cleanup Wave 1 - Node Select Ownership

**Files:**
- Primary: `app-LTL/src/ui/MainViewRuntime.gd`
- Primary: `app-LTL/src/Main.tscn`
- Candidate delete after ownership proof: `app-LTL/src/scenes/node_map/NodeMapScene.gd`
- Candidate delete after ownership proof: `app-LTL/src/scenes/node_map/NodeMapScene.tscn`
- Candidate delete after ownership proof: `app-LTL/src/ui/read_models/NodeMapReadModel.gd`
- Test updates: `app-LTL/tests/godot_contract_runner.gd`, `app-LTL/tests/test_node_map_scene_smoke.gd`, `app-LTL/tests/run_node_map_scene_smoke.gd`, layout/probe tests that still call `node_map_scene`

- [ ] **Step 1: Prove which node-select owner should remain**

Run:

```powershell
rg -n "node_map_scene|NodeMapScene|NodeMapReadModel|node_select_map_host|nodeMapFullPage|legacy_node_map" app-LTL/src app-LTL/tests
```

Expected: all references are classified as one of:

```text
keep: current node-select page implementation
migrate: behavior needed by current NodeSelectRuntimePage
delete: retired standalone node-map surface, read model, or test probe
```

- [ ] **Step 2: Add or update a contract that proves node-select works without the legacy map**

Required proof before deletion:

```text
- node_select page opens from the live start flow.
- available node choices remain visible/clickable.
- color/loadout interactions still work if they are part of the current page.
- layout audit no longer expects or tolerates a detached legacy_node_map.
```

Expected: the contract names the current page owner rather than testing `node_map_scene` directly.

- [ ] **Step 3: Remove the legacy map wiring from `MainViewRuntime.gd`**

Candidate internal deletions:

```text
NodeMapReadModelScript
NodeMapSceneScript
node_map_scene
node_select_map_host
_create_node_map_scene()
node_map_scene.visible/render/rerender_current_model branches
SharedBackpackHostCoordinator node_map_scene and node_select_map_host parameters if no longer needed
```

Expected: `MainViewRuntime.gd` no longer instantiates or renders the standalone node-map scene.

- [ ] **Step 4: Delete retired map files only after compile/contracts pass**

Delete only after Step 1-3 pass:

```text
app-LTL/src/scenes/node_map/NodeMapScene.gd
app-LTL/src/scenes/node_map/NodeMapScene.tscn
app-LTL/src/ui/read_models/NodeMapReadModel.gd
app-LTL/tests/test_node_map_scene_smoke.gd
app-LTL/tests/run_node_map_scene_smoke.gd
```

Expected: no remaining `rg` references except historical worklog/docs.

## Task 6: Internal Cleanup Wave 2 - `Main.tscn` App-Shell Residue

**Files:**
- Primary: `app-LTL/src/Main.tscn`
- Primary: `app-LTL/src/ui/MainViewRuntime.gd`
- Related tests: main layout, viewport, character-select cleanup, reward claim board, backpack layout suites

- [ ] **Step 1: Classify each old app-shell node**

Run:

```powershell
rg -n "LeftSidebar|RightSidebar|RepairOverlay|ConfirmOverlay|SettingsPanel|ParticleTemplate|ActionBar|GridMock" app-LTL/src/Main.tscn app-LTL/src app-LTL/tests
```

Classification rules:

```text
keep: current debug runtime still needs the node exactly where it is
migrate: behavior belongs inside a dedicated page/UI owner before deletion
delete: no runtime owner, no contract requirement, no user-facing effect
rename: active node has a misleading legacy/mock name but should remain
```

Expected initial classification:

```text
GridMock: active backpack grid despite misleading name; rename later, do not delete first.
SettingsPanel: active if settings still open from runtime; keep unless settings are intentionally removed.
ActionBar/RepairOverlay/ConfirmOverlay: likely active transition/repair controls; verify before touching.
ParticleTemplate: likely delete or migrate candidate; verify references and visual behavior first.
LeftSidebar/RightSidebar: possible shell-trim candidates only after page scenes own all side-panel content.
```

- [ ] **Step 2: Remove only proven-dead node subtrees**

Expected: `.tscn` edits are paired with `MainViewRuntime.gd` onready/callback cleanup. Never delete a node while an onready path or contract still expects it.

- [ ] **Step 3: Rename active misleading nodes in a separate wave**

Expected: if `GridMock` remains active, rename it only with a targeted contract update. Do not mix renames with behavior deletion.

## Task 7: Internal Cleanup Wave 3 - Stale Fields And Debug-Only Paths

**Files:**
- `app-LTL/src/ui/MainViewRuntime.gd`
- `app-LTL/src/MainControllerRuntime.gd`
- `app-LTL/src/ui/ArtifactCodexPanelUI.gd`
- `app-LTL/src/ui/read_models/ArtifactCodexReadModel.gd`
- `app-LTL/src/data/i18n/text-ko.json`
- `app-LTL/src/data/i18n/text-en.json`
- related read-model and reward/codex tests

- [ ] **Step 1: Delete stale shop fields if still unreferenced**

Run:

```powershell
rg -n "current_shop_state|shop_buttons|shop_gold_label|shop_labels|shop_xp_label" app-LTL/src app-LTL/tests
```

Expected: if references remain only as field declarations in `MainViewRuntime.gd`, remove those declarations. Do not touch `ShopPanelUI.gd` or active shop behavior.

- [ ] **Step 2: Decide whether to keep or remove the Codex debug reveal feature**

Run:

```powershell
rg -n "codex_force|CODEX_FORCE|debug_all|current_codex_debug_all|log\.debug\.codex|codex\.debug_all" app-LTL/src app-LTL/tests
```

Options:

```text
Option A: Keep as an intentional dev-only feature and document it.
Option B: Remove from main runtime and tests because it is not player-facing implementation.
Option C: Move behind a dedicated debug/dev build guard if Godot project conventions support it.
```

Expected: no partial removal. The key input, controller state, view flag, checkbox UI, read-model flag, i18n strings, and tests move together.

- [ ] **Step 3: Keep low-reference callbacks until signal ownership is proven**

Expected: do not delete methods solely because `rg` finds few references. GDScript signal connections and `Callable` hookups can be intentionally low-reference.

## Task 8: Verification After Each Deletion Wave

**Files:**
- Verify: live runtime and contract surfaces

- [ ] **Step 1: Re-run the live runtime flow contract**

Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools/invoke-godot.ps1 -ProjectPath app-LTL -Headless -Script tests/run_main_start_flow_contract.gd
```

Expected: `MAIN_START_FLOW_CONTRACT_OK`.

- [ ] **Step 2: Re-run the layout audit**

Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools/invoke-godot.ps1 -ProjectPath app-LTL -Headless -Script tests/run_main_layout_audit_contract.gd
```

Expected: `MAIN_LAYOUT_AUDIT_CONTRACT_OK`.

- [ ] **Step 3: Re-run the read-model and compile proofs**

Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools/invoke-godot.ps1 -ProjectPath app-LTL -Headless -Script tests/run_test_ui_read_models.gd
powershell -NoProfile -ExecutionPolicy Bypass -File tools/run-compile-check.ps1
```

Expected: `UI_READ_MODEL_TESTS_OK` and `Compilation Check: PASSED (GODOT_CONTRACTS_OK)`.

## Plan Outcome

- At the end of this plan, the repository should have one explicit live-runtime keep boundary, one explicit generated-residue delete set, one explicit prototype preservation policy, one separate non-prototype archive decision, and one task-by-task path for removing unnecessary `.gd`/`.tscn` internals without breaking the debug run.
- Class A means generated local residue only: cache, temp folders, import/editor output, and logs. It does not mean source, prototype, or design-history files.
- Prototype files are preserved unless the user gives a future explicit deletion instruction.
- This plan supersedes the older broad cleanup assumptions from `docs/superpowers/plans/2026-05-29-source-cleanup-deletion-plan.md` wherever the current audit shows the runtime boundary has changed.
