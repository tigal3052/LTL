import { cloneFacts, validateWithSchema } from "../validation/schema-validator.js";

const ENERGY_TYPES = ["red", "blue", "purple", "green"];

export const rewardSchema = {
  type: "object",
  required: ["id", "artifactId", "kind", "color", "qty"],
  additionalProperties: "warn",
  properties: {
    id: { type: "string" },
    artifactId: { type: "string" },
    kind: { type: "string" },
    color: { type: "string", enum: ENERGY_TYPES },
    qty: { type: "number", integer: true, minimum: 1 }
  }
};

export const rewardTableSchema = {
  type: "object",
  required: ["rewards"],
  additionalProperties: "warn",
  properties: {
    rewards: {
      type: "array",
      minItems: 1,
      items: rewardSchema
    }
  }
};

export function validateRewardTable(input, source = "reward_table") {
  return validateWithSchema({ input, schema: rewardTableSchema, source });
}

export function cloneRewardTable(table) {
  return cloneFacts(table);
}
