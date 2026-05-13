class_name Telemetry
extends RefCounted

const REQUIRED_FIELDS := [
	"run_id", "seed", "stage_index", "node_type", "shots_fired",
	"shots_hit_match", "shots_hit_mismatch", "shots_invalid_tile_cooldown",
	"shots_fired_empty_queue", "invalid_target_inputs", "queue_generated", "queue_consumed",
	"queue_wasted", "durability_loss_count", "repair_count",
	"clear_time_sec", "fail_time_sec", "result"
]

var events: Array[Dictionary] = []
var data := {}

func _init(options: Dictionary) -> void:
	data = {
		"run_id": options.get("run_id", "run"),
		"seed": options.get("seed", 1),
		"stage_index": options.get("stage_index", 0),
		"node_type": options.get("node_type", "normal"),
		"shots_fired": 0,
		"shots_hit_match": 0,
		"shots_hit_mismatch": 0,
		"shots_invalid_tile_cooldown": 0,
		"shots_fired_empty_queue": 0,
		"invalid_target_inputs": 0,
		"queue_generated": 0,
		"queue_consumed": 0,
		"queue_wasted": 0,
		"durability_loss_count": 0,
		"repair_count": 0,
		"clear_time_sec": null,
		"fail_time_sec": null,
		"result": "running"
	}

func increment(field: String, amount := 1) -> void:
	data[field] += amount

func set_value(field: String, value: Variant) -> void:
	data[field] = value

func sync_queue_stats(queue) -> void:
	data["queue_generated"] = queue.generated
	data["queue_consumed"] = queue.consumed
	data["queue_wasted"] = queue.wasted

func summary() -> Dictionary:
	return data.duplicate(true)
