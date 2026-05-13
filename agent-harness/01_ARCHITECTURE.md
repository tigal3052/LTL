# ARCHITECTURE.md

> 프로젝트 구조를 빠르게 이해하기 위한 요약 문서.
> 로컬 머신 특이사항은 이 문서에 적지 않고 `docs/15_pc-environment/`로 분리한다.

---

## Overview

<!-- SLOT: 프로젝트가 해결하는 문제와 주요 사용자 -->

---

## System Boundaries

- 제품이 직접 책임지는 영역: `<!-- SLOT -->`
- 외부 서비스에 위임하는 영역: `<!-- SLOT -->`
- 현재 범위에서 제외하는 영역: `<!-- SLOT -->`

---

## Tech Stack

| Layer | Choice | Why |
|------|--------|-----|
| Frontend | `<!-- SLOT -->` | |
| Backend | `<!-- SLOT -->` | |
| Database | `<!-- SLOT -->` | |
| Queue / Async | `<!-- SLOT or N/A -->` | |
| Infra | `<!-- SLOT -->` | |
| CI/CD | `<!-- SLOT -->` | |
| Observability | `<!-- SLOT -->` | |

---

## Directory Structure

```text
<!-- SLOT: 핵심 디렉토리만, 역할 중심으로 기록 -->
src/
  app/        # 진입점, 라우팅, 앱 조립
  domain/     # 핵심 비즈니스 규칙
  infra/      # DB, 외부 API, 메시징
  shared/     # 공통 유틸과 타입
tests/
scripts/
docs/
```

---

## Primary Flows

### Flow A
`사용자 입력 -> 앱/라우터 -> 서비스 -> 저장소/외부 API -> 응답`

### Flow B
`비동기 이벤트 -> 작업 큐 -> 워커 -> 저장소/알림 -> 상태 업데이트`

---

## Deployment Topology

- 실행 단위: `<!-- SLOT: monolith / frontend+api / worker 분리 등 -->`
- 환경: `local / dev / staging / production`
- 배포 단위: `<!-- SLOT: container / serverless / static asset 등 -->`
- 상태 저장 위치: `<!-- SLOT -->`

---

## Key Decisions

### Example Decision
- 선택: `<!-- SLOT -->`
- 이유: `<!-- SLOT -->`
- 포기한 대안: `<!-- SLOT -->`
- 운영 영향: `<!-- SLOT -->`

---

## Constraints

- 성능 제약: `<!-- SLOT -->`
- 보안 제약: `<!-- SLOT -->`
- 데이터 보존/규제 제약: `<!-- SLOT -->`
- 팀 운영 제약: `<!-- SLOT -->`

---

## Change Log

| Date | Change | Why |
|------|--------|-----|
| — | — | — |
