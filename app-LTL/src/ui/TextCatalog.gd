# 계약:
# - 책임: UI에 표시되는 문장을 locale key 기반 동적 텍스트로 제공한다.
# - 입력: text key, locale, 선택적 format 인자.
# - 출력: 현재 locale에 맞는 표시 문자열.
# - 금지: gameplay 상태 변경, Control node 직접 접근.
#
# 실행: define the locale-aware text catalog backed by external JSON files.
class_name TextCatalog
extends RefCounted

const FALLBACK_LOCALE := "ko"
const LOCALE_PATHS := {
	"ko": "res://src/data/i18n/text-ko.json",
	"en": "res://src/data/i18n/text-en.json"
}

static var _locale: String = FALLBACK_LOCALE
static var _catalog_cache: Dictionary = {}

func catalog_source_path(locale: String) -> String:
	return _catalog_source_path(locale)

func debug_catalog(locale_override: String = "") -> Dictionary:
	return _catalog_for(locale_override).duplicate(true)

static func set_locale(locale: String) -> void:
	_locale = _normalized_locale(locale)

static func locale() -> String:
	return _locale

static func t(key: String, args: Array = [], locale_override: String = "") -> String:
	var table := _string_table(locale_override)
	var fallback_table := _string_table(FALLBACK_LOCALE)
	var value := str(table.get(key, fallback_table.get(key, key)))
	return _format(value, args)

static func localized_text(text_block: Variant, field: String, fallback: String = "", locale_override := "") -> String:
	var loc := _resolved_locale(locale_override)
	if text_block is Dictionary:
		var localized = text_block.get(field, {})
		if localized is Dictionary:
			var value := str(localized.get(loc, localized.get("en", localized.get("ko", fallback)))).strip_edges()
			if not value.is_empty():
				return value
	return fallback

static func reward_name(reward: Dictionary, locale_override := "") -> String:
	var fallback := display_name(str(reward.get("kind", "Unknown Reward")), locale_override)
	return localized_text(reward.get("text", {}), "name", fallback, locale_override)

static func reward_description(reward: Dictionary, locale_override := "") -> String:
	var fallback := display_description(str(reward.get("presentation", {}).get("description", "")), locale_override)
	return localized_text(reward.get("text", {}), "description", fallback, locale_override)

static func effect_summary(schema: Dictionary, locale_override := "") -> String:
	var loc := _resolved_locale(locale_override)
	var localized = schema.get("summary_i18n", {})
	if localized is Dictionary:
		var value := str(localized.get(loc, localized.get("en", localized.get("ko", "")))).strip_edges()
		if not value.is_empty():
			return value
	return str(schema.get("summary", "")).strip_edges()

static func display_name(raw_name: String, locale_override := "") -> String:
	var value := _strip_size_noise(raw_name)
	if _resolved_locale(locale_override) == "en":
		return value
	for key in _section_dict("displayNames", locale_override).keys():
		value = value.replace(str(key), str(_section_dict("displayNames", locale_override).get(key, key)))
	return value

static func display_description(raw_description: String, locale_override := "") -> String:
	var value := _strip_size_noise(raw_description).strip_edges()
	if _resolved_locale(locale_override) == "en":
		return value
	for key in _section_dict("displayDescriptions", locale_override).keys():
		value = value.replace(str(key), str(_section_dict("displayDescriptions", locale_override).get(key, key)))
	return value.strip_edges()

static func enum_label(group: String, value: String, locale_override := "") -> String:
	return t("%s.%s" % [group, value.to_lower()], [], locale_override)

static func hint_label(raw_hint: String, locale_override := "") -> String:
	var normalized := raw_hint.strip_edges().to_lower().replace("-", " ").replace("/", " ").replace(" ", "_")
	var key := "hint.%s" % normalized
	var table := _string_table(locale_override)
	return t(key, [], locale_override) if table.has(key) else raw_hint

static func color_label(color_name: String, locale_override := "") -> String:
	return t("color.%s" % color_name.to_lower(), [], locale_override)

static func item_label(item_type: String, locale_override := "") -> String:
	return t("item.%s" % item_type.to_lower(), [], locale_override)

static func character_text(character_id: String, field: String, fallback: String = "", locale_override := "") -> String:
	return entity_text("characters", character_id, field, fallback, locale_override)

static func character_tags(character_id: String, fallback: Array = [], locale_override := "") -> Array:
	return entity_array("characters", character_id, "tags", fallback, locale_override)

static func leviathan_text(leviathan_id: String, field: String, fallback: String = "", locale_override := "") -> String:
	return entity_text("leviathans", leviathan_id, field, fallback, locale_override)

static func base_shop_label(item_id: String, fallback: String = "", locale_override := "") -> String:
	return entity_text("baseShop", item_id, "label", fallback, locale_override)

static func entity_text(section: String, entry_id: String, field: String, fallback: String = "", locale_override := "") -> String:
	var entry := _section_entry(section, entry_id, locale_override)
	if entry.is_empty():
		return fallback
	var value := str(entry.get(field, fallback)).strip_edges()
	return value if not value.is_empty() else fallback

static func entity_array(section: String, entry_id: String, field: String, fallback: Array = [], locale_override := "") -> Array:
	var entry := _section_entry(section, entry_id, locale_override)
	if entry.is_empty():
		return fallback.duplicate(true)
	var value = entry.get(field, fallback)
	return value.duplicate(true) if value is Array else fallback.duplicate(true)

static func _resolved_locale(locale_override: String = "") -> String:
	if not locale_override.is_empty():
		return _normalized_locale(locale_override)
	return _normalized_locale(_locale)

static func _normalized_locale(locale_name: String) -> String:
	return locale_name if LOCALE_PATHS.has(locale_name) else FALLBACK_LOCALE

static func _catalog_source_path(locale_name: String) -> String:
	return str(LOCALE_PATHS.get(_normalized_locale(locale_name), LOCALE_PATHS[FALLBACK_LOCALE]))

static func _catalog_for(locale_override: String = "") -> Dictionary:
	var loc := _resolved_locale(locale_override)
	if _catalog_cache.has(loc):
		return _catalog_cache[loc]
	var data := _load_catalog(_catalog_source_path(loc))
	if data.is_empty() and loc != FALLBACK_LOCALE:
		data = _catalog_for(FALLBACK_LOCALE)
	if data.is_empty():
		data = {"strings": {}}
	_catalog_cache[loc] = data
	return data

static func _load_catalog(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var json := JSON.new()
	if json.parse(file.get_as_text()) != OK:
		return {}
	var data = json.get_data()
	return data if data is Dictionary else {}

static func _string_table(locale_override := "") -> Dictionary:
	var table = _catalog_for(locale_override).get("strings", {})
	return table if table is Dictionary else {}

static func _section_dict(section: String, locale_override := "") -> Dictionary:
	var data = _catalog_for(locale_override).get(section, {})
	return data if data is Dictionary else {}

static func _section_entry(section: String, entry_id: String, locale_override := "") -> Dictionary:
	var section_data := _section_dict(section, locale_override)
	var entry = section_data.get(entry_id, {})
	if entry is Dictionary:
		return entry
	if _resolved_locale(locale_override) != FALLBACK_LOCALE:
		return _section_entry(section, entry_id, FALLBACK_LOCALE)
	return {}

static func _format(value: String, args: Array) -> String:
	var result := value
	for index in range(args.size()):
		result = result.replace("{%d}" % index, str(args[index]))
	return result

static func _strip_size_noise(value: String) -> String:
	var result := value
	var regex := RegEx.new()
	if regex.compile("\\s+v\\d+\\b") == OK:
		result = regex.sub(result, "", true)
	if regex.compile("\\s*\\((Red|Blue|Purple|Green|red|blue|purple|green|빨강|파랑|보라|초록)\\)\\s*") == OK:
		result = regex.sub(result, " ", true)
	if regex.compile("\\b(Compact|Large|Small|Medium)\\s+\\d+x\\d+\\s+module\\.?\\s*") == OK:
		result = regex.sub(result, "", true)
	if regex.compile("\\s*\\(?\\d+x\\d+\\)?\\s*") == OK:
		result = regex.sub(result, " ", true)
	while result.contains("  "):
		result = result.replace("  ", " ")
	return result.strip_edges()
