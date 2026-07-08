# Request Constraint Ledger

## Request Summary

- Convert the reward ceremony to reward-board crash diagnosis into a blocking harness recurrence-prevention policy.
- Add a dedicated transition-safety gate that forces transition review and runnable handoff proof instead of relying on exit-code-only success.
- Add a focused reward-handoff proof so reward ceremony completion to tray review is covered as its own boundary.

## Preserved Invariants

- Reward ceremony sequencing remains `count_tease`, `count_lock`, `reveal_queue`, `tray_review`.
- Existing page-contract, source-map, i18n, and test-size gates remain blocking in their current ownership areas.
- Transition safety stays separate from the architectural gate instead of being merged into it.
- Compile and quality orchestration remain under `tools/run-compile-check.ps1` and `tools/run-ltl-quality-gate.ps1`.

## Mutable Scope

- `LTL-harness/tools/request-analysis-gate.ps1`
- `LTL-harness/tools/request-analysis-gate.tests.ps1`
- `LTL-harness/tools/transition-safety-gate.ps1`
- `LTL-harness/tools/transition-safety-gate.tests.ps1`
- `LTL-harness/docs/request-analysis-execution-gate.md`
- `LTL-harness/docs/templates/request-constraint-ledger-template.md`
- `LTL-harness/docs/transition-safety-gate.md`
- `LTL-harness/README.md`
- `LTL-harness/00_AGENTS.md`
- `tools/run-compile-check.ps1`
- `tools/run-ltl-quality-gate.ps1`
- `app-LTL/tests/run_main_start_flow_contract.gd`
- `app-LTL/tests/run_reward_handoff_contract.gd`
- `docs/request-ledgers/2026-06-02-refactor-harness-quality-gate.md`
- `docs/source-map.md`
- today's worklog files and this ledger

## Source Map Findings

- `LTL-harness/tools/request-analysis-gate.ps1`
  - request-ledger validation is already the SoT for broad harness completion structure, so transition review belongs in the same surface.
- `LTL-harness/docs/request-analysis-execution-gate.md`
  - the request-analysis workflow defines required stages and is the right place to formalize transition review as a mandatory planning step.
- `LTL-harness/tools/page-contract-gate.ps1`
  - current page proof orchestration already enforces a marker for `PAGE_SCENE_MAPPING_CONTRACT_OK`, which makes it the closest existing pattern for transition marker enforcement.
- `tools/run-compile-check.ps1`
  - compile verification already blocks on source map, test size, and page-contract coverage, so it is the correct place to insert transition safety before compile smoke.
- `tools/run-ltl-quality-gate.ps1`
  - repository-wide harness verification already aggregates request-analysis, gate self-tests, page contracts, and Godot contracts, so it should aggregate transition safety too.
- `app-LTL/tests/run_main_start_flow_contract.gd`
  - the start-flow runner already covers real flow movement through battle and reward entry, but the current gate path does not require its success marker explicitly.
- `app-LTL/tests/run_reward_ceremony_contract.gd`
  - ceremony-only proof exists, which confirms the remaining gap is the handoff into tray review rather than reward reveal sequencing itself.

## Transition Safety Review

- touched transition ids: `meta.start_flow`, `page.scene_mapping`, `reward.ceremony`, `reward.handoff`
- entry owner: `app-LTL/src/MainControllerRuntime.gd`
- exit owner: `app-LTL/src/ui/MainViewRuntime.gd`
- shared handoff risks:
  - reward presentation step changes from ceremony-active steps into `tray_review`
  - shared backpack reparenting into the reward workspace host
  - reward-board layout sync running at the same time as page visibility changes
  - false-green verification when a runner exits `0` without emitting the expected marker
- required runners:
  - `app-LTL/tests/run_main_start_flow_contract.gd` -> `MAIN_START_FLOW_CONTRACT_OK`
  - `app-LTL/tests/run_page_scene_mapping_contract.gd` -> `PAGE_SCENE_MAPPING_CONTRACT_OK`
  - `app-LTL/tests/run_reward_ceremony_contract.gd` -> `REWARD_CEREMONY_CONTRACT_OK`
  - `app-LTL/tests/run_reward_handoff_contract.gd` -> `REWARD_HANDOFF_CONTRACT_OK`

## Refactor/Delete Disposition

- Keep existing request-analysis and page-contract scripts; extend them instead of replacing them.
- Add a dedicated transition-safety gate rather than folding transition proof into the architectural gate.
- Keep existing transition-relevant runners and normalize them to marker-required usage when they are registered.
- Do not delete reward-board proof coverage; add a smaller reward-handoff runner instead of overloading the broad reward-board contract runner further.

## Verification Checklist

- Run `powershell -NoProfile -ExecutionPolicy Bypass -File LTL-harness/tools/request-analysis-gate.ps1 -Ledger docs/request-ledgers/2026-06-09-transition-safety-gate.md -Mode pre-edit`
- Run `powershell -NoProfile -ExecutionPolicy Bypass -File LTL-harness/tools/request-analysis-gate.tests.ps1`
- Run `powershell -NoProfile -ExecutionPolicy Bypass -File LTL-harness/tools/transition-safety-gate.tests.ps1`
- Run `powershell -NoProfile -ExecutionPolicy Bypass -File tools/invoke-godot.ps1 -WorkspaceRoot . -ProjectPath app-LTL -GodotPath D:\Programming\godot_workspace\bin\Godot_v4.3-stable_win64_console.exe -Script tests/run_reward_handoff_contract.gd -Headless -Quit`
- Run `powershell -NoProfile -ExecutionPolicy Bypass -File LTL-harness/tools/transition-safety-gate.ps1 -Root . -GodotPath D:\Programming\godot_workspace\bin\Godot_v4.3-stable_win64_console.exe -Ledger docs/request-ledgers/2026-06-09-transition-safety-gate.md`
- Run `powershell -NoProfile -ExecutionPolicy Bypass -File tools/run-compile-check.ps1`
- Run `powershell -NoProfile -ExecutionPolicy Bypass -File tools/run-ltl-quality-gate.ps1 -RequestLedger docs/request-ledgers/2026-06-09-transition-safety-gate.md -ArtifactLedger docs/artifact-ledgers/2026-06-09-transition-safety-gate.md`

## Verification Notes

- `2026-06-09`: `powershell -NoProfile -ExecutionPolicy Bypass -File LTL-harness/tools/request-analysis-gate.ps1 -Ledger docs/request-ledgers/2026-06-09-transition-safety-gate.md -Mode pre-complete -RequireArtifactLedger` -> `REQUEST_ANALYSIS_GATE_OK`
- `2026-06-09`: `powershell -NoProfile -ExecutionPolicy Bypass -File LTL-harness/tools/transition-safety-gate.ps1 -Ledger docs/request-ledgers/2026-06-09-transition-safety-gate.md` -> `TRANSITION_SAFETY_GATE_OK`
- `2026-06-09`: `powershell -NoProfile -ExecutionPolicy Bypass -File tools/invoke-godot.ps1 -Headless -Script tests/run_reward_handoff_contract.gd` -> `REWARD_HANDOFF_CONTRACT_OK`
- `2026-06-09`: `powershell -NoProfile -ExecutionPolicy Bypass -File tools/run-compile-check.ps1` -> passed, including blocking transition-safety gate
- `2026-06-09`: `powershell -NoProfile -ExecutionPolicy Bypass -File tools/run-ltl-quality-gate.ps1 -RequestLedger docs/request-ledgers/2026-06-09-transition-safety-gate.md -ArtifactLedger docs/artifact-ledgers/2026-06-09-transition-safety-gate.md` -> blocked by pre-existing `architectural-gate.ps1` failure on `app-LTL/src/ui/StatusPanelUI.gd` forbidden `PanelContainer.new`

## Artifact Ledger

- Generated verification output for this change set will be recorded in `docs/artifact-ledgers/2026-06-09-transition-safety-gate.md`.
