# M0. 재설계 게이트

## 목표

P0~P4 결과를 바탕으로 정식 구현에 승격할 계약과 폐기할 임시 구조를 결정한다.

## 입력 자료

- P4 mini-run telemetry
- 수동 플레이 노트
- replay fixture 결과
- 프로토타입 코드 구조 리뷰

## 결정 항목

- 유지: domain class, telemetry schema, JSON data format, GUT fixture
- 교체: PrototypeMain/Controller/HUD, debug-only UI, 임시 연출
- 보류: 메타 성장, 서사, 대규모 보상 풀

## 완료 기준

- 정식 구현용 폴더 구조와 네이밍이 확정된다.
- P1~P4 fixture 중 정식 회귀 테스트로 승격할 항목이 정해진다.
- M1 작업 전 기술 부채 목록이 `00_tech-debt-tracker.md`에 반영된다.
