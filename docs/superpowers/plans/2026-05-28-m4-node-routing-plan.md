# M4 Node Routing Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Promote M4 node routing into the formal Godot path with deterministic offers, final-stage boss routing, selected-node combat modifiers, and readable node-map projections.

**Architecture:** Keep `NodeVocab.gd` as deterministic offer generation and `NodeSelectPhase.gd` as phase transition ownership. Add one modifier capsule so selected node metadata becomes explicit combat/reward/hazard state instead of hidden UI labels.

**Tech Stack:** Godot 4.3, GDScript, headless contract runner.

---

### Task 1: Contract Tests

**Files:**
- Create: `app-LTL/tests/test_node_routing_contract.gd`
- Modify: `app-LTL/tests/godot_contract_runner.gd`

- [ ] **Step 1: Write failing tests**

Add tests for deterministic candidate generation, normal guarantee, final-stage boss pinning, selected-node modifier transfer, read-model field projection, and validator required fields.

- [ ] **Step 2: Run tests to verify red**

Run:

```powershell
& 'D:\Programming\godot_workspace\bin\Godot_v4.3-stable_win64_console.exe' --headless --path 'D:\Programming\ex_workspace\LootingTheLeviathan\app-LTL' --script tests/godot_contract_runner.gd --quit
```

Expected: failure labels mention missing node routing implementation details.

### Task 2: Formal Node Data And Modifier Capsule

**Files:**
- Create: `app-LTL/src/data/node-table.json`
- Create: `app-LTL/src/vocabulary/node/ApplyNodeModifiers.gd`

- [ ] **Step 1: Add formal node rows**

Include normal, color-weakness, mixed-weakness, hazard-rich, repair-event, and boss rows with shield/health multipliers and route metadata.

- [ ] **Step 2: Add modifier translation**

Create `ApplyNodeModifiers.apply(choice, tuning)` returning a cloned candidate with normalized combat, node, hazard, reward, and telemetry fields.

### Task 3: Wire Routing Into Runtime

**Files:**
- Modify: `app-LTL/src/vocabulary/NodeVocab.gd`
- Modify: `app-LTL/src/phases/NodeSelectPhase.gd`
- Modify: `app-LTL/src/process/HeadlessMiniRun.gd`
- Modify: `app-LTL/src/phases/CombatPhase.gd`

- [ ] **Step 1: Normalize generated candidates**

Clamp candidate count through tuning, keep normal included, add boss on final stage, and attach route metadata.

- [ ] **Step 2: Apply selected-node modifiers**

Call `ApplyNodeModifiers` from `NodeSelectPhase`, preserve node metadata on combat state, and carry reward modifier into clear rewards without changing existing reward internals.

### Task 4: Read Model Projection

**Files:**
- Modify: `app-LTL/src/ui/SceneReadModel.gd`
- Modify: `app-LTL/src/ui/read_models/NodeSelectReadModel.gd`

- [ ] **Step 1: Expose player-facing route fields**

Project type, risk, reward bias, hint, final distance, and route hash.

- [ ] **Step 2: Keep generator internals private**

Do not expose raw pick weights or pool internals.

### Task 5: Verification

**Files:**
- Modify: `docs/codex-worklog/*_LootingTheLeviathan_2026-05-28.md`

- [ ] **Step 1: Run Godot contract suite**
- [ ] **Step 2: Run compile wrapper**
- [ ] **Step 3: Run `git diff --check`**
- [ ] **Step 4: Update worklog completion**
