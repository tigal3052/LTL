import { RunProgression } from "../domain/run-progression.js";

const fastScaling = {
  baseShield: 0.5,
  baseHealth: 0,
  baseTimeLimitTicks: 5000,
  peakShieldDelta: 0,
  peakHealthDelta: 0,
  peakTimeCutTicks: 0,
  minTimeLimitTicks: 4000
};

function driveMiniRun(seed) {
  const prog = new RunProgression({ seed, maxStages: 5, scalingOverrides: fastScaling });
  let guard = 0;
  while (!prog.runComplete && !prog.failed && guard < 200) {
    guard += 1;
    const snap = prog.snapshot();
    if (snap.phase === "node_select") {
      prog.selectNode(0);
      continue;
    }
    if (snap.phase === "combat") {
      prog.applyCombatInput({ tick: 1, target: 0, input: "click" });
      continue;
    }
    if (snap.phase === "reward") {
      prog.claimRewards();
    }
  }
  return prog.snapshot();
}

const runs = 20;
const results = [];
for (let i = 0; i < runs; i += 1) {
  const snap = driveMiniRun(5000 + i);
  results.push({
    seed: snap.seed,
    complete: snap.runComplete,
    failed: snap.failed,
    events: snap.runComplete ? "ok" : snap.failed ? "fail" : "incomplete"
  });
}

const completed = results.filter((r) => r.complete).length;
const failed = results.filter((r) => r.failed).length;
console.log(
  JSON.stringify(
    {
      runs,
      completed,
      failed,
      samples: results.slice(0, 5)
    },
    null,
    2
  )
);
