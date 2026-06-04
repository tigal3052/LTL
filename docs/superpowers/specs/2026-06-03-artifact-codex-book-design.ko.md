# 아티팩트 도감 책형 UI 리디자인

Date: 2026-06-03
Workspace: `LootingTheLeviathan`

## 목표

현재의 텍스트 목록형 유물 도감을 `책을 펼친 고급 수집 UI`로 교체한다.

새 도감은 다음을 만족해야 한다.

- [`ItemBook.png`](/D:/Programming/ex_workspace/LootingTheLeviathan/app-LTL/resources/UI/ItemBook.png) 를 실제 배경 프레임으로 사용한다.
- 좌측은 선택된 유물의 상세 전시 페이지, 우측은 수집 목록 선택 페이지로 역할을 명확히 나눈다.
- 우측 목록은 큰 썸네일을 적게 배치하는 저밀도 그리드로 구성하고, 카드에는 `이미지 + 등급`만 남긴다.
- 실제 유물 일러스트 PNG가 아직 없는 단계에서도 placeholder와 fallback이 자연스럽게 동작한다.
- 기존 `resources/UI` 자산의 작은 블록형 타일, 금속, 핀 질감과 시각 문법을 유지한다.
- 책 배경과 내부 UI가 어긋나지 않도록, 배경 전체가 아니라 `책 내부 페이지`만 기준으로 레이아웃과 스크롤을 설계한다.

## 현재 문제

- 현행 [`ArtifactCodexPanelUI.gd`](/D:/Programming/ex_workspace/LootingTheLeviathan/app-LTL/src/ui/ArtifactCodexPanelUI.gd)는 `RichTextLabel` 하나에 긴 텍스트를 출력하는 구조라, 도감이 아니라 로그/설정 패널처럼 보인다.
- 현재 UI는 `entries` 데이터를 이미 받지만, 텍스트 블록으로만 소비하므로 선택-상세-수집의 정보 구조가 화면에 드러나지 않는다.
- 책 배경 이미지를 곧바로 얹기만 하면 중앙 제본부, 바깥 장식, 이끼 프레임과 내용이 겹쳐 보일 위험이 크다.
- 썸네일 카드가 촘촘하면 책형 도감의 전시감이 약해지고, 좌측 상세 페이지도 관리 화면처럼 보이기 쉽다.
- 실제 아트가 아직 없어도 고급스럽게 보여야 하는데, 단순 회색 박스나 텍스트 목록은 프로토타입 인상을 강화한다.

## 승인된 방향

승인된 방향은 `A형 좌측 상세 전시 + C형 우측 큰 트로피 그리드` 하이브리드안이다.

- 좌측 페이지는 `Illustrated Folio`처럼 하나의 유물을 크게 읽는 전시 페이지다.
- 우측 페이지는 `Trophy Cabinet`처럼 큰 썸네일을 적게 배치하는 선택 페이지다.
- 우측 카드는 이름과 설명을 제거하고, 이미지와 등급만 보여준다.
- 선택 결과는 좌측 상세 페이지로 즉시 반영된다.
- 책 전체는 고정하고, 좌우 페이지 내부만 독립적으로 스크롤한다.

참조 목업:

- 방향 비교: [codex-book-approaches.html](/D:/Programming/ex_workspace/LootingTheLeviathan/docs/mockups/codex-book-approaches.html)
- 승인 반영안: [codex-book-hybrid.html](/D:/Programming/ex_workspace/LootingTheLeviathan/docs/mockups/codex-book-hybrid.html)

## 레이아웃 원칙

### 책이 본체, 카드와 핀은 고정 장치

책의 양피지, 가죽, 덩굴, 제본 장식이 전체 화면의 본체다.

- 넓은 면과 분위기는 책이 담당한다.
- 타일/금속/핀 자산은 `페이지를 잡아주는 하드웨어`처럼만 사용한다.
- 카드 프레임이 책보다 먼저 보이면 안 된다.

### 좌우 페이지 역할 분리

좌측은 `읽는 페이지`, 우측은 `고르는 페이지`다.

- 좌측 페이지
  - 대표 유물 전시
  - 이름
  - 등급
  - 핵심 속성 3줄 내외
  - 설명문
  - 획득처 또는 상태 칩
- 우측 페이지
  - 분류 탭
  - 발견 수 카운터
  - 저밀도 수집 그리드
  - 카드에는 썸네일과 등급만 노출

우측 카드에서 정보를 많이 보여주지 않는다. 책형 도감의 고급감은 `목록의 여백`과 `좌측 전시 집중도`에서 나온다.

## 책 내부 안전 영역

기준 해상도는 `1464x1074`다.

하드 세이프 영역은 다음 비율을 기준으로 잡는다.

- 좌우: `7.2%`
- 상단: `10.5%`
- 하단: `9.5%`

실측 기준으로는 대략 다음 범위다.

- 좌우: 약 `105px`
- 상단: 약 `113px`
- 하단: 약 `102px`

이 값들은 `1464x1074` 기준의 설명용 실측값일 뿐이고, 구현 상수로 하드코딩하지 않는다.

- 실제 런타임 레이아웃은 비율 기반 safe area 계산으로 결정한다.
- 픽셀 값은 검토용 기준선으로만 사용한다.
- 해상도나 책 표시 크기가 달라져도 같은 비율 규칙이 유지되어야 한다.

추가 규칙:

- 중앙 제본부는 별도 금지 구역으로 두고 `전체 폭의 4.5%` 정도를 비워 둔다.
- 좌우 페이지 비중은 `45 : 55`를 기본값으로 사용한다.
  - 구현 비율 기준: `0.90fr : 1.10fr`
- 각 페이지 안쪽에는 다시 `컴포트 패딩`을 둔다.
  - 바깥쪽: `5.5%`
  - 제본쪽: `6.5~7%`
  - 상단: `5%`
  - 하단: `4.5%`

구현 원칙:

- safe area와 gutter는 현재 표시 중인 책 rect에서 계산한다.
- `105 / 113 / 102px` 같은 기준값으로 직접 margin을 박지 않는다.
- 필요하다면 최소/최대 클램프를 두더라도, 기준은 비율 계산 결과여야 한다.

즉, `책 배경 기준 하드 세이프 영역`과 `페이지 내부 읽기 영역`을 분리해서 생각해야 한다.

## 좌측 상세 페이지 설계

좌측 페이지는 선택된 유물의 전시와 독서를 담당한다.

권장 구성 비율:

- 상단 8%: 카테고리 리본 또는 계열 라벨
- 중단 40~42%: 대표 이미지 영역
- 그 아래 8~10%: 유물 이름 + 등급
- 그 아래 12~14%: 핵심 속성 3줄
- 하단 20~22%: 설명문
- 맨 아래 6% 내외: 획득처, 발견 상태, 보조 칩

상세 원칙:

- 대표 이미지 영역은 `발굴 진열창`처럼 보여야 한다.
- 이름과 등급은 좌측에서 가장 빠르게 식별 가능해야 한다.
- 설명문은 길어도 괜찮지만, 스크롤은 설명 영역 또는 좌측 페이지 내부에서만 처리한다.
- 중앙 제본부 쪽에는 작은 텍스트나 버튼을 두지 않는다.

## 우측 수집 페이지 설계

우측 페이지는 탐색과 선택을 담당한다.

상단 구조:

- 필터 탭
- 분류 전환
- 발견 수 카운터

하단 구조:

- 큰 썸네일 저밀도 그리드

기본 그리드:

- `3열 x 2행`을 기본값으로 한다.
- 한 화면에는 약 6장의 카드만 보여준다.
- 카드에는 `이미지 + 등급 배지`만 둔다.
- 카드에 이름, 설명, 수치, 태그는 넣지 않는다.

선택 원칙:

- 선택된 카드는 강한 외곽광 대신 `차가운 밝기`, `1~2px 들뜸`, `코너 점등`으로 표현한다.
- 선택된 카드의 이름과 상세는 좌측에서 즉시 보여야 한다.
- 잠긴 카드도 그리드에는 남기되, 좌측 상세는 `봉인됨 / 미기록 / 발굴 전` 계열의 잠금 상태로 투영한다.

## 스크롤 정책

책형 UI의 핵심 규칙은 `책 전체가 스크롤되지 않는다`는 점이다.

정책:

- 책 프레임 전체는 고정
- 좌측 페이지는 기본적으로 비스크롤
- 좌측 설명문이 길 때만 상세 페이지 내부 스크롤 허용
- 우측은 `헤더/탭 고정 + 그리드 영역만 스크롤`
- 우측 그리드 스크롤 위치는 좌측 상세가 바뀌어도 유지
- 가로 스크롤은 금지
- 스크롤바는 프레임 외곽이 아니라 패딩 안쪽 거터에 배치

이 규칙을 깨면 배경과 내부 UI가 따로 노는 느낌이 강해진다.

## 그래픽 시스템

### 재질 언어

그래픽 시스템의 기준 문장은 `책이 본체, 타일/핀/금속은 고정 장치`다.

- 책 페이지는 유기적이고 따뜻해야 한다.
- 카드 프레임은 기계적이고 단단해야 한다.
- 유기 요소(이끼, 덩굴, 가죽)는 큰 배경 프레임에만 남기고, 우측 카드 그리드에는 반복하지 않는다.

### 좌측 대표 프레임

- 큰 타일 프레임을 그대로 확대해서 쓰지 않는다.
- 가는 금속 내곽선
- 4코너 블록 캡
- 핀 1개 내외의 고정 장치
- 아주 약한 원형 채광 또는 먼지 헤이즈

대표 이미지가 주인공이고, 프레임은 보조다.

### 우측 카드 프레임

- 작은 금속 샘플 플레이트처럼 보이게 한다.
- 검은 금속 본체
- 황동 모서리
- 색상별 코너 점등 또는 미세한 내광
- 카드 내부는 여백을 두어 유물 실루엣이 숨 쉬게 한다.

### 상태별 표현

- 기본 상태
  - 종이와 금속 프레임은 조용하다.
  - 유물 이미지가 우선이다.
- Hover
  - 금속 하이라이트가 살짝 살아난다.
  - 코너 광원이 10~15% 정도만 밝아진다.
- Selected
  - 카드가 미세하게 떠오른다.
  - 차가운 내곽선 또는 코너 라이트가 점등된다.
  - 좌측 대표 프레임과 색 리듬이 연결된다.
- Locked
  - 채도 제거
  - 명도 압축
  - 아이콘 흐림 또는 봉인판 실루엣
  - 명칭 마스킹

### 등급 표현

등급은 카드 전체 색칠이 아니라 `금속 재질 + 코너 부품 + 작은 배지`로 해결한다.

- Common: 기본 황동
- Rare: 청동 + 청색 계열 강조
- Epic: 보라 계열 강조
- Legendary / Mythic: 밝은 금속 + 더 깊은 내광 + 추가 코너 부품

## 피해야 할 것

- 책 배경 위에 기존 타일 프레임을 원본에 가깝게 크게 확대해 쓰는 것
- 플랫한 현대 UI 또는 SF 네온 패널식 외곽광
- 카드 전체를 rarity 색으로 칠하는 방식
- 핀 자산을 장식처럼 남발하는 것
- 덩굴/이끼/가죽 디테일을 카드마다 반복하는 것
- 우측 카드에 이름, 설명, 태그, 배지, 수치를 모두 우겨 넣는 과밀 배치
- 책 전체를 스크롤시키는 구조
- 제본부와 장식 프레임 위에 텍스트/버튼을 배치하는 것

## 데이터 및 기술 설계

기존 구조는 유지하되, `text` 중심 출력 대신 `book` 구조를 추가한다.

현행 흐름:

- [`ArtifactCodexReadModel.gd`](/D:/Programming/ex_workspace/LootingTheLeviathan/app-LTL/src/ui/read_models/ArtifactCodexReadModel.gd)
- [`ArtifactCodexPanelUI.gd`](/D:/Programming/ex_workspace/LootingTheLeviathan/app-LTL/src/ui/ArtifactCodexPanelUI.gd)
- [`MainViewRuntime.gd`](/D:/Programming/ex_workspace/LootingTheLeviathan/app-LTL/src/ui/MainViewRuntime.gd)

권장 model shape:

```gdscript
{
  "title": String,
  "totalCount": int,
  "discoveredCount": int,
  "activeSection": String,
  "resolvedSelectedEntryId": String,
  "debugAll": bool,
  "sections": Array,
  "entries": Array,
  "leftPage": Dictionary,
  "rightPage": Dictionary,
  "text": String
}
```

핵심 정책:

- `text`는 호환용 fallback으로 남긴다.
- `entries`는 원본 목록 source of truth로 유지한다.
- `leftPage`, `rightPage`는 `entries`의 파생 결과다.
- 선택 상태는 `selectedEntryId`, `activeSection`, `debugAll`을 runtime이 소유하고, projector가 `resolvedSelectedEntryId`를 반환한다.

## 아트 슬롯 및 fallback 설계

실제 Texture를 read model에 직접 넣지 않는다.

대신 다음 성격의 descriptor를 내려준다.

```gdscript
{
  "path": String,
  "placeholderId": String,
  "fallbackChain": Array,
  "state": String
}
```

권장 fallback 체인:

1. 명시적 codex art 경로
2. `presentation.icon` resolver
3. `itemType + energyType` 기반 placeholder
4. 전역 missing art

`hero`와 `thumb`는 분리한다.

- `hero_missing`
- `hero_locked`
- `thumb_missing`
- `thumb_locked`

아트 해상과 캐시는 신규 `ArtifactCodexArtResolver.gd`가 맡는다.

## 파일 책임 분리

- [`ArtifactCodexReadModel.gd`](/D:/Programming/ex_workspace/LootingTheLeviathan/app-LTL/src/ui/read_models/ArtifactCodexReadModel.gd)
  - reward table + growth state + UI state를 projection
  - file access, texture load, node 참조 금지
- `ArtifactCodexArtResolver.gd` 신규
  - hero/thumb 아트 경로 결정
  - fallback policy
  - `ResourceLoader.exists` 기반 캐시
- [`ArtifactCodexPanelUI.gd`](/D:/Programming/ex_workspace/LootingTheLeviathan/app-LTL/src/ui/ArtifactCodexPanelUI.gd)
  - 책 껍데기와 좌우 페이지 컨트롤 구성
  - texture 적용
  - signal emit
- [`MainViewRuntime.gd`](/D:/Programming/ex_workspace/LootingTheLeviathan/app-LTL/src/ui/MainViewRuntime.gd)
  - visible/debug/section/selectedEntry 상태 소유
  - projector 재호출
  - locale 재렌더
  - 열기/닫기 orchestration
- [`TextCatalog.gd`](/D:/Programming/ex_workspace/LootingTheLeviathan/app-LTL/src/ui/TextCatalog.gd)
  - section label, locked hint, missing art 문구 추가

파일 크기가 커질 조짐이 보이면 좌우 페이지를 분리한다.

- `ArtifactCodexDetailPageUI.gd`
- `ArtifactCodexGridPageUI.gd`

## 구현 대상 파일

- `app-LTL/src/ui/ArtifactCodexPanelUI.gd`
- `app-LTL/src/ui/read_models/ArtifactCodexReadModel.gd`
- `app-LTL/src/ui/MainViewRuntime.gd`
- `app-LTL/src/ui/TextCatalog.gd`
- `app-LTL/src/ui/ArtifactCodexArtResolver.gd` 신규
- 필요 시 좌우 페이지 분리 UI 파일 신규
- 관련 UI smoke / contract test 파일

## 테스트 타깃

read model 검증:

- section count
- resolvedSelectedEntryId
- locked entry projection
- fallback descriptor state
- debug toggle 후 selection normalize

UI smoke 검증:

- 좌우 페이지 루트 존재
- 페이지별 scroll 분리
- 우측 헤더 고정
- 카드 선택 시 좌측 상세 갱신
- 잠금 silhouette 또는 봉인 상태 표시

runtime 통합 검증:

- codex open 시 초기 선택 결정
- debug checkbox 토글 후 재렌더
- locale 변경 후 selection 유지
- ESC / close 동작
- shop/settings 와 visibility 상호 배타 유지

리사이즈 검증:

- 16:9
- 16:10
- 좁은 창 폭
- 제본부 침범 여부
- 썸네일 겹침 여부
- 스크롤바가 페이지 밖으로 튀지 않는지

## 최종 디자인 결정

승인된 최종 방향은 다음과 같다.

- `ItemBook.png`를 실제 배경 프레임으로 사용한다.
- 좌측 페이지는 A형 상세 전시 구조를 사용한다.
- 우측 페이지는 C형 큰 썸네일 저밀도 그리드를 사용한다.
- 우측 카드는 `이미지 + 등급`만 노출한다.
- 책 전체는 고정하고, 페이지 내부에서만 스크롤한다.
- 카드 프레임과 상태 표현은 기존 타일/핀/금속 자산 문법을 따르되, 책보다 먼저 튀지 않게 절제한다.
