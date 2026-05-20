import { parseJsonInput } from "../validation/schema-validator.js";
import { validateProgressData } from "../data/progress-contract.js";

export function loadProgressData({ input, source = "progress_data" }) {
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

  return validateProgressData(parsed.value, source);
}
