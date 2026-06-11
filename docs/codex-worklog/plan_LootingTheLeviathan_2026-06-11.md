# Codex Worklog Plan

Workspace: LootingTheLeviathan
Date: 2026-06-11

## Active Work

- Review M6 completion evidence, repair the false-green page-contract gate, restore source-map gate health, commit the minimal gate fix, then continue with active-runtime separation surgery and harness hardening.

## Request Summary

- Audit whether M6 is actually complete.
- Produce the current manual verification checklist.
- Fix the immediate harness/source-map issues and create a checkpoint commit.
- After the checkpoint, perform the larger runtime/legacy separation pass and strengthen harness enforcement so oversized active-runtime files stop regressing.

## Scope

- `docs/source-map.md`
- `LTL-harness/tools/page-contract-gate.ps1`
- request ledger and worklog updates for this task
- active-runtime refactor files that are touched after the checkpoint commit
- harness manifests and/or gates needed to prevent runtime-size regressions after the refactor pass

## Out of Scope

- Prototype archive rewrites under `app-LTL/prototype/**`
- Unrelated gameplay design changes outside the gate fix and runtime-separation pass
- Asset remastering beyond source-map and runtime-usage alignment

## Steps

1. Audit the live tree against M6 exit criteria and record pass/fail evidence.
2. Create a request ledger for the gate-fix plus runtime-surgery sequence.
3. Repair `docs/source-map.md` so current sound assets are mapped.
4. Repair `LTL-harness/tools/page-contract-gate.ps1` so layout audit success requires the contract marker and does not false-pass via `-Quit`.
5. Fix the exposed runtime layout issue if the stricter gate reveals a real failure.
6. Verify the minimal fix set, commit it as the checkpoint requested by the user, then continue.
7. Separate active-runtime owners from legacy/runtime residue, reduce large runtime-file pressure, and harden harness enforcement against future growth.
8. Re-run verification, summarize manual QA checkpoints, and prepare the final push.

## Expected Outputs

- Honest M6 completion status with supporting verification evidence.
- A current manual QA checklist for M6 sign-off.
- A checkpoint commit covering the minimal gate/source-map repair.
- A follow-up refactor and harness-hardening change set that separates active runtime from lingering legacy pressure.

## Verification Method

- `powershell -NoProfile -ExecutionPolicy Bypass -File LTL-harness/tools/request-analysis-gate.ps1 -Ledger <current-ledger> -Mode pre-edit`
- `powershell -NoProfile -ExecutionPolicy Bypass -File LTL-harness/tools/source-map-gate.ps1 -Root .`
- `powershell -NoProfile -ExecutionPolicy Bypass -File tools/invoke-godot.ps1 -ProjectPath app-LTL -Headless -Script tests/run_main_layout_audit_contract.gd`
- `powershell -NoProfile -ExecutionPolicy Bypass -File LTL-harness/tools/page-contract-gate.ps1 -Root . -GodotPath D:\Programming\godot_workspace\bin\Godot_v4.3-stable_win64_console.exe`
- `powershell -NoProfile -ExecutionPolicy Bypass -File tools/run-compile-check.ps1`
- additional focused Godot/harness commands for the post-checkpoint runtime surgery

## Plan Change Log

- 2026-06-11: Worklog bootstrapped automatically by Codex hook.
- 2026-06-11: Plan updated for a two-phase execution sequence: minimal gate/source-map checkpoint commit first, then runtime-separation surgery and harness hardening.
