import { Artifact } from "../../domain/inventory-model.js";
import { getArtifactDef } from "../../models/artifact-table.js";

/**
 * @typedef {{ source: "reward"|"inventory", tableId: string, rotation: number, shape: number[][], energyType: string, rewardId?: string }} HeldItem
 */

export function createHeldFromTable(tableId, rotation = 0, source = "inventory", rewardId = undefined) {
  const data = getArtifactDef(tableId);
  if (!data) return null;
  const preview = new Artifact(0, data, 0, 0, rotation);
  return {
    source,
    tableId,
    rotation,
    shape: preview.shape,
    energyType: data.energyType,
    rewardId
  };
}

export function rotateHeld(held) {
  if (!held) return null;
  const rotation = (held.rotation + 90) % 360;
  const next = createHeldFromTable(held.tableId, rotation, held.source, held.rewardId);
  return next;
}
