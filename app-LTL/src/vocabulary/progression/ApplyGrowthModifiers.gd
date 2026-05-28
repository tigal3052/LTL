# 계약:
# - 책임: RunGrowthState의 active modifier를 inventory artifact와 combat tuning에 적용한다.
# - 입력: InventoryModel, RunGrowthState, tuning Dictionary.
# - 출력: { ok, inventory, tuning, code } dictionary.
# - 금지: UI 접근, reward history 변경, phase 전환.
#
# 실행: define the ApplyGrowthModifiers vocabulary function holder.
class_name ApplyGrowthModifiers
extends RefCounted

# 실행: apply active cooldown and damage modifiers.
static func apply(inventory: InventoryModel, growth_state: RefCounted, tuning: Dictionary) -> Dictionary:
	if inventory == null or growth_state == null:
		return {"ok": false, "code": "missing_input", "inventory": inventory, "tuning": tuning}
	var cooldown_mod := float(growth_state.get_cooldown_modifier())
	for art_id in inventory.artifacts:
		var art: Artifact = inventory.artifacts[art_id]
		var default_base := _default_base_cooldown(art)
		art.base_cooldown_ticks = int(default_base * cooldown_mod)
		art.current_cooldown = mini(art.current_cooldown, art.base_cooldown_ticks)
	if not tuning.has("combat") or not (tuning["combat"] is Dictionary):
		tuning["combat"] = {}
	tuning["combat"]["damage_bonus"] = growth_state.get_damage_bonus()
	return {"ok": true, "code": "applied", "inventory": inventory, "tuning": tuning}

# 실행: infer the stable original cooldown for starter drills.
static func _default_base_cooldown(art: Artifact) -> int:
	if "ruby" in art.id.to_lower() or "ruby" in art.name.to_lower():
		return 80
	if "sapphire" in art.id.to_lower() or "sapphire" in art.name.to_lower():
		return 60
	if "emerald" in art.id.to_lower() or "emerald" in art.name.to_lower():
		return 120
	if "amethyst" in art.id.to_lower() or "amethyst" in art.name.to_lower():
		return 100
	return art.base_cooldown_ticks
