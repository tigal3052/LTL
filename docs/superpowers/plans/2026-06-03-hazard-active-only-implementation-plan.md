# Hazard Active-Only Logic Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Remove the battlefield hazard warning phase so spawned hazards are immediately active, preserve optional clear-afterglow, and trigger family fail effects only when live hazards exit the right edge unresolved.

**Architecture:** Keep the gameplay state change centered in `CombatVocab.gd`, because that file already owns obstacle spawn, tick, clear, and exit behavior. Keep the visual rule change centered in `CellView.gd` by replacing the ad-hoc family line art with same-rect hazard textures and explicit alpha helpers so UI behavior stays testable.

**Tech Stack:** Godot 4.3, GDScript, headless SceneTree test runners, formal contract suite

---

### Task 1: Lock the new obstacle lifecycle with failing combat tests

**Files:**
- Create: `app-LTL/tests/run_test_combat_vocab.gd`
- Modify: `app-LTL/tests/test_combat_vocab.gd`

- [ ] **Step 1: Write the failing tests**

```gdscript
func test_spawned_obstacles_start_active_without_warning_phase() -> void:
	var sim := CombatSimulatorScript.new({"combat": {"shield": 10.0, "health": 10.0, "maxShield": 10.0, "maxHealth": 10.0}}, {}, 8)
	CombatVocabScript.prime_obstacles(sim, 17, 0, 1.0)
	_assert(not sim.obstacles.is_empty(), "prime obstacles spawns at least one active hazard")
	if sim.obstacles.is_empty():
		return
	_assert_eq(str(sim.obstacles[0].get("state", "")), "active", "spawned hazards skip warning and start active")

func test_purple_obstacle_exit_failure_triggers_pressure_pulse() -> void:
	var sim := _sim_with_queue("purple", 10.0, 10.0)
	sim.terrain_debuffs = [{"scope": "global", "effect": "weakened_terrain", "energy": "purple", "stacks": 1}]
	sim.obstacles = [_obstacle("haz_purple_exit", "purple", "r1c9")]
	CombatVocabScript.resolve_obstacle_shift_exit(sim, ["haz_purple_exit"])
	_assert_eq(sim.terrain_debuffs.size(), 0, "purple exit failure consumes one terrain debuff stack via the fail pulse")
	_assert_eq(int(sim.obstacle_miss_debt.get("purple", 0)), 1, "purple exit failure still adds miss debt")

func test_cleared_obstacle_without_afterglow_disappears_on_next_tick() -> void:
	var sim := _sim_with_queue("red", 10.0, 10.0)
	sim.obstacles = [_obstacle("haz_red_clear", "red", "r0c1", {"afterglowTicks": 0})]
	CombatVocabScript.fire_shot(sim, "red", "r0c1", {}, null)
	CombatVocabScript.tick_combat(sim, 1, null)
	_assert_eq(sim.obstacles.size(), 0, "zero-afterglow hazards leave no lingering shell")
```

- [ ] **Step 2: Run test to verify it fails**

Run: `D:\Programming\godot_workspace\bin\Godot_v4.3-stable_win64_console.exe --headless --path D:\Programming\ex_workspace\LootingTheLeviathan\app-LTL --script tests/run_test_combat_vocab.gd --quit`

Expected: FAIL because spawned hazards still start as `warning`, purple exit behavior is not isolated by a focused runner yet, and zero-afterglow clears still linger.

- [ ] **Step 3: Write minimal focused runner**

```gdscript
extends SceneTree

func _init() -> void:
	var TestCombatVocabClass = load("res://tests/test_combat_vocab.gd")
	if TestCombatVocabClass == null:
		push_error("Combat vocab test runner failed to load res://tests/test_combat_vocab.gd")
		quit(1)
		return
	var tester = TestCombatVocabClass.new()
	var test_res: Dictionary = tester.run_all_tests()
	if bool(test_res.get("ok", false)):
		print("COMBAT_VOCAB_TESTS_OK")
		quit(0)
		return
	for err in test_res.get("errors", []):
		push_error("Combat vocab test failed: %s" % err)
	quit(1)
```

- [ ] **Step 4: Run test to verify it still fails for the right reason**

Run: `D:\Programming\godot_workspace\bin\Godot_v4.3-stable_win64_console.exe --headless --path D:\Programming\ex_workspace\LootingTheLeviathan\app-LTL --script tests/run_test_combat_vocab.gd --quit`

Expected: FAIL with the new obstacle lifecycle assertions, not with a missing runner error.

- [ ] **Step 5: Commit**

```bash
git add app-LTL/tests/test_combat_vocab.gd app-LTL/tests/run_test_combat_vocab.gd
git commit -m "test: cover active-only hazard lifecycle"
```

### Task 2: Implement active-only obstacle lifecycle in combat logic

**Files:**
- Modify: `app-LTL/src/vocabulary/CombatVocab.gd`
- Test: `app-LTL/tests/test_combat_vocab.gd`

- [ ] **Step 1: Make new hazards spawn as active**

```gdscript
return {
	"id": "obs_%s_%d_%d" % [family, sim.obstacle_shift_count, ordinal],
	"family": family,
	"requiredColor": family,
	"cellId": cell_id,
	"state": "active",
	"progress": 0,
	"clearProgress": int(config.get("clearProgress", 2)),
	"afterglowTicks": int(config.get("afterglowTicks", OBSTACLE_AFTERGLOW_TICKS)),
	"afterglowTicksRemaining": 0,
	"timeCutTicks": int(config.get("timeCutTicks", 200)),
	"healAmount": float(config.get("healAmount", 1.0)),
	"pulseIntervalTicks": int(config.get("pulseIntervalTicks", 20)),
	"pulseTicksRemaining": int(config.get("pulseIntervalTicks", 20)),
	"visual": {"family": family, "pattern": "single_cell"}
}
```

- [ ] **Step 2: Remove warning countdown behavior from ticking and spawn-distance math**

```gdscript
static func _tick_obstacles(sim: CombatSimulator) -> void:
	# keep afterglow cleanup and purple active pulses only

static func _eligible_spawn_cell_ids(sim: CombatSimulator, family: String) -> Array:
	var min_shift_distance := OBSTACLE_MIN_REACTION_COLUMNS
```

- [ ] **Step 3: Make afterglow optional on clear**

```gdscript
static func _resolve_obstacle_clear(obstacle: Dictionary) -> void:
	obstacle["progress"] = int(obstacle.get("clearProgress", 2))
	obstacle["state"] = "afterglow_clear"
	obstacle["afterglowTicksRemaining"] = maxi(0, int(obstacle.get("afterglowTicks", OBSTACLE_AFTERGLOW_TICKS)))
```

- [ ] **Step 4: Run focused combat tests to verify green**

Run: `D:\Programming\godot_workspace\bin\Godot_v4.3-stable_win64_console.exe --headless --path D:\Programming\ex_workspace\LootingTheLeviathan\app-LTL --script tests/run_test_combat_vocab.gd --quit`

Expected: `COMBAT_VOCAB_TESTS_OK`

- [ ] **Step 5: Commit**

```bash
git add app-LTL/src/vocabulary/CombatVocab.gd app-LTL/tests/test_combat_vocab.gd app-LTL/tests/run_test_combat_vocab.gd
git commit -m "feat: make hazards active on spawn"
```

### Task 3: Replace obstacle line art with alpha-driven tile and hazard textures

**Files:**
- Modify: `app-LTL/src/ui/CellView.gd`
- Modify: `app-LTL/tests/test_ui_read_models.gd`
- Test: `app-LTL/tests/run_test_ui_read_models.gd`

- [ ] **Step 1: Write failing UI helper tests**

```gdscript
func test_cell_view_uses_tile_alpha_for_weakness_readability() -> void:
	_assert(abs(float(CellViewScript.base_tile_alpha_for(null)) - 0.5) < 0.01, "non-weakness tiles render semi-transparent")
	_assert(abs(float(CellViewScript.base_tile_alpha_for("red")) - 1.0) < 0.01, "weakness tiles render fully opaque")

func test_cell_view_projects_hazard_alpha_by_state() -> void:
	_assert(abs(float(CellViewScript.hazard_alpha_for({"state": "active"})) - 1.0) < 0.01, "active hazards render fully opaque")
	_assert(float(CellViewScript.hazard_alpha_for({"state": "afterglow_clear", "afterglowTicksRemaining": 3, "afterglowTicks": 12})) < 0.3, "afterglow hazards render as faint residue")
```

- [ ] **Step 2: Run UI read model tests to verify red**

Run: `D:\Programming\godot_workspace\bin\Godot_v4.3-stable_win64_console.exe --headless --path D:\Programming\ex_workspace\LootingTheLeviathan\app-LTL --script tests/run_test_ui_read_models.gd --quit`

Expected: FAIL because `CellView.gd` does not yet expose the alpha helpers and still draws custom family line art.

- [ ] **Step 3: Implement alpha helpers and same-rect hazard texture overlay**

```gdscript
static func base_tile_alpha_for(weakness_value: Variant) -> float:
	return 1.0 if weakness_value != null else 0.5

static func hazard_alpha_for(obstacle_data: Dictionary) -> float:
	var state := str(obstacle_data.get("state", ""))
	if state == "active":
		return 1.0
	if state == "afterglow_clear":
		return clampf(float(obstacle_data.get("afterglowTicksRemaining", 0)) / float(maxi(1, int(obstacle_data.get("afterglowTicks", 12)))) * 0.22, 0.0, 0.22)
	return 0.0
```

- [ ] **Step 4: Run UI read model tests to verify green**

Run: `D:\Programming\godot_workspace\bin\Godot_v4.3-stable_win64_console.exe --headless --path D:\Programming\ex_workspace\LootingTheLeviathan\app-LTL --script tests/run_test_ui_read_models.gd --quit`

Expected: `UI_READ_MODEL_TESTS_OK`

- [ ] **Step 5: Commit**

```bash
git add app-LTL/src/ui/CellView.gd app-LTL/tests/test_ui_read_models.gd
git commit -m "feat: render hazards with tile-alpha readability"
```

### Task 4: Refresh docs and final verification

**Files:**
- Modify: `docs/superpowers/specs/2026-06-03-hazard-tile-visual-design.ko.md`
- Modify: `docs/codex-worklog/plan_LootingTheLeviathan_2026-06-03.md`
- Modify: `docs/codex-worklog/history_LootingTheLeviathan_2026-06-03.md`
- Modify: `docs/codex-worklog/complete_LootingTheLeviathan_2026-06-03.md`

- [ ] **Step 1: Update the spec from warning/active/afterglow to active/afterglow/exit-fail**

```md
- hazards spawn directly as `active`
- `warning` state is removed from runtime logic and UI
- unresolved right-edge exit triggers only the family fail effect path
```

- [ ] **Step 2: Run final focused verification**

Run:
- `D:\Programming\godot_workspace\bin\Godot_v4.3-stable_win64_console.exe --headless --path D:\Programming\ex_workspace\LootingTheLeviathan\app-LTL --script tests/run_test_combat_vocab.gd --quit`
- `D:\Programming\godot_workspace\bin\Godot_v4.3-stable_win64_console.exe --headless --path D:\Programming\ex_workspace\LootingTheLeviathan\app-LTL --script tests/run_test_ui_read_models.gd --quit`
- `git diff --check`

Expected:
- `COMBAT_VOCAB_TESTS_OK`
- `UI_READ_MODEL_TESTS_OK`
- no whitespace errors

- [ ] **Step 3: Commit**

```bash
git add docs/superpowers/specs/2026-06-03-hazard-tile-visual-design.ko.md docs/codex-worklog/plan_LootingTheLeviathan_2026-06-03.md docs/codex-worklog/history_LootingTheLeviathan_2026-06-03.md docs/codex-worklog/complete_LootingTheLeviathan_2026-06-03.md
git commit -m "docs: sync hazard active-only design"
```
