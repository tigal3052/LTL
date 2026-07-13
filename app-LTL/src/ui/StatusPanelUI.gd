# 계약:
# - 책임: battle HUD status, terrain copy, weakness cards, energy queue, and phase timing readouts stay contained inside the status sidebar.
# 실행: define the battle status panel as a PanelContainer script and update queue, timing, and terrain controls from scene models.
extends PanelContainer
const TextCatalogScript = preload("res://src/ui/TextCatalog.gd")
const RewardCeremonyPolicyScript = preload("res://src/ui/presenters/RewardCeremonyPolicy.gd")
const LTLThemeScript = preload("res://src/ui/theme/LTLTheme.gd")
const EnergyQueuePulseSlotScript = preload("res://src/ui/EnergyQueuePulseSlot.gd")
const StatusPanelInfoCardsScript = preload("res://src/ui/status_panel/StatusPanelInfoCards.gd")
const ENERGY_QUEUE_COLUMNS := 8
const ENERGY_QUEUE_ROWS := 2
const ENERGY_QUEUE_MAX_SLOTS := 16
const STATUS_ROW_LABEL_WIDTH := 76.0
@onready var status_box: VBoxContainer = $Margin/StatusBox
@onready var info_shell: PanelContainer = $Margin/StatusBox/InfoShell
@onready var info_title: Button = $Margin/StatusBox/InfoShell/InfoMargin/InfoBox/InfoTitle
@onready var terrain_copy: Label = $Margin/StatusBox/InfoShell/InfoMargin/InfoBox/TerrainCopy
@onready var weakness_card_grid: GridContainer = $Margin/StatusBox/InfoShell/InfoMargin/InfoBox/WeaknessCardGrid
@onready var info_detail_shell: PanelContainer = $Margin/StatusBox/InfoShell/InfoMargin/InfoBox/InfoDetailShell
@onready var info_note_row: HFlowContainer = $Margin/StatusBox/InfoShell/InfoMargin/InfoBox/InfoDetailShell/InfoDetailMargin/InfoNoteRow
@onready var ops_shell: PanelContainer = $Margin/StatusBox/OpsShell
@onready var ops_box: VBoxContainer = $Margin/StatusBox/OpsShell/OpsMargin/OpsBox
@onready var status_title: Label = $Margin/StatusBox/OpsShell/OpsMargin/OpsBox/StatusTitle
@onready var node_card: PanelContainer = $Margin/StatusBox/InfoShell/InfoMargin/InfoBox/NodeCard
@onready var extractor_visual: Panel = $Margin/StatusBox/InfoShell/InfoMargin/InfoBox/NodeCard/Margin/NodeInfoBox/NodeRow/ExtractorVisual
@onready var extractor_label: Label = $Margin/StatusBox/InfoShell/InfoMargin/InfoBox/NodeCard/Margin/NodeInfoBox/NodeRow/ExtractorLabel
@onready var node_meta_label: Label = $Margin/StatusBox/InfoShell/InfoMargin/InfoBox/NodeCard/Margin/NodeInfoBox/NodeMetaLabel
@onready var health_label: Label = $Margin/StatusBox/OpsShell/OpsMargin/OpsBox/HPBox/Head/HealthLabel
@onready var health_value_label: Label = $Margin/StatusBox/OpsShell/OpsMargin/OpsBox/HPBox/Head/HealthValue
@onready var health_bar: ProgressBar = $Margin/StatusBox/OpsShell/OpsMargin/OpsBox/HPBox/HealthBar
@onready var shield_label: Label = $Margin/StatusBox/OpsShell/OpsMargin/OpsBox/ShieldBox/Head/ShieldLabel
@onready var shield_value_label: Label = $Margin/StatusBox/OpsShell/OpsMargin/OpsBox/ShieldBox/Head/ShieldValue
@onready var shield_bar: ProgressBar = $Margin/StatusBox/OpsShell/OpsMargin/OpsBox/ShieldBox/ShieldBar
@onready var queue_row: VBoxContainer = $Margin/StatusBox/OpsShell/OpsMargin/OpsBox/QueueRow
@onready var queue_label: Label = $Margin/StatusBox/OpsShell/OpsMargin/OpsBox/QueueRow/Head/QueueLabel
@onready var queue_value_label: Label = $Margin/StatusBox/OpsShell/OpsMargin/OpsBox/QueueRow/Head/QueueValue
@onready var visual_queue_box: GridContainer = $Margin/StatusBox/OpsShell/OpsMargin/OpsBox/QueueRow/QueueStack/VisualQueueBox
@onready var pin_title_label: Label = $Margin/StatusBox/OpsShell/OpsMargin/OpsBox/TimerRow/Head/PinLabel
@onready var pin_value_label: Label = $Margin/StatusBox/OpsShell/OpsMargin/OpsBox/TimerRow/Head/PinValue
@onready var pin_progress_bar: ProgressBar = $Margin/StatusBox/OpsShell/OpsMargin/OpsBox/TimerRow/PinProgressBar
@onready var drill_status_title: Label = $Margin/StatusBox/OpsShell/OpsMargin/OpsBox/DrillStatusRow/DrillStatusLabel
@onready var repair_status_label: Label = $Margin/StatusBox/OpsShell/OpsMargin/OpsBox/DrillStatusRow/RepairStatusLabel
@onready var status_footer_spacer: Control = $Margin/StatusBox/OpsShell/OpsMargin/OpsBox/StatusFooterSpacer
@onready var purple_status_row: HBoxContainer = $Margin/StatusBox/OpsShell/OpsMargin/OpsBox/StatusFooterSpacer/PurpleStatusRow
@onready var purple_status_label: Label = $Margin/StatusBox/OpsShell/OpsMargin/OpsBox/StatusFooterSpacer/PurpleStatusRow/PurpleStatusLabel
@onready var purple_status_value: Label = $Margin/StatusBox/OpsShell/OpsMargin/OpsBox/StatusFooterSpacer/PurpleStatusRow/PurpleStatusValue
@onready var combat_timer_label: Label = $Margin/StatusBox/OpsShell/OpsMargin/OpsBox/CombatTimerFooterMargin/CombatTimerFooter/CombatTimerLabel

var queue_hint_label: Label
var info_details_expanded := false

func _ready() -> void:
	_apply_shell_theme()
	_connect_info_toggle()
	_install_queue_hint_label()
	_apply_row_alignment()
	_configure_visual_queue_grid()
	_configure_purple_status_overlay()
	apply_locale()
	render_node_info({})
	render_hud_projection({})
	render_combat_timer("00:00", false)

func apply_locale() -> void:
	_update_info_toggle_text()
	status_title.text = TextCatalogScript.t("panel.drill_node_status")
	health_label.text = TextCatalogScript.t("panel.health")
	shield_label.text = TextCatalogScript.t("panel.shield")
	queue_label.text = TextCatalogScript.t("panel.queue")
	pin_title_label.text = TextCatalogScript.t("panel.pin_status")
	drill_status_title.text = TextCatalogScript.t("panel.drill_status")
	if weakness_card_grid.get_child_count() == 0:
		terrain_copy.text = TextCatalogScript.t("panel.info.empty")
	_sync_info_detail_visibility()
	if purple_status_row.visible:
		purple_status_label.text = TextCatalogScript.t("panel.purple_status")

func render_target_bars(scene: Dictionary) -> void:
	if not _is_status_scene(scene):
		return
	var target: Dictionary = scene.get("targetPanel", {})
	_apply_value_bar(health_bar, health_value_label, float(target.get("health", 0.0)), float(target.get("maxHealth", 100.0)))
	_apply_value_bar(shield_bar, shield_value_label, float(target.get("shield", 0.0)), float(target.get("maxShield", 2.4)))

func render_extractor_label(scene: Dictionary) -> void:
	var context: Dictionary = scene.get("selectedNodeContext", {})
	var node_label := str(context.get("label", scene.get("lastNodeLabel", "")))
	extractor_label.text = TextCatalogScript.t(
		"status.node",
		[TextCatalogScript.display_name(node_label) if not node_label.is_empty() else "-"]
	)
	node_meta_label.text = StatusPanelInfoCardsScript.node_meta_text(context, scene.get("targetPanel", {}))

func render_node_info(scene: Dictionary) -> void:
	_clear_container(weakness_card_grid)
	_clear_container(info_note_row)
	info_note_row.visible = false
	if scene.is_empty():
		terrain_copy.text = TextCatalogScript.t("panel.info.empty")
		_sync_info_detail_visibility()
		return
	var context: Dictionary = scene.get("selectedNodeContext", {})
	var target_panel: Dictionary = scene.get("targetPanel", {})
	var weaknesses: Array = StatusPanelInfoCardsScript.normalized_colors(context.get("weakness", target_panel.get("weakness", [])))
	if context.is_empty() and target_panel.is_empty() and weaknesses.is_empty():
		terrain_copy.text = TextCatalogScript.t("panel.info.empty")
		_sync_info_detail_visibility()
		return
	var shield_mul := float(context.get("shieldMul", context.get("shield_mul", 1.0)))
	var health_mul := float(context.get("healthMul", context.get("health_mul", 1.0)))
	terrain_copy.text = StatusPanelInfoCardsScript.terrain_copy(context, weaknesses)
	if weaknesses.is_empty():
		weakness_card_grid.columns = 1
		weakness_card_grid.add_child(StatusPanelInfoCardsScript.build_neutral_card(shield_mul, health_mul))
	else:
		weakness_card_grid.columns = 1
		for color_name in weaknesses:
			var metrics := StatusPanelInfoCardsScript.metric_values_for_color(context, str(color_name))
			weakness_card_grid.add_child(
				StatusPanelInfoCardsScript.build_color_card(
					str(color_name),
					float(metrics.get("shield", shield_mul)),
					float(metrics.get("health", health_mul))
				)
			)
	StatusPanelInfoCardsScript.render_note_row(info_note_row, context, weaknesses)
	_sync_info_detail_visibility()

func render_visual_queue(scene: Dictionary) -> void:
	render_hud_projection({})
	if not _is_status_scene(scene):
		return
	var HudReadModelScript = load("res://src/ui/read_models/HudReadModel.gd")
	if HudReadModelScript != null:
		render_hud_projection(HudReadModelScript.project(scene))

func render_hud_projection(model: Dictionary) -> void:
	_configure_visual_queue_grid()
	_clear_visual_queue_box()
	if model.is_empty():
		_render_pin_projection({})
		_render_repair_projection({})
		_render_status_footer({})
		if queue_value_label != null:
			queue_value_label.text = ""
		if queue_hint_label != null:
			queue_hint_label.text = ""
		return
	var queue: Dictionary = model.get("queue", {})
	var slot_colors: Array = queue.get("slotColors", []).duplicate(true) if queue.get("slotColors", []) is Array else []
	var capacity := clampi(int(queue.get("capacity", ENERGY_QUEUE_COLUMNS)), 0, ENERGY_QUEUE_MAX_SLOTS)
	if capacity <= 0:
		capacity = ENERGY_QUEUE_COLUMNS
	for index in range(ENERGY_QUEUE_MAX_SLOTS):
		var slot := EnergyQueuePulseSlotScript.new()
		var enabled := index < capacity
		var loaded := index < slot_colors.size()
		var slot_color := str(slot_colors[index]) if loaded else ""
		slot.configure(slot_color, loaded, enabled, index == 0 and loaded)
		visual_queue_box.add_child(slot)
	if queue_value_label != null:
		queue_value_label.text = "%d / %d" % [mini(slot_colors.size(), ENERGY_QUEUE_MAX_SLOTS), ENERGY_QUEUE_MAX_SLOTS]
	if queue_hint_label != null:
		queue_hint_label.text = _queue_hint_text(queue, model.get("feedback", {}))
	_render_pin_projection(model.get("pin", {}))
	_render_repair_projection(model.get("repair", {}))
	_render_status_footer(model)

func render_combat_timer(timer_text: String, active: bool) -> void:
	combat_timer_label.visible = active
	combat_timer_label.text = timer_text if active else "00:00"

func render_repair_overlay(_scene: Dictionary, repair_overlay: PanelContainer, overlay_model: Dictionary = {}) -> void:
	if repair_overlay == null:
		return
	if overlay_model.is_empty():
		repair_overlay.visible = false
		return
	if not bool(overlay_model.get("visible", true)):
		repair_overlay.visible = false
		return
	var mode := str(overlay_model.get("mode", "hidden"))
	if mode == "hidden":
		repair_overlay.visible = false
		return
	_show_overlay(
		repair_overlay,
		str(overlay_model.get("title", "")),
		"%s\n\n%s" % [str(overlay_model.get("cause", "")), str(overlay_model.get("tip", ""))]
	)
	_apply_overlay_tone(repair_overlay, str(overlay_model.get("accent", "warning")))

func _connect_info_toggle() -> void:
	if info_title == null:
		return
	info_title.toggle_mode = true
	info_title.button_pressed = info_details_expanded
	if not info_title.pressed.is_connected(_on_info_title_pressed):
		info_title.pressed.connect(_on_info_title_pressed)
	_update_info_toggle_text()
	_sync_info_detail_visibility()

func _on_info_title_pressed() -> void:
	info_details_expanded = not info_details_expanded
	info_title.button_pressed = info_details_expanded
	_update_info_toggle_text()
	_sync_info_detail_visibility()

func _update_info_toggle_text() -> void:
	if info_title == null:
		return
	var marker := "-" if info_details_expanded else "+"
	info_title.text = "%s  %s" % [TextCatalogScript.t("panel.info.core"), marker]

func _sync_info_detail_visibility() -> void:
	if info_detail_shell == null:
		return
	var has_details := info_note_row != null and info_note_row.get_child_count() > 0
	var expanded_with_cards := info_details_expanded and weakness_card_grid != null and weakness_card_grid.get_child_count() > 0
	info_detail_shell.visible = info_details_expanded and has_details
	if weakness_card_grid != null:
		weakness_card_grid.visible = expanded_with_cards
	if node_card != null:
		node_card.visible = info_details_expanded
	if ops_shell != null:
		ops_shell.visible = not info_details_expanded
		ops_shell.size_flags_vertical = Control.SIZE_EXPAND_FILL
	if info_shell != null:
		info_shell.size_flags_vertical = Control.SIZE_EXPAND_FILL if info_details_expanded else Control.SIZE_FILL
	if info_note_row != null:
		info_note_row.visible = has_details
	if terrain_copy != null:
		terrain_copy.visible = true

func _is_status_scene(scene: Dictionary) -> bool:
	return should_render_status_scene(scene)

static func should_render_status_scene(scene: Dictionary) -> bool:
	var phase := str(scene.get("phase", ""))
	return phase == "combat" or RewardCeremonyPolicyScript.is_active_scene(scene) or (phase == "reward_loot" and bool(scene.get("show_victory_overlay", false)))

# 목업 .stat-row 준거: 수치 텍스트는 바 위 헤드 라인의 우측 라벨에 병기하고 바는 순수 게이지로 남긴다.
func _apply_value_bar(bar: ProgressBar, value_label: Label, value: float, max_value: float) -> void:
	bar.max_value = max_value
	bar.value = value
	bar.show_percentage = false
	if value_label == null:
		return
	var pct := (value / max_value) * 100.0 if max_value > 0.0 else 0.0
	value_label.text = "%.1f / %.1f (%.0f%%)" % [value, max_value, pct]

func _configure_visual_queue_grid() -> void:
	if visual_queue_box == null:
		return
	visual_queue_box.columns = ENERGY_QUEUE_COLUMNS
	visual_queue_box.add_theme_constant_override("h_separation", 4)
	visual_queue_box.add_theme_constant_override("v_separation", 4)

func _clear_visual_queue_box() -> void:
	for child in visual_queue_box.get_children():
		visual_queue_box.remove_child(child)
		child.queue_free()

func _render_pin_projection(pin: Dictionary) -> void:
	var progress := clampf(float(pin.get("progress", 0.0)), 0.0, 100.0)
	pin_progress_bar.max_value = 100.0
	pin_progress_bar.value = progress
	pin_progress_bar.show_percentage = false
	if pin_value_label != null:
		pin_value_label.text = "%d%%" % int(round(progress))

func _metric_stack(shield_mul: float, health_mul: float) -> GridContainer:
	return StatusPanelInfoCardsScript.metric_stack(shield_mul, health_mul)

func _render_purple_status(pressure: Dictionary) -> String:
	var stack_count := int(pressure.get("stackCount", 0))
	var buff_count := int(pressure.get("buffCount", 0))
	var parts: Array[String] = []
	if stack_count > 0:
		parts.append(TextCatalogScript.t("status.purple.weakened", [stack_count]))
	if buff_count > 0:
		parts.append(TextCatalogScript.t("status.purple.buff", [buff_count]))
	return " | ".join(parts)

func _show_overlay(overlay: PanelContainer, title: String, description: String) -> void:
	overlay.visible = true
	(overlay.get_node("Center/WarningBox/WarningLabel") as Label).text = title
	(overlay.get_node("Center/WarningBox/DescriptionLabel") as Label).text = description

func _configure_purple_status_overlay() -> void:
	if status_footer_spacer == null or purple_status_row == null:
		return
	status_footer_spacer.clip_contents = true
	purple_status_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_layout_purple_status_overlay()
	if not status_footer_spacer.resized.is_connected(_layout_purple_status_overlay):
		status_footer_spacer.resized.connect(_layout_purple_status_overlay)

func _layout_purple_status_overlay() -> void:
	if status_footer_spacer == null or purple_status_row == null:
		return
	var row_height := purple_status_row.get_combined_minimum_size().y
	purple_status_row.position = Vector2.ZERO
	purple_status_row.size = Vector2(maxf(0.0, status_footer_spacer.size.x), row_height)

func _apply_shell_theme() -> void:
	# 전투 리디자인: 좌측 '연구원 노트' 양피지 시트 + 원장(ledger) 카드 스타일
	add_theme_stylebox_override("panel", LTLThemeScript.parchment_style())
	info_shell.add_theme_stylebox_override("panel", LTLThemeScript.ledger_card_style(LTLThemeScript.OUTLINE_VARIANT, 10))
	_style_info_toggle()
	info_detail_shell.add_theme_stylebox_override("panel", LTLThemeScript.ledger_card_style(LTLThemeScript.OUTLINE_VARIANT, 8))
	ops_shell.add_theme_stylebox_override("panel", LTLThemeScript.ledger_card_style(Color(0.231, 0.412, 0.165, 0.35), 10))
	node_card.add_theme_stylebox_override("panel", LTLThemeScript.ledger_card_style(LTLThemeScript.OUTLINE_VARIANT, 8))
	_style_metric_bar(health_bar, LTLThemeScript.ERROR, Color(0.851, 0.824, 0.765, 1.0))
	_style_metric_bar(shield_bar, LTLThemeScript.energy_deep_color("blue"), Color(0.851, 0.824, 0.765, 1.0))
	_style_metric_bar(pin_progress_bar, LTLThemeScript.WARNING_GOLD, Color(0.851, 0.824, 0.765, 1.0))
	extractor_label.add_theme_color_override("font_color", LTLThemeScript.INK_PRIMARY)
	node_meta_label.add_theme_color_override("font_color", LTLThemeScript.INK_MUTED)
	terrain_copy.add_theme_color_override("font_color", LTLThemeScript.INK_MUTED)
	pin_title_label.add_theme_color_override("font_color", LTLThemeScript.INK_PRIMARY)
	# 목업 .stat-row .num: 수치 라벨은 게이지와 같은 색으로 병기한다.
	if health_value_label != null:
		health_value_label.add_theme_color_override("font_color", LTLThemeScript.ERROR)
	if shield_value_label != null:
		shield_value_label.add_theme_color_override("font_color", LTLThemeScript.energy_deep_color("blue"))
	if pin_value_label != null:
		pin_value_label.add_theme_color_override("font_color", Color(0.604, 0.435, 0.113, 1.0))
	if queue_value_label != null:
		queue_value_label.add_theme_color_override("font_color", LTLThemeScript.SECONDARY)
	repair_status_label.add_theme_color_override("font_color", LTLThemeScript.INK_MUTED)
	purple_status_label.add_theme_color_override("font_color", LTLThemeScript.INK_MUTED)
	purple_status_value.add_theme_color_override("font_color", Color(0.482, 0.29, 0.62, 1.0))
	combat_timer_label.add_theme_color_override("font_color", Color(0.604, 0.435, 0.113, 1.0))
	status_title.add_theme_color_override("font_color", LTLThemeScript.PRIMARY)
	for row_label in [health_label, shield_label, queue_label, drill_status_title]:
		if row_label != null:
			row_label.add_theme_color_override("font_color", LTLThemeScript.INK_PRIMARY)
	extractor_visual.add_theme_stylebox_override("panel", LTLThemeScript.surface_style(LTLThemeScript.TERTIARY_CONTAINER, Color(1.0, 1.0, 1.0, 1.0), 10, 2, 0.0))

func _style_info_toggle() -> void:
	if info_title == null:
		return
	info_title.flat = false
	info_title.alignment = HORIZONTAL_ALIGNMENT_LEFT
	info_title.add_theme_font_size_override("font_size", 13)
	info_title.add_theme_color_override("font_color", LTLThemeScript.PRIMARY)
	info_title.add_theme_color_override("font_hover_color", LTLThemeScript.SECONDARY)
	info_title.add_theme_color_override("font_pressed_color", LTLThemeScript.PRIMARY)
	info_title.add_theme_color_override("font_focus_color", LTLThemeScript.PRIMARY)
	var normal := LTLThemeScript.ledger_card_style(Color(0.231, 0.412, 0.165, 0.30), 8)
	var hover := LTLThemeScript.ledger_card_style(Color(0.231, 0.412, 0.165, 0.65), 8)
	var pressed := LTLThemeScript.ledger_card_style(LTLThemeScript.WARNING_GOLD, 8)
	for style in [normal, hover, pressed]:
		style.content_margin_left = 10
		style.content_margin_right = 10
		style.content_margin_top = 5
		style.content_margin_bottom = 5
	info_title.add_theme_stylebox_override("normal", normal)
	info_title.add_theme_stylebox_override("hover", hover)
	info_title.add_theme_stylebox_override("pressed", pressed)
	info_title.add_theme_stylebox_override("focus", hover)

func _apply_row_alignment() -> void:
	# 목업 .stat-row: 헤드 라벨(좌)·수치(우) + 아래 순수 게이지 — 고정 라벨 폭 없이 헤드가 폭을 나눈다.
	for label in [health_label, shield_label, queue_label, pin_title_label, drill_status_title]:
		if label == null:
			continue
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	if drill_status_title != null:
		drill_status_title.custom_minimum_size = Vector2(STATUS_ROW_LABEL_WIDTH, 0.0)
	for control in [health_bar, shield_bar, visual_queue_box.get_parent() if visual_queue_box != null else null, pin_progress_bar, repair_status_label]:
		var row_value = control as Control
		if row_value == null:
			continue
		row_value.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if repair_status_label != null:
		repair_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		repair_status_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

func _style_metric_bar(bar: ProgressBar, fill_color: Color, background_color: Color) -> void:
	bar.add_theme_stylebox_override("fill", LTLThemeScript.value_bar_fill(fill_color))
	bar.add_theme_stylebox_override("background", LTLThemeScript.value_bar_background(background_color))

func _install_queue_hint_label() -> void:
	if visual_queue_box == null or queue_hint_label != null:
		return
	queue_hint_label = Label.new()
	queue_hint_label.name = "QueueHintLabel"
	queue_hint_label.add_theme_font_size_override("font_size", 11)
	queue_hint_label.add_theme_color_override("font_color", LTLThemeScript.INK_MUTED)
	queue_hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	queue_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	queue_hint_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	queue_hint_label.visible = false
	if ops_box != null and queue_row != null:
		ops_box.add_child(queue_hint_label)
		ops_box.move_child(queue_hint_label, queue_row.get_index() + 1)

func _queue_hint_text(queue: Dictionary, feedback: Dictionary) -> String:
	if bool(feedback.get("isEmptyQueue", false)):
		return TextCatalogScript.t("hud.queue.hint.empty_queue")
	if bool(feedback.get("isMismatch", false)):
		return TextCatalogScript.t("hud.queue.hint.mismatch")
	if bool(queue.get("queueMatch", false)):
		return TextCatalogScript.t("hud.queue.hint.match")
	return TextCatalogScript.t("hud.queue.hint.default")

func _render_repair_projection(repair: Dictionary) -> void:
	var stage := str(repair.get("stage", "stable"))
	repair_status_label.text = str(repair.get("label", TextCatalogScript.t("hud.repair.stable")))
	match stage:
		"stable":
			repair_status_label.add_theme_color_override("font_color", LTLThemeScript.SECONDARY)
		"strained":
			repair_status_label.add_theme_color_override("font_color", Color(0.604, 0.435, 0.113, 1.0))
		"critical", "repair_required":
			repair_status_label.add_theme_color_override("font_color", LTLThemeScript.ERROR)
		_:
			repair_status_label.add_theme_color_override("font_color", LTLThemeScript.INK_MUTED)

func _render_status_footer(model: Dictionary) -> void:
	var parts: Array[String] = []
	var hazard: Dictionary = model.get("hazard", {})
	if bool(hazard.get("active", false)):
		parts.append(str(hazard.get("summary", "")))
	var purple_text := _render_purple_status(model.get("purplePressure", {}))
	if not purple_text.is_empty():
		parts.append(purple_text)
	var feedback: Dictionary = model.get("feedback", {})
	if bool(feedback.get("isRepairBlocked", false)):
		parts.append(TextCatalogScript.t("status.repair_locked"))
	purple_status_row.visible = not parts.is_empty()
	if parts.is_empty():
		purple_status_value.text = "-"
		_layout_purple_status_overlay()
		return
	purple_status_label.text = TextCatalogScript.t("status.field")
	purple_status_value.text = " | ".join(parts)
	var font_color := Color(0.482, 0.29, 0.62, 1.0)
	if bool(hazard.get("active", false)):
		font_color = LTLThemeScript.ERROR if str(hazard.get("severity", "stable")) == "critical" else Color(0.604, 0.435, 0.113, 1.0)
	purple_status_value.add_theme_color_override("font_color", font_color)
	_layout_purple_status_overlay()

func _apply_overlay_tone(overlay: PanelContainer, accent: String) -> void:
	overlay.add_theme_stylebox_override("panel", LTLThemeScript.overlay_style(accent))

func _clear_container(container: Node) -> void:
	if container == null:
		return
	for child in container.get_children():
		container.remove_child(child)
		child.queue_free()
