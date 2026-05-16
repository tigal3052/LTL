import { ArtifactTable } from "../models/artifact-table.js";

export class Artifact {
  constructor(id, data, x, y, rotation) {
    this.instanceId = id;
    this.tableId = data.id;
    this.name = data.name;
    this.energyType = data.energyType;
    this.baseCooldownTicks = data.baseCooldownTicks;
    this.synergyConfig = data.synergy;
    
    this.x = x;
    this.y = y;
    this.rotation = rotation; // 0, 90, 180, 270
    this.shape = this.rotateShape(data.shape, rotation);
    
    // Dynamic state
    this.currentCooldown = this.baseCooldownTicks;
    this.synergyCooldownReduction = 0;
    this.isBroken = false;
    this.freezeTicks = 0;
  }

  rotateShape(shape, degrees) {
    let result = shape;
    const times = (degrees % 360) / 90;
    for (let i = 0; i < times; i++) {
      // Transpose and reverse rows
      const rows = result.length;
      const cols = result[0].length;
      const rotated = Array.from({ length: cols }, () => Array(rows).fill(0));
      for (let r = 0; r < rows; r++) {
        for (let c = 0; c < cols; c++) {
          rotated[c][rows - 1 - r] = result[r][c];
        }
      }
      result = rotated;
    }
    return result;
  }

  get effectiveCooldown() {
    return Math.max(1, this.baseCooldownTicks - this.synergyCooldownReduction);
  }

  tick() {
    if (this.isBroken) return null; // Generates nothing while broken
    
    if (this.freezeTicks > 0) {
      this.freezeTicks -= 1;
      return null; // Cooldown doesn't progress while frozen
    }

    this.currentCooldown -= 1;
    if (this.currentCooldown <= 0) {
      this.currentCooldown = this.effectiveCooldown;
      return this.energyType;
    }
    return null;
  }
}

export class InventoryModel {
  constructor(width = 8, height = 8) {
    this.width = width;
    this.height = height;
    this.artifacts = []; // Array of Artifact instances
    this.grid = Array.from({ length: height }, () => Array(width).fill(null)); // Stores instanceIds
    this.nextInstanceId = 1;
  }

  placeArtifact(tableId, x, y, rotation = 0) {
    const data = ArtifactTable[tableId];
    if (!data) throw new Error(`Artifact ${tableId} not found`);

    const artifact = new Artifact(this.nextInstanceId++, data, x, y, rotation);
    
    // Check bounds and collisions
    if (!this.canPlace(artifact)) {
      return false;
    }

    // Place on grid
    this.artifacts.push(artifact);
    for (let r = 0; r < artifact.shape.length; r++) {
      for (let c = 0; c < artifact.shape[r].length; c++) {
        if (artifact.shape[r][c] === 1) {
          this.grid[y + r][x + c] = artifact.instanceId;
        }
      }
    }

    this.calculateSynergies();
    return artifact.instanceId;
  }

  removeArtifact(instanceId) {
    const idx = this.artifacts.findIndex(a => a.instanceId === instanceId);
    if (idx === -1) return null;
    
    const artifact = this.artifacts.splice(idx, 1)[0];
    
    // Clear from grid
    for (let r = 0; r < this.height; r++) {
      for (let c = 0; c < this.width; c++) {
        if (this.grid[r][c] === instanceId) {
          this.grid[r][c] = null;
        }
      }
    }
    
    this.calculateSynergies();
    return artifact;
  }

  canPlace(artifact) {
    for (let r = 0; r < artifact.shape.length; r++) {
      for (let c = 0; c < artifact.shape[r].length; c++) {
        if (artifact.shape[r][c] === 1) {
          const gy = artifact.y + r;
          const gx = artifact.x + c;
          if (gx < 0 || gx >= this.width || gy < 0 || gy >= this.height) {
            return false; // Out of bounds
          }
          if (this.grid[gy][gx] !== null) {
            return false; // Collision
          }
        }
      }
    }
    return true;
  }

  calculateSynergies() {
    // Reset synergies
    for (const artifact of this.artifacts) {
      artifact.synergyCooldownReduction = 0;
    }

    // A simple synergy check: for each artifact, check its adjacent cells for same color
    for (const artifact of this.artifacts) {
      if (!artifact.synergyConfig || artifact.synergyConfig.type !== 'same_color') continue;

      let adjacentMatches = new Set();

      // Check all cells of this artifact
      for (let r = 0; r < artifact.shape.length; r++) {
        for (let c = 0; c < artifact.shape[r].length; c++) {
          if (artifact.shape[r][c] === 1) {
            const gy = artifact.y + r;
            const gx = artifact.x + c;
            
            // Check 4 neighbors
            const neighbors = [
              [gy - 1, gx], [gy + 1, gx], [gy, gx - 1], [gy, gx + 1]
            ];

            for (const [ny, nx] of neighbors) {
              if (ny >= 0 && ny < this.height && nx >= 0 && nx < this.width) {
                const neighborId = this.grid[ny][nx];
                if (neighborId !== null && neighborId !== artifact.instanceId) {
                  const neighbor = this.getArtifactById(neighborId);
                  if (neighbor && neighbor.energyType === artifact.energyType) {
                    adjacentMatches.add(neighborId);
                  }
                }
              }
            }
          }
        }
      }

      // Apply synergy based on number of unique adjacent matching artifacts
      artifact.synergyCooldownReduction = adjacentMatches.size * artifact.synergyConfig.value;
    }
  }

  getArtifactById(id) {
    return this.artifacts.find(a => a.instanceId === id);
  }

  tick() {
    const generatedEnergies = [];
    for (const artifact of this.artifacts) {
      const energy = artifact.tick();
      if (energy) {
        generatedEnergies.push(energy);
      }
    }
    return generatedEnergies;
  }

  getDebugGrid() {
    let output = '';
    for (let r = 0; r < this.height; r++) {
      let row = '';
      for (let c = 0; c < this.width; c++) {
        const id = this.grid[r][c];
        row += id === null ? '.' : id;
      }
      output += row + '\n';
    }
    return output.trim();
  }
}
