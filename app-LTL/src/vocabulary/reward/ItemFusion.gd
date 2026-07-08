# 계약:
# - 책임: 동일 reward artifact 두 개를 다음 rarity의 성능 향상 artifact 하나로 합성한다.
# - 입력: InventoryModel, incoming Artifact, and artifact fusion metadata.
# - 출력: `{ ok, code, artifact, consumedArtifactId }` fusion result dictionary.
# - 금지: reward tray mutation, growth payout mutation, UI access, or legendary/mythic input fusion.
#
# 실행: define the reusable duplicate item fusion vocabulary.
class_name ItemFusion
extends RefCounted

const ArtifactScript = preload("res://src/models/Artifact.gd")

const FUSIBLE_RARITIES := ["common", "rare", "epic"]
const NEXT_RARITY := {
	"common": "rare",
	"rare": "epic",
	"epic": "legendary"
}

# 실행: fuse an incoming duplicate reward artifact into the matching inventory artifact when allowed.
static func try_fuse_duplicate(_inventory: InventoryModel, _incoming: Artifact) -> Dictionary:
	return {"ok": false, "code": "requires_exact_overlap", "artifact": null, "consumedArtifactId": ""}

static func try_fuse_exact_overlap(inventory: InventoryModel, incoming: Artifact, x: int, y: int) -> Dictionary:
	if inventory == null:
		return {"ok": false, "code": "missing_inventory", "artifact": null, "consumedArtifactId": ""}
	if incoming == null:
		return {"ok": false, "code": "missing_incoming", "artifact": null, "consumedArtifactId": ""}
	var incoming_rarity := _normalize_rarity(incoming.grade)
	if not FUSIBLE_RARITIES.has(incoming_rarity):
		return {"ok": false, "code": "not_fusible_rarity", "artifact": null, "consumedArtifactId": ""}
	var fusion_key := _fusion_key(incoming)
	if fusion_key.is_empty():
		return {"ok": false, "code": "missing_fusion_key", "artifact": null, "consumedArtifactId": ""}
	var target := _find_exact_overlap_target(inventory, x, y)
	if target == null:
		return {"ok": false, "code": "no_exact_overlap", "artifact": null, "consumedArtifactId": ""}
	if _fusion_key(target) != fusion_key:
		return {"ok": false, "code": "not_duplicate", "artifact": null, "consumedArtifactId": ""}
	var target_rarity := _normalize_rarity(target.grade)
	if target_rarity != incoming_rarity:
		return {"ok": false, "code": "rarity_mismatch", "artifact": null, "consumedArtifactId": ""}
	var origin := Vector2i(target.x, target.y)
	var consumed_id := inventory.artifact_key(target) if inventory.has_method("artifact_key") else str(target.id)
	var fused := fuse_pair(target, incoming)
	inventory.remove_artifact(consumed_id)
	if not inventory.place_artifact(fused, origin.x, origin.y):
		inventory.place_artifact(target, origin.x, origin.y)
		return {"ok": false, "code": "placement_failed", "artifact": null, "consumedArtifactId": ""}
	return {"ok": true, "code": "fused", "artifact": fused, "consumedArtifactId": consumed_id}

# 실행: preview a duplicate fusion result without mutating inventory or artifact placement.
static func preview_duplicate_fusion(existing: Artifact, incoming: Artifact) -> Dictionary:
	if existing == null:
		return {"ok": false, "code": "missing_existing", "before": null, "after": null}
	if incoming == null:
		return {"ok": false, "code": "missing_incoming", "before": existing, "after": null}
	var incoming_rarity := _normalize_rarity(incoming.grade)
	if not FUSIBLE_RARITIES.has(incoming_rarity):
		return {"ok": false, "code": "not_fusible_rarity", "before": existing, "after": null}
	if _fusion_key(existing).is_empty() or _fusion_key(existing) != _fusion_key(incoming):
		return {"ok": false, "code": "not_duplicate", "before": existing, "after": null}
	if _normalize_rarity(existing.grade) != incoming_rarity:
		return {"ok": false, "code": "rarity_mismatch", "before": existing, "after": null}
	return {"ok": true, "code": "preview", "before": existing, "after": fuse_pair(existing, incoming)}

# 실행: build a fused artifact without mutating inventory placement.
static func fuse_pair(base_artifact: Artifact, incoming: Artifact) -> Artifact:
	var base_data := base_artifact.to_dict()
	var base_rarity := _normalize_rarity(base_artifact.grade)
	var next_rarity := str(NEXT_RARITY.get(base_rarity, base_rarity))
	var base_cooldown := _better_cooldown_ticks(int(base_artifact.base_cooldown_ticks), int(incoming.base_cooldown_ticks))
	var native_cooldown := _better_cooldown_ticks(int(base_artifact.native_base_cooldown_ticks), int(incoming.native_base_cooldown_ticks))
	var roll_source := _roll_source_artifact(base_artifact, incoming)
	base_data["id"] = _fused_id(base_artifact, next_rarity)
	base_data["name"] = _fused_name(str(base_artifact.name), next_rarity)
	base_data["grade"] = next_rarity
	base_data["baseCooldownTicks"] = maxi(1, int(floor(float(base_cooldown) * 0.88)))
	base_data["nativeBaseCooldownTicks"] = maxi(1, int(floor(float(native_cooldown) * 0.88)))
	base_data["currentCooldown"] = mini(int(base_artifact.current_cooldown), int(base_data["baseCooldownTicks"]))
	base_data["damage"] = _improved_positive_stat(_better_positive_stat(float(base_artifact.base_damage), float(incoming.base_damage)), 0.22, 0.10)
	base_data["base_damage"] = base_data["damage"]
	base_data["beacon_cooldown_mod"] = _improved_cooldown_mod(_better_cooldown_mod(int(base_artifact.beacon_cooldown_mod), int(incoming.beacon_cooldown_mod)))
	base_data["beacon_damage_mod"] = _improved_positive_stat(_better_positive_stat(float(base_artifact.beacon_damage_mod), float(incoming.beacon_damage_mod)), 0.25, 0.05)
	base_data["effect_schema"] = _improved_effect_schema(base_artifact.effect_schema, incoming.effect_schema)
	base_data["fusionKey"] = _fusion_key(base_artifact)
	base_data["catalogId"] = str(base_artifact.catalog_id)
	base_data["visualId"] = str(base_artifact.visual_id)
	base_data["rollQuality"] = int(roll_source.roll_quality)
	base_data["roll_quality"] = int(roll_source.roll_quality)
	base_data["statRoll"] = roll_source.stat_roll.duplicate(true)
	base_data["stat_roll"] = roll_source.stat_roll.duplicate(true)
	return ArtifactScript.new(base_data)

# 실행: locate the same reward item already placed in the backpack.
static func _find_exact_overlap_target(inventory: InventoryModel, x: int, y: int) -> Artifact:
	for art_id in inventory.artifacts:
		var candidate = inventory.artifacts[art_id]
		if candidate is Artifact and int(candidate.x) == x and int(candidate.y) == y:
			return candidate
	return null

static func _fusion_key(artifact: Artifact) -> String:
	if artifact == null:
		return ""
	if not str(artifact.fusion_key).is_empty():
		return str(artifact.fusion_key)
	if not str(artifact.catalog_id).is_empty():
		return str(artifact.catalog_id)
	if not str(artifact.name).strip_edges().is_empty():
		return str(artifact.name).strip_edges().to_lower()
	return ""

static func _normalize_rarity(rarity: String) -> String:
	return rarity.to_lower()

static func _fused_id(base_artifact: Artifact, next_rarity: String) -> String:
	return "%s_fused_%s" % [str(base_artifact.id), next_rarity]

static func _fused_name(base_name: String, next_rarity: String) -> String:
	var label := next_rarity.capitalize()
	if base_name.to_lower().begins_with(label.to_lower()):
		return base_name
	return "%s %s +" % [label, base_name]

static func _improved_positive_stat(value: float, multiplier: float, flat_bonus: float) -> float:
	if value <= 0.0:
		return 0.0
	return snappedf(value * (1.0 + multiplier) + flat_bonus, 0.01)

static func _better_positive_stat(first: float, second: float) -> float:
	return maxf(first, second)

static func _better_cooldown_ticks(first: int, second: int) -> int:
	return mini(maxi(1, first), maxi(1, second))

static func _better_cooldown_mod(first: int, second: int) -> int:
	return mini(first, second)

static func _roll_source_artifact(base_artifact: Artifact, incoming: Artifact) -> Artifact:
	if int(incoming.roll_quality) > int(base_artifact.roll_quality):
		return incoming
	return base_artifact

static func _improved_cooldown_mod(value: int) -> int:
	if value < 0:
		return int(floor(float(value) * 1.25))
	if value > 0:
		return maxi(0, int(floor(float(value) * 0.80)))
	return 0

static func _improved_effect_schema(base_schema: Dictionary, incoming_schema: Dictionary) -> Dictionary:
	var improved := base_schema.duplicate(true)
	if incoming_schema.has("value") and (typeof(incoming_schema["value"]) == TYPE_INT or typeof(incoming_schema["value"]) == TYPE_FLOAT):
		if not improved.has("value") or absf(float(incoming_schema["value"])) > absf(float(improved.get("value", 0.0))):
			improved["value"] = incoming_schema["value"]
	if improved.has("value") and (typeof(improved["value"]) == TYPE_INT or typeof(improved["value"]) == TYPE_FLOAT):
		improved["value"] = _improved_schema_value(improved["value"])
	improved.erase("fusionTierBonus")
	return improved

static func _improved_schema_value(value: Variant) -> Variant:
	var number := float(value)
	if is_zero_approx(number):
		return value
	var improved := number * 1.25
	if number < 0.0:
		improved = number * 1.25
	if typeof(value) == TYPE_INT:
		return int(ceil(improved)) if improved > 0.0 else int(floor(improved))
	return snappedf(improved, 0.01)
