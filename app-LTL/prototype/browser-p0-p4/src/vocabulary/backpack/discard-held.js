/**
 * @returns {{ pendingRewards, held: null }}
 */
export function discardHeld(pendingRewards, held) {
  if (!held) {
    return { pendingRewards, held: null };
  }
  if (held.source === "reward" && held.rewardId) {
    return {
      pendingRewards: pendingRewards.filter((r) => r.rewardId !== held.rewardId),
      held: null
    };
  }
  return { pendingRewards, held: null };
}
