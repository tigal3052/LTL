# M0 Redesign Gate Completion Report

**Related active plan (kept in place)**: `docs/11_exec-plans/01_active/06_M0_redesign_gate.md`

## Completion Summary

- Completed the M0 redesign gate by deciding which prototype contracts should be promoted into formal M1 domain boundaries and which browser-only structures should remain prototype-specific.
- The gate outcome reclassified the current 5-stage browser mini-run as a test-scale structure, locked the browser combat SoT, and established the first formal contracts for fixture promotion, JSON schemas, phase records, reward structure, UI boundaries, and progress tracking.
- Bootstrapped the missing tech-debt tracker so the redesign-gate result can flow directly into M1 planning.

## Actual Outputs

- `docs/11_exec-plans/02_completed/06_M0_redesign_gate_completed.md`
- `docs/00_tech-debt-tracker.md`
- A formalized decision baseline derived from:
  - `docs/11_exec-plans/01_active/06_M0_redesign_gate.md`
  - `docs/11_exec-plans/01_active/06b_post_M0_implementation_handoff.md`
  - the user interview decisions collected during the gate review

## Verification Results

- The redesign-gate decisions were cross-checked against the current browser/runtime code in `app-LTL`, especially:
  - `src/ui/mini-run-app.js`
  - `src/process/mini-run-stage-script.js`
  - `src/vocabulary/combat/fire-shot.js`
  - `src/phases/*`
  - `src/data/*`
- `node --test tests/p4_mini_run.test.js`
- `node --test tests/*.test.js`
- The replay/core-loop/domain tests currently remain green, which means the gate decisions are being recorded against a stable prototype baseline rather than a broken intermediate state.

## Changes From Plan

- The active gate note expected a technical-debt tracker to already exist, but the file was missing. The redesign gate completion therefore includes tracker bootstrap as part of the completion work.
- Instead of continuing to evolve `06b_post_M0_implementation_handoff.md` as the main output, the authoritative gate result is recorded here as a milestone completion report as requested.

## Gate Decisions Recorded

### Browser SoT

- Browser combat rules are the current SoT and should be preserved as the M1 reference contract.
- The current browser `queue / time / pin` loop remains the baseline combat rhythm.
- The current 5-stage browser mini-run is a test-scale loop, not the final Leviathan-driven run structure.
- Final Leviathan structure should be driven by Leviathan data:
  - 4~6 stages per mini-run
  - 3~5 mini-runs per Leviathan
  - the last stage of each mini-run is a boss stage

### Fixture / Replay Promotion

- The promoted M1 replay/fixture matrix must cover:
  - one-shot clear
  - empty-queue repair pressure
  - mismatch attack
  - reward claim to next stage
  - final stage clear to run complete
  - run-complete branching
    - Leviathan clear end
    - next run progression
  - reward-phase last-artifact removal guard

### Data Contracts

- Artifact required fields:
  - `id`
  - `name`
  - `shape`
  - `energyType`
  - `baseCooldownTicks`
  - `synergy`
  - `keyword`
- `synergy` is required but may be `null`.
- Node required fields:
  - `id`
  - `label`
  - `weakness`
  - `pickWeight`
  - `shieldMul`
  - `healthMul`
- `alwaysOffer` remains optional because it is a normal-node-specific control flag, not a universal node property.
- Browser-only temporary fields are excluded from the formal Godot loader contract.

### Leviathan / Progress Split

- Leviathan master data should own:
  - `id`
  - `name`
  - `stageCnt`
  - `runCnt`
- Clear state should not live in master data.
- Progress/save data should own:
  - `clearedLeviathanIds`

### Phase Record Structure

- Root common state:
  - `seed`
  - `stageIndex`
  - `maxStages`
  - `inventory`
  - `leviathanId`
  - `runIndex`
- `node_select` phase state:
  - `candidates`
- `combat` phase state:
  - `combat`
- `reward_loot` phase state:
  - `pendingRewards`
  - `held`
  - `lastNodeLabel`
- `lastClearWeakness` was intentionally dropped from the future contract.

### UI / Transition Boundary

- Production UI keeps the `character / backpack / terrain` combat layout plus `queue` and `hp/shield`.
- Combat backpack is read-only.
- Reward backpack is editable and shares the same underlying inventory state.
- `reward tray` and artifact-removal UI belong inside the reward page.
- The reward transition must preserve the same inventory state across the combat-clear-to-reward boundary without a frame mismatch.
- Current fixed debug UI (`freeze-test`, `mono-color-mode`, `output`, `dev-hint`) is outside production scope and should be generated only when explicitly needed.
- `ghost` and `floating-text` remain valid production-facing presentation affordances.
- Browser `DOM overlay` is not a production UI contract; Godot should replace it with engine-native overlay layers/scenes.

### Reward Direction

- Reward data should move to JSON.
- M1 reward flow includes artifact pickup/placement/removal.
- Artifact rewards appear in batches of 1~5 and are all acquired, not chosen from a pick-one list.
- Artifact reward JSON should at least include:
  - `id`
  - `name`
  - `rarity`
  - `shape`
  - `energyType`
  - `baseCooldownTicks`
  - `synergy`
  - `keyword`
  - `sellValue`
- Longer-term reward/progression direction:
  - run-clear yields artifact items that can be sold plus experience
  - level-ups unlock Leviathans, artifacts, and traits
  - rarity ladder is `normal / rare / heroic / legendary / mythic`

## Remaining Gaps

- The redesign gate defines M1 contracts, but those contracts are not yet fully realized in code.
- Reward JSON, Leviathan/progress data, loaders/validators, and replay-promotion coverage remain M1 implementation work.
- The browser prototype still contains runtime/state shapes that do not yet match the redesigned M1 contract end-to-end.
