# Codex Worklog Plan

Workspace: LootingTheLeviathan
Date: 2026-07-03

## Active Work - Character-select implementation

Implement the approved character-select verdant runtime redesign from `docs/superpowers/plans/2026-07-03-character-select-verdant-runtime-redesign.md`, keeping current flow intact while moving the page onto the Leviathan-style top-menu shell and externalized data ownership.

## Request Summary - Character-select implementation

- Read the saved execution plan and execute it inline in this session.
- Upgrade the character-select page to the approved verdant three-column runtime redesign.
- Keep the top menu aligned with the already-implemented Leviathan-select page.
- Keep the existing character art/backdrop ownership and the current navigation/selection flow.
- Move long roster copy, hero short copy, and starter-set detail content out of the page script into external data/providers.
- Keep roster scrolling but hide visible scrollbar chrome.
- Replace the mini-bag hover model with a click-selected starter-item list plus a larger detail panel.
- Verify the focused contracts and the broad compile-check path.
- Honor repository rules by skipping the plan document's intermediate `git commit` steps.

## Objective Linkage - Character-select implementation

- Primary: `UI-001`
- Verification guard: `VERIFY-001`

## Scope - Character-select implementation

- Character-select runtime/layout ownership in `app-LTL/src/scenes/pages/CharacterSelectPage.gd`, `.tscn`, and focused helper/top-bar capsules under `app-LTL/src/scenes/pages/character_select/`
- Shared top-menu/chrome reuse from the Leviathan-select page
- Externalized character roster/hero copy data in the roster loader and i18n catalogs
- Externalized starter-item models and detail-copy provider logic
- Character-select contract updates, new focused interaction coverage, request ledger, and final verification

## Out of Scope - Character-select implementation

- Leviathan-select behavior changes unrelated to sharing the top-menu shell pattern
- New gameplay flow, reward/combat behavior, or art asset replacement
- Unrelated refactors outside the files touched by the saved execution plan
- Commits or pushes unless the user explicitly asks later

## Steps - Character-select implementation

1. Lock the new page contract red-first in `app-LTL/tests/run_character_select_cleanup_contract.gd`.
2. Externalize the character roster long-copy and hero-line fields through `CharacterRosterLoader` and the i18n catalogs.
3. Expand `CharacterSelectLoadoutText` into a starter-item model/detail provider and update the cleanup contract accordingly.
4. Rebuild `CharacterSelectPage.tscn` / `.gd` and the starter palette view around the verdant three-column layout plus Leviathan-style top bar.
5. Add the focused interaction contract for click-selected starter-item details and implement the stable selection behavior.
6. Add the request ledger, refresh supporting docs if needed, then run the focused runners and broad compile-check verification.

## Expected Outputs - Character-select implementation

- Updated character-select scene/runtime/scripts and localized data implementing the verdant redesign
- Updated cleanup contract plus new interaction contract for the starter-item detail model
- Verification ledger at `docs/request-ledgers/2026-07-03-ui-001-character-select-verdant-redesign.md`
- Objective-linked evidence for `UI-001` and `VERIFY-001`

## Verification Method - Character-select implementation

- TDD cycle per plan step: add or extend the relevant contract first, run it red, then implement minimally until green.
- Focused Godot runners:
  - `app-LTL/tests/run_character_select_cleanup_contract.gd`
  - `app-LTL/tests/run_character_select_interaction_contract.gd`
  - `app-LTL/tests/run_main_layout_audit_contract.gd`
  - `app-LTL/tests/run_page_scene_mapping_contract.gd`
- Broad verification:
  - `powershell -NoProfile -ExecutionPolicy Bypass -File tools/run-compile-check.ps1 -RequestLedger docs/request-ledgers/2026-07-03-ui-001-character-select-verdant-redesign.md`
- Supporting checks as needed:
  - source-map refresh/gate if mapped files change

## Plan Change Log - Character-select implementation

- 2026-07-03: Switched the character-select track from planning to inline implementation after the user requested execution of the saved plan.
- 2026-07-03: Recorded that the saved plan's commit steps are skipped in-session to honor repository rules while keeping the implementation and verification sequence intact.
- 2026-07-03: Added a runtime-size closeout step to split character-select view-only helpers and the reusable top-bar subtree out of the main page files after the final compile-check surfaced the 500-line runtime leaf gate.

## Active Work

Plan the character-select design upgrade before implementation, using the approved Verdant/Nature pivot direction plus the Stitch `stitch_ltl_charactor_select` reference while preserving current behavior and the Leviathan-select shared top menu contract.

## Request Summary

- Upgrade the character-select screen design.
- First produce a concrete code modification plan and wait for user approval before implementation.
- Use the mockup's left `탐험대 기록` idea to refine the left character roster and the mockup's right `첫 탐사 꾸러미` idea to refine the right prep area.
- Keep the top menu aligned with the already-implemented Leviathan select page.
- Treat the Stitch output as design-pattern reference only; do not copy its literal text or names.
- Preserve current working interactions and verify full-page plus per-component/per-motion behavior when implementation eventually happens.
- Preserve long supporting copy in the left roster, but move that copy out of the page script so each character can own editable text from character-managed data.
- Keep roster scrolling but hide the visible scrollbar chrome.
- Move right-side starter-set content into page-external data so each color set can be edited without hardcoding inside the page.
- Replace the mini backpack preview with a starter item list plus a click-selected detail panel; use click instead of hover as the primary detail interaction.
- Remove the right-side next-step CTA and use that lower space for a larger starter-item detail panel.
- Keep the center hero using the existing backdrop and character art, with the CTA, character name, and per-character short copy at the bottom.
- Ensure the center hero copy also comes from character-managed data rather than page-local hardcoding.

## Scope

- Character-select runtime ownership and layout strategy in `app-LTL/src/scenes/pages/CharacterSelectPage.gd` and `.tscn`
- Shared chrome/top-menu reuse or extraction strategy from Leviathan-select helpers
- Left roster styling, center hero-stage balance, and right prep-area structure/copy strategy
- Character-managed and starter-set-managed page data boundaries so roster text, hero copy, and starter-set details are editable outside the page owner
- Existing character-select contract coverage and what additional verification will be required during implementation
- Planning/spec artifacts for the approved implementation direction

## Out of Scope

- Any production implementation before explicit user approval
- Leviathan-select runtime changes unrelated to sharing or reusing its top-menu contract
- New gameplay behavior, data-model changes, or reward/combat flow changes
- Asset replacement outside what is already available in-project unless later explicitly approved

## Steps

1. Reconfirm project goals, objective linkage, relevant prior worklogs, and current runtime ownership for character/leviathan select.
2. Compare the current character-select runtime against the Stitch reference and existing Leviathan-select shell to identify reusable chrome versus page-specific redesign work.
3. Clarify any remaining layout ambiguity with the user one question at a time.
4. Propose 2-3 design/code-structure approaches with trade-offs and a recommendation.
5. Present the recommended design in approval-sized sections covering layout, component ownership, externalized content/data strategy, styling/theming, interaction behavior, and verification.
6. After user approval of the design, write the design/spec artifact and then create the detailed code modification plan tied to objective IDs.

## Expected Outputs

- Approved design direction for the character-select redesign
- A written design/spec document under `docs/superpowers/specs/`
- A detailed code modification plan for implementation after approval
- A saved implementation plan at `docs/superpowers/plans/2026-07-03-character-select-verdant-runtime-redesign.md`
- Objective linkage for this work, expected to include `UI-001` and `VERIFY-001`
- Externalized content-management approach for character roster text, hero copy, and starter-set item/detail content

## Verification Method

- Planning phase: static review of existing runtime files, tests, mockups, worklogs, and reference assets
- Implementation phase plan must include focused Godot runners for:
  - character-select page contract / cleanup contract
  - main layout containment
  - page-scene mapping / transition safety if shared chrome ownership changes
  - targeted interaction checks for click, hover, scroll, and stable layout under selection changes

## Plan Change Log

- 2026-07-03: Worklog bootstrapped automatically by Codex hook.
- 2026-07-03: Replaced the placeholder with the character-select redesign planning scope, constraints, and verification strategy.
- 2026-07-03: Expanded the planning scope after the user specified externalized roster/copy data, hidden roster scrollbar chrome, click-driven starter-item details, right-panel CTA removal, and center-bottom CTA retention.

---

## Additional Active Work - Story-scene redesign planning

### Request Summary

- Upgrade the story screen design using `.hermes/plans/2026-06-26_110716-ltl-verdant-ruins-sky-nature-design-pivot-v3-1-cross-reviewed.ko.md` plus `LTL-harness/new_design/stitch_ltl_story/` as the visual-direction reference.
- Change the story background and character presentation while building a reusable frame so developers can add story text and images easily.
- Treat the Stitch output as layout/style reference only; do not copy its literal text or names.
- Preserve current working behavior, including story routing, continue/skip flow, and per-step progression.
- Produce the code modification plan first, wait for user approval, and only then implement.
- The eventual implementation closeout must verify full-screen behavior plus per-component, per-motion, and interaction stability.

### Objective Linkage

- Primary: `UI-001`
- Verification guard: `VERIFY-001`
- Note: if the story-screen redesign scope remains long-lived, add a narrower story-screen objective instead of hiding it only in worklogs.

### Scope

- `StoryScenePage.gd` and `StoryScenePage.tscn` layout/theming/runtime surface
- Story-scene data authoring boundaries in `app-LTL/src/data/story-scenes.json`
- Story-scene projection and routing contracts in:
  - `app-LTL/src/ui/read_models/StorySceneReadModel.gd`
  - `app-LTL/src/controllers/MainControllerRenderFlow.gd`
  - `app-LTL/src/ui/main_view/MainViewPageShellRuntime.gd`
- Existing story-scene verification in:
  - `app-LTL/tests/test_story_scene_contract.gd`
  - `app-LTL/tests/run_main_start_flow_contract.gd`
  - story-related focused runners already referenced by `godot_contract_runner.gd`

### Out of Scope

- Production implementation before user approval
- New narrative progression rules or story-trigger semantics
- Copying Stitch wording, labels, or page names into the runtime
- Unrelated page-shell refactors outside what the story screen needs

### Recommended Planning Direction

1. Keep the current page ownership and signals intact: `story_scene` remains a dedicated page registered by `MainViewPageShellRuntime`, and `continue_requested` / `skip_requested` stay as the controller contract.
2. Rebuild only the story page surface around the approved direction:
   - bright ruin/sky backdrop with a readable lower scrim
   - parchment/field-note dialogue slab instead of the current dark panel
   - leaf-tab or specimen-label speaker tag
   - configurable portrait/background placement that supports left/right step ownership without per-layout code forks
3. Expand story-step data so content authors can swap images and optional presentation metadata from data, not page code.
4. Add focused verification for:
   - data projection and fallback behavior
   - continue/skip/typewriter behavior
   - layout containment across visible portrait/background combinations
   - story handoff from intro flow back to `character_select`

### Expected Outputs For This Planning Turn

- A user-reviewable story-scene redesign/code-modification plan
- Identified implementation file list and risk areas
- Verification matrix for the later implementation pass

### Verification Method

- Planning phase: static inspection of current runtime files, data, tests, worklogs, and Stitch HTML/design assets
- Implementation phase plan must include focused Godot verification for:
  - `test_story_scene_contract.gd`
  - `run_main_start_flow_contract.gd`
  - any new story layout/runtime contract runner introduced by the implementation
  - smallest applicable compile/quality gate after focused runners pass

### Story-scene Plan Change Log

- 2026-07-03: Added a separate story-scene redesign planning track without overwriting the existing same-day character-select planning entry.
- 2026-07-03: Added the concrete implementation-plan artifact path after writing the approved character-select redesign plan.
- 2026-07-03: User approved the `공용 스토리 프레임 시스템화` direction and required minimal top chrome, so the story track moved from planning-only to implementation with TDD-first verification.

### Approved Implementation Direction

- Build a reusable story-frame surface under a story-scene-specific subfolder instead of keeping all layout ownership inside `StoryScenePage`.
- Keep the global page shell behavior unchanged: `story_scene` remains a meta page, and no large top header/chrome is introduced.
- Use data-driven scene/step presentation metadata so developers can swap story copy, background art, portrait art, and frame presentation without page-script edits.
- Reuse the current routing and telemetry contracts while changing only the visible story frame and its data projection surface.

### Implementation Steps

1. Add/adjust failing tests for the shared story-frame data projection and runtime layout contract.
2. Create the shared story-frame component(s) under `app-LTL/src/scenes/pages/story_scene/`.
3. Refactor `StoryScenePage` to delegate visible layout/chrome rendering to the shared frame while keeping continue/skip/typewriter ownership stable.
4. Extend `story-scenes.json` and `StorySceneReadModel.gd` with minimal presentation metadata needed for the shared frame.
5. Run focused story tests first, then broader compile/quality verification, then update worklogs and closeout notes.

### Expected Outputs For Implementation

- New reusable story-frame runtime component(s)
- Updated `StoryScenePage` that uses the reusable frame and keeps minimal top chrome
- Data-driven story presentation metadata in the story-scene content table/read model
- Focused story-scene regression coverage plus final verification evidence
