# M6 Manual Sign-Off Checklist

## 2026-06-15 Closure Status

- M6 completion was processed by explicit user request on 2026-06-15.
- Unchecked manual QA items below remain evidence gaps; they are not silently converted into passed checks.
- The completion report carrying this status is `LTL-harness/docs/11_exec-plans/02_completed/12_M6_ui_ux_finalization_completed.md`.

기준일: 2026-06-12

## 자동 확인 결과

- [x] `source-map-gate.ps1`
- [x] `run_main_layout_audit_contract.gd`
- [ ] 스크린샷 매트릭스
- [ ] 전투 화면 1초 가독성 수동 점검
- [ ] failure/retry에서 "왜 졌는지 / 다음에 뭘 해야 하는지" 수동 점검
- [ ] 접근성 토글의 실제 체감 영향 수동 점검
- [x] 접근성 토글의 저장/재실행 유지 계약
- [x] 남는 known issue 문서화

## 자동 확인에 사용한 명령

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File LTL-harness/tools/source-map-gate.ps1 -Root .
powershell -NoProfile -ExecutionPolicy Bypass -File tools/invoke-godot.ps1 -ProjectPath app-LTL -Headless -Script tests/run_main_layout_audit_contract.gd
powershell -NoProfile -ExecutionPolicy Bypass -File tools/invoke-godot.ps1 -ProjectPath app-LTL -Headless -Script tests/run_test_ui_read_models.gd
```

## 수동 점검 방법

### 1. 스크린샷 매트릭스

확인 해상도:

- `1280x720`
- `1440x900`
- `1920x1080`
- 별도 16:10 샘플 1장
  권장: `1680x1050`

확인 대상 화면:

- `character_select`
- `leviathan_select`
- `node_select`
- `battle`
- `reward`
- `defeat`

합격 기준:

- 제목, 본문, CTA 버튼, 주요 카드가 잘리지 않는다.
- 버튼이 화면 밖으로 밀리지 않는다.
- 스크롤이 있어도 의도된 영역에만 생기고, 핵심 CTA는 스크롤 없이 바로 보인다.
- 배경 아트나 파티클이 텍스트를 읽기 어렵게 덮지 않는다.

### 2. 전투 화면 1초 가독성

실행 방법:

- 전투 진입 직후 1초 동안 화면을 본다.
- 아래 네 가지를 바로 말할 수 있는지 확인한다.
  - 지금 맞춰야 할 색
  - 현재 위험 상태
  - 누를 수 있는 핵심 버튼
  - 보상이나 다음 단계로 넘어갈 수 있는지

합격 기준:

- 1초 안에 위 네 가지를 헷갈리지 않고 말할 수 있다.
- 좌측 상태, 중앙 전장/백팩, 우측 로그가 서로 시선을 뺏어 정보 우선순위를 흐리지 않는다.
- 중요한 경고가 색만으로 전달되지 않고 텍스트나 형태로도 읽힌다.

### 3. failure / retry 설명력

실행 방법:

- 일부러 패배 화면으로 진입한다.
- 패배 직후 아래 두 질문에 화면만 보고 답할 수 있는지 본다.
  - 왜 졌는가?
  - 다음 판에서 무엇을 바꿔야 하는가?

합격 기준:

- 패배 원인이 문장으로 읽힌다.
- 다음 시도 팁이 추상적이지 않고 실제 행동으로 이어진다.
- `Retry` 또는 복귀 동선이 한 번에 보이고, 눌렀을 때 흐름이 끊기지 않는다.

### 4. 접근성 토글 체감 확인

토글 대상:

- `screenshake`
- `reduced flash`
- `reduced particles`
- `hold-fire assist`

실행 방법:

- 설정을 열고 토글을 하나씩 켠다/끈다.
- 전투 또는 보상 연출로 돌아가 실제 변화가 보이는지 확인한다.
- 게임을 완전히 다시 실행한 뒤 마지막 설정이 유지되는지 본다.

합격 기준:

- `screenshake`: 충격 때 화면 흔들림이 줄거나 꺼진다.
- `reduced flash`: 강한 번쩍임과 밝은 플래시가 눈에 띄게 약해진다.
- `reduced particles`: 입자 수나 입자 존재가 분명히 줄어든다.
- `hold-fire assist`: 길게 누를 때 기본 연사보다 더 넓은 보조가 실제 전투 입력에 반영된다.
- 재실행 후에도 마지막 설정값이 그대로 남아 있다.

## 완료 판정 메모

- 자동 게이트가 모두 초록이어도, 스크린샷 매트릭스와 사람이 직접 보는 가독성 체크가 비어 있으면 M6를 완전 완료로 부르면 안 된다.
- 남은 이슈와 증거 공백은 `docs/m6-known-issues.ko.md`에 정리한다.
