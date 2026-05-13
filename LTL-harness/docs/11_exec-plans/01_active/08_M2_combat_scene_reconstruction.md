# M2. 전투 씬 재구성

## 목표

프로토타입 HUD를 정식 전투 화면으로 재구성하되 도메인 규칙은 중복 구현하지 않는다.

## 산출물

- 정식 combat scene
- 7:3 레이아웃
- 3x10 terrain renderer
- queue, pin, repair, hazard HUD
- input adapter

## QA 대상

- 모든 해상도에서 3x10 셀이 겹치지 않는다.
- 조준/발사/비활성/수리 피드백이 즉시 읽힌다.
- replay fixture는 scene 없이도 계속 통과한다.

## 완료 기준

- P2 수동 QA를 정식 씬에서 통과한다.
- 연출 변경이 도메인 테스트 결과를 바꾸지 않는다.
