# Request Constraint Ledger

## Request Summary

- Continue from the earlier source-map request-analysis integration pass and clean up the remaining live source-map drift so the repository-wide source-map gate can pass again.

## Preserved Invariants

- `docs/source-map.md` remains the live file-map source of truth for the workspace.
- Existing custom responsibility notes for already-mapped files should be preserved unless a responsibility actually changed.
- Generated artifacts, worklog mirrors, and other existing excluded paths must stay excluded rather than being force-mapped as source.

## Mutable Scope

- `docs/source-map.md`
- `docs/request-ledgers/2026-06-09-source-map-drift-cleanup.md`
- today's worklog files

## Source Map Findings

- `docs/source-map.md`
  - The live map already tracks the formal app, harness, and docs tree, but it is missing newly added formal files and asset groups from the current dirty workspace.
- `app-LTL/resources/charactor/defeat/`
  - The live tree now contains a large defeat-art bundle plus import metadata that is formal runtime asset source, not a generated artifact path.
- `app-LTL/resources/Leviathan/Leviathan_drake.png`
  - A new Leviathan art variant exists on disk but is not yet represented in the source map.
- `app-LTL/src/data/i18n/text-en.json`
  - New formal localization catalogs exist under the app data tree and must be tracked as source.
- `app-LTL/src/scenes/pages/`
  - The formal page scene/controller surface has expanded and the map must catch up with the current runtime page files.
- `app-LTL/tests/`
  - Several new formal runners and contract tests now exist and should be mapped rather than excluded.

## Refactor/Delete Disposition

- Keep the current live files and repair the source map around them instead of deleting source to satisfy the gate.
- Do not relax the source-map gate or add new exclusions for these formal runtime/test files.
- Update only the source map and reporting documents in this pass unless verification reveals a source-map script defect.

## Verification Checklist

- Run `powershell -NoProfile -ExecutionPolicy Bypass -File LTL-harness/tools/request-analysis-gate.ps1 -Ledger docs/request-ledgers/2026-06-09-source-map-drift-cleanup.md -Mode pre-edit`
- Run a focused diagnostic diff between the live tree and `docs/source-map.md` to list missing and stale paths before editing.
- Run `powershell -NoProfile -ExecutionPolicy Bypass -File LTL-harness/tools/source-map-gate.ps1 -Root .`
- Run `git diff --check -- docs/source-map.md docs/request-ledgers/2026-06-09-source-map-drift-cleanup.md docs/codex-worklog/plan_LootingTheLeviathan_2026-06-09.md docs/codex-worklog/history_LootingTheLeviathan_2026-06-09.md docs/codex-worklog/complete_LootingTheLeviathan_2026-06-09.md`
- Run `powershell -NoProfile -ExecutionPolicy Bypass -File LTL-harness/tools/request-analysis-gate.ps1 -Ledger docs/request-ledgers/2026-06-09-source-map-drift-cleanup.md -Mode pre-complete -RequireArtifactLedger`

## Verification Notes

- Passed: `powershell -NoProfile -ExecutionPolicy Bypass -File LTL-harness/tools/request-analysis-gate.ps1 -Ledger docs/request-ledgers/2026-06-09-source-map-drift-cleanup.md -Mode pre-edit` -> `REQUEST_ANALYSIS_GATE_OK`
- Checked: targeted tree counts confirmed the main drift groups were formal source paths under `app-LTL/resources/charactor/defeat`, `app-LTL/resources/Leviathan`, `app-LTL/src/data/i18n`, `app-LTL/src/scenes/pages`, and `app-LTL/tests`, not generated-artifact folders.
- Passed: `powershell -NoProfile -ExecutionPolicy Bypass -File LTL-harness/tools/source-map-gate.ps1 -Root .` -> `SOURCE_MAP_GATE_OK`
- Passed: `git diff --check -- docs/source-map.md docs/request-ledgers/2026-06-09-source-map-drift-cleanup.md docs/codex-worklog/plan_LootingTheLeviathan_2026-06-09.md docs/codex-worklog/history_LootingTheLeviathan_2026-06-09.md docs/codex-worklog/complete_LootingTheLeviathan_2026-06-09.md` -> exit `0` with existing LF/CRLF warnings only
- Passed: `powershell -NoProfile -ExecutionPolicy Bypass -File LTL-harness/tools/request-analysis-gate.ps1 -Ledger docs/request-ledgers/2026-06-09-source-map-drift-cleanup.md -Mode pre-complete -RequireArtifactLedger` -> `REQUEST_ANALYSIS_GATE_OK`

## Artifact Ledger

- Verification notes for this cleanup will be tracked in `docs/artifact-ledgers/2026-06-09-source-map-drift-cleanup.md`.
