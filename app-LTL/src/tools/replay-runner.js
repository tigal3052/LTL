import fs from "node:fs";
import { RunSimulator } from "../domain/run-simulator.js";

export function runReplay({ seed = 1, inputLog = [], queueCapacity, node, timeLimitTicks } = {}) {
  const simulator = new RunSimulator({ seed, queueCapacity, node, timeLimitTicks });
  return simulator.run(inputLog);
}

export function runReplayFile(path) {
  const fixture = JSON.parse(fs.readFileSync(path, "utf8"));
  return runReplay(fixture);
}

if (process.argv[1] && process.argv[1].endsWith("replay-runner.js") && process.argv[2]) {
  const result = runReplayFile(process.argv[2]);
  console.log(JSON.stringify(result.summary, null, 2));
}
