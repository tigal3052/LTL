# Codex Worklog Plan

Workspace: LootingTheLeviathan
Date: 2026-06-09

## Active Work

- Realign the reward tray's three visible top panels, switch the header title from the static app copy to the selected Leviathan name, and strip the extra helper copy the user called out in the inspector, discard, and confirm zones.

## Request Summary

- Use `app-LTL/src/ui/MainViewRuntime.gd` as the reference surface to fix the reward tray layout where `보상 카드 더미`, `백팩 엔진 공간`, and `상세 인스펙터` keep showing mismatched heights.
- Change the header copy currently showing `레비아탄 채굴 작전` so the live shell shows the selected Leviathan name instead.
- Remove the extra helper copy the user called out:
  - `상세 인스펙터` hint `고정 정보 패널`
  - inspector kicker `선택 항목`
  - discard hint `안전 폐기`
  - discard inner `버리기 구역`
  - confirm hint `현재 전리품으로 종료`
  - ready-state confirm body `남은 보상이 없습니다. 전리품 정리를 끝내고 다음 노드 선택으로 이동하세요.`

## Scope

- `app-LTL/src/ui/MainViewRuntime.gd` reward-tray shell title/layout logic, especially the docked backpack workspace presentation
- localized reward-board copy in `app-LTL/src/data/i18n/text-*.json` and reward tray projection text in `app-LTL/src/ui/read_models/RewardReadModel.gd`
- focused reward-board/runtime tests under `app-LTL/tests/*` that can prove the Leviathan title override, visible workspace-shell alignment contract, and helper-copy removal
- today's worklog/reporting files for the debugging and verification summary

## Out of Scope

- Reverting unrelated user changes.
- Broad redesign outside the requested reward-tray/header/text cleanup.
- A full dirty-worktree staging or commit pass.

## Steps

- Confirm which visible reward-tray panels are actually being shown at runtime and identify why the docked backpack panel does not visually align with the left/right zones.
- Add failing regression coverage for the selected-Leviathan header title, the reward-workspace visible shell contract, and the helper-copy removals the user requested.
- Update the reward-tray runtime/layout logic so the workspace shell becomes the visible aligned panel while the docked backpack content stays contained inside it.
- Remove the requested helper copy from the reward-board catalogs/read model without regressing the remaining claim/discard behavior.
- Re-run the focused reward-board and UI read-model checks plus diff/worklog verification.

## Expected Outputs

- A concrete runtime explanation for the visible reward-workspace height mismatch.
- A targeted reward-tray layout fix that makes the three top panels read as aligned shells.
- Updated localized copy and reward-tray projections that remove the requested helper text.
- Regression evidence showing the Leviathan header title override and reward-board presentation contract now hold.

## Verification Method

- `powershell -NoProfile -ExecutionPolicy Bypass -File 'tools/invoke-godot.ps1' -WorkspaceRoot 'D:\Programming\ex_workspace\LootingTheLeviathan' -ProjectPath 'app-LTL' -Script 'tests/run_reward_claim_board_contract.gd' -Headless`
- `powershell -NoProfile -ExecutionPolicy Bypass -File 'tools/invoke-godot.ps1' -WorkspaceRoot 'D:\Programming\ex_workspace\LootingTheLeviathan' -ProjectPath 'app-LTL' -Script 'tests/run_test_ui_read_models.gd' -Headless -Quit`
- `git diff --check -- app-LTL/src/ui/MainViewRuntime.gd app-LTL/src/ui/read_models/RewardReadModel.gd app-LTL/src/data/i18n/text-ko.json app-LTL/src/data/i18n/text-en.json app-LTL/tests/test_reward_claim_board_contract.gd app-LTL/tests/ui_read_models/ui_codex_reward_board_suite.gd docs/codex-worklog/plan_LootingTheLeviathan_2026-06-09.md docs/codex-worklog/history_LootingTheLeviathan_2026-06-09.md docs/codex-worklog/complete_LootingTheLeviathan_2026-06-09.md`

## Plan Change Log

- 2026-06-09: Worklog bootstrapped automatically by Codex hook.
- 2026-06-09: Replaced placeholder plan with reward-board layout stabilization scope, test-first approach, and verification commands.
- 2026-06-09: Reopened after the first fix failed in live use; narrowed the root cause to reward-board child minimum-size inflation during inspection changes and shifted the runtime plan toward internal scroll containment shells plus fixed visible-height fallback.
- 2026-06-09: Added a diagnostic-only pass for the live reward-ceremony -> reward-board freeze/exit report, focusing on transition-state reward-board rendering versus isolated ceremony rendering.
- 2026-06-09: Temporarily re-scoped a parallel harness pass to review whether `docs/source-map.md` was only gate-enforced, then added request-analysis linkage so source-map findings become explicit request-triage inputs.
- 2026-06-09: Re-scoped again to the next requested step: clean up the remaining repository-wide source-map drift so the live gate can pass against the current formal source tree.
- 2026-06-09: Re-scoped once more after source-map recovery to audit the broader dirty workspace and recommend logical batching before any future staging or commit pass.
- 2026-06-09: Re-scoped again after the reward ceremony to reward-board crash review so the next pass formalizes a dedicated transition-safety harness gate before further runtime fixes.
- 2026-06-09: Re-scoped once more after the narrow Leviathan CTA and source-map recovery so the next slice targets the broader `page semantics contract` localization/copy drift in the split UI read-model suites.
- 2026-06-09: Re-scoped again after the page-semantics and source-map recovery so the next blocker is the `transition safety gate` failure on `meta.start_flow` inside the fast compile check.
- 2026-06-09: Re-scoped again after the focused reward-handoff repro so the next pass isolates the overlay-finish callback path and reward-board layout feedback loop instead of treating the transition crash as one opaque failure.
- 2026-06-09: Re-scoped again after the live user bug report to target the still-reproducible reward-board rightward drift, the self-referential width math behind it, and the missing gate coverage for alternating inspection clicks.
- 2026-06-09: Re-scoped for the next live user request: align the three visible reward-tray panels, swap the header title to the selected Leviathan name, and remove the extra helper copy called out in the tray UI.
