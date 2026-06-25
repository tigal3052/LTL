# 2026-06-25 Hermes Large GDScript/Test Reduction

## Agent
Hermes Agent

## Goal
Reduce oversized active GDScript owners and strict UI/test suites while preserving existing runtime/test entry points.

## Context Read
- `docs/agent-worklog/INDEX.md`
- `docs/architectural-gates/runtime-size-gate.md`
- `LTL-harness/tools/test-size-gate.ps1`
- Focused source/test files listed in the request ledger.

## Files Changed
- Source compaction/extraction: `MainController.gd`, `MainControllerRunFlow.gd`, `CharacterSelectPage.gd`, `RewardRevealOverlay.gd`, `MainControllerRewardBackpackFlow.gd`, `InteractionSfxSynth.gd`.
- New source helpers: `src/controllers/run_flow/*`, `src/ui/audio/InteractionSfxProfile.gd`.
- Test suite split: `test_combat_vocab.gd`, `tests/combat_vocab/*`, `ui_backpack_layout_suite.gd`, `ui_read_models/backpack_layout/*`, `ui_text_tooltip_suite.gd`, `ui_read_models/text_tooltip/*`.
- Docs/gates: `docs/source-map.md`, `docs/request-ledgers/2026-06-25-large-gd-test-reduction.md`.

## Decisions
- Kept public production/test entry paths as wrappers and moved only pure helper/test bodies behind them.
- Did not raise runtime/test size caps.
- Left legacy oversized top-level tests as `TEST_SIZE_GATE_WARN` surfaces for later focused splits.

## Validation
- `SOURCE_MAP_GATE_OK`
- `REQUEST_ANALYSIS_GATE_OK`
- `RUNTIME_SIZE_GATE_OK`
- `TEST_SIZE_GATE_OK` with legacy top-level warnings only
- `COMBAT_VOCAB_TESTS_OK`
- `HERMES_UI_SPLIT_SMOKE_OK`
- `run_main_start_flow_contract.gd` exited 0
- `ARCHITECTURAL_GATE_OK`
- `LTL_TECH_STACK_GATE_OK`

## Failures / Root Cause
- Full `run_test_ui_read_models.gd` and compile-check page-contract still fail on existing `VFXManager particle_template` serialization assertion from dirty `Main.tscn`, not on the new split suites.
- Default `tools/run-compile-check.ps1` ledger is stale and lacks `Root Cause Review`; the new request ledger passes request-analysis.

## Follow-ups
- Split remaining warned legacy top-level tests when their surfaces are touched: `test_reward_contract.gd`, `test_reward_claim_board_contract.gd`, `run_main_layout_audit_contract.gd`, `godot_contract_runner.gd`, and smaller 320+ warnings.
- Fix the unrelated `VFXManager particle_template` page-contract blocker separately.

## Compact Summary
- All active `app-LTL/src/**/*.gd` files are now at or under runtime-size caps; `InteractionSfxSynth.gd` was reduced by extracting `InteractionSfxProfile.gd`.
- `MainControllerRunFlow.gd` is now a 263-line facade over focused run-flow helpers.
- `test_combat_vocab.gd`, `ui_backpack_layout_suite.gd`, and `ui_text_tooltip_suite.gd` are wrappers over focused suite files.
- Strict gates pass (`source-map`, `request-analysis`, `runtime-size`, `test-size`); broad page contract remains blocked by an unrelated existing VFXManager scene wiring assertion.
