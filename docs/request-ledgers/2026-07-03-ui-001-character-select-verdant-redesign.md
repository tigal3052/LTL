# 2026-07-03 UI-001 character-select verdant runtime redesign closeout

## Request Summary

- Execute `docs/superpowers/plans/2026-07-03-character-select-verdant-runtime-redesign.md` inline and ship the approved verdant character-select redesign.
- Align the page shell with the Leviathan-select top-menu pattern while keeping character-select flow ownership and current onboarding routing intact.
- Move long roster copy, center hero copy, and starter-item detail content into data-backed owners outside the page runtime.
- Replace the mini-bag-first prep interaction with click-selected starter-item details while keeping hidden scrollbar chrome and layout stability.
- Close the work with focused Godot contracts, source-map refresh, request-ledger proof, and compile-check evidence tied to `UI-001` and `VERIFY-001`.

## Preserved Invariants

- The existing `story_scene -> character_select` onboarding handoff remains the active entry path.
- `CharacterSelectPage` keeps current selection and continue-flow ownership instead of moving routing into another page or controller.
- The Leviathan-style top bar is adopted as a shared chrome pattern, but character art, backdrop ownership, and character-select-specific content remain in the character-select runtime/data surfaces.
- Long roster helper copy, hero line copy, and starter-item detail text stay editable outside `CharacterSelectPage.gd`.
- Hidden scrollbar chrome remains in place without removing scroll interaction.
- The hidden mini-bag texture cache path used by existing runtime guards remains available.
- Existing unrelated dirty worktree changes are not reverted.

## Mutable Scope

- `app-LTL/src/scenes/pages/CharacterSelectPage.gd`
- `app-LTL/src/scenes/pages/CharacterSelectPage.tscn`
- `app-LTL/src/scenes/pages/character_select/CharacterSelectLoadoutText.gd`
- `app-LTL/src/scenes/pages/character_select/CharacterSelectPaletteView.gd`
- `app-LTL/src/scenes/pages/character_select/CharacterSelectTopBar.tscn`
- `app-LTL/src/scenes/pages/character_select/CharacterSelectViewBits.gd`
- `app-LTL/src/controllers/run_flow/CharacterRosterLoader.gd`
- `app-LTL/src/data/i18n/text-en.json`
- `app-LTL/src/data/i18n/text-ko.json`
- `app-LTL/src/ui/main_view/MainViewPageShellRuntime.gd`
- `app-LTL/tests/run_character_select_cleanup_contract.gd`
- `app-LTL/tests/run_character_select_interaction_contract.gd`
- `app-LTL/tests/run_page_scene_mapping_contract.gd`
- `app-LTL/tests/run_main_layout_audit_contract.gd`
- `app-LTL/tests/run_interaction_audio_runtime_contract.gd`
- `docs/request-ledgers/2026-07-03-ui-001-character-select-verdant-redesign.md`
- `docs/source-map.md`

## Source Map Findings

- `docs/source-map.md`
  - The source map identifies the page/runtime/data/test owners touched by this redesign and had to be refreshed after the character-select layout and contract changes.
- `app-LTL/src/scenes/pages/CharacterSelectPage.gd`
  - This file remains the runtime owner for character-select layout, selection flow, CTA wiring, and hidden guard-path behavior.
- `app-LTL/src/scenes/pages/CharacterSelectPage.tscn`
  - This scene owns the concrete top-bar shell, center-footer CTA placement, starter-item list container, and right-detail panel node structure required by the redesign.
- `app-LTL/src/scenes/pages/character_select/CharacterSelectTopBar.tscn`
  - This capsule preserves the existing `TopBar/...` node contract while keeping the main page scene under the runtime leaf-size gate.
- `app-LTL/src/scenes/pages/character_select/CharacterSelectViewBits.gd`
  - This helper owns view-only card construction and styling details so the page runtime can stay under the runtime leaf-size gate without changing interaction flow.
- `app-LTL/src/scenes/pages/character_select/CharacterSelectLoadoutText.gd`
  - This helper is the correct owner for starter-item data models and copy so the page does not re-own detail strings.
- `app-LTL/src/controllers/run_flow/CharacterRosterLoader.gd`
  - This loader owns data projection from i18n character tables into roster-facing fields such as `rosterLongCopy` and `heroLine`.
- `app-LTL/src/data/i18n/text-en.json` and `app-LTL/src/data/i18n/text-ko.json`
  - The locale tables are the author-facing owners for long roster copy and hero-line text.
- `app-LTL/tests/run_character_select_cleanup_contract.gd` and `app-LTL/tests/run_character_select_interaction_contract.gd`
  - These focused runners are the primary proof surfaces for the structural and interaction-level redesign contract.

## Root Cause Review

- Observed symptom: the old character-select page still exposed a darker legacy shell with page-local copy ownership, a right-column continue CTA, and mini-bag/hover-first prep behavior that no longer matched the approved verdant redesign.
- Evidence: the initial RED pass in `res://tests/run_character_select_cleanup_contract.gd` failed on missing `TopBar`, `TabsRow`, roster `Body`, center-footer `ContinueButton`, and `StarterItemList`, and runtime inspection showed starter-detail content still depended on page-local prep widgets instead of external data-backed models.
- Root cause target: `app-LTL/src/scenes/pages/CharacterSelectPage.gd`
- Supporting surface: `app-LTL/src/scenes/pages/CharacterSelectPage.tscn`, `app-LTL/src/controllers/run_flow/CharacterRosterLoader.gd`, and `app-LTL/src/scenes/pages/character_select/CharacterSelectLoadoutText.gd` did not yet expose the approved shell/data boundaries.
- Rejected workaround: apply cosmetic styling over the legacy shell while keeping page-local copy ownership, the right-column CTA, and hover-driven mini-bag detail behavior.
- Chosen fix: rebuild the page around a Leviathan-style shared top bar, data-backed roster/hero copy, a center-footer continue CTA, a click-selected starter-item list, and a dedicated right-side detail panel while preserving hidden guard paths.

## Transition Safety Review

- touched transitions: `meta.start_flow`, `page.scene_mapping`
- entry owner: `app-LTL/src/controllers/MainControllerRenderFlow.gd` still owns the onboarding entry into `story_scene` and the return handoff into `character_select`.
- exit owner: `app-LTL/src/ui/main_view/MainViewPageShellRuntime.gd` still owns page mounting, page registration, and the outward signal contract exposed by `CharacterSelectPage`.
- risk: splitting view-only helpers and the top-bar subtree into capsules could have broken the `story_scene -> character_select` handoff or the path-based page contract if node names, mounted paths, or continue wiring drifted.
- runner: `app-LTL/tests/run_main_start_flow_contract.gd` covers `meta.start_flow`; `app-LTL/tests/run_page_scene_mapping_contract.gd` covers `page.scene_mapping`.
- marker: `MAIN_START_FLOW_CONTRACT_OK`, `PAGE_SCENE_MAPPING_CONTRACT_OK`.
- focused guard runner: `app-LTL/tests/run_character_select_cleanup_contract.gd`, `app-LTL/tests/run_character_select_interaction_contract.gd`
- focused guard marker: `CHARACTER_SELECT_CLEANUP_CONTRACT_OK`, `CHARACTER_SELECT_INTERACTION_CONTRACT_OK`

## Feature Unit Lifecycle Plan

- Design stage: keep the character-select redesign split between page shell ownership, roster/i18n projection, and starter-item detail models so the page does not re-absorb authoring data.
- Implementation stage: confine behavior changes to character-select runtime/layout/data surfaces and focused contracts instead of changing global routing or onboarding flow.
- Maintenance stage: future copy, hero-line, and starter-item detail edits should go through `CharacterRosterLoader.gd`, `CharacterSelectLoadoutText.gd`, and locale tables before changing page runtime code.
- Capsule boundary: `CharacterSelectPage` owns interaction/render wiring, loader/i18n surfaces own roster text, and loadout-text helpers own starter-item detail models.
- Size trigger: if the page adds another major prep subsystem or multiple shell variants, extract another dedicated character-select capsule instead of growing more conditional layout code inside `CharacterSelectPage.gd`.

## Refactor/Delete Disposition

- Keep `CharacterSelectPage` as the runtime owner and refactor its structure rather than replacing the page or moving flow control elsewhere.
- Keep the hidden mini-bag guard path in a non-visible state instead of deleting it outright because existing runtime protection still depends on that texture-cache surface.
- Keep existing onboarding, character selection, color selection, and continue-flow behavior intact.
- Do not delete current art/backdrop ownership or unrelated workspace edits in overlapping files.

## Verification Checklist

- Run `powershell -NoProfile -ExecutionPolicy Bypass -File LTL-harness/tools/source-map-gate.ps1 -Root . -Refresh`.
- Run `powershell -NoProfile -ExecutionPolicy Bypass -File tools/project-objectives.ps1 -Mode validate`.
- Run `powershell -NoProfile -ExecutionPolicy Bypass -File LTL-harness/tools/request-analysis-gate.ps1 -Ledger docs/request-ledgers/2026-07-03-ui-001-character-select-verdant-redesign.md -Mode pre-complete`.
- Run `powershell -NoProfile -ExecutionPolicy Bypass -File tools/invoke-godot.ps1 -ProjectPath app-LTL -Headless -Script res://tests/run_character_select_cleanup_contract.gd`.
- Run `powershell -NoProfile -ExecutionPolicy Bypass -File tools/invoke-godot.ps1 -ProjectPath app-LTL -Headless -Script res://tests/run_character_select_interaction_contract.gd`.
- Run `powershell -NoProfile -ExecutionPolicy Bypass -File tools/invoke-godot.ps1 -ProjectPath app-LTL -Headless -Script res://tests/run_page_scene_mapping_contract.gd`.
- Run `powershell -NoProfile -ExecutionPolicy Bypass -File tools/invoke-godot.ps1 -ProjectPath app-LTL -Headless -Script res://tests/run_main_layout_audit_contract.gd`.
- Run `powershell -NoProfile -ExecutionPolicy Bypass -File tools/invoke-godot.ps1 -ProjectPath app-LTL -Headless -Script res://tests/run_interaction_audio_runtime_contract.gd`.
- Run `powershell -NoProfile -ExecutionPolicy Bypass -File tools/run-compile-check.ps1 -RequestLedger docs/request-ledgers/2026-07-03-ui-001-character-select-verdant-redesign.md`.

## Verification Notes

- `LTL-harness/tools/source-map-gate.ps1 -Root . -Refresh` passed with `SOURCE_MAP_REFRESH_OK: docs/source-map.md` and `SOURCE_MAP_GATE_OK`.
- `tools/project-objectives.ps1 -Mode validate` passed with `Objectives validated: 26` and `PROJECT_OBJECTIVE_GATE_VALIDATE_OK`.
- `LTL-harness/tools/runtime-size-gate.ps1 -Root .` passed with `RUNTIME_SIZE_GATE_OK` after splitting view-only helpers and the top-bar subtree into dedicated character-select capsules.
- `tools/invoke-godot.ps1 -ProjectPath app-LTL -Headless -Script res://tests/run_character_select_cleanup_contract.gd` exited `0` and emitted `CHARACTER_SELECT_CLEANUP_CONTRACT_OK`.
- `tools/invoke-godot.ps1 -ProjectPath app-LTL -Headless -Script res://tests/run_character_select_interaction_contract.gd` exited `0` and emitted `CHARACTER_SELECT_INTERACTION_CONTRACT_OK`.
- `tools/invoke-godot.ps1 -ProjectPath app-LTL -Headless -Script res://tests/run_page_scene_mapping_contract.gd` exited `0` and emitted `PAGE_SCENE_MAPPING_CONTRACT_OK`.
- `tools/invoke-godot.ps1 -ProjectPath app-LTL -Headless -Script res://tests/run_main_layout_audit_contract.gd` exited `0` and emitted `MAIN_LAYOUT_AUDIT_CONTRACT_OK`.
- `tools/invoke-godot.ps1 -ProjectPath app-LTL -Headless -Script res://tests/run_interaction_audio_runtime_contract.gd` exited `0` and emitted `INTERACTION_AUDIO_RUNTIME_CONTRACT_OK`.
- The Godot runners above still print `ObjectDB instances leaked at exit` warnings in some runs, but the runners returned exit `0` and emitted their expected `*_OK` markers.
- `tools/run-compile-check.ps1 -RequestLedger docs/request-ledgers/2026-07-03-ui-001-character-select-verdant-redesign.md` passed with `Compilation Check: PASSED (GODOT_CONTRACTS_OK)` after the ledger transition review was updated to name `meta.start_flow` and `page.scene_mapping`.
- The compile-check wrapper still reports legacy test-size warnings and existing Godot leak/resource warnings inside broader page-contract coverage, but the wrapper finished with exit `0`.

## Resolution Proof

- RED proof: before the redesign landed, `res://tests/run_character_select_cleanup_contract.gd` failed on missing verdant-shell nodes such as `TopBar`, roster `Body`, center-footer `ContinueButton`, and `StarterItemList`.
- Root-cause proof: after rebuilding `CharacterSelectPage` and its scene/data surfaces around shared top chrome, externalized roster/hero copy, and click-selected starter-item details, the focused cleanup, interaction, mapping, layout, and interaction-audio contracts all returned `*_OK`.
- Workaround guard: the fix kept the hidden mini-bag cache path and existing onboarding/continue flow alive, proving the redesign was not masked by deleting guard surfaces or bypassing the original navigation contract.

## Artifact Ledger

- No separate artifact ledger is planned for this UI redesign; proof lives in this request ledger, the refreshed `docs/source-map.md`, focused Godot runners, and the shared Codex worklog.
