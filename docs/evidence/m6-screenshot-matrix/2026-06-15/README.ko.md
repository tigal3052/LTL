# M6 스크린샷 매트릭스 증거

캡처일: 2026-06-15

이 디렉터리는 M6 수동 사인오프에서 요구한 전체 스크린샷 매트릭스 증거를 저장한다. 라이브 Godot 창을 실제로 띄운 뒤 Win32 클라이언트 영역을 캡처했으며, headless/dummy 렌더러 산출물이 아니다.

## 캡처 명령

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools\capture-m6-screenshot-matrix.ps1 -SettleDelaySeconds 3
```

## 범위

- 화면: `character_select`, `leviathan_select`, `node_select`, `battle`, `reward`, `defeat`
- 해상도: `1280x720`, `1440x900`, `1680x1050`, `1920x1080`
- 총 산출물: 6개 화면 x 4개 해상도 = 24 PNG

## 매트릭스

| 화면 | 1280x720 | 1440x900 | 1680x1050 | 1920x1080 |
| --- | --- | --- | --- | --- |
| character_select | [PNG](character_select_1280x720.png) | [PNG](character_select_1440x900.png) | [PNG](character_select_1680x1050.png) | [PNG](character_select_1920x1080.png) |
| leviathan_select | [PNG](leviathan_select_1280x720.png) | [PNG](leviathan_select_1440x900.png) | [PNG](leviathan_select_1680x1050.png) | [PNG](leviathan_select_1920x1080.png) |
| node_select | [PNG](node_select_1280x720.png) | [PNG](node_select_1440x900.png) | [PNG](node_select_1680x1050.png) | [PNG](node_select_1920x1080.png) |
| battle | [PNG](battle_1280x720.png) | [PNG](battle_1440x900.png) | [PNG](battle_1680x1050.png) | [PNG](battle_1920x1080.png) |
| reward | [PNG](reward_1280x720.png) | [PNG](reward_1440x900.png) | [PNG](reward_1680x1050.png) | [PNG](reward_1920x1080.png) |
| defeat | [PNG](defeat_1280x720.png) | [PNG](defeat_1440x900.png) | [PNG](defeat_1680x1050.png) | [PNG](defeat_1920x1080.png) |

## 사인오프 메모

- 전투 화면 1초 가독성: 사용자가 2026-06-15에 통과로 판단했다.
- 게임오버/재시작 문구: 사용자가 문구 수정 후 2026-06-15에 통과로 판단했다.
- 접근성 토글: 코드 계약은 저장/적용을 확인하지만, 실제 체감 강도 수동 평가는 아직 별도 판단이 필요하다.
