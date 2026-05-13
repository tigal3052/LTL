# TESTING.md

> 테스트 기준과 검증 원칙.
> 특정 OS나 특정 스크립트는 "예시 구현"으로만 적고, 범용 규칙을 먼저 둔다.

---

## Core Rules

- 테스트 없는 변경은 완료로 보지 않는다.
- 테스트는 구현 세부보다 사용자 관점의 동작을 우선 검증한다.
- 새 기능은 자동 검증과 수동 검증 범위를 구분해 기록한다.

---

## Verification Layers

| Layer | Goal | Required |
|------|------|----------|
| Unit | 순수 로직 검증 | 기본 |
| Integration | 모듈 간 연결 검증 | 권장 |
| E2E | 핵심 사용자 플로우 검증 | 핵심 기능 필수 |
| Manual | 기기/브라우저/권한/운영 확인 | 필요 시 |

---

## Minimum Done Criteria

- [ ] 관련 테스트 추가 또는 기존 테스트 보강
- [ ] 실패 경로 검증
- [ ] 문서/설정 변경이 있으면 그에 맞는 검증 포함
- [ ] 배포 전 핵심 플로우 확인

---

## Backend Control Policy

백엔드가 있는 프로젝트는 서버 제어 스크립트를 둘 수 있다. 단, 아래 원칙을 먼저 따른다.

- 스크립트 경로와 실행법은 프로젝트별 문서에 기록한다.
- 특정 OS 전용 스크립트는 기본 규칙이 아니라 구현 예시로 둔다.
- `start`, `stop`, `restart`, `status` 같은 공통 인터페이스를 권장한다.

예시:

```text
scripts/backend.ps1
scripts/backend.sh
make backend-start
```

---

## CI Expectations

- PR 기준 자동 테스트 실행
- 실패 시 머지 차단
- 보안/타입/린트 체크와 테스트를 릴리스 게이트에 포함
- 필요 시 스테이징 E2E 실행

---

## Manual Verification Template

| Scenario | Preconditions | Steps | Expected |
|----------|---------------|-------|----------|
| `<!-- SLOT -->` | `<!-- SLOT -->` | `<!-- SLOT -->` | `<!-- SLOT -->` |
