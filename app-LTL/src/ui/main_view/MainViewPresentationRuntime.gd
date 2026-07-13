class_name MainViewPresentationRuntime
extends RefCounted

const TextCatalogScript = preload("res://src/ui/TextCatalog.gd")
const LTLThemeScript = preload("res://src/ui/theme/LTLTheme.gd")

const CHARACTER_PORTRAIT_PATH := "res://resources/charactor/charactor1.png"
const CHARACTER_SPRITE_SHEET_PATH := "res://resources/charactor/charactor1_ss.png"
const REWARD_BACKDROP_PATH := "res://resources/Leviathan/Leviathan_lizard.png"
const FAILURE_BACKDROP_PATH := "res://resources/Leviathan/Leviathan_golem.png"

static func install_character_presentation(view) -> void:
	if view.portrait_placeholder == null:
		return
	view.portrait_art = view.portrait_placeholder.get_node_or_null("PortraitArt") as TextureRect
	if view.portrait_art == null:
		view.portrait_art = TextureRect.new()
		view.portrait_art.name = "PortraitArt"
		view.portrait_art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		view.portrait_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		view.portrait_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		view.portrait_art.texture = LTLThemeScript.art_texture(CHARACTER_PORTRAIT_PATH)
		view.portrait_art.self_modulate = Color(0.92, 0.92, 0.92, 0.95)
		view.portrait_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
		view.portrait_placeholder.add_child(view.portrait_art)
		view.portrait_placeholder.move_child(view.portrait_art, 0)
	view.portrait_idle = view.portrait_placeholder.get_node_or_null("PortraitIdle") as TextureRect
	if view.portrait_idle == null:
		view.portrait_idle = TextureRect.new()
		view.portrait_idle.name = "PortraitIdle"
		view.portrait_idle.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		view.portrait_idle.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
		view.portrait_idle.texture = character_sprite_frame(0)
		view.portrait_idle.size = Vector2(56.0, 82.0)
		view.portrait_idle.position = Vector2(view.portrait_placeholder.size.x - 58.0, 3.0)
		view.portrait_idle.mouse_filter = Control.MOUSE_FILTER_IGNORE
		view.portrait_idle.self_modulate = Color(1.0, 1.0, 1.0, 0.88)
		view.portrait_placeholder.add_child(view.portrait_idle)
	if view.portrait_label != null:
		view.portrait_label.visible = false
	var layout_callable := Callable(view, "_layout_character_presentation")
	if not view.portrait_placeholder.resized.is_connected(layout_callable):
		view.portrait_placeholder.resized.connect(layout_callable)
	view.call_deferred("_layout_character_presentation")

static func layout_character_presentation(view) -> void:
	if view.portrait_idle == null or view.portrait_placeholder == null:
		return
	var frame_size := Vector2(64.0, maxf(74.0, view.portrait_placeholder.size.y - 6.0))
	view.portrait_idle.size = frame_size
	view.portrait_idle.position = Vector2(maxf(6.0, view.portrait_placeholder.size.x - frame_size.x - 6.0), maxf(2.0, view.portrait_placeholder.size.y - frame_size.y - 2.0))

static func character_sprite_frame(index: int) -> Texture2D:
	var sheet := LTLThemeScript.art_texture(CHARACTER_SPRITE_SHEET_PATH)
	if sheet == null:
		return null
	var frame_width := 1024.0 / 5.0
	var frame_height := 1536.0 / 4.0
	var safe_index := posmod(index, 20)
	var column := safe_index % 5
	var row := int(floor(float(safe_index) / 5.0))
	return LTLThemeScript.atlas_frame(sheet, Rect2(column * frame_width, row * frame_height, frame_width, frame_height))

static func install_reward_backdrop(view) -> void:
	if view.reward_panel == null:
		return
	view.reward_backdrop = view.reward_panel.get_node_or_null("RewardBackdrop") as TextureRect
	if view.reward_backdrop == null:
		view.reward_backdrop = TextureRect.new()
		view.reward_backdrop.name = "RewardBackdrop"
		view.reward_backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		view.reward_backdrop.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		view.reward_backdrop.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		view.reward_backdrop.texture = LTLThemeScript.art_texture(REWARD_BACKDROP_PATH)
		view.reward_backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
		view.reward_backdrop.self_modulate = Color(0.58, 0.58, 0.58, 0.26)
		view.reward_panel.add_child(view.reward_backdrop)
		view.reward_panel.move_child(view.reward_backdrop, 0)

static func render_reward_backdrop(view, active: bool) -> void:
	if view.reward_backdrop == null:
		return
	view.reward_backdrop.visible = active

static func install_failure_backdrop(view) -> void:
	if view.repair_overlay == null or view.failure_backdrop != null:
		return
	view.failure_backdrop = TextureRect.new()
	view.failure_backdrop.name = "FailureBackdrop"
	view.failure_backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	view.failure_backdrop.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	view.failure_backdrop.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	view.failure_backdrop.texture = LTLThemeScript.art_texture(FAILURE_BACKDROP_PATH)
	view.failure_backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	view.failure_backdrop.self_modulate = Color(0.62, 0.30, 0.30, 0.24)
	view.repair_overlay.add_child(view.failure_backdrop)
	view.repair_overlay.move_child(view.failure_backdrop, 0)

static func render_failure_backdrop(view, scene: Dictionary) -> void:
	if view.failure_backdrop == null:
		return
	var overlay_active: bool = view.repair_overlay != null and view.repair_overlay.visible
	view.failure_backdrop.visible = overlay_active
	if not overlay_active:
		return
	var selected_leviathan: Dictionary = scene.get("selectedLeviathan", {})
	var art_path := str(selected_leviathan.get("artPath", FAILURE_BACKDROP_PATH))
	if art_path.is_empty():
		art_path = FAILURE_BACKDROP_PATH
	view.failure_backdrop.texture = LTLThemeScript.art_texture(art_path)

static func render_character_status(view, scene: Dictionary) -> void:
	if view.portrait_art == null:
		return
	var stage_index := int(scene.get("stageIndex", 0)) + 1
	var max_stages := maxi(1, int(scene.get("maxStages", 1)))
	var stage_label_text := TextCatalogScript.t("stage.label", [stage_index, max_stages])
	var selected_color := str(scene.get("selectedStartColor", scene.get("selectedColor", "red")))
	var selected_character: Dictionary = scene.get("selectedCharacter", {})
	var fallback_character_id := str(selected_character.get("id", "miner"))
	var character_name := str(selected_character.get("name", TextCatalogScript.character_text(
		fallback_character_id,
		"name",
		TextCatalogScript.t("character.contract_runner")
	)))
	var portrait_path := str(selected_character.get("portraitPath", CHARACTER_PORTRAIT_PATH))
	view.portrait_art.texture = LTLThemeScript.art_texture(portrait_path)
	# 전투 리디자인: 요약 라벨은 페이지 셸 번들 경로로 찾는다 (구 RootMargin 경로는 폐기됨).
	var summary_label := view.current_surface_node("TopContent/RightSidebar/Margin/SidebarBox/TabViewport/ExplorerContent/Margin/CharacterBox/InventorySummaryLabel") as RichTextLabel
	if summary_label != null:
		summary_label.add_theme_color_override("default_color", LTLThemeScript.INK_PRIMARY)
		summary_label.text = "[b]%s[/b]\n%s\n%s" % [
			TextCatalogScript.display_name(character_name),
			stage_label_text,
			TextCatalogScript.t("character.front_color", [TextCatalogScript.color_label(selected_color)])
		]
