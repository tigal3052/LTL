class_name EnergyTempoBalance
extends RefCounted

const VALID_COLORS := ["red", "blue", "purple", "green"]
const DEFAULT_QUEUE_CAPACITY := 16
const INITIAL_TERRAIN_COLUMNS := 10
const INITIAL_QUEUE_LOAD_RATIO := 0.5
const COOLDOWN_TEMPO_RATIO := 0.5
const COOLDOWN_REDUCTION_PER_LEVEL := 0.10
const MIN_COOLDOWN_MODIFIER := 0.5

static func normalized_colors(colors: Array, fallback_to_all: bool = false) -> Array:
	var normalized: Array = []
	var seen := {}
	for color in colors:
		var normalized_color := str(color).to_lower()
		if not (normalized_color in VALID_COLORS) or seen.has(normalized_color):
			continue
		seen[normalized_color] = true
		normalized.append(normalized_color)
	if not normalized.is_empty():
		return normalized
	return VALID_COLORS.duplicate() if fallback_to_all else []

static func native_cooldown_ticks(raw_ticks: int) -> int:
	return maxi(1, int(round(float(maxi(1, raw_ticks)) * COOLDOWN_TEMPO_RATIO)))

static func applied_cooldown_ticks(native_ticks: int, cooldown_modifier: float = 1.0) -> int:
	return maxi(1, int(round(float(maxi(1, native_ticks)) * maxf(0.0, cooldown_modifier))))

static func scaled_beacon_cooldown_mod(raw_delta: int) -> int:
	return int(raw_delta * 2)

static func cooldown_modifier_for_level(level: int) -> float:
	return clampf(1.0 - float(maxi(0, level)) * COOLDOWN_REDUCTION_PER_LEVEL, MIN_COOLDOWN_MODIFIER, 1.0)

static func initial_queue_loaded_count(capacity: int) -> int:
	var safe_capacity := maxi(0, capacity)
	if safe_capacity <= 0:
		return 0
	return maxi(1, int(ceil(float(safe_capacity) * INITIAL_QUEUE_LOAD_RATIO)))

static func terrain_color_palette() -> Array:
	return VALID_COLORS.duplicate(true)

static func terrain_markers(rows: int = 3, columns: int = 10, seed_val: int = 1, step: int = 0) -> Array:
	var safe_rows := maxi(0, rows)
	var safe_columns := maxi(0, columns)
	var markers: Array = []
	var color_counts := {}
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("%d:%d:%d:%d" % [int(seed_val), int(step), safe_rows, safe_columns]) & 0x7fffffff
	for column in range(safe_columns):
		for row in range(safe_rows):
			var color := str(VALID_COLORS[rng.randi_range(0, VALID_COLORS.size() - 1)])
			color_counts[color] = int(color_counts.get(color, 0)) + 1
			markers.append({"cellId": "r%dc%d" % [row, column], "color": color})
	if markers.size() >= VALID_COLORS.size():
		_ensure_palette_coverage(markers, color_counts)
	return markers

static func _ensure_palette_coverage(markers: Array, color_counts: Dictionary) -> void:
	for required_color in VALID_COLORS:
		if color_counts.has(required_color):
			continue
		for index in range(markers.size()):
			var old_color := str(markers[index].get("color", ""))
			if int(color_counts.get(old_color, 0)) <= 1:
				continue
			color_counts[old_color] = int(color_counts.get(old_color, 0)) - 1
			markers[index]["color"] = required_color
			color_counts[required_color] = 1
			break
