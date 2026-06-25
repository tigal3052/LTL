# 2026-06-23 Interaction Sound

## Request Summary

- Add sounds for currently silent interactions: combat hits, button clicks, screen movement, and menu movement.
- Use cross-role review from director, sound designer, QA, and UI designer perspectives.
- Keep most effects natural and restrained.
- Reserve thunder-like impact for combat hit sounds only.
- Continue the work with an explicit SFX target list and web-reference-backed implementation method.
- Improve combat hits by mixing in a lower-register impact layer.

## Preserved Invariants

- Existing gameplay rules, combat math, reward state, inventory state, and page routing must not change.
- Existing UI layout, page ownership, visual interaction FX, and menu behavior must stay intact.
- Existing dirty worktree changes outside the sound integration path must not be reverted.
- Non-combat UI sounds must stay subtle and must not become loud or fatiguing.
- Essential gameplay or UI information must not be conveyed by sound alone; the existing visual/read-model feedback remains authoritative.

## Mutable Scope

- `app-LTL/src/ui/InteractionFX.gd`
- `app-LTL/src/ui/MainViewRuntime.gd`
- `app-LTL/src/ui/main_view/MainViewRuntimeState.gd`
- `app-LTL/src/ui/main_view/MainViewChromeRuntime.gd`
- `app-LTL/src/ui/main_view/MainViewPageShellRuntime.gd`
- `app-LTL/src/ui/main_view/MainViewPanelsRuntime.gd`
- `app-LTL/src/ui/main_view/MainViewFeedbackRuntime.gd`
- `app-LTL/src/ui/main_view/MainViewRewardRuntime.gd`
- `app-LTL/src/ui/main_view/MainViewBackpackRuntime.gd`
- `app-LTL/src/controllers/MainControllerCombatFlow.gd`
- `app-LTL/src/ui/presenters/InteractionSfxSynth.gd`
- `app-LTL/tests/support/UiReadModelTestSuite.gd`
- `app-LTL/tests/ui_read_models/ui_interaction_feedback_accessibility_suite.gd`
- `docs/interaction-sound-application-plan.md`
- `docs/source-map.md`
- Worklog files under `docs/codex-worklog/`

## Source Map Findings

- `app-LTL/src/ui/InteractionFX.gd` owns shared hover, click, ripple, cursor, disabled, and drag/drop feedback on interactive controls.
- `app-LTL/src/ui/main_view/MainViewChromeRuntime.gd` owns interaction FX install, shell chrome updates, timer/reward overlays, and tooltips.
- `app-LTL/src/controllers/MainControllerRewardBackpackFlow.gd` owns reward tray and backpack interaction flow, but this task should not change reward logic.
- `app-LTL/src/ui/BackpackUI.gd` owns backpack slot click/hover signals and drag/drop visuals, but this task should avoid gameplay or placement changes.
- The source map has no existing `sound` match in `app-LTL/src`, so the sound route needs either a new mapped file or a small extension to existing chrome/view owners.
- `MainViewRewardRuntime.gd` and `MainViewBackpackRuntime.gd` own drag pickup/release boundaries where semantic pickup/drop/cancel sounds can be added without changing reward or inventory logic.

## Root Cause Review

- Observed symptom: core interactions are visually responsive but largely silent; the settings panel has a sound slider, yet only the heartbeat path has an obvious audio player.
- Evidence: `MainViewChromeRuntime.set_volume` forwards volume only to `GiantTimerUI`; `InteractionFX.gd` handles press/hover visual feedback without an audio callback; `Main.tscn` has no general SFX player nodes.
- Root cause target: `app-LTL/src/ui/main_view/MainViewChromeRuntime.gd`
- Rejected workaround: adding one-off `AudioStreamPlayer` nodes to individual buttons/pages or playing loud hover sounds on every pointer movement.
- Chosen fix: add a single view-level interaction SFX route, let existing interaction/page/menu/combat boundaries request stable sound categories, and keep generated UI sounds restrained while combat hits use the heavier existing hit assets.
- Extended fix: keep existing hit WAVs as the attack layer and add a low-pitch body layer under combat hit categories through the same reusable player pool.

## Transition Safety Review

- no transition impact
- Page activation will gain a sound side effect only after the existing page id is resolved; it will not change page id calculation, handoff order, or scene model payloads.
- Confirmation overlays and reward/backpack drag release boundaries may gain sound side effects only after the existing visible/drop/cancel decision is known.

## Feature Unit Lifecycle Plan

- Design stage: `InteractionFX` owns generic control press detection, `MainViewChromeRuntime` owns view-level audio playback, `MainViewPageShellRuntime` owns page-change cue calls, and `MainControllerCombatFlow` owns combat hit cue calls.
- Design stage extension: the SFX event inventory is documented in `docs/interaction-sound-application-plan.md`, with web-reference implementation principles and per-event routing notes.
- Implementation stage: add focused tests for category mapping, volume, event inventory, and low-hit layering first, then add minimal playback routing without changing existing signal names or domain state.
- Maintenance stage: new SFX helper remains stateless and listed in `docs/source-map.md`; future sound categories should be added through stable category names rather than ad hoc player nodes.
- Capsule boundary: view-facing API is `play_interaction_sfx(category)`, with no domain or controller needing to know about assets or synthesis.
- Size trigger: if `MainViewChromeRuntime.gd` grows beyond small routing helpers, move playback construction into a dedicated runtime leaf helper.

## Runtime Performance Review

- Hot path: `app-LTL/src/ui/InteractionFX.gd` recursively scans interactive controls during `install_tree` and may run after rerenders.
- Hot path: `app-LTL/src/ui/MainViewRuntime.gd` exposes the facade API that controller and page helpers call during active runtime interaction.
- Hot path: `app-LTL/src/ui/main_view/MainViewChromeRuntime.gd` processes per-frame chrome and will own reusable SFX players.
- Hot path: `app-LTL/src/ui/main_view/MainViewPageShellRuntime.gd` renders page scenes and must only play transition audio when page id changes.
- Hot path: `app-LTL/src/controllers/MainControllerCombatFlow.gd` handles repeated combat shots and hold-fire loops.
- Hot path: reward/backpack drag release runs on pointer release and must not allocate per-motion sound players.
- Risk: repeated hover sounds or player allocation during rapid input would create audio spam or frame churn.
- Performance proof: `app-LTL/tests/run_test_ui_read_models.gd`
- Budget: no per-frame audio traversal; no sound on mouse motion; page cue only when page id changes; combat hit layers reuse existing players; drag sounds fire only on pickup/release outcomes.

## Execution Responsibility Units

- Owner: `app-LTL/src/ui/presenters/InteractionSfxSynth.gd`
  - Unit: generated subtle UI/menu/page tone streams.
  - Focused proof: `ui_interaction_feedback_accessibility_suite.gd`
- Owner: `app-LTL/src/ui/main_view/MainViewChromeRuntime.gd`
  - Unit: SFX player creation, volume application, category-to-stream routing, layered hit playback, and facade API.
  - Focused proof: `ui_interaction_feedback_accessibility_suite.gd`
- Owner: `app-LTL/src/ui/InteractionFX.gd`
  - Unit: generic control press callback invocation while preserving existing visual FX behavior.
  - Focused proof: `ui_interaction_feedback_accessibility_suite.gd`
- Owner: `app-LTL/src/controllers/MainControllerCombatFlow.gd`
  - Unit: combat-hit SFX trigger next to existing beam/particle/screen-shake feedback.
  - Focused proof: `run_test_ui_read_models.gd` compile coverage plus manual runtime audio gap noted if not listened to.
- Owner: `app-LTL/src/ui/main_view/MainViewRewardRuntime.gd`
  - Unit: reward-card drag pickup semantic SFX.
  - Focused proof: `ui_interaction_feedback_accessibility_suite.gd`
- Owner: `app-LTL/src/ui/main_view/MainViewLifecycleRuntime.gd`
  - Unit: confirmation/settings overlay menu-open/menu-close SFX.
  - Focused proof: `ui_interaction_feedback_accessibility_suite.gd`
- Owner: `docs/interaction-sound-application-plan.md`
  - Unit: professional SFX target list and web-reference implementation plan.
  - Focused proof: source-map gate plus final audit.

## Refactor/Delete Disposition

- No runtime scene is deleted or replaced.
- No prototype files are edited.
- Existing WAV assets are reused; new subtle UI tones are synthesized in code to avoid import churn unless verification shows a file asset is required.
- Combat low-frequency improvement reuses existing hit WAVs at lower pitch/gain instead of importing external assets.

## Verification Checklist

- Run `powershell -NoProfile -ExecutionPolicy Bypass -File tools/invoke-godot.ps1 -ProjectPath app-LTL -Headless -Script res://tests/run_test_ui_read_models.gd -Quit`.
- Run `powershell -NoProfile -ExecutionPolicy Bypass -File tools/invoke-godot.ps1 -ProjectPath app-LTL -Headless -Script res://tests/godot_contract_runner.gd -Quit`.
- Run `powershell -NoProfile -ExecutionPolicy Bypass -File tools/run-compile-check.ps1 -RequestLedger docs/request-ledgers/2026-06-23-interaction-sound.md` if the broader dirty worktree allows it.
- Run `powershell -NoProfile -ExecutionPolicy Bypass -File LTL-harness/tools/source-map-gate.ps1 -Root .`.
- Run `powershell -NoProfile -ExecutionPolicy Bypass -File LTL-harness/tools/request-analysis-gate.ps1 -Ledger docs/request-ledgers/2026-06-23-interaction-sound.md -Mode pre-complete`.
- Run `git diff --check`.

## Verification Notes

- Pre-edit gate passed: `REQUEST_ANALYSIS_GATE_OK`.
- RED proof: `tools/invoke-godot.ps1 -ProjectPath app-LTL -Headless -Script res://tests/run_test_ui_read_models.gd -LogName ui-sfx-red.log -Quit` failed after the syntax correction with missing semantic SFX descriptor/player route assertions: `chrome runtime exposes semantic SFX descriptors` and `chrome runtime creates reusable interaction SFX players`.
- GREEN proof: `tools/invoke-godot.ps1 -ProjectPath app-LTL -Headless -Script res://tests/run_test_ui_read_models.gd -LogName ui-sfx-green.log -Quit` printed `UI_READ_MODEL_TESTS_OK`.
- Broader Godot proof: `tools/invoke-godot.ps1 -ProjectPath app-LTL -Headless -Script res://tests/godot_contract_runner.gd -LogName godot-contracts-sfx.log -Quit` printed `GODOT_CONTRACTS_OK`.
- Source-map proof: `LTL-harness/tools/source-map-gate.ps1 -Root D:\Programming\ex_workspace\LootingTheLeviathan` printed `SOURCE_MAP_GATE_OK` after mapping the new sound helper, request ledger, and real untracked files already present in the workspace.
- Diff hygiene: `git diff --check` exited 0, with line-ending normalization warnings only.
- Broad gate caveat: `tools/run-compile-check.ps1 -RequestLedger docs/request-ledgers/2026-06-23-interaction-sound.md` passed source-map and request-analysis, then failed in `LTL-harness/tools/test-size-gate.ps1` because `app-LTL/tests/ui_read_models/ui_text_tooltip_suite.gd` is 329 lines over the 320-line cap. That file was already dirty and outside this sound task; the sound-edited `ui_interaction_feedback_accessibility_suite.gd` is 195 lines.
- Web-reference implementation pass: `docs/interaction-sound-application-plan.md` records the SFX event inventory, Godot implementation method, accessibility guidance, and low-frequency hit-layer rationale.
- RED proof for the extended pass: `tools/invoke-godot.ps1 -ProjectPath app-LTL -Headless -Script res://tests/run_interaction_sfx_contract.gd -LogName interaction-sfx-red-clean.log -Quit` failed on missing `drag_start`/`drag_drop`/`drag_cancel` descriptors plus missing `sfx_event_inventory` and layered descriptor APIs.
- GREEN proof for the extended pass: `tools/invoke-godot.ps1 -ProjectPath app-LTL -Headless -Script res://tests/run_interaction_sfx_contract.gd -LogName interaction-sfx-green.log -Quit` printed `INTERACTION_SFX_CONTRACT_OK`.
- Current broader Godot caveat: `tools/invoke-godot.ps1 -ProjectPath app-LTL -Headless -Script res://tests/godot_contract_runner.gd -LogName godot-contracts-sfx-low-layer.log -Quit` and `run_test_ui_read_models.gd -LogName ui-read-models-current-state.log` fail on the pre-existing dirty `app-LTL/src/Main.tscn` removal of `particle_template = NodePath("../ParticleTemplate")`, outside this sound task.
- Current compile-check caveat: before this ledger update, `tools/run-compile-check.ps1 -RequestLedger docs/request-ledgers/2026-06-23-interaction-sound.md` stopped at request-analysis because this Resolution Proof still contained a pending note; rerun after this update is required for the current blocker.

## Resolution Proof

- RED proof: the focused UI read-model suite failed before the first production implementation because semantic SFX descriptors and reusable interaction SFX players were absent.
- RED proof: the dedicated interaction SFX contract failed before the low-layer/catalog implementation because drag descriptors, the event inventory API, and layered hit descriptors were absent.
- Root-cause proof: the dedicated SFX suite now passes with `INTERACTION_SFX_CONTRACT_OK`, proving the planned category inventory, combat-only thunder descriptors, low-pitch combat body layers, shared volume behavior, and page-change gate.
- Workaround guard: the implementation does not add one-off per-button players or play hover sounds; it routes button, menu, page, drag, and combat categories through a single view-level SFX path.
- Low-hit guard: focused tests assert `combat_hit` and `combat_strong_hit` expose a `low_body` layer with pitch below `0.8`, gain at or below `-12 dB`, and a combat thunder-family tone.
- Broader-suite blocker: current broad Godot/UI runners are blocked by unrelated dirty `Main.tscn` particle template wiring, not by the interaction SFX code path.

## Artifact Ledger

- No generated artifact ledger is planned for this narrow sound integration.
