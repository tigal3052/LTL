# 계약:
# - 책임: 사이드 패널의 텍스트 로그 기록을 읽기 쉬운 RichTextLabel로 출력한다.
# - 입력: 로그 스트림 메시지.
# - 출력: RichTextLabel에 정돈된 메시지 업데이트.
# - 금지: 통신 제어 컨트롤러 및 프레임 시뮬레이션 참조.
#
# 실행: define the Log Console UI controller as a RichTextLabel.
extends RichTextLabel

var log_history: Array[String] = []

# 실행: configure parchment-friendly log typography.
func _ready() -> void:
	bbcode_enabled = true
	scroll_following = true
	add_theme_font_size_override("normal_font_size", 10)
	add_theme_color_override("default_color", Color(0.18, 0.12, 0.07, 1.0))
	add_theme_color_override("font_shadow_color", Color(1.0, 0.92, 0.72, 0.35))
	add_theme_constant_override("shadow_offset_x", 1)
	add_theme_constant_override("shadow_offset_y", 1)

# 실행: add a line of log message and update UI.
func add_log(message: String) -> void:
	log_history.append(_parchment_log_color(message))
	if log_history.size() > 14:
		log_history.remove_at(0)
	text = "\n".join(log_history)

# 실행: clear the log history.
func clear_logs() -> void:
	log_history.clear()
	text = ""

# 실행: remap bright console colors to darker parchment-readable ink colors.
func _parchment_log_color(message: String) -> String:
	var value := message
	var replacements := {
		"#ffd766": "#5f4816",
		"#66c2cd": "#1f5d66",
		"#ff6666": "#7a2424",
		"#e05353": "#7a2424",
		"#a3be8c": "#35622d",
		"#8fa1b3": "#384a5a"
	}
	for key in replacements:
		value = value.replace(str(key), str(replacements[key]))
	return value
