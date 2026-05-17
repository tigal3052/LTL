import { recalculateSynergy } from "./recalculate-synergy.js";

/**
 * @returns {{ inventory, held: null, consumedRewardId?: string, placed: boolean }}
 */
export function placeHeld(inventory, held, row, col) {
  if (!held) {
    return { inventory, held: null, placed: false };
  }
  const result = inventory.placeArtifact(held.tableId, col, row, held.rotation);
  if (result === false) {
    return { inventory, held, placed: false };
  }
  recalculateSynergy(inventory);
  const consumedRewardId = held.source === "reward" ? held.rewardId : undefined;
  return { inventory, held: null, consumedRewardId, placed: true };
}
