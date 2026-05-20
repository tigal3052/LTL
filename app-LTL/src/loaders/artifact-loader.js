import { parseJsonInput } from "../validation/schema-validator.js";
import { validateArtifactTable } from "../data/artifact-contract.js";

export function loadArtifactTable({ input, source = "artifact_table" }) {
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

  return validateArtifactTable(parsed.value, source);
}
