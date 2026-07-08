extends SceneTree

const VIEWPORT_SIZE := Vector2i(1440, 900)

const CharacterSelectViewBitsScript = preload("res://src/scenes/pages/character_select/CharacterSelectViewBits.gd")

var failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	root.size = VIEWPORT_SIZE
	var main_scene := load("res://src/Main.tscn") as PackedScene
	_assert(main_scene != null, "main scene resource loads for character select visual style contract")
	if main_scene == null:
		await _finish()
		return
	var main_instance := main_scene.instantiate()
	root.add_child(main_instance)
	await _settle_frames(4)
	if str(main_instance.get("active_page_id")) == "story_scene":
		await _advance_story_if_present(main_instance, "character_select")
		await _settle_frames(4)
	_assert_eq(str(main_instance.get("active_page_id")), "character_select", "visual style contract reaches character select")
	var page := main_instance.get("character_select_page") as Control
	_assert(page != null, "character select page exists for visual style contract")
	if page != null:
		_assert_visual_targets(page)
	main_instance.queue_free()
	await process_frame
	await _finish()

func _assert_visual_targets(page: Control) -> void:
	var top_bar := page.get_node_or_null("TopBar") as PanelContainer
	var stage := page.get_node_or_null("Stage") as Control
	var hero_bg := page.get_node_or_null("Stage/HeroBg") as TextureRect
	var roster_rail := page.get_node_or_null("Stage/RosterRail") as PanelContainer
	var wing := page.get_node_or_null("Stage/Wing") as PanelContainer
	var hero_char := page.get_node_or_null("Stage/HeroChar") as TextureRect
	var continue_button := page.get_node_or_null("Stage/Wing/WingMargin/WingVBox/CtaDock/ContinueButton") as Button
	var selected_roster := page.get_node_or_null("Stage/RosterRail/RosterMargin/RosterVBox/RosterScroll/RosterList/CharacterChoice_miner") as Button
	var starter_item := page.get_node_or_null("Stage/Wing/WingMargin/WingVBox/BagSection/StarterItemList/StarterItem_starter_red_drill") as Button

	_assert(top_bar != null, "character visual contract keeps the shared top bar owner")
	_assert(stage != null, "Stage container exists")
	_assert(hero_bg != null, "HeroBg fullscreen background exists")
	_assert(hero_bg != null and hero_bg.texture != null, "HeroBg has a loaded texture")
	_assert(roster_rail != null, "RosterRail exists for dark themed roster")
	_assert(wing != null, "Glassmorphism Wing exists")

	# Roster-rail should be dark — now a horizontal gradient texture that fades to reveal the scene
	if roster_rail != null:
		var roster_style := roster_rail.get_theme_stylebox("panel")
		_assert(roster_style != null, "roster rail exposes a panel stylebox")
		if roster_style is StyleBoxFlat:
			_assert(_luminance((roster_style as StyleBoxFlat).bg_color) < 0.15, "roster rail uses a dark background for glassmorphism redesign")
		else:
			_assert(roster_style is StyleBoxTexture, "roster rail uses a gradient texture backing that reveals the scene image")

	# Wing should be a frosted glass panel — translucent enough to read as glass but opaque enough to be legible
	if wing != null:
		var wing_style := wing.get_theme_stylebox("panel") as StyleBoxFlat
		_assert(wing_style != null, "wing exposes a panel StyleBoxFlat")
		if wing_style != null:
			_assert(wing_style.bg_color.a < 0.90, "wing keeps a translucent frosted-glass background")
			_assert(wing_style.corner_radius_top_left >= 12, "wing has rounded corners")

	# Continue button — ornate frame image (transparent chrome) with a firefly overlay
	if continue_button != null:
		var cta_frame := continue_button.get_node_or_null("CtaFrameBg") as TextureRect
		_assert(cta_frame != null and cta_frame.texture != null, "continue button uses the ornate CTA frame image")
		var cta_fireflies := continue_button.get_node_or_null("CtaFireflies") as Control
		_assert(cta_fireflies != null and cta_fireflies.get_child_count() > 0, "continue button owns firefly hover motes")

	# Roster card — dark card style
	_assert(selected_roster != null, "selected roster card exists in RosterRail")
	if selected_roster != null:
		var roster_card_style := CharacterSelectViewBitsScript.card_visual_style(selected_roster)
		_assert(roster_card_style != null, "roster card exposes a visual card StyleBoxFlat")
		if roster_card_style != null:
			# alpha-weighted luminance: the card sits on a dark rail so effective brightness is low
			var effective_lum := _luminance(roster_card_style.bg_color) * roster_card_style.bg_color.a
			_assert(effective_lum < 0.40, "roster card uses a dark surface for the dark rail theme")
			_assert(roster_card_style.shadow_size == 0, "roster card avoids dirty shadow fill")
			# Sharp rectangle — no rounded corners (mockup requirement)
			_assert(roster_card_style.corner_radius_top_left == 0, "roster card uses sharp square corners")
		_assert_button_hover_contract(selected_roster, "selected roster card")
		_assert_button_has_texture(selected_roster, "selected roster card uses a small portrait image")

	# Starter item card — ornate frame image + centered icon, scale-based hover
	_assert(starter_item != null, "starter item card exists in Wing")
	if starter_item != null:
		var frame_bg := starter_item.get_node_or_null("CardFrame/FrameBg") as TextureRect
		_assert(frame_bg != null and frame_bg.texture != null, "starter item card uses the ornate frame image")
		_assert_button_has_texture(starter_item, "starter item card uses the runtime drill/beacon icon image")

func _assert_button_hover_contract(button: Button, label: String) -> void:
	_assert(button != null, "%s exists for hover contract" % label)
	if button == null:
		return
	_assert(bool(button.get_meta("_ltl_skip_interaction_fx", false)), "%s opts out of global scale hover that clips rounded borders" % label)
	var frame := button.get_node_or_null("CardFrame") as Control
	_assert(frame != null, "%s owns an inset visual frame" % label)
	if frame == null:
		return
	var normal_left := frame.offset_left
	button.mouse_entered.emit()
	_assert(frame.offset_left <= normal_left, "%s expands the visual frame toward the outer bounds on hover instead of scaling past them" % label)
	_assert(button.scale.x <= 1.0 and button.scale.y <= 1.0, "%s does not enlarge the button scale on hover" % label)

func _assert_button_has_texture(button: Button, label: String) -> void:
	_assert(button != null, label)
	if button == null:
		return
	var found := false
	var stack: Array[Node] = [button]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		if node is TextureRect and (node as TextureRect).texture != null:
			found = true
		for child in node.get_children():
			stack.append(child)
	_assert(found, label)

func _luminance(color: Color) -> float:
	return (0.2126 * color.r) + (0.7152 * color.g) + (0.0722 * color.b)

func _green_dominant(color: Color) -> bool:
	return color.g >= color.r and color.g >= color.b

func _advance_story_if_present(main_instance: Node, return_page_id: String) -> void:
	if str(main_instance.get("active_page_id")) != "story_scene":
		return
	var story_page = main_instance.get("story_scene_page")
	var controller = main_instance.get_node_or_null("MainController")
	_assert(story_page != null, "story scene page exists during visual-style handoff")
	_assert(controller != null, "main controller exists during visual-style handoff")
	if story_page == null or controller == null:
		return
	var story: Dictionary = controller.get("active_story_scene")
	var scene_id := str(story.get("id", ""))
	_assert(not scene_id.is_empty(), "story scene exposes an active scene id during visual-style handoff")
	if scene_id.is_empty():
		return
	story_page.continue_requested.emit(scene_id)
	await process_frame
	story_page.continue_requested.emit(scene_id)
	await process_frame
	_assert_eq(str(main_instance.get("active_page_id")), return_page_id, "story scene returns to %s during visual style contract" % return_page_id)

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
		print("CHARACTER_SELECT_VISUAL_STYLE_CONTRACT_OK")
		await process_frame
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	await process_frame
	quit(1)
