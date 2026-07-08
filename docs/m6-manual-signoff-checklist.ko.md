# M6 수동 사인오프 체크리스트

기준일: 2026-06-15

## 현재 상태

- M6는 2026-06-15 사용자의 명시 요청으로 완료 처리되었다.
- 자동 검증은 통과했고, 남은 항목은 수동 UX 확인 또는 증거 보강 항목으로 관리한다.
- 완료 보고서: `LTL-harness/docs/11_exec-plans/02_completed/12_M6_ui_ux_finalization_completed.md`

## 체크리스트

- [x] `source-map-gate.ps1`
- [x] `run_main_layout_audit_contract.gd`
- [x] 전체 스크린샷 매트릭스 저장소 증거
- [x] 전투 화면 1초 가독성 수동 확인
- [x] failure/retry 화면의 원인/다음 행동 문구 수동 확인
- [ ] 접근성 토글의 실제 체감 영향 수동 확인
- [x] 접근성 토글 저장/재실행 유지 계약
- [x] 남은 known issue 문서화

## 자동 확인에 사용한 명령

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File LTL-harness/tools/source-map-gate.ps1 -Root .
powershell -NoProfile -ExecutionPolicy Bypass -File tools/invoke-godot.ps1 -ProjectPath app-LTL -Headless -Script tests/run_main_layout_audit_contract.gd
powershell -NoProfile -ExecutionPolicy Bypass -File tools/invoke-godot.ps1 -ProjectPath app-LTL -Headless -Script tests/run_test_ui_read_models.gd
```

## 스크린샷 매트릭스 증거

저장 위치: `docs/evidence/m6-screenshot-matrix/2026-06-15/`

캡처 명령:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools\capture-m6-screenshot-matrix.ps1 -SettleDelaySeconds 3
```

확인 해상도:

- `1280x720`
- `1440x900`
- `1680x1050`
- `1920x1080`

확인 대상 화면:

- `character_select`
- `leviathan_select`
- `node_select`
- `battle`
- `reward`
- `defeat`

증거 색인: `docs/evidence/m6-screenshot-matrix/2026-06-15/README.ko.md`

## 전투 화면 1초 가독성

사용자가 2026-06-15에 "전투 화면 1초 가독성은 일단 통과되었다고 판단한다"고 명시했으므로 통과로 기록한다.

수동 확인 기준:

- 전투 진입 직후 1초 안에 현재 목표, 위험 상태, 사용할 수 있는 버튼, 다음 진행 방향을 파악할 수 있다.
- 좌측 상태, 중앙 전장/백팩, 우측 로그가 서로 시선을 방해하지 않는다.
- 중요한 경고가 색상만이 아니라 텍스트나 형태로도 읽힌다.

## failure / retry 문구

사용자가 2026-06-15에 게임오버 재시작 문구를 수정했고 통과로 판단한다고 명시했으므로 통과로 기록한다.

수동 확인 기준:

- 실패 원인이 문장으로 읽힌다.
- 다음 시도에서 무엇을 바꾸면 되는지 추상적이지 않게 이해된다.
- 재시도 또는 복귀 동선이 한 번에 보이고 과장되게 흔들리지 않는다.

## 접근성 토글 체감 확인

접근성 토글은 설정에서 전투 효과 강도나 입력 보조를 조절하는 항목을 뜻한다.

- `screenshake`: 충격/피격 시 화면 흔들림을 켜거나 끈다.
- `reduced flash`: 빔, 번쩍임, 강한 플래시 표현을 약하게 줄인다.
- `reduced particles`: 피격 파티클과 부유 효과 수를 줄인다.
- `hold-fire assist`: 길게 누르는 발사 입력을 더 관대하게 보조한다.

현재 코드 계약은 이 값들이 저장되고 재실행 뒤 유지되는지 확인한다. 남은 수동 확인은 실제 전투에서 토글을 켰을 때 사용자가 충분히 차이를 느끼는지 확인하는 것이다.
