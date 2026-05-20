/**
 * 1단계 프로토타입 액션 결과 문장:
 * 전투 입력과 전후 스냅샷의 이상 결과를 받아 표시용 action result만 파생한다.
 *
 * 참조 원형: `prototype/browser-p0-p4/src/action-result.js`
 *
 * 입력 사실:
 * - `attempted_input(input_id, tick, target_ref)`는 어떤 입력을 어떤 대상에 시도했는지 담고 있다.
 * - `transition_before(snapshot)`와 `transition_after(snapshot)`는 입력 전후의 공개 스냅샷이다.
 * - `shot_resolution(outcome, damage, queue_delta, target_delta)`는 전투 규칙이 계산한 명중 결과다.
 * - `repair_pressure(count, required)`는 내구도 저하와 수리 필요 상태를 보여준다.
 *
 * 파생 목표:
 * - `deriveActionResult(before, after, input, resolution)`는 상태를 바꾸지 않고 표시용 결과만 반환한다.
 * - `isEmptyQueueShot(input, before, resolution)`는 빈 큐에서 발사 시도인지 판정한다.
 * - `isInvalidTarget(input, before)`는 대상 참조가 현재 공개 대상 목록에서 유효하지 않은지 판정한다.
 * - `labelHitOutcome(resolution)`는 match, normal, mismatch 결과를 표시용 feedback으로 바꾼다.
 *
 * 규칙:
 * - 대상이 유효하지 않으면 피해 표시보다 먼저 `invalid_target` 결과가 나와야 한다.
 * - 전투 입력인데 에너지 큐가 비어 있으면 `empty_queue` 결과가 나와야 한다.
 * - 전투 규칙이 이미 결과를 계산했더라도 action result는 표시 우선순위를 다시 정해야 한다.
 * - 이 단계에서는 상태를 바꾸지 않고, 전후 스냅샷과 이상 결과만 읽어 파생한다.
 *
 * 출력:
 * - 최종 출력은 feedback, diff, resolution만 담은 action result 객체다.
 * - before, after, input, resolution은 모두 읽기 전용으로 취급한다.
 */

/**
 * 2단계 실행 문장: `COUNTER_FIELDS` 선언.
 *
 * - action result가 비교할 summary counter field 이름을 고정 순서 배열로 선언한다.
 * - shots field는 fired, match, normal, mismatch, cooldown, empty queue를 포함한다.
 * - invalid target field는 queue field와 분리된 별도 summary 항목으로 둔다.
 * - queue field는 generated, consumed, wasted를 포함한다.
 * - repair field는 durability loss와 repair count를 포함한다.
 */
export const COUNTER_FIELDS = [
  "shots_fired",
  "shots_hit_match",
  "shots_hit_normal",
  "shots_hit_mismatch",
  "shots_invalid_tile_cooldown",
  "shots_fired_empty_queue",
  "invalid_target_inputs",
  "queue_generated",
  "queue_consumed",
  "queue_wasted",
  "durability_loss_count",
  "repair_count"
];

/**
 * 2단계 실행 문장: `HIT_FEEDBACK_BY_OUTCOME` 선언.
 *
 * - resolution outcome `match`의 feedback은 `hit_match`다.
 * - resolution outcome `normal`의 feedback은 `hit_normal`이다.
 * - resolution outcome `mismatch`의 feedback은 `hit_mismatch`다.
 */
export const HIT_FEEDBACK_BY_OUTCOME = {
  match: "hit_match",
  normal: "hit_normal",
  mismatch: "hit_mismatch"
};

/**
 * 2단계 실행 문장: `diffSummaryCounters(beforeSummary, afterSummary)`.
 *
 * - 고정 diff 객체를 하나 만든다.
 * - `COUNTER_FIELDS`의 각 field를 순회한다.
 * - beforeSummary[field]가 없으면 before 값을 0으로 취급한다.
 * - afterSummary[field]가 없으면 after 값을 0으로 취급한다.
 * - after 값에 before 값을 뺀 결과를 diff[field]에 넣는다.
 * - 모든 field 계산이 끝나면 diff 객체를 반환한다.
 */
export function diffSummaryCounters(beforeSummary = {}, afterSummary = {}) {
  const diff = {};

  for (const field of COUNTER_FIELDS) {
    diff[field] = (afterSummary[field] ?? 0) - (beforeSummary[field] ?? 0);
  }

  return diff;
}

/**
 * 2단계 실행 문장: `readTargetRef(input)`.
 *
 * - input.targetRef가 null 또는 undefined가 아니면 input.targetRef를 반환한다.
 * - input.targetRef가 없으면 input.target을 반환한다.
 */
export function readTargetRef(input = {}) {
  if (input.targetRef != null) {
    return input.targetRef;
  }

  return input.target;
}

/**
 * 2단계 실행 문장: `readTargets(before)`.
 *
 * - before.targets가 배열이면 before.targets를 반환한다.
 * - before.targets가 없으면 빈 배열을 반환한다.
 */
export function readTargets(before = {}) {
  if (Array.isArray(before.targets)) {
    return before.targets;
  }

  return [];
}

/**
 * 2단계 실행 문장: `normalizeTargetRef(targetRef)`.
 *
 * - targetRef가 객체고 id field를 가지면 targetRef.id를 반환한다.
 * - targetRef가 원시값이면 targetRef를 그대로 반환한다.
 */
export function normalizeTargetRef(targetRef) {
  if (targetRef != null && typeof targetRef === "object" && "id" in targetRef) {
    return targetRef.id;
  }

  return targetRef;
}

/**
 * 2단계 실행 문장: `isTargetIndexMissing(targetIndex, targets)`.
 *
 * - targetIndex가 정수가 아니면 true를 반환한다.
 * - targetIndex가 0보다 작으면 true를 반환한다.
 * - targetIndex가 targets.length 이상이면 true를 반환한다.
 * - 위 조건이 아니면 false를 반환한다.
 */
export function isTargetIndexMissing(targetIndex, targets) {
  if (!Number.isInteger(targetIndex)) {
    return true;
  }

  if (targetIndex < 0) {
    return true;
  }

  if (targetIndex >= targets.length) {
    return true;
  }

  return false;
}

/**
 * 2단계 실행 문장: `hasTargetId(targetId, targets)`.
 *
 * - targets를 순회한다.
 * - target.id가 targetId와 같은 항목이 있으면 true를 반환한다.
 * - 끝까지 같은 id가 없으면 false를 반환한다.
 */
export function hasTargetId(targetId, targets) {
  for (const target of targets) {
    if (target?.id === targetId) {
      return true;
    }
  }

  return false;
}

/**
 * 2단계 실행 문장: `isInvalidTarget(input, before)`.
 *
 * - input에서 targetRef를 읽는다.
 * - targetRef가 null 또는 undefined면 false를 반환한다.
 * - before에서 targets 배열을 읽는다.
 * - targetRef 정규화 결과가 숫자 index면 index 범위 검사를 한다.
 * - 숫자 index가 아니면 id 기반으로 대상 존재 여부를 검사한다.
 * - 검사 결과 대상이 없으면 true를 반환하고, 있으면 false를 반환한다.
 */
export function isInvalidTarget(input = {}, before = {}) {
  const targetRef = readTargetRef(input);

  if (targetRef == null) {
    return false;
  }

  const targets = readTargets(before);
  const normalizedTargetRef = normalizeTargetRef(targetRef);

  if (typeof normalizedTargetRef === "number") {
    return isTargetIndexMissing(normalizedTargetRef, targets);
  }

  return !hasTargetId(normalizedTargetRef, targets);
}

/**
 * 2단계 실행 문장: `readInputId(input)`.
 *
 * - input.inputId가 null 또는 undefined가 아니면 input.inputId를 반환한다.
 * - input.inputId가 비고 input.input이 있으면 input.input을 반환한다.
 * - 그게도 없으면 input.attemptedInput을 반환한다.
 */
export function readInputId(input = {}) {
  if (input.inputId != null) {
    return input.inputId;
  }

  if (input.input != null) {
    return input.input;
  }

  return input.attemptedInput;
}

/**
 * 2단계 실행 문장: `readQueueItems(before)`.
 *
 * - before.queue가 배열이면 before.queue를 반환한다.
 * - before.queue가 비고 before.energyQueue.items가 배열이면 그 값을 반환한다.
 * - 그게도 없으면 빈 배열을 반환한다.
 */
export function readQueueItems(before = {}) {
  if (Array.isArray(before.queue)) {
    return before.queue;
  }

  if (Array.isArray(before.energyQueue?.items)) {
    return before.energyQueue.items;
  }

  return [];
}

/**
 * 2단계 실행 문장: `isEmptyQueueShot(input, before, resolution)`.
 *
 * - input에서 inputId를 읽는다.
 * - inputId가 `click`이 아니면 false를 반환한다.
 * - resolution.outcome이 `empty_queue`면 true를 반환한다.
 * - before에서 queue items를 읽는다.
 * - queue items 길이가 0이면 true를 반환한다.
 * - 그 외에는 false를 반환한다.
 */
export function isEmptyQueueShot(input = {}, before = {}, resolution = {}) {
  const inputId = readInputId(input);

  if (inputId !== "click") {
    return false;
  }

  if (resolution.outcome === "empty_queue") {
    return true;
  }

  const queueItems = readQueueItems(before);

  if (queueItems.length === 0) {
    return true;
  }

  return false;
}

/**
 * 2단계 실행 문장: `labelHitOutcome(resolution)`.
 *
 * - resolution.outcome이 `match`면 `hit_match`를 반환한다.
 * - resolution.outcome이 `normal`이면 `hit_normal`을 반환한다.
 * - resolution.outcome이 `mismatch`면 `hit_mismatch`를 반환한다.
 * - 위 경우가 아니면 null을 반환한다.
 */
export function labelHitOutcome(resolution = {}) {
  return HIT_FEEDBACK_BY_OUTCOME[resolution.outcome] ?? null;
}

/**
 * 2단계 실행 문장: `isNewClear(beforeSummary, afterSummary)`.
 *
 * - afterSummary.result가 `clear`가 아니면 false를 반환한다.
 * - beforeSummary.result가 이미 `clear`면 false를 반환한다.
 * - afterSummary.result만 `clear`면 true를 반환한다.
 */
export function isNewClear(beforeSummary = {}, afterSummary = {}) {
  if (afterSummary.result !== "clear") {
    return false;
  }

  if (beforeSummary.result === "clear") {
    return false;
  }

  return true;
}

/**
 * 2단계 실행 문장: `isNewTimeOver(beforeSummary, afterSummary)`.
 *
 * - afterSummary.result가 `time_over`가 아니면 false를 반환한다.
 * - beforeSummary.result가 이미 `time_over`면 false를 반환한다.
 * - afterSummary.result만 `time_over`면 true를 반환한다.
 */
export function isNewTimeOver(beforeSummary = {}, afterSummary = {}) {
  if (afterSummary.result !== "time_over") {
    return false;
  }

  if (beforeSummary.result === "time_over") {
    return false;
  }

  return true;
}

/**
 * 2단계 실행 문장: `isNewRepairRequired(before, after)`.
 *
 * - after.repairRequired가 true가 아니면 false를 반환한다.
 * - before.repairRequired가 이미 true면 false를 반환한다.
 * - after에서만 새로 true가 되면 true를 반환한다.
 */
export function isNewRepairRequired(before = {}, after = {}) {
  if (after.repairRequired !== true) {
    return false;
  }

  if (before.repairRequired === true) {
    return false;
  }

  return true;
}

/**
 * 2단계 실행 문장: `feedbackForFiredInput(input, diff)`.
 *
 * - input에서 inputId를 읽는다.
 * - inputId가 `click`이 아니면 `no_op`를 반환한다.
 * - diff.shots_fired가 0보다 크면 `fired`를 반환한다.
 * - 그렇지 않으면 `no_op`를 반환한다.
 */
export function feedbackForFiredInput(input = {}, diff = {}) {
  const inputId = readInputId(input);

  if (inputId !== "click") {
    return "no_op";
  }

  if ((diff.shots_fired ?? 0) > 0) {
    return "fired";
  }

  return "no_op";
}

/**
 * 2단계 실행 문장: `deriveActionResult(before, after, input, resolution)`.
 *
 * - before.summary가 없으면 빈 객체를 beforeSummary로 사용한다.
 * - after.summary가 없으면 빈 객체를 afterSummary로 사용한다.
 * - beforeSummary와 afterSummary의 counter 차이를 diff로 계산한다.
 * - diff.invalid_target_inputs가 0보다 크면 feedback을 `invalid_target`으로 정한다.
 * - invalid target diff가 없어도 현재 input 대상이 유효하지 않으면 feedback을 `invalid_target`으로 정한다.
 * - invalid target이 아니고 diff.shots_fired_empty_queue가 0보다 크면 feedback을 `empty_queue`로 정한다.
 * - empty queue diff가 없어도 click 입력이 빈 큐 발사 시도면 feedback을 `empty_queue`로 정한다.
 * - empty queue가 아니고 diff.shots_invalid_tile_cooldown이 0보다 크면 feedback을 `invalid_cooldown`으로 정한다.
 * - cooldown diff가 없어도 resolution.outcome이 `invalid_cooldown`이면 feedback을 `invalid_cooldown`으로 정한다.
 * - cooldown이 아니고 afterSummary.result가 새로 `clear`가 되면 feedback을 `clear`로 정한다.
 * - clear가 아니고 afterSummary.result가 새로 `time_over`가 되면 feedback을 `time_over`로 정한다.
 * - time_over가 아니고 after에서 repairRequired가 새로 생기면 feedback을 `repair_required`로 정한다.
 * - repair_required가 아니고 resolution outcome이 hit outcome이면 hit feedback을 사용한다.
 * - hit feedback이 없으면 click 발사 여부에 따라 `fired` 또는 `no_op`를 정한다.
 * - feedback, diff, resolution만 담은 action result 객체를 반환한다.
 */
export function deriveActionResult(before = {}, after = {}, input = {}, resolution = {}) {
  const beforeSummary = before.summary ?? {};
  const afterSummary = after.summary ?? {};
  const diff = diffSummaryCounters(beforeSummary, afterSummary);

  let feedback = null;

  if (diff.invalid_target_inputs > 0) {
    feedback = "invalid_target";
  } else if (isInvalidTarget(input, before)) {
    feedback = "invalid_target";
  } else if (diff.shots_fired_empty_queue > 0) {
    feedback = "empty_queue";
  } else if (isEmptyQueueShot(input, before, resolution)) {
    feedback = "empty_queue";
  } else if (diff.shots_invalid_tile_cooldown > 0) {
    feedback = "invalid_cooldown";
  } else if (resolution.outcome === "invalid_cooldown") {
    feedback = "invalid_cooldown";
  } else if (isNewClear(beforeSummary, afterSummary)) {
    feedback = "clear";
  } else if (isNewTimeOver(beforeSummary, afterSummary)) {
    feedback = "time_over";
  } else if (isNewRepairRequired(before, after)) {
    feedback = "repair_required";
  } else {
    feedback = labelHitOutcome(resolution) ?? feedbackForFiredInput(input, diff);
  }

  return {
    feedback,
    diff,
    resolution
  };
}
