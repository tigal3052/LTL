# 계약:
# - 책임: reward dictionaries, held state, and inspection state를 reward-board projection dictionaries로 변환한다.
# - 입력: pending reward arrays plus held reward, held artifact, and inspected selection context.
# - 출력: reward tray card data, discard/claim copy, and fixed inspector projection data for the reward board.
# - 금지: UI node 직접 접근, inventory mutation, reward claiming, runtime phase 변경.
#
# 실행: define the RewardReadModel class.
class_name RewardReadModel
extends RefCounted

const TextCatalogScript = preload("res://src/ui/TextCatalog.gd")
const TooltipReadModelScript = preload("res://src/ui/read_models/TooltipReadModel.gd")
const CreateArtifactFromRewardScript = preload("res://src/vocabulary/reward/CreateArtifactFromReward.gd")
const ArtifactCodexArtResolverScript = preload("res://src/ui/ArtifactCodexArtResolver.gd")

 # 실행: project localized summary data for one reward card outside the tray workspace.
static func project(reward: Dictionary) -> Dictionary:
	return {
		"rewardId": reward.get("rewardId", ""),
		"kind": TextCatalogScript.reward_name(reward),
		"rarity": reward.get("rarity", "common"),
		"qty": int(reward.get("qty", 1)),
		"presentation": {
			"description": TextCatalogScript.reward_description(reward),
			"badge": reward.get("presentation", {}).get("badge", ""),
			"icon": reward.get("presentation", {}).get("icon", "")
		},
		"nextCombatModifierPreview": reward.get("next_combat_modifier_preview", {}).duplicate(true),
		"tags": reward.get("tags", []).duplicate(true)
	}

 # 실행: project the live reward tray, discard state, and inspector payload for the reward board.
static func project_tray(pending_rewards: Array, held_reward_index: int = -1, held_artifact: Variant = null, held_from_rewards: bool = false, inspected_reward_index: int = -1, inspected_artifact: Variant = null) -> Dictionary:
	var cards: Array = []
	var lines: PackedStringArray = []
	for idx in range(pending_rewards.size()):
		var reward: Dictionary = pending_rewards[idx]
		var presentation: Dictionary = reward.get("presentation", {})
		var badge = presentation.get("badge", "reward")
		var holding = TextCatalogScript.t("reward.holding") if held_reward_index == idx else ""
		var selected := idx == inspected_reward_index or idx == held_reward_index
		cards.append(_project_card(reward, idx, selected))
		lines.append("> [url=%d]%s x%d (%s)[/url] [color=#e5c07b][%s][/color]%s" % [idx, TextCatalogScript.reward_name(reward), int(reward.get("qty", 0)), str(reward.get("rarity", "common")).to_upper(), badge, holding])
	if pending_rewards.is_empty():
		lines.append(TextCatalogScript.t("reward.empty"))
	var discard_text := TextCatalogScript.t("discard.idle")
	var discard_active := false
	if held_artifact != null:
		discard_active = true
		if held_from_rewards and held_reward_index >= 0 and held_reward_index < pending_rewards.size():
			discard_text = TextCatalogScript.t("discard.active", [TextCatalogScript.reward_name(pending_rewards[held_reward_index])])
		else:
			discard_text = TextCatalogScript.t("discard.active", [TextCatalogScript.display_name(str(held_artifact.name))])
	var inspector := _empty_inspector_model()
	if inspected_artifact != null:
		inspector = _project_artifact_inspector(inspected_artifact)
	elif inspected_reward_index >= 0 and inspected_reward_index < pending_rewards.size():
		inspector = _project_reward_inspector(pending_rewards[inspected_reward_index])
	elif held_from_rewards and held_reward_index >= 0 and held_reward_index < pending_rewards.size():
		inspector = _project_reward_inspector(pending_rewards[held_reward_index])
	elif held_artifact != null:
		inspector = _project_artifact_inspector(held_artifact)
	var remaining_count := pending_rewards.size()
	var claim_body := TextCatalogScript.t("reward.board.claim_ready")
	if remaining_count > 0:
		claim_body = TextCatalogScript.t("reward.board.claim_pending", [remaining_count])
	return {
		"title": TextCatalogScript.t("panel.rewards"),
		"subtitle": TextCatalogScript.t("reward.board.subtitle"),
		"modePill": TextCatalogScript.t("reward.board.mode_pill"),
		"cloudNote": TextCatalogScript.t("reward.board.cloud_note"),
		"workspaceNote": TextCatalogScript.t("reward.board.workspace_note"),
		"discardCardTitle": TextCatalogScript.t("reward.board.discard_card_title"),
		"claimCardTitle": TextCatalogScript.t("reward.board.claim_card_title"),
		"claimBody": claim_body,
		"claimButtonText": TextCatalogScript.t("action.claim_rewards"),
		"cards": cards,
		"remainingCount": remaining_count,
		"discardText": discard_text,
		"discardActive": discard_active,
		"inspector": inspector,
		"text": "\n".join(lines)
	}

static func _project_card(reward: Dictionary, index: int, selected: bool) -> Dictionary:
	var tooltip_data: Dictionary = TooltipReadModelScript.project(reward)
	var artifact_result: Dictionary = CreateArtifactFromRewardScript.create(reward)
	var artifact = artifact_result.get("artifact", null)
	var shape_matrix := _normalized_shape(artifact.shape if artifact != null else reward.get("payload", {}).get("shape", [[1]]))
	var occupied_cells := _shape_cell_count(shape_matrix)
	return {
		"index": index,
		"name": str(tooltip_data.get("name", "")),
		"rarity": str(tooltip_data.get("grade", "common")).to_lower(),
		"qty": int(reward.get("qty", 1)),
		"badge": str(reward.get("presentation", {}).get("badge", "")).strip_edges(),
		"itemType": str(tooltip_data.get("itemType", "drill")).to_lower(),
		"energyType": str(tooltip_data.get("energyType", "")).to_lower(),
		"energyLabel": "" if str(tooltip_data.get("energyType", "")).is_empty() else TextCatalogScript.color_label(str(tooltip_data.get("energyType", "")).to_lower()),
		"description": TextCatalogScript.reward_description(reward),
		"selected": selected,
		"shapeMatrix": shape_matrix,
		"shapeBounds": _shape_bounds(shape_matrix),
		"occupiedCellCount": occupied_cells,
		"footprintText": TextCatalogScript.t("reward.board.footprint_value", [_shape_width(shape_matrix), shape_matrix.size(), occupied_cells]),
		"art": ArtifactCodexArtResolverScript.descriptor_for_reward(reward, "thumb", true)
	}

static func _project_reward_inspector(reward: Dictionary) -> Dictionary:
	var artifact_result: Dictionary = CreateArtifactFromRewardScript.create(reward)
	var artifact = artifact_result.get("artifact", null)
	var tooltip_data: Dictionary = TooltipReadModelScript.project(reward)
	return _project_inspector_model(
		tooltip_data,
		artifact.shape if artifact != null else reward.get("payload", {}).get("shape", [[1]]),
		TextCatalogScript.t("reward.board.inspector.reward_source")
	)

static func _project_artifact_inspector(artifact: Variant) -> Dictionary:
	var tooltip_data: Dictionary = TooltipReadModelScript.project(artifact)
	return _project_inspector_model(
		tooltip_data,
		artifact.shape if artifact != null else [[1]],
		TextCatalogScript.t("reward.board.inspector.backpack_source")
	)

static func _project_inspector_model(tooltip_data: Dictionary, raw_shape: Variant, _source_label: String) -> Dictionary:
	var shape_matrix := _normalized_shape(raw_shape)
	var shape_width := _shape_width(shape_matrix)
	var shape_height := shape_matrix.size()
	var occupied_cells := _shape_cell_count(shape_matrix)
	var effect_schema: Dictionary = tooltip_data.get("effectSchema", {})
	var effect_summary := TextCatalogScript.effect_summary(effect_schema)
	var grade := str(tooltip_data.get("grade", "common")).to_lower()
	var item_type := str(tooltip_data.get("itemType", "drill")).to_lower()
	var energy_type := str(tooltip_data.get("energyType", "")).to_lower()
	var energy_value := TextCatalogScript.t("reward.board.fact.energy.none") if energy_type.is_empty() else TextCatalogScript.color_label(energy_type)
	var summary := str(tooltip_data.get("keyword", "")).strip_edges()
	if summary.is_empty():
		summary = effect_summary.strip_edges()
	if summary.is_empty():
		summary = _primary_stat_line(tooltip_data).strip_edges()
	if energy_value.is_empty():
		energy_value = TextCatalogScript.t("reward.board.fact.energy.none")
	return {
		"empty": false,
		"kicker": TextCatalogScript.t("reward.board.inspector.kicker"),
		"name": str(tooltip_data.get("name", "")),
		"summary": summary,
		"facts": [
			{
				"label": TextCatalogScript.t("reward.board.fact.type"),
				"value": "%s / %s" % [TextCatalogScript.enum_label("rarity", grade), TextCatalogScript.item_label(item_type)]
			},
			{
				"label": TextCatalogScript.t("reward.board.fact.energy"),
				"value": energy_value
			},
			{
				"label": TextCatalogScript.t("reward.board.fact.effect"),
				"value": _primary_stat_line(tooltip_data),
				"layoutColumns": 2
			}
		],
		"shapeTitle": TextCatalogScript.t("reward.board.shape_title"),
		"shapeFootprintText": TextCatalogScript.t("reward.board.footprint_value", [shape_width, shape_height, occupied_cells]),
		"shapeCellCountText": TextCatalogScript.t("reward.board.shape_cells", [occupied_cells]),
		"shapeMatrix": shape_matrix,
		"shapeItemType": item_type,
		"shapeEnergyType": energy_type
	}

static func _empty_inspector_model() -> Dictionary:
	return {
		"empty": true,
		"kicker": TextCatalogScript.t("reward.board.inspector.kicker"),
		"name": "",
		"summary": TextCatalogScript.t("reward.board.inspector.empty"),
		"facts": [
			{
				"label": TextCatalogScript.t("reward.board.fact.type"),
				"value": ""
			},
			{
				"label": TextCatalogScript.t("reward.board.fact.energy"),
				"value": ""
			},
			{
				"label": TextCatalogScript.t("reward.board.fact.effect"),
				"value": "",
				"layoutColumns": 2
			}
		],
		"shapeTitle": TextCatalogScript.t("reward.board.shape_title"),
		"shapeFootprintText": "",
		"shapeCellCountText": "",
		"shapeMatrix": [
			[0, 0, 0, 0],
			[0, 0, 0, 0]
		],
		"shapeItemType": "",
		"shapeEnergyType": ""
	}

static func _primary_stat_line(tooltip_data: Dictionary) -> String:
	var item_type := str(tooltip_data.get("itemType", "drill")).to_lower()
	if item_type == "drill":
		return "%s %d T / %s %.1f" % [
			TextCatalogScript.t("tooltip.cooldown"),
			int(tooltip_data.get("baseCooldownTicks", 0)),
			TextCatalogScript.t("tooltip.damage"),
			float(tooltip_data.get("damage", 0.0))
		]
	if item_type == "beacon":
		return "%s %+d T / %s %+0.1f" % [
			TextCatalogScript.t("tooltip.cooldown"),
			int(tooltip_data.get("beaconCooldownMod", 0)),
			TextCatalogScript.t("tooltip.damage"),
			float(tooltip_data.get("beaconDamageMod", 0.0))
		]
	var effect_summary := TextCatalogScript.effect_summary(tooltip_data.get("effectSchema", {}))
	if not effect_summary.is_empty():
		return effect_summary
	return TextCatalogScript.item_label(item_type)

static func _normalized_shape(raw_shape: Variant) -> Array:
	if not (raw_shape is Array) or raw_shape.is_empty():
		return [[1]]
	var width := 0
	for row in raw_shape:
		if row is Array:
			width = maxi(width, row.size())
	var normalized: Array = []
	for row in raw_shape:
		var next_row: Array = []
		if row is Array:
			next_row = row.duplicate(true)
		while next_row.size() < width:
			next_row.append(0)
		normalized.append(next_row)
	return normalized if not normalized.is_empty() else [[1]]

static func _shape_bounds(shape_matrix: Array) -> Dictionary:
	return {"width": _shape_width(shape_matrix), "height": shape_matrix.size()}

static func _shape_width(shape_matrix: Array) -> int:
	var width := 0
	for row in shape_matrix:
		if row is Array:
			width = maxi(width, row.size())
	return width

static func _shape_cell_count(shape_matrix: Array) -> int:
	var count := 0
	for row in shape_matrix:
		if not (row is Array):
			continue
		for cell in row:
			if int(cell) != 0:
				count += 1
	return count
