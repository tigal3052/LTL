# Request Analysis Execution Gate

This document is the source of truth for converting a user request into a checkable implementation ledger before non-trivial LTL work is completed.

## Required Stages

1. Request Parse Gate: restate the objective, preserved invariants, mutable scope, explicit exclusions, hidden risks, and proof expectations.
2. Source Map Lookup Gate: inspect `docs/source-map.md` before locking mutable scope, and record the mapped candidate files or responsibilities that shaped the request plan.
3. Constraint Ledger Gate: create a ledger under `docs/request-ledgers/` for broad refactors, visual changes, deletion work, or harness changes.
4. Root Cause Gate: record the observed symptom, evidence, actual source-level target, rejected workaround, and chosen fix before implementation begins.
5. Transition Safety Review Gate: declare touched transition ids or explicit `no transition impact`, record the entry owner and exit owner, and map shared handoff risks to runnable proofs when a request affects runtime boundaries.
6. Feature Unit Lifecycle Gate: when source or harness implementation surfaces are in scope, record design-stage ownership, implementation split rules, maintenance drift guards, capsule boundaries, and size triggers before editing.
7. Runtime Performance Review Gate: when a request touches a high-frequency runtime path, record the hot path, performance risk, proof runner, and measurable budget before editing.
8. Execution Mapping Gate: map every implementation step to at least one mutable scope item or preserved invariant.
9. Verification Gate: map tests, scripts, visual QA, or manual checks to the claims they prove.
10. Completion Gate: state which claims are verified and which remain explicitly unverified, including proof that the change resolved the cause rather than only masking the symptom.

## Required Ledger Sections

- `Request Summary`
- `Preserved Invariants`
- `Mutable Scope`
- `Source Map Findings`
- `Root Cause Review`
- `Transition Safety Review`
- `Feature Unit Lifecycle Plan` when `Mutable Scope` touches `app-LTL/src/**`, `LTL-harness/**`, `docs/architectural-gates/**`, or `docs/source-map.md`
- `Runtime Performance Review` when `Mutable Scope` touches a high-frequency runtime path enforced by `request-analysis-gate.ps1`
- `Execution Responsibility Units` when `Mutable Scope` touches a monitored runtime owner from `docs/architectural-gates/runtime-size-gate.md`
- `Refactor/Delete Disposition`
- `Verification Checklist`
- `Verification Notes` before completion
- `Resolution Proof` before completion
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

When `Mutable Scope` includes a monitored runtime-owner path such as `app-LTL/src/ui/MainViewRuntime.gd`, the pre-edit gate requires `Execution Responsibility Units` coverage for that owner. Monitored owners are:

- paths listed in `legacy_debt_path_caps`
- paths listed in `strict_path_caps`
- paths matched by `strict_glob_caps` whose current line count is at least 80% of that cap

Each owner block must declare:

- `Owner: <runtime-owner path>`
- `Unit: <the concrete execution slice being split>`
- `Extract to: <helper or leaf target path>`
- `Focused proof: <runner or focused suite path>`

Small helper files that match a strict glob but are still comfortably below the cap can be listed in `Mutable Scope` without their own owner block. They should normally appear as the `Extract to` target of a larger owner.

When `Mutable Scope` includes a high-frequency runtime path such as `app-LTL/src/ui/MainViewRuntime.gd`, `app-LTL/src/MainControllerRuntime.gd`, `BattlefieldUI.gd`, `BattlefieldVFX.gd`, or `CombatVocab.gd`, the pre-edit gate requires `Runtime Performance Review` coverage. Each section must declare:

- `Hot path: <backticked owner/function plus runtime scenario>`
- `Risk: <the repeated work or frame-time risk>`
- `Performance proof: <runner or focused suite path>`
- `Budget: <measurable bound such as no hidden-page apply_state calls, no full rebuilds, or a repeat-hit frame/update budget>`

Every non-trivial request ledger must also pass the root-cause checks:

- `Observed symptom: <what is wrong from the user's perspective>`
- `Evidence: <why the symptom points at a specific source owner or contract>`
- `Root cause target: <backticked owner path or formal target>`
- `Rejected workaround: <the tempting symptom-only patch that is not acceptable>`
- `Chosen fix: <the source-level repair being implemented>`

When `Mutable Scope` touches source or harness implementation surfaces, the pre-edit gate requires `Feature Unit Lifecycle Plan` coverage. This catches maintenance-time growth before it becomes another post-hoc split. The section must declare:

- `Design stage: <the owner/helper boundary before coding>`
- `Implementation stage: <the test-first split or non-growth implementation rule>`
- `Maintenance stage: <the drift guard for follow-up edits>`
- `Capsule boundary: <public API and private responsibility boundary>`
- `Size trigger: <when to split, stop, or declare non-growth before editing>`

Before completion, the ledger must also prove that the request did not stop at symptom masking:

- `RED proof: <the failing proof that existed before the fix>`
- `Root-cause proof: <what verifies the source-level repair>`
- `Workaround guard: <what proves a cosmetic-only patch is not the only thing that changed>`

## Completion Policy

Passing code tests is not the same as satisfying the request. Completion reporting must separate code change evidence, root-cause resolution evidence, transition-handoff evidence, harness gate evidence, visual/manual evidence, and unverified areas.
