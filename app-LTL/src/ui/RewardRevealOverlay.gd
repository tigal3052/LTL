# 계약:
# - Responsibility: render the mining-themed reward ceremony overlay and keep it on screen until the player confirms each beat.
# - Input: pending reward dictionaries from the controller plus step/done callbacks.
# - Output: full-screen reward ceremony visuals, confirm-gated step progression, and callback notifications.
# - Prohibited: mutating run-state rewards, claiming artifacts, or deciding reward tray logic.
#
# 실행: define the reward ceremony overlay controller.
# 怨꾩빟:
# - 책임: reward ceremony full-screen overlay를 그리고 단계별 확인 입력과 reveal presentation을 관리한다.
# - 입력: reward list, step/done callback, frame delta, confirm input.
# - 출력: stage reveal overlay drawing, ceremony_step_changed signal, done callback.
# - 금지: reward inventory mutation, combat state mutation, controller orchestration bypass.
#
# ?ㅽ뻾: define the full-screen reward reveal overlay control.
class_name RewardRevealOverlay
extends Control

signal ceremony_step_changed(step: String)
signal ceremony_finished

const TextCatalogScript = preload("res://src/ui/TextCatalog.gd")
const EXCAVATION_LID_TEXTURE = preload("res://resources/UI/tile/tile_panel_nobg.png")
const REVEAL_TIMING := {
	"scrimIn": 0.20,
	"countTeaseSmall": 2.80,
	"countTeaseStandard": 3.00,
	"countTeaseJackpot": 3.20,
	"countLockHold": 1.80,
	"revealCommon": 3.00,
	"revealRare": 3.45,
	"revealEpic": 4.10,
	"revealLegendary": 4.80,
	"heroHold": 0.92,
	"fadeOut": 0.34
}

var is_revealing := false
var rewards: Array = []
var sorted_rewards: Array = []
var presentation: Dictionary = {}
var particles: Array = []
var timer := 0.0
var confirm_pulse := 0.0
var callback: Callable = Callable()
var step_callback: Callable = Callable()
var current_step := "count_tease"
var current_reveal_index := 0
var readable := false
var source_lid_rect := Rect2()
 # 실행: expose a stable timing profile for tests and tuning.
static func reveal_timing_profile() -> Dictionary:
	return REVEAL_TIMING.duplicate()

 # 실행: project reward ceremony presentation data for tests and runtime consumers.
static func build_presentation_model(reward_list: Array) -> Dictionary:
	var reveal_order := _sorted_reward_dictionaries(reward_list)
	var hero_index := RewardRevealOverlay._hero_reward_index(reward_list)
	var hero_reward: Dictionary = {}
	if hero_index >= 0 and hero_index < reward_list.size() and reward_list[hero_index] is Dictionary:
		hero_reward = reward_list[hero_index]
	var hero_payload := RewardRevealOverlay._payload_dictionary(hero_reward)
	var hero_rarity := str(hero_reward.get("rarity", "common")).to_lower()
	var reveal_order_names: Array = []
	var reveal_order_rarity_vfx: Array = []
	for reward in reveal_order:
		reveal_order_names.append(RewardRevealOverlay._reward_display_name(reward))
		reveal_order_rarity_vfx.append(RewardRevealOverlay._reward_rarity_vfx_tier(reward))
	return {
		"heroIndex": hero_index,
		"heroName": RewardRevealOverlay._reward_display_name(hero_reward),
		"heroRarity": hero_rarity,
		"heroRarityLabel": _reward_rarity_label(hero_rarity),
		"heroItemType": str(hero_payload.get("item_type", "artifact")).to_lower(),
		"heroItemTypeLabel": _reward_item_type_label(hero_payload),
		"heroEnergyType": str(hero_payload.get("energy_type", "")),
		"extraCount": maxi(0, reward_list.size() - 1),
		"accent": RewardRevealOverlay._rarity_accent(hero_rarity),
		"energyAccent": RewardRevealOverlay._energy_accent(str(hero_payload.get("energy_type", ""))),
		"supportText": "%s  /  %s" % [_reward_rarity_label(hero_rarity), _reward_item_type_label(hero_payload)],
		"requiresConfirm": true,
		"revealOrderNames": reveal_order_names,
		"revealOrderRarityVfx": reveal_order_rarity_vfx,
		"quantityTeaseBand": RewardRevealOverlay._quantity_tease_band(reward_list.size()),
		"excavationLid": {
			"theme": "terrain_lid_clone",
			"texturePath": "res://resources/UI/tile/tile_panel_nobg.png",
			"texture": EXCAVATION_LID_TEXTURE
		}
	}

 # 실행: initialize the full-screen overlay and input capture.
func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	focus_mode = Control.FOCUS_ALL
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	set_process_input(true)

 # 실행: start the reward ceremony for the supplied reward queue.
func start_reveal(reward_list: Array, on_step_changed: Callable, done: Callable, source_lid_global_rect: Rect2 = Rect2()) -> void:
	rewards = reward_list.duplicate(true)
	sorted_rewards = _sorted_reward_dictionaries(rewards)
	presentation = build_presentation_model(rewards)
	step_callback = on_step_changed
	callback = done
	source_lid_rect = _local_source_lid_rect(source_lid_global_rect, _current_canvas_size())
	particles.clear()
	_spawn_intro_particles()
	current_reveal_index = 0
	confirm_pulse = 0.0
	timer = 0.0
	readable = false
	is_revealing = true
	visible = true
	_enter_step("count_tease")
	queue_redraw()

 # 실행: accelerate the current step or advance when already readable.
func skip_to_silhouettes() -> void:
	if not is_revealing:
		return
	if readable:
		_advance_step()
	else:
		_finish_current_step_animation()

# 실행: stop the ceremony overlay without notifying the controller completion callback.
func cancel_reveal() -> void:
	is_revealing = false
	visible = false
	readable = false
	timer = 0.0
	confirm_pulse = 0.0
	current_reveal_index = 0
	current_step = "count_tease"
	particles.clear()
	callback = Callable()
	step_callback = Callable()
	queue_redraw()

func _gui_input(event: InputEvent) -> void:
	if not is_revealing:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_handle_confirm_input()
		accept_event()

func _input(event: InputEvent) -> void:
	if not is_revealing:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode in [KEY_SPACE, KEY_ENTER, KEY_KP_ENTER]:
			_handle_confirm_input()
			get_viewport().set_input_as_handled()

func _process(delta: float) -> void:
	if not is_revealing:
		return
	confirm_pulse += delta
	_update_particles(delta)
	if readable:
		queue_redraw()
		return
	timer += delta
	if timer >= _current_step_duration():
		_finish_current_step_animation()
	queue_redraw()

func _draw() -> void:
	if not is_revealing:
		return
	var canvas_size := _current_canvas_size()
	var scrim_alpha := clampf(RewardRevealOverlay._segment(timer, 0.0, float(REVEAL_TIMING.get("scrimIn", 0.20))), 0.0, 1.0)
	if readable:
		scrim_alpha = 1.0
	draw_rect(Rect2(Vector2.ZERO, canvas_size), Color(0.02, 0.04, 0.07, 0.92 * scrim_alpha))
	_draw_background_auras(canvas_size, scrim_alpha)
	for particle in particles:
		draw_circle(
			particle.get("pos", Vector2.ZERO),
			float(particle.get("size", 3.0)),
			Color(1.0, 0.94, 0.72, float(particle.get("alpha", 0.0)) * scrim_alpha)
		)
	match current_step:
		"count_tease":
			_draw_count_tease(canvas_size, scrim_alpha)
		"count_lock":
			_draw_count_lock(canvas_size, scrim_alpha)
		"reveal_queue":
			_draw_reveal_queue(canvas_size, scrim_alpha)
	if readable:
		_draw_confirm_prompt(canvas_size, scrim_alpha)

func _handle_confirm_input() -> void:
	if not is_revealing:
		return
	if readable:
		_advance_step()
	else:
		_finish_current_step_animation()

func _advance_step() -> void:
	match current_step:
		"count_tease":
			_enter_step("count_lock")
		"count_lock":
			_enter_step("reveal_queue")
		"reveal_queue":
			if current_reveal_index + 1 < sorted_rewards.size():
				current_reveal_index += 1
				_enter_step("reveal_queue")
			else:
				_finish_reveal()

func _enter_step(step: String) -> void:
	current_step = step
	timer = 0.0
	readable = false
	_emit_step_changed(step)
	queue_redraw()

func _finish_current_step_animation() -> void:
	timer = _current_step_duration()
	readable = true
	queue_redraw()

func _emit_step_changed(step: String) -> void:
	ceremony_step_changed.emit(step)
	if step_callback.is_valid():
		step_callback.call(step)

func _current_step_duration() -> float:
	match current_step:
		"count_tease":
			match str(presentation.get("quantityTeaseBand", "small")):
				"standard":
					return float(REVEAL_TIMING.get("countTeaseStandard", 3.00))
				"jackpot":
					return float(REVEAL_TIMING.get("countTeaseJackpot", 3.20))
				_:
					return float(REVEAL_TIMING.get("countTeaseSmall", 2.80))
		"count_lock":
			return float(REVEAL_TIMING.get("countLockHold", 1.80))
		"reveal_queue":
			return _reveal_duration_for_rarity(_current_reward_rarity())
	return 0.0

func _reveal_duration_for_rarity(rarity: String) -> float:
	match rarity:
		"mythic", "legendary":
			return float(REVEAL_TIMING.get("revealLegendary", 4.80))
		"epic":
			return float(REVEAL_TIMING.get("revealEpic", 4.10))
		"rare":
			return float(REVEAL_TIMING.get("revealRare", 3.45))
	return float(REVEAL_TIMING.get("revealCommon", 3.00))

func _draw_background_auras(canvas_size: Vector2, alpha: float) -> void:
	var anchor := _current_highlight_color()
	var safe_layout := RewardRevealOverlay.overlay_safe_layout_model(canvas_size)
	var focus_center: Vector2 = safe_layout.get("focusCenter", canvas_size * 0.5)
	var focus_radius := float(safe_layout.get("focusMaxRadius", minf(canvas_size.x, canvas_size.y) * 0.26))
	draw_circle(focus_center, focus_radius * 0.66, Color(anchor.r, anchor.g, anchor.b, 0.035 * alpha))
	draw_circle(focus_center + Vector2(0.0, -focus_radius * 0.12), focus_radius * 0.42, Color(0.98, 0.88, 0.62, 0.025 * alpha))

func _draw_count_tease(canvas_size: Vector2, alpha: float) -> void:
	var progress := RewardRevealOverlay._ease_out(RewardRevealOverlay._segment(timer, 0.0, _current_step_duration()))
	var preview := RewardRevealOverlay.count_tease_preview_model(sorted_rewards.size())
	var accent := Color(0.90, 0.73, 0.38, 1.0)
	var motion := RewardRevealOverlay.mined_lid_motion_model(source_lid_rect, canvas_size, progress, sorted_rewards.size())
	var chamber_rect: Rect2 = motion.get("currentRect", Rect2())
	var shake_strength := lerpf(0.4, 4.8, progress)
	chamber_rect.position += Vector2(sin(timer * float(motion.get("sparkRate", 8.0))) * shake_strength, cos(timer * 11.0) * (shake_strength * 0.45))
	_draw_mined_lid_charge(canvas_size, chamber_rect, preview, motion, accent, progress, alpha)
	_draw_overlay_headline(
		canvas_size,
		_count_tease_title(),
		_count_tease_subtitle(),
		alpha
	)

func _draw_count_lock(canvas_size: Vector2, alpha: float) -> void:
	var reward_count := sorted_rewards.size()
	var burst := RewardRevealOverlay.count_burst_model(reward_count)
	var accent := Color(0.92, 0.76, 0.40, 1.0)
	var burst_progress := RewardRevealOverlay._ease_out(RewardRevealOverlay._segment(timer, 0.0, _current_step_duration()))
	var burst_animation := RewardRevealOverlay.count_burst_animation_model(canvas_size, burst_progress, reward_count)
	_draw_count_burst_animation(canvas_size, burst, burst_animation, accent, alpha)
	_draw_overlay_headline(
		canvas_size,
		_count_lock_title(reward_count),
		_count_lock_subtitle(),
		alpha
	)

func _draw_reveal_queue(canvas_size: Vector2, alpha: float) -> void:
	var reward := _current_reward()
	var rarity := _current_reward_rarity()
	var accent := RewardRevealOverlay._rarity_accent(rarity)
	var energy := RewardRevealOverlay._energy_accent(str(RewardRevealOverlay._payload_dictionary(reward).get("energy_type", "")))
	var profile := RewardRevealOverlay.reveal_visual_profile(rarity)
	var raw_reveal_progress := RewardRevealOverlay._segment(timer, 0.0, _current_step_duration())
	var reveal_progress := RewardRevealOverlay._ease_out(raw_reveal_progress)
	var phase := RewardRevealOverlay.card_reveal_phase_model(rarity, raw_reveal_progress, readable, current_reveal_index)
	var identity_visible := bool(phase.get("identityVisible", false))
	var stage_accent := accent if identity_visible else RewardRevealOverlay._sealed_neutral_accent()
	var stage_profile := profile if identity_visible else RewardRevealOverlay._sealed_visual_profile()
	var metrics := RewardRevealOverlay.reward_card_layout_metrics(canvas_size)
	var card_scale := lerpf(1.06, 1.0, reveal_progress)
	var card_size := Vector2(float(metrics.get("cardWidth", 580.0)), float(metrics.get("cardHeight", 292.0))) * card_scale
	var card_center := Vector2(canvas_size.x * 0.50, float(metrics.get("cardCenterY", canvas_size.y * 0.57)))
	var card_rect := Rect2(card_center - (card_size * 0.5), card_size)
	var shake_strength := float(phase.get("shakeStrength", 0.0))
	card_rect.position += Vector2(sin(timer * 38.0) * shake_strength, cos(timer * 31.0) * shake_strength * 0.42)
	_draw_overlay_headline(
		canvas_size,
		_reveal_queue_title(),
		_reveal_queue_subtitle(),
		alpha
	)
	_draw_reveal_stage_backdrop(canvas_size, card_rect, stage_accent, alpha, reveal_progress, stage_profile)
	if identity_visible:
		_draw_rarity_burst(canvas_size, card_rect, accent, alpha, phase, profile)
	_draw_reward_panel(card_rect, reward, accent, energy, alpha, reveal_progress, profile, metrics, phase)
	_draw_reveal_progress_bar(canvas_size, alpha, metrics, phase)
	_draw_reveal_progress_text(canvas_size, alpha, metrics)

func _draw_queue_progress(queue_strip_rects: Array, alpha: float) -> void:
	for index in range(queue_strip_rects.size()):
		var reward: Dictionary = sorted_rewards[index] if index < sorted_rewards.size() and sorted_rewards[index] is Dictionary else {}
		var rarity := str(reward.get("rarity", "common")).to_lower()
		var glow := 0.20
		var open_amount := 0.0
		var sealed := true
		var marker_phase := RewardRevealOverlay.queue_marker_phase_model(rarity, index < current_reveal_index, index == current_reveal_index, readable)
		var accent := RewardRevealOverlay._rarity_accent(str(marker_phase.get("accentTier", "common"))) if bool(marker_phase.get("rarityVisible", false)) else RewardRevealOverlay._sealed_neutral_accent()
		if index < current_reveal_index:
			glow = 0.32
			open_amount = 1.0
			sealed = false
		elif index == current_reveal_index:
			glow = 0.72 if readable else 0.48
			open_amount = 1.0 if readable else clampf(timer / maxf(_current_step_duration(), 0.001), 0.0, 1.0)
		_draw_queue_card_marker(queue_strip_rects[index], accent, glow, open_amount, sealed, alpha)

func _draw_reward_panel(card_rect: Rect2, reward: Dictionary, accent: Color, energy: Color, alpha: float, reveal_progress: float, profile: Dictionary, metrics: Dictionary, phase: Dictionary) -> void:
	var font := get_theme_font("font")
	var payload := RewardRevealOverlay._payload_dictionary(reward)
	var name_text := RewardRevealOverlay._reward_display_name(reward)
	var rarity := str(reward.get("rarity", "common")).to_lower()
	var support_text := "%s  /  %s" % [_reward_rarity_label(rarity), _reward_item_type_label(payload)]
	var identity_visible := bool(phase.get("identityVisible", false))
	var frame_accent := accent if identity_visible else RewardRevealOverlay._sealed_neutral_accent()
	var frame_glow_alpha := float(profile.get("frameGlowAlpha", 0.28))
	var border_width := int(profile.get("borderWidth", 1))
	if not identity_visible:
		frame_glow_alpha = float(phase.get("sealedFrameGlowAlpha", 0.34))
		border_width = 1
	var rarity_font_size := _fit_font_size(font, _reward_rarity_label(rarity).to_upper(), float(metrics.get("textWidth", 320.0)), int(metrics.get("rarityFontSize", 16)), 13)
	var name_font_size := _fit_font_size(font, name_text, float(metrics.get("textWidth", 320.0)), int(metrics.get("nameFontSize", 28)), 20)
	var support_font_size := _fit_font_size(font, support_text, float(metrics.get("textWidth", 320.0)), int(metrics.get("supportFontSize", 16)), 13)
	var shadow := StyleBoxFlat.new()
	shadow.bg_color = Color(0.0, 0.0, 0.0, 0.34 * alpha)
	shadow.corner_radius_top_left = 24
	shadow.corner_radius_top_right = 24
	shadow.corner_radius_bottom_right = 24
	shadow.corner_radius_bottom_left = 24
	draw_style_box(shadow, Rect2(card_rect.position + Vector2(0.0, 18.0), card_rect.size))
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
	draw_style_box(card, card_rect)
	var inner := StyleBoxFlat.new()
	inner.bg_color = Color(0.11, 0.15, 0.20, 0.96 * alpha)
	inner.corner_radius_top_left = 18
	inner.corner_radius_top_right = 18
	inner.corner_radius_bottom_right = 18
	inner.corner_radius_bottom_left = 18
	draw_style_box(inner, card_rect.grow(-12.0))
	draw_rect(Rect2(card_rect.position, Vector2(card_rect.size.x, 7.0)), Color(frame_accent.r, frame_accent.g, frame_accent.b, minf(1.0, frame_glow_alpha + 0.18) * alpha))
	if not identity_visible:
		_draw_sealed_reward_card(card_rect, frame_accent, alpha, reveal_progress, phase)
		return
	var icon_rect := Rect2(
		card_rect.position + Vector2(float(metrics.get("iconX", 36.0)), float(metrics.get("iconY", 34.0))),
		Vector2(float(metrics.get("iconWidth", 136.0)), float(metrics.get("iconHeight", 184.0)))
	)
	_draw_reward_icon(icon_rect, payload, energy, alpha, reveal_progress)
	var readable_alpha := clampf((0.36 + (0.64 * reveal_progress)) * alpha, 0.0, 1.0)
	if font != null:
		var text_left := card_rect.position.x + float(metrics.get("textLeft", 208.0))
		var rarity_y := card_rect.position.y + float(metrics.get("rarityY", 54.0))
		var name_y := card_rect.position.y + float(metrics.get("nameY", 104.0))
		var support_y := card_rect.position.y + float(metrics.get("supportY", 152.0))
		draw_string(font, Vector2(text_left, rarity_y), _reward_rarity_label(rarity).to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1.0, rarity_font_size, Color(0.95, 0.96, 0.98, 0.92 * readable_alpha))
		draw_string(font, Vector2(text_left, name_y), name_text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, name_font_size, Color(1.0, 1.0, 1.0, readable_alpha))
		draw_string(font, Vector2(text_left, support_y), support_text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, support_font_size, Color(0.73, 0.79, 0.87, 0.94 * readable_alpha))

func _draw_reward_icon(icon_rect: Rect2, payload: Dictionary, energy: Color, alpha: float, reveal_progress: float) -> void:
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
	draw_style_box(icon_shell, icon_rect)
	draw_circle(icon_rect.get_center(), 40.0, Color(energy.r, energy.g, energy.b, 0.22 * alpha))
	var item_type := str(payload.get("item_type", "artifact")).to_lower()
	var item_alpha := clampf(0.28 + (0.72 * reveal_progress), 0.0, 1.0) * alpha
	match item_type:
		"drill":
			draw_colored_polygon(
				[
					icon_rect.position + Vector2(44.0, 40.0),
					icon_rect.position + Vector2(82.0, 54.0),
					icon_rect.position + Vector2(72.0, 126.0),
					icon_rect.position + Vector2(58.0, 148.0),
					icon_rect.position + Vector2(48.0, 126.0)
				],
				Color(0.96, 0.93, 0.84, 0.96 * item_alpha)
			)
			draw_line(icon_rect.position + Vector2(60.0, 148.0), icon_rect.position + Vector2(60.0, 160.0), Color(energy.r, energy.g, energy.b, 0.95 * item_alpha), 4.0)
		"beacon":
			draw_rect(Rect2(icon_rect.position + Vector2(44.0, 48.0), Vector2(32.0, 74.0)), Color(0.92, 0.95, 0.98, 0.94 * item_alpha))
			draw_circle(icon_rect.position + Vector2(60.0, 40.0), 12.0, Color(energy.r, energy.g, energy.b, 0.92 * item_alpha))
			draw_arc(icon_rect.position + Vector2(60.0, 40.0), 28.0, -0.8, 3.94, 24, Color(energy.r, energy.g, energy.b, 0.58 * item_alpha), 3.0)
		_:
			draw_colored_polygon(
				[
					icon_rect.position + Vector2(60.0, 34.0),
					icon_rect.position + Vector2(92.0, 82.0),
					icon_rect.position + Vector2(60.0, 134.0),
					icon_rect.position + Vector2(28.0, 82.0)
				],
				Color(0.96, 0.93, 0.84, 0.96 * item_alpha)
			)

func _draw_reveal_progress_text(canvas_size: Vector2, alpha: float, metrics: Dictionary) -> void:
	var font := get_theme_font("font")
	if font == null:
		return
	var progress_text := "%d / %d" % [current_reveal_index + 1, maxi(1, sorted_rewards.size())]
	var font_size := int(metrics.get("progressFontSize", 18))
	var text_size := font.get_string_size(progress_text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size)
	var progress_y := float(metrics.get("progressY", canvas_size.y * 0.83))
	draw_string(font, Vector2((canvas_size.x - text_size.x) * 0.5, progress_y), progress_text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, Color(0.95, 0.96, 0.98, 0.92 * alpha))

func _draw_reveal_progress_bar(canvas_size: Vector2, alpha: float, metrics: Dictionary, phase: Dictionary) -> void:
	var bar_width := minf(float(metrics.get("cardWidth", 580.0)) * 0.72, canvas_size.x * 0.44)
	var bar_height := 8.0
	var progress_y := float(metrics.get("frontProgressY", float(metrics.get("progressY", canvas_size.y * 0.83)) - 34.0))
	var bar_rect := Rect2(Vector2((canvas_size.x - bar_width) * 0.5, progress_y), Vector2(bar_width, bar_height))
	var fill := clampf(float(phase.get("progressFill", 0.0)), 0.0, 1.0)
	draw_rect(bar_rect.grow(2.0), Color(0.02, 0.04, 0.07, 0.76 * alpha))
	draw_rect(bar_rect, Color(0.20, 0.25, 0.31, 0.72 * alpha))
	draw_rect(Rect2(bar_rect.position, Vector2(bar_rect.size.x * fill, bar_rect.size.y)), Color(0.94, 0.97, 1.0, 0.90 * alpha))
	if fill > 0.04:
		var head_x := bar_rect.position.x + bar_rect.size.x * fill
		draw_circle(Vector2(head_x, bar_rect.get_center().y), 8.0, Color(1.0, 1.0, 1.0, 0.26 * alpha))
		draw_circle(Vector2(head_x, bar_rect.get_center().y), 3.0, Color(1.0, 1.0, 1.0, 0.86 * alpha))

func _draw_lid_slot(rect: Rect2, accent: Color, glow_strength: float, open_amount: float, sealed: bool, alpha: float) -> void:
	var lid_texture: Texture2D = presentation.get("excavationLid", {}).get("texture", EXCAVATION_LID_TEXTURE)
	var modulate := Color(0.48 + accent.r * 0.18, 0.40 + accent.g * 0.14, 0.28 + accent.b * 0.10, 0.92 * alpha)
	var open_clamped := clampf(open_amount, 0.0, 1.0)
	draw_rect(rect, Color(0.06, 0.05, 0.04, 0.22 * alpha))
	draw_circle(rect.get_center(), rect.size.y * 0.32, Color(accent.r, accent.g, accent.b, glow_strength * 0.18 * alpha))
	if lid_texture != null:
		if open_clamped <= 0.02 or sealed:
			draw_texture_rect(lid_texture, rect, true, modulate)
		else:
			var half_width := rect.size.x * 0.50
			var gap := lerpf(0.0, 24.0, open_clamped)
			var left_rect := Rect2(rect.position + Vector2(-gap, 0.0), Vector2(half_width - 4.0, rect.size.y))
			var right_rect := Rect2(Vector2(rect.position.x + half_width + gap, rect.position.y), Vector2(half_width - 4.0, rect.size.y))
			draw_texture_rect(lid_texture, left_rect, true, modulate)
			draw_texture_rect(lid_texture, right_rect, true, modulate)
	else:
		draw_rect(rect, Color(0.34, 0.28, 0.18, 0.86 * alpha))
	draw_rect(Rect2(rect.position, Vector2(rect.size.x, 4.0)), Color(0.74, 0.63, 0.48, 0.38 * alpha))
	draw_rect(Rect2(rect.position + Vector2(0.0, rect.size.y - 4.0), Vector2(rect.size.x, 4.0)), Color(0.20, 0.16, 0.12, 0.28 * alpha))
	if glow_strength > 0.0:
		draw_rect(rect.grow(-10.0), Color(accent.r, accent.g, accent.b, glow_strength * 0.05 * alpha))

func _draw_overlay_headline(canvas_size: Vector2, title_text: String, subtitle_text: String, alpha: float) -> void:
	var font := get_theme_font("font")
	if font == null:
		return
	var safe_layout := RewardRevealOverlay.overlay_safe_layout_model(canvas_size)
	var title_font_size := _fit_font_size(font, title_text, canvas_size.x * 0.50, 28, 20)
	var subtitle_font_size := _fit_font_size(font, subtitle_text, canvas_size.x * 0.58, 16, 13)
	_draw_centered_text(font, Vector2(canvas_size.x * 0.50, float(safe_layout.get("headlineTitleY", canvas_size.y * 0.18))), title_text, title_font_size, Color(1.0, 1.0, 1.0, 0.96 * alpha))
	_draw_centered_text(font, Vector2(canvas_size.x * 0.50, float(safe_layout.get("headlineSubtitleY", canvas_size.y * 0.22))), subtitle_text, subtitle_font_size, Color(0.76, 0.82, 0.88, 0.90 * alpha))

func _draw_confirm_prompt(canvas_size: Vector2, alpha: float) -> void:
	var font := get_theme_font("font")
	if font == null:
		return
	var safe_layout := RewardRevealOverlay.overlay_safe_layout_model(canvas_size)
	var pulse := clampf(0.62 + (0.38 * sin(confirm_pulse * 4.4)), 0.35, 1.0) * alpha
	var prompt := _confirm_prompt_text()
	var font_size := _fit_font_size(font, prompt, canvas_size.x * 0.60, 16, 13)
	_draw_centered_text(font, Vector2(canvas_size.x * 0.50, float(safe_layout.get("confirmPromptY", canvas_size.y * 0.90))), prompt, font_size, Color(0.98, 0.94, 0.82, pulse))

func _draw_centered_text(font: Font, center: Vector2, text: String, font_size: int, color: Color) -> void:
	var text_size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size)
	draw_string(font, Vector2(center.x - (text_size.x * 0.5), center.y), text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, color)

func _fit_font_size(font: Font, text: String, max_width: float, start_size: int, min_size: int) -> int:
	var font_size := start_size
	while font_size > min_size and font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size).x > max_width:
		font_size -= 1
	return maxi(font_size, min_size)

func _local_source_lid_rect(source_lid_global_rect: Rect2, canvas_size: Vector2) -> Rect2:
	if source_lid_global_rect.size.x > 1.0 and source_lid_global_rect.size.y > 1.0:
		return Rect2(source_lid_global_rect.position - global_position, source_lid_global_rect.size)
	return RewardRevealOverlay._fallback_source_lid_rect(canvas_size)

func _center_lid_rect(canvas_size: Vector2) -> Rect2:
	return RewardRevealOverlay.center_lid_layout_model(canvas_size).get("closedLidRect", Rect2())

static func _center_lid_rect_for_canvas(canvas_size: Vector2) -> Rect2:
	return RewardRevealOverlay.center_lid_layout_model(canvas_size).get("closedLidRect", Rect2())

static func _fallback_source_lid_rect(canvas_size: Vector2) -> Rect2:
	var fallback_size := Vector2(96.0, 60.0)
	return Rect2((canvas_size * 0.5) - (fallback_size * 0.5), fallback_size)

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
	var focus_max_radius := RewardRevealOverlay.safe_radius_for_center(canvas_size, focus_center, safe_margin)
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
	var aspect_ratio := RewardRevealOverlay._excavation_lid_aspect_ratio()
	var safe_layout := RewardRevealOverlay.overlay_safe_layout_model(canvas_size)
	var focus_center: Vector2 = safe_layout.get("focusCenter", canvas_size * 0.5)
	var safe_margin := float(safe_layout.get("safeMargin", 24.0))
	var focus_radius := float(safe_layout.get("focusMaxRadius", RewardRevealOverlay.safe_radius_for_center(canvas_size, focus_center, safe_margin)))
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

func _draw_mined_lid_charge(canvas_size: Vector2, rect: Rect2, preview: Dictionary, motion: Dictionary, accent: Color, progress: float, alpha: float) -> void:
	var lid_texture: Texture2D = presentation.get("excavationLid", {}).get("texture", EXCAVATION_LID_TEXTURE)
	var wrap := float(motion.get("lightWrap", 0.0))
	var front_flash := float(motion.get("frontTileFlashAlpha", 0.0))
	var density := float(preview.get("sparkDensity", 1.0))
	var center := rect.get_center()
	var safe_layout := RewardRevealOverlay.overlay_safe_layout_model(canvas_size)
	var safe_margin := float(safe_layout.get("safeMargin", 24.0))
	var max_effect_radius := RewardRevealOverlay.safe_radius_for_center(canvas_size, center, safe_margin)
	var glow_radius := minf(max_effect_radius, maxf(rect.size.x, rect.size.y) * lerpf(0.58, 1.16, wrap))
	draw_circle(center, glow_radius, Color(accent.r, accent.g, accent.b, (0.08 + wrap * 0.22) * alpha))
	draw_circle(center, glow_radius * 0.62, Color(1.0, 0.94, 0.70, (0.05 + wrap * 0.18) * alpha))
	if lid_texture != null:
		draw_texture_rect(lid_texture, rect, true, Color(0.74 + accent.r * 0.08, 0.66 + accent.g * 0.08, 0.48 + accent.b * 0.08, 0.98 * alpha))
	else:
		draw_rect(rect, Color(0.42, 0.31, 0.18, 0.92 * alpha))
	var light_alpha := clampf(0.18 + wrap * 0.68, 0.0, 0.92) * alpha
	draw_rect(rect.grow(-8.0), Color(1.0, 0.93, 0.62, light_alpha * 0.20))
	draw_arc(center, minf(max_effect_radius * 0.92, maxf(rect.size.x, rect.size.y) * 0.52), -PI * 0.08, TAU * clampf(0.12 + wrap * 0.92, 0.0, 1.0), 40, Color(1.0, 0.93, 0.70, light_alpha), 4.0)
	draw_arc(center, minf(max_effect_radius * 0.72, maxf(rect.size.x, rect.size.y) * 0.38), PI * 0.62, PI * 0.62 + TAU * clampf(wrap, 0.0, 1.0), 36, Color(accent.r, accent.g, accent.b, light_alpha * 0.74), 3.0)
	var spark_count := int(round(12.0 * density))
	var spark_rate := float(motion.get("sparkRate", 8.0))
	for index in range(spark_count):
		var phase := timer * spark_rate + float(index) * 1.37
		var sparkle := clampf(sin(phase) * 0.5 + 0.5, 0.0, 1.0)
		var angle := (TAU / maxf(1.0, float(spark_count))) * float(index) + timer * (0.7 + wrap)
		var orbit := minf(max_effect_radius * 0.84, maxf(rect.size.x, rect.size.y) * lerpf(0.42, 0.70, sparkle))
		var pos := center + Vector2(cos(angle), sin(angle) * 0.62) * orbit
		draw_circle(pos, lerpf(1.4, 4.4, sparkle) * (0.75 + wrap * 0.5), Color(1.0, 0.95, 0.72, (0.18 + sparkle * 0.45 + wrap * 0.18) * alpha))
	if lid_texture != null:
		draw_texture_rect(lid_texture, rect, true, Color(1.0, 0.98, 0.86, (0.24 + front_flash * 0.72) * alpha))
	else:
		draw_rect(rect, Color(1.0, 0.96, 0.76, (0.18 + front_flash * 0.52) * alpha))
	draw_rect(rect.grow(-6.0), Color(1.0, 1.0, 1.0, front_flash * 0.24 * alpha))
	draw_rect(Rect2(rect.position, Vector2(rect.size.x, 5.0)), Color(1.0, 0.96, 0.78, (0.34 + front_flash * 0.42) * alpha))
	draw_rect(Rect2(rect.position + Vector2(0.0, rect.size.y - 5.0), Vector2(rect.size.x, 5.0)), Color(0.56, 0.42, 0.22, 0.28 * alpha))
	if bool(motion.get("burstReady", false)):
		draw_circle(center, glow_radius * 0.78, Color(1.0, 0.96, 0.78, 0.36 * alpha))

func _draw_count_burst_animation(canvas_size: Vector2, burst: Dictionary, animation: Dictionary, accent: Color, alpha: float) -> void:
	var closed_lid_rect: Rect2 = animation.get("closedLidRect", Rect2())
	var lid_texture: Texture2D = presentation.get("excavationLid", {}).get("texture", EXCAVATION_LID_TEXTURE)
	var center := closed_lid_rect.get_center()
	var safe_layout := RewardRevealOverlay.overlay_safe_layout_model(canvas_size)
	var safe_margin := float(safe_layout.get("safeMargin", 24.0))
	var max_effect_radius := RewardRevealOverlay.safe_radius_for_center(canvas_size, center, safe_margin)
	var orb_reveal_alpha := float(animation.get("orbRevealAlpha", 0.0))
	var flash_alpha := float(animation.get("flashAlpha", 0.0)) * alpha
	var pop_progress := float(animation.get("capPopProgress", 0.0))
	var cap_alpha := float(animation.get("capAlpha", 1.0)) * alpha
	var cap_offset: Vector2 = animation.get("lidCapOffset", Vector2.ZERO)
	var cap_rotation := deg_to_rad(float(animation.get("lidCapRotationDegrees", 0.0)))
	var impact_progress := float(animation.get("impactRingProgress", 0.0))
	draw_circle(center, minf(max_effect_radius * 0.78, closed_lid_rect.size.x * 0.62), Color(accent.r, accent.g, accent.b, (0.10 + flash_alpha * 0.28) * alpha))
	draw_circle(center, minf(max_effect_radius * 0.54, closed_lid_rect.size.x * 0.40), Color(1.0, 0.95, 0.78, (0.04 + flash_alpha * 0.20) * alpha))
	if flash_alpha > 0.0:
		draw_rect(Rect2(Vector2.ZERO, canvas_size), Color(1.0, 0.95, 0.78, flash_alpha * 0.08))
	draw_rect(Rect2(Vector2(closed_lid_rect.position.x, closed_lid_rect.position.y + closed_lid_rect.size.y - 4.0), Vector2(closed_lid_rect.size.x, 4.0)), Color(0.24, 0.19, 0.12, 0.42 * alpha))
	for wave in range(3):
		var wave_t := clampf(impact_progress - float(wave) * 0.14, 0.0, 1.0)
		if wave_t <= 0.0:
			continue
		var wave_radius := minf(max_effect_radius * (0.66 + float(wave) * 0.08), lerpf(closed_lid_rect.size.y * 0.30, closed_lid_rect.size.x * (0.40 + float(wave) * 0.10), wave_t))
		draw_arc(center, wave_radius, 0.0, TAU, 70, Color(1.0, 0.88, 0.58, (1.0 - wave_t) * 0.28 * alpha), maxf(2.0, 6.0 - float(wave)))
	for crack in range(10):
		var angle := -PI + (TAU / 10.0) * float(crack)
		var start := center + Vector2(cos(angle), sin(angle) * 0.34) * closed_lid_rect.size.y * 0.18
		var end := center + Vector2(cos(angle), sin(angle) * 0.50) * lerpf(closed_lid_rect.size.y * 0.38, closed_lid_rect.size.x * 0.36, pop_progress)
		draw_line(start, end, Color(1.0, 0.88, 0.62, (0.14 + pop_progress * 0.26) * alpha), 2.0)
	var fragment_count := int(animation.get("fragmentCount", 18))
	for index in range(fragment_count):
		var angle := (-PI * 0.92) + ((PI * 1.84) / maxf(1.0, float(fragment_count - 1))) * float(index)
		var seed := float((index * 37) % 11) / 10.0
		var distance := lerpf(closed_lid_rect.size.y * 0.24, closed_lid_rect.size.x * (0.24 + seed * 0.12), pop_progress)
		var fragment_center := center + Vector2(cos(angle), sin(angle) * 0.72 - 0.35) * distance
		var fragment_size := lerpf(3.0, 9.0, 1.0 - seed * 0.35)
		draw_line(center, fragment_center, Color(1.0, 0.86, 0.58, (1.0 - pop_progress * 0.38) * 0.18 * alpha), 1.4)
		draw_rect(Rect2(fragment_center - Vector2(fragment_size * 0.5, fragment_size * 0.25), Vector2(fragment_size, fragment_size * 0.5)), Color(0.94, 0.78, 0.48, (1.0 - pop_progress * 0.50) * 0.72 * alpha))
	var cap_center := center + cap_offset
	if lid_texture != null:
		draw_set_transform(cap_center, cap_rotation, Vector2.ONE)
		draw_texture_rect(lid_texture, Rect2(closed_lid_rect.size * -0.5, closed_lid_rect.size), true, Color(1.0, 0.92, 0.70, cap_alpha))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	else:
		draw_set_transform(cap_center, cap_rotation, Vector2.ONE)
		draw_rect(Rect2(closed_lid_rect.size * -0.5, closed_lid_rect.size), Color(0.72, 0.54, 0.30, cap_alpha))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	var font := get_theme_font("font")
	var token_count := int(burst.get("rewardTokenCount", 1))
	var visual_token_count := int(burst.get("visualTokenCount", clampi(token_count, 1, 5)))
	var target_rects := _quantity_slot_rects(visual_token_count, canvas_size, Vector2(68.0, 68.0), center.y - closed_lid_rect.size.y * 0.92)
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
		draw_line(seam_center, orb_center, Color(1.0, 0.92, 0.70, trail_alpha), 2.0)
		draw_circle(orb_center, orb_radius * 1.5, Color(accent.r, accent.g, accent.b, (0.08 + orb_reveal_alpha * 0.22) * alpha))
		draw_circle(orb_center, orb_radius, Color(1.0, 0.86, 0.38, (0.12 + orb_reveal_alpha * 0.82) * alpha))
		draw_circle(orb_center + Vector2(-orb_radius * 0.28, -orb_radius * 0.34), orb_radius * 0.30, Color(1.0, 0.98, 0.82, (0.28 + orb_reveal_alpha * 0.62) * alpha))
	if font != null:
		var count_text := str(burst.get("burstText", "x%d" % token_count))
		var font_size := 44
		var text_size := font.get_string_size(count_text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size)
		var text_alpha := clampf((orb_reveal_alpha - 0.32) / 0.40, 0.0, 1.0) * alpha
		draw_string(font, Vector2(center.x - text_size.x * 0.5, center.y + 112.0), count_text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, Color(1.0, 0.95, 0.72, text_alpha))

func _draw_queue_card_marker(rect: Rect2, accent: Color, glow_strength: float, open_amount: float, sealed: bool, alpha: float) -> void:
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
	draw_style_box(marker, rect)
	var center := rect.get_center()
	if sealed:
		draw_circle(center, rect.size.y * 0.22, Color(1.0, 1.0, 1.0, (0.14 + glow_strength * 0.16) * alpha))
	else:
		draw_circle(center, rect.size.y * 0.24, Color(accent.r, accent.g, accent.b, 0.34 * alpha))
	draw_rect(Rect2(rect.position + Vector2(8.0, rect.size.y * 0.50), Vector2((rect.size.x - 16.0) * clampf(open_amount, 0.0, 1.0), 3.0)), Color(accent.r, accent.g, accent.b, 0.72 * alpha))

func _draw_sealed_reward_card(card_rect: Rect2, accent: Color, alpha: float, reveal_progress: float, phase: Dictionary) -> void:
	var white_alpha := float(phase.get("whiteFlashAlpha", 0.6)) * alpha
	var pulse := float(phase.get("anticipationPulse", reveal_progress))
	var breathing_radius := 1.0 + sin(timer * lerpf(5.6, 9.2, pulse)) * 0.035
	var silhouette_radius := minf(card_rect.size.x, card_rect.size.y) * 0.24 * breathing_radius
	draw_rect(card_rect.grow(-16.0), Color(1.0, 1.0, 1.0, white_alpha * 0.16))
	draw_circle(card_rect.get_center(), minf(card_rect.size.x, card_rect.size.y) * 0.34, Color(1.0, 1.0, 1.0, white_alpha * 0.24))
	draw_circle(card_rect.get_center(), silhouette_radius, Color(accent.r, accent.g, accent.b, white_alpha * 0.26))
	draw_arc(card_rect.get_center(), silhouette_radius * 1.28, timer * 1.7, timer * 1.7 + PI * 1.18, 34, Color(1.0, 1.0, 1.0, white_alpha * 0.34), 2.4)
	draw_arc(card_rect.get_center(), silhouette_radius * 1.52, -timer * 1.2, -timer * 1.2 + PI * 0.82, 28, Color(1.0, 0.95, 0.78, white_alpha * 0.22), 1.8)
	var stripe_y := card_rect.position.y + card_rect.size.y * 0.50
	draw_line(Vector2(card_rect.position.x + 36.0, stripe_y), Vector2(card_rect.end.x - 36.0, stripe_y), Color(1.0, 1.0, 1.0, white_alpha * 0.72), 5.0)
	for index in range(10):
		var x := lerpf(card_rect.position.x + 54.0, card_rect.end.x - 54.0, float(index) / 9.0)
		var sparkle := clampf(sin(timer * 14.0 + float(index)) * 0.5 + 0.5, 0.0, 1.0)
		draw_circle(Vector2(x, stripe_y - 28.0 + sin(timer * 9.0 + float(index)) * 18.0), lerpf(1.6, 4.2, sparkle), Color(1.0, 1.0, 1.0, white_alpha * sparkle))

func _draw_rarity_burst(canvas_size: Vector2, card_rect: Rect2, accent: Color, alpha: float, phase: Dictionary, profile: Dictionary) -> void:
	var burst_progress := float(phase.get("burstProgress", 1.0))
	var strength := float(phase.get("burstStrength", 0.3))
	var spark_count := int(profile.get("sparkCount", 8))
	var beam_count := int(profile.get("beamCount", 8))
	var shockwave_count := int(profile.get("shockwaveCount", 1))
	var ember_count := int(profile.get("emberCount", spark_count / 2))
	var screen_wash_alpha := float(profile.get("screenWashAlpha", 0.0))
	var flash_alpha := float(profile.get("flashAlpha", 0.6))
	var center := card_rect.get_center()
	var safe_layout := RewardRevealOverlay.overlay_safe_layout_model(canvas_size)
	var safe_margin := float(safe_layout.get("safeMargin", 24.0))
	var max_effect_radius := RewardRevealOverlay.safe_radius_for_center(canvas_size, center, safe_margin)
	var burst_alpha := (1.0 - burst_progress * 0.42) * alpha * strength
	if screen_wash_alpha > 0.0:
		draw_rect(Rect2(Vector2.ZERO, canvas_size), Color(accent.r, accent.g, accent.b, burst_alpha * screen_wash_alpha))
		draw_rect(Rect2(Vector2.ZERO, canvas_size), Color(1.0, 0.96, 0.84, burst_alpha * flash_alpha * 0.10))
	for wave in range(shockwave_count):
		var wave_t := clampf(burst_progress + float(wave) * 0.08, 0.0, 1.0)
		var wave_radius := minf(max_effect_radius * (0.78 + float(wave) * 0.06), lerpf(card_rect.size.y * (0.24 + wave * 0.03), card_rect.size.x * (0.66 + float(wave) * 0.08), wave_t))
		var wave_width := maxf(2.0, 8.0 - float(wave) * 1.2)
		draw_arc(center, wave_radius, 0.0, TAU, 88, Color(1.0, 0.95, 0.84, burst_alpha * (0.52 - float(wave) * 0.08)), wave_width)
	for ring in range(int(profile.get("ringCount", 1))):
		var radius := minf(max_effect_radius * (0.72 + float(ring) * 0.08), lerpf(card_rect.size.y * (0.34 + ring * 0.04), card_rect.size.x * (0.60 + float(ring) * 0.12), burst_progress))
		draw_arc(center, radius, 0.0, TAU, 72, Color(accent.r, accent.g, accent.b, burst_alpha * (0.90 - float(ring) * 0.12)), maxf(2.0, 6.0 - float(ring) * 0.8))
	for index in range(beam_count):
		var angle := (TAU / maxf(1.0, float(beam_count))) * float(index) + burst_progress * 0.12
		var inner := card_rect.size.y * 0.22
		var outer := minf(max_effect_radius * 0.94, card_rect.size.x * (0.42 + strength * 0.24 + sin(float(index)) * 0.04))
		var start := center + Vector2(cos(angle), sin(angle) * 0.70) * inner
		var end := center + Vector2(cos(angle), sin(angle) * 0.70) * lerpf(inner, outer, burst_progress)
		draw_line(start, end, Color(1.0, 0.96, 0.84, burst_alpha * 0.54), 4.0)
		draw_line(start, end, Color(accent.r, accent.g, accent.b, burst_alpha * 0.82), 2.0)
	for index in range(spark_count):
		var angle := (TAU / maxf(1.0, float(spark_count))) * float(index) + burst_progress * 0.40
		var radius := minf(max_effect_radius * 0.72, lerpf(card_rect.size.x * 0.18, card_rect.size.x * (0.44 + strength * 0.12), burst_progress))
		var spark_center := center + Vector2(cos(angle), sin(angle) * 0.72) * radius
		var spark_radius := lerpf(2.0, 5.8, 1.0 - burst_progress * 0.32)
		draw_circle(spark_center, spark_radius, Color(accent.r, accent.g, accent.b, burst_alpha * 0.56))
	for index in range(ember_count):
		var ember_angle := (TAU / maxf(1.0, float(ember_count))) * float(index) + burst_progress * 0.75
		var ember_radius := minf(max_effect_radius * 0.56, lerpf(card_rect.size.x * 0.10, card_rect.size.x * (0.34 + strength * 0.08), burst_progress))
		var ember_center := center + Vector2(cos(ember_angle), sin(ember_angle) * 0.62) * ember_radius
		draw_circle(ember_center, lerpf(1.2, 3.6, burst_progress), Color(1.0, 0.92, 0.68, burst_alpha * 0.42))

func _draw_preview_excavation_chamber(rect: Rect2, preview: Dictionary, accent: Color, progress: float, alpha: float) -> void:
	var lid_texture: Texture2D = presentation.get("excavationLid", {}).get("texture", EXCAVATION_LID_TEXTURE)
	var glow_alpha := lerpf(0.18, 0.42, progress) * alpha
	var pulse_phase := timer * lerpf(3.2, 6.8, progress)
	draw_circle(rect.get_center(), rect.size.x * 0.34, Color(accent.r, accent.g, accent.b, glow_alpha * 0.30))
	draw_circle(rect.get_center() + Vector2(0.0, -12.0), rect.size.x * 0.22, Color(1.0, 0.92, 0.72, glow_alpha * 0.12))
	if lid_texture != null:
		draw_texture_rect(lid_texture, rect, true, Color(0.62 + accent.r * 0.12, 0.54 + accent.g * 0.10, 0.42 + accent.b * 0.08, 0.96 * alpha))
		draw_texture_rect(lid_texture, rect.grow(-8.0), true, Color(accent.r, accent.g, accent.b, 0.10 * alpha))
	draw_rect(Rect2(rect.position + Vector2(0.0, 6.0), Vector2(rect.size.x, 4.0)), Color(0.94, 0.82, 0.58, 0.34 * alpha))
	draw_rect(Rect2(rect.position + Vector2(0.0, rect.size.y - 8.0), Vector2(rect.size.x, 4.0)), Color(0.28, 0.21, 0.14, 0.32 * alpha))
	var hotspot_count := int(preview.get("hotspotCount", 2))
	var anchors: Array = preview.get("hotspotAnchors", [])
	for index in range(mini(hotspot_count, anchors.size())):
		var anchor := float(anchors[index])
		var hotspot_center := Vector2(lerpf(rect.position.x + 56.0, rect.end.x - 56.0, anchor), rect.position.y + rect.size.y * 0.52)
		var beat := clampf(sin(pulse_phase + (float(index) * 0.92)) * 0.5 + 0.5, 0.0, 1.0)
		var radius := lerpf(18.0, 34.0, beat)
		draw_circle(hotspot_center, radius, Color(accent.r, accent.g, accent.b, (0.12 + beat * 0.18) * alpha))
		draw_circle(hotspot_center, radius * 0.62, Color(1.0, 0.88, 0.54, (0.18 + beat * 0.16) * alpha))
		var crack_height := lerpf(18.0, 46.0, clampf(progress + beat * 0.25, 0.0, 1.0))
		draw_line(hotspot_center + Vector2(0.0, -6.0), hotspot_center + Vector2(0.0, -crack_height), Color(1.0, 0.90, 0.74, (0.18 + beat * 0.24) * alpha), 2.0)
		draw_line(hotspot_center + Vector2(-4.0, -12.0), hotspot_center + Vector2(-18.0, -28.0), Color(1.0, 0.86, 0.66, (0.10 + beat * 0.16) * alpha), 1.6)
		draw_line(hotspot_center + Vector2(4.0, -12.0), hotspot_center + Vector2(18.0, -28.0), Color(1.0, 0.86, 0.66, (0.10 + beat * 0.16) * alpha), 1.6)

func _draw_reveal_stage_backdrop(canvas_size: Vector2, card_rect: Rect2, accent: Color, alpha: float, reveal_progress: float, profile: Dictionary) -> void:
	if bool(profile.get("showBackdropLid", false)):
		_draw_lid_slot(card_rect.grow(18.0), accent, reveal_progress, reveal_progress, true, alpha)
	var aura_strength := float(profile.get("auraStrength", 0.16))
	var ring_count := int(profile.get("ringCount", 1))
	var center := card_rect.get_center() + Vector2(0.0, -12.0)
	var safe_layout := RewardRevealOverlay.overlay_safe_layout_model(canvas_size)
	var safe_margin := float(safe_layout.get("safeMargin", 24.0))
	var max_effect_radius := RewardRevealOverlay.safe_radius_for_center(canvas_size, center, safe_margin)
	for ring in range(ring_count):
		var radius := minf(max_effect_radius * (0.74 + float(ring) * 0.06), lerpf(card_rect.size.x * (0.38 + ring * 0.06), card_rect.size.x * (0.48 + ring * 0.08), reveal_progress))
		draw_circle(center, radius, Color(accent.r, accent.g, accent.b, aura_strength * (0.28 - ring * 0.05) * alpha))
	var pedestal_rect := Rect2(Vector2(card_rect.position.x + 28.0, card_rect.end.y - 6.0), Vector2(card_rect.size.x - 56.0, 22.0))
	draw_rect(pedestal_rect, Color(0.08, 0.10, 0.12, 0.72 * alpha))
	draw_rect(Rect2(pedestal_rect.position, Vector2(pedestal_rect.size.x, 3.0)), Color(accent.r, accent.g, accent.b, 0.34 * alpha))
	var spark_count := int(profile.get("sparkCount", 8))
	for index in range(spark_count):
		var angle := (TAU / maxf(1.0, float(spark_count))) * float(index)
		var radius := minf(max_effect_radius * 0.70, lerpf(card_rect.size.x * 0.34, card_rect.size.x * 0.44, reveal_progress))
		var spark_center := card_rect.get_center() + Vector2(cos(angle), sin(angle) * 0.72) * radius
		var spark_alpha := aura_strength * (0.24 + 0.16 * sin(confirm_pulse * 3.2 + float(index))) * alpha
		draw_circle(spark_center, lerpf(1.6, 3.2, reveal_progress), Color(accent.r, accent.g, accent.b, spark_alpha))

func _quantity_slot_rects(count: int, canvas_size: Vector2, slot_size: Vector2, center_y: float) -> Array:
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

func _queue_strip_rects(count: int, canvas_size: Vector2) -> Array:
	return _quantity_slot_rects(count, canvas_size, Vector2(116.0, 74.0), canvas_size.y * 0.31)

func _count_tease_thresholds(count: int) -> Array:
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

func _spawn_intro_particles() -> void:
	var canvas_size := _current_canvas_size()
	for _index in range(18):
		var base_x := randf_range(canvas_size.x * 0.24, canvas_size.x * 0.76)
		var base_y := randf_range(canvas_size.y * 0.18, canvas_size.y * 0.82)
		particles.append({
			"pos": Vector2(base_x, base_y),
			"vel": Vector2(randf_range(-24.0, 24.0), randf_range(-30.0, -8.0)),
			"size": randf_range(1.8, 4.8),
			"life": randf_range(0.8, 1.5),
			"alpha": randf_range(0.24, 0.86)
		})

func _update_particles(delta: float) -> void:
	var next_particles: Array = []
	for particle in particles:
		particle["pos"] = particle.get("pos", Vector2.ZERO) + (particle.get("vel", Vector2.ZERO) * delta)
		particle["life"] = float(particle.get("life", 0.0)) - delta
		particle["alpha"] = maxf(0.0, float(particle.get("alpha", 0.0)) - (delta * 0.26))
		if float(particle.get("life", 0.0)) > 0.0:
			next_particles.append(particle)
	particles = next_particles
	if particles.size() < 12 and is_revealing:
		_spawn_intro_particles()

func _current_canvas_size() -> Vector2:
	if size.x > 1.0 and size.y > 1.0:
		return size
	return get_viewport_rect().size

func _finish_reveal() -> void:
	is_revealing = false
	visible = false
	readable = false
	timer = 0.0
	confirm_pulse = 0.0
	particles.clear()
	callback = Callable()
	step_callback = Callable()
	queue_redraw()
	call_deferred("_emit_ceremony_finished")

func _emit_ceremony_finished() -> void:
	ceremony_finished.emit("tray_review")

func _current_reward() -> Dictionary:
	if current_reveal_index < 0 or current_reveal_index >= sorted_rewards.size():
		return {}
	return sorted_rewards[current_reveal_index] if sorted_rewards[current_reveal_index] is Dictionary else {}

func _current_reward_rarity() -> String:
	return str(_current_reward().get("rarity", "common")).to_lower()

func _current_highlight_color() -> Color:
	if current_step == "reveal_queue":
		return RewardRevealOverlay._rarity_accent(_current_reward_rarity())
	return Color(0.92, 0.74, 0.36, 1.0)

func _count_tease_title() -> String:
	return TextCatalogScript.t("reward_reveal.count_tease_title")

func _count_tease_subtitle() -> String:
	match str(presentation.get("quantityTeaseBand", "small")):
		"standard":
			return TextCatalogScript.t("reward_reveal.count_tease_subtitle.standard")
		"jackpot":
			return TextCatalogScript.t("reward_reveal.count_tease_subtitle.jackpot")
		_:
			return TextCatalogScript.t("reward_reveal.count_tease_subtitle.small")

func _count_lock_title(reward_count: int) -> String:
	return TextCatalogScript.t("reward_reveal.count_lock.title", [reward_count])

func _count_lock_subtitle() -> String:
	return TextCatalogScript.t("reward_reveal.count_lock.subtitle")

func _reveal_queue_title() -> String:
	return TextCatalogScript.t("reward_reveal.queue.title")

func _reveal_queue_subtitle() -> String:
	return TextCatalogScript.t("reward_reveal.queue.subtitle")

func _confirm_prompt_text() -> String:
	if current_step == "reveal_queue" and current_reveal_index + 1 >= sorted_rewards.size():
		return TextCatalogScript.t("reward_reveal.confirm.return_tray")
	return TextCatalogScript.t("reward_reveal.confirm.continue")

static func _hero_reward_index(reward_list: Array) -> int:
	if reward_list.is_empty():
		return -1
	var best_index := 0
	var best_score := -1
	for index in range(reward_list.size()):
		var reward: Dictionary = reward_list[index] if reward_list[index] is Dictionary else {}
		var rarity := str(reward.get("rarity", "common")).to_lower()
		var score := (RewardRevealOverlay._rarity_rank(rarity) * 100) - index
		if score > best_score:
			best_score = score
			best_index = index
	return best_index

static func _payload_dictionary(reward: Dictionary) -> Dictionary:
	var payload = reward.get("payload", {})
	return payload if payload is Dictionary else {}

static func _sorted_reward_dictionaries(reward_list: Array) -> Array:
	var sorted_rewards: Array = []
	for reward_entry in reward_list:
		var reward: Dictionary = reward_entry if reward_entry is Dictionary else {}
		var insert_at := sorted_rewards.size()
		for index in range(sorted_rewards.size()):
			var candidate: Dictionary = sorted_rewards[index]
			if RewardRevealOverlay._rarity_rank(str(reward.get("rarity", "common")).to_lower()) < RewardRevealOverlay._rarity_rank(str(candidate.get("rarity", "common")).to_lower()):
				insert_at = index
				break
		sorted_rewards.insert(insert_at, reward)
	return sorted_rewards

static func _reward_display_name(reward: Dictionary) -> String:
	return TextCatalogScript.reward_name(reward)

static func _reward_rarity_label(rarity: String) -> String:
	var label := TextCatalogScript.t("rarity.%s" % rarity)
	return label if not label.begins_with("rarity.") else rarity.capitalize()

static func _reward_item_type_label(payload: Dictionary) -> String:
	var item_type := str(payload.get("item_type", "artifact")).to_lower()
	var label := TextCatalogScript.t("item.%s" % item_type)
	return label if not label.begins_with("item.") else item_type.capitalize()

static func _reward_rarity_vfx_tier(reward: Dictionary) -> String:
	return str(reward.get("rarity", "common")).to_lower()

static func _quantity_tease_band(reward_count: int) -> String:
	if reward_count <= 2:
		return "small"
	if reward_count == 3:
		return "standard"
	return "jackpot"

static func count_tease_preview_model(reward_count: int) -> Dictionary:
	match RewardRevealOverlay._quantity_tease_band(reward_count):
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
	var eased_progress := RewardRevealOverlay._ease_out(clamped_progress)
	var band := RewardRevealOverlay._quantity_tease_band(reward_count)
	var base_spark_rate := 7.0
	if band == "standard":
		base_spark_rate = 8.8
	elif band == "jackpot":
		base_spark_rate = 10.4
	var safe_source := source_rect
	if safe_source.size.x <= 1.0 or safe_source.size.y <= 1.0:
		safe_source = RewardRevealOverlay._fallback_source_lid_rect(canvas_size)
	var final_rect := RewardRevealOverlay._center_lid_rect_for_canvas(canvas_size)
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
	var layout := RewardRevealOverlay.center_lid_layout_model(canvas_size)
	var closed_lid_rect: Rect2 = layout.get("closedLidRect", Rect2())
	var clamped_progress := clampf(progress, 0.0, 1.0)
	var compression_progress := RewardRevealOverlay._ease_out(clampf(clamped_progress / 0.24, 0.0, 1.0))
	var pop_progress := RewardRevealOverlay._ease_out(RewardRevealOverlay._segment(clamped_progress, 0.18, 0.62))
	var orb_reveal_alpha := RewardRevealOverlay._ease_out(clampf((clamped_progress - 0.30) / 0.58, 0.0, 1.0))
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
		"impactRingProgress": RewardRevealOverlay._ease_out(clampf((clamped_progress - 0.18) / 0.42, 0.0, 1.0)),
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
		"quantityBand": RewardRevealOverlay._quantity_tease_band(actual_count),
		"burstText": "x%d" % actual_count,
		"tokenStyle": "light_ore_count"
	}

static func card_reveal_phase_model(rarity: String, progress: float, identity_readable: bool, queue_position: int) -> Dictionary:
	var clamped_progress := clampf(progress, 0.0, 1.0)
	var profile := RewardRevealOverlay.reveal_visual_profile(rarity)
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

static func reveal_visual_profile(rarity: String) -> Dictionary:
	match rarity:
		"mythic":
			return {"showBackdropLid": false, "auraStrength": 0.72, "sparkCount": 84, "frameGlowAlpha": 1.00, "borderWidth": 3, "ringCount": 5, "burstStrength": 1.48, "shakeMagnitude": 8.4, "flashAlpha": 1.00, "rarityBurstTier": "mythic", "beamCount": 30, "shockwaveCount": 5, "screenWashAlpha": 0.36, "emberCount": 46}
		"legendary":
			return {"showBackdropLid": false, "auraStrength": 0.58, "sparkCount": 62, "frameGlowAlpha": 0.96, "borderWidth": 3, "ringCount": 4, "burstStrength": 1.22, "shakeMagnitude": 6.4, "flashAlpha": 0.94, "rarityBurstTier": "legendary", "beamCount": 24, "shockwaveCount": 4, "screenWashAlpha": 0.26, "emberCount": 34}
		"epic":
			return {"showBackdropLid": false, "auraStrength": 0.42, "sparkCount": 44, "frameGlowAlpha": 0.82, "borderWidth": 2, "ringCount": 3, "burstStrength": 0.92, "shakeMagnitude": 4.9, "flashAlpha": 0.82, "rarityBurstTier": "epic", "beamCount": 18, "shockwaveCount": 3, "screenWashAlpha": 0.18, "emberCount": 24}
		"rare":
			return {"showBackdropLid": false, "auraStrength": 0.28, "sparkCount": 28, "frameGlowAlpha": 0.68, "borderWidth": 2, "ringCount": 2, "burstStrength": 0.68, "shakeMagnitude": 3.8, "flashAlpha": 0.68, "rarityBurstTier": "rare", "beamCount": 12, "shockwaveCount": 2, "screenWashAlpha": 0.12, "emberCount": 18}
		_:
			return {"showBackdropLid": false, "auraStrength": 0.18, "sparkCount": 18, "frameGlowAlpha": 0.52, "borderWidth": 1, "ringCount": 2, "burstStrength": 0.50, "shakeMagnitude": 2.8, "flashAlpha": 0.62, "rarityBurstTier": "common", "beamCount": 8, "shockwaveCount": 1, "screenWashAlpha": 0.06, "emberCount": 12}

static func reveal_queue_layout_policy() -> Dictionary:
	return {
		"backgroundCardListVisible": false,
		"frontProgressBarVisible": true,
		"progressTextVisible": true,
		"identityVisibleBeforeProgressComplete": false
	}

static func reward_card_layout_metrics(canvas_size: Vector2) -> Dictionary:
	var safe_layout := RewardRevealOverlay.overlay_safe_layout_model(canvas_size)
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
	var rarity_y := 56.0
	var name_y := 108.0
	var support_y := 158.0
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
		"rarityY": rarity_y,
		"nameY": name_y,
		"supportY": support_y,
		"frontProgressY": front_progress_y,
		"progressY": progress_y,
		"cardBottom": card_bottom,
		"rarityFontSize": 16,
		"nameFontSize": 28,
		"supportFontSize": 16,
		"progressFontSize": progress_font_size
	}

static func _rarity_rank(rarity: String) -> int:
	match rarity:
		"mythic":
			return 5
		"legendary":
			return 4
		"epic":
			return 3
		"rare":
			return 2
		"common":
			return 1
	return 0

static func _rarity_accent(rarity: String) -> Color:
	match rarity:
		"mythic":
			return Color(1.00, 0.46, 0.26, 1.0)
		"legendary":
			return Color(0.97, 0.80, 0.36, 1.0)
		"epic":
			return Color(0.78, 0.54, 1.00, 1.0)
		"rare":
			return Color(0.40, 0.74, 1.00, 1.0)
	return Color(0.82, 0.88, 0.94, 1.0)

static func _sealed_neutral_accent() -> Color:
	return Color(0.92, 0.96, 1.0, 1.0)

static func _sealed_visual_profile() -> Dictionary:
	return {
		"showBackdropLid": false,
		"auraStrength": 0.08,
		"sparkCount": 8,
		"frameGlowAlpha": 0.34,
		"borderWidth": 1,
		"ringCount": 1,
		"burstStrength": 0.0,
		"shakeMagnitude": 2.0,
		"flashAlpha": 0.72,
		"rarityBurstTier": "sealed"
	}

static func _excavation_lid_aspect_ratio() -> float:
	if EXCAVATION_LID_TEXTURE != null and EXCAVATION_LID_TEXTURE.get_height() > 0:
		var measured_ratio := float(EXCAVATION_LID_TEXTURE.get_width()) / float(EXCAVATION_LID_TEXTURE.get_height())
		if measured_ratio > 5.0:
			return measured_ratio
	return 7.5

static func _energy_accent(energy_type: String) -> Color:
	match energy_type:
		"red":
			return Color(0.95, 0.42, 0.35, 1.0)
		"blue":
			return Color(0.35, 0.72, 0.98, 1.0)
		"green":
			return Color(0.42, 0.82, 0.52, 1.0)
		"purple":
			return Color(0.71, 0.54, 0.96, 1.0)
	return Color(0.90, 0.74, 0.38, 1.0)

static func _segment(value: float, start: float, duration: float) -> float:
	if duration <= 0.0:
		return 1.0 if value >= start else 0.0
	return clampf((value - start) / duration, 0.0, 1.0)

static func _ease_out(value: float) -> float:
	return 1.0 - pow(1.0 - clampf(value, 0.0, 1.0), 3.0)
