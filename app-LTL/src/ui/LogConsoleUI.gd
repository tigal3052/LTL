# 계약:
# - 책임: 사이드 패널에 텍스트 로그 기록을 포맷팅하여 출력한다.
# - 입력: 로그 스트링 메시지.
# - 출력: RichTextLabel에 출력 메시지 업데이트.
# - 금지: 핵심 제어 컨트롤러 및 도메인 시뮬레이터 참조.
# 실행: define the Log Console UI controller as a RichTextLabel.
extends RichTextLabel
var log_history: Array[String] = []

# 실행: add a line of log message and update UI.
func add_log(message: String) -> void:
	log_history.append(message)
	if log_history.size() > 18:
		log_history.remove_at(0)
	text = "\n".join(log_history)

# 실행: clear the log history.
func clear_logs() -> void:
	log_history.clear()
	text = ""
