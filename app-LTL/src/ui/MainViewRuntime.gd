# 계약:
# - 梨낆엫: UI ?붿냼?????吏곸젒?곸씤 李몄“瑜?愿由ы븯怨??ъ슜???낅젰 ?대깽?몃? ?좏샇(Signals)濡?蹂?섑빐 諛⑹텧?섎ŉ, ?섎룞 ?뚮뜑留??몄텧???ㅽ뻾?쒕떎. ?꾩떆 蹂댁셿 ?곸젏 ?⑤꼸怨?以묒븰 嫄곕? ?붿?????대㉧ 諛?紐⑥꽌由?留λ룞 鍮꾨꽕???④낵(VFX)瑜??숈쟻?쇰줈 鍮뚮뱶?쒕떎.
# - ?낅젰: MainController(?ㅼ??ㅽ듃?덉씠?????뚮뜑留?諛??곗텧 ?몄텧 紐낅졊, 媛?踰꾪듉/?щ’/????낅젰 ?대깽??
# - 異쒕젰: ?ъ슜???≪뀡??????쒓렇??諛⑹텧(reset_pressed, start_combat_pressed, hold_fire_pressed, shop_open_pressed, buy_passive, etc.)
# - 湲덉?: 鍮꾩쫰?덉뒪 ?쒕??덉씠??吏곸젒 李몄“, ?꾨찓???곹깭 蹂寃?

# 실행: define the main-scene UI view as a PanelContainer script and declare signals.
extends PanelContainer
const TooltipReadModelScript = preload("res://src/ui/read_models/TooltipReadModel.gd")
const TextCatalogScript = preload("res://src/ui/TextCatalog.gd")
const PhaseLayoutPresenterScript = preload("res://src/ui/presenters/PhaseLayoutPresenter.gd")
const ShopPanelUIScript = preload("res://src/ui/ShopPanelUI.gd")
const ArtifactTooltipUIScript = preload("res://src/ui/ArtifactTooltipUI.gd")
const GiantTimerUIScript = preload("res://src/ui/GiantTimerUI.gd")
signal reset_pressed
signal start_combat_pressed
signal hold_fire_pressed
signal repair_pressed
signal claim_rewards_pressed
signal settings_open_pressed
signal confirm_proceed_pressed
signal confirm_cancel_pressed
signal node_meta_clicked(meta: Variant)
signal reward_meta_clicked(meta: Variant)
signal reward_meta_hovered(meta: Variant)
signal reward_meta_unhovered(meta: Variant)
signal discard_zone_input(event: InputEvent)
signal repair_overlay_input(event: InputEvent)
signal backpack_slot_clicked(coord: Vector2)
signal backpack_slot_hovered(coord: Vector2)
signal backpack_slot_unhovered(coord: Vector2)
signal cell_hovered(cell_id: String, color_name: String)
signal cell_clicked(cell_id: String, color_name: String)
signal cell_pressed(cell_id: String, color: String)
signal cell_released
signal key_pressed(keycode: int)

# New Shop signals
signal shop_open_pressed
signal buy_passive(passive_id: String, cost: int)

# ?ㅽ뻾: cache UI node references.
@onready var phase_label: Label = $RootMargin/AppShell/Header/Margin/PhaseRow/PhaseLabel
@onready var stage_label: Label = $RootMargin/AppShell/Header/Margin/PhaseRow/StageLabel
@onready var node_select_text: RichTextLabel = $RootMargin/AppShell/ActivePhaseContainer/NodeSelectPanel/Margin/NodeSelectBox/NodeSelectText
@onready var reward_text: RichTextLabel = $RootMargin/AppShell/ActivePhaseContainer/RewardPanel/Margin/RewardBox/RewardRow/RewardText
@onready var reset_button: Button = $RootMargin/AppShell/ActionBar/ResetButton
@onready var start_button: Button = $RootMargin/AppShell/ActionBar/StartButton
@onready var hold_fire_button: Button = $RootMargin/AppShell/ActionBar/HoldFireButton
@onready var repair_button: Button = $RootMargin/AppShell/ActionBar/RepairButton
@onready var claim_rewards_button: Button = $RootMargin/AppShell/ActionBar/ClaimRewardsButton
@onready var settings_open_button: Button = $RootMargin/AppShell/Header/Margin/PhaseRow/SettingsOpenButton
@onready var repair_overlay: PanelContainer = $RepairOverlay
@onready var confirm_overlay: PanelContainer = $ConfirmOverlay
@onready var confirm_proceed_button: Button = $ConfirmOverlay/Center/ConfirmBox/ButtonsRow/ConfirmButton
@onready var confirm_cancel_button: Button = $ConfirmOverlay/Center/ConfirmBox/ButtonsRow/CancelButton
@onready var settings_panel = $SettingsPanel
@onready var backpack_ui = $RootMargin/AppShell/TopContent/BackpackContainer/BackpackEnginePanel
@onready var battlefield_ui = $RootMargin/AppShell/ActivePhaseContainer/BattlefieldPanel
@onready var status_panel = $RootMargin/AppShell/TopContent/LeftColumn/StatusPanel
@onready var log_console = $RootMargin/AppShell/TopContent/RightSidebar/Margin/InspectorBox/InspectorText
@onready var vfx_manager = $VFXManager
@onready var discard_zone: PanelContainer = $RootMargin/AppShell/ActivePhaseContainer/RewardPanel/Margin/RewardBox/RewardRow/DiscardZone
@onready var discard_label: Label = $RootMargin/AppShell/ActivePhaseContainer/RewardPanel/Margin/RewardBox/RewardRow/DiscardZone/DiscardLabel

# Shop UI Dynamic nodes
var shop_open_button: Button
var shop_panel: PanelContainer
var shop_gold_label: Label
var shop_xp_label: Label
var shop_buttons: Dictionary = {}
var shop_labels: Dictionary = {}
var current_shop_state: Dictionary = {}

# Giant Timer UI Dynamic nodes
var giant_timer_panel: PanelContainer
var giant_timer_label: Label
var vignette_overlay: Panel
var pulse_time: float = 0.0
var heartbeat_player: AudioStreamPlayer
var _heartbeat_volume: float = 75.0
var heartbeat_timer: float = 1.0
var giant_timer_ui

# Tooltip UI Dynamic nodes
var tooltip_panel: PanelContainer
var tooltip_label: RichTextLabel

# ?ㅽ뻾: connect raw UI signals to custom view signals for orchestrator consumption.
func _ready() -> void:
	reset_button.pressed.connect(func(): reset_pressed.emit())
	start_button.pressed.connect(func(): start_combat_pressed.emit())
	hold_fire_button.pressed.connect(func(): hold_fire_pressed.emit())
	repair_button.pressed.connect(func(): repair_pressed.emit())
	repair_button.visible = false # R button disabled/hidden since repair is automatic now
	claim_rewards_button.pressed.connect(func(): claim_rewards_pressed.emit())
	settings_open_button.pressed.connect(func(): settings_open_pressed.emit())
	confirm_proceed_button.pressed.connect(func(): confirm_proceed_pressed.emit())
	confirm_cancel_button.pressed.connect(func(): confirm_cancel_pressed.emit())
	node_select_text.meta_clicked.connect(func(meta): node_meta_clicked.emit(meta))
	reward_text.meta_clicked.connect(func(meta): reward_meta_clicked.emit(meta))
	reward_text.meta_hover_started.connect(func(meta): reward_meta_hovered.emit(meta))
	reward_text.meta_hover_ended.connect(func(meta): reward_meta_unhovered.emit(meta))
	discard_zone.gui_input.connect(func(ev): discard_zone_input.emit(ev))
	repair_overlay.gui_input.connect(func(ev):
		if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
			repair_overlay_input.emit(ev)
	)
	backpack_ui.slot_clicked.connect(func(coord): backpack_slot_clicked.emit(coord))
	backpack_ui.slot_hovered.connect(func(coord): backpack_slot_hovered.emit(coord))
	backpack_ui.slot_unhovered.connect(func(coord): backpack_slot_unhovered.emit(coord))
	battlefield_ui.cell_hovered.connect(func(cid, col): cell_hovered.emit(cid, col))
	battlefield_ui.cell_clicked.connect(func(cid, col): cell_clicked.emit(cid, col))
	battlefield_ui.cell_pressed.connect(func(cid, col): cell_pressed.emit(cid, col))
	battlefield_ui.cell_released.connect(func(): cell_released.emit())

	# Instantiate Dynamic Shop Button
	shop_open_button = Button.new()
	shop_open_button.text = TextCatalogScript.t("action.shop")
	shop_open_button.pressed.connect(func(): shop_open_pressed.emit())
	$RootMargin/AppShell/Header/Margin/PhaseRow.add_child(shop_open_button)
	$RootMargin/AppShell/Header/Margin/PhaseRow.move_child(shop_open_button, $RootMargin/AppShell/Header/Margin/PhaseRow.get_child_count() - 2)

	_create_shop_panel()

	# Instantiate Giant Timer & Vignette Overlay
	_create_giant_timer()
	_create_vignette_overlay()
	_create_tooltip_panel()

	# Connect volume slider signal
	settings_panel.volume_changed.connect(set_volume)
	settings_panel.language_changed.connect(func(_locale): apply_locale())
	apply_locale()

# ?ㅽ뻾: forward unhandled keys to presenter.
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		key_pressed.emit(event.keycode)

# ?ㅽ뻾: setup settings panel.
func setup_settings(shake_enabled: bool, is_fullscreen: bool) -> void:
	settings_panel.setup(shake_enabled, is_fullscreen)
	apply_locale()

# ?ㅽ뻾: setup backpack slots.
func setup_backpack_slots() -> void:
	backpack_ui.setup_grid_slots()

# ?ㅽ뻾: render backpack items using model data.
func render_backpack(inventory) -> void:
	backpack_ui.render_backpack_items(inventory)

# ?ㅽ뻾: update ghost item display.
func update_backpack_ghost(artifact) -> void:
	backpack_ui.update_ghost_display(artifact)

# ?ㅽ뻾: toggle settings visibility.
func toggle_settings() -> void:
	settings_panel.visible = not settings_panel.visible
	if settings_panel.visible:
		settings_panel.apply_locale()
		shop_panel.visible = false

# ?ㅽ뻾: set settings visibility directly.
func set_settings_visible(val: bool) -> void:
	settings_panel.visible = val

# ?ㅽ뻾: get settings visibility state.
func is_settings_visible() -> bool:
	return settings_panel.visible

# ?ㅽ뻾: toggle calibration shop visibility.
func toggle_shop() -> void:
	shop_panel.visible = not shop_panel.visible
	if shop_panel.visible:
		settings_panel.visible = false

# ?ㅽ뻾: set shop visibility directly.
func set_shop_visible(val: bool) -> void:
	shop_panel.visible = val

# ?ㅽ뻾: get shop visibility state.
func is_shop_visible() -> bool:
	return shop_panel.visible

# ?ㅽ뻾: render labels, manage view visibility and update status bars based on scene snapshot.
func render_scene(scene: Dictionary, show_victory_overlay: bool) -> void:
	var layout: Dictionary = PhaseLayoutPresenterScript.project(scene, show_victory_overlay)
	phase_label.text = str(layout.get("phaseText", TextCatalogScript.t("phase.label", [TextCatalogScript.t("phase.unknown")])))
	stage_label.text = str(layout.get("stageText", TextCatalogScript.t("stage.label", [1, 1])))
	$RootMargin/AppShell/ActivePhaseContainer/NodeSelectPanel.visible = bool(layout.get("nodeSelectVisible", false))
	battlefield_ui.visible = bool(layout.get("battlefieldVisible", false))
	$RootMargin/AppShell/ActivePhaseContainer/RewardPanel.visible = bool(layout.get("rewardVisible", false))
	status_panel.visible = bool(layout.get("statusVisible", false))
	shop_open_button.visible = bool(layout.get("shopButtonVisible", false))
	if bool(layout.get("closeShop", false)):
		shop_panel.visible = false
	giant_timer_panel.visible = bool(layout.get("giantTimerVisible", false))
	giant_timer_label.text = str(layout.get("timerText", "00:00"))
	vignette_overlay.visible = bool(layout.get("vignetteVisible", false))
	if giant_timer_ui != null and giant_timer_ui.has_method("apply_timer_state"):
		giant_timer_ui.apply_timer_state(str(layout.get("timerText", "00:00")), bool(layout.get("giantTimerVisible", false)), bool(layout.get("vignetteVisible", false)))
	if bool(layout.get("combatTimeActive", false)):
		battlefield_ui.update_combat_time(float(layout.get("timeLeft", 0.0)), float(layout.get("timeLimit", 0.0)), true)
	else:
		battlefield_ui.update_combat_time(0.0, 0.0, false)

	battlefield_ui.render_battlefield(scene, [])
	status_panel.render_target_bars(scene)
	status_panel.render_extractor_label(scene)
	status_panel.render_visual_queue(scene)
	status_panel.render_repair_overlay(scene, repair_overlay)

# ?ㅽ뻾: set battlefield disabled tiles.
func update_battlefield_disabled(scene: Dictionary, disabled_tiles: Array) -> void:
	battlefield_ui.render_battlefield(scene, disabled_tiles)

# 실행: skip the active reward reveal into its silhouette-count stage.
func skip_reward_reveal_to_silhouettes() -> void:
	if battlefield_ui != null and battlefield_ui.has_method("skip_reward_reveal_to_silhouettes"):
		battlefield_ui.skip_reward_reveal_to_silhouettes()

# ?ㅽ뻾: update action buttons enabled state.
func update_action_state(scene: Dictionary, show_victory_overlay: bool) -> void:
	var phase := str(scene.get("phase", "unknown"))
	start_button.disabled = not (phase == "node_select" and scene.get("nodeSelect", {}).get("candidates", []).size() > 0)
	hold_fire_button.disabled = not (phase == "combat" and bool(scene.get("hud", {}).get("aim", {}).get("canFire", false)))
	repair_button.disabled = not (phase == "combat" and bool(scene.get("hud", {}).get("repair", {}).get("available", false)))
	claim_rewards_button.disabled = (phase != "reward_loot" or show_victory_overlay)

# ?ㅽ뻾: show or hide confirm overlay.
func set_confirm_overlay_visible(val: bool) -> void:
	confirm_overlay.visible = val

# ?ㅽ뻾: append a message to the system log console.
func add_log(message: String) -> void:
	log_console.add_log(message)

# ?ㅽ뻾: update discard zone label and modulate color.
func update_discard_zone(label_text: String, is_active: bool) -> void:
	discard_label.text = label_text
	discard_zone.self_modulate = Color.WHITE if is_active else Color(0.5, 0.5, 0.5, 0.5)

# ?ㅽ뻾: get global hit position of a cell.
func get_cell_global_pos(cell_id: String) -> Vector2:
	var hit_pos = global_position + size / 2
	for child in battlefield_ui.battlefield_grid.get_children():
		if child is CellView and child.cell_id == cell_id:
			hit_pos = child.global_position + child.size / 2
			break
	return hit_pos

# ?ㅽ뻾: get global start position of the extractor.
func get_extractor_global_pos() -> Vector2:
	return status_panel.extractor_visual.global_position + status_panel.extractor_visual.size / 2

# ?ㅽ뻾: trigger resonance beam effect.
func trigger_resonance_beam(start_pos: Vector2, hit_pos: Vector2, color: String) -> void:
	vfx_manager.draw_resonance_beam(start_pos, hit_pos, color)

# ?ㅽ뻾: trigger hit particle spawn.
func trigger_hit_particles(hit_pos: Vector2, status: String, color: String) -> void:
	vfx_manager.spawn_hit_particles(hit_pos, status, color)

# ?ㅽ뻾: trigger screenshake VFX.
func trigger_screenshake(duration: float, magnitude: float) -> void:
	vfx_manager.trigger_screenshake(duration, magnitude, self)

# ?ㅽ뻾: update rich text labels directly.
func set_node_select_text(val: String) -> void:
	node_select_text.text = val

# ?ㅽ뻾: update reward text label.
func set_reward_text(val: String) -> void:
	reward_text.text = val

# 실행: refresh static view labels and buttons from the active text catalog.
func apply_locale() -> void:
	if reset_button == null:
		return
	settings_open_button.text = "⚙ %s" % TextCatalogScript.t("action.settings")
	reset_button.text = TextCatalogScript.t("action.reset")
	start_button.text = TextCatalogScript.t("action.start")
	hold_fire_button.text = TextCatalogScript.t("action.hold_fire")
	repair_button.text = TextCatalogScript.t("action.repair")
	claim_rewards_button.text = TextCatalogScript.t("action.claim_rewards")
	if shop_open_button != null:
		shop_open_button.text = TextCatalogScript.t("action.shop")
	if settings_panel != null and settings_panel.has_method("apply_locale"):
		settings_panel.apply_locale()

# ?ㅽ뻾: dynamically construct the calibration shop panel.
func _create_shop_panel() -> void:
	shop_panel = ShopPanelUIScript.new()
	shop_panel.buy_passive.connect(func(passive_id, cost): buy_passive.emit(passive_id, cost))
	add_child(shop_panel)

# 실행: update shop label and buttons.
func render_shop(growth_state: Dictionary) -> void:
	if shop_panel != null and shop_panel.has_method("render_shop"):
		shop_panel.render_shop(growth_state)
		return

# 실행: dynamically construct the central giant timer panel.
func _create_giant_timer() -> void:
	giant_timer_ui = GiantTimerUIScript.new()
	add_child(giant_timer_ui)
	giant_timer_ui.ensure_built()
	giant_timer_panel = giant_timer_ui.timer_panel
	giant_timer_label = giant_timer_ui.timer_label
	vignette_overlay = giant_timer_ui.vignette_overlay
	heartbeat_player = giant_timer_ui.heartbeat_player

# 실행: dynamically construct full-screen vignette overlay panel.
func _create_vignette_overlay() -> void:
	if giant_timer_ui != null:
		return

# 실행: animate flashing timer label and pulsing red vignette overlay when time is critical.
func _process(delta: float) -> void:
	_update_tooltip_position()
	if giant_timer_ui != null and giant_timer_ui.has_method("process_timer"):
		giant_timer_ui.process_timer(delta, battlefield_ui)
		return

# 실행: set the audio player volume.
func set_volume(val: float) -> void:
	_heartbeat_volume = val
	if giant_timer_ui != null and giant_timer_ui.has_method("set_volume"):
		giant_timer_ui.set_volume(val)
		return

# 실행: dynamically construct the floating info tooltip panel.
func _create_tooltip_panel() -> void:
	tooltip_panel = ArtifactTooltipUIScript.new()
	add_child(tooltip_panel)
	if tooltip_panel.has_method("get"):
		tooltip_label = tooltip_panel.label

# 실행: show the floating artifact info tooltip.
func show_artifact_tooltip(art) -> void:
	if tooltip_panel == null:
		return
	var tooltip_model: Dictionary = TooltipReadModelScript.project(art)
	if tooltip_panel != null and tooltip_panel.has_method("show_text"):
		tooltip_panel.show_text(str(tooltip_model.get("bbcode", "")))
		_update_tooltip_position()
		return
	tooltip_label.text = str(tooltip_model.get("bbcode", ""))
	tooltip_panel.visible = true
	_update_tooltip_position()

# 실행: show a reward tooltip with inventory comparison context.
func show_reward_tooltip(reward: Dictionary, equipped_artifacts: Array) -> void:
	if tooltip_panel == null:
		return
	var tooltip_model: Dictionary = TooltipReadModelScript.project_reward_comparison(reward, equipped_artifacts, TextCatalogScript.locale())
	if tooltip_panel != null and tooltip_panel.has_method("show_text"):
		tooltip_panel.show_text(str(tooltip_model.get("bbcode", "")))
		_update_tooltip_position()
		return
	tooltip_label.text = str(tooltip_model.get("bbcode", ""))
	tooltip_panel.visible = true
	_update_tooltip_position()

# 실행: hide the floating artifact info tooltip.
func hide_artifact_tooltip() -> void:
	if tooltip_panel and tooltip_panel.has_method("hide_tooltip"):
		tooltip_panel.hide_tooltip()
		return
	if tooltip_panel:
		tooltip_panel.visible = false

# ?ㅽ뻾: update the floating tooltip position.
func _update_tooltip_position() -> void:
	if tooltip_panel and tooltip_panel.has_method("update_position"):
		tooltip_panel.update_position(get_global_mouse_position())
		return
	if tooltip_panel and tooltip_panel.visible:
		var m_pos = get_global_mouse_position()
		tooltip_panel.global_position = m_pos + Vector2(15, 15)
