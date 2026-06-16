class_name MainViewLocaleRuntime
extends RefCounted

const TextCatalogScript = preload("res://src/ui/TextCatalog.gd")

static func apply_locale(view) -> void:
	if view.reset_button == null:
		return
	set_label_text(
		view,
		"RootMargin/AppShell/Header/Margin/PhaseRow/TitleLabel",
		resolved_header_title(view._last_rendered_scene) if not view._last_rendered_scene.is_empty() else TextCatalogScript.t("app.title")
	)
	for page_id in view.SURFACE_PAGE_IDS:
		var bundle: Dictionary = view._page_bundle(page_id)
		if bundle.is_empty():
			continue
		var bundle_status_panel = bundle.get("statusPanel", null)
		if bundle_status_panel != null and bundle_status_panel.has_method("apply_locale"):
			bundle_status_panel.apply_locale()
		set_bundle_label_text(bundle, "TopContent/BackpackContainer/BackpackEnginePanel/Margin/EngineBox/EngineTitle", TextCatalogScript.t("panel.backpack"))
		if bundle.get("rightSidebar", null) != null and bundle.get("rightSidebar").has_method("apply_locale"):
			bundle.get("rightSidebar").apply_locale()
		if bundle.get("battlefieldUI", null) != null:
			set_bundle_label_text(bundle, "BattlefieldPanel/Margin/BattlefieldBox/BattlefieldTitle", "")
		if bundle.get("rewardPanel", null) != null:
			_apply_reward_bundle_locale(bundle)
	set_label_text(view, "ConfirmOverlay/Center/ConfirmBox/WarningLabel", TextCatalogScript.t("confirm.unclaimed.title"))
	set_label_text(view, "ConfirmOverlay/Center/ConfirmBox/DescriptionLabel", TextCatalogScript.t("confirm.unclaimed.desc"))
	view.confirm_proceed_button.text = TextCatalogScript.t("action.proceed")
	view.confirm_cancel_button.text = TextCatalogScript.t("action.cancel")
	view.settings_open_button.text = TextCatalogScript.t("action.settings")
	_apply_action_bar_locale(view)
	_apply_panel_locale(view)
	view._set_reward_workspace_title_state(view.backpack_container != null and view.backpack_container.get_parent() == view.reward_backpack_host)
	view._apply_shell_theme()

static func set_label_text(view, path: String, text: String) -> void:
	var node := view.get_node_or_null(path) as Label
	if node != null:
		node.text = text

static func set_rich_text(view, path: String, text: String) -> void:
	var node := view.get_node_or_null(path) as RichTextLabel
	if node != null:
		node.text = text

static func set_bundle_label_text(bundle: Dictionary, path: String, text: String) -> void:
	var page_root: Node = bundle.get("pageRoot", null) as Node
	if page_root == null:
		return
	var node := page_root.get_node_or_null(path) as Label
	if node != null:
		node.text = text

static func set_bundle_optional_label_text(bundle: Dictionary, path: String, text: String) -> void:
	set_bundle_label_text(bundle, path, text)
	var page_root: Node = bundle.get("pageRoot", null) as Node
	if page_root == null:
		return
	var node := page_root.get_node_or_null(path) as Label
	if node != null:
		node.visible = not text.strip_edges().is_empty()

static func set_bundle_rich_text(bundle: Dictionary, path: String, text: String) -> void:
	var page_root: Node = bundle.get("pageRoot", null) as Node
	if page_root == null:
		return
	var node := page_root.get_node_or_null(path) as RichTextLabel
	if node != null:
		node.text = text

static func resolved_header_title(scene: Dictionary) -> String:
	var selected_leviathan: Dictionary = scene.get("selectedLeviathan", {})
	var leviathan_name := str(selected_leviathan.get("name", "")).strip_edges()
	if not leviathan_name.is_empty():
		return leviathan_name
	return TextCatalogScript.t("app.title")

static func _apply_reward_bundle_locale(bundle: Dictionary) -> void:
	set_bundle_label_text(bundle, "RewardPanel/Margin/RewardBox/BoardHead/BoardTitleBox/RewardTitle", TextCatalogScript.t("panel.rewards"))
	set_bundle_label_text(bundle, "RewardPanel/Margin/RewardBox/BoardHead/BoardTitleBox/RewardSubtitle", TextCatalogScript.t("reward.board.subtitle"))
	set_bundle_optional_label_text(bundle, "RewardPanel/Margin/RewardBox/BoardHead/ModePill", TextCatalogScript.t("reward.board.mode_pill"))
	set_bundle_label_text(bundle, "RewardPanel/Margin/RewardBox/RewardBoardScroll/RewardBoard/RewardGrid/RewardsZone/Margin/ZoneBox/ZoneHead/ZoneTitle", TextCatalogScript.t("reward.board.rewards_zone.title"))
	set_bundle_optional_label_text(bundle, "RewardPanel/Margin/RewardBox/RewardBoardScroll/RewardBoard/RewardGrid/RewardsZone/Margin/ZoneBox/ZoneHead/ZoneHint", TextCatalogScript.t("reward.board.rewards_zone.hint"))
	set_bundle_label_text(bundle, "RewardPanel/Margin/RewardBox/RewardBoardScroll/RewardBoard/RewardGrid/WorkspaceZone/Margin/ZoneBox/ZoneHead/ZoneTitle", TextCatalogScript.t("panel.backpack"))
	set_bundle_label_text(bundle, "RewardPanel/Margin/RewardBox/RewardBoardScroll/RewardBoard/RewardGrid/WorkspaceZone/Margin/ZoneBox/ZoneHead/ZoneHint", TextCatalogScript.t("reward.board.workspace_zone.hint"))
	set_bundle_label_text(bundle, "RewardPanel/Margin/RewardBox/RewardBoardScroll/RewardBoard/RewardGrid/InspectorZone/Margin/ZoneBox/ZoneHead/ZoneTitle", TextCatalogScript.t("reward.board.inspector_zone.title"))
	set_bundle_label_text(bundle, "RewardPanel/Margin/RewardBox/RewardBoardScroll/RewardBoard/RewardGrid/InspectorZone/Margin/ZoneBox/ZoneHead/ZoneHint", TextCatalogScript.t("reward.board.inspector_zone.hint"))
	set_bundle_label_text(bundle, "RewardPanel/Margin/RewardBox/RewardBoardScroll/RewardBoard/BottomRow/DiscardZone/Margin/ZoneBox/ZoneHead/ZoneTitle", TextCatalogScript.t("reward.board.discard_zone.title"))
	set_bundle_optional_label_text(bundle, "RewardPanel/Margin/RewardBox/RewardBoardScroll/RewardBoard/BottomRow/DiscardZone/Margin/ZoneBox/ZoneHead/ZoneHint", TextCatalogScript.t("reward.board.discard_zone.hint"))
	set_bundle_optional_label_text(bundle, "RewardPanel/Margin/RewardBox/RewardBoardScroll/RewardBoard/BottomRow/DiscardZone/Margin/ZoneBox/DiscardCardScroll/DiscardCard/Margin/DiscardCardBox/DiscardCardTitle", TextCatalogScript.t("reward.board.discard_card_title"))
	set_bundle_label_text(bundle, "RewardPanel/Margin/RewardBox/RewardBoardScroll/RewardBoard/BottomRow/ConfirmZone/Margin/ZoneBox/ZoneHead/ZoneTitle", TextCatalogScript.t("reward.board.confirm_zone.title"))
	set_bundle_optional_label_text(bundle, "RewardPanel/Margin/RewardBox/RewardBoardScroll/RewardBoard/BottomRow/ConfirmZone/Margin/ZoneBox/ZoneHead/ZoneHint", TextCatalogScript.t("reward.board.confirm_zone.hint"))
	set_bundle_optional_label_text(bundle, "RewardPanel/Margin/RewardBox/RewardBoardScroll/RewardBoard/BottomRow/ConfirmZone/Margin/ZoneBox/ClaimCardScroll/ClaimCard/Margin/ClaimCardBox/ClaimCardTitle", TextCatalogScript.t("reward.board.claim_card_title"))
	set_bundle_rich_text(bundle, "RewardPanel/Margin/RewardBox/RewardBoardScroll/RewardBoard/RewardGrid/WorkspaceZone/Margin/ZoneBox/WorkspaceNote", TextCatalogScript.t("reward.board.workspace_note"))

static func _apply_action_bar_locale(view) -> void:
	for page_id in view.ACTION_BAR_PAGE_IDS:
		var bundle: Dictionary = view._page_bundle(page_id)
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
		_apply_optional_action_buttons(bundle)

static func _apply_optional_action_buttons(bundle: Dictionary) -> void:
	var shop_btn := bundle.get("shopButton", null) as Button
	var codex_btn := bundle.get("codexButton", null) as Button
	var settings_btn := bundle.get("settingsButton", null) as Button
	if shop_btn != null:
		shop_btn.text = TextCatalogScript.t("action.shop")
	if codex_btn != null:
		codex_btn.text = TextCatalogScript.t("action.codex")
	if settings_btn != null:
		settings_btn.text = TextCatalogScript.t("action.settings")

static func _apply_panel_locale(view) -> void:
	for page_id in view.SURFACE_PAGE_IDS:
		var bundle: Dictionary = view._page_bundle(page_id)
		var inline_btn := bundle.get("claimInlineButton", null) as Button
		if inline_btn != null:
			inline_btn.text = TextCatalogScript.t("action.claim_rewards")
	if view.shop_open_button != null:
		view.shop_open_button.text = TextCatalogScript.t("action.shop")
	if view.codex_open_button != null:
		view.codex_open_button.text = TextCatalogScript.t("action.codex")
	if view.settings_panel != null and view.settings_panel.has_method("apply_locale"):
		view.settings_panel.apply_locale()
	if view.shop_panel != null and view.shop_panel.has_method("apply_locale"):
		view.shop_panel.apply_locale()
	if view.codex_panel != null and view.codex_panel.has_method("apply_locale"):
		view.codex_panel.apply_locale()
	if view.is_artifact_codex_visible() and not view.current_codex_reward_table.is_empty():
		view.render_artifact_codex(view.current_codex_reward_table, view.current_codex_growth_state, view.current_codex_debug_all)
