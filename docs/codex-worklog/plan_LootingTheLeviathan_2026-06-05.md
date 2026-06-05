# Codex Worklog Plan

Workspace: LootingTheLeviathan
Date: 2026-06-05

## Active Work

M6 와이어프레임 시안 작업을 런 전체 페이지 계약 재설계까지 확장하고, 승인된 `Phase-first page shell` 구조를 별도 spec으로 고정한다.

## Request Summary

사용자가 전투 HUD가 설정/유물도감과 같은 전역 메타 패널과 충돌하는지 검토하고, 전투를 제외한 런 전체 인터페이스를 페이지 단위로 재조정해 달라고 요청했다. 또한 현재 승인된 페이지 계약 내용을 별도 문서로 저장하고, 이후 HTML 목업 생성 계획과 하네스 설계 수정 방향까지 함께 정리해야 한다.

## Scope

- `docs/superpowers/specs` 아래에 별도 페이지 계약 spec 작성
- 전투 HUD와 설정/도감 패널의 구조적 충돌 분석 정리
- `run_start`부터 `defeat`까지 페이지 계약, 전역 오버레이 정책, HTML 목업 대상 범위 정의
- 하네스 설계를 `page contract` 중심으로 재정의
- 오늘 worklog의 plan/history/complete를 현재 요청에 맞게 갱신

## Out of Scope

- 실제 HTML 목업 구현
- Godot 런타임 코드 수정
- 하이파이 아트 시안 제작
- 전투 페이지 HTML 구현

## Steps

- 현재 Main shell, PhaseLayoutPresenter, NodeMapScene, layout audit contract를 기준으로 구조 충돌과 하네스 현황을 다시 확인한다.
- 승인된 `Phase-first page shell`과 9개 페이지 계약을 별도 spec으로 작성한다.
- HTML 목업 대상/미대상 페이지와 harness 수정 방향을 문서에 고정한다.
- spec을 self-review해서 모호성, 누락, stale scope를 제거한다.
- 사용자에게 새 spec 파일 리뷰를 요청한다.

## Expected Outputs

- `docs/superpowers/specs/2026-06-05-m6-wireframe-mockups-design.ko.md`
- `docs/superpowers/specs/2026-06-05-phase-first-page-shell-contract-design.ko.md`
- 갱신된 2026-06-05 worklog 문서들

## Verification Method

- spec 파일 존재와 내용 점검
- worklog 파일 갱신 확인
- `git diff --check`로 문서 편집의 공백/포맷 이상 여부 확인

## Plan Change Log

- 2026-06-05: Worklog bootstrapped automatically by Codex hook.
- 2026-06-05: M6 HTML 시안 요청을 반영해 분리형 와이어프레임 목업 spec 작성과 리뷰 게이트로 계획을 구체화함.
- 2026-06-05: 전투 외 런 전체 인터페이스를 페이지 단위로 재설계하는 요청을 반영해 별도 page-shell contract spec 작성 작업으로 범위를 확장함.
