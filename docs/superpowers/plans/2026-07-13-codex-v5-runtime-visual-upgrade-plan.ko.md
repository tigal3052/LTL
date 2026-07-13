# Codex Variant 5 — 런타임 시각 전환 및 출처별 Chrome 구현 계획 (검토 반영본)

> **상태:** 구현 전 수정 계획. 이 문서는 현재 작업 트리에 있는 다른 작업자의 변경을 수정·되돌림·stage하지 않는다.
>
> **목표:** `UI-001` — `LTL-harness/new_design/ltl_codex_redesign/index.html`의 **Variant 5, 1440×900** 시각 언어를 실제 Godot Codex에 적용하되, 현재의 발견 상태·선택·정렬·실제 아트 해석·overlay pause·SFX·locale 동작을 보존한다.
>
> **실행 조건:** 구현은 별도 worktree/branch에서 시작하며, 현재 dirty worktree를 기준으로 `reset`, 대량 format, 무관 파일 stage를 하지 않는다. §1.3의 기본값은 추가 product 결정 없이 적용한다.

---

## 1. 검토 결론: 무엇을 그대로 옮기고, 무엇을 분리해야 하는가

### 1.1 목업에서 잠금(locked)할 시각 계약

목업은 현재 1440×900 `screen` 하나를 소유한다. 이는 기존 `ItemBook.png` 위 책 overlay와 호환되는 장식 변경이 아니라 **full-screen parchment Codex presentation 교체**다.

| 목업 사실 | 런타임 적용 규칙 |
|---|---|
| `.screen`은 1440×900, `overflow:hidden`, 전체 양피지 background | `ArtifactCodexPanelUI`는 full-rect popup이며 내부에 1440×900 design canvas를 한 개만 둔다. `ItemBook.png`, book safe-area, leather overlay는 제거한다. |
| topbar `(0,0,1440,80)` | Codex 자체 topbar를 새로 만든다. 원본 page header를 숨기거나 mutate하지 않는다. |
| left `(40,118,740,750)` = title/count + 606px list, right `(804,118,596,750)` = detail | 목록은 왼쪽, 선택 상세는 오른쪽이다. 기존 read-model의 이름 `leftPage=detail`, `rightPage=grid`를 UI에 그대로 투영하지 않는다. 새 V5 adapter가 명시적으로 `catalog`/`detail` slot으로 변환한다. |
| 두 열 304×102 card, frame texture, 76px thumbnail | card가 Godot `Button`의 input shell이고 texture/decorative children은 전부 `MOUSE_FILTER_IGNORE`다. native Button normal/hover/pressed/focus/disabled StyleBox를 모두 비운다. |
| list의 tab/filter는 고정, grid만 scroll | `EntryScrollViewport`만 vertical scroll한다. title, tabs, filters, sort는 scroll하지 않는다. |
| right panel은 panel 자체가 scroll되지 않고 description만 max 66px scroll | hero/facts/detail shell은 fixed geometry다. 긴 locale 문자열은 명명된 bounded region에서만 ellipsis/wrap/inner scroll한다. |
| background/frame는 `background-size:100% 100%`, item art만 contain | frame/background은 `TextureRect.STRETCH_SCALE`, item art는 `STRETCH_KEEP_ASPECT_CENTERED`를 쓴다. `KEEP_ASPECT_COVERED`로 ornament 좌표를 바꾸지 않는다. |

### 1.2 보존할 기능 계약

다음은 시각 교체의 대상이 아니다.

- `ArtifactCodexReadModel.gd`의 discovered/locked projection, canonical catalog order, section 선택 시 selected id 보정
- `ArtifactCodexArtResolver.gd`의 실제 drill/beacon PNG 우선 해석
- reward-table, growth state, starter discovery, debug-all의 기존 의미
- Codex와 settings/shop의 배타성, Codex visibility를 포함한 combat pause 계산, open/close SFX
- mouse selection, keyboard focus, close/Escape, locale rerender
- 전투 중 open/close 후 timer가 중복 pause/resume 되지 않는 기존 흐름

### 1.3 이 계획에서 적용하는 product 기본값

사용자의 명시 요구(선택 화면에서는 메뉴만, run 중에는 run 정보·도감·설정만)를 우선 적용한다. 구현자가 목업의 예시 문구를 새 게임 기능으로 해석하지 않도록 다음을 기본값으로 고정한다.

1. **Topbar 정보 구조:** literal `Expedition / Codex / Archive`를 이식하지 않는다. `MENU`는 `캐릭터 선택 / 레비아탄 선택 / 도감(active) / 설정`만, `RUN`은 `항차 N/M / 구간 N/M / 도감(active) / 설정`만 표시한다. 브랜드, version pill, 80px topbar geometry는 목업 그대로다.
2. **분류와 sort:** 현재 데이터 축은 `all/drill/beacon/relic` 하나뿐이다. 38px tab row와 56px filter-chip row는 이 단일 `active_section`을 동기화해 표현한다. 어느 행을 클릭해도 같은 `section_selected`를 emit한다. sort shell은 목업의 texture/position을 유지하되 read-only `도감 순서`로 비활성화한다. 별도의 taxonomy/sort state와 fake dropdown은 추가하지 않는다.
3. **Debug-all:** 기존 debug-all 의미는 보존하되 production V5 topbar에는 넣지 않는다. 개발/test-only route에서만 접근하도록 하며 baseline 1440×900 geometry를 밀어내지 않는다.
4. **MENU navigation:** Codex 내부에는 page navigation intent를 추가하지 않는다. 메뉴 항목은 현재 page context를 보여주는 chrome이고 close만 제공한다. Character/Leviathan 이동은 Codex 밖의 기존 flow에서만 한다.
5. **Typography:** Work Sans 및 Noto Serif KR 계열 OFL font asset과 license manifest를 project에 포함한다. system Georgia는 optional observation일 뿐 acceptance baseline이 아니다.

---

## 2. 현행 구현 감사와 수정 이유

### 2.1 실제 코드와 기존 계획의 충돌

| 실제 근거 | 위험 | 수정된 계획 |
|---|---|---|
| `src/ui/ArtifactCodexPanelUI.gd`는 `BOOK_TEXTURE`, `BookCenter/BookAspect/BookRoot/Spread`, left detail/right grid, 3-column `EntryGrid`를 실제로 소유한다. | 기존 book tree를 조금 남기면 full-screen mockup의 좌우 ownership, clipping, capture 모두 불명확해진다. | 호환 wrapper를 두지 않고 V5 tree로 한 번에 교체한다. obsolete tree를 검증하는 tests도 동시에 V5 contract로 교체한다. |
| `ArtifactCodexReadModel.gd:14,38–55`는 `SECTION_IDS=[all,drill,beacon,relic]`, `leftPage=detail`, `rightPage.gridEntries`, fixed canonical order를 반환한다. | 목업의 taxonomy·sort를 현재 데이터인 것처럼 구현하면 fake filter / fake sorting이 된다. | UI adapter를 둬서 data field 이름과 visual slot을 분리한다. §1.3의 단일 section-state/disabled canonical-sort 기본값 밖의 product 기능은 구현하지 않는다. |
| `MainViewPanelsRuntime.gd:47–61`은 toggle로 visibility를 반전시키고 `set_artifact_codex_visible`은 단순 `visible=val`이다. | 여러 close route에서 focus/context/SFX/pause가 중복 또는 누락될 수 있다. panel의 현재 close button도 직접 `visible=false`다. | `open_artifact_codex`, `close_artifact_codex`, `render_artifact_codex`로 lifecycle을 단일화한다. 모든 외부 hide 호출은 close API로 migration한다. |
| `MainViewPageShellRuntime.gd:56–83`은 character/leviathan/node page의 no-argument `codex_requested`를 같은 `codex_open_pressed`로 보낸다. global header도 same signal이다. | opener page id/focus/run snapshot이 사라져 frozen contextual chrome을 만들 수 없다. | signal은 유지하되, source page id + actual opener `Control`을 open request에 함께 전달한다. global header는 click 순간 `active_page_id`로 한 번만 context를 만든다. |
| `MainViewRuntimeState.gd:51,136–140`에는 context/opener state가 없다. locale rerender는 `MainViewLocaleRuntime.gd:145–148`에서 model만 다시 render한다. | locale/selection rerender가 open origin을 다시 추론하거나 잃을 위험이 있다. | immutable `ArtifactCodexPresentationContext`를 state에 보관하고 render는 같은 context를 재사용한다. close 때만 clear한다. |
| `MainViewLifecycleRuntime.gd:131–141`는 global header에 Codex button을 추가한다. battle/reward 등의 Codex source도 이 경로를 쓴다. | MENU/RUN context matrix는 local page 3개만 bind해서는 불완전하다. | global header opener 및 battle/boss/reward/event phase 모두 matrix test 대상이다. |
| `project.godot:19–22`는 1440×900, `canvas_items`, `aspect="expand"`이다. | ultrawide에서 full-rect Control만 쓰면 decorative textures와 1px contract가 의도치 않게 늘어난다. | DesignCanvas만 1× center; side gutter에는 parchment/ambient/topbar field만 확장한다. |
| 현재 `ui_codex_reward_board_suite.gd`는 book safe-area/path/3-col tests를 실제로 강제한다. | obsolete layout test를 살리려 compatibility tree를 남기게 된다. | retired structure assertion을 제거하고 V5 geometry/input/context contract로 교체한다. model/art/discovery tests는 유지한다. |

### 2.2 목업 자체의 비기능 요소

- `.audit` CSS는 존재하지만 DOM에는 없으므로 구현 대상이 아니다.
- `Expedition`, `Archive`, `Geological & Botanical Survey`, HTML 예시 card names/facts는 runtime data source가 아니다.
- HTML의 `♧` 및 `⚙` glyph은 font-dependent decorative placeholder다. 런타임에는 text glyph을 우연히 재현하지 않고, 접근성 label이 있는 project-owned icon/control을 쓴다.
- HTML의 `backdrop-filter:blur(8px)`은 Godot compatibility renderer에서 strict하게 동등하지 않다. topbar의 solid color/alpha/border가 screenshot 기준에 맞으면 blur는 optional이며, 화면 backdrop 캡처를 요구하지 않는다.

---

## 3. 확정 가능한 아키텍처

### 3.1 owner map

| 책임 | owner | 금지 |
|---|---|---|
| reward→entry discovery/data projection | `ArtifactCodexReadModel.gd` | V5 pixel metric, texture path, Node 생성 |
| reward item artwork resolution | `ArtifactCodexArtResolver.gd` | locked/discovered policy 변경 |
| V5 metric/fit policy | `src/ui/codex/ArtifactCodexLayoutPolicy.gd` | book constants, reward read |
| immutable origin/chrome/run snapshot | **new** `src/ui/codex/ArtifactCodexPresentationContext.gd` | rerender 때 `active_page_id` 재조회 |
| fonts and named roles | **new** `src/ui/codex/CodexTypography.gd` | system default fallback을 pixel-match로 주장 |
| card/detail visual construction | **new** `src/ui/codex/ArtifactCodexVisualFactory.gd` | reward table read, controller mutation |
| topbar node/action construction | **new** `src/ui/codex/ArtifactCodexChromeFactory.gd` | source page tree 직접 mutation |
| V5 composition/render/signal forwarding | `ArtifactCodexPanelUI.gd` | layout magic number, file read, global nav decision |
| open/close/exclusivity/pause/SFX/focus | `MainViewPanelsRuntime.gd` | visual node construction |
| context request origin binding | `MainViewPageShellRuntime.gd`, lifecycle global header | context recomputation after open |

### 3.2 context contract

`ArtifactCodexPresentationContext.gd`는 immutable Dictionary를 반환하거나 immutable-style `RefCounted` value로 만든다.

```gdscript
{
  "origin_page_id": "node_select",
  "chrome_mode": "RUN", # MENU | RUN
  "run_index": 2, "run_total": 4,
  "stage_index": 3, "stage_total": 5,
  "opener": weakref(opener_control)
}
```

- page id → mode mapping은 한 함수만 소유한다: `character_select`, `leviathan_select` = `MENU`; `node_select`, `battle`, `boss_battle`, `reward`, `boss_reward` = `RUN`.
- `event_node`는 current scene에서 run/stage metadata를 얻을 수 있을 때만 `RUN`이다. metadata가 없으면 Codex open을 no-op + diagnostic으로 막는다.
- `story_scene`, `clear`, `defeat`는 global header Codex action을 hidden/disabled 처리한다. MENU/RUN으로 임의 fallback하지 않는다.
- run/stage number는 `SceneReadModel`/page state의 public fields (`runIndex`, `runCount`, `stageIndex`, `maxStages`)에서 **open 순간** 0-based→1-based로 normalize한다.
- `close_artifact_codex`은 weakref가 살아 있고 visible/focusable이면 opener에 focus를 돌린다. page transition은 하지 않는다.
- locale change와 entry/section/debug rerender는 `current_codex_context`를 다시 만들지 않는다. frozen numeric context를 현재 `TextCatalog` locale로 label화할 뿐이다.

### 3.3 V5 view-model adapter

`ArtifactCodexReadModel`의 public data shape를 불필요하게 깨지 않기 위해 Panel UI 또는 작은 private adapter가 다음만 수행한다.

```gdscript
{
  "catalog": {
    "sections": model.sections,
    "entries": model.rightPage.gridEntries,
    "active_section": model.activeSection,
    "total_count": model.totalCount,
    "discovered_count": model.discoveredCount
  },
  "detail": model.leftPage,
  "selected_entry_id": model.resolvedSelectedEntryId,
  "chrome": chrome_spec
}
```

이 어댑터는 **field rename/slot swap**과 아래 facts contract를 view에 연결하는 일만 한다. section taxonomy 또는 sort behavior를 새로 만들지 않는다.

### 3.4 Detail facts와 locked disclosure 계약

`reward-table.json`의 실제 `payload`에는 `base_cooldown_ticks`, `damage`, 그리고 beacon에 선택적으로 `beacon_cooldown_mod`/`beacon_damage_mod`가 있다. 반면 현재 `ArtifactCodexReadModel.gd`는 rarity/type/energy/shape/factChips만 detail로 project한다. Variant 5 facts panel은 mockup 숫자를 쓰지 않고 다음 순서로 보강한다.

1. `ArtifactCodexReadModel`이 UI-중립 named `facts` array를 만든다. source field와 label key를 함께 소유하고, rendering code가 reward raw payload를 재독하지 않는다.
2. discovered entry에는 rarity, type, energy, shape, base cooldown, base damage와 존재할 때 beacon modifiers를 표시한다. 이 값은 run 중 synergy/effective cooldown이 아닌 catalog base value다.
3. locked entry에는 unrevealed name, rarity, art, numeric stat을 UI model에서도 공개하지 않는다. panel은 locked status와 `—`만 render하며 tooltip/accessible name/focus detail도 같은 disclosure 정책을 따른다.
4. value가 정의되지 않은 entry는 placeholder mock value를 만들지 않고 해당 fact row를 숨긴다. 이를 reward-table fixture와 read-model contract test로 고정한다.

---

## 4. V5 visual contract (1440×900)

### 4.1 Design canvas

- `CodexScreen`: `(0,0,1440,900)`, clip enabled, popup z-index 500.
- screen texture: `screen_parchment_bg_1440x900.png` at exact rect, `STRETCH_SCALE`.
- ambient wash: screen background 위/content 아래, input ignore. radial center `(76%,12%)`, source CSS colors `rgba(255,255,255,.58) → rgba(255,248,245,.20) 34% → rgba(255,241,233,.26)`.
- topbar `(0,0,1440,80)`, z=10, padding 40, `rgba(255,248,245,.91)`, bottom 1px `rgba(66,72,65,.18)`.
- catalog region `(40,118,740,750)`, detail region `(804,118,596,750)`, gap 24, screen right/bottom inset 40/32.
- backgrounds and frames use source texture identity, not rounded `StyleBoxFlat` substitutes. Shadow is supplemental only.

### 4.2 Catalog

- hero: height 128, bottom aligned, margin-bottom 16.
- hero kicker/title/subtitle/count: 13/56/18/30 px and original color/letter spacing values from HTML; title and subtitle come from localization, not the HTML’s prose.
- list panel `(0,144,740,606)`, padding `(36,30,30,30)`, clip enabled.
- section row height 38, bottom divider; operational filter row height 56; both rows render the single synchronized `active_section` from §1.3. sort shell is read-only canonical catalog order.
- viewport begins after these two fixed rows. grid: 2 columns × 304 width, col gap 18, row gap 14, left margin 8.
- card 304×102 with 76×76 thumbnail, 56×56 known art, 64×64 locked plate, 13px name one-line ellipsis, 12px rarity. Selected annotation only on selected card.
- locked card may be clicked/focused only if it reveals **no** unrevealed name/art/rarity in the button accessible name, tooltip, or detail view. It renders locked art/name/status only.

### 4.3 Detail

- outer `(804,118,596,750)`, padding `(42,50,28,50)`, clip enabled.
- title header, status, hero, observation note, facts and description follow the HTML metrics: hero h 304 / extra 22px each side, art 214×214, observation 168×min76; facts h 198 / extra 22px each side; description max 66 internal scroll.
- rarity/type/energy/shape/base cooldown/base damage values use the §3.4 read-model facts contract and must not be fabricated from the mockup. Beacon modifier rows appear only when source data defines them.
- preserve a consistent 3×3 occupancy representation when current shape data permits; larger-than-3×3 shape must use the existing matrix data rather than silently crop. Its detailed visual treatment is a flexible item to validate during implementation.

### 4.4 Asset/import ledger

Copy **only** `LTL-harness/new_design/ltl_codex_redesign/generated/processed/v5/` approved files into `app-LTL/resources/UI/codex/v5/`. The required set is **14 texture families**, not eleven:

1. screen parchment
2. list panel
3. detail panel
4. card normal
5. card selected
6. card locked
7. thumb slot
8. locked thumb
9. active chip
10. inactive chip
11. sort dropdown
12. detail hero frame
13. facts panel
14. observation note

`codex_v5_topbar_bg_2880x160.png` remains excluded: HTML uses a CSS color/border topbar, and the source asset’s own match report rejects it as a usable 1440×80 strip.

Before copying, assert actual PNG dimensions. Godot `.import` side effects are generated by the editor/import pipeline and must not be hand-authored merely to imitate an import.

### 4.5 typography

The browser mockup requests Work Sans + Georgia + Noto Serif KR but the app resources currently contain no `.ttf`/`.otf`. Strict screenshot parity is impossible until font assets are supplied.

구현 시 OFL licensed files plus `resources/fonts/codex/LICENSES.md`를 추가한다:

- `WorkSans-VariableFont_wght.ttf` — UI 10–14px (400/850/900)
- `NotoSerifKR-VariableFont_wght.ttf` — Korean title/editorial roles (400/700)
- `NotoSerif-VariableFont_wght.ttf` — owned Latin serif fallback

`CodexTypography.gd` creates/caches `FontVariation` roles. Georgia can be used only as an observed Windows enhancement, never the sole distributable contract. If it differs from bundled Noto Serif, comparison captures record the difference and the acceptance baseline uses the approved bundled role.

---

## 5. Approval-sized, test-first implementation order

### Task 0 — Baseline/evidence isolation (no production UI edits)

**Files:** request ledger/worklog only after user approval; no current dirty file changes.

1. Capture the supplied HTML at 1440×900 with source path/hash and save visual baseline.
2. Record current worktree status; create isolated worktree/branch without touching the listed unrelated modifications.
3. Create `docs/request-ledgers/2026-07-13-ui-001-codex-v5-runtime-visual-upgrade.md` from `LTL-harness/docs/templates/request-constraint-ledger-template.md`; run its `pre-edit` gate before source edits.
4. Resolve the current source-map prerequisite failure for the two existing Codex harness crops — `LTL-harness/new_design/ltl_codex_redesign/generated/processed/crops/card_empty_placeholder.png` and `card_empty_placeholder_live.png` — by adding truthful producer/responsibility entries before any compile-closeout claim. This is pre-existing harness alignment, not a reason to hide or reset unrelated worktree changes.
5. Verify all 14 processed V5 asset dimensions and obtain the actual OFL font binaries plus license texts; the current checkout has neither `.ttf/.otf` files nor distributable license copies.
6. Reproduce the baseline discovery state used for the reference capture (six cards/one selected red drill only if the actual test fixture produces it).

**Proof:** baseline screenshot + asset manifest + no unrelated diff attributed to this task.

### Task 1 — RED contracts for context, lifecycle, metrics, and V5 tree

**Files:** add focused tests under `tests/ui_read_models/`; modify no production code before RED is observed.

Write and run failing tests for:

- context page-id mapping and frozen run/stage values;
- unsupported `story_scene`/`clear`/`defeat` global Codex action hidden/disabled and metadata-less `event_node` safe no-op;
- `open → rerender(locale/selection) → close` retaining context and restoring opener focus;
- unified close making SFX/pause transition once;
- read-model facts projection from the real reward payload and locked disclosure that reveals no raw stat/rarity/art;
- both visual section rows select and display the same `active_section`; the read-only canonical sort shell cannot mutate the model;
- 1440×900 canvas transform `(0,0), scale 1`; 1280×800 uniform fit; 1920×1080 1× centered;
- V5 tree/path absence of book nodes, exact catalog/detail rectangles, and card input ownership;
- selected/locked accessible text non-leak;
- only grid scrolls and description is bounded inner scroll.

**Proof:** each test fails for the intended missing V5/context behavior, not a script parse error.

### Task 2 — V5 assets, typography, layout policy (GREEN only for Task 1 metric/asset tests)

**Files:**
- Add `resources/UI/codex/v5/*` approved PNGs
- Add approved fonts + `resources/fonts/codex/LICENSES.md`
- Modify `src/ui/codex/ArtifactCodexLayoutPolicy.gd`
- Add `src/ui/codex/CodexTypography.gd`

1. Replace `BOOK_PIXEL_SIZE`, book safe-area functions and book transform with named V5 design constants and `canvas_transform_for_viewport()`.
2. Implement asset existence/dimension validator used by focused test tooling.
3. Load/cache named font roles and test Korean + English glyph layouts.

**Proof:** focused tests green; no panel code owns anonymous pixel constants; 1440×900 metric proof is exact.

### Task 3 — Context/open/close migration (GREEN context/lifecycle tests)

**Files:**
- Add `src/ui/codex/ArtifactCodexPresentationContext.gd`
- Modify `MainViewRuntimeState.gd`, `MainViewRuntime.gd`, `MainViewPanelsRuntime.gd`, `MainViewPageShellRuntime.gd`, `MainViewLifecycleRuntime.gd`, `MainViewLocaleRuntime.gd`, `MainController.gd`, `MainControllerSupportFlow.gd`, `MainControllerRunFlow.gd`, and callers named by search result

1. Add `current_codex_context` and `current_codex_opener`; do not overload selected entry state.
2. Change opener paths to pass context once. Bind local page emitters with literal page ids; global header resolves active page only at click time.
3. Implement idempotent `open_artifact_codex(context, reward_table, growth, debug)`, `close_artifact_codex(reason)`, and `render_artifact_codex()`. During migration, `set_artifact_codex_visible(false)` delegates to close; `set_artifact_codex_visible(true)` is rejected because it has no context. Remove the wrapper after every production/test caller uses explicit open/close.
4. Route close button, Escape, settings/shop exclusivity, external hides, controller phase changes through the single close API.
5. Keep `is_artifact_codex_visible()` and combat pause owner semantics stable while migrating call sites. Delete `toggle_artifact_codex` only after no callers remain.

**Proof:** MENU/RUN context matrix, focus return, same page after close, settings exclusivity, battle timer partial-resume and one open/close SFX tests pass.

### Task 4 — Replace book composition with V5 composition (GREEN V5 tree/input contracts)

**Files:**
- Rewrite `src/ui/ArtifactCodexPanelUI.gd`
- Modify `src/ui/read_models/ArtifactCodexReadModel.gd`
- Add `src/ui/codex/ArtifactCodexVisualFactory.gd`
- Add `src/ui/codex/ArtifactCodexChromeFactory.gd`
- Delete `src/ui/codex/ArtifactCodexBookVisualFactory.gd` only after no preload/caller remains
- Update `ArtifactCodexLayoutPolicy.gd`

1. Build `CodexViewport → DesignCanvas` once in `_ready`; render idempotently.
2. Extend the read model with §3.4 named facts/disclosure contract before rendering V5 details; keep raw reward-table reads out of panel/factory code.
3. Use a V5 view-model adapter to place `rightPage.gridEntries` in the left catalog and `leftPage` in the right detail.
4. Build texture-backed cards with all native button state StyleBoxes explicitly empty; assign only input shell focus/pressed behavior to Button.
5. Implement known/locked art paths, selected annotation, two synchronized section-control rows, disabled canonical-sort shell, grid scroll, hero/facts/shape/description bounded regions. No taxonomy-specific empty state or fabricated card list is added.
6. Ensure every decorative descendant ignores mouse input and card controls own accessibly safe names.

**Proof:** no `BookCenter`, `BookAspect`, `BookRoot`, `Spread`, `ItemBook` runtime paths remain; exact V5 geometry and click/focus contract passes.

### Task 5 — Chrome, navigation decision, locale and scroll (GREEN interaction contracts)

**Files:** primarily `ArtifactCodexChromeFactory.gd`, `ArtifactCodexPanelUI.gd`, `MainViewPanelsRuntime.gd`, i18n JSON only for genuinely missing labels.

1. Implement the §1.3 MENU/RUN chrome matrix; never render both hosts. Hide/disable global Codex on unsupported pages.
2. MENU Codex has no in-panel page navigation. The panel exposes close only and does not reparent or mutate source page headers.
3. Re-render locale without losing selected entry, active section, grid scroll value, or frozen context.
4. Test mouse, Tab/keyboard/controller focus and wheel on card, locked card, viewport, and description.
5. Preserve debug-all through a test/development-only route outside baseline V5 geometry.

**Proof:** Korean/English 1440×900 captures and interaction tests pass without title/card/status overflow or data leakage.

### Task 6 — Test migration, live capture, project gates

**Files:**
- `tests/ui_read_models/ui_codex_reward_board_suite.gd`
- `tests/test_reward_contract.gd`
- `tests/run_main_layout_audit_contract.gd`
- `tests/run_node_select_start_gate_contract.gd`
- `tests/run_leviathan_top_button_group_contract.gd`
- `tests/run_leviathan_select_runtime_contract.gd`
- `tests/godot_contract_runner.gd`
- caller-specific contracts found during Task 3
- add or extend a Codex-aware live capture driver

1. Replace book-only tests, update the contract-runner preload/required-script manifests, and retain reward projection/art resolver/discovery/debug/canonical order coverage.
2. Add/extend a **Codex-aware live capture driver**. The existing `tools/capture-m6-screenshot-matrix.ps1` passes only `--page`/`--viewport` to `tests/run_m6_visual_capture.gd` and cannot prove that Codex was opened through a real opener path. The new driver must invoke Character/Leviathan/Node/Battle open routes, capture the open V5 overlay, and emit both PNG and a success marker.
3. Run the capture matrix through real open paths: Character Select, Leviathan Select, Node Select, Battle open/close; add Reward/Event only after their context route is wired.
4. Compare 1440×900 captures to mockup: frame asset identity exact, panel/card geometry ±1px, calibrated text baselines ±2px. Dynamic data may be masked only after individual bounds/values are separately asserted.
5. Run the smallest focused tests first (`run_test_reward_contract.gd`, `run_codex_pause_timing_contract.gd`, `run_main_layout_audit_contract.gd`, `run_node_select_start_gate_contract.gd`), then `godot_contract_runner.gd`; all through `tools/invoke-godot.ps1` with a named log.
6. Run `source-map-gate.ps1`, the Codex V5 request ledger `pre-complete`, `tools/run-compile-check.ps1 -RequestLedger <V5 ledger>`, and the full quality gate with an artifact ledger. Do not use `-SkipGodotContracts` or `-SkipVisualContracts` for the final claim.

**Proof:** capture evidence is live-runtime, not headless tree-only; no claim of visual completion on compile alone.

---

## 6. Acceptance matrix

| Case | Required result |
|---|---|
| Character Select → Codex | approved MENU chrome only; no run/stage; V5 geometry; close returns to actual opener without page change |
| Leviathan Select → Codex | same MENU behavior; selection/section persist across normal rerender |
| Node Select → Codex | RUN chrome; frozen `run/stage`; no menu-only action; start readiness unaffected after close |
| Battle → Codex | RUN chrome; pause is enabled once; close retains partial timer and does not duplicate SFX |
| Story/Clear/Defeat → global header | Codex action hidden/disabled; no implicit MENU/RUN context is created |
| Event node without run metadata | safe no-op + diagnostic; no partial RUN chrome |
| Settings while Codex open | unified close then settings open; no stale focus/context host visible |
| known card | actual resolved image in 56px thumb / 214px hero, selected texture/annotation present |
| locked card | locked card + locked thumb only; no unrevealed art/name/rarity in visual, focus, tooltip, accessibility or detail surface |
| detail facts | base cooldown/damage come from reward payload through the read model; no mockup value or locked stat disclosure |
| section/sort shell | 상단 section row와 chip row는 `all/drill/beacon/relic` 한 개 state를 동기화한다. sort shell은 `도감 순서`를 표시하는 disabled control이며 query/model 순서를 바꾸지 않는다. |
| locale | Korean/English title/card/status stay inside bounded areas at 1440×900 |
| viewport | 1280×800 fit; 1920×1080 and ultrawide center 1× canvas; no one-column/list-below-detail reflow |

---

## 7. Non-goals / explicit rejections

- Do not fabricate taxonomy, flora/mineral/ruin entries, or sort comparators merely to populate mockup controls. The release uses only the current section data axis and canonical catalog order.
- Do not preserve an `ItemBook` hybrid, book safe-area math, or old 3-column card grid.
- Do not use flat rounded generic panels, emoji substitutions, arbitrary generated originals, or default runtime fonts as pixel-parity replacements.
- Do not implement literal `Expedition/Archive` navigation; §1.3의 context-aware MENU/RUN chrome만 사용한다.
- Do not duplicate Codex/Settings controls as both text and unrelated glyph buttons.
- Do not let `ArtifactCodexPanelUI` read reward-table files or determine discovery; do not let controller construct pixel nodes.
- Do not call a compile or headless scene-tree test proof of visual fidelity without a live capture.

---

## 8. Main risks and mitigations

| Risk | Mitigation |
|---|---|
| Dirty worktree is large and unrelated | isolated worktree; baseline audit; only named files staged |
| Existing test names encode retired book structure | delete/replace their assertions instead of compatibility wrappers |
| context drifts after rerender | immutable open-time context; clear exclusively in unified close |
| one close route bypasses pause/SFX/focus | migrate all callers, test idempotent close and visibility transition count |
| exact browser font unavailable | bundle OFL fonts and accept only capture-calibrated baseline |
| texture frame is stretched incorrectly | exact source dimensions + `STRETCH_SCALE` contracts; art only keeps aspect |
| HTML fake sort/category becomes dead UI | one real section state drives both visual rows; sort shell is explicitly disabled at canonical order |
| long localized shape/facts overflow | bounded field policy and locale capture before declaring green |
