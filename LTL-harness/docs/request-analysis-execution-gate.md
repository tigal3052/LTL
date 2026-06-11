# Request Analysis Execution Gate

This document is the source of truth for converting a user request into a checkable implementation ledger before non-trivial LTL work is completed.

## Required Stages

1. Request Parse Gate: restate the objective, preserved invariants, mutable scope, explicit exclusions, hidden risks, and proof expectations.
2. Source Map Lookup Gate: inspect `docs/source-map.md` before locking mutable scope, and record the mapped candidate files or responsibilities that shaped the request plan.
3. Constraint Ledger Gate: create a ledger under `docs/request-ledgers/` for broad refactors, visual changes, deletion work, or harness changes.
4. Transition Safety Review Gate: declare touched transition ids or explicit `no transition impact`, record the entry owner and exit owner, and map shared handoff risks to runnable proofs when a request affects runtime boundaries.
5. Execution Mapping Gate: map every implementation step to at least one mutable scope item or preserved invariant.
6. Verification Gate: map tests, scripts, visual QA, or manual checks to the claims they prove.
7. Completion Gate: state which claims are verified and which remain explicitly unverified.

## Required Ledger Sections

- `Request Summary`
- `Preserved Invariants`
- `Mutable Scope`
- `Source Map Findings`
- `Transition Safety Review`
- `Execution Responsibility Units` when `Mutable Scope` touches a monitored runtime owner from `docs/architectural-gates/runtime-size-gate.md`
- `Refactor/Delete Disposition`
- `Verification Checklist`
- `Verification Notes` before completion
- `Artifact Ledger` when generated logs, screenshots, videos, or reports are used as evidence

## Gate Script

Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File LTL-harness/tools/request-source-map.ps1 -MapPath docs/source-map.md -Keyword <term> [-PathPrefix <path>]
powershell -NoProfile -ExecutionPolicy Bypass -File LTL-harness/tools/request-analysis-gate.ps1 -Ledger docs/request-ledgers/<ledger>.md -Mode pre-edit
powershell -NoProfile -ExecutionPolicy Bypass -File LTL-harness/tools/transition-safety-gate.ps1 -Root . -GodotPath <godot.exe> -Ledger docs/request-ledgers/<ledger>.md
powershell -NoProfile -ExecutionPolicy Bypass -File LTL-harness/tools/request-analysis-gate.ps1 -Ledger docs/request-ledgers/<ledger>.md -Mode pre-complete -RequireArtifactLedger
```

`request-source-map.ps1` is the harness helper for turning the live file map into a short candidate list before manual code search expands further.

When `Mutable Scope` includes a strict runtime-owner path such as `app-LTL/src/ui/MainViewRuntime.gd`, the pre-edit gate now requires `Execution Responsibility Units` coverage for that owner. Each owner block must declare:

- `Owner: <runtime-owner path>`
- `Unit: <the concrete execution slice being split>`
- `Extract to: <helper or leaf target path>`
- `Focused proof: <runner or focused suite path>`

## Completion Policy

Passing code tests is not the same as satisfying the request. Completion reporting must separate code change evidence, transition-handoff evidence, harness gate evidence, visual/manual evidence, and unverified areas.
