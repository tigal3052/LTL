extends SceneTree

const RunSimulator = preload("res://prototype/domain/RunSimulator.gd")

func _init() -> void:
	var simulator := RunSimulator.new({
		"seed": 20260513,
		"queue_capacity": 4,
		"node": {"shield": 0.75, "health": 0.0, "weakness": ["red"]}
	})
	var result := simulator.run([
		{"tick": 1, "target": 0, "input": "click"}
	])
	print(JSON.stringify(result["summary"], "\t"))
	quit()
