import test from "node:test";
import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { dirname, join } from "node:path";

import { generateNodeCandidates } from "../src/domain/node-generator.js";
import { rollStageRewards } from "../src/domain/reward-resolver.js";
import { RunProgression } from "../src/domain/run-progression.js";
import {
  computeStageCombatParams,
  marginalShieldDelta
} from "../src/domain/stage-scaling.js";

const __dirname = dirname(fileURLToPath(import.meta.url));
const nodeTablePath = join(__dirname, "../src/data/node-table.json");
const nodeTable = JSON.parse(readFileSync(nodeTablePath, "utf8"));

const fastScaling = {
  baseShield: 0.5,
  baseHealth: 0,
  baseTimeLimitTicks: 5000,
  peakShieldDelta: 0,
  peakHealthDelta: 0,
  peakTimeCutTicks: 0,
  minTimeLimitTicks: 4000
};

function autopilotOneClickClear(prog) {
  const snap = prog.snapshot();
  if (snap.phase === "node_select") {
    prog.selectNode(0);
    prog.applyCombatInput({ tick: 1, target: 0, input: "click" });
    return;
  }
  if (snap.phase === "combat") {
    prog.applyCombatInput({ tick: 1, target: 0, input: "click" });
  }
}

test("node candidates always include normal and are seed-stable", () => {
  const a = generateNodeCandidates({ seed: 42, stageIndex: 1, table: nodeTable });
  const b = generateNodeCandidates({ seed: 42, stageIndex: 1, table: nodeTable });
  assert.equal(a[0].id, "normal");
  assert.deepEqual(
    a.map((c) => c.id),
    b.map((c) => c.id)
  );
});

test("stage stats rise with stage index", () => {
  const s0 = computeStageCombatParams(0);
  const s2 = computeStageCombatParams(2);
  assert.ok(s2.shield > s0.shield);
  assert.ok(s2.health > s0.health);
  assert.ok(s2.timeLimitTicks <= s0.timeLimitTicks);
});

test("marginal growth is gentle early, steep mid, then tapers vs extremes", () => {
  const d0 = marginalShieldDelta(0);
  const d3 = marginalShieldDelta(3);
  const d10 = marginalShieldDelta(10);
  assert.ok(d3 > d0);
  assert.ok(d3 > d10);
});

test("mini-run loops clear → reward → node select → next combat for 5 stages", () => {
  const prog = new RunProgression({ seed: 9, maxStages: 5, scalingOverrides: fastScaling });

  assert.equal(prog.snapshot().phase, "node_select");
  prog.selectNode(0);
  assert.equal(prog.snapshot().phase, "combat");

  prog.applyCombatInput({ tick: 1, target: 0, input: "click" });
  let snap = prog.snapshot();
  assert.equal(snap.phase, "reward");
  assert.ok(snap.pendingRewards.length >= 1 && snap.pendingRewards.length <= 5);

  prog.claimRewards();
  snap = prog.snapshot();
  assert.equal(snap.phase, "node_select");
  assert.equal(snap.combatStageIndex, 1);

  for (let stage = 1; stage < 4; stage += 1) {
    autopilotOneClickClear(prog);
    prog.claimRewards();
    snap = prog.snapshot();
    assert.equal(snap.combatStageIndex, stage + 1);
    assert.equal(snap.phase, "node_select");
  }

  autopilotOneClickClear(prog);
  assert.equal(prog.snapshot().phase, "reward");

  prog.claimRewards();
  snap = prog.snapshot();
  assert.equal(snap.phase, "run_complete");
  assert.equal(snap.runComplete, true);
});

test("cleared weakness biases reward colors upward", () => {
  const trials = 2400;
  let redHits = 0;
  let total = 0;
  for (let i = 0; i < trials; i += 1) {
    const rewards = rollStageRewards({ seed: i, clearedWeaknesses: ["red"], weaknessBonus: 3 });
    for (const r of rewards) {
      total += 1;
      if (r.color === "red") redHits += 1;
    }
  }
  const p = redHits / total;
  assert.ok(p > 0.28, `expected red share > 0.28, got ${p}`);
});
