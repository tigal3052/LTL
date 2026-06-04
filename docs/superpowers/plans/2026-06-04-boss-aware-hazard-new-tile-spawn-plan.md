# Boss-Aware Hazard New-Tile Spawn Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace active-count hazard replenishment with new-tile-only probability spawning, while allowing bosses and special nodes to override spawn chance, families, and wave caps.

**Architecture:** Keep combat lifecycle ownership in `CombatVocab.gd`, but extract new-tile candidate selection and profile evaluation into a focused combat helper so spawn policy stays isolated from obstacle effect logic. Keep node-specific tuning in node metadata by extending the existing `combat.hazard` snapshot rather than adding a separate global system.

**Tech Stack:** Godot 4.3, GDScript, headless combat tests, formal node/combat runtime snapshots

---

### Task 1: Lock boss-aware new-tile spawn behavior with failing tests

**Files:**
- Modify: `app-LTL/tests/test_combat_vocab.gd`

- [ ] **Step 1: Write the failing tests**

```gdscript
func test_shift_obstacle_spawn_respects_zero_chance_without_backfill() -> void:
	var sim := CombatSimulatorScript.new({
		"combat": {
			"shield": 10.0,
			"health": 10.0,
			"maxShield": 10.0,
			"maxHealth": 10.0,
			"hazard": {
				"allowedFamilies": ["red"],
				"spawn": {"chance": 0.0, "maxPerShift": 3, "maxInitialSpawns": 0}
			}
		}
	}, {}, 8)
	CombatVocabScript.shift_battlefield(sim, 17, ["red", "blue", "purple", "green"], 1, 0, 1.0)
	_assert_eq(sim.obstacles.size(), 0, "zero spawn chance prevents target-count backfill on new tiles")

func test_shift_obstacle_spawn_can_fill_multiple_new_tiles_with_multiple_families() -> void:
	var sim := CombatSimulatorScript.new({
		"combat": {
			"shield": 10.0,
			"health": 10.0,
			"maxShield": 10.0,
			"maxHealth": 10.0,
			"hazard": {
				"allowedFamilies": ["red", "blue", "purple"],
				"spawn": {"chance": 1.0, "maxPerShift": 3, "maxInitialSpawns": 6}
			}
		}
	}, {}, 8)
	CombatVocabScript.shift_battlefield(sim, 17, ["red", "blue", "purple", "green"], 1, 0, 1.0)
	_assert_eq(sim.obstacles.size(), 3, "boss-like shift can fill all three new tiles")
```

- [ ] **Step 2: Run test to verify it fails**

Run: `powershell -ExecutionPolicy Bypass -File .\tools\invoke-godot.ps1 -Script res://tests/run_test_combat_vocab.gd -Headless -Quit`
Expected: FAIL because combat still backfills to a target active count and does not honor any `hazard.spawn` override profile.

- [ ] **Step 3: Commit**

```bash
git add app-LTL/tests/test_combat_vocab.gd
git commit -m "test: lock boss-aware new-tile hazard spawning"
```

### Task 2: Implement hazard spawn profiles and new-tile-only selection

**Files:**
- Create: `app-LTL/src/vocabulary/combat/SpawnNewTileObstacles.gd`
- Modify: `app-LTL/src/models/CombatSimulator.gd`
- Modify: `app-LTL/src/vocabulary/CombatVocab.gd`

- [ ] **Step 1: Add the focused helper**

```gdscript
class_name SpawnNewTileObstacles
extends RefCounted

static func shift_inserted_cell_ids(rows: int) -> Array:
	var ids: Array = []
	for row in range(rows):
		ids.append("r%dc0" % row)
	return ids
```

- [ ] **Step 2: Replace target-active replenishment with new-tile rolls**

```gdscript
var inserted_cell_ids := SpawnNewTileObstaclesScript.shift_inserted_cell_ids(sim.battlefield_rows)
var spawn_requests := SpawnNewTileObstaclesScript.roll_shift_wave(sim, inserted_cell_ids, seed_val, shift_step, hazard_modifier)
for request in spawn_requests:
	sim.obstacles.append(_build_obstacle_definition(sim, str(request["family"]), str(request["cellId"]), stage_index, ordinal))
```

- [ ] **Step 3: Run the focused combat tests to verify green**

Run: `powershell -ExecutionPolicy Bypass -File .\tools\invoke-godot.ps1 -Script res://tests/run_test_combat_vocab.gd -Headless -Quit`
Expected: `COMBAT_VOCAB_TESTS_OK`

- [ ] **Step 4: Commit**

```bash
git add app-LTL/src/vocabulary/combat/SpawnNewTileObstacles.gd app-LTL/src/models/CombatSimulator.gd app-LTL/src/vocabulary/CombatVocab.gd
git commit -m "feat: spawn hazards only from new terrain tiles"
```

### Task 3: Wire node hazard metadata for boss and gimmick overrides

**Files:**
- Modify: `app-LTL/src/vocabulary/node/ApplyNodeModifiers.gd`
- Modify: `app-LTL/src/data/node-table.json`

- [ ] **Step 1: Carry explicit spawn metadata through combat hazard snapshots**

```gdscript
combat["hazard"] = {
	"tier": str(result.get("riskTier", "safe")),
	"modifier": hazard_modifier,
	"sourceNodeId": str(result.get("id", "")),
	"allowedFamilies": EnergyTempoBalanceScript.normalized_colors(result.get("weakness", []), true),
	"spawn": result.get("hazardSpawn", {}).duplicate(true)
}
```

- [ ] **Step 2: Give at least the boss node an explicit multicolor high-pressure profile**

```json
"hazardSpawn": {
  "chance": 0.72,
  "maxPerShift": 3,
  "maxInitialSpawns": 6,
  "allowedFamilies": ["red", "blue", "purple"]
}
```

- [ ] **Step 3: Run the focused combat tests again**

Run: `powershell -ExecutionPolicy Bypass -File .\tools\invoke-godot.ps1 -Script res://tests/run_test_combat_vocab.gd -Headless -Quit`
Expected: `COMBAT_VOCAB_TESTS_OK`

- [ ] **Step 4: Commit**

```bash
git add app-LTL/src/vocabulary/node/ApplyNodeModifiers.gd app-LTL/src/data/node-table.json
git commit -m "feat: allow node hazard spawn overrides"
```

### Task 4: Final verification and worklog sync

**Files:**
- Modify: `docs/codex-worklog/plan_LootingTheLeviathan_2026-06-04.md`
- Modify: `docs/codex-worklog/history_LootingTheLeviathan_2026-06-04.md`
- Modify: `docs/codex-worklog/complete_LootingTheLeviathan_2026-06-04.md`

- [ ] **Step 1: Run final verification**

Run:
- `powershell -ExecutionPolicy Bypass -File .\tools\invoke-godot.ps1 -Script res://tests/run_test_combat_vocab.gd -Headless -Quit`
- `git diff --check`

Expected:
- `COMBAT_VOCAB_TESTS_OK`
- no whitespace errors

- [ ] **Step 2: Commit**

```bash
git add docs/codex-worklog/plan_LootingTheLeviathan_2026-06-04.md docs/codex-worklog/history_LootingTheLeviathan_2026-06-04.md docs/codex-worklog/complete_LootingTheLeviathan_2026-06-04.md
git commit -m "docs: sync hazard new-tile spawn worklog"
```
