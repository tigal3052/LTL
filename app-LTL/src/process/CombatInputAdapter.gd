# 계약:
# - 책임: replay 또는 future scene 입력을 formal combat event contract로 번역하는 adapter 경계를 제공한다.
# - 입력: raw input Dictionary, current combat snapshot metadata, optional validation context.
# - 출력: normalized combat event, guard result, unsupported-input diagnostics를 반환하는 public API.
# - 금지: damage 계산, reward 생성, inventory mutation, scene node 접근
#
# 실행: define the combat input adapter class identity.
class_name CombatInputAdapter
extends RefCounted

# 실행: store the optional headless run target used by convenience methods.
var run

# 실행: initialize the adapter with an optional target run.
func _init(target_run = null) -> void:
	run = target_run

# 실행: return the target run snapshot or an empty snapshot when no run is attached.
func snapshot() -> Dictionary:
	return {} if run == null else run.snapshot()

# 실행: normalize a raw replay or scene input into a formal combat event.
func normalize_input(raw_input: Dictionary, current_snapshot: Dictionary = {}) -> Dictionary:
	var diagnostics: Array = []
	var action_type := _resolve_action_type(raw_input)
	if action_type.is_empty():
		diagnostics.append({"path": "type", "code": "unsupported_input", "value": raw_input})
		return {"ok": false, "event": {"type": "noop"}, "diagnostics": diagnostics}
	if action_type in ["repair", "claim_rewards", "select_node"]:
		return {"ok": true, "event": {"type": action_type, "index": int(raw_input.get("index", raw_input.get("target", 0)))}, "diagnostics": diagnostics}
	if action_type == "resolve":
		return {"ok": true, "event": raw_input.duplicate(true), "diagnostics": diagnostics}
	var target_color: Variant = raw_input.get("targetColor", null)
	var target_cell_id: Variant = raw_input.get("targetCellId", null)
	if current_snapshot.has("combat") and current_snapshot["combat"] != null:
		var combat: Dictionary = current_snapshot["combat"]
		if target_color == null:
			target_color = _infer_target_color(combat, int(raw_input.get("target", 0)))
		if target_cell_id == null:
			target_cell_id = _infer_target_cell_id(combat, int(raw_input.get("target", 0)))
	else:
		diagnostics.append({"path": "combat", "code": "missing_combat_snapshot"})
	if action_type in ["aim", "fire", "hold_fire_tick"] and target_color == null:
		diagnostics.append({"path": "targetColor", "code": "required"})
	if action_type in ["aim", "fire", "hold_fire_tick"] and target_cell_id == null:
		diagnostics.append({"path": "targetCellId", "code": "required"})
	if not diagnostics.is_empty():
		return {"ok": false, "event": {"type": "noop"}, "diagnostics": diagnostics}
	return {"ok": true, "event": {"type": action_type, "targetCellId": target_cell_id, "targetColor": target_color}, "diagnostics": diagnostics}

# 실행: select a node through the attached headless run.
func select_node(index: int) -> Dictionary:
	return {} if run == null else run.select_node(index)

# 실행: submit an aim event through the attached headless run.
func aim_at(cell_id: String, target_color: String) -> Dictionary:
	return {} if run == null else run.apply_combat_input({"type": "aim", "targetCellId": cell_id, "targetColor": target_color})

# 실행: submit a fire event through the attached headless run.
func fire(cell_id: String, target_color: String) -> Dictionary:
	return {} if run == null else run.apply_combat_input({"type": "fire", "targetCellId": cell_id, "targetColor": target_color})

# 실행: repeat hold-fire ticks until the run leaves combat or repeat count is exhausted.
func hold_fire(cell_id: String, target_color: String, repeat: int = 1) -> Dictionary:
	if run == null:
		return {}
	var current: Dictionary = run.snapshot()
	for _index in range(maxi(1, repeat)):
		if current.get("phase", "") != "combat":
			break
		current = run.apply_combat_input({"type": "hold_fire_tick", "targetCellId": cell_id, "targetColor": target_color})
	return current

# 실행: submit a repair intent through the attached headless run.
func request_repair() -> Dictionary:
	return {} if run == null else run.apply_combat_input({"type": "repair"})

# 실행: claim rewards through the attached headless run.
func claim_rewards() -> Dictionary:
	return {} if run == null else run.claim_rewards()

# 실행: map raw input vocabulary onto formal action types.
func _resolve_action_type(raw_input: Dictionary) -> String:
	var explicit_type := String(raw_input.get("type", ""))
	if not explicit_type.is_empty():
		return explicit_type
	match String(raw_input.get("input", "")):
		"click":
			return "fire"
		"aim":
			return "aim"
		"repair":
			return "repair"
		"claim_rewards":
			return "claim_rewards"
		_:
			return ""

# 실행: infer target color from combat weakness markers or current aim state.
func _infer_target_color(combat: Dictionary, target_index: int) -> Variant:
	var battlefield: Dictionary = combat.get("battlefield", {})
	var markers: Array = battlefield.get("weaknessMarkers", [])
	if target_index >= 0 and target_index < markers.size():
		return markers[target_index].get("color", null)
	if not markers.is_empty():
		return markers[0].get("color", null)
	var aim: Dictionary = combat.get("aim", {})
	return aim.get("targetColor", null)

# 실행: infer target cell id from combat weakness markers or current aim state.
func _infer_target_cell_id(combat: Dictionary, target_index: int) -> Variant:
	var battlefield: Dictionary = combat.get("battlefield", {})
	var markers: Array = battlefield.get("weaknessMarkers", [])
	if target_index >= 0 and target_index < markers.size():
		return markers[target_index].get("cellId", null)
	if not markers.is_empty():
		return markers[0].get("cellId", null)
	var aim: Dictionary = combat.get("aim", {})
	return aim.get("cellId", null)
