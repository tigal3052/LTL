# 2026-07-01 UI-001 Leviathan Select v6 rail + CTA detail fidelity closeout

## Agent

- agent: hermes
- source: hermes
- work_unit_id: ui-001-leviathan-select-v6-rail-cta-detail-fidelity
- objective_ids: UI-001
- status_at_closeout: done

## Goal

- Apply the user-requested follow-up fidelity pass to the Leviathan Select right rail only: hide the visible scrollbar while keeping wheel scroll, turn dummy cards into square borderless placeholders, push the start CTA closer to the approved v6 tokens, and make the strip snap back to the real first card at the top.

## Context Read

- `AGENTS.md`
- `docs/project-goals/final-goal.html`
- `docs/project-goals/work-objectives.html`
- `docs/agent-worklog/INDEX.md`
- `docs/agent-worklog/COMPACT.md`
- `docs/agent-worklog/2026-07-01-hermes-ui-001-leviathan-select-v6-compact-rail-cta-runtime-closeout.md`
- `app-LTL/src/scenes/pages/LeviathanSelectPage.gd`
- `app-LTL/src/scenes/pages/leviathan_select/LeviathanSelectViewBits.gd`
- `app-LTL/src/data/i18n/text-ko.json`
- `app-LTL/src/data/i18n/text-en.json`
- `app-LTL/tests/run_leviathan_rail_cta_style_audit.gd`
- `app-LTL/tests/run_leviathan_card_strip_scroll_contract.gd`
- `app-LTL/tests/run_leviathan_select_runtime_contract.gd`
- `docs/mockups/2026-07-01-leviathan-start-button-final-v6-edge-flush-tight.html`
- `docs/mockups/2026-07-01-leviathan-start-button-final-v6-edge-flush-tight.png`

## Files Changed

- `app-LTL/src/scenes/pages/LeviathanSelectPage.gd`: removed the persistent top teaser from the rail, added top snap-to-first-card behavior, and rebuilt dummy/filler cards as square borderless dark placeholders with oversized `LOCK` / `?` background glyph treatment.
- `app-LTL/src/scenes/pages/leviathan_select/LeviathanSelectViewBits.gd`: hid the rail scrollbar chrome, promoted CTA typography and border treatment, added the green gradient fill layer, and made the arrow bay fully opaque dark with a cleaner docked outline.
- `app-LTL/src/data/i18n/text-ko.json`: changed `leviathan.start_hint` to `STRIKE COMMENCE`.
- `app-LTL/src/data/i18n/text-en.json`: changed `leviathan.start_hint` to `STRIKE COMMENCE` for parity.
- `app-LTL/tests/run_leviathan_rail_cta_style_audit.gd`: tightened the fidelity audit to require hidden scrollbar chrome, square borderless preview cards with placeholder treatment, English CTA microcopy, stronger CTA frame, and the new dock decor.
- `app-LTL/tests/run_leviathan_card_strip_scroll_contract.gd`: tightened the strip contract so the first visible item at rest is the real first Leviathan card, not a teaser row.
- `docs/project-goals/work-objectives.html`: appended a UI-001 proof entry for this detail-fidelity pass.
- `docs/agent-worklog/INDEX.md`: added this closeout to the shared closeout table.
- `docs/agent-worklog/COMPACT.md`: added the condensed summary for this closeout.
- `docs/agent-worklog/2026-07-01-hermes-ui-001-leviathan-select-v6-rail-cta-detail-fidelity-closeout.md`: this closeout.

## Decisions

- Respect the user override on top-of-strip behavior: the approved teaser idea no longer persists at rest; the first real card now owns the top anchor.
- Hide the scrollbar entirely instead of merely slimming it down, because the user explicitly preferred invisible wheel scrolling over visible scroll affordance.
- Make dummy rows unmistakably fake data by replacing art-backed rounded preview cards with flat dark placeholder panels and giant background glyphs.
- Keep the CTA structure inside the existing page ownership rather than touching the left rail, top menu, or hero shell.

## Validation

- RED proof before the fix: `docs/evidence/leviathan-rail-cta-style-audit-red.log` captured the expected new audit failure before the runtime changes.
- RED proof before the fix: `docs/evidence/leviathan-card-strip-scroll-red.log` captured the expected teaser-at-top failure before the strip snap change.
- `powershell.exe ... --script 'res://tests/run_leviathan_rail_cta_style_audit.gd'` -> `LEVIATHAN_RAIL_CTA_STYLE_AUDIT_OK` (`docs/evidence/leviathan-rail-cta-style-audit-fix2.log`).
- `powershell.exe ... --script 'res://tests/run_leviathan_card_strip_scroll_contract.gd'` -> `LEVIATHAN_CARD_STRIP_SCROLL_CONTRACT_OK` (`docs/evidence/leviathan-card-strip-scroll-fix2.log`).
- `powershell.exe ... --script 'res://tests/run_leviathan_select_runtime_contract.gd'` -> `LEVIATHAN_SELECT_RUNTIME_CONTRACT_OK` (`docs/evidence/leviathan-select-runtime-fix2.log`).
- Visual capture proof refreshed at `docs/evidence/leviathan-select-v6-fix2.png` with runner log `docs/evidence/tmp-capture-leviathan-fix2.log`.

## Remaining Notes

- The updated runtime now matches the requested behavior more closely: no visible scrollbar, no resting top teaser, clearer dummy placeholders, and a stronger `STRIKE COMMENCE` moss dock with a darker arrow bay.
- The main remaining delta versus the HTML mockup is that the runtime placeholder rows intentionally read more abstract/minimal than the richer mockup-specific art cards, and the Godot CTA font still approximates the HTML reference rather than reproducing the exact browser typeface.
- Temporary one-off capture/debug scripts used during this pass were removed from `app-LTL/tests/` after verification.

## Compact Summary

- Leviathan Select right-rail follow-up now hides the scrollbar, snaps the strip back to the real first card at the top, and replaces the rounded dummy teaser look with square borderless placeholder rows.
- The start CTA now uses `STRIKE COMMENCE`, heavier typography, a stronger outer frame, a green fill layer, and a darker right arrow bay while leaving the rest of the page shell intact.
- Focused red/green rail fidelity and strip contracts passed, the runtime contract stayed green, and fresh visual proof was captured at `docs/evidence/leviathan-select-v6-fix2.png`.
