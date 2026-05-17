import { createRunSummary } from "./create-run-summary.js";
import { ENERGY_COLORS } from "../../tuning/mini-run-config.js";
import { createSeededRng } from "../../domain/seeded-rng.js";

function buildSeededColorPicker(seed) {
  const rng = createSeededRng(seed ^ 0x9e3779b9);
  return () => ENERGY_COLORS[rng.nextInt(ENERGY_COLORS.length)];
}

/**
 * @param {object} params
 * @param {{ runMaxShield: number, runMaxHp: number, timeRemaining: number }} params.display
 * @param {number} params.seed
 * @param {number} params.stageIndex
 * @param {number} [params.queueCapacity]
 * @param {string[]} [params.initialQueue]
 * @param {boolean} [params.gameStarted]
 * @param {number} [params.ticksPerSecond]
 * @param {string[]} [params.nodeWeakness]
 * @param {string} [params.nodeType]
 * @param {() => string} [params.pickColor]
 * @param {number} [params.timeProgressEveryTicks]
 * @param {number} [params.terrainScrollEveryTicks]
 */
export function createCombatRuntime({
  display,
  seed,
  stageIndex,
  queueCapacity = 8,
  initialQueue = [],
  gameStarted = false,
  ticksPerSecond = 20,
  nodeWeakness = ["red"],
  nodeType = "normal",
  pickColor = null,
  timeProgressEveryTicks = ticksPerSecond,
  terrainScrollEveryTicks = ticksPerSecond
}) {
  const nextColor = pickColor ?? buildSeededColorPicker(seed);
  const terrainColors = Array.from({ length: 3 }, () =>
    Array.from({ length: 10 }, () => nextColor())
  );
  const summary = createRunSummary({ seed, stageIndex });
  summary.node_type = nodeType;

  return {
    tick: 1,
    queue: [...initialQueue],
    queueCapacity,
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
    gameStarted,
    ticksPerSecond,
    timeProgressEveryTicks,
    terrainScrollEveryTicks,
    repairRequired: false,
    nodeWeakness: [...nodeWeakness],
    summary
  };
}
