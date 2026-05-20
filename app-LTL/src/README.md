# M1 Domain API

`app-LTL/src` now exposes a domain-facing API that does not require browser-only internals.

## Public entry points

- `createHeadlessRun(config)`: create a deterministic mini-run process with formalized root and phase snapshots.
- `runReplay({ fixture, ...config })`: replay an input log against the stabilized domain boundary.
- `createSceneReadModel(snapshot)`: derive a renderer-safe read model from the public snapshot only.
- `loadArtifactTable`, `loadNodeTable`, `loadRewardTable`, `loadLeviathanTable`, `loadProgressData`: validate loader-facing JSON contracts.

## Snapshot boundary

Root snapshot fields are stable for M1:

- `seed`
- `stageIndex`
- `maxStages`
- `inventory`
- `leviathanId`
- `runIndex`

Phase-specific fields are exposed only on the matching phase:

- `node_select`: `candidates`
- `combat`: `combat`
- `reward_loot`: `pendingRewards`, `held`, `lastNodeLabel`

Scene/UI code should consume the snapshot or read-model APIs instead of reading simulator, history, or browser DOM details directly.
