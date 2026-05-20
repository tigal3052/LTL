function clone(value) {
  return value == null ? value : JSON.parse(JSON.stringify(value));
}

export function createSceneReadModel(snapshot) {
  return {
    phase: snapshot.phase,
    run: {
      seed: snapshot.seed,
      stageIndex: snapshot.stageIndex,
      maxStages: snapshot.maxStages,
      leviathanId: snapshot.leviathanId,
      runIndex: snapshot.runIndex,
      runComplete: snapshot.runComplete,
      failed: snapshot.failed
    },
    inventory: clone(snapshot.inventory),
    nodeSelect: snapshot.phase === "node_select" ? { candidates: clone(snapshot.candidates ?? []) } : null,
    combat: snapshot.phase === "combat" ? clone(snapshot.combat) : null,
    rewardLoot:
      snapshot.phase === "reward_loot"
        ? {
            pendingRewards: clone(snapshot.pendingRewards ?? []),
            held: snapshot.held ?? null,
            lastNodeLabel: snapshot.lastNodeLabel ?? null
          }
        : null,
    progress: clone(snapshot.progress)
  };
}
