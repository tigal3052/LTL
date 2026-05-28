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
		var candidate = candidates[idx]
		var label = TextCatalogScript.display_name(str(candidate.get("label", candidate.get("id", "?"))))
		var weakness = str(candidate.get("weaknessLabel", ""))
		var risk = str(candidate.get("riskTier", "safe"))
		var reward = str(candidate.get("rewardBias", "baseline"))
		var hint = str(candidate.get("recommendedBuildHint", ""))
		var text = TextCatalogScript.t("node.card", [label, weakness, risk, reward])
		if not hint.is_empty():
			text += "  힌트: %s" % hint
		if idx == selected_index:
			text = "[b][color=#ffd766]%s[/color][/b]" % TextCatalogScript.t("node.selected", [text])
		else:
			text = "> %s" % text
		lines.append("[url=%d]%s[/url]" % [idx, text])
	var body := TextCatalogScript.t("node.select.empty")
	if not lines.is_empty():
		body = TextCatalogScript.t("node.select.header", ["\n".join(lines)])
	return {"text": body, "selectedIndex": selected_index}
