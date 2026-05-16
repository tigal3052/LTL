import { calculateDamage, baseDamageForEnergy } from "./calculate-damage.js";
import { applyNodeDamage } from "./apply-node-damage.js";
import { checkTimeProgress } from "./check-time-progress.js";
import { scrollTerrain } from "./scroll-terrain.js";
import { QUEUE_CAPACITY, TILE_SHOT_COOLDOWN_TICKS } from "./input-guard.js";

/**
 * @returns {{ combat: object, outcome: string, damage?: object, hitIndex?: number }}
 */
export function fireShot(combat, targetIndex) {
  if (combat.gameOver || combat.gameWon || !combat.gameStarted) {
    return { combat, outcome: "blocked" };
  }
  if (targetIndex == null) {
    return { combat, outcome: "no_target" };
  }

  const r = Math.floor(targetIndex / 10);
  const c = targetIndex % 10;
  const tileColor = combat.terrainColors[r][c];
  const isDisabled = combat.disabledUntil[targetIndex] > combat.tick;

  const summary = { ...combat.summary, shots_fired: combat.summary.shots_fired + 1 };

  if (combat.queue.length === 0) {
    return {
      combat: {
        ...combat,
        summary: {
          ...summary,
          shots_fired_empty_queue: summary.shots_fired_empty_queue + 1,
          durability_loss_count: summary.durability_loss_count + 1
        }
      },
      outcome: "empty_queue"
    };
  }

  const queue = [...combat.queue];
  summary.queue_consumed += 1;
  const energyType = queue.shift();

  if (isDisabled) {
    return {
      combat: {
        ...combat,
        queue,
        summary: {
          ...summary,
          shots_invalid_tile_cooldown: summary.shots_invalid_tile_cooldown + 1
        }
      },
      outcome: "invalid_cooldown"
    };
  }

  const damage = calculateDamage(energyType, tileColor, baseDamageForEnergy(energyType));
  if (damage.type === "match") summary.shots_hit_match += 1;
  else summary.shots_hit_mismatch += 1;

  const damaged = applyNodeDamage({ ...combat, queue, summary }, damage);
  const disabledUntil = [...damaged.disabledUntil];
  disabledUntil[targetIndex] = combat.tick + TILE_SHOT_COOLDOWN_TICKS;

  return {
    combat: { ...damaged, disabledUntil },
    outcome: "fired",
    damage,
    hitIndex: targetIndex
  };
}

/**
 * @param {object} combat
 * @param {import("../../domain/inventory-model.js").InventoryModel} inventory
 */
export function tickCombat(combat, inventory, { ticksPerSecond = 20, pickColor = () => "red" } = {}) {
  if (combat.gameOver || combat.gameWon || !combat.gameStarted) {
    return { combat, queueChanged: false, energies: [], pinBreak: null };
  }

  let next = { ...combat, tick: combat.tick + 1 };
  let queueChanged = false;
  let pinBreak = null;

  if (next.tick % ticksPerSecond === 0) {
    next = scrollTerrain(next, pickColor);
    const timeResult = checkTimeProgress(next);
    next = timeResult.combat;
    pinBreak = timeResult.pinBreak ?? null;
  }

  const energies = inventory.tick();
  const queue = [...next.queue];
  const summary = { ...next.summary };

  for (const e of energies) {
    summary.queue_generated += 1;
    if (queue.length < QUEUE_CAPACITY) {
      queue.push(e);
      queueChanged = true;
    } else {
      summary.queue_wasted += 1;
    }
  }

  return { combat: { ...next, queue, summary }, queueChanged, energies, pinBreak };
}
