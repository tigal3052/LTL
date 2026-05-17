import test from "node:test";
import assert from "node:assert/strict";

import { RunSimulator } from "../src/domain/run-simulator.js";
import { InventoryModel, Artifact } from "../src/domain/inventory-model.js";
import { HazardModel } from "../src/domain/hazard-model.js";

test("inventory model places artifacts and detects collisions", () => {
  const inv = new InventoryModel(8, 8);
  
  // place basic_red (1x2 horizontally) at 0,0
  const id1 = inv.placeArtifact("basic_red", 0, 0, 0);
  assert.ok(id1 !== false);
  
  // overlapping placement should fail
  const id2 = inv.placeArtifact("basic_red", 1, 0, 0);
  assert.equal(id2, false);
  
  // place basic_blue (1x2 vertically) at 2,0
  const id3 = inv.placeArtifact("basic_blue", 2, 0, 0);
  assert.ok(id3 !== false);
  
  // test out of bounds
  const id4 = inv.placeArtifact("l_purple", 7, 7, 0);
  assert.equal(id4, false); // requires 3x2, bounds exceeded
});

test("artifact rotation changes shape correctly", () => {
  // basic_red shape is [[1, 1]]
  // rotated 90 degrees should be [[1], [1]]
  const inv = new InventoryModel(8, 8);
  const id = inv.placeArtifact("basic_red", 0, 0, 90);
  assert.ok(id !== false);
  
  const artifact = inv.getArtifactById(id);
  assert.deepEqual(artifact.shape, [[1], [1]]);
});

test("synergy reduces cooldown based on adjacent same color artifacts", () => {
  const inv = new InventoryModel(8, 8);
  // place two basic_red adjacent to each other
  // basic_red: 1x2. Place at 0,0 and 0,1. Wait, they overlap at 0,1 if shape is [[1, 1]] horizontally.
  // let's place at 0,0 and 0,2 no wait, they need to be adjacent.
  // at 0,0 occupies (0,0), (1,0) (x, y)
  const id1 = inv.placeArtifact("basic_red", 0, 0, 0); // occupies (0,0) and (1,0)
  const id2 = inv.placeArtifact("basic_red", 0, 1, 0); // occupies (0,1) and (1,1)

  const a1 = inv.getArtifactById(id1);
  const a2 = inv.getArtifactById(id2);
  
  // Check synergy. Each cell has 1 adjacent cell from the other artifact.
  // The 'basic_red' synergy value is 2.
  // Let's trace adjacency: 
  // (0,0) is next to (0,1)
  // (1,0) is next to (1,1)
  // These are two unique cells of matching artifact, but they belong to the SAME artifact instance.
  // So a1 has 1 unique adjacent matching artifact (a2).
  // Synergy reduction = 1 * 2 = 2.
  assert.equal(a1.synergyCooldownReduction, 2);
  assert.equal(a2.synergyCooldownReduction, 2);
  
  // Base cooldown is 100 ticks (5s @ 50ms). Effective should be 98 (4.9s).
  assert.equal(a1.effectiveCooldown, 98);
});

test("freeze delays energy generation", () => {
  const inv = new InventoryModel(8, 8);
  const hazard = new HazardModel(inv);
  
  const id = inv.placeArtifact("basic_red", 0, 0, 0);
  const a = inv.getArtifactById(id);
  
  assert.equal(a.currentCooldown, 100);
  
  hazard.applyFreeze(id, 5);
  
  for (let i = 0; i < 5; i++) {
    const gen = inv.tick();
    assert.deepEqual(gen, []);
  }
  
  assert.equal(a.currentCooldown, 100);
  
  let energyGenerated = false;
  for (let i = 0; i < 100; i++) {
    const gen = inv.tick();
    if (gen.includes("red")) energyGenerated = true;
  }
  
  assert.ok(energyGenerated);
});

test("break stops generation until repaired", () => {
  const inv = new InventoryModel(8, 8);
  const hazard = new HazardModel(inv);
  
  const id = inv.placeArtifact("basic_red", 0, 0, 0);
  hazard.applyBreak(id);
  
  let generated = 0;
  for (let i = 0; i < 50; i++) {
    if (inv.tick().length > 0) generated++;
  }
  
  assert.equal(generated, 0); // broken, generates nothing
  
  hazard.repairHazard(id);
  
  for (let i = 0; i < 100; i++) {
    if (inv.tick().length > 0) generated++;
  }
  
  assert.equal(generated, 1);
});

test("simulator integration generates energy from inventory", () => {
  const sim = new RunSimulator({ seed: 123, queueCapacity: 10 });
  sim.inventory.placeArtifact("basic_red", 0, 0, 0);
  
  const snap1 = sim.applyInput({ tick: 101, target: 0, input: "click" });
  assert.ok(snap1.summary.queue_generated > 0);
  assert.ok(snap1.queue.items.length >= 4);
});
