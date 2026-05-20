import test from "node:test";
import assert from "node:assert/strict";

import {
  createHeadlessRun,
  createSceneReadModel,
  loadArtifactTable,
  loadLeviathanTable,
  loadNodeTable,
  loadProgressData,
  loadRewardTable,
  runReplay
} from "../src/index.js";

const artifactTable = {
  artifacts: [
    {
      id: "basic_red",
      name: "Red Generator",
      shape: [[1, 1]],
      energyType: "red",
      baseCooldownTicks: 100,
      synergy: "same_color",
      keyword: "starter"
    }
  ]
};

const nodeTable = {
  nodes: [
    {
      id: "normal",
      label: "Normal Node",
      weakness: ["red"],
      pickWeight: 0,
      shieldMul: 0.2,
      healthMul: 1,
      alwaysOffer: true
    },
    {
      id: "crimson_vein",
      label: "Crimson Vein",
      weakness: ["red"],
      pickWeight: 35,
      shieldMul: 0.2,
      healthMul: 1
    }
  ]
};

const rewardTable = {
  rewards: [
    {
      id: "reward_basic_red",
      artifactId: "basic_red",
      kind: "artifact",
      color: "red",
      qty: 1
    }
  ]
};

const leviathanTable = {
  leviathans: [
    {
      id: "tutorial_leviathan",
      name: "Tutorial Leviathan",
      stageCnt: 1,
      runCnt: 2
    }
  ]
};

const progressData = {
  clearedLeviathanIds: []
};

test("validators reject required-field omissions across all M1 contracts", () => {
  const artifact = loadArtifactTable({
    input: { artifacts: [{ ...artifactTable.artifacts[0], keyword: undefined }] },
    source: "artifact-fixture"
  });
  assert.equal(artifact.ok, false);
  assert.equal(artifact.errors[0].path, "artifacts[0].keyword");

  const node = loadNodeTable({
    input: { nodes: [{ ...nodeTable.nodes[1], label: undefined }] },
    source: "node-fixture"
  });
  assert.equal(node.ok, false);
  assert.equal(node.errors[0].path, "nodes[0].label");

  const reward = loadRewardTable({
    input: { rewards: [{ ...rewardTable.rewards[0], artifactId: undefined }] },
    source: "reward-fixture"
  });
  assert.equal(reward.ok, false);
  assert.equal(reward.errors[0].path, "rewards[0].artifactId");

  const leviathan = loadLeviathanTable({
    input: { leviathans: [{ ...leviathanTable.leviathans[0], runCnt: undefined }] },
    source: "leviathan-fixture"
  });
  assert.equal(leviathan.ok, false);
  assert.equal(leviathan.errors[0].path, "leviathans[0].runCnt");

  const progress = loadProgressData({
    input: {},
    source: "progress-fixture"
  });
  assert.equal(progress.ok, false);
  assert.equal(progress.errors[0].path, "clearedLeviathanIds");
});

test("headless run exposes the stabilized root and phase-state contracts", () => {
  const run = createHeadlessRun({
    artifacts: artifactTable,
    nodes: nodeTable,
    rewards: rewardTable,
    leviathans: leviathanTable,
    progress: progressData,
    seed: 7,
    leviathanId: "tutorial_leviathan"
  });

  const start = run.snapshot();
  assert.equal(start.phase, "node_select");
  assert.equal(start.seed, 7);
  assert.equal(start.stageIndex, 0);
  assert.equal(start.maxStages, 1);
  assert.equal(start.leviathanId, "tutorial_leviathan");
  assert.equal(start.runIndex, 0);
  assert.ok(Array.isArray(start.inventory.placed));
  assert.ok(Array.isArray(start.candidates));
  assert.equal("combat" in start, false);

  run.selectNode(0);
  const combat = run.snapshot();
  assert.equal(combat.phase, "combat");
  assert.ok(combat.combat);
  assert.equal("candidates" in combat, false);

  run.applyCombatInput({ tick: 1, target: 0, input: "click" });
  const reward = run.snapshot();
  assert.equal(reward.phase, "reward_loot");
  assert.ok(Array.isArray(reward.pendingRewards));
  assert.equal(reward.held, null);
  assert.equal(reward.lastNodeLabel, "Normal Node");
  assert.equal("combat" in reward, false);
});

test("scene read-model renders from the public snapshot without private internals", () => {
  const run = createHeadlessRun({
    artifacts: artifactTable,
    nodes: nodeTable,
    rewards: rewardTable,
    leviathans: leviathanTable,
    progress: progressData,
    seed: 9,
    leviathanId: "tutorial_leviathan"
  });

  const readModel = createSceneReadModel(run.snapshot());
  assert.equal(readModel.phase, "node_select");
  assert.equal(readModel.run.seed, 9);
  assert.equal(readModel.run.leviathanId, "tutorial_leviathan");
  assert.equal(Array.isArray(readModel.nodeSelect.candidates), true);
  assert.equal("simulator" in readModel, false);
  assert.equal("history" in readModel, false);
});

test("replay runner covers reward transition and run-complete branching", () => {
  const nextRun = runReplay({
    fixture: {
      seed: 21,
      leviathanId: "tutorial_leviathan",
      runIndex: 0,
      stageCount: 1,
      runCount: 2,
      inputLog: [{ tick: 1, target: 0, input: "click" }]
    },
    artifacts: artifactTable,
    nodes: nodeTable,
    rewards: rewardTable,
    leviathans: leviathanTable,
    progress: progressData
  });
  assert.equal(nextRun.summary.result, "next_run");
  assert.equal(nextRun.finalSnapshot.phase, "node_select");
  assert.equal(nextRun.finalSnapshot.runIndex, 1);

  const leviathanClear = runReplay({
    fixture: {
      seed: 21,
      leviathanId: "tutorial_leviathan",
      runIndex: 1,
      stageCount: 1,
      runCount: 2,
      inputLog: [{ tick: 1, target: 0, input: "click" }]
    },
    artifacts: artifactTable,
    nodes: nodeTable,
    rewards: rewardTable,
    leviathans: leviathanTable,
    progress: progressData
  });
  assert.equal(leviathanClear.summary.result, "leviathan_clear");
  assert.equal(leviathanClear.finalSnapshot.phase, "run_complete");
  assert.deepEqual(leviathanClear.finalSnapshot.progress.clearedLeviathanIds, ["tutorial_leviathan"]);
});

test("replay runner preserves the promoted empty-queue repair scenario", () => {
  const result = runReplay({
    fixture: {
      seed: 1,
      queueCapacity: 0,
      leviathanId: "tutorial_leviathan",
      stageCount: 1,
      runCount: 1,
      inputLog: [
        { tick: 1, target: 0, input: "click" },
        { tick: 2, target: 0, input: "click" },
        { tick: 3, target: 0, input: "click" }
      ]
    },
    artifacts: artifactTable,
    nodes: nodeTable,
    rewards: rewardTable,
    leviathans: leviathanTable,
    progress: progressData
  });

  assert.equal(result.summary.result, "repair_required");
  assert.equal(result.summary.shots_fired_empty_queue, 3);
  assert.equal(result.finalSnapshot.phase, "failed");
});

test("paired match vs mismatch replay fixtures stay distinguishable in result and summary", () => {
  const match = runReplay({
    fixture: {
      seed: 33,
      leviathanId: "tutorial_leviathan",
      stageCount: 1,
      runCount: 1,
      initialQueue: ["red"],
      inputLog: [{ tick: 1, target: 0, input: "click" }]
    },
    artifacts: artifactTable,
    nodes: nodeTable,
    rewards: rewardTable,
    leviathans: leviathanTable,
    progress: progressData
  });

  const mismatch = runReplay({
    fixture: {
      seed: 33,
      leviathanId: "tutorial_leviathan",
      stageCount: 1,
      runCount: 1,
      initialQueue: ["blue"],
      inputLog: [{ tick: 1, target: 0, input: "click" }]
    },
    artifacts: artifactTable,
    nodes: nodeTable,
    rewards: rewardTable,
    leviathans: leviathanTable,
    progress: progressData
  });

  assert.equal(match.summary.result, "leviathan_clear");
  assert.equal(match.summary.shots_hit_match, 1);
  assert.equal(match.summary.shots_hit_mismatch, 0);

  assert.equal(mismatch.summary.result, "combat");
  assert.equal(mismatch.summary.shots_hit_match, 0);
  assert.equal(mismatch.summary.shots_hit_mismatch, 1);
  assert.equal(mismatch.finalSnapshot.phase, "combat");
});

test("reward phase allows holding the last artifact for reposition without violating the guard", () => {
  const run = createHeadlessRun({
    artifacts: artifactTable,
    nodes: nodeTable,
    rewards: rewardTable,
    leviathans: leviathanTable,
    progress: progressData,
    seed: 12,
    leviathanId: "tutorial_leviathan"
  });

  run.selectNode(0);
  run.applyCombatInput({ tick: 1, target: 0, input: "click" });

  const before = run.snapshot();
  assert.equal(before.phase, "reward_loot");
  assert.equal(before.inventory.placed.length, 1);

  const instanceId = before.inventory.placed[0].instanceId;
  run.pickUpPlacedArtifact(instanceId);
  const held = run.snapshot();
  assert.equal(held.phase, "reward_loot");
  assert.equal(held.inventory.placed.length, 0);
  assert.ok(held.inventory.held);

  run.placeHeldArtifact({ x: 2, y: 1, rotation: 0 });
  const after = run.snapshot();
  assert.equal(after.inventory.held, null);
  assert.equal(after.inventory.placed.length, 1);
  assert.equal(after.inventory.placed[0].x, 2);
  assert.equal(after.inventory.placed[0].y, 1);
});

test("reward phase rejects finalizing an empty inventory when the last artifact is held", () => {
  const run = createHeadlessRun({
    artifacts: artifactTable,
    nodes: nodeTable,
    rewards: rewardTable,
    leviathans: leviathanTable,
    progress: progressData,
    seed: 14,
    leviathanId: "tutorial_leviathan"
  });

  run.selectNode(0);
  run.applyCombatInput({ tick: 1, target: 0, input: "click" });

  const instanceId = run.snapshot().inventory.placed[0].instanceId;
  run.pickUpPlacedArtifact(instanceId);
  run.discardHeldArtifact();

  const guarded = run.snapshot();
  assert.equal(guarded.phase, "reward_loot");
  assert.equal(guarded.inventory.held, null);
  assert.equal(guarded.inventory.placed.length, 1);
  assert.equal(guarded.inventory.lastGuardReason, "last_artifact_guard");
});
