# 계약:
# - 책임: UI에 보상을 표시하기 위한 퍼블릭 읽기 모델(Read Model) 프로젝션을 제공한다.
# - 입력: raw reward Dictionary 데이터.
# - 출력: 가중치(weight) 정보가 마스킹되고 뱃지 및 설명 정보가 정리된 UI 안전 Dictionary.
# - 금지: 비즈니스 롤 연산, 상태 직접 변형.
#
# 실행: define the RewardReadModel class.
class_name RewardReadModel
extends RefCounted

# 실행: project reward data for UI rendering.
static func project(reward: Dictionary) -> Dictionary:
	return {
		"rewardId": reward.get("rewardId", ""),
		"kind": reward.get("kind", "Unknown Reward"),
		"rarity": reward.get("rarity", "common"),
		"qty": int(reward.get("qty", 1)),
		"presentation": {
			"description": reward.get("presentation", {}).get("description", ""),
			"badge": reward.get("presentation", {}).get("badge", ""),
			"icon": reward.get("presentation", {}).get("icon", "")
		},
		"tags": reward.get("tags", []).duplicate(true)
	}
