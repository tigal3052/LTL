const DAMAGE_BY_ENERGY = {
  red: { shield: 0.5, hp: 1.2 },
  blue: { shield: 1.5, hp: 0.75 },
  purple: { shield: 0.75, hp: 0.75 },
  green: { shield: 0, hp: 1.0 }
};

/**
 * Core combat damage spec:
 * - vulnerable pulse + matching energy: base x 1.5
 * - normal terrain: base x 1.0
 * - vulnerable pulse + mismatching energy: fixed penalty damage
 */
export function calculateDamage(energyType, tileColor, nodeWeakness = []) {
  const base = DAMAGE_BY_ENERGY[energyType] ?? DAMAGE_BY_ENERGY.red;
  const weakness = new Set(nodeWeakness ?? []);
  const isVulnerablePulse = weakness.has(tileColor);

  if (!isVulnerablePulse) {
    return { shield: base.shield, hp: base.hp, type: "normal" };
  }

  if (energyType === tileColor) {
    return { shield: base.shield * 1.5, hp: base.hp * 1.5, type: "match" };
  }

  return { shield: 0.2, hp: 0.5, type: "mismatch" };
}
