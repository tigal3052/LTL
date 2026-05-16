import { ENERGY_COLORS } from "../../tuning/mini-run-config.js";

/**
 * [프로토타입 임시조치] NODE_SELECT 때 `phase.combat`이 없어 지형만 비어 보이는 문제를 막기 위한
 * 렌더 전용 스냅샷이다. 실제 전투 시뮬과 무관하며, 이후 로비/전투 UI 모델이 분리되면 제거·대체 예정.
 */
export function lobbyTerrainRenderState(seed = 0) {
  const colors = Array.from({ length: 3 }, (_, r) =>
    Array.from({ length: 10 }, (_, c) => {
      const i = (r * 10 + c + (seed >>> 0)) % ENERGY_COLORS.length;
      return ENERGY_COLORS[i];
    })
  );
  return {
    terrainColors: colors,
    disabledUntil: Array(30).fill(-1),
    tick: 0,
    hoveredTile: null
  };
}

export function bindTerrainGrid(terrainEl, { onHover, onMouseDown, onMouseUp, onMouseLeave }) {
  if (!terrainEl || terrainEl.children.length > 0) return;
  for (let i = 0; i < 30; i += 1) {
    const tile = document.createElement("div");
    tile.textContent = String(i + 1);
    tile.dataset.index = String(i);
    tile.addEventListener("mouseenter", () => onHover(i));
    tile.addEventListener("mousedown", (e) => onMouseDown(i, e));
    tile.addEventListener("mouseup", onMouseUp);
    tile.addEventListener("mouseleave", () => onMouseLeave(i));
    terrainEl.append(tile);
  }
}

export function renderTerrain(terrainEl, combat) {
  if (!terrainEl || !combat) return;
  for (let i = 0; i < 30; i += 1) {
    const r = Math.floor(i / 10);
    const c = i % 10;
    const color = combat.terrainColors[r][c];
    const tile = terrainEl.children[i];
    if (!tile) continue;
    let newClass = `tile ${color}`;
    if (combat.hoveredTile === i) newClass += " hovered";
    if (combat.disabledUntil[i] > combat.tick) newClass += " disabled";
    if (tile.classList.contains("hit")) newClass += " hit";
    tile.className = newClass;
  }
}
