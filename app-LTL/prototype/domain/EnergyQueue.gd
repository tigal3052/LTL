class_name EnergyQueue
extends RefCounted

var capacity: int
var items: Array[String] = []
var generated := 0
var consumed := 0
var wasted := 0

func _init(queue_capacity: int = 8) -> void:
	capacity = queue_capacity

func push(energy: String) -> bool:
	generated += 1
	if items.size() >= capacity:
		wasted += 1
		return false
	items.append(energy)
	return true

func consume() -> Variant:
	if items.is_empty():
		return null
	consumed += 1
	return items.pop_front()

func snapshot() -> Dictionary:
	return {
		"capacity": capacity,
		"items": items.duplicate(),
		"stats": {
			"generated": generated,
			"consumed": consumed,
			"wasted": wasted
		}
	}
