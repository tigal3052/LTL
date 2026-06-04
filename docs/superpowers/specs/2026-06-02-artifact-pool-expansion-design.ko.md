# 2026-06-02 드릴/비콘 유물 풀 확장 설계

## 목표

- 한국어 등급명을 `영웅 = epic`, `전설 = legendary`, `신화 = mythic`으로 고정한다.
- 전체 유물 풀을 56개로 확장한다.
- 등급별 개수는 `common 8`, `rare 12`, `epic 16`, `legendary 12`, `mythic 8`이다.
- 색상별 분포는 등급마다 빨강/파랑/보라/초록이 `2/3/4/3/2`개씩 균등하게 갖는다.
- 영웅 이상 유물은 단순 수치 증가를 넘어서 `effect_schema`로 고유 기믹을 가진다.
- 상세 원본 데이터는 [reward-table.json](../../../app-LTL/src/data/reward-table.json)에 strict JSON으로 관리한다.

## 레퍼런스 분석

- [Limbus Company status-effect references](https://limbuscompany.wiki.gg/wiki/Status_Effects), [status effects guide](https://games.gg/limbus-company/guides/limbus-company-status-effects-guide/): 복잡한 상태 이상 자체보다 `스택`, `조건부 트리거`, `다음 행동 보정`, `위험 자원` 구조를 가져온다. 이 프로젝트에서는 보라의 지형 약화 스택, 빨강의 과열/지연 보상, 초록의 수리 후 성장으로 축약한다.
- [The Bazaar Steam page](https://store.steampowered.com/app/1617400/The_Bazaar/), [The Bazaar wiki](https://thebazaar.wiki.gg/): 아이템 태그, 쿨타임, 트리거 체인을 덱 구성의 중심으로 삼는 방향을 참고한다. 이 프로젝트에서는 드릴이 에너지 생산자, 비콘이 인접 트리거 조절자 역할을 맡는다.
- [Backpack Battles Steam page](https://store.steampowered.com/app/2427700/Backpack_Battles/), [Backpack Battles overview](https://en.wikipedia.org/wiki/Backpack_Battles): 배치/인접/형태가 성능을 바꾸는 구조를 참고한다. 이 프로젝트에서는 과도한 공간 퍼즐은 피하고, 같은 색상 인접 드릴/비콘 시너지를 중심으로 깊이를 만든다.

## 서브에이전트 회의 결론

- 레퍼런스 조사: 복잡도는 상태 이상 사전 수준으로 늘리지 말고, 플레이어가 “어떤 색 빌드인가”를 바로 읽을 수 있게 한다.
- 레퍼런스 분석: 드릴은 생산과 타격을 담당하고, 비콘은 배치 기반 조율자 역할을 맡는다. 쿨타임 수치는 부호 의미를 명확히 한다.
- 밸런스 디자이너: 백팩에서는 같은 색상 드릴을 하나만 실전 장착할 수 있으므로, 전체 풀은 드릴보다 비콘이 많아야 한다. 최종 목표는 드릴 24개, 비콘 32개다. common/epic/mythic은 드릴과 비콘을 같은 비율로 두고, rare/legendary는 색상별 1드릴+2비콘으로 조합 보정 폭을 넓힌다.
- QA: JSON strict parse, 등급/색상 카운트, mythic 보상 등장, effect schema 저장/표시, 비콘 쿨타임 부호와 데미지 전투 반영을 계약 테스트로 고정한다.
- 인디게임 전문가: 한 유물은 “주 트리거/주 대상/주 보상”을 중심으로 읽히게 하되, 조합 다양성은 태그, 색상, 인접, 누적 상태가 다른 유물과 교차하면서 생기게 한다. 즉 한 유물 내부를 복잡한 문장 여러 개로 채우지 않고, 여러 단순한 유물이 서로 엮이게 하는 원칙이다.

## 색상 정체성

| 색상 | 전투 정체성 | 드릴 방향 | 비콘 방향 |
| --- | --- | --- | --- |
| 빨강 | HP 파괴, 폭발, 위험 보상 | 높은 피해, 과열, 지연을 대가로 한 압축 화력 | 데미지 크게 증가, 일부 펄스는 쿨타임을 지연 |
| 파랑 | 실드 파괴, 안정화, 쿨타임 관리 | 실드 우선 피해, 큐 안정성, 루프 | 쿨타임 환급, 안정 펄스, 저장 냉각 |
| 보라 | 지형 약화, 반향, 복제 | 약화 스택, 에코 피해, 표식 | 대각/인접 공명, 표식 확산, 반향 프라임 |
| 초록 | 관통, 수리, 성장, 장기전 | 실드 관통 HP 피해, 수리 후 성장 | 보호, 수리 전환, 긴 전투 보상 |

## 등급 체계

| 등급 | 개수 | 색상별 개수 | 역할 | 기믹 깊이 |
| --- | ---: | ---: | --- | --- |
| common | 8 | 2 | 색상과 드릴/비콘 기본 학습 | 낮음. 기본 피해, 기본 비콘 펄스 |
| rare | 12 | 3 | 색상별 선호 플레이 강화 | 중간. 약한 태그/형태 차이와 보정 |
| epic | 16 | 4 | 빌드 방향을 선택하게 하는 첫 구간 | 높음. `effect_schema`로 트리거와 특수 요약 제공 |
| legendary | 12 | 3 | 특정 색상 덱의 핵심 엔진 | 매우 높음. 위험/보호/반향/성장 엔진 |
| mythic | 8 | 2 | 한 빌드의 정체성을 바꾸는 축 | 최고. 강한 보상과 명확한 제약 |

## 구현된 런타임 범위

- 비콘 쿨타임 펄스는 부호를 구분한다. 음수는 인접 같은 색 드릴을 가속하고, 양수는 지연한다.
- 비콘 데미지 보정은 인접 같은 색 드릴의 실제 전투 피해에 반영된다.
- 빨강/파랑/보라/초록의 전투 정체성은 CombatVocab의 색상 프로필로 유지된다.
- 영웅 이상 특수 기믹은 `effect_schema`로 저장되고, 보상 프리뷰/툴팁/유물 직렬화에 연결된다.
- `reward-table.json`의 모든 유물은 `text.name.ko/en`, `text.description.ko/en`를 가진다. 영웅 이상은 `effect_schema.summary_i18n.ko/en`도 가진다.
- 유물 도감 메뉴는 플레이 기록의 `artifactDiscovery`와 연결되어 발견한 유물만 공개하고, 디버그 토글에서는 전체 56개 유물을 확인할 수 있다.
- 이번 범위에서 `effect_schema.summary`와 `summary_i18n`은 플레이어 표시와 후속 룰 엔진 확장의 계약이다. 모든 텍스트형 특수효과를 완전 실행하는 범용 룰 엔진은 다음 단계로 분리한다.

## JSON 관리 스키마

각 reward 항목은 다음 구조를 따른다.

```json
{
  "id": "reward_epic_red_beacon_3",
  "kind": "Crimson Overheat Beacon",
  "rarity": "epic",
  "weight": 32,
  "text": {
    "name": {"ko": "진홍 과열 비콘", "en": "Crimson Overheat Beacon"},
    "description": {
      "ko": "빨강 특성: 높은 피해, 과열, 지연을 대가로 한 폭발 보상. 비콘은 인접한 같은 색상 유물을 조율합니다.",
      "en": "Red identity: high damage, overheat pressure, and delay-for-burst rewards. Beacon role: tunes adjacent same-color artifacts."
    }
  },
  "payload": {
    "item_type": "beacon",
    "energy_type": "red",
    "shape": [[1], [1]],
    "base_cooldown_ticks": 80,
    "beacon_cooldown_mod": 2,
    "beacon_damage_mod": 0.9,
    "effect_schema": {
      "version": 1,
      "trigger": "on_beacon_pulse",
      "type": "damage_for_delay",
      "summary": "Adjacent red drills hit much harder, but beacon pulses delay their next cycle.",
      "summary_i18n": {
        "ko": "인접한 빨강 드릴의 피해를 크게 높이지만 다음 사이클을 지연합니다.",
        "en": "Adjacent red drills hit much harder, but beacon pulses delay their next cycle."
      }
    }
  },
  "presentation": {
    "icon": "beacon_red_epic",
    "description": "High-risk pulse beacon.",
    "badge": "epic red beacon"
  },
  "tags": ["beacon", "epic", "red_energy"]
}
```

## 유물 풀 요약

| 등급 | 빨강 | 파랑 | 보라 | 초록 |
| --- | --- | --- | --- | --- |
| common | Crimson Ember Bit, Crimson Heat Post | Azure Tide Bit, Azure Coolant Post | Violet Static Needle, Violet Echo Post | Verdant Moss Bit, Verdant Seed Post |
| rare | Crimson Pressure Fang, Crimson Spark Relay, Crimson Venting Beacon | Azure Tide Cutter, Azure Coolant Relay, Azure Flow Regulator | Violet Echo Needle, Violet Veil Relay, Violet Echo Lens | Verdant Moss Bore, Verdant Sap Relay, Verdant Root Clamp |
| epic | Crimson Overheat Lance, Crimson Pressure Bank Auger, Crimson Overheat Beacon, Crimson Venting Relay | Azure Tidal Regulator, Azure Queue Rudder, Azure Tide Loop Beacon, Azure Freeze Relay | Violet Phase Needle, Violet Static Rewriter, Violet Diagonal Resonator, Violet Prism Mark | Verdant Living Hull Seed, Verdant Repair Mycelium, Verdant Root Matrix, Verdant Living Shell Beacon |
| legendary | Crimson Leviathan Heart Auger, Crimson Catapult Furnace Beacon, Crimson Blood Pressure Beacon | Azure Eventide Core Drill, Azure Abyssal Keel Beacon, Azure Abyssal Stabilizer | Violet Twin-Signal Lance, Violet Void Ledger Beacon, Violet Mirror Court Beacon | Verdant Crown Drill, Verdant Lifeline Beacon, Verdant Sanctuary Root Beacon |
| mythic | Crimson Cataclysm Bore, Crimson Cataclysm Relay | Azure Eventide Sovereign Drill, Azure Zero-Tide Relay | Violet Singularity Needle, Violet Singularity Prism | Verdant Worldroot Excavator, Verdant Worldroot Heart |

## 밸런스 가드레일

- 1라운드 전설 비콘 획득이 다음 단계를 자동 클리어로 만들지는 않되, “큰 실수가 없는데도 실패”하는 상황은 줄인다.
- 전설/신화 비콘은 단순 가속만 하지 않는다. 빨강은 높은 피해 대신 지연을 줄 수 있고, 파랑은 안정 루프, 보라는 반향/표식, 초록은 보호/수리와 묶인다.
- 같은 색상 인접 시너지를 기본 대상으로 삼아, 네 색상 타입의 정체성이 흐려지지 않게 한다.
- common/rare는 설명과 숫자가 짧아야 한다. epic 이상은 트리거 문장 하나로 빌드 방향을 드러낸다.
- mythic은 강해야 하지만 무한 루프가 되면 안 된다. 신화 비콘도 쿨타임, 색상 조건, 인접 조건으로 제한한다.

## QA 체크리스트

- `reward-table.json` strict JSON 파싱 성공.
- 총 보상 수 56개.
- 등급별 개수 `8/12/16/12/8`.
- 등급별 색상 개수 `2/3/4/3/2`.
- 등급별 드릴/비콘 개수는 common `4/4`, rare `4/8`, epic `8/8`, legendary `4/8`, mythic `4/4`.
- 모든 reward payload에 `item_type`, `energy_type`, `shape`가 존재.
- 모든 reward에 `text.name.ko/en`, `text.description.ko/en`가 존재.
- epic/legendary/mythic payload에 `effect_schema.version`, `trigger`, `type`, `summary`, `summary_i18n.ko/en`가 존재.
- stage 4 보상 롤에서 mythic이 등장 가능.
- 비콘 쿨타임 펄스 부호 동작 검증: 음수는 가속, 양수는 지연.
- 비콘 데미지 보정이 인벤토리 계산과 실제 CombatVocab 피해 계산에 반영.
- 유물 도감은 일반 모드에서 발견 유물만 공개하고, 디버그 모드에서 전체 56개 유물을 공개.
- `i18n-text-gate.ps1`는 UI/scene 하드코딩 문구뿐 아니라 reward-table 다국어 텍스트 계약도 실패시킨다.
