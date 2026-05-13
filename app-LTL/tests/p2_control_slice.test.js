import test from "node:test";
import assert from "node:assert/strict";

import { RunSimulator } from "../src/domain/run-simulator.js";
import { CombatController } from "../src/combat-controller.js";

function createController(options = {}) {
  const simulator = new RunSimulator({
    seed: 20260513,
    queueCapacity: 4,
    node: { shield: 3, health: 2, weakness: ["red"] },
    ...options.simulator
  });

  return new CombatController({
    simulator,
    fireIntervalTicks: 2,
    ...options.controller
  });
}

test("hover always tracks exactly one tile", () => {
  const controller = createController();

  controller.hoverTile(4);
  controller.hoverTile(12);

  assert.equal(controller.state.hoveredTile, 12);
});

test("single click records one input and fires one shot", () => {
  const controller = createController();

  controller.hoverTile(0);
  const snapshot = controller.clickAtTick(1);

  assert.equal(controller.inputLog.length, 1);
  assert.equal(snapshot.summary.shots_fired, 1);
  assert.equal(snapshot.summary.queue_consumed, 1);
});

test("hold fire repeats every 0.1 seconds", () => {
  const controller = createController();

  controller.hoverTile(0);
  controller.startHoldAtTick(1);
  controller.advanceToTick(5);
  controller.stopHold();

  assert.deepEqual(
    controller.inputLog.map((entry) => entry.tick),
    [1, 3, 5]
  );
  assert.equal(controller.lastSnapshot.summary.shots_fired, 3);
});

test("cooldown shots are counted as invalid feedback", () => {
  const controller = createController();

  controller.hoverTile(0);
  controller.clickAtTick(1);
  const snapshot = controller.clickAtTick(2);

  assert.equal(snapshot.summary.shots_invalid_tile_cooldown, 1);
  assert.equal(controller.state.feedback, "invalid_cooldown");
});

test("empty queue click reports immediate failure feedback", () => {
  const controller = createController({
    simulator: { queueCapacity: 0 }
  });

  controller.hoverTile(0);
  const snapshot = controller.clickAtTick(1);

  assert.equal(snapshot.summary.shots_fired_empty_queue, 1);
  assert.equal(controller.state.feedback, "empty_queue");
});

test("feedback returns to fired after a later valid shot", () => {
  const controller = createController({
    controller: { fireIntervalTicks: 10 }
  });

  controller.hoverTile(0);
  controller.clickAtTick(1);
  controller.clickAtTick(2);
  const snapshot = controller.clickAtTick(20);

  assert.equal(snapshot.summary.shots_invalid_tile_cooldown, 1);
  assert.equal(controller.state.feedback, "fired");
});

test("out-of-range target click reports invalid_target feedback", () => {
  const controller = createController();

  const snapshot = controller.clickAtTick(1, 999);

  assert.equal(snapshot.summary.invalid_target_inputs, 1);
  assert.equal(controller.state.feedback, "invalid_target");
});
