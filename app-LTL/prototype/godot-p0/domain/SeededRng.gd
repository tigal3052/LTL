class_name SeededRng
extends RefCounted

var state: int

func _init(seed: int) -> void:
	state = seed & 0xffffffff

func next_float() -> float:
	state = int((1664525 * state + 1013904223) & 0xffffffff)
	return float(state) / 4294967296.0

func next_int(max_exclusive: int) -> int:
	if max_exclusive <= 0:
		push_error("max_exclusive must be greater than zero")
		return 0
	return int(floor(next_float() * max_exclusive))
