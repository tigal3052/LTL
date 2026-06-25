# 계약:
# - Responsibility: draw reward reveal effect primitives such as lids, bursts, sealed cards, and backdrops.
# - Input: a Control drawing host, presentation dictionaries, timer values, canvas/card rects, colors, progress, and phase data.
# - Output: direct draw calls on the supplied host during the overlay draw pass.
# - Prohibited: changing ceremony state, mutating rewards, handling input, or emitting callbacks.
#
# 실행: define reward reveal effect drawing helpers.
class_name RewardRevealEffectRenderer
extends RefCounted

const RewardRevealLayoutPolicyScript = preload("res://src/ui/reward_reveal/RewardRevealLayoutPolicy.gd")
const EXCAVATION_LID_TEXTURE = preload("res://resources/UI/tile/tile_panel_nobg.png")

static func draw_mined_lid_charge(host: Control, presentation: Dictionary, timer: float, canvas_size: Vector2, rect: Rect2, preview: Dictionary, motion: Dictionary, accent: Color, progress: float, alpha: float) -> void:
	var lid_texture: Texture2D = presentation.get("excavationLid", {}).get("texture", EXCAVATION_LID_TEXTURE)
	var wrap := float(motion.get("lightWrap", 0.0))
	var front_flash := float(motion.get("frontTileFlashAlpha", 0.0))
	var density := float(preview.get("sparkDensity", 1.0))
	var center := rect.get_center()
	var safe_layout := RewardRevealLayoutPolicyScript.overlay_safe_layout_model(canvas_size)
	var safe_margin := float(safe_layout.get("safeMargin", 24.0))
	var max_effect_radius := RewardRevealLayoutPolicyScript.safe_radius_for_center(canvas_size, center, safe_margin)
	var glow_radius := minf(max_effect_radius, maxf(rect.size.x, rect.size.y) * lerpf(0.58, 1.16, wrap))
	host.draw_circle(center, glow_radius, Color(accent.r, accent.g, accent.b, (0.08 + wrap * 0.22) * alpha))
	host.draw_circle(center, glow_radius * 0.62, Color(1.0, 0.94, 0.70, (0.05 + wrap * 0.18) * alpha))
	if lid_texture != null:
		host.draw_texture_rect(lid_texture, rect, true, Color(0.74 + accent.r * 0.08, 0.66 + accent.g * 0.08, 0.48 + accent.b * 0.08, 0.98 * alpha))
	else:
		host.draw_rect(rect, Color(0.42, 0.31, 0.18, 0.92 * alpha))
	var light_alpha := clampf(0.18 + wrap * 0.68, 0.0, 0.92) * alpha
	host.draw_rect(rect.grow(-8.0), Color(1.0, 0.93, 0.62, light_alpha * 0.20))
	host.draw_arc(center, minf(max_effect_radius * 0.92, maxf(rect.size.x, rect.size.y) * 0.52), -PI * 0.08, TAU * clampf(0.12 + wrap * 0.92, 0.0, 1.0), 40, Color(1.0, 0.93, 0.70, light_alpha), 4.0)
	host.draw_arc(center, minf(max_effect_radius * 0.72, maxf(rect.size.x, rect.size.y) * 0.38), PI * 0.62, PI * 0.62 + TAU * clampf(wrap, 0.0, 1.0), 36, Color(accent.r, accent.g, accent.b, light_alpha * 0.74), 3.0)
	var spark_count := int(round(12.0 * density))
	var spark_rate := float(motion.get("sparkRate", 8.0))
	for index in range(spark_count):
		var phase := timer * spark_rate + float(index) * 1.37
		var sparkle := clampf(sin(phase) * 0.5 + 0.5, 0.0, 1.0)
		var angle := (TAU / maxf(1.0, float(spark_count))) * float(index) + timer * (0.7 + wrap)
		var orbit := minf(max_effect_radius * 0.84, maxf(rect.size.x, rect.size.y) * lerpf(0.42, 0.70, sparkle))
		var pos := center + Vector2(cos(angle), sin(angle) * 0.62) * orbit
		host.draw_circle(pos, lerpf(1.4, 4.4, sparkle) * (0.75 + wrap * 0.5), Color(1.0, 0.95, 0.72, (0.18 + sparkle * 0.45 + wrap * 0.18) * alpha))
	if lid_texture != null:
		host.draw_texture_rect(lid_texture, rect, true, Color(1.0, 0.98, 0.86, (0.24 + front_flash * 0.72) * alpha))
	else:
		host.draw_rect(rect, Color(1.0, 0.96, 0.76, (0.18 + front_flash * 0.52) * alpha))
	host.draw_rect(rect.grow(-6.0), Color(1.0, 1.0, 1.0, front_flash * 0.24 * alpha))
	host.draw_rect(Rect2(rect.position, Vector2(rect.size.x, 5.0)), Color(1.0, 0.96, 0.78, (0.34 + front_flash * 0.42) * alpha))
	host.draw_rect(Rect2(rect.position + Vector2(0.0, rect.size.y - 5.0), Vector2(rect.size.x, 5.0)), Color(0.56, 0.42, 0.22, 0.28 * alpha))
	if bool(motion.get("burstReady", false)):
		host.draw_circle(center, glow_radius * 0.78, Color(1.0, 0.96, 0.78, 0.36 * alpha))

static func draw_count_burst_animation(host: Control, presentation: Dictionary, canvas_size: Vector2, burst: Dictionary, animation: Dictionary, accent: Color, alpha: float) -> void:
	var closed_lid_rect: Rect2 = animation.get("closedLidRect", Rect2())
	var lid_texture: Texture2D = presentation.get("excavationLid", {}).get("texture", EXCAVATION_LID_TEXTURE)
	var center := closed_lid_rect.get_center()
	var safe_layout := RewardRevealLayoutPolicyScript.overlay_safe_layout_model(canvas_size)
	var safe_margin := float(safe_layout.get("safeMargin", 24.0))
	var max_effect_radius := RewardRevealLayoutPolicyScript.safe_radius_for_center(canvas_size, center, safe_margin)
	var orb_reveal_alpha := float(animation.get("orbRevealAlpha", 0.0))
	var flash_alpha := float(animation.get("flashAlpha", 0.0)) * alpha
	var pop_progress := float(animation.get("capPopProgress", 0.0))
	var cap_alpha := float(animation.get("capAlpha", 1.0)) * alpha
	var cap_offset: Vector2 = animation.get("lidCapOffset", Vector2.ZERO)
	var cap_rotation := deg_to_rad(float(animation.get("lidCapRotationDegrees", 0.0)))
	var impact_progress := float(animation.get("impactRingProgress", 0.0))
	var extra_light_alpha := float(animation.get("extraLightBurstAlpha", 0.0)) * alpha
	host.draw_circle(center, minf(max_effect_radius * 0.78, closed_lid_rect.size.x * 0.62), Color(accent.r, accent.g, accent.b, (0.10 + flash_alpha * 0.28) * alpha))
	host.draw_circle(center, minf(max_effect_radius * 0.54, closed_lid_rect.size.x * 0.40), Color(1.0, 0.95, 0.78, (0.04 + flash_alpha * 0.20) * alpha))
	if flash_alpha > 0.0:
		host.draw_rect(Rect2(Vector2.ZERO, canvas_size), Color(1.0, 0.95, 0.78, flash_alpha * 0.08))
	if extra_light_alpha > 0.0:
		host.draw_rect(Rect2(Vector2.ZERO, canvas_size), Color(1.0, 0.96, 0.78, extra_light_alpha * 0.14))
		host.draw_circle(center, minf(max_effect_radius * 0.88, closed_lid_rect.size.x * 0.72), Color(1.0, 0.92, 0.50, extra_light_alpha * 0.34))
		host.draw_circle(center, minf(max_effect_radius * 0.58, closed_lid_rect.size.x * 0.48), Color(1.0, 1.0, 0.90, extra_light_alpha * 0.30))
		for beam in range(14):
			var beam_angle := (TAU / 14.0) * float(beam)
			var inner := closed_lid_rect.size.y * 0.35
			var outer := minf(max_effect_radius * 0.96, closed_lid_rect.size.x * 0.68)
			var start := center + Vector2(cos(beam_angle), sin(beam_angle) * 0.58) * inner
			var end := center + Vector2(cos(beam_angle), sin(beam_angle) * 0.58) * outer
			host.draw_line(start, end, Color(1.0, 0.96, 0.76, extra_light_alpha * 0.58), 5.0)
	host.draw_rect(Rect2(Vector2(closed_lid_rect.position.x, closed_lid_rect.position.y + closed_lid_rect.size.y - 4.0), Vector2(closed_lid_rect.size.x, 4.0)), Color(0.24, 0.19, 0.12, 0.42 * alpha))
	for wave in range(3):
		var wave_t := clampf(impact_progress - float(wave) * 0.14, 0.0, 1.0)
		if wave_t <= 0.0:
			continue
		var wave_radius := minf(max_effect_radius * (0.66 + float(wave) * 0.08), lerpf(closed_lid_rect.size.y * 0.30, closed_lid_rect.size.x * (0.40 + float(wave) * 0.10), wave_t))
		host.draw_arc(center, wave_radius, 0.0, TAU, 70, Color(1.0, 0.88, 0.58, (1.0 - wave_t) * 0.28 * alpha), maxf(2.0, 6.0 - float(wave)))
	for crack in range(10):
		var angle := -PI + (TAU / 10.0) * float(crack)
		var start := center + Vector2(cos(angle), sin(angle) * 0.34) * closed_lid_rect.size.y * 0.18
		var end := center + Vector2(cos(angle), sin(angle) * 0.50) * lerpf(closed_lid_rect.size.y * 0.38, closed_lid_rect.size.x * 0.36, pop_progress)
		host.draw_line(start, end, Color(1.0, 0.88, 0.62, (0.14 + pop_progress * 0.26) * alpha), 2.0)
	var fragment_count := int(animation.get("fragmentCount", 18))
	for index in range(fragment_count):
		var angle := (-PI * 0.92) + ((PI * 1.84) / maxf(1.0, float(fragment_count - 1))) * float(index)
		var seed := float((index * 37) % 11) / 10.0
		var distance := lerpf(closed_lid_rect.size.y * 0.24, closed_lid_rect.size.x * (0.24 + seed * 0.12), pop_progress)
		var fragment_center := center + Vector2(cos(angle), sin(angle) * 0.72 - 0.35) * distance
		var fragment_size := lerpf(3.0, 9.0, 1.0 - seed * 0.35)
		host.draw_line(center, fragment_center, Color(1.0, 0.86, 0.58, (1.0 - pop_progress * 0.38) * 0.18 * alpha), 1.4)
		host.draw_rect(Rect2(fragment_center - Vector2(fragment_size * 0.5, fragment_size * 0.25), Vector2(fragment_size, fragment_size * 0.5)), Color(0.94, 0.78, 0.48, (1.0 - pop_progress * 0.50) * 0.72 * alpha))
	var cap_center := center + cap_offset
	host.draw_set_transform(cap_center, cap_rotation, Vector2.ONE)
	if lid_texture != null:
		host.draw_texture_rect(lid_texture, Rect2(closed_lid_rect.size * -0.5, closed_lid_rect.size), true, Color(1.0, 0.92, 0.70, cap_alpha))
	else:
		host.draw_rect(Rect2(closed_lid_rect.size * -0.5, closed_lid_rect.size), Color(0.72, 0.54, 0.30, cap_alpha))
	host.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	var font := host.get_theme_font("font")
	var token_count := int(burst.get("rewardTokenCount", 1))
	var visual_token_count := int(burst.get("visualTokenCount", clampi(token_count, 1, 5)))
	var target_rects := RewardRevealLayoutPolicyScript.quantity_slot_rects(visual_token_count, canvas_size, Vector2(68.0, 68.0), center.y - closed_lid_rect.size.y * 0.92)
	var seam_center: Vector2 = animation.get("seamCenter", center)
	var orb_arc_height := float(animation.get("orbArcHeight", 40.0))
	for index in range(target_rects.size()):
		var target_rect: Rect2 = target_rects[index]
		var target_center := target_rect.get_center()
		var orbit_t := orb_reveal_alpha
		var current_x := lerpf(seam_center.x, target_center.x, orbit_t)
		var current_y := lerpf(seam_center.y + closed_lid_rect.size.y * 0.10, target_center.y, orbit_t) - sin(orbit_t * PI) * orb_arc_height
		var orb_center := Vector2(current_x, current_y)
		var orb_radius := lerpf(10.0, 22.0, orbit_t)
		var trail_alpha := clampf(orb_reveal_alpha * 0.42, 0.0, 0.42) * alpha
		host.draw_line(seam_center, orb_center, Color(1.0, 0.92, 0.70, trail_alpha), 2.0)
		host.draw_circle(orb_center, orb_radius * 1.5, Color(accent.r, accent.g, accent.b, (0.08 + orb_reveal_alpha * 0.22) * alpha))
		host.draw_circle(orb_center, orb_radius, Color(1.0, 0.86, 0.38, (0.12 + orb_reveal_alpha * 0.82) * alpha))
		host.draw_circle(orb_center + Vector2(-orb_radius * 0.28, -orb_radius * 0.34), orb_radius * 0.30, Color(1.0, 0.98, 0.82, (0.28 + orb_reveal_alpha * 0.62) * alpha))
	if font != null:
		var count_text := str(burst.get("burstText", "x%d" % token_count))
		var font_size := 44
		var text_size := font.get_string_size(count_text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size)
		var count_reveal_alpha := float(animation.get("countRevealAlpha", orb_reveal_alpha))
		var text_alpha := clampf((count_reveal_alpha - 0.32) / 0.40, 0.0, 1.0) * alpha
		host.draw_string(font, Vector2(center.x - text_size.x * 0.5, center.y + 112.0), count_text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, Color(1.0, 0.95, 0.72, text_alpha))

static func draw_queue_card_marker(host: Control, rect: Rect2, accent: Color, glow_strength: float, open_amount: float, sealed: bool, alpha: float) -> void:
	var marker := StyleBoxFlat.new()
	marker.bg_color = Color(0.08, 0.10, 0.14, 0.72 * alpha)
	marker.border_width_left = 1
	marker.border_width_top = 1
	marker.border_width_right = 1
	marker.border_width_bottom = 1
	marker.border_color = Color(accent.r, accent.g, accent.b, (0.22 + glow_strength * 0.46) * alpha)
	marker.corner_radius_top_left = 12
	marker.corner_radius_top_right = 12
	marker.corner_radius_bottom_right = 12
	marker.corner_radius_bottom_left = 12
	host.draw_style_box(marker, rect)
	var center := rect.get_center()
	if sealed:
		host.draw_circle(center, rect.size.y * 0.22, Color(1.0, 1.0, 1.0, (0.14 + glow_strength * 0.16) * alpha))
	else:
		host.draw_circle(center, rect.size.y * 0.24, Color(accent.r, accent.g, accent.b, 0.34 * alpha))
	host.draw_rect(Rect2(rect.position + Vector2(8.0, rect.size.y * 0.50), Vector2((rect.size.x - 16.0) * clampf(open_amount, 0.0, 1.0), 3.0)), Color(accent.r, accent.g, accent.b, 0.72 * alpha))

static func draw_sealed_reward_card(host: Control, timer: float, card_rect: Rect2, accent: Color, alpha: float, reveal_progress: float, phase: Dictionary) -> void:
	var white_alpha := float(phase.get("whiteFlashAlpha", 0.6)) * alpha
	var pulse := float(phase.get("anticipationPulse", reveal_progress))
	var breathing_radius := 1.0 + sin(timer * lerpf(5.6, 9.2, pulse)) * 0.035
	var silhouette_radius := minf(card_rect.size.x, card_rect.size.y) * 0.24 * breathing_radius
	host.draw_rect(card_rect.grow(-16.0), Color(1.0, 1.0, 1.0, white_alpha * 0.16))
	host.draw_circle(card_rect.get_center(), minf(card_rect.size.x, card_rect.size.y) * 0.34, Color(1.0, 1.0, 1.0, white_alpha * 0.24))
	host.draw_circle(card_rect.get_center(), silhouette_radius, Color(accent.r, accent.g, accent.b, white_alpha * 0.26))
	host.draw_arc(card_rect.get_center(), silhouette_radius * 1.28, timer * 1.7, timer * 1.7 + PI * 1.18, 34, Color(1.0, 1.0, 1.0, white_alpha * 0.34), 2.4)
	host.draw_arc(card_rect.get_center(), silhouette_radius * 1.52, -timer * 1.2, -timer * 1.2 + PI * 0.82, 28, Color(1.0, 0.95, 0.78, white_alpha * 0.22), 1.8)
	var stripe_y := card_rect.position.y + card_rect.size.y * 0.50
	host.draw_line(Vector2(card_rect.position.x + 36.0, stripe_y), Vector2(card_rect.end.x - 36.0, stripe_y), Color(1.0, 1.0, 1.0, white_alpha * 0.72), 5.0)
	for index in range(10):
		var x := lerpf(card_rect.position.x + 54.0, card_rect.end.x - 54.0, float(index) / 9.0)
		var sparkle := clampf(sin(timer * 14.0 + float(index)) * 0.5 + 0.5, 0.0, 1.0)
		host.draw_circle(Vector2(x, stripe_y - 28.0 + sin(timer * 9.0 + float(index)) * 18.0), lerpf(1.6, 4.2, sparkle), Color(1.0, 1.0, 1.0, white_alpha * sparkle))

static func draw_rarity_burst(host: Control, canvas_size: Vector2, card_rect: Rect2, accent: Color, alpha: float, phase: Dictionary, profile: Dictionary) -> void:
	var burst_progress := float(phase.get("burstProgress", 1.0))
	var strength := float(phase.get("burstStrength", 0.3))
	var spark_count := int(profile.get("sparkCount", 8))
	var beam_count := int(profile.get("beamCount", 8))
	var shockwave_count := int(profile.get("shockwaveCount", 1))
	var ember_count := int(profile.get("emberCount", spark_count / 2))
	var screen_wash_alpha := float(profile.get("screenWashAlpha", 0.0))
	var flash_alpha := float(profile.get("flashAlpha", 0.6))
	var center := card_rect.get_center()
	var safe_layout := RewardRevealLayoutPolicyScript.overlay_safe_layout_model(canvas_size)
	var safe_margin := float(safe_layout.get("safeMargin", 24.0))
	var max_effect_radius := RewardRevealLayoutPolicyScript.safe_radius_for_center(canvas_size, center, safe_margin)
	var burst_alpha := (1.0 - burst_progress * 0.42) * alpha * strength
	if screen_wash_alpha > 0.0:
		host.draw_rect(Rect2(Vector2.ZERO, canvas_size), Color(accent.r, accent.g, accent.b, burst_alpha * screen_wash_alpha))
		host.draw_rect(Rect2(Vector2.ZERO, canvas_size), Color(1.0, 0.96, 0.84, burst_alpha * flash_alpha * 0.10))
	for wave in range(shockwave_count):
		var wave_t := clampf(burst_progress + float(wave) * 0.08, 0.0, 1.0)
		var wave_radius := minf(max_effect_radius * (0.78 + float(wave) * 0.06), lerpf(card_rect.size.y * (0.24 + wave * 0.03), card_rect.size.x * (0.66 + float(wave) * 0.08), wave_t))
		host.draw_arc(center, wave_radius, 0.0, TAU, 88, Color(1.0, 0.95, 0.84, burst_alpha * (0.52 - float(wave) * 0.08)), maxf(2.0, 8.0 - float(wave) * 1.2))
	for ring in range(int(profile.get("ringCount", 1))):
		var radius := minf(max_effect_radius * (0.72 + float(ring) * 0.08), lerpf(card_rect.size.y * (0.34 + ring * 0.04), card_rect.size.x * (0.60 + float(ring) * 0.12), burst_progress))
		host.draw_arc(center, radius, 0.0, TAU, 72, Color(accent.r, accent.g, accent.b, burst_alpha * (0.90 - float(ring) * 0.12)), maxf(2.0, 6.0 - float(ring) * 0.8))
	for index in range(beam_count):
		var angle := (TAU / maxf(1.0, float(beam_count))) * float(index) + burst_progress * 0.12
		var inner := card_rect.size.y * 0.22
		var outer := minf(max_effect_radius * 0.94, card_rect.size.x * (0.42 + strength * 0.24 + sin(float(index)) * 0.04))
		var start := center + Vector2(cos(angle), sin(angle) * 0.70) * inner
		var end := center + Vector2(cos(angle), sin(angle) * 0.70) * lerpf(inner, outer, burst_progress)
		host.draw_line(start, end, Color(1.0, 0.96, 0.84, burst_alpha * 0.54), 4.0)
		host.draw_line(start, end, Color(accent.r, accent.g, accent.b, burst_alpha * 0.82), 2.0)
	for index in range(spark_count):
		var angle := (TAU / maxf(1.0, float(spark_count))) * float(index) + burst_progress * 0.40
		var radius := minf(max_effect_radius * 0.72, lerpf(card_rect.size.x * 0.18, card_rect.size.x * (0.44 + strength * 0.12), burst_progress))
		var spark_center := center + Vector2(cos(angle), sin(angle) * 0.72) * radius
		host.draw_circle(spark_center, lerpf(2.0, 5.8, 1.0 - burst_progress * 0.32), Color(accent.r, accent.g, accent.b, burst_alpha * 0.56))
	for index in range(ember_count):
		var ember_angle := (TAU / maxf(1.0, float(ember_count))) * float(index) + burst_progress * 0.75
		var ember_radius := minf(max_effect_radius * 0.56, lerpf(card_rect.size.x * 0.10, card_rect.size.x * (0.34 + strength * 0.08), burst_progress))
		var ember_center := center + Vector2(cos(ember_angle), sin(ember_angle) * 0.62) * ember_radius
		host.draw_circle(ember_center, lerpf(1.2, 3.6, burst_progress), Color(1.0, 0.92, 0.68, burst_alpha * 0.42))

static func draw_preview_excavation_chamber(host: Control, presentation: Dictionary, timer: float, rect: Rect2, preview: Dictionary, accent: Color, progress: float, alpha: float) -> void:
	var lid_texture: Texture2D = presentation.get("excavationLid", {}).get("texture", EXCAVATION_LID_TEXTURE)
	var glow_alpha := lerpf(0.18, 0.42, progress) * alpha
	var pulse_phase := timer * lerpf(3.2, 6.8, progress)
	host.draw_circle(rect.get_center(), rect.size.x * 0.34, Color(accent.r, accent.g, accent.b, glow_alpha * 0.30))
	host.draw_circle(rect.get_center() + Vector2(0.0, -12.0), rect.size.x * 0.22, Color(1.0, 0.92, 0.72, glow_alpha * 0.12))
	if lid_texture != null:
		host.draw_texture_rect(lid_texture, rect, true, Color(0.62 + accent.r * 0.12, 0.54 + accent.g * 0.10, 0.42 + accent.b * 0.08, 0.96 * alpha))
		host.draw_texture_rect(lid_texture, rect.grow(-8.0), true, Color(accent.r, accent.g, accent.b, 0.10 * alpha))
	host.draw_rect(Rect2(rect.position + Vector2(0.0, 6.0), Vector2(rect.size.x, 4.0)), Color(0.94, 0.82, 0.58, 0.34 * alpha))
	host.draw_rect(Rect2(rect.position + Vector2(0.0, rect.size.y - 8.0), Vector2(rect.size.x, 4.0)), Color(0.28, 0.21, 0.14, 0.32 * alpha))
	var hotspot_count := int(preview.get("hotspotCount", 2))
	var anchors: Array = preview.get("hotspotAnchors", [])
	for index in range(mini(hotspot_count, anchors.size())):
		var anchor := float(anchors[index])
		var hotspot_center := Vector2(lerpf(rect.position.x + 56.0, rect.end.x - 56.0, anchor), rect.position.y + rect.size.y * 0.52)
		var beat := clampf(sin(pulse_phase + (float(index) * 0.92)) * 0.5 + 0.5, 0.0, 1.0)
		var radius := lerpf(18.0, 34.0, beat)
		host.draw_circle(hotspot_center, radius, Color(accent.r, accent.g, accent.b, (0.12 + beat * 0.18) * alpha))
		host.draw_circle(hotspot_center, radius * 0.62, Color(1.0, 0.88, 0.54, (0.18 + beat * 0.16) * alpha))
		var crack_height := lerpf(18.0, 46.0, clampf(progress + beat * 0.25, 0.0, 1.0))
		host.draw_line(hotspot_center + Vector2(0.0, -6.0), hotspot_center + Vector2(0.0, -crack_height), Color(1.0, 0.90, 0.74, (0.18 + beat * 0.24) * alpha), 2.0)
		host.draw_line(hotspot_center + Vector2(-4.0, -12.0), hotspot_center + Vector2(-18.0, -28.0), Color(1.0, 0.86, 0.66, (0.10 + beat * 0.16) * alpha), 1.6)
		host.draw_line(hotspot_center + Vector2(4.0, -12.0), hotspot_center + Vector2(18.0, -28.0), Color(1.0, 0.86, 0.66, (0.10 + beat * 0.16) * alpha), 1.6)

static func draw_reveal_stage_backdrop(host: Control, canvas_size: Vector2, card_rect: Rect2, accent: Color, alpha: float, reveal_progress: float, profile: Dictionary, confirm_pulse: float, presentation: Dictionary) -> void:
	if bool(profile.get("showBackdropLid", false)):
		draw_lid_slot(host, presentation, card_rect.grow(18.0), accent, reveal_progress, reveal_progress, true, alpha)
	var aura_strength := float(profile.get("auraStrength", 0.16))
	var ring_count := int(profile.get("ringCount", 1))
	var center := card_rect.get_center() + Vector2(0.0, -12.0)
	var safe_layout := RewardRevealLayoutPolicyScript.overlay_safe_layout_model(canvas_size)
	var safe_margin := float(safe_layout.get("safeMargin", 24.0))
	var max_effect_radius := RewardRevealLayoutPolicyScript.safe_radius_for_center(canvas_size, center, safe_margin)
	for ring in range(ring_count):
		var radius := minf(max_effect_radius * (0.74 + float(ring) * 0.06), lerpf(card_rect.size.x * (0.38 + ring * 0.06), card_rect.size.x * (0.48 + ring * 0.08), reveal_progress))
		host.draw_circle(center, radius, Color(accent.r, accent.g, accent.b, aura_strength * (0.28 - ring * 0.05) * alpha))
	var pedestal_rect := Rect2(Vector2(card_rect.position.x + 28.0, card_rect.end.y - 6.0), Vector2(card_rect.size.x - 56.0, 22.0))
	host.draw_rect(pedestal_rect, Color(0.08, 0.10, 0.12, 0.72 * alpha))
	host.draw_rect(Rect2(pedestal_rect.position, Vector2(pedestal_rect.size.x, 3.0)), Color(accent.r, accent.g, accent.b, 0.34 * alpha))
	var spark_count := int(profile.get("sparkCount", 8))
	for index in range(spark_count):
		var angle := (TAU / maxf(1.0, float(spark_count))) * float(index)
		var radius := minf(max_effect_radius * 0.70, lerpf(card_rect.size.x * 0.34, card_rect.size.x * 0.44, reveal_progress))
		var spark_center := card_rect.get_center() + Vector2(cos(angle), sin(angle) * 0.72) * radius
		var spark_alpha := aura_strength * (0.24 + 0.16 * sin(confirm_pulse * 3.2 + float(index))) * alpha
		host.draw_circle(spark_center, lerpf(1.6, 3.2, reveal_progress), Color(accent.r, accent.g, accent.b, spark_alpha))

static func draw_lid_slot(host: Control, presentation: Dictionary, rect: Rect2, accent: Color, glow_strength: float, open_amount: float, sealed: bool, alpha: float) -> void:
	var lid_texture: Texture2D = presentation.get("excavationLid", {}).get("texture", EXCAVATION_LID_TEXTURE)
	var modulate := Color(0.48 + accent.r * 0.18, 0.40 + accent.g * 0.14, 0.28 + accent.b * 0.10, 0.92 * alpha)
	var open_clamped := clampf(open_amount, 0.0, 1.0)
	host.draw_rect(rect, Color(0.06, 0.05, 0.04, 0.22 * alpha))
	host.draw_circle(rect.get_center(), rect.size.y * 0.32, Color(accent.r, accent.g, accent.b, glow_strength * 0.18 * alpha))
	if lid_texture != null:
		if open_clamped <= 0.02 or sealed:
			host.draw_texture_rect(lid_texture, rect, true, modulate)
		else:
			var half_width := rect.size.x * 0.50
			var gap := lerpf(0.0, 24.0, open_clamped)
			var left_rect := Rect2(rect.position + Vector2(-gap, 0.0), Vector2(half_width - 4.0, rect.size.y))
			var right_rect := Rect2(Vector2(rect.position.x + half_width + gap, rect.position.y), Vector2(half_width - 4.0, rect.size.y))
			host.draw_texture_rect(lid_texture, left_rect, true, modulate)
			host.draw_texture_rect(lid_texture, right_rect, true, modulate)
	else:
		host.draw_rect(rect, Color(0.34, 0.28, 0.18, 0.86 * alpha))
	host.draw_rect(Rect2(rect.position, Vector2(rect.size.x, 4.0)), Color(0.74, 0.63, 0.48, 0.38 * alpha))
	host.draw_rect(Rect2(rect.position + Vector2(0.0, rect.size.y - 4.0), Vector2(rect.size.x, 4.0)), Color(0.20, 0.16, 0.12, 0.28 * alpha))
	if glow_strength > 0.0:
		host.draw_rect(rect.grow(-10.0), Color(accent.r, accent.g, accent.b, glow_strength * 0.05 * alpha))
