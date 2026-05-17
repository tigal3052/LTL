import { attachCombatPreview } from "./combat-phase.js";
import { offerNodeChoices } from "../vocabulary/node/offer-node-choices.js";
import { PHASE } from "./phase-tags.js";
import nodeTable from "../data/node-table.json" with { type: "json" };

export function enterNodeSelect({ seed, stageIndex, maxStages, inventory }) {
  return {
    tag: PHASE.NODE_SELECT,
    seed,
    stageIndex,
    maxStages,
    inventory,
    candidates: offerNodeChoices({ seed, stageIndex, table: nodeTable }),
    pendingRewards: [],
    lastClearWeakness: [],
    lastNodeLabel: "",
    held: null
  };
}

export function reduceNodeSelect(phase, event) {
  if (event.type !== "choose_node") return phase;
  const choice = phase.candidates[event.index];
  if (!choice) return phase;

  return attachCombatPreview({
    tag: PHASE.COMBAT_START,
    seed: phase.seed,
    stageIndex: phase.stageIndex,
    maxStages: phase.maxStages,
    inventory: phase.inventory,
    chosenNode: choice,
    lastClearWeakness: [...choice.combat.weakness],
    lastNodeLabel: choice.label,
    pendingRewards: [],
    held: null
  });
}
