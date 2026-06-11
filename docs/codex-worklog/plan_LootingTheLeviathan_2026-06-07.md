# Codex Worklog Plan

Workspace: LootingTheLeviathan
Date: 2026-06-07

## Active Work

Implement the live M6 UI/UX refresh in the Godot runtime, repair the discovered run-start contract drift where the live `character_select` page did not match the approved mockup, harden the page shell against viewport overflow regressions, land a focused `leviathan_select` CTA refinement so `Looting Start` reads as an obvious next-step button, contain the combat page so its live HUD plus battlefield stack stays inside the canonical desktop viewport, and replace the placeholder `node_select` shell that still reuses the generic stage backdrop instead of the approved route-selection page contract.

Add a same-day review pass for the start-page cleanup request so the `character_select` page removes scaffold copy, restores the top-right settings affordance, expands the reclaimed layout space into the live panels, upgrades the backpack preview hover affordance, captures the proposed visual direction in a browser-review mockup before runtime edits begin, and then follow through in the live runtime with a tighter CTA label plus a non-scrolling starter-loadout list that shows the actual starter drill and beacon data.

Correct the node-select follow-up evidence path after review showed the earlier `node-select-runtime.png` artifact was stale and did not reflect the live runtime page. Re-verify whether `node_select` is actually mapped to the new roadmap page, replace the misleading headless screenshot path with a real GUI capture flow, and refresh the canonical QA artifact from the live window.

## Request Summary

Use `docs/superpowers/plans/2026-06-04-m6-ui-ux-finalization-refresh-plan.md` as the implementation source of truth and ship the M6 pass in `app-LTL/src/**`. The pass should use the provided background, character, sprite-sheet, and leviathan images in the live UI; strengthen combat readability and failure/accessibility UX; upgrade node-select into a leviathan-contract style page; and keep verification grounded in the existing Godot runners and layout audits. After user review, also audit why `docs/mockups/m6-run-start-wireframe.html` drifted from the live runtime, identify the root cause, rebuild the `character_select` page to the mockup contract, add regression checks so meta pages cannot silently fall back to node-select layout again, harden the start-page shell so its stacked layout cannot overflow the canonical desktop viewport unnoticed, and apply the same containment discipline to the combat page without waiting on the separate root-cause investigation session.

## Scope

- Create today's worklog files for the new date.
- Update live Godot runtime/view/read-model code under `app-LTL/src/**`.
- Integrate the provided character and leviathan image assets into battle, status, reward, failure, and node-select surfaces.
- Add the missing `HudReadModel` / failure-state projection and improve settings accessibility controls.
- Audit the run-start contract failure and rebuild the actual `character_select` scene/layout so it matches the approved mockup structure instead of a placeholder shell.
- Apply the follow-up `character_select` pass so the CTA reads `레비아탄 선택`, the starter-loadout list uses the reclaimed vertical space without a scrollbar, and the UI surfaces the live starter drill and beacon details instead of placeholder copy.
- Audit the recurring viewport overflow on the rebuilt `character_select` page and extend the harness so page-shell containment is a blocking contract.
- Audit the combat HUD plus battlefield stack against the same viewport-containment contract and clamp the live combat layout so it still renders fully inside the canonical desktop viewport.
- Refine the `leviathan_select` `Looting Start` CTA so its height, typography, and color hierarchy immediately communicate progression to the next page.
- Produce a researched comparison board with nine premium / rough CTA directions before choosing the final live style.
- Update verification coverage and today's worklog files.

## Out of Scope

- New external asset sourcing beyond the provided local image set
- Reverting unrelated in-progress workspace changes
- Git publishing actions
- Git actions

## Steps

1. Refresh today's worklog to match the live M6 implementation objective.
2. Repair asset/source-map drift caused by the character art move and adopt the new image paths in runtime code.
3. Implement the core M6 runtime pass:
   - `HudReadModel` combat cue projection
   - status/combat cue upgrades
   - leviathan-contract style node-select presentation
   - battle/reward/failure art integration
   - accessibility/settings improvements
4. Investigate the run-start contract drift by comparing the mockup, `CharacterSelectPage`, `PhaseLayoutPresenter`, and the active `Main.tscn` render path.
5. Rebuild the `character_select` scene to the run-start board contract and harden meta-page rendering so `pageId` wins over the underlying gameplay phase.
6. Replace ad hoc UI telemetry prints with structured payload helpers where the current runtime still emits raw strings.
7. Add a meaningful RED containment check for the live `character_select` page before adjusting the runtime layout.
8. Repair the run-start page height policy so the approved board fits inside the 1440x900 desktop contract without clipping the CTA lane.
9. Extend the page-contract guidance and gate expectations so mockup-backed meta pages must prove viewport containment, then run compile/layout/read-model verification and update today's history/completion notes with the observed results.
10. Rework the `Looting Start` CTA styling and structure on `LeviathanSelectPage`, then verify the page contract still proves the button exists as an explicit staged CTA.
11. Probe the live combat layout, add a RED regression that proves combat containment, then clamp the combat stack so the viewport still shows HUD, battlefield, and action bar together.
12. Research premium CTA patterns plus rough poster/graffiti button references, then assemble a nine-direction visual board for the user to pick from before the next live restyle pass.

## Expected Outputs

- `app-LTL/src/ui/read_models/HudReadModel.gd`
- `app-LTL/src/ui/read_models/FailureReadModel.gd`
- rebuilt `app-LTL/src/scenes/pages/CharacterSelectPage.gd`
- rebuilt `app-LTL/src/scenes/pages/CharacterSelectPage.tscn`
- strengthened `app-LTL/tests/run_main_layout_audit_contract.gd`
- updated `LTL-harness/docs/page-contract-execution-gate.md`
- updated `LTL-harness/00_AGENTS.md`
- updated `app-LTL/src/ui/**`, `app-LTL/src/MainControllerRuntime.gd`, and relevant tests
- refined `app-LTL/src/scenes/pages/LeviathanSelectPage.gd`
- refined `app-LTL/src/scenes/pages/LeviathanSelectPage.tscn`
- `docs/mockups/2026-06-07-leviathan-cta-directions.html`
- `docs/superpowers/specs/2026-06-07-leviathan-looting-start-cta-directions-design.ko.md`
- refined combat containment policy in `app-LTL/src/ui/presenters/PhaseLayoutPresenter.gd`, `app-LTL/src/ui/MainViewRuntime.gd`, and related layout audits
- updated `docs/source-map.md`
- `docs/codex-worklog/plan_LootingTheLeviathan_2026-06-07.md`
- `docs/codex-worklog/history_LootingTheLeviathan_2026-06-07.md`
- `docs/codex-worklog/complete_LootingTheLeviathan_2026-06-07.md`

## Verification Method

- `powershell -NoProfile -ExecutionPolicy Bypass -File ..\tools\run-compile-check.ps1` from `app-LTL`
- `powershell -NoProfile -ExecutionPolicy Bypass -File ..\tools\invoke-godot.ps1 -Headless -Script tests/run_test_ui_read_models.gd -Quit`
- `powershell -NoProfile -ExecutionPolicy Bypass -File ..\tools\invoke-godot.ps1 -Headless -Script tests/run_main_layout_audit_contract.gd -Quit`
- `powershell -NoProfile -ExecutionPolicy Bypass -File ..\tools\invoke-godot.ps1 -Headless -Script tests/run_main_start_flow_contract.gd -Quit`
- `powershell -NoProfile -ExecutionPolicy Bypass -File ..\tools\invoke-godot.ps1 -Headless -Script tests/run_page_scene_mapping_contract.gd -Quit`
- `powershell -NoProfile -ExecutionPolicy Bypass -File tools/capture-node-select-runtime.ps1`
- targeted combat layout probes and the refreshed `powershell -NoProfile -ExecutionPolicy Bypass -File ..\tools\invoke-godot.ps1 -Headless -Script tests/run_main_layout_audit_contract.gd -Quit`
- `powershell -NoProfile -ExecutionPolicy Bypass -File LTL-harness/tools/request-analysis-gate.ps1 -Ledger docs/request-ledgers/2026-06-07-character-select-layout-containment.md -Mode pre-edit`
- additional targeted `rg` / `git diff --check` confirmation on touched files
- local browser review of the standalone CTA comparison board

## Plan Change Log

- 2026-06-07: Created today's plan for the node-select five-stage readability refinement.
- 2026-06-07: Retargeted today's plan to the leviathan-select page addition and mockup requested after the node-select refinement.
- 2026-06-07: Retargeted today's plan again to the full live M6 runtime implementation after the explicit `/goal` request to build the Godot slice with subagents and provided art assets.
- 2026-06-07: Expanded the implementation target again after review feedback so the live flow now requires explicit page scenes, meta-page routing, and page-flow contract verification.
- 2026-06-07: Expanded the plan once more after visual review showed the run-start mockup contract was not actually honored by the live `character_select` page, requiring root-cause analysis plus a contract-faithful rebuild.
- 2026-06-07: Re-scoped the follow-up once more so recurrence prevention moves into the harness itself with a page-contract execution gate wired into compile and quality checks.
- 2026-06-07: Expanded the follow-up again after runtime review showed the rebuilt `character_select` shell still exceeded the canonical desktop viewport, requiring runtime containment fixes plus viewport-aware harness guidance.
- 2026-06-07: Added a focused `leviathan_select` CTA follow-up so the `Looting Start` button becomes taller and visually unmistakable as the next-step control.
- 2026-06-07: Added a same-day combat containment follow-up after runtime review showed the battle page can still expand past the canonical desktop viewport even after the start-page shell hardening.
- 2026-06-07: Added a focused `node_select` shell follow-up after runtime review showed the leviathan handoff still lands on a reused generic backdrop page instead of a dedicated route-selection scene.
- 2026-06-07: Added an expedition-fail follow-up after runtime review showed the live defeat screen was still rendering the old repair overlay, leaking a fixed golem backdrop and breaking full-page containment expectations.
- 2026-06-07: Added a harness follow-up after review confirmed the recurring start-page overflow was fundamentally a page-host ownership plus vertical-budget contract gap, not just a one-off scene sizing bug.
- 2026-06-07: Added a design-exploration follow-up to compare nine researched premium and rough CTA directions before locking the next live Leviathan-select button style.
- 2026-06-07: User approved the `Monument Condensed` Leviathan CTA direction, so the follow-up now includes a live scene rebuild with RED/GREEN scene-contract coverage for the board-edge ribbon plus condensed CTA frame.
- 2026-06-07: Added a focused start-page cleanup review so the current `character_select` scaffold can be compared in-browser against a proposal that strips helper copy, moves settings to the top-right corner, expands the live panels, and previews the backpack hover tooltip behavior before runtime edits.
- 2026-06-07: Re-scoped the node-select fix again after review feedback so the final path is now `new runtime page -> switch routing -> verify -> delete legacy node-select panel/page`, not `legacy panel wrapped by a new shell`.
- 2026-06-07: Added a live runtime follow-up so the `character_select` CTA copy shortens, the starter-loadout palette consumes the currently wasted lower-column space without scrolling, and the palette plus bag hover now reflect the real starter drill/beacon data.
- 2026-06-07: Added a focused starter-selection layout-regression follow-up after live review showed choosing a starter relic could reflow the entire `character_select` board and break the initial aspect ratio.
- 2026-06-07: Added a node-select QA correction follow-up after review confirmed the previously cited `node-select-runtime.png` capture was stale, requiring a fresh live-window capture path and an explicit audit of whether runtime mapping or screenshot evidence was wrong.
