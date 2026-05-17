import { PHASE } from "./phase-tags.js";
import { reduceNodeSelect } from "./node-select-phase.js";
import { reduceCombatStart } from "./combat-start-phase.js";
import { reduceCombat } from "./combat-phase.js";
import { enterCombatEnd } from "./combat-end-phase.js";
import { enterRewardLoot, reduceRewardLoot } from "./reward-loot-phase.js";

const REDUCERS = {
  [PHASE.NODE_SELECT]: reduceNodeSelect,
  [PHASE.COMBAT_START]: reduceCombatStart,
  [PHASE.COMBAT]: reduceCombat,
  [PHASE.REWARD_LOOT]: reduceRewardLoot
};

/**
 * @param {object} phase
 * @param {{ type: string }} event
 */
export function reduceMiniRunPhase(phase, event) {
  if (event.type === "stage_cleared") {
    if (phase.tag !== PHASE.COMBAT) {
      return phase;
    }
    const ended = enterCombatEnd(phase, "clear");
    return enterRewardLoot(ended);
  }

  const reducer = REDUCERS[phase.tag];
  if (!reducer) return phase;
  return reducer(phase, event);
}
