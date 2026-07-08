# M5 Obstacle And Backpack Relic Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the first playable M5 slice with cell-bound obstacle families, missed-obstacle debt escalation, and backpack-equipped relic items that use diagonal or one-gap links.

**Architecture:** Extend the existing formal combat path instead of replacing it: enrich `CombatSimulator` and `CombatVocab` with obstacle state, keep combat projection flowing through `CombatPhase` and `CombatSceneModel`, and add relic support by treating relics as a third `item_type` inside `Artifact` and `InventoryModel`. Keep the launch set to the approved eight relics and implement obstacle pressure through pure dictionaries plus tick-based reducers so UI can read the same state without controller-only logic.

**Tech Stack:** Godot 4.3 GDScript, JSON content tables, existing pure vocabulary/reducer pattern, existing contract tests under `app-LTL/tests`.

---

### Task 1: Lock Red Tests For Relic Links And Queue Semantics

**Files:**
- Modify: `app-LTL/tests/test_backpack_vocab.gd`
- Modify: `app-LTL/tests/test_combat_vocab.gd`

- [ ] **Step 1: Write the failing backpack relic tests**

```gdscript
func test_relics_do_not_generate_queue_energy() -> void:
	var inv := InventoryScript.new(6, 6)
	var relic = ArtifactScript.new({"id": "tool_rack", "name": "Tool Rack", "shape": [[1]], "item_type": "relic", "effect_schema": {"link_mode": "diagonal_1"}})
	inv.place_artifact(relic, 2, 2)
	var generated := inv.tick()
	_assert_eq(generated.size(), 0, "relics never generate queue energy")

func test_relic_diagonal_links_ignore_orthogonal_neighbors() -> void:
	var inv := InventoryScript.new(6, 6)
	var relic = ArtifactScript.new({"id": "tool_rack", "name": "Tool Rack", "shape": [[1]], "item_type": "relic", "effect_schema": {"link_mode": "diagonal_1"}})
	var drill = _artifact("red_a", "red", [[1]])
	inv.place_artifact(relic, 2, 2)
	inv.place_artifact(drill, 3, 3)
	_assert_eq(inv.get_relic_linked_artifacts(relic).size(), 1, "diagonal relic links a corner target")
```

- [ ] **Step 2: Run the focused backpack test file to verify failure**

Run: `Godot_v4.3-stable_win64_console.exe --headless --path app-LTL --script tests/test_backpack_vocab.gd`
Expected: FAIL with missing `get_relic_linked_artifacts` or relic energy behavior mismatch.

- [ ] **Step 3: Write the failing combat queue and obstacle-support tests**

```gdscript
func test_queue_items_keep_dictionary_shape_when_inventory_generates_energy() -> void:
	var inv := InventoryScript.new(4, 4)
	inv.place_artifact(_artifact("red_a", "red"), 0, 0)
	var sim := CombatSimulatorScript.new({"combat": {"shield": 1.0, "health": 1.0, "maxShield": 1.0, "maxHealth": 1.0}}, {}, 3)
	CombatVocabScript.tick_combat(sim, 10, inv)
	_assert(sim.queue[0] is Dictionary, "queue item keeps structured token")
	_assert_eq(str(sim.queue[0].get("color", "")), "red", "queue token stores color")
```

- [ ] **Step 4: Run the focused combat test file to verify failure**

Run: `Godot_v4.3-stable_win64_console.exe --headless --path app-LTL --script tests/test_combat_vocab.gd`
Expected: FAIL because queue items are still plain strings.

### Task 2: Implement Relic-Aware Artifact And Inventory Behavior

**Files:**
- Modify: `app-LTL/src/models/Artifact.gd`
- Modify: `app-LTL/src/models/InventoryModel.gd`
- Modify: `app-LTL/src/vocabulary/combat/RecalculateQueueColors.gd`

- [ ] **Step 1: Add minimal relic-safe artifact behavior**

```gdscript
func tick() -> Variant:
	if is_broken:
		return null
	if freeze_ticks > 0:
		freeze_ticks -= 1
		return null
	if item_type == "beacon" or item_type == "relic":
		return null
```

- [ ] **Step 2: Add relic link helpers to inventory**

```gdscript
func get_relic_linked_artifacts(relic: Artifact) -> Array:
	var mode := str(relic.effect_schema.get("link_mode", ""))
	if mode == "skip_2":
		return _linked_by_skip_two(relic)
	return _linked_by_diagonal(relic)
```

- [ ] **Step 3: Return structured queue tokens instead of color strings**

```gdscript
generated.append({
	"color": str(energy),
	"source_artifact_id": art.id,
	"source_item_type": art.item_type
})
```

- [ ] **Step 4: Re-run focused backpack and combat tests**

Run: `Godot_v4.3-stable_win64_console.exe --headless --path app-LTL --script tests/test_backpack_vocab.gd`
Expected: PASS or fail only on the next unimplemented assertions.

Run: `Godot_v4.3-stable_win64_console.exe --headless --path app-LTL --script tests/test_combat_vocab.gd`
Expected: PASS or fail only on obstacle-specific assertions.

### Task 3: Add Obstacle State And Exit-Failure Escalation

**Files:**
- Modify: `app-LTL/src/models/CombatSimulator.gd`
- Modify: `app-LTL/src/models/HazardModel.gd`
- Modify: `app-LTL/src/vocabulary/CombatVocab.gd`
- Modify: `app-LTL/src/phases/CombatPhase.gd`
- Modify: `app-LTL/src/MainControllerRuntime.gd`

- [ ] **Step 1: Write the failing obstacle tests in combat contracts**

```gdscript
func test_red_obstacle_fails_when_host_cell_exits_and_cuts_time() -> void:
	var sim := _sim_with_queue("red", 10.0, 10.0)
	sim.obstacles = [{"id": "red_1", "family": "red", "cellId": "r0c9", "progress": 0, "clearProgress": 2}]
	CombatVocabScript.resolve_obstacle_shift_exit(sim, ["red_1"])
	_assert_eq(sim.time_limit_ticks, 2200, "red exit failure cuts remaining time")
```

- [ ] **Step 2: Run the combat tests to verify failure**

Run: `Godot_v4.3-stable_win64_console.exe --headless --path app-LTL --script tests/test_combat_vocab.gd`
Expected: FAIL because obstacle reducer APIs do not exist yet.

- [ ] **Step 3: Add obstacle fields to simulator and HUD state**

```gdscript
var obstacles: Array = []
var obstacle_miss_debt: Dictionary = {"red": 0, "blue": 0, "purple": 0, "green": 0}
```

- [ ] **Step 4: Add tick reducers for warning shifts, exit failures, and family effects**

```gdscript
static func _resolve_obstacle_fail(sim: CombatSimulator, obstacle: Dictionary) -> void:
	match str(obstacle.get("family", "")):
		"red":
			sim.time_limit_ticks = maxi(sim.elapsed_ticks + 20, sim.time_limit_ticks - int(obstacle.get("timeCutTicks", 240)))
```

- [ ] **Step 5: Make battlefield shifts happen every one second and trigger obstacle exit resolution**

```gdscript
const TERRAIN_SHIFT_SECONDS := 1.0
const TERRAIN_SHIFT_TICKS := int(round(TERRAIN_SHIFT_SECONDS * COMBAT_TICKS_PER_SECOND))
```

- [ ] **Step 6: Re-run focused combat and UI tests**

Run: `Godot_v4.3-stable_win64_console.exe --headless --path app-LTL --script tests/test_combat_vocab.gd`
Expected: PASS.

Run: `Godot_v4.3-stable_win64_console.exe --headless --path app-LTL --script tests/test_ui_read_models.gd`
Expected: FAIL only where HUD or labels still need relic/hazard updates.

### Task 4: Wire Launch Relics Through Rewards, Tooltips, And Content

**Files:**
- Modify: `app-LTL/src/data/reward-table.json`
- Modify: `app-LTL/src/vocabulary/RewardVocab.gd`
- Modify: `app-LTL/src/vocabulary/reward/CreateArtifactFromReward.gd`
- Modify: `app-LTL/src/ui/TextCatalog.gd`
- Modify: `app-LTL/src/ui/read_models/TooltipReadModel.gd`
- Modify: `app-LTL/tests/test_reward_contract.gd`
- Modify: `app-LTL/tests/test_ui_read_models.gd`

- [ ] **Step 1: Add the eight launch relic rewards and update reward-pool expectations**

```json
{
  "id": "reward_common_relic_breach_seal",
  "kind": "Breach Seal",
  "rarity": "common",
  "weight": 42,
  "payload": {
    "item_type": "relic",
    "energy_type": "",
    "shape": [[1]],
    "effect_schema": {
      "version": 1,
      "link_mode": "diagonal_1",
      "trigger": "on_obstacle_hit",
      "type": "obstacle_progress_bonus",
      "summary": "Linked drill gains +1 progress on its first obstacle hit each combat."
    }
  }
}
```

- [ ] **Step 2: Make reward typing understand relics**

```gdscript
if str(payload.get("item_type", payload.get("itemType", ""))).to_lower() == "relic":
	return "relic"
```

- [ ] **Step 3: Add UI labels and tooltip formatting for relics**

```gdscript
"item.relic": "Relic"
```

- [ ] **Step 4: Re-run reward and UI read-model tests**

Run: `Godot_v4.3-stable_win64_console.exe --headless --path app-LTL --script tests/test_reward_contract.gd`
Expected: PASS.

Run: `Godot_v4.3-stable_win64_console.exe --headless --path app-LTL --script tests/test_ui_read_models.gd`
Expected: PASS.

### Task 5: Run Broad Verification And Update Completion Docs

**Files:**
- Modify: `docs/codex-worklog/complete_LootingTheLeviathan_2026-06-03.md`
- Modify: `docs/codex-worklog/history_LootingTheLeviathan_2026-06-03.md`

- [ ] **Step 1: Run the full contract runner**

Run: `Godot_v4.3-stable_win64_console.exe --headless --path app-LTL --script tests/godot_contract_runner.gd`
Expected: `GODOT_CONTRACTS_OK`

- [ ] **Step 2: Run whitespace verification**

Run: `git diff --check`
Expected: no whitespace errors in touched files

- [ ] **Step 3: Update completion report with actual verification evidence**

```markdown
- Verification:
  - `tests/test_backpack_vocab.gd` PASS
  - `tests/test_combat_vocab.gd` PASS
  - `tests/test_reward_contract.gd` PASS
  - `tests/test_ui_read_models.gd` PASS
  - `tests/godot_contract_runner.gd` PASS
```
