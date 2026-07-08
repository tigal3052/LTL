extends SceneTree

const VIEWPORT_SIZE := Vector2i(1440, 900)
const CharacterSelectLoadoutTextScript = preload("res://src/scenes/pages/character_select/CharacterSelectLoadoutText.gd")

var failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	root.size = VIEWPORT_SIZE
	var main_scene := load("res://src/Main.tscn") as PackedScene
	_assert(main_scene != null, "main scene resource loads for character select cleanup contract")
	if main_scene == null:
		await _finish()
		return
	await _assert_character_select_cleanup(main_scene)
	await _finish()

func _instantiate_main(main_scene: PackedScene) -> Node:
	var main_instance := main_scene.instantiate()
	root.add_child(main_instance)
	await process_frame
	await process_frame
	await process_frame
	if str(main_instance.get("active_page_id")) == "story_scene":
		await _advance_story_if_present(main_instance, "character_select")
		await process_frame
		await process_frame
	return main_instance

func _assert(condition: bool, label: String) -> void:
	if not condition:
		failures.append(label)

func _assert_eq(actual: Variant, expected: Variant, label: String) -> void:
	if actual != expected:
		failures.append("%s: expected %s, got %s" % [label, str(expected), str(actual)])

func _finish() -> void:
	if failures.is_empty():
		print("CHARACTER_SELECT_CLEANUP_CONTRACT_OK")
		await process_frame
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	await process_frame
	quit(1)

func _advance_story_if_present(main_instance: Node, return_page_id: String) -> void:
	if str(main_instance.get("active_page_id")) != "story_scene":
		return
	var story_page = main_instance.get("story_scene_page")
	var controller = main_instance.get_node_or_null("MainController")
	_assert(story_page != null, "story scene page exists during cleanup-contract handoff")
	_assert(controller != null, "main controller exists during cleanup-contract handoff")
	if story_page == null or controller == null:
		return
	var story: Dictionary = controller.get("active_story_scene")
	var scene_id := str(story.get("id", ""))
	_assert(scene_id != "", "story scene exposes an active scene id during cleanup-contract handoff")
	if scene_id.is_empty():
		return
	story_page.continue_requested.emit(scene_id)
	await process_frame
	story_page.continue_requested.emit(scene_id)
	await process_frame
	_assert_eq(str(main_instance.get("active_page_id")), return_page_id, "story scene returns to %s during cleanup contract" % return_page_id)

func _assert_character_select_cleanup(main_scene: PackedScene) -> void:
	var main_instance = await _instantiate_main(main_scene)
	_assert_eq(str(main_instance.get("active_page_id")), "character_select", "main scene starts on character select for cleanup contract")
	var character_page := main_instance.get("character_select_page") as Control
	_assert(character_page != null, "character select page exists for cleanup contract")
	if character_page == null:
		main_instance.queue_free()
		await process_frame
		return

	# Stage-based node paths
	var top_bar := character_page.get_node_or_null("TopBar") as PanelContainer
	var tabs_row := character_page.get_node_or_null("TopBar/TopBarMargin/TopBarRow/BrandRow/TabsRow") as HBoxContainer
	var top_actions := character_page.get_node_or_null("TopBar/TopBarMargin/TopBarRow/TopActions") as HBoxContainer
	var stage := character_page.get_node_or_null("Stage") as Control
	var roster_rail := character_page.get_node_or_null("Stage/RosterRail") as PanelContainer
	var roster_scroll := character_page.get_node_or_null("Stage/RosterRail/RosterMargin/RosterVBox/RosterScroll") as ScrollContainer
	var roster_list := character_page.get_node_or_null("Stage/RosterRail/RosterMargin/RosterVBox/RosterScroll/RosterList") as VBoxContainer
	var roster_first_card := character_page.get_node_or_null("Stage/RosterRail/RosterMargin/RosterVBox/RosterScroll/RosterList/CharacterChoice_miner") as Button
	var roster_body: Label = null
	if roster_first_card != null:
		roster_body = roster_first_card.get_node_or_null("CardFrame/CardMargin/CardRow/CardVBox/Body") as Label
	var hero_bg := character_page.get_node_or_null("Stage/HeroBg") as TextureRect
	var hero_char := character_page.get_node_or_null("Stage/HeroChar") as TextureRect
	var hero_name := character_page.get_node_or_null("Stage/HeroCopy/HeroName") as Label
	var hero_line := character_page.get_node_or_null("Stage/HeroCopy/HeroLine") as Label
	var wing := character_page.get_node_or_null("Stage/Wing") as PanelContainer
	var preset_grid := character_page.get_node_or_null("Stage/Wing/WingMargin/WingVBox/PresetSection/PresetGrid") as GridContainer
	var starter_item_list := character_page.get_node_or_null("Stage/Wing/WingMargin/WingVBox/BagSection/StarterItemList") as VBoxContainer
	var starter_item_one := character_page.get_node_or_null("Stage/Wing/WingMargin/WingVBox/BagSection/StarterItemList/StarterItem_starter_red_drill") as Button
	var item_detail_title := character_page.get_node_or_null("Stage/Wing/WingMargin/WingVBox/DetailSection/ItemDetailTitle") as Label
	var item_detail_body := character_page.get_node_or_null("Stage/Wing/WingMargin/WingVBox/DetailSection/ItemDetailBody") as Label
	var continue_button := character_page.get_node_or_null("Stage/Wing/WingMargin/WingVBox/CtaDock/ContinueButton") as Button

	var selected_character: Dictionary = {}
	var selected_character_owner: Node = main_instance
	if not selected_character_owner.has_method("_selected_character_data"):
		selected_character_owner = main_instance.get_node_or_null("MainController")
	if selected_character_owner != null and selected_character_owner.has_method("_selected_character_data"):
		selected_character = selected_character_owner.call("_selected_character_data")
	var starter_items := CharacterSelectLoadoutTextScript.starter_item_models("red")
	var starter_detail := CharacterSelectLoadoutTextScript.detail_for_item_id("red", "starter_red_beacon")

	_assert(top_bar != null, "character select owns the Leviathan-style top bar")
	_assert(tabs_row != null and tabs_row.get_child_count() >= 4, "character select renders the shared top menu group")
	_assert(top_actions != null, "character select top bar exposes the right-side action host")
	_assert(stage != null, "character select Stage node exists")
	_assert(roster_rail != null, "character select RosterRail exists")
	_assert(roster_first_card != null, "character select still renders clickable roster cards after the redesign")
	_assert(roster_body != null, "character select roster card exposes a long supporting body label")
	_assert(hero_bg != null, "character select HeroBg fullscreen background exists")
	_assert(hero_char != null, "character select HeroChar exists")
	_assert(hero_name != null, "character select hero name label exists")
	_assert(hero_line != null, "character select center footer renders the per-character hero line")
	_assert(wing != null, "character select glassmorphism Wing exists")
	_assert(preset_grid != null, "character select Wing contains PresetGrid for 2x2 palette")
	_assert(preset_grid != null and preset_grid.get_child_count() >= 4, "character select PresetGrid has 4 palette buttons")
	_assert(continue_button != null, "character select moves the CTA into the wing")
	_assert(starter_item_list != null, "character select wing renders a starter item list")
	_assert(starter_item_one != null, "character select wing renders the first starter item button")
	_assert(item_detail_title != null, "character select wing exposes item detail title")
	_assert(item_detail_body != null, "character select wing exposes item detail body")
	_assert(not str(selected_character.get("rosterLongCopy", "")).is_empty(), "selected character exposes rosterLongCopy from external data")
	_assert(not str(selected_character.get("heroLine", "")).is_empty(), "selected character exposes heroLine from external data")
	_assert_eq(starter_items.size(), 2, "red starter set exposes two starter item models")
	_assert_eq(str(starter_items[0].get("itemId", "")) if starter_items.size() > 0 else "", "starter_red_drill", "starter item model keeps a stable drill id")
	_assert_eq(str(starter_items[1].get("itemId", "")) if starter_items.size() > 1 else "", "starter_red_beacon", "starter item model keeps a stable beacon id")
	_assert(not str(starter_detail.get("title", "")).is_empty(), "starter item detail model exposes a title for the clicked panel")
	_assert(not str(starter_detail.get("body", "")).is_empty(), "starter item detail model exposes a body for the clicked panel")
	if roster_scroll != null and roster_scroll.get_v_scroll_bar() != null:
		_assert(not roster_scroll.get_v_scroll_bar().visible, "character select keeps roster scrolling while hiding scrollbar chrome")

	main_instance.queue_free()
	await process_frame
