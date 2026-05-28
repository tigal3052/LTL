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

var gold_label: Label
var xp_label: Label
var buttons: Dictionary = {}
var labels: Dictionary = {}
var current_state: Dictionary = {}

const PASSIVES := [
	{"id": "starting_gold_boost", "name": "초기 골드 증가", "desc": "+10 초기 골드. 비용: %d골드", "render_desc": "+10 초기 골드. 비용: %d골드 | 레벨: %d", "base_cost": 50, "step": 50},
	{"id": "cooldown_reduction", "name": "드릴 쿨다운 감소", "desc": "-5%% 드릴 쿨다운. 비용: %d골드", "render_desc": "-5%% 드릴 쿨다운. 비용: %d골드 | 레벨: %d", "base_cost": 75, "step": 75},
	{"id": "aim_damage_boost", "name": "조준 피해 증가", "desc": "+1 고정 피해. 비용: %d골드", "render_desc": "+1 고정 피해. 비용: %d골드 | 레벨: %d", "base_cost": 100, "step": 100}
]

# 실행: construct the dynamic shop panel once it enters the scene tree.
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
	var title = Label.new()
	title.text = "보정 상점"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", Color(0.3, 0.6, 0.95))
	box.add_child(title)
	var currency_row = HBoxContainer.new()
	currency_row.add_theme_constant_override("separation", 30)
	currency_row.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_child(currency_row)
	gold_label = Label.new()
	gold_label.text = "골드: 0"
	gold_label.add_theme_color_override("font_color", Color(0.95, 0.75, 0.25))
	currency_row.add_child(gold_label)
	xp_label = Label.new()
	xp_label.text = "경험치: 0"
	xp_label.add_theme_color_override("font_color", Color(0.3, 0.85, 0.4))
	currency_row.add_child(xp_label)
	box.add_child(HSeparator.new())
	var passives_box = VBoxContainer.new()
	passives_box.add_theme_constant_override("separation", 8)
	box.add_child(passives_box)
	for passive in PASSIVES:
		_add_passive_row(passives_box, passive)
	box.add_child(HSeparator.new())
	var close_button = Button.new()
	close_button.text = "닫기"
	close_button.pressed.connect(func(): visible = false)
	box.add_child(close_button)

# 실행: render shop currency, passive levels, costs, and button availability.
func render_shop(growth_state: Dictionary) -> void:
	current_state = growth_state.duplicate(true)
	var gold_val := int(growth_state.get("gold", 0))
	var xp_val := int(growth_state.get("xp", 0))
	gold_label.text = "골드: %d" % gold_val
	xp_label.text = "경험치: %d" % xp_val
	var purchased: Dictionary = growth_state.get("purchasedPassives", {})
	for passive in PASSIVES:
		var pid := str(passive["id"])
		var level := int(purchased.get(pid, 0))
		var cost := _cost_for(passive, level)
		if labels.has(pid):
			labels[pid].text = str(passive["render_desc"]) % [cost, level]
		if buttons.has(pid):
			buttons[pid].disabled = gold_val < cost
			buttons[pid].text = "구매 (%d골드)" % cost

# 실행: add one passive purchase row.
func _add_passive_row(parent: Control, passive: Dictionary) -> void:
	var row = HBoxContainer.new()
	parent.add_child(row)
	var label_vbox = VBoxContainer.new()
	label_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(label_vbox)
	var name_label = Label.new()
	name_label.text = str(passive["name"])
	name_label.add_theme_font_size_override("font_size", 12)
	name_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.95))
	label_vbox.add_child(name_label)
	var desc_label = Label.new()
	desc_label.text = str(passive["desc"]) % int(passive["base_cost"])
	desc_label.add_theme_font_size_override("font_size", 10)
	desc_label.add_theme_color_override("font_color", Color(0.65, 0.68, 0.72))
	label_vbox.add_child(desc_label)
	var passive_id := str(passive["id"])
	labels[passive_id] = desc_label
	var button = Button.new()
	button.text = "구매"
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
