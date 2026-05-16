/**
 * @param {string} energyType
 * @param {string} tileColor
 * @param {number} baseDamage
 */
export function calculateDamage(energyType, tileColor, baseDamage) {
  if (energyType === tileColor) {
    return { shield: baseDamage * 2, hp: baseDamage * 2, type: "match" };
  }
  return { shield: baseDamage * 0.2, hp: baseDamage * 0.2, type: "mismatch" };
}

const BASE_DAMAGE_BY_ENERGY = {
  red: 50,
  blue: 50,
  purple: 60,
  green: 80
};

export function baseDamageForEnergy(energyType) {
  return BASE_DAMAGE_BY_ENERGY[energyType] ?? 50;
}
