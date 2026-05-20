function clone(value) {
  return value == null ? value : JSON.parse(JSON.stringify(value));
}

function typeName(value) {
  if (Array.isArray(value)) return "array";
  if (value === null) return "null";
  return typeof value;
}

function joinPath(base, segment) {
  if (!base) return `${segment}`;
  if (typeof segment === "number") return `${base}[${segment}]`;
  return `${base}.${segment}`;
}

function pushDiagnostic(list, source, path, code, message) {
  list.push({ source, path, code, message });
}

function validateValue(value, schema, path, source, errors, warnings) {
  if (schema?.validate) {
    const result = schema.validate(value, path);
    if (result !== true) {
      pushDiagnostic(errors, source, path, schema.code ?? "invalid_value", result);
      return undefined;
    }
  }

  if (schema?.enum && !schema.enum.includes(value)) {
    pushDiagnostic(
      errors,
      source,
      path,
      "invalid_enum",
      `Expected one of ${schema.enum.join(", ")} but received ${JSON.stringify(value)}.`
    );
    return undefined;
  }

  switch (schema?.type) {
    case "string": {
      if (typeof value !== "string") {
        pushDiagnostic(errors, source, path, "invalid_type", `Expected string but received ${typeName(value)}.`);
        return undefined;
      }
      return value;
    }
    case "number": {
      if (typeof value !== "number" || !Number.isFinite(value)) {
        pushDiagnostic(errors, source, path, "invalid_number", `Expected finite number but received ${JSON.stringify(value)}.`);
        return undefined;
      }
      if (schema.integer && !Number.isInteger(value)) {
        pushDiagnostic(errors, source, path, "invalid_integer", `Expected integer but received ${value}.`);
        return undefined;
      }
      if (schema.minimum != null && value < schema.minimum) {
        pushDiagnostic(errors, source, path, "below_minimum", `Expected number >= ${schema.minimum} but received ${value}.`);
        return undefined;
      }
      return value;
    }
    case "boolean": {
      if (typeof value !== "boolean") {
        pushDiagnostic(errors, source, path, "invalid_type", `Expected boolean but received ${typeName(value)}.`);
        return undefined;
      }
      return value;
    }
    case "array": {
      if (!Array.isArray(value)) {
        pushDiagnostic(errors, source, path, "invalid_type", `Expected array but received ${typeName(value)}.`);
        return undefined;
      }
      if (schema.minItems != null && value.length < schema.minItems) {
        pushDiagnostic(errors, source, path, "too_few_items", `Expected at least ${schema.minItems} items but received ${value.length}.`);
      }
      return value.map((entry, index) =>
        validateValue(entry, schema.items, joinPath(path, index), source, errors, warnings)
      );
    }
    case "object": {
      if (value == null || typeof value !== "object" || Array.isArray(value)) {
        pushDiagnostic(errors, source, path, "invalid_type", `Expected object but received ${typeName(value)}.`);
        return undefined;
      }

      const result = {};
      const props = schema.properties ?? {};
      const required = schema.required ?? [];
      for (const key of required) {
        if (value[key] === undefined) {
          pushDiagnostic(errors, source, joinPath(path, key), "missing_required", `Missing required field '${key}'.`);
        }
      }

      for (const [key, childSchema] of Object.entries(props)) {
        const childPath = joinPath(path, key);
        if (value[key] === undefined) {
          if (childSchema?.default !== undefined) {
            result[key] = clone(childSchema.default);
          }
          continue;
        }
        result[key] = validateValue(value[key], childSchema, childPath, source, errors, warnings);
      }

      for (const key of Object.keys(value)) {
        if (props[key]) continue;
        if (schema.additionalProperties === "error") {
          pushDiagnostic(errors, source, joinPath(path, key), "unknown_field", `Unknown field '${key}'.`);
        } else if (schema.additionalProperties === "warn") {
          pushDiagnostic(warnings, source, joinPath(path, key), "unknown_field", `Unknown field '${key}'.`);
        } else if (schema.additionalProperties === true) {
          result[key] = clone(value[key]);
        }
      }

      return result;
    }
    default:
      return clone(value);
  }
}

export function validateWithSchema({ input, schema, source = "memory" }) {
  const errors = [];
  const warnings = [];
  const facts = validateValue(input, schema, "", source, errors, warnings);

  return {
    ok: errors.length === 0,
    facts,
    errors,
    warnings,
    source
  };
}

export function parseJsonInput(input, source = "memory") {
  if (typeof input !== "string") {
    return { ok: true, value: clone(input), errors: [] };
  }

  try {
    return { ok: true, value: JSON.parse(input), errors: [] };
  } catch (error) {
    return {
      ok: false,
      value: null,
      errors: [
        {
          source,
          path: "",
          code: "invalid_json",
          message: error instanceof Error ? error.message : "Failed to parse JSON input."
        }
      ]
    };
  }
}

export function cloneFacts(value) {
  return clone(value);
}
