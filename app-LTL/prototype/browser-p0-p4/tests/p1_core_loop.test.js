import test from "node:test";
import assert from "node:assert/strict";

import { EnergyQueue } from "../src/domain/energy-queue.js";
import { BASE_COOLDOWN_TICKS } from "../src/domain/game-tuning.js";
import { InventoryModel } from "../src/domain/inventory-model.js";
import { MiningResolver } from "../src/domain/mining-resolver.js";
import { RunSimulator } from "../src/domain/run-simulator.js";
import { calculateDamage } from "../src/vocabulary/combat/calculate-damage.js";

test("energy queue counts generated, consumed, and wasted energy", () => {
  const queue = new EnergyQueue(2);

  queue.push("red");
  queue.push("blue");
  queue.push("green");

  assert.equal(queue.consume(), "red");
  assert.equal(queue.stats.generated, 3);
  assert.equal(queue.stats.consumed, 1);
  assert.equal(queue.stats.wasted, 1);
});

test("matching pulse deals bonus damage and mismatch is penalized", () => {
  const resolver = new MiningResolver();

  const match = resolver.resolveShot({
    energy: "red",
    target: { weakness: ["red"], shield: 10, health: 10, disabledUntil: -1 },
    tick: 1
  });
  const mismatch = resolver.resolveShot({
    energy: "blue",
    target: { weakness: ["red"], shield: 10, health: 10, disabledUntil: -1 },
    tick: 1
  });

  assert.equal(match.outcome, "match");
  assert.equal(mismatch.outcome, "mismatch");
  assert.ok(match.damage.shield > mismatch.damage.shield);
});

test("browser combat damage follows core combat spec for vulnerable, normal, and mismatch tiles", () => {
  const match = calculateDamage("red", "red", ["red"]);
  assert.equal(match.type, "match");
  assert.ok(Math.abs(match.shield - 0.75) < 1e-9);
  assert.ok(Math.abs(match.hp - 1.8) < 1e-9);

  const normal = calculateDamage("red", "blue", ["red"]);
  assert.equal(normal.type, "normal");
  assert.ok(Math.abs(normal.shield - 0.5) < 1e-9);
  assert.ok(Math.abs(normal.hp - 1.2) < 1e-9);

  const mismatch = calculateDamage("blue", "red", ["red"]);
  assert.equal(mismatch.type, "mismatch");
  assert.ok(Math.abs(mismatch.shield - 0.2) < 1e-9);
  assert.ok(Math.abs(mismatch.hp - 0.5) < 1e-9);
});

test("same tile is invalid while disabled", () => {
  const resolver = new MiningResolver({ tileCooldownTicks: 10 });
  const target = { weakness: ["red"], shield: 10, health: 10, disabledUntil: -1 };

  const first = resolver.resolveShot({ energy: "red", target, tick: 1 });
  const second = resolver.resolveShot({ energy: "red", target: first.target, tick: 5 });

  assert.equal(first.outcome, "match");
  assert.equal(second.outcome, "invalid_cooldown");
});

test("empty queue fire three times enters repair state", () => {
  const simulator = new RunSimulator({ seed: 1, queueCapacity: 0, node: { shield: 10, health: 10, weakness: ["red"] } });

  simulator.applyInput({ tick: 1, target: 0, input: "click" });
  simulator.applyInput({ tick: 2, target: 0, input: "click" });
  simulator.applyInput({ tick: 3, target: 0, input: "click" });

  assert.equal(simulator.snapshot().repairRequired, true);
  assert.equal(simulator.snapshot().durabilityLossCount, 3);
});

test("clear wins over time_over on the same tick", () => {
  const simulator = new RunSimulator({
    seed: 1,
    queueCapacity: 3,
    timeLimitTicks: 1,
    node: { shield: 0.75, health: 0, weakness: ["red"] }
  });

  simulator.energyQueue.push("red");
  simulator.applyInput({ tick: 1, target: 0, input: "click" });

  assert.equal(simulator.snapshot().result, "clear");
});

test("out-of-range target input is ignored without crashing", () => {
  const simulator = new RunSimulator({
    seed: 1,
    queueCapacity: 4,
    node: { shield: 1, health: 0, weakness: ["red"] }
  });

  const snapshot = simulator.applyInput({ tick: 1, target: 999, input: "click" });

  assert.equal(snapshot.result, "running");
  assert.equal(snapshot.summary.shots_fired, 1);
  assert.equal(snapshot.summary.invalid_target_inputs, 1);
  assert.equal(snapshot.summary.queue_consumed, 0);
  assert.equal(snapshot.action.feedback, "invalid_target");
});

test("run simulator uses injected inventory state for queue generation", () => {
  const inventory = new InventoryModel(8, 8);
  inventory.placeArtifact("basic_red", 0, 0, 0);

  const simulator = new RunSimulator({
    seed: 1,
    queueCapacity: 0,
    timeLimitTicks: BASE_COOLDOWN_TICKS + 5,
    node: { shield: 10, health: 10, weakness: ["red"] },
    inventory
  });

  const snapshot = simulator.applyInput({
    tick: BASE_COOLDOWN_TICKS + 1,
    target: 0,
    input: "click"
  });

  assert.ok(snapshot.summary.queue_generated > 0);
});
