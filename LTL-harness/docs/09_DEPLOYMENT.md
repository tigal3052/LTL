# Deployment

- **Target Platform**: PC (Steam)
- 개발 빌드 및 알파/베타/출시 후보(RC) 빌드 파이프라인.
# Deployment

LTL의 배포 문서는 정식 릴리즈 이전에는 `재현 가능한 테스트 빌드`를 만드는 기준으로 사용합니다.

## 프로토타입 빌드 기준

- P0/P1 headless 테스트가 통과한다.
- `PrototypeTuning.json`, `ArtifactTable.json`, `NodeTable.json`이 포함된다.
- replay fixture와 expected result가 저장소에 포함된다.
- 빌드 버전, seed, 데이터 해시를 화면 또는 로그에서 확인할 수 있다.

## 정식 릴리즈 후보 기준

- Windows export smoke test가 통과한다.
- 첫 실행부터 전투, 클리어, 보상, 다음 노드 진입까지 중단 없이 진행된다.
- 크래시 로그와 telemetry 로그 저장 경로가 명확하다.
- 디버그 hot reload는 릴리즈 빌드에서 비활성화되거나 안전하게 제한된다.

## 배포 전 확인 항목

- Godot/GUT 버전 기록
- 데이터 테이블 해시 기록
- regression fixture 통과 기록
- 알려진 미해결 이슈와 우회 방법 기록
