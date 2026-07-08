# 계약:
# - 책임: reward tray에서 reward 하나를 held reward로 선택한다.
# - 입력: pending reward Array, reward index.
# - 출력: { ok, pendingRewards, heldReward, heldRewardIndex, code } dictionary.
# - 금지: inventory 변경, reward 즉시 제거, UI 접근.
#
# 실행: define the PickUpFromRewardTray vocabulary function holder.
class_name PickUpFromRewardTray
extends RefCounted

# 실행: select a pending reward without removing it from the tray.
static func pick_up(pending_rewards: Array, reward_index: int) -> Dictionary:
	var next_pending := pending_rewards.duplicate(true)
	if reward_index < 0 or reward_index >= next_pending.size():
		return {"ok": false, "code": "invalid_reward_index", "pendingRewards": next_pending, "heldReward": {}, "heldRewardIndex": -1}
	var reward = next_pending[reward_index]
	if not (reward is Dictionary):
		return {"ok": false, "code": "invalid_reward_data", "pendingRewards": next_pending, "heldReward": {}, "heldRewardIndex": -1}
	return {"ok": true, "code": "picked_up_reward", "pendingRewards": next_pending, "heldReward": reward.duplicate(true), "heldRewardIndex": reward_index}
