# Plans

## 단기 목표: Minimum Viable Prototype

P0~P4는 출시용 MVP가 아니라 핵심 전투 감각을 검증하는 프로토타입입니다. 목표는 `파동 타이밍 + 에너지 큐 + 장비 배치 + 4핀 시간 압박 + 최소 성장`이 함께 재미를 만드는지 확인하는 것입니다.

## 장기 목표: 정식 구현

M0~M9는 검증된 도메인 계약을 유지하면서 전투 화면, 노드 진행, 방해 요소, 성장/보상, 서사, QA, 배포를 확장합니다.

## 단계 개요

| 단계 | 목적 | 핵심 산출물 |
|---|---|---|
| P0 | 테스트 하네스와 로그 기반 | seed, input log, telemetry schema, replay runner |
| P1 | Headless 코어 루프 | PulseModel, EnergyQueue, MiningResolver, RunSimulator |
| P2 | 전투 조작 슬라이스 | 7:3 화면, hover, 클릭/홀드 발사, HUD |
| P3 | 백팩/방해 요소 슬라이스 | InventoryModel, adjacency synergy, freeze/break repair |
| P4 | 미니 런과 스케일링 | node 선택, reward, stage scaling, mini-run report |
| M0 | 재설계 게이트 | 프로토타입 폐기/승격 판단, 사양 고정 |
| M1~M4 | 도메인/전투/보상/노드 안정화 | 정식 구조와 데이터 테이블 |
| M5~M7 | 위험 요소/UI/서사 통합 | hazard pool, UX, narrative beats |
| M8 | Vertical Slice | 시작부터 보상까지 플레이 가능한 세로 조각 |
| M9 | Release Candidate | 회귀 테스트, 빌드, 운영 기준 |

## 현재 우선순위

1. P0를 먼저 완료해 같은 seed와 같은 input log가 항상 같은 결과를 내도록 만든다.
2. P1에서 화면 없이도 `clear`, `time_over`, `repair`, `queue_waste`가 판정되게 한다.
3. P2 이후에야 화면 연출과 체감 조작을 다듬는다.
4. 정식 콘텐츠 확장은 P4 미니 런 지표가 나온 뒤 결정한다.
