# 怨꾩빟:
# - Responsibility: build stage-scaled combat obstacle dictionaries.
# - Input: CombatSimulator sizing values, obstacle family, target cell id, stage index, and ordinal.
# - Output: One obstacle Dictionary with family-specific pressure values.
# - Forbidden: simulator mutation, spawn selection, relic effects, or UI access.
#
# ?ㅽ뻾: define the combat obstacle definition helper.
class_name CombatObstacleDefinitions
extends RefCounted

const OBSTACLE_AFTERGLOW_TICKS := 12

static func build(sim: CombatSimulator, family: String, cell_id: String, stage_index: int, ordinal: int) -> Dictionary:
	var config := _config_for_stage(sim, family, stage_index)
	return {
		"id": "obs_%s_%d_%d" % [family, sim.obstacle_shift_count, ordinal],
		"family": family,
		"requiredColor": family,
		"cellId": cell_id,
		"state": "active",
		"progress": 0,
		"clearProgress": int(config.get("clearProgress", 2)),
		"afterglowTicks": int(config.get("afterglowTicks", OBSTACLE_AFTERGLOW_TICKS)),
		"afterglowTicksRemaining": 0,
		"timeCutTicks": int(config.get("timeCutTicks", 200)),
		"healAmount": float(config.get("healAmount", 1.0)),
		"pulseIntervalTicks": int(config.get("pulseIntervalTicks", 20)),
		"pulseTicksRemaining": int(config.get("pulseIntervalTicks", 20)),
		"visual": {
			"family": family,
			"pattern": "single_cell"
		}
	}

static func _config_for_stage(sim: CombatSimulator, family: String, stage_index: int) -> Dictionary:
	var stage_band := 0
	if stage_index >= 8:
		stage_band = 3
	elif stage_index >= 6:
		stage_band = 2
	elif stage_index >= 2:
		stage_band = 1
	var clear_progress := 2 if str(sim.hazard_snapshot.get("tier", "")) == "boss" else 1
	match family:
		"red":
			var time_cuts := [200, 260, 340, 400]
			return {
				"clearProgress": clear_progress,
				"afterglowTicks": OBSTACLE_AFTERGLOW_TICKS,
				"timeCutTicks": time_cuts[stage_band]
			}
		"blue":
			return {
				"clearProgress": clear_progress,
				"afterglowTicks": OBSTACLE_AFTERGLOW_TICKS
			}
		"purple":
			var pulse_intervals := [24, 20, 18, 16]
			return {
				"clearProgress": clear_progress,
				"afterglowTicks": OBSTACLE_AFTERGLOW_TICKS,
				"pulseIntervalTicks": pulse_intervals[stage_band]
			}
		"green":
			var heal_percents := [0.03, 0.05, 0.07, 0.08]
			return {
				"clearProgress": clear_progress,
				"afterglowTicks": OBSTACLE_AFTERGLOW_TICKS,
				"healAmount": maxf(1.0, sim.max_health * heal_percents[stage_band])
			}
	return {
		"clearProgress": clear_progress,
		"afterglowTicks": OBSTACLE_AFTERGLOW_TICKS
	}
