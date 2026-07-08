# Node Map Loadout Balance Design

## Request

Replace the prototype-style node list with a dedicated node-map page, make starting color choice matter by granting only one matching drill and beacon, rebalance five stages around visible durability targets, and slow terrain weakness movement from 1.0s to 1.5s.

## Design

The existing formal phase order remains `node_select -> combat -> reward_loot`. The first playable screen becomes a full node-map page inside the `node_select` phase. It renders stage progress, selectable route nodes, selected route details, and a four-color starting loadout selector. The old BBCode node list remains a fallback read model, but the live scene uses `NodeMapScene` as the main node selection surface.

Starting loadout is selected by color before combat. A selected color creates one drill and one adjacent beacon of the same energy type. Red remains the default for headless contracts and unattended replays so existing flows still start deterministically.

Stage durability is computed from a five-stage target curve instead of tiny Gaussian bumps. The target total durability uses:

```text
target_total(stage) = 30 * pow(1.43, stage_index)
rounded targets: 30, 43, 61, 88, 126
```

The implementation stores explicit balancing notes using the practical tuned equivalents `30, 42, 62, 88, 124`, then splits each target into shield and health by stage pressure:

```text
shield = target_total * shield_share(stage)
health = target_total - shield
shield_share = clamp(0.42 + stage_index * 0.025, 0.42, 0.52)
```

Node multipliers then create meaningful route differences. A safe node stays near the target; medium nodes lean about 8-15% harder; hard/danger nodes climb 25-40%; boss nodes keep the final-stage spike. This is balanced against one starter drill plus one beacon: the first node should clear reliably, the second should make color matching visible, and later stages should depend on reward growth.

Terrain weakness movement remains automatic, but the timer interval becomes 1.5 seconds to reduce the feeling that a selected tile changes immediately after player intent.

## Acceptance Criteria

- Node selection is presented as a dedicated map page with clickable node controls and selected detail text.
- Initial inventory contains exactly one drill and one beacon of the selected color.
- Headless default inventory uses red drill plus red beacon.
- Five normal-stage combat totals are close to `30, 42, 62, 88, 124` before node multipliers.
- The balance formula is documented in code comments and this spec.
- Weakness marker movement interval is 1.5 seconds.
