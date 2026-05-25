# 계약:
# - 책임: M1 formal data contract와 public snapshot contract를 검증하는 진입점을 제공한다.
# - M0 반영: artifact/node/reward/leviathan/progress/root snapshot/phase snapshot 경계를 고정한다.
# - 입력: loader 또는 fixture가 제공하는 raw Dictionary/Array와 public snapshot Dictionary.
# - 출력: contract validity 판정, normalized contract shape, human-readable diagnostics를 생성하는 public API.
# - 금지: SceneTree 접근, Node 생성, replay 실행, scene/UI label 가공, browser presentation field 승격
#
# 실행: define the formal contract class identity.
class_name FormalContracts
extends RefCounted

# 실행: define default tuning values shared by validators and headless runtime.
const DEFAULT_TUNING := {"combat": {"matchDamage": 2, "normalDamage": 1, "mismatchDamage": 0}, "queue": {"capacity": 8, "repairThreshold": 3}, "stageScaling": {"baseShield": 2.4, "baseHealth": 100.0, "baseTimeLimitTicks": 2400}, "reward": {"weaknessBonus": 2}}

# 실행: define root snapshot keys that every public snapshot must expose.
const ROOT_COMMON_KEYS := ["seed", "stageIndex", "maxStages", "leviathanId", "runIndex", "runCount", "inventory", "progress", "phase", "lastNodeLabel", "runComplete", "failed"]

# 실행: define phase-specific keys that prevent snapshot leakage between phases.
const PHASE_REQUIRED_KEYS := {"node_select": ["candidates"], "combat": ["combat"], "reward_loot": ["pendingRewards", "held"], "run_complete": ["pendingRewards"]}

# 실행: validate artifact rows by checking the required artifact fields.
func validate_artifact_table(table: Dictionary) -> Dictionary:
	var errors: Array = []
	var artifacts: Array = _coerce_array(table.get("artifacts", []))
	var required := ["id", "name", "shape", "energyType", "baseCooldownTicks", "synergy", "keyword"]
	for index in range(artifacts.size()):
		_append_missing_fields(errors, "artifacts[%d]" % index, _coerce_dictionary(artifacts[index]), required)
	return _result(errors)

# 실행: load a valid artifact table into a facts dictionary with source metadata.
func load_artifact_table(table: Dictionary, label: String = "inline-artifacts") -> Dictionary:
	var validation := validate_artifact_table(table)
	if not validation["ok"]:
		return validation
	return {"ok": true, "errors": [], "diagnostics": [], "facts": {"artifacts": _duplicate_array(table.get("artifacts", []))}, "source": {"label": label}}

# 실행: validate node rows and require one normal always-offered node.
func validate_node_table(table: Dictionary) -> Dictionary:
	var errors: Array = []
	var nodes: Array = _coerce_array(table.get("nodes", []))
	var has_normal := false
	var required := ["id", "label", "weakness", "pickWeight", "shieldMul", "healthMul"]
	for index in range(nodes.size()):
		var node: Dictionary = _coerce_dictionary(nodes[index])
		if node.get("alwaysOffer", false) == true or node.get("id", "") == "normal":
			has_normal = true
		_append_missing_fields(errors, "nodes[%d]" % index, node, required)
	if not has_normal:
		errors.append({"path": "nodes", "code": "missing_normal_node"})
	return _result(errors)

# 실행: load a valid node table into a facts dictionary with source metadata.
func load_node_table(table: Dictionary, label: String = "inline-nodes") -> Dictionary:
	var validation := validate_node_table(table)
	if not validation["ok"]:
		return validation
	return {"ok": true, "errors": [], "diagnostics": [], "facts": {"nodes": _duplicate_array(table.get("nodes", []))}, "source": {"label": label}}

# 실행: validate reward rows by checking the required reward fields.
func validate_reward_table(table: Dictionary) -> Dictionary:
	var errors: Array = []
	var rewards: Array = _coerce_array(table.get("rewards", []))
	var required := ["rewardId", "kind", "qty"]
	for index in range(rewards.size()):
		_append_missing_fields(errors, "rewards[%d]" % index, _coerce_dictionary(rewards[index]), required)
	return _result(errors)

# 실행: validate leviathan rows by checking run and stage metadata.
func validate_leviathan_table(table: Dictionary) -> Dictionary:
	var errors: Array = []
	var leviathans: Array = _coerce_array(table.get("leviathans", []))
	var required := ["id", "name", "stageCnt", "runCnt"]
	for index in range(leviathans.size()):
		_append_missing_fields(errors, "leviathans[%d]" % index, _coerce_dictionary(leviathans[index]), required)
	return _result(errors)

# 실행: load a valid leviathan table into a facts dictionary with source metadata.
func load_leviathan_table(table: Dictionary, label: String = "inline-leviathans") -> Dictionary:
	var validation := validate_leviathan_table(table)
	if not validation["ok"]:
		return validation
	return {"ok": true, "errors": [], "diagnostics": [], "facts": {"leviathans": _duplicate_array(table.get("leviathans", []))}, "source": {"label": label}}

# 실행: validate progress state and require cleared leviathan identifiers.
func validate_progress_state(progress: Dictionary) -> Dictionary:
	var errors: Array = []
	_append_missing_fields(errors, "", progress, ["clearedLeviathanIds"])
	if progress.has("clearedLeviathanIds") and not (progress["clearedLeviathanIds"] is Array):
		errors.append({"path": "clearedLeviathanIds", "code": "type_array"})
	return _result(errors)

# 실행: load a valid progress state into a facts dictionary with source metadata.
func load_progress_state(progress: Dictionary, label: String = "inline-progress") -> Dictionary:
	var validation := validate_progress_state(progress)
	if not validation["ok"]:
		return validation
	return {"ok": true, "errors": [], "diagnostics": [], "facts": {"clearedLeviathanIds": _duplicate_array(progress.get("clearedLeviathanIds", []))}, "source": {"label": label}}

# 실행: merge raw tuning values over the formal default tuning.
func create_game_tuning(raw_tuning: Dictionary = {}) -> Dictionary:
	var tuning: Dictionary = DEFAULT_TUNING.duplicate(true)
	for group in raw_tuning.keys():
		if tuning.has(group) and tuning[group] is Dictionary and raw_tuning[group] is Dictionary:
			var merged: Dictionary = tuning[group].duplicate(true)
			for key in raw_tuning[group].keys():
				merged[key] = raw_tuning[group][key]
			tuning[group] = merged
		else:
			tuning[group] = clone_value(raw_tuning[group])
	return tuning

# 실행: report which tuning groups are missing from an explicit tuning dictionary.
func validate_game_tuning(raw_tuning: Dictionary = {}) -> Dictionary:
	var missing: Array = []
	for group in ["combat", "queue", "stageScaling", "reward"]:
		if not raw_tuning.has(group):
			missing.append(group)
	return {"ok": missing.is_empty(), "errors": [] if missing.is_empty() else [{"path": "tuning", "code": "missing_groups", "missingGroups": missing}], "diagnostics": [] if missing.is_empty() else [{"path": "tuning", "code": "missing_groups", "missingGroups": missing}], "missingGroups": missing}

# 실행: validate root keys first and phase-specific keys second.
func validate_public_snapshot(snapshot: Dictionary) -> Dictionary:
	var errors: Array = []
	_append_missing_fields(errors, "", snapshot, ROOT_COMMON_KEYS)
	if errors.is_empty():
		errors.append_array(validate_phase_snapshot(String(snapshot.get("phase", "")), snapshot)["errors"])
	return _result(errors, snapshot if errors.is_empty() else {})

# 실행: validate the required fields for the current phase.
func validate_phase_snapshot(phase: String, snapshot: Dictionary) -> Dictionary:
	var errors: Array = []
	if not PHASE_REQUIRED_KEYS.has(phase):
		errors.append({"path": "phase", "code": "unsupported_phase", "value": phase})
		return _result(errors)
	for field in PHASE_REQUIRED_KEYS[phase]:
		if not snapshot.has(field):
			errors.append({"path": field, "code": "required"})
	return _result(errors, snapshot if errors.is_empty() else {})

# 실행: clone arrays and dictionaries so callers cannot mutate private state.
func clone_value(value: Variant) -> Variant:
	if value is Array or value is Dictionary:
		return value.duplicate(true)
	return value

# 실행: return a standard validation result from errors and an optional normalized value.
func _result(errors: Array, normalized: Variant = null) -> Dictionary:
	var normalized_value: Variant = normalized
	if normalized_value == null:
		normalized_value = {}
	return {"ok": errors.is_empty(), "errors": errors, "diagnostics": errors.duplicate(true), "normalized": clone_value(normalized_value)}

# 실행: append required-field diagnostics using a stable field path.
func _append_missing_fields(errors: Array, base_path: String, row: Dictionary, required: Array) -> void:
	for field in required:
		if not row.has(field):
			var path: String = String(field)
			if not base_path.is_empty():
				path = "%s.%s" % [base_path, String(field)]
			errors.append({"path": path, "code": "required"})

# 실행: deep clone every row in an array.
func _duplicate_array(rows: Array) -> Array:
	var result: Array = []
	for row in rows:
		result.append(clone_value(row))
	return result

# 실행: coerce non-array values to an empty array for validator safety.
func _coerce_array(value: Variant) -> Array:
	if value is Array:
		return value
	return []

# 실행: coerce non-dictionary values to an empty dictionary for validator safety.
func _coerce_dictionary(value: Variant) -> Dictionary:
	if value is Dictionary:
		return value
	return {}
