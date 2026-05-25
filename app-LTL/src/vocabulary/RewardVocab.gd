# 계약:
# - 책임: 전투 클리어 시 획득할 보상 생성에 관한 순수 동사 함수들을 제공한다.
# - 입력: 시드 값, 스테이지 인덱스, 격파된 속성 Array, 튜닝 설정 Dictionary.
# - 출력: 생성된 보상 목록 Array.
# - 금지: SceneTree 접근, 자체 상태 보존 (static func만 가짐).
#
# 실행: define the RewardVocab static entry.
class_name RewardVocab
extends RefCounted

# 실행: roll deterministic rewards based on seed and node weaknesses.
static func roll_stage_rewards(seed_val: int, stage_index: int, weaknesses: Array, tuning: Dictionary) -> Array:
	var reward_color := "red" if weaknesses.has("red") else ("blue" if weaknesses.has("blue") else "normal")
	var reward_tuning: Dictionary = tuning.get("reward", {"weaknessBonus": 1})
	var qty := maxi(1, int(reward_tuning.get("weaknessBonus", 1)))
	var combined_seed := int(seed_val) + int(stage_index) * 0x85ebca6b
	return [{
		"rewardId": "reward_%d" % (combined_seed & 0xffff),
		"kind": "artifact_reward",
		"color": reward_color,
		"qty": qty
	}]
