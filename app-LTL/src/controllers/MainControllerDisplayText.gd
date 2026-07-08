# 계약:
# - 책임: MainController 로그, 상점, codex에서 쓰는 표시 문자열 변환을 분리한다.
# - 입력: artifact 모델, raw rarity/color/passive/shop ids, boolean toggle state.
# - 출력: TextCatalog를 거친 player-facing label 문자열.
# - 금지: view 접근, controller state 변경, run state 변경.
#
# 실행: define the display-text helper as a stateless reference script.
extends RefCounted

const TextCatalogScript = preload("res://src/ui/TextCatalog.gd")

# 실행: return a localized artifact name for player-facing logs.
static func artifact_display_name(artifact) -> String:
	if artifact == null:
		return ""
	return TextCatalogScript.localized_text(artifact.text, "name", TextCatalogScript.display_name(str(artifact.name)))

# 실행: localize an artifact rarity label with raw fallback.
static func artifact_rarity_label(raw_rarity: Variant) -> String:
	var rarity := str(raw_rarity).to_lower()
	var key := "rarity.%s" % rarity
	var label := TextCatalogScript.t(key)
	return str(raw_rarity) if label == key else label

# 실행: localize known energy colors and preserve unknown values visibly.
static func display_color_name(raw_color: String) -> String:
	var color_name := raw_color.to_lower()
	if color_name in ["red", "blue", "purple", "green"]:
		return TextCatalogScript.color_label(color_name)
	return raw_color.to_upper()

# 실행: localize a passive upgrade label with id fallback.
static func passive_display_label(passive_id: String) -> String:
	var key := "passive.%s.name" % passive_id
	var label := TextCatalogScript.t(key)
	return passive_id if label == key else label

# 실행: localize a base shop item label with id fallback.
static func base_shop_item_display_label(item_id: String) -> String:
	return TextCatalogScript.base_shop_label(item_id, item_id)

# 실행: localize a boolean toggle state label.
static func toggle_state_label(enabled: bool) -> String:
	return TextCatalogScript.t("common.on" if enabled else "common.off")
