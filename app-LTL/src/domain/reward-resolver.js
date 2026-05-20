import { createSeededRng } from "./seeded-rng.js";

const ENERGY_TYPES = ["red", "blue", "purple", "green"];

function pickColor(rng, templateColor, clearedWeaknesses) {
  if (templateColor && clearedWeaknesses.includes(templateColor)) {
    return templateColor;
  }
  if (templateColor) {
    return templateColor;
  }
  return ENERGY_TYPES[rng.nextInt(ENERGY_TYPES.length)];
}

export function resolveStageRewards({
  seed,
  stageIndex,
  runIndex,
  rewardTable,
  clearedWeaknesses = []
}) {
  const rewardDefs = rewardTable?.rewards ?? [];
  if (rewardDefs.length === 0) {
    return [];
  }

  const rng = createSeededRng((seed >>> 0) ^ ((stageIndex + 1) * 0x85ebca6b) ^ ((runIndex + 1) * 0xc2b2ae35));
  const template = rewardDefs[rng.nextInt(rewardDefs.length)];

  return [
    {
      ...template,
      id: `${template.id}:${runIndex}:${stageIndex}:0`,
      color: pickColor(rng, template.color, clearedWeaknesses)
    }
  ];
}

export function rollStageRewards(options) {
  return resolveStageRewards(options);
}
