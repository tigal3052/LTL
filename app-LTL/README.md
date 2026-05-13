# Looting The Leviathan Prototype

`LTL-harness`의 P0/P1 기준으로 시작해 P2 전투 조작 슬라이스 일부까지 반영한 테스트 가능 골격입니다.

## 포함된 것

- Godot 4.3 프로젝트 골격: `project.godot`, `prototype/`
- P0: seed, telemetry, replay runner 기초
- P1: energy queue, mining resolver, run simulator 기초
- P2: hover, click 1발, hold 0.1초 연사, cooldown/empty queue 피드백용 입력 제어 슬라이스
- Node 내장 테스트: `node --test`
- Godot headless replay 스크립트: `prototype/tools/replay_runner.gd`
- 브라우저 확인용 상호작용 데모: `public/index.html`

## 검증 명령

```powershell
node --test
& 'D:\Programming\godot_workspace\bin\Godot_v4.3-stable_win64_console.exe' --headless --path 'D:\Programming\ex_workspace\LootingTheLeviathan\app-LTL' --script prototype/tools/replay_runner.gd --quit
```

## 현재 상태

- Node 테스트 기준으로 P0/P1 계약과 P2 입력 제어 슬라이스가 통과합니다.
- Godot headless replay는 현재 이 환경에서 크래시가 발생해 추가 조사가 필요합니다.
- 브라우저 데모에서는 3x10 타일 hover, 클릭 1발, 마우스 hold 연사, cooldown/empty queue 피드백을 확인할 수 있습니다.

## 다음 단계

- Godot headless replay 크래시 원인 조사 및 복구
- GUT 설치 후 Godot 테스트로 Node 테스트 계약 이전
- `PrototypeTuning.json`을 도메인 코드에서 로드
- P3 백팩/방해 요소 슬라이스로 확장
