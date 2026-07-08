# Character Select Starter Card Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the character-select starter set text buttons with structured VBox cards that emphasize the title, show tagged stats, and preserve the prep-column layout.

**Architecture:** Keep `CharacterSelectPage.gd` as the rendering owner for the page while extending `CharacterSelectLoadoutText.gd` to provide structured card data instead of raw multiline strings. The page script will instantiate clickable starter cards with nested labels and tag chips, then compensate for the extra card height by shrinking the bag-detail area so the outer board height stays stable.

**Tech Stack:** Godot 4 scene script (`.gd`), existing `CharacterSelectPage.tscn`, localized text from `TextCatalog`, contract coverage in `app-LTL/tests/run_character_select_cleanup_contract.gd`

---

### Task 1: Lock the new UI contract in tests

**Files:**
- Modify: `app-LTL/tests/run_character_select_cleanup_contract.gd`

- [ ] **Step 1: Write the failing test**

```gdscript
	var palette_red_title := character_page.get_node_or_null("Margin/VStack/BoardShell/ShellMargin/ShellVBox/BoardBody/PrepZone/ZoneMargin/ZoneVBox/PrepColumn/PaletteCard/PaletteMargin/PaletteVBox/PaletteScroll/PaletteList/Palette_red/CardMargin/CardVBox/Title") as Label
	var palette_red_tags := character_page.get_node_or_null("Margin/VStack/BoardShell/ShellMargin/ShellVBox/BoardBody/PrepZone/ZoneMargin/ZoneVBox/PrepColumn/PaletteCard/PaletteMargin/PaletteVBox/PaletteScroll/PaletteList/Palette_red/CardMargin/CardVBox/TagRow") as HBoxContainer
	var palette_red_body := character_page.get_node_or_null("Margin/VStack/BoardShell/ShellMargin/ShellVBox/BoardBody/PrepZone/ZoneMargin/ZoneVBox/PrepColumn/PaletteCard/PaletteMargin/PaletteVBox/PaletteScroll/PaletteList/Palette_red/CardMargin/CardVBox/Body") as Label
	_assert(palette_red_title != null, "starter palette renders a custom card title label")
	_assert_eq(palette_red_title.text if palette_red_title != null else "", "빨강 시작 세트", "starter palette title keeps the localized starter-set heading")
	_assert(palette_red_tags != null and palette_red_tags.get_child_count() >= 6, "starter palette exposes structured stat tags instead of a raw multiline string")
	_assert_contains(palette_red_body.text if palette_red_body != null else "", "붉은 유물", "starter palette body still explains the loadout identity")
```

- [ ] **Step 2: Run test to verify it fails**

Run: `python -m unittest app-LTL/tests/run_character_select_cleanup_contract.gd`

Expected: FAIL because the current implementation still creates plain `Button.text` rows and none of the nested title/tag/body nodes exist.

- [ ] **Step 3: Write minimal implementation**

```gdscript
# No production change in this task. Keep the failing assertions as the red phase.
```

- [ ] **Step 4: Run test to verify it still fails for the expected reason**

Run: `python -m unittest app-LTL/tests/run_character_select_cleanup_contract.gd`

Expected: FAIL with missing `Palette_red/.../Title` or equivalent nested-node assertion.

- [ ] **Step 5: Commit**

```bash
git add app-LTL/tests/run_character_select_cleanup_contract.gd
git commit -m "test: lock character select starter card structure"
```

### Task 2: Add structured starter-card data and render the new VBox cards

**Files:**
- Modify: `app-LTL/src/scenes/pages/character_select/CharacterSelectLoadoutText.gd`
- Modify: `app-LTL/src/scenes/pages/CharacterSelectPage.gd`
- Modify: `app-LTL/src/data/i18n/text-ko.json`

- [ ] **Step 1: Write the failing test**

```gdscript
	_assert_contains(palette_red_body.text if palette_red_body != null else "", "드릴", "starter palette body still names the primary loadout type")
	_assert_contains(palette_red_body.text if palette_red_body != null else "", "비컨", "starter palette body still names the support loadout type")
```

- [ ] **Step 2: Run test to verify it fails**

Run: `python -m unittest app-LTL/tests/run_character_select_cleanup_contract.gd`

Expected: FAIL because the body label does not exist yet and the structured text model has not been added.

- [ ] **Step 3: Write minimal implementation**

```gdscript
static func starter_palette_card_model(color_name: String) -> Dictionary:
	return {
		"title": TextCatalogScript.t("character.starter_set", [TextCatalogScript.color_label(color_name)]),
		"summary": "...",
		"tags": []
	}
```

```gdscript
var card := Button.new()
card.text = ""
var margin := MarginContainer.new()
var column := VBoxContainer.new()
var title := Label.new()
var tag_row := HBoxContainer.new()
var body := Label.new()
```

- [ ] **Step 4: Run test to verify it passes**

Run: `python -m unittest app-LTL/tests/run_character_select_cleanup_contract.gd`

Expected: PASS for the new nested title/body/tag assertions while preserving the existing layout checks.

- [ ] **Step 5: Commit**

```bash
git add app-LTL/src/scenes/pages/character_select/CharacterSelectLoadoutText.gd app-LTL/src/scenes/pages/CharacterSelectPage.gd app-LTL/src/data/i18n/text-ko.json app-LTL/tests/run_character_select_cleanup_contract.gd
git commit -m "feat: render structured starter cards"
```

### Task 3: Compensate layout height and verify the board stays stable

**Files:**
- Modify: `app-LTL/src/scenes/pages/CharacterSelectPage.gd`
- Modify: `app-LTL/tests/run_character_select_cleanup_contract.gd`

- [ ] **Step 1: Write the failing test**

```gdscript
	var bag_detail_card := character_page.get_node_or_null("Margin/VStack/BoardShell/ShellMargin/ShellVBox/BoardBody/PrepZone/ZoneMargin/ZoneVBox/PrepColumn/BagCard/BagMargin/BagVBox/BagDetailCard") as Control
	_assert(bag_detail_card != null and bag_detail_card.custom_minimum_size.y <= 96.0, "bag detail card gives back height to offset the taller starter cards")
```

- [ ] **Step 2: Run test to verify it fails**

Run: `python -m unittest app-LTL/tests/run_character_select_cleanup_contract.gd`

Expected: FAIL because `BagDetailCard` is currently created at `104.0` minimum height.

- [ ] **Step 3: Write minimal implementation**

```gdscript
detail_card.custom_minimum_size = Vector2(0.0, 92.0)
bag_card.custom_minimum_size.y = 204.0
```

- [ ] **Step 4: Run test to verify it passes**

Run: `python -m unittest app-LTL/tests/run_character_select_cleanup_contract.gd`

Expected: PASS and the existing assertions confirming stable board/palette heights remain green.

- [ ] **Step 5: Commit**

```bash
git add app-LTL/src/scenes/pages/CharacterSelectPage.gd app-LTL/tests/run_character_select_cleanup_contract.gd
git commit -m "fix: preserve prep column height with starter cards"
```
