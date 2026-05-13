# Design

## 디자인 목표

LTL의 화면은 `거대 생명체의 외피를 뚫는 채굴 작전`처럼 보여야 합니다. 동시에 플레이어가 3x10 파동, 에너지 큐, 백팩 시너지, 4핀 시간 압박을 즉시 읽을 수 있어야 합니다. 장식보다 판독성이 우선이고, 연출은 판단을 돕는 방향으로 제한합니다.

## 아키텍처 목표

LTL의 구현은 `재현 가능한 도메인 시뮬레이션`을 중심에 둡니다. Godot 씬과 HUD는 도메인 상태를 보여주고 입력을 전달하는 얇은 계층이어야 합니다.

## 권장 프로젝트 구조

```text
res://
  prototype/
    PrototypeMain.tscn
    PrototypeController.gd
    PrototypeHUD.gd
    domain/
      PulseModel.gd
      EnergyQueue.gd
      MiningResolver.gd
      InventoryModel.gd
      HazardModel.gd
      NodeGenerator.gd
      RunSimulator.gd
    data/
      PrototypeTuning.json
      ArtifactTable.json
      NodeTable.json
      VisualTuning.json
      AudioCueTable.json
    telemetry/
      Telemetry.gd
    ui/
      CombatRoot.tscn
      BackpackPanel.tscn
      TerrainGrid.tscn
      EnergyQueueBar.tscn
      PinTimer.tscn
      RewardReveal.tscn
    vfx/
      PulseTileEffect.tscn
      MiningBeamEffect.tscn
      RewardCrackEffect.tscn
  tests/
    unit/
    integration/
```

## 계층 책임

| 계층 | 책임 | 금지 |
|---|---|---|
| `domain` | 파동 이동, 큐, 데미지, 인벤토리 시너지, 노드 생성, 런 판정 | Godot SceneTree 직접 접근, 전역 난수 |
| `data` | 밸런스 수치, 유물/노드/시각/오디오 테이블 | 코드로만 존재하는 숨은 수치 |
| `telemetry` | 이벤트 기록, 파생 지표 계산, replay comparison | 화면 전용 로그와 혼합 |
| `controller` | 입력을 도메인 명령으로 변환, tick 전달 | 규칙 판정 중복 구현 |
| `HUD/view` | 상태 표시, 7:3 레이아웃, 조준/보상/경고 연출 | 도메인 상태 직접 변경 |
| `vfx/audio` | 도메인 이벤트를 시청각 cue로 변환 | 판정 타이밍을 임의로 변경 |

## 핵심 데이터 흐름

1. `PrototypeController`가 mouse/keyboard 입력을 `(tick, target_cell, input_type)`으로 기록한다.
2. `RunSimulator`가 fixed tick(`0.05초` 기본)마다 `PulseModel`, `EnergyQueue`, `HazardModel`을 갱신한다.
3. 발사 입력은 `MiningResolver`에 전달되어 큐 소비, 타일 비활성화, 마력장/체력 데미지, 미스매치, 수리 상태를 판정한다.
4. 모든 중요한 결과는 `Telemetry`에 누적된다.
5. HUD는 도메인 snapshot과 `직전 액션 diff`만 읽어 표시한다. 누적 summary를 마지막 액션 피드백으로 직접 해석하지 않는다.
6. VFX/SFX는 `shot_resolved`, `pin_released`, `repair_started`, `node_cleared` 같은 이벤트를 구독해 재생한다.

controller/HUD 입력-피드백 순서의 세부 규칙은 `docs/14_references/04_input_feedback_flow.md`를 따른다.

## 전투 화면 레이아웃

기본 화면은 7:3 수직 분할입니다.

```text
┌──────────────────────────────────────────────────────────┐
│ Top 70%                                                   │
│ ┌───────────────┐ ┌────────────────────────────────────┐ │
│ │ Character 30% │ │ Backpack / Engine 70%              │ │
│ │ miner + drill │ │ items, synergies, cooldown pulses  │ │
│ └───────────────┘ └────────────────────────────────────┘ │
├──────────────────────────────────────────────────────────┤
│ Bottom 30%                                                │
│ ┌──────────────────────────────────────────────────────┐ │
│ │ Leviathan surface: 3 rows x 10 cols, pulse flow       │ │
│ └──────────────────────────────────────────────────────┘ │
│ queue / pins / repair / hazard status                    │
└──────────────────────────────────────────────────────────┘
```

### 상단 좌측: 캐릭터/채굴기 영역

- 캐릭터는 화면을 지배하지 않고, 채굴기 조준 방향과 상태를 보여주는 기능적 실루엣이어야 한다.
- 채굴기는 돋보기/렌즈/수정/집약기 형태를 결합한 장비로 디자인한다.
- 발사 대기, 발사, 수리, 빙결, 고장 상태에 따라 캐릭터 포즈와 장비 색이 바뀐다.
- 캐릭터 애니메이션은 4~6프레임의 짧은 루프 또는 Tween 기반 흔들림으로 충분하다.

### 상단 우측: 백팩/엔진 영역

- 백팩 그리드는 가장 많은 정보를 담는 영역이므로 고정 셀 크기와 일정한 여백을 유지한다.
- 아이템은 모양이 바로 보이는 폴리오미노 블록이어야 한다.
- 쿨타임은 아이템 내부 radial fill 또는 가장자리 진행 바로 표시한다.
- 인접 시너지는 아이템 사이의 얇은 라인, pulse, 작은 아이콘으로 표시한다.
- 저주/축복 셀은 색상뿐 아니라 테두리 패턴을 사용한다.

### 하단: 레비아탄 표면 3x10

- 3x10 셀은 전투의 주 판독 대상입니다. 셀 간 간격과 외곽선을 명확히 둔다.
- 파동 색상은 빨강/파랑/보라/초록을 쓰되, 색각 접근성을 위해 각 색에 패턴 또는 심볼을 추가한다.
- hover 대상은 항상 1칸만 강조한다.
- 비활성 타일은 어두운 균열/재생 중인 막으로 표현한다.
- 파동 흐름은 셀 내부 이동선, 미세한 방향 애니메이션, 테두리 흐름으로 표현한다.

## 화면별 구성

| 화면 | 목적 | 주요 컴포넌트 |
|---|---|---|
| Combat | 파동 판독과 채굴 | CharacterView, BackpackGrid, TerrainGrid, EnergyQueueBar, PinTimer, RepairPrompt, HazardBanner |
| Backpack Edit | 배치와 시너지 조정 | InventoryGrid, ItemTray, SynergyInspector, Rotate/Place controls |
| Node Select | 다음 부위 선택 | NodeCardList, RoutePreview, Risk/Reward tags |
| Reward | 클리어 보상 선택 | RewardReveal, CandidateCards, ComparePanel |
| Run Report | 실패/성공 분석 | MetricsSummary, BuildSnapshot, RetryButtons |
| Settings | 접근성/오디오/로그 | AudioSliders, ColorblindMode, InputMapping, LogExport |

## UI 컴포넌트 방침

### EnergyQueueBar

- 큐의 앞쪽 에너지가 가장 먼저 소비됨을 왼쪽에서 오른쪽 또는 위에서 아래로 명확히 표시한다.
- 각 에너지는 색+아이콘+짧은 pulse로 식별한다.
- 큐가 가득 차면 마지막 슬롯이 떨리고, 누수 발생 시 짧은 소실 이펙트를 준다.

### PinTimer

- 4핀은 화면 네 모서리 또는 백팩 네 귀퉁이에 배치한다.
- 25/50/75/100% 경과 시 핀 해제 연출을 둔다.
- 마지막 핀 전에는 경고등과 BGM 템포 변화로 압박을 준다.
- 방해 요소가 핀을 직접 뽑는 것처럼 보이면 안 된다.

### TerrainGrid

- 셀 좌표는 도메인 좌표와 1:1로 매핑한다.
- hover, valid shot, mismatch, invalid cooldown, shield damage, health damage를 서로 다른 cue로 표시한다.
- 숫자 데미지는 프로토타입에서는 표시해도 되지만 정식 UI에서는 선택 옵션으로 둔다.

### BackpackGrid

- 아이템 배치 중에는 유효/무효 위치를 즉시 표시한다.
- 인접 시너지는 hover 시 관련 아이템을 동시에 강조한다.
- 시너지 설명은 짧은 tooltip으로 제공하고, 전투 중에는 축약 아이콘만 보여준다.

### RewardCandidateCard

- 카드에는 유물 이름, 파동 태그, 형태, 즉시 효과, 시너지 후보가 들어간다.
- 현재 백팩과 연결되는 후보는 `관련 있음` 표시를 하되, 자동 추천처럼 강요하지 않는다.
- 희귀도는 색만이 아니라 프레임 형태와 사운드 레이어로 구분한다.

## 배경 디자인

### 전투 배경

- 배경은 레비아탄의 피부, 비늘, 균열, 털, 암석화된 외피를 혼합한 거대한 표면입니다.
- 카메라는 레비아탄의 일부만 보여줘야 한다. 전체 생명체를 직접 보여주기보다 “내가 거대한 것 위에 있다”는 스케일감을 준다.
- 배경 움직임은 느린 호흡, 표면 진동, 먼지 낙하 정도로 제한한다.
- 배경 채도는 낮게, 파동/큐/보상은 높은 대비로 둔다.

### 노드별 배경 변주

| 노드 | 배경 신호 | 플레이 정보 |
|---|---|---|
| 상처 지형 | 갈라진 붉은 외피 | 물리력 취약 |
| 균열 지형 | 푸른 빛이 새는 틈 | 마력 취약 |
| 노화 지형 | 마른 회색/보라 조직 | 부정 취약 |
| 궤양 지형 | 녹색 부패 흔적 | 부패 취약 |
| 노멀 지형 | 단단하고 균일한 비늘 | 안전 선택지 |

## 캐릭터 디자인

### 주인공

- 실루엣: 등반 장비, 로프, 작은 망토, 대형 채굴기를 든 탐사자.
- 감정: 복수심을 직접 드러내기보다 절제된 집착, 위험을 감수하는 자세.
- 색상: 어두운 작업복 + 황금/청색 장비 포인트.
- 애니메이션 상태: idle, aim, fire, repair, stagger, fall warning.

### LTL 단장

- 전투 프로토타입에서는 직접 등장하지 않아도 된다.
- 정식 구현에서는 노드 선택/런 결과 화면에서 규율과 경고를 전달하는 인물로 사용한다.
- 주인공보다 안정적이고 수호자에 가까운 실루엣을 사용한다.

### 레비아탄

- 캐릭터가 아니라 환경으로 먼저 표현한다.
- 살아 있는 산처럼 느껴지도록 호흡, 맥동, 표면 재생, 균열 반응을 사용한다.
- 사냥 대상이 아니라 금기의 존재라는 느낌을 유지한다.

## 이펙트 디자인

| 이벤트 | VFX | SFX |
|---|---|---|
| 파동 이동 | 셀 내부 흐름선, 테두리 pulse | 낮은 맥동음 |
| 매칭 피격 | 색상 일치 flash, 균열 확장 | 맑은 타격음 |
| 미스매치 | 둔한 흡수, 작은 연기 | 먹먹한 실패음 |
| 비활성 타일 | 어두운 막, 재생 progress | 짧은 차단음 |
| 큐 누수 | 에너지 방울 소실 | 새는 소리 |
| 핀 해제 | 모서리 핀 튕김, 화면 흔들림 약하게 | 금속 파열음 |
| 수리 시작 | 채굴기 불꽃/정지 | 경고 beep |
| 노드 클리어 | 표면 붕괴, 황금 균열 | 저음 고조 후 개방음 |

## 판독성 원칙

- 중요한 정보는 색 하나에만 의존하지 않는다.
- 전투 중 텍스트 설명은 최소화하고, 상태 아이콘/패턴/위치로 전달한다.
- UI는 장식 카드처럼 떠다니지 않고, 전투 도구처럼 고정된 위치에 둔다.
- 화면 흔들림은 클리어/핀 해제 같은 큰 사건에만 짧게 사용한다.
- 보상 연출은 화려하되 반복 가능해야 하며, 2초를 넘는 강제 지연은 피한다.

## 해상도와 반응형 기준

- 기본 설계 기준: 1920x1080.
- 최소 대응: 1280x720.
- 3x10 TerrainGrid는 어떤 해상도에서도 셀 비율과 간격을 유지한다.
- 백팩 셀은 너무 작아지면 scroll보다 scale-down을 우선하되, 최소 판독 크기 아래로 내려가지 않는다.
- 모바일/터치 대응은 P0~M9 범위에서는 보류하되, 입력 추상화는 mouse/touch 확장을 막지 않게 둔다.

## 데이터 주도 원칙

`PrototypeTuning.json`에는 tick, hold fire interval, tile cooldown, queue capacity, damage multipliers, pin thresholds, repair thresholds가 들어갑니다. `VisualTuning.json`에는 색상, 셀 크기, pulse 속도, 이펙트 지속시간을 둡니다. 수치를 코드에 박아야 한다면 테스트 fixture에도 같은 값이 드러나야 합니다.

## 판정 우선순위

- 동일 tick에 `clear`와 `time_over`가 동시에 발생하면 `clear`를 우선한다.
- 비활성 타일 발사는 에너지를 소비하지만 데미지 판정은 무효다.
- 빈 큐 발사는 실패하며 채굴기 내구도 손실을 1 누적한다.
- 내구도 손실 3회 누적 시 수리 상태로 진입하고, 수리 중 발사는 금지된다.
