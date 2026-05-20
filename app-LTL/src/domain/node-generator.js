import { createSeededRng } from "./seeded-rng.js";
import { computeStageCombatParams } from "./stage-scaling.js";

const ENERGY_TYPES = ["red", "blue", "purple", "green"];

function cloneNode(node) {
  return {
    id: node.id,
    label: node.label,
    weakness: [...(node.weakness ?? [])],
    pickWeight: node.pickWeight ?? 0,
    shieldMul: node.shieldMul ?? 1,
    healthMul: node.healthMul ?? 1,
    alwaysOffer: Boolean(node.alwaysOffer)
  };
}

function weightedPickWithoutReplacement(rng, pool, count) {
  const remaining = pool.map(cloneNode);
  const picked = [];

  while (picked.length < count && remaining.length > 0) {
    const total = remaining.reduce((sum, node) => sum + (node.pickWeight ?? 0), 0);
    if (total <= 0) break;
    let roll = rng.next() * total;
    let index = remaining.length - 1;

    for (let i = 0; i < remaining.length; i += 1) {
      roll -= remaining[i].pickWeight ?? 0;
      if (roll <= 0) {
        index = i;
        break;
      }
    }

    picked.push(remaining.splice(index, 1)[0]);
  }

  return picked;
}

export function generateNodeCandidates({
  seed,
  stageIndex,
  table,
  candidateCount = 3,
  scalingOverrides = {}
}) {
  const rng = createSeededRng((seed >>> 0) ^ ((stageIndex + 1) * 0x9e3779b9));
  const nodes = table.nodes ?? [];
  const normal = nodes.find((node) => node.alwaysOffer || node.id === "normal");
  if (!normal) {
    throw new Error("node table must include a normal node.");
  }

  const base = computeStageCombatParams(stageIndex, scalingOverrides);
  const extras = weightedPickWithoutReplacement(
    rng,
    nodes.filter((node) => !node.alwaysOffer && node.id !== "normal"),
    Math.max(0, candidateCount - 1)
  );

  const candidates = [cloneNode(normal), ...extras].slice(0, candidateCount);
  return candidates.map((candidate) => ({
    ...candidate,
    combat: {
      shield: base.shield * candidate.shieldMul,
      health: base.health * candidate.healthMul,
      timeLimitTicks: base.timeLimitTicks,
      weakness: [...candidate.weakness]
    }
  }));
}

export function isWeaknessEnergy(value) {
  return ENERGY_TYPES.includes(value);
}
