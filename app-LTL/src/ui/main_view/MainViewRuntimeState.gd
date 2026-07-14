class_name MainViewRuntimeState
extends PanelContainer

const META_PAGE_IDS := ["character_select", "leviathan_select", "story_scene", "clear", "defeat"]
const SURFACE_PAGE_IDS := ["battle", "boss_battle", "reward", "boss_reward"]
const ACTION_BAR_PAGE_IDS := ["node_select", "battle", "boss_battle", "reward", "boss_reward"]
const SHOP_ENABLED := false
const POPUP_OVERLAY_Z_INDEX := 500
const REWARD_REVEAL_OVERLAY_Z_INDEX := 600

signal reset_pressed
signal start_combat_pressed
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
signal retry_same_seed_pressed
signal retry_new_seed_pressed
signal story_continue_requested(scene_id: String)
signal story_skip_requested(scene_id: String)
signal shop_open_pressed
signal codex_open_pressed
signal buy_passive(passive_id: String, cost: int)
signal buy_base_item(item_id: String)
signal narrative_continue_requested(beat_id: String)

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
@onready var confirm_proceed_button: Button = $ConfirmOverlay/Center/ConfirmBox/CardMargin/CardBody/ButtonsRow/ConfirmButton
@onready var confirm_cancel_button: Button = $ConfirmOverlay/Center/ConfirmBox/CardMargin/CardBody/ButtonsRow/CancelButton
@onready var settings_panel = $SettingsPanel
@onready var vfx_manager = $VFXManager

var top_content: HBoxContainer
var left_column: VBoxContainer
var portrait_placeholder: Panel
var portrait_label: Label
var backpack_container: AspectRatioContainer
var backpack_host: Control
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
var claim_rewards_button: Button
var action_bar: HBoxContainer
var backpack_ui
var battlefield_ui
var status_panel
var log_console
var discard_zone: PanelContainer
var confirm_zone: PanelContainer
var discard_card: PanelContainer
var claim_card: Control
var discard_label: Label
var claim_card_body: Label
var claim_inline_button: Button
var info_toast_panel: Panel = null
var info_toast_label: Label = null
var info_toast_hint_label: Label = null
# 실행: 토스트 리디자인 — 원형 아이콘 배지와 자동 소멸 진행 바 노드.
var info_toast_badge: TextureRect = null
var info_toast_progress_track: Panel = null
var info_toast_progress_fill: Panel = null
var info_toast_timer: Timer = null
var confirm_overlay_mode := "unclaimed"
var confirm_overlay_subject := ""
var shop_open_button: Button
var shop_panel: PanelContainer
var codex_open_button: Button
var codex_panel: ArtifactCodexPanelUI
var current_codex_reward_table: Dictionary = {}
var current_codex_growth_state: Dictionary = {}
var current_codex_debug_all := false
var current_codex_selected_entry_id := ""
var current_codex_active_section := "all"
var current_codex_active_taxonomy_id := "backpack_items"
var current_codex_sort_id := "catalog"
var giant_timer_panel: PanelContainer
var giant_timer_label: Label
var vignette_overlay: Panel
var pulse_time: float = 0.0
var heartbeat_player: AudioStreamPlayer
var _heartbeat_volume: float = 75.0
var _interaction_sfx_volume: float = 75.0
var interaction_sfx_players: Array[AudioStreamPlayer] = []
var interaction_sfx_streams: Dictionary = {}
var _interaction_sfx_next_player := 0
var _interaction_sfx_last_msec: Dictionary = {}
var _last_sfx_page_id := ""
var interaction_sfx_events: Array = []
var heartbeat_timer: float = 1.0
var giant_timer_ui
var reward_reveal_overlay
var reward_reveal_done_bridge: Callable = Callable()
var reward_reveal_pending_callback: Callable = Callable()
var reward_reveal_pending_step := ""
var tooltip_panel: PanelContainer
var tooltip_label: RichTextLabel
var narrative_toast: Control = null
var narrative_toast_model: Dictionary = {"visible": false}
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
var _shared_backpack_signals_connected := false
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
var story_scene_page: Control
var reward_cloud_scroll: ScrollContainer = null
var discard_card_scroll: ScrollContainer = null
var claim_card_scroll: ScrollContainer = null
var reward_inspector_scroll: ScrollContainer = null
