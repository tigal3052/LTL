function clone(value) {
  return value == null ? value : JSON.parse(JSON.stringify(value));
}

function cloneInventory(inventory) {
  return {
    placed: clone(inventory?.placed ?? []),
    held: inventory?.held ?? null,
    synergies: clone(inventory?.synergies ?? []),
    lastGuardReason: inventory?.lastGuardReason ?? null
  };
}

function cloneCombatSnapshot(snapshot) {
  if (!snapshot) return null;
  return {
    seed: snapshot.seed,
    tick: snapshot.tick,
    result: snapshot.result,
    repairRequired: snapshot.repairRequired,
    durabilityLossCount: snapshot.durabilityLossCount,
    queue: clone(snapshot.queue),
    targets: clone(snapshot.targets),
    summary: clone(snapshot.summary)
  };
}

export function createRunSnapshot(state) {
  const snapshot = {
    phase: state.phase,
    seed: state.seed,
    stageIndex: state.stageIndex,
    maxStages: state.maxStages,
    inventory: cloneInventory(state.inventory),
    leviathanId: state.leviathanId,
    runIndex: state.runIndex,
    progress: clone(state.progress),
    runComplete: state.runComplete,
    failed: state.failed
  };

  if (state.phase === "node_select") {
    snapshot.candidates = clone(state.candidates ?? []);
  }

  if (state.phase === "combat") {
    snapshot.combat = cloneCombatSnapshot(state.simulator?.snapshot());
  }

  if (state.phase === "reward_loot") {
    snapshot.pendingRewards = clone(state.pendingRewards ?? []);
    snapshot.held = state.inventory?.held ?? null;
    snapshot.lastNodeLabel = state.lastNodeLabel ?? null;
  }

  return snapshot;
}

export function createReplaySummary(state) {
  const summary = {
    result: state.resultTag,
    runIndex: state.runIndex,
    stageIndex: state.stageIndex,
    leviathanId: state.leviathanId
  };

  if (state.lastCombatSummary) {
    Object.assign(summary, clone(state.lastCombatSummary));
  }

  summary.result = state.resultTag;
  return summary;
}
