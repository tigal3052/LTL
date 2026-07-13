# complete: 전투 페이지 리디자인 (ltl_battle_redesign 목업 반영)

- 날짜: 2026-07-13 · 브랜치: codex/m4-m9-release-quality-implementation
- 근거: `LTL-harness/new_design/ltl_battle_redesign/` (index.html 목업 + APPLY_PLAN.md Phase 0~6)
- 목표 대응: 전투 화면 릴리즈 품질 (M4-M9 비주얼 슬라이스)

## 변경 요약

### 리소스 (Phase 0)
- 목업 assets → Godot 경로 복사(리사이즈): 타일 4색(`resources/UI/tile/*_tile.png`), hazard 4색(1132×348),
  마이너 3포즈(1024²), 백팩 림 9종 + 좌/우 엣지 변형 `backpack_4_2.png`/`backpack_6_2.png`,
  슬롯 스톤 → `backpack_5.png`, 신규 `resources/UI/battle_redesign/{bg_canopy_ruins,panel_parchment}.png`
- 원본은 git 히스토리에 보존(파일명 유지 덮어쓰기)

### 테마 (Phase 1)
- `LTLTheme.gd`: MD3 라이트 토큰(SURFACE/PRIMARY/ERROR/PARCHMENT_GLASS/LIMESTONE 등) +
  `parchment_style()/limestone_style()/ledger_card_style()/hero_button_style()/danger_button_style()/energy_deep_color()`

### 레이아웃 (§1.5 개정 반영)
- `BattlePage.tscn`: 하단 ActionBar 행 폐지, 배틀필드 154px 고정
- `GameplayTopContent.tscn`: 좌 302px 양피지 노트 / 중앙 보드 최대화 / **보드 우측 96px CTA 기둥**
  (`TopContent/CtaColumn/ActionBar` = VBox: 굴착 포기 → TimerChip → 굴착 시작/보상[숨김]) / 우 302px 야장
- `Main.tscn` 헤더: 양피지 스트립 + 유적 석판 칩(PhaseLabel/StageLabel, chip_ruin_tablet) + variant05 유틸 버튼(44px 유지)
- 런타임 배선: `MainViewPageShellRuntime`(battle CTA 경로 + ctaTimerChip/Label 번들, BoxContainer 캐스트),
  `MainViewRuntimeState.action_bar: BoxContainer`, `MainViewAppShellRuntime.action_bar_in_shell_flow()`
  (top_content 내부 CTA는 셸 세로 예산 제외 + CTA 폭을 백팩 폭 캡에 반영),
  `MainViewSceneRuntime`(_apply_page_chrome_backdrop: 전투/보상 라이트 크롬, _render_battle_cta_timer: CTA 타이머 칩 + 크리티컬 틴트, footer 타이머 중복 억제)
- i18n: `action.abort_dig`(굴착 포기)/`action.start_dig`(굴착 시작) 추가, battle 번들 전용 라벨

### 배틀필드 (F1~F7)
- `BattlefieldUI.gd`: 백드롭 → bg_canopy_ruins, 마이너 트림 영역 재측정(45/60/90), GRID_PADDING_Y_MIN 7, LANE_GAP_Y 4
- `CellView.gd`: **hazard를 셀보다 사방 10px(+계열별 확장) 큰 TextureRect 오버레이 레이어(z2)로 전환**,
  진행 바는 상위 z5 레이어 — 인접 hazard 겹침 시에도 판독 유지 (§1.5-5, F2 코드 무변경 전제 해제 항목)
- 셀 min 높이 36→26 (154px 존 대응). 알파/노치/스코프/✕ 로직 무변경

### 패널/보드 (F8~F17)
- `StatusPanelUI` + `StatusPanelInfoCards`: 양피지/원장 스타일, 바 색(HP=ERROR/실드=blue-deep/PIN=gold), 잉크 텍스트
- `EnergyQueuePulseSlot`: 라이트 슬롯 + 딥 파형색(mockup waveColor), min 26×17
- `BattleSidebarUI`: 라이트 탭(활성=석회암+골드), 양피지 셸
- `BackpackUI.setup_grid_slots`: 좌/우 엣지 행별 변형(-1 이끼/-2 스트랩) 선택 `_rim_texture_for()`
- `ShellButtonStyler`: 배틀 CTA(Hero/error 톤) + 헤더 언더라인 유틸 분기 추가

## 검증
- `godot_contract_runner.gd` → GODOT_CONTRACTS_OK (miner 트림 영역 기대값 갱신 포함)
- `run_main_layout_audit_contract` 전투 섹션 전부 통과 (CTA 기둥 기준으로 갱신: 배틀필드=플로어 앵커,
  CTA 위치/폭 캡 클램프 허용, 좌 컬럼 300~440)
- `run_combat_layout_containment` / `run_battle_hud_layout_read_model` / `run_battle_render_performance` / `run_i18n_localization_smoke` OK
- 윈도우 캡처(1440×900) battle 페이지: 목업 대비 3열 양피지 + CTA 기둥(굴착 포기/01:30 타이머) + 154px 발굴 현장 + 숲 백드롭 확인

## 기존(사전) 실패 — 본 작업과 무관 (기준선 검증 완료)
- `run_main_layout_audit`: leviathan rail ratio 0.23 / node-select disabled 스타일 / reward tray 6px 오버플로
  → 이전 세션 미커밋 작업(project.godot aspect=expand, 노드선택 root margin 0, 레비아탄 풀스크린) 파급.
  reward 오버플로는 SceneRuntime의 root margin 오버라이드(이전 세션 훅)로 재현됨을 이등분으로 확인
- `run_main_start_flow`: 노드선택 카피 어서션(LEVIATHAN EXPEDITION ATLAS) — 이전 세션 작업
- `run_battle_backpack_visual_width`: 헤드리스 뷰포트 캡처 불가 — HEAD 기준선에서도 FAIL
- `run_page_scene_mapping`: run-start(캐릭터 선택) 어서션 — HEAD 기준선에서도 FAIL

## 2차 피드백 반영 (2026-07-13)

1. **노드 정보 토글 레이아웃 고정**: `LeftColumn` 폭 372px 고정 — 접힘/펼침 어느 상태에서도
   좌 컬럼/보드 x 좌표 불변 (프로브: collapsed/expanded 모두 left=372, board_x=402)
2. **배틀필드 목업 정합**: 구 배경 이미지(백드롭 드리프트)·`tile_panel` 프레임 셸 폐지,
   좌측 마이너 도크(14.25%/min 96px) 분리 + 그리드 재배치(겹침 제거), 레인 밴드 = 셀 + 상하 3px 패딩 + 밴드 간 4px,
   셀에 목업 크롬(그라디언트 틴트/1px 다크 보더/인셋 음영/빈 셀 다크 필), 매치 노치를 **백색 코너 브래킷**으로 교체(색상 잔재 제거)
3. **굴착 시작 홀드**: `battle_start_hold_active` — 배틀 진입 시 전투 정지(타이머/시프트/입력),
   CTA '굴착 시작' 노출, 누르면 개시. 내러티브/설정/도감 일시정지와 `sync_battle_pause_from_overlay_visibility`로 합성.
   audit 갱신: 진입 홀드 → CTA 해제 → 오버레이 pause 재검증 순서
4. **에너지 큐 파형**: 슬롯 크기 비례 스트로크(내부 인셋 4px, stroke=h*0.18 clamp 1.2~2.4) — 소형 슬롯 뭉개짐 해소
5. **탐험가 탭 하단**: 캐릭터 요약(구 RootMargin 경로 사망 버그 수정 — 번들 경로로 전환) +
   PIN 진행 바/드릴 상태/필드 상태/고정석 4슬롯(트림 크롭) 신설, `panel.pin_stock` i18n 추가
6. **영향범위 하이라이트**: 옐로 → 연초록(bg 0.62,0.90,0.52,0.30 / border 0.38,0.76,0.33,0.80)
7. **핀 퀄리티 계획**: `LTL-harness/new_design/ltl_battle_redesign/PIN_CORNER_QUALITY_PLAN.md`
   (진단 6종 + 방안 A 신규 아트 / B 렌더링 개선 / C 구조 통합, 실행 순서 포함)

검증: `godot_contract_runner` OK, codex pause timing OK, combat containment OK,
layout audit 전투/일시정지 섹션 전부 통과(잔여 실패 = 기존 목록과 동일), 1440×900 캡처 3종(홀드/개시/펼침) 확인.

## 3차 피드백 반영 (2026-07-13)

1. **타일 코너 표시 제거**: `CellView` 큐 매치 백색 코너 브래킷(`_draw_match_frame`)과
   비매치 코너 프레임(`_draw_mismatch_frame`) 폐지 — 판독은 알파 이분(1.0/0.5)만 유지
2. **배틀필드 클리핑**: `BattlefieldPanel` `clip_contents=true` — 목업 `.battlefield overflow:hidden`
   등가, hazard 오버레이가 패널 경계에서 잘려 밖으로 삐져나오지 않음
3. **노드 정보 타일 이미지 복원**: 배율 카드 마커를 원형 점 → 지형 타일 아트(`MetricTileIcon`,
   체력=적/실드=청)로, 기본 지형(공통 배율) 카드에 4색 타일 스트립(`NeutralTileRow`) 추가
4. **드릴 정보 stat-row 정합**: HP/실드/큐/PIN 행을 목업 `.stat-row`(헤드 라벨+색상 수치 우측,
   9px 순수 게이지 분리)로 재구성 — 바 내부 `ValLabel`/`PinValueLabel` 오버레이 폐지,
   큐는 세로 스택(헤드 `n / 16` + 그리드, QueueShell 패널 제거). i18n 라벨 콜론 제거("레비아탄 체력 (HP)" 형식)
5. **에너지 큐 슬롯 목업화**: `EnergyQueuePulseSlot` 이중 패널 제거 — 흰 슬롯+1px 보더+파형만,
   선두=골드 보더+글로우, 비활성=45° 빗금(55% 톤)
6. **채집낭 보드 패널**: `GameplayTopContent`에 `BoardPanel(석회암)/BoardMargin/BoardBox/
   BoardTitleRow(BoardTitle)/BoardArea(BackpackContainer+CtaColumn)` 신설 — 제목("채집낭 — 공명 기관",
   `panel.backpack` 갱신)과 CTA 기둥이 한 패널에 포함(mockup `.board-wrap`). CTA/백팩 경로 변경:
   `TopContent/BoardPanel/BoardMargin/BoardBox/BoardArea/{CtaColumn/ActionBar,BackpackContainer}`
   (PageShellRuntime 구경로 폴백 유지). AppShellRuntime에 보드 크롬 예산(`board_panel_*_chrome`) 반영,
   EngineTitle 상시 숨김(제목은 보드 패널/보상 워크스페이스가 담당), 영향 토글 앵커=BoardTitleRow

검증: `godot_contract_runner` OK · layout audit 전투 섹션 전부 통과(잔여 = 기존 실패 목록과 동일) ·
start_flow/reward_handoff/claim_board/containment/hud_read_model/i18n/pause_timing/pin_probe/viewport/render_perf OK ·
1440×900 윈도우 캡처 2종(전투 CTA 노출/노드 정보 펼침) 확인.
i18n·source-map 게이트 실패는 기존 커밋 파일(unknown waters 카피, codex_redesign 소스맵 책임 누락) 때문 — 본 작업 무관.

## 4차 피드백 반영 (2026-07-13)

1. **타일 cover 크롭**: 타일 아트(640² 정사각)를 셀에 눌러 맞추던 것을 목업 `background-size: cover`
   등가(`CellView._draw_tile_texture_cover`, `draw_texture_rect_region` 중앙 크롭)로 전환 —
   위아래가 잘린 질감 밴드로 보여 '벽돌' 인상 해소
2. **방해요소 줄기 프레임 앵커링**: 오버레이를 셀 중심 대칭 outset(+10px) 대신
   **이미지 내 줄기 사각형(덩굴/가시 프레임)의 중심선을 타일 테두리에 정렬**하는 방식으로 교체.
   `CellView.HAZARD_FRAME_FRACTIONS`(색별 Rect2, hazard PNG 1132×348 알파 밴드 중앙값으로 측정 —
   컬럼 30~70%/로우 35~65% 구간 run 중심 median) + `hazard_overlay_rect_for()`.
   코너 불/얼음/버섯/연기 오브젝트가 프레임 위 여백에 있어 이미지 전체가 타일 위로 상승한다.
   구 `HAZARD_OVERLAY_OUTSET`/`hazard_texture_margin_for` 폐지(HUD 스위트를 rect 기반 어서션으로 교체)
3. **배율 카드 마커 정리**: 배율 카드의 타일 아이콘 제거 — 텍스트 앞 **세로 색상 바**(체력=빨강,
   실드=파랑, `MetricAccentBar`)로 교체. 타일 이미지는 약점 카드 아이콘과 공통 배율 4색 스트립만 유지

검증: `godot_contract_runner` OK · render_performance/containment OK · layout audit 잔여 실패 = 기존 목록과 동일 ·
1440×900 캡처(배틀필드 크롭 확대 포함)로 cover 질감/프레임 상승 정렬/색상 바 확인.

## 후속 과제
- 로그 타임라인화(LogConsoleUI → VBox 엔트리, R7) — APPLY_PLAN 선택 항목
- `tile_panel_frame.png` 교체(F6) 미적용 — 현 tile_panel_nobg 셸 유지
- portrait_explorer.png 미생성 — 기존 캐릭터 스프라이트 초상 유지
- 이전 세션 미커밋 작업의 audit 실패 3종 해소 (별도 태스크)
