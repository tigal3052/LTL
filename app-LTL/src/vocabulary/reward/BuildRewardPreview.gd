# 계약:
# - 책임: 보상 payload를 다음 전투에서 플레이어가 이해할 수 있는 modifier preview로 변환한다.
# - 입력: reward Dictionary.
# - 출력: { "summary": String, "modifiers": Dictionary } 형태의 scene-safe preview.
# - 금지: reward roll, UI node 접근, runtime state mutation.
#
# 실행: define the BuildRewardPreview vocabulary capsule.
class_name BuildRewardPreview
extends RefCounted

# 실행: build a next-combat modifier preview from reward payload fields.
static func build(reward: Dictionary) -> Dictionary:
	var payload: Dictionary = reward.get("payload", {})
	var modifiers := {}
	var parts: PackedStringArray = []
	if payload.has("cooldown_mod"):
		var cooldown_mod := int(payload.get("cooldown_mod", 0))
		modifiers["cooldown_mod"] = cooldown_mod
		if cooldown_mod < 0:
			parts.append("쿨타임 %d%% 감소" % abs(cooldown_mod))
		elif cooldown_mod > 0:
			parts.append("쿨타임 %d%% 증가" % cooldown_mod)
	if payload.has("damage_multiplier"):
		var damage_multiplier := float(payload.get("damage_multiplier", 1.0))
		modifiers["damage_multiplier"] = damage_multiplier
		if damage_multiplier > 1.0:
			parts.append("피해 x%.1f" % damage_multiplier)
	if payload.has("shield_repair"):
		var shield_repair := int(payload.get("shield_repair", 0))
		modifiers["shield_repair"] = shield_repair
		if shield_repair > 0:
			parts.append("수리 효율 +%d%%" % shield_repair)
	if payload.has("beacon_cooldown_mod"):
		var beacon_cooldown := int(payload.get("beacon_cooldown_mod", 0))
		modifiers["beacon_cooldown_mod"] = beacon_cooldown
		if beacon_cooldown < 0:
			parts.append("인접 채집기 쿨타임 %d틱 감소" % abs(beacon_cooldown))
		elif beacon_cooldown > 0:
			parts.append("인접 채집기 쿨타임 %d틱 증가" % beacon_cooldown)
	if payload.has("beacon_damage_mod"):
		var beacon_damage := float(payload.get("beacon_damage_mod", 0.0))
		modifiers["beacon_damage_mod"] = beacon_damage
		if beacon_damage > 0.0:
			parts.append("인접 채집기 피해 +%.1f" % beacon_damage)
	if payload.has("hazard_increase"):
		var hazard := int(payload.get("hazard_increase", 0))
		modifiers["hazard_increase"] = hazard
		if hazard > 0:
			parts.append("위험도 +%d" % hazard)
	if parts.is_empty():
		parts.append("다음 전투 영향 없음")
	return {"summary": ", ".join(parts), "modifiers": modifiers}
