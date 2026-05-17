import test from "node:test";
import assert from "node:assert/strict";

import { STAGE_SENTENCE } from "../src/process/mini-run-stage-script.js";
import { assertStageFlowOrder, nextStageTag } from "../src/process/stage-sentence.js";

test("STAGE_SENTENCE includes core loop tags in order", () => {
  assertStageFlowOrder();
  const idxCombat = STAGE_SENTENCE.indexOf("combat");
  const idxLoot = STAGE_SENTENCE.indexOf("reward_loot");
  assert.ok(idxCombat >= 0 && idxLoot > idxCombat);
});

test("nextStageTag walks the sentence", () => {
  assert.equal(nextStageTag("node_select"), "combat_start");
  assert.equal(nextStageTag("combat_start"), "combat");
  assert.equal(nextStageTag("combat"), "combat_end");
});
