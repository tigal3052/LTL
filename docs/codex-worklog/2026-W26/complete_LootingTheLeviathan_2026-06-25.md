# 2026-06-25 Beacon Item Art Wiring

## Agent

- agent: codex
- source: ide

## Goal

- Wire the supplied beacon item PNGs under `app-LTL/resources/items/becon` into existing beacon artifact presentation.

## Context Read

- `docs/agent-worklog/INDEX.md`
- `docs/agent-worklog/COMPACT.md`
- `docs/source-map.md`

## Files Changed

- `app-LTL/src/ui/ItemArtResolver.gd`: added beacon item root, `beacon_*` to `*_becon_*.png` mapping, starter/basic mapping, and rarity fallback candidates.
- `app-LTL/src/ui/presenters/BackpackGridFactory.gd`: exposed beacon and generic item texture lookup APIs.
- `app-LTL/src/ui/ArtifactCodexArtResolver.gd`: included beacon item PNG candidates in codex/reward art fallback chains.
- `app-LTL/src/ui/backpack/BackpackArtifactRenderer.gd`: generalized image-backed artifact rendering from drills to image-backed items while keeping drill compatibility.
- `app-LTL/src/ui/BackpackUI.gd`: made drag ghost texture lookup use the generic item renderer path.
- `app-LTL/tests/test_reward_contract.gd`, `app-LTL/tests/ui_read_models/ui_defeat_visual_suite.gd`, `app-LTL/tests/test_reward_claim_board_contract.gd`: added/updated focused coverage for beacon art paths and image-backed reward placement.
- `docs/source-map.md`: refreshed source-map coverage and fingerprint for new beacon resources and changed source/test files.

## Decisions

- Kept existing reward-table `presentation.icon` keys as `beacon_*` and translated them in the resolver, avoiding data churn.
- Preserved the supplied `becon` folder/file spelling because the assets were delivered under that path.
- Used fallback candidates so rarities without exact supplied art can still resolve the closest same-color beacon image instead of dropping to a generic tile.

## Validation

- `powershell -NoProfile -ExecutionPolicy Bypass -File tools\invoke-godot.ps1 -ProjectPath app-LTL -Headless -Script res://tests/run_test_reward_contract.gd` -> `REWARD_CONTRACT_TESTS_OK`
- `powershell -NoProfile -ExecutionPolicy Bypass -File tools\invoke-godot.ps1 -ProjectPath app-LTL -Headless -Script res://tests/run_backpack_ui_compile_contract.gd` -> `BACKPACK_UI_COMPILE_CONTRACT_OK`
- `powershell -NoProfile -ExecutionPolicy Bypass -File tools\invoke-godot.ps1 -ProjectPath app-LTL -Headless -Script res://tests/run_reward_claim_board_contract.gd` -> `REWARD_CLAIM_BOARD_CONTRACT_OK`
- `powershell -NoProfile -ExecutionPolicy Bypass -File LTL-harness\tools\source-map-gate.ps1 -Root . -Refresh` -> `SOURCE_MAP_GATE_OK`

## Failures / Root Cause

- `run_test_ui_read_models.gd` still reports `main scene serializes the VFXManager particle_template wiring to the shared ParticleTemplate node`; this is outside the beacon image scope and remained after beacon-specific checks stopped failing.

## Follow-ups

- None for beacon wiring.

## Compact Summary

- Beacon art now resolves from existing `beacon_*` keys to `app-LTL/resources/items/becon/*_becon_*.png`.
- Backpack rendering and drag ghosts now support beacon item images as well as drill images.
- Codex/reward descriptors include beacon PNGs in their fallback chain.
- Focused reward, backpack compile, reward-claim, and source-map checks passed; full UI read-model suite remains blocked by unrelated VFXManager wiring.

# 2026-06-25 Relay Beacon Common 1x1 Update

## Agent

- agent: codex
- source: ide

## Goal

- Change `"진홍 스파크 릴레이"` and `"보랏빛 베일 릴레이"` beacons into common 1x1 grid items.

## Files Changed

- `app-LTL/src/data/reward-table.json`: changed the two named beacon rewards to `rarity: "common"`, `payload.shape: [[1]]`, common-facing tags/badges/descriptions, and moved them into common source-order positions.
- `app-LTL/tests/test_reward_contract.gd`: added focused contract coverage for the two Korean reward names and updated only the rarity/type/color count expectations affected by the requested grade change.
- `docs/codex-worklog/plan_LootingTheLeviathan_2026-06-25.md`: rescoped the active plan to this reward data update.

## Validation

- RED: `run_test_reward_contract.gd` initially failed because both named beacons were still rare and multi-cell.
- GREEN: `powershell -NoProfile -ExecutionPolicy Bypass -File tools/invoke-godot.ps1 -ProjectPath app-LTL -Headless -Script res://tests/run_test_reward_contract.gd` -> `REWARD_CONTRACT_TESTS_OK`
- `powershell -NoProfile -ExecutionPolicy Bypass -File LTL-harness/tools/source-map-gate.ps1 -Root .` -> `SOURCE_MAP_GATE_OK`

## Notes

- Stable reward ids were left unchanged to avoid breaking existing discovery/save references.
- No unrelated reward weights, stats, run flow, or UI code were changed for this request.
