import { parseJsonInput } from "../validation/schema-validator.js";
import { validateLeviathanTable } from "../data/leviathan-contract.js";

export function loadLeviathanTable({ input, source = "leviathan_table" }) {
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

  return validateLeviathanTable(parsed.value, source);
}
