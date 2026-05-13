# Operations & Telemetry

- 텔레메트리 스키마: 노드 진입, 클리어 시간, 적중률, 큐 누수, 미스매치 발생 비율 등을 수치화하여 로깅.
- 인게임 디버그 콘솔을 통한 JSON 핫리로드 기능 활용.

## 필수 텔레메트리 필드

```text
run_id
seed
stage_index
node_type
shots_fired
shots_hit_match
shots_hit_mismatch
shots_invalid_tile_cooldown
shots_fired_empty_queue
queue_generated
queue_consumed
queue_wasted
durability_loss_count
repair_count
clear_time_sec
fail_time_sec
result
```

## 이벤트 로그 권장 형식

- `run_started`
- `node_entered`
- `pulse_shifted`
- `energy_generated`
- `shot_fired`
- `shot_resolved`
- `queue_wasted`
- `durability_lost`
- `repair_started`
- `repair_completed`
- `pin_released`
- `node_cleared`
- `run_failed`
- `reward_offered`
- `reward_selected`

## 운영용 디버그 기능

- seed 고정/변경
- input log 저장/재생
- telemetry export
- JSON hot reload
- current tick, queue, active hazard, pin state overlay

## 데이터 변경 기록

밸런스 JSON을 바꿀 때는 변경 사유를 남깁니다.

- 어떤 수치가 바뀌었는가
- 어떤 지표를 개선하려는가
- replay expected result가 바뀌었는가
- 수동 QA가 필요한가
