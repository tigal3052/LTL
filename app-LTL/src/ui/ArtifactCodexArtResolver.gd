# 계약:
# - 책임: 아티팩트 도감에서 사용할 이미지 슬롯 경로와 플레이스홀더 메타데이터를 해석한다.
# - 입력: reward dictionary, slot kind("hero" 또는 "thumb"), 발견 여부.
# - 출력: { path, requestedPath, fallbackChain, placeholderId, state, iconKey, itemType, energyType } descriptor.
# - 금지: 파일 생성/수정, UI 노드 생성, 런타임 상태 변경.
#
# 실행: define the artifact codex art resolver.
class_name ArtifactCodexArtResolver
extends RefCounted

const HERO_ROOT := "res://resources/UI/codex/heroes"
const THUMB_ROOT := "res://resources/UI/codex/thumbs"
const GENERIC_ROOT := "res://resources/UI/codex"
const FALLBACK_TILE := "res://resources/UI/tile/tile_panel_nobg.png"

# 실행: resolve a render descriptor for a reward art slot.
static func descriptor_for_reward(reward: Dictionary, slot: String, discovered: bool) -> Dictionary:
	var payload: Dictionary = reward.get("payload", {})
	var presentation: Dictionary = reward.get("presentation", {})
	var icon_key := str(presentation.get("icon", reward.get("id", ""))).strip_edges()
	var item_type := str(payload.get("item_type", "drill")).to_lower()
	var energy_type := str(payload.get("energy_type", "")).to_lower()
	var requested_path := _requested_path_for(slot, icon_key)
	var fallback_chain := _fallback_chain_for(slot, icon_key, item_type, energy_type)
	var resolved_path := _first_existing_path(fallback_chain)
	return {
		"path": resolved_path,
		"requestedPath": requested_path,
		"fallbackChain": fallback_chain,
		"placeholderId": _placeholder_id_for(slot, discovered, item_type, energy_type),
		"state": "discovered" if discovered else "locked",
		"iconKey": icon_key,
		"itemType": item_type,
		"energyType": energy_type
	}

# 실행: build the requested art path for future final illustrations.
static func _requested_path_for(slot: String, icon_key: String) -> String:
	if icon_key.is_empty():
		return ""
	var root := HERO_ROOT if slot == "hero" else THUMB_ROOT
	return "%s/%s.png" % [root, icon_key]

# 실행: provide a deterministic fallback chain while final art is absent.
static func _fallback_chain_for(slot: String, icon_key: String, item_type: String, energy_type: String) -> Array:
	var chain: Array = []
	var requested := _requested_path_for(slot, icon_key)
	if not requested.is_empty():
		chain.append(requested)
	if not icon_key.is_empty():
		chain.append("%s/%s.png" % [GENERIC_ROOT, icon_key])
	if not energy_type.is_empty():
		chain.append("%s/%s_%s.png" % [GENERIC_ROOT, item_type, energy_type])
	chain.append("%s/%s.png" % [GENERIC_ROOT, item_type])
	chain.append(FALLBACK_TILE)
	return chain

# 실행: choose the first loadable path in the fallback chain.
static func _first_existing_path(paths: Array) -> String:
	for path in paths:
		var normalized := str(path).strip_edges()
		if normalized.is_empty():
			continue
		if ResourceLoader.exists(normalized):
			return normalized
	return ""

# 실행: build a stable placeholder identifier for view-side placeholder rendering.
static func _placeholder_id_for(slot: String, discovered: bool, item_type: String, energy_type: String) -> String:
	var state := "known" if discovered else "locked"
	return "%s_%s_%s_%s" % [slot, state, item_type, energy_type if not energy_type.is_empty() else "neutral"]
