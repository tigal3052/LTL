# Request Constraint Ledger

## Request Summary

- Finish the remaining refactor and harness quality-gate plan items after the initial review/refactor pass.

## Preserved Invariants

- Reward ceremony sequence remains `count_tease`, `count_lock`, `reveal_queue`, `tray_review`.
- Active gameplay and UI runtime scripts remain in formal Godot paths.
- Existing user-facing text continues to flow through the text catalog or read-model presenters.
- Generated logs and temporary artifacts must not become source-map obligations.

## Mutable Scope

- Harness gate scripts and docs under `LTL-harness/`.
- Request and source-map documentation under `docs/`.
- Pure UI presenter/policy helpers and delegating call sites under `app-LTL/src/ui/`.
- Generic reusable harness files under `D:\Programming\ex_workspace\agent-harness`.

## Source Map Findings

- `docs/source-map.md`
  - The live map already tracks the harness docs, gate scripts, and UI files touched by this refactor, so the request can stay scoped to tracked formal paths.
- `LTL-harness/tools/source-map-gate.ps1`
  - Generated-artifact exclusions and tracked formal-source expectations live here, which is directly relevant to this quality-gate cleanup.
- `LTL-harness/tools/request-analysis-gate.ps1`
  - Request-ledger validation is part of the same harness-hardening surface and should remain aligned with source-map obligations.
- `tools/run-ltl-quality-gate.ps1`
  - The consolidated quality gate is already mapped as the SoT orchestration point for the full harness verification pass.

## Transition Safety Review

- no transition impact
- reason: this ledger governs broad harness aggregation and verification orchestration rather than a runtime page, overlay, or phase handoff implementation

## Refactor/Delete Disposition

- Keep and refactor `RewardRevealOverlay.gd`, `BackpackUI.gd`, and `MainViewRuntime.gd`; do not delete active runtime scripts.
- Extract pure layout/policy helpers where behavior can be contract-tested.
- Delete or ignore only generated artifacts and orphan import metadata with no source asset.
- Keep new request-analysis and quality-gate scripts as harness source.

## Verification Checklist

- Run `LTL-harness/tools/request-analysis-gate.tests.ps1`.
- Run `LTL-harness/tools/source-map-gate.tests.ps1`.
- Run `LTL-harness/tools/source-map-gate.ps1 -Root .`.
- Run `tools/run-ltl-quality-gate.ps1`.
- Run matching generic `agent-harness` source-map/request gate checks after common harness changes.

## Verification Notes

- Reward ceremony sequence is covered by `tests/run_reward_ceremony_contract.gd`.
- Request-analysis sections are covered by `LTL-harness/tools/request-analysis-gate.tests.ps1`.
- Source-map generated-artifact exclusions are covered by `LTL-harness/tools/source-map-gate.tests.ps1`.
- Consolidated completion evidence is covered by `tools/run-ltl-quality-gate.ps1`.

## Artifact Ledger

- Latest generated quality-gate log index: `docs/artifact-ledgers/ltl-quality-gate-latest.md`.
- Godot logs are written under ignored path `app-LTL/.tmp-godot-logs/`.
