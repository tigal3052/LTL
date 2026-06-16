# 계약:
# - Responsibility: calculate reward reveal count, lid, queue-marker, and card-reveal animation models.
# - Input: rarity ids, canvas dimensions, progress values, reward counts, and reveal readability state.
# - Output: deterministic phase and motion dictionaries used by the overlay renderer.
# - Prohibited: drawing UI, mutating reward state, reading input, or completing ceremony callbacks.
#
# 실행: define reward reveal animation model helpers.
class_name RewardRevealAnimationModels
extends RefCounted

const RewardRevealLayoutPolicyScript = preload("res://src/ui/reward_reveal/RewardRevealLayoutPolicy.gd")
const RewardRevealPresentationModelScript = preload("res://src/ui/reward_reveal/RewardRevealPresentationModel.gd")

static func count_tease_preview_model(reward_count: int) -> Dictionary:
	match RewardRevealPresentationModelScript.quantity_tease_band(reward_count):
		"standard":
			return {
				"quantityBand": "standard",
				"exactCountVisible": false,
				"previewLidCount": 1,
				"visibleRewardTokenCount": 0,
				"countClueStyle": "single_terrain_lid_charge",
				"sparkDensity": 1.25,
				"chargeDurationScale": 1.0
			}
		"jackpot":
			return {
				"quantityBand": "jackpot",
				"exactCountVisible": false,
				"previewLidCount": 1,
				"visibleRewardTokenCount": 0,
				"countClueStyle": "single_terrain_lid_charge",
				"sparkDensity": 1.65,
				"chargeDurationScale": 1.16
			}
		_:
			return {
				"quantityBand": "small",
				"exactCountVisible": false,
				"previewLidCount": 1,
				"visibleRewardTokenCount": 0,
				"countClueStyle": "single_terrain_lid_charge",
				"sparkDensity": 1.0,
				"chargeDurationScale": 0.86
			}

static func mined_lid_motion_model(source_rect: Rect2, canvas_size: Vector2, progress: float, reward_count: int) -> Dictionary:
	var clamped_progress := clampf(progress, 0.0, 1.0)
	var eased_progress := ease_out(clamped_progress)
	var band := RewardRevealPresentationModelScript.quantity_tease_band(reward_count)
	var base_spark_rate := 7.0
	if band == "standard":
		base_spark_rate = 8.8
	elif band == "jackpot":
		base_spark_rate = 10.4
	var safe_source := source_rect
	if safe_source.size.x <= 1.0 or safe_source.size.y <= 1.0:
		safe_source = RewardRevealLayoutPolicyScript.fallback_source_lid_rect(canvas_size)
	var final_rect := RewardRevealLayoutPolicyScript.center_lid_rect_for_canvas(canvas_size)
	var current_rect := Rect2(
		safe_source.position.lerp(final_rect.position, eased_progress),
		safe_source.size.lerp(final_rect.size, eased_progress)
	)
	var front_tile_flash := clampf((clamped_progress - 0.50) / 0.28, 0.0, 1.0)
	if clamped_progress > 0.92:
		front_tile_flash = maxf(0.76, 1.0 - ((clamped_progress - 0.92) / 0.18))
	return {
		"sourceRole": "terrain_lid_clone",
		"texturePath": "res://resources/UI/tile/tile_panel_nobg.png",
		"originRect": safe_source,
		"targetRect": final_rect,
		"currentRect": current_rect,
		"preservesBattlefield": true,
		"exactCountVisible": false,
		"identityVisible": false,
		"quantityBand": band,
		"baseSparkRate": base_spark_rate,
		"sparkRate": base_spark_rate * (1.0 + pow(clamped_progress, 2.0) * 4.6),
		"lightWrap": clampf((clamped_progress - 0.42) / 0.48, 0.0, 1.0),
		"frontTileFlashAlpha": front_tile_flash,
		"highlightHoldSeconds": 2.0,
		"drawOrder": "halo_behind_lid_front_flash",
		"burstReady": clamped_progress >= 0.92
	}

static func count_burst_animation_model(canvas_size: Vector2, progress: float, reward_count: int) -> Dictionary:
	var layout := RewardRevealLayoutPolicyScript.center_lid_layout_model(canvas_size)
	var closed_lid_rect: Rect2 = layout.get("closedLidRect", Rect2())
	var clamped_progress := clampf(progress, 0.0, 1.0)
	var compression_progress := ease_out(clampf(clamped_progress / 0.24, 0.0, 1.0))
	var pop_progress := ease_out(segment(clamped_progress, 0.18, 0.62))
	var orb_reveal_alpha := ease_out(clampf((clamped_progress - 0.30) / 0.58, 0.0, 1.0))
	var door_travel := 0.0
	var lid_lift := closed_lid_rect.size.y * lerpf(0.0, 3.20, pop_progress)
	var half_width := closed_lid_rect.size.x * 0.5
	var left_door_rect := Rect2(closed_lid_rect.position + Vector2(-door_travel, -lid_lift), Vector2(half_width, closed_lid_rect.size.y))
	var right_door_rect := Rect2(Vector2(closed_lid_rect.position.x + half_width + door_travel, closed_lid_rect.position.y - lid_lift), Vector2(half_width, closed_lid_rect.size.y))
	var cap_offset := Vector2(
		sin(pop_progress * PI) * closed_lid_rect.size.x * 0.08,
		(-closed_lid_rect.size.y * lerpf(0.0, 3.25, pop_progress)) - (sin(pop_progress * PI) * closed_lid_rect.size.y * 0.62) + (compression_progress * closed_lid_rect.size.y * 0.08)
	)
	var cap_rotation_degrees := lerpf(0.0, -46.0, pop_progress) + sin(clamped_progress * TAU) * 5.0
	return {
		"closedLidRect": closed_lid_rect,
		"openingStyle": "upward_cap_pop_explosion",
		"doorOpenProgress": pop_progress,
		"leftDoorRect": left_door_rect,
		"rightDoorRect": right_door_rect,
		"seamCenter": closed_lid_rect.get_center() + Vector2(0.0, closed_lid_rect.size.y * 0.06),
		"orbRevealAlpha": orb_reveal_alpha,
		"orbRiseDistance": closed_lid_rect.size.y * lerpf(0.0, 2.8, orb_reveal_alpha),
		"orbArcHeight": lerpf(closed_lid_rect.size.y * 0.20, closed_lid_rect.size.y * 1.30, orb_reveal_alpha),
		"flashAlpha": clampf((clamped_progress - 0.08) / 0.22, 0.0, 1.0) * (1.0 - pop_progress * 0.18),
		"capPopProgress": pop_progress,
		"compressionProgress": compression_progress,
		"lidCapOffset": cap_offset,
		"lidCapRotationDegrees": cap_rotation_degrees,
		"capAlpha": 1.0 - clampf((clamped_progress - 0.74) / 0.26, 0.0, 1.0),
		"fragmentCount": 18,
		"impactRingProgress": ease_out(clampf((clamped_progress - 0.18) / 0.42, 0.0, 1.0)),
		"orbMotionStyle": "buoyant_arc_silhouette",
		"visualCount": clampi(reward_count, 1, 5)
	}

static func count_burst_model(reward_count: int) -> Dictionary:
	var actual_count := maxi(1, reward_count)
	var visual_count := clampi(actual_count, 1, 5)
	return {
		"exactCountVisible": true,
		"rewardTokenCount": actual_count,
		"visualTokenCount": visual_count,
		"quantityBand": RewardRevealPresentationModelScript.quantity_tease_band(actual_count),
		"burstText": "x%d" % actual_count,
		"tokenStyle": "light_ore_count"
	}

static func card_reveal_phase_model(rarity: String, progress: float, identity_readable: bool, queue_position: int) -> Dictionary:
	var clamped_progress := clampf(progress, 0.0, 1.0)
	var profile := RewardRevealPresentationModelScript.reveal_visual_profile(rarity)
	var reveal_gate := 1.0
	var identity_visible := identity_readable
	var burst_progress := 1.0 if identity_visible else 0.0
	var shake_magnitude := float(profile.get("shakeMagnitude", 2.0))
	var pre_reveal_shake := lerpf(shake_magnitude * 0.28, shake_magnitude, clampf(clamped_progress, 0.0, 1.0))
	var progress_fill := 1.0 if identity_visible else minf(0.995, clamped_progress)
	var anticipation_pulse := clampf(0.42 + clamped_progress * 0.58, 0.0, 1.0)
	return {
		"identityVisible": identity_visible,
		"cardFace": "revealed_card" if identity_visible else "white_sealed_card",
		"shakeStrength": 0.0 if identity_visible else pre_reveal_shake,
		"whiteFlashAlpha": lerpf(0.48, 0.96, clamped_progress) if not identity_visible else lerpf(0.70, 0.0, burst_progress),
		"rarityVisibleBeforeReveal": false,
		"sealedAccentTier": "neutral_white",
		"sealedFrameGlowAlpha": 0.34,
		"rarityBurstTier": str(rarity).to_lower(),
		"burstProgress": burst_progress,
		"burstStrength": float(profile.get("burstStrength", 0.30)),
		"progressFill": progress_fill,
		"revealGate": reveal_gate,
		"anticipationPulse": anticipation_pulse,
		"usesQueuePositionForIntensity": false,
		"queuePositionIgnored": queue_position >= 0
	}

static func queue_marker_phase_model(rarity: String, revealed: bool, current: bool, current_readable: bool) -> Dictionary:
	var rarity_visible := revealed or (current and current_readable)
	return {
		"rarityVisible": rarity_visible,
		"accentTier": str(rarity).to_lower() if rarity_visible else "neutral_white",
		"sealed": not rarity_visible
	}

static func segment(value: float, start: float, duration: float) -> float:
	if duration <= 0.0:
		return 1.0 if value >= start else 0.0
	return clampf((value - start) / duration, 0.0, 1.0)

static func ease_out(value: float) -> float:
	return 1.0 - pow(1.0 - clampf(value, 0.0, 1.0), 3.0)
