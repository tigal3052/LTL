# 계약:
# - 책임: V5 도감의 고정 디자인 캔버스와 viewport fit geometry를 제공한다.
# - 입력: viewport size 또는 design rect.
# - 출력: 균일 scale, centered origin, V5 region metrics.
# - 금지: UI node 생성 및 state mutation.
#
# 실행: calculate V5 Codex geometry deterministically.
class_name ArtifactCodexLayoutPolicy
extends RefCounted

const DESIGN_SIZE := Vector2(1440.0, 900.0)
const BOOK_PIXEL_SIZE := DESIGN_SIZE # legacy compatibility for callers/tests.

static func canvas_transform_for_viewport(view_size: Vector2) -> Dictionary:
	var safe_size := Vector2(maxf(1.0, view_size.x), maxf(1.0, view_size.y))
	var scale := minf(safe_size.x / DESIGN_SIZE.x, safe_size.y / DESIGN_SIZE.y)
	var fitted := DESIGN_SIZE * scale
	return {"position": (safe_size - fitted) * 0.5, "scale": scale, "size": fitted}

static func v5_regions() -> Dictionary:
	return {
		"topBar": Rect2(0, 0, 1440, 80),
		"catalogHero": Rect2(40, 118, 740, 128),
		"catalogPanel": Rect2(40, 262, 740, 606),
		"detailPanel": Rect2(804, 118, 596, 750)
	}

# Retained for contract compatibility. V5 uses a two-column catalog/detail layout instead.
static func book_layout_metrics_for_rect(book_rect: Rect2) -> Dictionary:
	var scale := minf(book_rect.size.x / DESIGN_SIZE.x, book_rect.size.y / DESIGN_SIZE.y)
	return {"outerLeft": 40.0 * scale, "outerRight": 40.0 * scale, "outerTop": 80.0 * scale, "outerBottom": 32.0 * scale, "safeWidth": 1360.0 * scale, "safeHeight": 788.0 * scale, "pageWidth": 740.0 * scale, "pageHeight": 606.0 * scale, "gutter": 24.0 * scale, "pagePaddingX": 30.0 * scale, "pagePaddingY": 30.0 * scale, "headerHeight": 38.0 * scale, "tabsHeight": 38.0 * scale, "summaryHeight": 28.0 * scale, "pageGap": 14.0 * scale, "gridGap": 18.0 * scale, "gridColumns": 2, "cardWidth": 304.0 * scale, "cardHeight": 102.0 * scale, "heroHeight": 304.0 * scale}

static func book_transform_for_viewport(view_size: Vector2) -> Dictionary:
	return canvas_transform_for_viewport(view_size)
