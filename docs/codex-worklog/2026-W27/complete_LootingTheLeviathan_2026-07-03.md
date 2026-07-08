# Codex Worklog Completion

Workspace: LootingTheLeviathan
Date: 2026-07-03

## Completion Summary

- Implemented the approved story-scene shared-frame system with minimal top chrome.
- Kept story flow/typewriter ownership in `StoryScenePage` while moving reusable story presentation into a dedicated `story_scene/` component and data-driven frame metadata.

## Actual Outputs

- Added `StorySceneFrame.gd`, `StorySceneFrame.tscn`, and `StorySceneFrameBits.gd` under `app-LTL/src/scenes/pages/story_scene/`.
- Refactored `StoryScenePage.gd` / `.tscn` so the page delegates visuals to the shared frame but preserves continue/skip/typewriter behavior.
- Extended `StorySceneReadModel.gd`, `StoryScene.gd`, `ReleaseContentVocab.gd`, and `story-scenes.json` with shared-frame metadata and validation.
- Updated story-scene-focused tests plus runtime contract coverage for the new frame paths and layout behavior.
- Added `docs/request-ledgers/2026-07-03-ui-001-story-scene-shared-frame.md` and refreshed `docs/source-map.md`.

## Changes From Plan

- The implementation stayed within the approved direction, but the reusable shell was delivered as one shared `StorySceneFrame` plus a small metadata helper instead of multiple frame variants.
- The repository-level `run-compile-check.ps1` wrapper could not be closed cleanly because its internal source-map freshness step stayed unstable in this workspace, so the underlying gates were run directly as substitute evidence.

## Verification Results

- `tools/invoke-godot.ps1 -ProjectPath app-LTL -Headless -Script res://tests/run_story_scene_runtime_contract.gd` passed with `STORY_SCENE_RUNTIME_CONTRACT_OK`.
- `LTL-harness/tools/request-analysis-gate.ps1 -Ledger docs/request-ledgers/2026-07-03-ui-001-story-scene-shared-frame.md -Mode pre-complete` passed with `REQUEST_ANALYSIS_GATE_OK`.
- `LTL-harness/tools/test-size-gate.ps1 -Root .` passed with `TEST_SIZE_GATE_OK` and legacy warnings only.
- `LTL-harness/tools/runtime-size-gate.ps1 -Root .` passed with `RUNTIME_SIZE_GATE_OK`.
- `LTL-harness/tools/page-contract-gate.ps1 -Root . -GodotPath D:\Programming\godot_workspace\bin\Godot_v4.3-stable_win64_console.exe` passed with `PAGE_CONTRACT_GATE_OK`.
- `LTL-harness/tools/transition-safety-gate.ps1 -Root . -GodotPath D:\Programming\godot_workspace\bin\Godot_v4.3-stable_win64_console.exe -Ledger docs/request-ledgers/2026-07-03-ui-001-story-scene-shared-frame.md` passed with `TRANSITION_SAFETY_GATE_OK`.
- `tools/invoke-godot.ps1 -ProjectPath app-LTL -Headless -Script res://tests/run_interaction_audio_runtime_contract.gd` still failed on pre-existing character-select starter-set assertions.
- `tools/invoke-godot.ps1 -ProjectPath app-LTL -Headless -Script res://tests/godot_contract_runner.gd` still failed on unrelated node-routing and locale/read-model baseline issues.

## Blockers Or Unverified Areas

- `tools/run-compile-check.ps1 -RequestLedger docs/request-ledgers/2026-07-03-ui-001-story-scene-shared-frame.md` could not be used as the final wrapper proof because its internal source-map freshness step behaved inconsistently in this workspace after repeated runs.
- A non-headless manual screenshot/visual review was not added in this turn; confidence comes from focused runtime/layout/page-contract coverage instead.
- Godot leak/anchor warnings still appear inside broader repo gates, but the blocking page/story gates returned `OK`.

## Remaining Gaps

- The unrelated baseline failures in `run_interaction_audio_runtime_contract.gd` and `godot_contract_runner.gd` remain outside this story-scene change.
- If future story screens need more than the current minimal shell, extend `StorySceneFrameBits` or add another frame capsule instead of regrowing `StoryScenePage`.

---

## Character-select Verdant Redesign (`UI-001`, `VERIFY-001`)

### Completion Summary

- Implemented the approved verdant character-select redesign and closed the final request-ledger, transition-safety, and runtime-size gates.
- Kept the onboarding handoff, selection flow, hidden mini-bag cache guard, and Leviathan-style shared top-bar behavior intact while externalizing copy and starter-item detail models.

### Actual Outputs

- Updated `CharacterSelectPage.gd` / `.tscn` to use the verdant three-column layout, center-footer continue CTA, click-selected starter-item details, and shared top-bar action routing.
- Extended `CharacterRosterLoader.gd`, `text-en.json`, and `text-ko.json` with data-backed `rosterLongCopy` and `heroLine` fields.
- Expanded `CharacterSelectLoadoutText.gd` into a starter-item model/detail provider and raised palette button height in `CharacterSelectPaletteView.gd`.
- Added `CharacterSelectViewBits.gd` and `CharacterSelectTopBar.tscn` so view-only card styling and the top-bar subtree can stay under runtime leaf-size limits without changing runtime behavior.
- Updated focused character-select contract coverage plus the request ledger and refreshed `docs/source-map.md`.

### Changes From Plan

- The shipped behavior stayed within the approved redesign plan, but the closeout needed one additional containment step: extracting view-only helpers and the top-bar subtree into character-select capsules after the final compile-check exposed the 500-line runtime-size gates.

### Verification Results

- `LTL-harness/tools/source-map-gate.ps1 -Root . -Refresh` passed with `SOURCE_MAP_GATE_OK`.
- `tools/project-objectives.ps1 -Mode validate` passed with `PROJECT_OBJECTIVE_GATE_VALIDATE_OK`.
- `LTL-harness/tools/runtime-size-gate.ps1 -Root .` passed with `RUNTIME_SIZE_GATE_OK`.
- `tools/invoke-godot.ps1 -ProjectPath app-LTL -Headless -Script res://tests/run_character_select_cleanup_contract.gd` passed with `CHARACTER_SELECT_CLEANUP_CONTRACT_OK`.
- `tools/invoke-godot.ps1 -ProjectPath app-LTL -Headless -Script res://tests/run_character_select_interaction_contract.gd` passed with `CHARACTER_SELECT_INTERACTION_CONTRACT_OK`.
- `tools/invoke-godot.ps1 -ProjectPath app-LTL -Headless -Script res://tests/run_page_scene_mapping_contract.gd` passed with `PAGE_SCENE_MAPPING_CONTRACT_OK`.
- `tools/invoke-godot.ps1 -ProjectPath app-LTL -Headless -Script res://tests/run_main_layout_audit_contract.gd` passed with `MAIN_LAYOUT_AUDIT_CONTRACT_OK`.
- `tools/invoke-godot.ps1 -ProjectPath app-LTL -Headless -Script res://tests/run_interaction_audio_runtime_contract.gd` passed with `INTERACTION_AUDIO_RUNTIME_CONTRACT_OK`.
- `tools/run-compile-check.ps1 -RequestLedger docs/request-ledgers/2026-07-03-ui-001-character-select-verdant-redesign.md` passed with `Compilation Check: PASSED (GODOT_CONTRACTS_OK)`.

### Blockers Or Unverified Areas

- Broad Godot/page-contract runs still print existing leak/resource warnings and the compile-check wrapper still reports legacy oversized-test warnings, but none of those warnings blocked the character-select closeout and the wrapper exited `0`.
- No non-headless manual screenshot pass was added in this closeout; confidence comes from the focused runtime/layout/interaction contracts plus the full compile-check wrapper.

### Remaining Gaps

- If the character-select surface grows another major prep subsystem, continue the same capsule approach instead of regrowing `CharacterSelectPage.gd` / `.tscn` past the runtime-size gates.
