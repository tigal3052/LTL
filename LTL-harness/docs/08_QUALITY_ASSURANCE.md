# Quality Assurance (QA) 및 배포전 테스트

구현 이후 참조하는 테스트 종합 검증 문서입니다.
- **통합 테스트**: 전투 씬과 도메인 계층 연결 확인.
- **리플레이/회귀 테스트**: 동일한 고정 Seed와 입력 로그로 항상 동일한 결과가 도출되는지 검증.

## 마일스톤별 QA 게이트

| 단계 | 최소 QA |
|---|---|
| P0 | seed 10회 반복, input log 10회 replay, telemetry 필드 누락 검사 |
| P1 | domain unit 전체 통과, headless mini combat clear/time_over/repair 재현 |
| P2 | 3x10 전 셀 hover, click 1발, hold 0.1초 연사, 비활성 타일 무효 처리 |
| P3 | 인접 시너지, 빙결/고장/수리, 큐 생성 변화 검증 |
| P4 | 3스테이지 미니 런 20회 자동 실행 후 지표 분포 확인 |
| M8 | vertical slice 수동 플레이 체크리스트 통과 |
| M9 | regression suite, export smoke, 로그/크래시 확인 |

## 핵심 지표

- 파동 적중률: `shots_hit_match / shots_fired`
- 미스매치 비율: `shots_hit_mismatch / shots_fired`
- 무효 발사 비율: `shots_invalid_tile_cooldown / shots_fired`
- 큐 누수율: `queue_wasted / queue_generated`
- 수리 압박: `repair_count`, `durability_loss_count`
- 클리어/실패 시간: `clear_time_sec`, `fail_time_sec`

## 수동 QA 체크리스트

- 조준 표시가 항상 셀 1개만 가리킨다.
- 파동 색상과 에너지 색상이 구분된다.
- 큐가 비어 있을 때 발사 실패 피드백이 즉시 보인다.
- 4핀 소진 경고가 실패 전 충분히 읽힌다.
- 수리 상태에서 발사 금지가 명확히 전달된다.
- 클리어 보상 연출이 다음 빌드 선택으로 자연스럽게 이어진다.

## 회귀 금지선

- 같은 fixture replay 결과가 바뀌면 의도한 밸런스 변경인지 확인하고 expected fixture를 함께 갱신한다.
- 도메인 테스트를 깨뜨리는 연출 변경은 허용하지 않는다.
- 데이터 필드 추가는 기본값과 누락 테스트를 동반해야 한다.
