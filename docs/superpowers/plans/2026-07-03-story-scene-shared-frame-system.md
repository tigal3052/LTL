# Story Scene Shared Frame System Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Refactor the story scene into a reusable shared-frame system with minimal top chrome while preserving existing story routing, continue/skip, and typewriter behavior.

**Architecture:** Keep `story_scene` as the existing meta-page owner, but move visible story-frame layout responsibility into reusable page-local frame component(s) under a dedicated `story_scene/` subfolder. Drive frame presentation from `story-scenes.json` and `StorySceneReadModel.gd` so content authors can swap art and frame presentation without editing page logic.

**Tech Stack:** Godot 4.3, GDScript, Control/Container UI, existing `LTLTheme`, release-content JSON, focused Godot contract runners.

---

### Task 1: Add failing projection/runtime tests for the shared story frame

**Files:**
- Modify: `app-LTL/tests/test_story_scene_contract.gd`
- Modify: `app-LTL/tests/run_interaction_audio_runtime_contract.gd`
- Create: `app-LTL/tests/run_story_scene_runtime_contract.gd`

- [ ] Add a read-model contract that expects shared-frame presentation metadata to be projected.
- [ ] Add or adjust runtime assertions so the story page is expected to expose a reusable `StoryFrame` surface and keep top chrome minimal.
- [ ] Run the smallest focused tests and confirm they fail for the expected missing-structure reason.

### Task 2: Create the reusable story-frame component surface

**Files:**
- Create: `app-LTL/src/scenes/pages/story_scene/StorySceneFrame.gd`
- Create: `app-LTL/src/scenes/pages/story_scene/StorySceneFrame.tscn`
- Create: `app-LTL/src/scenes/pages/story_scene/StorySceneFrameBits.gd`

- [ ] Build the frame surface that owns background art, portrait slots, minimal top chrome, dialogue slab, speaker tag, and action row.
- [ ] Keep the API page-friendly: `apply_model(...)` plus direct access to body/progress/buttons needed by `StoryScenePage`.
- [ ] Keep layout names and bounds deterministic so focused runtime tests can inspect them.

### Task 3: Refactor `StoryScenePage` to delegate visible layout to the shared frame

**Files:**
- Modify: `app-LTL/src/scenes/pages/StoryScenePage.gd`
- Modify: `app-LTL/src/scenes/pages/StoryScenePage.tscn`

- [ ] Replace page-local layout ownership with the new `StoryFrame` instance while preserving signal names and typewriter ownership.
- [ ] Keep `continue_requested`, `skip_requested`, and `interaction_sfx_requested` behavior unchanged from the controller’s perspective.
- [ ] Re-run the focused tests and make them green before broader verification.

### Task 4: Extend story-scene authoring metadata and projection

**Files:**
- Modify: `app-LTL/src/data/story-scenes.json`
- Modify: `app-LTL/src/ui/read_models/StorySceneReadModel.gd`
- Modify: `app-LTL/src/models/StoryScene.gd`
- Modify: `app-LTL/src/vocabulary/ReleaseContentVocab.gd` only if validation needs to understand the new optional fields

- [ ] Add minimal presentation metadata that supports reusable-frame authoring without changing route-selection semantics.
- [ ] Project normalized frame metadata into the runtime model with stable defaults.
- [ ] Keep the content contract backward-safe and avoid making unrelated story fields mandatory unless tests require it.

### Task 5: Verify, refresh docs, and close out

**Files:**
- Modify: `docs/codex-worklog/plan_LootingTheLeviathan_2026-07-03.md`
- Modify: `docs/codex-worklog/history_LootingTheLeviathan_2026-07-03.md`
- Modify: `docs/codex-worklog/complete_LootingTheLeviathan_2026-07-03.md`
- Modify: `docs/source-map.md`

- [ ] Run focused story-scene tests first.
- [ ] Run source-map refresh if new story-scene files are created.
- [ ] Run the smallest broader compile/quality verification that covers the modified files.
- [ ] Record what changed, what was verified, and any remaining manual gaps.
