# M5. 방해 요소 계층화

## 목표

빙결, 강풍, 비상물, 고장 같은 방해 요소를 불쾌감보다 판단 압박으로 작동하게 만든다.

## 산출물

- hazard table
- hazard scheduler
- hazard visual/audio cues
- hazard telemetry

## TDD 대상

- 방해 요소는 핀을 직접 제거하지 않는다.
- 각 hazard는 지속 시간, 대상, 해제 조건을 가진다.
- 같은 seed의 hazard 발생 순서는 재현된다.

## 완료 기준

- 최소 3종 hazard가 서로 다른 로그 지표에 영향을 준다.
- 수동 QA에서 원인과 대응법이 화면상 명확하다.
