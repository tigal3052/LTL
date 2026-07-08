# 2026-07-01 UI-001 Leviathan Select selected-card shell and drag follow-up

## Request Summary

- Diagnose the extra left gutter that appears when a Leviathan card is selected, fix it at the architectural root instead of by visual patching, and explain why the rail looked component-dualized.
- Add drag-to-scroll behavior to the Leviathan roster strip while keeping click selection intact.
- Remove the remaining top/bottom/right blue gutters around the hero/rail stage, stop the first rail card from clipping at the top, and keep the dummy-card tail present.
- Verify the result with screenshot-grounded QA plus repo gates.

## Preserved Invariants

- The approved `character_select -> leviathan_select -> node_select` flow remains unchanged.
- No controller, reducer, data table, unlock logic, gameplay contract, or i18n ownership changes are introduced.
- The top menu and left rail remain intact outside the targeted hero/rail/card-strip scope.
- Existing unrelated dirty worktree state is not reverted.

## Mutable Scope

- `app-LTL/src/scenes/pages/LeviathanSelectPage.gd`
- `app-LTL/src/scenes/pages/LeviathanSelectPage.tscn`
- `app-LTL/src/scenes/pages/leviathan_select/LeviathanSelectViewBits.gd`
- `app-LTL/src/scenes/pages/leviathan_select/LeviathanSelectRailCardFactory.gd`
- `app-LTL/src/scenes/pages/leviathan_select/LeviathanSelectRailScrollController.gd`
- `app-LTL/src/scenes/pages/leviathan_select/LeviathanSelectChromeBits.gd`
- `app-LTL/tests/run_leviathan_rail_cta_style_audit.gd`
- `app-LTL/tests/run_leviathan_card_strip_scroll_contract.gd`
- `app-LTL/tests/run_page_scene_mapping_contract.gd`
- `docs/source-map.md`
- `docs/request-ledgers/2026-07-01-ui-001-leviathan-select-selected-card-shell-and-drag.md`
- `docs/project-goals/work-objectives.html`
- `docs/agent-worklog/2026-07-01-hermes-ui-001-leviathan-select-selected-card-shell-and-drag-closeout.md`
- `docs/agent-worklog/INDEX.md`
- `docs/agent-worklog/COMPACT.md`

## Source Map Findings

- `docs/source-map.md`
  - Must be refreshed because this pass changed the Leviathan Select page owner, scene shell, extracted helpers, focused tests, and closeout docs.
- `app-LTL/src/scenes/pages/LeviathanSelectPage.gd`
  - Owns state projection, hero/rail responsive layout, selection emission, and page-local orchestration.
- `app-LTL/src/scenes/pages/LeviathanSelectPage.tscn`
  - Owns the flush-stage shell and the scroll container's serialized top offset.
- `app-LTL/src/scenes/pages/leviathan_select/LeviathanSelectViewBits.gd`
  - Owns shared rail-card shell construction and selected-strip rendering rules.
- `app-LTL/src/scenes/pages/leviathan_select/LeviathanSelectRailScrollController.gd`
  - Owns drag/wheel/bounce/click-suppression behavior.
- `app-LTL/tests/run_leviathan_rail_cta_style_audit.gd`
  - Guards gutter removal, stage flush, and preview-tail preservation.
- `app-LTL/tests/run_leviathan_card_strip_scroll_contract.gd`
  - Guards scroll viewport top anchoring and drag-scroll behavior.

## Root Cause Review

- Observed symptom: the selected third card still showed a real blank left gutter beside the green strip, the hero/rail stage still floated inside the blue page background, and the first real rail card still clipped at the top.
- Evidence: `docs/evidence/leviathan-regression-diag.log`, the user-provided screenshot, and fresh runtime captures.
- Root cause target: `app-LTL/src/scenes/pages/leviathan_select/LeviathanSelectViewBits.gd`
- Root cause: `SelectionTint` still rendered as a 12 px lane beside the 4 px green strip, so the selected shell really did keep an extra dark gutter.
- Rejected workaround: reusing the previous "content-start x stayed invariant" argument and merely describing the lane as perceptual.
- Chosen fix: remove the extra tint lane from the shared shell path and keep only the integrated green strip.

## Transition Safety Review

- no transition impact
- reason: this pass changes only page-local hero/rail shell layout, selected-card rendering, and roster-strip input handling; routing, selected-Leviathan data handoff, and start flow stay on the existing controller contract.
- runtime runner: `app-LTL/tests/run_leviathan_select_runtime_contract.gd`
- runtime marker: `LEVIATHAN_SELECT_RUNTIME_CONTRACT_OK`
- rail runner: `app-LTL/tests/run_leviathan_rail_cta_style_audit.gd`
- rail marker: `LEVIATHAN_RAIL_CTA_STYLE_AUDIT_OK`
- strip runner: `app-LTL/tests/run_leviathan_card_strip_scroll_contract.gd`
- strip marker: `LEVIATHAN_CARD_STRIP_SCROLL_CONTRACT_OK`

## Feature Unit Lifecycle Plan

- Design stage: treat the selected-state gutter complaint and top-card clipping complaint as concrete shell/layout bugs with screenshot proof, not as subjective impressions.
- Implementation stage: keep selected/unselected/preview variation inside one rail-card shell owner, keep scroll physics under one interaction owner, and keep stage flush/layout offsets under the page owner.
- Interaction stage: drag-scroll remains local to the page rail interaction owner and continues suppressing release-click after a drag threshold.
- Maintenance stage: future Leviathan rail polish should extend the shared shell/tests rather than reintroduce page-local overlay lanes or hidden scroll offsets.
- Capsule boundary: the Leviathan Select page family owns this hero/rail/card-strip capsule locally; gameplay progression remains outside it.
- Size trigger: if the Leviathan rail helpers grow another large subsection, split CTA/chrome again before exceeding the runtime-size cap.

## Execution Responsibility Units

- Owner: `app-LTL/src/scenes/pages/LeviathanSelectPage.gd`
  - Unit: responsive stage layout, zeroing the rail viewport top offset, orchestration, and selection handoff.
  - Focused proof: `app-LTL/tests/run_leviathan_card_strip_scroll_contract.gd`, `app-LTL/tests/run_leviathan_select_runtime_contract.gd`
- Owner: `app-LTL/src/scenes/pages/leviathan_select/LeviathanSelectViewBits.gd`
  - Unit: shared selected/unselected/preview rail-card shell rendering.
  - Focused proof: `app-LTL/tests/run_leviathan_rail_cta_style_audit.gd`
- Owner: `app-LTL/src/scenes/pages/LeviathanSelectPage.tscn`
  - Unit: flush stage margins and serialized `CardsScroll` top anchor.
  - Focused proof: fresh runtime captures and `PAGE_SCENE_MAPPING_CONTRACT_OK`

## Refactor/Delete Disposition

- Keep the Leviathan Select page owner and its extracted helpers.
- Keep the preview tail, but forbid dropping below four preview placeholder cards.
- Remove the extra selected-state tint lane and the old outer hero-shell chrome.

## Verification Checklist

- Run `powershell -NoProfile -ExecutionPolicy Bypass -File LTL-harness/tools/source-map-gate.ps1 -Root . -Refresh`.
- Capture a red baseline against the updated focused style audit.
- Run the focused style audit headlessly.
- Run the focused strip scroll contract headlessly.
- Run the focused runtime contract headlessly.
- Capture fresh runtime screenshots for top and selected states.
- Run `powershell -NoProfile -ExecutionPolicy Bypass -File tools/run-compile-check.ps1 -RequestLedger docs/request-ledgers/2026-07-01-ui-001-leviathan-select-selected-card-shell-and-drag.md`.
- Update the relevant UI-001 objective log.
- Write a Hermes closeout worklog and refresh `docs/agent-worklog/INDEX.md` / `COMPACT.md`.

## Verification Notes

- `docs/evidence/leviathan-rail-cta-style-audit-red4.log` captured the red baseline showing the still-present selected gutter plus the top/bottom/right stage gutters.
- `docs/evidence/leviathan-regression-diag.log` proved `SelectionTint` width = 12 px and `cards_scroll.position.y = -56` before the fix.
- `docs/evidence/leviathan-regression-diag-fix6c.log` proved `cards_scroll.position.y = 0`, the first real card top gap = 12 px, and the selected shell no longer included `SelectionTint` after the fix.
- `docs/evidence/leviathan-top-fix6.png` and `docs/evidence/leviathan-selected-fix6.png` provide screenshot-grounded QA for the first card, selected strip, stage flush, and visible LOCK placeholders.
- `docs/evidence/leviathan-rail-cta-style-audit-fix7.log` emitted `LEVIATHAN_RAIL_CTA_STYLE_AUDIT_OK`.
- `docs/evidence/leviathan-card-strip-scroll-fix7.log` emitted `LEVIATHAN_CARD_STRIP_SCROLL_CONTRACT_OK`.
- `docs/evidence/leviathan-select-runtime-fix7.log` emitted `LEVIATHAN_SELECT_RUNTIME_CONTRACT_OK`.
- `tools/run-compile-check.ps1 -RequestLedger docs/request-ledgers/2026-07-01-ui-001-leviathan-select-selected-card-shell-and-drag.md` completed with `Compilation Check: PASSED (GODOT_CONTRACTS_OK)`.

## Resolution Proof

- RED proof: the updated style audit failed on the exact user complaints before the fix.
- Root-cause proof: diagnostics showed a real 12 px selected tint lane and a real `cards_scroll.position.y = -56` viewport offset.
- Fix proof: the selected shell now has only the 4 px strip, the stage is flush, the first real card sits fully inside the rail, four dummy tail cards remain structurally present, and all focused proofs plus compile-check pass.
- Workaround guard: no controller-side presentation hacks, route changes, or gameplay-schema changes were introduced.

## Artifact Ledger

- `docs/evidence/leviathan-rail-cta-style-audit-red4.log`
- `docs/evidence/leviathan-rail-cta-style-audit-fix7.log`
- `docs/evidence/leviathan-card-strip-scroll-fix7.log`
- `docs/evidence/leviathan-select-runtime-fix7.log`
- `docs/evidence/leviathan-regression-diag.log`
- `docs/evidence/leviathan-regression-diag-fix6c.log`
- `docs/evidence/leviathan-top-fix6.png`
- `docs/evidence/leviathan-selected-fix6.png`
- `docs/evidence/leviathan-fix6-capture.log`
