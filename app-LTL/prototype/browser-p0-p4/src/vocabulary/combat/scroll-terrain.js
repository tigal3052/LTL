/**
 * @param {object} combat
 * @param {(colors: string[]) => string} pickColor
 */
export function scrollTerrain(combat, pickColor) {
  const terrainColors = combat.terrainColors.map((row) => [...row]);
  for (let r = 0; r < 3; r += 1) {
    for (let c = 9; c > 0; c -= 1) {
      terrainColors[r][c] = terrainColors[r][c - 1];
    }
    terrainColors[r][0] = pickColor();
  }

  const disabledUntil = Array(30).fill(-1);
  for (let r = 0; r < 3; r += 1) {
    for (let c = 9; c > 0; c -= 1) {
      disabledUntil[r * 10 + c] = combat.disabledUntil[r * 10 + (c - 1)];
    }
  }

  return { ...combat, terrainColors, disabledUntil };
}
