# 계약:
# - 책임: reward 획득 효과를 RunGrowthState에 적용한다.
# - 입력: RunGrowthState, reward Dictionary.
# - 출력: { ok, growth, goldDelta, xpDelta, code } dictionary.
# - 금지: inventory 변경, UI 접근, phase 전환.
#
# 실행: define the ApplyRewardEffect vocabulary function holder.
class_name ApplyRewardEffect
extends RefCounted

# 실행: apply rarity-based reward payout and history.
static func apply(growth_state: RefCounted, reward: Dictionary) -> Dictionary:
	if growth_state == null:
		return {"ok": false, "code": "missing_growth", "growth": growth_state, "goldDelta": 0, "xpDelta": 0}
	var payout := payout_for_rarity(str(reward.get("rarity", "common")))
	growth_state.reward_history.append(reward.get("rewardId", ""))
	growth_state.add_gold(int(payout["gold"]))
	growth_state.add_xp(int(payout["xp"]))
	return {"ok": true, "code": "applied", "growth": growth_state, "goldDelta": int(payout["gold"]), "xpDelta": int(payout["xp"])}

# 실행: return gold/xp payout for a reward rarity.
static func payout_for_rarity(rarity: String) -> Dictionary:
	var normalized := rarity.to_lower()
	if normalized == "rare":
		return {"gold": 25, "xp": 15}
	if normalized == "epic":
		return {"gold": 50, "xp": 30}
	if normalized == "legendary":
		return {"gold": 100, "xp": 60}
	if normalized == "mythic":
		return {"gold": 200, "xp": 120}
	return {"gold": 10, "xp": 5}
