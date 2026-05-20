import { cloneFacts, validateWithSchema } from "../validation/schema-validator.js";

const ENERGY_TYPES = ["red", "blue", "purple", "green"];

function validateShape(value) {
  if (!Array.isArray(value) || value.length === 0) {
    return "Artifact shape must be a non-empty 2D array.";
  }

  for (const row of value) {
    if (!Array.isArray(row) || row.length === 0) {
      return "Artifact shape rows must be non-empty arrays.";
    }
    for (const cell of row) {
      if (cell !== 0 && cell !== 1) {
        return "Artifact shape cells must be 0 or 1.";
      }
    }
  }

  return true;
}

export const artifactSchema = {
  type: "object",
  required: ["id", "name", "shape", "energyType", "baseCooldownTicks", "synergy", "keyword"],
  additionalProperties: "warn",
  properties: {
    id: { type: "string" },
    name: { type: "string" },
    shape: { validate: validateShape },
    energyType: { type: "string", enum: ENERGY_TYPES },
    baseCooldownTicks: { type: "number", integer: true, minimum: 1 },
    synergy: { type: "string" },
    keyword: { type: "string" }
  }
};

export const artifactTableSchema = {
  type: "object",
  required: ["artifacts"],
  additionalProperties: "warn",
  properties: {
    artifacts: {
      type: "array",
      minItems: 1,
      items: artifactSchema
    }
  }
};

export function validateArtifactTable(input, source = "artifact_table") {
  const result = validateWithSchema({ input, schema: artifactTableSchema, source });
  if (result.facts?.artifacts) {
    result.facts.artifacts = result.facts.artifacts.map((artifact) => ({
      ...artifact,
      shape: artifact.shape.map((row) => [...row])
    }));
  }
  return result;
}

export function cloneArtifactTable(table) {
  return cloneFacts(table);
}
