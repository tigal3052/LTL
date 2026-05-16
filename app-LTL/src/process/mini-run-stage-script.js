import { enterNodeSelect } from "../phases/node-select-phase.js";
import { reduceMiniRunPhase } from "../phases/reduce-mini-run-phase.js";
import { MINI_RUN_MAX_STAGES, MINI_RUN_SEED } from "../tuning/mini-run-config.js";

/**
 * One stage loop in player-facing order. Reorder only here.
 * reward_loot and backpack_organize are merged in reward-loot-phase.js.
 */
export const STAGE_SENTENCE = [
  "node_select",
  "combat_start",
  "combat",
  "combat_end",
  "reward_loot",
  "backpack_organize"
];

export function startMiniRun({ seed = MINI_RUN_SEED, maxStages = MINI_RUN_MAX_STAGES, inventory }) {
  return enterNodeSelect({ seed, stageIndex: 0, maxStages, inventory });
}

export function advanceMiniRun(phase, event) {
  return reduceMiniRunPhase(phase, event);
}

export function isInventoryEditable(phase) {
  return phase.tag === "reward_loot";
}

export function lootReadyToContinue(phase) {
  return phase.tag === "reward_loot" && phase.pendingRewards.length === 0;
}
