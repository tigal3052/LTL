# Local Toolchain Paths

## Owner / Machine

- Owner: YoungSoon
- Workspace root: `D:\Programming\ex_workspace\LootingTheLeviathan`
- Updated: 2026-05-13

## OS / Shell

- Windows build: `10.0.26200.8246`
- Primary shell in this workspace: `PowerShell 5.1.26100.8115`
- WSL version: `2.6.3.0`
- Common shell caveat: PowerShell profile loading is blocked by execution policy in this environment, so each shell command may emit a `Microsoft.PowerShell_profile.ps1` warning even when the command itself succeeds.

## Toolchain

| Tool | Version | Absolute Path | Verification Command | Notes |
|------|---------|---------------|----------------------|-------|
| Godot Console | `4.3.stable.official.77dcf97d8` | `D:\Programming\godot_workspace\bin\Godot_v4.3-stable_win64_console.exe` | `& 'D:\Programming\godot_workspace\bin\Godot_v4.3-stable_win64_console.exe' --version` | Headless/script execution용 |
| Godot Editor | `4.3` | `D:\Programming\godot_workspace\bin\Godot_v4.3-stable_win64.exe` | 파일 존재 확인 | GUI editor 실행용 |
| Node.js | `v24.13.1` | `D:\Program Files\nodejs\node.exe` | `node --version` | `npm` 대신 `node --test` 직접 실행이 안전함 |
| Python | `3.14.3` | `C:\Python314\python.exe` | `python --version` | |
| Git | `2.48.1.windows.1` | `C:\Program Files\Git\cmd\git.exe` | `git --version` | |
| WSL | `2.6.3.0` | `C:\WINDOWS\system32\wsl.exe` | `wsl --version` | Linux side 확인용 |

## Frequently Used Commands

```powershell
node --test

& 'D:\Programming\godot_workspace\bin\Godot_v4.3-stable_win64_console.exe' `
  --headless `
  --path 'D:\Programming\ex_workspace\LootingTheLeviathan\app-LTL' `
  --script prototype/tools/replay_runner.gd `
  --quit
```

## PATH Highlights

- `D:\Program Files\nodejs\`
- `C:\Python314\`
- `C:\Program Files\Git\cmd`
- `D:\Programs\flutter\bin`
- `D:\Program Files\PostgreSQL\17\bin`
- `C:\Users\YoungSoon\AppData\Local\Android\Sdk\platform-tools`
- `C:\Users\YoungSoon\AppData\Local\OpenAI\Codex\bin`

## Known Local Pitfalls

- PowerShell 실행 정책 때문에 프로필 로드 경고가 섞여 나온다. 종료 코드와 실제 표준 출력/오류를 분리해서 봐야 한다.
- `npm` PowerShell shim은 환경에 따라 막힐 수 있어, 간단한 테스트는 `node --test` 직접 실행이 더 안정적이다.
- Godot headless replay는 현재 `signal 11` 크래시가 재현되고 있으므로, 경로 문제와 엔진/스크립트 문제를 구분해서 봐야 한다.
