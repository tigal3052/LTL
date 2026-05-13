# Codex Worklog Plan

Workspace: LootingTheLeviathan
Date: 2026-05-13

## Active Work

`LTL-harness`와 `agent-harness`에 로컬 PC 환경 문서 흐름을 고정하고, 실제 툴체인 경로/버전 문서를 작성해 이후 세션에서 바로 참조 가능하게 만든다.

## Request Summary

매 실행마다 Godot 경로를 다시 찾는 문제를 막기 위해 `LTL-harness/docs/15_pc-environment`를 실제 내용으로 채우고, `agent-harness`가 프로젝트 전용 하네스로 전환될 때 이 폴더를 필수로 작성·참조하도록 수정한다.

## Scope

- `LTL-harness/docs/15_pc-environment/`에 실제 로컬 툴체인 문서를 만든다.
- `agent-harness`의 README, AGENTS, intake, active template, environment README를 수정해 환경 문서가 게이트에 걸리도록 만든다.
- 이후 프로젝트 전환 시 복사/작성/참조 흐름이 빠지지 않도록 템플릿 문서를 추가한다.
- 변경 이유와 검증 결과를 worklog에 남긴다.

## Out of Scope

- Godot 엔진 크래시 자체 수정
- P3 이후 게임플레이 구현
- 외부 도구 설치 또는 환경변수 재구성

## Steps

- `agent-harness`의 `15_pc-environment` 관련 템플릿과 게이트 누락 지점을 찾는다.
- 실제 로컬 툴체인 경로와 버전을 수집한다.
- `LTL-harness/docs/15_pc-environment/`에 즉시 사용 가능한 환경 문서를 작성한다.
- `agent-harness` 문서를 수정해 환경 문서가 필수 입력/참조로 남도록 만든다.
- 수정 결과를 재검색하고 worklog를 갱신한다.

## Expected Outputs

- `LTL-harness/docs/15_pc-environment/*`
- `agent-harness/docs/15_pc-environment/01_toolchain-paths._template.md`
- `agent-harness/README.md`
- `agent-harness/00_AGENTS.md`
- `agent-harness/docs/09_PROJECT_INTAKE.md`
- `agent-harness/docs/11_exec-plans/01_active/_TEMPLATE-active.md`
- `docs/codex-worklog/history_LootingTheLeviathan_2026-05-13.md`
- `docs/codex-worklog/complete_LootingTheLeviathan_2026-05-13.md`

## Verification Method

- 환경 문서 파일 존재와 하네스 참조 경로를 `rg`로 확인한다.
- 실제 툴체인 버전/경로 수집 명령 출력과 문서 내용을 대조한다.
- 수정된 템플릿이 입력 문서와 Ready 체크에 환경 문서를 요구하는지 직접 확인한다.

## Plan Change Log

- 2026-05-13: 사용자 요청에 따라 P0/P1/P2 검증, P2 구현, `11_exec-plans` 완료 문서 보강 작업으로 계획을 전환.
- 2026-05-13: 사용자 요청에 따라 로컬 PC 환경 문서 체계와 `15_pc-environment` 필수 흐름 보강 작업으로 계획을 전환.
- 2026-05-13: `app-LTL/public/index.html`에서 캐릭터, 가방 그리드, 표면 그리드가 viewport height 안에 모두 보이도록 CSS 레이아웃 조정 작업을 추가.

- 2026-05-13: Worklog bootstrapped automatically by Codex hook.
- 2026-05-13: LTL-harness 문서 보강 작업 계획 작성.
- 2026-05-13: `app-LTL` P0/P1 테스트 가능 골격 구축 계획으로 갱신.
