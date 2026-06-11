# M6 UI/UX Finalization Refresh Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Re-scope M6 around the live `Main.tscn` / `MainViewRuntime` UI stack, close the remaining readability and accessibility gaps, and add a concrete visual-production plan so the game stops reading as a polished prototype and starts reading as a cohesive release-facing slice.

**Architecture:** Do not build a second HUD architecture beside the current one. Keep M6 inside the shipped `app-LTL/src/**` path and treat `MainViewRuntime`, `MainControllerRuntime`, `StatusPanelUI`, `BattlefieldUI`, `RewardRevealOverlay`, `NodeMapScene`, `BackpackUI`, and `ui/read_models` / `ui/presenters` as the real system to finish. Add missing read-model/presenter boundaries only where the current code is still forcing UI state to be recomputed ad hoc.

**Tech Stack:** Godot 4.3, GDScript, Control-tree UI composition, `ui/read_models`, `ui/presenters`, existing Godot contract runners, viewport/layout audit scripts, release-art fallback manifests.

---

## Why This Refresh Exists

The June 3 M6 plan captured the right milestone intent, but it no longer matches the codebase closely enough to be the execution source of truth.

### Stale assumptions in the June 3 plan

- The green baseline recovery task is outdated.
  - Current evidence on June 4 already shows `MILESTONE_GATE_OK`, `SOURCE_MAP_GATE_OK`, `GODOT_CONTRACTS_OK`, `UI_READ_MODEL_TESTS_OK`, and `REWARD_CEREMONY_CONTRACT_OK`.
- Several recommended target files do not exist in the live tree.
  - `app-LTL/src/scenes/hud/HudRoot.tscn`
  - `app-LTL/src/scenes/hud/HudRoot.gd`
  - `app-LTL/src/scenes/reward/RewardPresentation.gd`
  - `app-LTL/src/scenes/backpack/BackpackOrganizeScene.gd`
  - `app-LTL/tests/test_ui_scene_smoke.gd`
- The codex-book is no longer a hypothetical stretch slice.
  - The tree already contains `ArtifactCodexPanelUI.gd`, `ArtifactCodexReadModel.gd`, codex layout tests, and the dedicated book redesign spec.
- The failure/retry task is aimed at a brand-new screen, while the live runtime currently routes failure through the existing repair overlay and reset flow.

### What the live tree already gives M6

- `MainViewRuntime.gd` already owns the shell layout, overlays, tooltip layer, reward reveal overlay, node map scene, codex panel, and settings panel.
- `StatusPanelUI.gd`, `BattlefieldUI.gd`, and `BackpackUI.gd` already expose testable UI contracts for queue, hazard, pin, repair, and layout behavior.
- `RewardRevealOverlay.gd` already implements the approved `count_tease -> count_lock -> reveal_queue -> tray_review` ceremony structure.
- `NodeMapScene.gd` and `NodeMapReadModel.gd` already provide a full-page route surface with focused smoke tests.
- `run_main_layout_audit_contract.gd` already functions as the closest thing to a real M6 scene smoke / viewport bounds suite.

### What is still missing

- A single, explicit combat cue projection for `aim`, `front token`, `weakness/mismatch`, `hazard pressure`, and `repair risk`.
- Non-color-only cue language that is shared across battlefield, HUD, reward, and node map.
- Accessibility controls beyond current `screenshake/fullscreen/language/volume`.
- Structured UI telemetry beyond `print("TELEMETRY: ...")` debug strings.
- A stable theme / art-kit plan that tells implementation exactly what is reusable kit art versus bespoke hero art.
- A failure/retry UX pass that explains `why this run failed` and `what to try next`, instead of only presenting a generic fail overlay.

## Reference Direction

This refresh uses the following reference split:

- Combat readability:
  - `Dome Keeper`
  - `FTL`
  - `Into the Breach`
- Reward and route flow:
  - `Slay the Spire`
  - `Hades`
  - `Balatro`
- Visual language and backpack surfaces:
  - `DREDGE`
  - `Dome Keeper`
  - `Backpack Hero`

### What to borrow

- From `Dome Keeper`: one-glance combat pressure, mining-machine contrast, and a dedicated danger strip instead of diffuse HUD noise.
- From `FTL`: panic-proof state scanning, repair severity clarity, and subsystem-style warning language.
- From `Into the Breach`: telegraph discipline, icon-first consequence reading, and non-color-only status signaling.
- From `Slay the Spire` and `Hades`: route nodes that are understood by silhouette and badge before copy is read.
- From `Balatro`: compact, player-confirmed reward reveals with rigid geometry and strong anticipation beats.
- From `DREDGE`: oily metal plus occult contamination material language.
- From `Backpack Hero`: compartment-first backpack readability and silhouette-first item classes.

## North-Star Visual Rules

These rules are mandatory for the M6 pass and should be treated as implementation constraints, not optional polish notes.

### 1. Materials

- Base material stack:
  - oiled steel
  - oxidized brass
  - canvas or leather liners
  - smoked glass and dim instrument lighting
- Leviathan contamination layer:
  - wet chitin
  - bone-like ridges
  - salt stains
  - hairline occult etching

### 2. Shared cue vocabulary

- Energy families must always resolve through `shape first`, `color second`, `text third`.
- Recommended family anchors:
  - red: triangle or spearhead
  - blue: ring or coil
  - purple: diamond or split prism
  - green: spore or leaf-spine
- Match states:
  - match: closed ring / stable frame
  - normal: neutral frame
  - mismatch: broken ring / cracked frame
- Hazard families must have lane or cell markers that survive muted color perception.
- Repair states must use a four-step ladder:
  - stable
  - strained
  - critical
  - repair required

### 3. Motion

- Continuous motion belongs only to danger, countdowns, or reveal suspense.
- Queue advance should snap.
- Mismatch should shatter once.
- Repair lock should clunk once.
- Backpack polish should stay local to slots or panel edges, not bloom across the whole screen.

### 4. Asset split

Reusable kit art:

- shell frames
- panel insets
- slot lips and inner trays
- button shells
- icon atlas
- rarity trims
- cable / bolt / gasket decals
- charge masks
- small dust / spark / smoke sheets
- route glow strips
- hazard sigils

Bespoke hero art:

- starter drills
- starter beacons
- relic silhouettes
- legendary / mythic reward lids
- major hazard icons
- leviathan biome backplates
- portraits
- codex book hero framing

## Additional Meta Page: Leviathan Select

This refresh also needs one non-combat meta page between character selection and actual run entry: `leviathan_select`.

### Purpose

- Let the player choose which leviathan contract to loot after locking a character.
- Sell the target as a major expedition destination, not as a text-heavy menu list.
- Keep route complexity visible, but compress it into a cinematic hunt brief rather than a systems panel.

### Layout Contract

- Left rail: `1/5`
  - same narrow roster behavior as the approved character selector
  - small image + leviathan name only
  - scrollable when the roster grows
- Main board: `4/5`
  - dominant leviathan hero image
  - the image is the page centerpiece and should read before any prose

### Overlay Content

- Top overlay:
  - ultra-compact run structure only
  - examples:
    - `RUN 4`
    - `5 • 6 • 5 • 6`
    - or equivalent icon/number shorthand
  - no long explanatory copy in the top strip
- Lower-right overlay on the image:
  - `루팅 목표` card for the final clear artifact
  - completion state expressed as a `CLEAR` stamp directly over the target card, not as a separate badge
  - one fixed CTA:
    - `Looting Start`

### Tone Rules

- This page should feel like accepting a dangerous mercenary contract.
- The CTA should use a rough, graffiti-like lettering treatment while keeping the actual button hitbox clear and legible.
- The loot-target card should read like a tagged target dossier, not a clean codex card.
- Any leviathan explanation or strategy hint must stay short enough that the image and target card still dominate the page.

### What this page intentionally removes

- No long paragraph stack beside the image
- No large checklist cards for each run
- No separate clear-status panel
- No heavy right-column documentation layout

## Real M6 File Map

These are the real centers of gravity for M6 work.

### Core runtime and orchestration

- `app-LTL/src/Main.tscn`
- `app-LTL/src/MainControllerRuntime.gd`
- `app-LTL/src/ui/MainViewRuntime.gd`

### Combat readability and feedback

- `app-LTL/src/ui/StatusPanelUI.gd`
- `app-LTL/src/ui/BattlefieldUI.gd`
- `app-LTL/src/ui/CellView.gd`
- `app-LTL/src/ui/BattlefieldVFX.gd`
- `app-LTL/src/ui/VFXManager.gd`
- `app-LTL/src/ui/presenters/PhaseLayoutPresenter.gd`
- `app-LTL/src/ui/presenters/CombatFeedbackPresenter.gd`
- `app-LTL/src/ui/presenters/InteractionCuePresenter.gd`
- Create: `app-LTL/src/ui/read_models/HudReadModel.gd`

### Reward flow and node map

- `app-LTL/src/ui/RewardRevealOverlay.gd`
- `app-LTL/src/ui/read_models/RewardReadModel.gd`
- `app-LTL/src/ui/presenters/RewardCeremonyPolicy.gd`
- `app-LTL/src/scenes/node_map/NodeMapScene.gd`
- `app-LTL/src/ui/read_models/NodeMapReadModel.gd`

### Backpack and item surfaces

- `app-LTL/src/ui/BackpackUI.gd`
- `app-LTL/src/ui/InteractionFX.gd`
- `app-LTL/src/ui/presenters/BackpackGridFactory.gd`
- `app-LTL/src/ui/presenters/BackpackPinLayoutPolicy.gd`

### Meta, accessibility, failure flow, and docs

- `app-LTL/src/ui/SettingsPanelUI.gd`
- Create: `app-LTL/src/ui/read_models/FailureReadModel.gd`
- Create or modify: a failure overlay component inside the existing `Main.tscn` shell
- Create: `app-LTL/src/ui/theme/LTLTheme.tres`
- Create: `docs/ui-style-guide.md`

### Existing verification to extend instead of replacing

- `app-LTL/tests/test_ui_read_models.gd`
- `app-LTL/tests/run_test_ui_read_models.gd`
- `app-LTL/tests/run_reward_ceremony_contract.gd`
- `app-LTL/tests/test_node_map_scene_smoke.gd`
- `app-LTL/tests/run_node_map_scene_smoke.gd`
- `app-LTL/tests/run_main_layout_audit_contract.gd`
- `app-LTL/tests/godot_contract_runner.gd`

## Execution Order

## Task 1: Replace Stale M6 Assumptions With The Live Baseline

**Files:**
- Modify: `docs/superpowers/plans/2026-06-03-m6-ui-ux-finalization-plan.md`
- Modify: `LTL-harness/docs/11_exec-plans/01_active/12_M6_ui_ux_finalization.md` only if milestone wording must be clarified, not re-scoped
- Modify: `docs/ui-style-guide.md` later as the living style reference
- Modify: `app-LTL/tests/run_main_layout_audit_contract.gd`
- Modify: `app-LTL/tests/test_ui_read_models.gd`

- [ ] Remove any remaining implementation checklist items that assume a broken baseline or nonexistent HUD scene split.
- [ ] Treat the current green gate/test baseline as a starting line, not as a task deliverable.
- [ ] Consolidate the active M6 verification surface around:
  - `run_test_ui_read_models.gd`
  - `run_reward_ceremony_contract.gd`
  - `run_node_map_scene_smoke.gd`
  - `run_main_layout_audit_contract.gd`
  - `godot_contract_runner.gd`
- [ ] Add one comment block in the M6 implementation docs that explicitly says:
  - `HudRoot` is not the live execution path
  - `MainViewRuntime` is the live shell
  - `test_ui_scene_smoke.gd` is represented by the current layout audit plus focused smoke runners

**Exit check:**

- The refreshed plan and milestone notes no longer direct work into nonexistent files.

## Task 2: Build The Combat Cue System Around 1-Second Recognition

**Files:**
- Create: `app-LTL/src/ui/read_models/HudReadModel.gd`
- Modify: `app-LTL/src/ui/MainViewRuntime.gd`
- Modify: `app-LTL/src/ui/StatusPanelUI.gd`
- Modify: `app-LTL/src/ui/BattlefieldUI.gd`
- Modify: `app-LTL/src/ui/CellView.gd`
- Modify: `app-LTL/src/ui/presenters/PhaseLayoutPresenter.gd`
- Modify: `app-LTL/tests/test_ui_read_models.gd`
- Modify: `app-LTL/tests/run_main_layout_audit_contract.gd`

- [ ] Project the combat strip through one explicit read-model boundary instead of recomputing state in multiple controls.
- [ ] Replace the current “all queue gems are equal” presentation with `Now / Next / Reserve`.
  - `Now` must be visually dominant.
  - `Next` may stay compact.
  - the remaining queue can stay abstracted as reserve count or small capsules.
- [ ] Mirror weakness/mismatch on both the target cell and the active token.
- [ ] Add one hazard-pressure strip that unifies:
  - family icon
  - remaining time / shift pressure
  - active vs cleared state
- [ ] Promote repair state from plain text to a stable ladder:
  - stable
  - strained
  - critical
  - repair required
- [ ] Make each combat outcome physically distinct:
  - match
  - normal
  - mismatch
  - empty queue
  - disabled target
  - repair blocked

**Exit check:**

- `test_ui_read_models.gd` can assert the presence of all required combat cues without depending on color-only interpretation.
- `run_main_layout_audit_contract.gd` proves the compact combat strip stays inside supported resolutions.

## Task 3: Polish Reward Ceremony And Node Map As A Shared Decision Rhythm

**Files:**
- Modify: `app-LTL/src/ui/RewardRevealOverlay.gd`
- Modify: `app-LTL/src/ui/MainViewRuntime.gd`
- Modify: `app-LTL/src/ui/read_models/RewardReadModel.gd`
- Modify: `app-LTL/src/ui/presenters/RewardCeremonyPolicy.gd`
- Modify: `app-LTL/src/scenes/node_map/NodeMapScene.gd`
- Modify: `app-LTL/src/ui/read_models/NodeMapReadModel.gd`
- Modify: `app-LTL/tests/test_ui_read_models.gd`
- Modify: `app-LTL/tests/run_reward_ceremony_contract.gd`
- Modify: `app-LTL/tests/test_node_map_scene_smoke.gd`

- [ ] Keep the current ceremony step order, but retune it around authored beats:
  - `count_tease`: sealed lids plus dust / rumble only
  - `count_lock`: exact count plus pip markers
  - `reveal_queue`: crack -> silhouette -> rarity ring -> full card
  - `tray_review`: first moment where backpack and discard inputs unlock
- [ ] Make confirm readiness visible instead of silently waiting for input.
- [ ] Keep reward geometry rigid so copy length cannot reflow the core composition.
- [ ] Limit node chips to three scanning tokens:
  - risk
  - reward class
  - special modifier
- [ ] Keep route lines low-information and move detail into the focus panel.
- [ ] Reclaim the stage-2+ starter-color area for route comparison polish, not extra prose.

**Exit check:**

- `run_reward_ceremony_contract.gd` remains green.
- `test_node_map_scene_smoke.gd` proves node choice remains compact, non-overlapping, and route-focused.

## Task 4: Give The Backpack A Final Surface Pass Instead Of A Pure Logic Pass

**Files:**
- Modify: `app-LTL/src/ui/BackpackUI.gd`
- Modify: `app-LTL/src/ui/InteractionFX.gd`
- Modify: `app-LTL/src/ui/presenters/BackpackGridFactory.gd`
- Modify: `app-LTL/src/ui/presenters/BackpackPinLayoutPolicy.gd`
- Modify: `app-LTL/src/ui/MainViewRuntime.gd`
- Modify: `app-LTL/tests/test_ui_read_models.gd`

- [ ] Upgrade empty slots from “blank functional cells” to authored compartments.
  - outer hardware lip
  - inner matte tray
  - subtle contact shadow when occupied
- [ ] Keep item silhouettes readable before tooltip text appears.
- [ ] Preserve current pin geometry and removal order, but finish the surrounding shell treatment so the backpack reads as a physical machine surface.
- [ ] Restrict VFX to local slot or panel-edge events.
  - dust
  - sparks
  - ore-glow
  - light fog-edge contamination
- [ ] Keep rarity expression in trim, corners, and micro-ornament before saturation.

**Exit check:**

- Backpack state is readable at idle without hover.
- Item class is identifiable from silhouette at the live slot size.

## Task 5: Add A Practical Failure / Retry Layer And Real Accessibility Settings

**Files:**
- Create: `app-LTL/src/ui/read_models/FailureReadModel.gd`
- Modify: `app-LTL/src/Main.tscn`
- Modify: `app-LTL/src/MainControllerRuntime.gd`
- Modify: `app-LTL/src/ui/MainViewRuntime.gd`
- Modify: `app-LTL/src/ui/StatusPanelUI.gd`
- Modify: `app-LTL/src/ui/SettingsPanelUI.gd`
- Modify: `app-LTL/src/ui/VFXManager.gd`
- Modify: `app-LTL/tests/test_ui_read_models.gd`
- Modify: `app-LTL/tests/run_main_layout_audit_contract.gd`

- [ ] Keep failure UI inside the existing shell unless a separate scene becomes absolutely necessary.
- [ ] Project:
  - primary failure cause
  - one next-try tip
  - retry / exit focus order
- [ ] Replace debug-print telemetry strings with structured UI event payload helpers.
- [ ] Expand settings beyond current toggles to include at least:
  - reduced shake
  - reduced flash
  - reduced particle intensity
  - explicit hold-fire assist policy
- [ ] Persist accessibility options in a stable runtime-facing state object.

**Exit check:**

- Failure flow explains what happened and what to try next.
- Accessibility options affect the actual systems they claim to control.
- UI telemetry fields can be inspected without parsing freeform log strings.

## Task 6: Lock The Theme, Asset Kit, Screenshot Matrix, And Style Guide

**Files:**
- Create: `app-LTL/src/ui/theme/LTLTheme.tres`
- Modify: `app-LTL/src/Main.tscn`
- Modify: `app-LTL/src/ui/MainViewRuntime.gd`
- Modify: `app-LTL/src/ui/StatusPanelUI.gd`
- Modify: `app-LTL/src/ui/BackpackUI.gd`
- Modify: `app-LTL/src/scenes/node_map/NodeMapScene.gd`
- Create: `docs/ui-style-guide.md`
- Update as needed: `docs/release-visual-quality-upgrade-plan.md`

- [ ] Move hard-coded panel/button styling into `LTLTheme.tres` where practical.
- [ ] Build the first reusable art kit around:
  - shell backgrounds
  - panel frames
  - node silhouettes
  - route glow strips
  - slot trays
  - hazard sigils
  - reward lid states
- [ ] Define screenshot targets for:
  - combat HUD
  - reward reveal
  - tray review
  - node map
  - backpack organization
  - leviathan select
  - failure overlay
  - settings/accessibility overlay
- [ ] Record fallback-art rules so placeholder assets are allowed only when:
  - they preserve silhouette
  - they preserve bounds
  - they preserve cue vocabulary

**Exit check:**

- M6 produces a shared style guide, not just isolated UI fixes.
- The art-kit plan is specific enough that outside art production can plug in without changing layout math.

## Verification Matrix

Run after each slice that touches layout or readable UI state:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File LTL-harness/tools/milestone-gate.ps1 -TargetPlan 12_M6_ui_ux_finalization.md -Root D:\Programming\ex_workspace\LootingTheLeviathan
powershell -NoProfile -ExecutionPolicy Bypass -File tools/run-compile-check.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File tools/invoke-godot.ps1 -Headless -Script tests/run_test_ui_read_models.gd -Quit
powershell -NoProfile -ExecutionPolicy Bypass -File tools/invoke-godot.ps1 -Headless -Script tests/run_reward_ceremony_contract.gd -Quit
powershell -NoProfile -ExecutionPolicy Bypass -File tools/invoke-godot.ps1 -Headless -Script tests/run_node_map_scene_smoke.gd -Quit
powershell -NoProfile -ExecutionPolicy Bypass -File tools/invoke-godot.ps1 -Headless -Script tests/run_main_layout_audit_contract.gd -Quit
```

Expected:

- `MILESTONE_GATE_OK`
- `SOURCE_MAP_GATE_OK`
- `GODOT_CONTRACTS_OK`
- `UI_READ_MODEL_TESTS_OK`
- `REWARD_CEREMONY_CONTRACT_OK`
- `MAIN_LAYOUT_AUDIT_CONTRACT_OK`

## Completion Gate

M6 is ready to call complete only when all of the following are true:

- Combat interaction state is recognizable in about one second without relying on color alone.
- Reward ceremony, tray review, node map, and backpack all read as one cohesive visual family.
- Failure/retry explains the previous loss and the next attempt clearly.
- Accessibility toggles materially affect shake / flash / particles / assist behavior and persist.
- The tree has a reusable theme and art-kit plan, not only per-script style overrides.
- The screenshot matrix exists for supported aspect ratios and any remaining issues are listed explicitly.
