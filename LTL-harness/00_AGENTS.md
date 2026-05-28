# LTL 워크플로우 진입점 (00_AGENTS.md)

Looting The Leviathan의 프로젝트 하네스입니다. 모든 에이전트와 구현자는 Prototype-First history를 참고하되, 현재 구현은 Test-Driven Development와 재현 가능한 로그 기반 검증을 바탕으로 정식 경로에만 반영합니다.

## 1. 비가역 규칙

### SoT
- 모든 핵심 규칙은 반드시 하나의 **단일 진실 소스(Single Source of Truth, SoT)** 에만 존재해야 합니다.
- UI, 테스트, 디버그, 어댑터, 임시 스크립트는 SoT를 재구현하면 안 됩니다.
- 같은 규칙이 두 곳에 있으면 하나를 SoT로 지정하고, 나머지는 그것을 호출하거나 참조하도록 정리합니다.
- SoT는 코드뿐 아니라 규칙 설명과 주석에도 적용합니다.
- LTL의 도메인 규칙 SoT는 `app-LTL/src/domain/**` 또는 해당 exec-plan에서 명시한 정식 도메인 경로에 둡니다.
- `app-LTL/prototype/**`는 보존된 참조 아카이브입니다. 더 이상 구현 대상이 아니며, 사용자가 prototype 수정 자체를 명시적으로 승인한 경우에만 편집할 수 있습니다.
- prototype 코드는 계약 추출, 리플레이 비교, 시각 연출 참고를 위한 읽기 전용 자료입니다. 정식 규칙, 정식 UI, 정식 scene 구현은 `app-LTL/src/**` 또는 별도로 지정된 정식 경로에만 둡니다.

### 경로 선택 우선순위
- 구현 시작 전 반드시 이번 작업의 수정 대상 경로를 한 줄로 선언합니다.
- 경로 결정 우선순위는 `app-LTL/src/README.md` -> `docs/11_exec-plans/01_active/**` -> `docs/02_DESIGN.md` -> completed milestone report 순서입니다.
- 활성 계획에 `formal`, `stabilized`, `promoted`, `production-path`, `scene reconstruction`, `정식`, `승격` 같은 표현이 있으면 기본 대상은 `app-LTL/src/**` 또는 해당 정식 경로입니다.
- completed milestone report의 prototype 이력은 참고 근거일 뿐 현재 구현 경로를 뒤집을 수 없습니다.
- scene, HUD, 입력 어댑터, read-model, process wiring 작업도 사용자가 따로 prototype 유지보수를 지시하지 않는 한 정식 경로에 구현합니다.
- prototype 경로를 수정해야 한다고 판단되면 근거 문서와 위험을 먼저 적고 사용자 승인 없이 진행하지 않습니다.

### 논리기반 프로그래밍
- LTL 구현은 반드시 `1. 설계기반 주석 작성 -> 2. 실행 문장 주석 작성 -> 3. 주석기반 프로그래밍 구현` 순서로 진행합니다.
- 1단계 설계기반 주석은 파일 구조, 모듈 책임, SoT 경계, 입력/출력 계약, 참조 원형, 금지 의존성을 정리합니다.
- 1단계 설계기반 주석은 코딩을 시작하기 위한 구조 설계일 뿐이며, 구현 완료나 구현 준비로 취급하지 않습니다.
- 2단계 실행 문장 주석은 설계기반 주석을 함수 본문 안에서 실행 가능한 작은 문장으로 다시 번역한 것입니다.
- 실행 문장 주석은 `입력/대상/조건/동작/결과` 중 구현에 필요한 요소를 포함해야 합니다.
- 하나의 실행 문장 주석은 바로 아래 코드 한 줄 또는 하나의 들여쓰기 블록으로 번역 가능해야 합니다.
- 주석 한 줄을 구현하려면 여러 독립 판단이 필요할 때, 그 주석은 너무 큽니다. 더 작은 실행 문장 주석으로 쪼갭니다.
- 3단계 주석기반 프로그래밍 구현에서는 모든 구현 코드가 바로 위 실행 문장 주석을 기계적으로 번역한 결과여야 합니다.
- 큰 함수는 허용되지만, 함수 본문은 실행 문장 주석과 그 바로 아래 구현 블록의 반복으로만 구성합니다.
- 각 작은 함수는 최종적으로 하나의 실행 문장을 수행하는 단위가 되어야 하며, 함수 이름도 그 실행 문장과 같은 의미여야 합니다.
- 권장 순서: `설계기반 주석 -> 검증 테스트 -> 실행 문장 주석 -> 코드 블록 -> 호출 중심 주석 -> 상위 조립`
- UI는 실행 문장을 수행하지 않고, 실행 문장을 가진 도메인 함수에 명령을 전달하고 결과를 표시합니다.
- LTL 도메인은 사실(fact), 규칙(rule), 질의(query), 전이(transition), 스냅샷(snapshot)을 먼저 설계기반 주석으로 배치한 뒤 실행 문장 주석으로 쪼갭니다.
- seed, input log, node table, artifact table, tuning 값은 모두 명시적 사실로 주입하고 전역 상태로 숨기지 않습니다.
- 설계기반 주석만 보고 구현을 시작하면 안 됩니다. 반드시 실행 문장 주석으로 변환한 뒤 구현합니다.
- 실행 문장 주석만 보고도 같은 코드를 다시 작성할 수 없다면 그 주석은 구현 주석이 아니라 설계 메모입니다.

### 주석 규칙
- 주석 규칙 SoT는 `[docs/comment-implementation-rules.md](../docs/comment-implementation-rules.md)` 입니다.
- 이 파일의 주석 규칙은 위 문서를 축약 참조하며, 충돌이 나면 항상 위 문서를 우선합니다.
- 함수 본문 안의 실행 주석은 반드시 `주석A -> 주석A 구현 -> 주석B -> 주석B 구현` 순서만 허용합니다.
- `주석A -> 주석B -> 주석A 구현 -> 주석B 구현` 형태는 금지합니다.
- 실행 주석은 반드시 바로 아래의 연속된 코드 블록 하나와만 1:1 대응해야 합니다.
- 두 개 이상의 실행 주석이 하나의 코드 블록을 공유하려 하면 블록을 쪼개거나 helper를 추출합니다.
- 기존 주석 스캐폴드가 있는 파일은 전체 교체하지 말고 부분 수정으로 구현합니다.
- 기존 주석 문장은 구현 편의 때문에 임의 삭제, 합치기, 요약하지 않습니다.

### 계획 우선
- 구현 전에 범위, SoT, 테스트 방법, 완료 기준을 먼저 문서로 고정합니다.
- 구현 중 새 결정이 생기면 코드보다 문서를 먼저 갱신합니다.
- LTL 구현 단위는 `docs/11_exec-plans/01_active/`의 활성 계획 하나와 연결되어야 합니다.
- 활성 계획이 정식 경로를 가리키면 prototype에서 먼저 만들어 본 뒤 옮기는 우회 절차를 사용하지 않습니다.

### 주석우선 강제 게이트
- 주석우선 구현 강제 규칙 SoT는 `docs/comment-first-enforcement.md`입니다.
- 이 규칙은 권장이 아니라 구현 차단 조건입니다. 런타임 테스트가 통과해도 이 게이트가 실패하면 완료가 아닙니다.
- 정식 소스 경로에 구현 코드를 쓰기 전에 반드시 comment-only 상태의 계약 주석과 실행 문장 주석을 먼저 작성합니다.
- comment-only 단계는 사용자 승인 전 구현 단계로 넘어갈 수 없습니다.
- 구현 후 주석을 맞추는 방식은 인정하지 않습니다. 그런 소스는 정식 구현으로 고치지 말고 `_quarantine_comment_first_violation_<date>/` 아래로 격리합니다.
- 구현 단계에서는 각 코드 블록 바로 위에 `실행:` 주석 하나가 있어야 하며, `주석A -> 구현A -> 주석B -> 구현B` 순서만 허용합니다.
- 구현 중 새 판단, 새 상태 변경, 새 반환이 필요해지면 코드를 쓰기 전에 실행 주석과 comment gate 기록을 먼저 갱신합니다.
- 구현 완료 전 `docs/comment-first-enforcement.md`의 하드 스톱 조건과 프로젝트별 comment gate 검증을 반드시 통과해야 합니다.

### M0 이후 Godot 정식 구현 게이트
- M0 이후 정식 구현 기술스택 강제 규칙 SoT는 `docs/post-m0-godot-enforcement.md`입니다.
- M1~M9 정식 구현은 Godot 4.3 이상, GDScript, Godot headless 또는 GUT 검증을 기본값으로 삼습니다.
- `engine-agnostic`은 Godot을 벗어나도 된다는 뜻이 아니라, Godot 안에서 도메인 로직이 SceneTree와 화면 계층에 직접 묶이지 않도록 분리한다는 뜻입니다.
- M0 이후 `app-LTL/src/**`와 `app-LTL/tests/**`에는 `.js`, `.ts`, `.html`, `.css`, `package.json`, 웹 dev server 산출물을 둘 수 없습니다.
- 활성 exec-plan이 `.js` 또는 browser/Node 산출물을 정식 구현 예시로 들면, 구현 전에 exec-plan을 Godot 산출물로 먼저 수정합니다.
- 정식 구현 전과 완료 전에는 `LTL-harness/tools/ltl-tech-stack-gate.ps1`를 통과해야 합니다. 소스가 아직 격리되어 없는 하네스 수정 작업에서만 `-AllowNoFormalSource`를 사용할 수 있습니다.
- Node/browser 테스트는 prototype 비교 근거가 될 수 있지만, M0 이후 정식 구현 완료 증거가 될 수 없습니다.

## Workflow Gates

1. **Context Gate**: `기획서v0.2.md`, `구현기획서_Godot_TDD.md`, `docs/00_PRODUCT_SENSE.md`를 먼저 확인합니다.
2. **Environment Gate**: 로컬 실행 파일 경로나 셸 차이가 필요한 작업이면 `docs/15_pc-environment/01_local_toolchain.youngsoon.md`를 먼저 확인합니다.
3. **Reference Gate**: `docs/14_references/`를 통해 뱀파이어 서바이벌의 보상 쾌감, 백팩 배틀즈의 배치 시너지, 슬롯머신식 기대감 중 현재 작업이 어느 감각을 건드리는지 명시합니다.
4. **Spec Gate**: `docs/12_product-specs/`에서 전투, 인벤토리, 성장, 서사의 원천 규칙을 확인합니다.
5. **Architecture Gate**: `docs/02_DESIGN.md`, `docs/03_TECH_STACK.md`, `docs/07_TEST_DRIVEN_DEV.md`를 기준으로 도메인/데이터/뷰 경계를 정합니다.
6. **Milestone Gate**: `docs/11_exec-plans/01_active/`에서 현재 단계 하나만 선택하여 작업을 시작하기 전, 반드시 `LTL-harness/tools/milestone-gate.ps1 -TargetPlan <계획파일명>`을 실행하여 이전 단계의 완료 보고서가 `docs/11_exec-plans/02_completed/`에 정상적으로 작성되어 존재하는지 검증해야 합니다. 이 검증에 실패할 경우, 즉시 구현을 중단하고 소스를 분석하여 이전 단계의 완료 보고서를 먼저 작성한 뒤 사용자의 승인을 얻어야 합니다.
7. **Verification Gate**: 구현 후 `docs/08_QUALITY_ASSURANCE.md`와 `docs/10_OPERATIONS.md`의 리플레이/텔레메트리 기준으로 검증합니다.

## Document Structure

Looting The Leviathan 작업자는 아래 지도를 기준으로 빠르게 문서를 찾습니다. 범용 하네스의 문서 이름과 완전히 일치하지 않는 항목은 LTL 현재 구조에 맞춘 최신 경로를 우선합니다.

```text
LTL-harness/
├── README.md                                  # LTL 하네스 사용법과 프로젝트 진입 안내
├── 00_AGENTS.md                               # LTL 작업 규칙, SoT, 주석, 논리기반 프로그래밍 기준
└── docs/
    ├── 00_PRODUCT_SENSE.md                    # LTL의 핵심 재미, 제품 감각, 판단 기준
    ├── 01_PLANS.md                            # 로드맵과 계획 요약
    ├── 02_DESIGN.md                           # 도메인/데이터/뷰 경계와 설계 원칙
    ├── 03_TECH_STACK.md                       # 앱, 테스트, 도구 스택과 경계
    ├── 07_TEST_DRIVEN_DEV.md                  # TDD 원칙과 테스트 작성 순서
    ├── 08_QUALITY_ASSURANCE.md                # 리플레이, 텔레메트리, QA 기준
    ├── 09_DEPLOYMENT.md                       # 배포 기준
    ├── 10_OPERATIONS.md                       # 운영, 로그, 장애 대응 기준
    ├── 11_exec-plans/
    │   ├── 01_active/                         # 현재 진행할 마일스톤 계획
    │   └── 02_completed/                      # 검증 완료된 계획과 결과
    ├── 12_product-specs/                      # 전투, 인벤토리, 성장, 서사 원천 규칙
    ├── 14_references/                         # 장르/레퍼런스 감각 자료
    └── 15_pc-environment/                     # YoungSoon PC 로컬 경로와 툴체인

app-LTL/
├── src/                                       # 정식 구현 경로와 도메인 SoT 후보
├── tests/                                     # 정식 구현 테스트와 replay fixture
└── prototype/
    └── browser-p0-p4/                         # 검증된 보존 프로토타입, 직접 수정 금지
```

## 에이전트 작업 규칙

- 구현 계획서(Implementation Plan, implementation_plan.md) 및 완료 보고서(Walkthrough, walkthrough.md)는 무조건 한글로 작성해야 합니다.
- 기획 변경과 구현 변경을 섞지 않습니다. 밸런스 수치를 바꿔야 하면 변경 이유와 기대 효과를 문서에 남깁니다.
- P0~P4에서는 화면보다 headless 재현성을 우선합니다.
- `app-LTL/prototype/**`는 검증된 프로토타입 보존 아카이브입니다. 새 기능 구현, 리팩터링, 주석 정제, 파일 이동을 직접 수행하지 않습니다. 필요한 경우 git 히스토리에서 복원하거나 별도 문서/정식 구현 경로에서 작업합니다.
- 로컬 툴체인 경로를 추측하지 않습니다. 필요한 경로는 `docs/15_pc-environment/`에서 먼저 찾고, 없으면 해당 문서를 먼저 갱신합니다.
- 도메인 규칙은 가능한 한 순수 로직으로 작성하고, 엔진/DOM/화면 의존은 컨트롤러/뷰 계층에 둡니다.
- 모든 난수는 seed로 주입합니다. `Math.random()`, `randf()` 같은 전역 난수 직접 사용은 금지합니다.
- 사용자의 체감 검증이 필요한 항목도 먼저 로그 지표를 정의합니다.
- 실패 테스트 없이 핵심 도메인 구현을 추가하지 않습니다.
- TODO만 남긴 문서를 완료로 취급하지 않습니다.
- 백그라운드 태스크나 비대화형(Headless) 환경에서 실행할 스크립트나 명령어는 필수 매개변수(Arguments)를 누락 없이 명시해야 합니다. 인자 누락 시 PowerShell 등의 셸이 사용자 입력을 위한 대화형 프롬프트를 띄워 무한 대기(Hang) 상태에 빠질 수 있습니다.
- 하네스용 도구 스크립트를 작성하거나 수정할 때는 생략된 인자로 인한 프롬프트 입력을 방지하기 위해, 파라미터를 필수(`Mandatory = $true`)로 지정하는 대신 선택적으로 받고 스크립트 초입에서 검증하여 누락 시 즉시 에러(`exit 1`) 및 사용법(Usage)을 안내하도록 조치해야 합니다.


## Definition of Ready

- 작업할 마일스톤 문서에 목표, 산출물, TDD 대상, 완료 기준이 있습니다.
- 참조할 제품 사양 문서가 명시되어 있습니다.
- 문제와 범위가 문서화되어 있습니다.
- SoT가 지정되어 있습니다.
- 기능 문장을 1~3개 수준의 상위 문장으로 설명할 수 있습니다.
- 1단계 설계기반 주석으로 파일 구조, 모듈 책임, SoT 경계, 입력/출력 계약을 설명할 수 있습니다.
- 2단계 실행 문장 주석으로 설계기반 주석을 바로 아래 코드 한 줄 또는 코드 블록으로 번역 가능한 단위까지 쪼갤 수 있습니다.
- 3단계 주석기반 프로그래밍에서 직접 구현 주석, 호출 중심 주석, 설계기반 주석, 계약 헤더 주석을 구분해 사용할 수 있습니다.
- 함수 본문에는 추상 설계 주석이 없고 실행 문장 주석만 있습니다.
- 로컬 툴 의존 작업이면 `docs/15_pc-environment/`에 실제 경로/버전 문서가 있습니다.
- 새 데이터 필드가 필요하면 JSON 스키마와 기본값이 정의되어 있습니다.
- 검증 명령 또는 수동 QA 절차가 정해져 있습니다.

## Definition of Done

- 핵심 규칙이 한 곳의 SoT로 수렴했습니다.
- 구현이 `설계기반 주석 -> 실행 문장 주석 -> 주석기반 프로그래밍 구현` 순서를 거쳤습니다.
- 설계기반 주석이 실행 문장 주석으로 변환되지 않은 채 구현 근거로 사용되지 않았습니다.
- 구현이 기능 문장과 실행 문장 주석 단위에 맞게 분해되어 있습니다.
- 함수 본문 안의 모든 주석은 바로 아래 코드 한 줄 또는 코드 블록과 1:1로 대응합니다.
- 실행 문장 주석 하나가 두 개 이상의 독립 판단, 계산, 상태 변경, 반환을 덮지 않습니다.
- 계약 헤더 주석이 함수 본문 구현 주석을 대체하지 않습니다.
- 세부 동작 설명은 SoT 함수 하나에만 존재합니다.
- 상위 함수 주석과 하위 함수 주석이 같은 세부 동작을 중복 설명하지 않습니다.
- 주석이 현재 최종 구현과 일치합니다.
- 해당 단계의 단위/통합 테스트가 통과합니다.
- 동일 seed와 동일 input log로 결과가 재현됩니다.
- 텔레메트리 필수 필드가 누락되지 않습니다.
- 다음 단계가 참조할 계약이 문서화되어 있습니다.
- 남은 기술 부채와 후속 결정이 문서화되어 있습니다.
### Delete/Add 사용 원칙
- `Delete/Add`는 Codex 내부적으로 강제되는 규칙이 아니라, 큰 구조 변경을 빠르게 적용하려 할 때 자주 선택되는 편집 방식이다.
- LTL에서는 이 방식보다 기존 문맥과 기존 한글 주석을 유지하는 부분 수정이 더 우선이다.
- 기존 한글 주석이 살아 있는 파일에서는 전체 재작성보다 부분 수정, 기존 문장 유지, 블록 이동 최소화를 기본값으로 삼는다.
- 파일 전체 재작성이 불가피한 경우에만 예외적으로 `Delete/Add`를 허용한다.
- 예외적으로 `Delete/Add`를 사용했다면 구현 완료 전에 후처리를 반드시 수행한다.
- 후처리 1: 원본 파일의 한글 주석을 가능한 범위까지 복원한다.
- 후처리 2: 구현 중 새로 들어간 영문 설명 주석은 모두 한글 주석으로 교체한다.
- 후처리 3: 새 한글 주석도 기존 저장소의 용어와 문장 톤을 우선 계승한다.
- 후처리 4: 최종 상태가 다시 `주석A -> 구현A -> 주석B -> 구현B` 순서를 만족하는지 확인한다.
- 사용자가 명시적으로 허용하지 않은 한, 설명용 영문 `//` 주석이나 영문 블록 주석이 남아 있으면 완료로 간주하지 않는다.
- 

## I18n Text Gate Addendum
- User-facing UI text must flow through `app-LTL/src/ui/TextCatalog.gd` or a read-model/presenter that uses that catalog.
- Settings must expose Korean/English switching and trigger a scene re-render after locale changes.
- Domain/vocabulary code should emit stable ids and enum values; UI read models own language projection.
- Completion evidence must include `LTL-harness/tools/i18n-text-gate.ps1`.
## Comment Gate Addendum
- Comment-first SoT is `docs/comment-first-enforcement.md`.
- Formal source work must advance in this exact order: `contract-only -> execution-only -> implementation`.
- `contract-only` allows only `계약:` comments.
- `execution-only` allows `계약:` comments and `실행:` comments, but no implementation code.
- `implementation` requires an approved ledger with `phase: implementation-approved`.
- Every implementation block must be directly guarded by one `실행:` comment.
- Before editing harness enforcement files, create a local backup set under `docs/comment-gates/backups/<date>/ltl-harness/`.
- If phase order is violated, quarantine or roll back from the last valid phase instead of backfilling comments after code.
