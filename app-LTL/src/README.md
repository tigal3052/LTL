# 계약:
# - 책임: M0 재설계 게이트에서 확정된 정식 폴더 구조와 파일 책임 분리를 formal Godot 경로 기준으로 고정한다.
# - SoT: `LTL-harness/docs/11_exec-plans/01_active/06_M0_redesign_gate.md`, `LTL-harness/docs/11_exec-plans/01_active/07_M1_core_domain_stabilization.md`, `LTL-harness/docs/comment-first-enforcement.md`.
# - 범위: `domain/`, `process/`, `ui/`, `tools/` 아래의 정식 M1 계약 파일과 headless 검증 진입점을 정의한다.
# - 구조:
#   - `domain/`: formal data contract와 snapshot contract를 검증하는 진입점
#   - `process/`: headless mini-run, replay, input adaptation 같은 phase progression orchestration
#   - `ui/`: scene/HUD가 private runtime을 보지 않도록 하는 read model 계약
#   - `tools/`: headless smoke verification 진입점
# - 금지: prototype 소스를 직접 복사하거나 browser-only runtime 의존을 정식 경로에 조기 유입하지 않는다.
#
# 실행:
# - `domain/`은 raw data를 정규화하고 검증 결과를 공용 snapshot 계약으로 승격시키는 순서로 구현 블록을 배치한다.
# - `process/`는 초기화 -> 입력 해석 -> phase 전이 -> 결과 snapshot 정리 순서가 드러나도록 파일별 실행 블록을 맞춘다.
# - `ui/`는 public snapshot만 읽고 scene-safe read model만 만드는 순서를 유지한다.
# - `tools/`와 `tests/`는 fixture 선택 -> headless 실행 -> verdict 집계 -> failure surface 기록 순서로 맞춘다.
# - 이후 구현 단계에서는 이 README를 실행 코드 근거로 쓰지 않고, 각 파일의 `계약:`과 `실행:` 주석이 직접 SoT 역할을 맡는다.
