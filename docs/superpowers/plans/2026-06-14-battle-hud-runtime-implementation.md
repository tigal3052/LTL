# Battle HUD Runtime Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Apply the approved battle HUD mockups to the real Godot runtime, including the tabbed right sidebar, enlarged left status panel, two-row FIFO energy queue, and terrain multiplier info panel.

**Architecture:** Keep the existing shared battle shell and runtime facade, but change the shell node tree, update bundle-path wiring in `MainViewRuntime.gd`, and extend combat/HUD read-model projection so the sidebar can render terrain-state-specific info without pulling from gameplay state directly.

**Tech Stack:** Godot 4.3 GDScript, `.tscn` scene shells, `MainViewRuntime.gd`, `StatusPanelUI.gd`, combat read models, localized text catalogs, headless UI contract runners.

---

### Task 1: Lock the new HUD contract in tests

**Files:**
- Modify: `app-LTL/tests/ui_read_models/ui_battlefield_hud_suite.gd`
- Modify: `app-LTL/tests/ui_read_models/ui_phase_layout_suite.gd`
- Test: `app-LTL/tests/run_test_ui_read_models.gd`

- [ ] **Step 1: Rewrite the old queue/layout expectations to the approved runtime contract**

Add or update assertions so the suite expects:

- no standalone `LeftSidebar` dependency for explorer status
- a right-sidebar tab shell with a default explorer tab
- a two-row queue contract instead of the `now / next / reserve` triplet
- no stage-limit label expectation inside the status body

- [ ] **Step 2: Add failing terrain-info projection expectations**

Add tests for neutral, single-weakness, and composite terrain info data so the current runtime fails until the new info model exists.

- [ ] **Step 3: Run the focused runner and confirm RED**

Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools/invoke-godot.ps1 -ProjectPath app-LTL -Headless -Script tests/run_test_ui_read_models.gd
```

Expected:

- exit code non-zero
- failures tied to the new HUD layout / queue / terrain-info expectations

### Task 2: Rebuild the shared battle shell structure

**Files:**
- Modify: `app-LTL/src/scenes/pages/shells/GameplayTopContent.tscn`
- Modify: `app-LTL/src/ui/MainViewRuntime.gd`
- Test: `app-LTL/tests/ui_read_models/ui_battlefield_hud_suite.gd`

- [ ] **Step 1: Move explorer content into the right sidebar tab shell**

Restructure `GameplayTopContent.tscn` so:

- the old left explorer panel is removed
- the left column is driven by the status panel
- the right sidebar contains a tab header plus two content bodies
- the explorer tab body hosts the portrait and loadout summary

- [ ] **Step 2: Update bundle paths and locale bindings**

Update `MainViewRuntime.gd` bundle caching, locale path bindings, character summary rendering, and any node lookup helpers that still assume:

- `TopContent/LeftColumn/LeftSidebar/...`
- `TopContent/RightSidebar/Margin/InspectorBox/InspectorText`

- [ ] **Step 3: Keep shared shell compatibility across battle and reward page bundles**

Make the shell wiring resilient for every page in `SURFACE_PAGE_IDS`, even if some tabs or info blocks are only visible during battle.

- [ ] **Step 4: Run the focused runner and confirm the old shell failures are gone**

Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools/invoke-godot.ps1 -ProjectPath app-LTL -Headless -Script tests/run_test_ui_read_models.gd
```

Expected:

- any remaining failures are now about queue/info behavior, not missing shell nodes

### Task 3: Replace the queue hub and status-panel body behavior

**Files:**
- Modify: `app-LTL/src/ui/StatusPanelUI.gd`
- Modify: `app-LTL/src/ui/read_models/HudReadModel.gd`
- Modify: `app-LTL/src/data/i18n/text-ko.json`
- Modify: `app-LTL/src/data/i18n/text-en.json`
- Test: `app-LTL/tests/ui_read_models/ui_battlefield_hud_suite.gd`

- [ ] **Step 1: Change the queue read model from role buckets to slot rows**

Project queue data as:

- slot list
- active capacity
- max capacity
- per-slot active/inactive/filled state

instead of only:

- `nowColor`
- `nextColor`
- `reserveCount`

- [ ] **Step 2: Rebuild the status-panel queue rendering as a two-row FIFO surface**

Update `StatusPanelUI.gd` so the queue UI renders:

- row 1 slots 1-8
- row 2 slots 9-16
- filled waveform slots in energy color
- disabled slots for unavailable capacity

- [ ] **Step 3: Remove the stage-limit treatment but keep drill status and footer timer**

Update labels and body structure so the old stage-limit wording disappears from the panel while the footer timer remains active.

- [ ] **Step 4: Run the focused runner and confirm GREEN on queue/status expectations**

Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools/invoke-godot.ps1 -ProjectPath app-LTL -Headless -Script tests/run_test_ui_read_models.gd
```

Expected:

- queue contract tests pass
- no failures mention `now / next / reserve` assumptions

### Task 4: Add the log/info tab terrain panels

**Files:**
- Modify: `app-LTL/src/ui/StatusPanelUI.gd`
- Modify: `app-LTL/src/ui/read_models/HudReadModel.gd`
- Modify: `app-LTL/src/ui/CombatSceneModel.gd`
- Modify: `app-LTL/src/MainControllerRuntime.gd`
- Test: `app-LTL/tests/ui_read_models/ui_battlefield_hud_suite.gd`
- Test: `app-LTL/tests/ui_read_models/ui_interaction_controller_suite.gd`

- [ ] **Step 1: Surface selected-node multiplier data into the combat UI scene model**

Expose enough node metadata for the sidebar info panel to distinguish:

- neutral terrain
- single weakness
- composite weakness
- per-color shield/health multipliers
- compact tags such as reward bias or recommended hint

- [ ] **Step 2: Render the info tab using terrain-state-specific cards**

Implement the right-tab info content so:

- neutral terrain uses a common multiplier summary
- single weakness uses one color card with two mini cards
- composite terrain uses two color cards, each with its own shield/health mini cards
- the extra tags stay compact instead of expanding into a long panel wall

- [ ] **Step 3: Preserve log behavior inside the same tab**

Keep the existing log console visible within the secondary tab so system messages remain available without becoming the default HUD focus.

- [ ] **Step 4: Run focused and broader layout verification**

Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools/invoke-godot.ps1 -ProjectPath app-LTL -Headless -Script tests/run_test_ui_read_models.gd
powershell -NoProfile -ExecutionPolicy Bypass -File tools/invoke-godot.ps1 -ProjectPath app-LTL -Headless -Script tests/run_main_layout_audit_contract.gd
```

Expected:

- both runners exit 0
- `UI_READ_MODEL_TESTS_OK`
- `MAIN_LAYOUT_AUDIT_CONTRACT_OK`
