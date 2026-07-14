# 계약:
# - 책임: 보급 캠프 상점 오버레이의 고정 디자인 캔버스와 viewport fit geometry를 제공한다.
# - 입력: viewport size.
# - 출력: 균일 scale, centered origin, region metrics.
# - 금지: UI node 생성 및 state mutation.
#
# 실행: calculate shop overlay geometry deterministically.
class_name ShopLayoutPolicy
extends RefCounted

const DESIGN_SIZE := Vector2(1440.0, 900.0)

# 실행: 디자인 캔버스를 뷰포트 안에 균일 스케일로 맞추고 중앙 정렬 원점을 돌려준다.
static func canvas_transform_for_viewport(view_size: Vector2) -> Dictionary:
	var safe_size := Vector2(maxf(1.0, view_size.x), maxf(1.0, view_size.y))
	var scale := minf(safe_size.x / DESIGN_SIZE.x, safe_size.y / DESIGN_SIZE.y)
	var fitted := DESIGN_SIZE * scale
	return {"position": (safe_size - fitted) * 0.5, "scale": scale, "size": fitted}

# 실행: 승인 목업(shop_r6)의 구획을 디자인 좌표계 Rect2로 노출한다.
static func regions() -> Dictionary:
	return {
		"overlayCard": Rect2(80, 40, 1280, 820),
		"header": Rect2(112, 68, 1216, 92),
		"catalog": Rect2(112, 198, 660, 578),
		"detail": Rect2(796, 198, 532, 578),
		"footer": Rect2(112, 796, 1216, 42)
	}

# 실행: 카탈로그 2열 그리드의 카드 규격과 간격을 제공한다.
static func catalog_grid_metrics() -> Dictionary:
	return {
		"columns": 2,
		"cardSize": Vector2(310.0, 62.0),
		"hSeparation": 8,
		"vSeparation": 8,
		"padding": Vector2(14.0, 12.0)
	}
