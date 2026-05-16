import { createCombatRuntime } from "../vocabulary/combat/create-combat-runtime.js";
import { combatToDisplay } from "../vocabulary/node/combat-to-display.js";
import { PHASE } from "./phase-tags.js";

function buildCombatRuntime(phase) {
  const display = combatToDisplay(phase.chosenNode.combat);
  return createCombatRuntime({
    display,
    seed: phase.seed,
    stageIndex: phase.stageIndex
  });
}

/** 노드 확정 직후 — Start 전에도 지형·스탯을 보여 준다. */
export function attachCombatPreview(phase) {
  if (!phase.chosenNode) return phase;
  return {
    ...phase,
    combat: buildCombatRuntime(phase),
    held: null
  };
}

export function enterCombat(phase) {
  if (!phase.chosenNode) {
    return phase;
  }
  return {
    tag: PHASE.COMBAT,
    seed: phase.seed,
    stageIndex: phase.stageIndex,
    maxStages: phase.maxStages,
    inventory: phase.inventory,
    chosenNode: phase.chosenNode,
    lastClearWeakness: phase.lastClearWeakness ?? [],
    lastNodeLabel: phase.lastNodeLabel ?? "",
    combat: buildCombatRuntime(phase),
    held: null
  };
}

export function reduceCombat(phase, event) {
  if (event.type === "set_hovered_tile") {
    if (!phase.combat) return phase;
    return {
      ...phase,
      combat: { ...phase.combat, hoveredTile: event.index }
    };
  }
  return phase;
}
