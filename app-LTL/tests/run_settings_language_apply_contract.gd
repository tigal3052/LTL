extends SceneTree

const VIEWPORT_SIZE := Vector2i(1440, 900)
const TextCatalogScript = preload("res://src/ui/TextCatalog.gd")

var failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	root.size = VIEWPORT_SIZE
	TextCatalogScript.set_locale("ko")
	var MainScene = load("res://src/Main.tscn")
	_assert(MainScene != null, "main scene resource loads for settings language contract")
	if MainScene == null:
		_finish()
		return
	var main_instance = MainScene.instantiate()
	_assert(main_instance != null, "main scene instantiates for settings language contract")
	if main_instance == null:
		_finish()
		return
	root.add_child(main_instance)
	await process_frame
	await process_frame
	await process_frame

	var settings_panel = main_instance.get("settings_panel") as Control
	_assert(settings_panel != null, "settings panel exists")
	if settings_panel == null:
		main_instance.queue_free()
		_finish()
		return
	var language_select = settings_panel.get("language_select") as OptionButton
	var settings_title = settings_panel.get_node_or_null("Center/SettingsBox/SettingsTitle") as Label
	var close_button = settings_panel.get_node_or_null("Center/SettingsBox/ButtonsRow/CloseSettingsButton") as Button
	var character_page = main_instance.get("character_select_page") as Control
	var character_title: Label = null
	var character_name: Label = null
	if character_page != null:
		character_title = character_page.get_node_or_null("Margin/VStack/HeroSection/PageTitle") as Label
		character_name = character_page.get_node_or_null("Margin/VStack/BoardShell/ShellMargin/ShellVBox/BoardBody/FeatureZone/ZoneMargin/ZoneVBox/HeroColumn/CopyCard/CopyMargin/CopyVBox/HeroName") as Label
	_assert(language_select != null, "settings panel exposes the language selector")
	_assert(settings_title != null, "settings panel exposes the title label")
	_assert(close_button != null, "settings panel exposes the apply-close button")
	_assert(character_page != null, "character select page exists for dynamic English refresh")
	_assert(character_title != null, "character select page exposes the page title")
	_assert(character_name != null, "character select page exposes the selected character name")
	if language_select == null or settings_title == null or close_button == null:
		main_instance.queue_free()
		_finish()
		return

	var language_events: Array[String] = []
	settings_panel.language_changed.connect(func(locale: String): language_events.append(locale))

	main_instance.call("set_settings_visible", true)
	await process_frame
	await process_frame
	_assert_eq(bool(settings_panel.visible), true, "settings panel opens before selecting English")

	language_events.clear()
	language_select.select(1)
	language_select.item_selected.emit(1)
	await process_frame
	await process_frame
	_assert_eq(TextCatalogScript.locale(), "en", "selecting English updates the active catalog locale")
	_assert_eq(language_events.size(), 1, "selecting English emits one language_changed event")
	if language_events.size() > 0:
		_assert_eq(language_events[0], "en", "English language_changed event carries the en locale")
	_assert_eq(settings_title.text, "System Calibration", "settings title refreshes to English immediately")
	_assert_eq(close_button.text, "Apply & Close", "apply-close button refreshes to English immediately")
	if character_title != null:
		_assert_eq(character_title.text, "Character Select", "visible character page title refreshes to English behind settings")
	if character_name != null:
		_assert_eq(character_name.text, "Anchor Miner", "visible character page roster data refreshes to English behind settings")

	close_button.pressed.emit()
	await process_frame
	_assert_eq(bool(settings_panel.visible), false, "English apply-close hides the settings panel")

	if character_page != null:
		character_page.continue_requested.emit()
	await process_frame
	await process_frame
	_assert_eq(str(main_instance.get("active_page_id")), "leviathan_select", "English locale remains active across the next page transition")
	var leviathan_page = main_instance.get("leviathan_select_page") as Control
	var roster_title: Label = null
	var start_label: Label = null
	var leviathan_name: Label = null
	if leviathan_page != null:
		roster_title = leviathan_page.get_node_or_null("Margin/Layout/RosterPanel/Margin/RosterBox/RosterTitle") as Label
		start_label = leviathan_page.get_node_or_null("Margin/Layout/BoardPanel/StartButtonFrame/StartButton/StartButtonMargin/StartButtonCenter/StartButtonStack/StartLabel") as Label
		leviathan_name = leviathan_page.get_node_or_null("Margin/Layout/BoardPanel/Margin/VStack/LeviathanName") as Label
	_assert(roster_title != null, "leviathan select page exposes the roster title")
	_assert(start_label != null, "leviathan select page exposes the looting-start label")
	_assert(leviathan_name != null, "leviathan select page exposes the selected leviathan name")
	if roster_title != null:
		_assert_eq(roster_title.text, "Leviathan Contracts", "leviathan select roster title renders in English")
	if start_label != null:
		_assert_eq(start_label.text, "LOOTING START", "leviathan select start CTA renders in English")
	if leviathan_name != null:
		_assert_eq(leviathan_name.text, "Ossuary Tortoise", "leviathan select roster data renders in English")

	main_instance.call("set_settings_visible", true)
	await process_frame
	await process_frame
	language_events.clear()
	language_select.item_selected.emit(1)
	await process_frame
	_assert_eq(language_events.size(), 0, "reselecting the active English locale does not emit language_changed again")
	_assert_eq(TextCatalogScript.locale(), "en", "active English locale remains stable after redundant selection")
	_assert_eq(language_select.selected, 1, "language selector remains synced to English after redundant English selection")

	await _select_locale(language_select, language_events, 0, "ko", "Korean", settings_panel, settings_title, close_button)
	var korean_character_page = main_instance.get("character_select_page") as Control
	var korean_leviathan_page = main_instance.get("leviathan_select_page") as Control
	_assert_eq(str(main_instance.get("active_page_id")), "leviathan_select", "Korean locale apply keeps the current page active")
	if korean_leviathan_page != null:
		var korean_roster_title = korean_leviathan_page.get_node_or_null("Margin/Layout/RosterPanel/Margin/RosterBox/RosterTitle") as Label
		var korean_start_label = korean_leviathan_page.get_node_or_null("Margin/Layout/BoardPanel/StartButtonFrame/StartButton/StartButtonMargin/StartButtonCenter/StartButtonStack/StartLabel") as Label
		_assert(korean_roster_title != null, "leviathan page still exposes roster title after Korean apply")
		_assert(korean_start_label != null, "leviathan page still exposes start label after Korean apply")
		if korean_roster_title != null:
			_assert_eq(korean_roster_title.text, TextCatalogScript.t("leviathan.roster.title"), "leviathan roster title refreshes to Korean")
		if korean_start_label != null:
			_assert_eq(korean_start_label.text, TextCatalogScript.t("leviathan.start_button"), "leviathan start CTA refreshes to Korean")
	if korean_character_page != null:
		var hidden_character_title = korean_character_page.get_node_or_null("Margin/VStack/HeroSection/PageTitle") as Label
		if hidden_character_title != null:
			_assert_eq(hidden_character_title.text, TextCatalogScript.t("character.page.title"), "hidden character page also refreshes to Korean for later return")

	language_events.clear()
	language_select.item_selected.emit(0)
	await process_frame
	_assert_eq(language_events.size(), 0, "reselecting the active Korean locale does not emit language_changed again")
	_assert_eq(TextCatalogScript.locale(), "ko", "active Korean locale remains stable after redundant Korean selection")
	_assert_eq(language_select.selected, 0, "language selector remains synced to Korean after redundant Korean selection")

	await _select_locale(language_select, language_events, 1, "en", "English again", settings_panel, settings_title, close_button)
	await _select_locale(language_select, language_events, 0, "ko", "Korean again", settings_panel, settings_title, close_button)

	main_instance.queue_free()
	await process_frame
	_finish()

func _select_locale(
	language_select: OptionButton,
	language_events: Array[String],
	index: int,
	expected_locale: String,
	label: String,
	settings_panel: Control,
	settings_title: Label,
	close_button: Button
) -> void:
	if not bool(settings_panel.visible):
		settings_panel.visible = true
	await process_frame
	language_events.clear()
	language_select.select(index)
	language_select.item_selected.emit(index)
	await process_frame
	await process_frame
	_assert_eq(TextCatalogScript.locale(), expected_locale, "%s selection updates the active catalog locale" % label)
	_assert_eq(language_events.size(), 1, "%s selection emits one language_changed event" % label)
	if language_events.size() > 0:
		_assert_eq(language_events[0], expected_locale, "%s language_changed event carries the selected locale" % label)
	_assert_eq(language_select.selected, index, "%s selection keeps the selector synced to the selected index" % label)
	_assert_eq(settings_title.text, TextCatalogScript.t("settings.title"), "%s selection refreshes the settings title" % label)
	_assert_eq(close_button.text, TextCatalogScript.t("action.apply_close"), "%s selection refreshes the apply-close button" % label)
	close_button.pressed.emit()
	await process_frame
	_assert_eq(bool(settings_panel.visible), false, "%s apply-close hides the settings panel" % label)

func _assert(condition: bool, label: String) -> void:
	if not condition:
		failures.append(label)

func _assert_eq(actual: Variant, expected: Variant, label: String) -> void:
	if actual != expected:
		failures.append("%s: expected %s, got %s" % [label, str(expected), str(actual)])

func _finish() -> void:
	if failures.is_empty():
		print("SETTINGS_LANGUAGE_APPLY_CONTRACT_OK")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)
