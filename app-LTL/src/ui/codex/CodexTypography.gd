# 계약:
# - 책임: Codex V5의 번들 OFL 폰트 역할을 한 곳에서 제공한다.
# - 입력: 없음.
# - 출력: UI sans, 한글 editorial serif, Latin serif FontFile.
# - 금지: OS 시스템 글꼴을 acceptance baseline으로 사용하지 않는다.
class_name CodexTypography
extends RefCounted

const UI_FONT := preload("res://resources/fonts/codex/WorkSans-VariableFont_wght.ttf")
const KOREAN_SERIF_FONT := preload("res://resources/fonts/codex/NotoSerifKR-VariableFont_wght.ttf")
const LATIN_SERIF_FONT := preload("res://resources/fonts/codex/NotoSerif-VariableFont_wght.ttf")

static func ui_font() -> Font:
	return UI_FONT

static func korean_serif_font() -> Font:
	return KOREAN_SERIF_FONT

static func latin_serif_font() -> Font:
	return LATIN_SERIF_FONT
