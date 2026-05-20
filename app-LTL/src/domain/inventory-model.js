function clone(value) {
  return value == null ? value : JSON.parse(JSON.stringify(value));
}

export function createStarterInventory(artifactTable, initialInventory = null) {
  if (initialInventory) {
    return clone(initialInventory);
  }

  const starter = artifactTable?.artifacts?.[0];
  return {
    placed: starter
      ? [
          {
            instanceId: `${starter.id}:starter`,
            artifactId: starter.id,
            x: 0,
            y: 0,
            rotation: 0
          }
        ]
      : [],
    held: null,
    synergies: [],
    lastGuardReason: null
  };
}

export function pickUpPlacedArtifact(inventory, instanceId) {
  const next = clone(inventory);
  if (next.held) {
    return next;
  }

  const index = next.placed.findIndex((entry) => entry.instanceId === instanceId);
  if (index === -1) {
    return next;
  }

  const [picked] = next.placed.splice(index, 1);
  next.held = {
    ...picked,
    originPlacement: {
      x: picked.x,
      y: picked.y,
      rotation: picked.rotation
    }
  };
  next.lastGuardReason = null;
  return next;
}

export function placeHeldArtifact(inventory, placement = {}) {
  const next = clone(inventory);
  if (!next.held) {
    return next;
  }

  const held = next.held;
  next.placed.push({
    instanceId: held.instanceId,
    artifactId: held.artifactId,
    x: placement.x ?? held.originPlacement?.x ?? 0,
    y: placement.y ?? held.originPlacement?.y ?? 0,
    rotation: placement.rotation ?? held.originPlacement?.rotation ?? 0
  });
  next.held = null;
  next.lastGuardReason = null;
  return next;
}

export function discardHeldArtifact(inventory) {
  const next = clone(inventory);
  if (!next.held) {
    return next;
  }

  if (next.placed.length === 0) {
    const held = next.held;
    next.placed.push({
      instanceId: held.instanceId,
      artifactId: held.artifactId,
      x: held.originPlacement?.x ?? 0,
      y: held.originPlacement?.y ?? 0,
      rotation: held.originPlacement?.rotation ?? 0
    });
    next.held = null;
    next.lastGuardReason = "last_artifact_guard";
    return next;
  }

  next.held = null;
  next.lastGuardReason = null;
  return next;
}
