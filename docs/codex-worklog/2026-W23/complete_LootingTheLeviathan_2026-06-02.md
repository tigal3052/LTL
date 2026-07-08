# Codex Worklog Completion

Workspace: LootingTheLeviathan
Date: 2026-06-02

Status: Complete

- Completion summary: Fixed the stale reward tooltip bug by treating the floating tooltip as transient hover UI instead of a stateful reward panel. The root cause was that reward tooltip dismissal depended only on hover-end signals, so reward tray rerenders and phase changes could invalidate the hover source without hiding the shared tooltip. Combat terrain interaction also lacked a cleanup path, which is why clicking terrain did not remove the stale reward info.
- Actual outputs:
  - `app-LTL/src/MainControllerRuntime.gd`
  - `app-LTL/tests/run_main_start_flow_contract.gd`
  - `docs/codex-worklog/plan_LootingTheLeviathan_2026-06-02.md`
  - `docs/codex-worklog/history_LootingTheLeviathan_2026-06-02.md`
  - `docs/codex-worklog/complete_LootingTheLeviathan_2026-06-02.md`
- Changes from plan:
  - Kept the runtime change centered on tooltip lifecycle cleanup. No reward data, reward ceremony sequencing, or inventory placement rules were modified.
  - Implemented one extra defensive cleanup path on combat terrain hover/click so stale reward tooltips cannot survive the first battlefield interaction even if another future regression reintroduces a missed phase cleanup.
- Verification results:
  - RED first: `Godot_v4.3-stable_win64_console.exe --headless --path app-LTL --script tests/run_main_start_flow_contract.gd` failed on `reward tooltip clears when the scene leaves reward_loot: expected false, got true`.
  - Focused GREEN: `Godot_v4.3-stable_win64_console.exe --headless --path app-LTL --script tests/run_main_start_flow_contract.gd` printed `MAIN_START_FLOW_CONTRACT_OK`.
  - Focused UI regression: `Godot_v4.3-stable_win64_console.exe --headless --path app-LTL --script tests/run_test_ui_read_models.gd` printed `UI_READ_MODEL_TESTS_OK`.
  - Smoke compile wrapper: `powershell -NoProfile -ExecutionPolicy Bypass -File tools/run-compile-check.ps1` printed `SOURCE_MAP_GATE_OK` and `Compilation Check: PASSED (GODOT_CONTRACTS_OK)`.
  - Whitespace: `git diff --check -- app-LTL/src/MainControllerRuntime.gd app-LTL/tests/run_main_start_flow_contract.gd docs/codex-worklog/plan_LootingTheLeviathan_2026-06-02.md` returned no whitespace errors; only the existing LF-to-CRLF warning for `MainControllerRuntime.gd`.
- Blockers or unverified areas:
  - Headless Godot still prints long-standing RID/resource leak warnings on exit in this environment. They did not block the success markers and were already present outside this bugfix.
- Remaining gaps:
  - This fix is targeted at reward-origin stale tooltips. If future UI surfaces add more floating hover panels, they should reuse the same transient cleanup approach instead of depending only on hover-end signals.
