# PC_ENVIRONMENT

> 이 폴더는 특정 개발 PC 또는 특정 작업 환경 전용 정보만 둔다.
> 범용 하네스의 기본 규칙은 여기에 두지 않는다.

---

## Why This Folder Is Mandatory

이 폴더가 비어 있으면 다음 문제가 반복된다.

- Godot, Android SDK, Docker, DB CLI 같은 실행 파일 경로를 매번 다시 찾는다.
- PowerShell, WSL, PATH 차이 같은 셸 이슈를 같은 프로젝트 안에서 반복해서 재발견한다.
- 프로젝트 전용 하네스를 만들 때 로컬 전용 정보가 구조에서 빠져 구현 속도가 떨어진다.

로컬 툴체인 의존 작업은 이 폴더의 실제 문서 없이는 Ready 상태가 아니다.

---

## What Belongs Here

- 절대 경로가 필요한 툴체인 정보
- 특정 OS 셸 이슈
- 특정 개발자 PC의 PATH / SDK / 런타임 메모
- 로컬 실행 보조 스크립트 예시
- 자주 쓰는 검증 명령과 그 전제 조건

---

## What Does Not Belong Here

- 프로젝트 공통 아키텍처
- 배포 정책
- 보안 정책
- 범용 테스트 정책

---

## Required Minimum For Project Conversion

프로젝트 전용 하네스로 전환할 때 아래 둘은 반드시 만든다.

1. `00_README.md`
2. 실제 환경 문서 1개 이상

권장 기본 파일:

- `01_toolchain-paths.<owner>.md`
- `02_local-shell-notes.<owner>.md`

---

## Reference Rule

- `docs/11_exec-plans/01_active/*.md`는 로컬 툴 의존 작업이면 이 폴더의 실제 파일을 입력 문서에 적어야 한다.
- 완료 문서에는 어떤 환경 문서를 참조했는지 남긴다.
- 프로젝트 루트 `README.md`나 `00_AGENTS.md`에도 필요 시 대표 환경 문서를 링크한다.

공유 저장소라면 개인 정보나 민감 경로 노출에 주의한다.
