extends SceneTree

const VIEWPORT_SIZE := Vector2i(1440, 900)

var failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	root.size = VIEWPORT_SIZE
	var story_scene := load("res://src/scenes/pages/StoryScenePage.tscn") as PackedScene
	_assert(story_scene != null, "story scene page loads for shared-frame runtime contract")
	if story_scene != null:
		var page := story_scene.instantiate() as Control
		root.add_child(page)
		await process_frame
		await process_frame
		await _assert_left_and_right_story_frame_layout(page)
		page.queue_free()
		await process_frame
	_finish()

func _assert_left_and_right_story_frame_layout(page: Control) -> void:
	var base_state := {
		"visible": true,
		"sceneId": "contract_story",
		"speaker": "Guide",
		"text": "Shared frame contract text",
		"stepIndex": 0,
		"stepCount": 2,
		"continueText": "Next",
		"skipText": "Skip",
		"portraitPath": "res://resources/charactor/charactor1.png",
		"backgroundPath": "res://resources/charactor/background.png",
		"side": "left",
		"frame": {
			"chromeMode": "minimal",
			"dialogueVariant": "expedition_journal",
			"speakerTagVariant": "leaf_tab",
			"speakerTagText": "Guide",
			"scrimOpacity": 0.42,
			"portraitScale": 0.92,
			"portraitOffsetX": 12.0,
			"portraitOffsetY": 6.0
		}
	}
	page.apply_state(base_state)
	await process_frame
	await process_frame
	var story_frame := page.get_node_or_null("StoryFrame") as Control
	_assert(story_frame != null, "story scene exposes a reusable StoryFrame root")
	var top_chrome := page.get_node_or_null("StoryFrame/TopChrome") as Control
	_assert(top_chrome != null, "story frame exposes a dedicated top chrome container")
	_assert(top_chrome == null or not bool(top_chrome.visible), "story frame keeps top chrome minimal by hiding the top container for minimal mode")
	var speaker_name := page.get_node_or_null("StoryFrame/DialogueDock/SpeakerTag/SpeakerTagMargin/SpeakerNameLabel") as Label
	_assert(speaker_name != null, "story frame exposes the speaker tag label")
	_assert_eq(speaker_name.text if speaker_name != null else "", "Guide", "story frame speaker tag renders the active speaker")
	var dialogue_panel := page.get_node_or_null("StoryFrame/DialogueDock/DialoguePanel") as Control
	_assert(dialogue_panel != null, "story frame exposes the dialogue panel")
	if dialogue_panel != null:
		var rect := dialogue_panel.get_global_rect()
		_assert(rect.position.x >= -0.5 and rect.position.y >= -0.5, "story dialogue panel stays inside the viewport origin")
		_assert(rect.end.x <= VIEWPORT_SIZE.x + 0.5 and rect.end.y <= VIEWPORT_SIZE.y + 0.5, "story dialogue panel stays inside the viewport bounds")
	var left_portrait := page.get_node_or_null("StoryFrame/PortraitLayer/LeftPortrait") as Control
	var right_portrait := page.get_node_or_null("StoryFrame/PortraitLayer/RightPortrait") as Control
	_assert(left_portrait != null, "story frame exposes the left portrait slot")
	_assert(right_portrait != null, "story frame exposes the right portrait slot")
	_assert(left_portrait == null or bool(left_portrait.visible), "story frame shows the left portrait when the step side is left")
	_assert(right_portrait == null or not bool(right_portrait.visible), "story frame hides the right portrait when the step side is left")
	var right_state := base_state.duplicate(true)
	right_state["side"] = "right"
	page.apply_state(right_state)
	await process_frame
	await process_frame
	_assert(left_portrait == null or not bool(left_portrait.visible), "story frame hides the left portrait when the step side is right")
	_assert(right_portrait == null or bool(right_portrait.visible), "story frame shows the right portrait when the step side is right")

func _assert(condition: bool, label: String) -> void:
	if not condition:
		failures.append(label)

func _assert_eq(actual: Variant, expected: Variant, label: String) -> void:
	if actual != expected:
		failures.append("%s: expected %s, got %s" % [label, str(expected), str(actual)])

func _finish() -> void:
	if failures.is_empty():
		print("STORY_SCENE_RUNTIME_CONTRACT_OK")
		call_deferred("quit", 0)
		return
	for failure in failures:
		push_error(failure)
	call_deferred("quit", 1)
