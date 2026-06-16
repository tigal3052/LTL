# Request Constraint Ledger

## Request Summary

- Analyze the completed 500-line refactor and apply the lessons to the harness so design, implementation, and maintenance work keeps code split into small feature units.

## Preserved Invariants

- Existing request-analysis gate checks for source-map, root-cause, transition, runtime performance, execution responsibility, verification, and resolution proof must keep working.
- Current runtime-size gate behavior and the 500-line source cap must remain strict.
- Existing Godot source behavior and the completed helper split structure must not be changed by this harness-only follow-up.

## Mutable Scope

- `LTL-harness/tools/request-analysis-gate.ps1`
- `LTL-harness/tools/request-analysis-gate.tests.ps1`
- `LTL-harness/docs/request-analysis-execution-gate.md`
- `LTL-harness/docs/templates/request-constraint-ledger-template.md`
- `LTL-harness/00_AGENTS.md`
- `docs/request-ledgers/2026-06-15-feature-unit-lifecycle-harness.md`
- `docs/codex-worklog/plan_LootingTheLeviathan_2026-06-15.md`
- `docs/codex-worklog/history_LootingTheLeviathan_2026-06-15.md`
- `docs/codex-worklog/complete_LootingTheLeviathan_2026-06-15.md`

## Source Map Findings

- `docs/source-map.md` maps `LTL-harness/tools/request-analysis-gate.ps1` as the request-analysis validator that can block incomplete request ledgers before edits.
- `docs/architectural-gates/runtime-size-gate.md` enforces the final 500-line source and scene cap, but final-size enforcement alone cannot prevent maintenance-time drift before a file grows.
- The completed split showed that `app-LTL/src/ui/MainViewRuntime.gd`, `NodeSelectRuntimePage.gd`, and similar owners grew through repeated maintenance additions that were not forced to name a feature-unit capsule first.

## Root Cause Review

- Observed symptom: source files can pass an initial refactor and later grow again because maintenance changes append behavior to the nearest owner instead of selecting or creating a feature-unit capsule.
- Evidence: the completed refactor split oversized owners only after they had accumulated unrelated UI, lifecycle, panel, locale, reward, and runtime state responsibilities.
- Root cause target: `LTL-harness/tools/request-analysis-gate.ps1`
- Rejected workaround: relying only on completion-time runtime-size checks catches oversize files after the implementation path has already drifted.
- Chosen fix: require a pre-edit feature-unit lifecycle plan for source and harness scopes, covering design boundaries, implementation split rules, maintenance drift guards, capsule contracts, and size triggers.

## Transition Safety Review

- no transition impact
- reason: this is a harness and documentation change; it does not modify runtime page handoff or gameplay transition code.

## Feature Unit Lifecycle Plan

- Design stage: ledger scope must name the intended feature-unit boundary before implementation, including what remains in the owner and what belongs in helper capsules.
- Implementation stage: source and harness edits must add behavior through a focused owner or extraction target, with tests tied to that unit before production code.
- Maintenance stage: follow-up changes must extend an existing capsule only when the responsibility still matches; otherwise the ledger must declare a new helper or split target before editing.
- Capsule boundary: helper files expose a narrow public/static API and keep state, layout, parsing, or rendering details private to the unit.
- Size trigger: any capped source or harness owner at or above 80% of its cap requires a split target or explicit non-growth plan before editing.

## Refactor/Delete Disposition

- Refactor the request-analysis harness to enforce lifecycle planning.
- Keep existing root-cause, execution-responsibility, runtime-performance, and resolution-proof checks.
- Delete no source or harness files in this follow-up.

## Verification Checklist

- Add a RED request-analysis self-test for missing feature-unit lifecycle planning.
- Run request-analysis self-tests after implementation.
- Run this ledger through pre-edit and pre-complete request-analysis gates.

## Verification Notes

- Lifecycle RED fixture: `source-scope-without-lifecycle-plan.md` failed before implementation because the gate did not yet reject source scope without lifecycle planning.
- Gate self-tests: `powershell -NoProfile -ExecutionPolicy Bypass -File LTL-harness/tools/request-analysis-gate.tests.ps1` passed with `REQUEST_ANALYSIS_GATE_TESTS_OK`.
- Pre-edit ledger gate: `powershell -NoProfile -ExecutionPolicy Bypass -File LTL-harness/tools/request-analysis-gate.ps1 -Ledger docs/request-ledgers/2026-06-15-feature-unit-lifecycle-harness.md -Mode pre-edit` passed with `REQUEST_ANALYSIS_GATE_OK`.
- Documentation alignment: request-analysis execution gate, ledger template, agent entry addendum, and source-map responsibility descriptions now mention feature-unit lifecycle planning.
- Runtime-size gate: `powershell -NoProfile -ExecutionPolicy Bypass -File LTL-harness/tools/runtime-size-gate.ps1 -Root .` passed with `RUNTIME_SIZE_GATE_OK`.
- Source-map gate: `powershell -NoProfile -ExecutionPolicy Bypass -File LTL-harness/tools/source-map-gate.ps1 -Root .` still fails only on pre-existing missing drill image files and `.import` files under `app-LTL/resources/items/drill/`.

## Resolution Proof

- RED proof: `request-analysis-gate.tests.ps1` failed on `ledger that touches source implementation scope without a feature-unit lifecycle plan should fail pre-edit` before the gate implementation.
- Root-cause proof: `request-analysis-gate.tests.ps1` now passes and includes a missing-lifecycle negative fixture plus valid lifecycle-covered source/harness fixtures.
- Workaround guard: the template and execution-gate docs require design-stage boundaries, implementation-stage split rules, maintenance-stage drift guards, capsule boundaries, and size triggers, so completion cannot rely only on final runtime-size checks.

## Artifact Ledger

- No generated artifacts are expected; command output remains in terminal verification.
