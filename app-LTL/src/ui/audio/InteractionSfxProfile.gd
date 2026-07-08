extends RefCounted
static func duration_for(category: String) -> float:
	match category:
		"typewriter_tick":
			return 0.035
		"ui_confirm":
			return 0.14
		"ui_cancel":
			return 0.12
		"ui_toggle", "starter_set_select", "item_place", "dialogue_advance":
			return 0.12
		"battle_start":
			return 0.30
		"settings_open", "settings_close":
			return 0.22
		"codex_open", "codex_close":
			return 0.28
		"menu_open", "menu_close":
			return 0.26
		"page_transition":
			return 0.36
		"item_fusion":
			return 0.18
		"fusion_buildup":
			return 0.46
		"fusion_complete":
			return 0.30
		"reward_expectation":
			return 0.80
		"reward_count_fanfare":
			return 0.42
		"excavation_buildup":
			return 0.74
		"excavation_detail_fanfare":
			return 0.46
		"drag_start", "drag_drop", "drag_cancel":
			return 0.10
	return 0.08

static func frequency_for(category: String) -> float:
	match category:
		"typewriter_tick":
			return 900.0
		"ui_confirm":
			return 420.0
		"ui_cancel":
			return 210.0
		"ui_toggle":
			return 280.0
		"battle_start":
			return 150.0
		"starter_set_select":
			return 360.0
		"settings_open":
			return 330.0
		"settings_close":
			return 230.0
		"codex_open":
			return 260.0
		"codex_close":
			return 190.0
		"item_click":
			return 480.0
		"item_place":
			return 250.0
		"dialogue_advance":
			return 360.0
		"reward_expectation":
			return 300.0
		"reward_count_fanfare":
			return 520.0
		"excavation_buildup":
			return 130.0
		"excavation_detail_fanfare":
			return 410.0
		"menu_open":
			return 260.0
		"menu_close":
			return 190.0
		"page_transition":
			return 150.0
		"drag_start":
			return 240.0
		"drag_drop":
			return 300.0
		"item_fusion":
			return 340.0
		"fusion_buildup":
			return 170.0
		"fusion_complete":
			return 520.0
		"drag_cancel":
			return 170.0
	return 320.0

static func interval_for(category: String) -> float:
	match category:
		"ui_confirm", "menu_open", "drag_drop", "item_fusion", "starter_set_select", "settings_open", "codex_open", "reward_count_fanfare":
			return 1.5
		"fusion_buildup":
			return 1.25
		"fusion_complete":
			return 1.72
		"battle_start":
			return 2.0
		"item_place", "dialogue_advance":
			return 1.33
		"reward_expectation":
			return 1.42
		"excavation_buildup":
			return 1.18
		"excavation_detail_fanfare":
			return 1.72
		"page_transition":
			return 1.25
		"ui_cancel", "menu_close", "drag_cancel", "settings_close", "codex_close":
			return 0.75
		"drag_start":
			return 1.2
	return 1.0
