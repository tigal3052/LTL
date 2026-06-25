extends SceneTree

const VIEWPORT_SIZE := Vector2i(1440, 900)
const InteractionFXScript = preload("res://src/ui/InteractionFX.gd")
const META_SFX_CATEGORY := "_ltl_interaction_sfx_category"
const META_INSTALLED := "_ltl_interaction_fx_installed"
const META_SKIP := "_ltl_skip_interaction_fx"
const META_SFX_CALLBACK := "_ltl_interaction_sfx_callback"

var failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	root.size = VIEWPORT_SIZE
	await _assert_character_select_starter_sfx_and_cache()
	await _assert_reward_reveal_sfx_milestones()
	await _assert_story_page_typewriter_sfx()
	await _assert_narrative_toast_typewriter_sfx()
	await _assert_invalid_placement_info_toast_auto_hides()
	await _finish()

func _assert_character_select_starter_sfx_and_cache() -> void:
	var main_scene := load("res://src/Main.tscn") as PackedScene
	_assert(main_scene != null, "main scene loads for starter-set interaction audio contract")
	if main_scene == null:
		return
	var main_instance := main_scene.instantiate()
	root.add_child(main_instance)
	await _settle_frames(5)
	var character_page := main_instance.get("character_select_page") as Control
	_assert(character_page != null, "character select page exists for starter-set interaction audio contract")
	if character_page == null:
		main_instance.queue_free()
		await process_frame
		return
	_assert_main_buttons_have_generic_sfx(main_instance)
	_assert(character_page.has_method("starter_drill_preview_cache_size"), "character select exposes starter drill preview cache size for performance guard")
	var palette_blue := _palette_button(character_page, "blue")
	var palette_red := _palette_button(character_page, "red")
	_assert(palette_blue != null, "blue starter-set button exists")
	_assert(palette_red != null, "red starter-set button exists")
	if palette_blue != null:
		_assert_eq(str(palette_blue.get_meta(META_SFX_CATEGORY, "")), "starter_set_select", "starter-set buttons carry the semantic selection SFX category")
		_emit_left_press(palette_blue)
		await process_frame
		_assert(_sfx_events_include(main_instance, "starter_set_select"), "starter-set mouse press records starter_set_select audio")
	if character_page.has_method("_select_palette_color"):
		character_page.call("_select_palette_color", "red")
		await _settle_frames(4)
	var initial_red_texture := _starter_drill_texture(character_page)
	var initial_red_path := _starter_drill_texture_path(character_page)
	if character_page.has_method("_select_palette_color"):
		character_page.call("_select_palette_color", "blue")
		await _settle_frames(4)
	var after_blue_path := _starter_drill_texture_path(character_page)
	if character_page.has_method("_select_palette_color"):
		character_page.call("_select_palette_color", "red")
		await _settle_frames(4)
	var red_texture_after_round_trip := _starter_drill_texture(character_page)
	var final_red_path := _starter_drill_texture_path(character_page)
	_assert(initial_red_texture != null, "initial red starter drill texture exists")
	_assert(red_texture_after_round_trip != null, "red starter drill texture exists after color round trip")
	_assert(initial_red_texture == red_texture_after_round_trip, "starter drill preview reuses cached display textures instead of rescanning the image on every color click")
	if character_page.has_method("starter_drill_preview_cache_size"):
		var cache_size := int(character_page.call("starter_drill_preview_cache_size"))
		_assert(cache_size >= 2, "starter drill preview cache keeps at least the viewed red and blue textures, got %d with paths %s -> %s -> %s" % [cache_size, initial_red_path, after_blue_path, final_red_path])
	main_instance.queue_free()
	await process_frame

func _assert_reward_reveal_sfx_milestones() -> void:
	var overlay_script = load("res://src/ui/RewardRevealOverlay.gd")
	_assert(overlay_script != null, "reward reveal overlay loads for ceremony SFX milestone contract")
	if overlay_script == null:
		return
	var overlay = overlay_script.new()
	var heard: Array[String] = []
	_assert(overlay.has_signal("interaction_sfx_requested"), "reward reveal overlay exposes interaction_sfx_requested signal")
	if overlay.has_signal("interaction_sfx_requested"):
		overlay.interaction_sfx_requested.connect(func(category: String) -> void:
			heard.append(category)
		)
	root.add_child(overlay)
	await process_frame
	overlay.start_reveal([{"kind": "Test Relic", "rarity": "rare", "payload": {"item_type": "relic"}}], Callable(), Callable())
	_assert("reward_expectation" in heard, "reward ceremony starts with an expectation-building reward cue")
	overlay.call("_enter_step", "count_lock")
	_assert("reward_count_fanfare" in heard, "reward count reveal emits a reward-count fanfare")
	overlay.call("_enter_step", "reveal_queue")
	_assert("excavation_buildup" in heard, "excavation result reveal starts a buildup cue while the progress bar fills")
	overlay.call("_complete_current_step_animation")
	_assert("excavation_detail_fanfare" in heard, "excavation detail reveal emits its own fanfare")
	overlay.queue_free()
	await process_frame

func _assert_story_page_typewriter_sfx() -> void:
	var story_scene := load("res://src/scenes/pages/StoryScenePage.tscn") as PackedScene
	_assert(story_scene != null, "story scene page loads for typewriter audio contract")
	if story_scene == null:
		return
	var page := story_scene.instantiate() as Control
	var heard: Array[String] = []
	_assert(page.has_signal("interaction_sfx_requested"), "story scene page exposes interaction_sfx_requested signal")
	if page.has_signal("interaction_sfx_requested"):
		page.interaction_sfx_requested.connect(func(category: String) -> void:
			heard.append(category)
		)
	root.add_child(page)
	await process_frame
	page.apply_state({"visible": true, "sceneId": "contract_story", "speaker": "Guide", "text": "ABCD", "stepIndex": 0, "stepCount": 1, "continueText": "Next", "skipText": "Skip"})
	var body_label := page.get_node_or_null("DialoguePanel/DialogueMargin/DialogueBox/BodyLabel") as Label
	_assert(body_label != null, "story scene body label exists")
	_assert(body_label == null or int(body_label.visible_characters) == 0, "story scene starts by hiding dialogue text for typewriter reveal")
	_assert(page.has_method("advance_typewriter_for_test"), "story scene exposes a deterministic typewriter advance helper for contract tests")
	if page.has_method("advance_typewriter_for_test"):
		page.call("advance_typewriter_for_test", 0.12)
	_assert(body_label == null or int(body_label.visible_characters) > 0, "story scene typewriter advance reveals characters incrementally")
	_assert("typewriter_tick" in heard, "story scene typewriter reveal emits typing ticks")
	var continue_button := page.get_node_or_null("DialoguePanel/DialogueMargin/DialogueBox/ButtonRow/ContinueButton") as Button
	if continue_button != null:
		continue_button.pressed.emit()
		await process_frame
	_assert("dialogue_advance" in heard, "story scene continue click emits dialogue advance audio")
	page.queue_free()
	await process_frame

func _assert_narrative_toast_typewriter_sfx() -> void:
	var toast_script = load("res://src/scenes/narrative/NarrativeToast.gd")
	_assert(toast_script != null, "narrative toast script loads for typewriter audio contract")
	if toast_script == null:
		return
	var toast = toast_script.new()
	var heard: Array[String] = []
	_assert(toast.has_signal("interaction_sfx_requested"), "narrative toast exposes interaction_sfx_requested signal")
	if toast.has_signal("interaction_sfx_requested"):
		toast.interaction_sfx_requested.connect(func(category: String) -> void:
			heard.append(category)
		)
	root.add_child(toast)
	await process_frame
	toast.render({"visible": true, "beatId": "contract_beat", "speaker": "Guide", "text": "ABCD", "continuePrompt": "Next", "skipInputAllowed": true})
	_assert(toast.body_label != null, "narrative toast body label exists")
	_assert(toast.body_label == null or int(toast.body_label.visible_characters) == 0, "narrative toast starts by hiding dialogue text for typewriter reveal")
	_assert(toast.has_method("advance_typewriter_for_test"), "narrative toast exposes a deterministic typewriter advance helper for contract tests")
	if toast.has_method("advance_typewriter_for_test"):
		toast.call("advance_typewriter_for_test", 0.12)
	_assert(toast.body_label == null or int(toast.body_label.visible_characters) > 0, "narrative toast typewriter advance reveals characters incrementally")
	_assert("typewriter_tick" in heard, "narrative toast typewriter reveal emits typing ticks")
	toast.dismiss()
	_assert("dialogue_advance" in heard, "narrative toast dismiss emits dialogue advance audio")
	toast.queue_free()
	await process_frame

func _assert_invalid_placement_info_toast_auto_hides() -> void:
	var main_scene := load("res://src/Main.tscn") as PackedScene
	_assert(main_scene != null, "main scene loads for invalid-placement toast contract")
	if main_scene == null:
		return
	var main_instance := main_scene.instantiate()
	root.add_child(main_instance)
	await _settle_frames(5)
	_assert(main_instance.has_method("show_info_toast"), "main view exposes a reusable info toast API")
	if main_instance.has_method("show_info_toast"):
		main_instance.call("show_info_toast", "Cannot place there", 5.0)
		await process_frame
		var panel = main_instance.get("info_toast_panel") as Control
		var label = main_instance.get("info_toast_label") as Label
		var hint_label = main_instance.get("info_toast_hint_label") as Label
		var timer = main_instance.get("info_toast_timer") as Timer
		_assert(panel != null, "info toast panel is created on demand")
		_assert(label != null, "info toast label is created on demand")
		_assert(hint_label != null, "info toast lower countdown hint is created on demand")
		_assert(timer != null, "info toast timer is created on demand")
		if panel != null:
			_assert_eq(bool(panel.visible), true, "info toast is visible immediately after placement warning")
			var toast_rect := panel.get_global_rect()
			var toast_center := toast_rect.position + toast_rect.size * 0.5
			_assert(toast_rect.size.x <= 620.0 and toast_rect.size.y <= 120.0, "info toast uses a compact centered size instead of covering the screen, got %s" % str(toast_rect))
			_assert(absf(toast_center.x - float(VIEWPORT_SIZE.x) * 0.5) <= 12.0, "info toast is centered horizontally, got %s" % str(toast_rect))
			_assert(absf(toast_center.y - float(VIEWPORT_SIZE.y) * 0.5) <= 20.0, "info toast is centered vertically, got %s" % str(toast_rect))
			_assert_eq(int(panel.mouse_filter), int(Control.MOUSE_FILTER_STOP), "info toast receives clicks so it can dismiss immediately")
			if label != null:
				_assert(toast_rect.encloses(label.get_global_rect()), "info toast warning label stays inside the compact toast, got %s inside %s" % [str(label.get_global_rect()), str(toast_rect)])
			if hint_label != null:
				_assert(toast_rect.encloses(hint_label.get_global_rect()), "info toast hint label stays inside the compact toast, got %s inside %s" % [str(hint_label.get_global_rect()), str(toast_rect)])
		if label != null:
			_assert_eq(str(label.text), "Cannot place there", "info toast displays the placement warning text")
		if hint_label != null:
			_assert_eq(str(hint_label.text), "0초 뒤 사라집니다.", "info toast shows the requested lower dismissal hint")
		if timer != null:
			_assert(absf(float(timer.wait_time) - 5.0) <= 0.01, "info toast uses a 5 second default placement-warning lifetime")
		if panel != null:
			_emit_left_press(panel)
			await process_frame
			_assert_eq(bool(panel.visible), false, "info toast hides immediately when clicked")
		main_instance.call("show_info_toast", "Quick warning", 0.02)
		await create_timer(0.08).timeout
		if panel != null:
			_assert_eq(bool(panel.visible), false, "info toast automatically hides after its timer")
	main_instance.queue_free()
	await process_frame

func _palette_button(character_page: Control, color: String) -> Button:
	return character_page.get_node_or_null("Margin/VStack/BoardShell/ShellMargin/ShellVBox/BoardBody/PrepZone/ZoneMargin/ZoneVBox/PrepColumn/PaletteCard/PaletteMargin/PaletteVBox/PaletteScroll/PaletteList/Palette_%s" % color) as Button

func _starter_drill_texture(character_page: Control) -> Texture2D:
	var image := character_page.get_node_or_null("Margin/VStack/BoardShell/ShellMargin/ShellVBox/BoardBody/PrepZone/ZoneMargin/ZoneVBox/PrepColumn/BagCard/BagMargin/BagVBox/MiniBag/Slot1/ItemImage") as TextureRect
	return image.texture if image != null else null

func _starter_drill_texture_path(character_page: Control) -> String:
	var image := character_page.get_node_or_null("Margin/VStack/BoardShell/ShellMargin/ShellVBox/BoardBody/PrepZone/ZoneMargin/ZoneVBox/PrepColumn/BagCard/BagMargin/BagVBox/MiniBag/Slot1/ItemImage") as TextureRect
	return str(image.get_meta("drill_texture_path", "")) if image != null else ""

func _emit_left_press(control: Control) -> void:
	var click_event := InputEventMouseButton.new()
	click_event.button_index = MOUSE_BUTTON_LEFT
	click_event.pressed = true
	click_event.position = control.size * 0.5
	control.emit_signal("gui_input", click_event)

func _sfx_events_include(main_instance: Node, category: String) -> bool:
	var events: Array = main_instance.get("interaction_sfx_events")
	for event in events:
		if event is Dictionary and str(event.get("category", "")) == category:
			return true
	return false

func _assert_main_buttons_have_generic_sfx(root_node: Node) -> void:
	var missing: Array[String] = []
	_collect_buttons_missing_generic_sfx(root_node, missing)
	_assert(missing.is_empty(), "all non-skip runtime buttons have generic interaction SFX installed; missing %s" % ", ".join(missing.slice(0, 8)))

func _collect_buttons_missing_generic_sfx(node: Node, missing: Array[String]) -> void:
	if node is Button and not bool(node.get_meta(META_SKIP, false)):
		var installed := bool(node.get_meta(META_INSTALLED, false))
		var callback: Callable = node.get_meta(META_SFX_CALLBACK, Callable())
		if not installed or callback.is_null():
			missing.append(str(node.get_path()))
	for child in node.get_children():
		_collect_buttons_missing_generic_sfx(child, missing)

func _settle_frames(count: int) -> void:
	for _index in range(count):
		await process_frame

func _assert(condition: bool, label: String) -> void:
	if not condition:
		failures.append(label)

func _assert_eq(actual: Variant, expected: Variant, label: String) -> void:
	if actual != expected:
		failures.append("%s: expected %s, got %s" % [label, str(expected), str(actual)])

func _finish() -> void:
	if failures.is_empty():
		print("INTERACTION_AUDIO_RUNTIME_CONTRACT_OK")
		await process_frame
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	await process_frame
	quit(1)
