extends SceneTree

const VIEWPORT_SIZE := Vector2i(1440, 900)

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
	return main_instance

func _assert(condition: bool, label: String) -> void:
	if not condition:
		failures.append(label)

func _assert_eq(actual: Variant, expected: Variant, label: String) -> void:
	if actual != expected:
		failures.append("%s: expected %s, got %s" % [label, str(expected), str(actual)])

func _assert_contains(actual: String, fragment: String, label: String) -> void:
	if not actual.contains(fragment):
		failures.append("%s: expected fragment %s in %s" % [label, fragment, actual])

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

func _assert_character_select_cleanup(main_scene: PackedScene) -> void:
	var main_instance = await _instantiate_main(main_scene)
	_assert_eq(str(main_instance.get("active_page_id")), "character_select", "main scene starts on character select for cleanup contract")
	var character_page := main_instance.get("character_select_page") as Control
	_assert(character_page != null, "character select page exists for cleanup contract")
	if character_page == null:
		main_instance.queue_free()
		await process_frame
		return

	var title := character_page.get_node_or_null("Margin/VStack/HeroSection/PageTitle") as Label
	var subtitle := character_page.get_node_or_null("Margin/VStack/HeroSection/PageSubtitle") as Control
	var settings_button := character_page.get_node_or_null("SettingsButton") as Button
	var settings_panel := main_instance.get("settings_panel") as Control
	var action_bar := main_instance.get_node_or_null("RootMargin/AppShell/ActionBar") as Control
	var hold_fire_button := main_instance.get_node_or_null("RootMargin/AppShell/ActionBar/HoldFireButton") as Button
	var repair_button := main_instance.get_node_or_null("RootMargin/AppShell/ActionBar/RepairButton") as Button
	var claim_rewards_button := main_instance.get_node_or_null("RootMargin/AppShell/ActionBar/ClaimRewardsButton") as Button
	var board_head := character_page.get_node_or_null("Margin/VStack/BoardShell/ShellMargin/ShellVBox/BoardHead") as Control
	var selector_hint := character_page.get_node_or_null("Margin/VStack/BoardShell/ShellMargin/ShellVBox/BoardBody/SelectorZone/ZoneMargin/ZoneVBox/ZoneHead/ZoneHint") as Control
	var feature_hint := character_page.get_node_or_null("Margin/VStack/BoardShell/ShellMargin/ShellVBox/BoardBody/FeatureZone/ZoneMargin/ZoneVBox/ZoneHead/ZoneHint") as Control
	var prep_hint := character_page.get_node_or_null("Margin/VStack/BoardShell/ShellMargin/ShellVBox/BoardBody/PrepZone/ZoneMargin/ZoneVBox/ZoneHead/ZoneHint") as Control
	var palette_title := character_page.get_node_or_null("Margin/VStack/BoardShell/ShellMargin/ShellVBox/BoardBody/PrepZone/ZoneMargin/ZoneVBox/PrepColumn/PaletteCard/PaletteMargin/PaletteVBox/PaletteTitle") as Control
	var palette_scroll := character_page.get_node_or_null("Margin/VStack/BoardShell/ShellMargin/ShellVBox/BoardBody/PrepZone/ZoneMargin/ZoneVBox/PrepColumn/PaletteCard/PaletteMargin/PaletteVBox/PaletteScroll") as ScrollContainer
	var palette_red := character_page.get_node_or_null("Margin/VStack/BoardShell/ShellMargin/ShellVBox/BoardBody/PrepZone/ZoneMargin/ZoneVBox/PrepColumn/PaletteCard/PaletteMargin/PaletteVBox/PaletteScroll/PaletteList/Palette_red") as Button
	var palette_blue := character_page.get_node_or_null("Margin/VStack/BoardShell/ShellMargin/ShellVBox/BoardBody/PrepZone/ZoneMargin/ZoneVBox/PrepColumn/PaletteCard/PaletteMargin/PaletteVBox/PaletteScroll/PaletteList/Palette_blue") as Button
	var bag_head := character_page.get_node_or_null("Margin/VStack/BoardShell/ShellMargin/ShellVBox/BoardBody/PrepZone/ZoneMargin/ZoneVBox/PrepColumn/BagCard/BagMargin/BagVBox/BagHead") as Control
	var bag_detail_title := character_page.get_node_or_null("Margin/VStack/BoardShell/ShellMargin/ShellVBox/BoardBody/PrepZone/ZoneMargin/ZoneVBox/PrepColumn/BagCard/BagMargin/BagVBox/BagDetailCard/BagDetailMargin/BagDetailVBox/BagDetailTitle") as Label
	var bag_detail_body := character_page.get_node_or_null("Margin/VStack/BoardShell/ShellMargin/ShellVBox/BoardBody/PrepZone/ZoneMargin/ZoneVBox/PrepColumn/BagCard/BagMargin/BagVBox/BagDetailCard/BagDetailMargin/BagDetailVBox/BagDetailBody") as Label
	var bag_slot_1 := character_page.get_node_or_null("Margin/VStack/BoardShell/ShellMargin/ShellVBox/BoardBody/PrepZone/ZoneMargin/ZoneVBox/PrepColumn/BagCard/BagMargin/BagVBox/MiniBag/Slot1") as Control
	var bag_slot_2 := character_page.get_node_or_null("Margin/VStack/BoardShell/ShellMargin/ShellVBox/BoardBody/PrepZone/ZoneMargin/ZoneVBox/PrepColumn/BagCard/BagMargin/BagVBox/MiniBag/Slot2") as Control
	var cta_label := character_page.get_node_or_null("Margin/VStack/BoardShell/ShellMargin/ShellVBox/BoardBody/PrepZone/ZoneMargin/ZoneVBox/PrepColumn/CtaCard/CtaMargin/CtaVBox/CtaLabel") as Control
	var cta_copy := character_page.get_node_or_null("Margin/VStack/BoardShell/ShellMargin/ShellVBox/BoardBody/PrepZone/ZoneMargin/ZoneVBox/PrepColumn/CtaCard/CtaMargin/CtaVBox/CtaCopy") as Control
	var cta_footnote := character_page.get_node_or_null("Margin/VStack/BoardShell/ShellMargin/ShellVBox/BoardBody/PrepZone/ZoneMargin/ZoneVBox/PrepColumn/CtaCard/CtaMargin/CtaVBox/CtaFootnote") as Control
	var continue_button := character_page.get_node_or_null("Margin/VStack/BoardShell/ShellMargin/ShellVBox/BoardBody/PrepZone/ZoneMargin/ZoneVBox/PrepColumn/CtaCard/CtaMargin/CtaVBox/ContinueButton") as Button
	var board_shell := character_page.get_node_or_null("Margin/VStack/BoardShell") as Control
	var hero_stage := character_page.get_node_or_null("Margin/VStack/BoardShell/ShellMargin/ShellVBox/BoardBody/FeatureZone/ZoneMargin/ZoneVBox/HeroColumn/HeroStage") as Control

	_assert(title != null, "character select title exists for cleanup contract")
	_assert(action_bar != null, "main shell action bar exists after main scene instantiation")
	_assert(hold_fire_button != null, "main shell hold-fire button exists after main scene instantiation")
	_assert(repair_button != null, "main shell repair button exists after main scene instantiation")
	_assert(claim_rewards_button != null, "main shell claim-rewards button exists after main scene instantiation")
	_assert_eq(title.text if title != null else "", "캐릭터 선택", "character select title uses the cleaned heading copy")
	_assert(subtitle != null, "character select subtitle exists for cleanup contract")
	_assert(subtitle == null or not subtitle.visible, "character select removes the long introductory subtitle")
	_assert(settings_button != null, "character select settings button exists inside the page shell")
	_assert(settings_button == null or settings_button.visible, "character select settings button is visible")
	_assert_eq(settings_button.text if settings_button != null else "", "설정", "character select settings button uses localized settings copy")
	if settings_button != null:
		settings_button.pressed.emit()
		await process_frame
	_assert(settings_panel != null and settings_panel.visible, "character select settings button opens the shared settings panel")
	_assert(board_head != null, "character select board header exists for cleanup contract")
	_assert(board_head == null or not board_head.visible, "character select removes the board helper header and mode pill")
	_assert(selector_hint == null or not selector_hint.visible, "character select selector helper hint is removed")
	_assert(feature_hint == null or not feature_hint.visible, "character select feature helper hint is removed")
	_assert(prep_hint == null or not prep_hint.visible, "character select prep helper hint is removed")
	_assert(palette_title == null or not palette_title.visible, "character select palette title copy is removed")
	_assert(bag_head == null or not bag_head.visible, "character select bag heading copy is removed")
	_assert(cta_label == null or not cta_label.visible, "character select CTA heading copy is removed")
	_assert(cta_copy == null or not cta_copy.visible, "character select CTA description copy is removed")
	_assert(cta_footnote == null or not cta_footnote.visible, "character select CTA footnote copy is removed")

	_assert(palette_scroll != null, "character select starter palette scroll exists")
	_assert(palette_red != null, "character select renders a red starter palette option")
	_assert(palette_blue != null, "character select renders a blue starter palette option")
	if palette_red != null:
		_assert_contains(palette_red.text, "드릴 1.5 / 40", "character select starter palette shows the actual starter drill metrics")
		_assert_contains(palette_red.text, "비콘 45", "character select starter palette shows the actual starter beacon base cooldown")
		_assert_contains(palette_red.text, "-8", "character select starter palette shows the actual starter beacon drill cooldown modifier")
		_assert_contains(palette_red.text, "+0.4", "character select starter palette shows the actual starter beacon damage bonus")
	if palette_scroll != null and palette_scroll.get_v_scroll_bar() != null:
		_assert(not palette_scroll.get_v_scroll_bar().visible, "character select starter palette expands enough to remove the scrollbar")

	_assert(bag_detail_title != null, "character select bag detail panel exists for hover audit")
	_assert(bag_detail_body != null, "character select bag detail body exists for hover audit")
	_assert(bag_slot_1 != null, "character select bag slot 1 exists for hover audit")
	_assert(bag_slot_2 != null, "character select bag slot 2 exists for hover audit")
	_assert(bag_slot_1 == null or bag_slot_1.size.x >= 48.0, "character select bag slots expand after helper copy is removed")
	if bag_slot_1 != null:
		bag_slot_1.emit_signal("mouse_entered")
		await process_frame
	_assert_contains(bag_detail_title.text if bag_detail_title != null else "", "드릴", "character select bag hover updates the detail panel with the starter drill title")
	_assert_contains(bag_detail_body.text if bag_detail_body != null else "", "1.5", "character select bag hover shows the actual starter drill damage")
	if bag_slot_2 != null:
		bag_slot_2.emit_signal("mouse_entered")
		await process_frame
	_assert_contains(bag_detail_title.text if bag_detail_title != null else "", "비콘", "character select bag hover updates the detail panel with the starter beacon title")
	_assert_contains(bag_detail_body.text if bag_detail_body != null else "", "8틱 감소", "character select bag hover shows the actual starter beacon cooldown effect")

	_assert_eq(continue_button.text if continue_button != null else "", "레비아탄 선택", "character select CTA uses the shortened progression button copy")

	_assert(board_shell != null, "character select board shell exists for layout regression audit")
	_assert(hero_stage != null, "character select hero stage exists for layout regression audit")
	if board_shell != null and hero_stage != null and palette_scroll != null and palette_blue != null:
		var board_height_before: float = board_shell.size.y
		var hero_stage_height_before: float = hero_stage.size.y
		var palette_height_before: float = palette_scroll.size.y
		palette_blue.pressed.emit()
		await process_frame
		await process_frame
		_assert(
			board_shell.global_position.y + board_shell.size.y <= float(VIEWPORT_SIZE.y),
			"character select board shell stays inside the viewport after starter selection"
		)
		_assert(
			absf(board_shell.size.y - board_height_before) <= 4.0,
			"character select board shell height stays stable after starter selection"
		)
		_assert(
			absf(hero_stage.size.y - hero_stage_height_before) <= 4.0,
			"character select hero stage height stays stable after starter selection"
		)
		_assert(
			absf(palette_scroll.size.y - palette_height_before) <= 4.0,
			"character select starter palette height stays stable after starter selection"
		)
		if palette_scroll.get_v_scroll_bar() != null:
			_assert(
				not palette_scroll.get_v_scroll_bar().visible,
				"character select starter palette keeps the full list visible after starter selection"
			)

	main_instance.queue_free()
	await process_frame
