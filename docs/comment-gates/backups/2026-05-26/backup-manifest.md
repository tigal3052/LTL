# Backup Manifest (2026-05-26)

이 백업 세트는 디커플링 규칙의 루프홀을 메우기 위해 하네스 검증 규칙 스크립트 및 문서를 수정하기 전에 생성되었습니다.

## 백업 파일 정보

- **LTL Harness - tools/architectural-gate.ps1**
  - 원본 경로: `LTL-harness/tools/architectural-gate.ps1`
  - 백업 경로: `docs/comment-gates/backups/2026-05-26/ltl-harness/tools/architectural-gate.ps1`
- **LTL Harness - docs/architectural-decoupling-enforcement.md**
  - 원본 경로: `LTL-harness/docs/architectural-decoupling-enforcement.md`
  - 백업 경로: `docs/comment-gates/backups/2026-05-26/ltl-harness/docs/architectural-decoupling-enforcement.md`
- **Agent Harness - tools/architectural-gate.ps1**
  - 원본 경로: `d:/Programming/ex_workspace/agent-harness/tools/architectural-gate.ps1`
  - 백업 경로: `docs/comment-gates/backups/2026-05-26/agent-harness/tools/architectural-gate.ps1`
- **Agent Harness - docs/architectural-decoupling-enforcement.md**
  - 원본 경로: `d:/Programming/ex_workspace/agent-harness/docs/architectural-decoupling-enforcement.md`
  - 백업 경로: `docs/comment-gates/backups/2026-05-26/agent-harness/docs/architectural-decoupling-enforcement.md`

## 백업 사유
- 오케스트레이터 및 뷰가 임계값 미만 크기일 때 의존성 검사(금지 패턴 검사)를 아예 건너뛰는 우회 루프홀을 차단하기 위함.

## 복원 명령
```powershell
Copy-Item docs/comment-gates/backups/2026-05-26/ltl-harness/tools/architectural-gate.ps1 LTL-harness/tools/ -Force
Copy-Item docs/comment-gates/backups/2026-05-26/ltl-harness/docs/architectural-decoupling-enforcement.md LTL-harness/docs/ -Force
Copy-Item docs/comment-gates/backups/2026-05-26/agent-harness/tools/architectural-gate.ps1 d:/Programming/ex_workspace/agent-harness/tools/ -Force
Copy-Item docs/comment-gates/backups/2026-05-26/agent-harness/docs/architectural-decoupling-enforcement.md d:/Programming/ex_workspace/agent-harness/docs/ -Force
```
