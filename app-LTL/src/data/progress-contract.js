import { cloneFacts, validateWithSchema } from "../validation/schema-validator.js";

export const progressSchema = {
  type: "object",
  required: ["clearedLeviathanIds"],
  additionalProperties: "warn",
  properties: {
    clearedLeviathanIds: {
      type: "array",
      items: { type: "string" }
    }
  }
};

export function validateProgressData(input, source = "progress_data") {
  return validateWithSchema({ input, schema: progressSchema, source });
}

export function cloneProgressData(table) {
  return cloneFacts(table);
}
