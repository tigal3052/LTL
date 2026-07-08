# Request Constraint Ledger

## Request Summary

- Find the root cause of the recurring character-select page overflow beyond the game window, fix the runtime layout, and harden the harness guidance so viewport containment regressions fail before completion.

## Preserved Invariants

- The approved `character_select -> leviathan_select -> node_select -> battle/reward` flow remains unchanged.
- The run-start mockup structure stays image-first with left selector, center hero stage, and right prep/CTA columns.
- Existing combat, reward, and page-contract verification remains in the blocking pipeline.

## Mutable Scope

- `app-LTL/src/scenes/pages/CharacterSelectPage.tscn`
- `app-LTL/src/scenes/pages/CharacterSelectPage.gd`
- `app-LTL/tests/run_main_layout_audit_contract.gd`
- `LTL-harness/docs/page-contract-execution-gate.md`
- `LTL-harness/00_AGENTS.md`
- `LTL-harness/tools/page-contract-gate.ps1`
- today's worklog files and this request ledger

## Source Map Findings

- `docs/source-map.md`
  - The live map identifies the character-select scene/controller, the page-contract gate, and the layout audit runner as the formal surfaces tied to this overflow fix.
- `app-LTL/src/scenes/pages/CharacterSelectPage.tscn`
  - The scene file is mapped as the runtime page shell that owns the live character-select layout.
- `app-LTL/src/scenes/pages/CharacterSelectPage.gd`
  - The page controller is mapped as the formal logic entrypoint for that layout surface.
- `app-LTL/tests/run_main_layout_audit_contract.gd`
  - The layout audit runner is a mapped verification path for viewport containment evidence.

## Refactor/Delete Disposition

- Keep the current character-select scene owner and repair its layout policy instead of replacing the page with a different screen shell.
- Extend the existing page-layout audit and page-contract gate rather than introducing a parallel one-off checker.
- Do not relax existing gameplay layout assertions to make the new page pass.

## Verification Checklist

- Run `powershell -NoProfile -ExecutionPolicy Bypass -File LTL-harness/tools/request-analysis-gate.ps1 -Ledger docs/request-ledgers/2026-06-07-character-select-layout-containment.md -Mode pre-edit`
- Run `powershell -NoProfile -ExecutionPolicy Bypass -File tools/invoke-godot.ps1 -WorkspaceRoot D:\Programming\ex_workspace\LootingTheLeviathan -ProjectPath app-LTL -Script tests/run_main_layout_audit_contract.gd -Headless -Quit`
- Run `powershell -NoProfile -ExecutionPolicy Bypass -File LTL-harness/tools/page-contract-gate.ps1 -Root D:\Programming\ex_workspace\LootingTheLeviathan`
- Run `powershell -NoProfile -ExecutionPolicy Bypass -File tools/run-compile-check.ps1`
- Run `powershell -NoProfile -ExecutionPolicy Bypass -File LTL-harness/tools/request-analysis-gate.ps1 -Ledger docs/request-ledgers/2026-06-07-character-select-layout-containment.md -Mode pre-complete -RequireArtifactLedger`

## Verification Notes

- Root cause confirmed: the rebuilt `character_select` page was a full-screen mockup shell that still lived inside the reduced gameplay host before the meta-page host split, and its stacked minimum heights could exceed the live host without an explicit scroll/compaction contract.
- Harness blind spot confirmed: earlier page-contract checks proved scene existence and page flow, but did not prove `page -> owning host -> viewport` containment or correct meta-vs-gameplay host ownership.
- Verification completed:
  - `tools/invoke-godot.ps1 ... tests/run_main_layout_audit_contract.gd -Headless -Quit` -> exit `0`
  - `LTL-harness/tools/page-contract-gate.tests.ps1` -> `PAGE_CONTRACT_GATE_TESTS_OK`
  - `LTL-harness/tools/page-contract-gate.ps1 -Root D:\Programming\ex_workspace\LootingTheLeviathan` -> `PAGE_CONTRACT_GATE_OK`
  - `tools/run-compile-check.ps1` -> `SOURCE_MAP_GATE_OK`, `PAGE_CONTRACT_GATE_OK`, `GODOT_CONTRACTS_OK`, `Compilation Check: PASSED (GODOT_CONTRACTS_OK)`
- Required harness backups were created under `docs/comment-gates/backups/2026-06-07/ltl-harness/`.

## Artifact Ledger

- Verification artifacts for this pass are tracked in `docs/artifact-ledgers/2026-06-07-character-select-layout-containment.md`.
