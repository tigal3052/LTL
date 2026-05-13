# AGENTS.md

> 이 디렉토리의 범용 하네스 규칙.
> 이 파일은 세부 규칙집이 아니라 "작업 순서와 문서 지도"에 집중한다.

---

## Core Principles

### 1. 먼저 구조를 파악한다
- 구현 전에 현재 구조, 기존 패턴, 영향 범위를 확인한다.
- 구조 파악 없이 바로 코드를 쓰지 않는다.

### 2. 계획을 승인받고 실행한다
- 수정 전 반드시 변경 파일, 검증 방법, 가정을 포함한 계획을 먼저 보여준다.
- 가정이 있으면 명시하고 승인받는다.

### 3. 문서는 계층별로 분리한다
- 이 파일: 범용 규칙과 문서 흐름
- `01_ARCHITECTURE.md`: 프로젝트 기술 구조
- `docs/09_PROJECT_INTAKE.md`: 기획 입력과 필수 확인 항목
- `docs/12_product-specs/`: 기능 단위 명세
- `docs/11_exec-plans/`: 실제 구현 단위 실행 계획과 완료 기록
- `docs/15_pc-environment/`: 특정 개발 PC 전용 정보

### 3-1. 로컬 툴체인 의존 작업은 환경 문서를 먼저 만든다
- 절대 경로, 특정 SDK, 특정 셸 동작, 로컬 설치 프로그램에 의존하면 `docs/15_pc-environment/` 문서를 먼저 작성한다.
- `docs/15_pc-environment/`에 실제 경로/버전/실행 명령이 없으면 해당 작업은 Ready 상태가 아니다.
- 프로젝트 전용 하네스로 전환할 때도 이 폴더를 함께 복사하고, 프로젝트명에 맞는 실제 문서를 최소 1개 만든다.

### 4. 반복 실수는 자동화 후보로 올린다
- 같은 실수가 반복되면 설명을 늘리기보다 체크리스트, 테스트, 린트, 훅, CI로 승격한다.

### 5. 범용 템플릿과 예시는 구분한다
- 샘플 값은 "예시"로 표시한다.
- 프로젝트 확정값은 `PROJECT-SPECIFIC` 또는 체크리스트 승인 후 채운다.

---

## Start Here

새 프로젝트 또는 큰 변경은 아래 순서로 진행한다:

```text
1. docs/09_PROJECT_INTAKE.md
2. 로컬 툴 의존성이 있으면 docs/15_pc-environment/00_README.md 와 실제 환경 문서 작성
3. docs/12_product-specs/00_index.md 또는 기능 명세 작성
4. 01_ARCHITECTURE.md
5. docs/00_PRODUCT_SENSE.md
6. docs/01_PLANS.md
7. docs/14_references/00_README.md
8. docs/11_exec-plans/01_active/_TEMPLATE-active.md 기반 실행 계획 작성
9. 구현
10. docs/07_TESTING.md / docs/08_DEPLOYMENT.md / docs/09_OPERATIONS.md 기준 검증
11. docs/11_exec-plans/02_completed/에 완료 기록
```

---

## Document Structure

```text
AGENT-HARNESS2/
├── README.md
├── 00_AGENTS.md
├── 01_ARCHITECTURE.md
└── docs/
    ├── 00_PRODUCT_SENSE.md
    ├── 01_PLANS.md
    ├── 02_DESIGN.md
    ├── 07_TESTING.md
    ├── 08_DEPLOYMENT.md
    ├── 09_PROJECT_INTAKE.md
    ├── 09_OPERATIONS.md
    ├── 11_exec-plans/
    │   ├── 00_tech-debt-tracker.md
    │   ├── 01_active/
    │   │   └── _TEMPLATE-active.md
    │   └── 02_completed/
    │       └── _TEMPLATE-completed.md
    ├── 12_product-specs/
    │   └── 00_index.md
    ├── 14_references/
    │   └── 00_README.md
    └── 15_pc-environment/
        └── 00_README.md
```

---

## Workflow Gates

### Intake Gate
- 문제 정의, 목표, 제외 범위, 승인자, 성공 기준이 없으면 구현하지 않는다.

### Planning Gate
- `docs/09_PROJECT_INTAKE.md`의 Ready Check 충족
- 로컬 툴체인 의존 작업이면 `docs/15_pc-environment/`에 실제 문서 존재
- 필요한 경우 `docs/12_product-specs/`에 기능 명세 존재
- `docs/11_exec-plans/01_active/`에 기능 단위 실행 계획 생성
- 수정 대상 파일
- 파일별 변경 내용
- 검증 단계
- 가정 및 미결정 항목

### Release Gate
- 테스트 기준 충족
- 배포 전략 명시
- 롤백 경로 확인
- 운영 모니터링 준비 완료

---

## Out Of Scope Without Approval

- 데이터 모델 또는 DB 스키마 대규모 변경
- 인증/인가 정책 변경
- 외부 결제/정산/개인정보 흐름 변경
- 운영비에 큰 영향을 주는 인프라 선택
- 법적/규제 대응 방식 확정

---

## Notes

- 로컬 PC 경로, 개인 툴체인, 특정 IDE 설정은 이 파일에 쓰지 않는다.
- 대신 `docs/15_pc-environment/`에 적고, 실행 계획과 완료 문서에서 해당 파일을 직접 참조한다.
- 외부 참고자료는 `docs/14_references/`에만 둔다.
- 디자인 방향이 아직 확정되지 않았다면 `docs/02_DESIGN.md`는 예시가 아니라 선택지 수준으로 유지한다.
- 구현 단위 작업은 `docs/11_exec-plans/01_active/` 없이 시작하지 않는다.
