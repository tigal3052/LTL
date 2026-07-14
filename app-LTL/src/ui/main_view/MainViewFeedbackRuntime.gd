class_name MainViewFeedbackRuntime
extends RefCounted

const TextCatalogScript = preload("res://src/ui/TextCatalog.gd")
const ToastRedesignThemeScript = preload("res://src/ui/theme/ToastRedesignTheme.gd")

static func set_confirm_overlay_visible(view, val: bool) -> void:
	if val:
		_apply_confirm_overlay_copy(view)
	var changed: bool = view.confirm_overlay.visible != val
	view.confirm_overlay.visible = val
	if not val:
		view.confirm_overlay_mode = "unclaimed"
		view.confirm_overlay_subject = ""
	if changed and view.has_method("play_interaction_sfx"):
		view.play_interaction_sfx("menu_open" if val else "menu_close")

static func show_unclaimed_reward_confirmation(view) -> void:
	view.confirm_overlay_mode = "unclaimed"
	view.confirm_overlay_subject = ""
	set_confirm_overlay_visible(view, true)

static func show_discard_confirmation(view, artifact_name: String) -> void:
	view.confirm_overlay_mode = "discard"
	view.confirm_overlay_subject = artifact_name
	set_confirm_overlay_visible(view, true)

# 계약: info 토스트는 우하단 코너 밴드에 양피지 카드로 표시되고, 실제 남은 시간을 힌트/진행 바에 반영한다.
# 실행: 메시지와 자동 소멸 시간을 적용하고 코너 배치 후 타이머를 시작한다.
static func show_info_toast(view, message: String, duration_seconds: float = 5.0) -> void:
	_ensure_info_toast(view)
	if view.info_toast_panel == null or view.info_toast_label == null:
		return
	view.info_toast_label.text = message
	var wait_time: float = maxf(0.01, duration_seconds)
	_set_info_toast_hint(view, wait_time)
	view.info_toast_panel.visible = true
	_layout_info_toast(view)
	if view.info_toast_timer != null:
		view.info_toast_timer.stop()
		view.info_toast_timer.wait_time = wait_time
		view.info_toast_timer.start()
	_update_info_toast_progress(view, 1.0)
	view.info_toast_panel.set_process(true)

static func hide_info_toast(view) -> void:
	if view.info_toast_timer != null:
		view.info_toast_timer.stop()
	if view.info_toast_panel != null:
		view.info_toast_panel.visible = false
		view.info_toast_panel.set_process(false)

# 실행: 남은 시간을 올림 처리해 "N초 뒤 사라집니다" 카피에 반영한다(기존 상수 0초 표기 결함 수정).
static func _set_info_toast_hint(view, seconds_left: float) -> void:
	if view.info_toast_hint_label == null:
		return
	var seconds := maxi(0, int(ceil(seconds_left)))
	view.info_toast_hint_label.text = TextCatalogScript.t("toast.info.auto_dismiss", [str(seconds)])

# 실행: 자동 소멸 진행 바 채움 비율을 갱신한다(1.0 = 방금 표시, 0.0 = 소멸 직전).
static func _update_info_toast_progress(view, ratio: float) -> void:
	if view.info_toast_progress_fill == null or view.info_toast_progress_track == null:
		return
	var clamped := clampf(ratio, 0.0, 1.0)
	var track_width: float = view.info_toast_progress_track.size.x
	view.info_toast_progress_fill.size = Vector2(track_width * clamped, view.info_toast_progress_track.size.y)

# 실행: 토스트가 보이는 동안 타이머 잔여 시간을 힌트와 진행 바에 반영한다.
static func tick_info_toast(view) -> void:
	if view.info_toast_panel == null or not view.info_toast_panel.visible:
		return
	if view.info_toast_timer == null or view.info_toast_timer.is_stopped():
		return
	var wait_time: float = maxf(0.01, view.info_toast_timer.wait_time)
	var time_left: float = view.info_toast_timer.time_left
	_set_info_toast_hint(view, time_left)
	_update_info_toast_progress(view, time_left / wait_time)

static func add_log(view, message: String) -> void:
	for bundle in view.page_shell_bundles.values():
		var console = bundle.get("logConsole", null)
		if console != null and console.has_method("add_log"):
			console.add_log(message)

static func update_discard_zone(view, label_text: String, is_active: bool) -> void:
	view.discard_label.text = label_text
	view.discard_zone.self_modulate = Color.WHITE if is_active else Color(0.82, 0.82, 0.82, 0.78)

# 계약: 확인 카드 카피는 TextCatalog가 SoT이며, 모드(unclaimed/discard)에 따라 제목·영문 부제·설명이 함께 바뀐다.
# 실행: 모드별 카피를 조회해 양피지 카드 라벨에 적용한다.
static func _apply_confirm_overlay_copy(view) -> void:
	var title := TextCatalogScript.t("confirm.unclaimed.title")
	var title_en := TextCatalogScript.t("confirm.unclaimed.title_en")
	var desc := TextCatalogScript.t("confirm.unclaimed.desc")
	if str(view.confirm_overlay_mode) == "discard":
		title = TextCatalogScript.t("confirm.discard.title")
		title_en = TextCatalogScript.t("confirm.discard.title_en")
		desc = TextCatalogScript.t("confirm.discard.desc", [str(view.confirm_overlay_subject)])
	_set_confirm_label_text(view, CONFIRM_TITLE_PATH, title)
	_set_confirm_label_text(view, CONFIRM_TITLE_EN_PATH, title_en)
	_set_confirm_label_text(view, CONFIRM_DESC_PATH, desc)
	view.confirm_proceed_button.text = TextCatalogScript.t("action.confirm" if str(view.confirm_overlay_mode) == "discard" else "action.proceed")
	view.confirm_cancel_button.text = TextCatalogScript.t("action.cancel")

# 계약: 확인 카드 라벨 경로 SoT — Main.tscn ConfirmOverlay 서브트리와 동기 유지 필수.
const CONFIRM_TITLE_PATH := "Center/ConfirmBox/CardMargin/CardBody/HeaderRow/TitleBox/WarningTitle"
const CONFIRM_TITLE_EN_PATH := "Center/ConfirmBox/CardMargin/CardBody/HeaderRow/TitleBox/WarningTitleEn"
const CONFIRM_DESC_PATH := "Center/ConfirmBox/CardMargin/CardBody/MessagePanel/WarningDescription"

static func _set_confirm_label_text(view, node_path: String, text: String) -> void:
	var node := view.confirm_overlay.get_node_or_null(node_path) as Label
	if node != null:
		node.text = text

# 계약: 토스트 패널 트리는 1회만 만들고 이후 렌더는 텍스트/배치만 갱신한다.
# 실행: 양피지 카드 + 원형 배지 + 제목/부제 2행 + 자동 소멸 진행 바로 구성한다.
static func _ensure_info_toast(view) -> void:
	if view.info_toast_panel != null:
		return
	var panel := ToastPanel.new()
	panel.name = "InfoToast"
	panel.visible = false
	panel.top_level = true
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.z_index = ToastRedesignThemeScript.toast_z_index(view.popup_overlay_z_index())
	panel.add_theme_stylebox_override("panel", ToastRedesignThemeScript.info_toast_style())
	panel.setup(view)
	panel.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			MainViewFeedbackRuntime.hide_info_toast(view)
	)

	var badge := TextureRect.new()
	badge.name = "ToastBadge"
	badge.texture = ToastRedesignThemeScript.BadgeTraceTexture
	badge.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	badge.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge.z_index = 1
	panel.add_child(badge)

	var label := Label.new()
	label.name = "ToastLabel"
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.z_index = 1
	label.add_theme_font_size_override("font_size", 15)
	label.add_theme_color_override("font_color", ToastRedesignThemeScript.SOIL)
	panel.add_child(label)

	var hint_label := Label.new()
	hint_label.name = "ToastHintLabel"
	hint_label.text = TextCatalogScript.t("toast.info.auto_dismiss", ["0"])
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	hint_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hint_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hint_label.z_index = 1
	hint_label.add_theme_font_size_override("font_size", 11)
	hint_label.add_theme_color_override("font_color", ToastRedesignThemeScript.OUTLINE)
	panel.add_child(hint_label)

	var track := Panel.new()
	track.name = "ToastTimerTrack"
	track.mouse_filter = Control.MOUSE_FILTER_IGNORE
	track.z_index = 1
	track.add_theme_stylebox_override("panel", ToastRedesignThemeScript.timer_track_style())
	panel.add_child(track)

	var fill := Panel.new()
	fill.name = "ToastTimerFill"
	fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fill.add_theme_stylebox_override("panel", ToastRedesignThemeScript.timer_fill_style())
	track.add_child(fill)

	var timer := Timer.new()
	timer.one_shot = true
	timer.timeout.connect(func():
		MainViewFeedbackRuntime.hide_info_toast(view)
	)
	if view.is_inside_tree():
		view.get_tree().root.add_child(panel)
		var cleanup := func() -> void:
			if is_instance_valid(panel):
				panel.queue_free()
		view.tree_exiting.connect(cleanup, CONNECT_ONE_SHOT)
	else:
		view.add_child(panel)
	view.add_child(timer)
	view.info_toast_panel = panel
	view.info_toast_label = label
	view.info_toast_hint_label = hint_label
	view.info_toast_badge = badge
	view.info_toast_progress_track = track
	view.info_toast_progress_fill = fill
	view.info_toast_timer = timer

# 계약: info 토스트는 우하단 코너 밴드에 고정 크기로 앉는다(페이지 콘텐츠 비침범 규칙).
# 실행: 뷰포트 우하단에서 코너 마진만큼 띄우고, 내부 요소를 배지 알파 외곽 기준으로 정렬한다.
static func _layout_info_toast(view) -> void:
	if view.info_toast_panel == null:
		return
	# 계약: 토스트는 top_level이므로 뷰포트 좌표계를 쓴다.
	# - 주의: view(Main)는 PanelContainer가 자식을 최소 높이로 늘려 실제 화면보다 큰 rect를 가질 수 있어
	#   view.size나 get_viewport_rect()가 아니라 root 창 크기를 SoT로 삼는다.
	var viewport_size: Vector2 = Vector2(1440, 900)
	if view.is_inside_tree():
		viewport_size = Vector2(view.get_tree().root.size)
		if viewport_size.x <= 1.0 or viewport_size.y <= 1.0:
			viewport_size = view.get_viewport_rect().size
	if viewport_size.x <= 1.0 or viewport_size.y <= 1.0:
		viewport_size = Vector2(1440, 900)
	var toast_size: Vector2 = ToastRedesignThemeScript.INFO_TOAST_SIZE
	view.info_toast_panel.size = toast_size
	# 실행: 내러티브 토스트가 아래 칸을 쓰므로 info 토스트는 스택 위 칸에 앉는다.
	var stack_offset: float = ToastRedesignThemeScript.NARRATIVE_TOAST_SIZE.y + ToastRedesignThemeScript.STACK_GAP
	view.info_toast_panel.global_position = Vector2(
		viewport_size.x - toast_size.x - ToastRedesignThemeScript.CORNER_MARGIN.x,
		viewport_size.y - toast_size.y - ToastRedesignThemeScript.CORNER_MARGIN.y - stack_offset
	)

	# 실행: 배지는 가시 원 외곽(알파 경계)이 40px 슬롯과 맞도록 렌더 사각형을 역보정한다.
	var badge_slot := 40.0
	var badge_origin := Vector2(22.0, (toast_size.y - badge_slot) * 0.5)
	if view.info_toast_badge != null:
		var rect: Rect2 = ToastRedesignThemeScript.badge_visual_rect(view.info_toast_badge.texture, badge_slot)
		view.info_toast_badge.position = badge_origin + rect.position
		view.info_toast_badge.size = rect.size

	var text_left := badge_origin.x + badge_slot + 14.0
	var text_width := toast_size.x - text_left - 20.0
	if view.info_toast_label != null:
		view.info_toast_label.position = Vector2(text_left, 18.0)
		view.info_toast_label.size = Vector2(text_width, 21.0)
	if view.info_toast_hint_label != null:
		view.info_toast_hint_label.position = Vector2(text_left, 41.0)
		view.info_toast_hint_label.size = Vector2(text_width, 16.0)
	if view.info_toast_progress_track != null:
		# 실행: accent 바(6px) 우측부터 카드 라운드 안쪽까지 인셋.
		view.info_toast_progress_track.position = Vector2(8.0, toast_size.y - 6.0)
		view.info_toast_progress_track.size = Vector2(toast_size.x - 12.0, 3.0)
		if view.info_toast_progress_fill != null:
			view.info_toast_progress_fill.position = Vector2.ZERO
			view.info_toast_progress_fill.size = view.info_toast_progress_track.size

# 계약: 토스트 패널은 표시 중에만 타이머 잔여 시간을 폴링해 힌트/진행 바를 갱신한다.
# 실행: Panel을 상속해 _process에서 소유 view의 tick 함수를 호출한다.
class ToastPanel extends Panel:
	var _owner_view = null

	func setup(owner_view) -> void:
		_owner_view = owner_view
		set_process(false)

	func _process(_delta: float) -> void:
		if _owner_view == null or not is_instance_valid(_owner_view):
			set_process(false)
			return
		MainViewFeedbackRuntime.tick_info_toast(_owner_view)

static func get_cell_global_pos(view, cell_id: String) -> Vector2:
	var hit_pos = view.global_position + view.size / 2
	for child in view.battlefield_ui.battlefield_grid.get_children():
		if child is CellView and child.cell_id == cell_id:
			hit_pos = child.global_position + child.size / 2
			break
	return hit_pos

static func get_extractor_global_pos(view) -> Vector2:
	return view.status_panel.extractor_visual.global_position + view.status_panel.extractor_visual.size / 2

static func get_health_bar_global_pos(view) -> Vector2:
	return view.status_panel.health_bar.global_position + Vector2(view.status_panel.health_bar.size.x * 0.58, -4.0)

static func get_shield_bar_global_pos(view) -> Vector2:
	return view.status_panel.shield_bar.global_position + Vector2(view.status_panel.shield_bar.size.x * 0.58, -4.0)

static func get_timer_global_pos(view) -> Vector2:
	return view.status_panel.combat_timer_label.global_position + Vector2(view.status_panel.combat_timer_label.size.x * 0.5, -4.0)

static func get_purple_status_global_pos(view) -> Vector2:
	return view.status_panel.purple_status_value.global_position + Vector2(view.status_panel.purple_status_value.size.x * 0.5, -4.0)

static func trigger_resonance_beam(view, start_pos: Vector2, hit_pos: Vector2, color: String) -> void:
	view.vfx_manager.draw_resonance_beam(start_pos, hit_pos, color)

static func trigger_hit_particles(view, hit_pos: Vector2, status: String, color: String) -> void:
	view.vfx_manager.spawn_hit_particles(hit_pos, status, color)

static func trigger_damage_popups(view, events: Array) -> void:
	if events.is_empty():
		return
	var anchored_events: Array = []
	for event in events:
		if not event is Dictionary:
			continue
		var popup: Dictionary = event.duplicate(true)
		var channel := str(popup.get("channel", ""))
		popup["origin"] = get_shield_bar_global_pos(view) if channel == "shield" else get_health_bar_global_pos(view)
		anchored_events.append(popup)
	view.vfx_manager.spawn_damage_popups(anchored_events)

static func trigger_obstacle_feedback(view, events: Array) -> void:
	if events.is_empty():
		return
	var popup_events: Array = []
	for event in events:
		if not event is Dictionary:
			continue
		var family := str(event.get("family", ""))
		if view.battlefield_ui != null and view.battlefield_ui.has_method("trigger_obstacle_flash"):
			view.battlefield_ui.trigger_obstacle_flash(family)
		if not bool(event.get("popup", true)):
			continue
		var popup: Dictionary = event.duplicate(true)
		match str(popup.get("channel", "")):
			"timer":
				popup["origin"] = get_timer_global_pos(view)
			"purple_debuff":
				popup["origin"] = get_purple_status_global_pos(view)
			_:
				popup["origin"] = get_health_bar_global_pos(view)
		popup_events.append(popup)
	if not popup_events.is_empty():
		view.vfx_manager.spawn_obstacle_feedback(popup_events)

static func trigger_screenshake(view, duration: float, magnitude: float) -> void:
	view.vfx_manager.trigger_screenshake(duration, magnitude, view)
