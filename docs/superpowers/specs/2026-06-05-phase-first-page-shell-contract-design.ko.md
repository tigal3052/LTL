# 2026-06-05 Phase-First Page Shell Contract Design

Date: 2026-06-05  
Workspace: `LootingTheLeviathan`

## 목적

현재 `Main.tscn` / `MainViewRuntime.gd` 기반 UI 셸을 `phase-first page shell` 기준으로 재정의한다.

이번 문서는 단순 와이어프레임 목록이 아니라, 런 전체를 구성하는 페이지 계약과 전역 오버레이 정책, HTML 목업 범위, 하네스 설계 변경 방향을 고정하는 별도 설계 문서다.

이 문서는 [2026-06-05-m6-wireframe-mockups-design.ko.md](/D:/Programming/ex_workspace/LootingTheLeviathan/docs/superpowers/specs/2026-06-05-m6-wireframe-mockups-design.ko.md:1)의 상위 계약 문서다.  
앞선 문서가 `목업 형식`을 정의했다면, 이 문서는 `무슨 페이지를 어떤 규칙으로 만들 것인가`를 정의한다.

## 현재 구조 진단

### 1. 전투 HUD와 전역 메타 패널은 픽셀 충돌보다 구조 충돌이 더 크다

현재 셸에서는 다음 요소가 같은 런타임 계층에 놓여 있다.

- 전투 HUD와 상태 패널
- `SettingsPanel`
- `ArtifactCodexPanel`
- `ShopPanel`
- `ConfirmOverlay`
- `RepairOverlay`

특히 `MainViewRuntime.gd`는 설정과 유물도감을 `combat overlay pause`의 일부처럼 취급한다.

즉, 현재 문제는 “전투 HUD가 설정창과 몇 픽셀 겹치는가”보다 다음에 가깝다.

- 전투용 정보 셸과 전역 메타 패널이 같은 헤더 액션 정책으로 열림
- 페이지별 주인공 패널이 고정되지 않음
- `TopContent`, `ActivePhaseContainer`, `backpack reparent`가 페이지가 늘수록 복잡도를 누적시킴
- layout audit도 page contract보다 shell containment 쪽에 더 묶여 있음

### 2. 전투 외 페이지는 아직 page-first contract가 아니다

현 구조에서 `node_select`, `reward_loot`, `codex`, `settings`는 모두 같은 메인 셸 내부 패널 전환이나 오버레이로 처리된다.

이 방식은 초기 구현에는 유리했지만, 다음 요구사항을 담기 어렵다.

- 런 시작 페이지
- 이벤트 노드 페이지
- 보스 보상 선택 페이지
- 패배 연출 페이지
- 보상 수령 페이지의 고정형 상세 정보 패널

따라서 이번 M6 재설계에서는 `전투 HUD만 고치는 방식`이 아니라 `런 전체 페이지를 명시적으로 정의하는 방식`이 필요하다.

## 승인된 방향

승인된 방향은 `Phase-first page shell`이다.

핵심 원칙은 다음과 같다.

- 페이지마다 `주인공 패널`이 하나만 존재해야 한다.
- 전투 페이지는 현행 전투 레이아웃을 최대한 유지한다.
- 전역 메타 패널 접근 권한은 페이지별로 다르게 설정한다.
- 페이지 계약이 먼저이고, 개별 목업과 하네스는 그 계약을 따라간다.

## 전역 정책

### 헤더 정책

공통 헤더는 다음 역할만 담당한다.

- `run progress`
- `page title`
- `settings`

다음 액션은 비전투 페이지 전용으로 제한한다.

- `artifact codex`
- `shop`

### 오버레이 접근 정책

- `settings`
  - 모든 페이지에서 허용
  - 단, 전투에서는 유일하게 허용되는 전역 메타 패널
- `artifact codex`
  - `run_start`, `node_select`, `reward_claim`에서 허용
  - `combat`, `boss_combat`, `reward_reveal`, `defeat`에서는 비허용
- `shop`
  - 비전투 페이지에서만 허용
  - 구체적으로는 `node_select` 중심, 필요 시 `run_start`까지 확장 가능
- `confirm` / `repair`
  - 전투나 보상 문맥에 종속된 상황형 오버레이로 유지

### 페이지 우선 원칙

한 페이지에서 가장 중요한 정보층 하나만 중심에 둔다.

- 전투: HUD + 전장
- 노드 선택: 런 경로와 노드 비교
- 보상 수령: 보상 목록 + 상세 패널 + 백팩
- 이벤트: 대형 이미지 + 선택지
- 패배: 패배 연출 + 재시작 CTA

## 페이지 계약

이번 재설계에서 셸이 지원해야 하는 페이지는 9개다.

1. `run_start`
2. `node_select`
3. `combat`
4. `reward_reveal`
5. `reward_claim`
6. `event_node`
7. `boss_combat`
8. `boss_reward_pick`
9. `defeat`

아래 내용이 페이지별 source-of-truth다.

## 1. `run_start`

### 목적

런 시작 전 `캐릭터 선택`, `시작 유물 선택`, `시작 백팩 구성`을 한 화면에서 완료한다.

### 주인공 패널

`캐릭터 선택 + 시작 유물/백팩`

### 필수 구성

- 좌측: 캐릭터 리스트 또는 캐릭터 선택 카드 열
- 중앙: 선택한 캐릭터의 대형 패널
- 우측: 시작 유물 후보와 시작 백팩 미리보기
- 하단: `런 시작` CTA

### 전역 액션 정책

- `settings`: 허용
- `artifact codex`: 허용
- `shop`: 비허용

### 목업 구현 포인트

- 캐릭터 선택은 세로 리스트나 카드 스택 중 하나로 정리
- 시작 유물은 `선택 후보`와 `백팩 반영 결과`가 한 화면에서 같이 보여야 함
- 시작 백팩은 실제 전투용 거대 패널이 아니라 `준비 상태를 읽는 preview grid` 성격이어야 함

## 2. `node_select`

### 목적

현재 런의 진행도와 다음 노드 선택지를 `한눈에` 이해하게 한다.

### 주인공 패널

`런 경로`

### 필수 구성

- 상단 진행도:
  - `Run 1/5`
  - `Stage 6/25`
- 메인 경로 라인:
  - 시작 노드
  - 지나온 노드
  - 현재 선택 가능한 노드 5개
  - 앞으로 남은 구간은 `?`로 표기된 단일 노드 체인
  - 마지막은 보스전 노드
- 하단 또는 우측: 선택 노드 상세 패널

### 노드 구조 규칙

사용자 요구사항 기준 표현은 다음과 같이 고정한다.

- `시작노드 -> 지나온 노드들 -> 현재 선택지 5개 -> 남은 ? 노드 체인 -> 보스전`

이 페이지는 기존 `NodeMapScene`의 후보 카드 나열보다 더 강하게 `런 전체 길이`를 보여줘야 한다.

### 백팩 정책

`node_select`의 백팩은 더 이상 항상 큰 우측 동반 패널로 붙지 않는다.

권장 방향:

- 기본: 축소형 loadout summary 또는 닫힌 상태
- 필요 시: 열리는 보조 패널

즉, 전투처럼 큰 실사용 백팩이 아니라 `참조형 loadout surface`로 취급한다.

### 전역 액션 정책

- `settings`: 허용
- `artifact codex`: 허용
- `shop`: 허용

## 3. `combat`

### 목적

현행 전투 레이아웃을 유지하되, 전역 메타 패널 접근 정책만 재정의한다.

### 주인공 패널

`전투 HUD + 전장`

### 유지 정책

- 기존 전투 HTML은 구현 대상에서 제외
- 기존 전투 HUD 개선 작업은 별도 M6 HUD 작업으로 유지

### 전역 액션 정책

- `settings`: 허용
- `artifact codex`: 비허용
- `shop`: 비허용

### 핵심 결론

전투 페이지에서는 HUD가 전역 메타 패널과 경쟁하지 않아야 한다.  
설정만 예외적으로 허용하고, 도감/상점은 전투 흐름에서 제거한다.

## 4. `reward_reveal`

### 목적

기존 보상 연출을 `cinematic page`로 명시적으로 취급한다.

### 주인공 패널

`reward ceremony`

### 정책

- 현재 보상 연출 구조는 유지
- HTML 목업은 이번 라운드에서 구현하지 않음
- 페이지 계약상으로만 분리 정의

### 전역 액션 정책

- `settings`: 원칙적으로 비권장
- `artifact codex`: 비허용
- `shop`: 비허용

이 페이지는 읽기보다 `연출 집중`이 우선인 예외 페이지다.

## 5. `reward_claim`

### 목적

획득한 보상 유물의 목록 확인, 상세 읽기, 시너지 판단, 백팩 배치, 파기를 한 화면에서 수행한다.

### 주인공 패널

`보상 목록 + 상세 정보 + 백팩`

### 필수 구성

- 좌측: 수령한 보상 유물 목록
  - 이미지 중심
  - 선택 상태 명확
- 중앙: 백팩 배치 공간
- 우측: 상세 정보 패널
- 별도: 파기 영역

### 핵심 UX 변경

기존 방식:

- 백팩에서 아이템 마우스오버 시 툴팁 패널에 정보 표시

새 방식:

- 아이템 클릭 시 우측 `상세 정보 패널`에 고정 표기

### 상세 패널이 보여야 할 내용

- 유물 이름
- 종류와 희귀도
- 효과
- 시너지
- 차지/쿨다운 또는 활성 조건
- 크기와 도형 정보
- 배치 힌트

### 전역 액션 정책

- `settings`: 허용
- `artifact codex`: 허용
- `shop`: 비허용

### 핵심 결론

이 페이지는 `툴팁 기반`이 아니라 `인스펙터 기반` 페이지다.  
읽기 안정성이 중요하므로, hover보다 click-to-inspect가 우선이다.

## 6. `event_node`

### 목적

서사와 선택지를 명확하게 전달한다.

### 주인공 패널

`대형 이벤트 이미지 + 선택지`

### 필수 구성

- 중앙 또는 상단: 큰 이벤트 이미지
- 하단: 선택지 버튼 패널
- 선택지별 리스크/결과 힌트 블록은 보조적으로 허용

### 전역 액션 정책

- `settings`: 허용
- `artifact codex`: 비허용 또는 제한적 허용
- `shop`: 비허용

권장 기본값은 `도감 비허용`이다. 이벤트 집중도를 지키기 쉽다.

## 7. `boss_combat`

### 목적

일반 전투와 같은 구조를 유지하면서, `지형 자체가 보스`라는 감각을 추가한다.

### 주인공 패널

`전투 HUD + 보스전 전장 연출층`

### 필수 정책

- 일반 전투 페이지와 같은 레이아웃 기반 유지
- HTML 목업은 이번 라운드에서 구현하지 않음
- 보스전 전용 차별화 포인트만 계약으로 정의

### 보스전 연출 아이디어

몬스터 이미지를 두지 않는 대신, 다음 요소로 보스전 느낌을 만든다.

- 화면 외곽 `심해 압력 링`
- 일반 hazard보다 느리고 무거운 `지각 진동 pulse`
- 상단 `Leviathan Core Depth` 또는 `Crust Pressure` 전용 스트립
- 특정 간격으로 전장을 훑는 `거대 판독선`
- 셀 단위가 아니라 전장 전체가 살아 있는 듯한 `구조적 맥동`

### 전역 액션 정책

- `settings`: 허용
- `artifact codex`: 비허용
- `shop`: 비허용

## 8. `boss_reward_pick`

### 목적

보스전 승리 후 랜덤 보상 3개 중 1개를 확정 선택한다.

### 주인공 패널

`3개 선택 카드 비교`

### 필수 구성

- 중앙 3카드
- 선택 카드 강조
- 하단 또는 측면 상세 설명
- `선택 확정` CTA

### 디자인 방향

- `Slay the Spire`의 relic pick처럼 즉시 비교 가능해야 함
- 단, 시각 언어는 LTL의 채굴/유물 질감에 맞춘다

### 전역 액션 정책

- `settings`: 허용
- `artifact codex`: 비허용 또는 제한적 허용
- `shop`: 비허용

권장 기본값은 `도감 비허용`이다. 3개 선택 판단에 집중시키기 쉽다.

## 9. `defeat`

### 목적

패배 감정 전달과 재도전 유도

### 주인공 패널

`패배 연출 + restart CTA`

### 필수 구성

- 캐릭터 패널 확대
- 패러글라이딩 탈출 애니메이션
- 대형 `GAME OVER`
- 중앙 `다시하기` 버튼
- 보조 문구:
  - 실패 원인 1줄
  - 다음 시도 힌트 1줄

### 전역 액션 정책

- `settings`: 허용 가능
- `artifact codex`: 비허용
- `shop`: 비허용

## HTML 목업 대상 범위

이번 라운드에서 HTML 목업을 생성해야 하는 페이지는 다음과 같다.

- `run_start`
- `node_select`
- `reward_claim`
- `event_node`
- `boss_reward_pick`
- `defeat`

이번 라운드에서 HTML 미구현 유지 대상은 다음과 같다.

- `combat`
- `reward_reveal`
- `boss_combat`

## HTML 페이지 구성 계획

생성 예정 HTML 파일은 다음을 기준으로 한다.

- `docs/mockups/m6-run-start-wireframe.html`
- `docs/mockups/m6-node-select-run-flow-wireframe.html`
- `docs/mockups/m6-reward-claim-wireframe.html`
- `docs/mockups/m6-event-node-wireframe.html`
- `docs/mockups/m6-boss-reward-pick-wireframe.html`
- `docs/mockups/m6-defeat-page-wireframe.html`

공통 규칙:

- 문서형 헤더
- 큰 중앙 와이어프레임
- 번호형 주석
- 구현 포인트 메모
- 페이지 계약과 직접 연결되는 용어 사용

## 하네스 설계 수정 방향

현재 layout audit는 주로 다음을 검증한다.

- visible control viewport containment
- node select map/backpack split
- combat top-content bounds
- overlay top-layer behavior
- reward tray bounds

이제는 `page contract`를 기준으로 하네스를 재구성해야 한다.

## 하네스 재설계 원칙

### 1. phase가 아니라 page contract를 검증한다

기존:

- `combat layout`
- `node_select layout`
- `reward tray layout`

앞으로:

- `run_start page contract`
- `node_select page contract`
- `reward_claim page contract`
- `event_node page contract`
- `boss_reward_pick page contract`
- `defeat page contract`

### 2. visible/hidden contract를 명시한다

각 페이지에 대해 다음을 검증한다.

- 반드시 보여야 하는 핵심 패널
- 반드시 숨겨져야 하는 패널
- 허용되는 전역 액션
- 금지되는 전역 액션

예시:

- `combat`
  - visible: battlefield, combat hud, settings button
  - hidden or disabled: codex button, shop button
- `reward_claim`
  - visible: reward list, backpack, detail panel, discard zone
  - hidden: battlefield

### 3. 상호작용 contract도 검증한다

하네스는 단순 배치뿐 아니라 다음도 검증해야 한다.

- `reward_claim`에서 아이템 선택 시 hover tooltip 대신 detail panel이 갱신되는가
- `node_select`에서 5개 선택지와 남은 `?` 구간이 구분되는가
- `run_start`에서 캐릭터 선택과 시작 유물 선택이 동시에 읽히는가

### 4. overlay policy를 검증한다

페이지별로 다음을 테스트해야 한다.

- 전투 중 codex/shop 차단
- 비전투 페이지에서 codex 허용
- settings는 항상 top-layer

## 하네스 구현 계획

### 1차 수정

- `run_main_layout_audit_contract.gd`를 page-contract 중심 이름과 책임으로 재편
- phase별 containment 검증을 페이지별 visibility contract 검증으로 확장

### 2차 추가

신규 또는 분리된 테스트 러너 후보:

- `run_page_shell_contract_audit.gd`
- `test_run_start_page_smoke.gd`
- `test_reward_claim_page_smoke.gd`
- `test_event_node_page_smoke.gd`
- `test_boss_reward_pick_page_smoke.gd`
- `test_defeat_page_smoke.gd`

### 3차 정리

`NodeMapReadModel`, `PhaseLayoutPresenter`, `MainViewRuntime`의 책임도 page contract 기준으로 다시 나눈다.

예상 방향:

- `PhaseLayoutPresenter`
  - phase label projection만이 아니라 `page id`, `allowed overlays`, `header action visibility`까지 투영
- `MainViewRuntime`
  - 단일 셸에서 page root visibility를 관리
- read-model layer
  - `node_select`와 `reward_claim` 등 페이지별 모델로 분리 강화

## 구현 우선순위

1. 별도 page-shell contract spec 고정
2. harness 설계 변경 계획 반영
3. HTML 목업 6종 제작
4. page contract 기반 셸/레이아웃 구현 계획 작성

## 설계 결론

승인된 최종 방향은 다음과 같다.

- 전투 HUD와 설정/도감 문제는 `전투 HUD 자체`보다 `전역 메타 패널 정책`의 문제로 본다.
- 전체 런 인터페이스는 `phase-first page shell`로 재구성한다.
- `run_start`부터 `defeat`까지 9개 페이지 계약을 명시적으로 정의한다.
- `combat`, `reward_reveal`, `boss_combat`은 이번 라운드에서 HTML 미구현 유지다.
- `run_start`, `node_select`, `reward_claim`, `event_node`, `boss_reward_pick`, `defeat`는 HTML 목업 대상이다.
- 하네스는 `layout audit` 중심에서 `page contract audit` 중심으로 이동해야 한다.
