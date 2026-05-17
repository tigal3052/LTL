import table from "../data/artifact-table.json" with { type: "json" };

export const ArtifactTable = table;

export function getArtifactDef(tableId) {
  return ArtifactTable[tableId] ?? null;
}
