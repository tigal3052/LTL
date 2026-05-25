# 계약:
# - 책임: promoted replay fixture를 formal headless runtime에 재생하는 integration contract 경계를 제공한다.
# - 입력: fixture spec path 또는 fixture Dictionary, headless runtime constructor, input adapter API.
# - 출력: final public snapshot, replay-visible summary, diagnostics, optional trace를 반환하는 public API.
# - 금지: combat rule 자체를 재정의하거나 scene mutation을 하지 않는다.
#
# 실행: define the replay process class identity.
class_name ReplayProcess
extends RefCounted

# 실행: preload the headless runtime and input adapter used by replay.
const HeadlessMiniRunScript = preload("res://src/process/HeadlessMiniRun.gd")
const CombatInputAdapterScript = preload("res://src/process/CombatInputAdapter.gd")

# 실행: normalize a replay payload, execute each event, and return snapshot summary data.
func run_replay(payload: Dictionary) -> Dictionary:
	var fixture: Dictionary = _normalize_fixture(payload)
	var diagnostics: Array = fixture["diagnostics"]
	var run = HeadlessMiniRunScript.new(fixture["options"])
	var adapter = CombatInputAdapterScript.new(run)
	
	# 만약 payload에 직접 node 정보가 주어져 있다면(prototype-style), 자동으로 전투 페이즈에 진입시킴
	if payload.has("node"):
		run.select_node(0)
		
	var current: Dictionary = run.snapshot()
	var trace: Array = [current.duplicate(true)] if fixture["traceEnabled"] else []
	for event in fixture["inputLog"]:
		current = _apply_event(run, adapter, current, event, diagnostics)
		if fixture["traceEnabled"]:
			trace.append(current.duplicate(true))
	var summary: Dictionary = _build_summary(current, diagnostics)
	if fixture["expectedPhase"] != "" and summary["phase"] != fixture["expectedPhase"]:
		diagnostics.append({"path": "summary.phase", "code": "unexpected_phase", "expected": fixture["expectedPhase"], "actual": summary["phase"]})
		summary["ok"] = false
	return {"snapshot": current, "summary": summary, "diagnostics": diagnostics, "trace": trace}

# 실행: read a replay fixture file and execute it as a replay payload.
func run_replay_file(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {"snapshot": {}, "summary": {"ok": false, "phase": "file_error", "runComplete": false, "failed": true}, "diagnostics": [{"path": "path", "code": "file_open_failed", "value": path}], "trace": []}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not (parsed is Dictionary):
		return {"snapshot": {}, "summary": {"ok": false, "phase": "parse_error", "runComplete": false, "failed": true}, "diagnostics": [{"path": "path", "code": "invalid_json", "value": path}], "trace": []}
	return run_replay(parsed)

# 실행: convert a fixture dictionary into runtime options and ordered replay input.
func _normalize_fixture(payload: Dictionary) -> Dictionary:
	var diagnostics: Array = []
	var options: Dictionary = {"seed": int(payload.get("seed", 1)), "maxStages": maxi(1, int(payload.get("maxStages", 1))), "runCount": maxi(1, int(payload.get("runCount", 1))), "queueCapacity": int(payload.get("queueCapacity", 8)), "nodeTable": payload.get("nodeTable", _build_node_table_from_payload(payload))}
	var trace_enabled: bool = payload.get("trace", false) == true
	if payload.has("node") and not payload.has("nodeTable"):
		options["nodeTable"] = _build_node_table_from_payload(payload)
	var raw_input_log: Variant = payload.get("inputLog", [])
	var input_log: Array = []
	if raw_input_log is Array:
		input_log = raw_input_log
	else:
		diagnostics.append({"path": "inputLog", "code": "type_array"})
	return {"options": options, "inputLog": input_log, "expectedPhase": String(payload.get("expectedPhase", "")), "traceEnabled": trace_enabled, "diagnostics": diagnostics}

# 실행: dispatch one replay event according to the current phase.
func _apply_event(run, adapter, current: Dictionary, event: Dictionary, diagnostics: Array) -> Dictionary:
	if current.get("phase", "") == "node_select":
		if event.has("type") and String(event.get("type", "")) == "select_node":
			return run.select_node(int(event.get("index", 0)))
		if event.has("input") or event.has("target"):
			return run.select_node(int(event.get("index", event.get("target", 0))))
	if current.get("phase", "") == "reward_loot":
		if String(event.get("type", "")) == "claim_rewards" or String(event.get("input", "")) == "claim_rewards":
			return run.claim_rewards()
		if String(event.get("type", "")) == "remove_inventory_artifact":
			return run.remove_inventory_artifact(String(event.get("artifactId", "")))
	if current.get("phase", "") == "combat":
		var normalized: Dictionary = adapter.normalize_input(event, current)
		if not normalized["ok"]:
			diagnostics.append_array(normalized["diagnostics"])
			return current
		var normalized_event: Dictionary = normalized["event"]
		if String(normalized_event.get("type", "")) in ["aim", "fire", "hold_fire_tick", "repair", "resolve"]:
			return run.apply_combat_input(normalized_event)
		diagnostics.append({"path": "event.type", "code": "unsupported_normalized_event", "value": normalized_event})
		return current
	diagnostics.append({"path": "event", "code": "ignored_event_for_phase", "phase": current.get("phase", ""), "value": event})
	return current

# 실행: project the final replay snapshot into a stable summary dictionary.
func _build_summary(current: Dictionary, diagnostics: Array) -> Dictionary:
	var combat_value: Variant = current.get("combat", null)
	var combat: Dictionary = {}
	if combat_value is Dictionary:
		combat = combat_value
	var combat_summary_value: Variant = combat.get("summary", {})
	var combat_summary: Dictionary = {}
	if combat_summary_value is Dictionary:
		combat_summary = combat_summary_value
	var has_combat: bool = combat_value is Dictionary
	return {"ok": diagnostics.is_empty(), "phase": current.get("phase", "unknown"), "runComplete": current.get("runComplete", false), "failed": current.get("failed", false), "pendingRewards": current.get("pendingRewards", []).size(), "stageIndex": current.get("stageIndex", -1), "runIndex": current.get("runIndex", -1), "leviathanId": current.get("leviathanId", ""), "result": null if not has_combat else combat.get("result", null), "shots_fired": 0 if not has_combat else int(combat_summary.get("shots_fired", 0)), "shots_hit_match": 0 if not has_combat else int(combat_summary.get("shots_hit_match", 0)), "shots_hit_mismatch": 0 if not has_combat else int(combat_summary.get("shots_hit_mismatch", 0)), "shots_fired_empty_queue": 0 if not has_combat else int(combat_summary.get("shots_fired_empty_queue", 0))}

# 실행: build a minimal node table from prototype-style fixture payload fields.
func _build_node_table_from_payload(payload: Dictionary) -> Dictionary:
	var node_value: Variant = payload.get("node", {})
	var node: Dictionary = {}
	if node_value is Dictionary:
		node = node_value
	if node.is_empty():
		return {"nodes": [{"id": "normal", "label": "Normal Node", "weakness": ["red"], "pickWeight": 1, "shieldMul": 1, "healthMul": 1, "alwaysOffer": true}]}
	var weakness_value: Variant = node.get("weakness", ["red"])
	var weakness: Array = ["red"]
	if weakness_value is Array:
		weakness = weakness_value.duplicate(true)
	return {"nodes": [{"id": "normal", "label": String(node.get("label", "Normal Node")), "weakness": weakness.duplicate(true), "pickWeight": 1, "shieldMul": 1, "healthMul": 1, "alwaysOffer": true, "combat": {"shield": float(node.get("shield", 1.0)), "health": float(node.get("health", 1.0)), "timeLimitTicks": int(payload.get("timeLimitTicks", 2400)), "weakness": weakness.duplicate(true)}}]}
