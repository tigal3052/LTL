import { createSeededRng } from "./seeded-rng.js";

const DEFAULT_COUNT_WEIGHTS = [
  { count: 1, weight: 40 },
  { count: 2, weight: 30 },
  { count: 3, weight: 15 },
  { count: 4, weight: 10 },
  { count: 5, weight: 5 }
];

const DEFAULT_KIND_WEIGHTS = [
  { kind: "aether_shard", weight: 25 },
  { kind: "signal_cache", weight: 20 },
  { kind: "resonance_dust", weight: 18 },
  { kind: "pulse_battery", weight: 15 },
  { kind: "hazard_insurance", weight: 12 },
  { kind: "tuning_gear", weight: 10 }
];

const ENERGY_COLORS = ["red", "blue", "purple", "green"];

function isWeaknessEnergy(value) {
  return ENERGY_COLORS.includes(value);
}

function rollWeighted(rng, rows, weightKey = "weight") {
  const total = rows.reduce((s, r) => s + r[weightKey], 0);
  if (total <= 0) {
    return rows[0];
  }
  let roll = rng.next() * total;
  for (const row of rows) {
    roll -= row[weightKey];
    if (roll <= 0) return row;
  }
  return rows[rows.length - 1];
}

function pickRewardColor(rng, clearedWeaknesses, weaknessBonus) {
  const weak = new Set((clearedWeaknesses ?? []).filter(isWeaknessEnergy));
  const rows = ENERGY_COLORS.map((color) => ({
    color,
    weight: weak.has(color) ? weaknessBonus : 1
  }));
  return rollWeighted(rng, rows).color;
}

/**
 * @param {object} params
 * @param {number} params.seed
 * @param {string[]} params.clearedWeaknesses
 * @param {typeof DEFAULT_COUNT_WEIGHTS} [params.countWeights]
 * @param {typeof DEFAULT_KIND_WEIGHTS} [params.kindWeights]
 * @param {number} [params.weaknessBonus=2]
 */
export function rollStageRewards({
  seed,
  clearedWeaknesses,
  countWeights = DEFAULT_COUNT_WEIGHTS,
  kindWeights = DEFAULT_KIND_WEIGHTS,
  weaknessBonus = 2
}) {
  if (typeof seed !== "number") {
    throw new TypeError("rollStageRewards requires seed");
  }
  const rng = createSeededRng((seed >>> 0) ^ 0x6a09e667);
  const countRow = rollWeighted(rng, countWeights);
  const count = countRow.count;
  const rewards = [];

  for (let i = 0; i < count; i += 1) {
    const kindPick = rollWeighted(rng, kindWeights);
    const color = pickRewardColor(rng, clearedWeaknesses, weaknessBonus);
    rewards.push({
      kind: kindPick.kind,
      color,
      qty: 1 + rng.nextInt(3)
    });
  }

  return rewards;
}

export { DEFAULT_COUNT_WEIGHTS, DEFAULT_KIND_WEIGHTS };
