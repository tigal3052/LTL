# LTL-Harness

Looting The Leviathan 프로젝트를 위한 특화 구현 하네스입니다. 이 하네스의 목적은 기획 아이디어를 바로 코드로 흘려보내는 것이 아니라, Godot 프로토타입에서 검증할 계약, 테스트, 로그, 단계별 산출물을 고정하는 것입니다.

## 빠른 진입 순서

1. `00_AGENTS.md`에서 작업 게이트와 금지사항을 확인합니다.
2. `docs/00_PRODUCT_SENSE.md`에서 LTL의 재미 기준을 확인합니다.
3. `docs/12_product-specs/`에서 구현할 규칙의 원천 사양을 확인합니다.
4. `docs/15_pc-environment/`에서 로컬 PC 전용 툴체인 경로와 셸 주의사항을 먼저 확인합니다.
5. `docs/02_DESIGN.md`, `docs/03_TECH_STACK.md`, `docs/07_TEST_DRIVEN_DEV.md`를 읽고 Godot/TDD 경계를 맞춥니다.
6. `docs/11_exec-plans/01_active/`에서 현재 마일스톤 하나를 골라 실패 테스트부터 작성합니다.

## 현재 구현 기준

- 엔진: Godot 4.3 이상
- 언어: GDScript
- 테스트: GUT
- 핵심 구조: `prototype/domain`, `prototype/data`, `prototype/telemetry`, `tests/unit`, `tests/integration`
- 우선순위: 재현 가능한 순수 로직 > 로그/리플레이 > 플레이 가능한 화면 > 장기 콘텐츠
- 로컬 툴체인 참조: `docs/15_pc-environment/01_local_toolchain.youngsoon.md`

## 핵심 원칙

LTL의 MVP는 출시 가능한 최소 게임이 아니라 `Minimum Viable Prototype`입니다. P0~P4에서는 3x10 파동 타겟팅, 에너지 큐, 장비 배치, 4핀 시간 압박, 수리/방해 요소가 정말 재미와 긴장을 만드는지를 검증합니다. 정식 구현(M0~M9)은 검증된 도메인 계약을 유지하면서 화면, 성장, 노드, 내러티브, 릴리즈 품질을 확장합니다.
