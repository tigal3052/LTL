# 怨꾩빟:
# - Responsibility: convert node-map UI intent into formal node_select event literals.
# - Input: selected candidate index or disabled selection state.
# - Output: event Dictionary for PhaseReducers or an invalid selection event.
# - Prohibited: HeadlessMiniRun mutation, candidate generation, SceneTree access.
#
# ?ㅽ뻾: define the NodeInputAdapter class identity.
class_name NodeInputAdapter
extends RefCounted

# ?ㅽ뻾: create a select_node event for non-negative indices.
func choose_node(index: int) -> Dictionary:
	if index < 0:
		return {"type": "invalid_node_selection", "index": index}
	return {"type": "select_node", "index": index}

# ?ㅽ뻾: create a hover event that can be consumed by node-map presentation without changing phase state.
func hover_node(index: int) -> Dictionary:
	if index < 0:
		return {"type": "clear_node_hover", "index": index}
	return {"type": "preview_node", "index": index}
