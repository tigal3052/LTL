# Codex Worklog Plan

Workspace: LootingTheLeviathan
Date: 2026-06-05

## Active Work

승인된 `Phase-first page shell` 계약을 기준으로 HTML 목업 6종과 page-contract 기반 하네스 설계 문서를 구현하기 위한 실행 계획을 작성한다.

## Request Summary

사용자가 별도 문서로 저장된 페이지 계약을 기준으로 다음 단계를 수행해 달라고 요청했다. 이번 단계에서는 `run_start`, `node_select`, `reward_claim`, `event_node`, `boss_reward_pick`, `defeat` HTML 목업 구현과, `combat/reward_reveal/boss_combat` 비구현 페이지를 전제로 한 page-contract 하네스 설계 계획을 실제 실행 계획 문서로 정리해야 한다.

## Scope

- `docs/superpowers/plans` 아래에 HTML 목업 + 하네스 설계 구현 계획 작성
- 계획 안에서 HTML 6종의 파일 경로, 구성 규칙, 검증 절차 고정
- page-contract 하네스 설계 문서의 산출물과 후속 테스트 러너 분할 전략 고정
- 오늘 worklog의 plan/history/complete를 현재 요청에 맞게 갱신

## Out of Scope

- 이번 턴에서 실제 HTML 목업 구현
- Godot 런타임 코드 수정
- 하이파이 아트 시안 제작
- 전투 페이지 HTML 구현

## Steps

- 기존 spec 2종과 `docs/mockups` 패턴을 기준으로 구현 계획에 필요한 파일 구조를 정리한다.
- HTML 6종과 하네스 설계 문서의 실행 계획을 `docs/superpowers/plans`에 저장한다.
- 계획을 self-review해서 placeholder, scope mismatch, 검증 누락을 제거한다.
- 필요하면 plan/worklog만 별도 commit으로 남긴다.
- 사용자에게 계획 파일을 공유하고 실행 방식 선택을 요청한다.

## Expected Outputs

- `docs/superpowers/plans/2026-06-05-phase-first-page-shell-wireframes-and-harness-plan.md`
- 갱신된 2026-06-05 worklog 문서들

## Verification Method

- spec 파일 존재와 내용 점검
- worklog 파일 갱신 확인
- `git diff --check`로 문서 편집의 공백/포맷 이상 여부 확인

## Plan Change Log

- 2026-06-05: Worklog bootstrapped automatically by Codex hook.
- 2026-06-05: M6 HTML 시안 요청을 반영해 분리형 와이어프레임 목업 spec 작성과 리뷰 게이트로 계획을 구체화함.
- 2026-06-05: 전투 외 런 전체 인터페이스를 페이지 단위로 재설계하는 요청을 반영해 별도 page-shell contract spec 작성 작업으로 범위를 확장함.
- 2026-06-05: 사용자의 수행 요청에 따라 HTML 6종과 하네스 설계 문서의 구현 순서를 고정하는 실행 계획 작성 단계로 전환함.
