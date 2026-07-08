# 怨꾩빟:
# - 책임: M8 representative seed batch를 headless vertical-slice runner로 실행하고 telemetry bundle 생성 상태를 집계한다.
# - 입력: seed list, optional runner/export options.
# - 출력: seed별 summary, telemetry manifest, failed seed 목록이 포함된 deterministic batch report.
# - 금지: fixture rule 재구현, UI scene instantiation, 외부 프로세스 실행.
#
# ?ㅽ뻾: define the M8 replay batch runner class identity.
class_name ReplayBatchRunner
extends RefCounted

const VerticalSliceRunnerScript = preload("res://src/process/VerticalSliceRunner.gd")
const TelemetryExportScript = preload("res://src/tools/TelemetryExport.gd")

# ?ㅽ뻾: execute the fixed M8 clear path across representative seeds and package manifest metadata.
func run_m8_seed_batch(options: Dictionary = {}) -> Dictionary:
	var seeds: Array = options.get("seeds", VerticalSliceRunnerScript.DEFAULT_SEEDS).duplicate(true)
	var runner = VerticalSliceRunnerScript.new()
	var exporter = TelemetryExportScript.new()
	var results: Array = []
	var failed_seeds: Array = []
	for index in range(seeds.size()):
		var seed_value := int(seeds[index])
		var result: Dictionary = runner.run_clear({"seed": seed_value})
		var bundle: Dictionary = exporter.build_session_bundle(result, {
			"sessionId": "m8-seed-%d" % seed_value,
			"qaRunIndex": index + 1
		})
		var item := {
			"seed": seed_value,
			"ok": bool(result.get("ok", false)) and bool(bundle.get("ok", false)),
			"summary": result.get("summary", {}).duplicate(true),
			"manifest": bundle.get("manifest", {}).duplicate(true),
			"diagnostics": result.get("diagnostics", []).duplicate(true)
		}
		results.append(item)
		if not bool(item["ok"]):
			failed_seeds.append(seed_value)
	return {
		"ok": failed_seeds.is_empty(),
		"seedCount": seeds.size(),
		"failedSeeds": failed_seeds,
		"results": results
	}
