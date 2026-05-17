import { PHASE } from "./phase-tags.js";
import { enterCombat } from "./combat-phase.js";

export function reduceCombatStart(phase, event) {
  if (event.type !== "begin_combat") return phase;

  if (phase.combat) {
    return {
      ...phase,
      tag: PHASE.COMBAT,
      combat: { ...phase.combat, gameStarted: true }
    };
  }

  const next = enterCombat(phase);
  if (!next.combat) return phase;
  return {
    ...next,
    combat: { ...next.combat, gameStarted: true }
  };
}
