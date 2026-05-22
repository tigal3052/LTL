# 계약:
# - 책임: replay 또는 future scene 입력을 formal combat event contract로 번역하는 adapter 경계를 제공한다.
# - M0 반영: browser combat rhythm의 input intent를 formal M1 replay/scene 공용 입력 shape로 조립한다.
# - SoT: browser prototype combat input vocabulary, M1 replay fixture input requirements.
# - 입력: raw input Dictionary, current combat snapshot metadata, optional validation context.
# - 출력: normalized combat event, guard result, unsupported-input diagnostics를 반환하는 public API.
# - 금지: damage 계산, reward 생성, inventory mutation, scene node 접근
#
# 실행:
# - raw input에서 action type, target hint, queue hint, confirm/cancel intent를 먼저 추출한다.
# - action type을 replay-supported combat verb 집합으로 정규화한다.
# - current combat snapshot metadata를 참조해 target index, queue slot, mismatch allowance를 가드한다.
# - 지원하지 않는 action이나 누락된 필드는 stable diagnostic으로 누적한다.
# - 가드 통과 시 normalized combat event를 생성하고, 실패 시 no-op verdict와 diagnostics를 반환한다.
# - adapter 출력은 HeadlessMiniRun과 ReplayProcess가 그대로 소비할 수 있는 공용 shape로 유지한다.
