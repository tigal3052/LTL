# 계약:
# - 책임: node_select scene snapshot을 RichTextLabel 표시용 text contract로 변환한다.
# - 입력: scene Dictionary, selected node index.
# - 출력: { text, selectedIndex } dictionary.
# - 금지: UI node 접근, phase 전환, gameplay 상태 변경.
#
# 실행: define the NodeSelectReadModel class.
class_name NodeSelectReadModel
extends RefCounted

# 실행: project node selection candidates into BBCode text.
static func project(scene: Dictionary, selected_index: int = 0) -> Dictionary:
	var lines: PackedStringArray = []
	var candidates: Array = scene.get("nodeSelect", {}).get("candidates", [])
	for idx in range(candidates.size()):
		var candidate = candidates[idx]
		var label = str(candidate.get("label", candidate.get("id", "?")))
		var weakness = str(candidate.get("weaknessLabel", ""))
		var text = "%s  [%s]" % [label, weakness]
		if idx == selected_index:
			text = "[b][color=#ffd766]> %s (selected)[/color][/b]" % text
		else:
			text = "> %s" % text
		lines.append("[url=%d]%s[/url]" % [idx, text])
	var body := "Node Select\nNo candidates available."
	if not lines.is_empty():
		body = "Node Select\nChoose a route, then press Start:\n\n" + "\n".join(lines)
	return {"text": body, "selectedIndex": selected_index}
