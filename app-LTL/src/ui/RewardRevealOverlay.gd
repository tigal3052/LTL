# 계약:
# - Responsibility: render the mining-themed reward ceremony overlay, auto-link the lid/count beats, and gate later beats by confirmation.
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
const RewardRevealPresentationModelScript = preload("res://src/ui/reward_reveal/RewardRevealPresentationModel.gd")
const RewardRevealLayoutPolicyScript = preload("res://src/ui/reward_reveal/RewardRevealLayoutPolicy.gd")
const RewardRevealAnimationModelsScript = preload("res://src/ui/reward_reveal/RewardRevealAnimationModels.gd")
const RewardRevealCeremonyRendererScript = preload("res://src/ui/reward_reveal/RewardRevealCeremonyRenderer.gd")
const RewardRevealEffectRendererScript = preload("res://src/ui/reward_reveal/RewardRevealEffectRenderer.gd")
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
	return RewardRevealPresentationModelScript.reveal_timing_profile()

 # 실행: project reward ceremony presentation data for tests and runtime consumers.
static func build_presentation_model(reward_list: Array) -> Dictionary:
	return RewardRevealPresentationModelScript.build_presentation_model(reward_list)

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
		_complete_current_step_animation()

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
		_complete_current_step_animation()
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
		_complete_current_step_animation()

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

func _complete_current_step_animation() -> void:
	if _auto_advances_after_animation(current_step):
		_advance_step()
	else:
		_finish_current_step_animation()

func _auto_advances_after_animation(step: String) -> bool:
	return step == "count_tease"

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
	RewardRevealCeremonyRendererScript.draw_background_auras(self, canvas_size, alpha, _current_highlight_color())

func _draw_count_tease(canvas_size: Vector2, alpha: float) -> void:
	RewardRevealCeremonyRendererScript.draw_count_tease(self, presentation, timer, canvas_size, alpha, _current_step_duration(), sorted_rewards.size(), source_lid_rect, _count_tease_title(), _count_tease_subtitle())

func _draw_count_lock(canvas_size: Vector2, alpha: float) -> void:
	RewardRevealCeremonyRendererScript.draw_count_lock(self, presentation, timer, canvas_size, alpha, _current_step_duration(), sorted_rewards.size(), _count_lock_title(sorted_rewards.size()), _count_lock_subtitle())

func _draw_reveal_queue(canvas_size: Vector2, alpha: float) -> void:
	RewardRevealCeremonyRendererScript.draw_reveal_queue(self, presentation, timer, confirm_pulse, canvas_size, alpha, _current_step_duration(), _current_reward(), current_reveal_index, sorted_rewards.size(), readable, _reveal_queue_title(), _reveal_queue_subtitle())

func _draw_queue_progress(queue_strip_rects: Array, alpha: float) -> void:
	RewardRevealCeremonyRendererScript.draw_queue_progress(self, timer, _current_step_duration(), current_reveal_index, sorted_rewards, readable, queue_strip_rects, alpha)

func _draw_reward_panel(card_rect: Rect2, reward: Dictionary, accent: Color, energy: Color, alpha: float, reveal_progress: float, profile: Dictionary, metrics: Dictionary, phase: Dictionary) -> void:
	RewardRevealCeremonyRendererScript.draw_reward_panel(self, timer, card_rect, reward, accent, energy, alpha, reveal_progress, profile, metrics, phase)

func _draw_reward_icon(icon_rect: Rect2, payload: Dictionary, energy: Color, alpha: float, reveal_progress: float) -> void:
	RewardRevealCeremonyRendererScript.draw_reward_icon(self, icon_rect, payload, energy, alpha, reveal_progress)

func _draw_reveal_progress_text(canvas_size: Vector2, alpha: float, metrics: Dictionary) -> void:
	RewardRevealCeremonyRendererScript.draw_reveal_progress_text(self, canvas_size, alpha, metrics, current_reveal_index, sorted_rewards.size())

func _draw_reveal_progress_bar(canvas_size: Vector2, alpha: float, metrics: Dictionary, phase: Dictionary) -> void:
	RewardRevealCeremonyRendererScript.draw_reveal_progress_bar(self, canvas_size, alpha, metrics, phase)

func _draw_lid_slot(rect: Rect2, accent: Color, glow_strength: float, open_amount: float, sealed: bool, alpha: float) -> void:
	RewardRevealEffectRendererScript.draw_lid_slot(self, presentation, rect, accent, glow_strength, open_amount, sealed, alpha)

func _draw_overlay_headline(canvas_size: Vector2, title_text: String, subtitle_text: String, alpha: float) -> void:
	RewardRevealCeremonyRendererScript.draw_overlay_headline(self, canvas_size, title_text, subtitle_text, alpha)

func _draw_confirm_prompt(canvas_size: Vector2, alpha: float) -> void:
	RewardRevealCeremonyRendererScript.draw_confirm_prompt(self, canvas_size, alpha, confirm_pulse, _confirm_prompt_text())

func _draw_centered_text(font: Font, center: Vector2, text: String, font_size: int, color: Color) -> void:
	RewardRevealCeremonyRendererScript.draw_centered_text(self, font, center, text, font_size, color)

func _fit_font_size(font: Font, text: String, max_width: float, start_size: int, min_size: int) -> int:
	return RewardRevealCeremonyRendererScript.fit_font_size(font, text, max_width, start_size, min_size)

func _local_source_lid_rect(source_lid_global_rect: Rect2, canvas_size: Vector2) -> Rect2:
	if source_lid_global_rect.size.x > 1.0 and source_lid_global_rect.size.y > 1.0:
		return Rect2(source_lid_global_rect.position - global_position, source_lid_global_rect.size)
	return RewardRevealOverlay._fallback_source_lid_rect(canvas_size)

func _center_lid_rect(canvas_size: Vector2) -> Rect2:
	return RewardRevealOverlay.center_lid_layout_model(canvas_size).get("closedLidRect", Rect2())

static func _center_lid_rect_for_canvas(canvas_size: Vector2) -> Rect2:
	return RewardRevealLayoutPolicyScript.center_lid_rect_for_canvas(canvas_size)

static func _fallback_source_lid_rect(canvas_size: Vector2) -> Rect2:
	return RewardRevealLayoutPolicyScript.fallback_source_lid_rect(canvas_size)

static func safe_radius_for_center(canvas_size: Vector2, center: Vector2, margin: float = 24.0) -> float:
	return RewardRevealLayoutPolicyScript.safe_radius_for_center(canvas_size, center, margin)

static func overlay_safe_layout_model(canvas_size: Vector2) -> Dictionary:
	return RewardRevealLayoutPolicyScript.overlay_safe_layout_model(canvas_size)

static func center_lid_layout_model(canvas_size: Vector2) -> Dictionary:
	return RewardRevealLayoutPolicyScript.center_lid_layout_model(canvas_size)

func _draw_mined_lid_charge(canvas_size: Vector2, rect: Rect2, preview: Dictionary, motion: Dictionary, accent: Color, progress: float, alpha: float) -> void:
	RewardRevealEffectRendererScript.draw_mined_lid_charge(self, presentation, timer, canvas_size, rect, preview, motion, accent, progress, alpha)

func _draw_count_burst_animation(canvas_size: Vector2, burst: Dictionary, animation: Dictionary, accent: Color, alpha: float) -> void:
	RewardRevealEffectRendererScript.draw_count_burst_animation(self, presentation, canvas_size, burst, animation, accent, alpha)

func _draw_queue_card_marker(rect: Rect2, accent: Color, glow_strength: float, open_amount: float, sealed: bool, alpha: float) -> void:
	RewardRevealEffectRendererScript.draw_queue_card_marker(self, rect, accent, glow_strength, open_amount, sealed, alpha)

func _draw_sealed_reward_card(card_rect: Rect2, accent: Color, alpha: float, reveal_progress: float, phase: Dictionary) -> void:
	RewardRevealEffectRendererScript.draw_sealed_reward_card(self, timer, card_rect, accent, alpha, reveal_progress, phase)

func _draw_rarity_burst(canvas_size: Vector2, card_rect: Rect2, accent: Color, alpha: float, phase: Dictionary, profile: Dictionary) -> void:
	RewardRevealEffectRendererScript.draw_rarity_burst(self, canvas_size, card_rect, accent, alpha, phase, profile)

func _draw_preview_excavation_chamber(rect: Rect2, preview: Dictionary, accent: Color, progress: float, alpha: float) -> void:
	RewardRevealEffectRendererScript.draw_preview_excavation_chamber(self, presentation, timer, rect, preview, accent, progress, alpha)

func _draw_reveal_stage_backdrop(canvas_size: Vector2, card_rect: Rect2, accent: Color, alpha: float, reveal_progress: float, profile: Dictionary) -> void:
	RewardRevealEffectRendererScript.draw_reveal_stage_backdrop(self, canvas_size, card_rect, accent, alpha, reveal_progress, profile, confirm_pulse, presentation)

func _quantity_slot_rects(count: int, canvas_size: Vector2, slot_size: Vector2, center_y: float) -> Array:
	return RewardRevealLayoutPolicyScript.quantity_slot_rects(count, canvas_size, slot_size, center_y)

func _queue_strip_rects(count: int, canvas_size: Vector2) -> Array:
	return RewardRevealLayoutPolicyScript.queue_strip_rects(count, canvas_size)

func _count_tease_thresholds(count: int) -> Array:
	return RewardRevealLayoutPolicyScript.count_tease_thresholds(count)

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
	return RewardRevealPresentationModelScript.hero_reward_index(reward_list)

static func _payload_dictionary(reward: Dictionary) -> Dictionary:
	return RewardRevealPresentationModelScript.payload_dictionary(reward)

static func _sorted_reward_dictionaries(reward_list: Array) -> Array:
	return RewardRevealPresentationModelScript.sorted_reward_dictionaries(reward_list)

static func _reward_display_name(reward: Dictionary) -> String:
	return RewardRevealPresentationModelScript.reward_display_name(reward)

static func _reward_rarity_label(rarity: String) -> String:
	return RewardRevealPresentationModelScript.reward_rarity_label(rarity)

static func _reward_item_type_label(payload: Dictionary) -> String:
	return RewardRevealPresentationModelScript.reward_item_type_label(payload)

static func _reward_rarity_vfx_tier(reward: Dictionary) -> String:
	return RewardRevealPresentationModelScript.reward_rarity_vfx_tier(reward)

static func _quantity_tease_band(reward_count: int) -> String:
	return RewardRevealPresentationModelScript.quantity_tease_band(reward_count)

static func count_tease_preview_model(reward_count: int) -> Dictionary:
	return RewardRevealAnimationModelsScript.count_tease_preview_model(reward_count)

static func mined_lid_motion_model(source_rect: Rect2, canvas_size: Vector2, progress: float, reward_count: int) -> Dictionary:
	return RewardRevealAnimationModelsScript.mined_lid_motion_model(source_rect, canvas_size, progress, reward_count)

static func count_burst_animation_model(canvas_size: Vector2, progress: float, reward_count: int) -> Dictionary:
	return RewardRevealAnimationModelsScript.count_burst_animation_model(canvas_size, progress, reward_count)

static func count_burst_model(reward_count: int) -> Dictionary:
	return RewardRevealAnimationModelsScript.count_burst_model(reward_count)

static func card_reveal_phase_model(rarity: String, progress: float, identity_readable: bool, queue_position: int) -> Dictionary:
	return RewardRevealAnimationModelsScript.card_reveal_phase_model(rarity, progress, identity_readable, queue_position)

static func queue_marker_phase_model(rarity: String, revealed: bool, current: bool, current_readable: bool) -> Dictionary:
	return RewardRevealAnimationModelsScript.queue_marker_phase_model(rarity, revealed, current, current_readable)

static func reveal_visual_profile(rarity: String) -> Dictionary:
	return RewardRevealPresentationModelScript.reveal_visual_profile(rarity)

static func reveal_queue_layout_policy() -> Dictionary:
	return RewardRevealPresentationModelScript.reveal_queue_layout_policy()

static func reward_card_layout_metrics(canvas_size: Vector2) -> Dictionary:
	return RewardRevealLayoutPolicyScript.reward_card_layout_metrics(canvas_size)

static func _rarity_rank(rarity: String) -> int:
	return RewardRevealPresentationModelScript.rarity_rank(rarity)

static func _rarity_accent(rarity: String) -> Color:
	return RewardRevealPresentationModelScript.rarity_accent(rarity)

static func _sealed_neutral_accent() -> Color:
	return RewardRevealPresentationModelScript.sealed_neutral_accent()

static func _sealed_visual_profile() -> Dictionary:
	return RewardRevealPresentationModelScript.sealed_visual_profile()

static func _excavation_lid_aspect_ratio() -> float:
	return RewardRevealLayoutPolicyScript.excavation_lid_aspect_ratio()

static func _energy_accent(energy_type: String) -> Color:
	return RewardRevealPresentationModelScript.energy_accent(energy_type)

static func _segment(value: float, start: float, duration: float) -> float:
	return RewardRevealAnimationModelsScript.segment(value, start, duration)

static func _ease_out(value: float) -> float:
	return RewardRevealAnimationModelsScript.ease_out(value)
