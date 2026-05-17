import { createSeededRng } from "./seeded-rng.js";
import { computeStageCombatParams } from "./stage-scaling.js";

const ENERGIES = ["red", "blue", "purple", "green"];

function cloneNodeDef(def) {
  return {
    id: def.id,
    label: def.label,
    weakness: [...(def.weakness ?? [])],
    shieldMul: def.shieldMul ?? 1,
    healthMul: def.healthMul ?? 1,
    alwaysOffer: Boolean(def.alwaysOffer)
  };
}

function weightedPickWithoutReplacement(rng, pool, count) {
  const picked = [];
  const bag = pool.map((n) => ({ ...n, w: n.pickWeight ?? 0 }));

  while (picked.length < count && bag.length > 0) {
    const total = bag.reduce((s, n) => s + n.w, 0);
    if (total <= 0) break;
    let roll = rng.next() * total;
    let idx = 0;
    for (; idx < bag.length; idx += 1) {
      roll -= bag[idx].w;
      if (roll <= 0) break;
    }
    idx = Math.min(idx, bag.length - 1);
    const [choice] = bag.splice(idx, 1);
    picked.push(cloneNodeDef(choice));
  }
  return picked;
}

/**
 * @param {object} params
 * @param {number} params.seed
 * @param {number} params.stageIndex - scaling stage for this offer set
 * @param {object} params.table - parsed node-table `{ nodes: [...] }`
 * @param {number} [params.candidateCount=3]
 */
export function generateNodeCandidates({ seed, stageIndex, table, candidateCount = 3, scalingOverrides = {} } = {}) {
  const rng = createSeededRng((seed >>> 0) ^ ((stageIndex + 1) * 0x9e3779b9));
  const nodes = table.nodes ?? [];
  const normal = nodes.find((n) => n.alwaysOffer || n.id === "normal");
  if (!normal) {
    throw new Error("node table must include a normal node");
  }

  const base = computeStageCombatParams(stageIndex, scalingOverrides);
  const pool = nodes.filter((n) => !n.alwaysOffer && n.id !== "normal");
  const extrasNeeded = Math.max(0, candidateCount - 1);
  const extras = weightedPickWithoutReplacement(rng, pool, extrasNeeded);

  const raw = [cloneNodeDef(normal), ...extras];
  // De-dupe by id while preserving order
  const seen = new Set();
  const unique = [];
  for (const n of raw) {
    if (seen.has(n.id)) continue;
    seen.add(n.id);
    unique.push(n);
  }

  while (unique.length < candidateCount && pool.length > 0) {
    const filler = pool.find((p) => !seen.has(p.id));
    if (!filler) break;
    unique.push(cloneNodeDef(filler));
    seen.add(filler.id);
  }

  return unique.slice(0, candidateCount).map((n) => ({
    ...n,
    combat: {
      shield: base.shield * n.shieldMul,
      health: base.health * n.healthMul,
      timeLimitTicks: base.timeLimitTicks,
      weakness: [...n.weakness]
    }
  }));
}

export function isWeaknessEnergy(value) {
  return ENERGIES.includes(value);
}
