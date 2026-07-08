# 2026-06-05 Page Contract Harness Audit Design

Date: 2026-06-05  
Workspace: `LootingTheLeviathan`

## Goal

Move the current UI audit from generic shell containment checks to page-aware contract validation.

Audit ownership stays with the harness design until the runtime page runners and smoke tests are introduced. This note is the source of truth for the next implementation step.

## Ownership Split

- Shared page-contract audit runner: owns visible, hidden, and overlay policy checks across the page tokens.
- Per-page smoke tests: own page-specific interaction semantics and page-specific assertions, including reward detail-panel behavior and progress-model assertions.

## Current Inputs

- `docs/superpowers/specs/2026-06-05-phase-first-page-shell-contract-design.ko.md`
- `app-LTL/tests/run_main_layout_audit_contract.gd`
- `app-LTL/src/ui/MainViewRuntime.gd`
- `app-LTL/src/ui/presenters/PhaseLayoutPresenter.gd`

## Required Audit Split

The harness must treat these page contracts as first-class audit targets:

1. `run_start`
2. `node_select`
3. `combat`
4. `reward_claim`
5. `event_node`
6. `boss_reward_pick`
7. `defeat`

## Per-Page Rules

### `run_start`

- Visible: character list, selected character hero panel, starter relic candidates, starter backpack preview, start CTA
- Hidden: battlefield, reward tray, discard zone, node map canvas
- Allowed overlay actions: `settings`, `artifact codex`
- Blocked overlay actions: `shop`

### `node_select`

- Visible: run progress bar, path row, five live node choices, unknown future node chain, boss endpoint, selected-node detail
- Hidden: battlefield, reward discard zone, defeat hero frame
- Allowed overlay actions: `settings`, `artifact codex`, `shop`
- Blocked interaction: full-size combat backpack dock

### `reward_claim`

- Visible: reward image list, backpack grid, fixed detail inspector, discard zone, confirm CTA
- Hidden: battlefield, node path row, event hero image
- Required interaction: `click-to-inspect drives the detail panel instead of hover-only tooltip`

## Audit Migration

- Keep `run_main_layout_audit_contract.gd` as the viewport-containment base.
- Add a page-aware runner for visible/hidden and action policy checks.
- Split page-specific smoke tests once runtime implementation starts.

## Candidate Future Runners

- `app-LTL/tests/run_page_shell_contract_audit.gd`
- `app-LTL/tests/test_run_start_page_smoke.gd`
- `app-LTL/tests/test_reward_claim_page_smoke.gd`
- `app-LTL/tests/test_event_node_page_smoke.gd`
- `app-LTL/tests/test_boss_reward_pick_page_smoke.gd`
- `app-LTL/tests/test_defeat_page_smoke.gd`
- `node_select` and `combat` remain on the shared contract runner first, because their current validation is limited to page-token visibility, hidden-surface, and overlay policy checks until page-specific interaction semantics are implemented.

## Verification Targets

- Each page declares exactly one primary panel cluster.
- Blocked overlays stay hidden or disabled.
- Visible controls stay inside viewport bounds.
- Node-select progress model exposes run and stage counts separately.
- Reward-claim exposes detail-panel-first interaction language.
