import test from "node:test";
import assert from "node:assert/strict";

import { InventoryModel } from "../src/models/inventory.js";
import { enterNodeSelect } from "../src/phases/node-select-phase.js";
import { reduceRewardLoot } from "../src/phases/reward-loot-phase.js";
import { PHASE } from "../src/phases/phase-tags.js";

test("reduceRewardLoot allows claim when pending is empty", () => {
  const inventory = new InventoryModel(8, 8);
  let phase = enterNodeSelect({ seed: 9, stageIndex: 0, maxStages: 5, inventory });
  phase = {
    tag: PHASE.REWARD_LOOT,
    seed: 9,
    stageIndex: 0,
    maxStages: 5,
    inventory,
    pendingRewards: [],
    lastClearWeakness: [],
    lastNodeLabel: "normal",
    held: null
  };
  const next = reduceRewardLoot(phase, { type: "claim_rewards" });
  assert.equal(next.tag, PHASE.NODE_SELECT);
  assert.equal(next.stageIndex, 1);
});
