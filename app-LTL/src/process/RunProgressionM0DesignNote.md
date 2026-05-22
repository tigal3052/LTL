# 계약:
# - 책임: M0에서 확정한 소거/승격/보류 항목이 M1 formal runtime 구조와 직접 연결되는 설계 메모를 제공한다.
# - 승격:
#   - domain class boundary
#   - telemetry/schema concepts
#   - replay fixture promotion surface
# - 소거:
#   - browser controller/HUD wiring
#   - debug-only UI
#   - temporary presentation-driven structure
# - 보류:
#   - meta growth
#   - narrative systems
#   - large reward pool expansion
# - 금지: 이 문서를 implementation 근거 그 자체로 쓰지 않고, SoT 해설 메모로만 유지한다.
#
# 실행:
# - M0 승격 항목은 `FormalContracts`, `HeadlessMiniRun`, `ReplayProcess`, `CombatInputAdapter`에 어떻게 배치되는지 대응표처럼 정리한다.
# - 소거 항목은 formal 경로에서 재도입되면 안 되는 browser coupling으로 명시한다.
# - 보류 항목은 execution-only 단계에서 구현 블록을 만들지 않는 이유와 함께 남겨 구현 단계 범위를 좁힌다.
# - 이후 구현 단계에서는 이 메모를 참조용으로만 보고, 실제 블록 순서는 각 파일의 `실행:` 주석을 우선한다.
