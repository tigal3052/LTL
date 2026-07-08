# 2026-06-03 M5 장애물 / 백팩 Relic 설계

## 목표

- M5를 `색상별로 읽히는 장애물 레이어`로 구체화한다.
- `relic`을 전역 패시브가 아니라 `백팩 안에 장착하는 제3 아이템 타입`으로 정의한다.
- relic은 `drill`과 `beacon`처럼 희귀도와 차지 면적이 의미를 갖도록 만든다.
- relic의 공간 문법은 일반 인접 시너지가 아니라 `대각선 연결` 또는 `한 칸 띄운 연결`을 사용한다.
- 장애물은 단순 이미지가 아니라 `경고`, `활성`, `파훼`, `실패`, `후유증`까지 시각적으로 구분되게 설계한다.

## 이번 설계에서 고정하는 사용자 조건

- relic은 인벤토리 장착칸에 들어간다.
- 아이템 타입은 `drill / beacon / relic` 3종이다.
- relic은 색상 타입을 갖지 않는다.
- relic은 범용 아이템이다.
- 희귀도는 유지하되, 의미는 `수치 상승`보다 `공간 가치`, `트리거 안정성`, `효과의 질`로 만든다.
- relic은 너무 다양한 성장축을 열지 않고, `장애물 대응`, `복구`, `위기 완화`, `배치 전략` 중심으로 제한한다.

## 핵심 결정

### 1. 백팩 안의 세 가지 공간 문법

- `drill`
  같은 색 drill끼리 `직교 인접` 시너지를 쓴다.
- `beacon`
  인접한 같은 색 drill에 `직교 인접` 보조를 준다.
- `relic`
  일반 인접 대신 아래 두 가지 연결만 쓴다.

### 2. relic 전용 연결 규칙

relic은 아래 둘 중 하나의 링크 모드를 가진다.

- `diagonal_1`
  모서리를 맞대는 `대각선 1칸` 위치의 장비를 연결한다.
- `skip_2`
  `상하좌우로 정확히 2칸 떨어진` 장비를 연결한다.
  중간 1칸은 비어 있어도 되고, 다른 아이템이 있어도 되지만 링크 판정은 정확히 2칸만 본다.

legendary relic만 예외적으로 두 패턴을 동시에 쓰는 `crown_link`를 허용한다.

이렇게 하면:

- drill은 `붙여서 굴리는 색 배치`
- beacon은 `옆에서 밀어주는 조력자`
- relic은 `비틀어 놓는 장거리 보조`

라는 역할 차이가 분명해진다.

### 3. 희귀도 의미

- `common`
  작고 읽기 쉽다. 주로 `1x1`.
- `rare`
  조금 더 좋은 범위 또는 안정적인 트리거를 가진다. 주로 `1x2`, `2x1`.
- `epic`
  배치 압박이 생기는 대신 전투 흐름을 바꾼다. 주로 `2x2`.
- `legendary`
  백팩의 중심축이 되는 파츠다. `2x3`, `3x2`, 또는 명확한 시그니처 모양을 쓴다.

이번 1차에서는 `mythic relic`은 넣지 않는다.
카테고리 학습이 끝나기 전에는 common~legendary로 끝내는 편이 안전하다.

### 4. 런타임 구조 영향

현재 큐는 단순 색 문자열 배열이지만, relic이 특정 drill을 원거리로 지원하려면 에너지 토큰이 출처를 알아야 한다.

따라서 M5 구현 시 큐 토큰은 아래 구조로 바뀐다.

```json
{
  "color": "red",
  "source_artifact_id": "starter_red_drill",
  "source_item_type": "drill"
}
```

이 변경으로 relic은:

- 어떤 drill이 발사 원천인지
- 어떤 beacon이 그 drill을 보조 중인지
- 어떤 relic이 그 drill에 링크 중인지

를 추적할 수 있다.

## 장애물 설계 원칙

### 1. 장애물은 색상별로 빠르게 읽혀야 한다

- `Red`: 시간 폭탄, 과열, 파열
- `Blue`: 결빙, 전체 쿨다운 둔화, 흐름 억제
- `Purple`: 적 디버프 정화, 피해 감소 강화막
- `Green`: 포자 확산, 재생, 체력 회복

### 2. 모든 장애물은 같은 생명주기를 가진다

1. `warn`
   경고. 어디가 위험한지 미리 보인다.
2. `arm`
   장애물이 활성화 준비를 마친다.
3. `pressure`
   플레이를 방해하는 본효과가 작동한다.
4. `break`
   플레이어가 파훼했을 때의 해소 상태.
5. `afterglow`
   완전히 끝나지 않고 짧은 후유증이 남는다.

### 2-1. 셀 부착형 지속시간 제약

- 전장은 `3x10` 지형 타일이며, 타일은 `1초마다 1칸` 이동한다.
- 따라서 하나의 셀은 화면에 최대 `10초`만 존재한다.
- 장애물은 `셀에 부착`되는 방식이므로, 어떤 장애물도 `10초를 넘는 단일 지속시간`을 가질 수 없다.
- 장애물이 붙은 셀이 화면 끝으로 이동해 사라지면, 그 장애물은 `무조건 실패 발동`한다.
- 난이도를 올릴 때는 지속시간을 늘리지 않고 아래 세 가지로만 압박을 늘린다.
  - `동시 생성 수 증가`
  - `추가 연쇄 생성`
  - `놓친 장애물 수만큼 다음 생성량 증가`

### 2-2. 놓친 장애물 누적 규칙

- 각 패밀리는 전투 중 `miss_debt`를 가진다.
- 해결하지 못한 장애물이 화면 끝으로 빠져나가 실패 발동하면 해당 패밀리의 `miss_debt += 1`.
- 다음 같은 패밀리 생성 시 `base_spawn_count + miss_debt`만큼 장애물을 생성한다.
- 이렇게 사용된 `miss_debt`는 그 생성 이벤트에서 소모된다.
- 즉, 오래 남기는 방식이 아니라 `놓치면 다음 웨이브가 더 많아지는 방식`으로 압박이 커진다.
- 단, stage별 `overflow_spawn_cap`을 둬서 한 번에 폭주하지 않게 막는다.

### 2-3. 생성 가능 위치 규칙

- 장애물은 `남은 이동 칸 수`가 `warning_shifts + 최소 반응 칸 수`보다 큰 셀에만 생성된다.
- 즉, 화면 끝에 가까운 셀에는 새 장애물을 붙이지 않는다.
- 기본 최소 반응 칸 수는 `2`.
- 따라서 `warning_shifts = 2`인 장애물은 최소 `4칸` 이상 남은 셀에만 생성된다.
- 화면에 남은 칸 수가 부족한데 더 높은 압박을 줘야 한다면, 기존 장애물 지속시간을 늘리지 않고 `다음 셀/다음 웨이브에 신규 생성`한다.

### 3. 모든 장애물은 오프컬러 해결이 가능해야 한다

- matching color는 `쉽게` 해결한다.
- 다른 색도 `느리게` 해결한다.
- 해결 불가능한 색 조합은 만들지 않는다.

기본 규칙:

- 매칭 색 해결: `+2 progress`
- 비매칭 색 해결: `+1 progress`
- 일부 패밀리는 매칭 색에 추가 보너스를 가진다.

### 4. 장애물은 직접 핀을 꽂아 플레이를 끊지 않는다

장애물은 주로 아래를 건드린다.

- 남은 시간
- 백팩 전체 cooldown 효율
- 레비아탄에게 걸린 디버프 상태
- 레비아탄 체력
- 특정 cell의 사용 가능 여부
- aim drift
- repair 효율
- 짧은 afterglow 패널티

직접적인 즉사, 무경고 강제 실패, 장시간 조작 봉쇄는 금지한다.

## 장애물 데이터 스키마

각 장애물 레시피는 아래 구조를 가진다.

```json
{
  "id": "haz_red_pressure_vent_t1",
  "family": "red_pressure",
  "pattern": "single_cell",
  "required_color": "red",
  "clear_progress": 2,
  "match_progress": 2,
  "off_progress": 1,
  "warning_shifts": 2,
  "max_active_shifts": 6,
  "afterglow_shifts": 1,
  "max_targets": 1,
  "fail_on_exit": true,
  "miss_debt_gain": 1,
  "overflow_mode": "spawn_new",
  "fail_effect": {
    "type": "time_cut",
    "value": 12
  },
  "vfx": {
    "warn": "pressure_glow",
    "active": "pressure_pulse",
    "clear": "pressure_rupture",
    "fail": "ember_burst",
    "afterglow": "heat_haze"
  }
}
```

## 장애물 실패 효과 기준

- `red`
  제한 시간 내 파훼하지 못하면 폭발하고 남은 시간이 즉시 줄어든다.
- `blue`
  얼어붙은 타일이 하나라도 남아 있으면 전 백팩 cooldown이 증가한다.
- `purple`
  활성 중에는 주기적으로 레비아탄 디버프를 지우고, 지울 디버프가 없으면 피해 감소 버프를 얻는다.
- `green`
  제한 시간 내 파훼하지 못하면 포자가 퍼지고 레비아탄이 체력을 회복한다.

purple의 `디버프`는 1차 구현에서 현재 전투 모델이 이미 갖고 있는 `terrain_debuffs` 계열을 우선 대상으로 한다.
이후 시스템이 확장되면 `mark`, `exposed`, `vulnerability` 같은 다른 적 디버프에도 연결한다.

## 장애물 패밀리

### Red 패밀리: Pressure Core / Furnace Vein

색상 정체성:
남은 시간을 직접 위협하는 폭발형 장애물.

초기 패턴:

- `Pressure Core`
  단일 cell에 붉은 핵이 생기고 카운트다운이 시작된다.
- `Furnace Vein`
  같은 행 또는 열의 2칸에 연결된 균열이 생긴다.

파훼 규칙:

- red hit: `+2 progress`, 그리고 clear 시 주변에 작은 파열 피해를 준다.
- off-color hit: `+1 progress`.
- blue hit: 일반 오프컬러와 동일하지만, clear 이후 afterglow를 약하게 만든다.

실패 시:

- 해당 타일이 폭발한다.
- 남은 시간이 즉시 `10~20초` 감소한다.
- stage가 높거나 risk가 높을수록 시간 손실이 커진다.
- 이 폭발은 `miss_debt +1`을 남겨 다음 red 생성량을 증가시킨다.

후유증:

- 폭발 지점에 짧은 `heat afterglow`가 남아 시야와 판정을 약하게 흔든다.

연출:

- `warn`: 붉은 금과 내부 맥동, 카운트다운 비프음
- `active`: 셀이 숨 쉬듯 부풀고 붉은 증기 누출
- `break`: 균열 파열, 불꽃, 금속 파편, 짧은 화면 진동
- `fail`: 셀 중심에서 바깥으로 크게 터지는 화염 파열과 타이머 절단 연출
- `afterglow`: 열기 아지랑이와 약한 ember 점멸

### Blue 패밀리: Frost Lock / Frozen Sheet

색상 정체성:
얼어붙은 타일이 남아 있는 동안 전 백팩 템포를 늦추는 둔화형 장애물.

초기 패턴:

- `Frost Lock`
  단일 타일이 얼어붙는다.
- `Frozen Sheet`
  인접 2칸 또는 짧은 띠 형태로 얼음 타일이 생성된다.

파훼 규칙:

- blue hit: `+2 progress`, clear 시 짧은 전체 안정화 보너스
- off-color hit: `+1 progress`
- green hit: 오프컬러지만 clear 후 repair penalty를 줄인다

실패 시:

- `실패`라기보다 `미해결 pressure 지속`에 가깝다.
- 얼어붙은 타일이 하나라도 남아 있으면 전 백팩의 모든 장비 cooldown이 증가한다.
- 시간이 더 지나면 얼음이 한 타일 더 번지거나 cooldown tax가 한 단계 오른다.
- 얼음 타일이 화면 끝까지 남아 사라지면 해당 blue 웨이브는 실패로 판정되고 `miss_debt +1`.

후유증:

- 마지막 얼음 타일을 깨도 짧은 시간 냉기 잔상이 남아 회복이 약간 늦다.

연출:

- `warn`: 서리 테두리, 얇은 얼음 선, 고음 냉기음
- `active`: 셀 위에 얼음 결정 성장, 백팩 쿨다운 UI에 차가운 푸른 오버레이
- `break`: 얼음 파쇄 조각, 차가운 증기
- `fail`: 얼음이 더 두꺼워지고 전체 쿨다운 경고음이 울림
- `afterglow`: 사라지는 성에와 냉기 김

### Purple 패밀리: Echo Knot / Null Prism

색상 정체성:
플레이어가 쌓아 둔 적 디버프를 지우거나, 지울 것이 없으면 레비아탄에게 피해 감소를 부여하는 정화형 장애물.

초기 패턴:

- `Echo Knot`
  떨어진 2개 cell이 보라색 끈으로 연결된다.
- `Null Prism`
  하나의 프리즘 코어가 떠오르며 정화 맥동을 만든다.

파훼 규칙:

- purple hit: `+2 progress`, 연결된 두 지점에 동시에 progress 적용
- off-color hit: 맞은 지점 하나에만 `+1 progress`
- red hit: clear 직전 마지막 1 progress를 강제로 터뜨리기 좋다

실패 시:

- 일정 간격마다 레비아탄에게 걸린 디버프를 1스택씩 제거한다.
- 제거할 디버프가 없으면 짧은 `damage reduction` 버프를 얻는다.
- 코어가 화면 밖으로 빠져나가면 정화 펄스 1회를 추가로 발동하고 `miss_debt +1`.

후유증:

- 링크가 사라진 뒤 짧게 잔광선이 남아 방금 정화된 상태를 보여준다.

연출:

- `warn`: 보라색 도형, 선 연결, 미세한 이중상
- `active`: 두 지점 사이를 오가는 공명선, 프리즘 정화 파동
- `break`: 유리 금이 가듯 퍼지는 crack wave
- `fail`: 레비아탄 쪽으로 보라색 정화 파동이 들어가고 보호막이 맺힘
- `afterglow`: 약한 보라 리본과 잔향

### Green 패밀리: Root Clamp / Husk Bloom

색상 정체성:
시간 내 파훼하지 못하면 포자가 퍼지며 레비아탄이 체력을 회복하는 재생형 장애물.

초기 패턴:

- `Root Clamp`
  특정 cell 또는 장비 슬롯에 뿌리 고정물이 감긴다.
- `Husk Bloom`
  막 피어나기 직전의 초록 포자가 2칸 영역을 점유한다.

파훼 규칙:

- green hit: `+2 progress`, clear 시 repair progress를 소량 돌려준다.
- off-color hit: `+1 progress`
- blue hit: clear 자체는 느리지만 afterglow를 짧게 만든다.

실패 시:

- 포자가 주변으로 퍼진다.
- 레비아탄이 즉시 체력을 회복한다.
- stage가 높을수록 회복량과 확산 범위가 조금씩 증가한다.
- 미해결 상태로 화면 끝에 도달한 개수만큼 다음 green 생성량이 늘어난다.

후유증:

- 짧은 시간 동안 같은 위치에 약한 잔포자 구름이 남는다.

연출:

- `warn`: 뿌리 그림자, 초록 포자 먼지, 미세한 성장 소리
- `active`: 덩굴이 감기고 포자가 들썩임
- `break`: 뿌리 절단, 잎 파편, 포자 흩뿌림
- `fail`: 포자가 바깥으로 확산되며 레비아탄 체력 회복 숫자가 뜸
- `afterglow`: 바닥에 남은 잔포자선과 희미한 재생 안개

## 패턴과 난이도 스케일

### 1. 패턴 등급

- `Pattern A`
  단일 cell 또는 단일 장비 대상
- `Pattern B`
  2칸 연결, 1줄 lane, 또는 장비+cell 조합
- `Pattern C`
  2개 동시 위협 또는 좁은 영역 위협

### 2. 스테이지별 기본 규칙

| 스테이지 | 장애물 예산 | 동시 활성 수 | 주 패턴 | clear progress | warning shifts | overflow spawn cap |
| --- | ---: | ---: | --- | ---: | ---: |
| 1-2 | 1 | 1 | A | 2 | 2 | 0 |
| 3-4 | 2 | 1 | A, B | 3 | 2 | 1 |
| 5-6 | 3 | 2 | B | 3 | 1-2 | 1 |
| 7-8 | 4 | 2 | B, C | 4 | 1 | 2 |
| 9+ | 5 | 2 | C | 4 | 1 | 2 |

### 3. 패밀리별 수치 스케일 기준

| 패밀리 | 초반 | 중반 | 후반 | 보스 |
| --- | --- | --- | --- | --- |
| Red 실패 시간 손실 | 10초 | 12~14초 | 15~18초 | 20초 |
| Blue 남아있는 동안 전역 쿨증가 | +12% | +15~18% | +20~25% | +30% |
| Purple 펄스 정화 / 보호 | 디버프 1스택 정화 또는 피해 15% 감소 | 1스택 정화 또는 20% 감소 | 2스택 정화 또는 25% 감소 | 2스택 정화 또는 30% 감소 |
| Green 실패 회복량 | 최대 체력 3% | 4~5% | 6~7% | 8% |
| 추가 생성 기준 | 놓치면 다음 동일 패밀리 +1 | 놓치면 +1, hard 이상은 +2 가능 | 놓치면 +1~2 | 놓치면 +2 |

### 4. 노드 위험도 가중치

- `safe`: 예산 -1, 최소 0
- `medium`: 기본값
- `hard`: 예산 +1
- `danger`: 예산 +2
- `boss`: Pattern C 고정 + family 혼합 허용

### 5. 겹침 규칙

- 초반에는 family 1종만 등장
- stage 5부터 2종 혼합 허용
- stage 7부터 `major 1 + minor 1` 조합 허용
- 같은 tick에 3개 이상 동시에 터지지 않는다
- afterglow가 남아 있을 때는 같은 family가 동일 위치에 재소환되지 않는다
- 같은 셀에 붙은 장애물은 그 셀이 화면 끝으로 나가면 무조건 실패 처리된다
- stage 상승은 `지속시간 증가`가 아니라 `spawn 수`, `pattern 복합도`, `miss_debt 사용량`으로만 처리한다

### 6. 패밀리별 기본 파훼 목표

- `Red`
  카운트다운이 끝나기 전에 핵심 타일을 우선 파괴한다.
- `Blue`
  얼어붙은 타일을 `모두` 제거해 전역 쿨다운 tax를 끊는다.
- `Purple`
  적에게 걸어 둔 디버프가 지워지기 전에 정화 코어를 빠르게 제거한다.
- `Green`
  포자가 번져 회복으로 이어지기 전에 확산 지점을 먼저 끊는다.

## relic 시스템

## 설계 원칙

- relic은 `중립 도구`다.
- drill처럼 에너지를 만들지 않는다.
- beacon처럼 옆 칸만 강제하지 않는다.
- `대각선` 또는 `한 칸 띄운 직선`으로 멀리 관여한다.
- 효과는 `한 문장`으로 끝나야 한다.
- 1차 출시에서는 `경제`, `상점`, `노드 조작`, `복잡한 콤보 카운터`를 다루지 않는다.

## relic 20개 컨셉 풀

### 장애물 대응 relic 10

| 이름 | 희귀도 | 크기 | 링크 | 효과 |
| --- | --- | --- | --- | --- |
| Breach Seal | common | 1x1 | diagonal_1 | 링크된 drill의 첫 장애물 타격은 추가 `+1 progress`를 준다. |
| Warning Bell | common | 1x1 | skip_2 | 링크된 drill이 관여하는 장애물 warning이 더 길어진다. |
| Spare Fuse | common | 1x2 | diagonal_1 | 링크된 장비는 전투당 첫 freeze 또는 malfunction를 1단계 무시한다. |
| Sealant Patch | common | 1x1 | skip_2 | 링크된 drill은 전투당 첫 afterglow 패널티를 받지 않는다. |
| Brake Coil | rare | 2x1 | diagonal_1 | 링크된 장비가 repair에 들어가면 장애물 타이머가 잠깐 멈춘다. |
| Debris Chalk | rare | 1x2 | skip_2 | 링크된 drill이 관여한 장애물 cell은 blocked 상태가 더 잘 보이고 조금 빨리 풀린다. |
| Stabilizer Clamp | rare | 1x2 | diagonal_1 | 장애물 pressure 중 링크된 drill의 첫 mismatch는 핀으로 이어지지 않는다. |
| Counterflow Governor | rare | 2x1 | skip_2 | 링크된 drill로 장애물을 해결하면 링크된 장비 전체에 작은 cooldown 환급을 준다. |
| Recovery Winch | epic | 2x2 | diagonal_1 | 링크된 drill의 첫 장애물 clear는 repair progress 또는 spare queue 1개를 되돌린다. |
| Stormglass Archive | legendary | 2x3 | crown_link | 링크된 drill의 첫 clean clear는 afterglow를 제거하고 짧은 calm window를 연다. |

### 일반 relic 10

| 이름 | 희귀도 | 크기 | 링크 | 효과 |
| --- | --- | --- | --- | --- |
| Tool Rack | common | 1x1 | diagonal_1 | 링크된 drill의 기본 cooldown을 소폭 줄인다. |
| Reserve Canister | common | 1x1 | skip_2 | 링크된 drill은 큐가 빈 직후 첫 발사에서 추가 위기 패널티를 덜 받는다. |
| Repair Coil | common | 1x2 | diagonal_1 | repair 종료 후 링크된 drill의 다음 2발이 강화된다. |
| Packing Foam | common | 1x2 | skip_2 | 링크된 beacon의 첫 pulse가 조금 더 빨리 온다. |
| Pinbreaker Spring | rare | 1x2 | diagonal_1 | 링크된 drill의 첫 mismatch는 즉시 해소되어 핀이 오래 남지 않는다. |
| Anchor Oathplate | rare | 2x1 | skip_2 | 링크된 drill은 전투당 첫 drift 또는 displacement를 무시한다. |
| Split Feeder | rare | 1x2 | diagonal_1 | repair 이후 링크된 drill이 만든 첫 에너지를 한 번 복제한다. |
| Spine Choir Bell | rare | 2x1 | skip_2 | 링크된 beacon은 pulse 주기가 안정적으로 앞당겨진다. |
| Overrun Valve | epic | 2x2 | diagonal_1 | 링크된 drill의 finishing shot 일부가 다음 대상에 spill된다. |
| Pressure Gauge | legendary | 3x2 | crown_link | 남은 시간이 위험 구간에 들어가면 링크된 장비 전체가 잠깐 가속된다. |

## 출시 권장 풀

20개를 한 번에 넣지 않는다.

### 1차 출시 8개

- Breach Seal
- Warning Bell
- Spare Fuse
- Brake Coil
- Tool Rack
- Repair Coil
- Pinbreaker Spring
- Anchor Oathplate

선정 이유:

- 장애물 읽기
- 장애물 해결
- 장애물 실패 완화
- repair 회복
- 핀/드리프트 스트레스 완화
- 원거리 백팩 배치 가치

를 모두 담으면서도, 경제/노드 조작 같은 학습 분산을 만들지 않는다.

## UI / 연출 규칙

### 1. 백팩 링크 시각화

- relic은 평상시 얇은 금속선 또는 점선으로 링크 대상 방향을 암시한다.
- 마우스 hover 시:
  - `diagonal_1`은 대각선 모서리 하이라이트
  - `skip_2`는 가운데 한 칸을 건너뛰는 점선
  - `crown_link`는 두 패턴을 모두 보여준다
- drill/beacon의 기존 인접 표시와 색이 겹치지 않게, relic 링크는 `황동색` 또는 `백색 골조선`을 쓴다.

### 2. 장애물 표현 계층

- `cell overlay`
  위험 cell, 연결선, blocked/occupied, afterglow
- `equipment overlay`
  freeze, malfunction, root clamp
- `battlefield border / lane cue`
  drift current, pressure wave

### 3. 파훼 애니메이션

각 패밀리는 최소 아래 다섯 연출을 가진다.

- warning pulse
- activation idle
- solve burst
- fail burst
- afterglow fade

정적 아이콘 하나만 바꾸는 방식은 금지한다.

## 구현 영향 요약

### 필요한 구조 변경

- `Artifact.gd`
  `item_type == "relic"` 처리 추가
- `InventoryModel.gd`
  relic 링크 계산 함수 추가
- `CreateArtifactFromReward.gd`
  relic의 `energy_type` 기본값을 강제로 비워 넣도록 수정
- combat queue
  plain string 대신 `source_artifact_id`를 가진 토큰 구조로 확장
- obstacle state
  현재 단순 hazard 테이블보다 풍부한 family/pattern 기반 구조로 확장

### 1차 구현에서 하지 않는 것

- manual active relic 버튼
- relic 자체의 에너지 생산
- relic의 상점/경제/경로 조작
- mid-combat backpack 재배치
- 3개 이상 동시 장애물 폭주

## 검증 포인트

- matching color가 오프컬러보다 항상 빠르게 해결되는가
- 장애물 경고 없이 즉시 활성화되는 경우가 없는가
- 동일 위치에 afterglow가 남았을 때 같은 family가 즉시 재소환되지 않는가
- relic 링크가 `직교 인접`이 아니라 `대각선` 또는 `한 칸 띄움`으로만 계산되는가
- queue token이 source drill을 잃지 않는가
- launch 8 relic이 모두 한 문장으로 설명 가능한가

## 최종 추천

이번 M5의 좋은 첫 버전은:

- `색상별로 빠르게 읽히는 4대 장애물 패밀리`
- `경고-활성-파훼-후유증이 보이는 VFX`
- `drill/beacon과 다른 공간 문법을 가진 neutral relic`
- `20개 설계 풀 + 8개 출시`

조합이다.

이 구조라면 relic이 희귀도 의미를 잃지 않으면서도, 새로운 성장축이 과하게 퍼지지 않는다.
