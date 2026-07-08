# 계약:
# - Responsibility: project reward reveal presentation data and shared rarity/energy visual profiles.
# - Input: reward dictionaries, rarity ids, and artifact payload dictionaries.
# - Output: deterministic presentation dictionaries, timing profile, labels, accents, and reveal profile data.
# - Prohibited: mutating reward state, drawing UI, or advancing ceremony steps.
#
# 실행: define reward reveal presentation projection helpers.
class_name RewardRevealPresentationModel
extends RefCounted

const TextCatalogScript = preload("res://src/ui/TextCatalog.gd")
const EXCAVATION_LID_TEXTURE = preload("res://resources/UI/tile/tile_panel_nobg.png")
const REVEAL_TIMING := {
	"scrimIn": 0.20,
	"countTeaseSmall": 2.80,
	"countTeaseStandard": 3.00,
	"countTeaseJackpot": 3.20,
	"countLockHold": 1.80,
	"revealCommon": 3.00,
	"revealRare": 3.45,
	"revealEpic": 4.10,
	"revealLegendary": 4.80,
	"heroHold": 0.92,
	"fadeOut": 0.34
}

# 실행: expose a stable timing profile for tests and tuning.
static func reveal_timing_profile() -> Dictionary:
	return REVEAL_TIMING.duplicate()

# 실행: project reward ceremony presentation data for tests and runtime consumers.
static func build_presentation_model(reward_list: Array) -> Dictionary:
	var reveal_order := sorted_reward_dictionaries(reward_list)
	var hero_index := hero_reward_index(reward_list)
	var hero_reward: Dictionary = {}
	if hero_index >= 0 and hero_index < reward_list.size() and reward_list[hero_index] is Dictionary:
		hero_reward = reward_list[hero_index]
	var hero_payload := payload_dictionary(hero_reward)
	var hero_rarity := str(hero_reward.get("rarity", "common")).to_lower()
	var reveal_order_names: Array = []
	var reveal_order_rarity_vfx: Array = []
	for reward in reveal_order:
		reveal_order_names.append(reward_display_name(reward))
		reveal_order_rarity_vfx.append(reward_rarity_vfx_tier(reward))
	return {
		"heroIndex": hero_index,
		"heroName": reward_display_name(hero_reward),
		"heroRarity": hero_rarity,
		"heroRarityLabel": reward_rarity_label(hero_rarity),
		"heroItemType": str(hero_payload.get("item_type", "artifact")).to_lower(),
		"heroItemTypeLabel": reward_item_type_label(hero_payload),
		"heroEnergyType": str(hero_payload.get("energy_type", "")),
		"extraCount": maxi(0, reward_list.size() - 1),
		"accent": rarity_accent(hero_rarity),
		"energyAccent": energy_accent(str(hero_payload.get("energy_type", ""))),
		"supportText": "%s  /  %s" % [reward_rarity_label(hero_rarity), reward_item_type_label(hero_payload)],
		"requiresConfirm": true,
		"revealOrderNames": reveal_order_names,
		"revealOrderRarityVfx": reveal_order_rarity_vfx,
		"quantityTeaseBand": quantity_tease_band(reward_list.size()),
		"excavationLid": {
			"theme": "terrain_lid_clone",
			"texturePath": "res://resources/UI/tile/tile_panel_nobg.png",
			"texture": EXCAVATION_LID_TEXTURE
		}
	}

static func hero_reward_index(reward_list: Array) -> int:
	if reward_list.is_empty():
		return -1
	var best_index := 0
	var best_score := -1
	for index in range(reward_list.size()):
		var reward: Dictionary = reward_list[index] if reward_list[index] is Dictionary else {}
		var rarity := str(reward.get("rarity", "common")).to_lower()
		var score := (rarity_rank(rarity) * 100) - index
		if score > best_score:
			best_score = score
			best_index = index
	return best_index

static func payload_dictionary(reward: Dictionary) -> Dictionary:
	var payload = reward.get("payload", {})
	return payload if payload is Dictionary else {}

static func sorted_reward_dictionaries(reward_list: Array) -> Array:
	var sorted_rewards: Array = []
	for reward_entry in reward_list:
		var reward: Dictionary = reward_entry if reward_entry is Dictionary else {}
		var insert_at := sorted_rewards.size()
		for index in range(sorted_rewards.size()):
			var candidate: Dictionary = sorted_rewards[index]
			if rarity_rank(str(reward.get("rarity", "common")).to_lower()) < rarity_rank(str(candidate.get("rarity", "common")).to_lower()):
				insert_at = index
				break
		sorted_rewards.insert(insert_at, reward)
	return sorted_rewards

static func reward_display_name(reward: Dictionary) -> String:
	return TextCatalogScript.reward_name(reward)

static func reward_rarity_label(rarity: String) -> String:
	var label := TextCatalogScript.t("rarity.%s" % rarity)
	return label if not label.begins_with("rarity.") else rarity.capitalize()

static func reward_item_type_label(payload: Dictionary) -> String:
	var item_type := str(payload.get("item_type", "artifact")).to_lower()
	var label := TextCatalogScript.t("item.%s" % item_type)
	return label if not label.begins_with("item.") else item_type.capitalize()

static func reward_rarity_vfx_tier(reward: Dictionary) -> String:
	return str(reward.get("rarity", "common")).to_lower()

static func quantity_tease_band(reward_count: int) -> String:
	if reward_count <= 2:
		return "small"
	if reward_count == 3:
		return "standard"
	return "jackpot"

static func reveal_visual_profile(rarity: String) -> Dictionary:
	match rarity:
		"mythic":
			return {"showBackdropLid": false, "auraStrength": 0.72, "sparkCount": 84, "frameGlowAlpha": 1.00, "borderWidth": 3, "ringCount": 5, "burstStrength": 1.48, "shakeMagnitude": 8.4, "flashAlpha": 1.00, "rarityBurstTier": "mythic", "beamCount": 30, "shockwaveCount": 5, "screenWashAlpha": 0.36, "emberCount": 46}
		"legendary":
			return {"showBackdropLid": false, "auraStrength": 0.58, "sparkCount": 62, "frameGlowAlpha": 0.96, "borderWidth": 3, "ringCount": 4, "burstStrength": 1.22, "shakeMagnitude": 6.4, "flashAlpha": 0.94, "rarityBurstTier": "legendary", "beamCount": 24, "shockwaveCount": 4, "screenWashAlpha": 0.26, "emberCount": 34}
		"epic":
			return {"showBackdropLid": false, "auraStrength": 0.42, "sparkCount": 44, "frameGlowAlpha": 0.82, "borderWidth": 2, "ringCount": 3, "burstStrength": 0.92, "shakeMagnitude": 4.9, "flashAlpha": 0.82, "rarityBurstTier": "epic", "beamCount": 18, "shockwaveCount": 3, "screenWashAlpha": 0.18, "emberCount": 24}
		"rare":
			return {"showBackdropLid": false, "auraStrength": 0.28, "sparkCount": 28, "frameGlowAlpha": 0.68, "borderWidth": 2, "ringCount": 2, "burstStrength": 0.68, "shakeMagnitude": 3.8, "flashAlpha": 0.68, "rarityBurstTier": "rare", "beamCount": 12, "shockwaveCount": 2, "screenWashAlpha": 0.12, "emberCount": 18}
		_:
			return {"showBackdropLid": false, "auraStrength": 0.18, "sparkCount": 18, "frameGlowAlpha": 0.52, "borderWidth": 1, "ringCount": 2, "burstStrength": 0.50, "shakeMagnitude": 2.8, "flashAlpha": 0.62, "rarityBurstTier": "common", "beamCount": 8, "shockwaveCount": 1, "screenWashAlpha": 0.06, "emberCount": 12}

static func reveal_queue_layout_policy() -> Dictionary:
	return {
		"backgroundCardListVisible": false,
		"frontProgressBarVisible": true,
		"progressTextVisible": true,
		"identityVisibleBeforeProgressComplete": false
	}

static func rarity_rank(rarity: String) -> int:
	match rarity:
		"mythic":
			return 5
		"legendary":
			return 4
		"epic":
			return 3
		"rare":
			return 2
		"common":
			return 1
	return 0

static func rarity_accent(rarity: String) -> Color:
	match rarity:
		"mythic":
			return Color(1.00, 0.46, 0.26, 1.0)
		"legendary":
			return Color(0.97, 0.80, 0.36, 1.0)
		"epic":
			return Color(0.78, 0.54, 1.00, 1.0)
		"rare":
			return Color(0.40, 0.74, 1.00, 1.0)
	return Color(0.82, 0.88, 0.94, 1.0)

static func sealed_neutral_accent() -> Color:
	return Color(0.92, 0.96, 1.0, 1.0)

static func sealed_visual_profile() -> Dictionary:
	return {
		"showBackdropLid": false,
		"auraStrength": 0.08,
		"sparkCount": 8,
		"frameGlowAlpha": 0.34,
		"borderWidth": 1,
		"ringCount": 1,
		"burstStrength": 0.0,
		"shakeMagnitude": 2.0,
		"flashAlpha": 0.72,
		"rarityBurstTier": "sealed"
	}

static func energy_accent(energy_type: String) -> Color:
	match energy_type:
		"red":
			return Color(0.95, 0.42, 0.35, 1.0)
		"blue":
			return Color(0.35, 0.72, 0.98, 1.0)
		"green":
			return Color(0.42, 0.82, 0.52, 1.0)
		"purple":
			return Color(0.71, 0.54, 0.96, 1.0)
	return Color(0.90, 0.74, 0.38, 1.0)
