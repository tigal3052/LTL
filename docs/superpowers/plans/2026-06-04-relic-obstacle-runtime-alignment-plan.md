# Relic Obstacle Runtime Alignment Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Align relic runtime behavior and reward data with the active-only obstacle model, the new `activate` / `execute` terminology, and the requested rarity expansion.

**Architecture:** Keep the runtime changes centered in the existing combat reducer path so obstacle lifecycle and relic triggers stay in one place. Use a thin combat-time relic state dictionary on `CombatSimulator`, wire the requested effects through explicit obstacle-hit / obstacle-clear / obstacle-execute / weakness-hit hooks, and update reward-table contracts plus localized player-facing summaries in parallel.

**Tech Stack:** Godot GDScript, JSON reward content, headless contract tests in `app-LTL/tests`

---

### Task 1: Lock the new relic contract with failing tests

**Files:**
- Modify: `app-LTL/tests/test_reward_contract.gd`
- Modify: `app-LTL/tests/test_combat_vocab.gd`
- Test: `app-LTL/tests/godot_contract_runner.gd`
- Test: `app-LTL/tests/run_test_combat_vocab.gd`

- [ ] **Step 1: Write failing reward-contract expectations for the revised relic pool**

Add or update expectations so the suite requires:

- `Brake Coil` rarity `legendary`
- `Anchor Oathplate` rarity `epic`
- `3` new `rare` relics
- `1` new `epic` relic
- updated total relic count and per-rarity type distributions

Target sections:

```gdscript
func test_reward_table_includes_launch_relic_slice() -> void:
	var expected_launch := {
		"reward_common_relic_breach_seal": {"kind": "Breach Seal", "rarity": "common", "link_mode": "diagonal_1"},
		"reward_common_relic_warning_bell": {"kind": "Warning Bell", "rarity": "common", "link_mode": "skip_2"},
		"reward_common_relic_spare_fuse": {"kind": "Spare Fuse", "rarity": "common", "link_mode": "diagonal_1"},
		"reward_legendary_relic_brake_coil": {"kind": "Brake Coil", "rarity": "legendary", "link_mode": "diagonal_1"},
		"reward_common_relic_tool_rack": {"kind": "Tool Rack", "rarity": "common", "link_mode": "diagonal_1"},
		"reward_common_relic_repair_coil": {"kind": "Repair Coil", "rarity": "common", "link_mode": "diagonal_1"},
		"reward_rare_relic_pinbreaker_spring": {"kind": "Pinbreaker Spring", "rarity": "rare", "link_mode": "diagonal_1"},
		"reward_epic_relic_anchor_oathplate": {"kind": "Anchor Oathplate", "rarity": "epic", "link_mode": "skip_2"},
		"reward_rare_relic_sealant_patch": {"kind": "Sealant Patch", "rarity": "rare", "link_mode": ""},
		"reward_rare_relic_debris_chalk": {"kind": "Debris Chalk", "rarity": "rare", "link_mode": ""},
		"reward_rare_relic_counterflow_governor": {"kind": "Counterflow Governor", "rarity": "rare", "link_mode": ""},
		"reward_epic_relic_recovery_winch": {"kind": "Recovery Winch", "rarity": "epic", "link_mode": ""}
	}
```

Update pool-count expectations to:

```gdscript
var expected_counts := {"common": 13, "rare": 16, "epic": 18, "legendary": 13, "mythic": 8}
var expected_type_counts := {
	"common": {"drill": 4, "beacon": 4, "relic": 5},
	"rare": {"drill": 4, "beacon": 8, "relic": 4},
	"epic": {"drill": 8, "beacon": 8, "relic": 2},
	"legendary": {"drill": 4, "beacon": 8, "relic": 1},
	"mythic": {"drill": 4, "beacon": 4, "relic": 0}
}
_assert_eq(rewards.size(), 68, "expanded reward table has exactly 68 artifacts")
_assert_eq(total_relics, 12, "expanded pool has the approved twelve relics")
```

- [ ] **Step 2: Write failing combat-vocab tests for the requested runtime behavior**

Add tests covering:

- `Warning Bell` blocks the first obstacle execute without fail effect or miss debt
- `Spare Fuse` suppresses one blue obstacle's active tax and execute debt
- `Brake Coil` adds `20` ticks when an obstacle is cleared
- `Anchor Oathplate` turns every weakness marker into the triggering color after `5` weakness hits

Add tests shaped like:

```gdscript
func test_warning_bell_blocks_first_obstacle_execute() -> void:
	var inv := InventoryScript.new(6, 6)
	var relic := _relic("warning_bell", "Warning Bell", {"type": "prevent_first_execute", "trigger": "on_obstacle_execute"})
	inv.place_artifact(relic, 1, 1)
	var sim := _sim_with_queue("red", 10.0, 10.0)
	sim.elapsed_ticks = 100
	sim.time_limit_ticks = 700
	sim.obstacles = [_obstacle("haz_red_exit", "red", "r0c9", {"timeCutTicks": 240})]
	CombatVocabScript.resolve_obstacle_shift_exit(sim, ["haz_red_exit"], inv)
	_assert_eq(sim.time_limit_ticks, 700, "warning bell blocks the first execute time cut")
	_assert_eq(int(sim.obstacle_miss_debt.get("red", 0)), 0, "warning bell blocks execute miss debt")
```

```gdscript
func test_brake_coil_adds_time_when_obstacle_clears() -> void:
	var inv := InventoryScript.new(6, 6)
	var relic := _relic("brake_coil", "Brake Coil", {"type": "clear_add_time", "trigger": "on_obstacle_clear"})
	inv.place_artifact(relic, 1, 1)
	var sim := _sim_with_queue("red", 10.0, 10.0)
	sim.time_limit_ticks = 600
	sim.obstacles = [_obstacle("haz_red_clear", "red", "r0c1", {"afterglowTicks": 0, "clearProgress": 1})]
	CombatVocabScript.fire_shot(sim, "red", "r0c1", {}, inv)
	_assert_eq(sim.time_limit_ticks, 620, "brake coil adds one second when an obstacle is removed")
```

- [ ] **Step 3: Run tests to verify they fail for the right reason**

Run:

```powershell
godot --headless --path app-LTL res://tests/run_test_combat_vocab.gd --quit
```

Expected: FAIL with new relic-behavior assertions.

Run:

```powershell
godot --headless --path app-LTL res://tests/godot_contract_runner.gd --quit
```

Expected: FAIL on the revised reward relic-count / rarity expectations.

### Task 2: Add combat-time relic state and wire obstacle lifecycle hooks

**Files:**
- Modify: `app-LTL/src/models/CombatSimulator.gd`
- Modify: `app-LTL/src/phases/CombatPhase.gd`
- Modify: `app-LTL/src/vocabulary/CombatVocab.gd`

- [ ] **Step 1: Add persistent relic runtime state to combat snapshots**

Extend `CombatSimulator` with a serialized dictionary:

```gdscript
var relic_runtime: Dictionary = {}
```

Initialize and export it:

```gdscript
relic_runtime = combat_data.get("relicRuntime", {}).duplicate(true)
```

```gdscript
"relicRuntime": relic_runtime.duplicate(true),
```

Mirror the field during `CombatPhase.reduce(...)` rehydration:

```gdscript
sim.relic_runtime = combat_dict.get("relicRuntime", {}).duplicate(true)
```

- [ ] **Step 2: Add minimal relic-runtime helpers inside `CombatVocab.gd`**

Add helper functions for:

- reading equipped relics from `InventoryModel`
- checking relic `effect_schema.type`
- tracking once-per-combat charges in `sim.relic_runtime`
- tracking shot buffs and weakness-hit counters

Shape:

```gdscript
static func _equipped_relics(inventory: InventoryModel) -> Array:
static func _relics_with_type(inventory: InventoryModel, effect_type: String) -> Array:
static func _runtime_bucket(sim: CombatSimulator, key: String) -> Dictionary:
static func _consume_once(sim: CombatSimulator, relic_id: String) -> bool:
static func _increment_relic_counter(sim: CombatSimulator, relic_id: String, amount: int = 1) -> int:
```

- [ ] **Step 3: Rename runtime hook intent around obstacle execute / clear / weakness-hit**

Keep obstacle model fields unchanged, but make the hook names explicit:

- obstacle appears on the field: `activate`
- unresolved right-edge fail effect: `execute`
- player-cleared removal: `clear`

Implement hook helpers:

```gdscript
static func _maybe_protect_blue_activation(sim: CombatSimulator, obstacle: Dictionary, inventory: InventoryModel) -> void:
static func _before_obstacle_execute(sim: CombatSimulator, obstacle: Dictionary, inventory: InventoryModel) -> bool:
static func _after_obstacle_clear(sim: CombatSimulator, obstacle: Dictionary, inventory: InventoryModel, source_artifact_id: String, energy_color: String) -> void:
static func _after_weakness_hit(sim: CombatSimulator, inventory: InventoryModel, target_color: String, energy_color: String) -> void:
```

- [ ] **Step 4: Wire the new hooks into the combat flow**

Use the new helpers from:

- obstacle spawn/build path for blue activation protection
- obstacle exit fail path for execute prevention
- obstacle clear path for clear rewards
- shot path for weakness-hit counting

Critical call sites:

```gdscript
static func fire_shot(...):
```

```gdscript
static func resolve_obstacle_shift_exit(...):
```

```gdscript
static func _apply_obstacle_hit(...):
```

```gdscript
static func _build_obstacle_definition(...):
```

### Task 3: Make the requested existing relics actually behave

**Files:**
- Modify: `app-LTL/src/vocabulary/CombatVocab.gd`
- Modify: `app-LTL/src/models/InventoryModel.gd`

- [ ] **Step 1: Make `Tool Rack` a real linked passive**

Apply linked cooldown trim during inventory synergy recalculation:

```gdscript
for relic_id in artifacts:
	var relic: Artifact = artifacts[relic_id]
	if relic.item_type != "relic":
		continue
	if str(relic.effect_schema.get("type", "")) != "cooldown_trim":
		continue
	var trim := abs(int(relic.effect_schema.get("value", 0)))
	for linked_artifact in get_relic_linked_artifacts(relic):
		if linked_artifact is Artifact and linked_artifact.item_type == "drill":
			linked_artifact.synergy_cooldown_reduction += trim
```

- [ ] **Step 2: Make `Breach Seal` add first-hit obstacle progress**

In the obstacle-hit path, if the firing drill is linked to an unused `obstacle_progress_bonus` relic, add `+1` progress and consume that relic's once-per-combat charge.

- [ ] **Step 3: Make `Repair Coil` buff the next two linked shots**

When repair ends, grant `2` charges to linked drills through `sim.relic_runtime["shotBuffs"]`, then spend one charge per fired shot and multiply shot damage for those charges.

- [ ] **Step 4: Make `Pinbreaker Spring` cancel the first linked mismatch pin**

On mismatch from a linked drill, clear the pin side effect and consume the relic charge:

```gdscript
if hit_type == "mismatch" and _linked_relic_consumed(..., "first_mismatch_cleanse"):
	pin_active = false
	sim.queue_pinned_slots = 0
```

- [ ] **Step 5: Make the four user-requested relic updates real**

Implement:

- `Warning Bell`: block first obstacle execute
- `Spare Fuse`: protect one blue obstacle from active slowdown and execute debt
- `Brake Coil`: `+20` ticks on clear
- `Anchor Oathplate`: every `5` weakness hits, repaint every weakness marker to the triggering color

### Task 4: Expand reward content and keep previews/tooltips coherent

**Files:**
- Modify: `app-LTL/src/data/reward-table.json`
- Modify: `app-LTL/src/ui/read_models/TooltipReadModel.gd`
- Modify: `app-LTL/src/vocabulary/reward/BuildRewardPreview.gd`

- [ ] **Step 1: Rewrite the four requested relic entries**

Update schema trigger/type, rarity, summaries, and text for:

- `Warning Bell`
- `Spare Fuse`
- `Brake Coil`
- `Anchor Oathplate`

Examples:

```json
"trigger": "on_obstacle_execute",
"type": "prevent_first_execute",
"summary": "Blocks the first obstacle execute each combat."
```

```json
"trigger": "on_obstacle_clear",
"type": "clear_add_time",
"value": 20,
"summary": "Adds 1 second when an obstacle is removed."
```

- [ ] **Step 2: Add three rare relics and one epic relic**

Add:

- `reward_rare_relic_sealant_patch`
- `reward_rare_relic_debris_chalk`
- `reward_rare_relic_counterflow_governor`
- `reward_epic_relic_recovery_winch`

Use colorless relic payloads with valid shape, localized text, `effect_schema.version = 1`, and player-facing `summary_i18n`.

- [ ] **Step 3: Keep tooltip and reward preview projections compatible with global relics**

Do not require `link_mode` for relic tooltip rendering. The tooltip should only render a relic link label when `link_mode` exists and is non-empty.

Keep reward previews schema-driven:

```gdscript
var summary := TextCatalogScript.effect_summary(schema)
if not summary.is_empty():
	parts.append(summary)
```

### Task 5: Verify green and record the outcome

**Files:**
- Modify: `docs/codex-worklog/history_LootingTheLeviathan_2026-06-04.md`
- Modify: `docs/codex-worklog/complete_LootingTheLeviathan_2026-06-04.md`

- [ ] **Step 1: Run focused combat tests**

Run:

```powershell
godot --headless --path app-LTL res://tests/run_test_combat_vocab.gd --quit
```

Expected: `COMBAT_VOCAB_TESTS_OK`

- [ ] **Step 2: Run the full contract suite**

Run:

```powershell
godot --headless --path app-LTL res://tests/godot_contract_runner.gd --quit
```

Expected: `GODOT_CONTRACTS_OK`

- [ ] **Step 3: Run diff hygiene**

Run:

```powershell
git diff --check
```

Expected: no whitespace errors. Existing line-ending warnings are acceptable if no new whitespace failures appear.

- [ ] **Step 4: Update worklog history and completion notes**

Record:

- the new relic runtime layer
- the updated execute/activate semantics
- the four revised relic behaviors
- the four added relics
- the verification commands and outcomes
