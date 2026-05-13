# M4. 노드 라우팅

## 목표

다중 선택 노드 구조를 구현해 플레이어가 현재 빌드에 유리한 경로를 고르게 만든다.

## 산출물

- node map screen
- node choice model
- normal/random/event/boss node definitions
- route telemetry

## TDD 대상

- 스테이지당 후보 수 규칙
- 노멀 노드 보장
- boss node 위치 고정
- seed 기반 route 재현성

## 완료 기준

- 3~5스테이지 런 구성이 가능하다.
- 선택한 노드 타입이 전투/보상/난이도에 반영된다.
