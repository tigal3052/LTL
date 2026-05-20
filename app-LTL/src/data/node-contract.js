import { cloneFacts, validateWithSchema } from "../validation/schema-validator.js";

const ENERGY_TYPES = ["red", "blue", "purple", "green"];

export const nodeSchema = {
  type: "object",
  required: ["id", "label", "weakness", "pickWeight", "shieldMul", "healthMul"],
  additionalProperties: "warn",
  properties: {
    id: { type: "string" },
    label: { type: "string" },
    weakness: {
      type: "array",
      items: { type: "string", enum: ENERGY_TYPES }
    },
    pickWeight: { type: "number", minimum: 0 },
    shieldMul: { type: "number", minimum: 0 },
    healthMul: { type: "number", minimum: 0 },
    alwaysOffer: { type: "boolean", default: false }
  }
};

export const nodeTableSchema = {
  type: "object",
  required: ["nodes"],
  additionalProperties: "warn",
  properties: {
    nodes: {
      type: "array",
      minItems: 1,
      items: nodeSchema
    }
  }
};

export function validateNodeTable(input, source = "node_table") {
  return validateWithSchema({ input, schema: nodeTableSchema, source });
}

export function cloneNodeTable(table) {
  return cloneFacts(table);
}
