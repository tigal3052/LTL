# 계약:
# - 책임: held artifact를 시계방향으로 90도 회전한다.
# - 입력: held Artifact.
# - 출력: { ok, held, code } dictionary.
# - 금지: inventory 변경, reward tray 변경, UI 접근.
#
# 실행: define the RotateHeld vocabulary function holder.
class_name RotateHeld
extends RefCounted

# 실행: rotate the held artifact in place.
static func rotate(held: Artifact) -> Dictionary:
	if held == null:
		return {"ok": false, "code": "missing_held", "held": null}
	held.rotate_shape()
	return {"ok": true, "code": "rotated", "held": held}
