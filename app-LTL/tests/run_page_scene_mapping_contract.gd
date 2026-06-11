extends SceneTree

var failures: Array[String] = []
const TextCatalogScript = preload("res://src/ui/TextCatalog.gd")

const PAGE_SCENES := {
	"m6-run-start-wireframe.html": "res://src/scenes/pages/CharacterSelectPage.tscn",
	"m6-leviathan-select-wireframe.html": "res://src/scenes/pages/LeviathanSelectPage.tscn",
	"2026-06-08-node-select-crossroads-3up.html": "res://src/scenes/pages/NodeSelectRuntimePage.tscn",
	"m6-reward-claim-wireframe.html": "res://src/scenes/pages/RewardPage.tscn",
	"m6-boss-reward-pick-wireframe.html": "res://src/scenes/pages/BossRewardPage.tscn",
	"m6-defeat-page-wireframe.html": "res://src/scenes/pages/DefeatPage.tscn",
	"m6-event-node-wireframe.html": "res://src/scenes/pages/EventNodePage.tscn"
}

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	for mockup_name in PAGE_SCENES.keys():
		var scene_path := str(PAGE_SCENES[mockup_name])
		var packed: PackedScene = load(scene_path)
		_assert(packed != null, "scene exists for %s -> %s" % [mockup_name, scene_path])
		if packed == null:
			continue
		var instance = packed.instantiate()
		_assert(instance != null, "scene instantiates for %s" % mockup_name)
		if instance != null:
			if mockup_name == "m6-run-start-wireframe.html":
				_assert(instance.get_node_or_null("Margin/VStack/HeroSection") != null, "run-start scene exposes the hero introduction section")
				_assert(instance.get_node_or_null("Margin/VStack/BoardShell") != null, "run-start scene exposes the board shell")
				_assert(instance.get_node_or_null("Margin/VStack/BoardShell/ShellMargin/ShellVBox/BoardBody/SelectorZone") != null, "run-start scene exposes the narrow selector zone")
				_assert(instance.get_node_or_null("Margin/VStack/BoardShell/ShellMargin/ShellVBox/BoardBody/FeatureZone") != null, "run-start scene exposes the wide hero stage zone")
				_assert(instance.get_node_or_null("Margin/VStack/BoardShell/ShellMargin/ShellVBox/BoardBody/PrepZone") != null, "run-start scene exposes the right prep zone")
				_assert(instance.get_node_or_null("Margin/VStack/BoardShell/ShellMargin/ShellVBox/BoardBody/PrepZone/ZoneMargin/ZoneVBox/PrepColumn/CtaCard/CtaMargin/CtaVBox/ContinueButton") != null, "run-start scene exposes the run-start CTA button")
			elif mockup_name == "m6-leviathan-select-wireframe.html":
				var target_ribbon := instance.get_node_or_null("Margin/Layout/BoardPanel/TargetRibbon") as Control
				var start_frame := instance.get_node_or_null("Margin/Layout/BoardPanel/StartButtonFrame") as Control
				var start_button := instance.get_node_or_null("Margin/Layout/BoardPanel/StartButtonFrame/StartButton") as Button
				var advance_label := instance.get_node_or_null("Margin/Layout/BoardPanel/StartButtonFrame/StartButton/StartButtonMargin/StartButtonCenter/StartButtonStack/AdvanceLabel") as Label
				var start_label := instance.get_node_or_null("Margin/Layout/BoardPanel/StartButtonFrame/StartButton/StartButtonMargin/StartButtonCenter/StartButtonStack/StartLabel") as Label
				_assert(target_ribbon != null, "leviathan-select scene exposes the full-width target ribbon overlay")
				_assert(start_frame != null, "leviathan-select scene exposes the dedicated start-button frame overlay")
				_assert(start_button != null, "leviathan-select scene exposes the looting-start button")
				_assert(advance_label != null, "leviathan-select CTA exposes a next-step kicker label")
				_assert(start_label != null, "leviathan-select CTA exposes a primary looting-start label")
				_assert_eq(TextCatalogScript.t("leviathan.start_hint", [], "en"), "IMMEDIATE HANDOFF", "leviathan-select CTA keeps the approved condensed kicker copy")
				_assert_eq(TextCatalogScript.t("leviathan.start_button", [], "en"), "LOOTING START", "leviathan-select CTA keeps the approved condensed primary copy")
				if start_button != null:
					_assert(start_button.custom_minimum_size.y >= 68.0 and start_button.custom_minimum_size.y <= 74.0, "leviathan-select CTA keeps the slimmer ~70px baseline height")
			elif mockup_name == "2026-06-08-node-select-crossroads-3up.html":
				_assert(instance.get_node_or_null("Margin/VStack/HeroSection") != null, "node-select scene exposes the mockup hero section")
				_assert(instance.get_node_or_null("Margin/VStack/BoardShell") != null, "node-select scene exposes the dedicated board shell")
				_assert(instance.get_node_or_null("Margin/VStack/BoardShell/ShellMargin/ShellVBox/BoardHead") != null, "node-select scene exposes the board header")
				_assert(instance.get_node_or_null("Margin/VStack/BoardShell/ShellMargin/ShellVBox/BoardHead/BoardLead") != null, "node-select scene exposes the leviathan lead block")
				_assert(instance.get_node_or_null("Margin/VStack/BoardShell/ShellMargin/ShellVBox/BoardHead/BoardLead/BoardLabel") != null, "node-select scene exposes the selected-leviathan label")
				_assert(instance.get_node_or_null("Margin/VStack/BoardShell/ShellMargin/ShellVBox/BoardHead/BoardLead/LeviathanTitle") != null, "node-select scene exposes the board-head leviathan title")
				_assert(instance.get_node_or_null("Margin/VStack/BoardShell/ShellMargin/ShellVBox/BoardHead/TitleChips") != null, "node-select scene exposes the run and stage chips")
				_assert(instance.get_node_or_null("Margin/VStack/BoardShell/ShellMargin/ShellVBox/BoardBody/RoadmapFrame") != null, "node-select scene exposes the roadmap frame")
				_assert(instance.get_node_or_null("Margin/VStack/BoardShell/ShellMargin/ShellVBox/BoardBody/RoadmapFrame/FrameMargin/FrameVBox/RoadmapCanvas") != null, "node-select scene exposes the roadmap canvas")
				_assert(instance.get_node_or_null("Margin/VStack/BoardShell/ShellMargin/ShellVBox/BoardBody/RoadmapFrame/FrameMargin/FrameVBox/RoadmapCanvas/StageRuler") != null, "node-select scene exposes the stage rail inside the roadmap canvas")
				_assert(instance.get_node_or_null("Margin/VStack/BoardShell/ShellMargin/ShellVBox/BoardBody/RoadmapFrame/FrameMargin/FrameVBox/RoadmapCanvas/InfoCard") != null, "node-select scene exposes the hover info card")
				_assert(instance.get_node_or_null("Margin/VStack/BoardShell/ShellMargin/ShellVBox/BoardBody/RoadmapFrame/FrameMargin/FrameVBox/RoadmapCanvas/InfoCard/InfoMargin/InfoVBox/InfoNameLabel") != null, "node-select scene exposes the hover-card node-name label")
				_assert(instance.get_node_or_null("Margin/VStack/BoardShell/ShellMargin/ShellVBox/BoardBody/RoadmapFrame/FrameMargin/FrameVBox/RoadmapCanvas/InfoCard/InfoMargin/InfoVBox/InfoBodyLabel") != null, "node-select scene exposes the hover-card node-description label")
				_assert(instance.get_node_or_null("Margin/VStack/BoardShell/ShellMargin/ShellVBox/BoardBody/RoadmapFrame/FrameMargin/FrameVBox/RoadmapCanvas/NodeLayer") != null, "node-select scene exposes the hotspot layer")
				_assert(instance.get_node_or_null("Margin/VStack/BoardShell/ShellMargin/ShellVBox/BoardBody/RoadmapFrame/FrameMargin/FrameVBox/MapTitle") == null, "node-select scene removes the retired roadmap title band")
				_assert(instance.get_node_or_null("Margin/VStack/BoardShell/ShellMargin/ShellVBox/RouteSplit") == null, "node-select scene removes the retired split map/backpack shell")
			elif mockup_name == "m6-defeat-page-wireframe.html":
				_assert(instance.get_node_or_null("Margin/VStack/HeroSection") != null, "defeat scene exposes the wireframe hero section")
				_assert(instance.get_node_or_null("Margin/VStack/BoardShell") != null, "defeat scene exposes the dedicated board shell")
				_assert(instance.get_node_or_null("Margin/VStack/BoardShell/ShellMargin/ShellVBox/BoardHead") != null, "defeat scene exposes the board header")
				_assert(instance.get_node_or_null("Margin/VStack/BoardShell/ShellMargin/ShellVBox/BoardBody/HeroFrame") != null, "defeat scene exposes the character-centered hero frame")
				_assert(instance.get_node_or_null("Margin/VStack/BoardShell/ShellMargin/ShellVBox/BoardBody/FailureCauseLabel") != null, "defeat scene exposes the failure cause line")
				_assert(instance.get_node_or_null("Margin/VStack/BoardShell/ShellMargin/ShellVBox/BoardBody/FailureTipLabel") != null, "defeat scene exposes the retry hint line")
				_assert(instance.get_node_or_null("Margin/VStack/BoardShell/ShellMargin/ShellVBox/BoardBody/RetryButton") != null, "defeat scene exposes the centered retry CTA")
			instance.queue_free()
	_finish()

func _assert(condition: bool, label: String) -> void:
	if not condition:
		failures.append(label)

func _assert_eq(actual: Variant, expected: Variant, label: String) -> void:
	if actual != expected:
		failures.append("%s: expected %s, got %s" % [label, str(expected), str(actual)])

func _finish() -> void:
	if failures.is_empty():
		print("PAGE_SCENE_MAPPING_CONTRACT_OK")
		call_deferred("quit", 0)
		return
	for failure in failures:
		push_error(failure)
	call_deferred("quit", 1)
