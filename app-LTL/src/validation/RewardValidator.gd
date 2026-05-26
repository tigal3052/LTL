# 계약:
# - 책임: reward-table, rarity-table, run growth state 데이터의 유효성을 검증한다.
# - 입력: raw Dictionary 데이터.
# - 출력: { "ok": bool, "errors": Array } 형태의 검증 결과.
# - 금지: 외부 입출력 수행, 상태 보존.
#
# 실행: define the RewardValidator class.
class_name RewardValidator
extends RefCounted

# 실행: validate reward table structure.
static func validate_reward_table(table: Dictionary) -> Dictionary:
	var errors := []
	var rewards = table.get("rewards", null)
	if rewards == null:
		errors.append({"path": "rewards", "code": "missing_rewards_array"})
		return {"ok": false, "errors": errors}
	
	if not (rewards is Array):
		errors.append({"path": "rewards", "code": "type_array"})
		return {"ok": false, "errors": errors}
		
	var required_fields := ["id", "kind", "rarity", "weight", "payload", "presentation", "tags"]
	for i in range(rewards.size()):
		var r = rewards[i]
		if not (r is Dictionary):
			errors.append({"path": "rewards[%d]" % i, "code": "type_dictionary"})
			continue
		
		for field in required_fields:
			if not r.has(field):
				errors.append({"path": "rewards[%d].%s" % [i, field], "code": "required"})
			
		if r.has("payload") and not (r["payload"] is Dictionary):
			errors.append({"path": "rewards[%d].payload" % i, "code": "type_dictionary"})
		if r.has("presentation") and not (r["presentation"] is Dictionary):
			errors.append({"path": "rewards[%d].presentation" % i, "code": "type_dictionary"})
		if r.has("tags") and not (r["tags"] is Array):
			errors.append({"path": "rewards[%d].tags" % i, "code": "type_array"})
			
	return {"ok": errors.is_empty(), "errors": errors}

# 실행: validate rarity table structure.
static func validate_rarity_table(table: Dictionary) -> Dictionary:
	var errors := []
	var rarities = table.get("rarities", null)
	if rarities == null:
		errors.append({"path": "rarities", "code": "missing_rarities_array"})
		return {"ok": false, "errors": errors}
		
	if not (rarities is Array):
		errors.append({"path": "rarities", "code": "type_array"})
		return {"ok": false, "errors": errors}
		
	var required_fields := ["id", "label", "weightMul", "presentationTier"]
	for i in range(rarities.size()):
		var r = rarities[i]
		if not (r is Dictionary):
			errors.append({"path": "rarities[%d]" % i, "code": "type_dictionary"})
			continue
			
		for field in required_fields:
			if not r.has(field):
				errors.append({"path": "rarities[%d].%s" % [i, field], "code": "required"})
				
	return {"ok": errors.is_empty(), "errors": errors}

# 실행: validate run growth state structure.
static func validate_growth_state(state: Dictionary) -> Dictionary:
	var errors := []
	var required_fields := ["gold", "xp", "purchasedPassives", "temporaryModifiers", "runModifiers", "rewardHistory"]
	
	for field in required_fields:
		if not state.has(field):
			errors.append({"path": field, "code": "required"})
			
	if state.has("gold") and not (state["gold"] is int or state["gold"] is float):
		errors.append({"path": "gold", "code": "type_number"})
	if state.has("xp") and not (state["xp"] is int or state["xp"] is float):
		errors.append({"path": "xp", "code": "type_number"})
	if state.has("purchasedPassives") and not (state["purchasedPassives"] is Dictionary):
		errors.append({"path": "purchasedPassives", "code": "type_dictionary"})
	if state.has("temporaryModifiers") and not (state["temporaryModifiers"] is Dictionary):
		errors.append({"path": "temporaryModifiers", "code": "type_dictionary"})
	if state.has("runModifiers") and not (state["runModifiers"] is Dictionary):
		errors.append({"path": "runModifiers", "code": "type_dictionary"})
	if state.has("rewardHistory") and not (state["rewardHistory"] is Array):
		errors.append({"path": "rewardHistory", "code": "type_array"})
		
	return {"ok": errors.is_empty(), "errors": errors}
