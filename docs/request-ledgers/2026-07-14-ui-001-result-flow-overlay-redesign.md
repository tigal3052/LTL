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
- Root cause target: 각 페이지 씬/오버레이 UI 계층(위 Mutable Scope)의 스타일 미구현 — 도메인 규칙은 정상.
- Rejected workaround: 색상만 바꾸는 표면 패치, 목업 없이 즉흥 스타일링, 스티치 원안의 기능 불일치 요소(존재하지 않는 네비/기능) 복제.
- Chosen fix: 승인된 목업(평가 기준 통과) 기반으로 씬 구조·스타일박스·생성 자산을 이식하고, 런타임 캡처 평가 루프로 수렴시킨다.

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

- [ ] 페이지별 목업 평가 A항목 전부 PASS (`LTL-harness/docs/mockup-evaluation-criteria.md`, EVAL_LOG.md 증빙)
- [ ] 페이지별 적용 평가 A항목 전부 PASS (`LTL-harness/docs/mockup-apply-evaluation-criteria.md`, APPLY_EVAL_LOG.md 증빙)
- [ ] `tools/run-compile-check.ps1` 통과(브랜치 기존 실패 목록 대조, 신규 실패 0)
- [ ] 소스맵 refresh OK, i18n 게이트 신규 위반 0
- [ ] 팝업 레이어링 검증(settings/shop/confirm 전투 중 최상위)

## Artifact Ledger

- 캡처: `.tmp-redesign/captures/current/**`(기준선), `.tmp-redesign/captures/mockup/**`, `.tmp-redesign/captures/applied/**`(모두 gitignore 경로)
- 목업 패키지: `LTL-harness/new_design/ltl_<page>_redesign/**`(gitignore 경로)

## Verification Notes

- (완료 시 기록)

## Resolution Proof

- RED proof: 기준선 캡처 7종이 스티치 원안과의 구조적 불일치를 증명(분석 문서 §1).
- Root-cause proof: (구현 후 페이지별 APPLY_EVAL_LOG 최종 회차로 기록)
- Workaround-guard evidence: (완료 시 기록 — 평가 기준 A항목 체크리스트가 표면 패치 완료 선언을 차단)
