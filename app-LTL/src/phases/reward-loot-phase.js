import { rollUiRewards } from "../vocabulary/reward/roll-ui-rewards.js";
import { pickUpFromInventory } from "../vocabulary/backpack/pick-up-from-inventory.js";
import { pickUpFromRewardTray } from "../vocabulary/backpack/pick-up-from-reward.js";
import { placeHeld } from "../vocabulary/backpack/place-held.js";
import { discardHeld } from "../vocabulary/backpack/discard-held.js";
import { rotateHeld } from "../vocabulary/backpack/held-item.js";
import { enterNodeSelect } from "./node-select-phase.js";
import { PHASE } from "./phase-tags.js";

export function enterRewardLoot(phase) {
  const rwSeed = phase.seed + phase.stageIndex * 1315423;
  return {
    tag: PHASE.REWARD_LOOT,
    seed: phase.seed,
    stageIndex: phase.stageIndex,
    maxStages: phase.maxStages,
    inventory: phase.inventory,
    pendingRewards: rollUiRewards(rwSeed, phase.lastClearWeakness),
    lastClearWeakness: phase.lastClearWeakness ?? [],
    lastNodeLabel: phase.lastNodeLabel ?? "",
    held: null
  };
}

export function reduceRewardLoot(phase, event) {
  switch (event.type) {
    case "pick_up_inventory": {
      const result = pickUpFromInventory(phase.inventory, event.row, event.col);
      if (!result) return phase;
      return { ...phase, inventory: result.inventory, held: result.held };
    }
    case "pick_up_reward": {
      const result = pickUpFromRewardTray(phase.pendingRewards, event.rewardId);
      if (!result) return phase;
      return { ...phase, held: result.held };
    }
    case "rotate_held": {
      if (!phase.held) return phase;
      return { ...phase, held: rotateHeld(phase.held) };
    }
    case "place": {
      if (!phase.held) return phase;
      const { inventory, held, consumedRewardId, placed } = placeHeld(
        phase.inventory,
        phase.held,
        event.row,
        event.col
      );
      if (!placed) return phase;
      let pendingRewards = phase.pendingRewards;
      if (consumedRewardId) {
        pendingRewards = pendingRewards.filter((r) => r.rewardId !== consumedRewardId);
      }
      return { ...phase, inventory, held, pendingRewards };
    }
    case "discard_held": {
      const { pendingRewards, held } = discardHeld(phase.pendingRewards, phase.held);
      return { ...phase, pendingRewards, held };
    }
    case "claim_rewards": {
      if (phase.pendingRewards.length > 0) return phase;
      const clearedFinal = phase.stageIndex >= phase.maxStages - 1;
      if (clearedFinal) {
        return {
          tag: PHASE.RUN_COMPLETE,
          seed: phase.seed,
          stageIndex: phase.stageIndex,
          maxStages: phase.maxStages,
          inventory: phase.inventory,
          lastNodeLabel: phase.lastNodeLabel
        };
      }
      const nextStage = phase.stageIndex + 1;
      return enterNodeSelect({
        seed: phase.seed,
        stageIndex: nextStage,
        maxStages: phase.maxStages,
        inventory: phase.inventory
      });
    }
    default:
      return phase;
  }
}
