# 2026-07-01 UI-001 Leviathan Select selected-card shell + flush + drag closeout

## Agent

- agent: hermes
- source: hermes
- work_unit_id: ui-001-leviathan-select-selected-card-shell-and-drag
- objective: Remove the selected-card left gutter at the architectural root, restore proper rail top anchoring, make the hero/rail flush to the top/bottom/right frame, preserve dummy cards, and keep drag-to-scroll working.
- status: done

## Context Read

- `docs/project-goals/final-goal.html`
- `docs/project-goals/work-objectives.html`
- `docs/agent-worklog/INDEX.md`
- `docs/agent-worklog/COMPACT.md`
- `D:/Programming/ex_workspace/agent-harness/00_AGENTS.md`
- `D:/Programming/ex_workspace/agent-harness/docs/architectural-decoupling-enforcement.md`

## Root Cause

There were three separate runtime bugs, and the earlier pass only fixed one of them incompletely.

1. **Selected-card extra gutter was real, not just perceptual.**
   - `LeviathanSelectViewBits.gd` still created `SelectionTint` beside the green strip.
   - Fresh runtime diagnostics (`docs/evidence/leviathan-regression-diag.log`) showed `SelectionStrip` width = 4 px but `SelectionTint` width = 12 px, which created an actual dark lane beside the green strip.

2. **Top card clipping came from a negative viewport offset, not from card geometry.**
   - Fresh diagnostics showed `cards_scroll.position.y = -56` even though the strip should have started at the rail top.
   - That negative offset caused the first real card (`유해갑 거북`) to render partially above the visible viewport.

3. **Blue background gutters were caused by page shell layout and chrome, not by art scaling.**
   - `WorkspaceMargin` kept 18 px top/right/bottom margins.
   - `HeroShell` still applied outer frame/shadow chrome, which prevented the hero image and overlay rail from reading as frame-flush.

## Fix Applied

### 1. Removed the real selected-card gutter
- `LeviathanSelectViewBits.gd` no longer creates the extra `SelectionTint` lane by default.
- The selected state now keeps only the green `SelectionStrip`, integrated into the shared card shell.

### 2. Restored the rail top anchor
- `LeviathanSelectPage.gd` now explicitly sets `cards_scroll.offset_top = 0.0` during responsive layout sync.
- `LeviathanSelectPage.tscn` also serializes `CardsScroll.offset_top = 0.0`.
- Diagnostics after the fix (`docs/evidence/leviathan-regression-diag-fix6c.log`) showed `cards_scroll_local_pos=(10, 0)` and the first real card fully inside the viewport with a 12 px top gap.

### 3. Removed outer blue gutters on the hero/rail stage
- `LeviathanSelectPage.tscn` now sets `WorkspaceMargin` top/right/bottom margins to 0.
- `LeviathanSelectPage.gd` now removes the old rounded/shadowed `HeroShell` panel chrome so the hero image and overlay rail touch the top/bottom/right frame directly under the top bar.

### 4. Preserved dummy cards and interaction behavior
- The rail still preserves the full four-card dummy tail.
- `run_leviathan_rail_cta_style_audit.gd` now guards `preview_cards.size() >= 4`.
- `LeviathanSelectRailScrollController.gd` remains the single owner for wheel/drag/bounce/click suppression.

## Files Changed

- `app-LTL/src/scenes/pages/LeviathanSelectPage.gd`
- `app-LTL/src/scenes/pages/LeviathanSelectPage.tscn`
- `app-LTL/src/scenes/pages/leviathan_select/LeviathanSelectViewBits.gd`
- `app-LTL/src/scenes/pages/leviathan_select/LeviathanSelectRailCardFactory.gd`
- `app-LTL/src/scenes/pages/leviathan_select/LeviathanSelectRailScrollController.gd`
- `app-LTL/src/scenes/pages/leviathan_select/LeviathanSelectChromeBits.gd`
- `app-LTL/tests/run_leviathan_rail_cta_style_audit.gd`
- `app-LTL/tests/run_leviathan_card_strip_scroll_contract.gd`
- `app-LTL/tests/run_page_scene_mapping_contract.gd`
- `docs/project-goals/work-objectives.html`
- `docs/request-ledgers/2026-07-01-ui-001-leviathan-select-selected-card-shell-and-drag.md`
- `docs/agent-worklog/2026-07-01-hermes-ui-001-leviathan-select-selected-card-shell-and-drag-closeout.md`

## Harness / SRP Review

### Improved in this pass
- Selected/unselected/preview rows still share one named rail-card shell owner.
- The real left gutter bug is now removed at the shell-builder level instead of being rationalized away by content-margin invariants.
- The rail viewport offset bug is now fixed at the page layout owner, where it belongs.
- `LeviathanSelectPage.gd` and `LeviathanSelectViewBits.gd` remain under the runtime-size cap thanks to the extracted card/scroll/chrome helpers.

### Remaining debt
- `LeviathanSelectChromeBits.gd` is still broad, though under cap.
- Future growth should split chrome tokens from CTA decoration before the helper becomes another oversized owner.

## Verification

### Red
- `docs/evidence/leviathan-rail-cta-style-audit-red4.log`
  - failed on the exact three user complaints: extra selected-card gutter, top/bottom/right blue gutters, and missing frame flush.

### Green
- `docs/evidence/leviathan-rail-cta-style-audit-fix7.log` → `LEVIATHAN_RAIL_CTA_STYLE_AUDIT_OK`
- `docs/evidence/leviathan-card-strip-scroll-fix7.log` → `LEVIATHAN_CARD_STRIP_SCROLL_CONTRACT_OK`
- `docs/evidence/leviathan-select-runtime-fix7.log` → `LEVIATHAN_SELECT_RUNTIME_CONTRACT_OK`
- `tools/run-compile-check.ps1 -RequestLedger docs/request-ledgers/2026-07-01-ui-001-leviathan-select-selected-card-shell-and-drag.md` → `Compilation Check: PASSED (GODOT_CONTRACTS_OK)`

### Runtime / visual evidence
- `docs/evidence/leviathan-regression-diag.log`
- `docs/evidence/leviathan-regression-diag-fix6c.log`
- `docs/evidence/leviathan-top-fix6.png`
- `docs/evidence/leviathan-selected-fix6.png`
- `docs/evidence/leviathan-fix6-capture.log`

## Compact Summary

The previous pass misdiagnosed the selected-card gutter as merely perceptual, but fresh diagnostics proved a real 12 px `SelectionTint` lane still existed beside the 4 px green strip; that lane is now removed so the selected card keeps only the integrated strip. The hero/rail stage is now flush to the top/bottom/right frame by zeroing `WorkspaceMargin` gutters and removing the old `HeroShell` outer chrome, and the first rail card no longer starts at a hidden negative viewport offset because `cards_scroll.offset_top` is forced back to 0. Focused rail style, strip scroll, runtime, page-contract, transition-safety, source-map, request-analysis, runtime-size, and compile gates all passed, and fresh runtime captures show the selected card, top card anchoring, and visible LOCK dummy cards behaving as requested.