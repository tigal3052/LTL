# 계약:
# - 책임: combat phase에서 제한된 public presentation state를 별도 read model로 조립해 HUD/scene이 low-level runtime을 직접 읽지 않게 한다.
# - M0 반영: browser combat HUD에서 검증한 정보만 남기고 renderer/controller leakage는 제거한다.
# - SoT: combat phase snapshot contract, mismatch visibility decision, queue/time/pin rhythm baseline.
# - 입력: combat phase public snapshot, optional label/lookup tables.
# - 출력: combat HUD, target panel, queue panel, feedback rendering에 필요한 read-only data contract.
# - 금지: combat progression mutation, reward state 접근, browser render ordering 가정
#
# 실행:
# - combat phase snapshot인지 먼저 확인하고 아니면 guard failure surface를 만든다.
# - actor/target summary, queue summary, timer summary, mismatch summary를 별도 블록으로 나눈다.
# - 각 블록은 HUD가 바로 소비할 수 있도록 primitive field와 display-safe label만 남긴다.
# - 선택 가능 target, pending queue item, 최근 feedback를 정규화해 panel별 read model로 재배치한다.
# - mismatch 또는 guard 상태는 숨기지 않고 별도 feedback surface로 올린다.
# - 최종 combat scene model은 mutation 없이 read-only Dictionary로 마감한다.
