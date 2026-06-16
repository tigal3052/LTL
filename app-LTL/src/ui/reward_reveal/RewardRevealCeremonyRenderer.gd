# 계약:
# - Responsibility: orchestrate reward reveal ceremony drawing for count tease, count lock, reveal queue, text, and reward cards.
# - Input: drawing host, reward/presentation state, timing values, canvas metrics, and localized text strings.
# - Output: direct draw calls on the supplied host while preserving the overlay state machine.
# - Prohibited: advancing ceremony steps, mutating rewards, handling input, or emitting callbacks.
#
# 실행: define high-level reward reveal ceremony drawing helpers.
class_name RewardRevealCeremonyRenderer
extends RefCounted

const RewardRevealAnimationModelsScript = preload("res://src/ui/reward_reveal/RewardRevealAnimationModels.gd")
const RewardRevealEffectRendererScript = preload("res://src/ui/reward_reveal/RewardRevealEffectRenderer.gd")
const RewardRevealLayoutPolicyScript = preload("res://src/ui/reward_reveal/RewardRevealLayoutPolicy.gd")
const RewardRevealPresentationModelScript = preload("res://src/ui/reward_reveal/RewardRevealPresentationModel.gd")

static func draw_background_auras(host: Control, canvas_size: Vector2, alpha: float, anchor: Color) -> void:
	var safe_layout := RewardRevealLayoutPolicyScript.overlay_safe_layout_model(canvas_size)
	var focus_center: Vector2 = safe_layout.get("focusCenter", canvas_size * 0.5)
	var focus_radius := float(safe_layout.get("focusMaxRadius", minf(canvas_size.x, canvas_size.y) * 0.26))
	host.draw_circle(focus_center, focus_radius * 0.66, Color(anchor.r, anchor.g, anchor.b, 0.035 * alpha))
	host.draw_circle(focus_center + Vector2(0.0, -focus_radius * 0.12), focus_radius * 0.42, Color(0.98, 0.88, 0.62, 0.025 * alpha))

static func draw_count_tease(host: Control, presentation: Dictionary, timer: float, canvas_size: Vector2, alpha: float, step_duration: float, reward_count: int, source_lid_rect: Rect2, title_text: String, subtitle_text: String) -> void:
	var progress := RewardRevealAnimationModelsScript.ease_out(RewardRevealAnimationModelsScript.segment(timer, 0.0, step_duration))
	var preview := RewardRevealAnimationModelsScript.count_tease_preview_model(reward_count)
	var accent := Color(0.90, 0.73, 0.38, 1.0)
	var motion := RewardRevealAnimationModelsScript.mined_lid_motion_model(source_lid_rect, canvas_size, progress, reward_count)
	var chamber_rect: Rect2 = motion.get("currentRect", Rect2())
	var shake_strength := lerpf(0.4, 4.8, progress)
	chamber_rect.position += Vector2(sin(timer * float(motion.get("sparkRate", 8.0))) * shake_strength, cos(timer * 11.0) * (shake_strength * 0.45))
	RewardRevealEffectRendererScript.draw_mined_lid_charge(host, presentation, timer, canvas_size, chamber_rect, preview, motion, accent, progress, alpha)
	draw_overlay_headline(host, canvas_size, title_text, subtitle_text, alpha)

static func draw_count_lock(host: Control, presentation: Dictionary, timer: float, canvas_size: Vector2, alpha: float, step_duration: float, reward_count: int, title_text: String, subtitle_text: String) -> void:
	var burst := RewardRevealAnimationModelsScript.count_burst_model(reward_count)
	var accent := Color(0.92, 0.76, 0.40, 1.0)
	var burst_progress := RewardRevealAnimationModelsScript.ease_out(RewardRevealAnimationModelsScript.segment(timer, 0.0, step_duration))
	var burst_animation := RewardRevealAnimationModelsScript.count_burst_animation_model(canvas_size, burst_progress, reward_count)
	RewardRevealEffectRendererScript.draw_count_burst_animation(host, presentation, canvas_size, burst, burst_animation, accent, alpha)
	draw_overlay_headline(host, canvas_size, title_text, subtitle_text, alpha)

static func draw_reveal_queue(host: Control, presentation: Dictionary, timer: float, confirm_pulse: float, canvas_size: Vector2, alpha: float, step_duration: float, reward: Dictionary, current_reveal_index: int, reward_total: int, readable: bool, title_text: String, subtitle_text: String) -> void:
	var rarity := str(reward.get("rarity", "common")).to_lower()
	var accent := RewardRevealPresentationModelScript.rarity_accent(rarity)
	var payload := RewardRevealPresentationModelScript.payload_dictionary(reward)
	var energy := RewardRevealPresentationModelScript.energy_accent(str(payload.get("energy_type", "")))
	var profile := RewardRevealPresentationModelScript.reveal_visual_profile(rarity)
	var raw_reveal_progress := RewardRevealAnimationModelsScript.segment(timer, 0.0, step_duration)
	var reveal_progress := RewardRevealAnimationModelsScript.ease_out(raw_reveal_progress)
	var phase := RewardRevealAnimationModelsScript.card_reveal_phase_model(rarity, raw_reveal_progress, readable, current_reveal_index)
	var identity_visible := bool(phase.get("identityVisible", false))
	var stage_accent := accent if identity_visible else RewardRevealPresentationModelScript.sealed_neutral_accent()
	var stage_profile := profile if identity_visible else RewardRevealPresentationModelScript.sealed_visual_profile()
	var metrics := RewardRevealLayoutPolicyScript.reward_card_layout_metrics(canvas_size)
	var card_scale := lerpf(1.06, 1.0, reveal_progress)
	var card_size := Vector2(float(metrics.get("cardWidth", 580.0)), float(metrics.get("cardHeight", 292.0))) * card_scale
	var card_center := Vector2(canvas_size.x * 0.50, float(metrics.get("cardCenterY", canvas_size.y * 0.57)))
	var card_rect := Rect2(card_center - (card_size * 0.5), card_size)
	var shake_strength := float(phase.get("shakeStrength", 0.0))
	card_rect.position += Vector2(sin(timer * 38.0) * shake_strength, cos(timer * 31.0) * shake_strength * 0.42)
	draw_overlay_headline(host, canvas_size, title_text, subtitle_text, alpha)
	RewardRevealEffectRendererScript.draw_reveal_stage_backdrop(host, canvas_size, card_rect, stage_accent, alpha, reveal_progress, stage_profile, confirm_pulse, presentation)
	if identity_visible:
		RewardRevealEffectRendererScript.draw_rarity_burst(host, canvas_size, card_rect, accent, alpha, phase, profile)
	draw_reward_panel(host, timer, card_rect, reward, accent, energy, alpha, reveal_progress, profile, metrics, phase)
	draw_reveal_progress_bar(host, canvas_size, alpha, metrics, phase)
	draw_reveal_progress_text(host, canvas_size, alpha, metrics, current_reveal_index, reward_total)

static func draw_queue_progress(host: Control, timer: float, step_duration: float, current_reveal_index: int, sorted_rewards: Array, readable: bool, queue_strip_rects: Array, alpha: float) -> void:
	for index in range(queue_strip_rects.size()):
		var reward: Dictionary = sorted_rewards[index] if index < sorted_rewards.size() and sorted_rewards[index] is Dictionary else {}
		var rarity := str(reward.get("rarity", "common")).to_lower()
		var glow := 0.20
		var open_amount := 0.0
		var sealed := true
		var marker_phase := RewardRevealAnimationModelsScript.queue_marker_phase_model(rarity, index < current_reveal_index, index == current_reveal_index, readable)
		var accent := RewardRevealPresentationModelScript.rarity_accent(str(marker_phase.get("accentTier", "common"))) if bool(marker_phase.get("rarityVisible", false)) else RewardRevealPresentationModelScript.sealed_neutral_accent()
		if index < current_reveal_index:
			glow = 0.32
			open_amount = 1.0
			sealed = false
		elif index == current_reveal_index:
			glow = 0.72 if readable else 0.48
			open_amount = 1.0 if readable else clampf(timer / maxf(step_duration, 0.001), 0.0, 1.0)
		RewardRevealEffectRendererScript.draw_queue_card_marker(host, queue_strip_rects[index], accent, glow, open_amount, sealed, alpha)

static func draw_reward_panel(host: Control, timer: float, card_rect: Rect2, reward: Dictionary, accent: Color, energy: Color, alpha: float, reveal_progress: float, profile: Dictionary, metrics: Dictionary, phase: Dictionary) -> void:
	var font := host.get_theme_font("font")
	var payload := RewardRevealPresentationModelScript.payload_dictionary(reward)
	var name_text := RewardRevealPresentationModelScript.reward_display_name(reward)
	var rarity := str(reward.get("rarity", "common")).to_lower()
	var support_text := "%s  /  %s" % [RewardRevealPresentationModelScript.reward_rarity_label(rarity), RewardRevealPresentationModelScript.reward_item_type_label(payload)]
	var identity_visible := bool(phase.get("identityVisible", false))
	var frame_accent := accent if identity_visible else RewardRevealPresentationModelScript.sealed_neutral_accent()
	var frame_glow_alpha := float(profile.get("frameGlowAlpha", 0.28))
	var border_width := int(profile.get("borderWidth", 1))
	if not identity_visible:
		frame_glow_alpha = float(phase.get("sealedFrameGlowAlpha", 0.34))
		border_width = 1
	var shadow := StyleBoxFlat.new()
	shadow.bg_color = Color(0.0, 0.0, 0.0, 0.34 * alpha)
	shadow.corner_radius_top_left = 24
	shadow.corner_radius_top_right = 24
	shadow.corner_radius_bottom_right = 24
	shadow.corner_radius_bottom_left = 24
	host.draw_style_box(shadow, Rect2(card_rect.position + Vector2(0.0, 18.0), card_rect.size))
	var card := StyleBoxFlat.new()
	card.bg_color = Color(0.07, 0.10, 0.14, 0.98 * alpha)
	card.border_width_left = border_width
	card.border_width_top = border_width
	card.border_width_right = border_width
	card.border_width_bottom = border_width
	card.border_color = Color(frame_accent.r, frame_accent.g, frame_accent.b, frame_glow_alpha * alpha)
	card.corner_radius_top_left = 24
	card.corner_radius_top_right = 24
	card.corner_radius_bottom_right = 24
	card.corner_radius_bottom_left = 24
	host.draw_style_box(card, card_rect)
	var inner := StyleBoxFlat.new()
	inner.bg_color = Color(0.11, 0.15, 0.20, 0.96 * alpha)
	inner.corner_radius_top_left = 18
	inner.corner_radius_top_right = 18
	inner.corner_radius_bottom_right = 18
	inner.corner_radius_bottom_left = 18
	host.draw_style_box(inner, card_rect.grow(-12.0))
	host.draw_rect(Rect2(card_rect.position, Vector2(card_rect.size.x, 7.0)), Color(frame_accent.r, frame_accent.g, frame_accent.b, minf(1.0, frame_glow_alpha + 0.18) * alpha))
	if not identity_visible:
		RewardRevealEffectRendererScript.draw_sealed_reward_card(host, timer, card_rect, frame_accent, alpha, reveal_progress, phase)
		return
	var icon_rect := Rect2(
		card_rect.position + Vector2(float(metrics.get("iconX", 36.0)), float(metrics.get("iconY", 34.0))),
		Vector2(float(metrics.get("iconWidth", 136.0)), float(metrics.get("iconHeight", 184.0)))
	)
	draw_reward_icon(host, icon_rect, payload, energy, alpha, reveal_progress)
	var readable_alpha := clampf((0.36 + (0.64 * reveal_progress)) * alpha, 0.0, 1.0)
	if font != null:
		var text_width := float(metrics.get("textWidth", 320.0))
		var rarity_label := RewardRevealPresentationModelScript.reward_rarity_label(rarity).to_upper()
		var rarity_font_size := fit_font_size(font, rarity_label, text_width, int(metrics.get("rarityFontSize", 16)), 13)
		var name_font_size := fit_font_size(font, name_text, text_width, int(metrics.get("nameFontSize", 28)), 20)
		var support_font_size := fit_font_size(font, support_text, text_width, int(metrics.get("supportFontSize", 16)), 13)
		var text_left := card_rect.position.x + float(metrics.get("textLeft", 208.0))
		host.draw_string(font, Vector2(text_left, card_rect.position.y + float(metrics.get("rarityY", 54.0))), rarity_label, HORIZONTAL_ALIGNMENT_LEFT, -1.0, rarity_font_size, Color(0.95, 0.96, 0.98, 0.92 * readable_alpha))
		host.draw_string(font, Vector2(text_left, card_rect.position.y + float(metrics.get("nameY", 104.0))), name_text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, name_font_size, Color(1.0, 1.0, 1.0, readable_alpha))
		host.draw_string(font, Vector2(text_left, card_rect.position.y + float(metrics.get("supportY", 152.0))), support_text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, support_font_size, Color(0.73, 0.79, 0.87, 0.94 * readable_alpha))

static func draw_reward_icon(host: Control, icon_rect: Rect2, payload: Dictionary, energy: Color, alpha: float, reveal_progress: float) -> void:
	var icon_shell := StyleBoxFlat.new()
	icon_shell.bg_color = Color(0.09, 0.12, 0.17, 0.98 * alpha)
	icon_shell.border_width_left = 1
	icon_shell.border_width_top = 1
	icon_shell.border_width_right = 1
	icon_shell.border_width_bottom = 1
	icon_shell.border_color = Color(energy.r, energy.g, energy.b, 0.76 * alpha)
	icon_shell.corner_radius_top_left = 18
	icon_shell.corner_radius_top_right = 18
	icon_shell.corner_radius_bottom_right = 18
	icon_shell.corner_radius_bottom_left = 18
	host.draw_style_box(icon_shell, icon_rect)
	host.draw_circle(icon_rect.get_center(), 40.0, Color(energy.r, energy.g, energy.b, 0.22 * alpha))
	var item_type := str(payload.get("item_type", "artifact")).to_lower()
	var item_alpha := clampf(0.28 + (0.72 * reveal_progress), 0.0, 1.0) * alpha
	match item_type:
		"drill":
			host.draw_colored_polygon([icon_rect.position + Vector2(44.0, 40.0), icon_rect.position + Vector2(82.0, 54.0), icon_rect.position + Vector2(72.0, 126.0), icon_rect.position + Vector2(58.0, 148.0), icon_rect.position + Vector2(48.0, 126.0)], Color(0.96, 0.93, 0.84, 0.96 * item_alpha))
			host.draw_line(icon_rect.position + Vector2(60.0, 148.0), icon_rect.position + Vector2(60.0, 160.0), Color(energy.r, energy.g, energy.b, 0.95 * item_alpha), 4.0)
		"beacon":
			host.draw_rect(Rect2(icon_rect.position + Vector2(44.0, 48.0), Vector2(32.0, 74.0)), Color(0.92, 0.95, 0.98, 0.94 * item_alpha))
			host.draw_circle(icon_rect.position + Vector2(60.0, 40.0), 12.0, Color(energy.r, energy.g, energy.b, 0.92 * item_alpha))
			host.draw_arc(icon_rect.position + Vector2(60.0, 40.0), 28.0, -0.8, 3.94, 24, Color(energy.r, energy.g, energy.b, 0.58 * item_alpha), 3.0)
		_:
			host.draw_colored_polygon([icon_rect.position + Vector2(60.0, 34.0), icon_rect.position + Vector2(92.0, 82.0), icon_rect.position + Vector2(60.0, 134.0), icon_rect.position + Vector2(28.0, 82.0)], Color(0.96, 0.93, 0.84, 0.96 * item_alpha))

static func draw_reveal_progress_text(host: Control, canvas_size: Vector2, alpha: float, metrics: Dictionary, current_reveal_index: int, reward_total: int) -> void:
	var font := host.get_theme_font("font")
	if font == null:
		return
	var progress_text := "%d / %d" % [current_reveal_index + 1, maxi(1, reward_total)]
	var font_size := int(metrics.get("progressFontSize", 18))
	var text_size := font.get_string_size(progress_text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size)
	var progress_y := float(metrics.get("progressY", canvas_size.y * 0.83))
	host.draw_string(font, Vector2((canvas_size.x - text_size.x) * 0.5, progress_y), progress_text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, Color(0.95, 0.96, 0.98, 0.92 * alpha))

static func draw_reveal_progress_bar(host: Control, canvas_size: Vector2, alpha: float, metrics: Dictionary, phase: Dictionary) -> void:
	var bar_width := minf(float(metrics.get("cardWidth", 580.0)) * 0.72, canvas_size.x * 0.44)
	var progress_y := float(metrics.get("frontProgressY", float(metrics.get("progressY", canvas_size.y * 0.83)) - 34.0))
	var bar_rect := Rect2(Vector2((canvas_size.x - bar_width) * 0.5, progress_y), Vector2(bar_width, 8.0))
	var fill := clampf(float(phase.get("progressFill", 0.0)), 0.0, 1.0)
	host.draw_rect(bar_rect.grow(2.0), Color(0.02, 0.04, 0.07, 0.76 * alpha))
	host.draw_rect(bar_rect, Color(0.20, 0.25, 0.31, 0.72 * alpha))
	host.draw_rect(Rect2(bar_rect.position, Vector2(bar_rect.size.x * fill, bar_rect.size.y)), Color(0.94, 0.97, 1.0, 0.90 * alpha))
	if fill > 0.04:
		var head_x := bar_rect.position.x + bar_rect.size.x * fill
		host.draw_circle(Vector2(head_x, bar_rect.get_center().y), 8.0, Color(1.0, 1.0, 1.0, 0.26 * alpha))
		host.draw_circle(Vector2(head_x, bar_rect.get_center().y), 3.0, Color(1.0, 1.0, 1.0, 0.86 * alpha))

static func draw_overlay_headline(host: Control, canvas_size: Vector2, title_text: String, subtitle_text: String, alpha: float) -> void:
	var font := host.get_theme_font("font")
	if font == null:
		return
	var safe_layout := RewardRevealLayoutPolicyScript.overlay_safe_layout_model(canvas_size)
	var title_font_size := fit_font_size(font, title_text, canvas_size.x * 0.50, 28, 20)
	var subtitle_font_size := fit_font_size(font, subtitle_text, canvas_size.x * 0.58, 16, 13)
	draw_centered_text(host, font, Vector2(canvas_size.x * 0.50, float(safe_layout.get("headlineTitleY", canvas_size.y * 0.18))), title_text, title_font_size, Color(1.0, 1.0, 1.0, 0.96 * alpha))
	draw_centered_text(host, font, Vector2(canvas_size.x * 0.50, float(safe_layout.get("headlineSubtitleY", canvas_size.y * 0.22))), subtitle_text, subtitle_font_size, Color(0.76, 0.82, 0.88, 0.90 * alpha))

static func draw_confirm_prompt(host: Control, canvas_size: Vector2, alpha: float, confirm_pulse: float, prompt: String) -> void:
	var font := host.get_theme_font("font")
	if font == null:
		return
	var safe_layout := RewardRevealLayoutPolicyScript.overlay_safe_layout_model(canvas_size)
	var pulse := clampf(0.62 + (0.38 * sin(confirm_pulse * 4.4)), 0.35, 1.0) * alpha
	var font_size := fit_font_size(font, prompt, canvas_size.x * 0.60, 16, 13)
	draw_centered_text(host, font, Vector2(canvas_size.x * 0.50, float(safe_layout.get("confirmPromptY", canvas_size.y * 0.90))), prompt, font_size, Color(0.98, 0.94, 0.82, pulse))

static func draw_centered_text(host: Control, font: Font, center: Vector2, text: String, font_size: int, color: Color) -> void:
	var text_size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size)
	host.draw_string(font, Vector2(center.x - (text_size.x * 0.5), center.y), text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, color)

static func fit_font_size(font: Font, text: String, max_width: float, start_size: int, min_size: int) -> int:
	var font_size := start_size
	while font_size > min_size and font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size).x > max_width:
		font_size -= 1
	return maxi(font_size, min_size)
