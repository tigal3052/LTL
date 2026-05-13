extends Control

const RunSimulator = preload("res://prototype/domain/RunSimulator.gd")

@onready var output: RichTextLabel = $Output

func _ready() -> void:
	var simulator := RunSimulator.new({
		"seed": 20260513,
		"queue_capacity": 4,
		"node": {"shield": 0.75, "health": 0.0, "weakness": ["red"]}
	})
	var result := simulator.run([
		{"tick": 1, "target": 0, "input": "click"}
	])
	output.text = JSON.stringify(result["summary"], "\t")
