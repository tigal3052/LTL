# Tech Debt Tracker

This tracker captures debt that is already visible at the M0 redesign gate and must be handled or consciously deferred before and during M1.

## Active Debt

### TD-001. Browser prototype contracts are not yet formalized as loader-facing schemas

- Status: Open
- Source: M0 redesign gate, post-M0 handoff decisions
- Affected areas:
  - `app-LTL/src/data/artifact-table.json`
  - `app-LTL/src/data/node-table.json`
  - reward / leviathan / progress data definitions do not yet exist as formal JSON contracts
- Risk:
  - Godot-side loaders and validators would be forced to infer browser-only structure.
  - Required-vs-optional field boundaries are still partly implicit in code.
- Target milestone: M1
- Expected action:
  - Create formal artifact, node, reward, leviathan, and progress schemas.
  - Add validator coverage for missing required fields.

### TD-002. Replay regression coverage is below the redesigned gate contract

- Status: Open
- Source: M0 redesign gate decision set
- Affected areas:
  - `app-LTL/tests/p0_replay.test.js`
  - `app-LTL/tests/fixtures/input_logs/*`
- Risk:
  - Current replay fixtures do not yet cover the full M1-required SoT matrix.
  - Browser-verified behavior could drift without fixture promotion.
- Target milestone: M1
- Expected action:
  - Promote fixture/replay coverage for:
    - one-shot clear
    - empty-queue repair pressure
    - mismatch attack
    - reward claim to next stage
    - final stage to run complete
    - run-complete branching
    - reward-phase last-artifact removal guard

### TD-003. Phase/root state contract exists in code, but not in a stabilized domain API

- Status: Open
- Source: M0 redesign gate decision set
- Affected areas:
  - `app-LTL/src/phases/*`
  - `app-LTL/src/process/mini-run-stage-script.js`
  - `app-LTL/src/process/headless-mini-run.js`
- Risk:
  - Renderers and tests may continue to depend on internal shape details instead of a stable public contract.
  - Root-state additions such as `leviathanId` and `runIndex` are not yet represented end-to-end.
- Target milestone: M1
- Expected action:
  - Stabilize root state and phase-specific records.
  - Publish a domain-facing snapshot/API contract for UI consumers.

### TD-004. Reward domain is still split between browser-era UI rewards and future progression rewards

- Status: Open
- Source: P4 implementation history, M0 redesign gate decisions
- Affected areas:
  - `app-LTL/src/domain/reward-resolver.js`
  - `app-LTL/src/vocabulary/reward/*`
  - `app-LTL/src/phases/reward-loot-phase.js`
- Risk:
  - Current reward generation is not yet aligned with the redesigned JSON reward model.
  - Progression rewards, rarity, sell value, and unlock-driven reward semantics are not yet unified.
- Target milestone: M1
- Expected action:
  - Move reward data to JSON.
  - Formalize artifact reward fields and progression-related reward boundaries.

### TD-005. Leviathan/progress model is not yet represented in runtime data

- Status: Open
- Source: M0 redesign gate decisions
- Affected areas:
  - no dedicated leviathan/progress JSON or loader yet
- Risk:
  - Stage/run counts remain hard-coded or prototype-driven.
  - Clear state would be easy to place in the wrong layer without a formal progress model.
- Target milestone: M1
- Expected action:
  - Add leviathan master data with `id`, `name`, `stageCnt`, `runCnt`.
  - Add progress data with `clearedLeviathanIds`.

### TD-006. Browser UI still contains prototype-only debug and transition assumptions

- Status: Open
- Source: M0 redesign gate decisions
- Affected areas:
  - `app-LTL/public/index.html`
  - `app-LTL/src/ui/mini-run-app.js`
- Risk:
  - UI-specific debug affordances can leak into engine-port scope.
  - Reward transition behavior is not yet encoded as a formal domain contract.
- Target milestone: M2+
- Expected action:
  - Keep the debug UI stripped from production scope.
  - Treat Godot overlay/transition implementation as a scene-layer concern, not a domain concern.

## Deferred by Design

### D-001. Full Leviathan progression, unlock loop, and meta growth implementation

- Status: Deferred intentionally
- Reason:
  - M0 decided the contracts for XP, unlocks, and clear-tracking must be documented early, but full player-progression implementation should not block core domain stabilization.
- Earliest target milestone: M3+

### D-002. Final Godot scene composition for reward page and terrain-to-reward transition

- Status: Deferred intentionally
- Reason:
  - The transition contract is decided at M0, but the final engine-side scene realization belongs after the core domain contracts are stable.
- Earliest target milestone: M2+
