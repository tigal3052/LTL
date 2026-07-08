# M7 내러티브 통합 수동 사인오프 체크리스트

기준일: 2026-06-16

## 현재 상태

- M7 내러티브 통합은 코드 구현과 자동 계약 검증 기준으로 완료 상태다.
- 수동 플레이 확인은 아래 항목을 기준으로 별도 확인한다.
- 내러티브는 전투, 보상, 노드 선택 리듀서 규칙을 바꾸지 않고 UI 읽기 모델과 토스트 표시 계층에서만 합성한다.

## 자동 확인

- [x] 내러티브 beat 데이터가 `intro_contract`, `first_valid_hit`, `first_artifact`, `first_failure`, `first_clear`, `hunt_tension` 핵심 beat를 포함한다.
- [x] 각 beat가 `screenId`, `triggerPhase`, `displayMode`, `skipInputAllowed`, 현지화 텍스트, side-effect-free 계약을 가진다.
- [x] 순수 내러티브 선택/기록/읽기 모델/텔레메트리 계약이 통과한다.
- [x] 첫 node-select 진입에서 intro toast가 표시되고, 입력을 막지 않는다.
- [x] 전체 Godot 계약 runner가 새 내러티브 스크립트를 로드하고 주석 계약을 통과한다.

## 수동 확인 항목

- [ ] 첫 계약 진입 시 intro toast가 화면 주요 행동 버튼이나 노드 선택을 가리지 않는다.
- [ ] 첫 유효 타격, 첫 아티팩트, 첫 실패, 첫 클리어 상황에서 적절한 문구가 한 번씩만 표시된다.
- [ ] reward ceremony 중에는 내러티브 toast가 보상 연출을 방해하지 않는다.
- [ ] 한국어/영어 전환 후 문구가 의도한 언어로 읽힌다.
- [ ] 토스트가 키보드/마우스 진행을 막지 않고, 반복 플레이 중 화면을 과도하게 점유하지 않는다.

## 검증 명령

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools/invoke-godot.ps1 -ProjectPath app-LTL -Headless -Script res://tests/run_node_select_start_gate_contract.gd
powershell -NoProfile -ExecutionPolicy Bypass -File tools/invoke-godot.ps1 -ProjectPath app-LTL -Headless -Script res://tests/godot_contract_runner.gd
powershell -NoProfile -ExecutionPolicy Bypass -File tools/run-compile-check.ps1
```

## 주의

- 수동 확인 항목은 자동 계약으로 대체하지 않는다.
- 접근성 체감 확인은 M6에서 후속 UX sign-off 항목으로 분리된 상태를 유지한다.
