export class Telemetry {
  static requiredFields = [
    "run_id",
    "seed",
    "stage_index",
    "node_type",
    "shots_fired",
    "shots_hit_match",
    "shots_hit_mismatch",
    "shots_invalid_tile_cooldown",
    "shots_fired_empty_queue",
    "invalid_target_inputs",
    "queue_generated",
    "queue_consumed",
    "queue_wasted",
    "durability_loss_count",
    "repair_count",
    "clear_time_sec",
    "fail_time_sec",
    "result"
  ];

  constructor({ runId = crypto.randomUUID?.() ?? "run", seed, stageIndex = 0, nodeType = "normal" }) {
    this.events = [];
    this.data = {
      run_id: runId,
      seed,
      stage_index: stageIndex,
      node_type: nodeType,
      shots_fired: 0,
      shots_hit_match: 0,
      shots_hit_mismatch: 0,
      shots_invalid_tile_cooldown: 0,
      shots_fired_empty_queue: 0,
      invalid_target_inputs: 0,
      queue_generated: 0,
      queue_consumed: 0,
      queue_wasted: 0,
      durability_loss_count: 0,
      repair_count: 0,
      clear_time_sec: null,
      fail_time_sec: null,
      result: "running"
    };
  }

  record(event, payload = {}) {
    this.events.push({ event, ...payload });
  }

  increment(field, amount = 1) {
    this.data[field] += amount;
  }

  set(field, value) {
    this.data[field] = value;
  }

  syncQueueStats(queue) {
    this.data.queue_generated = queue.stats.generated;
    this.data.queue_consumed = queue.stats.consumed;
    this.data.queue_wasted = queue.stats.wasted;
  }

  summary() {
    return { ...this.data };
  }
}
