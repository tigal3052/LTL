# 계약:
# - 책임: 메인 런타임 화면의 페이지 셸, 전투 HUD, 오버레이, 입력 신호를 한 화면에서 조율한다.
# 실행: define the main-scene UI view as a PanelContainer script and declare signals.
# 怨꾩빟:
# - 筌?굞?? UI ?遺용꺖??????筌욊낯??怨몄뵥 筌〓챷?쒐몴??온?귐뗫릭?????????낆젾 ??源?紐? ?醫륁깈(Signals)嚥?癰궰??묐퉸 獄쎻뫗???렽? ??롫짗 ???쐭筌??紐꾪뀱????쎈뻬??뺣뼄. ?袁⑸뻻 癰귣똻???怨몄젎 ??ㅺ섯??餓λ쵐釉?椰꾧퀡? ?遺?????????獄?筌뤴뫁苑뚨뵳?筌띘삳짗 ??쑬苑????ｋ궢(VFX)????덉읅??곗쨮 ??슢諭??뺣뼄.
# - ??낆젾: MainController(?????쎈뱜??됱뵠???????쐭筌?獄??怨쀭뀱 ?紐꾪뀱 筌뤿굝議? 揶?甕곌쑵????????????낆젾 ??源??
# - ?곗뮆?? ???????る????????볥젃??獄쎻뫗??reset_pressed, start_combat_pressed, hold_fire_pressed, shop_open_pressed, buy_passive, etc.)
# - 疫뀀뜆?: ??쑴已??됰뮞 ?????됱뵠??筌욊낯??筌〓챷?? ?袁⑥컭???怨밴묶 癰궰野?

# ?ㅽ뻾: define the main-scene UI view as a PanelContainer script and declare signals.
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
const NodeMapReadModelScript = preload("res://src/ui/read_models/NodeMapReadModel.gd")
const LTLThemeScript = preload("res://src/ui/theme/LTLTheme.gd")
const NodeMapSceneScript = preload("res://src/scenes/node_map/NodeMapScene.gd")
const ShopPanelUIScript = preload("res://src/ui/ShopPanelUI.gd")
const PopupOverlayHostScript = preload("res://src/ui/PopupOverlayHost.gd")
const PageSceneRegistryScript = preload("res://src/ui/PageSceneRegistry.gd")
const PageSceneModelBuilderScript = preload("res://src/ui/PageSceneModelBuilder.gd")
const ArtifactCodexPanelUIScript = preload("res://src/ui/ArtifactCodexPanelUI.gd")
const ArtifactCodexReadModelScript = preload("res://src/ui/read_models/ArtifactCodexReadModel.gd")
const ArtifactTooltipUIScript = preload("res://src/ui/ArtifactTooltipUI.gd")
const GiantTimerUIScript = preload("res://src/ui/GiantTimerUI.gd")
const RewardRevealOverlayScript = preload("res://src/ui/RewardRevealOverlay.gd")
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
const REWARD_CARD_FLOAT_EDGE_PADDING := 9.0
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
@onready var top_content: HBoxContainer = $RootMargin/AppShell/TopContent
@onready var active_phase_container: Control = $RootMargin/AppShell/ActivePhaseContainer
@onready var left_column: VBoxContainer = $RootMargin/AppShell/TopContent/LeftColumn
@onready var portrait_placeholder: Panel = $RootMargin/AppShell/TopContent/LeftColumn/LeftSidebar/Margin/CharacterBox/PortraitPlaceholder
@onready var portrait_label: Label = $RootMargin/AppShell/TopContent/LeftColumn/LeftSidebar/Margin/CharacterBox/PortraitPlaceholder/PortraitLabel
@onready var backpack_container: AspectRatioContainer = $RootMargin/AppShell/TopContent/BackpackContainer
@onready var right_sidebar: PanelContainer = $RootMargin/AppShell/TopContent/RightSidebar
@onready var reward_panel: PanelContainer = $RootMargin/AppShell/ActivePhaseContainer/RewardPanel
@onready var reward_panel_margin: MarginContainer = $RootMargin/AppShell/ActivePhaseContainer/RewardPanel/Margin
@onready var reward_box: VBoxContainer = $RootMargin/AppShell/ActivePhaseContainer/RewardPanel/Margin/RewardBox
@onready var reward_board_head: HBoxContainer = $RootMargin/AppShell/ActivePhaseContainer/RewardPanel/Margin/RewardBox/BoardHead
@onready var reward_board_scroll: ScrollContainer = $RootMargin/AppShell/ActivePhaseContainer/RewardPanel/Margin/RewardBox/RewardBoardScroll
@onready var reward_board: VBoxContainer = $RootMargin/AppShell/ActivePhaseContainer/RewardPanel/Margin/RewardBox/RewardBoardScroll/RewardBoard
@onready var reward_grid: HBoxContainer = $RootMargin/AppShell/ActivePhaseContainer/RewardPanel/Margin/RewardBox/RewardBoardScroll/RewardBoard/RewardGrid
@onready var reward_rewards_zone: PanelContainer = $RootMargin/AppShell/ActivePhaseContainer/RewardPanel/Margin/RewardBox/RewardBoardScroll/RewardBoard/RewardGrid/RewardsZone
@onready var reward_workspace_zone: PanelContainer = $RootMargin/AppShell/ActivePhaseContainer/RewardPanel/Margin/RewardBox/RewardBoardScroll/RewardBoard/RewardGrid/WorkspaceZone
@onready var reward_workspace_margin: MarginContainer = $RootMargin/AppShell/ActivePhaseContainer/RewardPanel/Margin/RewardBox/RewardBoardScroll/RewardBoard/RewardGrid/WorkspaceZone/Margin
@onready var reward_workspace_box: VBoxContainer = $RootMargin/AppShell/ActivePhaseContainer/RewardPanel/Margin/RewardBox/RewardBoardScroll/RewardBoard/RewardGrid/WorkspaceZone/Margin/ZoneBox
@onready var reward_workspace_head: VBoxContainer = $RootMargin/AppShell/ActivePhaseContainer/RewardPanel/Margin/RewardBox/RewardBoardScroll/RewardBoard/RewardGrid/WorkspaceZone/Margin/ZoneBox/ZoneHead
@onready var reward_workspace_title: Label = $RootMargin/AppShell/ActivePhaseContainer/RewardPanel/Margin/RewardBox/RewardBoardScroll/RewardBoard/RewardGrid/WorkspaceZone/Margin/ZoneBox/ZoneHead/ZoneTitle
@onready var reward_inspector_zone: PanelContainer = $RootMargin/AppShell/ActivePhaseContainer/RewardPanel/Margin/RewardBox/RewardBoardScroll/RewardBoard/RewardGrid/InspectorZone
@onready var reward_bottom_row: HBoxContainer = $RootMargin/AppShell/ActivePhaseContainer/RewardPanel/Margin/RewardBox/RewardBoardScroll/RewardBoard/BottomRow
@onready var reward_title: Label = $RootMargin/AppShell/ActivePhaseContainer/RewardPanel/Margin/RewardBox/BoardHead/BoardTitleBox/RewardTitle
@onready var reward_subtitle: Label = $RootMargin/AppShell/ActivePhaseContainer/RewardPanel/Margin/RewardBox/BoardHead/BoardTitleBox/RewardSubtitle
@onready var reward_mode_pill: Label = $RootMargin/AppShell/ActivePhaseContainer/RewardPanel/Margin/RewardBox/BoardHead/ModePill
@onready var reward_card_grid: Control = $RootMargin/AppShell/ActivePhaseContainer/RewardPanel/Margin/RewardBox/RewardBoardScroll/RewardBoard/RewardGrid/RewardsZone/Margin/ZoneBox/RewardCloudBox/CloudMargin/CloudVBox/RewardCardGrid
@onready var reward_cloud_content: VBoxContainer = $RootMargin/AppShell/ActivePhaseContainer/RewardPanel/Margin/RewardBox/RewardBoardScroll/RewardBoard/RewardGrid/RewardsZone/Margin/ZoneBox/RewardCloudBox/CloudMargin/CloudVBox
@onready var reward_cloud_box: PanelContainer = $RootMargin/AppShell/ActivePhaseContainer/RewardPanel/Margin/RewardBox/RewardBoardScroll/RewardBoard/RewardGrid/RewardsZone/Margin/ZoneBox/RewardCloudBox
@onready var reward_cloud_note: Label = $RootMargin/AppShell/ActivePhaseContainer/RewardPanel/Margin/RewardBox/RewardBoardScroll/RewardBoard/RewardGrid/RewardsZone/Margin/ZoneBox/RewardCloudBox/CloudMargin/CloudVBox/CloudNote
@onready var reward_workspace_note: RichTextLabel = $RootMargin/AppShell/ActivePhaseContainer/RewardPanel/Margin/RewardBox/RewardBoardScroll/RewardBoard/RewardGrid/WorkspaceZone/Margin/ZoneBox/WorkspaceNote
@onready var reward_backpack_host: Control = $RootMargin/AppShell/ActivePhaseContainer/RewardPanel/Margin/RewardBox/RewardBoardScroll/RewardBoard/RewardGrid/WorkspaceZone/Margin/ZoneBox/BackpackHost
@onready var reward_inspector_kicker: Label = $RootMargin/AppShell/ActivePhaseContainer/RewardPanel/Margin/RewardBox/RewardBoardScroll/RewardBoard/RewardGrid/InspectorZone/Margin/ZoneBox/InspectorStage/InspectorKicker
@onready var reward_inspector_name: Label = $RootMargin/AppShell/ActivePhaseContainer/RewardPanel/Margin/RewardBox/RewardBoardScroll/RewardBoard/RewardGrid/InspectorZone/Margin/ZoneBox/InspectorStage/InspectorName
@onready var reward_inspector_summary: RichTextLabel = $RootMargin/AppShell/ActivePhaseContainer/RewardPanel/Margin/RewardBox/RewardBoardScroll/RewardBoard/RewardGrid/InspectorZone/Margin/ZoneBox/InspectorStage/InspectorSummary
@onready var reward_inspector_facts: GridContainer = $RootMargin/AppShell/ActivePhaseContainer/RewardPanel/Margin/RewardBox/RewardBoardScroll/RewardBoard/RewardGrid/InspectorZone/Margin/ZoneBox/InspectorStage/InspectorFacts
@onready var reward_inspector_stage: VBoxContainer = $RootMargin/AppShell/ActivePhaseContainer/RewardPanel/Margin/RewardBox/RewardBoardScroll/RewardBoard/RewardGrid/InspectorZone/Margin/ZoneBox/InspectorStage
@onready var reward_footprint_title: Label = $RootMargin/AppShell/ActivePhaseContainer/RewardPanel/Margin/RewardBox/RewardBoardScroll/RewardBoard/RewardGrid/InspectorZone/Margin/ZoneBox/InspectorStage/FootprintCard/Margin/FootprintBox/FootprintTitle
@onready var reward_footprint_info: Label = $RootMargin/AppShell/ActivePhaseContainer/RewardPanel/Margin/RewardBox/RewardBoardScroll/RewardBoard/RewardGrid/InspectorZone/Margin/ZoneBox/InspectorStage/FootprintCard/Margin/FootprintBox/FootprintInfo
@onready var reward_footprint_grid: GridContainer = $RootMargin/AppShell/ActivePhaseContainer/RewardPanel/Margin/RewardBox/RewardBoardScroll/RewardBoard/RewardGrid/InspectorZone/Margin/ZoneBox/InspectorStage/FootprintCard/Margin/FootprintBox/FootprintGrid
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
@onready var discard_zone: PanelContainer = $RootMargin/AppShell/ActivePhaseContainer/RewardPanel/Margin/RewardBox/RewardBoardScroll/RewardBoard/BottomRow/DiscardZone
@onready var confirm_zone: PanelContainer = $RootMargin/AppShell/ActivePhaseContainer/RewardPanel/Margin/RewardBox/RewardBoardScroll/RewardBoard/BottomRow/ConfirmZone
@onready var discard_card: PanelContainer = $RootMargin/AppShell/ActivePhaseContainer/RewardPanel/Margin/RewardBox/RewardBoardScroll/RewardBoard/BottomRow/DiscardZone/Margin/ZoneBox/DiscardCard
@onready var claim_card: PanelContainer = $RootMargin/AppShell/ActivePhaseContainer/RewardPanel/Margin/RewardBox/RewardBoardScroll/RewardBoard/BottomRow/ConfirmZone/Margin/ZoneBox/ClaimCard
@onready var discard_label: Label = $RootMargin/AppShell/ActivePhaseContainer/RewardPanel/Margin/RewardBox/RewardBoardScroll/RewardBoard/BottomRow/DiscardZone/Margin/ZoneBox/DiscardCard/Margin/DiscardCardBox/DiscardLabel
@onready var claim_card_body: Label = $RootMargin/AppShell/ActivePhaseContainer/RewardPanel/Margin/RewardBox/RewardBoardScroll/RewardBoard/BottomRow/ConfirmZone/Margin/ZoneBox/ClaimCard/Margin/ClaimCardBox/ClaimCardBody
@onready var claim_inline_button: Button = $RootMargin/AppShell/ActivePhaseContainer/RewardPanel/Margin/RewardBox/RewardBoardScroll/RewardBoard/BottomRow/ConfirmZone/Margin/ZoneBox/ClaimCard/Margin/ClaimCardBox/ClaimInlineButton

# Shop UI Dynamic nodes
var shop_open_button: Button
var shop_panel: PanelContainer
var shop_gold_label: Label
var shop_xp_label: Label
var shop_buttons: Dictionary = {}
var shop_labels: Dictionary = {}
var current_shop_state: Dictionary = {}
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
var node_map_scene: NodeMapScene = null
var node_select_content_row: HBoxContainer = null
var node_select_runtime_page: Control = null
var node_select_map_host: Control = null
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
var _node_map_layout_refresh_pending := false
var _node_map_followup_refresh_requested := false
var _view_layout_ready := false
var _viewport_shell_sync_pending := false
var _last_viewport_shell_size := Vector2.ZERO
var battle_pause_active := false
var _last_combat_pause_overlay_visible := false
var _last_rendered_scene: Dictionary = {}
var page_shell_host: Control
var meta_page_shell_host: Control
var page_scenes: Dictionary = {}
var active_page_id := ""
var character_select_page: Control
var leviathan_select_page: Control
var reward_cloud_scroll: ScrollContainer = null
var discard_card_scroll: ScrollContainer = null
var claim_card_scroll: ScrollContainer = null
var reward_inspector_scroll: ScrollContainer = null

static func node_select_backpack_width_for_row(row_size: Vector2, map_min_width: float) -> float:
	return BackpackPinLayoutPolicyScript.node_select_width_for_row(row_size, map_min_width)

static func top_content_backpack_horizontal_flags() -> int:
	return Control.SIZE_SHRINK_CENTER

static func top_content_side_horizontal_flags() -> int:
	return Control.SIZE_EXPAND_FILL

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
	_install_reward_zone_scroll_shells()
	_install_reward_inspector_scroll_shell()
	_apply_shared_split_layout_text_policies()
	reset_button.pressed.connect(func(): reset_pressed.emit())
	start_button.pressed.connect(func(): call_deferred("_emit_start_combat_pressed"))
	hold_fire_button.pressed.connect(func(): hold_fire_pressed.emit())
	repair_button.pressed.connect(func(): repair_pressed.emit())
	repair_button.visible = false # R button disabled/hidden since repair is automatic now
	claim_rewards_button.pressed.connect(func(): claim_rewards_pressed.emit())
	claim_inline_button.pressed.connect(func(): claim_rewards_pressed.emit())
	settings_open_button.pressed.connect(func(): settings_open_pressed.emit())
	confirm_proceed_button.pressed.connect(func(): confirm_proceed_pressed.emit())
	confirm_cancel_button.pressed.connect(func(): confirm_cancel_pressed.emit())
	discard_zone.gui_input.connect(func(ev): discard_zone_input.emit(ev))
	_set_descendant_mouse_filter_ignore(discard_zone)
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
	backpack_ui.slot_clicked.connect(func(coord): backpack_slot_clicked.emit(coord))
	backpack_ui.slot_hovered.connect(func(coord): backpack_slot_hovered.emit(coord))
	backpack_ui.slot_unhovered.connect(func(coord): backpack_slot_unhovered.emit(coord))
	backpack_ui.slot_drag_started.connect(func(coord):
		_begin_backpack_drag_tracking(coord)
		backpack_slot_drag_started.emit(coord)
	)
	battlefield_ui.cell_hovered.connect(func(cid, col): cell_hovered.emit(cid, col))
	battlefield_ui.cell_clicked.connect(func(cid, col): cell_clicked.emit(cid, col))
	battlefield_ui.cell_pressed.connect(func(cid, col): cell_pressed.emit(cid, col))
	battlefield_ui.cell_released.connect(func(): cell_released.emit())
	resized.connect(_queue_shared_backpack_layout_sync)
	top_content.resized.connect(_queue_shared_backpack_layout_sync)
	active_phase_container.resized.connect(_queue_shared_backpack_layout_sync)
	reward_grid.resized.connect(_queue_reward_board_layout_sync)
	reward_backpack_host.resized.connect(_queue_reward_board_layout_sync)
	reward_bottom_row.resized.connect(_queue_reward_board_layout_sync)
	discard_zone.resized.connect(_queue_reward_board_layout_sync)
	confirm_zone.resized.connect(_queue_reward_board_layout_sync)
	reward_card_grid.resized.connect(_queue_reward_card_float_layout)
	resized.connect(_queue_node_map_layout_refresh)
	active_phase_container.resized.connect(_queue_node_map_layout_refresh)

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
	_create_page_scenes()
	_install_character_presentation()
	_install_reward_backdrop()
	_install_failure_backdrop()
	backpack_original_parent = backpack_container.get_parent()
	backpack_original_index = backpack_container.get_index()

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
	_queue_node_map_layout_refresh()
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
	backpack_ui.setup_grid_slots()

# ??쎈뻬: render backpack items using model data.
func render_backpack(inventory) -> void:
	backpack_ui.render_backpack_items(inventory)

# ??쎈뻬: update ghost item display.
func update_backpack_ghost(artifact) -> void:
	backpack_ui.update_ghost_display(artifact)

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
	if battlefield_ui != null and battlefield_ui.has_method("set_battle_pause_active"):
		battlefield_ui.set_battle_pause_active(active)
	if backpack_ui != null and backpack_ui.has_method("set_battle_pause_active"):
		backpack_ui.set_battle_pause_active(active)
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
		backpack_container.custom_minimum_size = Vector2.ZERO
		backpack_container.ratio = 1.0
	active_phase_container.size_flags_stretch_ratio = float(layout.get("activePhaseStretchRatio", 1.0))
	if node_map_scene != null:
		node_map_scene.visible = bool(layout.get("nodeSelectVisible", false))
	battlefield_ui.visible = bool(layout.get("battlefieldVisible", false))
	$RootMargin/AppShell/ActivePhaseContainer/RewardPanel.visible = bool(layout.get("rewardVisible", false))
	_apply_reward_backpack_dock(reward_backpack_dock)
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
	if bool(layout.get("nodeSelectVisible", false)) and node_map_scene != null:
		var node_map_model: Dictionary = NodeMapReadModelScript.project(scene, int(scene.get("selectedNodeIndex", 0)))
		node_map_model["allowStartColorSelection"] = bool(layout.get("allowStartColorSelection", node_map_model.get("allowStartColorSelection", true)))
		node_map_scene.render(node_map_model)
		_queue_shared_backpack_layout_sync()
		_node_map_followup_refresh_requested = true
		_queue_node_map_layout_refresh()
	status_panel.render_target_bars(scene)
	status_panel.render_extractor_label(scene)
	status_panel.render_hud_projection(hud_model)
	status_panel.render_combat_timer(str(layout.get("timerText", "00:00")), bool(layout.get("combatTimeActive", false)))
	status_panel.render_repair_overlay(scene, repair_overlay, overlay_model)
	_render_failure_backdrop(scene)
	_render_character_status(scene)
	_render_reward_backdrop(show_victory_overlay or str(scene.get("phase", "")) == "reward_loot")
	_render_page_scene(scene)
	_defer_interaction_fx_install()
	_queue_shared_backpack_layout_sync()

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
	log_console.add_log(message)

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
	_clear_dynamic_children(reward_card_grid)
	reward_card_buttons.clear()
	for card in cards:
		if not (card is Dictionary):
			continue
		var button := Button.new()
		button.text = ""
		button.clip_contents = false
		button.custom_minimum_size = Vector2(122, 122)
		button.focus_mode = Control.FOCUS_NONE
		button.action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
		button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		button.set_meta(InteractionFXScript.META_SKIP, true)
		var rarity := str(card.get("rarity", "common"))
		var selected := bool(card.get("selected", false))
		var normal := LTLThemeScript.surface_style(Color(0.22, 0.28, 0.36, 0.98), _reward_rarity_border_color(rarity), 24, 1, 0.30)
		if selected:
			normal.border_width_left = 2
			normal.border_width_top = 2
			normal.border_width_right = 2
			normal.border_width_bottom = 2
			normal.bg_color = Color(0.24, 0.20, 0.11, 0.98)
		var hover = normal.duplicate()
		var pressed = normal.duplicate()
		button.add_theme_stylebox_override("normal", normal)
		button.add_theme_stylebox_override("hover", hover)
		button.add_theme_stylebox_override("pressed", pressed)
		button.add_theme_stylebox_override("focus", hover)
		var index := int(card.get("index", -1))
		button.set_meta("reward_card_index", index)
		_wire_reward_card_interactions(button, index)
		button.pivot_offset = button.custom_minimum_size * 0.5
		var margin := MarginContainer.new()
		margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
		margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		margin.add_theme_constant_override("margin_left", 12)
		margin.add_theme_constant_override("margin_top", 12)
		margin.add_theme_constant_override("margin_right", 12)
		margin.add_theme_constant_override("margin_bottom", 12)
		button.add_child(margin)
		var body := VBoxContainer.new()
		body.mouse_filter = Control.MOUSE_FILTER_IGNORE
		body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		body.size_flags_vertical = Control.SIZE_EXPAND_FILL
		body.alignment = BoxContainer.ALIGNMENT_CENTER
		body.add_theme_constant_override("separation", 8)
		margin.add_child(body)
		var icon_shell := PanelContainer.new()
		icon_shell.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon_shell.custom_minimum_size = Vector2(0, 62)
		icon_shell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		icon_shell.add_theme_stylebox_override("panel", LTLThemeScript.surface_style(Color(0.29, 0.34, 0.41, 0.92), Color(0.44, 0.50, 0.58, 1.0), 18, 1, 0.12))
		body.add_child(icon_shell)
		var icon_center := CenterContainer.new()
		icon_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon_shell.add_child(icon_center)
		var icon_texture := TextureRect.new()
		icon_texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon_texture.custom_minimum_size = Vector2(42, 42)
		icon_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		var art: Dictionary = card.get("art", {})
		icon_texture.texture = LTLThemeScript.art_texture(str(art.get("path", "")))
		if icon_texture.texture == null:
			icon_texture.self_modulate = _reward_rarity_border_color(rarity)
		icon_center.add_child(icon_texture)
		var name_label := Label.new()
		name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		name_label.text = str(card.get("name", ""))
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		name_label.add_theme_font_size_override("font_size", 11)
		name_label.add_theme_color_override("font_color", LTLThemeScript.TEXT_PRIMARY)
		body.add_child(name_label)
		reward_card_grid.add_child(button)
		reward_card_buttons.append(button)
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
	var usable := Vector2(
		maxf(0.0, cloud_size.x - card_size.x - REWARD_CARD_FLOAT_EDGE_PADDING * 2.0),
		maxf(0.0, cloud_size.y - card_size.y - REWARD_CARD_FLOAT_EDGE_PADDING * 2.0)
	)
	return Rect2(Vector2(REWARD_CARD_FLOAT_EDGE_PADDING, REWARD_CARD_FLOAT_EDGE_PADDING), usable)

func clamp_reward_card_anchor(cloud_size: Vector2, card_size: Vector2, anchor: Vector2) -> Vector2:
	var bounds := reward_card_anchor_bounds(cloud_size, card_size)
	return Vector2(
		clampf(anchor.x, bounds.position.x, bounds.position.x + bounds.size.x),
		clampf(anchor.y, bounds.position.y, bounds.position.y + bounds.size.y)
	)

func _reward_card_anchor_from_norm(cloud_size: Vector2, card_size: Vector2, normalized: Vector2) -> Vector2:
	var bounds := reward_card_anchor_bounds(cloud_size, card_size)
	var safe_norm := Vector2(clampf(normalized.x, 0.0, 1.0), clampf(normalized.y, 0.0, 1.0))
	return bounds.position + Vector2(bounds.size.x * safe_norm.x, bounds.size.y * safe_norm.y)

func _reward_card_anchor_to_norm(cloud_size: Vector2, card_size: Vector2, anchor: Vector2) -> Vector2:
	var bounds := reward_card_anchor_bounds(cloud_size, card_size)
	var clamped := clamp_reward_card_anchor(cloud_size, card_size, anchor)
	return Vector2(
		0.0 if bounds.size.x <= 0.0 else (clamped.x - bounds.position.x) / bounds.size.x,
		0.0 if bounds.size.y <= 0.0 else (clamped.y - bounds.position.y) / bounds.size.y
	)

func _prune_reward_card_manual_anchors(cards: Array) -> void:
	var active_indices: Dictionary = {}
	for card in cards:
		if card is Dictionary:
			active_indices[int(card.get("index", -1))] = true
	for key in _reward_card_manual_anchor_norms.keys():
		var index := int(key)
		if not active_indices.has(index):
			_reward_card_manual_anchor_norms.erase(key)

func _layout_reward_float_cards() -> void:
	if reward_card_grid == null or reward_card_buttons.is_empty():
		return
	var cloud_size := reward_card_grid.size
	if cloud_size.x <= 1.0 or cloud_size.y <= 1.0:
		cloud_size = reward_card_grid.custom_minimum_size
	var card_edge := clampf(minf(cloud_size.x * 0.27, cloud_size.y * 0.34), 98.0, 132.0)
	var card_size := Vector2(card_edge, card_edge)
	var usable := Vector2(maxf(0.0, cloud_size.x - card_size.x - 18.0), maxf(0.0, cloud_size.y - card_size.y - 18.0))
	var seeded_positions := [
		Vector2(0.06, 0.08),
		Vector2(0.56, 0.12),
		Vector2(0.22, 0.34),
		Vector2(0.68, 0.42),
		Vector2(0.10, 0.62),
		Vector2(0.48, 0.68),
		Vector2(0.74, 0.62)
	]
	var placement_rects: Array[Rect2] = []
	var rng := RandomNumberGenerator.new()
	rng.seed = int(cloud_size.x * 1003.0 + cloud_size.y * 917.0 + reward_card_buttons.size() * 67.0)
	for index in range(reward_card_buttons.size()):
		var button := reward_card_buttons[index] as Control
		if button == null:
			continue
		var card_index := int(button.get_meta("reward_card_index", index))
		button.size = card_size
		button.pivot_offset = card_size * 0.5
		var manual_norm: Variant = _reward_card_manual_anchor_norms.get(card_index, null)
		var anchor := Vector2.ZERO
		var placed := false
		if manual_norm is Vector2:
			anchor = _reward_card_anchor_from_norm(cloud_size, card_size, manual_norm)
			placement_rects.append(Rect2(anchor, card_size).grow(6.0))
			placed = true
		else:
			for attempt in range(18):
				var norm: Vector2 = seeded_positions[(index + attempt) % seeded_positions.size()]
				if attempt >= seeded_positions.size():
					norm = Vector2(rng.randf_range(0.04, 0.78), rng.randf_range(0.06, 0.72))
				var candidate := Vector2(
					REWARD_CARD_FLOAT_EDGE_PADDING + usable.x * norm.x,
					REWARD_CARD_FLOAT_EDGE_PADDING + usable.y * norm.y
				)
				var candidate_rect := Rect2(candidate, card_size).grow(10.0)
				var collides := false
				for used_rect in placement_rects:
					if used_rect.intersects(candidate_rect):
						collides = true
						break
				if collides:
					continue
				anchor = candidate
				placement_rects.append(candidate_rect)
				placed = true
				break
		if not placed:
			anchor = clamp_reward_card_anchor(
				cloud_size,
				card_size,
				Vector2(
					REWARD_CARD_FLOAT_EDGE_PADDING + usable.x * float(index % 3) / maxf(1.0, minf(2.0, float(reward_card_buttons.size() - 1))),
					REWARD_CARD_FLOAT_EDGE_PADDING + usable.y * float(index / 3) / maxf(1.0, ceil(float(reward_card_buttons.size()) / 3.0) - 1.0)
				)
			)
			placement_rects.append(Rect2(anchor, card_size).grow(6.0))
		var float_phase := rng.randf_range(0.0, TAU)
		var float_speed := rng.randf_range(0.72, 1.14)
		var float_amplitude := Vector2(rng.randf_range(2.0, 5.0), rng.randf_range(4.0, 8.0))
		var base_rotation := rng.randf_range(-5.0, 5.0)
		button.set_meta("float_anchor", anchor)
		button.set_meta("float_phase", float_phase)
		button.set_meta("float_speed", float_speed)
		button.set_meta("float_amplitude", float_amplitude)
		button.set_meta("float_rotation", base_rotation)
		_apply_reward_card_idle_transform(button)

func _apply_reward_card_idle_transform(button: Control) -> void:
	if button == null:
		return
	if _reward_drag_active and button == _reward_drag_button:
		return
	var anchor: Vector2 = button.get_meta("float_anchor", button.position)
	var phase := float(button.get_meta("float_phase", 0.0))
	var speed := float(button.get_meta("float_speed", 1.0))
	var amplitude: Vector2 = button.get_meta("float_amplitude", Vector2(3.0, 6.0))
	var base_rotation := float(button.get_meta("float_rotation", 0.0))
	var offset := Vector2(
		sin(pulse_time * speed + phase) * amplitude.x,
		cos(pulse_time * speed * 0.82 + phase) * amplitude.y
	)
	button.position = anchor + offset
	button.rotation_degrees = base_rotation + sin(pulse_time * speed * 0.66 + phase) * 1.8

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
	if reward_card_grid == null or _reward_drag_button == null or not is_instance_valid(_reward_drag_button):
		return
	var local_mouse := get_global_mouse_position() - reward_card_grid.global_position
	var anchor := clamp_reward_card_anchor(
		reward_card_grid.size,
		_reward_drag_button.size,
		local_mouse - _reward_drag_pointer_offset
	)
	_reward_drag_button.position = anchor
	_reward_drag_button.rotation_degrees = 0.0

func _commit_reward_card_manual_anchor(index: int) -> void:
	if reward_card_grid == null or _reward_drag_button == null or not is_instance_valid(_reward_drag_button):
		return
	var anchor := clamp_reward_card_anchor(reward_card_grid.size, _reward_drag_button.size, _reward_drag_button.position)
	_reward_drag_button.position = anchor
	_reward_card_manual_anchor_norms[index] = _reward_card_anchor_to_norm(reward_card_grid.size, _reward_drag_button.size, anchor)

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

func _reward_rarity_border_color(rarity: String) -> Color:
	match rarity:
		"rare":
			return Color(0.39, 0.69, 0.95, 1.0)
		"epic":
			return Color(0.77, 0.47, 0.92, 1.0)
		"legendary":
			return Color(0.93, 0.78, 0.41, 1.0)
		"mythic":
			return Color(0.90, 0.58, 0.34, 1.0)
	return Color(0.56, 0.77, 0.54, 1.0)

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
	_set_label_text("RootMargin/AppShell/TopContent/LeftColumn/LeftSidebar/Margin/CharacterBox/CharacterTitle", TextCatalogScript.t("panel.character_status"))
	_set_label_text("RootMargin/AppShell/TopContent/LeftColumn/LeftSidebar/Margin/CharacterBox/PortraitPlaceholder/PortraitLabel", TextCatalogScript.t("panel.profile"))
	_set_rich_text("RootMargin/AppShell/TopContent/LeftColumn/LeftSidebar/Margin/CharacterBox/InventorySummaryLabel", TextCatalogScript.t("panel.loadout"))
	_set_label_text("RootMargin/AppShell/TopContent/LeftColumn/StatusPanel/Margin/StatusBox/StatusTitle", TextCatalogScript.t("panel.drill_node_status"))
	_set_label_text("RootMargin/AppShell/TopContent/LeftColumn/StatusPanel/Margin/StatusBox/HPBox/HealthLabel", TextCatalogScript.t("panel.health"))
	_set_label_text("RootMargin/AppShell/TopContent/LeftColumn/StatusPanel/Margin/StatusBox/ShieldBox/ShieldLabel", TextCatalogScript.t("panel.shield"))
	_set_label_text("RootMargin/AppShell/TopContent/LeftColumn/StatusPanel/Margin/StatusBox/QueueRow/QueueLabel", TextCatalogScript.t("panel.queue"))
	_set_label_text("RootMargin/AppShell/TopContent/LeftColumn/StatusPanel/Margin/StatusBox/TimerRow/PinLabel", TextCatalogScript.t("panel.stage_timer"))
	_set_label_text("RootMargin/AppShell/TopContent/LeftColumn/StatusPanel/Margin/StatusBox/DrillStatusRow/DrillStatusLabel", TextCatalogScript.t("panel.drill_status"))
	_set_label_text("RootMargin/AppShell/TopContent/LeftColumn/StatusPanel/Margin/StatusBox/StatusFooterSpacer/PurpleStatusRow/PurpleStatusLabel", TextCatalogScript.t("panel.purple_status"))
	_set_label_text("RootMargin/AppShell/TopContent/BackpackContainer/BackpackEnginePanel/Margin/EngineBox/EngineTitle", TextCatalogScript.t("panel.backpack"))
	_set_label_text("RootMargin/AppShell/TopContent/RightSidebar/Margin/InspectorBox/InspectorTitle", TextCatalogScript.t("panel.log"))
	_set_label_text("RootMargin/AppShell/ActivePhaseContainer/BattlefieldPanel/Margin/BattlefieldBox/BattlefieldTitle", "")
	_set_label_text("RootMargin/AppShell/ActivePhaseContainer/RewardPanel/Margin/RewardBox/BoardHead/BoardTitleBox/RewardTitle", TextCatalogScript.t("panel.rewards"))
	_set_label_text("RootMargin/AppShell/ActivePhaseContainer/RewardPanel/Margin/RewardBox/BoardHead/BoardTitleBox/RewardSubtitle", TextCatalogScript.t("reward.board.subtitle"))
	_set_optional_label_text("RootMargin/AppShell/ActivePhaseContainer/RewardPanel/Margin/RewardBox/BoardHead/ModePill", TextCatalogScript.t("reward.board.mode_pill"))
	_set_label_text("RootMargin/AppShell/ActivePhaseContainer/RewardPanel/Margin/RewardBox/RewardBoardScroll/RewardBoard/RewardGrid/RewardsZone/Margin/ZoneBox/ZoneHead/ZoneTitle", TextCatalogScript.t("reward.board.rewards_zone.title"))
	_set_optional_label_text("RootMargin/AppShell/ActivePhaseContainer/RewardPanel/Margin/RewardBox/RewardBoardScroll/RewardBoard/RewardGrid/RewardsZone/Margin/ZoneBox/ZoneHead/ZoneHint", TextCatalogScript.t("reward.board.rewards_zone.hint"))
	_set_label_text("RootMargin/AppShell/ActivePhaseContainer/RewardPanel/Margin/RewardBox/RewardBoardScroll/RewardBoard/RewardGrid/WorkspaceZone/Margin/ZoneBox/ZoneHead/ZoneTitle", TextCatalogScript.t("panel.backpack"))
	_set_label_text("RootMargin/AppShell/ActivePhaseContainer/RewardPanel/Margin/RewardBox/RewardBoardScroll/RewardBoard/RewardGrid/WorkspaceZone/Margin/ZoneBox/ZoneHead/ZoneHint", TextCatalogScript.t("reward.board.workspace_zone.hint"))
	_set_label_text("RootMargin/AppShell/ActivePhaseContainer/RewardPanel/Margin/RewardBox/RewardBoardScroll/RewardBoard/RewardGrid/InspectorZone/Margin/ZoneBox/ZoneHead/ZoneTitle", TextCatalogScript.t("reward.board.inspector_zone.title"))
	_set_label_text("RootMargin/AppShell/ActivePhaseContainer/RewardPanel/Margin/RewardBox/RewardBoardScroll/RewardBoard/RewardGrid/InspectorZone/Margin/ZoneBox/ZoneHead/ZoneHint", TextCatalogScript.t("reward.board.inspector_zone.hint"))
	_set_label_text("RootMargin/AppShell/ActivePhaseContainer/RewardPanel/Margin/RewardBox/RewardBoardScroll/RewardBoard/BottomRow/DiscardZone/Margin/ZoneBox/ZoneHead/ZoneTitle", TextCatalogScript.t("reward.board.discard_zone.title"))
	_set_optional_label_text("RootMargin/AppShell/ActivePhaseContainer/RewardPanel/Margin/RewardBox/RewardBoardScroll/RewardBoard/BottomRow/DiscardZone/Margin/ZoneBox/ZoneHead/ZoneHint", TextCatalogScript.t("reward.board.discard_zone.hint"))
	_set_optional_label_text("RootMargin/AppShell/ActivePhaseContainer/RewardPanel/Margin/RewardBox/RewardBoardScroll/RewardBoard/BottomRow/DiscardZone/Margin/ZoneBox/DiscardCardScroll/DiscardCard/Margin/DiscardCardBox/DiscardCardTitle", TextCatalogScript.t("reward.board.discard_card_title"))
	_set_label_text("RootMargin/AppShell/ActivePhaseContainer/RewardPanel/Margin/RewardBox/RewardBoardScroll/RewardBoard/BottomRow/ConfirmZone/Margin/ZoneBox/ZoneHead/ZoneTitle", TextCatalogScript.t("reward.board.confirm_zone.title"))
	_set_optional_label_text("RootMargin/AppShell/ActivePhaseContainer/RewardPanel/Margin/RewardBox/RewardBoardScroll/RewardBoard/BottomRow/ConfirmZone/Margin/ZoneBox/ZoneHead/ZoneHint", TextCatalogScript.t("reward.board.confirm_zone.hint"))
	_set_optional_label_text("RootMargin/AppShell/ActivePhaseContainer/RewardPanel/Margin/RewardBox/RewardBoardScroll/RewardBoard/BottomRow/ConfirmZone/Margin/ZoneBox/ClaimCardScroll/ClaimCard/Margin/ClaimCardBox/ClaimCardTitle", TextCatalogScript.t("reward.board.claim_card_title"))
	_set_rich_text("RootMargin/AppShell/ActivePhaseContainer/RewardPanel/Margin/RewardBox/RewardBoardScroll/RewardBoard/RewardGrid/WorkspaceZone/Margin/ZoneBox/WorkspaceNote", TextCatalogScript.t("reward.board.workspace_note"))
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
	claim_inline_button.text = TextCatalogScript.t("action.claim_rewards")
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
	if node != null:
		node.text = text

func _set_optional_label_text(path: String, text: String) -> void:
	var node := get_node_or_null(path) as Label
	if node != null:
		node.text = text
		node.visible = not text.strip_edges().is_empty()

# ?ㅽ뻾: set a RichTextLabel text by relative path when present.
func _set_rich_text(path: String, text: String) -> void:
	var node := get_node_or_null(path) as RichTextLabel
	if node != null:
		node.text = text

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
	if node_select_runtime_page != null and node_select_runtime_page.has_signal("start_color_selected"):
		node_select_runtime_page.connect("start_color_selected", func(color): loadout_color_selected.emit(color))
	for outcome_id in ["defeat", "clear"]:
		var outcome_page = page_scenes.get(outcome_id)
		if outcome_page != null and outcome_page.has_signal("return_requested"):
			outcome_page.return_requested.connect(func(): return_to_character_select_pressed.emit())

func _cache_node_select_runtime_hosts() -> void:
	if node_select_runtime_page == null:
		node_select_content_row = null
		node_select_map_host = null
		node_select_backpack_host = null
		return
	node_select_content_row = node_select_runtime_page.get_node_or_null("Margin/BoardShell/ShellMargin/ShellVBox/RouteSplit") as HBoxContainer
	node_select_map_host = node_select_runtime_page.get_node_or_null("Margin/BoardShell/ShellMargin/ShellVBox/RouteSplit/MapHost") as Control
	node_select_backpack_host = node_select_runtime_page.get_node_or_null("Margin/BoardShell/ShellMargin/ShellVBox/RouteSplit/BackpackHost") as Control
	if node_select_content_row != null:
		node_select_content_row.resized.connect(_queue_shared_backpack_layout_sync)
		node_select_content_row.resized.connect(_queue_node_map_layout_refresh)
	if node_select_backpack_host != null:
		node_select_backpack_host.resized.connect(_queue_shared_backpack_layout_sync)
		node_select_backpack_host.resized.connect(_queue_node_map_layout_refresh)

func _register_page_scene(page_id: String, page_scene: Node) -> void:
	PageSceneRegistryScript.register_page_scene(
		page_scenes,
		page_id,
		page_scene,
		page_shell_host,
		meta_page_shell_host,
		META_PAGE_IDS
	)

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
	if active_scene == null or not active_scene.has_method("apply_state"):
		return
	active_scene.apply_state(_page_scene_model(page_id, scene))

func _is_meta_page(page_id: String) -> bool:
	return PageSceneRegistryScript.is_meta_page(page_id, META_PAGE_IDS)

func _page_scene_model(page_id: String, scene: Dictionary) -> Dictionary:
	return PageSceneModelBuilderScript.project(page_id, scene, CHARACTER_PORTRAIT_PATH)

# ??쎈뻬: dynamically construct the full-page node-map selector inside the node-select panel.
func _create_node_map_scene() -> void:
	node_map_scene = NodeMapSceneScript.new()
	node_map_scene.name = "NodeMapPage"
	node_map_scene.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	node_map_scene.size_flags_vertical = Control.SIZE_EXPAND_FILL
	node_map_scene.custom_minimum_size = Vector2(NODE_SELECT_MAP_MIN_WIDTH, 360)
	node_map_scene.node_selected.connect(func(index): node_meta_clicked.emit(index))
	node_map_scene.color_selected.connect(func(color): loadout_color_selected.emit(color))
	node_map_scene.set("characterSpriteSheetPath", CHARACTER_SPRITE_SHEET_PATH)
	if node_select_map_host != null:
		node_select_map_host.add_child(node_map_scene)
	else:
		page_shell_host.add_child(node_map_scene)

func _install_character_presentation() -> void:
	if portrait_placeholder == null or portrait_art != null:
		return
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
	portrait_label.visible = false
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
	if reward_panel == null or reward_backdrop != null:
		return
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
		"RootMargin/AppShell/TopContent/LeftColumn/LeftSidebar/Margin/CharacterBox/InventorySummaryLabel",
		("[b]%s[/b]\n%s\n%s" % [
			TextCatalogScript.display_name(character_name),
			stage_label_text,
			TextCatalogScript.t("character.front_color", [TextCatalogScript.color_label(selected_color)])
		])
	)

# ?ㅽ뻾: place the backpack beside the node map only during node selection.
func _apply_node_select_backpack_dock(dock: String, map_ratio: float, backpack_ratio: float) -> void:
	if node_select_content_row == null or node_select_backpack_host == null or backpack_original_parent == null:
		return
	if dock == "right":
		if backpack_container.get_parent() != node_select_backpack_host:
			_schedule_backpack_reparent(node_select_backpack_host)
		if node_map_scene != null:
			node_map_scene.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			node_map_scene.size_flags_stretch_ratio = map_ratio
			node_map_scene.custom_minimum_size.x = NODE_SELECT_MAP_MIN_WIDTH
		if node_select_map_host != null:
			node_select_map_host.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			node_select_map_host.size_flags_stretch_ratio = map_ratio
		node_select_backpack_host.size_flags_horizontal = Control.SIZE_SHRINK_END
		node_select_backpack_host.size_flags_stretch_ratio = backpack_ratio
		node_select_backpack_host.custom_minimum_size = Vector2(_node_select_backpack_width(), 0.0)
		backpack_container.size_flags_stretch_ratio = backpack_ratio
		backpack_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		backpack_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
		backpack_container.custom_minimum_size = Vector2(_node_select_backpack_width(), 0)
	else:
		if backpack_container.get_parent() != backpack_original_parent:
			_schedule_backpack_reparent(backpack_original_parent, backpack_original_index)
		if node_select_backpack_host != null:
			node_select_backpack_host.custom_minimum_size = Vector2.ZERO
		backpack_container.size_flags_stretch_ratio = 0.0
		backpack_container.size_flags_horizontal = top_content_backpack_horizontal_flags()
		backpack_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
		backpack_container.custom_minimum_size = Vector2.ZERO

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
	if node_select_backpack_host == null or backpack_container.get_parent() != node_select_backpack_host:
		return
	node_select_backpack_host.custom_minimum_size = Vector2(_node_select_backpack_width(), 0.0)
	backpack_container.custom_minimum_size = Vector2(_node_select_backpack_width(), 0.0)
	backpack_container.ratio = 1.0
	backpack_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	backpack_container.size_flags_vertical = Control.SIZE_EXPAND_FILL

func _apply_reward_backpack_dock(dock_to_board: bool) -> void:
	if reward_backpack_host == null or backpack_original_parent == null:
		return
	_set_reward_workspace_title_state(dock_to_board)
	if dock_to_board:
		if backpack_container.get_parent() != reward_backpack_host:
			_schedule_backpack_reparent(reward_backpack_host)
		backpack_container.ratio = 1.0
		backpack_container.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		backpack_container.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		return
	if backpack_container.get_parent() == reward_backpack_host:
		_schedule_backpack_reparent(backpack_original_parent, backpack_original_index)

func _sync_reward_backpack_layout() -> void:
	if reward_backpack_host == null or backpack_container.get_parent() != reward_backpack_host:
		return
	var host_size := reward_backpack_host.size
	if host_size.x <= 1.0 or host_size.y <= 1.0:
		host_size = Vector2(active_phase_container.size.x * 0.40, active_phase_container.size.y * 0.82)
	var panel_dims := _reward_backpack_panel_dimensions_for_host(host_size)
	if panel_dims.x <= 1.0 or panel_dims.y <= 1.0:
		return
	_set_custom_minimum_size_if_changed(backpack_container, panel_dims)
	backpack_container.ratio = panel_dims.x / maxf(1.0, panel_dims.y)
	backpack_container.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	backpack_container.size_flags_vertical = Control.SIZE_SHRINK_CENTER

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
	var discard_body: Control = discard_card_scroll if discard_card_scroll != null else discard_card
	var discard_body_height := _reward_zone_body_target_height(discard_zone, discard_body, bottom_row_height, 72.0)
	var claim_body: Control = claim_card_scroll if claim_card_scroll != null else claim_card
	var claim_body_height := _reward_zone_body_target_height(confirm_zone, claim_body, bottom_row_height, 72.0)
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
	rewards_body_height = _reward_zone_body_target_height(reward_rewards_zone, rewards_body, top_zone_height, 220.0)
	workspace_body_height = _reward_zone_body_target_height(reward_workspace_zone, reward_backpack_host, top_zone_height, 220.0)
	inspector_body_height = _reward_zone_body_target_height(reward_inspector_zone, inspector_body, top_zone_height, 220.0)
	discard_body_height = _reward_zone_body_target_height(discard_zone, discard_body, bottom_row_height, 72.0)
	claim_body_height = _reward_zone_body_target_height(confirm_zone, claim_body, bottom_row_height, 72.0)
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
	return resolved_top_content_backpack_height(top_content.size.y, min_row_height, backpack_container.size.y)

func _top_content_backpack_width() -> float:
	var target_height := _top_content_backpack_height()
	return top_content_backpack_width_for_height(target_height)

func _apply_top_content_backpack_bounds() -> void:
	var target_height := _top_content_backpack_height()
	var resolved_width := top_content_backpack_width_for_height(target_height)
	var safe_width_cap := _max_safe_top_content_backpack_width()
	if safe_width_cap > 0.0:
		resolved_width = minf(resolved_width, safe_width_cap)
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
	if backpack_container == null or backpack_container.get_parent() != backpack_original_parent:
		return
	if not top_content.visible:
		return
	_apply_top_content_backpack_bounds()
	backpack_container.size_flags_horizontal = top_content_backpack_horizontal_flags()
	backpack_container.size_flags_vertical = Control.SIZE_EXPAND_FILL

func _queue_shared_backpack_layout_sync() -> void:
	if backpack_container != null and backpack_container.get_parent() == reward_backpack_host:
		_queue_reward_board_layout_sync()
		return
	if _shared_backpack_layout_sync_pending:
		return
	_shared_backpack_layout_sync_pending = true
	call_deferred("_sync_shared_backpack_layout")

func _sync_shared_backpack_layout() -> void:
	_shared_backpack_layout_sync_pending = false
	if backpack_container == null:
		return
	if backpack_container.get_parent() == node_select_backpack_host:
		_sync_node_select_backpack_width()
		return
	if backpack_container.get_parent() == reward_backpack_host:
		return
	if backpack_container.get_parent() == backpack_original_parent:
		_sync_top_content_backpack_layout()

func _queue_node_map_layout_refresh() -> void:
	if _node_map_layout_refresh_pending:
		return
	_node_map_layout_refresh_pending = true
	call_deferred("_refresh_node_map_layout_after_frame")

func _refresh_node_map_layout_after_frame() -> void:
	await get_tree().process_frame
	_node_map_layout_refresh_pending = false
	if node_map_scene == null or not node_map_scene.visible:
		return
	_sync_shared_backpack_layout()
	node_map_scene.rerender_current_model()
	if _node_map_followup_refresh_requested:
		_node_map_followup_refresh_requested = false
		_queue_node_map_layout_refresh()

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
	status_panel.add_theme_stylebox_override("panel", surface)
	backpack_ui.add_theme_stylebox_override("panel", surface)
	right_sidebar.add_theme_stylebox_override("panel", surface)
	battlefield_ui.add_theme_stylebox_override("panel", surface)
	reward_panel.add_theme_stylebox_override("panel", LTLThemeScript.surface_style(Color(0.10, 0.11, 0.13, 0.98), LTLThemeScript.BORDER_WARM, 12))
	for zone_path in [
		"RootMargin/AppShell/ActivePhaseContainer/RewardPanel/Margin/RewardBox/RewardBoardScroll/RewardBoard/RewardGrid/RewardsZone",
		"RootMargin/AppShell/ActivePhaseContainer/RewardPanel/Margin/RewardBox/RewardBoardScroll/RewardBoard/RewardGrid/WorkspaceZone",
		"RootMargin/AppShell/ActivePhaseContainer/RewardPanel/Margin/RewardBox/RewardBoardScroll/RewardBoard/RewardGrid/InspectorZone",
		"RootMargin/AppShell/ActivePhaseContainer/RewardPanel/Margin/RewardBox/RewardBoardScroll/RewardBoard/RewardGrid/RewardsZone/Margin/ZoneBox/RewardCloudBox",
		"RootMargin/AppShell/ActivePhaseContainer/RewardPanel/Margin/RewardBox/RewardBoardScroll/RewardBoard/RewardGrid/InspectorZone/Margin/ZoneBox/InspectorStage/FootprintCard",
		"RootMargin/AppShell/ActivePhaseContainer/RewardPanel/Margin/RewardBox/RewardBoardScroll/RewardBoard/BottomRow/ConfirmZone"
	]:
		var zone = get_node_or_null(zone_path) as PanelContainer
		if zone != null:
			zone.add_theme_stylebox_override("panel", LTLThemeScript.surface_style(Color(0.11, 0.14, 0.18, 0.98), LTLThemeScript.BORDER_COLD, 18, 1, 0.18))
	var discard_shell = get_node_or_null("RootMargin/AppShell/ActivePhaseContainer/RewardPanel/Margin/RewardBox/RewardBoardScroll/RewardBoard/BottomRow/DiscardZone") as PanelContainer
	if discard_shell != null:
		discard_shell.add_theme_stylebox_override("panel", LTLThemeScript.surface_style(Color(0.14, 0.08, 0.09, 0.98), Color(0.68, 0.28, 0.28, 1.0), 18, 1, 0.20))
	var discard_card = get_node_or_null("RootMargin/AppShell/ActivePhaseContainer/RewardPanel/Margin/RewardBox/RewardBoardScroll/RewardBoard/BottomRow/DiscardZone/Margin/ZoneBox/DiscardCard") as PanelContainer
	if discard_card != null:
		discard_card.add_theme_stylebox_override("panel", LTLThemeScript.surface_style(Color(0.18, 0.09, 0.10, 0.98), Color(0.78, 0.34, 0.34, 1.0), 16, 1, 0.16))
	var claim_card = get_node_or_null("RootMargin/AppShell/ActivePhaseContainer/RewardPanel/Margin/RewardBox/RewardBoardScroll/RewardBoard/BottomRow/ConfirmZone/Margin/ZoneBox/ClaimCard") as PanelContainer
	if claim_card != null:
		claim_card.add_theme_stylebox_override("panel", LTLThemeScript.surface_style(Color(0.18, 0.15, 0.09, 0.98), LTLThemeScript.BORDER_WARM, 16, 1, 0.16))
	repair_overlay.add_theme_stylebox_override("panel", LTLThemeScript.overlay_style("warning"))
	for button in [settings_open_button, reset_button, start_button, hold_fire_button, repair_button, claim_rewards_button, claim_inline_button, shop_open_button, codex_open_button]:
		if button != null:
			_style_shell_button(button)

func _style_shell_button(button: Button) -> void:
	var normal := LTLThemeScript.surface_style(Color(0.13, 0.16, 0.20, 0.98), LTLThemeScript.BORDER_COLD, 10)
	var hover := normal.duplicate()
	hover.bg_color = Color(0.16, 0.20, 0.25, 1.0)
	hover.border_color = Color(0.50, 0.67, 0.76, 1.0)
	var pressed := normal.duplicate()
	pressed.bg_color = Color(0.11, 0.14, 0.18, 1.0)
	pressed.border_color = LTLThemeScript.BORDER_WARM
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("focus", hover)
	button.add_theme_font_size_override("font_size", 14)
	button.add_theme_color_override("font_color", LTLThemeScript.TEXT_PRIMARY)
	normal.content_margin_left = 16
	normal.content_margin_right = 16
	hover.content_margin_left = 16
	hover.content_margin_right = 16
	pressed.content_margin_left = 16
	pressed.content_margin_right = 16
	button.custom_minimum_size.x = maxf(button.custom_minimum_size.x, _shell_button_min_width(button))
	button.custom_minimum_size.y = maxf(button.custom_minimum_size.y, 32.0)

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

# ?ㅽ뻾: dynamically construct the central giant timer panel.
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
	var target_parent := _pending_backpack_parent
	if backpack_container == null or _pending_backpack_parent == null:
		return
	if backpack_container.get_parent() != _pending_backpack_parent:
		var current_parent := backpack_container.get_parent()
		if current_parent != null:
			current_parent.remove_child(backpack_container)
		_pending_backpack_parent.add_child(backpack_container)
	if _pending_backpack_parent == backpack_original_parent and _pending_backpack_parent_index >= 0:
		backpack_original_parent.move_child(backpack_container, _pending_backpack_parent_index)
	_pending_backpack_parent = null
	_pending_backpack_parent_index = -1
	_queue_shared_backpack_layout_sync()
	if target_parent == reward_backpack_host:
		_queue_reward_board_layout_sync()
	if target_parent == node_select_backpack_host:
		_node_map_followup_refresh_requested = true
		_queue_node_map_layout_refresh()
	_flush_pending_backpack_pin_scene()

func _flush_pending_backpack_pin_scene() -> void:
	if _backpack_reparent_pending:
		return
	if backpack_ui == null or not backpack_ui.has_method("update_pin_overlays"):
		return
	if _pending_backpack_pin_scene.is_empty():
		return
	backpack_ui.update_pin_overlays(_pending_backpack_pin_scene)
	_pending_backpack_pin_scene = {}
