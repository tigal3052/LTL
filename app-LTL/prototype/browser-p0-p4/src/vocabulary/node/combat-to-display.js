import { computeStageCombatParams } from "../../domain/stage-scaling.js";

const DISPLAY_BASE = {
  baseShield: 2.4,
  baseHealth: 3.2,
  runMaxShield: 500,
  runMaxHp: 1000,
  ticksPerSecond: 20
};

/**
 * Maps domain combat caps to UI shield/HP/time labels.
 */
export function combatToDisplay(combat) {
  return {
    runMaxShield: Math.max(
      1,
      Math.round(combat.shield * (DISPLAY_BASE.runMaxShield / DISPLAY_BASE.baseShield))
    ),
    runMaxHp: Math.max(
      1,
      Math.round(combat.health * (DISPLAY_BASE.runMaxHp / DISPLAY_BASE.baseHealth))
    ),
    timeRemaining: Math.max(10, Math.round(combat.timeLimitTicks / DISPLAY_BASE.ticksPerSecond))
  };
}

export function combatCapsForStage(stageIndex, scalingOverrides = {}) {
  return computeStageCombatParams(stageIndex, scalingOverrides);
}
