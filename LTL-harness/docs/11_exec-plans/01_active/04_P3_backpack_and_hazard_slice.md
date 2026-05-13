# P3. 백팩과 방해 요소 슬라이스

## 목표

장비 배치가 전투 리듬을 바꾸고, 방해 요소가 시간을 지연시키되 억울한 실패로 느껴지지 않는지 검증한다.

## 산출물

- `InventoryModel.gd`
- `HazardModel.gd`
- `ArtifactTable.json`
- backpack debug UI
- freeze 또는 break hazard 1종 이상
- repair interaction 최소 1종

## TDD 대상

- 폴리오미노 배치/회전/충돌 판정
- 인접 면 시너지 계산
- 시너지에 따른 쿨타임/에너지 생성량 변화
- 빙결은 장비 쿨타임을 지연시키지만 핀을 직접 제거하지 않는다.
- 고장은 수리 상태와 구분된다.

## 완료 기준

- 같은 백팩 배치에서 같은 seed의 큐 생성이 재현된다.
- 시너지 없는 배치와 시너지 배치의 지표 차이가 telemetry로 확인된다.
- 방해 요소가 큐 누수율/클리어 시간에 영향을 준다.
