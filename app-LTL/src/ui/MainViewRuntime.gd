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
const NodeMapReadModelScript = preload("res://src/ui/read_models/NodeMapReadModel.gd")
const NodeMapSceneScript = preload("res://src/scenes/node_map/NodeMapScene.gd")
const ShopPanelUIScript = preload("res://src/ui/ShopPanelUI.gd")
const ArtifactTooltipUIScript = preload("res://src/ui/ArtifactTooltipUI.gd")
const GiantTimerUIScript = preload("res://src/ui/GiantTimerUI.gd")
const InteractionFXScript = preload("res://src/ui/InteractionFX.gd")
const NODE_SELECT_ROW_GAP := 20.0
const NODE_SELECT_MAP_MIN_WIDTH := 460.0
const NODE_SELECT_BACKPACK_MIN_WIDTH := 480.0
const NODE_SELECT_BACKPACK_MAX_WIDTH := 860.0

signal reset_pressed
signal start_combat_pressed
signal hold_fire_pressed
signal repair_pressed
signal claim_rewards_pressed
signal settings_open_pressed
signal confirm_proceed_pressed
signal confirm_cancel_pressed
signal node_meta_clicked(meta: Variant)
signal loadout_color_selected(color: String)
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
signal buy_base_item(item_id: String)

# ?ㅽ뻾: cache UI node references.
@onready var phase_label: Label = $RootMargin/AppShell/Header/Margin/PhaseRow/PhaseLabel
@onready var stage_label: Label = $RootMargin/AppShell/Header/Margin/PhaseRow/StageLabel
@onready var header_actions: HBoxContainer = $RootMargin/AppShell/Header/Margin/PhaseRow/HeaderActions
@onready var top_content: HBoxContainer = $RootMargin/AppShell/TopContent
@onready var active_phase_container: Control = $RootMargin/AppShell/ActivePhaseContainer
@onready var node_select_panel: PanelContainer = $RootMargin/AppShell/ActivePhaseContainer/NodeSelectPanel
@onready var node_select_box: VBoxContainer = $RootMargin/AppShell/ActivePhaseContainer/NodeSelectPanel/Margin/NodeSelectBox
@onready var node_select_title: Label = $RootMargin/AppShell/ActivePhaseContainer/NodeSelectPanel/Margin/NodeSelectBox/NodeSelectTitle
@onready var node_select_text: RichTextLabel = $RootMargin/AppShell/ActivePhaseContainer/NodeSelectPanel/Margin/NodeSelectBox/NodeSelectText
@onready var left_column: VBoxContainer = $RootMargin/AppShell/TopContent/LeftColumn
@onready var backpack_container: AspectRatioContainer = $RootMargin/AppShell/TopContent/BackpackContainer
@onready var right_sidebar: PanelContainer = $RootMargin/AppShell/TopContent/RightSidebar
@onready var reward_text: RichTextLabel = $RootMargin/AppShell/ActivePhaseContainer/RewardPanel/Margin/RewardBox/RewardRow/RewardText
@onready var reset_button: Button = $RootMargin/AppShell/ActionBar/ResetButton
@onready var start_button: Button = $RootMargin/AppShell/ActionBar/StartButton
@onready var hold_fire_button: Button = $RootMargin/AppShell/ActionBar/HoldFireButton
@onready var repair_button: Button = $RootMargin/AppShell/ActionBar/RepairButton
@onready var claim_rewards_button: Button = $RootMargin/AppShell/ActionBar/ClaimRewardsButton
@onready var settings_open_button: Button = $RootMargin/AppShell/Header/Margin/PhaseRow/HeaderActions/SettingsOpenButton
@onready var action_bar: HBoxContainer = $RootMargin/AppShell/ActionBar
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
var node_map_scene: NodeMapScene = null
var node_select_content_row: HBoxContainer = null
var backpack_original_parent: Node = null
var backpack_original_index: int = -1

static func node_select_backpack_width_for_row(row_size: Vector2, map_min_width: float) -> float:
	var target_height := maxf(0.0, row_size.y)
	var available_width := NODE_SELECT_BACKPACK_MAX_WIDTH
	if row_size.x > 1.0:
		available_width = maxf(0.0, row_size.x - map_min_width - NODE_SELECT_ROW_GAP)
	var upper_bound := minf(NODE_SELECT_BACKPACK_MAX_WIDTH, available_width)
	var lower_bound := minf(NODE_SELECT_BACKPACK_MIN_WIDTH, upper_bound)
	if upper_bound <= 0.0:
		return 0.0
	return clampf(target_height, lower_bound, upper_bound)

static func top_content_backpack_horizontal_flags() -> int:
	return Control.SIZE_SHRINK_CENTER

static func top_content_side_horizontal_flags() -> int:
	return Control.SIZE_EXPAND_FILL

static func top_content_backpack_width_for_height(target_height: float) -> float:
	var safe_height := maxf(0.0, target_height)
	if safe_height <= 0.0:
		return 0.0
	return maxf(safe_height, 420.0)

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
	header_actions.add_child(shop_open_button)

	_create_shop_panel()
	_create_node_map_scene()
	backpack_original_parent = backpack_container.get_parent()
	backpack_original_index = backpack_container.get_index()

	# Instantiate Giant Timer & Vignette Overlay
	_create_giant_timer()
	_create_vignette_overlay()
	_create_tooltip_panel()

	# Connect volume slider signal
	settings_panel.volume_changed.connect(set_volume)
	settings_panel.language_changed.connect(func(_locale): apply_locale())
	_apply_shell_theme()
	apply_locale()
	call_deferred("_install_interaction_fx")

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
	var node_map_full_page := bool(layout.get("nodeMapFullPage", false))
	_apply_node_select_backpack_dock(str(layout.get("nodeSelectBackpackDock", "top")), float(layout.get("nodeMapStretchRatio", 2.1)), float(layout.get("backpackStretchRatio", 1.0)))
	_apply_top_content_stretch(float(layout.get("leftColumnTopStretchRatio", 3.5)), float(layout.get("backpackTopStretchRatio", 6.0)), float(layout.get("rightSidebarTopStretchRatio", 2.5)))
	top_content.visible = bool(layout.get("topContentVisible", true))
	left_column.visible = bool(layout.get("sidebarsVisible", true))
	right_sidebar.visible = bool(layout.get("sidebarsVisible", true))
	backpack_container.visible = bool(layout.get("backpackVisible", true))
	if node_map_full_page:
		backpack_container.custom_minimum_size = Vector2(_node_select_backpack_width(), 0.0)
	elif top_content.visible:
		backpack_container.custom_minimum_size = Vector2(_top_content_backpack_width(), 0.0)
	else:
		backpack_container.custom_minimum_size = Vector2.ZERO
	active_phase_container.size_flags_stretch_ratio = float(layout.get("activePhaseStretchRatio", 1.0))
	node_select_panel.visible = bool(layout.get("nodeSelectVisible", false))
	node_select_title.visible = not node_map_full_page
	node_select_text.visible = not node_map_full_page and node_map_scene == null
	if node_map_scene != null:
		node_map_scene.visible = bool(layout.get("nodeSelectVisible", false))
	battlefield_ui.visible = bool(layout.get("battlefieldVisible", false))
	$RootMargin/AppShell/ActivePhaseContainer/RewardPanel.visible = bool(layout.get("rewardVisible", false))
	status_panel.visible = bool(layout.get("statusVisible", false))
	shop_open_button.visible = bool(layout.get("shopButtonVisible", false))
	if backpack_ui != null and backpack_ui.has_method("set_cooldown_visuals_enabled"):
		backpack_ui.set_cooldown_visuals_enabled(bool(layout.get("backpackCooldownVisible", false)))
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
	if bool(layout.get("nodeSelectVisible", false)) and node_map_scene != null:
		var node_map_model: Dictionary = NodeMapReadModelScript.project(scene, int(scene.get("selectedNodeIndex", 0)))
		node_map_scene.render(node_map_model)
		call_deferred("_sync_node_select_backpack_width")
	status_panel.render_target_bars(scene)
	status_panel.render_extractor_label(scene)
	status_panel.render_visual_queue(scene)
	status_panel.render_repair_overlay(scene, repair_overlay)
	call_deferred("_install_interaction_fx")

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
	node_select_text.visible = node_map_scene == null

# ?ㅽ뻾: update reward text label.
func set_reward_text(val: String) -> void:
	reward_text.text = val

# 실행: refresh static view labels and buttons from the active text catalog.
func apply_locale() -> void:
	if reset_button == null:
		return
	_set_label_text("RootMargin/AppShell/Header/Margin/PhaseRow/TitleLabel", TextCatalogScript.t("app.title"))
	_set_label_text("RootMargin/AppShell/TopContent/LeftColumn/LeftSidebar/Margin/CharacterBox/CharacterTitle", TextCatalogScript.t("panel.character_status"))
	_set_label_text("RootMargin/AppShell/TopContent/LeftColumn/LeftSidebar/Margin/CharacterBox/PortraitPlaceholder/PortraitLabel", TextCatalogScript.t("panel.profile"))
	_set_rich_text("RootMargin/AppShell/TopContent/LeftColumn/LeftSidebar/Margin/CharacterBox/InventorySummaryLabel", TextCatalogScript.t("panel.loadout"))
	_set_label_text("RootMargin/AppShell/TopContent/LeftColumn/StatusPanel/Margin/StatusBox/StatusTitle", TextCatalogScript.t("panel.drill_node_status"))
	_set_label_text("RootMargin/AppShell/TopContent/LeftColumn/StatusPanel/Margin/StatusBox/HPBox/HealthLabel", TextCatalogScript.t("panel.health"))
	_set_label_text("RootMargin/AppShell/TopContent/LeftColumn/StatusPanel/Margin/StatusBox/ShieldBox/ShieldLabel", TextCatalogScript.t("panel.shield"))
	_set_label_text("RootMargin/AppShell/TopContent/LeftColumn/StatusPanel/Margin/StatusBox/QueueRow/QueueLabel", TextCatalogScript.t("panel.queue"))
	_set_label_text("RootMargin/AppShell/TopContent/LeftColumn/StatusPanel/Margin/StatusBox/TimerRow/PinLabel", TextCatalogScript.t("panel.stage_timer"))
	_set_label_text("RootMargin/AppShell/TopContent/LeftColumn/StatusPanel/Margin/StatusBox/DrillStatusRow/DrillStatusLabel", TextCatalogScript.t("panel.drill_status"))
	_set_label_text("RootMargin/AppShell/TopContent/BackpackContainer/BackpackEnginePanel/Margin/EngineBox/EngineTitle", TextCatalogScript.t("panel.backpack"))
	_set_label_text("RootMargin/AppShell/TopContent/RightSidebar/Margin/InspectorBox/InspectorTitle", TextCatalogScript.t("panel.log"))
	_set_label_text("RootMargin/AppShell/ActivePhaseContainer/NodeSelectPanel/Margin/NodeSelectBox/NodeSelectTitle", TextCatalogScript.t("panel.next_node"))
	_set_label_text("RootMargin/AppShell/ActivePhaseContainer/BattlefieldPanel/Margin/BattlefieldBox/BattlefieldTitle", TextCatalogScript.t("panel.battlefield"))
	_set_label_text("RootMargin/AppShell/ActivePhaseContainer/RewardPanel/Margin/RewardBox/RewardTitle", TextCatalogScript.t("panel.rewards"))
	_set_label_text("ConfirmOverlay/Center/ConfirmBox/WarningLabel", TextCatalogScript.t("confirm.unclaimed.title"))
	_set_label_text("ConfirmOverlay/Center/ConfirmBox/DescriptionLabel", TextCatalogScript.t("confirm.unclaimed.desc"))
	confirm_proceed_button.text = TextCatalogScript.t("action.proceed")
	confirm_cancel_button.text = TextCatalogScript.t("action.cancel")
	settings_open_button.text = TextCatalogScript.t("action.settings")
	reset_button.text = TextCatalogScript.t("action.reset")
	start_button.text = TextCatalogScript.t("action.start")
	hold_fire_button.text = TextCatalogScript.t("action.hold_fire")
	repair_button.text = TextCatalogScript.t("action.repair")
	claim_rewards_button.text = TextCatalogScript.t("action.claim_rewards")
	if shop_open_button != null:
		shop_open_button.text = TextCatalogScript.t("action.shop")
	if settings_panel != null and settings_panel.has_method("apply_locale"):
		settings_panel.apply_locale()
	if shop_panel != null and shop_panel.has_method("apply_locale"):
		shop_panel.apply_locale()
	_apply_shell_theme()

# 실행: set a Label text by relative path when present.
func _set_label_text(path: String, text: String) -> void:
	var node := get_node_or_null(path) as Label
	if node != null:
		node.text = text

# 실행: set a RichTextLabel text by relative path when present.
func _set_rich_text(path: String, text: String) -> void:
	var node := get_node_or_null(path) as RichTextLabel
	if node != null:
		node.text = text

# ?ㅽ뻾: dynamically construct the calibration shop panel.
func _create_shop_panel() -> void:
	shop_panel = ShopPanelUIScript.new()
	shop_panel.buy_passive.connect(func(passive_id, cost): buy_passive.emit(passive_id, cost))
	shop_panel.buy_base_item.connect(func(item_id): buy_base_item.emit(item_id))
	add_child(shop_panel)

# ?ㅽ뻾: dynamically construct the full-page node-map selector inside the node-select panel.
func _create_node_map_scene() -> void:
	node_select_content_row = HBoxContainer.new()
	node_select_content_row.name = "NodeMapBackpackRow"
	node_select_content_row.alignment = BoxContainer.ALIGNMENT_BEGIN
	node_select_content_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	node_select_content_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	node_select_content_row.add_theme_constant_override("separation", int(NODE_SELECT_ROW_GAP))
	node_select_box.add_child(node_select_content_row)
	node_map_scene = NodeMapSceneScript.new()
	node_map_scene.name = "NodeMapPage"
	node_map_scene.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	node_map_scene.size_flags_vertical = Control.SIZE_EXPAND_FILL
	node_map_scene.custom_minimum_size = Vector2(0, 360)
	node_map_scene.node_selected.connect(func(index): node_meta_clicked.emit(index))
	node_map_scene.color_selected.connect(func(color): loadout_color_selected.emit(color))
	node_select_content_row.add_child(node_map_scene)

# 실행: place the backpack beside the node map only during node selection.
func _apply_node_select_backpack_dock(dock: String, map_ratio: float, backpack_ratio: float) -> void:
	if node_select_content_row == null or backpack_original_parent == null:
		return
	if dock == "right":
		if backpack_container.get_parent() != node_select_content_row:
			backpack_container.get_parent().remove_child(backpack_container)
			node_select_content_row.add_child(backpack_container)
		if node_map_scene != null:
			node_map_scene.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			node_map_scene.size_flags_stretch_ratio = map_ratio
		backpack_container.size_flags_stretch_ratio = backpack_ratio
		backpack_container.size_flags_horizontal = Control.SIZE_SHRINK_END
		backpack_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
		backpack_container.custom_minimum_size = Vector2(_node_select_backpack_width(), 0)
	else:
		if backpack_container.get_parent() != backpack_original_parent:
			backpack_container.get_parent().remove_child(backpack_container)
			backpack_original_parent.add_child(backpack_container)
			if backpack_original_index >= 0:
				backpack_original_parent.move_child(backpack_container, backpack_original_index)
		backpack_container.size_flags_stretch_ratio = 0.0
		backpack_container.size_flags_horizontal = top_content_backpack_horizontal_flags()
		backpack_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
		backpack_container.custom_minimum_size = Vector2.ZERO

func _node_select_backpack_width() -> float:
	var row_size := Vector2.ZERO
	if node_select_content_row != null:
		row_size = node_select_content_row.size
	if row_size.y <= 1.0:
		row_size.y = maxf(active_phase_container.size.y, node_select_panel.size.y)
	if row_size.x <= 1.0:
		row_size.x = node_select_panel.size.x
	return node_select_backpack_width_for_row(row_size, NODE_SELECT_MAP_MIN_WIDTH)

func _sync_node_select_backpack_width() -> void:
	if node_select_content_row == null or backpack_container.get_parent() != node_select_content_row:
		return
	backpack_container.custom_minimum_size = Vector2(_node_select_backpack_width(), 0.0)
	backpack_container.size_flags_horizontal = Control.SIZE_SHRINK_END
	backpack_container.size_flags_vertical = Control.SIZE_EXPAND_FILL

func _top_content_backpack_width() -> float:
	var target_height := maxf(top_content.size.y, backpack_container.size.y)
	return top_content_backpack_width_for_height(target_height)

# 실행: update shop label and buttons.
func render_shop(growth_state: Dictionary) -> void:
	if shop_panel != null and shop_panel.has_method("render_shop"):
		shop_panel.render_shop(growth_state)
		call_deferred("_install_interaction_fx")
		return

# 실행: install shader/tween affordance effects on interactive controls.
func _install_interaction_fx() -> void:
	InteractionFXScript.install_tree(self)

# 실행: give major panels and buttons a coherent in-world UI language.
func _apply_shell_theme() -> void:
	var surface := StyleBoxFlat.new()
	surface.bg_color = Color(0.10, 0.13, 0.17, 0.98)
	surface.border_width_left = 1
	surface.border_width_top = 1
	surface.border_width_right = 1
	surface.border_width_bottom = 1
	surface.border_color = Color(0.24, 0.30, 0.38, 1.0)
	surface.corner_radius_top_left = 12
	surface.corner_radius_top_right = 12
	surface.corner_radius_bottom_right = 12
	surface.corner_radius_bottom_left = 12
	surface.shadow_color = Color(0.0, 0.0, 0.0, 0.22)
	surface.shadow_size = 8
	surface.shadow_offset = Vector2(0, 3)
	node_select_panel.add_theme_stylebox_override("panel", surface)
	status_panel.add_theme_stylebox_override("panel", surface)
	backpack_ui.add_theme_stylebox_override("panel", surface)
	right_sidebar.add_theme_stylebox_override("panel", surface)
	battlefield_ui.add_theme_stylebox_override("panel", surface)
	for button in [settings_open_button, reset_button, start_button, hold_fire_button, repair_button, claim_rewards_button, shop_open_button]:
		if button != null:
			_style_shell_button(button)

func _style_shell_button(button: Button) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.13, 0.16, 0.20, 0.98)
	normal.border_width_left = 1
	normal.border_width_top = 1
	normal.border_width_right = 1
	normal.border_width_bottom = 1
	normal.border_color = Color(0.24, 0.30, 0.38, 1.0)
	normal.corner_radius_top_left = 10
	normal.corner_radius_top_right = 10
	normal.corner_radius_bottom_right = 10
	normal.corner_radius_bottom_left = 10
	var hover := normal.duplicate()
	hover.bg_color = Color(0.16, 0.20, 0.25, 1.0)
	hover.border_color = Color(0.50, 0.67, 0.76, 1.0)
	var pressed := normal.duplicate()
	pressed.bg_color = Color(0.11, 0.14, 0.18, 1.0)
	pressed.border_color = Color(0.85, 0.77, 0.49, 1.0)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("focus", hover)
	button.add_theme_font_size_override("font_size", 14)
	button.add_theme_color_override("font_color", Color(0.93, 0.95, 0.97))
	normal.content_margin_left = 16
	normal.content_margin_right = 16
	hover.content_margin_left = 16
	hover.content_margin_right = 16
	pressed.content_margin_left = 16
	pressed.content_margin_right = 16
	button.custom_minimum_size.x = maxf(button.custom_minimum_size.x, _shell_button_min_width(button))
	button.custom_minimum_size.y = maxf(button.custom_minimum_size.y, 40.0)

func _apply_top_content_stretch(left_ratio: float, backpack_ratio: float, right_ratio: float) -> void:
	left_column.size_flags_horizontal = top_content_side_horizontal_flags()
	left_column.size_flags_stretch_ratio = left_ratio
	if backpack_container.get_parent() == backpack_original_parent:
		backpack_container.size_flags_horizontal = top_content_backpack_horizontal_flags()
	backpack_container.size_flags_stretch_ratio = backpack_ratio
	right_sidebar.size_flags_horizontal = top_content_side_horizontal_flags()
	right_sidebar.size_flags_stretch_ratio = right_ratio

func _shell_button_min_width(button: Button) -> float:
	if button == null:
		return 96.0
	if button.get_parent() == header_actions:
		return 108.0
	if button.get_parent() == action_bar:
		return 136.0
	return 112.0

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
