# Codex Worklog History

Workspace: LootingTheLeviathan
Date: 2026-05-13

No implementation history has been recorded yet.
## 2026-05-13 01:58:04

<!-- codex-worklog-signature: 437b8ebf0fa4f4086a6a149129d60fee1308100623ab844db409635fb40e7a67 -->

- Intent: Workspace files changed through Codex tooling.
- Tool: Bash
- Files or areas touched:
``text
Git status unavailable.
``
- Summary: Review the plan and current diff for semantic details; keep this entry compressed if later updates touch the same area.
- Verification: Not recorded by hook. Update this after running checks.

## 2026-05-13 LTL-harness 구체화

- Intent: `기획서v0.2.md`, `구현기획서_Godot_TDD.md`, 범용 `agent-harness` 구조를 바탕으로 LTL 전용 구현 하네스를 실사용 가능한 문서 세트로 보강.
- Files or areas touched:
  - `LTL-harness/README.md`
  - `LTL-harness/00_AGENTS.md`
  - `LTL-harness/docs/00_PRODUCT_SENSE.md`
  - `LTL-harness/docs/01_PLANS.md`
  - `LTL-harness/docs/02_DESIGN.md`
  - `LTL-harness/docs/03_TECH_STACK.md`
  - `LTL-harness/docs/07_TEST_DRIVEN_DEV.md`
  - `LTL-harness/docs/08_QUALITY_ASSURANCE.md`
  - `LTL-harness/docs/09_DEPLOYMENT.md`
  - `LTL-harness/docs/10_OPERATIONS.md`
  - `LTL-harness/docs/12_product-specs/*.md`
  - `LTL-harness/docs/11_exec-plans/01_active/*.md`
- Summary: 상위 워크플로우 게이트, Godot 도메인/데이터/뷰 경계, GUT 기반 TDD 계약, telemetry/replay/seed 기준, P0~P4 및 M0~M9 단계별 산출물과 완료 기준을 구체화했다. 기존 마일스톤 placeholder가 남아 있던 파일은 중복 제목과 placeholder를 정리했다.
- Plan impact: 기존 계획 범위 안에서 완료. 실제 Godot 코드 구현은 범위 밖으로 유지.
- Verification: `rg`로 placeholder/TODO 잔존 여부를 확인했고, P0~P4/M0~M9/GUT/seed/telemetry/replay/input log 키워드가 하네스 문서에 반영된 것을 확인했다. `git status`는 현재 디렉터리가 git 저장소가 아니어서 사용할 수 없었다.

## 2026-05-13 레퍼런스/디자인/기술 스택 보강

- Intent: 웹 검색을 통해 `14_references`를 세부 분석하고, `02_DESIGN.md`와 `03_TECH_STACK.md`의 구현 지침 밀도를 높임.
- Files or areas touched:
  - `LTL-harness/docs/14_references/01_vampire_survivors_dopamine.md`
  - `LTL-harness/docs/14_references/02_backpack_battles_synergy.md`
  - `LTL-harness/docs/14_references/03_slot_machine_mechanics.md`
  - `LTL-harness/docs/02_DESIGN.md`
  - `LTL-harness/docs/03_TECH_STACK.md`
- Summary: Vampire Survivors, Backpack Battles, 강화 스케줄 관련 웹 근거를 문서에 반영하고 LTL 적용/금지선을 작성했다. 디자인 문서에는 7:3 전투 레이아웃, 화면별 구성, UI 컴포넌트, 배경, 캐릭터, 레비아탄, VFX/SFX cue, 판독성/해상도 기준을 추가했다. 기술 스택 문서에는 오디오 bus, GPUParticles2D/ShaderMaterial, AnimationPlayer/Tween, JSONL 로그, ConfigFile 설정, export preset, 현지화, 접근성, 성능 기준을 보강했다.
- Plan impact: 최신 사용자 요청에 따라 계획을 갱신한 뒤 범위 내에서 완료.
- Verification: `rg`로 대상 문서의 TODO/TBD/Pending 잔존 여부를 확인했고, Audio/GPUParticles2D/export/telemetry/replay/ConfigFile/localization/접근성/캐릭터/백팩/TerrainGrid/RewardResolver 키워드 반영을 확인했다. 검색 결과의 placeholder 언급은 worklog의 검증 문장에만 남아 있다.

## 2026-05-13 app-LTL P0/P1 골격 구축

- Intent: `LTL-harness`의 P0/P1 기준을 따라 `app-LTL`에 사용자가 테스트 가능한 첫 단계 구현.
- Files or areas touched:
  - `app-LTL/project.godot`
  - `app-LTL/prototype/**`
  - `app-LTL/src/**`
  - `app-LTL/tests/**`
  - `app-LTL/public/index.html`
  - `app-LTL/README.md`
  - `app-LTL/package.json`
- Summary: Node 내장 test runner 기반 P0/P1 테스트를 먼저 작성해 RED 실패를 확인한 뒤 seed RNG, telemetry, energy queue, mining resolver, run simulator, replay runner를 구현했다. Godot 4.3 프로젝트 골격과 GDScript 도메인/텔레메트리/replay runner를 추가했고, 정적 브라우저 데모를 추가했다.
- Plan impact: 사용자가 제공한 Godot 설치 경로를 반영해 Godot headless 검증까지 수행했다. GUT 설치는 하지 않았고 Node 테스트와 Godot script smoke로 첫 단계 검증을 대체했다.
- Verification: `node --test` 8개 테스트 통과. `D:\Programming\godot_workspace\bin\Godot_v4.3-stable_win64_console.exe --headless --path app-LTL --script prototype/tools/replay_runner.gd --quit` 실행 결과 `result: clear`, `shots_fired: 1`, `shots_hit_match: 1` 확인.

## 2026-05-13 02:00:33

<!-- codex-worklog-signature: 991487e70da9c789d766717f104cec9884356a8562bcc36f92f3d1222a3c86d7 -->

- Intent: Workspace files changed through Codex tooling.
- Tool: apply_patch
- Files or areas touched:
``text
Git status unavailable.
``
- Summary: Review the plan and current diff for semantic details; keep this entry compressed if later updates touch the same area.
- Verification: Not recorded by hook. Update this after running checks.

## 2026-05-13 02:06:44

<!-- codex-worklog-signature: c1b9fccfdbe3b7b8be848c02eb8cdd4271b7f746b01d042c6817b9c592a8bdc8 -->

- Intent: Workspace files changed through Codex tooling.
- Tool: unknown
- Files or areas touched:
``text
Git status unavailable.
``
- Summary: Review the plan and current diff for semantic details; keep this entry compressed if later updates touch the same area.
- Verification: Not recorded by hook. Update this after running checks.

## 2026-05-13 app-LTL viewport height 레이아웃 조정

- Intent: `public/index.html` 미리보기에서 캐릭터, 가방 그리드, 표면 그리드가 한 화면 높이를 넘지 않도록 정리.
- Files or areas touched:
  - `app-LTL/public/index.html`
  - `docs/codex-worklog/plan_LootingTheLeviathan_2026-05-13.md`
- Summary: `main` 높이를 viewport 기준으로 제한하고, `.combat`, `.top`, `.terrain`, `.backpack-grid`, `.terrain-grid`에 `minmax(0, ...)`와 `min-height: 0` 제약을 넣어 내부 그리드가 사용 가능한 높이 안에서 축소되도록 조정했다. 기존 `min-height: 620px`, 슬롯 최소 높이, 타일 종횡비 기반 확장 때문에 발생하던 세로 overflow를 제거했다.
- Plan impact: P0/P1 레이아웃 확인용 HTML의 viewport 적합성 보정 작업을 반영했다.
- Verification: 수정 후 `app-LTL/public/index.html`을 다시 읽어 viewport 제한, 전투 패널 overflow hidden, 그리드 행 sizing 관계를 코드 기준으로 점검했다. 브라우저 시각 확인은 이번 세션에서 수행하지 못했다.

## 2026-05-13 app-LTL viewport height 레이아웃 재조정

- Intent: 전투 영역이 너무 줄어든 문제를 바로잡아 `.terrain`까지가 viewport 100%를 쓰도록 수정.
- Files or areas touched:
  - `app-LTL/public/index.html`
- Summary: 원인을 `main` 전체 높이 안에 버튼과 출력 패널 높이까지 미리 배정한 구조로 확인했다. `body`는 패딩 기반 일반 문서 흐름으로 바꾸고, `main`은 `min-height: calc(100vh - 40px)`와 `grid-template-rows: minmax(0, calc(100vh - 40px)) auto auto`를 사용해 `.combat`이 viewport 높이를 전부 차지하도록 재조정했다.
- Plan impact: 하단 요약 텍스트를 제외하고 전투 레이아웃 자체가 화면 높이를 꽉 채우는 의도에 맞게 조정했다.
- Verification: 수정 후 CSS를 재검토해 버튼/출력 영역이 `.combat` 높이 예산을 더 이상 차감하지 않음을 코드 기준으로 확인했다.
## 2026-05-13 P0/P1 재검증과 P2 입력 슬라이스 구현

- Intent: `LTL-harness`의 누락된 완료 문서 체계를 보강하고, 기존 P0/P1 구현 주장을 실제 검증으로 다시 확인한 뒤 P2 전투 조작 슬라이스를 이어서 구현.
- Files or areas touched:
  - `docs/codex-worklog/plan_LootingTheLeviathan_2026-05-13.md`
  - `app-LTL/tests/p2_control_slice.test.js`
  - `app-LTL/src/combat-controller.js`
  - `app-LTL/public/index.html`
  - `app-LTL/README.md`
  - `LTL-harness/docs/11_exec-plans/02_completed/_TEMPLATE-completed.md`
  - `LTL-harness/docs/11_exec-plans/02_completed/01_P0_test_harness_and_logs_completed.md`
  - `LTL-harness/docs/11_exec-plans/02_completed/02_P1_headless_core_loop_completed.md`
  - `LTL-harness/docs/11_exec-plans/02_completed/03_P2_combat_control_slice_completed.md`
- Summary: `app-LTL`이 실제 구현 저장소임을 확인한 뒤 Node 테스트와 Godot headless replay를 다시 실행했다. P0/P1 Node 계약은 통과했지만 Godot replay는 signal 11 크래시로 실패했다. 이후 P2 기준을 `hover 1개`, `click 1발`, `hold 0.1초`, `cooldown/empty queue feedback`으로 테스트 먼저 고정하고 `CombatController`를 최소 구현했다. 브라우저 데모도 정적 요약 화면에서 상호작용 가능한 P2 슬라이스 데모로 올렸고, `LTL-harness`에는 누락된 `02_completed` 디렉토리와 단계별 완료 보고서를 추가했다.
- Plan impact: 사용자 요청에 맞춰 기존 P0/P1 골격 확인 작업에서 P2 구현과 완료 문서 작성까지 범위를 확장했다.
- Verification: `node --test` RED에서 누락 모듈 실패를 확인한 뒤 구현 후 GREEN 13개 통과를 확인했다. `Godot_v4.3-stable_win64_console.exe --headless --path ... --script prototype/tools/replay_runner.gd --quit`는 재실행 시에도 signal 11 크래시가 재현됐다.

## 2026-05-13 로컬 PC 환경 문서화와 하네스 게이트 보강

- Intent: Godot 실행 파일 경로를 매번 다시 찾는 문제를 막고, 프로젝트 전용 하네스로 전환할 때 `15_pc-environment`가 빠지지 않도록 하네스 자체를 수정.
- Files or areas touched:
  - `LTL-harness/docs/15_pc-environment/00_README.md`
  - `LTL-harness/docs/15_pc-environment/01_local_toolchain.youngsoon.md`
  - `LTL-harness/README.md`
  - `LTL-harness/00_AGENTS.md`
  - `agent-harness/README.md`
  - `agent-harness/00_AGENTS.md`
  - `agent-harness/docs/09_PROJECT_INTAKE.md`
  - `agent-harness/docs/11_exec-plans/01_active/_TEMPLATE-active.md`
  - `agent-harness/docs/15_pc-environment/00_README.md`
  - `agent-harness/docs/15_pc-environment/01_toolchain-paths._template.md`
- Summary: 원인을 분석해 보니 `15_pc-environment`는 문서 구조에는 있었지만 읽기 순서, intake, ready check, active plan 입력 문서 목록 어디에도 필수 단계로 연결되지 않았다. 그래서 `agent-harness`에는 환경 문서 게이트를 추가했고, `LTL-harness`에는 실제 로컬 툴체인 문서를 생성해 Godot/Node/Python/Git/WSL 경로와 버전, PowerShell 실행 정책 이슈, 자주 쓰는 명령을 기록했다.
- Plan impact: 이후 로컬 툴 의존 작업은 환경 문서가 없으면 Ready 상태가 아니도록 문서 흐름을 강화했다.
- Verification: Godot/Node/Python/Git/WSL 버전 및 경로를 셸 명령으로 수집했고, `rg`로 README/AGENTS/intake/template 문서가 `15_pc-environment`를 직접 참조하도록 갱신됐는지 확인했다.
