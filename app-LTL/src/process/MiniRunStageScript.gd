# 계약:
# - 책임: 한 스테이지의 절 순서(STAGE_SENTENCE) 및 흐름 구성 사양을 제공한다.
# - 입력: 없음.
# - 출력: 진행 흐름 상태 문자열 Array.
# - 금지: SceneTree 접근, 비즈니스 로직 작성.
#
# 실행: define the MiniRunStageScript class identity.
class_name MiniRunStageScript
extends RefCounted

# 실행: declare the formal stage sentence order.
const STAGE_SENTENCE := [
	"node_select",
	"combat_start",
	"combat",
	"combat_end",
	"reward_loot",
	"backpack_organize"
]

# 실행: declare alternative stage sentence order.
const STAGE_SENTENCE_ALT := [
	"node_select",
	"combat_start",
	"combat",
	"combat_end",
	"reward_loot",
	"backpack_organize"
]
