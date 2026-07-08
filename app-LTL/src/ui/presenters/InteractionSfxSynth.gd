class_name InteractionSfxSynth
extends RefCounted
const MIX_RATE := 16000
const InteractionSfxProfileScript = preload("res://src/ui/audio/InteractionSfxProfile.gd")
static func create_stream(category: String) -> AudioStreamWAV:
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_8_BITS
	stream.mix_rate = MIX_RATE
	stream.stereo = false
	var duration := InteractionSfxProfileScript.duration_for(category)
	var frame_count := int(round(duration * float(MIX_RATE)))
	var data := PackedByteArray()
	data.resize(frame_count)
	var base_freq := InteractionSfxProfileScript.frequency_for(category)
	var second_freq := base_freq * InteractionSfxProfileScript.interval_for(category)
	for i in range(frame_count):
		var t := float(i) / float(MIX_RATE)
		var n := t / maxf(duration, 0.001)
		var envelope := sin(clampf(n, 0.0, 1.0) * PI)
		var decay := pow(maxf(0.0, 1.0 - n), 1.55)
		var sample := sin(t * TAU * base_freq) * 28.0
		if category == "typewriter_tick":
			envelope = clampf(n * 16.0, 0.0, 1.0)
			decay = pow(maxf(0.0, 1.0 - n), 3.2)
			sample = (1.0 if sin(t * TAU * base_freq) >= 0.0 else -1.0) * 34.0
			sample += sin(t * TAU * base_freq * 2.0) * 5.0
		elif category == "ui_toggle":
			sample += sin(t * TAU * second_freq) * 12.0 * smoothstep(0.10, 0.68, n)
			sample += sin(t * TAU * base_freq * 0.5) * 9.0 * (1.0 - smoothstep(0.18, 0.78, n))
		elif category == "battle_start":
			sample = sin(t * TAU * base_freq * (1.0 + n * 0.18)) * 30.0
			sample += sin(t * TAU * second_freq) * 18.0 * smoothstep(0.12, 0.82, n)
			sample += sin(t * TAU * base_freq * 0.5) * 18.0 * pow(maxf(0.0, 1.0 - n), 0.85)
			decay = pow(maxf(0.0, 1.0 - n), 0.72)
		elif category == "starter_set_select":
			sample += sin(t * TAU * second_freq) * 12.0 * smoothstep(0.06, 0.62, n)
			sample += sin(t * TAU * base_freq * 2.0) * 5.0 * (1.0 - n)
		elif category == "settings_open" or category == "settings_close":
			var glide := 1.0 + n * 0.18
			if category == "settings_close":
				glide = 1.18 - n * 0.26
			sample = sin(t * TAU * base_freq * glide) * 23.0
			sample += sin(t * TAU * second_freq) * 13.0 * smoothstep(0.10, 0.76, n)
			sample += sin(t * TAU * base_freq * 2.0) * 5.0 * (1.0 - n)
		elif category == "codex_open" or category == "codex_close":
			var page_phase := sin(t * TAU * 11.0)
			var sweep := 0.92 + n * 0.28
			if category == "codex_close":
				sweep = 1.12 - n * 0.34
			sample = sin(t * TAU * base_freq * sweep) * 21.0
			sample += sin(t * TAU * second_freq) * 12.0 * smoothstep(0.14, 0.82, n)
			sample += page_phase * 6.0 * pow(maxf(0.0, 1.0 - n), 1.4)
		elif category == "item_click":
			sample = sin(t * TAU * base_freq) * 24.0
			sample += sin(t * TAU * base_freq * 1.8) * 8.0 * (1.0 - n)
			decay = pow(maxf(0.0, 1.0 - n), 2.2)
		elif category == "item_place":
			sample = sin(t * TAU * base_freq * 0.72) * 26.0
			sample += sin(t * TAU * second_freq) * 18.0 * smoothstep(0.08, 0.58, n)
			decay = pow(maxf(0.0, 1.0 - n), 1.05)
		elif category == "dialogue_advance":
			sample = sin(t * TAU * base_freq) * 24.0
			sample += sin(t * TAU * second_freq) * 14.0 * smoothstep(0.10, 0.70, n)
		elif category == "reward_expectation":
			var lift := 0.82 + n * 0.76
			envelope = smoothstep(0.0, 0.16, n) * pow(maxf(0.0, 1.0 - n), 0.18)
			decay = 1.0
			sample = sin(t * TAU * base_freq * lift) * 22.0
			sample += sin(t * TAU * second_freq * (0.94 + n * 0.18)) * 14.0 * smoothstep(0.18, 0.86, n)
			sample += sin(t * TAU * base_freq * 2.0) * 5.0 * smoothstep(0.55, 1.0, n)
		elif category == "reward_count_fanfare":
			var arp := 1.0
			if n > 0.32:
				arp = 1.25
			if n > 0.64:
				arp = 1.5
			sample = sin(t * TAU * base_freq * arp) * 28.0
			sample += sin(t * TAU * second_freq) * 16.0 * smoothstep(0.12, 0.72, n)
			sample += sin(t * TAU * base_freq * 2.0) * 8.0 * smoothstep(0.40, 0.90, n)
			decay = pow(maxf(0.0, 1.0 - n), 0.78)
		elif category == "excavation_buildup":
			var lift_low := 0.66 + n * 0.48
			var tremolo := 0.58 + 0.42 * sin(t * TAU * 9.0)
			envelope = smoothstep(0.0, 0.14, n) * pow(maxf(0.0, 1.0 - n), 0.12)
			decay = 1.0
			sample = sin(t * TAU * base_freq * lift_low) * 24.0 * tremolo
			sample += sin(t * TAU * second_freq * (0.80 + n * 0.20)) * 10.0 * smoothstep(0.20, 0.84, n)
		elif category == "excavation_detail_fanfare":
			var reveal := 0.86
			if n > 0.38:
				reveal = 1.34
			if n > 0.70:
				reveal = 1.68
			sample = sin(t * TAU * base_freq * reveal) * 25.0
			sample += sin(t * TAU * second_freq * 0.92) * 12.0 * smoothstep(0.10, 0.80, n)
			sample += sin(t * TAU * base_freq * 2.25) * 6.0 * smoothstep(0.48, 0.95, n)
			decay = pow(maxf(0.0, 1.0 - n), 0.86)
		elif category == "item_fusion":
			sample += sin(t * TAU * second_freq) * 18.0 * smoothstep(0.08, 0.72, n)
			sample += sin(t * TAU * base_freq * 2.0) * 7.0 * sin(clampf(n, 0.0, 1.0) * PI * 2.0)
		elif category == "fusion_buildup":
			var beat_phase := fmod(t * 7.5, 1.0)
			var pulse := pow(maxf(0.0, 1.0 - beat_phase), 4.0)
			var lift := 0.72 + n * 0.52
			envelope = smoothstep(0.0, 0.08, n) * pow(maxf(0.0, 1.0 - n), 0.10)
			decay = 1.0
			sample = sin(t * TAU * base_freq * lift) * 20.0 * (0.58 + pulse)
			sample += sin(t * TAU * base_freq * 0.48) * 24.0 * pulse
			sample += sin(t * TAU * second_freq * (0.88 + n * 0.24)) * 12.0 * smoothstep(0.22, 0.88, n)
		elif category == "fusion_complete":
			var arp := 1.0
			if n > 0.26:
				arp = 1.25
			if n > 0.54:
				arp = 1.50
			if n > 0.78:
				arp = 2.0
			sample = sin(t * TAU * base_freq * arp) * 27.0
			sample += sin(t * TAU * second_freq) * 16.0 * smoothstep(0.08, 0.72, n)
			sample += sin(t * TAU * base_freq * 2.0) * 8.0 * smoothstep(0.36, 0.94, n)
			decay = pow(maxf(0.0, 1.0 - n), 0.72)
		elif category == "ui_confirm" or category == "menu_open" or category == "page_transition" or category == "drag_drop":
			sample += sin(t * TAU * second_freq) * 14.0 * smoothstep(0.12, 0.82, n)
		elif category == "ui_cancel" or category == "menu_close" or category == "drag_cancel":
			sample += sin(t * TAU * second_freq) * 9.0 * (1.0 - smoothstep(0.18, 0.88, n))
		elif category == "drag_start":
			sample += sin(t * TAU * second_freq) * 6.0 * (1.0 - n)
		data[i] = int(clamp(sample * envelope * decay, -128.0, 127.0))
	stream.data = data
	return stream
