# Runtime Owner Separation Plan

> **For follow-up refactor workers:** keep `MainController.gd` and `MainUI.gd` as scene-entry facades, and split active runtime owners without reactivating archived legacy surfaces.

**Goal:** Separate the currently active runtime owners from preserved legacy/archive code so the live debug path is easier to reason about and future edits stop accumulating in thousand-line owner files.

**Architecture:** Treat the live runtime as four layers: scene-entry facades, active runtime owners, extracted leaf helpers, and explicit archive/legacy storage. Move page-specific layout and phase-specific orchestration out of the owner files into smaller leaf scripts while the harness freezes the current owner ceilings.

**Tech Stack:** Godot 4.3 GDScript, `.tscn` page scenes, PowerShell harness gates.

---

## Current Ownership Snapshot

- Scene-entry facades
  - `app-LTL/src/MainController.gd`
  - `app-LTL/src/ui/MainUI.gd`
- Active runtime owners that are live in debug runs
  - `app-LTL/src/MainControllerRuntime.gd`
  - `app-LTL/src/ui/MainViewRuntime.gd`
  - `app-LTL/src/scenes/node_map/NodeMapScene.gd`
  - `app-LTL/src/scenes/pages/NodeSelectRuntimePage.gd`
  - `app-LTL/src/ui/RewardRevealOverlay.gd`
  - `app-LTL/src/ui/ArtifactCodexPanelUI.gd`
  - `app-LTL/src/ui/BackpackUI.gd`
- Active leaf surfaces that should stay small
  - `app-LTL/src/scenes/pages/*.gd`
  - `app-LTL/src/ui/read_models/*.gd`
  - `app-LTL/src/ui/presenters/*.gd`
- Preserved legacy or archive surfaces
  - `app-LTL/src/ui/legacy/**`
  - `app-LTL/prototype/**`
  - `docs/comment-gates/backups/**`

## Mixed Areas To Untangle Next

1. `MainViewRuntime.gd`
   - Still owns page registration, popup creation, reward-board sizing, backpack reparenting, and some page-specific layout policies in one file.
2. `MainControllerRuntime.gd`
   - Still mixes meta-flow state, combat/reward handoff control, codex debug state, and run progression orchestration.
3. `NodeSelectRuntimePage.gd` plus `NodeMapScene.gd`
   - The dedicated page exists, but map-host wiring and node-map view responsibilities still straddle both files.
4. `RewardRevealOverlay.gd`, `ArtifactCodexPanelUI.gd`, `BackpackUI.gd`
   - These are live owners, but each still bundles view composition with policy or content-shaping logic that can move into presenters/read models.

## Refactor Waves

### Wave 1: Make the live boundary obvious

- Keep `MainController.gd` and `MainUI.gd` as the only scene-entry wrappers.
- Add or refresh comments/doc ownership notes wherever a file is intentionally archive-only.
- Make any preserved legacy helper live under `app-LTL/src/ui/legacy/**` or another clearly archived path instead of leaving it adjacent to the active path without a label.

### Wave 2: Split `MainViewRuntime.gd` by responsibility

- Completed in the current branch:
  - Extracted page registration and page-host mounting into `PageSceneRegistry.gd`.
  - Extracted reward-board measurement and containment math into `RewardBoardLayoutPolicy.gd`.
  - Extracted popup/overlay front-order plus pause-state projection into `PopupOverlayHost.gd`.
  - Extracted page copy and defeat wireframe projection into `PageSceneModelBuilder.gd`.
  - Extracted safe-shell and shared-backpack layout budget math into `AppShellLayoutPolicy.gd`.
- Remaining splits required to push `MainViewRuntime.gd` from 2375 lines toward the low hundreds:
  - Move reward card cloud rendering, drag anchors, and inspector projection into a dedicated reward-board coordinator plus small policy helpers.
  - Move reward reveal overlay lifecycle and source-rect math into a focused ceremony host helper.
  - Move page bootstrap and signal bridge wiring into a page-scene bootstrap helper.
  - Move shared backpack docking and top-content/node-select reparent orchestration into a dedicated backpack host coordinator.
- Keep `MainViewRuntime.gd` as the top-level composition root that delegates to those helpers.

### Wave 3: Split `MainControllerRuntime.gd` by flow

- Extract meta-page start flow and roster selection into a dedicated start-flow coordinator.
- Extract reward-ceremony and reward-claim handoff logic into a focused reward-flow coordinator.
- Extract codex/debug-only state toggles behind a separate helper so the main controller only keeps player-facing orchestration.

### Wave 4: Finish page-local ownership

- Keep `CharacterSelectPage.gd`, `LeviathanSelectPage.gd`, `DefeatPage.gd`, and future page scripts below the shared page cap.
- Move any node-select-only formatting logic that still lives in shared runtime files into `NodeSelectRuntimePage.gd` or `NodeMapScene.gd`, then split again if those page-local owners cross their caps.
- Use read models and presenters for formatting and layout policy before introducing another large page script.

## Harness Rules That Now Protect This

- `docs/architectural-gates/runtime-size-gate.md` freezes current oversized owners close to their current size so growth fails immediately.
- `app-LTL/src/scenes/pages/*.gd` now has a hard cap of 600 lines, with `NodeSelectRuntimePage.gd` called out as a temporary exception that must shrink in a later wave.
- `app-LTL/src/ui/read_models/*.gd` and `app-LTL/src/ui/presenters/*.gd` stay capped at 300 and 200 lines so future extractions land as small leaves instead of recreating new owner blobs.

## Exit Criteria For The Follow-Up Refactor

- Active runtime owners each have one primary responsibility and delegate page-specific or formatting-specific work outward.
- Archive-only code is clearly labeled by path and is not mistaken for the debug runtime path.
- `runtime-size-gate.ps1`, `run-compile-check.ps1`, and `run-ltl-quality-gate.ps1` all stay green after every extraction wave.
- No newly created active runtime script exceeds the few-hundred-line cap for its surface.
