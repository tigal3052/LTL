import { cloneFacts, validateWithSchema } from "../validation/schema-validator.js";

export const leviathanSchema = {
  type: "object",
  required: ["id", "name", "stageCnt", "runCnt"],
  additionalProperties: "warn",
  properties: {
    id: { type: "string" },
    name: { type: "string" },
    stageCnt: { type: "number", integer: true, minimum: 1 },
    runCnt: { type: "number", integer: true, minimum: 1 }
  }
};

export const leviathanTableSchema = {
  type: "object",
  required: ["leviathans"],
  additionalProperties: "warn",
  properties: {
    leviathans: {
      type: "array",
      minItems: 1,
      items: leviathanSchema
    }
  }
};

export function validateLeviathanTable(input, source = "leviathan_table") {
  return validateWithSchema({ input, schema: leviathanTableSchema, source });
}

export function cloneLeviathanTable(table) {
  return cloneFacts(table);
}
