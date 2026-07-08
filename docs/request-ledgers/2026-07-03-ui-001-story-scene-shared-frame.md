# 2026-07-03 UI-001 story-scene shared-frame closeout

## Request Summary

- Systemize option 3 by extracting a reusable shared story frame instead of keeping the whole story layout embedded in `StoryScenePage`.
- Minimize top chrome on the story screen while preserving current story routing, continue/skip flow, and typewriter behavior.
- Make story authoring easier by moving background/portrait/frame presentation decisions into story-scene data and read-model projection.
- Verify the change with focused runtime/component checks first, then broader project gates as far as the current workspace baseline allows.

## Preserved Invariants

- The existing `story_scene` meta-page routing and return handoff back to `character_select` remain unchanged.
- `continue_requested`, `skip_requested`, and `interaction_sfx_requested` stay as the story page contract.
- The typewriter reveal, per-step progression, and shown-once story selection behavior remain intact.
- Stitch output is treated as layout/style reference only; no Stitch-specific copy or naming is shipped into runtime content.
- Existing unrelated dirty worktree changes are not reverted.

## Mutable Scope

- `app-LTL/src/scenes/pages/StoryScenePage.gd`
- `app-LTL/src/scenes/pages/StoryScenePage.tscn`
- `app-LTL/src/scenes/pages/story_scene/StorySceneFrame.gd`
- `app-LTL/src/scenes/pages/story_scene/StorySceneFrame.tscn`
- `app-LTL/src/scenes/pages/story_scene/StorySceneFrameBits.gd`
- `app-LTL/src/ui/read_models/StorySceneReadModel.gd`
- `app-LTL/src/models/StoryScene.gd`
- `app-LTL/src/vocabulary/ReleaseContentVocab.gd`
- `app-LTL/src/data/story-scenes.json`
- `app-LTL/tests/test_story_scene_contract.gd`
- `app-LTL/tests/test_release_content_contract.gd`
- `app-LTL/tests/run_interaction_audio_runtime_contract.gd`
- `app-LTL/tests/run_story_scene_runtime_contract.gd`
- `docs/source-map.md`

## Source Map Findings

- `docs/source-map.md`
  - The live source map is the ownership/freshness gate and must be refreshed after adding the new shared story-frame files.
- `app-LTL/src/scenes/pages/StoryScenePage.gd`
  - The page remains the story flow owner for continue/skip/typewriter behavior and should not absorb reusable layout chrome again.
- `app-LTL/src/scenes/pages/story_scene/StorySceneFrame.gd`
  - The new file is the correct reusable owner for story-screen backdrop, portrait, dialogue, and minimal top-chrome presentation.
- `app-LTL/src/ui/read_models/StorySceneReadModel.gd`
  - The read model owns projection of scene/step data into a UI-safe `frame` payload for the shared shell.
- `app-LTL/src/data/story-scenes.json`
  - The story content table is the author-facing surface for background, portrait, and per-step presentation metadata.
- `app-LTL/tests/run_story_scene_runtime_contract.gd`
  - The focused runtime contract is the viewport/path/left-right layout proof for the new shared frame.

## Root Cause Review

- Observed symptom: the story screen still owned all layout and theme detail inside `StoryScenePage`, making the approved redesign hard to reuse and difficult for content authors to extend without page-script edits.
- Evidence: the original page directly managed backdrop, portraits, dialogue panel, and speaker label nodes with no shared frame owner, while story-scene data exposed only text/image primitives and no frame metadata.
- Root cause target: `app-LTL/src/scenes/pages/StoryScenePage.gd`
- Supporting surface: `app-LTL/src/ui/read_models/StorySceneReadModel.gd` and `app-LTL/src/data/story-scenes.json` did not project or store reusable frame metadata, so visual changes depended on page-local code edits.
- Rejected workaround: repaint the existing embedded panel in place or add more page-local conditionals without separating the reusable frame owner.
- Chosen fix: extract a dedicated `story_scene/StorySceneFrame` component, keep flow control in `StoryScenePage`, and extend story data/read-model projection with shared-frame metadata defaults plus per-step overrides.

## Transition Safety Review

- no transition impact
- reason: page registration, meta-page ownership, and story-scene controller signals remain unchanged; only the story page's visual owner and projected frame metadata changed.
- guard runner: `app-LTL/tests/run_story_scene_runtime_contract.gd`
- guard marker: `STORY_SCENE_RUNTIME_CONTRACT_OK`
- mapping runner: `app-LTL/tests/godot_contract_runner.gd`
- mapping marker: absence of story-scene-specific failures after the shared-frame changes, with unrelated baseline failures remaining elsewhere.

## Feature Unit Lifecycle Plan

- Design stage: keep story-screen work split between flow ownership (`StoryScenePage`) and reusable presentation ownership (`StorySceneFrame`) so the redesign does not regrow into a single large page owner.
- Implementation stage: limit controller-visible changes to read-model/data projection and frame extraction instead of changing page routing or introducing shell-wide chrome logic.
- Maintenance stage: future story additions should prefer new `story-scenes.json` rows and `presentation` metadata before adding new page-script branches.
- Capsule boundary: the shared story frame owns the visual shell; story scene selection, telemetry, and progression stay in their existing owners.
- Size trigger: if more story-shell variants appear, extend `StorySceneFrameBits` or add a second frame capsule instead of pushing more conditional layout code into `StoryScenePage`.

## Refactor/Delete Disposition

- Keep `StoryScenePage` as the runtime flow owner and refactor it into a delegating controller instead of deleting it.
- Keep current story-scene content ids, routing behavior, and telemetry/event naming intact.
- Do not delete existing story art paths or change narrative trigger semantics in this request.

## Verification Checklist

- Run `powershell -NoProfile -ExecutionPolicy Bypass -File LTL-harness/tools/source-map-gate.ps1 -Root . -Refresh`.
- Run `powershell -NoProfile -ExecutionPolicy Bypass -File LTL-harness/tools/request-analysis-gate.ps1 -Ledger docs/request-ledgers/2026-07-03-ui-001-story-scene-shared-frame.md -Mode pre-complete`.
- Run `powershell -NoProfile -ExecutionPolicy Bypass -File tools/invoke-godot.ps1 -ProjectPath app-LTL -Headless -Script res://tests/run_story_scene_runtime_contract.gd`.
- Run `powershell -NoProfile -ExecutionPolicy Bypass -File tools/invoke-godot.ps1 -ProjectPath app-LTL -Headless -Script res://tests/run_interaction_audio_runtime_contract.gd`.
- Run `powershell -NoProfile -ExecutionPolicy Bypass -File tools/invoke-godot.ps1 -ProjectPath app-LTL -Headless -Script res://tests/godot_contract_runner.gd`.
- Run `powershell -NoProfile -ExecutionPolicy Bypass -File tools/run-compile-check.ps1 -RequestLedger docs/request-ledgers/2026-07-03-ui-001-story-scene-shared-frame.md`.

## Verification Notes

- `LTL-harness/tools/source-map-gate.ps1 -Root . -Refresh` passed with `SOURCE_MAP_REFRESH_OK: docs/source-map.md` and `SOURCE_MAP_GATE_OK`.
- `LTL-harness/tools/request-analysis-gate.ps1 -Ledger docs/request-ledgers/2026-07-03-ui-001-story-scene-shared-frame.md -Mode pre-complete` passed with `REQUEST_ANALYSIS_GATE_OK`.
- `LTL-harness/tools/test-size-gate.ps1 -Root .` passed with `TEST_SIZE_GATE_OK` and legacy warnings only.
- `LTL-harness/tools/runtime-size-gate.ps1 -Root .` passed with `RUNTIME_SIZE_GATE_OK`.
- `LTL-harness/tools/page-contract-gate.ps1 -Root . -GodotPath D:\Programming\godot_workspace\bin\Godot_v4.3-stable_win64_console.exe` passed with `PAGE_CONTRACT_GATE_OK`, including `PAGE_SCENE_MAPPING_CONTRACT_OK`, `UI_READ_MODEL_TESTS_OK`, `MAIN_START_FLOW_CONTRACT_OK`, `MAIN_LAYOUT_AUDIT_CONTRACT_OK`, and `REWARD_CLAIM_BOARD_CONTRACT_OK`.
- `LTL-harness/tools/transition-safety-gate.ps1 -Root . -GodotPath D:\Programming\godot_workspace\bin\Godot_v4.3-stable_win64_console.exe -Ledger docs/request-ledgers/2026-07-03-ui-001-story-scene-shared-frame.md` passed with `TRANSITION_SAFETY_GATE_OK`.
- `tools/invoke-godot.ps1 -ProjectPath app-LTL -Headless -Script res://tests/run_story_scene_runtime_contract.gd` exited `0` and emitted `STORY_SCENE_RUNTIME_CONTRACT_OK`.
- `tools/invoke-godot.ps1 -ProjectPath app-LTL -Headless -Script res://tests/run_interaction_audio_runtime_contract.gd` still exits `1` because of pre-existing character-select starter-set assertions, but it did not report new story-scene typewriter/button-path failures after the shared-frame change.
- `tools/invoke-godot.ps1 -ProjectPath app-LTL -Headless -Script res://tests/godot_contract_runner.gd` still exits `1` because of unrelated baseline node-routing and Korean locale catalog/read-model failures; it did not report new story-scene contract or release-content failures from the shared-frame work.
- `tools/run-compile-check.ps1 -RequestLedger docs/request-ledgers/2026-07-03-ui-001-story-scene-shared-frame.md` was attempted, but the wrapper stayed blocked by an internal source-map freshness issue after repeated runs, so the underlying gates above were used as substitute proof.

## Resolution Proof

- RED proof: before implementation, `res://tests/run_story_scene_runtime_contract.gd` failed because `StoryFrame`, `TopChrome`, speaker-tag, and shared dialogue-dock nodes did not exist, and the story read-model/content contracts lacked frame metadata.
- Root-cause proof: after introducing `StorySceneFrame`, delegating `StoryScenePage`, and projecting `frame` / `presentation` metadata through the read model and story content tables, the focused runtime contract emitted `STORY_SCENE_RUNTIME_CONTRACT_OK`.
- Workaround guard: the fix preserved existing story flow and signal ownership inside `StoryScenePage` instead of masking the redesign with page-local style overrides or shell-wide routing changes.

## Artifact Ledger

- No separate artifact ledger is planned for this story-screen UI change; proof lives in this request ledger, the refreshed source map, focused Godot runners, and the shared Codex worklog.
