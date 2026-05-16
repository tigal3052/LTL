import { createSeededRng } from "../../domain/seeded-rng.js";
import { COLOR_ARTIFACT_POOL } from "../../tuning/mini-run-config.js";

const REWARD_COUNT_WEIGHTS = [
  { count: 1, weight: 40 },
  { count: 2, weight: 30 },
  { count: 3, weight: 15 },
  { count: 4, weight: 10 },
  { count: 5, weight: 5 }
];

const ENERGY_COLORS = ["red", "blue", "purple", "green"];

function rollWeighted(rng, rows) {
  const total = rows.reduce((s, r) => s + r.weight, 0);
  let roll = rng.next() * total;
  for (const row of rows) {
    roll -= row.weight;
    if (roll <= 0) return row;
  }
  return rows[rows.length - 1];
}

function pickRewardColor(rng, clearedWeaknesses, weaknessBonus) {
  const weak = new Set((clearedWeaknesses ?? []).filter((c) => ENERGY_COLORS.includes(c)));
  const rows = ENERGY_COLORS.map((color) => ({
    color,
    weight: weak.has(color) ? weaknessBonus : 1
  }));
  return rollWeighted(rng, rows).color;
}

/**
 * UI reward chips: artifact table ids the player drags into the backpack.
 */
export function rollUiRewards(seed, clearedWeaknesses, weaknessBonus = 2) {
  const rng = createSeededRng((seed >>> 0) ^ 0x6a09e667);
  const count = rollWeighted(rng, REWARD_COUNT_WEIGHTS).count;
  const rewards = [];

  for (let i = 0; i < count; i += 1) {
    const color = pickRewardColor(rng, clearedWeaknesses, weaknessBonus);
    const pool = COLOR_ARTIFACT_POOL[color] ?? COLOR_ARTIFACT_POOL.red;
    const tableId = pool[rng.nextInt(pool.length)];
    rewards.push({
      rewardId: `rw-${seed}-${i}`,
      tableId,
      color,
      rotation: 0
    });
  }

  return rewards;
}
