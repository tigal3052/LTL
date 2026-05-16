import { createHeldFromTable } from "./held-item.js";

/**
 * @returns {{ pendingRewards, held } | null}
 */
export function pickUpFromRewardTray(pendingRewards, rewardId) {
  const reward = pendingRewards.find((r) => r.rewardId === rewardId);
  if (!reward) return null;
  const held = createHeldFromTable(reward.tableId, reward.rotation ?? 0, "reward", reward.rewardId);
  return { pendingRewards, held };
}
