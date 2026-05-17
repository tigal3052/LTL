class_name RunSimulator
extends RefCounted

const EnergyQueueScript = preload("res://prototype/domain/EnergyQueue.gd")
const MiningResolverScript = preload("res://prototype/domain/MiningResolver.gd")
const TelemetryScript = preload("res://prototype/telemetry/Telemetry.gd")

var seed := 1
var time_limit_ticks := 1200
var energy_queue
var resolver
var telemetry
var targets: Array[Dictionary] = []
var durability_loss_count := 0
var repair_required := false
var result := "running"
var tick := 0

func _init(options := {}) -> void:
	seed = options.get("seed", 1)
	time_limit_ticks = options.get("time_limit_ticks", 1200)
	energy_queue = EnergyQueueScript.new(options.get("queue_capacity", 8))
	resolver = MiningResolverScript.new()
	telemetry = TelemetryScript.new({"run_id": "seed-%s" % seed, "seed": seed})
	var node: Dictionary = options.get("node", {"shield": 0.75, "health": 0.0, "weakness": ["red"]})
	for i in range(30):
		targets.append({
			"weakness": node.get("weakness", []).duplicate(),
			"shield": node.get("shield", 3.0),
			"health": node.get("health", 0.0),
			"disabled_until": -1
		})
	for energy in ["red", "blue", "purple", "green"].slice(0, min(4, energy_queue.capacity)):
		energy_queue.push(energy)
	telemetry.sync_queue_stats(energy_queue)

func apply_input(input: Dictionary) -> Dictionary:
	tick = input.get("tick", 0)
	if result != "running" or repair_required or input.get("input", "") != "click":
		return snapshot()
	telemetry.increment("shots_fired")
	var target_index: int = input.get("target", 0)
	if target_index < 0 or target_index >= targets.size():
		telemetry.increment("invalid_target_inputs")
		return snapshot()
	var energy = energy_queue.consume()
	if energy == null:
		durability_loss_count += 1
		telemetry.increment("shots_fired_empty_queue")
		telemetry.increment("durability_loss_count")
		if durability_loss_count >= 3:
			repair_required = true
			telemetry.increment("repair_count")
		evaluate_result(tick)
		return snapshot()
	var resolved: Dictionary = resolver.resolve_shot(energy, targets[target_index], tick)
	targets[target_index] = resolved["target"]
	match resolved["outcome"]:
		"match", "normal":
			telemetry.increment("shots_hit_match")
		"mismatch":
			telemetry.increment("shots_hit_mismatch")
		"invalid_cooldown":
			telemetry.increment("shots_invalid_tile_cooldown")
	telemetry.sync_queue_stats(energy_queue)
	evaluate_result(tick)
	return snapshot()

func evaluate_result(current_tick: int) -> void:
	var cleared := false
	for target in targets:
		if target["shield"] <= 0 and target["health"] <= 0:
			cleared = true
			break
	if cleared:
		result = "clear"
		telemetry.set_value("result", "clear")
		telemetry.set_value("clear_time_sec", current_tick * 0.05)
		return
	if current_tick >= time_limit_ticks:
		result = "time_over"
		telemetry.set_value("result", "time_over")
		telemetry.set_value("fail_time_sec", current_tick * 0.05)

func run(input_log: Array) -> Dictionary:
	for input in input_log:
		apply_input(input)
	telemetry.sync_queue_stats(energy_queue)
	return snapshot()

func snapshot() -> Dictionary:
	return {
		"seed": seed,
		"tick": tick,
		"result": result,
		"repairRequired": repair_required,
		"durabilityLossCount": durability_loss_count,
		"queue": energy_queue.snapshot(),
		"summary": telemetry.summary()
	}
