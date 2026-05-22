# 계약:
# - 책임: promoted replay fixture를 formal headless runtime에 재생하는 integration contract 경계를 제공한다.
# - M0 반영: one-shot clear, empty-queue repair pressure, mismatch attack, reward claim progression, final stage clear, run-complete branching, last-artifact guard를 replay-visible 계약으로 묶는다.
# - SoT: `app-LTL/prototype/browser-p0-p4/tests/fixtures/input_logs/**`, M1 replay matrix, 2026-05-20 interview addendum decisions.
# - 입력: fixture spec path 또는 fixture Dictionary, validated contract helpers, headless runtime constructor, input adapter API.
# - 출력: final public snapshot, replay-visible summary, diagnostics, optional trace를 반환하는 public API.
# - 금지: combat rule 자체를 재정의하거나 parallel SoT를 만들지 않고, scene mutation이나 browser-only telemetry schema 강제를 하지 않는다.
#
# 실행:
# - fixture source를 path 또는 in-memory Dictionary로 받아 deterministic fixture object로 정규화한다.
# - fixture header를 검증해 seed, stage count, expected branch, trace policy를 확정한다.
# - headless mini-run 인스턴스를 만들고 replay step cursor를 초기화한다.
# - 각 step에서 raw replay input을 CombatInputAdapter로 넘겨 normalized event 또는 guard failure를 만든다.
# - normalized event는 HeadlessMiniRun phase transition API에 순서대로 전달한다.
# - step 실행 중에는 snapshot trace, branch summary, diagnostic accumulation을 같은 replay context에 모은다.
# - replay 종료 시에는 expected final state와 actual final snapshot을 비교해 verdict를 정리한다.
