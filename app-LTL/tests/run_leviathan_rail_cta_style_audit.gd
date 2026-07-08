extends SceneTree

const VIEWPORT_SIZE := Vector2i(1440, 900)
const CARD_HEIGHT_MAX := 144.0
const CARD_HEIGHT_MIN := 126.0
const CTA_HEIGHT_MAX := 108.0
const CTA_HEIGHT_MIN := 96.0

var failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	root.size = VIEWPORT_SIZE
	var main_scene := load("res://src/Main.tscn") as PackedScene
	_assert(main_scene != null, "main scene loads for leviathan rail/cta style audit")
	if main_scene == null:
		_finish()
		return
	await _assert_style_contract(main_scene)
	_finish()

func _assert(condition: bool, label: String) -> void:
	if not condition:
		failures.append(label)

func _assert_close(actual: float, expected: float, tolerance: float, label: String) -> void:
	if absf(actual - expected) > tolerance:
		failures.append("%s: expected %.3f ± %.3f, got %.3f" % [label, expected, tolerance, actual])

func _finish() -> void:
	if failures.is_empty():
		print("LEVIATHAN_RAIL_CTA_STYLE_AUDIT_OK")
		call_deferred("quit", 0)
		return
	for failure in failures:
		push_error(failure)
	call_deferred("quit", 1)

func _advance_story_if_present(main_instance: Node, return_page_id: String) -> void:
	if str(main_instance.get("active_page_id")) != "story_scene":
		return
	var story_page = main_instance.get("story_scene_page")
	var controller = main_instance.get_node_or_null("MainController")
	_assert(story_page != null, "story scene exists during rail/cta style audit")
	_assert(controller != null, "main controller exists during rail/cta style audit story handoff")
	if story_page == null or controller == null:
		return
	var story: Dictionary = controller.get("active_story_scene")
	var scene_id := str(story.get("id", ""))
	_assert(not scene_id.is_empty(), "story scene exposes a scene id during rail/cta style audit")
	if scene_id.is_empty():
		return
	story_page.continue_requested.emit(scene_id)
	await process_frame
	story_page.continue_requested.emit(scene_id)
	await process_frame
	await process_frame
	_assert(str(main_instance.get("active_page_id")) == return_page_id, "story scene returns to %s for rail/cta style audit" % return_page_id)

func _instantiate_main(main_scene: PackedScene) -> Node:
	var main_instance := main_scene.instantiate()
	root.add_child(main_instance)
	await process_frame
	await process_frame
	return main_instance

func _go_to_leviathan_select(main_instance: Node) -> Node:
	await _advance_story_if_present(main_instance, "character_select")
	var character_page = main_instance.get("character_select_page")
	_assert(character_page != null, "character select page exists before rail/cta style audit")
	if character_page == null:
		return null
	character_page.color_selected.emit("purple")
	character_page.continue_requested.emit()
	await process_frame
	await process_frame
	await process_frame
	_assert(str(main_instance.get("active_page_id")) == "leviathan_select", "character select advances to leviathan select for rail/cta style audit")
	return main_instance.get("leviathan_select_page")

func _collect_label_texts(node: Node) -> Array[String]:
	var results: Array[String] = []
	for child in node.get_children():
		if child is Label:
			results.append((child as Label).text)
		results.append_array(_collect_label_texts(child))
	return results

func _card_buttons(cards_box: Node) -> Array[Button]:
	var buttons: Array[Button] = []
	for child in cards_box.get_children():
		if child is Button:
			buttons.append(child as Button)
	return buttons

func _assert_style_contract(main_scene: PackedScene) -> void:
	var main_instance := await _instantiate_main(main_scene)
	var page = await _go_to_leviathan_select(main_instance)
	_assert(page != null, "leviathan select page exists for rail/cta style audit")
	if page == null:
		main_instance.queue_free()
		await process_frame
		return
	await process_frame
	await process_frame
	var overlay_rail := page.get_node_or_null("WorkspaceMargin/Workspace/HeroShell/OverlayRail") as PanelContainer
	var hero_shell := page.get_node_or_null("WorkspaceMargin/Workspace/HeroShell") as Control
	var top_bar := page.get_node_or_null("TopBar") as Control
	var cards_scroll := page.get_node_or_null("WorkspaceMargin/Workspace/HeroShell/OverlayRail/OverlayVBox/CardsScroll") as ScrollContainer
	var cards_box := page.get_node_or_null("WorkspaceMargin/Workspace/HeroShell/OverlayRail/OverlayVBox/CardsScroll/CardsVBox") as VBoxContainer
	var start_button_frame := page.get_node_or_null("WorkspaceMargin/Workspace/HeroShell/OverlayRail/OverlayVBox/StartButtonFrame") as MarginContainer
	var start_button := page.get_node_or_null("WorkspaceMargin/Workspace/HeroShell/OverlayRail/OverlayVBox/StartButtonFrame/StartButton") as Button
	_assert(hero_shell != null and top_bar != null and overlay_rail != null and cards_scroll != null and cards_box != null and start_button_frame != null and start_button != null, "rail/cta nodes exist for style audit")
	if hero_shell == null or top_bar == null or overlay_rail == null or cards_scroll == null or cards_box == null or start_button_frame == null or start_button == null:
		main_instance.queue_free()
		await process_frame
		return
	_assert(absf(hero_shell.get_global_rect().position.y - top_bar.get_global_rect().end.y) <= 1.5, "hero shell starts directly under the top bar without a blue top gutter")
	_assert(absf(hero_shell.get_global_rect().end.y - float(VIEWPORT_SIZE.y)) <= 1.5, "hero shell reaches the viewport bottom without a blue bottom gutter")
	_assert(absf(hero_shell.get_global_rect().end.x - float(VIEWPORT_SIZE.x)) <= 1.5, "hero shell reaches the viewport right edge without a blue outer gutter")
	_assert(absf(overlay_rail.get_global_rect().end.x - float(VIEWPORT_SIZE.x)) <= 1.5, "overlay rail reaches the viewport right edge without a blue outer gutter")
	var overlay_style := overlay_rail.get_theme_stylebox("panel") as StyleBoxFlat
	var rail_blend := overlay_rail.get_node_or_null("RailBlend") as TextureRect
	_assert(overlay_style != null, "overlay rail stylebox exists for style audit")
	if overlay_style != null:
		_assert(overlay_style.corner_radius_top_left == 0 and overlay_style.corner_radius_top_right == 0 and overlay_style.corner_radius_bottom_left == 0 and overlay_style.corner_radius_bottom_right == 0, "overlay rail keeps square edge corners instead of rounded outer corners")
		_assert(overlay_style.shadow_size == 0, "overlay rail keeps edge-flush styling without floating shadow")
		_assert(overlay_style.bg_color.a <= 0.02, "overlay rail background stays transparent so the hero field can blend under the rail instead of forming a hard sidebar slab")
	_assert(rail_blend != null, "overlay rail installs a named blend layer so the hero field can fade under the rail instead of stopping at a hard seam")
	if rail_blend != null:
		_assert(rail_blend.texture != null, "overlay rail blend layer exposes a texture-backed fade instead of an empty placeholder node")
		_assert(absf(rail_blend.get_global_rect().position.x - overlay_rail.get_global_rect().position.x) <= 1.0 and absf(rail_blend.get_global_rect().end.x - overlay_rail.get_global_rect().end.x) <= 1.0, "overlay rail blend layer spans the full rail width for seam-free overlap")
		_assert(overlay_rail.get_child(0) == rail_blend, "overlay rail blend layer stays behind the cards/cta stack instead of covering the interactive chrome")
	var cta_style := start_button.get_theme_stylebox("normal") as StyleBoxFlat
	_assert(cta_style != null, "cta stylebox exists for style audit")
	if cta_style != null:
		_assert(cta_style.corner_radius_top_left == 0 and cta_style.corner_radius_top_right == 0 and cta_style.corner_radius_bottom_left == 0 and cta_style.corner_radius_bottom_right == 0, "cta keeps square edge corners instead of rounded outer corners")
		_assert(cta_style.shadow_size == 0, "cta keeps edge-flush styling without floating shadow")
		_assert(cta_style.border_width_left >= 1 and cta_style.border_width_top >= 1 and cta_style.border_width_right >= 1 and cta_style.border_width_bottom >= 1, "cta keeps a full outer border instead of leaving one edge open")
		_assert(cta_style.border_color.a >= 0.72, "cta keeps a strong visible green outer border across the full dock")
	_assert(absf(start_button_frame.get_global_rect().position.x - overlay_rail.get_global_rect().position.x) <= 1.5, "cta frame starts flush with the rail edge instead of leaving a left gutter")
	var scroll_bar := cards_scroll.get_v_scroll_bar()
	_assert(scroll_bar != null, "rail scroll bar node exists for hidden-scroll audit")
	if scroll_bar != null:
		_assert(not scroll_bar.visible, "rail scroll stays functional without exposing a visible scrollbar chrome")
	var card_buttons := _card_buttons(cards_box)
	_assert(card_buttons.size() >= 4, "leviathan roster renders enough cards for rail style audit")
	if not card_buttons.is_empty():
		var first_card := card_buttons[0]
		_assert(str(first_card.get_meta("rail_card_visual_family", "")) == "overlay-rail-shared-shell-v1", "real rail cards use the shared visual-shell owner instead of a page-local ad-hoc shell")
		var first_height := first_card.get_global_rect().size.y
		_assert(first_height >= CARD_HEIGHT_MIN and first_height <= CARD_HEIGHT_MAX, "rail cards stay compact like the approved strip instead of using tall hero-card heights (height=%.2f)" % first_height)
		var first_texts := _collect_label_texts(first_card)
		_assert(not first_texts.has("현재 선택") and not first_texts.has("미선택") and not first_texts.has("CURRENT") and not first_texts.has("AVAILABLE"), "approved rail cards remove the old explicit selected/available state pills")
		_assert(first_card.get_node_or_null("CardVisualRoot") != null, "real rail cards expose a named shared visual root for the card shell")
		_assert(first_card.get_node_or_null("CardVisualRoot/CardArt") != null, "real rail cards expose a named art layer inside the shared card shell")
		_assert(first_card.get_node_or_null("CardVisualRoot/CardVeil") != null, "real rail cards expose a named veil layer inside the shared card shell")
		_assert(first_card.get_node_or_null("CardVisualRoot/CardContentMargin") != null, "real rail cards expose a named content margin inside the shared card shell")
	var preview_cards := _preview_cards(cards_box)
	_assert(preview_cards.size() >= 4, "rail preserves the full dummy tail instead of dropping the placeholder cards")
	for preview_card in preview_cards:
		_assert(str(preview_card.get_meta("rail_card_visual_family", "")) == "overlay-rail-shared-shell-v1", "preview filler cards use the same shared visual-shell owner as real rail cards")
		var preview_style := preview_card.get_theme_stylebox("panel") as StyleBoxFlat
		_assert(preview_style != null, "preview filler card exposes a stylebox for square-edge audit")
		if preview_style != null:
			_assert(preview_style.corner_radius_top_left == 0 and preview_style.corner_radius_top_right == 0 and preview_style.corner_radius_bottom_left == 0 and preview_style.corner_radius_bottom_right == 0, "preview filler card keeps square corners instead of pill-like rounding")
			_assert(preview_style.border_width_left == 0 and preview_style.border_width_top == 0 and preview_style.border_width_right == 0 and preview_style.border_width_bottom == 0, "preview filler card drops the visible border chrome")
		var placeholder := preview_card.get_node_or_null("CardVisualRoot/PlaceholderIcon") as Label
		_assert(placeholder != null, "preview filler card renders a centered placeholder icon instead of creature-art chrome")
		if placeholder != null:
			_assert(placeholder.text == "LOCK", "preview filler cards use LOCK-only placeholder language instead of mixing LOCK and ?")
	if card_buttons.size() >= 3:
		var baseline_margin := card_buttons[0].get_node_or_null("CardVisualRoot/CardContentMargin") as MarginContainer
		card_buttons[2].pressed.emit()
		await process_frame
		await process_frame
		card_buttons = _card_buttons(cards_box)
		var selected_card := card_buttons[2]
		_assert(str(selected_card.get_meta("rail_card_visual_family", "")) == "overlay-rail-shared-shell-v1", "selected rail cards stay on the same shared visual-shell path instead of switching to a second component owner")
		var selection_strip := selected_card.get_node_or_null("CardVisualRoot/SelectionStrip") as ColorRect
		var selection_tint := selected_card.get_node_or_null("CardVisualRoot/SelectionTint") as ColorRect
		var selected_margin := selected_card.get_node_or_null("CardVisualRoot/CardContentMargin") as MarginContainer
		_assert(selection_strip != null, "selected rail cards expose a named selection strip instead of an anonymous ad-hoc overlay")
		_assert(selection_tint == null, "selected rail cards remove the extra dark tint lane beside the green strip instead of creating a second left gutter")
		_assert(selected_margin != null, "selected rail cards keep a named shared content margin after selection")
		if selection_strip != null:
			_assert(absf(selection_strip.get_global_rect().position.x - selected_card.get_global_rect().position.x) <= 1.0, "selection strip stays flush with the selected card edge instead of introducing a second left lane owner")
		if baseline_margin != null and selected_margin != null:
			_assert(absf(selected_margin.get_global_rect().position.x - baseline_margin.get_global_rect().position.x) <= 1.0, "selection state keeps the same content start instead of shifting the card body into a second left gutter")
	var cta_height := start_button.get_global_rect().size.y
	_assert(cta_height >= CTA_HEIGHT_MIN and cta_height <= CTA_HEIGHT_MAX, "cta keeps the compact docked lane height from the approved mockup (height=%.2f)" % cta_height)
	_assert(cards_scroll.get_global_rect().size.y >= 560.0, "card strip keeps a tall scroll lane so multiple compact cards remain visible")
	_assert(start_button.text == "", "cta button keeps text rendering in dedicated child labels instead of default button text")
	_assert(str(page.start_button_hint.text) == "STRIKE COMMENCE", "cta microcopy matches the approved English caption")
	var cta_fill := start_button.get_node_or_null("CTAFill") as TextureRect
	_assert(cta_fill != null, "cta renders a dedicated green fill layer for the stronger dock treatment")
	if cta_fill != null:
		_assert(cta_fill.offset_left >= 1.0 and cta_fill.offset_top >= 1.0 and cta_fill.offset_right <= -1.0 and cta_fill.offset_bottom <= -1.0, "cta fill stays inset so the green outer border remains visible on every edge")
	var arrow_bay := start_button.get_node_or_null("ArrowBay") as ColorRect
	_assert(arrow_bay != null, "cta renders a dedicated arrow bay")
	if arrow_bay != null:
		_assert(arrow_bay.color.a >= 0.99 and arrow_bay.color.r <= 0.08 and arrow_bay.color.g <= 0.10 and arrow_bay.color.b <= 0.08, "cta arrow bay uses an opaque near-black fill")
		_assert(arrow_bay.offset_top >= 1.0 and arrow_bay.offset_right <= -1.0 and arrow_bay.offset_bottom <= -1.0, "cta arrow bay stays inset so the outer green border wraps around the black arrow zone too")
	main_instance.queue_free()
	await process_frame

func _preview_cards(cards_box: VBoxContainer) -> Array[PanelContainer]:
	var cards: Array[PanelContainer] = []
	for child in cards_box.get_children():
		if child is PanelContainer and not (child is Button):
			cards.append(child)
	return cards
