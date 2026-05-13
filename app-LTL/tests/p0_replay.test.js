import test from "node:test";
import assert from "node:assert/strict";
import path from "node:path";
import { fileURLToPath } from "node:url";

import { createSeededRng } from "../src/domain/seeded-rng.js";
import { Telemetry } from "../src/telemetry/telemetry.js";
import { runReplay, runReplayFile } from "../src/tools/replay-runner.js";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

test("same seed produces the same random sequence", () => {
  const a = createSeededRng(1234);
  const b = createSeededRng(1234);

  assert.deepEqual(
    [a.nextInt(10), a.nextInt(10), a.nextInt(10)],
    [b.nextInt(10), b.nextInt(10), b.nextInt(10)]
  );
});

test("telemetry summary contains all P0 required fields", () => {
  const telemetry = new Telemetry({ runId: "test-run", seed: 7, stageIndex: 0, nodeType: "normal" });
  const summary = telemetry.summary();

  for (const field of Telemetry.requiredFields) {
    assert.ok(Object.hasOwn(summary, field), `missing ${field}`);
  }
});

test("same input log replays to identical results", () => {
  const first = runReplay({
    seed: 20260513,
    inputLog: [
      { tick: 1, target: 0, input: "click" },
      { tick: 2, target: 1, input: "click" },
      { tick: 3, target: 2, input: "click" }
    ]
  });
  const second = runReplay({
    seed: 20260513,
    inputLog: [
      { tick: 1, target: 0, input: "click" },
      { tick: 2, target: 1, input: "click" },
      { tick: 3, target: 2, input: "click" }
    ]
  });

  assert.deepEqual(second.summary, first.summary);
});

test("basic_clear fixture replays to a clear result", () => {
  const result = runReplayFile(path.join(__dirname, "fixtures", "input_logs", "basic_clear.json"));

  assert.equal(result.summary.result, "clear");
  assert.equal(result.summary.shots_fired, 1);
  assert.equal(result.summary.shots_hit_match, 1);
});

test("empty_queue_repair fixture replays to repair pressure", () => {
  const result = runReplayFile(path.join(__dirname, "fixtures", "input_logs", "empty_queue_repair.json"));

  assert.equal(result.repairRequired, true);
  assert.equal(result.durabilityLossCount, 3);
  assert.equal(result.summary.shots_fired_empty_queue, 3);
});
