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

const TextCatalogScript = preload("res://src/ui/TextCatalog.gd")

var title_label: Label
var gold_label: Label
var xp_label: Label
var close_button: Button
var buttons: Dictionary = {}
var name_labels: Dictionary = {}
var desc_labels: Dictionary = {}
var current_state: Dictionary = {}

const PASSIVES := [
	{"id": "starting_gold_boost", "base_cost": 50, "step": 50},
	{"id": "cooldown_reduction", "base_cost": 75, "step": 75},
	{"id": "aim_damage_boost", "base_cost": 100, "step": 100}
]

func _ready() -> void:
	visible = false
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.08, 0.10, 0.96)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.24, 0.35, 0.50, 1.0)
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_right = 12
	style.corner_radius_bottom_left = 12
	add_theme_stylebox_override("panel", style)
	var center = CenterContainer.new()
	add_child(center)
	var box = VBoxContainer.new()
	box.custom_minimum_size = Vector2(420, 280)
	box.add_theme_constant_override("separation", 14)
	center.add_child(box)
	title_label = Label.new()
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 16)
	title_label.add_theme_color_override("font_color", Color(0.3, 0.6, 0.95))
	box.add_child(title_label)
	var currency_row = HBoxContainer.new()
	currency_row.add_theme_constant_override("separation", 30)
	currency_row.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_child(currency_row)
	gold_label = Label.new()
	gold_label.add_theme_color_override("font_color", Color(0.95, 0.75, 0.25))
	currency_row.add_child(gold_label)
	xp_label = Label.new()
	xp_label.add_theme_color_override("font_color", Color(0.3, 0.85, 0.4))
	currency_row.add_child(xp_label)
	box.add_child(HSeparator.new())
	var passives_box = VBoxContainer.new()
	passives_box.add_theme_constant_override("separation", 8)
	box.add_child(passives_box)
	for passive in PASSIVES:
		_add_passive_row(passives_box, passive)
	box.add_child(HSeparator.new())
	close_button = Button.new()
	close_button.pressed.connect(func(): visible = false)
	box.add_child(close_button)
	apply_locale()

# 실행: refresh static shop text and rerender current state.
func apply_locale() -> void:
	if title_label == null:
		return
	title_label.text = TextCatalogScript.t("shop.title")
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

# 실행: add one passive purchase row.
func _add_passive_row(parent: Control, passive: Dictionary) -> void:
	var row = HBoxContainer.new()
	parent.add_child(row)
	var label_vbox = VBoxContainer.new()
	label_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(label_vbox)
	var passive_id := str(passive["id"])
	var name_label = Label.new()
	name_label.add_theme_font_size_override("font_size", 12)
	name_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.95))
	label_vbox.add_child(name_label)
	var desc_label = Label.new()
	desc_label.add_theme_font_size_override("font_size", 10)
	desc_label.add_theme_color_override("font_color", Color(0.65, 0.68, 0.72))
	label_vbox.add_child(desc_label)
	name_labels[passive_id] = name_label
	desc_labels[passive_id] = desc_label
	var button = Button.new()
	button.custom_minimum_size = Vector2(100, 24)
	row.add_child(button)
	buttons[passive_id] = button
	button.pressed.connect(func():
		var purchased: Dictionary = current_state.get("purchasedPassives", {})
		var level := int(purchased.get(passive_id, 0))
		buy_passive.emit(passive_id, _cost_for(passive, level))
	)

# 실행: calculate passive purchase cost by level.
func _cost_for(passive: Dictionary, level: int) -> int:
	return int(passive["base_cost"]) + level * int(passive["step"])
