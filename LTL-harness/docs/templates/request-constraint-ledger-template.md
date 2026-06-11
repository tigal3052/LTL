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

## Transition Safety Review

- Record touched transition ids or state `no transition impact`.
- Name the transition entry owner and exit owner.
- List shared state, layout, overlay, reparent, or sequencing handoff risks.
- Map each touched transition to a runner path and expected success marker.

## Execution Responsibility Units

- Add this section when `Mutable Scope` touches a monitored runtime owner from `docs/architectural-gates/runtime-size-gate.md`.
- Use one owner block per monitored runtime owner:
- `Owner: <runtime-owner path>`
- `Unit: <the execution responsibility being split>`
- `Extract to: <helper or leaf target path>`
- `Keep in owner: <what intentionally remains with the owner>`
- `Focused proof: <focused suite or runner path>`

## Refactor/Delete Disposition

- For each broad target, choose one: keep, refactor, quarantine, delete.
- Explain any deletion with source, generated-artifact, or orphan-file evidence.

## Verification Checklist

- List commands, visual checks, manual QA, or review checks that prove the request.

## Verification Notes

- Fill before completion. Map each invariant and completion claim to evidence.

## Artifact Ledger

- Link generated logs, screenshots, videos, reports, or other evidence paths.
