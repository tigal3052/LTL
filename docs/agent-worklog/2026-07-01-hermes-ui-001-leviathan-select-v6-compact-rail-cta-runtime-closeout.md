# 2026-07-01 UI-001 Leviathan Select v6 compact rail + CTA runtime closeout

## Agent

- agent: hermes
- source: hermes
- work_unit_id: ui-001-leviathan-select-v6-compact-rail-cta-runtime
- objective_ids: UI-001
- status_at_closeout: done

## Goal

- Apply the approved v6 Leviathan Select rail/CTA direction to the real Godot runtime while preserving the rest of the page design outside the rail/button scope.

## Context Read

- `AGENTS.md`
- `docs/project-goals/final-goal.html`
- `docs/project-goals/work-objectives.html`
- `docs/agent-worklog/2026-06-30-hermes-ui-001-leviathan-select-runtime-overlay-rail-closeout.md`
- `app-LTL/src/scenes/pages/LeviathanSelectPage.gd`
- `app-LTL/src/scenes/pages/LeviathanSelectPage.tscn`
- `app-LTL/src/scenes/pages/leviathan_select/LeviathanSelectViewBits.gd`
- `app-LTL/tests/run_leviathan_select_runtime_contract.gd`
- `app-LTL/tests/run_leviathan_card_strip_scroll_contract.gd`
- `app-LTL/tests/run_leviathan_top_button_style_audit.gd`
- `app-LTL/tests/run_main_layout_audit_contract.gd`
- `docs/mockups/2026-07-01-leviathan-start-button-final-v6-edge-flush-tight.html`

## Files Changed

- `app-LTL/src/scenes/pages/LeviathanSelectPage.gd`: switched the overlay rail/CTA to the compact v6 sizing rules, kept the rest of the page ownership intact, inset only the rail content strip, and added non-interactive teaser/filler rail cards so the strip keeps the approved dense stacked feel instead of falling into a large dead zone.
- `app-LTL/src/scenes/pages/leviathan_select/LeviathanSelectViewBits.gd`: restyled rail cards and CTA for square edge-flush geometry, removed old current/available state pills, and added the dark CTA arrow bay while preserving existing page chrome helpers.
- `app-LTL/tests/run_leviathan_rail_cta_style_audit.gd`: added a focused red/green audit for compact card height, square flush corners, no floating CTA shadow, and removal of old selected/available state pills.
- `app-LTL/tests/run_leviathan_select_runtime_contract.gd`: updated the runtime contract so compact strips may either scroll when overflowing or remain fitted at the canonical viewport while still bouncing correctly at edges.
- `app-LTL/tests/run_leviathan_card_strip_scroll_contract.gd`: aligned the scroll contract with the compact strip behavior, preserving bounce assertions even when the starter roster fits without active scrolling.
- `docs/project-goals/work-objectives.html`: appended the UI-001 proof entry for the approved v6 runtime rail/CTA pass.
- `docs/agent-worklog/2026-07-01-hermes-ui-001-leviathan-select-v6-compact-rail-cta-runtime-closeout.md`: this closeout.

## Decisions

- Preserve all non-rail areas: top menu, left rail, hero stage, and page shell stayed visually intact; only the right card strip and CTA dock were reworked.
- Match the approved v6 direction by runtime behavior, not by replacing unrelated layout ownership: keep controller/data/story/start flow unchanged and localize the change to Leviathan Select page/view helpers.
- Treat compact-fit and scroll-overflow as both valid for the rail strip: the canonical starter roster can fully fit at 1440x900, but the bounce/scroll behavior remains covered for overflow cases.

## Validation

- RED proof before the fix: `docs/evidence/leviathan-rail-cta-style-audit-before.log` recorded the expected failures for rounded rail/CTA corners, floating CTA shadow, tall rail cards, old current/available pills, and oversize CTA height.
- `powershell.exe ... --script 'res://tests/run_leviathan_rail_cta_style_audit.gd'` -> `LEVIATHAN_RAIL_CTA_STYLE_AUDIT_OK`.
- `powershell.exe ... --script 'res://tests/run_leviathan_select_runtime_contract.gd'` -> `LEVIATHAN_SELECT_RUNTIME_CONTRACT_OK`.
- `powershell.exe ... --script 'res://tests/run_leviathan_card_strip_scroll_contract.gd'` -> `LEVIATHAN_CARD_STRIP_SCROLL_CONTRACT_OK`.
- `powershell.exe ... --script 'res://tests/run_leviathan_top_button_style_audit.gd'` -> `LEVIATHAN_TOP_BUTTON_STYLE_AUDIT_OK`.
- `powershell.exe ... --script 'res://tests/run_main_layout_audit_contract.gd'` -> `MAIN_LAYOUT_AUDIT_CONTRACT_OK`.
- `powershell.exe ... --script 'res://tests/run_m6_visual_capture.gd' -- --page=leviathan_select --viewport=1440x900 --output=../docs/evidence/leviathan-select-v6-runtime-after.png` -> `M6_INTERNAL_CAPTURED .../leviathan-select-v6-runtime-after.png`.
- Visual proof reviewed directly from `docs/evidence/leviathan-select-v6-runtime-after.png`.

## Remaining Notes

- The updated runtime now reads much closer to the approved v6 direction: compact edge-flush cards, square outer rail/CTA edges, no current/available pills, a dark arrow bay on the CTA, and preview filler cards that remove the large empty dead zone under the live roster.
- The most noticeable residual difference versus the HTML mockup is that the preview filler cards are dimmer/more generic than the richer mockup-specific bottom cards; the layout ownership is now aligned, but those filler rows are still the remaining visual delta if the strip gets another fidelity pass.

## Compact Summary

- Leviathan Select runtime now uses the approved v6 compact rail/CTA treatment without disturbing the rest of the page shell.
- The right strip is shorter, squarer, and cleaner: no old current/available state pills, no rounded outer edges, and the CTA now docks flush with a dark right arrow bay.
- Proof passed across the focused style audit, runtime contract, compact-strip scroll contract, top-button audit, main layout audit, and fresh visual capture.
