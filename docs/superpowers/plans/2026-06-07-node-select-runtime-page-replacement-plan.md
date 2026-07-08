# Node Select Runtime Page Replacement Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the legacy `NodeSelectPanel` path with a new dedicated node-select runtime page that directly owns the live node map and backpack layout.

**Architecture:** Keep `NodeMapScene` as the interactive core, but stop mounting it under `Main.tscn`'s legacy `NodeSelectPanel`. Instead, add a new runtime page scene that exposes a compact header plus dedicated `MapHost` and `BackpackHost`, switch `node_select` routing to that page, verify the flow and layout, then delete the old `NodeSelectPanel` path and cleanup code.

**Tech Stack:** Godot 4.3, GDScript, existing page-scene host system, existing Godot contract runners.

---

### Task 1: Add the replacement node-select runtime page

**Files:**
- Create: `app-LTL/src/scenes/pages/NodeSelectRuntimePage.gd`
- Create: `app-LTL/src/scenes/pages/NodeSelectRuntimePage.tscn`
- Modify: `docs/source-map.md`

- [ ] **Step 1: Create the replacement page scene and script**

Add a new page that exposes:
- `BoardHead`
- `RouteSplit`
- `MapHost`
- `BackpackHost`
- compact title/chip labels updated from `apply_state(scene)`

- [ ] **Step 2: Update the source map for the new page files**

Add entries for:
- `app-LTL/src/scenes/pages/NodeSelectRuntimePage.gd`
- `app-LTL/src/scenes/pages/NodeSelectRuntimePage.tscn`

### Task 2: Switch runtime ownership to the new page

**Files:**
- Modify: `app-LTL/src/ui/MainViewRuntime.gd`
- Modify: `app-LTL/src/MainControllerRuntime.gd`
- Modify: `app-LTL/src/Main.tscn`

- [ ] **Step 1: Route `node_select` through `NodeSelectRuntimePage`**

Change the page-scene preload/registration so `node_select` uses the new page instead of the legacy node-select page.

- [ ] **Step 2: Mount live runtime children into the new page**

Reparent:
- `node_map_scene` -> `MapHost`
- `backpack_container` -> `BackpackHost`

When leaving `node_select`, restore `backpack_container` to its original parent.

- [ ] **Step 3: Remove runtime dependence on the legacy node-select panel**

Delete or neutralize:
- legacy `node_select_panel` visibility/render logic
- `set_node_select_text()` write path from the controller
- old node-select content-row creation under `NodeSelectPanel`

### Task 3: Update regression coverage for the replacement path

**Files:**
- Modify: `app-LTL/tests/run_page_scene_mapping_contract.gd`
- Modify: `app-LTL/tests/run_main_start_flow_contract.gd`
- Modify: `app-LTL/tests/run_main_layout_audit_contract.gd`
- Modify: `app-LTL/tests/test_ui_read_models.gd`

- [ ] **Step 1: RED test the new page ownership**

Require:
- node-select mockup maps to `NodeSelectRuntimePage.tscn`
- runtime flow mounts `node_map_scene` under `MapHost`
- runtime flow mounts `backpack_container` under `BackpackHost`

- [ ] **Step 2: Update layout assertions to the new page structure**

Containment checks should use:
- `RouteSplit`
- `MapHost`
- `BackpackHost`

- [ ] **Step 3: Remove legacy test assumptions**

Stop asserting on:
- `NodeSelectPanel`
- `NodeSelectText`
- `LivePanelHost`

### Task 4: Verify replacement, then remove the old path

**Files:**
- Delete: `app-LTL/src/scenes/pages/NodeSelectPage.gd`
- Delete: `app-LTL/src/scenes/pages/NodeSelectPage.tscn`
- Modify: `app-LTL/src/ui/MainViewRuntime.gd`
- Modify: `app-LTL/src/Main.tscn`
- Modify: `docs/source-map.md`

- [ ] **Step 1: Run focused verification before deletion**

Run:
- `powershell -NoProfile -ExecutionPolicy Bypass -File 'tools/invoke-godot.ps1' -ProjectPath 'app-LTL' -Headless -Script 'tests/run_page_scene_mapping_contract.gd' -Quit`
- `powershell -NoProfile -ExecutionPolicy Bypass -File 'tools/invoke-godot.ps1' -ProjectPath 'app-LTL' -Headless -Script 'tests/run_main_start_flow_contract.gd' -Quit`
- `powershell -NoProfile -ExecutionPolicy Bypass -File 'tools/invoke-godot.ps1' -ProjectPath 'app-LTL' -Headless -Script 'tests/run_main_layout_audit_contract.gd' -Quit`

- [ ] **Step 2: Delete the legacy node-select page and scene path**

Remove:
- old `NodeSelectPage.*`
- old `NodeSelectPanel` subtree in `Main.tscn`
- dead helper/state code in `MainViewRuntime.gd`

- [ ] **Step 3: Run full verification and visual QA**

Run:
- `powershell -NoProfile -ExecutionPolicy Bypass -File 'tools/run-compile-check.ps1'`
- launch the Godot runtime once and capture the node-select screen
- verify visually that the replacement page renders without overlap, clipping, or legacy surfaces
