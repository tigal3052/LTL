extends RefCounted

static func bring_to_front(overlay: Control, z_index: int) -> void:
	if overlay == null:
		return
	overlay.z_index = z_index
	if overlay.get_parent() != null:
		overlay.move_to_front()

static func promote_when_visible(overlay: Control, z_index: int) -> void:
	if overlay == null or not overlay.visible:
		return
	bring_to_front(overlay, z_index)

static func pause_overlay_visible(settings_visible: bool, codex_visible: bool, repair_visible: bool) -> bool:
	return settings_visible or codex_visible or repair_visible
