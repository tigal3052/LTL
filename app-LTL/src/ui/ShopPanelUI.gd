# 계약:
# - 책임: calibration shop 패널의 동적 UI 생성과 렌더링을 캡슐화한다.
# - 입력: growth state Dictionary와 버튼 클릭 입력.
# - 출력: buy_passive(passive_id, cost) signal과 패널 visibility.
# - 금지: run state 직접 변경, MainController 직접 접근, combat/reward 규칙 계산.
#
# 실행: define the shop panel UI control.
class_name ShopPanelUI
extends PanelContainer

signal buy_passive(passive_id: String, cost: int)
signal buy_base_item(item_id: String)

const TextCatalogScript = preload("res://src/ui/TextCatalog.gd")
const ReleaseContentVocabScript = preload("res://src/vocabulary/ReleaseContentVocab.gd")

var title_label: Label
var gold_label: Label
var xp_label: Label
var close_button: Button
var passive_section_label: Label
var base_section_label: Label
var buttons: Dictionary = {}
var base_item_buttons: Dictionary = {}
var name_labels: Dictionary = {}
var desc_labels: Dictionary = {}
var base_item_labels: Dictionary = {}
var current_state: Dictionary = {}
var base_shop_items: Array = []

const SHOP_BUTTON_MIN := Vector2(132, 38)

const PASSIVES := [
	{"id": "starting_gold_boost", "base_cost": 50, "step": 50},
	{"id": "cooldown_reduction", "base_cost": 75, "step": 75},
	{"id": "aim_damage_boost", "base_cost": 100, "step": 100}
]

func _ready() -> void:
	visible = false
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.07, 0.09, 0.98)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.20, 0.34, 0.48, 1.0)
	style.corner_radius_top_left = 14
	style.corner_radius_top_right = 14
	style.corner_radius_bottom_right = 14
	style.corner_radius_bottom_left = 14
	style.shadow_size = 12
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.28)
	add_theme_stylebox_override("panel", style)
	var center = CenterContainer.new()
	add_child(center)
	var box = VBoxContainer.new()
	box.custom_minimum_size = Vector2(500, 380)
	box.add_theme_constant_override("separation", 16)
	var frame_margin := MarginContainer.new()
	frame_margin.add_theme_constant_override("margin_left", 20)
	frame_margin.add_theme_constant_override("margin_top", 20)
	frame_margin.add_theme_constant_override("margin_right", 20)
	frame_margin.add_theme_constant_override("margin_bottom", 20)
	center.add_child(frame_margin)
	frame_margin.add_child(box)
	title_label = Label.new()
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 22)
	title_label.add_theme_color_override("font_color", Color(0.79, 0.89, 1.0))
	box.add_child(title_label)
	var currency_row = HBoxContainer.new()
	currency_row.add_theme_constant_override("separation", 12)
	box.add_child(currency_row)
	gold_label = _build_currency_chip(Color(0.95, 0.78, 0.28), Color(0.28, 0.22, 0.08, 0.95))
	currency_row.add_child(gold_label)
	xp_label = _build_currency_chip(Color(0.54, 0.92, 0.64), Color(0.10, 0.24, 0.16, 0.95))
	currency_row.add_child(xp_label)
	passive_section_label = _build_section_label()
	box.add_child(passive_section_label)
	var passives_box = VBoxContainer.new()
	passives_box.add_theme_constant_override("separation", 10)
	box.add_child(passives_box)
	for passive in PASSIVES:
		_add_passive_row(passives_box, passive)
	base_section_label = _build_section_label()
	box.add_child(base_section_label)
	base_shop_items = ReleaseContentVocabScript.load_content_bundle().get("baseShop", [])
	var base_shop_box = VBoxContainer.new()
	base_shop_box.add_theme_constant_override("separation", 10)
	box.add_child(base_shop_box)
	for item in base_shop_items:
		_add_base_item_row(base_shop_box, item)
	close_button = Button.new()
	close_button.custom_minimum_size = SHOP_BUTTON_MIN
	_style_action_button(close_button, false)
	close_button.pressed.connect(func(): visible = false)
	box.add_child(close_button)
	apply_locale()

# 실행: refresh static shop text and rerender current state.
func apply_locale() -> void:
	if title_label == null:
		return
	title_label.text = TextCatalogScript.t("shop.title")
	if passive_section_label != null:
		passive_section_label.text = "PASSIVE TREE"
	if base_section_label != null:
		base_section_label.text = "BASE UNLOCKS"
	if close_button != null:
		close_button.text = TextCatalogScript.t("action.close")
	for passive in PASSIVES:
		var pid := str(passive["id"])
		if name_labels.has(pid):
			name_labels[pid].text = TextCatalogScript.t("passive.%s.name" % pid)
	if not current_state.is_empty():
		render_shop(current_state)
	else:
		gold_label.text = TextCatalogScript.t("shop.gold", [0])
		xp_label.text = TextCatalogScript.t("shop.xp", [0])
		for passive in PASSIVES:
			var pid := str(passive["id"])
			if desc_labels.has(pid):
				desc_labels[pid].text = TextCatalogScript.t("passive.%s.desc" % pid, [int(passive["base_cost"]), 0])
			if buttons.has(pid):
				buttons[pid].text = TextCatalogScript.t("shop.buy")
		for item in base_shop_items:
			var item_id := str(item.get("id", ""))
			if base_item_buttons.has(item_id):
				base_item_buttons[item_id].text = TextCatalogScript.t("shop.buy")

# 실행: render shop currency, passive levels, costs, and button availability.
func render_shop(growth_state: Dictionary) -> void:
	current_state = growth_state.duplicate(true)
	var gold_val := int(growth_state.get("gold", 0))
	var xp_val := int(growth_state.get("xp", 0))
	gold_label.text = TextCatalogScript.t("shop.gold", [gold_val])
	xp_label.text = TextCatalogScript.t("shop.xp", [xp_val])
	var purchased: Dictionary = growth_state.get("purchasedPassives", {})
	for passive in PASSIVES:
		var pid := str(passive["id"])
		var level := int(purchased.get(pid, 0))
		var cost := _cost_for(passive, level)
		if desc_labels.has(pid):
			desc_labels[pid].text = TextCatalogScript.t("passive.%s.desc" % pid, [cost, level])
		if buttons.has(pid):
			buttons[pid].disabled = gold_val < cost
			buttons[pid].text = TextCatalogScript.t("shop.buy_with_cost", [cost])
	var unlocked_characters: Array = growth_state.get("unlockedCharacters", [])
	var unlocked_items: Array = growth_state.get("unlockedStarterItems", [])
	var scan_unlocks: Array = growth_state.get("scanUnlocks", [])
	for item in base_shop_items:
		var item_id := str(item.get("id", ""))
		var unlock_id := str(item.get("unlockId", item_id))
		var cost_gold := int(item.get("costGold", 0))
		var cost_xp := int(item.get("costXp", 0))
		var owned := _is_base_item_owned(str(item.get("type", "")), unlock_id, unlocked_characters, unlocked_items, scan_unlocks)
		if base_item_labels.has(item_id):
			base_item_labels[item_id].text = "%s - %dG / %dXP" % [str(item.get("label", item_id)), cost_gold, cost_xp]
		if base_item_buttons.has(item_id):
			base_item_buttons[item_id].disabled = owned or gold_val < cost_gold or xp_val < cost_xp
			base_item_buttons[item_id].text = "Owned" if owned else "%dG %dXP" % [cost_gold, cost_xp]

# 실행: add one passive purchase row.
func _add_passive_row(parent: Control, passive: Dictionary) -> void:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _row_style())
	parent.add_child(panel)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 10)
	panel.add_child(margin)
	var row = HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 12)
	margin.add_child(row)
	var label_vbox = VBoxContainer.new()
	label_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label_vbox.add_theme_constant_override("separation", 4)
	row.add_child(label_vbox)
	var passive_id := str(passive["id"])
	var name_label = Label.new()
	name_label.add_theme_font_size_override("font_size", 13)
	name_label.add_theme_color_override("font_color", Color(0.93, 0.95, 0.98))
	label_vbox.add_child(name_label)
	var desc_label = Label.new()
	desc_label.add_theme_font_size_override("font_size", 11)
	desc_label.add_theme_color_override("font_color", Color(0.67, 0.74, 0.82))
	label_vbox.add_child(desc_label)
	name_labels[passive_id] = name_label
	desc_labels[passive_id] = desc_label
	var button = Button.new()
	button.custom_minimum_size = SHOP_BUTTON_MIN
	_style_action_button(button, true)
	row.add_child(button)
	buttons[passive_id] = button
	button.pressed.connect(func():
		var purchased: Dictionary = current_state.get("purchasedPassives", {})
		var level := int(purchased.get(passive_id, 0))
		buy_passive.emit(passive_id, _cost_for(passive, level))
	)

# ?ㅽ뻾: add one base item or character purchase row.
func _add_base_item_row(parent: Control, item: Dictionary) -> void:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _row_style())
	parent.add_child(panel)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 10)
	panel.add_child(margin)
	var row = HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 12)
	margin.add_child(row)
	var label = Label.new()
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", Color(0.82, 0.87, 0.92))
	row.add_child(label)
	var item_id := str(item.get("id", ""))
	base_item_labels[item_id] = label
	var button = Button.new()
	button.custom_minimum_size = SHOP_BUTTON_MIN
	_style_action_button(button, true)
	row.add_child(button)
	base_item_buttons[item_id] = button
	button.pressed.connect(func():
		buy_base_item.emit(item_id)
	)

# 실행: calculate passive purchase cost by level.
func _cost_for(passive: Dictionary, level: int) -> int:
	return int(passive["base_cost"]) + level * int(passive["step"])

# ?ㅽ뻾: check whether an unlock row is already owned.
func _is_base_item_owned(item_type: String, unlock_id: String, characters: Array, starter_items: Array, scans: Array) -> bool:
	match item_type:
		"character":
			return unlock_id in characters
		"starter_item":
			return unlock_id in starter_items
		"scan":
			return unlock_id in scans
	return false

func _build_section_label() -> Label:
	var label := Label.new()
	label.add_theme_font_size_override("font_size", 11)
	label.add_theme_color_override("font_color", Color(0.49, 0.69, 0.88))
	return label

func _build_currency_chip(font_color: Color, bg_color: Color) -> Label:
	var label := Label.new()
	label.add_theme_font_size_override("font_size", 13)
	label.add_theme_color_override("font_color", font_color)
	label.add_theme_stylebox_override("normal", _chip_style(bg_color))
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return label

func _style_action_button(button: Button, accent: bool) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.12, 0.16, 0.21, 1.0) if accent else Color(0.10, 0.12, 0.16, 1.0)
	normal.border_color = Color(0.28, 0.45, 0.62, 1.0) if accent else Color(0.24, 0.28, 0.34, 1.0)
	normal.border_width_left = 1
	normal.border_width_top = 1
	normal.border_width_right = 1
	normal.border_width_bottom = 1
	normal.corner_radius_top_left = 9
	normal.corner_radius_top_right = 9
	normal.corner_radius_bottom_right = 9
	normal.corner_radius_bottom_left = 9
	var disabled := normal.duplicate()
	disabled.bg_color = Color(0.08, 0.10, 0.12, 0.92)
	disabled.border_color = Color(0.18, 0.20, 0.24, 0.95)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", _brightened_style(normal, 0.06))
	button.add_theme_stylebox_override("pressed", _brightened_style(normal, -0.03))
	button.add_theme_stylebox_override("disabled", disabled)
	button.add_theme_color_override("font_color", Color(0.92, 0.96, 1.0))
	button.add_theme_color_override("font_disabled_color", Color(0.46, 0.50, 0.56))

func _row_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.11, 0.15, 0.96)
	style.border_color = Color(0.16, 0.25, 0.34, 1.0)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_right = 10
	style.corner_radius_bottom_left = 10
	return style

func _chip_style(bg_color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_right = 10
	style.corner_radius_bottom_left = 10
	style.content_margin_left = 10
	style.content_margin_top = 8
	style.content_margin_right = 10
	style.content_margin_bottom = 8
	return style

func _brightened_style(base: StyleBoxFlat, amount: float) -> StyleBoxFlat:
	var style: StyleBoxFlat = base.duplicate()
	style.bg_color = style.bg_color.lightened(amount) if amount >= 0.0 else style.bg_color.darkened(-amount)
	return style
