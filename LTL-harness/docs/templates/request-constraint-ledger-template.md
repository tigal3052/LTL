# Request Constraint Ledger

## Request Summary

- Restate the current request in plain language.

## Preserved Invariants

- List behavior, layout, data, files, or user wording that must not change.

## Mutable Scope

- List files, modules, or behavior that may change.

## Source Map Findings

- Record the `docs/source-map.md` entries or source-map-derived observations that shaped this request's scope.
- Prefer mapped file paths plus one short responsibility note per relevant entry.

## Root Cause Review

- `Observed symptom: <what is visibly wrong or incomplete>`
- `Evidence: <what evidence ties the symptom to a specific source owner, contract, or state boundary>`
- `Root cause target: <backticked source owner or formal target path>`
- `Rejected workaround: <the tempting symptom-only patch that should not count as completion>`
- `Chosen fix: <the source-level repair that the implementation will make>`

## Transition Safety Review

- Record touched transition ids or state `no transition impact`.
- Name the transition entry owner and exit owner.
- List shared state, layout, overlay, reparent, or sequencing handoff risks.
- Map each touched transition to a runner path and expected success marker.

## Feature Unit Lifecycle Plan

- Add this section when `Mutable Scope` touches source or harness implementation surfaces such as `app-LTL/src/**`, `LTL-harness/**`, `docs/architectural-gates/**`, or `docs/source-map.md`.
- `Design stage: <the feature-unit owner/helper boundary chosen before coding>`
- `Implementation stage: <the test-first split or non-growth implementation rule>`
- `Maintenance stage: <the follow-up drift guard that decides whether to extend an existing capsule or create a new helper>`
- `Capsule boundary: <the narrow public API plus details that must remain private to the unit>`
- `Size trigger: <the line-count, responsibility, or cap-proximity signal that requires splitting before editing>`

## Execution Responsibility Units

- Add this section when `Mutable Scope` touches a monitored runtime owner from `docs/architectural-gates/runtime-size-gate.md`.
- This includes exact debt/path caps and strict-glob runtime files whose current line count is at least 80% of the cap.
- Use one owner block per monitored runtime owner:
- `Owner: <runtime-owner path>`
- `Unit: <the execution responsibility being split>`
- `Extract to: <helper or leaf target path>`
- `Keep in owner: <what intentionally remains with the owner>`
- `Focused proof: <focused suite or runner path>`

## Runtime Performance Review

- Add this section when `Mutable Scope` touches a high-frequency runtime path such as battle input, hover, tick, VFX, battlefield rendering, or combat reducer code.
- `Hot path: <backticked owner/function plus runtime scenario>`
- `Risk: <the repeated work, allocation, rebuild, layout invalidation, or backlog risk>`
- `Performance proof: <focused runner or suite path>`
- `Budget: <measurable bound for repeated input/tick/render behavior>`

## File Size Budget

- For each `app-LTL/src/**/*.gd` or `app-LTL/src/**/*.tscn` file in `Mutable Scope`, record current lines, cap, planned final shape, and split target when the file is near the cap.
- Example: `app-LTL/src/ui/StatusPanelUI.gd`: current 739, cap 739 frozen debt, planned final non-growth, split target `app-LTL/src/ui/StatusPanelQueueRenderer.gd`.

## Refactor/Delete Disposition

- For each broad target, choose one: keep, refactor, quarantine, delete.
- Explain any deletion with source, generated-artifact, or orphan-file evidence.

## Verification Checklist

- List commands, visual checks, manual QA, or review checks that prove the request.

## Verification Notes

- Fill before completion. Map each invariant and completion claim to evidence.

## Resolution Proof

- `RED proof: <the failing proof that existed before the fix>`
- `Root-cause proof: <the proof that the source-level repair now passes>`
- `Workaround guard: <the proof that completion did not stop at cosmetic symptom masking>`

## Artifact Ledger

- Link generated logs, screenshots, videos, reports, or other evidence paths.
