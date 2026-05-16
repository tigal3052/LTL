import { createHeldFromTable } from "./held-item.js";

/**
 * @returns {{ inventory, held } | null}
 */
export function pickUpFromInventory(inventory, row, col) {
  const instanceId = inventory.grid[row]?.[col];
  if (instanceId == null) return null;
  const removed = inventory.removeArtifact(instanceId);
  if (!removed) return null;
  const held = createHeldFromTable(removed.tableId, removed.rotation, "inventory");
  return { inventory, held };
}
