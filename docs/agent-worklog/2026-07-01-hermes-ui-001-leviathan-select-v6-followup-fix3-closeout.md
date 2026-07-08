# 2026-07-01 UI-001 Leviathan Select v6 follow-up fix3 closeout

## Agent

- agent: hermes
- source: hermes
- work_unit_id: ui-001-leviathan-select-v6-followup-fix3
- objective: Apply the user-requested second right-rail follow-up without disturbing the rest of the page: move the top snap below the header, remove the CTA left gutter, unify locked placeholders to `LOCK`, enlarge rail cards by about 1.5x, and ensure the green CTA border wraps around the full button including the arrow bay.

## Scope Guard

- Modified only the Leviathan Select right rail / CTA implementation and its focused verification coverage.
- Left the top bar, left rail shell, hero copy layout, controller/data ownership, and non-Leviathan pages untouched.

## Files Changed

- `app-LTL/src/scenes/pages/LeviathanSelectPage.gd`
- `app-LTL/src/scenes/pages/leviathan_select/LeviathanSelectViewBits.gd`
- `app-LTL/tests/run_leviathan_rail_cta_style_audit.gd`
- `app-LTL/tests/run_leviathan_card_strip_scroll_contract.gd`

## What Changed

1. Added a small persistent top rest gap above the strip via `CardsSpringTop`, raised the top snap threshold, and re-centered edge bounce so the first real card now lands just below the header-adjacent strip edge instead of being partially hidden.
2. Removed the CTA frame's external left gutter by setting the dock frame flush to the rail edge while keeping the card strip inset intact.
3. Standardized the bottom placeholder lane to `LOCK` and promoted the final placeholder to full-height so locked rows no longer mix `LOCK` and `?` or collapse shorter than the rest of the strip.
4. Increased rail card height by roughly 1.5x (`88-92px` → `132-138px`) so the roster reads closer to the approved taller-card direction.
5. Strengthened the CTA outer frame, flattened the green fill, inset the fill/arrow-bay layers by 1px so the border remains visible on every edge, and increased the separator strength between the green field and the black arrow bay.

## Verification

### Red evidence

- `docs/evidence/leviathan-rail-cta-style-audit-red2.log`
- `docs/evidence/leviathan-card-strip-scroll-red2.log`

These captured the expected failures before the fix:
- weak CTA outer border
- CTA left gutter still present
- compact card height still too short
- mixed `LOCK` / `?` placeholders
- arrow-bay/fill layers still covering the outer border
- missing top rest gap above the first real card

### Green evidence

- `docs/evidence/leviathan-rail-cta-style-audit-fix3.log`
  - `LEVIATHAN_RAIL_CTA_STYLE_AUDIT_OK`
- `docs/evidence/leviathan-card-strip-scroll-fix3.log`
  - `LEVIATHAN_CARD_STRIP_SCROLL_CONTRACT_OK`
- `docs/evidence/leviathan-select-runtime-fix3.log`
  - `LEVIATHAN_SELECT_RUNTIME_CONTRACT_OK`

### Visual evidence

- `docs/evidence/leviathan-select-v6-fix3.png`
- `docs/evidence/tmp-capture-leviathan-fix3.log`
  - `LEV_FIX3_CAPTURE_OK D:/Programming/ex_workspace/LootingTheLeviathan/docs/evidence/leviathan-select-v6-fix3.png`

## Runtime Result Summary

The latest runtime capture confirms the requested five-item follow-up landed:

- the first real card now starts below the header instead of hiding under it
- the CTA now begins flush with the rail edge with no external left gap
- locked placeholders read as `LOCK` consistently
- the roster cards are materially taller than the prior compact strip
- the green CTA border remains visible around the entire button, including around the black arrow bay

## Remaining Mismatch

- The runtime is now structurally aligned with the approved v6 direction, but the Godot rail still reads a little darker/flatter than the mockup's richer stitched presentation. The main remaining difference is tonal polish, not geometry or ownership.
