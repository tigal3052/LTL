# 계약:
# - 책임: formal M2 preview controller를 Godot main scene에 연결하고 phase-aware combat preview UI를 렌더링한다.
# - 입력: `CombatScenePreviewController` public API와 main-scene panel/button/particle/extractor/grid/discard nodes.
# - 출력: node-select, combat, reward, run-complete 상태를 보여주는 interactive preview surface.
# - 금지: combat rule 재구현, prototype scene 참조, private runtime mutation
#
# 실행: define the main-scene controller as a PanelContainer script.
extends PanelContainer

# 실행: preload the CellView class for interactive grid cells.
const CellViewScript = preload("res://src/ui/CellView.gd")
const PreviewControllerScript = preload("res://src/ui/CombatScenePreviewController.gd")
const ArtifactScript = preload("res://src/models/Artifact.gd")

# 실행: cache the scene nodes that receive rendered preview state.
@onready var phase_label: Label = $RootMargin/AppShell/Header/Margin/PhaseRow/PhaseLabel
@onready var stage_label: Label = $RootMargin/AppShell/Header/Margin/PhaseRow/StageLabel
@onready var node_select_text: RichTextLabel = $RootMargin/AppShell/ActivePhaseContainer/NodeSelectPanel/Margin/NodeSelectBox/NodeSelectText
@onready var reward_text: RichTextLabel = $RootMargin/AppShell/ActivePhaseContainer/RewardPanel/Margin/RewardBox/RewardRow/RewardText
@onready var battlefield_grid: GridContainer = $RootMargin/AppShell/ActivePhaseContainer/BattlefieldPanel/Margin/BattlefieldBox/BattlefieldGrid
@onready var reset_button: Button = $RootMargin/AppShell/ActionBar/ResetButton
@onready var start_button: Button = $RootMargin/AppShell/ActionBar/StartButton
@onready var hold_fire_button: Button = $RootMargin/AppShell/ActionBar/HoldFireButton
@onready var repair_button: Button = $RootMargin/AppShell/ActionBar/RepairButton
@onready var claim_rewards_button: Button = $RootMargin/AppShell/ActionBar/ClaimRewardsButton

# 실행: cache the new visual UI nodes.
@onready var settings_panel: PanelContainer = $SettingsPanel
@onready var settings_open_button: Button = $RootMargin/AppShell/Header/Margin/PhaseRow/SettingsOpenButton
@onready var screenshake_checkbox: CheckBox = $SettingsPanel/Center/SettingsBox/GameplaySection/ScreenshakeCheckbox
@onready var fullscreen_checkbox: CheckBox = $SettingsPanel/Center/SettingsBox/ScreenSection/FullscreenCheckbox
@onready var volume_slider: HSlider = $SettingsPanel/Center/SettingsBox/SoundSection/VolumeSlider
@onready var main_menu_button: Button = $SettingsPanel/Center/SettingsBox/ButtonsRow/MainMenuButton
@onready var close_settings_button: Button = $SettingsPanel/Center/SettingsBox/ButtonsRow/CloseSettingsButton
@onready var repair_overlay: PanelContainer = $RepairOverlay
@onready var status_panel: PanelContainer = $RootMargin/AppShell/TopContent/LeftColumn/StatusPanel
@onready var extractor_label: Label = $RootMargin/AppShell/TopContent/LeftColumn/StatusPanel/Margin/StatusBox/NodeRow/ExtractorLabel
@onready var visual_queue_box: HBoxContainer = $RootMargin/AppShell/TopContent/LeftColumn/StatusPanel/Margin/StatusBox/QueueRow/VisualQueueBox
@onready var particle_template: CPUParticles2D = $ParticleTemplate
@onready var extractor_visual: Panel = $RootMargin/AppShell/TopContent/LeftColumn/StatusPanel/Margin/StatusBox/NodeRow/ExtractorVisual

# 실행: cache right sidebar inspector nodes.
@onready var inspector_text: RichTextLabel = $RootMargin/AppShell/TopContent/RightSidebar/Margin/InspectorBox/InspectorText

# 실행: cache the 3:7 panels and target/core system bars.
@onready var node_select_panel: PanelContainer = $RootMargin/AppShell/ActivePhaseContainer/NodeSelectPanel
@onready var backpack_engine_panel: PanelContainer = $RootMargin/AppShell/TopContent/BackpackContainer/BackpackEnginePanel
@onready var backpack_grid_mock: GridContainer = $RootMargin/AppShell/TopContent/BackpackContainer/BackpackEnginePanel/Margin/EngineBox/GridMock
@onready var battlefield_panel: PanelContainer = $RootMargin/AppShell/ActivePhaseContainer/BattlefieldPanel
@onready var reward_panel: PanelContainer = $RootMargin/AppShell/ActivePhaseContainer/RewardPanel
@onready var discard_zone: PanelContainer = $RootMargin/AppShell/ActivePhaseContainer/RewardPanel/Margin/RewardBox/RewardRow/DiscardZone
@onready var discard_label: Label = $RootMargin/AppShell/ActivePhaseContainer/RewardPanel/Margin/RewardBox/RewardRow/DiscardZone/DiscardLabel
@onready var health_bar: ProgressBar = $RootMargin/AppShell/TopContent/LeftColumn/StatusPanel/Margin/StatusBox/HPBox/HealthBar
@onready var shield_bar: ProgressBar = $RootMargin/AppShell/TopContent/LeftColumn/StatusPanel/Margin/StatusBox/ShieldBox/ShieldBar
@onready var pin_progress_bar: ProgressBar = $RootMargin/AppShell/TopContent/LeftColumn/StatusPanel/Margin/StatusBox/TimerRow/PinProgressBar
@onready var pin_label: Label = $RootMargin/AppShell/TopContent/LeftColumn/StatusPanel/Margin/StatusBox/TimerRow/PinLabel
@onready var repair_status_label: Label = $RootMargin/AppShell/TopContent/LeftColumn/StatusPanel/Margin/StatusBox/DrillStatusRow/RepairStatusLabel

# 실행: store global configuration and screenshake state.
static var screenshake_enabled: bool = true

var preview_controller
var current_scene: Dictionary = {}
var disabled_tiles: Array[String] = []

# 실행: store screenshake runtime variables.
var shake_timer: float = 0.0
var shake_intensity: float = 0.0

# 실행: store hold-to-fire loop variables.
var hold_cell_id: String = ""
var hold_color: String = ""
var is_holding: bool = false

# 실행: store 1.0 second shifting timer.
var shift_timer: Timer

# 실행: store backpack inventory models and held state.
var inventory: InventoryModel = null
var held_artifact: Artifact = null
var held_from_rewards: bool = false

# 실행: store backpack items loadout (8x8 grid).
# Item shape list: offsets relative to the origin of the item.
var backpack_items = [
	{"name": "Ruby Drill Core", "color": "red", "shape": [Vector2(0, 0), Vector2(1, 0)], "pos": Vector2(1, 2)},
	{"name": "Sapphire Lens", "color": "blue", "shape": [Vector2(0, 0), Vector2(0, 1)], "pos": Vector2(4, 1)},
	{"name": "Amethyst Resonance", "color": "purple", "shape": [Vector2(0, 0), Vector2(1, 0), Vector2(0, 1), Vector2(1, 1)], "pos": Vector2(2, 4)},
	{"name": "Emerald Capacitor", "color": "green", "shape": [Vector2(0, 0)], "pos": Vector2(6, 5)}
]

# 실행: store dynamic energy queue colors loaded by active items.
var queue_colors: Array[String] = []

var repair_countdown: float = 0.0
var last_logged_pins: int = -1

# 실행: store the currently held reward index for drag/click loot mechanics.
var held_reward_index: int = -1
var local_rewards_list: Array = []

# 실행: ghost container for dragging artifacts.
var ghost_container: GridContainer = null

# 실행: store log state variables.
var log_history: Array[String] = []
var prev_phase: String = ""
var prev_pin_active: bool = false
var prev_hazard_severity: String = "stable"

# 실행: create the preview controller, wire actions, and render the initial combat preview.
func _ready() -> void:
	inventory = InventoryModel.new(8, 8)
	_load_backpack_items_into_inventory()
	
	preview_controller = PreviewControllerScript.new({"seed": 61, "maxStages": 1, "viewportWidth": 1440, "viewportHeight": 900})
	
	# Wire action buttons
	reset_button.pressed.connect(_on_reset_pressed)
	start_button.pressed.connect(_on_start_pressed)
	hold_fire_button.pressed.connect(_on_hold_fire_pressed)
	repair_button.pressed.connect(_on_repair_pressed)
	claim_rewards_button.pressed.connect(_on_claim_rewards_pressed)
	
	# Wire settings menu buttons
	settings_open_button.pressed.connect(_toggle_settings)
	close_settings_button.pressed.connect(_toggle_settings)
	main_menu_button.pressed.connect(_on_main_menu_pressed)
	screenshake_checkbox.toggled.connect(_on_screenshake_toggled)
	fullscreen_checkbox.toggled.connect(_on_fullscreen_toggled)
	
	# Wire reward click and discard inputs
	reward_text.meta_clicked.connect(_on_reward_meta_clicked)
	discard_zone.gui_input.connect(_on_discard_zone_input)
	
	# Wire repair overlay inputs
	repair_overlay.gui_input.connect(_on_repair_overlay_input)
	
	# Set checkbox initial values
	screenshake_checkbox.button_pressed = screenshake_enabled
	fullscreen_checkbox.button_pressed = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
	
	# Load 9-slice StyleBoxTexture for Backpack Panel at runtime
	_setup_backpack_stylebox()
	
	# Initialize 8x8 grid mock slots
	_setup_backpack_grid_slots()
	
	# Setup drag ghost visual container
	_setup_ghost_container()
	
	current_scene = preview_controller.reset()
	current_scene = preview_controller.start_combat(0)
	
	# Initialize random weakness cells (Red, Blue, Purple, Green)
	_initialize_random_weaknesses()
	
	current_scene = preview_controller.aim_cell("r0c0", "red")
	_render_scene(current_scene)
	
	# Setup 1.0s conveyor-belt shift timer
	_setup_shift_timer()

# 실행: append message to the system log and update the RichTextLabel.
func _add_log(message: String) -> void:
	log_history.append(message)
	if log_history.size() > 18:
		log_history.remove_at(0)
	if inspector_text:
		inspector_text.text = "\n".join(log_history)


# 실행: process screenshake delta tick on each frame, and update drag ghost position.
func _process(delta: float) -> void:
	if shake_timer > 0.0 and screenshake_enabled:
		shake_timer -= delta
		position = Vector2(randf_range(-shake_intensity, shake_intensity), randf_range(-shake_intensity, shake_intensity))
	else:
		position = Vector2.ZERO
		
	# Update drag ghost position centered around the mouse cursor
	if ghost_container and ghost_container.visible and held_artifact:
		var shape = held_artifact.shape
		var rows = shape.size()
		var cols = shape[0].size() if rows > 0 else 0
		var expected_size = Vector2(cols * 24 + (cols - 1) * 2, rows * 24 + (rows - 1) * 2)
		ghost_container.global_position = get_global_mouse_position() - expected_size / 2

# 실행: load the 9-patch StyleBoxTexture for the backpack panel dynamically.
func _setup_backpack_stylebox() -> void:
	# We now lay out the backpack slices inside the GridMock itself.
	# The panel size is dynamically managed by the AspectRatioContainer parent.
	pass

# 실행: construct the 8x8 grid slots inside the backpack mock.
func _setup_backpack_grid_slots() -> void:
	for child in backpack_grid_mock.get_children():
		child.queue_free()
		
	backpack_grid_mock.columns = 10
	backpack_grid_mock.add_theme_constant_override("h_separation", 2)
	backpack_grid_mock.add_theme_constant_override("v_separation", 2)
	
	# Load the 9 slice textures
	var textures = {}
	for i in range(1, 10):
		textures[i] = load("res://resources/UI/backpack_%d.png" % i)
		
	for r in range(10):
		for c in range(10):
			var is_border = (r == 0 or r == 9 or c == 0 or c == 9)
			if is_border:
				var slice_num = 5
				if r == 0:
					if c == 0: slice_num = 1
					elif c == 9: slice_num = 3
					else: slice_num = 2
				elif r == 9:
					if c == 0: slice_num = 7
					elif c == 9: slice_num = 9
					else: slice_num = 8
				else:
					if c == 0: slice_num = 4
					elif c == 9: slice_num = 6
					
				var border_rect := TextureRect.new()
				border_rect.custom_minimum_size = Vector2(16, 16)
				border_rect.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				border_rect.size_flags_vertical = Control.SIZE_EXPAND_FILL
				border_rect.texture = textures[slice_num]
				border_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
				border_rect.stretch_mode = TextureRect.STRETCH_SCALE
				backpack_grid_mock.add_child(border_rect)
			else:
				var grid_r = r - 1
				var grid_c = c - 1
				var slot := Panel.new()
				slot.custom_minimum_size = Vector2(16, 16)
				slot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				slot.size_flags_vertical = Control.SIZE_EXPAND_FILL
				
				# Empty slot style uses the wood grain texture (backpack_5.png)
				var bg_style := StyleBoxTexture.new()
				bg_style.texture = textures[5]
				slot.add_theme_stylebox_override("panel", bg_style)
				
				# Semi-transparent overlay to display active items
				var overlay := ColorRect.new()
				overlay.name = "Overlay"
				overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
				overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
				overlay.color = Color(0, 0, 0, 0)
				slot.add_child(overlay)
				
				slot.gui_input.connect(func(event: InputEvent):
					if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
						_on_backpack_slot_clicked(Vector2(grid_c, grid_r))
				)
				backpack_grid_mock.add_child(slot)
				
	_render_backpack_items()

# 실행: load hardcoded starter backpack items into the InventoryModel.
func _load_backpack_items_into_inventory() -> void:
	inventory = InventoryModel.new(8, 8)
	var drills = ArtifactScript.get_basic_drills()
	var positions = [
		Vector2(1, 2),
		Vector2(4, 1),
		Vector2(2, 4),
		Vector2(6, 5)
	]
	for i in range(drills.size()):
		var art = drills[i]
		var pos = positions[i]
		inventory.place_artifact(art, int(pos.x), int(pos.y))
	if preview_controller != null and preview_controller.run != null:
		preview_controller.run.state["inventory"] = inventory.to_dict()

# 실행: render active items inside the 8x8 backpack grid with colored overlays from InventoryModel.
func _render_backpack_items() -> void:
	# Reset overlays
	for r in range(8):
		for c in range(8):
			var slot_idx = (r + 1) * 10 + (c + 1)
			var slot = backpack_grid_mock.get_child(slot_idx) as Panel
			if slot:
				var overlay = slot.get_node("Overlay") as ColorRect
				if overlay:
					overlay.color = Color(0, 0, 0, 0)
					
	# Render active items from InventoryModel
	for art_id in inventory.artifacts:
		var art = inventory.artifacts[art_id] as Artifact
		var color: Color = Color.WHITE
		match str(art.energy_type):
			"red": color = Color(0.85, 0.25, 0.25, 0.7)
			"blue": color = Color(0.25, 0.50, 0.85, 0.7)
			"purple": color = Color(0.65, 0.25, 0.85, 0.7)
			"green": color = Color(0.25, 0.75, 0.35, 0.7)
			
		var pos = Vector2(art.x, art.y)
		var rows = art.shape.size()
		var cols = art.shape[0].size() if rows > 0 else 0
		for r in range(rows):
			for c in range(cols):
				if art.shape[r][c] == 1:
					var cell_col = int(pos.x) + c
					var cell_row = int(pos.y) + r
					if cell_col >= 0 and cell_col < 8 and cell_row >= 0 and cell_row < 8:
						var slot_idx = (cell_row + 1) * 10 + (cell_col + 1)
						var slot = backpack_grid_mock.get_child(slot_idx) as Panel
						if slot:
							var overlay = slot.get_node("Overlay") as ColorRect
							if overlay:
								overlay.color = color

# 실행: generate the dynamic energy queue colors by cycling active backpack item colors.
func _recalculate_queue_colors() -> void:
	queue_colors.clear()
	var active_colors: Array[String] = []
	for art_id in inventory.artifacts:
		var art = inventory.artifacts[art_id] as Artifact
		var c = str(art.energy_type)
		if not c in active_colors:
			active_colors.append(c)
			
	if active_colors.is_empty():
		active_colors.append("red") # fallback
		
	# Populate 8 slots by cycling active item colors
	for i in range(8):
		var color = active_colors[i % active_colors.size()]
		queue_colors.append(color)

# 실행: setup the 1.0 second timer for left-to-right grid shifting.
func _setup_shift_timer() -> void:
	shift_timer = Timer.new()
	shift_timer.wait_time = 1.0
	shift_timer.autostart = true
	shift_timer.timeout.connect(_on_shift_timer_timeout)
	add_child(shift_timer)

# 실행: shift weaknesses left-to-right and generate new random weaknesses on column 0 every 1.0s.
func _on_shift_timer_timeout() -> void:
	if str(current_scene.get("phase", "")) != "combat":
		return
		
	# 1. 20틱만큼 공식 시뮬레이션 틱 진행
	current_scene = preview_controller.run.apply_combat_input({"type": "tick", "ticks": 20})
	
	# 만약 틱 진행 후 전투가 종료되었으면 씬만 렌더링하고 리턴
	if str(current_scene.get("phase", "")) != "combat":
		_render_scene(current_scene)
		return
		
	# 2. 지형 스크롤
	var run_state = preview_controller.run.state
	var combat_dict = run_state["combat"]
	var weakness_markers = combat_dict.get("battlefield", {}).get("weaknessMarkers", [])
	var new_markers = []
	var colors = ["red", "blue", "purple", "green"]
	
	for marker in weakness_markers:
		var cell_id = str(marker.get("cellId", ""))
		if cell_id.begins_with("r") and "c" in cell_id:
			var parts = cell_id.substr(1).split("c")
			if parts.size() == 2:
				var r = int(parts[0])
				var c = int(parts[1])
				var new_c = c + 1
				if new_c < 10:
					new_markers.append({
						"cellId": "r%dc%d" % [r, new_c],
						"color": marker.get("color", "red")
					})
					
	for r in range(3):
		var chosen_color = colors[randi() % colors.size()]
		new_markers.append({
			"cellId": "r%dc0" % r,
			"color": chosen_color
		})
		
	run_state["combat"]["battlefield"]["weaknessMarkers"] = new_markers
	
	# Local inventory model sync from the updated run state
	var inv_data = run_state.get("inventory", {})
	if inv_data is Dictionary:
		inventory = InventoryModel.new(int(inv_data.get("width", 8)), int(inv_data.get("height", 8)))
		if inv_data.has("artifacts"):
			for art_dict in inv_data["artifacts"]:
				var art = ArtifactScript.new(art_dict)
				inventory.place_artifact(art, art.x, art.y)
				
	current_scene = preview_controller.get_scene()
	_render_scene(current_scene)

# 실행: initialize the entire 3x10 grid with random colors from red, blue, purple, green.
func _initialize_random_weaknesses() -> void:
	if not current_scene.has("combat") or current_scene["combat"] == null:
		return
	var run_state = preview_controller.run.state
	if not run_state.has("combat") or run_state["combat"] == null:
		return
		
	var markers = []
	var colors = ["red", "blue", "purple", "green"]
	for r in range(3):
		for c in range(10):
			var chosen_color = colors[randi() % colors.size()]
			markers.append({
				"cellId": "r%dc%d" % [r, c],
				"color": chosen_color
			})
	run_state["combat"]["battlefield"]["weaknessMarkers"] = markers
	current_scene = preview_controller.get_scene()

# 실행: toggle settings menu popup overlay.
func _toggle_settings() -> void:
	settings_panel.visible = not settings_panel.visible

# 실행: handle main menu button click inside settings.
func _on_main_menu_pressed() -> void:
	_toggle_settings()
	_on_reset_pressed()

# 실행: toggle screenshake static configuration.
func _on_screenshake_toggled(toggled: bool) -> void:
	screenshake_enabled = toggled

# 실행: toggle display full screen state.
func _on_fullscreen_toggled(toggled: bool) -> void:
	if toggled:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

# 실행: handle ESC key input to toggle settings.
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE:
			_toggle_settings()
		elif event.keycode == KEY_R:
			if held_artifact != null:
				if str(current_scene.get("phase", "")) == "combat":
					return
				held_artifact.rotate_shape()
				_add_log("[color=#ffd766][인벤토리] 유물 회전됨: %s[/color]" % held_artifact.name)
				_update_ghost_display()
			elif not repair_button.disabled:
				_on_repair_pressed()

# 실행: trigger screenshake for the specified duration and intensity.
func _trigger_screenshake(duration: float, intensity: float) -> void:
	if screenshake_enabled:
		shake_timer = duration
		shake_intensity = intensity

# 실행: start holding fire repeating loop.
func _start_hold_timer(cell_id: String, color: String) -> void:
	is_holding = true
	hold_cell_id = cell_id
	hold_color = color
	_trigger_hold_fire()

# 실행: stop holding fire repeating loop.
func _stop_hold_timer() -> void:
	is_holding = false

# 실행: execute hold-to-fire loop ticks at 0.1s interval.
func _trigger_hold_fire() -> void:
	if not is_holding or str(current_scene.get("phase", "")) != "combat":
		return
	_on_cell_clicked(hold_cell_id, hold_color)
	await get_tree().create_timer(0.1).timeout
	_trigger_hold_fire()

# 실행: trigger Line2D magic resonance beam animation.
func _draw_resonance_beam(start_pos: Vector2, end_pos: Vector2, color_name: String) -> void:
	var line := Line2D.new()
	line.width = 5.0
	
	# Determine glowing beam color
	var c_color := Color(0.95, 0.75, 0.25, 0.9)
	if color_name == "red":
		c_color = Color(0.9, 0.2, 0.2, 0.9)
	elif color_name == "blue":
		c_color = Color(0.2, 0.5, 0.9, 0.9)
	elif color_name == "green":
		c_color = Color(0.2, 0.8, 0.3, 0.9)
	elif color_name == "purple":
		c_color = Color(0.7, 0.2, 0.8, 0.9)
		
	line.default_color = c_color
	
	# Zig-zag resonance waves
	var steps = 8
	var dir = end_pos - start_pos
	var perp = Vector2(-dir.y, dir.x).normalized()
	
	line.add_point(start_pos - global_position)
	for i in range(1, steps):
		var t = float(i) / steps
		var pt = start_pos + dir * t
		var offset = perp * randf_range(-6.0, 6.0)
		line.add_point(pt + offset - global_position)
	line.add_point(end_pos - global_position)
	
	add_child(line)
	
	# Tween to fade out beam
	var tween = create_tween()
	tween.tween_property(line, "self_modulate:a", 0.0, 0.12)
	tween.tween_callback(line.queue_free)

# 실행: trigger CPUParticles2D mineral hit burst.
func _spawn_hit_particles(pos: Vector2, outcome: String, color_name: String) -> void:
	var p = particle_template.duplicate() as CPUParticles2D
	add_child(p)
	p.global_position = pos
	
	# Color and amount adjustments based on C-type crust concept
	match outcome:
		"match":
			var c_color := Color(0.9, 0.3, 0.3)
			if color_name == "blue": c_color = Color(0.3, 0.6, 0.9)
			elif color_name == "green": c_color = Color(0.3, 0.8, 0.4)
			elif color_name == "purple": c_color = Color(0.7, 0.3, 0.8)
			p.color = c_color
			p.amount = 20
			p.initial_velocity_min = 120.0
			p.initial_velocity_max = 220.0
		"mismatch":
			p.color = Color(0.65, 0.68, 0.72) # Grey rock fragments
			p.amount = 12
			p.initial_velocity_min = 80.0
			p.initial_velocity_max = 140.0
		_: # disabled, empty_queue
			p.color = Color(0.4, 0.35, 0.3, 0.6) # Dusty smoke
			p.amount = 8
			p.initial_velocity_min = 40.0
			p.initial_velocity_max = 80.0
			
	p.emitting = true
	get_tree().create_timer(1.0).timeout.connect(p.queue_free)

# 실행: handle interactive hover cell aiming.
func _on_cell_hovered(cell_id: String, color_name: String) -> void:
	if str(current_scene.get("phase", "")) != "combat":
		return
	
	# Fire color is always matched with the current queue front color
	var active_color = _get_active_queue_color()
	current_scene = preview_controller.aim_cell(cell_id, active_color)
	_render_scene(current_scene)

# 실행: handle interactive click/fire target events.
func _on_cell_clicked(cell_id: String, color_name: String) -> void:
	if str(current_scene.get("phase", "")) != "combat" or cell_id in disabled_tiles:
		return
		
	# Compute damage by comparing target HP and Shield before and after fire
	var prev_shield = float(current_scene.get("targetPanel", {}).get("shield", 0.0))
	var prev_health = float(current_scene.get("targetPanel", {}).get("health", 0.0))

	# Consume energy and evaluate result (Always fires the front queue color based on item setup)
	var active_color = _get_active_queue_color()
	current_scene = preview_controller.fire(cell_id, active_color)
	
	var next_shield = float(current_scene.get("targetPanel", {}).get("shield", 0.0))
	var next_health = float(current_scene.get("targetPanel", {}).get("health", 0.0))
	var damage = (prev_shield - next_shield) + (prev_health - next_health)
	
	# Visual feedback triggers
	var feedback: Dictionary = current_scene.get("feedback", {})
	var status = str(feedback.get("status", "active"))
	
	# Item activation log
	var matched_item = null
	for art_id in inventory.artifacts:
		var art = inventory.artifacts[art_id]
		if str(art.energy_type) == active_color and art.item_type == "drill":
			matched_item = art
			break
	if matched_item:
		_add_log("[color=#ffd766][아이템 발동] %s (%s) 사용![/color]" % [matched_item.name, active_color.to_upper()])
	else:
		_add_log("[color=#ffd766][아이템 발동] 익명 드릴 (%s) 사용![/color]" % active_color.to_upper())
		
	# Drill hit log
	_add_log("[color=#66c2cd][지형 타격] 좌표: %s | 사용 에너지: %s | 광석 타입: %s | 최종 데미지: %.1f[/color]" % [cell_id.to_upper(), active_color.to_upper(), color_name.to_upper(), damage])
	
	if status == "empty_queue":
		_add_log("[color=#ff6666][경고] 에너지 큐 고갈! 드릴 가동이 중단되었습니다.[/color]")
	
	# Determine hit position accurately
	var hit_pos = global_position + size / 2 # fallback
	for child in battlefield_grid.get_children():
		if child is CellViewScript and child.cell_id == cell_id:
			hit_pos = child.global_position + child.size / 2
			break
			
	# Start position from the separate B-type Magic Resonator Core visual
	var start_pos = extractor_visual.global_position + extractor_visual.size / 2
	
	# Draw B-type resonance beam
	_draw_resonance_beam(start_pos, hit_pos, active_color)
	
	# Spawn C-type crust hit particles
	_spawn_hit_particles(hit_pos, status, active_color)
	
	# Apply screenshake based on match/mismatch intensity
	if status == "match" or status == "clear":
		_trigger_screenshake(0.18, 7.0)
	elif status == "mismatch":
		_trigger_screenshake(0.12, 3.0)
	else: # empty queue, repair blocked
		_trigger_screenshake(0.08, 1.0)
		
	# Add tile to 0.5s local cooldown list
	disabled_tiles.append(cell_id)
	get_tree().create_timer(0.5).timeout.connect(func():
		disabled_tiles.erase(cell_id)
		if str(current_scene.get("phase", "")) == "combat":
			_render_scene(current_scene)
	)
	
	_render_scene(current_scene)

# 실행: return the active front color of the dynamic queue loaded by backpack items.
func _get_active_queue_color() -> String:
	var hud: Dictionary = current_scene.get("hud", {})
	var queue: Dictionary = hud.get("queue", {})
	var items: Array = queue.get("items", [])
	if not items.is_empty():
		return str(items[0])
	return "red" # fallback

# 실행: render one preview-scene snapshot into labels, battlefield cells, and action states.
func _render_scene(scene: Dictionary) -> void:
	current_scene = scene.duplicate(true)
	var phase := str(scene.get("phase", "unknown"))
	
	# Log Phase Changes
	if phase != prev_phase:
		if phase == "node_select":
			_add_log("[color=#8fa1b3][시스템] 페이즈 전환: 노드 선택. 탐사할 구역을 선택하십시오.[/color]")
		elif phase == "combat":
			_add_log("[color=#8fa1b3][시스템] 페이즈 전환: 갑각 채굴 전투 돌입.[/color]")
		elif phase == "reward_loot":
			_add_log("[color=#8fa1b3][시스템] 페이즈 전환: 유물 회수 및 백팩 정렬.[/color]")
		elif phase == "run_complete":
			if bool(scene.get("failed", false)):
				_add_log("[color=#e05353][시스템] 탐사 실패! 시뮬레이터가 중단되었습니다. (사유: %s)[/color]" % str(scene.get("failureReason", "")).to_upper())
			else:
				_add_log("[color=#a3be8c][시스템] 탐사 완료! 유물 회수 성공.[/color]")
		prev_phase = phase

	# Log Pin Obstacle and Hazard Severity Changes (Combat phase only)
	if phase == "combat":
		var hud: Dictionary = scene.get("hud", {})
		var pin: Dictionary = hud.get("pin", {})
		var pin_active_now = bool(pin.get("active", false))
		if pin_active_now != prev_pin_active:
			if pin_active_now:
				_add_log("[color=#e05353][방해요소 발생] 드릴 고정(Pin) 활성화! 다음 턴까지 에너지가 잠깁니다.[/color]")
			else:
				_add_log("[color=#a3be8c][방해요소 해제] 드릴 고정(Pin) 해제 완료![/color]")
			prev_pin_active = pin_active_now

		var hazard: Dictionary = hud.get("hazard", {})
		var hazard_sev_now = str(hazard.get("severity", "stable"))
		if hazard_sev_now != prev_hazard_severity:
			if hazard_sev_now in ["warning", "critical"]:
				_add_log("[color=#e05353][방해요소 작동] 위험도 경보 발생! 위험 수준: %s[/color]" % hazard_sev_now.to_upper())
			elif hazard_sev_now == "stable" and prev_hazard_severity in ["warning", "critical"]:
				_add_log("[color=#a3be8c][방해요소 해제] 위험도 등급 해제! 환경 안정화됨.[/color]")
			prev_hazard_severity = hazard_sev_now

	phase_label.text = "Phase: %s" % phase.capitalize()
	stage_label.text = "Stage %d / %d" % [int(scene.get("stageIndex", 0)) + 1, maxi(1, int(scene.get("maxStages", 1)))]
	node_select_text.text = _node_select_summary(scene)
	
	var last_node = str(scene.get("lastNodeLabel", ""))
	if last_node != "":
		extractor_label.text = "노드: %s" % last_node
	else:
		extractor_label.text = "노드: —"
	
	# Clean & update UI components based on phase state machine
	_manage_screen_views(phase)
	
	_render_battlefield(scene)
	_update_action_state(scene)
	_render_visual_queue(scene)
	_render_repair_overlay(scene)
	_render_target_bars(scene)
	_render_rewards(scene)

# 실행: manage show/hide nodes based on the current active phase.
func _manage_screen_views(phase: String) -> void:
	if phase == "node_select":
		node_select_panel.visible = true
		battlefield_panel.visible = false
		reward_panel.visible = false
		status_panel.visible = false
	elif phase == "combat":
		node_select_panel.visible = false
		battlefield_panel.visible = true
		reward_panel.visible = false
		status_panel.visible = true
	elif phase == "reward_loot":
		node_select_panel.visible = false
		battlefield_panel.visible = false
		reward_panel.visible = true
		status_panel.visible = false
	else: # run_complete
		node_select_panel.visible = false
		battlefield_panel.visible = false
		reward_panel.visible = false
		status_panel.visible = false

# 실행: update target status HP and Shield bars inside the ExtractorRow.
func _render_target_bars(scene: Dictionary) -> void:
	if str(scene.get("phase", "")) != "combat":
		return
	var target: Dictionary = scene.get("targetPanel", {})
	var max_hp = float(target.get("maxHealth", 100.0))
	var max_shield = float(target.get("maxShield", 2.4))
	
	health_bar.max_value = max_hp
	health_bar.value = float(target.get("health", 0.0))
	
	shield_bar.max_value = max_shield
	shield_bar.value = float(target.get("shield", 0.0))

# 실행: rebuild battlefield cells from the current combat terrain projection.
func _render_battlefield(scene: Dictionary) -> void:
	var terrain: Dictionary = scene.get("terrain", {})
	var rows := int(terrain.get("rows", 0))
	var columns := int(terrain.get("columns", 10))
	battlefield_grid.columns = maxi(1, columns)
	
	if rows <= 0 or not battlefield_panel.visible:
		for child in battlefield_grid.get_children():
			child.queue_free()
		return
		
	# Clean non-CellView children
	for child in battlefield_grid.get_children():
		if not (child is CellViewScript):
			child.queue_free()
			
	var cells: Array = terrain.get("cells", [])
	var existing_count = battlefield_grid.get_child_count()
	
	# Only recreate if count changes
	if existing_count != cells.size():
		for child in battlefield_grid.get_children():
			child.queue_free()
		for cell in cells:
			var cell_view = CellViewScript.new()
			cell_view.configure(cell, disabled_tiles)
			cell_view.cell_hovered.connect(_on_cell_hovered)
			cell_view.cell_clicked.connect(_on_cell_clicked)
			cell_view.cell_pressed.connect(_start_hold_timer)
			cell_view.cell_released.connect(_stop_hold_timer)
			battlefield_grid.add_child(cell_view)
	else:
		# Update cell properties cleanly
		for i in range(cells.size()):
			var cell_view = battlefield_grid.get_child(i)
			if cell_view.has_method("configure"):
				cell_view.configure(cells[i], disabled_tiles)

# 실행: render glowing circle gems inside the queue panel.
func _render_visual_queue(scene: Dictionary) -> void:
	for child in visual_queue_box.get_children():
		child.queue_free()
	if str(scene.get("phase", "")) != "combat":
		return
	var hud: Dictionary = scene.get("hud", {})
	var queue: Dictionary = hud.get("queue", {})
	var capacity := int(queue.get("capacity", 8))
	var items: Array = queue.get("items", [])
	
	for i in range(capacity):
		var gem := Panel.new()
		var style := StyleBoxFlat.new()
		style.corner_radius_top_left = 10
		style.corner_radius_top_right = 10
		style.corner_radius_bottom_right = 10
		style.corner_radius_bottom_left = 10
		
		if i < items.size():
			var color_name = str(items[i])
			if color_name == "red":
				style.bg_color = Color(0.9, 0.25, 0.25)
			elif color_name == "blue":
				style.bg_color = Color(0.25, 0.5, 0.9)
			elif color_name == "green":
				style.bg_color = Color(0.25, 0.75, 0.35)
			elif color_name == "purple":
				style.bg_color = Color(0.65, 0.25, 0.85)
				
			if i == 0:
				gem.custom_minimum_size = Vector2(24, 24)
				style.corner_radius_top_left = 12
				style.corner_radius_top_right = 12
				style.corner_radius_bottom_right = 12
				style.corner_radius_bottom_left = 12
				style.border_width_left = 2
				style.border_width_top = 2
				style.border_width_right = 2
				style.border_width_bottom = 2
				style.border_color = Color.WHITE
			else:
				gem.custom_minimum_size = Vector2(18, 18)
		else:
			style.bg_color = Color(0.1, 0.12, 0.15) # Empty socket slot
			style.border_width_left = 1
			style.border_width_top = 1
			style.border_width_right = 1
			style.border_width_bottom = 1
			style.border_color = Color(0.2, 0.24, 0.3, 0.6)
			gem.custom_minimum_size = Vector2(16, 16)
			
		gem.add_theme_stylebox_override("panel", style)
		visual_queue_box.add_child(gem)

# 실행: render the repair critical overlay when drill fails, and update pin bars.
func _render_repair_overlay(scene: Dictionary) -> void:
	var phase := str(scene.get("phase", ""))
	var failed := bool(scene.get("failed", false))
	
	if phase == "run_complete" and failed:
		repair_overlay.visible = true
		var warning_lbl = repair_overlay.get_node("Center/WarningBox/WarningLabel") as Label
		var desc_lbl = repair_overlay.get_node("Center/WarningBox/DescriptionLabel") as Label
		warning_lbl.text = "⚠️ EXPEDITION FAILED ⚠️"
		desc_lbl.text = "Time limit exceeded or core destroyed.\nClick here to restart."
		return
		
	if phase != "combat":
		repair_overlay.visible = false
		return
		
	var hud: Dictionary = scene.get("hud", {})
	var queue: Dictionary = hud.get("queue", {})
	var repair: Dictionary = hud.get("repair", {})
	var feedback: Dictionary = scene.get("feedback", {})
	
	var depleted := int(queue.get("loaded", 0)) == 0
	var is_rebuilding := bool(repair.get("active", false))
	var status = str(feedback.get("status", ""))
	
	repair_overlay.visible = depleted or is_rebuilding or status == "empty_queue" or status == "repair_blocked"
	if repair_overlay.visible:
		var warning_lbl = repair_overlay.get_node("Center/WarningBox/WarningLabel") as Label
		var desc_lbl = repair_overlay.get_node("Center/WarningBox/DescriptionLabel") as Label
		warning_lbl.text = "⚠️ MINING DRILL CRITICAL FAILURE ⚠️"
		desc_lbl.text = "Core overheated. Energy queue depleted.\nPress [R] or click the Repair button to restart the drill core."
	
	# Update pin and repair bars
	var pin: Dictionary = hud.get("pin", {})
	pin_progress_bar.max_value = 4.0
	pin_progress_bar.value = float(pin.get("progress", 0))
	
	var time_limit = float(scene.get("combat", {}).get("timeLimitTicks", 2400))
	var elapsed = float(scene.get("combat", {}).get("elapsedTicks", 0))
	var remaining_seconds = max(0, int((time_limit - elapsed) / 20.0))
	
	pin_label.text = "Stage Time Limit: %ds" % remaining_seconds
	
	if is_rebuilding:
		repair_status_label.text = "REPAIRING..."
		repair_status_label.add_theme_color_override("font_color", Color(0.85, 0.25, 0.25))
	elif depleted:
		repair_status_label.text = "OVERHEATED!"
		repair_status_label.add_theme_color_override("font_color", Color(0.85, 0.25, 0.25))
	else:
		repair_status_label.text = "Normal"
		repair_status_label.add_theme_color_override("font_color", Color(0.34, 0.68, 0.42))

# 실행: render the interactive reward looting list.
func _render_rewards(scene: Dictionary) -> void:
	if str(scene.get("phase", "")) != "reward_loot":
		return
		
	# Populate local list of rewards if empty or phase newly entered
	var server_rewards = scene.get("reward", {}).get("pendingRewards", [])
	if local_rewards_list.is_empty() and not server_rewards.is_empty():
		local_rewards_list = server_rewards.duplicate(true)
		
	# Render items inside BBCode RichTextLabel
	var lines: PackedStringArray = []
	if local_rewards_list.is_empty():
		lines.append("No pending rewards left. Press 'Claim Rewards' to select your next node.")
	else:
		lines.append("Click an item to hold it, then drop it in the Discard Zone or backpack grid:\n")
		for idx in range(local_rewards_list.size()):
			var r = local_rewards_list[idx]
			var held_marker = " [HOLDING]" if held_reward_index == idx else ""
			lines.append("▶ [url=%d]%s x%d (%s)[/url]%s" % [idx, str(r.get("kind", "reward")), int(r.get("qty", 0)), str(r.get("color", "normal")), held_marker])
			
	reward_text.text = "\n".join(lines)
	
	# Update discard zone visual
	if held_reward_index >= 0:
		discard_label.text = "🗑 DISCARD ZONE\n[Click here to discard %s]" % str(local_rewards_list[held_reward_index].get("kind", ""))
		discard_zone.self_modulate = Color.WHITE
	else:
		discard_label.text = "🗑 DISCARD ZONE\n[Select reward to drop here]"
		discard_zone.self_modulate = Color(0.5, 0.5, 0.5, 0.5)

# 실행: handle clicking on reward meta links inside RichTextLabel and stage artifact for placement.
func _on_reward_meta_clicked(meta: Variant) -> void:
	held_reward_index = int(meta)
	var item_data = local_rewards_list[held_reward_index]
	var color = str(item_data.get("color", "red"))
	
	var grid_shape = [[1]]
	var base_cooldown := 100
	var art_name := str(item_data.get("kind", "New Artifact"))
	
	if "Drill" in art_name or "Core" in art_name:
		grid_shape = [[1, 1]]
	elif "Lens" in art_name or "Capacitor" in art_name:
		grid_shape = [[1], [1]]
	elif "Resonance" in art_name or "Reactor" in art_name:
		grid_shape = [[1, 1], [1, 1]]
	elif "Condenser" in art_name:
		grid_shape = [[1]]
		
	var art_data = {
		"id": "reward_%d" % randi(),
		"name": art_name,
		"shape": grid_shape,
		"energyType": color,
		"baseCooldownTicks": base_cooldown,
		"synergy": {"type": "same_color", "value": 2}
	}
	held_artifact = Artifact.new(art_data)
	held_from_rewards = true
	_add_log("[color=#ffd766][보상 획득] %s (%s) 선택됨. 백팩을 클릭해 배치하십시오.[/color]" % [art_name, color.to_upper()])
	_render_rewards(current_scene)
	_update_ghost_display()

# 실행: discard the held reward when the discard zone is clicked.
func _on_discard_zone_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if held_reward_index >= 0:
			# Remove from local reward tray
			local_rewards_list.remove_at(held_reward_index)
			held_reward_index = -1
			held_artifact = null
			held_from_rewards = false
			_update_ghost_display()
			_render_rewards(current_scene)

# 실행: place the held reward or pickup/place artifact into the backpack grid slot.
func _on_backpack_slot_clicked(coord: Vector2) -> void:
	if str(current_scene.get("phase", "")) == "combat":
		_add_log("[color=#ff6666][경고] 전투 단계에서는 백팩 내부의 아이템을 움직일 수 없습니다.[/color]")
		return
		
	if held_artifact != null:
		if inventory.can_place_artifact(held_artifact, int(coord.x), int(coord.y)):
			inventory.place_artifact(held_artifact, int(coord.x), int(coord.y))
			_add_log("[color=#a3be8c][인벤토리] 유물 배치 완료: %s[/color]" % held_artifact.name)
			
			if held_from_rewards:
				if held_reward_index >= 0 and held_reward_index < local_rewards_list.size():
					local_rewards_list.remove_at(held_reward_index)
				held_reward_index = -1
				held_from_rewards = false
				
			held_artifact = null
			_update_ghost_display()
			_render_backpack_items()
			_recalculate_queue_colors()
			_render_rewards(current_scene)
			if preview_controller != null and preview_controller.run != null:
				preview_controller.run.state["inventory"] = inventory.to_dict()
		else:
			_add_log("[color=#ff6666][경고] 충돌 또는 범위를 벗어나 배치할 수 없습니다.[/color]")
		return

	var slot_id = str(inventory.grid[int(coord.y)][int(coord.x)])
	if not slot_id.is_empty():
		if inventory.artifacts.has(slot_id):
			held_artifact = inventory.artifacts[slot_id]
			held_from_rewards = false
			inventory.remove_artifact(slot_id)
			_add_log("[color=#ffd766][인벤토리] 유물 선택: %s (이동 또는 [R]키로 회전)[/color]" % held_artifact.name)
			_update_ghost_display()
			_render_backpack_items()
			if preview_controller != null and preview_controller.run != null:
				preview_controller.run.state["inventory"] = inventory.to_dict()

# 실행: enable or disable the main action buttons based on the current phase and combat guards.
func _update_action_state(scene: Dictionary) -> void:
	var phase := str(scene.get("phase", "unknown"))
	var hud: Dictionary = scene.get("hud", {})
	var repair: Dictionary = hud.get("repair", {})
	var aim: Dictionary = hud.get("aim", {})
	start_button.disabled = not (phase == "node_select" and scene.get("nodeSelect", {}).get("candidates", []).size() > 0)
	hold_fire_button.disabled = not (phase == "combat" and bool(aim.get("canFire", false)))
	repair_button.disabled = not (phase == "combat" and bool(repair.get("available", false)))
	claim_rewards_button.disabled = phase != "reward_loot" or not local_rewards_list.is_empty()

# 실행: summarize node-select candidates for the side panel.
func _node_select_summary(scene: Dictionary) -> String:
	var lines: PackedStringArray = []
	for candidate in scene.get("nodeSelect", {}).get("candidates", []):
		lines.append("%s  [%s]" % [str(candidate.get("label", candidate.get("id", "?"))), str(candidate.get("weaknessLabel", ""))])
	if lines.is_empty():
		return "Node Select\nNo candidates available."
	return "Node Select\n" + "\n".join(lines)

# 실행: summarize current target state and fallback messaging for non-combat phases.
func _target_summary(scene: Dictionary) -> String:
	if str(scene.get("phase", "")) != "combat":
		return "Target\nAwaiting combat."
	var target: Dictionary = scene.get("targetPanel", {})
	var weakness: Array = target.get("weakness", [])
	var time_limit = float(target.get("timeLimitTicks", 0))
	var elapsed = float(target.get("elapsedTicks", 0))
	var remaining_seconds = max(0, int((time_limit - elapsed) / 20.0))
	return "Target\nWeakness: %s\nHealth: %.1f\nShield: %.1f\nTimer: %ds" % [",".join(weakness), float(target.get("health", 0.0)), float(target.get("shield", 0.0)), remaining_seconds]

# 실행: summarize queue, repair, hazard, and feedback status for the combat side panel.
func _queue_summary(scene: Dictionary) -> String:
	if str(scene.get("phase", "")) != "combat":
		return "Systems\nCombat systems idle."
	var hud: Dictionary = scene.get("hud", {})
	var queue: Dictionary = hud.get("queue", {})
	var repair: Dictionary = hud.get("repair", {})
	var hazard: Dictionary = hud.get("hazard", {})
	var feedback: Dictionary = scene.get("feedback", {})
	return "Systems\nQueue: %d / %d\nPin: %s\nRepair: %s\nHazard: %s\nStatus: %s" % [int(queue.get("loaded", 0)), int(queue.get("capacity", 0)), "active" if bool(hud.get("pin", {}).get("active", false)) else "clear", "available" if bool(repair.get("available", false)) else "locked", str(hazard.get("label", "stable")), str(feedback.get("status", "idle"))]

# 실행: choose a combat target cell and enter combat when the Start button is pressed.
func _on_start_pressed() -> void:
	current_scene = preview_controller.start_combat(0)
	
	# Re-initialize random weakness cells (Red, Blue, Purple, Green)
	_initialize_random_weaknesses()
	
	var target := _current_target(current_scene)
	var active_color = _get_active_queue_color()
	current_scene = preview_controller.aim_cell(str(target.get("cellId", "r0c0")), active_color)
	_render_scene(current_scene)

# 실행: replay the default combat preview from the beginning when Reset is pressed.
func _on_reset_pressed() -> void:
	current_scene = preview_controller.reset()
	disabled_tiles.clear()
	local_rewards_list.clear()
	held_reward_index = -1
	held_artifact = null
	held_from_rewards = false
	repair_countdown = 0.0
	last_logged_pins = -1
	_update_ghost_display()
	
	_load_backpack_items_into_inventory()
	
	_render_backpack_items()
	_recalculate_queue_colors()
	_initialize_random_weaknesses()
	_render_scene(current_scene)

# 실행: advance combat through the formal hold-fire path when Hold Fire is pressed.
func _on_hold_fire_pressed() -> void:
	var target := _current_target(current_scene)
	var active_color = _get_active_queue_color()
	current_scene = preview_controller.hold_fire(str(target.get("cellId", "r0c0")), active_color, 2)
	_render_scene(current_scene)

# 실행: route repair intent through the formal preview controller when Repair is pressed.
func _on_repair_pressed() -> void:
	current_scene = preview_controller.repair()
	_render_scene(current_scene)

# 실행: claim rewards through the formal preview controller when Claim Rewards is pressed.
func _on_claim_rewards_pressed() -> void:
	current_scene = preview_controller.claim_rewards()
	local_rewards_list.clear()
	held_reward_index = -1
	held_artifact = null
	held_from_rewards = false
	_update_ghost_display()
	_render_scene(current_scene)

# 실행: resolve the best available combat target from the current scene snapshot.
func _current_target(scene: Dictionary) -> Dictionary:
	var hud: Dictionary = scene.get("hud", {})
	var aim: Dictionary = hud.get("aim", {})
	if aim.get("cellId", null) != null and aim.get("targetColor", null) != null:
		return {"cellId": aim.get("cellId", "r0c0"), "color": aim.get("targetColor", "red")}
	for cell in scene.get("terrain", {}).get("cells", []):
		if cell.get("weakness", null) != null:
			return {"cellId": cell.get("id", "r0c0"), "color": cell.get("weakness", "red")}
	return {"cellId": "r0c0", "color": "red"}

# 실행: initialize the drag-and-drop ghost container in the scene.
func _setup_ghost_container() -> void:
	ghost_container = GridContainer.new()
	ghost_container.top_level = true
	ghost_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(ghost_container)
	ghost_container.visible = false

# 실행: update the visual presentation of the drag-and-drop ghost overlay.
func _update_ghost_display() -> void:
	if not ghost_container:
		return
		
	# Clear old cells
	for child in ghost_container.get_children():
		child.queue_free()
		
	if held_artifact == null:
		ghost_container.visible = false
		return
		
	var shape = held_artifact.shape
	var rows = shape.size()
	var cols = shape[0].size() if rows > 0 else 0
	
	ghost_container.columns = cols
	ghost_container.add_theme_constant_override("h_separation", 2)
	ghost_container.add_theme_constant_override("v_separation", 2)
	
	var color: Color = Color.WHITE
	match str(held_artifact.energy_type):
		"red": color = Color(0.85, 0.25, 0.25, 0.5)
		"blue": color = Color(0.25, 0.50, 0.85, 0.5)
		"purple": color = Color(0.65, 0.25, 0.85, 0.5)
		"green": color = Color(0.25, 0.75, 0.35, 0.5)
		
	for r in range(rows):
		for c in range(cols):
			if shape[r][c] == 1:
				var box = ColorRect.new()
				box.custom_minimum_size = Vector2(24, 24)
				box.color = color
				box.mouse_filter = Control.MOUSE_FILTER_IGNORE
				ghost_container.add_child(box)
			else:
				var empty = Control.new()
				empty.custom_minimum_size = Vector2(24, 24)
				empty.mouse_filter = Control.MOUSE_FILTER_IGNORE
				ghost_container.add_child(empty)
				
	ghost_container.visible = true

# 실행: handle repair overlay inputs (e.g. click-to-restart on game over)
func _on_repair_overlay_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var phase := str(current_scene.get("phase", ""))
		if phase == "run_complete" and bool(current_scene.get("failed", false)):
			_on_reset_pressed()
