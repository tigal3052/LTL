# Request Constraint Ledger — 2026-07-14 결과/보상/설정/상점/토스트 리디자인

## Request Summary

- `LTL-harness/new_design`의 스티치 원안 7종(stitch_ltl_clear/fail/reward/reward_boss/settings/shop/toast)을 분석해 페이지별 적용 계획을 세우고, 스티치 기반 신규 목업을 제작한 뒤 목업 품질을 올릴 이미지를 직접 생성해 CTA/배경/패널에 적용하고, 목업 평가 기준과 적용 결과 평가 기준으로 캡처 분석을 반복하며 Godot 정식 페이지에 반영한다.
- 페이지별 작업은 브랜치 `claude/redesign-<page>`에서 서브에이전트 병렬 진행, 공용 기반은 `claude/redesign-base`.

## Preserved Invariants

- 게임플레이 규칙/수치/기획 결정 불변: `SHOP_ENABLED := false`, 상점 가격/효과, 보상 확정·버리기 규칙, 재도전 시드 규칙.
- 백팩 보드/CellView/타일 렌더링은 전투 페이지와 공유 SoT — 전투 리디자인 결과 시각 불변.
- 페이지 계약: clear/defeat=viewport_meta, reward/boss_reward=phase_scoped, settings/shop/confirm/toast=팝업 최상위 레이어링.
- 싱글톤 화면 소유자: reward와 boss_reward는 같은 레이아웃 정책의 상태 분기.
- i18n: 사용자 노출 문자열은 TextCatalog 경유, ko/en 동시 유지.
- `app-LTL/prototype/**` 수정 금지, `project.godot`의 stretch 설정 불변.
- 내러티브 토스트의 continue_requested/자동 소멸 타이머 계약.

## Mutable Scope

- `app-LTL/src/scenes/pages/ClearPage.tscn`, `DefeatPage.tscn|.gd`, `RewardPage.tscn`, `BossRewardPage.tscn`, `src/scenes/pages/shells/RewardPanel.tscn`
- `app-LTL/src/Main.tscn`(SettingsPanel/ConfirmOverlay 서브트리), `src/ui/SettingsPanelUI.gd`, `src/ui/ShopPanelUI.gd`
- `src/ui/main_view/MainViewRewardLayoutRuntime.gd`, `MainViewFeedbackRuntime.gd`, `MainViewPanelsRuntime.gd`(시각 계층만), `src/scenes/narrative/NarrativeToast.gd`
- `app-LTL/resources/UI/<page>_redesign/**`(신규 자산), `src/data/i18n/text-ko.json`, `text-en.json`
- `app-LTL/tests/run_redesign_page_capture.gd`(캡처 하네스), `docs/source-map.md`
- 로컬 하네스 산출물: `LTL-harness/new_design/ltl_<page>_redesign/**`, `LTL-harness/docs/mockup-*evaluation-criteria.md`(gitignore 경로)

## Source Map Findings

- `app-LTL/src/ui/main_view/MainViewPageShellRuntime.gd` — page id 등록과 META/SURFACE 페이지 구분(clear/defeat=meta, reward/boss_reward=surface).
- `app-LTL/src/controllers/MainControllerRenderFlow.gd` — resolve_page_id가 phase→pageId 라우팅 SoT.
- `app-LTL/src/ui/main_view/MainViewPanelsRuntime.gd` — settings/shop 오버레이 토글 소유자.
- `app-LTL/src/ui/main_view/MainViewFeedbackRuntime.gd` — info 토스트 SoT.
- `app-LTL/src/scenes/narrative/NarrativeToast.gd` — 내러티브 토스트 SoT(페이지 겹침 문제의 근원).

## Root Cause Review

- Observed symptom: clear/defeat/settings/shop/toast 화면이 무테마 다크 플레이스홀더이고, reward/boss_reward는 백팩 보드 외 크롬이 다크 남색으로 테마 불일치. 내러티브 토스트가 페이지 콘텐츠를 가림.
- Evidence: `.tmp-redesign/captures/current/*_1440x900.png` 7종 vs `LTL-harness/new_design/stitch_ltl_*/screen.png` 비교(`LTL-harness/new_design/REDESIGN_2026W29_ANALYSIS.md`).
- Root cause target: `app-LTL/src/ui/main_view/MainViewChromeRuntime.gd`
- Root cause target detail: 위 소유자가 reward 패널을 런타임마다 다크로 재오버라이드하던 것이 대표 근본 원인이며, 나머지 페이지는 각자의 씬/오버레이 UI 계층에 스타일이 미구현된 상태다 — `app-LTL/src/scenes/pages/shells/RewardPanel.tscn`, `ClearPage.tscn`, `DefeatPage.tscn`, `app-LTL/src/Main.tscn`, `app-LTL/src/ui/SettingsPanelUI.gd`, `app-LTL/src/ui/ShopPanelUI.gd`, `app-LTL/src/scenes/narrative/NarrativeToast.gd`. 도메인 규칙은 정상.
- Rejected workaround: 색상만 바꾸는 표면 패치, 목업 없이 즉흥 스타일링, 스티치 원안의 기능 불일치 요소(존재하지 않는 네비/기능) 복제.
- Chosen fix: 승인된 목업(평가 기준 통과) 기반으로 씬 구조·스타일박스·생성 자산을 이식하고, 런타임 캡처 평가 루프로 수렴시킨다.

## Refactor/Delete Disposition

- **Delete 없음**: 페이지 씬/오버레이의 기존 노드를 삭제하지 않았다. 스타일박스·텍스처·색상 오버라이드 교체와 노드 추가(보스 오버레이 3종, SettingsDim, 토스트 코너 밴드)만 수행했다.
- **Refactor 유지**: `MainViewChromeRuntime._apply_surface_bundle_theme`의 다크 재오버라이드 로직은 삭제가 아니라 라이트 팔레트로 **교체**했다(호출 계약·시그니처 불변).
- **신규 추출**: `app-LTL/src/ui/theme/ToastRedesignTheme.gd`(토스트 시각 토큰 SoT), `app-LTL/src/ui/read_models/ShopReadModel.gd`, `app-LTL/src/ui/shop/ShopLayoutPolicy.gd`, `ShopVisualFactory.gd` — 기존 런타임 파일 비대화를 피하기 위한 캡슐 분리.
- **공유 리소스 보존**: `Main.tscn`의 `StyleBoxFlat_settings`는 ConfirmOverlay가 참조하므로 삭제하지 않고 유지, ConfirmOverlay 전용 sub_resource를 신설해 참조를 분리했다.
- **테스트 갱신(삭제 아님)**: `run_page_scene_mapping_contract.gd`, `ui_defeat_visual_suite.gd`의 노드 경로 어서션을 신규 트리 기준으로 갱신했다. 검증 의도는 동일하게 유지했다.
- **prototype 미변경**: `app-LTL/prototype/**`는 읽기 전용 아카이브로 두었다.

## Transition Safety Review

- Touched transition ids: 없음(페이지 진입/이탈 시그널 계약 유지, 시각 계층만 변경) — `no transition impact` 선언. 단, 각 페이지 에이전트는 `tests/run_redesign_page_capture.gd` 드라이브로 진입 경로가 여전히 도달 가능함을 캡처로 증명해야 한다.
- Runner path: `app-LTL/tests/run_redesign_page_capture.gd`, 성공 마커 `M6_INTERNAL_CAPTURED`.

## Feature Unit Lifecycle Plan

- Design stage: 페이지별 씬이 레이아웃 소유자, 공용 테마 토큰(스타일박스/폰트)은 페이지 폴더 내 헬퍼로 캡슐화. reward/boss_reward는 RewardPanel 셸이 소유자.
- Implementation stage: 목업 승인 → APPLY_PLAN → 캡처 평가 루프. 기존 파일은 부분 수정 우선(Delete/Add 지양), 새 코드는 `계약:`/`실행:` 주석 선행.
- Maintenance stage: 페이지 스타일 확장 시 페이지 폴더 헬퍼를 확장하고 MainView 런타임 파일 비대화를 피한다.
- Capsule boundary: 각 페이지의 공개 API는 기존 시그널/등록 함수 시그니처로 한정, 스타일 상수·텍스처 경로는 페이지 내부 비공개.
- Size trigger: 수정 대상 런타임 파일이 runtime-size 캡의 80%에 근접하면 편집 전 분리.

## Runtime Performance Review

- Hot path: 토스트 표시/소멸과 오버레이 토글은 빈도 낮음. 신규 텍스처는 로드 1회 캐시(프레임 내 반복 로드 금지).
- Budget: 페이지 렌더 추가 비용은 텍스처 draw 수준, per-frame 스크립트 로직 추가 없음.

## Verification Checklist

- [x] 페이지별 목업 평가 A항목 전부 PASS (`LTL-harness/docs/mockup-evaluation-criteria.md`, EVAL_LOG.md 증빙)
- [x] 페이지별 적용 평가 A항목 전부 PASS (`LTL-harness/docs/mockup-apply-evaluation-criteria.md`, APPLY_EVAL_LOG.md 증빙)
- [x] `tools/run-compile-check.ps1`: source-map/request-analysis/test-size 게이트 통과. runtime-size 게이트는 `app-LTL/src/scenes/pages/CharacterSelectPage.gd`(703줄)에서 실패하나, 이 파일은 본 작업 6개 브랜치 어디서도 미변경이고 작업 시작 전 커밋(63bc346)에서도 703줄로 동일 — 기존 부채이며 신규 회귀 아님.
- [x] 소스맵 refresh OK, i18n 게이트 신규 위반 0
- [x] 팝업 레이어링 검증(settings/shop/confirm 전투 중 최상위)

## Artifact Ledger

- 캡처: `.tmp-redesign/captures/current/**`(기준선), `.tmp-redesign/captures/mockup/**`, `.tmp-redesign/captures/applied/**`(모두 gitignore 경로)
- 목업 패키지: `LTL-harness/new_design/ltl_<page>_redesign/**`(gitignore 경로)

## Verification Notes

페이지별 브랜치(전부 origin 푸시 완료):

| 페이지 | 브랜치 | 최종 커밋 | 적용 평가 |
|---|---|---|---|
| clear | `claude/redesign-clear` | `0d29b09` | r4, A항목 PASS |
| defeat(fail) | `claude/redesign-fail` | `88a3970` | r4 + 목업 상수 교정 r5, A 4/4 PASS |
| reward + boss_reward | `claude/redesign-reward` | `15dd17a` | r_final + 대비 수정 r6, A항목 PASS |
| settings | `claude/redesign-settings` | `fbabe22` | r8, A항목 PASS |
| shop | `claude/redesign-shop` | `54e4363` | r11, A항목 PASS |
| toast/confirm | `claude/redesign-toast` | `f9dcc50` | r4, A항목 PASS |
| 공용 기반 | `claude/redesign-base` | `8c00a60` | 캡처 러너·분석·평가 기준·원장 |

하네스 자체 결함 2건을 작업 중 발견해 base에서 수정:
- `3918084` — 소스맵 게이트가 `.claude/worktrees`를 제외하지 않아 에이전트 worktree가 맵에 유입(가짜 app-LTL 항목 4851개, ~14000줄). 제외 규칙 추가로 맵 2936줄 안정화.
- `8c00a60` — 캡처 러너가 내러티브 타자기 연출(36자/초, 벽시계)을 고정 프레임으로 대기해 문장이 잘린 채 캡처됨. `_complete_typewriter()` 확정 호출 추가.

## Resolution Proof

- RED proof: 기준선 캡처 7종(`.tmp-redesign/captures/current/*_1440x900.png`)이 스티치 원안과의 구조적 불일치를 증명했다(분석 문서 §1). clear/defeat/settings/shop/toast는 무테마 다크 플레이스홀더였고, reward/boss_reward는 백팩 보드 외 크롬이 다크 남색이었다.
- Root-cause proof: 아래 3건의 근본 원인을 소스 수준에서 각각 규명하고 수정했다(상세는 하위 항목).
- Workaround guard: 평가 기준 A항목이 표면 패치 완료 선언을 실제로 차단했다 — defeat 2회차와 reward 최종본이 "A항목 PASS"로 보고됐으나 캡처 검증에서 반려되어 재작업했다. 게이트가 red라 못 믿는 reward tray 오버플로는 `git stash` 기준선 실측으로 대조해 회귀 0을 증명했다(기준선 bottom=906 vs 적용후 906).
- Root-cause proof 상세:
  - reward 다크 잔존의 근본 원인은 `MainViewChromeRuntime._apply_surface_bundle_theme`가 런타임마다 reward 패널을 다크로 **재오버라이드**하던 전투 리디자인 시절 레거시 코드였다. 스타일박스만 바꾸는 표면 패치로는 재발했을 문제이며, 해당 소유자를 라이트 팔레트로 교체해 해결(`claude/redesign-reward`).
  - defeat 보드 105px 편차의 근본 원인은 목업이 런타임 상수를 잘못 인코딩한 것(`layout_narrative_toast()`의 `clamp(x*0.38, 420, 620)`에서 클램프 하한 420을 실제값으로 오인, 1440에서 실제 547.2px). 목업 상수를 실제 공식에 맞춰 교정해 해결(실측: 목업 607-1415 vs 런타임 605-1410).
  - reward 인스펙터 텍스트 불가시의 근본 원인은 다크→라이트 전환 시 `InspectorSummary`(RichTextLabel)에 색상 오버라이드가 누락되어 Godot 기본 근백색으로 폴백된 것. RichTextLabel은 `font_color`가 아니라 `default_color`가 필요하며, 테마 흙갈색으로 지정해 해결(`15dd17a`).
- Workaround guard 상세:
  - reward tray 6px 오버플로는 `run_main_layout_audit`가 이미 red라 게이트로 회귀를 증명할 수 없었다. 게이트 대신 `git stash` 기준선 실측으로 대조: **기준선 bottom=906 vs 적용후 bottom=906, 회귀 0**. 최초 적용본이 확정 버튼 높이로 907(1px 회귀)이었던 것을 42px 조정으로 기준선과 일치시켰다.
  - 실측 우선 원칙(A0)을 평가 기준에 하드 룰로 추가했다 — 구현자와 검토자가 각각 육안 판정으로 오판한 사례(토스트 rect 79px 침범을 "겹침 없음"으로 PASS, 목업 중앙 아님을 "우측 쏠림"으로 반려)를 근거로 기록.
