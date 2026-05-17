export function createRunSummary({ seed, stageIndex }) {
  return {
    run_id: `seed-${seed}`,
    seed,
    stage_index: stageIndex,
    node_type: "normal",
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
