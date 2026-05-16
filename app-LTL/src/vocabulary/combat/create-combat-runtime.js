import { createRunSummary } from "./create-run-summary.js";
import { ENERGY_COLORS } from "../../tuning/mini-run-config.js";

function randomEnergyColor() {
  return ENERGY_COLORS[Math.floor(Math.random() * ENERGY_COLORS.length)];
}

/**
 * @param {object} params
 * @param {{ runMaxShield: number, runMaxHp: number, timeRemaining: number }} params.display
 * @param {number} params.seed
 * @param {number} params.stageIndex
 */
export function createCombatRuntime({ display, seed, stageIndex }) {
  const terrainColors = Array.from({ length: 3 }, () =>
    Array.from({ length: 10 }, () => randomEnergyColor())
  );

  return {
    tick: 1,
    queue: [],
    terrainColors,
    disabledUntil: Array.from({ length: 30 }, () => -1),
    hoveredTile: null,
    runMaxShield: display.runMaxShield,
    runMaxHp: display.runMaxHp,
    nodeShield: display.runMaxShield,
    nodeHp: display.runMaxHp,
    timeRemaining: display.timeRemaining,
    stageInitialTime: display.timeRemaining,
    pins: 4,
    gameOver: false,
    gameWon: false,
    gameStarted: false,
    summary: createRunSummary({ seed, stageIndex })
  };
}
