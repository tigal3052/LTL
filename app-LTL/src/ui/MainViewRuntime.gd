# 계약:
# - 책임: 메인 런타임 화면의 페이지 셸, 전투 HUD, 오버레이, 입력 신호를 한 화면에서 조율한다.
# 실행: define the main-scene UI view as a PanelContainer script and declare signals.
# 怨꾩빟:
# - 筌?굞?? UI ?遺용꺖??????筌욊낯??怨몄뵥 筌〓챷?쒐몴??온?귐뗫릭?????????낆젾 ??源?紐? ?醫륁깈(Signals)嚥?癰궰??묐퉸 獄쎻뫗???렽? ??롫짗 ???쐭筌??紐꾪뀱????쎈뻬??뺣뼄. ?袁⑸뻻 癰귣똻???怨몄젎 ??ㅺ섯??餓λ쵐釉?椰꾧퀡? ?遺?????????獄?筌뤴뫁苑뚨뵳?筌띘삳짗 ??쑬苑????ｋ궢(VFX)????덉읅??곗쨮 ??슢諭??뺣뼄.
# - ??낆젾: MainController(?????쎈뱜??됱뵠???????쐭筌?獄??怨쀭뀱 ?紐꾪뀱 筌뤿굝議? 揶?甕곌쑵????????????낆젾 ??源??
# - ?곗뮆?? ???????る????????볥젃??獄쎻뫗??reset_pressed, start_combat_pressed, hold_fire_pressed, shop_open_pressed, buy_passive, etc.)
# - 疫뀀뜆?: ??쑴已??됰뮞 ?????됱뵠??筌욊낯??筌〓챷?? ?袁⑥컭???怨밴묶 癰궰野?

extends PanelContainer
const TooltipReadModelScript = preload("res://src/ui/read_models/TooltipReadModel.gd")
const TextCatalogScript = preload("res://src/ui/TextCatalog.gd")
const HudReadModelScript = preload("res://src/ui/read_models/HudReadModel.gd")
const FailureReadModelScript = preload("res://src/ui/read_models/FailureReadModel.gd")
const AppShellLayoutPolicyScript = preload("res://src/ui/presenters/AppShellLayoutPolicy.gd")
const PhaseLayoutPresenterScript = preload("res://src/ui/presenters/PhaseLayoutPresenter.gd")
const RewardBoardLayoutPolicyScript = preload("res://src/ui/presenters/RewardBoardLayoutPolicy.gd")
const RewardCeremonyPolicyScript = preload("res://src/ui/presenters/RewardCeremonyPolicy.gd")
const BackpackPinLayoutPolicyScript = preload("res://src/ui/presenters/BackpackPinLayoutPolicy.gd")
const ShellButtonStylerScript = preload("res://src/ui/presenters/ShellButtonStyler.gd")
const LTLThemeScript = preload("res://src/ui/theme/LTLTheme.gd")
const ShopPanelUIScript = preload("res://src/ui/ShopPanelUI.gd")
const PopupOverlayHostScript = preload("res://src/ui/PopupOverlayHost.gd")
const PageSceneRegistryScript = preload("res://src/ui/PageSceneRegistry.gd")
const PageSceneModelBuilderScript = preload("res://src/ui/PageSceneModelBuilder.gd")
const ArtifactCodexPanelUIScript = preload("res://src/ui/ArtifactCodexPanelUI.gd")
const ArtifactCodexReadModelScript = preload("res://src/ui/read_models/ArtifactCodexReadModel.gd")
const ArtifactTooltipUIScript = preload("res://src/ui/ArtifactTooltipUI.gd")
const GiantTimerUIScript = preload("res://src/ui/GiantTimerUI.gd")
const RewardRevealOverlayScript = preload("res://src/ui/RewardRevealOverlay.gd")
const RewardCardCloudHostScript = preload("res://src/ui/RewardCardCloudHost.gd")
const SharedBackpackHostCoordinatorScript = preload("res://src/ui/SharedBackpackHostCoordinator.gd")
const InteractionFXScript = preload("res://src/ui/InteractionFX.gd")
const CharacterSelectPageScene = preload("res://src/scenes/pages/CharacterSelectPage.tscn")
const LeviathanSelectPageScene = preload("res://src/scenes/pages/LeviathanSelectPage.tscn")
const NodeSelectRuntimePageScene = preload("res://src/scenes/pages/NodeSelectRuntimePage.tscn")
const BattlePageScene = preload("res://src/scenes/pages/BattlePage.tscn")
const BossBattlePageScene = preload("res://src/scenes/pages/BossBattlePage.tscn")
const RewardPageScene = preload("res://src/scenes/pages/RewardPage.tscn")
const BossRewardPageScene = preload("res://src/scenes/pages/BossRewardPage.tscn")
const EventNodePageScene = preload("res://src/scenes/pages/EventNodePage.tscn")
const DefeatPageScene = preload("res://src/scenes/pages/DefeatPage.tscn")
const ClearPageScene = preload("res://src/scenes/pages/ClearPage.tscn")
const META_PAGE_IDS := ["character_select", "leviathan_select", "clear", "defeat"]
const SURFACE_PAGE_IDS := ["battle", "boss_battle", "reward", "boss_reward"]
const ACTION_BAR_PAGE_IDS := ["node_select", "battle", "boss_battle", "reward", "boss_reward"]
const NODE_SELECT_MAP_MIN_WIDTH := 460.0
const VIEWPORT_SAFE_GUTTER := 16.0
const POPUP_OVERLAY_Z_INDEX := 500
const REWARD_REVEAL_OVERLAY_Z_INDEX := 600
const REWARD_INSPECTOR_FACT_MIN_HEIGHT := 58.0
const REWARD_FOOTPRINT_MIN_COLUMNS := 4
const REWARD_FOOTPRINT_MIN_ROWS := 2
const REWARD_FOOTPRINT_CELL_SIZE := 20.0
const REWARD_FOOTPRINT_CELL_GAP := 6.0
const REWARD_BOARD_TOP_ZONE_MIN_HEIGHT := 280.0
const REWARD_BOARD_BOTTOM_ROW_MIN_HEIGHT := 132.0
const REWARD_BOARD_BOTTOM_ROW_RATIO := 0.22
const CHARACTER_PORTRAIT_PATH := "res://resources/charactor/charactor1.png"
const CHARACTER_SPRITE_SHEET_PATH := "res://resources/charactor/charactor1_ss.png"
const REWARD_BACKDROP_PATH := "res://resources/Leviathan/Leviathan_lizard.png"
const FAILURE_BACKDROP_PATH := "res://resources/Leviathan/Leviathan_golem.png"

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
signal reward_meta_drag_started(meta: Variant)
signal reward_meta_drop_requested(meta: Variant, coord: Vector2)
signal reward_meta_discard_requested(meta: Variant)
signal reward_meta_drag_canceled(meta: Variant)
signal discard_zone_input(event: InputEvent)
signal repair_overlay_input(event: InputEvent)
signal backpack_slot_clicked(coord: Vector2)
signal backpack_slot_hovered(coord: Vector2)
signal backpack_slot_unhovered(coord: Vector2)
signal backpack_slot_drag_started(coord: Vector2)
signal backpack_slot_drop_requested(origin_coord: Vector2, coord: Vector2)
signal backpack_slot_discard_requested(origin_coord: Vector2)
signal backpack_slot_drag_canceled(origin_coord: Vector2)
signal cell_hovered(cell_id: String, color_name: String)
signal cell_clicked(cell_id: String, color_name: String)
signal cell_pressed(cell_id: String, color: String)
signal cell_released
signal key_pressed(keycode: int)
signal combat_overlay_pause_visibility_changed(active: bool)
signal character_selected(character_id: String)
signal character_continue_pressed
signal leviathan_selected(leviathan_id: String)
signal looting_start_pressed
signal return_to_character_select_pressed

# New Shop signals
signal shop_open_pressed
signal codex_open_pressed
signal buy_passive(passive_id: String, cost: int)
signal buy_base_item(item_id: String)

# ??쎈뻬: cache UI node references.
@onready var header_panel: PanelContainer = $RootMargin/AppShell/Header
@onready var header_title_label: Label = $RootMargin/AppShell/Header/Margin/PhaseRow/TitleLabel
@onready var root_margin: MarginContainer = $RootMargin
@onready var app_shell: VBoxContainer = $RootMargin/AppShell
@onready var phase_label: Label = $RootMargin/AppShell/Header/Margin/PhaseRow/PhaseLabel
@onready var stage_label: Label = $RootMargin/AppShell/Header/Margin/PhaseRow/StageLabel
@onready var header_actions: HBoxContainer = $RootMargin/AppShell/Header/Margin/PhaseRow/HeaderActions
@onready var active_phase_container: Control = $RootMargin/AppShell/ActivePhaseContainer
@onready var settings_open_button: Button = $RootMargin/AppShell/Header/Margin/PhaseRow/HeaderActions/SettingsOpenButton
@onready var repair_overlay: PanelContainer = $RepairOverlay
@onready var confirm_overlay: PanelContainer = $ConfirmOverlay
@onready var confirm_proceed_button: Button = $ConfirmOverlay/Center/ConfirmBox/ButtonsRow/ConfirmButton
@onready var confirm_cancel_button: Button = $ConfirmOverlay/Center/ConfirmBox/ButtonsRow/CancelButton
@onready var settings_panel = $SettingsPanel
@onready var vfx_manager = $VFXManager
var top_content: HBoxContainer
var left_column: VBoxContainer
var portrait_placeholder: Panel
var portrait_label: Label
var backpack_container: AspectRatioContainer
var right_sidebar: PanelContainer
var reward_panel: PanelContainer
var reward_panel_margin: MarginContainer
var reward_box: VBoxContainer
var reward_board_head: HBoxContainer
var reward_board_scroll: ScrollContainer
var reward_board: VBoxContainer
var reward_grid: HBoxContainer
var reward_rewards_zone: PanelContainer
var reward_workspace_zone: PanelContainer
var reward_workspace_margin: MarginContainer
var reward_workspace_box: VBoxContainer
var reward_workspace_head: VBoxContainer
var reward_workspace_title: Label
var reward_inspector_zone: PanelContainer
var reward_bottom_row: HBoxContainer
var reward_title: Label
var reward_subtitle: Label
var reward_mode_pill: Label
var reward_card_grid: Control
var reward_cloud_content: VBoxContainer
var reward_cloud_box: PanelContainer
var reward_cloud_note: Label
var reward_workspace_note: RichTextLabel
var reward_backpack_host: Control
var reward_inspector_kicker: Label
var reward_inspector_name: Label
var reward_inspector_summary: RichTextLabel
var reward_inspector_facts: GridContainer
var reward_inspector_stage: VBoxContainer
var reward_footprint_title: Label
var reward_footprint_info: Label
var reward_footprint_grid: GridContainer
var reset_button: Button
var start_button: Button
var hold_fire_button: Button
var repair_button: Button
var claim_rewards_button: Button
var action_bar: HBoxContainer
var backpack_ui
var battlefield_ui
var status_panel
var log_console
var discard_zone: PanelContainer
var confirm_zone: PanelContainer
var discard_card: PanelContainer
var claim_card: PanelContainer
var discard_label: Label
var claim_card_body: Label
var claim_inline_button: Button

# Shop UI Dynamic nodes
var shop_open_button: Button
var shop_panel: PanelContainer
var codex_open_button: Button
var codex_panel: ArtifactCodexPanelUI
var current_codex_reward_table: Dictionary = {}
var current_codex_growth_state: Dictionary = {}
var current_codex_debug_all := false
var current_codex_selected_entry_id := ""
var current_codex_active_section := "all"

# Giant Timer UI Dynamic nodes
var giant_timer_panel: PanelContainer
var giant_timer_label: Label
var vignette_overlay: Panel
var pulse_time: float = 0.0
var heartbeat_player: AudioStreamPlayer
var _heartbeat_volume: float = 75.0
var heartbeat_timer: float = 1.0
var giant_timer_ui
var reward_reveal_overlay
var reward_reveal_done_bridge: Callable = Callable()
var reward_reveal_pending_callback: Callable = Callable()
var reward_reveal_pending_step := ""

# Tooltip UI Dynamic nodes
var tooltip_panel: PanelContainer
var tooltip_label: RichTextLabel
var node_select_content_row: HBoxContainer = null
var node_select_runtime_page: Control = null
var node_select_backpack_host: Control = null
var portrait_art: TextureRect
var portrait_idle: TextureRect
var reward_backdrop: TextureRect
var failure_backdrop: TextureRect
var reward_card_buttons: Array = []
var _reward_card_manual_anchor_norms: Dictionary = {}
var _reward_drag_index := -1
var _reward_drag_active := false
var _reward_drag_button: Control = null
var _reward_drag_pointer_offset := Vector2.ZERO
var _backpack_drag_origin := Vector2(-1, -1)
var _backpack_drag_active := false
var backpack_original_parent: Node = null
var backpack_original_index: int = -1
var interaction_fx_enabled := true
var _pending_backpack_parent: Node = null
var _pending_backpack_parent_index := -1
var _backpack_reparent_pending := false
var _pending_backpack_pin_scene: Dictionary = {}
var _shared_backpack_layout_sync_pending := false
var _reward_board_layout_sync_pending := false
var _view_layout_ready := false
var _viewport_shell_sync_pending := false
var _last_viewport_shell_size := Vector2.ZERO
var battle_pause_active := false
var _last_combat_pause_overlay_visible := false
var _last_rendered_scene: Dictionary = {}
var page_shell_host: Control
var meta_page_shell_host: Control
var page_scenes: Dictionary = {}
var page_shell_bundles: Dictionary = {}
var _active_surface_bundle_id := "battle"
var _active_action_bar_bundle_id := "node_select"
var active_page_id := ""
var character_select_page: Control
var leviathan_select_page: Control
var reward_cloud_scroll: ScrollContainer = null
var discard_card_scroll: ScrollContainer = null
var claim_card_scroll: ScrollContainer = null
var reward_inspector_scroll: ScrollContainer = null

static func node_select_backpack_width_for_row(row_size: Vector2, map_min_width: float) -> float:
	return SharedBackpackHostCoordinatorScript.node_select_backpack_width_for_row(row_size, map_min_width)

static func top_content_backpack_horizontal_flags() -> int:
	return SharedBackpackHostCoordinatorScript.top_content_backpack_horizontal_flags()

static func top_content_side_horizontal_flags() -> int:
	return SharedBackpackHostCoordinatorScript.top_content_side_horizontal_flags()

static func top_content_backpack_slot_extent_for_height(target_height: float) -> float:
	return BackpackPinLayoutPolicyScript.top_content_slot_extent_for_height(target_height)

static func top_content_backpack_pin_side_outset_for_height(target_height: float) -> float:
	return BackpackPinLayoutPolicyScript.top_content_side_outset_for_height(target_height)

static func top_content_backpack_width_for_height(target_height: float) -> float:
	return BackpackPinLayoutPolicyScript.top_content_width_for_height(target_height)

static func top_content_backpack_ratio_for_height(target_height: float) -> float:
	return BackpackPinLayoutPolicyScript.top_content_ratio_for_height(target_height)

static func resolved_top_content_backpack_height(row_height: float, min_row_height: float, _current_backpack_height: float) -> float:
	return BackpackPinLayoutPolicyScript.resolved_top_content_height(row_height, min_row_height)

static func popup_overlay_z_index() -> int:
	return POPUP_OVERLAY_Z_INDEX

static func reward_reveal_overlay_z_index() -> int:
	return REWARD_REVEAL_OVERLAY_Z_INDEX

# ??쎈뻬: connect raw UI signals to custom view signals for orchestrator consumption.
func _ready() -> void:
	add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	theme = LTLThemeScript.shared_theme()
	_create_page_scenes()
	_cache_page_shell_bundles()
	_activate_surface_bundle("battle")
	_activate_action_bar_bundle("node_select")

	settings_open_button.pressed.connect(func(): settings_open_pressed.emit())
	confirm_proceed_button.pressed.connect(func(): confirm_proceed_pressed.emit())
	confirm_cancel_button.pressed.connect(func(): confirm_cancel_pressed.emit())
	repair_overlay.gui_input.connect(func(ev):
		if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
			repair_overlay_input.emit(ev)
	)
	settings_panel.visibility_changed.connect(func():
		_promote_popup_overlay_when_visible(settings_panel)
		_emit_combat_overlay_pause_visibility_changed()
	)
	confirm_overlay.visibility_changed.connect(func(): _promote_popup_overlay_when_visible(confirm_overlay))
	repair_overlay.visibility_changed.connect(func(): _promote_popup_overlay_when_visible(repair_overlay))
	_connect_page_shell_bundle_signals()
	resized.connect(_queue_shared_backpack_layout_sync)
	active_phase_container.resized.connect(_queue_shared_backpack_layout_sync)
	if page_shell_host != null:
		page_shell_host.resized.connect(_sync_page_scene_bounds)
	if meta_page_shell_host != null:
		meta_page_shell_host.resized.connect(_sync_page_scene_bounds)

	# Instantiate Dynamic Shop Button
	shop_open_button = Button.new()
	shop_open_button.text = TextCatalogScript.t("action.shop")
	shop_open_button.pressed.connect(func(): shop_open_pressed.emit())
	header_actions.add_child(shop_open_button)
	codex_open_button = Button.new()
	codex_open_button.text = TextCatalogScript.t("action.codex")
	codex_open_button.pressed.connect(func(): codex_open_pressed.emit())
	header_actions.add_child(codex_open_button)

	_create_shop_panel()
	_create_artifact_codex_panel()
	_install_character_presentation()
	_install_reward_backdrop()
	_install_failure_backdrop()
	backpack_original_parent = _active_surface_bundle().get("backpackOriginalParent", null)
	backpack_original_index = int(_active_surface_bundle().get("backpackOriginalIndex", -1))

	# Instantiate Giant Timer & Vignette Overlay
	_create_giant_timer()
	_create_reward_reveal_overlay()
	_create_vignette_overlay()
	_create_tooltip_panel()

	# Connect volume slider signal
	settings_panel.volume_changed.connect(set_volume)
	settings_panel.language_changed.connect(func(_locale): apply_locale())
	_apply_shell_theme()
	apply_locale()
	_defer_interaction_fx_install()
	_view_layout_ready = true
	_emit_combat_overlay_pause_visibility_changed()
	_sync_page_scene_bounds()
	_queue_viewport_shell_sync()
	_queue_shared_backpack_layout_sync()
	_queue_reward_board_layout_sync()

func _apply_shared_split_layout_text_policies() -> void:
	_apply_wrapping_label_policy(reward_inspector_name)
	_apply_wrapping_label_policy(reward_cloud_note)
	_apply_wrapping_label_policy(discard_label)
	_apply_wrapping_label_policy(claim_card_body)
	_apply_wrapping_rich_text_policy(reward_workspace_note)
	_apply_wrapping_rich_text_policy(reward_inspector_summary)

func _apply_wrapping_label_policy(label: Label) -> void:
	if label == null:
		return
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

func _apply_wrapping_rich_text_policy(label: RichTextLabel) -> void:
	if label == null:
		return
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.fit_content = false
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.scroll_active = false

# ??쎈뻬: forward unhandled keys to presenter.
func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and _view_layout_ready:
		var viewport_size := get_viewport_rect().size
		if _last_viewport_shell_size.distance_to(viewport_size) > 0.5:
			_queue_viewport_shell_sync()

func _queue_viewport_shell_sync() -> void:
	if _viewport_shell_sync_pending:
		return
	_viewport_shell_sync_pending = true
	call_deferred("_sync_viewport_shell_bounds")

func _sync_viewport_shell_bounds() -> void:
	_viewport_shell_sync_pending = false
	if not is_inside_tree():
		return
	var viewport_size := get_viewport_rect().size
	if viewport_size.x <= 1.0 or viewport_size.y <= 1.0:
		return
	_last_viewport_shell_size = viewport_size
	custom_minimum_size = Vector2.ZERO
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	clip_contents = true
	_queue_shared_backpack_layout_sync()
	if reward_panel != null and reward_panel.visible:
		_queue_reward_board_layout_sync()

func _input(event: InputEvent) -> void:
	if not (_reward_drag_active or _backpack_drag_active):
		return
	if event is InputEventMouseMotion and _reward_drag_active:
		_update_reward_drag_card_position()
	if event is InputEventMouseButton and not event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var mouse_pos := get_global_mouse_position()
		var drop_coord: Vector2 = backpack_ui.slot_coord_at_global_pos(get_global_mouse_position()) if backpack_ui != null and backpack_ui.has_method("slot_coord_at_global_pos") else Vector2(-1, -1)
		if _reward_drag_active:
			if drop_coord.x >= 0.0 and drop_coord.y >= 0.0:
				reward_meta_drop_requested.emit(_reward_drag_index, drop_coord)
			elif discard_zone != null and discard_zone.get_global_rect().has_point(get_global_mouse_position()):
				reward_meta_discard_requested.emit(_reward_drag_index)
			elif reward_card_grid != null and reward_card_grid.get_global_rect().has_point(mouse_pos):
				_commit_reward_card_manual_anchor(_reward_drag_index)
				reward_meta_drag_canceled.emit(_reward_drag_index)
			else:
				reward_meta_drag_canceled.emit(_reward_drag_index)
			_end_reward_drag_tracking()
		elif _backpack_drag_active:
			if drop_coord.x >= 0.0 and drop_coord.y >= 0.0:
				backpack_slot_drop_requested.emit(_backpack_drag_origin, drop_coord)
			elif discard_zone != null and discard_zone.get_global_rect().has_point(get_global_mouse_position()):
				backpack_slot_discard_requested.emit(_backpack_drag_origin)
			else:
				backpack_slot_drag_canceled.emit(_backpack_drag_origin)
			_end_backpack_drag_tracking()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		key_pressed.emit(event.keycode)

# ??쎈뻬: setup settings panel.
func setup_settings(shake_enabled: bool, is_fullscreen: bool, accessibility_state: Dictionary = {}) -> void:
	settings_panel.setup(shake_enabled, is_fullscreen, accessibility_state)
	apply_locale()

# ??쎈뻬: setup backpack slots.
func setup_backpack_slots() -> void:
	for bundle in page_shell_bundles.values():
		var backpack_panel = bundle.get("backpackUI", null)
		if backpack_panel != null and backpack_panel.has_method("setup_grid_slots"):
			backpack_panel.setup_grid_slots()

# ??쎈뻬: render backpack items using model data.
func render_backpack(inventory) -> void:
	for bundle in page_shell_bundles.values():
		var backpack_panel = bundle.get("backpackUI", null)
		if backpack_panel != null and backpack_panel.has_method("render_backpack_items"):
			backpack_panel.render_backpack_items(inventory)

# ??쎈뻬: update ghost item display.
func update_backpack_ghost(artifact) -> void:
	for bundle in page_shell_bundles.values():
		var backpack_panel = bundle.get("backpackUI", null)
		if backpack_panel != null and backpack_panel.has_method("update_ghost_display"):
			backpack_panel.update_ghost_display(artifact)

# ??쎈뻬: toggle settings visibility.
func toggle_settings() -> void:
	settings_panel.visible = not settings_panel.visible
	if settings_panel.visible:
		settings_panel.apply_locale()
		shop_panel.visible = false
		set_artifact_codex_visible(false)
		if settings_panel.has_method("focus_first_control"):
			settings_panel.focus_first_control()
	else:
		settings_open_button.grab_focus()

# ??쎈뻬: set settings visibility directly.
func set_settings_visible(val: bool) -> void:
	settings_panel.visible = val
	if not val:
		settings_open_button.grab_focus()

# ??쎈뻬: get settings visibility state.
func is_settings_visible() -> bool:
	return settings_panel.visible

# ??쎈뻬: toggle calibration shop visibility.
func toggle_shop() -> void:
	shop_panel.visible = not shop_panel.visible
	if shop_panel.visible:
		settings_panel.visible = false
		set_artifact_codex_visible(false)

# ??쎈뻬: set shop visibility directly.
func set_shop_visible(val: bool) -> void:
	shop_panel.visible = val

# ??쎈뻬: get shop visibility state.
func is_shop_visible() -> bool:
	return shop_panel.visible

# ?ㅽ뻾: toggle the artifact codex visibility with the latest projected data.
func toggle_artifact_codex(reward_table: Dictionary, growth_state: Dictionary, debug_all: bool = false) -> void:
	if codex_panel == null:
		return
	current_codex_reward_table = reward_table.duplicate(true)
	current_codex_growth_state = growth_state.duplicate(true)
	current_codex_debug_all = debug_all
	codex_panel.visible = not codex_panel.visible
	if codex_panel.visible:
		settings_panel.visible = false
		shop_panel.visible = false
		render_artifact_codex(current_codex_reward_table, current_codex_growth_state, current_codex_debug_all)

# ?ㅽ뻾: set artifact codex panel visibility directly.
func set_artifact_codex_visible(val: bool) -> void:
	if codex_panel != null:
		codex_panel.visible = val

# ?ㅽ뻾: get artifact codex visibility state.
func is_artifact_codex_visible() -> bool:
	return codex_panel != null and codex_panel.visible

func is_combat_pause_overlay_visible() -> bool:
	return PopupOverlayHostScript.pause_overlay_visible(
		is_settings_visible(),
		is_artifact_codex_visible(),
		repair_overlay != null and repair_overlay.visible
	)

func is_battle_pause_active() -> bool:
	return battle_pause_active

func set_battle_pause_active(active: bool) -> void:
	if battle_pause_active == active:
		return
	battle_pause_active = active
	for bundle in page_shell_bundles.values():
		var battlefield_panel = bundle.get("battlefieldUI", null)
		if battlefield_panel != null and battlefield_panel.has_method("set_battle_pause_active"):
			battlefield_panel.set_battle_pause_active(active)
		var backpack_panel = bundle.get("backpackUI", null)
		if backpack_panel != null and backpack_panel.has_method("set_battle_pause_active"):
			backpack_panel.set_battle_pause_active(active)
	if giant_timer_ui != null and giant_timer_ui.has_method("set_battle_pause_active"):
		giant_timer_ui.set_battle_pause_active(active)
	if vfx_manager != null and vfx_manager.has_method("set_battle_pause_active"):
		vfx_manager.set_battle_pause_active(active)

func _promote_popup_overlay_when_visible(overlay: Control) -> void:
	PopupOverlayHostScript.promote_when_visible(overlay, POPUP_OVERLAY_Z_INDEX)

func _bring_popup_overlay_to_front(overlay: Control) -> void:
	PopupOverlayHostScript.bring_to_front(overlay, POPUP_OVERLAY_Z_INDEX)

func _emit_combat_overlay_pause_visibility_changed() -> void:
	var active := is_combat_pause_overlay_visible()
	if active == _last_combat_pause_overlay_visible:
		return
	_last_combat_pause_overlay_visible = active
	combat_overlay_pause_visibility_changed.emit(active)

# ??쎈뻬: render labels, manage view visibility and update status bars based on scene snapshot.
func render_scene(scene: Dictionary, show_victory_overlay: bool) -> void:
	_last_rendered_scene = scene.duplicate(true)
	var layout: Dictionary = PhaseLayoutPresenterScript.project(scene, show_victory_overlay)
	var hud_model: Dictionary = HudReadModelScript.project(scene)
	var overlay_model: Dictionary = FailureReadModelScript.project(scene)
	var page_id := str(scene.get("pageId", str(scene.get("phase", "unknown"))))
	if page_id in ACTION_BAR_PAGE_IDS:
		_activate_action_bar_bundle(page_id)
	if page_id in SURFACE_PAGE_IDS:
		_activate_surface_bundle(page_id)
	if page_id in ["character_select", "leviathan_select", "clear", "defeat"]:
		overlay_model["visible"] = false
	header_panel.visible = bool(layout.get("headerVisible", true))
	if header_title_label != null:
		header_title_label.text = _resolved_header_title(scene)
	phase_label.text = str(layout.get("phaseText", TextCatalogScript.t("phase.label", [TextCatalogScript.t("phase.unknown")])))
	stage_label.text = str(layout.get("stageText", TextCatalogScript.t("stage.label", [1, 1])))
	stage_label.visible = not stage_label.text.is_empty()
	action_bar.visible = bool(layout.get("actionBarVisible", true))
	var node_map_full_page := bool(layout.get("nodeMapFullPage", false))
	var reward_backpack_dock := bool(layout.get("rewardBackpackDock", false))
	_apply_node_select_backpack_dock(str(layout.get("nodeSelectBackpackDock", "top")), float(layout.get("nodeMapStretchRatio", 2.1)), float(layout.get("backpackStretchRatio", 1.0)))
	_apply_top_content_stretch(float(layout.get("leftColumnTopStretchRatio", 3.5)), float(layout.get("backpackTopStretchRatio", 6.0)), float(layout.get("rightSidebarTopStretchRatio", 2.5)))
	top_content.visible = bool(layout.get("topContentVisible", true))
	left_column.visible = bool(layout.get("sidebarsVisible", true))
	right_sidebar.visible = bool(layout.get("sidebarsVisible", true))
	backpack_container.visible = bool(layout.get("backpackVisible", true)) or reward_backpack_dock
	left_column.add_theme_constant_override("separation", 12 if top_content.visible else 16)
	if node_map_full_page:
		backpack_container.custom_minimum_size = Vector2(_node_select_backpack_width(), 0.0)
		backpack_container.ratio = 1.0
	elif top_content.visible:
		_apply_top_content_backpack_bounds()
	else:
		top_content.custom_minimum_size.y = 0.0
		backpack_container.custom_minimum_size = Vector2.ZERO
		backpack_container.ratio = 1.0
	active_phase_container.size_flags_stretch_ratio = float(layout.get("activePhaseStretchRatio", 1.0))
	if battlefield_ui != null:
		battlefield_ui.visible = bool(layout.get("battlefieldVisible", false))
	if reward_panel != null:
		reward_panel.visible = bool(layout.get("rewardVisible", false))
	_apply_reward_backpack_dock(reward_backpack_dock)
	if status_panel != null:
		status_panel.visible = bool(layout.get("statusVisible", false))
	shop_open_button.visible = bool(layout.get("shopButtonVisible", false))
	if backpack_ui != null and backpack_ui.has_method("set_cooldown_visuals_enabled"):
		backpack_ui.set_cooldown_visuals_enabled(bool(layout.get("backpackCooldownVisible", false)))
	if backpack_ui != null and backpack_ui.has_method("update_pin_overlays"):
		if _backpack_reparent_pending:
			_pending_backpack_pin_scene = scene.duplicate(true)
			call_deferred("_flush_pending_backpack_pin_scene")
		else:
			backpack_ui.update_pin_overlays(scene)
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

	if bool(layout.get("battlefieldVisible", false)) and not RewardCeremonyPolicyScript.is_active_scene(scene):
		battlefield_ui.render_battlefield(scene, [])
	status_panel.render_target_bars(scene)
	status_panel.render_extractor_label(scene)
	if status_panel.has_method("render_node_info"):
		status_panel.render_node_info(scene)
	status_panel.render_hud_projection(hud_model)
	status_panel.render_combat_timer(str(layout.get("timerText", "00:00")), bool(layout.get("combatTimeActive", false)))
	status_panel.render_repair_overlay(scene, repair_overlay, overlay_model)
	if right_sidebar != null and right_sidebar.has_method("render_scene"):
		right_sidebar.render_scene(scene)
	_render_failure_backdrop(scene)
	_render_character_status(scene)
	_render_reward_backdrop(show_victory_overlay or str(scene.get("phase", "")) == "reward_loot")
	_render_page_scene(scene)
	_defer_interaction_fx_install()
	_queue_shared_backpack_layout_sync()
	call_deferred("_sync_page_scene_bounds")

# ??쎈뻬: set battlefield disabled tiles.
func update_battlefield_disabled(scene: Dictionary, disabled_tiles: Array) -> void:
	battlefield_ui.render_battlefield(scene, disabled_tiles)

# ?ㅽ뻾: start the active full-screen reward reveal overlay.
func start_reward_reveal_vfx(rewards_list: Array, step_callback: Callable, callback: Callable) -> void:
	if reward_reveal_overlay != null and reward_reveal_overlay.has_method("start_reveal"):
		reward_reveal_done_bridge = Callable(self, "_on_reward_reveal_overlay_finished").bind(callback)
		if reward_reveal_overlay.has_signal("ceremony_finished") and reward_reveal_overlay.is_connected("ceremony_finished", reward_reveal_done_bridge):
			reward_reveal_overlay.disconnect("ceremony_finished", reward_reveal_done_bridge)
		if reward_reveal_overlay.has_signal("ceremony_finished"):
			reward_reveal_overlay.connect("ceremony_finished", reward_reveal_done_bridge, CONNECT_ONE_SHOT)
		_bring_reward_reveal_overlay_to_front()
		reward_reveal_overlay.start_reveal(rewards_list, step_callback, Callable(), _reward_lid_source_global_rect())
		return
	callback.call()

# ?ㅽ뻾: skip the active reward reveal into its silhouette-count stage.
func skip_reward_reveal_to_silhouettes() -> void:
	if reward_reveal_overlay != null and reward_reveal_overlay.has_method("skip_to_silhouettes"):
		reward_reveal_overlay.skip_to_silhouettes()

# ?ㅽ뻾: cancel the active reward reveal without firing its completion callback.
func cancel_reward_reveal_vfx() -> void:
	if reward_reveal_overlay != null and reward_reveal_overlay.has_method("cancel_reveal"):
		reward_reveal_overlay.cancel_reveal()

# ?ㅽ뻾: reorder the reward reveal overlay above sibling controls using the Control-compatible front-order API.
func _on_reward_reveal_overlay_finished(next_step: String, callback: Callable) -> void:
	if not callback.is_valid():
		return
	reward_reveal_pending_step = next_step
	reward_reveal_pending_callback = callback
	call_deferred("_flush_reward_reveal_finished_callback")

func _flush_reward_reveal_finished_callback() -> void:
	if not reward_reveal_pending_callback.is_valid():
		return
	var callback := reward_reveal_pending_callback
	var next_step := reward_reveal_pending_step
	reward_reveal_pending_step = ""
	reward_reveal_pending_callback = Callable()
	callback.call_deferred(next_step)

func _bring_reward_reveal_overlay_to_front() -> void:
	PopupOverlayHostScript.bring_to_front(reward_reveal_overlay, REWARD_REVEAL_OVERLAY_Z_INDEX)

func _reward_lid_source_global_rect() -> Rect2:
	if battlefield_ui != null and battlefield_ui.has_method("reward_lid_source_global_rect"):
		return battlefield_ui.reward_lid_source_global_rect()
	var fallback_size := Vector2(96.0, 60.0)
	return Rect2(global_position + (size * 0.5) - (fallback_size * 0.5), fallback_size)

# ??쎈뻬: update action buttons enabled state.
func update_action_state(scene: Dictionary, show_victory_overlay: bool) -> void:
	var phase := str(scene.get("phase", "unknown"))
	var page_id := str(scene.get("pageId", phase))
	var reward_ceremony_active := RewardCeremonyPolicyScript.is_active_scene(scene)
	reset_button.visible = page_id not in ["character_select", "leviathan_select", "clear", "defeat"]
	start_button.visible = page_id == "node_select"
	hold_fire_button.visible = page_id in ["battle", "boss_battle"]
	repair_button.visible = page_id in ["battle", "boss_battle"]
	claim_rewards_button.visible = page_id in ["reward", "boss_reward"]
	start_button.disabled = not (page_id == "node_select" and scene.get("nodeSelect", {}).get("candidates", []).size() > 0)
	hold_fire_button.disabled = not (phase == "combat" and bool(scene.get("hud", {}).get("aim", {}).get("canFire", false)))
	repair_button.disabled = not (phase == "combat" and bool(scene.get("hud", {}).get("repair", {}).get("available", false)))
	var claim_disabled := (page_id not in ["reward", "boss_reward"] or show_victory_overlay or reward_ceremony_active or bool(scene.get("is_reveal_vfx_running", false)))
	claim_rewards_button.disabled = claim_disabled
	claim_inline_button.disabled = claim_disabled

# ??쎈뻬: show or hide confirm overlay.
func set_confirm_overlay_visible(val: bool) -> void:
	confirm_overlay.visible = val

# ??쎈뻬: append a message to the system log console.
func add_log(message: String) -> void:
	for bundle in page_shell_bundles.values():
		var console = bundle.get("logConsole", null)
		if console != null and console.has_method("add_log"):
			console.add_log(message)

# ??쎈뻬: update discard zone label and modulate color.
func update_discard_zone(label_text: String, is_active: bool) -> void:
	discard_label.text = label_text
	discard_zone.self_modulate = Color.WHITE if is_active else Color(0.82, 0.82, 0.82, 0.78)

# ??쎈뻬: get global hit position of a cell.
func get_cell_global_pos(cell_id: String) -> Vector2:
	var hit_pos = global_position + size / 2
	for child in battlefield_ui.battlefield_grid.get_children():
		if child is CellView and child.cell_id == cell_id:
			hit_pos = child.global_position + child.size / 2
			break
	return hit_pos

# ??쎈뻬: get global start position of the extractor.
func get_extractor_global_pos() -> Vector2:
	return status_panel.extractor_visual.global_position + status_panel.extractor_visual.size / 2

func get_health_bar_global_pos() -> Vector2:
	return status_panel.health_bar.global_position + Vector2(status_panel.health_bar.size.x * 0.58, -4.0)

func get_shield_bar_global_pos() -> Vector2:
	return status_panel.shield_bar.global_position + Vector2(status_panel.shield_bar.size.x * 0.58, -4.0)

# ??쎈뻬: trigger resonance beam effect.
func trigger_resonance_beam(start_pos: Vector2, hit_pos: Vector2, color: String) -> void:
	vfx_manager.draw_resonance_beam(start_pos, hit_pos, color)

# ??쎈뻬: trigger hit particle spawn.
func trigger_hit_particles(hit_pos: Vector2, status: String, color: String) -> void:
	vfx_manager.spawn_hit_particles(hit_pos, status, color)

func trigger_damage_popups(events: Array) -> void:
	if events.is_empty():
		return
	var anchored_events: Array = []
	for event in events:
		if not event is Dictionary:
			continue
		var popup: Dictionary = event.duplicate(true)
		var channel := str(popup.get("channel", ""))
		popup["origin"] = get_shield_bar_global_pos() if channel == "shield" else get_health_bar_global_pos()
		anchored_events.append(popup)
	vfx_manager.spawn_damage_popups(anchored_events)

# ??쎈뻬: trigger screenshake VFX.
func trigger_screenshake(duration: float, magnitude: float) -> void:
	vfx_manager.trigger_screenshake(duration, magnitude, self)

# ??쎈뻬: update reward text label.
func render_reward_tray(model: Dictionary) -> void:
	var title_text := str(model.get("title", TextCatalogScript.t("panel.rewards")))
	var subtitle_text := str(model.get("subtitle", ""))
	var mode_pill_text := str(model.get("modePill", ""))
	var cloud_note_text := str(model.get("cloudNote", ""))
	var workspace_note_text := str(model.get("workspaceNote", ""))
	reward_title.text = title_text
	reward_subtitle.text = subtitle_text
	reward_mode_pill.text = mode_pill_text
	reward_mode_pill.visible = not mode_pill_text.strip_edges().is_empty()
	reward_cloud_note.text = cloud_note_text
	reward_cloud_note.visible = not cloud_note_text.strip_edges().is_empty()
	reward_workspace_note.text = workspace_note_text
	reward_workspace_note.visible = not workspace_note_text.strip_edges().is_empty()
	claim_card_body.text = str(model.get("claimBody", ""))
	claim_inline_button.text = str(model.get("claimButtonText", TextCatalogScript.t("action.claim_rewards")))
	update_discard_zone(str(model.get("discardText", "")), bool(model.get("discardActive", false)))
	_prune_reward_card_manual_anchors(model.get("cards", []))
	_render_reward_cards(model.get("cards", []))
	_render_reward_inspector(model.get("inspector", {}))
	_queue_reward_board_layout_sync()
	_defer_interaction_fx_install()

func set_reward_text(val: String) -> void:
	reward_inspector_summary.text = val

func _render_reward_cards(cards: Array) -> void:
	reward_card_buttons = RewardCardCloudHostScript.render_cards(
		reward_card_grid,
		cards,
		Callable(self, "_wire_reward_card_interactions")
	)
	_queue_reward_card_float_layout()

func _wire_reward_card_interactions(button: Button, index: int) -> void:
	var state := {"pressed": false, "dragging": false, "press_pos": Vector2.ZERO}
	button.gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				state["pressed"] = true
				state["dragging"] = false
				state["press_pos"] = event.position
			else:
				var was_pressed := bool(state.get("pressed", false))
				var was_dragging := bool(state.get("dragging", false))
				state["pressed"] = false
				state["dragging"] = false
				if was_pressed and not was_dragging:
					reward_meta_clicked.emit(index)
		elif event is InputEventMouseMotion and bool(state.get("pressed", false)) and not bool(state.get("dragging", false)):
			var press_pos: Vector2 = state.get("press_pos", Vector2.ZERO)
			if event.position.distance_to(press_pos) >= 10.0:
				state["dragging"] = true
				_begin_reward_drag_tracking(index, button, press_pos)
				reward_meta_drag_started.emit(index)
	)

func _queue_reward_card_float_layout() -> void:
	call_deferred("_layout_reward_float_cards")

func reward_card_anchor_bounds(cloud_size: Vector2, card_size: Vector2) -> Rect2:
	return RewardCardCloudHostScript.reward_card_anchor_bounds(cloud_size, card_size)

func clamp_reward_card_anchor(cloud_size: Vector2, card_size: Vector2, anchor: Vector2) -> Vector2:
	return RewardCardCloudHostScript.clamp_reward_card_anchor(cloud_size, card_size, anchor)

func _prune_reward_card_manual_anchors(cards: Array) -> void:
	_reward_card_manual_anchor_norms = RewardCardCloudHostScript.prune_manual_anchors(cards, _reward_card_manual_anchor_norms)

func _layout_reward_float_cards() -> void:
	RewardCardCloudHostScript.layout_cards(
		reward_card_grid,
		reward_card_buttons,
		_reward_card_manual_anchor_norms,
		pulse_time
	)

func _apply_reward_card_idle_transform(button: Control) -> void:
	RewardCardCloudHostScript.apply_idle_transform(button, pulse_time, _reward_drag_active, _reward_drag_button)

func _begin_reward_drag_tracking(index: int, button: Control, pointer_offset: Vector2) -> void:
	_reward_drag_index = index
	_reward_drag_active = true
	_reward_drag_button = button
	_reward_drag_pointer_offset = pointer_offset
	if _reward_drag_button != null:
		_reward_drag_button.z_index = 8
		_update_reward_drag_card_position()

func _end_reward_drag_tracking() -> void:
	if _reward_drag_button != null and is_instance_valid(_reward_drag_button):
		_reward_drag_button.z_index = 0
	_reward_drag_button = null
	_reward_drag_pointer_offset = Vector2.ZERO
	_reward_drag_index = -1
	_reward_drag_active = false

func _update_reward_drag_card_position() -> void:
	RewardCardCloudHostScript.update_drag_card_position(
		reward_card_grid,
		_reward_drag_button,
		_reward_drag_pointer_offset,
		get_global_mouse_position()
	)

func _commit_reward_card_manual_anchor(index: int) -> void:
	_reward_card_manual_anchor_norms = RewardCardCloudHostScript.commit_manual_anchor(
		reward_card_grid,
		_reward_drag_button,
		index,
		_reward_card_manual_anchor_norms
	)

func _begin_backpack_drag_tracking(origin_coord: Vector2) -> void:
	_backpack_drag_origin = origin_coord
	_backpack_drag_active = true

func _end_backpack_drag_tracking() -> void:
	_backpack_drag_origin = Vector2(-1, -1)
	_backpack_drag_active = false

func _render_reward_inspector(inspector: Dictionary) -> void:
	var empty := bool(inspector.get("empty", true))
	reward_inspector_kicker.text = str(inspector.get("kicker", ""))
	reward_inspector_name.text = "" if empty else str(inspector.get("name", ""))
	reward_inspector_summary.text = str(inspector.get("summary", ""))
	reward_inspector_summary.visible = true
	_clear_dynamic_children(reward_inspector_facts)
	for fact in inspector.get("facts", []):
		if not (fact is Dictionary):
			continue
		var tile := PanelContainer.new()
		tile.custom_minimum_size.y = REWARD_INSPECTOR_FACT_MIN_HEIGHT
		tile.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tile.add_theme_stylebox_override("panel", LTLThemeScript.surface_style(Color(0.13, 0.16, 0.20, 0.96), Color(0.28, 0.34, 0.40, 1.0), 14, 1, 0.12))
		var margin := MarginContainer.new()
		margin.add_theme_constant_override("margin_left", 10)
		margin.add_theme_constant_override("margin_top", 10)
		margin.add_theme_constant_override("margin_right", 10)
		margin.add_theme_constant_override("margin_bottom", 10)
		tile.add_child(margin)
		var box := VBoxContainer.new()
		box.add_theme_constant_override("separation", 4)
		margin.add_child(box)
		var label := Label.new()
		label.text = str(fact.get("label", ""))
		label.add_theme_font_size_override("font_size", 10)
		label.add_theme_color_override("font_color", LTLThemeScript.TEXT_MUTED)
		box.add_child(label)
		var value := Label.new()
		value.text = str(fact.get("value", ""))
		value.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		value.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		value.add_theme_font_size_override("font_size", 12)
		value.add_theme_color_override("font_color", LTLThemeScript.TEXT_PRIMARY)
		box.add_child(value)
		reward_inspector_facts.add_child(tile)
	reward_footprint_title.text = str(inspector.get("shapeTitle", ""))
	var footprint_parts := PackedStringArray()
	var footprint_text := str(inspector.get("shapeFootprintText", "")).strip_edges()
	var cell_text := str(inspector.get("shapeCellCountText", "")).strip_edges()
	if not footprint_text.is_empty():
		footprint_parts.append(footprint_text)
	if not cell_text.is_empty():
		footprint_parts.append(cell_text)
	reward_footprint_info.text = "\n".join(footprint_parts)
	_render_reward_footprint(inspector.get("shapeMatrix", []), str(inspector.get("shapeEnergyType", "")), str(inspector.get("shapeItemType", "")))

func _render_reward_footprint(shape_matrix: Array, energy_type: String, item_type: String) -> void:
	_clear_dynamic_children(reward_footprint_grid)
	var normalized_shape: Array = []
	if shape_matrix is Array:
		normalized_shape = shape_matrix
	var layout := reward_footprint_layout_policy(normalized_shape)
	var columns := int(layout.get("columns", REWARD_FOOTPRINT_MIN_COLUMNS))
	var rows := int(layout.get("rows", REWARD_FOOTPRINT_MIN_ROWS))
	reward_footprint_grid.columns = columns
	reward_footprint_grid.custom_minimum_size = Vector2(
		float(columns) * REWARD_FOOTPRINT_CELL_SIZE + float(maxi(0, columns - 1)) * REWARD_FOOTPRINT_CELL_GAP,
		float(rows) * REWARD_FOOTPRINT_CELL_SIZE + float(maxi(0, rows - 1)) * REWARD_FOOTPRINT_CELL_GAP
	)
	var fill_color := _reward_footprint_fill_color(energy_type, item_type)
	for row_index in range(rows):
		var row_data: Array = []
		if row_index < normalized_shape.size() and normalized_shape[row_index] is Array:
			row_data = normalized_shape[row_index]
		for column_index in range(columns):
			var tile := Panel.new()
			tile.custom_minimum_size = Vector2(REWARD_FOOTPRINT_CELL_SIZE, REWARD_FOOTPRINT_CELL_SIZE)
			var active := column_index < row_data.size() and int(row_data[column_index]) != 0
			tile.add_theme_stylebox_override("panel", LTLThemeScript.surface_style(
				fill_color if active else Color(0.12, 0.15, 0.19, 0.95),
				Color(0.30, 0.36, 0.42, 1.0),
				6,
				1,
				0.0
			))
			reward_footprint_grid.add_child(tile)

func reward_footprint_layout_policy(shape_matrix: Array) -> Dictionary:
	var width := 0
	var height := 0
	for row in shape_matrix:
		if row is Array:
			height += 1
			width = maxi(width, row.size())
	return {
		"columns": maxi(REWARD_FOOTPRINT_MIN_COLUMNS, width),
		"rows": maxi(REWARD_FOOTPRINT_MIN_ROWS, height)
	}

func _reward_card_meta_text(card: Dictionary) -> String:
	var parts := PackedStringArray()
	parts.append(TextCatalogScript.enum_label("rarity", str(card.get("rarity", "common"))))
	if not str(card.get("energyLabel", "")).is_empty():
		parts.append(str(card.get("energyLabel", "")))
	else:
		parts.append(TextCatalogScript.item_label(str(card.get("itemType", "drill"))))
	var qty := int(card.get("qty", 1))
	if qty > 1:
		parts.append("x%d" % qty)
	return " / ".join(parts)

func _reward_footprint_fill_color(energy_type: String, item_type: String) -> Color:
	if item_type == "relic":
		return Color(0.88, 0.72, 0.40, 0.98)
	match energy_type:
		"red":
			return Color(0.86, 0.31, 0.29, 0.98)
		"blue":
			return Color(0.35, 0.57, 0.90, 0.98)
		"green":
			return Color(0.36, 0.73, 0.42, 0.98)
		"purple":
			return Color(0.69, 0.42, 0.89, 0.98)
	return Color(0.63, 0.69, 0.76, 0.98)

func _clear_dynamic_children(node: Node) -> void:
	for child in node.get_children():
		child.queue_free()

func _set_descendant_mouse_filter_ignore(node: Node) -> void:
	for child in node.get_children():
		var control = child as Control
		if control != null:
			control.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_set_descendant_mouse_filter_ignore(child)

# ?ㅽ뻾: refresh static view labels and buttons from the active text catalog.
func apply_locale() -> void:
	if reset_button == null:
		return
	_set_label_text(
		"RootMargin/AppShell/Header/Margin/PhaseRow/TitleLabel",
		_resolved_header_title(_last_rendered_scene) if not _last_rendered_scene.is_empty() else TextCatalogScript.t("app.title")
	)
	for page_id in SURFACE_PAGE_IDS:
		var bundle: Dictionary = _page_bundle(page_id)
		if bundle.is_empty():
			continue
		var bundle_status_panel = bundle.get("statusPanel", null)
		if bundle_status_panel != null and bundle_status_panel.has_method("apply_locale"):
			bundle_status_panel.apply_locale()
		_set_bundle_label_text(bundle, "TopContent/BackpackContainer/BackpackEnginePanel/Margin/EngineBox/EngineTitle", TextCatalogScript.t("panel.backpack"))
		if bundle.get("rightSidebar", null) != null and bundle.get("rightSidebar").has_method("apply_locale"):
			bundle.get("rightSidebar").apply_locale()
		if bundle.get("battlefieldUI", null) != null:
			_set_bundle_label_text(bundle, "BattlefieldPanel/Margin/BattlefieldBox/BattlefieldTitle", "")
		if bundle.get("rewardPanel", null) != null:
			_set_bundle_label_text(bundle, "RewardPanel/Margin/RewardBox/BoardHead/BoardTitleBox/RewardTitle", TextCatalogScript.t("panel.rewards"))
			_set_bundle_label_text(bundle, "RewardPanel/Margin/RewardBox/BoardHead/BoardTitleBox/RewardSubtitle", TextCatalogScript.t("reward.board.subtitle"))
			_set_bundle_optional_label_text(bundle, "RewardPanel/Margin/RewardBox/BoardHead/ModePill", TextCatalogScript.t("reward.board.mode_pill"))
			_set_bundle_label_text(bundle, "RewardPanel/Margin/RewardBox/RewardBoardScroll/RewardBoard/RewardGrid/RewardsZone/Margin/ZoneBox/ZoneHead/ZoneTitle", TextCatalogScript.t("reward.board.rewards_zone.title"))
			_set_bundle_optional_label_text(bundle, "RewardPanel/Margin/RewardBox/RewardBoardScroll/RewardBoard/RewardGrid/RewardsZone/Margin/ZoneBox/ZoneHead/ZoneHint", TextCatalogScript.t("reward.board.rewards_zone.hint"))
			_set_bundle_label_text(bundle, "RewardPanel/Margin/RewardBox/RewardBoardScroll/RewardBoard/RewardGrid/WorkspaceZone/Margin/ZoneBox/ZoneHead/ZoneTitle", TextCatalogScript.t("panel.backpack"))
			_set_bundle_label_text(bundle, "RewardPanel/Margin/RewardBox/RewardBoardScroll/RewardBoard/RewardGrid/WorkspaceZone/Margin/ZoneBox/ZoneHead/ZoneHint", TextCatalogScript.t("reward.board.workspace_zone.hint"))
			_set_bundle_label_text(bundle, "RewardPanel/Margin/RewardBox/RewardBoardScroll/RewardBoard/RewardGrid/InspectorZone/Margin/ZoneBox/ZoneHead/ZoneTitle", TextCatalogScript.t("reward.board.inspector_zone.title"))
			_set_bundle_label_text(bundle, "RewardPanel/Margin/RewardBox/RewardBoardScroll/RewardBoard/RewardGrid/InspectorZone/Margin/ZoneBox/ZoneHead/ZoneHint", TextCatalogScript.t("reward.board.inspector_zone.hint"))
			_set_bundle_label_text(bundle, "RewardPanel/Margin/RewardBox/RewardBoardScroll/RewardBoard/BottomRow/DiscardZone/Margin/ZoneBox/ZoneHead/ZoneTitle", TextCatalogScript.t("reward.board.discard_zone.title"))
			_set_bundle_optional_label_text(bundle, "RewardPanel/Margin/RewardBox/RewardBoardScroll/RewardBoard/BottomRow/DiscardZone/Margin/ZoneBox/ZoneHead/ZoneHint", TextCatalogScript.t("reward.board.discard_zone.hint"))
			_set_bundle_optional_label_text(bundle, "RewardPanel/Margin/RewardBox/RewardBoardScroll/RewardBoard/BottomRow/DiscardZone/Margin/ZoneBox/DiscardCardScroll/DiscardCard/Margin/DiscardCardBox/DiscardCardTitle", TextCatalogScript.t("reward.board.discard_card_title"))
			_set_bundle_label_text(bundle, "RewardPanel/Margin/RewardBox/RewardBoardScroll/RewardBoard/BottomRow/ConfirmZone/Margin/ZoneBox/ZoneHead/ZoneTitle", TextCatalogScript.t("reward.board.confirm_zone.title"))
			_set_bundle_optional_label_text(bundle, "RewardPanel/Margin/RewardBox/RewardBoardScroll/RewardBoard/BottomRow/ConfirmZone/Margin/ZoneBox/ZoneHead/ZoneHint", TextCatalogScript.t("reward.board.confirm_zone.hint"))
			_set_bundle_optional_label_text(bundle, "RewardPanel/Margin/RewardBox/RewardBoardScroll/RewardBoard/BottomRow/ConfirmZone/Margin/ZoneBox/ClaimCardScroll/ClaimCard/Margin/ClaimCardBox/ClaimCardTitle", TextCatalogScript.t("reward.board.claim_card_title"))
			_set_bundle_rich_text(bundle, "RewardPanel/Margin/RewardBox/RewardBoardScroll/RewardBoard/RewardGrid/WorkspaceZone/Margin/ZoneBox/WorkspaceNote", TextCatalogScript.t("reward.board.workspace_note"))
	_set_label_text("ConfirmOverlay/Center/ConfirmBox/WarningLabel", TextCatalogScript.t("confirm.unclaimed.title"))
	_set_label_text("ConfirmOverlay/Center/ConfirmBox/DescriptionLabel", TextCatalogScript.t("confirm.unclaimed.desc"))
	confirm_proceed_button.text = TextCatalogScript.t("action.proceed")
	confirm_cancel_button.text = TextCatalogScript.t("action.cancel")
	settings_open_button.text = TextCatalogScript.t("action.settings")
	for page_id in ACTION_BAR_PAGE_IDS:
		var bundle: Dictionary = _page_bundle(page_id)
		if bundle.is_empty():
			continue
		var reset_btn := bundle.get("resetButton", null) as Button
		var start_btn := bundle.get("startButton", null) as Button
		var hold_btn := bundle.get("holdFireButton", null) as Button
		var repair_btn := bundle.get("repairButton", null) as Button
		var claim_btn := bundle.get("claimRewardsButton", null) as Button
		if reset_btn != null:
			reset_btn.text = TextCatalogScript.t("action.reset")
		if start_btn != null:
			start_btn.text = TextCatalogScript.t("action.start")
		if hold_btn != null:
			hold_btn.text = TextCatalogScript.t("action.hold_fire")
		if repair_btn != null:
			repair_btn.text = TextCatalogScript.t("action.repair")
		if claim_btn != null:
			claim_btn.text = TextCatalogScript.t("action.claim_rewards")
		var shop_btn := bundle.get("shopButton", null) as Button
		var codex_btn := bundle.get("codexButton", null) as Button
		var settings_btn := bundle.get("settingsButton", null) as Button
		if shop_btn != null:
			shop_btn.text = TextCatalogScript.t("action.shop")
		if codex_btn != null:
			codex_btn.text = TextCatalogScript.t("action.codex")
		if settings_btn != null:
			settings_btn.text = TextCatalogScript.t("action.settings")
	for page_id in SURFACE_PAGE_IDS:
		var bundle: Dictionary = _page_bundle(page_id)
		var inline_btn := bundle.get("claimInlineButton", null) as Button
		if inline_btn != null:
			inline_btn.text = TextCatalogScript.t("action.claim_rewards")
	if shop_open_button != null:
		shop_open_button.text = TextCatalogScript.t("action.shop")
	if codex_open_button != null:
		codex_open_button.text = TextCatalogScript.t("action.codex")
	if settings_panel != null and settings_panel.has_method("apply_locale"):
		settings_panel.apply_locale()
	if shop_panel != null and shop_panel.has_method("apply_locale"):
		shop_panel.apply_locale()
	if codex_panel != null and codex_panel.has_method("apply_locale"):
		codex_panel.apply_locale()
	if is_artifact_codex_visible() and not current_codex_reward_table.is_empty():
		render_artifact_codex(current_codex_reward_table, current_codex_growth_state, current_codex_debug_all)
	_set_reward_workspace_title_state(backpack_container != null and backpack_container.get_parent() == reward_backpack_host)
	_apply_shell_theme()

# ?ㅽ뻾: set a Label text by relative path when present.
func _set_label_text(path: String, text: String) -> void:
	var node := get_node_or_null(path) as Label
	if node != null: node.text = text

# ?ㅽ뻾: set a RichTextLabel text by relative path when present.
func _set_rich_text(path: String, text: String) -> void:
	var node := get_node_or_null(path) as RichTextLabel
	if node != null: node.text = text

func _set_bundle_label_text(bundle: Dictionary, path: String, text: String) -> void:
	var page_root: Node = bundle.get("pageRoot", null) as Node
	if page_root == null:
		return
	var node := page_root.get_node_or_null(path) as Label
	if node != null: node.text = text

func _set_bundle_optional_label_text(bundle: Dictionary, path: String, text: String) -> void:
	_set_bundle_label_text(bundle, path, text)
	var page_root: Node = bundle.get("pageRoot", null) as Node
	if page_root == null:
		return
	var node := page_root.get_node_or_null(path) as Label
	if node != null: node.visible = not text.strip_edges().is_empty()

func _set_bundle_rich_text(bundle: Dictionary, path: String, text: String) -> void:
	var page_root: Node = bundle.get("pageRoot", null) as Node
	if page_root == null:
		return
	var node := page_root.get_node_or_null(path) as RichTextLabel
	if node != null: node.text = text

# ??쎈뻬: dynamically construct the calibration shop panel.
func _create_shop_panel() -> void:
	shop_panel = ShopPanelUIScript.new()
	shop_panel.buy_passive.connect(func(passive_id, cost): buy_passive.emit(passive_id, cost))
	shop_panel.buy_base_item.connect(func(item_id): buy_base_item.emit(item_id))
	shop_panel.visibility_changed.connect(func(): _promote_popup_overlay_when_visible(shop_panel))
	add_child(shop_panel)

# ?ㅽ뻾: dynamically construct the artifact codex panel.
func _create_artifact_codex_panel() -> void:
	codex_panel = ArtifactCodexPanelUIScript.new()
	codex_panel.debug_toggled.connect(_on_codex_debug_toggled)
	codex_panel.entry_selected.connect(_on_codex_entry_selected)
	codex_panel.section_selected.connect(_on_codex_section_selected)
	codex_panel.visibility_changed.connect(func():
		_promote_popup_overlay_when_visible(codex_panel)
		_emit_combat_overlay_pause_visibility_changed()
	)
	add_child(codex_panel)

func _create_page_scenes() -> void:
	meta_page_shell_host = PageSceneRegistryScript.build_shell_host("MetaPageShellHost")
	add_child(meta_page_shell_host)
	move_child(meta_page_shell_host, repair_overlay.get_index())
	page_shell_host = PageSceneRegistryScript.build_shell_host("PageShellHost")
	active_phase_container.add_child(page_shell_host)
	active_phase_container.move_child(page_shell_host, 0)
	_register_page_scene("character_select", CharacterSelectPageScene.instantiate())
	_register_page_scene("leviathan_select", LeviathanSelectPageScene.instantiate())
	_register_page_scene("node_select", NodeSelectRuntimePageScene.instantiate())
	_register_page_scene("battle", BattlePageScene.instantiate())
	_register_page_scene("boss_battle", BossBattlePageScene.instantiate())
	_register_page_scene("reward", RewardPageScene.instantiate())
	_register_page_scene("boss_reward", BossRewardPageScene.instantiate())
	_register_page_scene("event_node", EventNodePageScene.instantiate())
	_register_page_scene("defeat", DefeatPageScene.instantiate())
	_register_page_scene("clear", ClearPageScene.instantiate())
	character_select_page = page_scenes.get("character_select")
	leviathan_select_page = page_scenes.get("leviathan_select")
	node_select_runtime_page = page_scenes.get("node_select") as Control
	_cache_node_select_runtime_hosts()
	if character_select_page != null and character_select_page.has_signal("character_selected"):
		character_select_page.connect("character_selected", func(character_id): character_selected.emit(character_id))
	if character_select_page != null and character_select_page.has_signal("color_selected"):
		character_select_page.connect("color_selected", func(color): loadout_color_selected.emit(color))
	if character_select_page != null and character_select_page.has_signal("continue_requested"):
		character_select_page.connect("continue_requested", func(): character_continue_pressed.emit())
	if character_select_page != null and character_select_page.has_signal("settings_requested"):
		character_select_page.connect("settings_requested", func(): settings_open_pressed.emit())
	if leviathan_select_page != null and leviathan_select_page.has_signal("leviathan_selected"):
		leviathan_select_page.connect("leviathan_selected", func(leviathan_id): leviathan_selected.emit(leviathan_id))
	if leviathan_select_page != null and leviathan_select_page.has_signal("start_requested"):
		leviathan_select_page.connect("start_requested", func(): looting_start_pressed.emit())
	if node_select_runtime_page != null and node_select_runtime_page.has_signal("node_selected"):
		node_select_runtime_page.connect("node_selected", func(index): node_meta_clicked.emit(index))
	if node_select_runtime_page != null and node_select_runtime_page.has_signal("settings_requested"):
		node_select_runtime_page.connect("settings_requested", func(): settings_open_pressed.emit())
	if node_select_runtime_page != null and node_select_runtime_page.has_signal("shop_requested"):
		node_select_runtime_page.connect("shop_requested", func(): shop_open_pressed.emit())
	if node_select_runtime_page != null and node_select_runtime_page.has_signal("codex_requested"):
		node_select_runtime_page.connect("codex_requested", func(): codex_open_pressed.emit())
	if node_select_runtime_page != null and node_select_runtime_page.has_signal("start_color_selected"):
		node_select_runtime_page.connect("start_color_selected", func(color): loadout_color_selected.emit(color))
	for outcome_id in ["defeat", "clear"]:
		var outcome_page = page_scenes.get(outcome_id)
		if outcome_page != null and outcome_page.has_signal("return_requested"):
			outcome_page.return_requested.connect(func(): return_to_character_select_pressed.emit())
	_sync_page_scene_bounds()

func _cache_node_select_runtime_hosts() -> void:
	if node_select_runtime_page == null:
		node_select_content_row = null
		node_select_backpack_host = null
		return
	node_select_content_row = node_select_runtime_page.get_node_or_null("Margin/BoardShell/ShellMargin/ShellVBox/RouteSplit") as HBoxContainer
	node_select_backpack_host = node_select_runtime_page.get_node_or_null("Margin/BoardShell/ShellMargin/ShellVBox/RouteSplit/BackpackHost") as Control
	if node_select_content_row != null:
		node_select_content_row.resized.connect(_queue_shared_backpack_layout_sync)
	if node_select_backpack_host != null:
		node_select_backpack_host.resized.connect(_queue_shared_backpack_layout_sync)

func _page_bundle(page_id: String) -> Dictionary:
	return page_shell_bundles.get(page_id, {})

func _active_surface_bundle() -> Dictionary:
	return _page_bundle(_active_surface_bundle_id)

func bundle_node(page_id: String, path: String = "") -> Node:
	return _bundle_node(page_id, path)

func current_surface_node(path: String = "") -> Node:
	return _bundle_node(_active_surface_bundle_id, path)

func current_action_bar_node(path: String = "") -> Node:
	return _bundle_node(_active_action_bar_bundle_id, path)

func _bundle_node(page_id: String, path: String = "") -> Node:
	var bundle: Dictionary = _page_bundle(page_id)
	var page_root: Node = bundle.get("pageRoot", null) as Node
	if page_root == null:
		page_root = page_scenes.get(page_id, null) as Node
	if page_root == null:
		return null
	if path.is_empty():
		return page_root
	return page_root.get_node_or_null(path)

func _cache_page_shell_bundles() -> void:
	page_shell_bundles.clear()
	for page_id in ACTION_BAR_PAGE_IDS:
		var page_root: Control = page_scenes.get(page_id, null) as Control
		if page_root == null:
			continue
		var bundle: Dictionary = _capture_page_shell_bundle(page_id, page_root)
		page_shell_bundles[page_id] = bundle
	if page_shell_bundles.has("reward"):
		_assign_reward_bundle_refs(_page_bundle("reward"))
	if page_shell_bundles.has("battle"):
		_assign_battle_bundle_refs(_page_bundle("battle"))

func _capture_page_shell_bundle(page_id: String, page_root: Control) -> Dictionary:
	var bundle := {
		"pageId": page_id,
		"pageRoot": page_root
	}
	var action_bar_path := "ActionBar"
	if page_id == "node_select":
		action_bar_path = "Margin/VStack/ActionBar"
	bundle["actionBar"] = page_root.get_node_or_null(action_bar_path) as HBoxContainer
	bundle["resetButton"] = page_root.get_node_or_null("%s/ResetButton" % action_bar_path) as Button
	bundle["startButton"] = page_root.get_node_or_null("%s/StartButton" % action_bar_path) as Button
	bundle["holdFireButton"] = page_root.get_node_or_null("%s/HoldFireButton" % action_bar_path) as Button
	bundle["repairButton"] = page_root.get_node_or_null("%s/RepairButton" % action_bar_path) as Button
	bundle["claimRewardsButton"] = page_root.get_node_or_null("%s/ClaimRewardsButton" % action_bar_path) as Button
	if page_id == "node_select":
		bundle["shopButton"] = page_root.get_node_or_null("Margin/VStack/BoardShell/ShellMargin/ShellVBox/BoardHead/TitleChips/ShopButton") as Button
		bundle["codexButton"] = page_root.get_node_or_null("Margin/VStack/BoardShell/ShellMargin/ShellVBox/BoardHead/TitleChips/CodexButton") as Button
		bundle["settingsButton"] = page_root.get_node_or_null("Margin/VStack/BoardShell/ShellMargin/ShellVBox/BoardHead/TitleChips/SettingsButton") as Button
	if page_id in SURFACE_PAGE_IDS:
		bundle["topContent"] = page_root.get_node_or_null("TopContent") as HBoxContainer
		bundle["leftColumn"] = page_root.get_node_or_null("TopContent/LeftColumn") as VBoxContainer
		bundle["portraitPlaceholder"] = page_root.get_node_or_null("TopContent/RightSidebar/Margin/SidebarBox/TabViewport/ExplorerContent/Margin/CharacterBox/PortraitPlaceholder") as Panel
		bundle["portraitLabel"] = page_root.get_node_or_null("TopContent/RightSidebar/Margin/SidebarBox/TabViewport/ExplorerContent/Margin/CharacterBox/PortraitPlaceholder/PortraitLabel") as Label
		bundle["backpackContainer"] = page_root.get_node_or_null("TopContent/BackpackContainer") as AspectRatioContainer
		bundle["rightSidebar"] = page_root.get_node_or_null("TopContent/RightSidebar") as PanelContainer
		bundle["backpackUI"] = page_root.get_node_or_null("TopContent/BackpackContainer/BackpackEnginePanel")
		bundle["statusPanel"] = page_root.get_node_or_null("TopContent/LeftColumn/StatusPanel")
		bundle["logConsole"] = page_root.get_node_or_null("TopContent/RightSidebar/Margin/SidebarBox/TabViewport/LogContent/Margin/LogBox/InspectorText")
		bundle["battlefieldUI"] = page_root.get_node_or_null("BattlefieldPanel")
		bundle["rewardPanel"] = page_root.get_node_or_null("RewardPanel") as PanelContainer
		var bundle_backpack_container: AspectRatioContainer = bundle.get("backpackContainer", null) as AspectRatioContainer
		bundle["backpackOriginalParent"] = bundle_backpack_container.get_parent() if bundle_backpack_container != null else null
		bundle["backpackOriginalIndex"] = bundle_backpack_container.get_index() if bundle_backpack_container != null else -1
		if bundle.get("rewardPanel", null) != null:
			bundle["rewardPanelMargin"] = page_root.get_node_or_null("RewardPanel/Margin") as MarginContainer
			bundle["rewardBox"] = page_root.get_node_or_null("RewardPanel/Margin/RewardBox") as VBoxContainer
			bundle["rewardBoardHead"] = page_root.get_node_or_null("RewardPanel/Margin/RewardBox/BoardHead") as HBoxContainer
			bundle["rewardBoardScroll"] = page_root.get_node_or_null("RewardPanel/Margin/RewardBox/RewardBoardScroll") as ScrollContainer
			bundle["rewardBoard"] = page_root.get_node_or_null("RewardPanel/Margin/RewardBox/RewardBoardScroll/RewardBoard") as VBoxContainer
			bundle["rewardGrid"] = page_root.get_node_or_null("RewardPanel/Margin/RewardBox/RewardBoardScroll/RewardBoard/RewardGrid") as HBoxContainer
			bundle["rewardRewardsZone"] = page_root.get_node_or_null("RewardPanel/Margin/RewardBox/RewardBoardScroll/RewardBoard/RewardGrid/RewardsZone") as PanelContainer
			bundle["rewardWorkspaceZone"] = page_root.get_node_or_null("RewardPanel/Margin/RewardBox/RewardBoardScroll/RewardBoard/RewardGrid/WorkspaceZone") as PanelContainer
			bundle["rewardWorkspaceMargin"] = page_root.get_node_or_null("RewardPanel/Margin/RewardBox/RewardBoardScroll/RewardBoard/RewardGrid/WorkspaceZone/Margin") as MarginContainer
			bundle["rewardWorkspaceBox"] = page_root.get_node_or_null("RewardPanel/Margin/RewardBox/RewardBoardScroll/RewardBoard/RewardGrid/WorkspaceZone/Margin/ZoneBox") as VBoxContainer
			bundle["rewardWorkspaceHead"] = page_root.get_node_or_null("RewardPanel/Margin/RewardBox/RewardBoardScroll/RewardBoard/RewardGrid/WorkspaceZone/Margin/ZoneBox/ZoneHead") as VBoxContainer
			bundle["rewardWorkspaceTitle"] = page_root.get_node_or_null("RewardPanel/Margin/RewardBox/RewardBoardScroll/RewardBoard/RewardGrid/WorkspaceZone/Margin/ZoneBox/ZoneHead/ZoneTitle") as Label
			bundle["rewardInspectorZone"] = page_root.get_node_or_null("RewardPanel/Margin/RewardBox/RewardBoardScroll/RewardBoard/RewardGrid/InspectorZone") as PanelContainer
			bundle["rewardBottomRow"] = page_root.get_node_or_null("RewardPanel/Margin/RewardBox/RewardBoardScroll/RewardBoard/BottomRow") as HBoxContainer
			bundle["rewardTitle"] = page_root.get_node_or_null("RewardPanel/Margin/RewardBox/BoardHead/BoardTitleBox/RewardTitle") as Label
			bundle["rewardSubtitle"] = page_root.get_node_or_null("RewardPanel/Margin/RewardBox/BoardHead/BoardTitleBox/RewardSubtitle") as Label
			bundle["rewardModePill"] = page_root.get_node_or_null("RewardPanel/Margin/RewardBox/BoardHead/ModePill") as Label
			bundle["rewardCardGrid"] = page_root.get_node_or_null("RewardPanel/Margin/RewardBox/RewardBoardScroll/RewardBoard/RewardGrid/RewardsZone/Margin/ZoneBox/RewardCloudBox/CloudMargin/CloudVBox/RewardCardGrid") as Control
			bundle["rewardCloudContent"] = page_root.get_node_or_null("RewardPanel/Margin/RewardBox/RewardBoardScroll/RewardBoard/RewardGrid/RewardsZone/Margin/ZoneBox/RewardCloudBox/CloudMargin/CloudVBox") as VBoxContainer
			bundle["rewardCloudBox"] = page_root.get_node_or_null("RewardPanel/Margin/RewardBox/RewardBoardScroll/RewardBoard/RewardGrid/RewardsZone/Margin/ZoneBox/RewardCloudBox") as PanelContainer
			bundle["rewardCloudNote"] = page_root.get_node_or_null("RewardPanel/Margin/RewardBox/RewardBoardScroll/RewardBoard/RewardGrid/RewardsZone/Margin/ZoneBox/RewardCloudBox/CloudMargin/CloudVBox/CloudNote") as Label
			bundle["rewardWorkspaceNote"] = page_root.get_node_or_null("RewardPanel/Margin/RewardBox/RewardBoardScroll/RewardBoard/RewardGrid/WorkspaceZone/Margin/ZoneBox/WorkspaceNote") as RichTextLabel
			bundle["rewardBackpackHost"] = page_root.get_node_or_null("RewardPanel/Margin/RewardBox/RewardBoardScroll/RewardBoard/RewardGrid/WorkspaceZone/Margin/ZoneBox/BackpackHost") as Control
			bundle["rewardInspectorKicker"] = page_root.get_node_or_null("RewardPanel/Margin/RewardBox/RewardBoardScroll/RewardBoard/RewardGrid/InspectorZone/Margin/ZoneBox/InspectorStage/InspectorKicker") as Label
			bundle["rewardInspectorName"] = page_root.get_node_or_null("RewardPanel/Margin/RewardBox/RewardBoardScroll/RewardBoard/RewardGrid/InspectorZone/Margin/ZoneBox/InspectorStage/InspectorName") as Label
			bundle["rewardInspectorSummary"] = page_root.get_node_or_null("RewardPanel/Margin/RewardBox/RewardBoardScroll/RewardBoard/RewardGrid/InspectorZone/Margin/ZoneBox/InspectorStage/InspectorSummary") as RichTextLabel
			bundle["rewardInspectorFacts"] = page_root.get_node_or_null("RewardPanel/Margin/RewardBox/RewardBoardScroll/RewardBoard/RewardGrid/InspectorZone/Margin/ZoneBox/InspectorStage/InspectorFacts") as GridContainer
			bundle["rewardInspectorStage"] = page_root.get_node_or_null("RewardPanel/Margin/RewardBox/RewardBoardScroll/RewardBoard/RewardGrid/InspectorZone/Margin/ZoneBox/InspectorStage") as VBoxContainer
			bundle["rewardFootprintTitle"] = page_root.get_node_or_null("RewardPanel/Margin/RewardBox/RewardBoardScroll/RewardBoard/RewardGrid/InspectorZone/Margin/ZoneBox/InspectorStage/FootprintCard/Margin/FootprintBox/FootprintTitle") as Label
			bundle["rewardFootprintInfo"] = page_root.get_node_or_null("RewardPanel/Margin/RewardBox/RewardBoardScroll/RewardBoard/RewardGrid/InspectorZone/Margin/ZoneBox/InspectorStage/FootprintCard/Margin/FootprintBox/FootprintInfo") as Label
			bundle["rewardFootprintGrid"] = page_root.get_node_or_null("RewardPanel/Margin/RewardBox/RewardBoardScroll/RewardBoard/RewardGrid/InspectorZone/Margin/ZoneBox/InspectorStage/FootprintCard/Margin/FootprintBox/FootprintGrid") as GridContainer
			bundle["discardZone"] = page_root.get_node_or_null("RewardPanel/Margin/RewardBox/RewardBoardScroll/RewardBoard/BottomRow/DiscardZone") as PanelContainer
			bundle["confirmZone"] = page_root.get_node_or_null("RewardPanel/Margin/RewardBox/RewardBoardScroll/RewardBoard/BottomRow/ConfirmZone") as PanelContainer
			bundle["discardCard"] = page_root.get_node_or_null("RewardPanel/Margin/RewardBox/RewardBoardScroll/RewardBoard/BottomRow/DiscardZone/Margin/ZoneBox/DiscardCard") as PanelContainer
			bundle["claimCard"] = page_root.get_node_or_null("RewardPanel/Margin/RewardBox/RewardBoardScroll/RewardBoard/BottomRow/ConfirmZone/Margin/ZoneBox/ClaimCard") as PanelContainer
			bundle["discardLabel"] = page_root.get_node_or_null("RewardPanel/Margin/RewardBox/RewardBoardScroll/RewardBoard/BottomRow/DiscardZone/Margin/ZoneBox/DiscardCard/Margin/DiscardCardBox/DiscardLabel") as Label
			bundle["claimCardBody"] = page_root.get_node_or_null("RewardPanel/Margin/RewardBox/RewardBoardScroll/RewardBoard/BottomRow/ConfirmZone/Margin/ZoneBox/ClaimCard/Margin/ClaimCardBox/ClaimCardBody") as Label
			bundle["claimInlineButton"] = page_root.get_node_or_null("RewardPanel/Margin/RewardBox/RewardBoardScroll/RewardBoard/BottomRow/ConfirmZone/Margin/ZoneBox/ClaimCard/Margin/ClaimCardBox/ClaimInlineButton") as Button
	return bundle

func _connect_page_shell_bundle_signals() -> void:
	for bundle in page_shell_bundles.values():
		var reset_btn := bundle.get("resetButton", null) as Button
		if reset_btn != null:
			reset_btn.pressed.connect(func(): reset_pressed.emit())
		var start_btn := bundle.get("startButton", null) as Button
		if start_btn != null:
			start_btn.pressed.connect(func(): call_deferred("_emit_start_combat_pressed"))
		var hold_btn := bundle.get("holdFireButton", null) as Button
		if hold_btn != null:
			hold_btn.pressed.connect(func(): hold_fire_pressed.emit())
		var repair_btn := bundle.get("repairButton", null) as Button
		if repair_btn != null:
			repair_btn.pressed.connect(func(): repair_pressed.emit())
			repair_btn.visible = false
		var claim_btn := bundle.get("claimRewardsButton", null) as Button
		if claim_btn != null:
			claim_btn.pressed.connect(func(): claim_rewards_pressed.emit())
		var inline_btn := bundle.get("claimInlineButton", null) as Button
		if inline_btn != null:
			inline_btn.pressed.connect(func(): claim_rewards_pressed.emit())
		var discard_shell := bundle.get("discardZone", null) as PanelContainer
		if discard_shell != null:
			discard_shell.gui_input.connect(func(ev): discard_zone_input.emit(ev))
			_set_descendant_mouse_filter_ignore(discard_shell)
			discard_shell.resized.connect(_queue_reward_board_layout_sync)
		var confirm_shell := bundle.get("confirmZone", null) as PanelContainer
		if confirm_shell != null:
			confirm_shell.resized.connect(_queue_reward_board_layout_sync)
		var backpack_panel = bundle.get("backpackUI", null)
		if backpack_panel != null:
			backpack_panel.slot_clicked.connect(func(coord): backpack_slot_clicked.emit(coord))
			backpack_panel.slot_hovered.connect(func(coord): backpack_slot_hovered.emit(coord))
			backpack_panel.slot_unhovered.connect(func(coord): backpack_slot_unhovered.emit(coord))
			backpack_panel.slot_drag_started.connect(func(coord):
				_begin_backpack_drag_tracking(coord)
				backpack_slot_drag_started.emit(coord)
			)
		var battlefield_panel = bundle.get("battlefieldUI", null)
		if battlefield_panel != null:
			battlefield_panel.cell_hovered.connect(func(cid, col): cell_hovered.emit(cid, col))
			battlefield_panel.cell_clicked.connect(func(cid, col): cell_clicked.emit(cid, col))
			battlefield_panel.cell_pressed.connect(func(cid, col): cell_pressed.emit(cid, col))
			battlefield_panel.cell_released.connect(func(): cell_released.emit())
		var top_row := bundle.get("topContent", null) as HBoxContainer
		if top_row != null:
			top_row.resized.connect(_queue_shared_backpack_layout_sync)
		var reward_grid_node := bundle.get("rewardGrid", null) as HBoxContainer
		if reward_grid_node != null:
			reward_grid_node.resized.connect(_queue_reward_board_layout_sync)
		var reward_host := bundle.get("rewardBackpackHost", null) as Control
		if reward_host != null:
			reward_host.resized.connect(_queue_reward_board_layout_sync)
		var reward_bottom := bundle.get("rewardBottomRow", null) as HBoxContainer
		if reward_bottom != null:
			reward_bottom.resized.connect(_queue_reward_board_layout_sync)
		var reward_cards := bundle.get("rewardCardGrid", null) as Control
		if reward_cards != null:
			reward_cards.resized.connect(_queue_reward_card_float_layout)

func _activate_action_bar_bundle(page_id: String) -> void:
	var bundle: Dictionary = _page_bundle(page_id)
	if bundle.is_empty():
		return
	_active_action_bar_bundle_id = page_id
	action_bar = bundle.get("actionBar", null) as HBoxContainer
	reset_button = bundle.get("resetButton", null) as Button
	start_button = bundle.get("startButton", null) as Button
	hold_fire_button = bundle.get("holdFireButton", null) as Button
	repair_button = bundle.get("repairButton", null) as Button
	claim_rewards_button = bundle.get("claimRewardsButton", null) as Button

func _activate_surface_bundle(page_id: String) -> void:
	var bundle: Dictionary = _page_bundle(page_id)
	if bundle.is_empty():
		return
	_active_surface_bundle_id = page_id
	top_content = bundle.get("topContent", top_content) as HBoxContainer
	left_column = bundle.get("leftColumn", left_column) as VBoxContainer
	portrait_placeholder = bundle.get("portraitPlaceholder", portrait_placeholder) as Panel
	portrait_label = bundle.get("portraitLabel", portrait_label) as Label
	backpack_container = bundle.get("backpackContainer", backpack_container) as AspectRatioContainer
	right_sidebar = bundle.get("rightSidebar", right_sidebar) as PanelContainer
	backpack_ui = bundle.get("backpackUI", backpack_ui)
	status_panel = bundle.get("statusPanel", status_panel)
	log_console = bundle.get("logConsole", log_console)
	backpack_original_parent = bundle.get("backpackOriginalParent", backpack_original_parent)
	backpack_original_index = int(bundle.get("backpackOriginalIndex", backpack_original_index))
	if bundle.get("battlefieldUI", null) != null:
		_assign_battle_bundle_refs(bundle)
	if bundle.get("rewardPanel", null) != null:
		_assign_reward_bundle_refs(bundle)
	_install_character_presentation()
	if reward_panel != null:
		_install_reward_backdrop()

func _assign_battle_bundle_refs(bundle: Dictionary) -> void:
	battlefield_ui = bundle.get("battlefieldUI", battlefield_ui)

func _assign_reward_bundle_refs(bundle: Dictionary) -> void:
	reward_panel = bundle.get("rewardPanel", reward_panel) as PanelContainer
	reward_panel_margin = bundle.get("rewardPanelMargin", reward_panel_margin) as MarginContainer
	reward_box = bundle.get("rewardBox", reward_box) as VBoxContainer
	reward_board_head = bundle.get("rewardBoardHead", reward_board_head) as HBoxContainer
	reward_board_scroll = bundle.get("rewardBoardScroll", reward_board_scroll) as ScrollContainer
	reward_board = bundle.get("rewardBoard", reward_board) as VBoxContainer
	reward_grid = bundle.get("rewardGrid", reward_grid) as HBoxContainer
	reward_rewards_zone = bundle.get("rewardRewardsZone", reward_rewards_zone) as PanelContainer
	reward_workspace_zone = bundle.get("rewardWorkspaceZone", reward_workspace_zone) as PanelContainer
	reward_workspace_margin = bundle.get("rewardWorkspaceMargin", reward_workspace_margin) as MarginContainer
	reward_workspace_box = bundle.get("rewardWorkspaceBox", reward_workspace_box) as VBoxContainer
	reward_workspace_head = bundle.get("rewardWorkspaceHead", reward_workspace_head) as VBoxContainer
	reward_workspace_title = bundle.get("rewardWorkspaceTitle", reward_workspace_title) as Label
	reward_inspector_zone = bundle.get("rewardInspectorZone", reward_inspector_zone) as PanelContainer
	reward_bottom_row = bundle.get("rewardBottomRow", reward_bottom_row) as HBoxContainer
	reward_title = bundle.get("rewardTitle", reward_title) as Label
	reward_subtitle = bundle.get("rewardSubtitle", reward_subtitle) as Label
	reward_mode_pill = bundle.get("rewardModePill", reward_mode_pill) as Label
	reward_card_grid = bundle.get("rewardCardGrid", reward_card_grid) as Control
	reward_cloud_content = bundle.get("rewardCloudContent", reward_cloud_content) as VBoxContainer
	reward_cloud_box = bundle.get("rewardCloudBox", reward_cloud_box) as PanelContainer
	reward_cloud_note = bundle.get("rewardCloudNote", reward_cloud_note) as Label
	reward_workspace_note = bundle.get("rewardWorkspaceNote", reward_workspace_note) as RichTextLabel
	reward_backpack_host = bundle.get("rewardBackpackHost", reward_backpack_host) as Control
	reward_inspector_kicker = bundle.get("rewardInspectorKicker", reward_inspector_kicker) as Label
	reward_inspector_name = bundle.get("rewardInspectorName", reward_inspector_name) as Label
	reward_inspector_summary = bundle.get("rewardInspectorSummary", reward_inspector_summary) as RichTextLabel
	reward_inspector_facts = bundle.get("rewardInspectorFacts", reward_inspector_facts) as GridContainer
	reward_inspector_stage = bundle.get("rewardInspectorStage", reward_inspector_stage) as VBoxContainer
	reward_footprint_title = bundle.get("rewardFootprintTitle", reward_footprint_title) as Label
	reward_footprint_info = bundle.get("rewardFootprintInfo", reward_footprint_info) as Label
	reward_footprint_grid = bundle.get("rewardFootprintGrid", reward_footprint_grid) as GridContainer
	discard_zone = bundle.get("discardZone", discard_zone) as PanelContainer
	confirm_zone = bundle.get("confirmZone", confirm_zone) as PanelContainer
	discard_card = bundle.get("discardCard", discard_card) as PanelContainer
	claim_card = bundle.get("claimCard", claim_card) as PanelContainer
	discard_label = bundle.get("discardLabel", discard_label) as Label
	claim_card_body = bundle.get("claimCardBody", claim_card_body) as Label
	claim_inline_button = bundle.get("claimInlineButton", claim_inline_button) as Button
	reward_cloud_scroll = bundle.get("rewardCloudScroll", reward_cloud_scroll) as ScrollContainer
	discard_card_scroll = bundle.get("discardCardScroll", discard_card_scroll) as ScrollContainer
	claim_card_scroll = bundle.get("claimCardScroll", claim_card_scroll) as ScrollContainer
	reward_inspector_scroll = bundle.get("rewardInspectorScroll", reward_inspector_scroll) as ScrollContainer
	_install_reward_zone_scroll_shells()
	_install_reward_inspector_scroll_shell()
	bundle["rewardCloudScroll"] = reward_cloud_scroll
	bundle["discardCardScroll"] = discard_card_scroll
	bundle["claimCardScroll"] = claim_card_scroll
	bundle["rewardInspectorScroll"] = reward_inspector_scroll
	_apply_shared_split_layout_text_policies()

func _register_page_scene(page_id: String, page_scene: Node) -> void:
	PageSceneRegistryScript.register_page_scene(
		page_scenes,
		page_id,
		page_scene,
		page_shell_host,
		meta_page_shell_host,
		META_PAGE_IDS
	)
	_sync_page_scene_bounds()

func _sync_page_scene_bounds() -> void:
	for page_id in page_scenes.keys():
		var page_scene := page_scenes.get(page_id) as Control
		if page_scene == null:
			continue
		var host: Control = meta_page_shell_host if PageSceneRegistryScript.is_meta_page(page_id, META_PAGE_IDS) else page_shell_host
		if host == null:
			continue
		page_scene.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func _render_page_scene(scene: Dictionary) -> void:
	var page_id := str(scene.get("pageId", ""))
	active_page_id = page_id
	var active_scene = PageSceneRegistryScript.activate_page(
		page_scenes,
		page_id,
		page_shell_host,
		meta_page_shell_host,
		META_PAGE_IDS
	)
	_sync_page_scene_bounds()
	if active_scene == null or not active_scene.has_method("apply_state"):
		return
	active_scene.apply_state(_page_scene_model(page_id, scene))

func _is_meta_page(page_id: String) -> bool:
	return PageSceneRegistryScript.is_meta_page(page_id, META_PAGE_IDS)

func _page_scene_model(page_id: String, scene: Dictionary) -> Dictionary:
	return PageSceneModelBuilderScript.project(page_id, scene, CHARACTER_PORTRAIT_PATH)

# ??쎈뻬: dynamically construct the full-page node-map selector inside the node-select panel.
func _install_character_presentation() -> void:
	if portrait_placeholder == null:
		return
	portrait_art = portrait_placeholder.get_node_or_null("PortraitArt") as TextureRect
	if portrait_art == null:
		portrait_art = TextureRect.new()
		portrait_art.name = "PortraitArt"
		portrait_art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		portrait_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		portrait_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		portrait_art.texture = LTLThemeScript.art_texture(CHARACTER_PORTRAIT_PATH)
		portrait_art.self_modulate = Color(0.92, 0.92, 0.92, 0.95)
		portrait_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
		portrait_placeholder.add_child(portrait_art)
		portrait_placeholder.move_child(portrait_art, 0)
	portrait_idle = portrait_placeholder.get_node_or_null("PortraitIdle") as TextureRect
	if portrait_idle == null:
		portrait_idle = TextureRect.new()
		portrait_idle.name = "PortraitIdle"
		portrait_idle.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		portrait_idle.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
		portrait_idle.texture = _character_sprite_frame(0)
		portrait_idle.size = Vector2(56.0, 82.0)
		portrait_idle.position = Vector2(portrait_placeholder.size.x - 58.0, 3.0)
		portrait_idle.mouse_filter = Control.MOUSE_FILTER_IGNORE
		portrait_idle.self_modulate = Color(1.0, 1.0, 1.0, 0.88)
		portrait_placeholder.add_child(portrait_idle)
	if portrait_label != null:
		portrait_label.visible = false
	if not portrait_placeholder.resized.is_connected(_layout_character_presentation):
		portrait_placeholder.resized.connect(_layout_character_presentation)
	call_deferred("_layout_character_presentation")

func _layout_character_presentation() -> void:
	if portrait_idle == null or portrait_placeholder == null:
		return
	var frame_size := Vector2(64.0, maxf(74.0, portrait_placeholder.size.y - 6.0))
	portrait_idle.size = frame_size
	portrait_idle.position = Vector2(maxf(6.0, portrait_placeholder.size.x - frame_size.x - 6.0), maxf(2.0, portrait_placeholder.size.y - frame_size.y - 2.0))

func _character_sprite_frame(index: int) -> Texture2D:
	var sheet := LTLThemeScript.art_texture(CHARACTER_SPRITE_SHEET_PATH)
	if sheet == null:
		return null
	var frame_width := 1024.0 / 5.0
	var frame_height := 1536.0 / 4.0
	var safe_index := posmod(index, 20)
	var column := safe_index % 5
	var row := int(floor(float(safe_index) / 5.0))
	return LTLThemeScript.atlas_frame(sheet, Rect2(column * frame_width, row * frame_height, frame_width, frame_height))

func _install_reward_backdrop() -> void:
	if reward_panel == null:
		return
	reward_backdrop = reward_panel.get_node_or_null("RewardBackdrop") as TextureRect
	if reward_backdrop == null:
		reward_backdrop = TextureRect.new()
		reward_backdrop.name = "RewardBackdrop"
		reward_backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		reward_backdrop.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		reward_backdrop.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		reward_backdrop.texture = LTLThemeScript.art_texture(REWARD_BACKDROP_PATH)
		reward_backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
		reward_backdrop.self_modulate = Color(0.58, 0.58, 0.58, 0.26)
		reward_panel.add_child(reward_backdrop)
		reward_panel.move_child(reward_backdrop, 0)

func _render_reward_backdrop(active: bool) -> void:
	if reward_backdrop == null:
		return
	reward_backdrop.visible = active

func _install_failure_backdrop() -> void:
	if repair_overlay == null or failure_backdrop != null:
		return
	failure_backdrop = TextureRect.new()
	failure_backdrop.name = "FailureBackdrop"
	failure_backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	failure_backdrop.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	failure_backdrop.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	failure_backdrop.texture = LTLThemeScript.art_texture(FAILURE_BACKDROP_PATH)
	failure_backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	failure_backdrop.self_modulate = Color(0.62, 0.30, 0.30, 0.24)
	repair_overlay.add_child(failure_backdrop)
	repair_overlay.move_child(failure_backdrop, 0)

func _render_failure_backdrop(scene: Dictionary) -> void:
	if failure_backdrop == null:
		return
	var overlay_active := repair_overlay != null and repair_overlay.visible
	failure_backdrop.visible = overlay_active
	if not overlay_active:
		return
	var selected_leviathan: Dictionary = scene.get("selectedLeviathan", {})
	var art_path := str(selected_leviathan.get("artPath", FAILURE_BACKDROP_PATH))
	if art_path.is_empty():
		art_path = FAILURE_BACKDROP_PATH
	failure_backdrop.texture = LTLThemeScript.art_texture(art_path)

func _render_character_status(scene: Dictionary) -> void:
	if portrait_art == null:
		return
	var stage_index := int(scene.get("stageIndex", 0)) + 1
	var max_stages := maxi(1, int(scene.get("maxStages", 1)))
	var stage_label_text := TextCatalogScript.t("stage.label", [stage_index, max_stages])
	var selected_color := str(scene.get("selectedStartColor", scene.get("selectedColor", "red")))
	var selected_character: Dictionary = scene.get("selectedCharacter", {})
	var fallback_character_id := str(selected_character.get("id", "miner"))
	var character_name := str(selected_character.get("name", TextCatalogScript.character_text(
		fallback_character_id,
		"name",
		TextCatalogScript.t("character.contract_runner")
	)))
	var portrait_path := str(selected_character.get("portraitPath", CHARACTER_PORTRAIT_PATH))
	portrait_art.texture = LTLThemeScript.art_texture(portrait_path)
	_set_rich_text(
		"RootMargin/AppShell/TopContent/RightSidebar/Margin/SidebarBox/TabViewport/ExplorerContent/Margin/CharacterBox/InventorySummaryLabel",
		("[b]%s[/b]\n%s\n%s" % [
			TextCatalogScript.display_name(character_name),
			stage_label_text,
			TextCatalogScript.t("character.front_color", [TextCatalogScript.color_label(selected_color)])
		])
	)

# ?ㅽ뻾: place the backpack beside the node map only during node selection.
func _apply_node_select_backpack_dock(dock: String, map_ratio: float, backpack_ratio: float) -> void:
	SharedBackpackHostCoordinatorScript.apply_node_select_backpack_dock(
		backpack_container,
		node_select_content_row,
		node_select_backpack_host,
		backpack_original_parent,
		backpack_original_index,
		dock,
		map_ratio,
		backpack_ratio,
		_node_select_backpack_width(),
		Callable(self, "_schedule_backpack_reparent")
	)

func _node_select_backpack_width() -> float:
	var row_size := Vector2.ZERO
	if node_select_content_row != null:
		row_size = node_select_content_row.size
		row_size.x = _viewport_safe_width_for_control(node_select_content_row, row_size.x)
	if row_size.y <= 1.0:
		row_size.y = active_phase_container.size.y
	if row_size.x <= 1.0:
		row_size.x = _viewport_safe_width_for_control(active_phase_container, active_phase_container.size.x)
	return node_select_backpack_width_for_row(row_size, NODE_SELECT_MAP_MIN_WIDTH)

func _sync_node_select_backpack_width() -> void:
	SharedBackpackHostCoordinatorScript.sync_node_select_backpack_width(
		backpack_container,
		node_select_backpack_host,
		_node_select_backpack_width()
	)

func _apply_reward_backpack_dock(dock_to_board: bool) -> void:
	SharedBackpackHostCoordinatorScript.apply_reward_backpack_dock(
		backpack_container,
		reward_backpack_host,
		backpack_original_parent,
		backpack_original_index,
		dock_to_board,
		Callable(self, "_set_reward_workspace_title_state"),
		Callable(self, "_schedule_backpack_reparent")
	)

func _sync_reward_backpack_layout() -> void:
	SharedBackpackHostCoordinatorScript.sync_reward_backpack_layout(
		backpack_container,
		reward_backpack_host,
		active_phase_container,
		Callable(self, "_reward_backpack_panel_dimensions_for_host"),
		Callable(self, "_set_custom_minimum_size_if_changed")
	)

func _queue_reward_board_layout_sync() -> void:
	if _reward_board_layout_sync_pending:
		return
	_reward_board_layout_sync_pending = true
	call_deferred("_sync_reward_board_layout")

func _install_reward_zone_scroll_shells() -> void:
	reward_cloud_scroll = _install_body_scroll_shell(reward_cloud_content, "RewardCloudScroll")
	discard_card_scroll = _install_body_scroll_shell(discard_card, "DiscardCardScroll")
	claim_card_scroll = _install_body_scroll_shell(claim_card, "ClaimCardScroll")

func _install_body_scroll_shell(body: Control, shell_name: String) -> ScrollContainer:
	if body == null:
		return null
	var existing_scroll := body.get_parent() as ScrollContainer
	if existing_scroll != null:
		return existing_scroll
	var host := body.get_parent()
	if host == null:
		return null
	var body_index := body.get_index()
	host.remove_child(body)
	var scroll := ScrollContainer.new()
	scroll.name = shell_name
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = 0
	scroll.clip_contents = true
	host.add_child(scroll)
	host.move_child(scroll, body_index)
	scroll.add_child(body)
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	return scroll

func _install_reward_inspector_scroll_shell() -> void:
	if reward_inspector_stage == null:
		return
	var existing_scroll := reward_inspector_stage.get_parent() as ScrollContainer
	if existing_scroll != null:
		reward_inspector_scroll = existing_scroll
		return
	var zone_box := reward_inspector_stage.get_parent() as VBoxContainer
	if zone_box == null:
		return
	var stage_index := reward_inspector_stage.get_index()
	zone_box.remove_child(reward_inspector_stage)
	reward_inspector_scroll = ScrollContainer.new()
	reward_inspector_scroll.name = "InspectorScroll"
	reward_inspector_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	reward_inspector_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	reward_inspector_scroll.horizontal_scroll_mode = 0
	reward_inspector_scroll.clip_contents = true
	zone_box.add_child(reward_inspector_scroll)
	zone_box.move_child(reward_inspector_scroll, stage_index)
	reward_inspector_scroll.add_child(reward_inspector_stage)
	reward_inspector_stage.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	reward_inspector_stage.size_flags_vertical = Control.SIZE_SHRINK_BEGIN

func _sync_reward_board_layout() -> void:
	_reward_board_layout_sync_pending = false
	if reward_grid == null or reward_workspace_zone == null or reward_backpack_host == null or reward_board_scroll == null:
		return
	_install_reward_zone_scroll_shells()
	_install_reward_inspector_scroll_shell()
	_set_reward_workspace_title_state(true)
	if reward_workspace_note != null:
		reward_workspace_note.visible = false
	if reward_workspace_box != null:
		_set_theme_constant_override_if_changed(reward_workspace_box, "separation", 12)
	if reward_workspace_margin != null:
		_set_theme_constant_override_if_changed(reward_workspace_margin, "margin_left", 14)
		_set_theme_constant_override_if_changed(reward_workspace_margin, "margin_top", 14)
		_set_theme_constant_override_if_changed(reward_workspace_margin, "margin_right", 14)
		_set_theme_constant_override_if_changed(reward_workspace_margin, "margin_bottom", 14)
	var grid_width := _reward_board_available_width()
	var grid_height := reward_grid.size.y
	if grid_width <= 1.0 or grid_height <= 1.0:
		return
	var visible_board_height := _reward_board_visible_height()
	_set_custom_minimum_height_if_changed(reward_board_scroll, visible_board_height)
	var layout_targets := _reward_board_layout_targets(visible_board_height)
	var top_zone_height := float(layout_targets.get("topZoneHeight", maxf(REWARD_BOARD_TOP_ZONE_MIN_HEIGHT, grid_height)))
	var bottom_row_height := float(layout_targets.get("bottomRowHeight", REWARD_BOARD_BOTTOM_ROW_MIN_HEIGHT))
	var rewards_body: Control = reward_cloud_scroll if reward_cloud_scroll != null else reward_cloud_box
	var rewards_body_height := _reward_zone_body_target_height(reward_rewards_zone, rewards_body, top_zone_height, 220.0)
	var workspace_body_height := _reward_zone_body_target_height(reward_workspace_zone, reward_backpack_host, top_zone_height, 220.0)
	var inspector_body: Control = reward_inspector_scroll if reward_inspector_scroll != null else reward_inspector_stage
	var inspector_body_height := _reward_zone_body_target_height(reward_inspector_zone, inspector_body, top_zone_height, 220.0)
	var discard_body_height := _reward_zone_body_target_height(discard_zone, discard_card, bottom_row_height, 72.0)
	var claim_body_height := _reward_zone_body_target_height(confirm_zone, claim_card, bottom_row_height, 72.0)
	top_zone_height = maxf(
		top_zone_height,
		maxf(
			reward_rewards_zone.get_combined_minimum_size().y,
			maxf(
				reward_workspace_zone.get_combined_minimum_size().y,
				reward_inspector_zone.get_combined_minimum_size().y
			)
		)
	)
	bottom_row_height = maxf(bottom_row_height, reward_bottom_row.get_combined_minimum_size().y)
	top_zone_height = maxf(REWARD_BOARD_TOP_ZONE_MIN_HEIGHT, visible_board_height - bottom_row_height - float(reward_board.get_theme_constant("separation")))
	rewards_body_height = _reward_zone_body_target_height(reward_rewards_zone, rewards_body, top_zone_height, 220.0)
	workspace_body_height = _reward_zone_body_target_height(reward_workspace_zone, reward_backpack_host, top_zone_height, 220.0)
	inspector_body_height = _reward_zone_body_target_height(reward_inspector_zone, inspector_body, top_zone_height, 220.0)
	discard_body_height = _reward_zone_body_target_height(discard_zone, discard_card, bottom_row_height, 72.0)
	claim_body_height = _reward_zone_body_target_height(confirm_zone, claim_card, bottom_row_height, 72.0)
	_set_custom_minimum_width_if_changed(reward_board, grid_width)
	_set_custom_minimum_width_if_changed(reward_grid, grid_width)
	_set_custom_minimum_height_if_changed(reward_board, top_zone_height + bottom_row_height + float(reward_board.get_theme_constant("separation")))
	_set_custom_minimum_height_if_changed(reward_grid, top_zone_height)
	reward_grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_set_custom_minimum_height_if_changed(reward_bottom_row, bottom_row_height)
	reward_bottom_row.size_flags_vertical = Control.SIZE_FILL
	_apply_reward_board_zone_height(reward_rewards_zone, top_zone_height)
	_apply_reward_board_zone_height(reward_workspace_zone, top_zone_height)
	_apply_reward_board_zone_height(reward_inspector_zone, top_zone_height)
	_apply_reward_board_zone_height(discard_zone, bottom_row_height)
	_apply_reward_board_zone_height(confirm_zone, bottom_row_height)
	if reward_cloud_scroll != null:
		_set_custom_minimum_height_if_changed(reward_cloud_scroll, rewards_body_height)
		reward_cloud_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
		reward_cloud_scroll.scroll_vertical = 0
	if reward_cloud_box != null:
		_set_custom_minimum_height_if_changed(reward_cloud_box, 0.0)
	if reward_backpack_host != null:
		_set_custom_minimum_height_if_changed(reward_backpack_host, workspace_body_height)
		reward_backpack_host.size_flags_vertical = Control.SIZE_EXPAND_FILL
	if reward_inspector_scroll != null:
		_set_custom_minimum_height_if_changed(reward_inspector_scroll, inspector_body_height)
		reward_inspector_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
		reward_inspector_scroll.scroll_vertical = 0
	if reward_inspector_stage != null:
		_set_custom_minimum_height_if_changed(reward_inspector_stage, 0.0)
	if discard_card_scroll != null:
		_set_custom_minimum_height_if_changed(discard_card_scroll, discard_body_height)
		discard_card_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
		discard_card_scroll.scroll_vertical = 0
	if claim_card_scroll != null:
		_set_custom_minimum_height_if_changed(claim_card_scroll, claim_body_height)
		claim_card_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
		claim_card_scroll.scroll_vertical = 0
	reward_board_scroll.scroll_vertical = 0
	var host_height := maxf(0.0, reward_workspace_zone.size.y - 4.0)
	var desired_panel := _reward_backpack_panel_dimensions_for_host(Vector2(maxf(0.0, grid_width), maxf(0.0, host_height)))
	var gap := float(reward_grid.get_theme_constant("separation"))
	var min_side_width := clampf(grid_width * 0.19, 188.0, 280.0)
	var desired_middle_width := clampf(desired_panel.x + 8.0, 320.0, maxf(320.0, grid_width - gap * 2.0))
	var max_middle_width := maxf(320.0, grid_width - gap * 2.0 - min_side_width * 2.0)
	if max_middle_width > 0.0:
		desired_middle_width = minf(desired_middle_width, max_middle_width)
	var remaining_width := maxf(0.0, grid_width - desired_middle_width - gap * 2.0)
	var side_width := maxf(min_side_width, remaining_width * 0.5)
	_set_custom_minimum_width_if_changed(reward_rewards_zone, side_width)
	_set_custom_minimum_width_if_changed(reward_inspector_zone, side_width)
	_set_custom_minimum_width_if_changed(reward_workspace_zone, desired_middle_width)
	var side_ratio := maxf(0.64, side_width / 240.0)
	reward_rewards_zone.size_flags_stretch_ratio = side_ratio
	reward_inspector_zone.size_flags_stretch_ratio = side_ratio
	reward_workspace_zone.size_flags_stretch_ratio = maxf(1.55, desired_middle_width / 240.0)
	_sync_reward_backpack_layout()

func _reward_board_available_width() -> float:
	var shell_width := _viewport_safe_app_shell_size().x
	if shell_width <= 1.0:
		shell_width = get_viewport_rect().size.x
	var horizontal_margin := 0.0
	if reward_panel_margin != null:
		horizontal_margin = float(
			reward_panel_margin.get_theme_constant("margin_left") +
			reward_panel_margin.get_theme_constant("margin_right")
		)
	return RewardBoardLayoutPolicyScript.board_available_width(shell_width, horizontal_margin)

func _reward_board_layout_targets(scroll_height: float) -> Dictionary:
	var bottom_min := REWARD_BOARD_BOTTOM_ROW_MIN_HEIGHT
	if reward_bottom_row != null:
		bottom_min = maxf(bottom_min, reward_bottom_row.get_combined_minimum_size().y)
	var board_gap := float(reward_board.get_theme_constant("separation")) if reward_board != null else 0.0
	return RewardBoardLayoutPolicyScript.board_layout_targets(
		scroll_height,
		board_gap,
		bottom_min,
		REWARD_BOARD_TOP_ZONE_MIN_HEIGHT,
		REWARD_BOARD_BOTTOM_ROW_RATIO
	)

func _reward_board_visible_height() -> float:
	if reward_panel == null or reward_panel_margin == null or reward_box == null or reward_board_head == null:
		return REWARD_BOARD_TOP_ZONE_MIN_HEIGHT + REWARD_BOARD_BOTTOM_ROW_MIN_HEIGHT + 16.0
	var panel_height := minf(reward_panel.size.y, _max_safe_active_phase_height())
	if panel_height <= 1.0:
		panel_height = maxf(_max_safe_active_phase_height(), reward_panel.get_combined_minimum_size().y)
	if panel_height <= 1.0:
		return REWARD_BOARD_TOP_ZONE_MIN_HEIGHT + REWARD_BOARD_BOTTOM_ROW_MIN_HEIGHT + 16.0
	var outer_margin := float(
		reward_panel_margin.get_theme_constant("margin_top") +
		reward_panel_margin.get_theme_constant("margin_bottom")
	)
	var reward_box_gap := float(reward_box.get_theme_constant("separation"))
	var head_height := reward_board_head.get_combined_minimum_size().y
	var min_board_height := REWARD_BOARD_TOP_ZONE_MIN_HEIGHT + REWARD_BOARD_BOTTOM_ROW_MIN_HEIGHT + float(reward_board.get_theme_constant("separation"))
	return maxf(min_board_height, panel_height - outer_margin - reward_box_gap - head_height - 2.0)

func _apply_reward_board_zone_height(zone: Control, target_height: float) -> void:
	if zone == null:
		return
	_set_custom_minimum_height_if_changed(zone, target_height)
	zone.size_flags_vertical = Control.SIZE_EXPAND_FILL

func _reward_zone_body_target_height(zone: Control, body: Control, target_height: float, fallback_min: float) -> float:
	if zone == null or body == null:
		return maxf(fallback_min, target_height)
	return RewardBoardLayoutPolicyScript.zone_body_target_height(
		zone.get_combined_minimum_size().y,
		body.get_combined_minimum_size().y,
		target_height,
		fallback_min
	)

func _set_theme_constant_override_if_changed(control: Control, key: StringName, value: int) -> void:
	if control == null:
		return
	if control.get_theme_constant(key) == value:
		return
	control.add_theme_constant_override(key, value)

func _set_custom_minimum_size_if_changed(control: Control, next_size: Vector2, epsilon: float = 0.5) -> void:
	if control == null:
		return
	if control.custom_minimum_size.distance_to(next_size) <= epsilon:
		return
	control.custom_minimum_size = next_size

func _set_custom_minimum_height_if_changed(control: Control, next_height: float, epsilon: float = 0.5) -> void:
	if control == null:
		return
	if absf(control.custom_minimum_size.y - next_height) <= epsilon:
		return
	control.custom_minimum_size.y = next_height

func _set_custom_minimum_width_if_changed(control: Control, next_width: float, epsilon: float = 0.5) -> void:
	if control == null:
		return
	if absf(control.custom_minimum_size.x - next_width) <= epsilon:
		return
	control.custom_minimum_size.x = next_width

func _reward_backpack_panel_dimensions_for_host(host_size: Vector2) -> Vector2:
	var chrome := _reward_backpack_panel_chrome_dimensions()
	return RewardBoardLayoutPolicyScript.backpack_panel_dimensions_for_host(
		host_size,
		chrome.x,
		chrome.y,
		_reward_backpack_panel_visible_height_cap()
	)

func _reward_backpack_panel_chrome_dimensions() -> Vector2:
	var margin_width := 32.0
	var chrome_height := 56.0
	if backpack_ui == null:
		return Vector2(margin_width, chrome_height)
	var margin := backpack_ui.get_node_or_null("Margin") as MarginContainer
	if margin != null:
		margin_width = float(
			margin.get_theme_constant("margin_left") +
			margin.get_theme_constant("margin_right")
		)
		chrome_height = float(
			margin.get_theme_constant("margin_top") +
			margin.get_theme_constant("margin_bottom")
		)
	var engine_box := backpack_ui.get_node_or_null("Margin/EngineBox") as VBoxContainer
	var title := backpack_ui.get_node_or_null("Margin/EngineBox/EngineTitle") as Control
	if engine_box != null and title != null and title.visible:
		chrome_height += float(engine_box.get_theme_constant("separation"))
	if title != null and title.visible:
		chrome_height += title.get_combined_minimum_size().y
	return Vector2(margin_width, chrome_height)

func _set_reward_workspace_title_state(dock_to_board: bool) -> void:
	if reward_workspace_head != null:
		reward_workspace_head.visible = dock_to_board
	if reward_workspace_title != null and dock_to_board:
		reward_workspace_title.text = TextCatalogScript.t("panel.backpack")
	var backpack_engine_title := backpack_ui.get_node_or_null("Margin/EngineBox/EngineTitle") as Control
	if backpack_engine_title != null:
		backpack_engine_title.visible = not dock_to_board

func _resolved_header_title(scene: Dictionary) -> String:
	var selected_leviathan: Dictionary = scene.get("selectedLeviathan", {})
	var leviathan_name := str(selected_leviathan.get("name", "")).strip_edges()
	if not leviathan_name.is_empty():
		return leviathan_name
	return TextCatalogScript.t("app.title")

func _reward_backpack_panel_visible_height_cap() -> float:
	if reward_panel == null or reward_panel_margin == null or reward_box == null or reward_board_head == null or reward_board == null or reward_bottom_row == null:
		return 0.0
	var panel_height := minf(reward_panel.size.y, _max_safe_active_phase_height())
	if panel_height <= 1.0:
		panel_height = _max_safe_active_phase_height()
	if panel_height <= 1.0:
		return 0.0
	var outer_margin := float(
		reward_panel_margin.get_theme_constant("margin_top") +
		reward_panel_margin.get_theme_constant("margin_bottom")
	)
	var reward_box_gap := float(reward_box.get_theme_constant("separation"))
	var reward_board_gap := float(reward_board.get_theme_constant("separation"))
	var head_height := reward_board_head.get_combined_minimum_size().y
	var bottom_row_height := maxf(reward_bottom_row.get_combined_minimum_size().y, reward_bottom_row.custom_minimum_size.y)
	return AppShellLayoutPolicyScript.reward_backpack_panel_visible_height_cap(
		panel_height,
		outer_margin,
		reward_box_gap,
		reward_board_gap,
		head_height,
		bottom_row_height
	)

func _max_safe_active_phase_height() -> float:
	var shell_size := _viewport_safe_app_shell_size()
	var section_gap := float(app_shell.get_theme_constant("separation")) if app_shell != null else 0.0
	var header_height := float(header_panel.get_combined_minimum_size().y) if header_panel != null and header_panel.visible else 0.0
	var top_content_height := float(top_content.get_combined_minimum_size().y) if top_content != null and top_content.visible else 0.0
	var action_bar_height := float(action_bar.get_combined_minimum_size().y) if action_bar != null and action_bar.visible else 0.0
	return AppShellLayoutPolicyScript.max_safe_active_phase_height(
		shell_size,
		section_gap,
		header_height,
		top_content_height,
		_active_phase_surface_visible(),
		action_bar_height
	)

func _top_content_backpack_height() -> float:
	var min_row_height := maxf(float(top_content.get_combined_minimum_size().y), BackpackPinLayoutPolicyScript.MIN_TOP_CONTENT_GRID_EXTENT)
	var resolved_height := resolved_top_content_backpack_height(top_content.size.y, min_row_height, backpack_container.size.y)
	var safe_height := _max_safe_top_content_height()
	if safe_height > 0.0:
		resolved_height = safe_height
	return resolved_height

func _top_content_backpack_width() -> float:
	var target_height := _top_content_backpack_height()
	return top_content_backpack_width_for_height(target_height)

func _apply_top_content_backpack_bounds() -> void:
	var target_height := _top_content_backpack_height()
	var resolved_width := top_content_backpack_width_for_height(target_height)
	var safe_width_cap := _max_safe_top_content_backpack_width()
	if safe_width_cap > 0.0 and resolved_width > safe_width_cap:
		target_height = minf(target_height, BackpackPinLayoutPolicyScript.top_content_height_for_width(safe_width_cap))
		resolved_width = top_content_backpack_width_for_height(target_height)
		if resolved_width > safe_width_cap:
			resolved_width = safe_width_cap
	top_content.custom_minimum_size.y = target_height
	backpack_container.custom_minimum_size = Vector2(resolved_width, 0.0)
	backpack_container.ratio = top_content_backpack_ratio_for_height(target_height)

func _viewport_safe_app_shell_size() -> Vector2:
	var horizontal_margin := 0.0
	var vertical_margin := 0.0
	if root_margin != null:
		horizontal_margin = float(root_margin.get_theme_constant("margin_left") + root_margin.get_theme_constant("margin_right"))
		vertical_margin = float(root_margin.get_theme_constant("margin_top") + root_margin.get_theme_constant("margin_bottom"))
	return AppShellLayoutPolicyScript.viewport_safe_size(get_viewport_rect().size, horizontal_margin, vertical_margin)

func _app_shell_visible_section_count() -> int:
	return AppShellLayoutPolicyScript.visible_section_count(
		header_panel != null and header_panel.visible,
		top_content != null and top_content.visible,
		_active_phase_surface_visible(),
		action_bar != null and action_bar.visible
	)

func _active_phase_surface_visible() -> bool:
	return active_phase_container != null and AppShellLayoutPolicyScript.active_phase_visible(
		battlefield_ui != null and battlefield_ui.visible,
		reward_panel != null and reward_panel.visible,
		page_shell_host != null and page_shell_host.visible
	)

func _active_phase_min_height() -> float:
	var min_height := 0.0
	if battlefield_ui != null and battlefield_ui.visible:
		min_height = maxf(min_height, float(battlefield_ui.get_combined_minimum_size().y))
	if reward_panel != null and reward_panel.visible:
		min_height = maxf(min_height, float(reward_panel.get_combined_minimum_size().y))
	return min_height

func _max_safe_top_content_height() -> float:
	var shell_size := _viewport_safe_app_shell_size()
	var section_gap := float(app_shell.get_theme_constant("separation")) if app_shell != null else 0.0
	return AppShellLayoutPolicyScript.max_safe_top_content_height(
		shell_size,
		section_gap,
		header_panel != null and header_panel.visible,
		float(header_panel.get_combined_minimum_size().y) if header_panel != null else 0.0,
		_active_phase_surface_visible(),
		_active_phase_min_height(),
		action_bar != null and action_bar.visible,
		float(action_bar.get_combined_minimum_size().y) if action_bar != null else 0.0,
		top_content != null and top_content.visible
	)

func _max_safe_top_content_backpack_width() -> float:
	if top_content == null or not top_content.visible:
		return 0.0
	var shell_size := _viewport_safe_app_shell_size()
	var row_gap := float(top_content.get_theme_constant("separation"))
	var left_min := float(left_column.get_combined_minimum_size().x) if left_column != null and left_column.visible else 0.0
	var right_min := float(right_sidebar.get_combined_minimum_size().x) if right_sidebar != null and right_sidebar.visible else 0.0
	return AppShellLayoutPolicyScript.max_safe_backpack_width(shell_size.x, row_gap, left_min, right_min)

func _viewport_safe_width_for_control(control: Control, fallback_width: float) -> float:
	var width := maxf(0.0, fallback_width)
	if control == null or not is_inside_tree():
		return width
	var viewport_width := get_viewport_rect().size.x
	if viewport_width <= 1.0:
		return width
	var left_edge := maxf(0.0, control.global_position.x)
	var safe_right := maxf(0.0, viewport_width - VIEWPORT_SAFE_GUTTER)
	var viewport_width_from_control := maxf(0.0, safe_right - left_edge)
	if width <= 1.0:
		return viewport_width_from_control
	return minf(width, viewport_width_from_control)

func _sync_top_content_backpack_layout() -> void:
	SharedBackpackHostCoordinatorScript.sync_top_content_backpack_layout(
		backpack_container,
		backpack_original_parent,
		top_content,
		Callable(self, "_apply_top_content_backpack_bounds")
	)

func _queue_shared_backpack_layout_sync() -> void:
	var queue_state: Dictionary = SharedBackpackHostCoordinatorScript.queue_shared_backpack_layout_sync(
		backpack_container,
		reward_backpack_host,
		_shared_backpack_layout_sync_pending,
		Callable(self, "_queue_reward_board_layout_sync")
	)
	_shared_backpack_layout_sync_pending = bool(queue_state.get("sharedLayoutSyncPending", false))
	if bool(queue_state.get("shouldDeferSharedSync", false)):
		call_deferred("_sync_shared_backpack_layout")

func _sync_shared_backpack_layout() -> void:
	_shared_backpack_layout_sync_pending = false
	SharedBackpackHostCoordinatorScript.sync_shared_backpack_layout(
		backpack_container,
		reward_backpack_host,
		node_select_backpack_host,
		backpack_original_parent,
		Callable(self, "_sync_node_select_backpack_width"),
		Callable(self, "_sync_top_content_backpack_layout")
	)

# ?ㅽ뻾: update shop label and buttons.
func render_shop(growth_state: Dictionary) -> void:
	if shop_panel != null and shop_panel.has_method("render_shop"):
		shop_panel.render_shop(growth_state)
		_defer_interaction_fx_install()
		return

# ?ㅽ뻾: project and render the artifact codex from reward data and discovery state.
func render_artifact_codex(reward_table: Dictionary, growth_state: Dictionary, debug_all: bool = false) -> void:
	if codex_panel == null or not codex_panel.has_method("render_codex"):
		return
	current_codex_reward_table = reward_table.duplicate(true)
	current_codex_growth_state = growth_state.duplicate(true)
	current_codex_debug_all = debug_all
	var model := ArtifactCodexReadModelScript.project(
		current_codex_reward_table,
		current_codex_growth_state,
		current_codex_debug_all,
		"",
		current_codex_selected_entry_id,
		current_codex_active_section
	)
	current_codex_selected_entry_id = str(model.get("resolvedSelectedEntryId", ""))
	current_codex_active_section = str(model.get("activeSection", "all"))
	codex_panel.render_codex(model)
	_defer_interaction_fx_install()

# ?ㅽ뻾: rerender the current codex model when the debug visibility toggle changes.
func _on_codex_debug_toggled(debug_all: bool) -> void:
	current_codex_debug_all = debug_all
	if current_codex_reward_table.is_empty():
		return
	call_deferred("_rerender_current_codex")

# ?ㅽ뻾: persist the current codex entry selection and rerender the book detail page.
func _on_codex_entry_selected(entry_id: String) -> void:
	current_codex_selected_entry_id = entry_id
	if current_codex_reward_table.is_empty():
		return
	call_deferred("_rerender_current_codex")

# ?ㅽ뻾: persist the current codex section tab and rerender the right-page grid.
func _on_codex_section_selected(section_id: String) -> void:
	current_codex_active_section = section_id
	if current_codex_reward_table.is_empty():
		return
	call_deferred("_rerender_current_codex")

# ?ㅽ뻾: rerender the current codex state outside active button/toggle signal stacks.
func _rerender_current_codex() -> void:
	if current_codex_reward_table.is_empty():
		return
	render_artifact_codex(current_codex_reward_table, current_codex_growth_state, current_codex_debug_all)

# ?ㅽ뻾: install shader/tween affordance effects on interactive controls.
func _install_interaction_fx() -> void:
	InteractionFXScript.install_tree(self)

# ?ㅽ뻾: give major panels and buttons a coherent in-world UI language.
func _apply_shell_theme() -> void:
	var surface := LTLThemeScript.surface_style(LTLThemeScript.SURFACE_MID)
	for page_id in SURFACE_PAGE_IDS:
		var bundle: Dictionary = _page_bundle(page_id)
		if bundle.is_empty():
			continue
		var status = bundle.get("statusPanel", null)
		if status != null:
			status.add_theme_stylebox_override("panel", surface)
		var backpack_panel = bundle.get("backpackUI", null)
		if backpack_panel != null:
			backpack_panel.add_theme_stylebox_override("panel", surface)
		var sidebar = bundle.get("rightSidebar", null)
		if sidebar != null:
			sidebar.add_theme_stylebox_override("panel", surface)
		var battlefield_panel = bundle.get("battlefieldUI", null)
		if battlefield_panel != null:
			battlefield_panel.add_theme_stylebox_override("panel", surface)
		var reward_surface = bundle.get("rewardPanel", null) as PanelContainer
		if reward_surface != null:
			reward_surface.add_theme_stylebox_override("panel", LTLThemeScript.surface_style(Color(0.10, 0.11, 0.13, 0.98), LTLThemeScript.BORDER_WARM, 12))
			for zone_path in [
				"RewardPanel/Margin/RewardBox/RewardBoardScroll/RewardBoard/RewardGrid/RewardsZone",
				"RewardPanel/Margin/RewardBox/RewardBoardScroll/RewardBoard/RewardGrid/WorkspaceZone",
				"RewardPanel/Margin/RewardBox/RewardBoardScroll/RewardBoard/RewardGrid/InspectorZone",
				"RewardPanel/Margin/RewardBox/RewardBoardScroll/RewardBoard/RewardGrid/RewardsZone/Margin/ZoneBox/RewardCloudBox",
				"RewardPanel/Margin/RewardBox/RewardBoardScroll/RewardBoard/RewardGrid/InspectorZone/Margin/ZoneBox/InspectorStage/FootprintCard",
				"RewardPanel/Margin/RewardBox/RewardBoardScroll/RewardBoard/BottomRow/ConfirmZone"
			]:
				var zone = _bundle_node(page_id, zone_path) as PanelContainer
				if zone != null:
					zone.add_theme_stylebox_override("panel", LTLThemeScript.surface_style(Color(0.11, 0.14, 0.18, 0.98), LTLThemeScript.BORDER_COLD, 18, 1, 0.18))
			var discard_shell = _bundle_node(page_id, "RewardPanel/Margin/RewardBox/RewardBoardScroll/RewardBoard/BottomRow/DiscardZone") as PanelContainer
			if discard_shell != null:
				discard_shell.add_theme_stylebox_override("panel", LTLThemeScript.surface_style(Color(0.14, 0.08, 0.09, 0.98), Color(0.68, 0.28, 0.28, 1.0), 18, 1, 0.20))
			var discard_card_panel = _bundle_node(page_id, "RewardPanel/Margin/RewardBox/RewardBoardScroll/RewardBoard/BottomRow/DiscardZone/Margin/ZoneBox/DiscardCard") as PanelContainer
			if discard_card_panel != null:
				discard_card_panel.add_theme_stylebox_override("panel", LTLThemeScript.surface_style(Color(0.18, 0.09, 0.10, 0.98), Color(0.78, 0.34, 0.34, 1.0), 16, 1, 0.16))
			var claim_card_panel = _bundle_node(page_id, "RewardPanel/Margin/RewardBox/RewardBoardScroll/RewardBoard/BottomRow/ConfirmZone/Margin/ZoneBox/ClaimCard") as PanelContainer
			if claim_card_panel != null:
				claim_card_panel.add_theme_stylebox_override("panel", LTLThemeScript.surface_style(Color(0.18, 0.15, 0.09, 0.98), LTLThemeScript.BORDER_WARM, 16, 1, 0.16))
	repair_overlay.add_theme_stylebox_override("panel", LTLThemeScript.overlay_style("warning"))
	for button in [settings_open_button, reset_button, start_button, hold_fire_button, repair_button, claim_rewards_button, claim_inline_button, shop_open_button, codex_open_button]:
		if button != null:
			_style_shell_button(button)
	for page_id in ACTION_BAR_PAGE_IDS:
		var bundle: Dictionary = _page_bundle(page_id)
		for key in ["resetButton", "startButton", "holdFireButton", "repairButton", "claimRewardsButton", "claimInlineButton"]:
			var button = bundle.get(key, null) as Button
			if button != null:
				_style_shell_button(button)
	for key in ["shopButton", "codexButton", "settingsButton"]:
		var node_select_button := _page_bundle("node_select").get(key, null) as Button
		if node_select_button != null:
			_style_shell_button(node_select_button)

func _style_shell_button(button: Button) -> void:
	ShellButtonStylerScript.apply_button(button, header_actions, action_bar)

func _apply_top_content_stretch(left_ratio: float, backpack_ratio: float, right_ratio: float) -> void:
	SharedBackpackHostCoordinatorScript.apply_top_content_stretch(left_column, backpack_container, backpack_original_parent, right_sidebar, left_ratio, backpack_ratio, right_ratio)

func _create_giant_timer() -> void:
	giant_timer_ui = GiantTimerUIScript.new()
	add_child(giant_timer_ui)
	giant_timer_ui.ensure_built()
	giant_timer_panel = giant_timer_ui.timer_panel
	giant_timer_label = giant_timer_ui.timer_label
	vignette_overlay = giant_timer_ui.vignette_overlay
	heartbeat_player = giant_timer_ui.heartbeat_player

# ?ㅽ뻾: dynamically construct the full-screen reward reveal overlay.
func _create_reward_reveal_overlay() -> void:
	reward_reveal_overlay = RewardRevealOverlayScript.new()
	reward_reveal_overlay.name = "RewardRevealOverlay"
	reward_reveal_overlay.z_index = REWARD_REVEAL_OVERLAY_Z_INDEX
	reward_reveal_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(reward_reveal_overlay)

# ?ㅽ뻾: dynamically construct full-screen vignette overlay panel.
func _create_vignette_overlay() -> void:
	if giant_timer_ui != null:
		return

# ?ㅽ뻾: animate flashing timer label and pulsing red vignette overlay when time is critical.
func _process(delta: float) -> void:
	_update_tooltip_position()
	pulse_time += delta
	if portrait_idle != null and portrait_idle.visible:
		var frame_index := int(floor(pulse_time * 5.0)) % 20
		portrait_idle.texture = _character_sprite_frame(frame_index)
		portrait_idle.position.y = maxf(2.0, portrait_placeholder.size.y - portrait_idle.size.y - 2.0) + sin(pulse_time * 2.2) * 1.5
	if reward_backdrop != null and reward_backdrop.visible:
		reward_backdrop.self_modulate.a = 0.24 + 0.03 * sin(pulse_time * 0.9)
	if reward_panel != null and reward_panel.visible:
		for button in reward_card_buttons:
			_apply_reward_card_idle_transform(button)
	if battle_pause_active:
		return
	if giant_timer_ui != null and giant_timer_ui.has_method("process_timer"):
		giant_timer_ui.process_timer(delta, battlefield_ui)
		return

# ?ㅽ뻾: set the audio player volume.
func set_volume(val: float) -> void:
	_heartbeat_volume = val
	if giant_timer_ui != null and giant_timer_ui.has_method("set_volume"):
		giant_timer_ui.set_volume(val)
		return

# ?ㅽ뻾: dynamically construct the floating info tooltip panel.
func _create_tooltip_panel() -> void:
	tooltip_panel = ArtifactTooltipUIScript.new()
	add_child(tooltip_panel)
	if tooltip_panel.has_method("get"):
		tooltip_label = tooltip_panel.label

# ?ㅽ뻾: show the floating artifact info tooltip.
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

# ?ㅽ뻾: show a reward tooltip with inventory comparison context.
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

# ?ㅽ뻾: hide the floating artifact info tooltip.
func hide_artifact_tooltip() -> void:
	if tooltip_panel and tooltip_panel.has_method("hide_tooltip"):
		tooltip_panel.hide_tooltip()
		return
	if tooltip_panel:
		tooltip_panel.visible = false

# ??쎈뻬: update the floating tooltip position.
func _update_tooltip_position() -> void:
	if tooltip_panel and tooltip_panel.has_method("update_position"):
		tooltip_panel.update_position(get_global_mouse_position())
		return
	if tooltip_panel and tooltip_panel.visible:
		var m_pos = get_global_mouse_position()
		tooltip_panel.global_position = m_pos + Vector2(15, 15)

func _emit_start_combat_pressed() -> void:
	start_combat_pressed.emit()

func _defer_interaction_fx_install() -> void:
	if not interaction_fx_enabled:
		return
	call_deferred("_install_interaction_fx")

func _schedule_backpack_reparent(target_parent: Node, target_index: int = -1) -> void:
	if backpack_container == null or target_parent == null:
		return
	_pending_backpack_parent = target_parent
	_pending_backpack_parent_index = target_index
	if _backpack_reparent_pending:
		return
	_backpack_reparent_pending = true
	call_deferred("_commit_backpack_reparent")

func _commit_backpack_reparent() -> void:
	_backpack_reparent_pending = false
	var reparent_state: Dictionary = SharedBackpackHostCoordinatorScript.commit_backpack_reparent(
		backpack_container,
		_pending_backpack_parent,
		_pending_backpack_parent_index,
		backpack_original_parent,
		reward_backpack_host,
		node_select_backpack_host,
		Callable(self, "_queue_shared_backpack_layout_sync"),
		Callable(self, "_queue_reward_board_layout_sync"),
		Callable(),
		Callable(self, "_flush_pending_backpack_pin_scene")
	)
	_pending_backpack_parent = reparent_state.get("pendingBackpackParent", null)
	_pending_backpack_parent_index = int(reparent_state.get("pendingBackpackParentIndex", -1))

func _flush_pending_backpack_pin_scene() -> void:
	if _backpack_reparent_pending:
		return
	_pending_backpack_pin_scene = SharedBackpackHostCoordinatorScript.flush_pending_backpack_pin_scene(
		backpack_ui,
		_pending_backpack_pin_scene
	)
