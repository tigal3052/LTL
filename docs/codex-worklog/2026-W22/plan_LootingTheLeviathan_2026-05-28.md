# Codex Worklog Plan

Workspace: LootingTheLeviathan
Date: 2026-05-28

## Active Work

Implement the requested M3/M4 follow-up pass: localized UI text with settings language switching, reward drill comparison tooltip, cooldown charge visualization, beacon cooldown behavior, reward reveal skip/longer VFX, and i18n harness gates.

## Request Summary

Replace hardcoded English UI output with a dynamic text catalog, add Korean/English switching in settings, make reward hover compare same-color equipped drills, change beacon effects to pulse from beacon cooldowns, improve cooldown/reward reveal visuals, and add LTL plus generic harness i18n guidance/gates.

## Scope

- Add `TextCatalog.gd` and route UI read-model/presenter strings through it.
- Add settings language selector and scene re-render on locale change.
- Add same-color equipped drill comparison for reward drill hover tooltips.
- Add artifact cooldown charge overlay in backpack cells.
- Convert beacon behavior from permanent adjacent stat edits to cooldown pulse cooldown reduction.
- Extend reward reveal timing and allow repeated click to jump to silhouette count stage.
- Add LTL i18n text gate and generic `agent-harness` i18n text gate guidance.

## Out of Scope

- No full translation of internal telemetry codes, enum values, test names, or source comments.
- No final art asset replacement for artifact icons.
- No browser screenshot matrix in this pass.

## Steps

- Add failing tests for catalog switching, reward comparison, and beacon cooldown pulse.
- Implement catalog, language settings, localized read models, and display-name projection.
- Implement reward hover comparison and backpack cooldown overlay.
- Implement beacon pulse behavior and reward reveal skip/longer VFX.
- Add LTL and generic harness i18n text gate docs/scripts.
- Run Godot contract checks, i18n gates, milestone gate, and `git diff --check`.

## Expected Outputs

- Localized UI text path and language setting.
- Same-color drill comparison in reward tooltip.
- Visual cooldown charge overlay.
- Beacon cooldown pulse behavior.
- Reward reveal skip and stronger/longer VFX.
- LTL and generic harness i18n text gates.
- Updated worklog.
- Final status summary in chat.

## Verification Method

- Run `powershell -NoProfile -ExecutionPolicy Bypass -File LTL-harness/tools/milestone-gate.ps1 -TargetPlan 10_M4_node_routing.md`.
- Run `powershell -NoProfile -ExecutionPolicy Bypass -File tools/run-compile-check.ps1`.
- Run `powershell -NoProfile -ExecutionPolicy Bypass -File LTL-harness/tools/i18n-text-gate.ps1`.
- Run generic agent-harness i18n gate with `-AllowNoCatalog` to verify script execution.
- Run `git diff --check`.

## Plan Change Log

- 2026-05-28: Switched active work to M4 QA follow-up: beacon tooltip single-item behavior, node data/text cleanup, cooldown animation fix, reward reveal white-flash timing, artifact size-label cleanup, and fuller locale switching.
- 2026-05-28: Worklog bootstrapped automatically by Codex hook.
- 2026-05-28: Updated for M2 review and M3-prep logical capsule refactoring plan.
- 2026-05-28: Switched active work from planning/translation to executing the saved refactoring plan.
- 2026-05-28: Switched active work to actual M3 reward/progression contract-gap implementation after confirming the pre-refactor work is already committed.
- 2026-05-28: Switched active work to reward pool composition and item data design after gameplay balance feedback.
- 2026-05-28: Switched active work to M4 node routing implementation requested against `LTL-harness`.
- 2026-05-28: Switched active work to requested M3 completion handling, M4 gate continuation, and git update.
- 2026-05-28: Switched active work to continuing M4 implementation with node-map read-model, input adapter, and scene smoke coverage.
- 2026-05-28: Switched active work to requested localization, reward comparison, cooldown visualization, beacon pulse behavior, reward reveal tuning, and i18n harness gates.
