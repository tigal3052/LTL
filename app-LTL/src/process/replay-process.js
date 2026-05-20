import { createHeadlessRun } from "./headless-mini-run.js";

export function runReplay({ fixture, ...config }) {
  const run = createHeadlessRun({
    ...config,
    seed: fixture.seed,
    leviathanId: fixture.leviathanId,
    runIndex: fixture.runIndex ?? 0,
    stageCount: fixture.stageCount,
    runCount: fixture.runCount,
    queueCapacity: fixture.queueCapacity ?? 8,
    initialQueue: fixture.initialQueue ?? null
  });

  if ((fixture.inputLog?.length ?? 0) > 0 && run.snapshot().phase === "node_select") {
    run.selectNode(fixture.candidateIndex ?? 0);
  }

  for (const input of fixture.inputLog ?? []) {
    run.applyCombatInput(input);
    const phase = run.snapshot().phase;
    if (phase === "failed" || phase === "run_complete") {
      break;
    }
  }

  if (run.snapshot().phase === "reward_loot") {
    run.claimRewards();
  }

  return {
    finalSnapshot: run.snapshot(),
    summary: run.replaySummary()
  };
}
