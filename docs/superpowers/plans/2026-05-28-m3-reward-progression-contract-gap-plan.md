# M3 Reward Progression Contract Gap Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** M3 보상/진행도 milestone에서 이미 구현된 reward loop 위에 누락된 formal contract 증거를 보강한다.

**Architecture:** 기존 `RewardVocab`, `RewardValidator`, `RewardReadModel`, `HeadlessMiniRun` 경계를 유지한다. 새 로직은 순수 캡슐로 추가하고 scene/runtime은 필요한 snapshot 필드만 소비한다.

**Tech Stack:** Godot 4.3 GDScript, JSON data contracts, `tools/run-compile-check.ps1`, `LTL-harness/tools/architectural-gate.ps1`.

---

## 1차 계획

- reward offer마다 `offer_weights_hash`와 `next_combat_modifier_preview`를 붙여 M3 telemetry 필드와 다음 전투 영향 preview를 formal snapshot에서 검증한다.
- `RewardValidator`가 reward rarity와 weight까지 엄격히 확인하도록 확장한다.
- `RewardReadModel`이 private `weight` 값은 숨기면서 badge, description, modifier preview는 노출하도록 테스트를 추가한다.
- headless contract runner에 위 테스트를 연결하고 기존 architecture gate를 유지한다.

## 1차 계획에 대한 반박과 허점

- `offer_weights_hash`를 reward 객체에 붙이면 UI read-model이 실수로 hash를 노출할 수 있다.
- 다음 전투 영향 preview를 scene 문자열로만 만들면 실제 growth/run modifier와 분리되어 “보이는 말”만 맞는 허위 증거가 될 수 있다.
- validator를 너무 엄격하게 만들면 기존 fallback/mock reward가 테스트에서만 통과하고 실제 JSON table은 깨질 수 있다.
- M3 완료 기준에는 reward scene screenshot과 telemetry JSONL sample도 있지만, 이번 작은 구현은 headless formal contract에 치우쳐 수동 증거가 부족할 수 있다.

## 보완 계획

- `offer_weights_hash`는 roll 결과 reward 객체 내부에 남기되 `RewardReadModel.project()`가 명시적으로 제외하는 테스트를 먼저 작성한다.
- `next_combat_modifier_preview`는 reward payload에서 계산하는 순수 vocabulary 함수로 만들고, reward roll 결과와 read-model이 같은 preview를 전달하는지 검증한다.
- validator는 reward table과 rarity table을 함께 받아 교차 검증하는 새 함수로 확장한다. 기존 단독 구조 검증은 유지해 호환성을 지킨다.
- telemetry JSONL 파일을 새로 쓰는 대신, headless snapshot에서 M3 필수 telemetry payload를 만들 수 있는 순수 `RewardTelemetry` 캡슐을 테스트한다.
- screenshot/연출 증거는 이번 pass의 out-of-scope로 명시하고, formal runtime M3 readiness gap으로 worklog에 남긴다.

## Files

- Create: `app-LTL/src/vocabulary/reward/BuildRewardTelemetry.gd`
- Create: `app-LTL/src/vocabulary/reward/BuildRewardPreview.gd`
- Modify: `app-LTL/src/vocabulary/RewardVocab.gd`
- Modify: `app-LTL/src/validation/RewardValidator.gd`
- Modify: `app-LTL/src/ui/read_models/RewardReadModel.gd`
- Modify: `app-LTL/tests/test_reward_contract.gd`
- Modify: `app-LTL/tests/godot_contract_runner.gd`
- Modify: `docs/codex-worklog/plan_LootingTheLeviathan_2026-05-28.md`
- Modify: `docs/codex-worklog/history_LootingTheLeviathan_2026-05-28.md`
- Modify: `docs/codex-worklog/complete_LootingTheLeviathan_2026-05-28.md`

## Tasks

### Task 1: Failing M3 Contract Tests

- [x] Add tests for cross-table reward validation rejecting an unknown rarity and non-positive weight.
- [x] Add tests that reward rolls include stable `offer_weights_hash`.
- [x] Add tests that read-model output omits raw `weight` and `offer_weights_hash` while exposing `nextCombatModifierPreview`.
- [x] Add tests that telemetry payloads contain M3 required event names and selected reward fields.
- [x] Run `powershell -NoProfile -ExecutionPolicy Bypass -File tools/run-compile-check.ps1` and confirm the new tests fail before implementation.

### Task 2: Minimal Implementation

- [x] Implement cross-table validation as `RewardValidator.validate_reward_database(reward_table, rarity_table)`.
- [x] Implement `BuildRewardPreview.build(reward)` and call it from `RewardVocab.roll_stage_rewards`.
- [x] Implement a stable hash helper for offer weights without exposing raw weights to `RewardReadModel`.
- [x] Implement `BuildRewardTelemetry` for `reward_offer_generated`, `reward_selected`, and `growth_state_changed` payloads.
- [x] Add new scripts to `godot_contract_runner.gd` required script/comment lists.

### Task 3: Verification and Readiness

- [x] Run `tools/run-compile-check.ps1`.
- [x] Run `LTL-harness/tools/architectural-gate.ps1 -ManifestPath docs/architectural-gates/m2-refactoring-gate.md`.
- [x] Record remaining M3 gaps: screenshot evidence and richer reward scene polish are still manual/visual follow-up work.
