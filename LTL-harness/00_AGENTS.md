# LTL 워크플로우 진입점 (00_AGENTS.md)

Looting The Leviathan의 프로젝트 하네스입니다. 모든 에이전트와 구현자는 Prototype-First, Test-Driven Development, 재현 가능한 로그 기반 검증을 기본 전제로 작업합니다.

## Workflow Gates

1. **Context Gate**: `기획서v0.2.md`, `구현기획서_Godot_TDD.md`, `docs/00_PRODUCT_SENSE.md`를 먼저 확인합니다.
2. **Environment Gate**: 로컬 실행 파일 경로나 셸 차이가 필요한 작업이면 `docs/15_pc-environment/01_local_toolchain.youngsoon.md`를 먼저 확인합니다.
3. **Reference Gate**: `docs/14_references/`를 통해 뱀파이어 서바이벌의 보상 쾌감, 백팩 배틀즈의 배치 시너지, 슬롯머신식 기대감 중 현재 작업이 어느 감각을 건드리는지 명시합니다.
4. **Spec Gate**: `docs/12_product-specs/`에서 전투, 인벤토리, 성장, 서사의 원천 규칙을 확인합니다.
5. **Architecture Gate**: `docs/02_DESIGN.md`, `docs/03_TECH_STACK.md`, `docs/07_TEST_DRIVEN_DEV.md`를 기준으로 도메인/데이터/뷰 경계를 정합니다.
6. **Milestone Gate**: `docs/11_exec-plans/01_active/`에서 현재 단계 하나만 선택합니다. 선행 단계 완료 기준이 불명확하면 구현하지 말고 해당 기준을 먼저 보완합니다.
7. **Verification Gate**: 구현 후 `docs/08_QUALITY_ASSURANCE.md`와 `docs/10_OPERATIONS.md`의 리플레이/텔레메트리 기준으로 검증합니다.

## 에이전트 작업 규칙

- 기획 변경과 구현 변경을 섞지 않습니다. 밸런스 수치를 바꿔야 하면 변경 이유와 기대 효과를 문서에 남깁니다.
- P0~P4에서는 화면보다 headless 재현성을 우선합니다.
- 로컬 툴체인 경로를 추측하지 않습니다. 필요한 경로는 `docs/15_pc-environment/`에서 먼저 찾고, 없으면 해당 문서를 먼저 갱신합니다.
- 도메인 규칙은 가능한 한 `RefCounted` 순수 로직으로 작성하고, `Node` 의존은 컨트롤러/뷰 계층에 둡니다.
- 모든 난수는 seed로 주입합니다. `randf()` 같은 전역 난수 직접 사용은 금지합니다.
- 사용자의 체감 검증이 필요한 항목도 먼저 로그 지표를 정의합니다.
- 실패 테스트 없이 핵심 도메인 구현을 추가하지 않습니다.
- TODO만 남긴 문서를 완료로 취급하지 않습니다.

## Definition of Ready

- 작업할 마일스톤 문서에 목표, 산출물, TDD 대상, 완료 기준이 있다.
- 참조할 제품 사양 문서가 명시되어 있다.
- 로컬 툴 의존 작업이면 `docs/15_pc-environment/`에 실제 경로/버전 문서가 있다.
- 새 데이터 필드가 필요하면 JSON 스키마와 기본값이 정의되어 있다.
- 검증 명령 또는 수동 QA 절차가 정해져 있다.

## Definition of Done

- 해당 단계의 GUT 단위/통합 테스트가 통과한다.
- 동일 seed와 동일 input log로 결과가 재현된다.
- 텔레메트리 필수 필드가 누락되지 않는다.
- 다음 단계가 참조할 계약이 문서화되어 있다.
