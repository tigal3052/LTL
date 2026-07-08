# UI Layout System Refactor Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the node-select and combat layouts predictable, centered, and testable by separating layout policy, production rendering, and test-only scene probes.

**Architecture:** Move hardcoded UI constants into design/layout token scripts, move node-map geometry into a pure presenter, and keep runtime scene scripts responsible only for applying already-computed layout data to Godot controls. Tests should target pure presenters for geometry and use test-only probes for rendered scene inspection instead of adding public test helpers to production scene classes.

**Tech Stack:** Godot 4.3 GDScript, `.tscn` scene defaults, headless Godot contract tests in `app-LTL/tests`, PowerShell verification scripts.

---

## Current Root Cause

Changing `app-LTL/src/Main.tscn:403` from `custom_minimum_size = Vector2(0, 180)` does not reduce the empty area below START because that value is only the minimum height of `NodeSelectPanel`.

The effective node-select height is controlled by these runtime values:

- `app-LTL/src/ui/presenters/PhaseLayoutPresenter.gd:31`: `activePhaseStretchRatio = 7.0` gives the active phase row most of the vertical shell.
- `app-LTL/src/ui/MainViewRuntime.gd:216-228`: applies the phase layout, reparents the backpack, and assigns `active_phase_container.size_flags_stretch_ratio`.
- `app-LTL/src/ui/MainViewRuntime.gd:383-398`: dynamically creates `NodeMapBackpackRow` and injects `NodeMapScene`, so the visible node map is not only the static `.tscn` children.
- `app-LTL/src/ui/MainViewRuntime.gd:395`: `node_map_scene.custom_minimum_size = Vector2(0, 360)` sets a larger runtime minimum than the static panel minimum.
- `app-LTL/src/scenes/node_map/NodeMapScene.gd:260`: `map_frame.size_flags_stretch_ratio = 1.35` controls how much of `NodeMapScene` goes to the upper map area.
- `app-LTL/src/scenes/node_map/NodeMapScene.gd:270`: `_map_canvas.custom_minimum_size = Vector2(0, 300)` sets the upper map canvas minimum height.
- `app-LTL/src/scenes/node_map/NodeMapScene.gd:281-283`: `_detail_panel.custom_minimum_size = Vector2(0, 220)` and `_detail_panel.size_flags_stretch_ratio = 1.2` reserve lower detail-panel space.
- `app-LTL/src/scenes/node_map/NodeMapScene.gd:334`: `start_pos := Vector2(canvas_size.x * 0.50, canvas_size.y * 0.78)` places START inside the upper map canvas. Lowering `0.78` moves START upward; shrinking the map canvas or lowering map stretch reduces bottom whitespace structurally.

The first code to change for START bottom whitespace is `NodeMapScene.gd`, not `Main.tscn:403`.

## File Structure

- Create `app-LTL/src/ui/tokens/DesignTokens.gd`: shared spacing, font, radius, stroke, and color tokens.
- Create `app-LTL/src/ui/tokens/LayoutMetrics.gd`: panel, backpack, battlefield, status, and node-map layout constants and ratio policies.
- Create `app-LTL/src/ui/presenters/NodeMapLayoutPresenter.gd`: pure node-map geometry, candidate bounds, start marker position, line specs, and fit checks.
- Create `app-LTL/src/ui/presenters/BackpackDropPolicy.gd`: pure backpack drop/hover policy moved out of `BackpackUI`.
- Create `app-LTL/tests/helpers/NodeMapSceneProbe.gd`: test-only rendered-scene inspection and button press helpers.
- Modify `app-LTL/src/scenes/node_map/NodeMapScene.gd`: remove public test helpers, consume tokens and presenter output, reduce map/detail coupling.
- Modify `app-LTL/src/ui/presenters/PhaseLayoutPresenter.gd`: consume `LayoutMetrics` instead of inline numeric ratios.
- Modify `app-LTL/src/ui/MainViewRuntime.gd`: consume `LayoutMetrics`, compute responsive backpack widths from available row size, and apply shell/panel constants at runtime.
- Modify `app-LTL/src/ui/BackpackUI.gd`: delegate drop policy to `BackpackDropPolicy`.
- Modify `app-LTL/src/ui/BattlefieldVFX.gd` and `app-LTL/src/ui/InteractionFX.gd`: move pure test-targeted decisions into presenters or policies.
- Modify `app-LTL/tests/test_node_map_scene_smoke.gd`: use `NodeMapSceneProbe` and `NodeMapLayoutPresenter`.
- Modify `app-LTL/tests/test_ui_read_models.gd`: assert named layout metrics and policies instead of locking anonymous inline numbers.
- Modify `app-LTL/tests/godot_contract_runner.gd`: load any new test classes needed for token/presenter contracts.

## Task 1: Centralize Design Tokens And Layout Metrics

**Files:**
- Create: `app-LTL/src/ui/tokens/DesignTokens.gd`
- Create: `app-LTL/src/ui/tokens/LayoutMetrics.gd`
- Modify: `app-LTL/tests/test_ui_read_models.gd`

- [ ] **Step 1: Add failing token contract tests**

Append this test to `app-LTL/tests/test_ui_read_models.gd` and call it from `run_all_tests()`:

```gdscript
func test_layout_metrics_collect_shared_ui_policy() -> void:
	var DesignTokensScript = load("res://src/ui/tokens/DesignTokens.gd")
	var LayoutMetricsScript = load("res://src/ui/tokens/LayoutMetrics.gd")
	_assert(DesignTokensScript != null, "design tokens script loads")
	_assert(LayoutMetricsScript != null, "layout metrics script loads")
	if DesignTokensScript == null or LayoutMetricsScript == null:
		return
	_assert_eq(DesignTokensScript.SPACE["xl"], 20, "20px panel gap is a named spacing token")
	_assert_eq(LayoutMetricsScript.NODE_SELECT["row_gap"], DesignTokensScript.SPACE["xl"], "node-select backpack gap uses the shared 20px token")
	_assert_eq(LayoutMetricsScript.NODE_MAP["start_y_ratio"], 0.72, "START is positioned higher to remove bottom dead space")
	_assert_eq(LayoutMetricsScript.NODE_MAP["canvas_min_height"], 260, "node map upper canvas is smaller than the old 300px minimum")
	_assert_eq(LayoutMetricsScript.NODE_MAP["detail_min_height"], 260, "node detail panel gains the freed vertical space")
	_assert(LayoutMetricsScript.BACKPACK["node_select_width_min"] < 600, "node-select backpack minimum no longer squeezes the node map at narrow widths")
```

- [ ] **Step 2: Run the focused test and verify it fails**

Run:

```powershell
$env:APPDATA='D:\Programming\ex_workspace\LootingTheLeviathan\.godot-user\Roaming'
$env:LOCALAPPDATA='D:\Programming\ex_workspace\LootingTheLeviathan\.godot-user\Local'
& 'D:\Programming\godot_workspace\bin\Godot_v4.3-stable_win64_console.exe' --headless --editor --path 'app-LTL' -s 'tests/godot_contract_runner.gd' -- --smoke-only
```

Expected: FAIL because `DesignTokens.gd` and `LayoutMetrics.gd` do not exist yet.

- [ ] **Step 3: Create `DesignTokens.gd`**

Add:

```gdscript
class_name DesignTokens
extends RefCounted

const SPACE := {
	"xxs": 2,
	"xs": 4,
	"sm": 8,
	"md": 12,
	"lg": 16,
	"xl": 20,
	"xxl": 24
}

const FONT := {
	"log": 10,
	"caption": 11,
	"small": 12,
	"body": 14,
	"timer": 16,
	"title": 18,
	"modal": 20,
	"display": 22,
	"alert": 24
}

const RADIUS := {
	"slot": 4,
	"sm": 8,
	"button": 10,
	"panel": 12,
	"large": 14,
	"pill": 16
}

const STROKE := {
	"thin": 1,
	"medium": 2,
	"alert": 3,
	"route": 4
}

const SHADOW := {
	"slot": 2,
	"panel": 8,
	"shop": 12,
	"modal": 16,
	"vignette": 25
}
```

- [ ] **Step 4: Create `LayoutMetrics.gd`**

Add:

```gdscript
class_name LayoutMetrics
extends RefCounted

const DesignTokensScript = preload("res://src/ui/tokens/DesignTokens.gd")

const SHELL := {
	"root_margin": 16,
	"header_margin_x": 16,
	"header_margin_y": 8,
	"stack_gap": 12,
	"top_content_gap": 20,
	"combat_ratios": {"left": 2.45, "backpack": 8.20, "right": 2.35},
	"node_select_active_ratio": 5.2,
	"default_active_ratio": 1.0
}

const NODE_SELECT := {
	"row_gap": 20,
	"node_map_min_height": 320,
	"map_stretch": 1.0,
	"backpack_stretch": 0.0
}

const BACKPACK := {
	"model_cols": 8,
	"model_rows": 8,
	"bordered_cols": 10,
	"bordered_rows": 10,
	"slot_min": 16,
	"ghost_slot": 24,
	"gap": 2,
	"node_select_width_min": 520,
	"node_select_width_max": 860,
	"node_select_height_subtract": 52,
	"combat_width_min": 420,
	"combat_width_max": 640,
	"combat_height_subtract": 84
}

const NODE_MAP := {
	"color_button": Vector2(108, 42),
	"card": Vector2(132, 82),
	"canvas_min_height": 260,
	"detail_min_height": 260,
	"fallback_canvas": Vector2(320, 540),
	"start_marker": Vector2(96, 40),
	"map_frame_ratio": 1.00,
	"detail_ratio": 1.45,
	"start_y_ratio": 0.72,
	"node_top_ratio": 0.34,
	"node_bottom_ratio": 0.74,
	"candidate_inset_x": 18,
	"candidate_inset_y": 16,
	"start_bottom_reserved": 44,
	"route_line_width": 4
}

const BATTLEFIELD := {
	"columns": 10,
	"cell_min": Vector2(24, 20),
	"grid_gap": 8,
	"panel_min_height": 180,
	"reveal_min": Vector2(720, 360)
}

const STATUS := {
	"label_width": 78,
	"bar_height": 14,
	"extractor_size": Vector2(20, 20),
	"queue_gap": 6,
	"queue_gem_front": 24,
	"queue_gem_filled": 18,
	"queue_gem_empty": 16
}
```

- [ ] **Step 5: Run the focused test and verify it passes**

Run the same Godot command. Expected: PASS for the new token contract.

## Task 2: Extract Pure Node Map Geometry

**Files:**
- Create: `app-LTL/src/ui/presenters/NodeMapLayoutPresenter.gd`
- Modify: `app-LTL/src/scenes/node_map/NodeMapScene.gd`
- Modify: `app-LTL/tests/test_node_map_scene_smoke.gd`

- [ ] **Step 1: Add presenter geometry tests**

Append to `app-LTL/tests/test_node_map_scene_smoke.gd` and call from `run_all_tests()`:

```gdscript
func test_node_map_layout_presenter_keeps_five_nodes_inside_canvas() -> void:
	var LayoutScript = load("res://src/ui/presenters/NodeMapLayoutPresenter.gd")
	_assert(LayoutScript != null, "node map layout presenter loads")
	if LayoutScript == null:
		return
	var card_size := Vector2(132, 82)
	var canvas_size := Vector2(460, 260)
	var specs: Array = LayoutScript.candidate_specs(5, canvas_size, card_size)
	_assert_eq(specs.size(), 5, "presenter returns five candidate specs")
	for spec in specs:
		var rect: Rect2 = spec["rect"]
		_assert(rect.position.x >= 0.0, "candidate remains inside left canvas edge")
		_assert(rect.position.y >= 0.0, "candidate remains inside top canvas edge")
		_assert(rect.position.x + rect.size.x <= canvas_size.x, "candidate remains inside right canvas edge")
		_assert(rect.position.y + rect.size.y <= canvas_size.y, "candidate remains inside bottom canvas edge")
	var center_x := LayoutScript.visual_center_x(specs, LayoutScript.start_rect(canvas_size))
	_assert(absf(center_x - (canvas_size.x * 0.5)) <= 18.0, "candidate cluster remains centered in narrow canvas")
```

- [ ] **Step 2: Run focused test and verify it fails**

Run the Godot smoke command. Expected: FAIL because `NodeMapLayoutPresenter.gd` does not exist.

- [ ] **Step 3: Create `NodeMapLayoutPresenter.gd`**

Add:

```gdscript
class_name NodeMapLayoutPresenter
extends RefCounted

const LayoutMetricsScript = preload("res://src/ui/tokens/LayoutMetrics.gd")

static func start_center(canvas_size: Vector2) -> Vector2:
	return Vector2(canvas_size.x * 0.50, canvas_size.y * float(LayoutMetricsScript.NODE_MAP["start_y_ratio"]))

static func start_rect(canvas_size: Vector2) -> Rect2:
	var marker_size: Vector2 = LayoutMetricsScript.NODE_MAP["start_marker"]
	return Rect2(start_center(canvas_size) - (marker_size * 0.5), marker_size)

static func candidate_specs(count: int, canvas_size: Vector2, card_size: Vector2) -> Array:
	var result: Array = []
	for index in range(maxi(1, count)):
		var center := candidate_center(index, count, canvas_size, card_size)
		result.append({
			"index": index,
			"center": center,
			"rect": Rect2(center - (card_size * 0.5), card_size)
		})
	return result

static func candidate_center(index: int, count: int, canvas_size: Vector2, card_size: Vector2) -> Vector2:
	var normalized := _normalized_candidate(index, count)
	var inset_x := float(LayoutMetricsScript.NODE_MAP["candidate_inset_x"]) + (card_size.x * 0.5)
	var inset_y := float(LayoutMetricsScript.NODE_MAP["candidate_inset_y"]) + (card_size.y * 0.5)
	var max_x := maxf(inset_x, canvas_size.x - inset_x)
	var max_y := maxf(inset_y, canvas_size.y - inset_y - float(LayoutMetricsScript.NODE_MAP["start_bottom_reserved"]))
	return Vector2(lerpf(inset_x, max_x, normalized.x), lerpf(inset_y, max_y, normalized.y))

static func route_line_specs(count: int, canvas_size: Vector2, card_size: Vector2) -> Array:
	var start := start_center(canvas_size)
	var result: Array = []
	for spec in candidate_specs(count, canvas_size, card_size):
		result.append({"from": start, "to": spec["center"]})
	return result

static func visual_center_x(candidate_specs_value: Array, start_rect_value: Rect2) -> float:
	var total := start_rect_value.get_center().x
	var count := 1
	for spec in candidate_specs_value:
		total += Rect2(spec["rect"]).get_center().x
		count += 1
	return total / float(count)

static func _normalized_candidate(index: int, count: int) -> Vector2:
	var point_sets := {
		1: [Vector2(0.50, 0.34)],
		2: [Vector2(0.34, 0.34), Vector2(0.66, 0.34)],
		3: [Vector2(0.22, 0.38), Vector2(0.50, 0.24), Vector2(0.78, 0.38)],
		4: [Vector2(0.0, 0.0), Vector2(1.0, 0.0), Vector2(0.25, 0.74), Vector2(0.75, 0.74)],
		5: [Vector2(0.0, 0.0), Vector2(0.50, 0.0), Vector2(1.0, 0.0), Vector2(0.25, 0.74), Vector2(0.75, 0.74)]
	}
	var points: Array = point_sets.get(maxi(1, count), point_sets[5])
	return points[clampi(index, 0, points.size() - 1)]
```

- [ ] **Step 4: Change `NodeMapScene.gd` to use presenter geometry**

At the top:

```gdscript
const LayoutMetricsScript = preload("res://src/ui/tokens/LayoutMetrics.gd")
const NodeMapLayoutPresenterScript = preload("res://src/ui/presenters/NodeMapLayoutPresenter.gd")
```

Replace direct button size and position values:

```gdscript
var card_size: Vector2 = LayoutMetricsScript.NODE_MAP["card"]
button.custom_minimum_size = card_size
button.size = card_size
button.position = NodeMapLayoutPresenterScript.candidate_center(index, cards.size(), _map_canvas_extent(), card_size) - (card_size * 0.5)
```

Replace `_build_map_scaffold()`:

```gdscript
func _build_map_scaffold(candidate_count: int) -> void:
	var canvas_size := _map_canvas_extent()
	var card_size: Vector2 = LayoutMetricsScript.NODE_MAP["card"]
	for line_spec in NodeMapLayoutPresenterScript.route_line_specs(candidate_count, canvas_size, card_size):
		_add_map_line(line_spec["from"], line_spec["to"], Color(0.45, 0.63, 0.71, 0.72), float(LayoutMetricsScript.NODE_MAP["route_line_width"]))
	_add_static_map_node("START", NodeMapLayoutPresenterScript.start_center(canvas_size), Color(0.18, 0.48, 0.40, 0.96))
```

- [ ] **Step 5: Run the focused test and verify it passes**

Run the Godot smoke command. Expected: PASS for presenter geometry and existing node-map scene smoke tests.

## Task 3: Move Test-Only NodeMapScene Helpers Into Test Probe

**Files:**
- Create: `app-LTL/tests/helpers/NodeMapSceneProbe.gd`
- Modify: `app-LTL/src/scenes/node_map/NodeMapScene.gd`
- Modify: `app-LTL/tests/test_node_map_scene_smoke.gd`

- [ ] **Step 1: Create failing probe import test**

Add to `app-LTL/tests/test_node_map_scene_smoke.gd`:

```gdscript
func test_node_map_scene_probe_reads_rendered_controls_without_production_helpers() -> void:
	var SceneScript = load("res://src/scenes/node_map/NodeMapScene.gd")
	var ProbeScript = load("res://tests/helpers/NodeMapSceneProbe.gd")
	_assert(SceneScript != null, "node map scene loads")
	_assert(ProbeScript != null, "node map scene probe loads")
	if SceneScript == null or ProbeScript == null:
		return
	var scene = SceneScript.new()
	scene.render({
		"stageText": TextCatalogScript.t("stage.label", [1, 5]),
		"selectedColor": "red",
		"startColors": ["red", "blue", "purple", "green"],
		"cards": [
			{"label": "Safe Scar", "weaknessLabel": "green", "riskTier": "safe", "rewardBias": "baseline", "recommendedBuildHint": "Stable route", "finalStageDistance": 4, "selected": true}
		]
	})
	var probe = ProbeScript.new(scene)
	_assert_eq(probe.card_count(), 1, "probe reads rendered card buttons")
	_assert_eq(probe.map_canvas_name(), "RunMapCanvas", "probe finds the map canvas by scene tree")
	_assert(probe.detail_text().contains("Safe Scar"), "probe reads rendered detail text")
	scene.queue_free()
```

- [ ] **Step 2: Run focused test and verify it fails**

Run the Godot smoke command. Expected: FAIL because the probe file does not exist.

- [ ] **Step 3: Create `NodeMapSceneProbe.gd`**

Add:

```gdscript
extends RefCounted

var _scene: Control

func _init(scene: Control) -> void:
	_scene = scene

func card_count() -> int:
	return _node_buttons().size()

func map_node_count() -> int:
	return _node_buttons().size()

func loadout_color_count() -> int:
	return _color_buttons().size()

func map_page_root_name() -> String:
	return _scene.get_child(0).name if _scene != null and _scene.get_child_count() > 0 else ""

func map_canvas_name() -> String:
	var canvas := _find_by_name(_scene, "RunMapCanvas") as Control
	return canvas.name if canvas != null else ""

func map_canvas_width() -> float:
	var canvas := _find_by_name(_scene, "RunMapCanvas") as Control
	return canvas.size.x if canvas != null else 0.0

func node_leftmost_edge() -> float:
	var edge := INF
	for button in _node_buttons():
		edge = minf(edge, button.position.x)
	return 0.0 if edge == INF else edge

func node_rightmost_edge() -> float:
	var edge := 0.0
	for button in _node_buttons():
		edge = maxf(edge, button.position.x + button.size.x)
	return edge

func map_line_count() -> int:
	return _nodes_by_class(_scene, "ColorRect", "RouteLine").size()

func core_marker_present() -> bool:
	return _find_by_name(_scene, "CoreMarker") != null

func node_button_text(index: int) -> String:
	var buttons := _node_buttons()
	return buttons[index].text if index >= 0 and index < buttons.size() else ""

func node_button_selected_state(index: int) -> bool:
	var buttons := _node_buttons()
	return bool(buttons[index].get_meta("selected", false)) if index >= 0 and index < buttons.size() else false

func summary_text() -> String:
	var label := _find_by_name(_scene, "SummaryLabel") as Label
	return label.text if label != null else ""

func detail_text() -> String:
	var label := _find_by_name(_scene, "DetailLabel") as RichTextLabel
	return label.text if label != null else ""

func press_node_button(index: int) -> void:
	var buttons := _node_buttons()
	if index >= 0 and index < buttons.size():
		buttons[index].pressed.emit()

func press_color_button(index: int) -> void:
	var buttons := _color_buttons()
	if index >= 0 and index < buttons.size():
		buttons[index].pressed.emit()

func _node_buttons() -> Array[Button]:
	var buttons: Array[Button] = []
	var canvas := _find_by_name(_scene, "RunMapCanvas")
	for child in _collect_nodes(canvas):
		if child is Button:
			buttons.append(child)
	return buttons

func _color_buttons() -> Array[Button]:
	var buttons: Array[Button] = []
	var row := _find_by_name(_scene, "StartColors")
	for child in _collect_nodes(row):
		if child is Button:
			buttons.append(child)
	return buttons

func _nodes_by_class(root: Node, class_name: String, node_name: String) -> Array:
	var result: Array = []
	for child in _collect_nodes(root):
		if child.get_class() == class_name and child.name == node_name:
			result.append(child)
	return result

func _find_by_name(root: Node, node_name: String) -> Node:
	if root == null:
		return null
	if root.name == node_name:
		return root
	for child in root.get_children():
		var found := _find_by_name(child, node_name)
		if found != null:
			return found
	return null

func _collect_nodes(root: Node) -> Array:
	var result: Array = []
	if root == null:
		return result
	result.append(root)
	for child in root.get_children():
		result.append_array(_collect_nodes(child))
	return result
```

- [ ] **Step 4: Replace production helper calls in tests**

In `app-LTL/tests/test_node_map_scene_smoke.gd`, replace calls like:

```gdscript
scene.card_count()
scene.map_node_count()
scene.map_canvas_name()
scene.node_button_text(0)
scene.press_node_button(0)
```

with:

```gdscript
var probe = ProbeScript.new(scene)
probe.card_count()
probe.map_node_count()
probe.map_canvas_name()
probe.node_button_text(0)
probe.press_node_button(0)
```

- [ ] **Step 5: Remove public test-only helpers from `NodeMapScene.gd`**

Delete these production methods after all tests use `NodeMapSceneProbe` or `NodeMapLayoutPresenter`:

```gdscript
func card_count() -> int
func loadout_color_count() -> int
func map_node_count() -> int
func map_page_root_name() -> String
func map_canvas_name() -> String
func map_line_count() -> int
func core_marker_present() -> bool
func node_visual_center_x() -> float
func map_canvas_center_x() -> float
func map_canvas_width() -> float
func node_leftmost_edge() -> float
func node_rightmost_edge() -> float
func map_canvas_min_height() -> float
func detail_panel_min_height() -> float
func set_map_canvas_test_size(canvas_size: Vector2) -> void
func node_button_text(index: int) -> String
func node_button_selected_state(index: int) -> bool
func press_node_button(index: int) -> void
func color_button_text(index: int) -> String
func press_color_button(index: int) -> void
func summary_text() -> String
func detail_text() -> String
```

Also delete `_test_canvas_size` and its branches in `_map_canvas_extent()`.

- [ ] **Step 6: Run focused tests and verify they pass**

Run the Godot smoke command. Expected: PASS with no production scene test-helper API.

## Task 4: Apply Node-Select Vertical Rebalance

**Files:**
- Modify: `app-LTL/src/scenes/node_map/NodeMapScene.gd`
- Modify: `app-LTL/src/ui/MainViewRuntime.gd`
- Modify: `app-LTL/tests/test_node_map_scene_smoke.gd`
- Modify: `app-LTL/tests/test_ui_read_models.gd`

- [ ] **Step 1: Update layout assertions**

Replace the old assertions that expect `300` and `220`:

```gdscript
_assert_eq(LayoutMetricsScript.NODE_MAP["canvas_min_height"], 260, "node map upper panel is shorter")
_assert_eq(LayoutMetricsScript.NODE_MAP["detail_min_height"], 260, "node detail panel reserves more readable space")
```

- [ ] **Step 2: Apply token values to `NodeMapScene.gd`**

Replace:

```gdscript
map_frame.size_flags_stretch_ratio = 1.35
_map_canvas.custom_minimum_size = Vector2(0, 300)
_detail_panel.custom_minimum_size = Vector2(0, 220)
_detail_panel.size_flags_stretch_ratio = 1.2
```

with:

```gdscript
map_frame.size_flags_stretch_ratio = float(LayoutMetricsScript.NODE_MAP["map_frame_ratio"])
_map_canvas.custom_minimum_size = Vector2(0, float(LayoutMetricsScript.NODE_MAP["canvas_min_height"]))
_detail_panel.custom_minimum_size = Vector2(0, float(LayoutMetricsScript.NODE_MAP["detail_min_height"]))
_detail_panel.size_flags_stretch_ratio = float(LayoutMetricsScript.NODE_MAP["detail_ratio"])
```

- [ ] **Step 3: Lower `MainViewRuntime.gd` node map minimum**

Replace:

```gdscript
node_map_scene.custom_minimum_size = Vector2(0, 360)
```

with:

```gdscript
node_map_scene.custom_minimum_size = Vector2(0, float(LayoutMetricsScript.NODE_SELECT["node_map_min_height"]))
```

- [ ] **Step 4: Verify START is no longer visually low**

The START coordinate must come from:

```gdscript
NodeMapLayoutPresenterScript.start_center(canvas_size)
```

Expected computed y for a 260px canvas is `187.2` because `260 * 0.72 = 187.2`, compared with the previous `202.8` from `260 * 0.78`.

- [ ] **Step 5: Run focused tests**

Run the Godot smoke command. Expected: PASS.

## Task 5: Make Backpack Width Responsive Without Overlapping Node Map

**Files:**
- Modify: `app-LTL/src/ui/MainViewRuntime.gd`
- Modify: `app-LTL/src/ui/presenters/PhaseLayoutPresenter.gd`
- Modify: `app-LTL/tests/test_ui_read_models.gd`

- [ ] **Step 1: Add responsive width tests**

Add to `app-LTL/tests/test_ui_read_models.gd`:

```gdscript
func test_node_select_backpack_width_leaves_clickable_map_space() -> void:
	var RuntimeScript = load("res://src/ui/MainViewRuntime.gd")
	var LayoutMetricsScript = load("res://src/ui/tokens/LayoutMetrics.gd")
	_assert(RuntimeScript != null, "main view runtime loads")
	_assert(LayoutMetricsScript != null, "layout metrics loads")
	if RuntimeScript == null or LayoutMetricsScript == null:
		return
	var total_width := 1220.0
	var gap := float(LayoutMetricsScript.NODE_SELECT["row_gap"])
	var width := RuntimeScript.node_select_backpack_width_for_size(Vector2(total_width, 704), 520.0)
	_assert(width <= 704.0, "backpack width never exceeds available height")
	_assert(total_width - width - gap >= 460.0, "node map retains enough width for five clickable node buttons")
```

- [ ] **Step 2: Add a static helper to `MainViewRuntime.gd`**

Add:

```gdscript
const LayoutMetricsScript = preload("res://src/ui/tokens/LayoutMetrics.gd")

static func node_select_backpack_width_for_size(row_size: Vector2, map_min_width: float) -> float:
	var target_from_height := maxf(0.0, row_size.y - float(LayoutMetricsScript.BACKPACK["node_select_height_subtract"]))
	var gap := float(LayoutMetricsScript.NODE_SELECT["row_gap"])
	var width_limit_from_row := maxf(float(LayoutMetricsScript.BACKPACK["node_select_width_min"]), row_size.x - map_min_width - gap)
	var upper_bound := minf(float(LayoutMetricsScript.BACKPACK["node_select_width_max"]), width_limit_from_row)
	return clampf(target_from_height, float(LayoutMetricsScript.BACKPACK["node_select_width_min"]), upper_bound)
```

- [ ] **Step 3: Use the helper at runtime**

Replace `_node_select_backpack_width()` with:

```gdscript
func _node_select_backpack_width() -> float:
	var row_size := node_select_content_row.size if node_select_content_row != null else active_phase_container.size
	var map_min_width := _node_map_min_width()
	return node_select_backpack_width_for_size(row_size, map_min_width)

func _node_map_min_width() -> float:
	var card_size: Vector2 = LayoutMetricsScript.NODE_MAP["card"]
	return maxf(460.0, (card_size.x * 3.0) + (float(LayoutMetricsScript.NODE_MAP["candidate_inset_x"]) * 2.0))
```

- [ ] **Step 4: Apply exact node-select row gap**

Replace:

```gdscript
node_select_content_row.add_theme_constant_override("separation", 18)
```

with:

```gdscript
node_select_content_row.add_theme_constant_override("separation", int(LayoutMetricsScript.NODE_SELECT["row_gap"]))
```

- [ ] **Step 5: Run focused tests**

Run the Godot smoke command. Expected: PASS and no right-side button clipping in node-map tests.

## Task 6: Move Phase Layout Ratios Into Metrics

**Files:**
- Modify: `app-LTL/src/ui/presenters/PhaseLayoutPresenter.gd`
- Modify: `app-LTL/tests/test_ui_read_models.gd`

- [ ] **Step 1: Update tests to assert named metrics**

In `test_phase_layout_gives_backpack_more_space_in_combat_and_reward()`, assert against `LayoutMetricsScript.SHELL["combat_ratios"]` rather than anonymous literals:

```gdscript
var ratios: Dictionary = LayoutMetricsScript.SHELL["combat_ratios"]
_assert_eq(float(combat.get("leftColumnTopStretchRatio", 0.0)), float(ratios["left"]), "combat left ratio comes from layout metrics")
_assert_eq(float(combat.get("backpackTopStretchRatio", 0.0)), float(ratios["backpack"]), "combat backpack ratio comes from layout metrics")
_assert_eq(float(combat.get("rightSidebarTopStretchRatio", 0.0)), float(ratios["right"]), "combat right ratio comes from layout metrics")
```

- [ ] **Step 2: Preload metrics in `PhaseLayoutPresenter.gd`**

Add:

```gdscript
const LayoutMetricsScript = preload("res://src/ui/tokens/LayoutMetrics.gd")
```

- [ ] **Step 3: Replace inline ratio values**

Replace:

```gdscript
"activePhaseStretchRatio": 7.0 if is_node_select else 1.0,
"leftColumnTopStretchRatio": 2.45,
"backpackTopStretchRatio": 8.20,
"rightSidebarTopStretchRatio": 2.35,
"nodeMapStretchRatio": 1.00,
"backpackStretchRatio": 0.00,
```

with:

```gdscript
var combat_ratios: Dictionary = LayoutMetricsScript.SHELL["combat_ratios"]
var node_select_ratio := float(LayoutMetricsScript.SHELL["node_select_active_ratio"])
var default_active_ratio := float(LayoutMetricsScript.SHELL["default_active_ratio"])
```

and return:

```gdscript
"activePhaseStretchRatio": node_select_ratio if is_node_select else default_active_ratio,
"leftColumnTopStretchRatio": float(combat_ratios["left"]),
"backpackTopStretchRatio": float(combat_ratios["backpack"]),
"rightSidebarTopStretchRatio": float(combat_ratios["right"]),
"nodeMapStretchRatio": float(LayoutMetricsScript.NODE_SELECT["map_stretch"]),
"backpackStretchRatio": float(LayoutMetricsScript.NODE_SELECT["backpack_stretch"]),
```

- [ ] **Step 4: Run focused tests**

Run the Godot smoke command. Expected: PASS.

## Task 7: Split Backpack Drop Policy From Runtime UI

**Files:**
- Create: `app-LTL/src/ui/presenters/BackpackDropPolicy.gd`
- Modify: `app-LTL/src/ui/BackpackUI.gd`
- Modify: `app-LTL/tests/test_ui_read_models.gd`

- [ ] **Step 1: Add policy tests**

Move existing `BackpackUI.can_drop_artifact()` assertions to:

```gdscript
func test_backpack_drop_policy_uses_real_placement_rules() -> void:
	var PolicyScript = load("res://src/ui/presenters/BackpackDropPolicy.gd")
	_assert(PolicyScript != null, "backpack drop policy loads")
	if PolicyScript == null:
		return
	var inventory := {
		"cols": 2,
		"rows": 2,
		"artifacts": [{"id": "existing", "pos": Vector2i(0, 0), "shape": [Vector2i(0, 0)]}]
	}
	var held := {"id": "held", "shape": [Vector2i(0, 0)]}
	_assert_eq(PolicyScript.can_drop_artifact(inventory, held, Vector2i(1, 1)), true, "empty in-bounds drop is accepted")
	_assert_eq(PolicyScript.can_drop_artifact(inventory, held, Vector2i(0, 0)), false, "occupied drop is rejected")
	_assert_eq(PolicyScript.can_drop_artifact(inventory, held, Vector2i(2, 2)), false, "out-of-bounds drop is rejected")
```

- [ ] **Step 2: Create `BackpackDropPolicy.gd`**

Add:

```gdscript
class_name BackpackDropPolicy
extends RefCounted

static func can_drop_artifact(inventory: Dictionary, artifact: Dictionary, target: Vector2i) -> bool:
	var shape: Array = artifact.get("shape", [Vector2i.ZERO])
	var cols := int(inventory.get("cols", 0))
	var rows := int(inventory.get("rows", 0))
	for cell in shape:
		var pos := target + Vector2i(cell)
		if pos.x < 0 or pos.y < 0 or pos.x >= cols or pos.y >= rows:
			return false
		for existing in inventory.get("artifacts", []):
			for occupied in existing.get("shape", [Vector2i.ZERO]):
				var occupied_pos := Vector2i(existing.get("pos", Vector2i.ZERO)) + Vector2i(occupied)
				if occupied_pos == pos:
					return false
	return true
```

- [ ] **Step 3: Delegate from `BackpackUI.gd`**

Replace the body of `can_drop_artifact()` with:

```gdscript
const BackpackDropPolicyScript = preload("res://src/ui/presenters/BackpackDropPolicy.gd")

static func can_drop_artifact(inventory: Dictionary, artifact: Dictionary, target: Vector2i) -> bool:
	return BackpackDropPolicyScript.can_drop_artifact(inventory, artifact, target)
```

- [ ] **Step 4: Run focused tests**

Run the Godot smoke command. Expected: PASS.

## Task 8: Apply Runtime Metrics To Scene Controls

**Files:**
- Modify: `app-LTL/src/ui/MainViewRuntime.gd`
- Modify: `app-LTL/src/Main.tscn`
- Modify: `app-LTL/tests/test_ui_read_models.gd`

- [ ] **Step 1: Add runtime metrics application method**

Add to `MainViewRuntime.gd`:

```gdscript
func _apply_layout_metrics_to_scene_controls() -> void:
	var shell: Dictionary = LayoutMetricsScript.SHELL
	_set_container_gap($RootMargin/AppShell, int(shell["stack_gap"]))
	_set_container_gap(top_content, int(shell["top_content_gap"]))
	_set_container_gap(node_select_content_row, int(LayoutMetricsScript.NODE_SELECT["row_gap"]))
	_set_margin_constants($RootMargin/AppShell/TopContent/BackpackContainer/BackpackEnginePanel/Margin, 16, 16, 16, 16)
	_set_margin_constants($RootMargin/AppShell/TopContent/RightSidebar/Margin, 20, 20, 20, 20)
	_set_margin_constants($RootMargin/AppShell/ActivePhaseContainer/NodeSelectPanel/Margin, 12, 12, 12, 12)

func _set_container_gap(container: Control, gap: int) -> void:
	if container != null:
		container.add_theme_constant_override("separation", gap)

func _set_margin_constants(margin: MarginContainer, left: int, top: int, right: int, bottom: int) -> void:
	if margin == null:
		return
	margin.add_theme_constant_override("margin_left", left)
	margin.add_theme_constant_override("margin_top", top)
	margin.add_theme_constant_override("margin_right", right)
	margin.add_theme_constant_override("margin_bottom", bottom)
```

- [ ] **Step 2: Call the metrics method after dynamic nodes are created**

In `_ready()`, after `_create_node_map_scene()` and backpack parent capture, call:

```gdscript
_apply_layout_metrics_to_scene_controls()
```

- [ ] **Step 3: Keep `.tscn` as safe fallback**

Do not delete all scene values in one pass. Keep `.tscn` minimums as editor-readable fallback defaults, but make runtime metrics the source of truth for layout behavior.

- [ ] **Step 4: Run focused tests**

Run the Godot smoke command. Expected: PASS.

## Task 9: Verification And Visual QA

**Files:**
- Modify: `docs/codex-worklog/history_LootingTheLeviathan_2026-05-31.md`
- Modify: `docs/codex-worklog/complete_LootingTheLeviathan_2026-05-31.md`

- [ ] **Step 1: Run contract smoke**

Run:

```powershell
$env:APPDATA='D:\Programming\ex_workspace\LootingTheLeviathan\.godot-user\Roaming'
$env:LOCALAPPDATA='D:\Programming\ex_workspace\LootingTheLeviathan\.godot-user\Local'
& 'D:\Programming\godot_workspace\bin\Godot_v4.3-stable_win64_console.exe' --headless --editor --path 'app-LTL' -s 'tests/godot_contract_runner.gd' -- --smoke-only
```

Expected: exit code 0 and `GODOT_CONTRACTS_OK`.

- [ ] **Step 2: Run full compile wrapper**

Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools/run-compile-check.ps1
```

Expected: PASS. If it fails on the existing source-map gate, record that as an unrelated blocker and keep the Godot smoke result as the layout verification evidence.

- [ ] **Step 3: Run whitespace check**

Run:

```powershell
git diff --check
```

Expected: no whitespace errors.

- [ ] **Step 4: Manual visual QA checklist**

Inspect the app at 1440x900 and 1280x720:

- Node-select backpack remains right-docked and keeps uniform panel padding.
- Node-select row gap between node map and backpack is 20px.
- Node graph cluster is centered inside the visible map panel.
- All five node buttons are fully inside the map canvas and clickable.
- START no longer sits with excessive empty space below it.
- Lower node detail panel has enough height that Korean labels do not clip.
- Combat top row keeps backpack size, fills dead space by widening status/log panels, and preserves about 20px panel gaps.
- Battlefield panel remains visually aligned with the bottom row and does not overlap action buttons.

## Execution Order For Subagents

- Agent A owns Task 1 and Task 6: token scripts and phase layout presenter. Write set is `app-LTL/src/ui/tokens/*`, `app-LTL/src/ui/presenters/PhaseLayoutPresenter.gd`, and `app-LTL/tests/test_ui_read_models.gd`.
- Agent B owns Task 2 and Task 4: node-map geometry and vertical rebalance. Write set is `app-LTL/src/ui/presenters/NodeMapLayoutPresenter.gd`, `app-LTL/src/scenes/node_map/NodeMapScene.gd`, and `app-LTL/tests/test_node_map_scene_smoke.gd`.
- Agent C owns Task 3: test-only probe separation. Write set is `app-LTL/tests/helpers/NodeMapSceneProbe.gd`, `app-LTL/tests/test_node_map_scene_smoke.gd`, and public helper deletions from `NodeMapScene.gd` after Agent B has landed.
- Agent D owns Task 5 and Task 8: runtime responsive width and scene metrics application. Write set is `app-LTL/src/ui/MainViewRuntime.gd` and runtime-layout assertions in `app-LTL/tests/test_ui_read_models.gd`.
- Agent E owns Task 7: backpack policy split. Write set is `app-LTL/src/ui/presenters/BackpackDropPolicy.gd`, `app-LTL/src/ui/BackpackUI.gd`, and matching tests.

Run Agent A and Agent E in parallel first because their write sets do not overlap with node-map geometry. Run Agent B after Agent A provides metrics. Run Agent C after Agent B so the probe reflects the final node tree. Run Agent D after Agent A and B so responsive backpack sizing can use the final metrics and node-map minimum width.

## Self Review

- Spec coverage: This plan answers why `Main.tscn:403` does not control START whitespace, centralizes UI constants, separates test-only scene probes, preserves right-docked backpack behavior, prevents right-side node clipping, and adds verification for adjacent layout ratios.
- Placeholder scan: No task relies on undefined files without a creation step, and every implementation step names exact files and code.
- Type consistency: Token dictionaries use string keys, presenter methods are static, Godot paths use `res://`, and tests load the files they assert.
