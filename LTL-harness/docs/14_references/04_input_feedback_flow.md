# Input Feedback Flow

## Why This Note Exists

P2 이후 controller/HUD 구현에서는 `summary` 누적치와 `마지막 액션 결과`를 섞지 않아야 합니다. 누적 telemetry는 런 전체 상태를 보여주고, HUD 피드백은 직전 액션의 결과를 보여줍니다.

## Sequential Flow

1. Controller가 입력을 받습니다.
   - hover: `hoveredTile`만 바뀝니다.
   - click/hold fire: `(tick, target, input)`를 input log에 기록할 후보가 됩니다.

2. Controller는 `applyInput` 호출 직전 상태를 저장합니다.
   - `beforeSummary`
   - `beforeRepairRequired`
   - 필요하면 `beforeResult`

3. `RunSimulator.applyInput`가 입력을 처리합니다.
   - 이미 종료됨 / 수리 중 / click 아님: snapshot만 반환
   - target 범위 오류: `invalid_target_inputs`만 증가시키고 snapshot 반환
   - 큐 비어 있음: `shots_fired_empty_queue`, `durability_loss_count` 증가
   - 타일 cooldown 중: `shots_invalid_tile_cooldown` 증가
   - 정상 피격: damage, cooldown, clear/time_over 판정 진행

4. Controller는 `applyInput` 직후 상태를 읽습니다.
   - `afterSummary`
   - `afterRepairRequired`

5. HUD 피드백은 누적 summary 자체가 아니라 `before -> after diff`로 계산합니다.
   - `invalid_target_inputs` 증가: `invalid_target`
   - `shots_fired_empty_queue` 증가: `empty_queue`
   - `shots_invalid_tile_cooldown` 증가: `invalid_cooldown`
   - `result`가 `clear`로 새 전환: `clear`
   - `result`가 `time_over`로 새 전환: `time_over`
   - `repairRequired`가 false -> true: `repair_required`
   - 그 외 이번 click으로 `shots_fired` 증가: `fired`

6. 누적 summary는 계속 유지됩니다.
   - summary는 런 전체 통계입니다.
   - HUD의 마지막 액션 문구는 누적치가 아니라 이번 액션 diff를 기준으로 갱신합니다.

## Summary vs ApplyInput Result

- `summary` 누적치:
  - 런 시작부터 현재까지의 총합
  - 예: 한번 `shots_invalid_tile_cooldown`이 1이 되면 이후 계속 1 이상
  - 용도: run report, telemetry export, replay verification

- `applyInput` 전후 차이:
  - 이번 액션 때문에 새로 증가한 값만 봄
  - 예: 이전 cooldown 실패가 있었어도 이번 액션이 정상 발사면 feedback은 `fired`
  - 용도: HUD, toast, controller state

## Hold Fire Timing

- hold 시작 시 첫 발은 즉시 처리합니다.
- 이후 발사는 `hold_fire_interval`마다 반복합니다.
- 각 반복 발사도 동일하게 `beforeSummary -> applyInput -> afterSummary -> diff` 순서를 탑니다.
- hold 중간에 한번 `invalid_cooldown`이 나와도, 다음 유효 타이밍에 정상 발사되면 feedback은 다시 `fired`로 바뀌어야 합니다.

## Implementation Rule

- controller는 규칙 판정을 중복 구현하지 않습니다.
- controller는 domain snapshot과 telemetry diff를 사용해 마지막 액션 피드백만 계산합니다.
- 동일 로직은 JS/GDScript 양쪽에서 같은 우선순위를 유지해야 합니다.
