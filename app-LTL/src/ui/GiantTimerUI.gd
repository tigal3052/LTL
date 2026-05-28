# 계약:
# - 책임: 전투 타이머 floating panel, critical vignette, heartbeat sound를 캡슐화한다.
# - 입력: timer text/visibility/vignette state, battlefield anchor control, volume value.
# - 출력: timer/vignette 표시와 heartbeat audio playback.
# - 금지: combat state 계산, battlefield 렌더링, controller 직접 접근.
#
# 실행: define the giant timer UI control.
class_name GiantTimerUI
extends Control

const HeartbeatSynthScript = preload("res://src/ui/presenters/HeartbeatSynth.gd")

var timer_panel: PanelContainer
var timer_label: Label
var vignette_overlay: Panel
var heartbeat_player: AudioStreamPlayer
var heartbeat_volume: float = 75.0
var heartbeat_timer: float = 1.0
var pulse_time: float = 0.0

# 실행: build timer, vignette, and heartbeat nodes.
func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	ensure_built()

# 실행: ensure child controls exist before the owner reads exported references.
func ensure_built() -> void:
	if timer_panel != null:
		return
	_create_timer_panel()
	_create_vignette_overlay()
	_create_heartbeat_player()

# 실행: apply timer state from the phase layout presenter.
func apply_timer_state(timer_text: String, timer_visible: bool, vignette_visible: bool) -> void:
	if timer_panel == null or timer_label == null or vignette_overlay == null:
		return
	timer_panel.visible = timer_visible
	timer_label.text = timer_text
	vignette_overlay.visible = vignette_visible

# 실행: animate timer/vignette and position over the battlefield anchor.
func process_timer(delta: float, battlefield_anchor: Control) -> void:
	if timer_panel == null or timer_label == null or vignette_overlay == null:
		return
	if timer_panel.visible and battlefield_anchor != null:
		var anchor_pos = battlefield_anchor.global_position
		var anchor_size = battlefield_anchor.size
		var panel_size = timer_panel.size
		if panel_size == Vector2.ZERO:
			panel_size = timer_panel.get_combined_minimum_size()
		timer_panel.global_position = Vector2(anchor_pos.x + (anchor_size.x - panel_size.x) / 2.0, anchor_pos.y + 4.0)
	if timer_panel.visible and vignette_overlay.visible:
		pulse_time += delta
		var pulse = 0.35 + 0.65 * abs(sin(pulse_time * 6.5))
		var vignette_style = vignette_overlay.get_theme_stylebox("panel") as StyleBoxFlat
		if vignette_style:
			vignette_style.border_color = Color(0.85, 0.1, 0.1, pulse * 0.35)
			vignette_style.shadow_color = Color(1.0, 0.0, 0.0, pulse * 0.2)
		timer_label.add_theme_color_override("font_color", Color(0.9, 0.1, 0.1).lerp(Color(0.95, 0.75, 0.25), abs(sin(pulse_time * 3.5))))
		var timer_style = timer_panel.get_theme_stylebox("panel") as StyleBoxFlat
		if timer_style:
			timer_style.border_color = Color(0.9, 0.1, 0.1, 0.5 + 0.5 * pulse)
		timer_label.pivot_offset = timer_label.size / 2.0
		timer_label.scale = Vector2.ONE * (1.0 + 0.08 * pulse)
		heartbeat_timer += delta
		if heartbeat_timer >= 1.0:
			heartbeat_timer = 0.0
			if heartbeat_player and not heartbeat_player.playing:
				heartbeat_player.play()
	else:
		heartbeat_timer = 1.0
		if heartbeat_player and heartbeat_player.playing:
			heartbeat_player.stop()
		if timer_panel.visible:
			var timer_style = timer_panel.get_theme_stylebox("panel") as StyleBoxFlat
			if timer_style:
				timer_style.border_color = Color(0.24, 0.35, 0.50, 0.8)
			timer_label.add_theme_color_override("font_color", Color(0.95, 0.75, 0.25))
			timer_label.scale = Vector2.ONE

# 실행: set heartbeat volume percentage.
func set_volume(value: float) -> void:
	heartbeat_volume = value
	_update_heartbeat_volume()

# 실행: construct the floating timer panel.
func _create_timer_panel() -> void:
	timer_panel = PanelContainer.new()
	timer_panel.visible = false
	timer_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(timer_panel)
	timer_panel.set_as_top_level(true)
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.04, 0.06, 0.95)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.24, 0.35, 0.50, 0.8)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.content_margin_left = 10
	style.content_margin_top = 2
	style.content_margin_right = 10
	style.content_margin_bottom = 2
	timer_panel.add_theme_stylebox_override("panel", style)
	timer_label = Label.new()
	timer_label.text = "00:00"
	timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	timer_label.add_theme_font_size_override("font_size", 16)
	timer_label.add_theme_color_override("font_color", Color(0.95, 0.75, 0.25))
	timer_panel.add_child(timer_label)

# 실행: construct the full-screen critical vignette overlay.
func _create_vignette_overlay() -> void:
	vignette_overlay = Panel.new()
	vignette_overlay.name = "VignetteOverlay"
	vignette_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vignette_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vignette_overlay.visible = false
	add_child(vignette_overlay)
	var style = StyleBoxFlat.new()
	style.draw_center = false
	style.border_width_left = 50
	style.border_width_top = 50
	style.border_width_right = 50
	style.border_width_bottom = 50
	style.border_color = Color(0.85, 0.1, 0.1, 0.0)
	style.shadow_color = Color(1.0, 0.0, 0.0, 0.0)
	style.shadow_size = 25
	vignette_overlay.add_theme_stylebox_override("panel", style)

# 실행: create synthetic heartbeat audio.
func _create_heartbeat_player() -> void:
	heartbeat_player = AudioStreamPlayer.new()
	heartbeat_player.name = "HeartbeatPlayer"
	add_child(heartbeat_player)
	heartbeat_player.stream = HeartbeatSynthScript.create_stream()
	_update_heartbeat_volume()

# 실행: apply heartbeat volume as decibels.
func _update_heartbeat_volume() -> void:
	if heartbeat_player == null:
		return
	if heartbeat_volume <= 0.0:
		heartbeat_player.volume_db = -80.0
	else:
		heartbeat_player.volume_db = linear_to_db(heartbeat_volume / 100.0)
