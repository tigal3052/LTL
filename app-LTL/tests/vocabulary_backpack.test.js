import test from "node:test";
import assert from "node:assert/strict";

import { InventoryModel } from "../src/models/inventory.js";
import { placeHeld } from "../src/vocabulary/backpack/place-held.js";
import { recalculateSynergy } from "../src/vocabulary/backpack/recalculate-synergy.js";

test("placeHeld fails on collision and succeeds on empty cell", () => {
  const inv = new InventoryModel(8, 8);
  inv.placeArtifact("basic_red", 0, 0, 0);
  const held = { source: "inventory", tableId: "basic_red", rotation: 0, shape: [[1, 1]], energyType: "red" };
  const fail = placeHeld(inv, held, 0, 0);
  assert.equal(fail.placed, false);
  const ok = placeHeld(inv, held, 0, 2);
  assert.equal(ok.placed, true);
  assert.equal(ok.held, null);
});

test("recalculateSynergy applies adjacent same-color reduction", () => {
  const inv = new InventoryModel(8, 8);
  const id1 = inv.placeArtifact("basic_red", 0, 0, 0);
  const id2 = inv.placeArtifact("basic_red", 0, 1, 0);
  recalculateSynergy(inv);
  assert.equal(inv.getArtifactById(id1).synergyCooldownReduction, 2);
  assert.equal(inv.getArtifactById(id2).synergyCooldownReduction, 2);
});
