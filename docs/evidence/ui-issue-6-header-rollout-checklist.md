# ui-issue-6 header rollout checklist

## Current rollout decision
- `repo-level closeout` for the Variant-05 top-menu rollout is **deferred until all intended page-level design updates are implemented**.
- Intermediate page-level work should keep using focused proof only (style audit / page contract / internal viewport capture), not the full repo closeout stack.
- `Codex` / `Settings` are planned as **separate pages** in the product direction, so the header should ultimately behave as page ownership would behave, not as a passive background-overlay cosmetic state.

## Confirmed analysis
### 1) Leviathan top-menu visual refinement
- Variant-05 typography was updated toward the approved `유물 도감 / 설정` action feel:
  - top-group font size raised to `14`
  - top-group font weight raised to `800`
  - underline moved visually closer to the text via the current runtime interpretation (`UNDERLINE_BOTTOM = 9`)
- Evidence:
  - `docs/evidence/ui-issue-6-top-group-logs/leviathan_top_button_style_audit.log`
  - `docs/evidence/ui-issue-6-top-group-logs/leviathan_top_button_group.log`
  - `docs/evidence/ui-issue-6-top-group-leviathan_select_1440x900.png`

### 2) Codex modal active-state does **not** fix itself by restyling other pages
- On the Leviathan page, the top buttons are currently built with hard-coded active metadata at navigation rebuild time:
  - `LeviathanTabButton` is created with `"active": true`
  - `CodexActionButton` is created with `"active": false`
- Opening Codex does **not** change the active page id. It only toggles a popup overlay (`codex_panel.visible`).
- Verified runtime probe:
  - before open: `page=leviathan_select`, `leviathan_active=true`, `codex_active=false`
  - after open: `page=leviathan_select`, `codex_visible=true`, `leviathan_active=true`, `codex_active=false`
- Evidence:
  - `docs/evidence/ui-issue-6-top-group-logs/leviathan_codex_active_probe.log`

## Locked product decisions from the user
### A. Codex / Settings active-state behavior
- `Codex` / `Settings` should be treated as future **page owners**, not as permanently background-only overlays.
- Therefore the header **must actively switch** to `Codex` / `Settings` while those surfaces are open.
- The current Leviathan-behind-modal active state is **not acceptable as the final interaction model**.

### B. Character Select participation
- `Character Select` is part of the shared fixed top-menu rollout.
- It should join the same header family used by the non-runtime meta pages.

### C. Node-flow participation
- Node-related pages do **not** reuse the exact `Character / Leviathan / Codex / Settings` label set.
- Instead, the node/runtime flow should use a **phase-specific header family** within the same overall navigation system:
  - `레비아탄 계약`
  - `노드선택`
  - `배틀`
  - `보상선택`
- This is a planned variation of the shared navigation system, not an accidental exception.

## Page-by-page rollout tasks
### A. Character Select page
- [ ] Replace the standalone `SettingsButton` with the shared fixed top-menu family.
- [ ] Apply the shared non-runtime header system consistently on Character Select.
- [ ] Add focused layout/style proof for the new top header on Character Select.

### B. Leviathan Select page
- [x] Move the four top actions into one shared top-group host.
- [x] Reapply Variant-05 visual family with dedicated underline nodes and style audit.
- [x] Refine typography/underline spacing toward the approved `유물 도감 / 설정` action feel.
- [ ] Make `Codex` / `Settings` take the active header state while visible, matching the planned separate-page ownership model.
- [ ] Re-capture once the active-state owner rule is implemented.

### C. Codex / Settings surfaces
- [ ] Keep current popup/overlay carriers functional, but drive header active state as if `Codex` / `Settings` owns the surface.
- [ ] When Codex / Settings become dedicated pages later, preserve the same active-header contract rather than introducing a second rule.
- [ ] Verify open/close/return flows keep the header state coherent.

### D. Node-flow header family
- [ ] Roll the node/runtime flow into the same overall top-navigation system with the phase-specific item set:
  - `레비아탄 계약`
  - `노드선택`
  - `배틀`
  - `보상선택`
- [ ] Verify the active item changes correctly as the player moves across those runtime phases.
- [ ] Add focused proof for the node-flow header variation.

### E. Shared header state ownership
- [ ] Define one source of truth for the active header item.
- [ ] Replace page-local hard-coded `active` flags where needed with a state derived from the current visible surface / current phase.
- [ ] Verify top-header buttons and any secondary navigation mirrors stay consistent.

## Final closeout gate (run only after the rollout is fully implemented)
- [ ] Cross-page / cross-phase interaction matrix:
  - Character Select -> Leviathan Select
  - Leviathan Select -> Codex open/close
  - Leviathan Select -> Settings open/close
  - Codex / Settings active-owner states remain coherent
  - Leviathan Contract -> Node Select -> Battle -> Reward Select phase transitions update the active header correctly
  - return/back/navigation states remain visually coherent
- [ ] Fresh viewport capture set for each affected page/state
- [ ] Focused page/layout/style contracts all green
- [ ] Only then escalate to the repo-level closeout bundle (ledger / source-map / compile-check / objective / worklog)
