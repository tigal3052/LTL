# Codex Worklog Plan

Workspace: LootingTheLeviathan
Date: 2026-06-05

## Active Work

M6 구현 예정사항을 설명하는 분리형 HTML 와이어프레임 시안의 디자인 명세를 확정하고, 구현 전 리뷰 게이트를 통과할 준비를 한다.

## Request Summary

사용자가 M6 구현 예정사항을 HTML 시안으로 보고 싶어 한다. 우선 하이파이보다 와이어프레임 중심으로 가고, `전투 HUD`, `노드맵+보상`, `백팩 정리`를 각각 별도 목업으로 만들며, 각 목업에는 구현 포인트 주석을 포함한다.

## Scope

- `docs/superpowers/specs` 아래에 와이어프레임 목업 디자인 spec 작성
- 화면 분리 원칙, HTML 파일명, 공통 레이아웃 구조, 화면별 포함 요소 정의
- 오늘 worklog의 plan/history/complete를 현재 요청에 맞게 갱신

## Out of Scope

- 실제 HTML 목업 구현
- Godot 런타임 코드 수정
- 하이파이 아트 시안 제작

## Steps

- 현재 목업 문서 패턴과 M6 refresh plan 기준점을 다시 확인한다.
- 승인된 방향을 정리한 와이어프레임 디자인 spec을 작성한다.
- spec을 self-review해서 모호성, 누락, 범위 이탈이 없는지 확인한다.
- 사용자에게 spec 파일 리뷰를 요청하고, 승인 후 HTML 구현 단계로 넘긴다.

## Expected Outputs

- `docs/superpowers/specs/2026-06-05-m6-wireframe-mockups-design.ko.md`
- 갱신된 2026-06-05 worklog 문서들

## Verification Method

- spec 파일 존재와 내용 점검
- worklog 파일 갱신 확인
- `git diff --check`로 문서 편집의 공백/포맷 이상 여부 확인

## Plan Change Log

- 2026-06-05: Worklog bootstrapped automatically by Codex hook.
- 2026-06-05: M6 HTML 시안 요청을 반영해 분리형 와이어프레임 목업 spec 작성과 리뷰 게이트로 계획을 구체화함.
