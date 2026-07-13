# 계약:
# - Responsibility: unify the node-select header chrome with the shared leviathan-select header design.
# - Input: a NodeSelectRuntimePage owner exposing header nodes, chip panels, and state.
# - Output: a styled HeaderBar strip, brand title, fact-pill chips, and variant05 utility buttons.
# - Prohibited: mutating gameplay state, changing node tree paths locked by other contracts.
#
# 실행: apply and re-apply the unified header chrome theme on every render.
class_name NodeSelectHeaderChrome
extends RefCounted

const LeviathanSelectChromeBitsScript = preload("res://src/scenes/pages/leviathan_select/LeviathanSelectChromeBits.gd")
const NodeSelectVisualFactoryScript = preload("res://src/scenes/pages/node_select/NodeSelectVisualFactory.gd")
const NodeSelectContentModelScript = preload("res://src/scenes/pages/node_select/NodeSelectContentModel.gd")
const LTLThemeScript = preload("res://src/ui/theme/LTLTheme.gd")
const CHIP_TEXTURE_PATH := "res://resources/node_select/atlas/chip_ruin_tablet.png"

# 실행: idempotently create the header chrome nodes once, then re-apply styling on every call.
static func apply(page) -> void:
	var board_head: HBoxContainer = page.get_node("Margin/VStack/BoardShell/ShellMargin/ShellVBox/BoardHead")
	var page_root: Control = page

	var header_bar := page_root.get_node_or_null("HeaderBar") as Panel
	if header_bar == null:
		header_bar = Panel.new()
		header_bar.name = "HeaderBar"
		header_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		header_bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
		header_bar.anchor_left = 0.0
		header_bar.anchor_right = 1.0
		header_bar.anchor_top = 0.0
		header_bar.anchor_bottom = 0.0
		header_bar.offset_left = 0.0
		header_bar.offset_right = 0.0
		header_bar.offset_top = 0.0
		header_bar.offset_bottom = 76.0
		page_root.add_child(header_bar)
		page_root.move_child(header_bar, 1)
	var header_style: StyleBoxFlat = LTLThemeScript.surface_style(Color(0.95, 0.91, 0.82, 0.98), Color(0.78, 0.74, 0.65, 0.22), 0, 0, 0.08)
	header_style.shadow_size = 0
	header_bar.add_theme_stylebox_override("panel", header_style)

	board_head.custom_minimum_size = Vector2(0.0, 76.0)
	board_head.add_theme_constant_override("separation", 16)

	var pad_left := board_head.get_node_or_null("HeaderPadLeft") as Control
	if pad_left == null:
		pad_left = Control.new()
		pad_left.name = "HeaderPadLeft"
		pad_left.mouse_filter = Control.MOUSE_FILTER_IGNORE
		pad_left.custom_minimum_size = Vector2(LeviathanSelectChromeBitsScript.TOP_GROUP_HEADER_LEFT_PAD, 0.0)
		board_head.add_child(pad_left)
		board_head.move_child(pad_left, 0)

	var pad_right := board_head.get_node_or_null("HeaderPadRight") as Control
	if pad_right == null:
		pad_right = Control.new()
		pad_right.name = "HeaderPadRight"
		pad_right.mouse_filter = Control.MOUSE_FILTER_IGNORE
		pad_right.custom_minimum_size = Vector2(LeviathanSelectChromeBitsScript.TOP_GROUP_HEADER_RIGHT_PAD, 0.0)
		board_head.add_child(pad_right)
	board_head.move_child(pad_right, board_head.get_child_count() - 1)

	var board_lead: VBoxContainer = board_head.get_node("BoardLead")
	board_lead.alignment = BoxContainer.ALIGNMENT_CENTER
	board_lead.add_theme_constant_override("separation", 2)

	var title_chips: HBoxContainer = board_head.get_node("TitleChips")
	title_chips.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	title_chips.add_theme_constant_override("separation", 12)

	page.board_label.add_theme_font_size_override("font_size", 10)
	page.board_label.add_theme_color_override("font_color", Color(0.153, 0.278, 0.212, 0.66))
	page.leviathan_title.add_theme_font_size_override("font_size", 20)
	page.leviathan_title.add_theme_color_override("font_color", Color(0.153, 0.278, 0.212, 1.0))
	page.leviathan_title.add_theme_font_override("font", LeviathanSelectChromeBitsScript._copy_weighted_font(LTLThemeScript, 700))

	for chip in [page.run_chip_panel, page.stage_chip_panel]:
		var chip_style: StyleBoxFlat = NodeSelectVisualFactoryScript.panel_style(Color(0, 0, 0, 0.0), Color(0, 0, 0, 0.0), 0, 0)
		chip_style.content_margin_left = 24
		chip_style.content_margin_right = 24
		chip_style.content_margin_top = 11
		chip_style.content_margin_bottom = 11
		chip.add_theme_stylebox_override("panel", chip_style)
		chip.custom_minimum_size = Vector2(146.0, 42.0)

		var chip_label := chip.get_node("ChipLabel") as Label
		var frame := chip_label.get_node_or_null("ChipFrameBg") as TextureRect
		if frame == null:
			frame = TextureRect.new()
			frame.name = "ChipFrameBg"
			frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
			frame.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			frame.stretch_mode = TextureRect.STRETCH_SCALE
			frame.show_behind_parent = true
			chip_label.add_child(frame)
		frame.set_anchors_preset(Control.PRESET_FULL_RECT)
		frame.offset_left = -24.0
		frame.offset_top = -11.0
		frame.offset_right = 24.0
		frame.offset_bottom = 11.0
		frame.texture = LTLThemeScript.art_texture(CHIP_TEXTURE_PATH)

		chip_label.add_theme_font_size_override("font_size", 13)
		chip_label.add_theme_font_override("font", LeviathanSelectChromeBitsScript._copy_weighted_font(LTLThemeScript, 700))
		chip_label.add_theme_color_override("font_color", Color(0.93, 0.95, 0.89, 1.0))
		chip_label.add_theme_constant_override("outline_size", 3)
		chip_label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.45))
		chip_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		chip_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		chip_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		chip_label.size_flags_vertical = Control.SIZE_EXPAND_FILL

	for utility_button in [page.codex_button, page.settings_button]:
		utility_button.custom_minimum_size = Vector2(108.0, 40.0)
		utility_button.flat = false
		utility_button.focus_mode = Control.FOCUS_NONE
		utility_button.alignment = HORIZONTAL_ALIGNMENT_CENTER
		utility_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		LeviathanSelectChromeBitsScript.apply_variant05_top_group_theme(utility_button, LTLThemeScript, false)

	page.shop_button.custom_minimum_size = Vector2(108.0, 40.0)
	page.shop_button.flat = false
	page.shop_button.focus_mode = Control.FOCUS_NONE
	page.shop_button.alignment = HORIZONTAL_ALIGNMENT_CENTER
	page.shop_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	LeviathanSelectChromeBitsScript.apply_variant05_top_group_theme(page.shop_button, LTLThemeScript, false)
	page.shop_button.visible = page.SHOP_ENABLED
	page.shop_button.disabled = not page.SHOP_ENABLED

# 실행: gate the run/stage chip visibility to the mid-run window (leviathan chosen, run not yet complete).
static func update_chips(page) -> void:
	var chips_on := NodeSelectContentModelScript.chips_visible(page._state)
	page.run_chip_panel.visible = chips_on
	page.stage_chip_panel.visible = chips_on
