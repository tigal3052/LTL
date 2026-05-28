# 계약:
# - 책임: node_select scene snapshot을 RichTextLabel 표시용 text contract로 변환한다.
# - 입력: scene Dictionary, selected node index.
# - 출력: { text, selectedIndex } dictionary.
# - 금지: UI node 접근, phase 전환, gameplay 상태 변경.
#
# 실행: define the NodeSelectReadModel class.
class_name NodeSelectReadModel
extends RefCounted

const TextCatalogScript = preload("res://src/ui/TextCatalog.gd")

# 실행: project node selection candidates into BBCode text.
static func project(scene: Dictionary, selected_index: int = 0) -> Dictionary:
	var lines: PackedStringArray = []
	var candidates: Array = scene.get("nodeSelect", {}).get("candidates", [])
	for idx in range(candidates.size()):
		var candidate: Dictionary = candidates[idx]
		var text := _candidate_text(candidate)
		if idx == selected_index:
			text = "[b][color=#ffd766]%s[/color][/b]" % TextCatalogScript.t("node.selected", [text])
		else:
			text = "> %s" % text
		lines.append("[url=%d]%s[/url]" % [idx, text])
	var body := TextCatalogScript.t("node.select.empty")
	if not lines.is_empty():
		body = TextCatalogScript.t("node.select.header", ["\n".join(lines)])
	return {"text": body, "selectedIndex": selected_index}

# 실행: format one candidate with only meaningful route facts.
static func _candidate_text(candidate: Dictionary) -> String:
	var label := TextCatalogScript.display_name(str(candidate.get("label", candidate.get("id", "?"))))
	var weakness := _weakness_label(candidate)
	var risk := TextCatalogScript.enum_label("risk", str(candidate.get("riskTier", "safe")))
	var text := TextCatalogScript.t("node.card.base", [label, weakness, risk])
	var reward := str(candidate.get("rewardBias", "baseline"))
	if not reward.is_empty() and reward != "baseline":
		text += TextCatalogScript.t("node.card.reward", [TextCatalogScript.enum_label("reward_bias", reward)])
	var hint := str(candidate.get("recommendedBuildHint", ""))
	if not hint.is_empty():
		text += TextCatalogScript.t("node.card.hint", [TextCatalogScript.hint_label(hint)])
	return text

# 실행: localize weakness labels from candidate fields.
static func _weakness_label(candidate: Dictionary) -> String:
	var weakness_label := str(candidate.get("weaknessLabel", ""))
	if weakness_label.is_empty():
		var weaknesses: Array = candidate.get("weakness", [])
		if weaknesses.is_empty():
			return TextCatalogScript.t("node.no_weakness")
		weakness_label = ",".join(weaknesses)
	var parts := weakness_label.split(",", false)
	var localized: Array[String] = []
	for part in parts:
		var key := part.strip_edges().to_lower()
		localized.append(TextCatalogScript.t("color.%s" % key) if key in ["red", "blue", "purple", "green"] else key)
	return ", ".join(localized) if not localized.is_empty() else TextCatalogScript.t("node.no_weakness")
