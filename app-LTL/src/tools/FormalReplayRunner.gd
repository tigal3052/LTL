# 계약:
# - 책임: formal replay fixture 세트를 headless Godot에서 일괄 실행하는 smoke verification entrypoint 경계를 제공한다.
# - M0 반영: 승격된 replay matrix가 formal path에서 자동 검증 가능한 단위로 존재해야 한다.
# - SoT: M1 replay regression deliverable, comment-first gate 이후 implementation verification workflow.
# - 입력: fixture selection policy, optional seed override policy, ReplayProcess public API.
# - 출력: machine-readable aggregate verdict와 fixture별 summary를 제공하는 headless tool contract.
# - 금지: replay rule을 중복 구현하거나 scene preview 실행, prototype fixture 임의 변경을 하지 않는다.
#
# 실행:
# - fixture discovery policy를 읽어 replay 대상 목록을 확정한다.
# - 각 fixture에 대해 ReplayProcess 실행 context를 만들고 deterministic 옵션을 주입한다.
# - replay 결과에서 verdict, final snapshot summary, diagnostic count, trace presence를 추출한다.
# - fixture별 결과를 aggregate summary에 누적하고 failing fixture 목록을 따로 모은다.
# - batch 종료 후 machine-readable report shape를 정리하고 overall pass/fail verdict를 계산한다.
# - CLI 또는 headless caller가 읽기 쉬운 최소 출력 surface만 남긴다.
