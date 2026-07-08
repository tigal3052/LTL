# 2026-06-29 CORE-001 onboarding story-scene baseline closeout

## Agent

- agent: hermes
- source: tui

## Goal

- Close CORE-001 by recording the new onboarding owner, the gate results, and the final completion decision.

## Context Read

- `docs/agent-worklog/INDEX.md`
- `docs/agent-worklog/COMPACT.md`
- `docs/project-goals/work-objectives.html`
- `docs/request-ledgers/2026-06-29-core-001-onboarding-story-scene-baseline.md`
- `app-LTL/tests/run_main_layout_audit_contract.gd`
- `tools/project-objectives.ps1`
- `tools/agent-worklog.ps1`

## Files Changed

- `app-LTL/src/data/story-scenes.json`: moved `intro_contract_vn` to `before_character_select` and returned to `character_select`.
- `app-LTL/src/data/narrative-beats.json`: removed first-run intro ownership from node-select narrative flow.
- `app-LTL/src/vocabulary/story/SelectStoryScene.gd`: selected the intro scene before `character_select`.
- `app-LTL/src/controllers/MainControllerBootstrapFlow.gd`: opened the intro story-scene during startup before `character_select`.
- `app-LTL/src/controllers/MainControllerRunFlow.gd`: aligned reset/continue routing with `story_scene -> character_select -> leviathan_select`.
- `app-LTL/tests/run_main_start_flow_contract.gd`, `run_node_select_start_gate_contract.gd`, `run_m8_vertical_slice_contract.gd`, `run_reward_handoff_contract.gd`, `run_vertical_slice_flow_contract.gd`, `test_story_scene_contract.gd`, `test_narrative_contract.gd`: aligned acceptance coverage to the single onboarding owner.
- `app-LTL/tests/run_main_layout_audit_contract.gd`: advanced the intro story before asserting character-select layout so the compile/page gate matches the new baseline.
- `docs/request-ledgers/2026-06-29-core-001-onboarding-story-scene-baseline.md`: recorded request-analysis, transition-safety, page-contract, and compile-check proof.
- `docs/project-goals/work-objectives.html`: closeout status/proof for `CORE-001`.
- `docs/agent-worklog/2026-06-29-hermes-core-001-onboarding-story-scene-baseline-closeout.md`: this closeout log.

## Decisions

- Make `story_scene` the single intro onboarding owner and return to `character_select` after the scene completes.
- Keep node-select, reward, and vertical-slice flows under the same downstream owners; only the intro entry point moved.
- Treat the stale layout-audit startup assumption as a test-only regression and fix it minimally instead of changing runtime behavior.
- Use a current CORE-001 request ledger for compile-check evidence instead of the unrelated 2026-06-02 harness ledger.

## Validation

- `powershell -NoProfile -ExecutionPolicy Bypass -File LTL-harness/tools/source-map-gate.ps1 -Root . -Refresh` -> `SOURCE_MAP_REFRESH_OK`, `SOURCE_MAP_GATE_OK`.
- `powershell -NoProfile -ExecutionPolicy Bypass -File LTL-harness/tools/source-map-gate.ps1 -Root .` -> `SOURCE_MAP_GATE_OK`.
- `powershell -NoProfile -ExecutionPolicy Bypass -File LTL-harness/tools/request-analysis-gate.ps1 -Ledger docs/request-ledgers/2026-06-29-core-001-onboarding-story-scene-baseline.md -Mode pre-complete` -> `REQUEST_ANALYSIS_GATE_OK`.
- `powershell -NoProfile -ExecutionPolicy Bypass -File LTL-harness/tools/transition-safety-gate.ps1 -Root . -Ledger docs/request-ledgers/2026-06-29-core-001-onboarding-story-scene-baseline.md` -> `TRANSITION_SAFETY_GATE_OK`.
- `powershell -NoProfile -ExecutionPolicy Bypass -File LTL-harness/tools/page-contract-gate.ps1 -Root . -GodotPath D:/Programming/godot_workspace/bin/Godot_v4.3-stable_win64_console.exe` -> `PAGE_CONTRACT_GATE_OK`.
- `powershell -NoProfile -ExecutionPolicy Bypass -File tools/run-compile-check.ps1 -RequestLedger docs/request-ledgers/2026-06-29-core-001-onboarding-story-scene-baseline.md` -> `Compilation Check: PASSED (GODOT_CONTRACTS_OK)`.
- Acceptance runners stayed green and emitted `story_scene_started` telemetry with `return_page_id` set to `character_select`.

## Failures / Root Cause

- The first compile-check failure was not a gameplay failure; it came from the default 2026-06-02 request ledger missing required request-analysis sections.
- After switching to a current CORE-001 ledger, the remaining gate failure came from `run_main_layout_audit_contract.gd` still assuming the app starts on `character_select`; the runtime now correctly starts on `story_scene` first.
- Fix: add the intro-story advance step inside the layout-audit helper, then rerun source-map/page-contract/compile gates.

## Follow-ups

- Watch the known Godot shutdown RID/ObjectDB/resource leak warnings separately; they did not block this closeout.
- If another onboarding change moves the intro entry point again, update the request ledger and layout-audit helper together.

## Compact Summary

- CORE-001 now uses a single onboarding owner: first-run startup/reset enters `story_scene`, then returns to `character_select`, then proceeds to `leviathan_select` and node-select.
- Acceptance coverage and the compile/page gates were realigned to that owner, including a minimal fix to `run_main_layout_audit_contract.gd` so layout tests advance the intro before measuring `character_select`.
- Source-map refresh/validate, request-analysis, transition-safety, page-contract, and compile-check all passed with the new CORE-001 request ledger.
- `CORE-001` is ready to mark complete; remaining Godot shutdown leak warnings are known non-blocking noise for this closeout.
