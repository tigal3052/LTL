# DEPLOYMENT.md

> 구축, 배포, 릴리스 준비를 위한 기준 문서.
> 운영 중 대응은 `09_OPERATIONS.md`에서 관리한다.

---

## Principles

- 모든 배포는 가능한 한 자동화한다.
- 같은 빌드 산출물을 환경 간 승격한다.
- 환경 차이는 설정과 인프라 정의로만 관리한다.
- 배포는 롤백 가능해야 하며, DB 변경은 별도 위험 관리가 필요하다.

---

## Environment Matrix

| Env | Purpose | Data | Access | Promotion Rule |
|-----|---------|------|--------|----------------|
| local | 개발 | 샘플/목 | 개인 | 자유 |
| dev | 통합 확인 | 테스트 | 개발팀 | PR 머지 후 |
| staging | 릴리스 검증 | 프로덕션 유사 | 개발/QA | release candidate |
| production | 실서비스 | 실데이터 | 사용자 | 승인된 릴리스만 |

---

## Build And Release Gates

```text
commit / PR
  -> lint + typecheck
  -> unit/integration tests
  -> security scan
  -> build artifact
  -> deploy to staging
  -> E2E / smoke test
  -> release approval
  -> production deploy
  -> post-deploy monitoring
```

---

## Deployment Strategy

| Strategy | When To Use | Notes |
|----------|-------------|-------|
| Rolling | 단순 서비스, 짧은 재시작 허용 | 가장 기본 |
| Blue-Green | 빠른 전환과 즉시 롤백이 중요할 때 | 비용 증가 가능 |
| Canary | 대규모 사용자, 점진 노출이 필요할 때 | 모니터링 필수 |

선택 전략: `<!-- SLOT -->`

---

## Infrastructure And Configuration

- 인프라 정의 위치: `<!-- SLOT: Terraform / Pulumi / console managed 등 -->`
- 애플리케이션 설정 위치: `<!-- SLOT -->`
- 시크릿 관리: `<!-- SLOT -->`
- 환경 드리프트 확인 방법: `<!-- SLOT -->`

규칙:

- `.env.example` 또는 동등한 설정 명세를 유지한다.
- 시크릿은 저장소에 커밋하지 않는다.
- 환경별 차이는 문서가 아니라 코드/설정 정의로 추적 가능해야 한다.

---

## Database And State Changes

- 마이그레이션 도구: `<!-- SLOT -->`
- 배포 전 검증: 스키마 diff, 백업 여부, 역방향 가능 여부
- 배포 후 검증: row count, 핵심 쿼리, 오류율

체크리스트:

- [ ] 마이그레이션이 버전 관리된다
- [ ] 백업 또는 스냅샷이 준비되어 있다
- [ ] 애플리케이션과 하위 호환 여부를 검토했다
- [ ] 롤백 또는 2단계 배포 전략이 있다

---

## Release Checklist

- [ ] 릴리스 오너가 지정되었다
- [ ] 승인자가 지정되었다
- [ ] 변경 범위와 제외 범위가 공유되었다
- [ ] 테스트와 스모크 검증이 통과했다
- [ ] 모니터링 대시보드와 알림이 준비되었다
- [ ] 롤백 절차가 검증되었다
- [ ] 공지 또는 릴리스 노트가 준비되었다

---

## Rollback

### Required Inputs

- 이전 안정 버전 식별자
- 되돌릴 아티팩트 위치
- DB/state 되돌림 가능 여부
- 롤백 책임자

### Basic Procedure

```text
1. 문제 감지
2. 영향도 판단
3. 기능 플래그 off 또는 트래픽 축소
4. 이전 버전으로 롤백
5. 헬스체크 및 핵심 지표 확인
6. 사고 기록 및 재배포 조건 정리
```

---

## Open Decisions

- `<!-- SLOT -->`
