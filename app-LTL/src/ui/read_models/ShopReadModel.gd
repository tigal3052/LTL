# 계약:
# - 책임: growth state와 상점 카탈로그를 표시 전용 read model로 투영한다(선택 상태 포함).
# - 입력: growth state Dictionary, passive 정의 Array, base shop item Array, 선택 entry id, shop_enabled 플래그.
# - 출력: 헤더 잔액/탭/항목 목록/상세 패널 payload Dictionary.
# - 금지: run state 변경, 가격·효과 수치 재계산(기존 정의값만 읽는다), 도메인 규칙 판단.
#
# 실행: project shop catalog and selection into a display-only read model.
class_name ShopReadModel
extends RefCounted

const TextCatalogScript = preload("res://src/ui/TextCatalog.gd")

# 실행: 전체 상점 read model을 조립한다.
static func project(
	growth_state: Dictionary,
	passives: Array,
	base_items: Array,
	selected_entry_id: String,
	active_section: String,
	shop_enabled: bool
) -> Dictionary:
	var gold := int(growth_state.get("gold", 0))
	var xp := int(growth_state.get("xp", 0))
	var entries: Array = []
	entries.append_array(_project_passives(growth_state, passives, gold, shop_enabled))
	entries.append_array(_project_base_items(growth_state, base_items, gold, xp, shop_enabled))
	var resolved_section := _resolve_section(active_section)
	var resolved_id := _resolve_selected_id(entries, selected_entry_id)
	for entry in entries:
		entry["selected"] = str(entry.get("id", "")) == resolved_id
	return {
		"gold": gold,
		"xp": xp,
		"goldText": TextCatalogScript.t("shop.gold", [gold]),
		"xpText": TextCatalogScript.t("shop.xp", [xp]),
		"sections": _project_sections(passives.size(), base_items.size(), resolved_section),
		"entries": entries,
		"activeSection": resolved_section,
		"resolvedSelectedEntryId": resolved_id,
		"detail": _project_detail(entries, resolved_id, gold, xp, shop_enabled)
	}

# 실행: 패시브 트리 항목을 투영한다(비용은 기존 base_cost/step 정의를 그대로 사용).
static func _project_passives(growth_state: Dictionary, passives: Array, gold: int, shop_enabled: bool) -> Array:
	var purchased: Dictionary = growth_state.get("purchasedPassives", {})
	var result: Array = []
	for passive in passives:
		var pid := str(passive.get("id", ""))
		var level := int(purchased.get(pid, 0))
		var cost := cost_for(passive, level)
		var affordable := gold >= cost
		result.append({
			"id": pid,
			"group": "passive",
			"name": TextCatalogScript.t("passive.%s.name" % pid),
			"caption": TextCatalogScript.t("passive.%s.effect_short" % pid),
			"effectText": TextCatalogScript.t("passive.%s.desc" % pid, [cost, level]),
			"costGold": cost,
			"costXp": 0,
			"level": level,
			"levelText": TextCatalogScript.t("shop.level", [level]),
			"step": int(passive.get("step", 0)),
			"owned": false,
			"affordable": affordable,
			"purchasable": shop_enabled and affordable,
			"selected": false
		})
	return result

# 실행: 기본 해금 항목을 투영한다(비용은 base-shop-table.json 값을 그대로 사용).
static func _project_base_items(growth_state: Dictionary, base_items: Array, gold: int, xp: int, shop_enabled: bool) -> Array:
	var unlocked_characters: Array = growth_state.get("unlockedCharacters", [])
	var unlocked_items: Array = growth_state.get("unlockedStarterItems", [])
	var scan_unlocks: Array = growth_state.get("scanUnlocks", [])
	var result: Array = []
	for item in base_items:
		var item_id := str(item.get("id", ""))
		var unlock_id := str(item.get("unlockId", item_id))
		var cost_gold := int(item.get("costGold", 0))
		var cost_xp := int(item.get("costXp", 0))
		var category := str(item.get("category", ""))
		var owned := is_base_item_owned(str(item.get("type", "")), unlock_id, unlocked_characters, unlocked_items, scan_unlocks)
		var affordable := gold >= cost_gold and xp >= cost_xp
		result.append({
			"id": item_id,
			"group": "base",
			"name": TextCatalogScript.base_shop_label(item_id, str(item.get("label", item_id))),
			"caption": TextCatalogScript.t("shop.category.%s" % category),
			"effectText": TextCatalogScript.t("shop.base_item_cost", [
				TextCatalogScript.base_shop_label(item_id, str(item.get("label", item_id))), cost_gold, cost_xp
			]),
			"costGold": cost_gold,
			"costXp": cost_xp,
			"level": -1,
			"levelText": "",
			"step": 0,
			"owned": owned,
			"affordable": affordable,
			"purchasable": shop_enabled and affordable and not owned,
			"selected": false
		})
	return result

# 실행: 카탈로그 탭 payload를 만든다.
static func _project_sections(passive_count: int, base_count: int, active_section: String) -> Array:
	return [
		{
			"id": "passive",
			"label": TextCatalogScript.t("shop.section.passive"),
			"subLabel": TextCatalogScript.t("shop.group.passive_sub"),
			"count": passive_count,
			"active": active_section == "passive"
		},
		{
			"id": "base",
			"label": TextCatalogScript.t("shop.section.base"),
			"subLabel": TextCatalogScript.t("shop.group.base_sub"),
			"count": base_count,
			"active": active_section == "base"
		}
	]

# 실행: 선택된 항목을 우측 상세 패널 payload로 투영한다.
static func _project_detail(entries: Array, selected_id: String, gold: int, xp: int, shop_enabled: bool) -> Dictionary:
	var selected := {}
	for entry in entries:
		if str(entry.get("id", "")) == selected_id:
			selected = entry
			break
	if selected.is_empty():
		return {"empty": true, "title": TextCatalogScript.t("shop.title"), "ctaEnabled": false}
	var is_passive := str(selected.get("group", "")) == "passive"
	var ledger: Array = []
	if is_passive:
		ledger.append({"label": TextCatalogScript.t("shop.detail.level_current"), "value": str(int(selected.get("level", 0)))})
		ledger.append({"label": TextCatalogScript.t("shop.detail.level_next_cost"), "value": TextCatalogScript.t("shop.gold_amount", [int(selected.get("costGold", 0))])})
		ledger.append({"label": TextCatalogScript.t("shop.detail.level_step"), "value": TextCatalogScript.t("shop.gold_step", [int(selected.get("step", 0))])})
	else:
		ledger.append({"label": TextCatalogScript.t("shop.detail.cost_gold"), "value": TextCatalogScript.t("shop.gold_amount", [int(selected.get("costGold", 0))])})
		ledger.append({"label": TextCatalogScript.t("shop.detail.cost_xp"), "value": TextCatalogScript.t("shop.xp_amount", [int(selected.get("costXp", 0))])})
		ledger.append({"label": TextCatalogScript.t("shop.detail.status"), "value": TextCatalogScript.t("shop.owned") if bool(selected.get("owned", false)) else TextCatalogScript.t("shop.not_owned")})
	var entry_id := str(selected.get("id", ""))
	return {
		"empty": false,
		"entryId": entry_id,
		"group": str(selected.get("group", "")),
		"badge": TextCatalogScript.t("shop.section.passive") if is_passive else TextCatalogScript.t("shop.section.base"),
		"title": str(selected.get("name", "")),
		"subtitle": TextCatalogScript.t("shop.repeatable") if is_passive else TextCatalogScript.t("shop.one_time"),
		"effectText": str(selected.get("effectText", "")),
		"fieldNotes": TextCatalogScript.t("shop.field_notes.%s" % entry_id),
		"ledger": ledger,
		"costGold": int(selected.get("costGold", 0)),
		"costXp": int(selected.get("costXp", 0)),
		"showXpCost": not is_passive,
		"ctaText": TextCatalogScript.t("shop.owned") if bool(selected.get("owned", false)) else TextCatalogScript.t("shop.detail.cta_buy"),
		"ctaEnabled": bool(selected.get("purchasable", false)) and shop_enabled
	}

# 실행: 유효하지 않은 선택 id는 첫 항목으로 폴백한다.
static func _resolve_selected_id(entries: Array, selected_entry_id: String) -> String:
	for entry in entries:
		if str(entry.get("id", "")) == selected_entry_id:
			return selected_entry_id
	return str(entries[0].get("id", "")) if not entries.is_empty() else ""

# 실행: 알 수 없는 섹션 id는 패시브 탭으로 폴백한다.
static func _resolve_section(active_section: String) -> String:
	return active_section if active_section in ["passive", "base"] else "passive"

# 실행: 패시브 구매 비용을 기존 정의(base_cost + level * step)로 계산한다.
static func cost_for(passive: Dictionary, level: int) -> int:
	return int(passive.get("base_cost", 0)) + level * int(passive.get("step", 0))

# 실행: 해금 항목의 보유 여부를 판정한다.
static func is_base_item_owned(item_type: String, unlock_id: String, characters: Array, starter_items: Array, scans: Array) -> bool:
	match item_type:
		"character":
			return unlock_id in characters
		"starter_item":
			return unlock_id in starter_items
		"scan":
			return unlock_id in scans
	return false
