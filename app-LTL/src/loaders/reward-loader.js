import { parseJsonInput } from "../validation/schema-validator.js";
import { validateRewardTable } from "../data/reward-contract.js";

export function loadRewardTable({ input, source = "reward_table" }) {
  const parsed = parseJsonInput(input, source);
  if (!parsed.ok) {
    return {
      ok: false,
      facts: null,
      warnings: [],
      errors: parsed.errors,
      source
    };
  }

  return validateRewardTable(parsed.value, source);
}
