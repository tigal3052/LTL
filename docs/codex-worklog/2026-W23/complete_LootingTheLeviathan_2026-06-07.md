# Codex Worklog Completion

Workspace: LootingTheLeviathan
Date: 2026-06-07

## Completion Summary

Implemented the live M6 UI/UX refresh in the Godot runtime, integrated the provided character and leviathan art into the playable flow, completed the page-scene split after review feedback, repaired the final run-start contract failure by rebuilding the live `character_select` page to the approved wireframe while hardening layout precedence and regression checks, and then finished with a focused `leviathan_select` CTA refinement so `Looting Start` reads clearly as the next step.

## Actual Outputs

- `app-LTL/src/MainControllerRuntime.gd`
- `app-LTL/src/ui/MainViewRuntime.gd`
- `app-LTL/src/ui/CombatScenePreviewController.gd`
- `app-LTL/src/ui/presenters/PhaseLayoutPresenter.gd`
- `app-LTL/src/ui/read_models/HudReadModel.gd`
- `app-LTL/src/ui/read_models/FailureReadModel.gd`
- `app-LTL/src/scenes/pages/CharacterSelectPage.gd`
- `app-LTL/src/scenes/pages/CharacterSelectPage.tscn`
- `app-LTL/src/scenes/pages/LeviathanSelectPage.gd`
- `app-LTL/src/scenes/pages/LeviathanSelectPage.tscn`
- `app-LTL/src/scenes/pages/OutcomePage.gd`
- `app-LTL/src/scenes/pages/OutcomePage.tscn`
- `app-LTL/src/scenes/pages/StageBackdropPage.gd`
- `app-LTL/src/scenes/pages/StageBackdropPage.tscn`
- `app-LTL/src/scenes/pages/NodeSelectPage.gd`
- `app-LTL/src/scenes/pages/NodeSelectPage.tscn`
- `app-LTL/src/scenes/pages/BattlePage.tscn`
- `app-LTL/src/scenes/pages/BossBattlePage.tscn`
- `app-LTL/src/scenes/pages/RewardPage.tscn`
- `app-LTL/src/scenes/pages/BossRewardPage.tscn`
- `app-LTL/src/scenes/pages/EventNodePage.tscn`
- `app-LTL/src/scenes/pages/DefeatPage.tscn`
- `app-LTL/src/scenes/pages/ClearPage.tscn`
- `app-LTL/tests/run_main_start_flow_contract.gd`
- `app-LTL/tests/run_main_layout_audit_contract.gd`
- `app-LTL/tests/run_page_scene_mapping_contract.gd`
- `app-LTL/tests/test_start_option_contract.gd`
- `app-LTL/tests/test_ui_read_models.gd`
- `docs/source-map.md`
- `docs/codex-worklog/plan_LootingTheLeviathan_2026-06-07.md`
- `docs/codex-worklog/history_LootingTheLeviathan_2026-06-07.md`
- `docs/codex-worklog/complete_LootingTheLeviathan_2026-06-07.md`

## Changes From Plan

- The original June 7 plan targeted the broader live M6 runtime refresh and art integration first, then expanded again after review feedback to require explicit scene-per-page coverage instead of only phase-driven overlays.
- The existing battle and reward runtime composition was intentionally preserved rather than rebuilt from scratch; new page scenes were layered as visible shells so the stable combat layout stayed intact while the broken or missing pages were replaced.
- The final clear page was implemented as a temporary minimal outcome scene with only clear messaging and a return path to character select, matching the requested stopgap scope.
- After visual review against `docs/mockups/m6-run-start-wireframe.html`, the work expanded one more time because the live start page was only a placeholder and the old node-select layout was still leaking through meta pages under certain `phase` values.
- The final follow-up moved recurrence prevention into the harness itself, because fixing only the runtime page left too much room for future mockup-to-scene drift.
- The last pass on June 7 narrowed to the `leviathan_select` CTA itself, replacing the small footer button with a taller staged action block and adding explicit viewport containment proof for that page.
- The final same-day follow-up narrowed once more to the `node_select` shell after visual review showed the leviathan handoff still rendered through the shared backdrop scene instead of a dedicated route-board page.

## Root Cause Analysis

- The approved run-start mockup contract was never actually implemented in the runtime `CharacterSelectPage`; the shipped scene was a simpler placeholder shell.
- `app-LTL/src/ui/presenters/PhaseLayoutPresenter.gd` treated the gameplay `phase` as equal or stronger than the explicit `pageId`, so `phase == node_select` could reopen node-select panels even when the visible page should have been `character_select` or `leviathan_select`.
- `app-LTL/src/ui/MainViewRuntime.gd` kept the legacy phase content active behind page shells, which made the presenter mistake visible as a broken composite screen instead of a fully isolated meta page.
- The regression suite only verified scene existence and page-flow ids, not visual isolation rules such as header suppression and node-select panel hiding on start/meta pages.
- `app-LTL/src/scenes/pages/NodeSelectPage.tscn` was still just an instance of the generic `StageBackdropPage` shell, so even the correct `node_select` route could still look like a recycled selection page instead of the approved roadmap page.

## Prevention Measures

- Layout visibility now treats explicit `pageId` as authoritative, with fallback-to-`phase` behavior only for callers that do not provide a page id.
- Meta pages such as character select, leviathan select, clear, and defeat now explicitly control shell/header visibility and page layering so old phase panels cannot sit on top.
- The live `character_select` scene was rebuilt around the mockup contract structure itself: narrow left roster, central hero board, right start-color and backpack prep, and a dedicated CTA handoff to leviathan select.
- `run_page_scene_mapping_contract.gd` now checks run-start scene structure instead of only checking that a `.tscn` file exists and instantiates.
- `run_page_scene_mapping_contract.gd` now also checks that node select exposes dedicated roadmap-shell nodes, preventing future fallbacks to the generic stage-backdrop scene.
- `run_main_start_flow_contract.gd` and `test_ui_read_models.gd` now assert that legacy node-select UI stays hidden on meta pages, turning this exact regression into a failing test next time.
- `LTL-harness/tools/page-contract-gate.ps1` now turns those runtime assertions into a blocking harness gate, and both `tools/run-compile-check.ps1` and `tools/run-ltl-quality-gate.ps1` now include that gate in their verification path.
- `LTL-harness/docs/page-contract-execution-gate.md` and the `Page Contract Gate Addendum` in `LTL-harness/00_AGENTS.md` now make the build rule explicit: mockup-backed pages need scene ownership, contract coverage, and hidden legacy-surface proof before completion.

## Verification Results

- `powershell -NoProfile -ExecutionPolicy Bypass -File LTL-harness/tools/page-contract-gate.tests.ps1` -> `PAGE_CONTRACT_GATE_TESTS_OK`
- `powershell -NoProfile -ExecutionPolicy Bypass -File LTL-harness/tools/page-contract-gate.ps1 -Root D:\Programming\ex_workspace\LootingTheLeviathan` -> `PAGE_CONTRACT_GATE_OK`
- `powershell -NoProfile -ExecutionPolicy Bypass -File ..\tools\invoke-godot.ps1 -Headless -Script tests/run_page_scene_mapping_contract.gd -Quit` -> `PAGE_SCENE_MAPPING_CONTRACT_OK`
- `powershell -NoProfile -ExecutionPolicy Bypass -File ..\tools\invoke-godot.ps1 -Headless -Script tests/run_main_start_flow_contract.gd -Quit` -> exit `0`
- `powershell -NoProfile -ExecutionPolicy Bypass -File ..\tools\invoke-godot.ps1 -Headless -Script tests/run_start_option_contract.gd -Quit` -> `START_OPTION_CONTRACT_OK`
- `powershell -NoProfile -ExecutionPolicy Bypass -File ..\tools\invoke-godot.ps1 -Headless -Script tests/run_test_ui_read_models.gd -Quit` -> `UI_READ_MODEL_TESTS_OK`
- `powershell -NoProfile -ExecutionPolicy Bypass -File ..\tools\invoke-godot.ps1 -Headless -Script tests/run_main_layout_audit_contract.gd -Quit` -> exit `0` with the leviathan-select CTA containment assertions included
- `powershell -NoProfile -ExecutionPolicy Bypass -File ..\tools\run-compile-check.ps1` -> `SOURCE_MAP_GATE_OK`, `GODOT_CONTRACTS_OK`, `Compilation Check: PASSED (GODOT_CONTRACTS_OK)`
- `powershell -NoProfile -ExecutionPolicy Bypass -File tools/run-ltl-quality-gate.ps1 -RequestLedger docs/request-ledgers/2026-06-07-page-contract-harness-hardening.md -ArtifactLedger docs/artifact-ledgers/2026-06-07-page-contract-harness-hardening.md` -> blocked by the pre-existing `warning-refactor-gate` architectural finding on `app-LTL/src/ui/StatusPanelUI.gd`

## Blockers Or Unverified Areas

- No blocking failures remained after the page-scene split and flow-contract updates.
- A fresh live-window screenshot-based QA pass was completed for the `node_select` handoff, so that page no longer depends on stale headless capture evidence.
- The broader quality gate still has an unrelated blocking architectural debt in `StatusPanelUI.gd`, so this follow-up closes the page-contract recurrence gap but does not also clear every existing repository-wide gate.

## Remaining Gaps

- Godot still emits shutdown-time leak warnings and editor-settings save warnings in the verification harness, but those warnings did not cause any contract failure in this pass.
- One anchor-layout warning still appears during compile verification and is worth a quick manual pass in the editor even though the runtime checks passed.
- Full-flow manual playthrough evidence still centers on the refreshed `node_select` handoff capture rather than every page in the June 7 M6 pass.

## Addendum: Defeat Page Follow-up

- The live `defeat` route had still been rendering the legacy `repair_overlay`, which is why the page looked like a fixed golem background instead of the selected leviathan outcome page.
- `StatusPanelUI.render_repair_overlay()` now respects `visible=false`, and `MainViewRuntime.gd` now keeps the overlay backdrop synced to the selected leviathan art whenever that overlay is legitimately shown.
- New focused regression coverage now checks that `defeat` hides the legacy repair overlay, uses the selected leviathan art path, and keeps the dedicated defeat page inside the viewport contract.
- Verification passed for:
  - `run_test_ui_read_models.gd`
  - `run_main_start_flow_contract.gd`
  - `run_main_layout_audit_contract.gd`
  - `run_page_scene_mapping_contract.gd`
- `run-compile-check.ps1` now passes again after the source-map entries for the temporary probes and current containment ledger were restored.

## Addendum: Node Select Shell Follow-up

- The leviathan handoff itself was already routing to `node_select`; the remaining visual regression was that the visible page shell still came from the shared `StageBackdropPage` placeholder instead of a dedicated route-board scene.
- Added `app-LTL/src/scenes/pages/NodeSelectPage.gd` plus a new `NodeSelectPage.tscn` structure with a board header, roadmap frame, staged rows, and active-pick note so the page now reads as a route-selection board rather than another selection page.
- `MainViewRuntime.gd` now applies a lighter glass treatment to `node_select_panel` while the route board is active so the dedicated shell can read through the preserved live node-map composition.
- Verification passed for:
  - `run_page_scene_mapping_contract.gd`
  - `run_main_start_flow_contract.gd`
  - `run_test_ui_read_models.gd`
  - `run_main_layout_audit_contract.gd`
  - `run-compile-check.ps1`

## Addendum: Battle Containment Follow-up

- The direct battle page was still exceeding the canonical desktop viewport because `TopContent` let the combat backpack scale from an unconstrained row height and `QueueHintLabel` was mounted inside the queue `HBox`, wrapping into a tall vertical strip that inflated the status column's minimum height.
- Restored the missing `app-LTL/src/scenes/pages/NodeSelectPage.tscn` preload dependency so `MainViewRuntime.gd` and `Main.tscn` compile again before layout verification.
- `StatusPanelUI.gd` now mounts `QueueHintLabel` under the queue hub instead of beside it, preventing one-character-per-line wrapping from forcing the battle HUD taller than the screen.
- `MainViewRuntime.gd` now caps the combat backpack against viewport-safe top-content height and width budgets and trims the live top-left combat column gap from `16` to `12` while the combat/reward top row is active, which keeps the header, top row, battlefield, and action bar inside `1440x900`.
- Added `app-LTL/tests/run_combat_layout_containment_contract.gd` as a focused regression contract that bypasses the unstable start-page flow, renders a direct battle snapshot, and asserts that all major battle surfaces stay inside the viewport.
- Verification passed for:
  - `powershell -NoProfile -ExecutionPolicy Bypass -File D:\Programming\ex_workspace\LootingTheLeviathan\tools\invoke-godot.ps1 -Headless -Script tests/run_combat_layout_containment_contract.gd`
- Remaining scope limits:
  - `run_main_layout_audit_contract.gd` still fails because of broader `character_select` / meta-page / start-flow regressions that were explicitly left to the other session handling root cause work.

## Addendum: Character Select Containment Harness Follow-up

- The recurring full-screen overflow was not just a bad `character_select` minimum height. The deeper cause was that a mockup-backed meta page could still be mounted under a reduced gameplay shell unless the runtime explicitly split hosts and the harness proved that ownership.
- The second half of the failure was vertical-budget drift: the page used a tall stacked board with hero art, palette cards, bag preview, and CTA, but the harness had no rule requiring a scroll region or adaptive compaction once the page's minimum height exceeded the 1440x900 baseline.
- `app-LTL/tests/run_main_layout_audit_contract.gd` now asserts page-shell ownership directly:
  - `character_select`, `leviathan_select`, and `defeat` must mount under `meta_page_shell_host`
  - `node_select` must mount under `page_shell_host`
  - the active host must stay inside the viewport while the inactive host stays hidden
- `LTL-harness/docs/page-contract-execution-gate.md` and the `Page Contract Gate Addendum` in `LTL-harness/00_AGENTS.md` now require every mockup-backed page to declare `viewport_meta` or `phase_scoped`, prove `page -> owning host -> viewport` containment, and provide explicit scroll/compaction when vertical minimums can exceed the baseline viewport.
- Verification passed for:
  - `powershell -NoProfile -ExecutionPolicy Bypass -File tools/invoke-godot.ps1 -WorkspaceRoot D:\Programming\ex_workspace\LootingTheLeviathan -ProjectPath app-LTL -Script tests/run_main_layout_audit_contract.gd -Headless -Quit`
  - `powershell -NoProfile -ExecutionPolicy Bypass -File LTL-harness/tools/page-contract-gate.tests.ps1`
  - `powershell -NoProfile -ExecutionPolicy Bypass -File LTL-harness/tools/page-contract-gate.ps1 -Root D:\Programming\ex_workspace\LootingTheLeviathan`
  - `powershell -NoProfile -ExecutionPolicy Bypass -File tools/run-compile-check.ps1`

## Addendum: Character Select Cleanup Follow-up

- The live `character_select` page now matches the requested cleanup direction instead of the earlier scaffold-heavy presentation:
  - `출항 준비 페이지` -> `캐릭터 선택`
  - the long subtitle is hidden
  - the board helper header and `pre-combat setup only` pill are removed
  - selector / feature / prep helper hints are removed
  - the palette heading, bag heading, and CTA copy blocks are removed
  - the CTA lane now keeps only `레비아탄 선택으로`
- The missing settings affordance was a runtime-hosting issue, not a missing control asset: meta pages hide the legacy header, so the existing settings button disappeared with it. The fix was to inject a page-local `설정` button into `CharacterSelectPage` and wire it back into the shared settings overlay through `MainViewRuntime.gd`.
- The backpack preview now uses larger starter slots and an in-page hover detail card so the user can inspect starter relic details without relying on the browser mockup or combat tooltip flow.
- Verification passed for:
  - `powershell -NoProfile -ExecutionPolicy Bypass -File tools/invoke-godot.ps1 -WorkspaceRoot D:\Programming\ex_workspace\LootingTheLeviathan -ProjectPath app-LTL -Script tests/run_character_select_cleanup_contract.gd -Headless`
  - `powershell -NoProfile -ExecutionPolicy Bypass -File tools/invoke-godot.ps1 -WorkspaceRoot D:\Programming\ex_workspace\LootingTheLeviathan -ProjectPath app-LTL -Script tests/run_main_start_flow_contract.gd -Headless`
  - `powershell -NoProfile -ExecutionPolicy Bypass -File tools/invoke-godot.ps1 -WorkspaceRoot D:\Programming\ex_workspace\LootingTheLeviathan -ProjectPath app-LTL -Script tests/godot_contract_runner.gd -Headless -Editor -ScriptArgs '--smoke-only'`
- Remaining verification gap:
  - `tools/run-compile-check.ps1` is currently blocked by an unrelated source-map ledger failure for missing `docs/mockups/2026-06-07-leviathan-cta-directions.html`, so the UI change itself is verified by focused Godot contracts plus smoke compilation rather than the full repository gate.

## Addendum: Character Select Starter-Data Follow-up

- The `character_select` CTA copy is now shortened from `레비아탄 선택으로` to `레비아탄 선택`, matching the reduced CTA shell and the user's latest wording request.
- The right-side starter palette now spends the reclaimed empty column height on the actual loadout list instead of a compressed scroll lane:
  - palette rows now show the real starter drill and beacon pair for each color
  - each row surfaces live in-game values such as drill damage, drill cooldown, beacon cooldown, beacon cooldown delta, and beacon damage bonus
  - the vertical scrollbar no longer appears at the canonical 1440x900 contract size
- The backpack hover detail card is now data-driven as well, so hovering the first and second starter slots shows the selected color's real starter drill and starter beacon details instead of placeholder flavor text.
- Verification passed for:
  - `powershell -NoProfile -ExecutionPolicy Bypass -File tools/invoke-godot.ps1 -WorkspaceRoot D:\Programming\ex_workspace\LootingTheLeviathan -ProjectPath app-LTL -Script tests/run_character_select_cleanup_contract.gd -Headless`
  - `powershell -NoProfile -ExecutionPolicy Bypass -File tools/invoke-godot.ps1 -WorkspaceRoot D:\Programming\ex_workspace\LootingTheLeviathan -ProjectPath app-LTL -Script tests/run_main_start_flow_contract.gd -Headless`
  - `powershell -NoProfile -ExecutionPolicy Bypass -File tools/invoke-godot.ps1 -WorkspaceRoot D:\Programming\ex_workspace\LootingTheLeviathan -ProjectPath app-LTL -Script tests/godot_contract_runner.gd -Headless -Editor -ScriptArgs '--smoke-only'`
- Remaining verification gap:
  - `tools/run-compile-check.ps1` still stops at a pre-existing source-map gate failure unrelated to this starter-data UI follow-up.

## Addendum: Live Launch Verification Correction

- The earlier same-day close-out overstated runtime confidence: the implemented headless contracts were real, but the manual window launch had not been verified as a clean game-runtime path and could still surface editor-specific warnings.
- The user's pasted log helped confirm that the problematic launch path was editor mode. That path has now been rechecked directly, and the previous `@EditorNode`, vanished-parent, and unicode warning burst no longer reproduces after the `Main.tscn` text normalization pass.
- Fresh verification now includes both automated contracts and explicit live startup checks:
  - `powershell -NoProfile -ExecutionPolicy Bypass -File tools/invoke-godot.ps1 -WorkspaceRoot D:\Programming\ex_workspace\LootingTheLeviathan -ProjectPath app-LTL -Editor -Quit`
  - `D:\Programming\godot_workspace\bin\Godot_v4.3-stable_win64_console.exe --path D:\Programming\ex_workspace\LootingTheLeviathan\app-LTL --quit-after 3`
  - `powershell -NoProfile -ExecutionPolicy Bypass -File tools/invoke-godot.ps1 -WorkspaceRoot D:\Programming\ex_workspace\LootingTheLeviathan -ProjectPath app-LTL -Script tests/run_character_select_cleanup_contract.gd -Headless`
  - `powershell -NoProfile -ExecutionPolicy Bypass -File tools/invoke-godot.ps1 -WorkspaceRoot D:\Programming\ex_workspace\LootingTheLeviathan -ProjectPath app-LTL -Script tests/run_main_start_flow_contract.gd -Headless`
- Remaining caveat:
  - `tools/run-compile-check.ps1` is still gated by the separate source-map failure path and was not the source of the live startup warning reported by the user.

## Addendum: Node Select Runtime Replacement Follow-up

- The earlier `node_select` fix was replaced with a cleaner runtime-page swap instead of layering more exceptions onto the reused selection page path.
- `app-LTL/src/scenes/pages/NodeSelectRuntimePage.gd` and `app-LTL/src/scenes/pages/NodeSelectRuntimePage.tscn` now own the node-select phase outright:
  - the live node map mounts into a dedicated `MapHost`
  - the shared backpack mounts into a dedicated `BackpackHost`
  - the page no longer depends on the old `NodeSelectPanel` overlay in `Main.tscn`
- `MainViewRuntime.gd` now routes `node_select` entirely through the new runtime page, and the legacy `NodeSelectPage.gd` / `NodeSelectPage.tscn` were removed after verification.
- Contracts were updated so regressions now fail on structure, not just routing:
  - `run_page_scene_mapping_contract.gd`
  - `run_main_start_flow_contract.gd`
  - `run_main_layout_audit_contract.gd`
  - `test_ui_read_models.gd`
  - `LTL-harness/tools/page-contract-gate.ps1`
- Verification passed for:
  - `powershell -NoProfile -ExecutionPolicy Bypass -File tools/run-compile-check.ps1`
  - `powershell -NoProfile -ExecutionPolicy Bypass -File LTL-harness/tools/page-contract-gate.ps1`
  - `powershell -NoProfile -ExecutionPolicy Bypass -File tools/capture-node-select-runtime.ps1`
  - `powershell -NoProfile -ExecutionPolicy Bypass -File tools/invoke-godot.ps1 -ProjectPath app-LTL -Headless -Script tests/run_node_select_visual_capture.gd -Quit` now fails fast with the deprecation warning instead of silently claiming screenshot success
- Manual in-app visual QA completed:
  - reviewed `app-LTL/test-artifacts/visual/node-select-runtime.png` captured from the live Godot window
  - confirmed the node-select runtime page renders cleanly under the header
  - confirmed the previous leviathan-select / reused-page bleed-through is gone
  - confirmed the live route board appears instead of the retired split map/backpack page
- Non-blocking follow-up note:
  - the page title (`Ossuary Tortoise`) and the internal node-map title (`OSSUARY TORTOISE`) are both visible, so there is still a small polish opportunity if the team wants a less redundant header stack.

## Addendum: Starter Selection Ratio Regression Follow-up

- The live `character_select` page had a second-stage layout bug after the starter palette refresh:
  - the initial page entered with an under-settled right-column height budget
  - clicking a starter color triggered another layout sync through the shared state update path
  - that later pass recomputed a larger palette height and expanded the whole board, which is why the page ratio visibly changed only after interaction
- The fix was not to freeze the page after selection, but to make the initial state settle the same way:
  - `CharacterSelectPage.gd` now requests a two-pass settled layout sync for startup, state application, resize, and CTA/palette refresh events
  - the right-side starter palette now uses compact live drill/beacon metric rows sized to the fixed prep-card budget instead of longer multi-line copy that fights the column height
- The focused cleanup contract was rebuilt as a clean UTF-8 script and now blocks on:
  - `캐릭터 선택` title and `설정` button presence
  - compact live starter drill/beacon metrics in the palette
  - `레비아탄 선택` CTA copy
  - starter-slot hover detail behavior
  - identical `board_shell`, `hero_stage`, and `palette_scroll` heights before and after choosing a different starter color
  - full-list visibility without a scrollbar both before and after selection
- Verification passed for:
  - `powershell -NoProfile -ExecutionPolicy Bypass -File tools/invoke-godot.ps1 -WorkspaceRoot D:\Programming\ex_workspace\LootingTheLeviathan -ProjectPath app-LTL -Script tests/run_character_select_cleanup_contract.gd -Headless`
  - `powershell -NoProfile -ExecutionPolicy Bypass -File tools/invoke-godot.ps1 -WorkspaceRoot D:\Programming\ex_workspace\LootingTheLeviathan -ProjectPath app-LTL -Script tests/run_main_start_flow_contract.gd -Headless`
  - `powershell -NoProfile -ExecutionPolicy Bypass -File tools/invoke-godot.ps1 -WorkspaceRoot D:\Programming\ex_workspace\LootingTheLeviathan -ProjectPath app-LTL -Editor -Quit`
- Remaining caveat:
  - a direct GUI runtime launch via `D:\Programming\godot_workspace\bin\Godot_v4.3-stable_win64_console.exe --path ... --quit-after 3` crashed with `signal 11` in this environment, so the ratio fix itself is verified by focused contracts and editor startup, not by a fresh clean GUI quit path.
