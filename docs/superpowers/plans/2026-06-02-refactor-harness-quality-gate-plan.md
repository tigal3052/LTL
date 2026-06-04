# 2026-06-02 Refactor And Harness Quality Gate Plan

## Goal

Review the current large change set, refactor the highest-risk gameplay/UI coupling, and adjust the LTL harness plus the generic agent harness so refactor gaps are caught before completion.

## Review Conclusion

- UI design review: `BackpackUI.gd`, `BattlefieldUI.gd`, and `RewardRevealOverlay.gd` are still too broad. The immediate safe refactor is to move ceremony step and interaction policy out of view/controller duplication, while leaving large visual splits for a follow-up because they affect many assets and tests.
- Logic review: reward ceremony state was duplicated across controller, presenter, and view; stale reward meta clicks could index past `local_rewards_list`; reveal callbacks could still complete after phase cleanup.
- Planning/harness review: source-map enforcement treated generated logs and agent caches as source files, headless Godot logging was not normalized, and `Mandatory = $true` PowerShell parameters could block automation.

## Harness Design Conclusion

- Source-map gates must track durable source and docs only. Generated logs, `.tmp-*` folders, `.superpowers`, Godot caches, and artifact folders are explicitly excluded.
- Completion should use a single project quality gate that runs source-map, source-map self-tests, stack/i18n/architecture gates, and Godot contract runners.
- Godot contract commands should create artifact/log directories up front and judge success by explicit runner markers, not by noisy renderer shutdown warnings.
- Gate scripts must fail with usage text instead of prompting interactively.
- Architectural gates should keep large UI files visible as warnings today, then promote selected files to strict thresholds only after the next planned split.

## Applied Scope

- Add `RewardCeremonyPolicy.gd` as the single source of ceremony step and interaction gate policy.
- Add reward reveal cancellation so phase cleanup cannot fire stale completion callbacks.
- Add bounds checks for reward meta clicks.
- Add `BackpackPinLayoutPolicy.gd` so `BackpackUI.gd` and `MainViewRuntime.gd` share one tested pin slot/overhang/top-content sizing policy.
- Update source-map rules, architectural gate parameter handling, and generated artifact ignores.
- Add request-analysis gate docs, templates, tests, and the current request constraint ledger.
- Add artifact ledger output to the consolidated quality gate.
- Split architectural gate execution into `warning`, `strict-refactor`, and `release-blocking` manifest profiles.
- Add `tools/run-ltl-quality-gate.ps1`.
- Apply the same request-analysis, source-map/generated-artifact exclusions, and non-interactive architectural gate handling to `D:\Programming\ex_workspace\agent-harness`.

## Follow-Up Harness Hardening Completed

- Done: request-analysis gate now requires request summary, preserved invariants, mutable scope, refactor/delete disposition, verification checklist, and pre-complete verification notes.
- Done: consolidated quality gate writes generated Godot log references to `docs/artifact-ledgers/ltl-quality-gate-latest.md`, while source-map gates exclude generated artifact ledgers.
- Done: architectural execution now runs `warning-refactor-gate.md`, `strict-refactor-gate.md`, and `release-blocking-gate.md`.
- Done: first safe split landed for `BackpackUI.gd` and `MainViewRuntime.gd` via `BackpackPinLayoutPolicy.gd`.
- Deferred: promote full `RewardRevealOverlay.gd`, `BackpackUI.gd`, and `MainViewRuntime.gd` file-size thresholds to strict only after deeper presenter/control splits land.

## Verification

- `powershell -NoProfile -ExecutionPolicy Bypass -File LTL-harness/tools/request-analysis-gate.tests.ps1` -> `REQUEST_ANALYSIS_GATE_TESTS_OK`
- `powershell -NoProfile -ExecutionPolicy Bypass -File LTL-harness/tools/source-map-gate.tests.ps1` -> `SOURCE_MAP_GATE_TESTS_OK`
- `powershell -NoProfile -ExecutionPolicy Bypass -File LTL-harness/tools/source-map-gate.ps1 -Root .` -> `SOURCE_MAP_GATE_OK`
- `powershell -NoProfile -ExecutionPolicy Bypass -File tools/run-ltl-quality-gate.ps1` -> `LTL_QUALITY_GATE_OK`
- `powershell -NoProfile -ExecutionPolicy Bypass -File D:\Programming\ex_workspace\agent-harness\tools\request-analysis-gate.tests.ps1` -> `REQUEST_ANALYSIS_GATE_TESTS_OK`
- `powershell -NoProfile -ExecutionPolicy Bypass -File D:\Programming\ex_workspace\agent-harness\tools\source-map-gate.tests.ps1` -> `SOURCE_MAP_GATE_TESTS_OK`
- `powershell -NoProfile -ExecutionPolicy Bypass -File D:\Programming\ex_workspace\agent-harness\tools\source-map-gate.ps1 -Root D:\Programming\ex_workspace\agent-harness` -> `SOURCE_MAP_GATE_OK`
- `git diff --check` -> no whitespace errors; LF-to-CRLF warnings only.
