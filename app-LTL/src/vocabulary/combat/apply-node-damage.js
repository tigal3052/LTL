/**
 * @param {object} combat
 * @param {{ shield: number, hp: number }} dmg
 */
export function applyNodeDamage(combat, dmg) {
  let nodeShield = combat.nodeShield - Math.min(combat.nodeShield, dmg.shield);
  let nodeHp = combat.nodeHp;
  if (nodeShield <= 0) {
    nodeHp -= dmg.hp;
  }
  const cleared = nodeHp <= 0;
  if (cleared) {
    nodeHp = 0;
  }
  return {
    ...combat,
    nodeShield,
    nodeHp,
    gameWon: cleared || combat.gameWon
  };
}
