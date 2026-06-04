# Artifact Codex Book UI Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the text-list codex with the approved `ItemBook.png`-based hybrid book UI while keeping the book safe area ratio-driven instead of hardcoding sample pixel measurements.

**Architecture:** Extend the codex read model so it projects section, selection, left-page detail, right-page grid, and art descriptors in one pass. Rebuild the panel into a ratio-driven book layout with page-local scroll containers, then wire `MainViewRuntime` to own selected entry / active section state and rerender the panel from a single source of truth.

**Tech Stack:** Godot 4.3, GDScript, dynamic Control-tree UI, existing `TextCatalog`, existing Godot contract test runners.

---

## File Structure

- Modify: `app-LTL/src/ui/read_models/ArtifactCodexReadModel.gd`
  - Expand the codex projection from text-only output to a richer book model with sections, selection normalization, and art descriptors.
- Create: `app-LTL/src/ui/ArtifactCodexArtResolver.gd`
  - Resolve hero/thumb art paths and placeholder policies without leaking file access into the read model.
- Modify: `app-LTL/src/ui/ArtifactCodexPanelUI.gd`
  - Replace the simple text panel with a book-layout control tree rooted in `ItemBook.png`.
- Modify: `app-LTL/src/ui/MainViewRuntime.gd`
  - Store codex UI state, pass it into projection, and rerender on panel interaction.
- Modify: `app-LTL/src/ui/TextCatalog.gd`
  - Add missing codex strings for sections, locked hints, and discovery-state copy.
- Modify: `app-LTL/tests/test_reward_contract.gd`
  - Add read-model contract coverage for the richer codex model.
- Modify: `app-LTL/tests/test_ui_read_models.gd`
  - Add book-panel layout, ratio-safe-area, and page-scroll structure checks.

## Task 1: Lock the richer codex projection contract

**Files:**
- Modify: `app-LTL/tests/test_reward_contract.gd`
- Modify: `app-LTL/src/ui/read_models/ArtifactCodexReadModel.gd`
- Create: `app-LTL/src/ui/ArtifactCodexArtResolver.gd`

- [ ] **Step 1: Write the failing read-model tests**

```gdscript
func test_artifact_codex_projects_book_sections_selection_and_art_descriptors() -> void:
	var table := _load_reward_table_fixture()
	var rewards: Array = table.get("rewards", [])
	_assert(rewards.size() > 2, "codex fixture has enough rewards for section coverage")
	if rewards.size() <= 2:
		return
	var selected_id := str(rewards[1].get("id", ""))
	var model: Dictionary = ArtifactCodexReadModelScript.project(table, {"artifactDiscovery": [selected_id]}, false, "en", selected_id, "all")
	var sections: Array = model.get("sections", [])
	_assert(sections.size() >= 4, "codex exposes section tabs")
	_assert_eq(str(model.get("resolvedSelectedEntryId", "")), selected_id, "codex preserves visible selected entry")
	_assert(model.has("leftPage"), "codex exposes left page payload")
	_assert(model.has("rightPage"), "codex exposes right page payload")
	var left_page: Dictionary = model.get("leftPage", {})
	_assert(left_page.has("heroArt"), "left page exposes hero art descriptor")
	var hero_art: Dictionary = left_page.get("heroArt", {})
	_assert(hero_art.has("path"), "hero art descriptor exposes a path field")
	_assert(hero_art.has("placeholderId"), "hero art descriptor exposes placeholder id")
	_assert(hero_art.has("state"), "hero art descriptor exposes state")

func test_artifact_codex_selection_normalizes_when_filtered_out() -> void:
	var table := _load_reward_table_fixture()
	var rewards: Array = table.get("rewards", [])
	_assert(rewards.size() > 2, "codex fixture has enough rewards for normalization coverage")
	if rewards.size() <= 2:
		return
	var hidden_id := str(rewards[0].get("id", ""))
	var model: Dictionary = ArtifactCodexReadModelScript.project(table, {"artifactDiscovery": []}, false, "en", hidden_id, "relic")
	_assert(str(model.get("resolvedSelectedEntryId", "")) != hidden_id, "codex reselects when the requested entry is hidden")
```

- [ ] **Step 2: Run the full contract runner to verify the new codex projection tests fail**

Run:

```powershell
& 'D:\Programming\godot_workspace\bin\Godot_v4.3-stable_win64_console.exe' --display-driver headless --audio-driver Dummy --path 'D:\Programming\ex_workspace\LootingTheLeviathan\app-LTL' --script tests/godot_contract_runner.gd --disable-crash-handler --quit
```

Expected:

- `test_artifact_codex_projects_book_sections_selection_and_art_descriptors` fails because the current projector does not accept `selected_id` / `active_section` and does not return `sections`, `leftPage`, `rightPage`, or art descriptors.

- [ ] **Step 3: Implement the richer projection and art-resolver minimal code**

```gdscript
# ArtifactCodexReadModel.gd
static func project(
	reward_table: Dictionary,
	growth_state: Dictionary = {},
	debug_all: bool = false,
	locale := "",
	selected_entry_id := "",
	active_section := "all"
) -> Dictionary:
	var entries := _project_entries(reward_table, growth_state, debug_all, locale)
	var normalized_section := _normalize_section(active_section)
	var grid_entries := _filter_entries_for_section(entries, normalized_section)
	var resolved_selected_entry_id := _resolve_selected_entry_id(grid_entries, selected_entry_id)
	return {
		"title": TextCatalogScript.t("codex.title", [], locale),
		"text": _legacy_text(entries, locale),
		"entries": entries,
		"sections": _project_sections(entries, normalized_section, locale),
		"leftPage": _project_left_page(entries, resolved_selected_entry_id, locale),
		"rightPage": {"gridEntries": grid_entries, "emptyText": TextCatalogScript.t("codex.empty", [], locale)},
		"resolvedSelectedEntryId": resolved_selected_entry_id,
		"activeSection": normalized_section,
		"totalCount": entries.size(),
		"discoveredCount": _count_discovered(entries),
		"visibleCount": _count_visible(entries),
		"debugAll": debug_all
	}
```

```gdscript
# ArtifactCodexArtResolver.gd
class_name ArtifactCodexArtResolver
extends RefCounted

const HERO_MISSING := "hero_missing"
const HERO_LOCKED := "hero_locked"
const THUMB_MISSING := "thumb_missing"
const THUMB_LOCKED := "thumb_locked"

static func descriptor_for_reward(reward: Dictionary, slot: String, discovered: bool) -> Dictionary:
	var payload: Dictionary = reward.get("payload", {})
	var item_type := str(payload.get("item_type", "drill"))
	var energy_type := str(payload.get("energy_type", ""))
	var path := _placeholder_path_for(item_type, energy_type)
	return {
		"path": path,
		"placeholderId": _placeholder_id_for(slot, discovered),
		"fallbackChain": [path],
		"state": "discovered" if discovered else "locked"
	}
```

- [ ] **Step 4: Run the full contract runner to verify the richer codex projection passes**

Run the same command from Step 2.

Expected:

- Codex projection tests pass.
- Existing reward-contract assertions around `text`, `discoveredCount`, and `visibleCount` stay green.

- [ ] **Step 5: Commit the projection-contract task**

```bash
git add app-LTL/src/ui/read_models/ArtifactCodexReadModel.gd app-LTL/src/ui/ArtifactCodexArtResolver.gd app-LTL/tests/test_reward_contract.gd
git commit -m "feat: project codex book read model"
```

## Task 2: Add ratio-driven book safe-area and page-scroll UI

**Files:**
- Modify: `app-LTL/tests/test_ui_read_models.gd`
- Modify: `app-LTL/src/ui/ArtifactCodexPanelUI.gd`
- Modify: `app-LTL/src/ui/TextCatalog.gd`

- [ ] **Step 1: Write the failing UI layout and safe-area tests**

```gdscript
func test_codex_book_safe_area_uses_ratios_instead_of_fixed_pixels() -> void:
	var panel = ArtifactCodexPanelUIScript.new()
	var large_rect := Rect2(Vector2.ZERO, Vector2(1464, 1074))
	var small_rect := Rect2(Vector2.ZERO, Vector2(732, 537))
	var large_metrics: Dictionary = panel.book_layout_metrics_for_rect(large_rect)
	var small_metrics: Dictionary = panel.book_layout_metrics_for_rect(small_rect)
	_assert(float(large_metrics.get("outerLeft", 0.0)) > float(small_metrics.get("outerLeft", 0.0)), "safe area scales with available book width")
	_assert(absf((float(large_metrics.get("outerLeft", 0.0)) / large_rect.size.x) - (float(small_metrics.get("outerLeft", 0.0)) / small_rect.size.x)) < 0.01, "safe area keeps the same width ratio across sizes")

func test_codex_panel_exposes_split_page_scroll_structure() -> void:
	var panel = ArtifactCodexPanelUIScript.new()
	panel._ready()
	_assert(panel.has_method("book_layout_metrics_for_rect"), "codex panel exposes deterministic book layout metrics")
	_assert(panel.get_node_or_null("BookCenter/BookAspect/BookRoot/Spread/LeftPage/LeftScroll") != null, "left page uses its own scroll container")
	_assert(panel.get_node_or_null("BookCenter/BookAspect/BookRoot/Spread/RightPage/RightScroll") != null, "right page grid uses its own scroll container")
```

- [ ] **Step 2: Run the UI read-model runner to verify the new layout tests fail**

Run:

```powershell
& 'D:\Programming\godot_workspace\bin\Godot_v4.3-stable_win64_console.exe' --display-driver headless --audio-driver Dummy --path 'D:\Programming\ex_workspace\LootingTheLeviathan\app-LTL' --script tests/run_test_ui_read_models.gd --quit
```

Expected:

- Failure because the current codex panel does not expose `book_layout_metrics_for_rect` and still renders a single text area instead of page-local scroll containers.

- [ ] **Step 3: Implement the ratio-driven book panel**

```gdscript
func book_layout_metrics_for_rect(book_rect: Rect2) -> Dictionary:
	return {
		"outerLeft": book_rect.size.x * 0.072,
		"outerRight": book_rect.size.x * 0.072,
		"outerTop": book_rect.size.y * 0.105,
		"outerBottom": book_rect.size.y * 0.095,
		"gutter": book_rect.size.x * 0.045
	}
```

```gdscript
func _ready() -> void:
	visible = false
	_build_book_shell()
	_build_left_page()
	_build_right_page()
	_apply_book_layout()
```

```gdscript
func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_apply_book_layout()
```

- [ ] **Step 4: Run the UI read-model runner to verify the panel layout passes**

Run the same command from Step 2.

Expected:

- `UI_READ_MODEL_TESTS_OK`

- [ ] **Step 5: Commit the book-panel task**

```bash
git add app-LTL/src/ui/ArtifactCodexPanelUI.gd app-LTL/src/ui/TextCatalog.gd app-LTL/tests/test_ui_read_models.gd
git commit -m "feat: add ratio-driven codex book panel"
```

## Task 3: Wire runtime state, interaction, and rerender flow

**Files:**
- Modify: `app-LTL/src/ui/MainViewRuntime.gd`
- Modify: `app-LTL/src/ui/ArtifactCodexPanelUI.gd`
- Test: `app-LTL/tests/test_ui_read_models.gd`

- [ ] **Step 1: Write the failing runtime interaction tests**

```gdscript
func test_main_view_codex_keeps_selected_entry_and_section_state() -> void:
	_assert(MainViewRuntimeScript.has_method("_on_codex_entry_selected"), "main view exposes codex entry-selection handler")
	_assert(MainViewRuntimeScript.has_method("_on_codex_section_selected"), "main view exposes codex section-selection handler")
```

- [ ] **Step 2: Run the UI read-model runner to verify the runtime tests fail**

Run the same UI runner command from Task 2 Step 2.

Expected:

- Failure because `MainViewRuntime` does not yet own selected-entry or section state for the codex.

- [ ] **Step 3: Implement the runtime state handoff**

```gdscript
var current_codex_selected_entry_id := ""
var current_codex_active_section := "all"

func render_artifact_codex(reward_table: Dictionary, growth_state: Dictionary, debug_all: bool = false) -> void:
	var model := ArtifactCodexReadModelScript.project(
		reward_table,
		growth_state,
		debug_all,
		"",
		current_codex_selected_entry_id,
		current_codex_active_section
	)
	current_codex_selected_entry_id = str(model.get("resolvedSelectedEntryId", ""))
	current_codex_active_section = str(model.get("activeSection", "all"))
	codex_panel.render_codex(model)
```

```gdscript
func _on_codex_entry_selected(entry_id: String) -> void:
	current_codex_selected_entry_id = entry_id
	render_artifact_codex(current_codex_reward_table, current_codex_growth_state, current_codex_debug_all)
```

- [ ] **Step 4: Run focused and broad verification**

Run:

```powershell
& 'D:\Programming\godot_workspace\bin\Godot_v4.3-stable_win64_console.exe' --display-driver headless --audio-driver Dummy --path 'D:\Programming\ex_workspace\LootingTheLeviathan\app-LTL' --script tests/run_test_ui_read_models.gd --quit
& 'D:\Programming\godot_workspace\bin\Godot_v4.3-stable_win64_console.exe' --display-driver headless --audio-driver Dummy --path 'D:\Programming\ex_workspace\LootingTheLeviathan\app-LTL' --script tests/godot_contract_runner.gd --disable-crash-handler --quit
git diff --check
```

Expected:

- `UI_READ_MODEL_TESTS_OK`
- `GODOT_CONTRACTS_OK`
- No whitespace errors

- [ ] **Step 5: Commit the runtime-integration task**

```bash
git add app-LTL/src/ui/MainViewRuntime.gd app-LTL/src/ui/ArtifactCodexPanelUI.gd app-LTL/tests/test_ui_read_models.gd
git commit -m "feat: wire artifact codex book interactions"
```

## Self-Review

- Spec coverage:
  - Hybrid A+C layout: Task 2
  - Ratio-driven safe area without hardcoded sample pixels: Task 2
  - Right-grid image + rarity only: Tasks 1 and 2
  - Selection and section rerender flow: Task 3
  - Placeholder and fallback art descriptors: Task 1
- Placeholder scan:
  - No `TODO`, `TBD`, or “similar to previous task” placeholders remain.
- Type consistency:
  - `selectedEntryId`, `activeSection`, `resolvedSelectedEntryId`, `leftPage`, and `rightPage` naming are consistent across tasks.

## Execution Handoff

Plan complete and saved to `docs/superpowers/plans/2026-06-03-artifact-codex-book-implementation-plan.md`.

The user explicitly asked for immediate execution with subagent collaboration, so proceed with **Subagent-Driven (recommended)** in this session.
