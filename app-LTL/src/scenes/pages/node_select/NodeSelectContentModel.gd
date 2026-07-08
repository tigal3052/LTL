# 怨꾩빟:
# - Responsibility: project node-select runtime state into route copy, candidate visual ids, and phase gates.
# - Input: page state dictionaries, candidate dictionaries, and projected route-history entries.
# - Output: localized labels, palette dictionaries, icon ids, route history, and stage/boss flags.
# - Prohibited: creating UI nodes, mutating controls, drawing textures, or emitting page signals.
#
# ?ㅽ뻾: define reusable node-select content projection helpers.
class_name NodeSelectContentModel
extends RefCounted

const TextCatalogScript = preload("res://src/ui/TextCatalog.gd")
const NodeSelectVisualFactoryScript = preload("res://src/scenes/pages/node_select/NodeSelectVisualFactory.gd")

# ?ㅽ뻾: map a node candidate into the route palette used by visuals.
static func candidate_palette(candidate: Dictionary) -> Dictionary:
	var risk := str(candidate.get("riskTier", "safe"))
	var node_type := str(candidate.get("nodeType", "normal"))
	if node_type == "boss" or risk == "boss":
		return NodeSelectVisualFactoryScript.tone_palette("boss")
	if risk == "support" or node_type == "repair_event" or risk == "event" or node_type == "mysterious_crevice":
		return NodeSelectVisualFactoryScript.tone_palette("brown")
	if risk in ["danger", "hard"] or node_type == "mixed_weakness" or node_type.find("red") >= 0:
		return NodeSelectVisualFactoryScript.tone_palette("red")
	return NodeSelectVisualFactoryScript.tone_palette("stage")

# ?ㅽ뻾: map a node candidate into the glyph renderer icon id.
static func candidate_icon_kind(candidate: Dictionary) -> String:
	var node_type := str(candidate.get("nodeType", "normal"))
	var risk := str(candidate.get("riskTier", "safe"))
	if node_type == "repair_event" or risk == "support":
		return "repair"
	if node_type == "boss" or risk == "boss":
		return "boss"
	if node_type == "mixed_weakness":
		return "reef"
	if node_type == "mysterious_crevice" or risk == "unknown":
		return "unknown"
	if risk in ["danger", "hard"]:
		return "danger"
	if node_type.find("red") >= 0:
		return "harpoon"
	if node_type.find("blue") >= 0 or bool(candidate.get("isEvent", false)):
		return "reef"
	return "normal"

static func candidate_glyph(candidate: Dictionary) -> String:
	var node_type := str(candidate.get("nodeType", "normal"))
	var risk := str(candidate.get("riskTier", "safe"))
	if node_type == "repair_event" or risk == "support":
		return "+"
	if bool(candidate.get("isEvent", false)) or risk == "event":
		return "?"
	if node_type == "mixed_weakness":
		return "="
	if risk in ["danger", "hard"]:
		return "!"
	if node_type.find("blue") >= 0:
		return "~"
	if node_type.find("red") >= 0:
		return "^"
	return "o"

static func candidate_glyph_color(candidate: Dictionary) -> Color:
	return candidate_palette(candidate).get("glyph", Color(0.96, 0.91, 0.82, 1.0))

# ?ㅽ뻾: build the localized candidate description copy.
static func candidate_description(candidate: Dictionary) -> String:
	var risk := TextCatalogScript.enum_label("risk", str(candidate.get("riskTier", "safe")))
	var reward := TextCatalogScript.enum_label("reward_bias", str(candidate.get("rewardBias", "baseline")))
	var hint := TextCatalogScript.hint_label(str(candidate.get("recommendedBuildHint", "")))
	return TextCatalogScript.t("node_runtime.candidate_description", [risk, weakness_text(candidate), reward, hint])

static func candidate_obstruction_text(candidate: Dictionary) -> String:
	var explicit := str(candidate.get("obstructionLabel", candidate.get("obstruction", ""))).strip_edges()
	if not explicit.is_empty():
		return explicit
	var node_type := str(candidate.get("nodeType", "normal"))
	var risk := str(candidate.get("riskTier", "safe"))
	var reward_bias := str(candidate.get("rewardBias", "baseline"))
	if risk == "boss" or node_type == "boss":
		return "거대 코어 외피가 주기적으로 굳어 채굴 타이밍을 제한합니다."
	if risk in ["danger", "hard"]:
		return "불안정한 균열과 역류 압력이 장비 내구도를 빠르게 소모합니다."
	if risk == "unknown" or node_type == "mysterious_crevice" or reward_bias == "mystery":
		return "내부 지형 정보가 불완전해 첫 진입 전까지 위협 패턴을 확정하기 어렵습니다."
	if risk == "support" or node_type == "repair_event":
		return "직접 위협은 낮지만 보급 동선이 좁아 장비 정비 선택지가 제한됩니다."
	if node_type == "mixed_weakness" or reward_bias == "multi_energy":
		return "복수 속성의 단단한 판층이 번갈아 노출되어 단일 속성 빌드의 효율이 떨어집니다."
	return "표층은 안정적이지만 석회질 판이 드릴 진행 속도를 늦춥니다."

static func candidate_lore_text(candidate: Dictionary) -> String:
	var explicit := str(candidate.get("lore", candidate.get("flavor", ""))).strip_edges()
	if not explicit.is_empty():
		return explicit
	var node_type := str(candidate.get("nodeType", "normal"))
	var risk := str(candidate.get("riskTier", "safe"))
	if risk == "boss" or node_type == "boss":
		return "레비아탄의 등갑 심부와 맞닿은 핵심 절리입니다. 모든 탐사 기록은 이곳의 반응을 기준으로 재정렬됩니다."
	if node_type == "repair_event" or risk == "support":
		return "오래된 탐사 흔적과 비교적 안정된 숨구멍이 남아 있어 장비를 재정비하기 좋은 구간입니다."
	if risk == "unknown" or node_type == "mysterious_crevice":
		return "지도에 없는 틈새가 갑자기 열렸습니다. 내부의 공명은 보상과 위험을 동시에 암시합니다."
	if risk in ["danger", "hard"]:
		return "등갑 아래의 열과 압력이 뒤틀린 구간입니다. 높은 보상은 대부분 이런 불안정한 판층 사이에 묻혀 있습니다."
	return "초입 표식과 지형 흔적이 비교적 선명한 표층 구간입니다. 원정대가 안전하게 첫 채굴선을 잡기 좋습니다."

static func candidate_panel_body(candidate: Dictionary) -> String:
	return "약점\n%s\n\n방해요소\n%s\n\n노드 설명\n%s" % [weakness_text(candidate), candidate_obstruction_text(candidate), candidate_lore_text(candidate)]

# ?ㅽ뻾: build compact hover tooltip copy for a candidate.
static func candidate_tooltip(candidate: Dictionary) -> String:
	var label := TextCatalogScript.display_name(str(candidate.get("label", candidate.get("id", "?"))))
	var risk := TextCatalogScript.enum_label("risk", str(candidate.get("riskTier", "safe")))
	var reward := TextCatalogScript.enum_label("reward_bias", str(candidate.get("rewardBias", "baseline")))
	return "%s\n%s | %s" % [label, risk, reward]

# ?ㅽ뻾: resolve the selected candidate index from page state and candidate count.
static func selected_candidate_index(state: Dictionary, candidate_count: int) -> int:
	if candidate_count <= 0:
		return -1
	var selected := int(state.get("selectedNodeIndex", -1))
	if selected < 0 or selected >= candidate_count:
		return -1
	return selected

# ?ㅽ뻾: resolve candidate arrays from either nested node-select state or direct page state.
static func candidates(state: Dictionary) -> Array:
	var node_state: Variant = node_select_state(state)
	if node_state is Dictionary:
		var nested: Variant = node_state.get("candidates", [])
		if nested is Array:
			return nested
	var direct: Variant = state.get("candidates", [])
	return direct if direct is Array else []

# ?ㅽ뻾: return the nested node-select state dictionary.
static func node_select_state(state: Dictionary) -> Dictionary:
	var nested: Variant = state.get("nodeSelect", {})
	return nested if nested is Dictionary else {}

# ?ㅽ뻾: resolve route history and synthesize the fixed-entry fallback after stage one.
static func route_history(state: Dictionary, stage_index_value: int) -> Array:
	var node_state := node_select_state(state)
	var nested: Variant = node_state.get("routeHistory", state.get("routeHistory", []))
	var history: Array = nested.duplicate(true) if nested is Array else []
	if history.is_empty() and stage_index_value > 0:
		history.append({
			"stageIndex": 0,
			"routeSlotIndex": 0,
			"id": "fixed_entry",
			"label": TextCatalogScript.t("node_runtime.fixed_entry.name"),
			"nodeType": "normal",
			"riskTier": "safe",
			"rewardBias": "baseline",
			"recommendedBuildHint": TextCatalogScript.t("node_runtime.fixed_entry.body"),
			"weakness": []
		})
	return history

static func stage_index(state: Dictionary) -> int:
	return int(state.get("stageIndex", 0))

static func stage_number(state: Dictionary) -> int:
	return stage_index(state) + 1

static func max_stages(state: Dictionary) -> int:
	return maxi(1, int(state.get("maxStages", 1)))

static func is_fixed_stage(state: Dictionary) -> bool:
	return stage_index(state) <= 0

# ?ㅽ뻾: resolve whether the current node-select state is a boss stage.
static func is_boss_stage(state: Dictionary) -> bool:
	var node_state := node_select_state(state)
	if bool(node_state.get("isBossStage", false)):
		return true
	return stage_index(state) >= max_stages(state) - 1

static func selected_leviathan(state: Dictionary) -> Dictionary:
	return state.get("selectedLeviathan", {})

static func leviathan_name(leviathan: Dictionary) -> String:
	return TextCatalogScript.display_name(str(leviathan.get("name", TextCatalogScript.t("node_runtime.leviathan_default"))))

static func board_title(state: Dictionary) -> String:
	if is_fixed_stage(state):
		return TextCatalogScript.t("node_runtime.board_title.fixed")
	if is_boss_stage(state):
		return TextCatalogScript.t("node_runtime.boss.name")
	return TextCatalogScript.t("node_runtime.board_title.branch")

static func board_hint(state: Dictionary) -> String:
	if is_fixed_stage(state) or is_boss_stage(state):
		return TextCatalogScript.t("node_runtime.board_hint.fixed", [stage_number(state), max_stages(state)])
	return TextCatalogScript.t("node_runtime.board_hint.branch")

# ?ㅽ뻾: localize candidate weakness labels from raw color ids or preformatted labels.
static func weakness_text(candidate: Dictionary) -> String:
	var weakness_label := str(candidate.get("weaknessLabel", ""))
	if weakness_label.is_empty():
		var weakness: Array = candidate.get("weakness", [])
		if weakness.is_empty():
			return TextCatalogScript.t("node.no_weakness")
		weakness_label = ",".join(weakness)
	var parts := weakness_label.split(",", false)
	var localized: Array[String] = []
	for part in parts:
		var value := part.strip_edges().to_lower()
		if value.is_empty():
			continue
		if value in ["red", "blue", "purple", "green"]:
			localized.append(TextCatalogScript.t("color.%s" % value))
		else:
			localized.append(part.strip_edges())
	return ", ".join(localized) if not localized.is_empty() else TextCatalogScript.t("node.no_weakness")

static func history_entry_name(entry: Dictionary) -> String:
	if int(entry.get("stageIndex", -1)) == 0:
		return TextCatalogScript.t("node_runtime.fixed_entry.name")
	return TextCatalogScript.display_name(str(entry.get("label", entry.get("id", "?"))))

static func history_entry_body(entry: Dictionary) -> String:
	if int(entry.get("stageIndex", -1)) == 0:
		return TextCatalogScript.t("node_runtime.fixed_entry.body")
	return candidate_panel_body(entry)

static func history_entry_icon_kind(entry: Dictionary) -> String:
	if int(entry.get("stageIndex", -1)) == 0:
		return "start"
	return candidate_icon_kind(entry)
