# Reward Ceremony Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement the mining-themed reward ceremony with count suspense, player-confirmed single-item reveals, rarity-fixed VFX, and stage-2-plus node-select color-picker removal.

**Architecture:** Keep `reward_loot` as the gameplay phase, but add explicit reward presentation substate ownership in the runtime and presenter. Let `RewardRevealOverlay.gd` render the ceremony while `MainControllerRuntime.gd` owns step transitions and input locks, and gate node-select color-picker visibility through explicit stage-aware layout data.

**Tech Stack:** Godot 4.3, GDScript, headless focused contract runners, Godot UI read-model tests.

---

### Task 1: Reward Ceremony Contracts

**Files:**
- Modify: `app-LTL/tests/test_ui_read_models.gd`
- Create: `app-LTL/tests/run_reward_ceremony_contract.gd`

- [ ] **Step 1: Write failing reward ceremony contract assertions**

Add assertions for:

- reward ceremony step sequence support
- no auto-dismiss before explicit confirm
- low-to-high rarity sorting helper
- quantity tease band helper for `1-2`, `3`, `4-5`
- stage-2-plus node-select color-picker gating contract

- [ ] **Step 2: Run the focused contract runner to verify RED**

Run:

```powershell
& 'D:\Programming\godot_workspace\bin\Godot_v4.3-stable_win64_console.exe' --display-driver headless --audio-driver Dummy --path 'D:\Programming\ex_workspace\LootingTheLeviathan\app-LTL' --script tests/run_reward_ceremony_contract.gd --disable-crash-handler --quit
```

Expected: failures mention missing reward ceremony helpers or incorrect node-select color-picker gating.

### Task 2: Reward Presentation State And Input Ownership

**Files:**
- Modify: `app-LTL/src/MainControllerRuntime.gd`
- Modify: `app-LTL/src/ui/presenters/PhaseLayoutPresenter.gd`
- Modify: `app-LTL/src/ui/MainViewRuntime.gd`

- [ ] **Step 1: Add explicit reward presentation step ownership**

Introduce runtime-owned step values:

- `count_tease`
- `count_lock`
- `reveal_queue`
- `tray_review`

Keep them attached to the scene dictionary so presenter and overlay can consume them without re-deriving timing state.

- [ ] **Step 2: Move confirm and skip behavior onto explicit step rules**

Make confirm behavior follow:

- first confirm during animation -> jump to readable end state
- second confirm on readable state -> advance to next step

Block reward tray, backpack, discard, shop, and node-select inputs until `tray_review`.

- [ ] **Step 3: Gate node-select starter color UI by stage**

Expose an explicit `allow_start_color_selection` contract based on stage index so stage 1 keeps the picker and stage 2+ removes it.

### Task 3: Overlay Model And Mining-Lid Quantity Suspense

**Files:**
- Modify: `app-LTL/src/ui/RewardRevealOverlay.gd`

- [ ] **Step 1: Add ceremony helpers before implementation**

Add helpers for:

- quantity tease band selection
- low-to-high rarity sorting
- current reveal index / progress state
- player-readable state detection

- [ ] **Step 2: Implement sealed mining-lid quantity tease**

Use `res://resources/UI/tile/tile_panel_nobg.png` as the sealed excavation lid presentation and implement banded count suspense:

- `1-2`
- `3`
- `4-5`

Do not reveal item identity or rarity in this step.

- [ ] **Step 3: Implement count lock and single-item reveal queue**

After count tease, lock the final count and then reveal one reward at a time in ascending rarity order with progress indicators.

- [ ] **Step 4: Bind VFX strength to actual rarity tier**

Keep VFX packages fixed by real rarity tier so the last item is only as flashy as its real rarity deserves.

### Task 4: Node Select Color Picker Removal After Stage 1

**Files:**
- Modify: `app-LTL/src/scenes/node_map/NodeMapScene.gd`
- Modify: related node-map read-model or render call files if needed

- [ ] **Step 1: Stop rendering color-choice UI after stage 1**

Use the explicit contract from runtime/presenter to skip building or rendering the color row after stage 1.

- [ ] **Step 2: Stop emitting color-choice input after stage 1**

Ensure hidden color controls also stop emitting signals so the earned inventory cannot be overwritten by stray interactions.

### Task 5: Green Pass And Verification

**Files:**
- Modify: `docs/codex-worklog/plan_LootingTheLeviathan_2026-06-01.md`
- Modify: `docs/codex-worklog/history_LootingTheLeviathan_2026-06-01.md`
- Modify: `docs/codex-worklog/complete_LootingTheLeviathan_2026-06-01.md`

- [ ] **Step 1: Run the focused reward ceremony contract runner**

Run:

```powershell
& 'D:\Programming\godot_workspace\bin\Godot_v4.3-stable_win64_console.exe' --display-driver headless --audio-driver Dummy --path 'D:\Programming\ex_workspace\LootingTheLeviathan\app-LTL' --script tests/run_reward_ceremony_contract.gd --disable-crash-handler --quit
```

Expected: success marker for the focused reward ceremony contract.

- [ ] **Step 2: Run the broader Godot contract suite**

Run:

```powershell
& 'D:\Programming\godot_workspace\bin\Godot_v4.3-stable_win64_console.exe' --display-driver headless --audio-driver Dummy --path 'D:\Programming\ex_workspace\LootingTheLeviathan\app-LTL' --script tests/godot_contract_runner.gd --disable-crash-handler --quit
```

Expected: `GODOT_CONTRACTS_OK`

- [ ] **Step 3: Run `git diff --check` on touched files**

Run:

```powershell
git diff --check -- app-LTL/src/MainControllerRuntime.gd app-LTL/src/ui/MainViewRuntime.gd app-LTL/src/ui/RewardRevealOverlay.gd app-LTL/src/ui/presenters/PhaseLayoutPresenter.gd app-LTL/src/scenes/node_map/NodeMapScene.gd app-LTL/tests/test_ui_read_models.gd app-LTL/tests/run_reward_ceremony_contract.gd docs/codex-worklog/plan_LootingTheLeviathan_2026-06-01.md docs/codex-worklog/history_LootingTheLeviathan_2026-06-01.md docs/codex-worklog/complete_LootingTheLeviathan_2026-06-01.md
```

Expected: no whitespace errors.

- [ ] **Step 4: Update worklog completion**

Record final implementation outputs, verification evidence, and any remaining gaps.
