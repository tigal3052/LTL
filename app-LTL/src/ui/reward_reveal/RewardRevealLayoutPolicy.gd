# 계약:
# - Responsibility: calculate reward reveal safe-area, lid, card, and token-slot layout models.
# - Input: canvas dimensions, centers, margins, slot counts, and slot sizes.
# - Output: deterministic Rect2/Vector2 layout dictionaries and slot rect arrays.
# - Prohibited: drawing, reward mutation, input handling, or ceremony-step decisions.
#
# 실행: define reward reveal layout policy helpers.
class_name RewardRevealLayoutPolicy
extends RefCounted

const EXCAVATION_LID_TEXTURE = preload("res://resources/UI/tile/tile_panel_nobg.png")

static func safe_radius_for_center(canvas_size: Vector2, center: Vector2, margin: float = 24.0) -> float:
	var horizontal := minf(center.x, canvas_size.x - center.x)
	var vertical := minf(center.y, canvas_size.y - center.y)
	return maxf(0.0, minf(horizontal, vertical) - margin)

static func overlay_safe_layout_model(canvas_size: Vector2) -> Dictionary:
	var safe_margin := clampf(minf(canvas_size.x, canvas_size.y) * 0.03, 24.0, 36.0)
	var headline_title_y := clampf(canvas_size.y * 0.18, safe_margin + 56.0, canvas_size.y * 0.24)
	var headline_subtitle_y := headline_title_y + clampf(canvas_size.y * 0.042, 28.0, 38.0)
	var confirm_prompt_y := minf(canvas_size.y * 0.90, canvas_size.y - safe_margin)
	var focus_center := Vector2(
		canvas_size.x * 0.50,
		clampf(canvas_size.y * 0.56, headline_subtitle_y + 110.0, confirm_prompt_y - 128.0)
	)
	var focus_max_radius := safe_radius_for_center(canvas_size, focus_center, safe_margin)
	return {
		"safeMargin": safe_margin,
		"focusCenter": focus_center,
		"focusMaxRadius": focus_max_radius,
		"headlineTitleY": headline_title_y,
		"headlineSubtitleY": headline_subtitle_y,
		"confirmPromptY": confirm_prompt_y,
		"cardCenterY": clampf(focus_center.y + canvas_size.y * 0.012, headline_subtitle_y + 140.0, confirm_prompt_y - 148.0)
	}

static func center_lid_layout_model(canvas_size: Vector2) -> Dictionary:
	var aspect_ratio := excavation_lid_aspect_ratio()
	var safe_layout := overlay_safe_layout_model(canvas_size)
	var focus_center: Vector2 = safe_layout.get("focusCenter", canvas_size * 0.5)
	var safe_margin := float(safe_layout.get("safeMargin", 24.0))
	var focus_radius := float(safe_layout.get("focusMaxRadius", safe_radius_for_center(canvas_size, focus_center, safe_margin)))
	var lid_width := minf(
		minf(clampf(canvas_size.x * 0.34, 300.0, 560.0), maxf(280.0, (focus_radius - 12.0) * 1.72)),
		canvas_size.x - (safe_margin * 2.0)
	)
	var lid_height := lid_width / maxf(1.0, aspect_ratio)
	var closed_rect := Rect2(focus_center - Vector2(lid_width * 0.5, lid_height * 0.5), Vector2(lid_width, lid_height))
	return {
		"aspectRatio": aspect_ratio,
		"closedLidRect": closed_rect,
		"lidWidth": lid_width,
		"lidHeight": lid_height
	}

static func center_lid_rect_for_canvas(canvas_size: Vector2) -> Rect2:
	return center_lid_layout_model(canvas_size).get("closedLidRect", Rect2())

static func fallback_source_lid_rect(canvas_size: Vector2) -> Rect2:
	var fallback_size := Vector2(96.0, 60.0)
	return Rect2((canvas_size * 0.5) - (fallback_size * 0.5), fallback_size)

static func reward_card_layout_metrics(canvas_size: Vector2) -> Dictionary:
	var safe_layout := overlay_safe_layout_model(canvas_size)
	var safe_margin := float(safe_layout.get("safeMargin", 24.0))
	var confirm_prompt_y := float(safe_layout.get("confirmPromptY", canvas_size.y - safe_margin))
	var headline_subtitle_y := float(safe_layout.get("headlineSubtitleY", canvas_size.y * 0.22))
	var card_center_y := float(safe_layout.get("cardCenterY", canvas_size.y * 0.57))
	var card_width := minf(canvas_size.x - (safe_margin * 2.0), clampf(canvas_size.x * 0.44, 420.0, 620.0))
	var max_card_height := maxf(200.0, confirm_prompt_y - headline_subtitle_y - 134.0)
	var card_height := minf(max_card_height, clampf(canvas_size.y * 0.30, 220.0, 308.0))
	var card_half_height := card_height * 0.5
	card_center_y = clampf(card_center_y, headline_subtitle_y + 56.0 + card_half_height, confirm_prompt_y - 70.0 - card_half_height)
	var card_bottom := card_center_y + card_half_height
	var front_progress_y := minf(card_bottom + maxf(10.0, canvas_size.y * 0.018), confirm_prompt_y - 34.0)
	var progress_font_size := int(clampf(canvas_size.y * 0.033, 16.0, 18.0))
	var progress_y := minf(front_progress_y + maxf(18.0, canvas_size.y * 0.030), confirm_prompt_y - float(progress_font_size) - 12.0)
	var icon_x := 36.0
	var icon_y := 36.0
	var icon_width := minf(132.0, card_width * 0.24)
	var icon_height := card_height - 72.0
	var text_left := icon_x + icon_width + 32.0
	var text_right_padding := 30.0
	var text_width := card_width - text_left - text_right_padding
	return {
		"cardWidth": card_width,
		"cardHeight": card_height,
		"cardCenterY": card_center_y,
		"iconX": icon_x,
		"iconY": icon_y,
		"iconWidth": icon_width,
		"iconHeight": icon_height,
		"iconRight": icon_x + icon_width,
		"textLeft": text_left,
		"textWidth": text_width,
		"rarityY": 56.0,
		"nameY": 108.0,
		"supportY": 158.0,
		"frontProgressY": front_progress_y,
		"progressY": progress_y,
		"cardBottom": card_bottom,
		"rarityFontSize": 16,
		"nameFontSize": 28,
		"supportFontSize": 16,
		"progressFontSize": progress_font_size
	}

static func quantity_slot_rects(count: int, canvas_size: Vector2, slot_size: Vector2, center_y: float) -> Array:
	var rects: Array = []
	var clamped_count := clampi(count, 1, 5)
	match clamped_count:
		1:
			rects.append(Rect2(Vector2(canvas_size.x * 0.50, center_y) - (slot_size * 0.5), slot_size))
		2:
			var half_spacing := (slot_size.x + 24.0) * 0.5
			rects.append(Rect2(Vector2((canvas_size.x * 0.50) - half_spacing, center_y) - (slot_size * 0.5), slot_size))
			rects.append(Rect2(Vector2((canvas_size.x * 0.50) + half_spacing, center_y) - (slot_size * 0.5), slot_size))
		3:
			for offset in [-1, 0, 1]:
				rects.append(Rect2(Vector2(canvas_size.x * 0.50 + (float(offset) * (slot_size.x + 20.0) * 0.78), center_y) - (slot_size * 0.5), slot_size))
		4:
			for offset in [-1.5, -0.5, 0.5, 1.5]:
				rects.append(Rect2(Vector2(canvas_size.x * 0.50 + (offset * (slot_size.x + 18.0) * 0.66), center_y) - (slot_size * 0.5), slot_size))
		_:
			for offset in [-2.0, -1.0, 0.0, 1.0, 2.0]:
				rects.append(Rect2(Vector2(canvas_size.x * 0.50 + (offset * (slot_size.x + 14.0) * 0.58), center_y) - (slot_size * 0.5), slot_size))
	return rects

static func queue_strip_rects(count: int, canvas_size: Vector2) -> Array:
	return quantity_slot_rects(count, canvas_size, Vector2(116.0, 74.0), canvas_size.y * 0.31)

static func count_tease_thresholds(count: int) -> Array:
	match clampi(count, 1, 5):
		1:
			return [0.18]
		2:
			return [0.16, 0.60]
		3:
			return [0.12, 0.42, 0.72]
		4:
			return [0.10, 0.30, 0.54, 0.80]
		_:
			return [0.08, 0.24, 0.42, 0.62, 0.82]

static func excavation_lid_aspect_ratio() -> float:
	if EXCAVATION_LID_TEXTURE != null and EXCAVATION_LID_TEXTURE.get_height() > 0:
		var measured_ratio := float(EXCAVATION_LID_TEXTURE.get_width()) / float(EXCAVATION_LID_TEXTURE.get_height())
		if measured_ratio > 5.0:
			return measured_ratio
	return 7.5
