# AGENT-HARNESS

기존 하네스를 그대로 복사한 디렉토리가 아니라, 비교를 위해 구조를 재정리한 "개선안 버전"이다.

이 버전의 핵심 변화:

- 루트 규칙 문서는 짧고 명확한 목차 역할에 집중한다.
- 프로젝트 기획 입력은 `docs/09_PROJECT_INTAKE.md`에서 먼저 받는다.
- 기능 명세와 실행 계획을 분리해 `기획 -> 명세 -> 구현 계획 -> 구현` 흐름을 명확히 한다.
- 배포와 운영을 분리해, 릴리스 준비와 운영 대응이 한 문서에 섞이지 않도록 한다.
- 로컬 PC 전용 정보는 `docs/15_pc-environment/`로 격리하고, 로컬 툴체인 의존 작업은 이 문서 없이는 시작하지 않는다.
- 외부 레퍼런스 폴더는 단일 인덱스 파일만 사용한다.
- 반복 위반은 장문 규칙보다 체크리스트와 자동화 후보로 관리한다.

왜 `15_pc-environment`가 자주 빠졌는가:

- 기존 읽기 순서에 포함되지 않아 초기에 열리지 않았다.
- intake 문서에 환경 의존성 확인 칸이 없어 "필수 정보"로 취급되지 않았다.
- active plan 템플릿이 입력 문서 목록에 환경 문서를 요구하지 않았다.
- 프로젝트 하네스로 전환할 때 폴더가 선택적으로만 복사되어도 흐름상 막히지 않았다.

이제부터의 권장 읽기 순서:

1. `00_AGENTS.md`
2. `docs/09_PROJECT_INTAKE.md`
3. `docs/15_pc-environment/00_README.md`
4. `docs/15_pc-environment/01_toolchain-paths._template.md`
5. `docs/12_product-specs/00_index.md`
6. `docs/11_exec-plans/01_active/_TEMPLATE-active.md`
7. `01_ARCHITECTURE.md`
8. `docs/00_PRODUCT_SENSE.md`
9. `docs/01_PLANS.md`
10. `docs/07_TESTING.md`
11. `docs/08_DEPLOYMENT.md`
12. `docs/09_OPERATIONS.md`
