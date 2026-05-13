# OPERATIONS.md

> 서비스 운영, 관측성, 장애 대응 기준.
> 배포 절차는 `08_DEPLOYMENT.md`, 운영 상태 관리는 이 문서에서 다룬다.

---

## Operations Goals

- 운영 목표 시간대: `<!-- SLOT -->`
- 지원 수준: `<!-- SLOT: 업무시간 / 24x7 / 베스트에포트 -->`
- 허용 가능한 장애 영향: `<!-- SLOT -->`

---

## Observability Baseline

세 가지를 기본으로 갖춘다:

- Metrics: 지연시간, 에러율, 처리량, 자원 사용량
- Logs: 구조화 로그, correlation ID, 민감정보 제거
- Traces: 주요 요청 흐름 추적

도구:

- Metrics: `<!-- SLOT -->`
- Logs: `<!-- SLOT -->`
- Traces: `<!-- SLOT -->`

---

## SLI / SLO

| SLI | Target SLO | Why |
|-----|------------|-----|
| API availability | `<!-- SLOT -->` | |
| API latency p95 | `<!-- SLOT -->` | |
| Job success rate | `<!-- SLOT -->` | |
| Error budget burn | `<!-- SLOT -->` | |

---

## Alert Severity

| Severity | Meaning | Example Response |
|----------|---------|------------------|
| Sev1 | 전체 서비스 장애 또는 데이터 손상 위험 | 즉시 대응, 상황실 |
| Sev2 | 핵심 기능 장애, 많은 사용자 영향 | 우선 대응 |
| Sev3 | 부분 장애 또는 성능 저하 | 근무시간 내 대응 |
| Sev4 | 정보성 또는 장기 개선 항목 | 백로그 관리 |

---

## On-Call And Escalation

- 1차 대응자: `<!-- SLOT -->`
- 2차 에스컬레이션: `<!-- SLOT -->`
- 제품/사업 커뮤니케이션 담당: `<!-- SLOT -->`
- 외부 공지 채널: `<!-- SLOT -->`

---

## Incident Workflow

```text
1. Detect
2. Triage
3. Mitigate
4. Resolve
5. Communicate
6. Review
```

필수 기록:

- 시작 시각
- 감지 경로
- 영향 범위
- 임시 조치
- 근본 원인
- 재발 방지 조치

---

## Runbook Checklist

- [ ] 헬스체크 엔드포인트
- [ ] 로그 조회 방법
- [ ] 주요 대시보드 링크
- [ ] 기능 플래그 위치
- [ ] 롤백 절차 링크
- [ ] 데이터 복구 절차
- [ ] 연락망

---

## Cost And Usage Monitoring

다음 중 해당하는 항목을 추적한다:

- 외부 API 사용량/비용
- 토큰 사용량
- 큐 적체량
- 스토리지 증가량
- 캐시 적중률

---

## Postmortem Rule

- Sev1, Sev2는 회고 문서를 남긴다.
- 회고는 개인 비난이 아니라 시스템 개선 중심으로 작성한다.
- 반복 이슈는 문서 보강이 아니라 자동화/검증 강화로 연결한다.
