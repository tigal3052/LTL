# Runtime Size Cap Enforcement Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Enforce small runtime files by adding a 500-line source/scene gate, freezing existing oversized debt, and splitting two immediately tractable oversized files.

**Architecture:** The harness keeps a single machine-readable size manifest. Non-debt active runtime `.gd` and `.tscn` files are capped by strict globs; legacy oversized files must be named in a separate debt field with frozen exact caps and cannot grow.

**Tech Stack:** PowerShell harness scripts, Godot 4.3 GDScript, existing Godot contract runners.

---

### Task 1: Size Gate Debt Semantics

**Files:**
- Modify: `LTL-harness/tools/runtime-size-gate.ps1`
- Modify: `LTL-harness/tools/runtime-size-gate.tests.ps1`
- Modify: `docs/architectural-gates/runtime-size-gate.md`

- [ ] Add failing self-tests for `legacy_debt_path_caps`, strict `.gd` glob caps, and strict `.tscn` glob caps.
- [ ] Implement `legacy_debt_path_caps` as exact path caps that are excluded from strict glob matching but fail if missing or above their frozen cap.
- [ ] Update the manifest so active `app-LTL/src/**/*.gd` and `app-LTL/src/**/*.tscn` default to 500 lines, while current large debt is explicitly frozen.
- [ ] Run the self-test and real gate.

### Task 2: Reward Fallback Data Split

**Files:**
- Modify: `app-LTL/src/vocabulary/RewardVocab.gd`
- Create: `app-LTL/src/vocabulary/reward/DefaultMockRewards.gd`
- Modify: `docs/source-map.md`

- [ ] Move `_get_default_mock_rewards()` data into `DefaultMockRewards.gd`.
- [ ] Keep `RewardVocab.gd` responsible for rolling and weighting only.
- [ ] Run reward contract verification and confirm both files are under 500 lines.

### Task 3: Character Select Loadout Text Split

**Files:**
- Modify: `app-LTL/src/scenes/pages/CharacterSelectPage.gd`
- Create: `app-LTL/src/scenes/pages/character_select/CharacterSelectLoadoutText.gd`
- Modify: `docs/source-map.md`

- [ ] Move starter loadout detail/copy helpers into `CharacterSelectLoadoutText.gd`.
- [ ] Keep `CharacterSelectPage.gd` responsible for scene rendering and input binding only.
- [ ] Run character-select cleanup verification and confirm both files are under 500 lines.

### Task 4: Worklog and Verification

**Files:**
- Modify: `docs/codex-worklog/plan_LootingTheLeviathan_2026-06-11.md`
- Modify: `docs/codex-worklog/history_LootingTheLeviathan_2026-06-11.md`
- Modify: `docs/codex-worklog/complete_LootingTheLeviathan_2026-06-11.md`

- [ ] Record root cause: high exact caps and warning-only legacy gates let oversized owners pass.
- [ ] Record recurrence prevention: strict global active runtime caps plus exact frozen debt entries.
- [ ] Run source-map, runtime-size, focused Godot contracts, and compile check.
