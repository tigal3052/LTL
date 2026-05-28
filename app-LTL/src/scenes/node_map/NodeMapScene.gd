# 怨꾩빟:
# - Responsibility: render supplied NodeMapReadModel data into a minimal Control surface.
# - Input: already-projected node-map model dictionary.
# - Output: visible labels and query helpers used by smoke tests.
# - Prohibited: node generation, phase reduction, direct runtime mutation.
#
# ?ㅽ뻾: define the NodeMapScene class identity.
class_name NodeMapScene
extends Control

# ?ㅽ뻾: store render state and generated label nodes.
var _model: Dictionary = {}
var _summary_label: Label = null
var _cards_container: VBoxContainer = null

# ?ㅽ뻾: build child controls when the scene enters the tree.
func _ready() -> void:
	_ensure_children()
	if not _model.is_empty():
		render(_model)

# ?ㅽ뻾: render supplied read-model data without calling domain generators.
func render(model: Dictionary) -> void:
	_model = model.duplicate(true)
	_ensure_children()
	for child in _cards_container.get_children():
		child.queue_free()
	var lines: Array = [str(model.get("stageText", "Node Map"))]
	for card in model.get("cards", []):
		var line := _card_line(card)
		lines.append(line)
		var label := Label.new()
		label.text = line
		_cards_container.add_child(label)
	_summary_label.text = "\n".join(lines)

# ?ㅽ뻾: return the rendered card count for smoke tests.
func card_count() -> int:
	return _cards_container.get_child_count() if _cards_container != null else 0

# ?ㅽ뻾: return the current summary text for smoke tests.
func summary_text() -> String:
	if _summary_label == null:
		return ""
	return _summary_label.text

# ?ㅽ뻾: ensure this scene has stable child controls even when instantiated from script.
func _ensure_children() -> void:
	if _summary_label == null:
		_summary_label = Label.new()
		_summary_label.name = "SummaryLabel"
		add_child(_summary_label)
	if _cards_container == null:
		_cards_container = VBoxContainer.new()
		_cards_container.name = "Cards"
		add_child(_cards_container)

# ?ㅽ뻾: format one node card line for the minimal route panel.
func _card_line(card: Dictionary) -> String:
	var selected_prefix := "* " if bool(card.get("selected", false)) else "- "
	return "%s%s [%s] Risk: %s Reward: %s Hint: %s Final: %d" % [
		selected_prefix,
		str(card.get("label", "")),
		str(card.get("weaknessLabel", "")),
		str(card.get("riskTier", "safe")),
		str(card.get("rewardBias", "baseline")),
		str(card.get("recommendedBuildHint", "")),
		int(card.get("finalStageDistance", 0))
	]
