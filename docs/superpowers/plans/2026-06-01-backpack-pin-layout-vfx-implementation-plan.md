# Backpack Pin Layout VFX Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement the approved grounded local backpack pin layout and removal VFX so combat pins sit in the backpack shell, remove in the requested order, and visibly pull out.

**Architecture:** `MainViewRuntime.gd` keeps ownership of top-content width policy while `BackpackUI.gd` owns all pin sizing, placement, visibility order, and local VFX. Tests stay in the existing UI read-model contract suite because the behavior is deterministic and should compile without booting the full scene.

**Tech Stack:** Godot 4.3 GDScript, `Control`/`TextureRect`, `Tween`, existing `tests/run_test_ui_read_models.gd` and `tests/godot_contract_runner.gd` headless runners.

---

## File Structure

- Modify: `app-LTL/tests/test_ui_read_models.gd`
  - Adds RED-first contract tests for backpack width, pin sizing, removal order, and VFX profile helpers.
- Modify: `app-LTL/src/ui/MainViewRuntime.gd`
  - Replaces the broad `30%` top-content backpack width policy with slot-scaled pin overhang helpers.
- Modify: `app-LTL/src/ui/BackpackUI.gd`
  - Adds deterministic geometry helpers, requested visible-index ordering, slot-scaled placement, and local pull-out tween behavior.
- Modify: `docs/codex-worklog/history_LootingTheLeviathan_2026-06-01.md`
  - Records RED/GREEN evidence and implementation summary.
- Modify: `docs/codex-worklog/complete_LootingTheLeviathan_2026-06-01.md`
  - Records final verification and any remaining visual risks.

## Shared Commands

Use these commands from `D:\Programming\ex_workspace\LootingTheLeviathan`.

```powershell
& 'D:\Programming\godot_workspace\bin\Godot_v4.3-stable_win64_console.exe' --display-driver headless --audio-driver Dummy --path 'D:\Programming\ex_workspace\LootingTheLeviathan\app-LTL' --script tests/run_test_ui_read_models.gd --disable-crash-handler --quit
```

Expected focused success marker after GREEN: `UI_READ_MODEL_TESTS_OK`

```powershell
& 'D:\Programming\godot_workspace\bin\Godot_v4.3-stable_win64_console.exe' --display-driver headless --audio-driver Dummy --path 'D:\Programming\ex_workspace\LootingTheLeviathan\app-LTL' --script tests/godot_contract_runner.gd --disable-crash-handler --quit
```

Expected broad success marker after GREEN: `GODOT_CONTRACTS_OK`

```powershell
git diff --check -- app-LTL/src/ui/BackpackUI.gd app-LTL/src/ui/MainViewRuntime.gd app-LTL/tests/test_ui_read_models.gd docs/codex-worklog/history_LootingTheLeviathan_2026-06-01.md docs/codex-worklog/complete_LootingTheLeviathan_2026-06-01.md
```

Expected: no whitespace errors. Existing line-ending normalization warnings may appear and should be noted separately.

---

### Task 1: Add RED Contracts For Pin Geometry, Order, And VFX

**Files:**
- Modify: `app-LTL/tests/test_ui_read_models.gd`

- [ ] **Step 1: Add test calls to `run_all_tests()`**

Insert these calls immediately after `test_backpack_pin_contract_maps_count_and_corner_order()` in `run_all_tests()`:

```gdscript
	test_top_content_backpack_width_uses_slot_scaled_pin_overhang()
	test_backpack_pin_visibility_removes_in_requested_order()
	test_backpack_pin_vfx_contract_is_localized_pullout()
```

- [ ] **Step 2: Add a small float assertion helper**

Place this helper near the existing `_assert_eq()` helper at the bottom of `test_ui_read_models.gd`:

```gdscript
func _assert_close(actual: float, expected: float, tolerance: float, msg: String) -> void:
	if absf(actual - expected) > tolerance:
		failures.append("%s expected %.4f got %.4f" % [msg, expected, actual])
```

- [ ] **Step 3: Add the width and slot-scale test**

Place this test after `test_top_content_backpack_width_tracks_full_row_height()`:

```gdscript
func test_top_content_backpack_width_uses_slot_scaled_pin_overhang() -> void:
	var MainViewRuntimeScript = load("res://src/ui/MainViewRuntime.gd")
	var backpack_ui = BackpackUIScript.new()
	_assert(MainViewRuntimeScript != null, "main view runtime loads for slot-scaled pin width policy")
	if MainViewRuntimeScript == null:
		return
	_assert(backpack_ui.has_method("pin_slot_extent_for_grid_extent"), "backpack exposes slot extent helper for pin sizing")
	_assert(backpack_ui.has_method("pin_display_extent_for_slot_extent"), "backpack exposes slot-scaled pin display helper")
	_assert(backpack_ui.has_method("pin_side_outset_for_slot_extent"), "backpack exposes slot-scaled side outset helper")
	_assert(MainViewRuntimeScript.has_method("top_content_backpack_pin_side_outset_for_height"), "main view exposes top-content pin side outset helper")
	if not backpack_ui.has_method("pin_slot_extent_for_grid_extent") or not backpack_ui.has_method("pin_side_outset_for_slot_extent") or not MainViewRuntimeScript.has_method("top_content_backpack_pin_side_outset_for_height"):
		return

	var grid_extent := 548.0
	var slot_extent := float(backpack_ui.call("pin_slot_extent_for_grid_extent", grid_extent))
	var pin_extent := float(backpack_ui.call("pin_display_extent_for_slot_extent", slot_extent))
	var side_outset := float(backpack_ui.call("pin_side_outset_for_slot_extent", slot_extent))
	var main_side_outset := float(MainViewRuntimeScript.top_content_backpack_pin_side_outset_for_height(grid_extent))
	var width := float(MainViewRuntimeScript.top_content_backpack_width_for_height(grid_extent))

	_assert_close(slot_extent, 53.0, 0.001, "548px grid resolves to a 10-column slot extent with 2px separators")
	_assert(pin_extent < 120.0, "pin display extent is slot-scaled rather than 30 percent of the whole grid")
	_assert_close(main_side_outset, side_outset, 0.001, "main view and backpack agree on pin side outset")
	_assert_close(width, grid_extent + side_outset * 2.0, 0.001, "top-content backpack width adds only left and right pin outsets")
	_assert(width < 712.4, "top-content backpack no longer uses the old broad 30 percent full-grid width")
```

- [ ] **Step 4: Add the requested removal-order test**

Place this test after `test_backpack_pin_contract_maps_count_and_corner_order()`:

```gdscript
func test_backpack_pin_visibility_removes_in_requested_order() -> void:
	var backpack_ui = BackpackUIScript.new()
	_assert(backpack_ui.has_method("pin_visible_indices"), "backpack exposes deterministic visible pin index mapping")
	_assert(backpack_ui.has_method("pin_is_visible"), "backpack exposes per-index pin visibility helper")
	if not backpack_ui.has_method("pin_visible_indices") or not backpack_ui.has_method("pin_is_visible"):
		return

	_assert_eq(backpack_ui.call("pin_visible_indices", 4), [0, 1, 2, 3], "all pins visible at full count")
	_assert_eq(backpack_ui.call("pin_visible_indices", 3), [1, 2, 3], "pin_1 is removed first")
	_assert_eq(backpack_ui.call("pin_visible_indices", 2), [2, 3], "pin_2 is removed second")
	_assert_eq(backpack_ui.call("pin_visible_indices", 1), [3], "pin_3 is removed third")
	_assert_eq(backpack_ui.call("pin_visible_indices", 0), [], "pin_4 is removed last")
	_assert_eq(bool(backpack_ui.call("pin_is_visible", 0, 3)), false, "pin_1 hidden when three pins remain")
	_assert_eq(bool(backpack_ui.call("pin_is_visible", 3, 1)), true, "pin_4 remains when one pin remains")
```

- [ ] **Step 5: Add the localized pull-out VFX profile test**

Place this test after `test_backpack_pin_visibility_removes_in_requested_order()`:

```gdscript
func test_backpack_pin_vfx_contract_is_localized_pullout() -> void:
	var backpack_ui = BackpackUIScript.new()
	_assert(backpack_ui.has_method("pin_pull_direction_for_index"), "backpack exposes pull direction helper for pin removal VFX")
	_assert(backpack_ui.has_method("pin_removal_vfx_profile_for_index"), "backpack exposes deterministic removal VFX profile")
	if not backpack_ui.has_method("pin_pull_direction_for_index") or not backpack_ui.has_method("pin_removal_vfx_profile_for_index"):
		return

	_assert_eq(backpack_ui.call("pin_pull_direction_for_index", 0), Vector2(-1, -1).normalized(), "pin_1 pulls out toward the top-left")
	_assert_eq(backpack_ui.call("pin_pull_direction_for_index", 1), Vector2(1, -1).normalized(), "pin_2 pulls out toward the top-right")
	_assert_eq(backpack_ui.call("pin_pull_direction_for_index", 2), Vector2(1, 1).normalized(), "pin_3 pulls out toward the bottom-right")
	_assert_eq(backpack_ui.call("pin_pull_direction_for_index", 3), Vector2(-1, 1).normalized(), "pin_4 pulls out toward the bottom-left")

	var profile: Dictionary = backpack_ui.call("pin_removal_vfx_profile_for_index", 0, 80.0)
	_assert_close(float(profile.get("anticipationDuration", 0.0)), 0.05, 0.001, "pin removal anticipation stays short")
	_assert_close(float(profile.get("pullDuration", 0.0)), 0.12, 0.001, "pin removal pull stays quick")
	_assert_close(float(profile.get("pullDistance", 0.0)), 14.4, 0.001, "pin removal pull distance scales from displayed pin size")
	_assert_eq(float(profile.get("fadeToAlpha", 1.0)), 0.0, "removed pin fades out")
	_assert_eq(bool(profile.get("localOnly", false)), true, "pin removal VFX is localized rather than screen shake")
```

- [ ] **Step 6: Run the focused test runner and verify RED**

Run:

```powershell
& 'D:\Programming\godot_workspace\bin\Godot_v4.3-stable_win64_console.exe' --display-driver headless --audio-driver Dummy --path 'D:\Programming\ex_workspace\LootingTheLeviathan\app-LTL' --script tests/run_test_ui_read_models.gd --disable-crash-handler --quit
```

Expected: FAIL before production code changes. The failure should mention missing helpers such as `pin_slot_extent_for_grid_extent`, `pin_visible_indices`, or `pin_removal_vfx_profile_for_index`.

---

### Task 2: Implement Slot-Scaled Width Policy

**Files:**
- Modify: `app-LTL/src/ui/MainViewRuntime.gd`
- Modify: `app-LTL/src/ui/BackpackUI.gd`
- Test: `app-LTL/tests/test_ui_read_models.gd`

- [ ] **Step 1: Add deterministic pin geometry helpers in `BackpackUI.gd`**

Replace the old full-grid pin constants and helper implementations:

```gdscript
const PIN_GRID_COLUMNS := 10.0
const PIN_GRID_SEPARATION := 2.0
const PIN_DISPLAY_SLOT_RATIO := 1.55
const PIN_GRID_OVERLAP_RATIO := 0.35
const PIN_Z_INDEX := 24
```

Add these helper methods near `pin_corner_specs()`:

```gdscript
func pin_slot_extent_for_grid_extent(grid_extent: float) -> float:
	var safe_extent := maxf(0.0, grid_extent)
	if safe_extent <= 0.0:
		return 0.0
	var total_separator := PIN_GRID_SEPARATION * maxf(0.0, PIN_GRID_COLUMNS - 1.0)
	return maxf(0.0, (safe_extent - total_separator) / PIN_GRID_COLUMNS)

func pin_display_extent_for_slot_extent(slot_extent: float) -> float:
	return maxf(0.0, slot_extent) * PIN_DISPLAY_SLOT_RATIO

func pin_grid_overlap_for_slot_extent(slot_extent: float) -> float:
	return pin_display_extent_for_slot_extent(slot_extent) * PIN_GRID_OVERLAP_RATIO

func pin_side_outset_for_slot_extent(slot_extent: float) -> float:
	return pin_display_extent_for_slot_extent(slot_extent) - pin_grid_overlap_for_slot_extent(slot_extent)

func pin_display_extent_for_grid_extent(grid_extent: float) -> float:
	return pin_display_extent_for_slot_extent(pin_slot_extent_for_grid_extent(grid_extent))

func pin_side_outset_for_grid_extent(grid_extent: float) -> float:
	return pin_side_outset_for_slot_extent(pin_slot_extent_for_grid_extent(grid_extent))

func backpack_panel_extra_width_for_grid_extent(grid_extent: float) -> float:
	return pin_side_outset_for_grid_extent(grid_extent) * 2.0
```

- [ ] **Step 2: Replace top-content width math in `MainViewRuntime.gd`**

Replace `TOP_CONTENT_BACKPACK_PIN_EXTRA_WIDTH_RATIO` with explicit slot-scaled constants:

```gdscript
const TOP_CONTENT_BACKPACK_GRID_COLUMNS := 10.0
const TOP_CONTENT_BACKPACK_GRID_SEPARATION := 2.0
const TOP_CONTENT_BACKPACK_PIN_DISPLAY_SLOT_RATIO := 1.55
const TOP_CONTENT_BACKPACK_PIN_GRID_OVERLAP_RATIO := 0.35
```

Replace `top_content_backpack_width_for_height()` and add the helper methods:

```gdscript
static func top_content_backpack_slot_extent_for_height(target_height: float) -> float:
	var grid_extent := maxf(maxf(0.0, target_height), 420.0)
	var total_separator := TOP_CONTENT_BACKPACK_GRID_SEPARATION * maxf(0.0, TOP_CONTENT_BACKPACK_GRID_COLUMNS - 1.0)
	return maxf(0.0, (grid_extent - total_separator) / TOP_CONTENT_BACKPACK_GRID_COLUMNS)

static func top_content_backpack_pin_side_outset_for_height(target_height: float) -> float:
	var slot_extent := top_content_backpack_slot_extent_for_height(target_height)
	var pin_extent := slot_extent * TOP_CONTENT_BACKPACK_PIN_DISPLAY_SLOT_RATIO
	var grid_overlap := pin_extent * TOP_CONTENT_BACKPACK_PIN_GRID_OVERLAP_RATIO
	return maxf(0.0, pin_extent - grid_overlap)

static func top_content_backpack_width_for_height(target_height: float) -> float:
	var safe_height := maxf(0.0, target_height)
	if safe_height <= 0.0:
		return 0.0
	var grid_extent := maxf(safe_height, 420.0)
	return grid_extent + top_content_backpack_pin_side_outset_for_height(grid_extent) * 2.0
```

Keep `top_content_backpack_ratio_for_height()` as the ratio of the new width over the grid extent.

- [ ] **Step 3: Run the focused test runner**

Run:

```powershell
& 'D:\Programming\godot_workspace\bin\Godot_v4.3-stable_win64_console.exe' --display-driver headless --audio-driver Dummy --path 'D:\Programming\ex_workspace\LootingTheLeviathan\app-LTL' --script tests/run_test_ui_read_models.gd --disable-crash-handler --quit
```

Expected: the width policy assertions pass. Remaining failures should be limited to visibility-order or VFX helpers not yet implemented.

---

### Task 3: Implement Requested Pin Visibility Order

**Files:**
- Modify: `app-LTL/src/ui/BackpackUI.gd`
- Test: `app-LTL/tests/test_ui_read_models.gd`

- [ ] **Step 1: Add visible-index helpers**

Add these methods near `pin_visible_count()`:

```gdscript
func pin_visible_indices(visible_count: int, total_count: int = 4) -> Array:
	var safe_total := maxi(0, total_count)
	var safe_count := clampi(visible_count, 0, safe_total)
	var start_index := safe_total - safe_count
	var indices: Array = []
	for index in range(start_index, safe_total):
		indices.append(index)
	return indices

func pin_is_visible(index: int, visible_count: int) -> bool:
	return pin_visible_indices(visible_count, pin_nodes.size() if not pin_nodes.is_empty() else 4).has(index)
```

- [ ] **Step 2: Update `update_pin_overlays()` to use the helper**

Replace the current visibility loop:

```gdscript
	for index in range(pin_nodes.size()):
		pin_nodes[index].visible = index < visible_pin_count_value
```

with:

```gdscript
	for index in range(pin_nodes.size()):
		pin_nodes[index].visible = pin_is_visible(index, visible_pin_count_value)
```

- [ ] **Step 3: Update `_layout_pin_overlays()` to use the helper**

Replace the current line:

```gdscript
		pin.visible = index < visible_pin_count_value
```

with:

```gdscript
		pin.visible = pin.visible or pin_is_visible(index, visible_pin_count_value)
		if not pin_is_visible(index, visible_pin_count_value) and not pin.has_meta("pin_removing"):
			pin.visible = false
```

This keeps a removing pin visible during its tween in the later VFX task.

- [ ] **Step 4: Run the focused test runner**

Run:

```powershell
& 'D:\Programming\godot_workspace\bin\Godot_v4.3-stable_win64_console.exe' --display-driver headless --audio-driver Dummy --path 'D:\Programming\ex_workspace\LootingTheLeviathan\app-LTL' --script tests/run_test_ui_read_models.gd --disable-crash-handler --quit
```

Expected: removal-order assertions pass. Remaining failures should be VFX helper failures until Task 5 is implemented.

---

### Task 4: Reposition Pins Into The Shell Gutter

**Files:**
- Modify: `app-LTL/src/ui/BackpackUI.gd`
- Test: `app-LTL/tests/test_ui_read_models.gd`

- [ ] **Step 1: Add a deterministic position helper**

Add this helper near `_layout_pin_overlays()`:

```gdscript
func pin_position_for_anchor(anchor: Vector2, pin_size: Vector2, spec: Dictionary, grid_overlap: float) -> Vector2:
	var horizontal := str(spec.get("horizontal", "left"))
	var vertical := str(spec.get("vertical", "top"))
	var x := anchor.x + grid_overlap - pin_size.x if horizontal == "left" else anchor.x - grid_overlap
	var y := anchor.y + grid_overlap - pin_size.y if vertical == "top" else anchor.y - grid_overlap
	return Vector2(x, y)
```

- [ ] **Step 2: Update `_layout_pin_overlays()` sizing math**

Replace the old grid-scale pin sizing:

```gdscript
	var grid_extent := minf(backpack_grid_mock.size.x, backpack_grid_mock.size.y)
	if grid_extent <= 0.0:
		return
	var pin_extent := pin_display_extent_for_grid_extent(grid_extent)
	var pin_size := Vector2(pin_extent, pin_extent)
```

with:

```gdscript
	var grid_extent := minf(backpack_grid_mock.size.x, backpack_grid_mock.size.y)
	if grid_extent <= 0.0:
		return
	var slot_extent := pin_slot_extent_for_grid_extent(grid_extent)
	var pin_extent := pin_display_extent_for_slot_extent(slot_extent)
	var grid_overlap := pin_grid_overlap_for_slot_extent(slot_extent)
	var pin_size := Vector2(pin_extent, pin_extent)
```

- [ ] **Step 3: Update `_layout_pin_overlays()` placement math**

Replace:

```gdscript
		pin.global_position = anchor - pin.size * PIN_OVERLAP_RATIO
```

with:

```gdscript
		if not pin.has_meta("pin_removing"):
			pin.global_position = pin_position_for_anchor(anchor, pin.size, spec, grid_overlap)
```

- [ ] **Step 4: Run focused tests**

Run:

```powershell
& 'D:\Programming\godot_workspace\bin\Godot_v4.3-stable_win64_console.exe' --display-driver headless --audio-driver Dummy --path 'D:\Programming\ex_workspace\LootingTheLeviathan\app-LTL' --script tests/run_test_ui_read_models.gd --disable-crash-handler --quit
```

Expected: no new compile errors. Any remaining failures should be VFX profile failures until Task 5 is complete.

---

### Task 5: Add Local Pull-Out VFX Contract Helpers And Tween

**Files:**
- Modify: `app-LTL/src/ui/BackpackUI.gd`
- Test: `app-LTL/tests/test_ui_read_models.gd`

- [ ] **Step 1: Add VFX constants and state**

Add constants near the pin constants:

```gdscript
const PIN_REMOVAL_ANTICIPATION_SECONDS := 0.05
const PIN_REMOVAL_PULL_SECONDS := 0.12
const PIN_REMOVAL_PULL_RATIO := 0.18
const PIN_REMOVAL_ROTATION_DEGREES := 12.0
const PIN_REMOVAL_ANTICIPATION_SCALE := 0.97
```

Add state near `visible_pin_count_value`:

```gdscript
var pin_state_initialized: bool = false
var pin_removal_tweens: Dictionary = {}
```

- [ ] **Step 2: Add VFX profile helpers**

Add near the visible-index helpers:

```gdscript
func pin_pull_direction_for_index(index: int) -> Vector2:
	match index:
		0:
			return Vector2(-1, -1).normalized()
		1:
			return Vector2(1, -1).normalized()
		2:
			return Vector2(1, 1).normalized()
		3:
			return Vector2(-1, 1).normalized()
		_:
			return Vector2.ZERO

func pin_removal_vfx_profile_for_index(index: int, pin_extent: float) -> Dictionary:
	return {
		"direction": pin_pull_direction_for_index(index),
		"anticipationDuration": PIN_REMOVAL_ANTICIPATION_SECONDS,
		"pullDuration": PIN_REMOVAL_PULL_SECONDS,
		"pullDistance": maxf(0.0, pin_extent) * PIN_REMOVAL_PULL_RATIO,
		"rotationDegrees": PIN_REMOVAL_ROTATION_DEGREES,
		"anticipationScale": PIN_REMOVAL_ANTICIPATION_SCALE,
		"fadeToAlpha": 0.0,
		"localOnly": true
	}

func removed_pin_indices(previous_count: int, next_count: int) -> Array:
	var previous_indices: Array = pin_visible_indices(previous_count)
	var next_indices: Array = pin_visible_indices(next_count)
	var removed: Array = []
	for index in previous_indices:
		if not next_indices.has(index):
			removed.append(index)
	return removed
```

- [ ] **Step 3: Trigger removal VFX from `update_pin_overlays()`**

Replace the current count and visibility body with:

```gdscript
	var next_visible_count := pin_visible_count(phase == "combat", float(pin_state.get("progress", 0.0)))
	if phase != "combat":
		_reset_pin_vfx_state()
		visible_pin_count_value = 0
		for index in range(pin_nodes.size()):
			pin_nodes[index].visible = false
		call_deferred("_layout_pin_overlays")
		return

	if pin_state_initialized:
		for removed_index in removed_pin_indices(visible_pin_count_value, next_visible_count):
			_play_pin_removed_vfx(removed_index)
	else:
		pin_state_initialized = true

	visible_pin_count_value = next_visible_count
	for index in range(pin_nodes.size()):
		if pin_is_visible(index, visible_pin_count_value):
			_reset_pin_visual(pin_nodes[index])
			pin_nodes[index].visible = true
		elif not pin_nodes[index].has_meta("pin_removing"):
			pin_nodes[index].visible = false
	call_deferred("_layout_pin_overlays")
```

- [ ] **Step 4: Add reset and tween helpers**

Add these helpers near `_layout_pin_overlays()`:

```gdscript
func _reset_pin_visual(pin: TextureRect) -> void:
	pin.remove_meta("pin_removing")
	pin.modulate = Color(1, 1, 1, 1)
	pin.scale = Vector2.ONE
	pin.rotation_degrees = 0.0

func _reset_pin_vfx_state() -> void:
	pin_state_initialized = false
	for key in pin_removal_tweens.keys():
		var tween = pin_removal_tweens[key]
		if tween != null and tween is Tween:
			tween.kill()
	pin_removal_tweens.clear()
	for pin in pin_nodes:
		_reset_pin_visual(pin)

func _play_pin_removed_vfx(index: int) -> void:
	if index < 0 or index >= pin_nodes.size():
		return
	var pin := pin_nodes[index]
	if pin == null:
		return
	if pin_removal_tweens.has(index):
		var previous_tween = pin_removal_tweens[index]
		if previous_tween != null and previous_tween is Tween:
			previous_tween.kill()
	var pin_extent := maxf(pin.size.x, pin.size.y)
	var profile := pin_removal_vfx_profile_for_index(index, pin_extent)
	var direction: Vector2 = profile.get("direction", Vector2.ZERO)
	var pull_distance := float(profile.get("pullDistance", 0.0))
	var anticipation_seconds := float(profile.get("anticipationDuration", 0.05))
	var pull_seconds := float(profile.get("pullDuration", 0.12))
	var rotation_degrees := float(profile.get("rotationDegrees", 12.0))
	var base_position := pin.global_position
	pin.set_meta("pin_removing", true)
	pin.visible = true
	pin.modulate = Color(1, 1, 1, 1)
	pin.scale = Vector2.ONE

	var tween := create_tween().bind_node(pin)
	pin_removal_tweens[index] = tween
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(pin, "scale", Vector2.ONE * float(profile.get("anticipationScale", 0.97)), anticipation_seconds)
	tween.parallel().tween_property(pin, "rotation_degrees", -rotation_degrees * 0.35, anticipation_seconds)
	tween.tween_property(pin, "global_position", base_position + direction * pull_distance, pull_seconds)
	tween.parallel().tween_property(pin, "rotation_degrees", rotation_degrees, pull_seconds)
	tween.parallel().tween_property(pin, "modulate:a", float(profile.get("fadeToAlpha", 0.0)), pull_seconds)
	tween.finished.connect(func():
		pin_removal_tweens.erase(index)
		_reset_pin_visual(pin)
		pin.visible = pin_is_visible(index, visible_pin_count_value)
		call_deferred("_layout_pin_overlays")
	)
```

- [ ] **Step 5: Run focused tests**

Run:

```powershell
& 'D:\Programming\godot_workspace\bin\Godot_v4.3-stable_win64_console.exe' --display-driver headless --audio-driver Dummy --path 'D:\Programming\ex_workspace\LootingTheLeviathan\app-LTL' --script tests/run_test_ui_read_models.gd --disable-crash-handler --quit
```

Expected: `UI_READ_MODEL_TESTS_OK`

---

### Task 6: Verify Full UI Contract And Update Worklog

**Files:**
- Modify: `docs/codex-worklog/history_LootingTheLeviathan_2026-06-01.md`
- Modify: `docs/codex-worklog/complete_LootingTheLeviathan_2026-06-01.md`

- [ ] **Step 1: Run the broad Godot contract runner**

Run:

```powershell
& 'D:\Programming\godot_workspace\bin\Godot_v4.3-stable_win64_console.exe' --display-driver headless --audio-driver Dummy --path 'D:\Programming\ex_workspace\LootingTheLeviathan\app-LTL' --script tests/godot_contract_runner.gd --disable-crash-handler --quit
```

Expected: `GODOT_CONTRACTS_OK`

- [ ] **Step 2: Run diff whitespace check**

Run:

```powershell
git diff --check -- app-LTL/src/ui/BackpackUI.gd app-LTL/src/ui/MainViewRuntime.gd app-LTL/tests/test_ui_read_models.gd docs/codex-worklog/history_LootingTheLeviathan_2026-06-01.md docs/codex-worklog/complete_LootingTheLeviathan_2026-06-01.md
```

Expected: no whitespace errors.

- [ ] **Step 3: Update worklog history**

Append this entry to `docs/codex-worklog/history_LootingTheLeviathan_2026-06-01.md`, replacing command status text with the observed markers:

```markdown
- Intent: Implement approved backpack pin shell layout, requested removal order, and local pull-out VFX.
- Files or areas touched:
  - `app-LTL/src/ui/BackpackUI.gd`
  - `app-LTL/src/ui/MainViewRuntime.gd`
  - `app-LTL/tests/test_ui_read_models.gd`
- Summary: Added slot-scaled pin geometry, replaced the broad top-content width policy with left/right pin outsets, changed visible pin mapping so removals occur `pin_1 -> pin_2 -> pin_3 -> pin_4`, and added localized pull-out tween helpers for removed pins.
- Plan impact: Completed the approved backpack pin design without changing backend combat timing or backpack drag/drop behavior.
- Verification:
  - RED: focused UI read-model runner failed first on missing pin geometry/order/VFX helpers.
  - GREEN: focused UI read-model runner printed `UI_READ_MODEL_TESTS_OK`.
  - Broad suite: Godot contract runner printed `GODOT_CONTRACTS_OK`.
  - Diff hygiene: `git diff --check` reported no whitespace errors in touched files.
```

- [ ] **Step 4: Update completion report**

Add this concise note to `docs/codex-worklog/complete_LootingTheLeviathan_2026-06-01.md`:

```markdown
## Additional Completion: Backpack Pin Layout And VFX

Implemented the approved grounded local pin effect. Combat backpack pins now use slot-scaled sizing, the top-content backpack width adds only the left/right pin outsets, pins remain top-layer overlays, removal order follows `pin_1 -> pin_2 -> pin_3 -> pin_4`, and each removed pin receives a short localized pull-out tween.

Verification:

- Focused UI runner: `UI_READ_MODEL_TESTS_OK`
- Broad Godot contracts: `GODOT_CONTRACTS_OK`
- Diff hygiene: no whitespace errors in touched files
```

---

## Self-Review Checklist

- Spec coverage:
  - Grid size preserved through width helpers and shell-only extra width.
  - Side panel behavior preserved through `Control.SIZE_EXPAND_FILL` tests already in the suite.
  - Removal order covered by `pin_visible_indices()`.
  - VFX readability covered by deterministic profile and runtime tween.
  - Non-combat reset covered by existing pin visibility contract plus `_reset_pin_vfx_state()`.
- Type consistency:
  - Helper names used in tests match helpers added to `BackpackUI.gd` and `MainViewRuntime.gd`.
  - VFX profile keys match the test assertions and tween implementation.
  - Existing public methods `pin_visible_count()` and `pin_corner_specs()` remain intact.
- Execution notes:
  - Use `apply_patch` for all manual edits.
  - Do not revert unrelated dirty worktree changes.
  - Record Godot shutdown leak warnings separately from success markers if they appear.
