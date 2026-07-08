# Character Select Verdant Runtime Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Upgrade the character-select page to the approved verdant three-column layout while keeping current flow intact, matching the Leviathan-select top menu pattern, and moving character/starter copy ownership out of the page script.

**Architecture:** Keep `CharacterSelectPage.gd` as the runtime owner for state application, page-level signal wiring, and responsive sizing, but move editable copy/model concerns into existing page-external data sources. Rebuild the page around three stable zones: a scrollable left expedition-log roster with hidden scrollbar chrome, a center hero stage that keeps the existing art pipeline and now owns the next-step CTA, and a right prep column that swaps the mini backpack hover model for a click-selected starter-item list plus a larger detail panel.

**Tech Stack:** Godot 4 scene/runtime scripts (`.gd`, `.tscn`), localized entity data in `app-LTL/src/data/i18n/text-ko.json` and `text-en.json`, starter artifacts from `app-LTL/src/models/Artifact.gd`, page contract runners in `app-LTL/tests/`, repo validation via `tools/run-compile-check.ps1`

---

## Objective Linkage

- `UI-001` - align the character-select screen to the approved sky / verdant / expedition direction while reducing the gap between mockup patterns and the Godot runtime.
- `VERIFY-001` - prove the redesign through focused character-select contracts, layout stability checks, and the broad compile-check path.

## Frozen Requirements

- Keep the top menu aligned with the already-implemented Leviathan-select page.
- Keep the existing character art and backdrop image ownership.
- Keep current navigation and selection flow working while the new design lands.
- Keep long roster copy, hero short copy, and starter-set descriptions editable outside the page script.
- Keep scroll behavior, but hide visible scrollbar chrome where requested.
- Do not allow hover, click, or scroll interactions to shift layout bounds.

## File Structure

- Modify: `app-LTL/src/scenes/pages/CharacterSelectPage.tscn`
  - Add the Leviathan-style top bar shell.
  - Repurpose the prep column from `MiniBag + CtaCard` to `StarterItemList + a restyled detail panel that keeps the existing `CtaCard` host node`.
  - Extend the hero copy block so it also hosts the next-step CTA.
- Modify: `app-LTL/src/scenes/pages/CharacterSelectPage.gd`
  - Wire the shared top menu buttons.
  - Render roster cards with long supporting copy.
  - Hide the roster scrollbar chrome while keeping scroll input.
  - Keep hero art/backdrop behavior and move the continue CTA into the center footer.
  - Replace hover-driven bag detail logic with click-selected starter item detail logic.
- Modify: `app-LTL/src/scenes/pages/character_select/CharacterSelectLoadoutText.gd`
  - Expand from summary text helper into the page-external starter-set model provider.
  - Expose palette card copy, starter item list models, and starter item detail models.
- Modify: `app-LTL/src/scenes/pages/character_select/CharacterSelectPaletteView.gd`
  - Restyle the starter set cards to match the approved prep-card pattern without hardcoded page copy.
- Modify: `app-LTL/src/controllers/run_flow/CharacterRosterLoader.gd`
  - Add externally editable roster/hero fields such as the long roster body copy and the center hero short line.
- Modify: `app-LTL/src/data/i18n/text-ko.json`
  - Add the new per-character fields and generic character-select UI copy keys.
- Modify: `app-LTL/src/data/i18n/text-en.json`
  - Mirror the new fields so locale fallbacks stay complete.
- Modify: `app-LTL/tests/run_character_select_cleanup_contract.gd`
  - Replace the old mini-bag / right-CTA assertions with the new page contract.
- Add: `app-LTL/tests/run_character_select_interaction_contract.gd`
  - Focus on click-selected starter-item detail behavior, hidden scrollbar chrome, and stable selection rendering.
- Add: `docs/request-ledgers/2026-07-03-ui-001-character-select-verdant-redesign.md`
  - Provide the explicit request ledger used by `tools/run-compile-check.ps1`.

### Task 1: Lock the new page contract before runtime edits

**Files:**
- Modify: `app-LTL/tests/run_character_select_cleanup_contract.gd`

- [ ] **Step 1: Write the failing test**

```gdscript
	var top_bar := character_page.get_node_or_null("TopBar") as PanelContainer
	var tabs_row := character_page.get_node_or_null("TopBar/TopBarMargin/TopBarRow/BrandRow/TabsRow") as HBoxContainer
	var roster_scroll_bar := character_page.get_node_or_null("Margin/VStack/BoardShell/ShellMargin/ShellVBox/BoardBody/SelectorZone/ZoneMargin/ZoneVBox/RosterScroll") as ScrollContainer
	var roster_body := character_page.get_node_or_null("Margin/VStack/BoardShell/ShellMargin/ShellVBox/BoardBody/SelectorZone/ZoneMargin/ZoneVBox/RosterScroll/RosterList/CharacterChoice_miner/CardMargin/CardVBox/Body") as Label
	var hero_continue_button := character_page.get_node_or_null("Margin/VStack/BoardShell/ShellMargin/ShellVBox/BoardBody/FeatureZone/ZoneMargin/ZoneVBox/HeroColumn/CopyCard/CopyMargin/CopyVBox/ContinueButton") as Button
	var starter_item_list := character_page.get_node_or_null("Margin/VStack/BoardShell/ShellMargin/ShellVBox/BoardBody/PrepZone/ZoneMargin/ZoneVBox/PrepColumn/BagCard/BagMargin/BagVBox/StarterItemList") as VBoxContainer
	var item_detail_card := character_page.get_node_or_null("Margin/VStack/BoardShell/ShellMargin/ShellVBox/BoardBody/PrepZone/ZoneMargin/ZoneVBox/PrepColumn/CtaCard") as PanelContainer
	_assert(top_bar != null, "character select owns the Leviathan-style top bar")
	_assert(tabs_row != null and tabs_row.get_child_count() >= 4, "character select renders the shared top menu group")
	_assert(roster_body != null, "character select roster card exposes a long supporting body label")
	_assert(hero_continue_button != null, "character select moves the next-step CTA into the center hero footer")
	_assert(starter_item_list != null, "character select prep column renders a starter item list instead of the mini bag")
	_assert(item_detail_card != null, "character select repurposes the lower prep card into a large item-detail panel")
	if roster_scroll_bar != null and roster_scroll_bar.get_v_scroll_bar() != null:
		_assert(not roster_scroll_bar.get_v_scroll_bar().visible, "character select keeps roster scrolling while hiding scrollbar chrome")
```

- [ ] **Step 2: Run test to verify it fails**

Run:

```powershell
$godot = 'D:\Programming\godot_workspace\bin\Godot_v4.3-stable_win64.exe'
& $godot --headless --path 'D:\Programming\ex_workspace\LootingTheLeviathan\app-LTL' --script 'res://tests/run_character_select_cleanup_contract.gd'
```

Expected: exit code `1` with failures for missing `TopBar`, missing nested roster `Body`, missing hero-footer `ContinueButton`, and missing `StarterItemList`.

- [ ] **Step 3: Keep the red phase only**

```gdscript
# Do not touch production files in this task.
# The failing assertions above become the contract for the redesign.
```

- [ ] **Step 4: Run the contract again to confirm the same red state**

Run:

```powershell
$godot = 'D:\Programming\godot_workspace\bin\Godot_v4.3-stable_win64.exe'
& $godot --headless --path 'D:\Programming\ex_workspace\LootingTheLeviathan\app-LTL' --script 'res://tests/run_character_select_cleanup_contract.gd'
```

Expected: exit code `1` and the failures still point to the new structure rather than an unrelated crash.

- [ ] **Step 5: Commit**

```bash
git add app-LTL/tests/run_character_select_cleanup_contract.gd
git commit -m "test: lock character select verdant redesign contract"
```

### Task 2: Externalize character roster and hero copy fields

**Files:**
- Modify: `app-LTL/src/controllers/run_flow/CharacterRosterLoader.gd`
- Modify: `app-LTL/src/data/i18n/text-ko.json`
- Modify: `app-LTL/src/data/i18n/text-en.json`

- [ ] **Step 1: Add the next failing assertions for data-backed copy**

```gdscript
	var selected_character := main_instance.call("_selected_character_data") if main_instance.has_method("_selected_character_data") else {}
	_assert(not str(selected_character.get("rosterLongCopy", "")).is_empty(), "selected character exposes rosterLongCopy from external data")
	_assert(not str(selected_character.get("heroLine", "")).is_empty(), "selected character exposes heroLine from external data")
```

- [ ] **Step 2: Run the contract to verify the new data fields fail**

Run:

```powershell
$godot = 'D:\Programming\godot_workspace\bin\Godot_v4.3-stable_win64.exe'
& $godot --headless --path 'D:\Programming\ex_workspace\LootingTheLeviathan\app-LTL' --script 'res://tests/run_character_select_cleanup_contract.gd'
```

Expected: exit code `1` because `CharacterRosterLoader` does not yet include `rosterLongCopy` or `heroLine`.

- [ ] **Step 3: Write the minimal implementation**

```gdscript
static func build_character_row(character_id: String, fallback_name: String, portrait_path: String, selectable: bool, default_portrait_path: String) -> Dictionary:
	return {
		"id": character_id,
		"name": TextCatalogScript.character_text(character_id, "name", fallback_name),
		"role": TextCatalogScript.character_text(character_id, "role", ""),
		"rosterMeta": TextCatalogScript.character_text(character_id, "rosterMeta", ""),
		"rosterLongCopy": TextCatalogScript.character_text(character_id, "rosterLongCopy", ""),
		"description": TextCatalogScript.character_text(character_id, "description", ""),
		"heroLine": TextCatalogScript.character_text(character_id, "heroLine", ""),
		"summary": TextCatalogScript.character_text(character_id, "summary", ""),
		"tags": TextCatalogScript.character_tags(character_id),
		"portraitPath": portrait_path if not portrait_path.is_empty() else default_portrait_path,
		"selectable": selectable,
		"locked": not selectable,
		"accentColor": character_accent(character_id)
	}
```

```json
"miner": {
  "name": "Anchor Miner",
  "role": "Frontline Excavator",
  "rosterMeta": "Lead Expedition",
  "rosterLongCopy": "Keep this long placeholder copy in character data so the left expedition-log card never hardcodes it in the page script.",
  "description": "Existing description field",
  "heroLine": "Read the first wave, then break the thickest surface first.",
  "summary": "Existing summary field",
  "tags": ["Frontline Drill", "Linear Pressure", "Color Start"]
}
```

- [ ] **Step 4: Run the contract to verify the data fields pass**

Run:

```powershell
$godot = 'D:\Programming\godot_workspace\bin\Godot_v4.3-stable_win64.exe'
& $godot --headless --path 'D:\Programming\ex_workspace\LootingTheLeviathan\app-LTL' --script 'res://tests/run_character_select_cleanup_contract.gd'
```

Expected: the `rosterLongCopy` and `heroLine` assertions pass, while the layout assertions from Task 1 still fail until the page is rebuilt.

- [ ] **Step 5: Commit**

```bash
git add app-LTL/src/controllers/run_flow/CharacterRosterLoader.gd app-LTL/src/data/i18n/text-ko.json app-LTL/src/data/i18n/text-en.json app-LTL/tests/run_character_select_cleanup_contract.gd
git commit -m "feat: externalize character select roster and hero copy"
```

### Task 3: Expand starter-set models outside the page script

**Files:**
- Modify: `app-LTL/src/scenes/pages/character_select/CharacterSelectLoadoutText.gd`
- Modify: `app-LTL/src/data/i18n/text-ko.json`
- Modify: `app-LTL/src/data/i18n/text-en.json`
- Modify: `app-LTL/tests/run_character_select_cleanup_contract.gd`

- [ ] **Step 1: Add the failing assertions for starter item models**

```gdscript
	var starter_items := CharacterSelectLoadoutText.starter_item_models("red")
	_assert_eq(starter_items.size(), 2, "red starter set exposes two starter item models")
	_assert_eq(str(starter_items[0].get("itemId", "")), "starter_red_drill", "starter item model keeps a stable drill id")
	_assert_eq(str(starter_items[1].get("itemId", "")), "starter_red_beacon", "starter item model keeps a stable beacon id")
	var starter_detail := CharacterSelectLoadoutText.detail_for_item_id("red", "starter_red_beacon")
	_assert(not str(starter_detail.get("title", "")).is_empty(), "starter item detail model exposes a title for the clicked panel")
	_assert(not str(starter_detail.get("body", "")).is_empty(), "starter item detail model exposes a body for the clicked panel")
```

- [ ] **Step 2: Run the contract to verify it fails**

Run:

```powershell
$godot = 'D:\Programming\godot_workspace\bin\Godot_v4.3-stable_win64.exe'
& $godot --headless --path 'D:\Programming\ex_workspace\LootingTheLeviathan\app-LTL' --script 'res://tests/run_character_select_cleanup_contract.gd'
```

Expected: exit code `1` because `starter_item_models()` and `detail_for_item_id()` do not exist yet.

- [ ] **Step 3: Write the minimal implementation**

```gdscript
static func starter_item_models(color_name: String) -> Array:
	var loadout := starter_loadout_for_color(color_name)
	var models: Array = []
	for artifact in loadout:
		models.append({
			"itemId": str(artifact.id),
			"title": starter_artifact_title(artifact),
			"summary": starter_artifact_summary(artifact),
			"metricLine": starter_palette_metric_line(artifact),
			"itemType": str(artifact.item_type),
			"colorName": str(artifact.energy_type)
		})
	return models

static func detail_for_item_id(color_name: String, item_id: String) -> Dictionary:
	for artifact in starter_loadout_for_color(color_name):
		if str(artifact.id) == item_id:
			return {
				"title": starter_artifact_title(artifact),
				"body": starter_artifact_summary(artifact),
				"metricLine": starter_palette_metric_line(artifact)
			}
	return empty_bag_detail()
```

```json
"character.starter.detail.metric": "{0}",
"character.starter.item.drill.label": "Base Drill",
"character.starter.item.beacon.label": "Base Beacon"
```

- [ ] **Step 4: Run the contract to verify it passes**

Run:

```powershell
$godot = 'D:\Programming\godot_workspace\bin\Godot_v4.3-stable_win64.exe'
& $godot --headless --path 'D:\Programming\ex_workspace\LootingTheLeviathan\app-LTL' --script 'res://tests/run_character_select_cleanup_contract.gd'
```

Expected: the new starter-model assertions pass, and the remaining failures are still limited to page layout/runtime ownership work.

- [ ] **Step 5: Commit**

```bash
git add app-LTL/src/scenes/pages/character_select/CharacterSelectLoadoutText.gd app-LTL/src/data/i18n/text-ko.json app-LTL/src/data/i18n/text-en.json app-LTL/tests/run_character_select_cleanup_contract.gd
git commit -m "feat: externalize character select starter item models"
```

### Task 4: Rebuild the scene structure around the approved three-column layout

**Files:**
- Modify: `app-LTL/src/scenes/pages/CharacterSelectPage.tscn`
- Modify: `app-LTL/src/scenes/pages/CharacterSelectPage.gd`
- Modify: `app-LTL/src/scenes/pages/character_select/CharacterSelectPaletteView.gd`

- [ ] **Step 1: Add the next failing assertions for the final node paths**

```gdscript
	var top_actions := character_page.get_node_or_null("TopBar/TopBarMargin/TopBarRow/TopActions") as HBoxContainer
	var roster_first_card := character_page.get_node_or_null("Margin/VStack/BoardShell/ShellMargin/ShellVBox/BoardBody/SelectorZone/ZoneMargin/ZoneVBox/RosterScroll/RosterList/CharacterChoice_miner") as Button
	var hero_line := character_page.get_node_or_null("Margin/VStack/BoardShell/ShellMargin/ShellVBox/BoardBody/FeatureZone/ZoneMargin/ZoneVBox/HeroColumn/CopyCard/CopyMargin/CopyVBox/HeroLine") as Label
	var starter_item_one := character_page.get_node_or_null("Margin/VStack/BoardShell/ShellMargin/ShellVBox/BoardBody/PrepZone/ZoneMargin/ZoneVBox/PrepColumn/BagCard/BagMargin/BagVBox/StarterItemList/StarterItem_starter_red_drill") as Button
	var item_detail_body := character_page.get_node_or_null("Margin/VStack/BoardShell/ShellMargin/ShellVBox/BoardBody/PrepZone/ZoneMargin/ZoneVBox/PrepColumn/CtaCard/CtaMargin/CtaVBox/ItemDetailBody") as Label
	_assert(top_actions != null, "character select top bar exposes the right-side action host")
	_assert(roster_first_card != null, "character select still renders clickable roster cards after the redesign")
	_assert(hero_line != null, "character select center footer renders the per-character hero line")
	_assert(starter_item_one != null, "character select prep column renders the first starter item button")
	_assert(item_detail_body != null, "character select repurposes the lower prep card body into item detail copy")
```

- [ ] **Step 2: Run the contract to verify it fails**

Run:

```powershell
$godot = 'D:\Programming\godot_workspace\bin\Godot_v4.3-stable_win64.exe'
& $godot --headless --path 'D:\Programming\ex_workspace\LootingTheLeviathan\app-LTL' --script 'res://tests/run_character_select_cleanup_contract.gd'
```

Expected: exit code `1` because the scene tree has not yet been rebuilt to those paths.

- [ ] **Step 3: Write the minimal implementation**

```gdscript
@onready var top_bar: PanelContainer = $TopBar
@onready var tabs_row: HBoxContainer = $TopBar/TopBarMargin/TopBarRow/BrandRow/TabsRow
@onready var top_actions: HBoxContainer = $TopBar/TopBarMargin/TopBarRow/TopActions
@onready var starter_item_list: VBoxContainer = $Margin/VStack/BoardShell/ShellMargin/ShellVBox/BoardBody/PrepZone/ZoneMargin/ZoneVBox/PrepColumn/BagCard/BagMargin/BagVBox/StarterItemList
@onready var item_detail_title: Label = $Margin/VStack/BoardShell/ShellMargin/ShellVBox/BoardBody/PrepZone/ZoneMargin/ZoneVBox/PrepColumn/CtaCard/CtaMargin/CtaVBox/ItemDetailTitle
@onready var item_detail_body: Label = $Margin/VStack/BoardShell/ShellMargin/ShellVBox/BoardBody/PrepZone/ZoneMargin/ZoneVBox/PrepColumn/CtaCard/CtaMargin/CtaVBox/ItemDetailBody
@onready var hero_line: Label = $Margin/VStack/BoardShell/ShellMargin/ShellVBox/BoardBody/FeatureZone/ZoneMargin/ZoneVBox/HeroColumn/CopyCard/CopyMargin/CopyVBox/HeroLine
```

```gdscript
func _apply_cleanup_layout() -> void:
	page_title.text = TextCatalogScript.t("character.page.title")
	_bind_top_menu()
	_hide_scrollbar_chrome(roster_scroll)
	_hide_scrollbar_chrome(palette_scroll)
	copy_card.size_flags_vertical = Control.SIZE_SHRINK_END
	cta_card.custom_minimum_size.y = 188.0
	continue_button.reparent(copy_card.get_node("CopyMargin/CopyVBox"))
```

```gdscript
static func build_palette_button(color_name: String) -> Button:
	var model := CharacterSelectLoadoutTextScript.starter_palette_card_model(color_name)
	var button := Button.new()
	button.name = "Palette_%s" % color_name
	button.custom_minimum_size = Vector2(0.0, 112.0)
	button.clip_contents = true
	# card children stay nested so the page can theme them without page-local copy strings
	return button
```

- [ ] **Step 4: Run the contract to verify the structure passes**

Run:

```powershell
$godot = 'D:\Programming\godot_workspace\bin\Godot_v4.3-stable_win64.exe'
& $godot --headless --path 'D:\Programming\ex_workspace\LootingTheLeviathan\app-LTL' --script 'res://tests/run_character_select_cleanup_contract.gd'
```

Expected: the new node-path assertions pass, while interaction-specific assertions still fail until click-selected detail state is implemented.

- [ ] **Step 5: Commit**

```bash
git add app-LTL/src/scenes/pages/CharacterSelectPage.tscn app-LTL/src/scenes/pages/CharacterSelectPage.gd app-LTL/src/scenes/pages/character_select/CharacterSelectPaletteView.gd
git commit -m "feat: rebuild character select layout for verdant runtime"
```

### Task 5: Implement stable click-selected starter item detail behavior

**Files:**
- Modify: `app-LTL/src/scenes/pages/CharacterSelectPage.gd`
- Add: `app-LTL/tests/run_character_select_interaction_contract.gd`

- [ ] **Step 1: Write the failing focused interaction test**

```gdscript
extends SceneTree

func _run() -> void:
	var main_scene := load("res://src/Main.tscn") as PackedScene
	var main := main_scene.instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	var page := main.get("character_select_page") as Control
	var drill := page.get_node("Margin/VStack/BoardShell/ShellMargin/ShellVBox/BoardBody/PrepZone/ZoneMargin/ZoneVBox/PrepColumn/BagCard/BagMargin/BagVBox/StarterItemList/StarterItem_starter_red_drill") as Button
	var beacon := page.get_node("Margin/VStack/BoardShell/ShellMargin/ShellVBox/BoardBody/PrepZone/ZoneMargin/ZoneVBox/PrepColumn/BagCard/BagMargin/BagVBox/StarterItemList/StarterItem_starter_red_beacon") as Button
	var detail_title := page.get_node("Margin/VStack/BoardShell/ShellMargin/ShellVBox/BoardBody/PrepZone/ZoneMargin/ZoneVBox/PrepColumn/CtaCard/CtaMargin/CtaVBox/ItemDetailTitle") as Label
	var detail_body := page.get_node("Margin/VStack/BoardShell/ShellMargin/ShellVBox/BoardBody/PrepZone/ZoneMargin/ZoneVBox/PrepColumn/CtaCard/CtaMargin/CtaVBox/ItemDetailBody") as Label
	beacon.pressed.emit()
	await process_frame
	assert(detail_title.text.contains("Beacon"))
	var stable_height := page.size.y
	drill.mouse_entered.emit()
	await process_frame
	assert(detail_title.text.contains("Beacon"))
	assert(is_equal_approx(page.size.y, stable_height))
	assert(not detail_body.text.is_empty())
	quit()
```

- [ ] **Step 2: Run the focused interaction contract to verify it fails**

Run:

```powershell
$godot = 'D:\Programming\godot_workspace\bin\Godot_v4.3-stable_win64.exe'
& $godot --headless --path 'D:\Programming\ex_workspace\LootingTheLeviathan\app-LTL' --script 'res://tests/run_character_select_interaction_contract.gd'
```

Expected: exit code `1` because the page still updates details from hover state or does not keep a clicked selection.

- [ ] **Step 3: Write the minimal implementation**

```gdscript
var _selected_starter_item_id := ""

func _refresh_starter_item_list() -> void:
	for child in starter_item_list.get_children():
		child.queue_free()
	for item_model in CharacterSelectLoadoutTextScript.starter_item_models(_selected_color):
		var item_id := str(item_model.get("itemId", ""))
		var button := _build_starter_item_button(item_model)
		button.pressed.connect(func() -> void:
			_selected_starter_item_id = item_id
			_refresh_starter_item_styles()
			_refresh_starter_item_detail()
			interaction_sfx_requested.emit("item_click")
		)
		starter_item_list.add_child(button)
	if _selected_starter_item_id.is_empty():
		_selected_starter_item_id = str(CharacterSelectLoadoutTextScript.starter_item_models(_selected_color)[0].get("itemId", ""))
	_refresh_starter_item_styles()
	_refresh_starter_item_detail()

func _refresh_starter_item_detail() -> void:
	var detail := CharacterSelectLoadoutTextScript.detail_for_item_id(_selected_color, _selected_starter_item_id)
	item_detail_title.text = str(detail.get("title", ""))
	item_detail_body.text = "%s\n%s" % [str(detail.get("metricLine", "")), str(detail.get("body", ""))]
```

- [ ] **Step 4: Run the focused interaction contract to verify it passes**

Run:

```powershell
$godot = 'D:\Programming\godot_workspace\bin\Godot_v4.3-stable_win64.exe'
& $godot --headless --path 'D:\Programming\ex_workspace\LootingTheLeviathan\app-LTL' --script 'res://tests/run_character_select_interaction_contract.gd'
```

Expected: exit code `0` and `CHARACTER_SELECT_INTERACTION_CONTRACT_OK` after the clicked item remains selected, hover no longer overrides the detail panel, and the page height stays stable.

- [ ] **Step 5: Commit**

```bash
git add app-LTL/src/scenes/pages/CharacterSelectPage.gd app-LTL/tests/run_character_select_interaction_contract.gd
git commit -m "feat: add click-selected starter item detail behavior"
```

### Task 6: Finish the visual/runtime verification pass

**Files:**
- Add: `docs/request-ledgers/2026-07-03-ui-001-character-select-verdant-redesign.md`

- [ ] **Step 1: Write the request ledger used for verification**

```md
# Request Analysis

## Goal
- Upgrade the character-select page to the approved verdant redesign while preserving current flow and shared top-menu behavior.

## Frozen Requirements
- Follow the Leviathan-select top menu pattern.
- Keep character art/backdrop ownership.
- Keep copy and starter-set content editable outside the page script.
- Keep layout stable across click, hover, and scroll interactions.
```

- [ ] **Step 2: Run the focused character-select contracts**

Run:

```powershell
$godot = 'D:\Programming\godot_workspace\bin\Godot_v4.3-stable_win64.exe'
& $godot --headless --path 'D:\Programming\ex_workspace\LootingTheLeviathan\app-LTL' --script 'res://tests/run_character_select_cleanup_contract.gd'
& $godot --headless --path 'D:\Programming\ex_workspace\LootingTheLeviathan\app-LTL' --script 'res://tests/run_character_select_interaction_contract.gd'
& $godot --headless --path 'D:\Programming\ex_workspace\LootingTheLeviathan\app-LTL' --script 'res://tests/run_main_layout_audit_contract.gd'
& $godot --headless --path 'D:\Programming\ex_workspace\LootingTheLeviathan\app-LTL' --script 'res://tests/run_page_scene_mapping_contract.gd'
```

Expected: all four scripts exit `0`, with the character-select runners printing their success markers and the broader audits staying green.

- [ ] **Step 3: Run the broad compile-check path**

Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools/run-compile-check.ps1 -RequestLedger docs/request-ledgers/2026-07-03-ui-001-character-select-verdant-redesign.md
```

Expected: `SOURCE_MAP_GATE_OK`, `REQUEST_ANALYSIS_GATE_OK`, `PAGE_CONTRACT_GATE_OK`, `TRANSITION_SAFETY_GATE_OK`, and `Compilation Check: PASSED (GODOT_CONTRACTS_OK)`.

- [ ] **Step 4: Capture manual interaction proof if any automated check is missing**

Run:

```text
1. Open character select at 1440x900.
2. Scroll the left roster with the wheel and confirm the list moves while the scrollbar chrome stays hidden.
3. Change characters and confirm the left long copy, center hero line, and center CTA copy update without overflow.
4. Change starter colors and confirm the right item list refreshes without the board height shifting.
5. Click each starter item and confirm the detail panel updates on click, stays pinned, and does not change on hover alone.
```

Expected: written notes or screenshots prove the remaining interactive behavior if a runner does not cover it.

- [ ] **Step 5: Commit**

```bash
git add docs/request-ledgers/2026-07-03-ui-001-character-select-verdant-redesign.md
git commit -m "docs: add character select verdant redesign verification ledger"
```

## Self-Review

1. **Spec coverage:** This plan covers the shared top menu, left roster long copy, hidden scrollbars, center hero CTA relocation, externalized character copy, externalized starter-set models, click-selected right-side detail behavior, and broad verification tied to `UI-001` and `VERIFY-001`.
2. **Placeholder scan:** No `TBD`, `TODO`, or "implement later" placeholders remain. Each task names concrete files, concrete commands, and concrete node/data changes.
3. **Type consistency:** `rosterLongCopy`, `heroLine`, `starter_item_models()`, `detail_for_item_id()`, `StarterItemList`, `ItemDetailTitle`, and `ItemDetailBody` are used consistently across data, runtime, and test tasks.

## Execution Handoff

Plan complete and saved to `docs/superpowers/plans/2026-07-03-character-select-verdant-runtime-redesign.md`. Two execution options:

**1. Subagent-Driven (recommended)** - I dispatch a fresh subagent per task, review between tasks, fast iteration

**2. Inline Execution** - Execute tasks in this session using executing-plans, batch execution with checkpoints

Which approach?
