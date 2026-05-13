class_name MiningResolver
extends RefCounted

var tile_cooldown_ticks := 10
var damage := {
	"red": {"shield": 0.5, "health": 1.2},
	"blue": {"shield": 1.5, "health": 0.75},
	"purple": {"shield": 0.75, "health": 0.75},
	"green": {"shield": 0.0, "health": 1.0}
}

func _init(options := {}) -> void:
	tile_cooldown_ticks = options.get("tile_cooldown_ticks", 10)

func resolve_shot(energy: String, target: Dictionary, tick: int) -> Dictionary:
	var next_target := target.duplicate(true)
	if tick < next_target.get("disabled_until", -1):
		return {"outcome": "invalid_cooldown", "damage": {"shield": 0.0, "health": 0.0}, "target": next_target}

	var weakness: Array = next_target.get("weakness", [])
	var base: Dictionary = damage.get(energy, damage["red"])
	var is_normal := weakness.is_empty()
	var is_match := is_normal or weakness.has(energy)
	var dealt := {"shield": 0.2, "health": 0.5}
	if is_match:
		var multiplier := 1.0 if is_normal else 1.5
		dealt = {"shield": base["shield"] * multiplier, "health": base["health"] * multiplier}

	if next_target["shield"] > 0:
		next_target["shield"] = max(0.0, next_target["shield"] - dealt["shield"])
	else:
		next_target["health"] = max(0.0, next_target["health"] - dealt["health"])
	next_target["disabled_until"] = tick + tile_cooldown_ticks

	return {
		"outcome": "normal" if is_normal else ("match" if is_match else "mismatch"),
		"damage": dealt,
		"target": next_target
	}
