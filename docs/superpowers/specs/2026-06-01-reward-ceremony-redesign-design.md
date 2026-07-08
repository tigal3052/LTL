# Reward Ceremony Redesign

Date: 2026-06-01
Workspace: `LootingTheLeviathan`

## Goal

Replace the current auto-closing single-card reward reveal with a player-confirmed, mining-themed reward ceremony that:

- keeps the reward on screen until the player confirms
- builds anticipation before revealing exact rewards
- separates reward-count excitement from reward-rarity excitement
- reveals rewards one-by-one in ascending rarity order
- keeps rarity VFX fixed by rarity tier rather than exaggerating the last item
- preserves the existing reward tray and backpack organization flow after the ceremony
- removes the starter color-selection UI from node select after stage 1

## Current Problems

- The current full-screen overlay auto-finishes after a short timer, so rewards feel like a passing animation rather than a claimed prize.
- The reveal currently exposes name, rarity, and identity too quickly, so there is no suspense curve.
- Multiple rewards are collapsed into one hero card plus `+N more`, which weakens the sense of a multi-reward drop.
- Reward ceremony state is currently spread across `show_victory_overlay` and `is_reveal_vfx_running`, which makes timing and input ownership fragile.
- Node select always receives starter color UI data, so stage 2+ can still show the original loadout picker and overwrite earned progression.

## Experience Direction

The reward ceremony should read as `excavation`, not `UI card reveal`.

The player has just finished drilling into the Leviathan. Reward items should feel like artifacts being excavated from sealed terrain panels, not abstract cards sliding onto the screen. The reveal therefore uses [`tile_panel_nobg.png`](/D:/Programming/ex_workspace/LootingTheLeviathan/app-LTL/resources/UI/tile/tile_panel_nobg.png) as the sealed excavation lid. Each reward is hidden inside one of these mining lids until it cracks open and releases the artifact.

## Ceremony Structure

The reward ceremony stays inside `reward_loot`, but introduces explicit presentation steps:

1. `count_tease`
2. `count_lock`
3. `reveal_queue`
4. `tray_review`

The player does not interact with the reward tray or backpack until `tray_review`.

## Step 1: Count Tease

This step should create uncertainty about how many artifacts were excavated.

- The screen dims and centers on sealed excavation lids built from `tile_panel_nobg.png`.
- No item identity or rarity is shown.
- The lids glow, shake, leak dust, and flare from within as though the mined terrain is about to break open.
- The count is not stated immediately.
- The lids appear in `three quantity bands`, not five independent patterns:

### Band A: 1-2 rewards

- Tone: compact find
- `1 reward`
  - One central sealed lid overheats, glows, and stabilizes.
- `2 rewards`
  - The first lid overheats.
  - The effect appears to settle.
  - A second lid activates late, creating a small surprise beat.

### Band B: 3 rewards

- Tone: standard jackpot
- One lid activates.
- Brief pause.
- Second lid activates.
- Brief pause.
- Third lid activates as the "this run paid out well" beat.

### Band C: 4-5 rewards

- Tone: obvious jackpot
- The pattern starts like the 3-reward band.
- Additional lids are added with stronger vibration, dust, and light.
- `4 rewards`
  - The fourth lid is the escalation beat.
- `5 rewards`
  - The fifth lid is the final quantity climax.

The important rule is that quantity spectacle remains separate from rarity spectacle. A 5-reward drop can feel large without pretending the items are high rarity.

## Step 2: Count Lock

This step confirms how many rewards were excavated.

- The final number of sealed lids is now fixed and clearly visible.
- The UI can now state the count, for example "3 artifacts excavated".
- The lids remain sealed.
- Rarity and identity are still hidden.
- This is the final "how many did I get?" payoff before individual item reveals begin.

## Step 3: Reveal Queue

Rewards are individually revealed one at a time.

- Rewards are sorted from `lowest rarity -> highest rarity`.
- The player sees one main reward at a time in the center.
- The current reward always remains the focus; this is a true single-reveal flow.
- The queue uses progress indicators such as `2 / 5` or small pip markers so the player still understands how many remain.
- The currently focused sealed lid cracks, bursts open, and reveals the item within.
- After the item is readable, the player advances to the next reveal.
- The final reveal is simply the highest actual rarity item in the queue, not an artificially upgraded climax.

## Rarity VFX Rules

Rarity effects are `fixed by rarity tier`.

The last item should only be as flashy as its real rarity deserves.

- `Common`
  - short crack-open, weak dust, low light bloom
- `Rare`
  - stronger ring light, cleaner fracture burst, more particles
- `Epic`
  - larger internal glow, longer opening hold, richer burst trail
- `Legendary / Mythic`
  - full ceremony highlight, largest crack burst, strongest background aura, longest hold

The system must never inflate a `Rare` into a `Legendary-feeling` reveal just because it happens to be last. Ordering increases anticipation; rarity tier determines effect strength.

## Step 4: Tray Review

After the final reveal, the cinematic overlay exits and the existing reward handling UI returns.

- The current `reward list + discard zone + backpack organization` flow remains.
- The ceremony closing action is separate from actual reward claiming.
- The player still places, discards, and organizes rewards exactly as today.

## Input Policy

### During `count_tease`, `count_lock`, and `reveal_queue`

- Block reward tray input
- Block backpack input
- Block discard input
- Block shop input
- Block node-select input
- Block starter color selection input
- Block unrelated overlay toggles

Allowed input should be limited to:

- left click
- `Space`
- `Enter`
- controller confirm

### Confirm behavior

Each confirm input follows a two-state rule:

- If the current step is still animating, confirm advances it to its readable end state immediately.
- If the current step is already readable, confirm moves to the next step.

This keeps skip behavior as `acceleration`, not `information loss`.

## Node Select Cleanup

Starter color selection should only appear on the first stage.

The node-select read model should expose an explicit contract such as:

- `allow_start_color_selection = true` for stage 1
- `allow_start_color_selection = false` for stage 2+

When false:

- the color selection row should not be rendered
- related signals should not be emitted
- the existing earned inventory must remain untouched

This must be a contract-level behavior, not a late visibility hack.

## State and Ownership

Reward ceremony flow should move from ad-hoc booleans toward explicit presentation state.

Recommended ownership split:

- `MainControllerRuntime.gd`
  - owns reward presentation step transitions and player input rules
- `PhaseLayoutPresenter.gd`
  - decides which screen regions are visible for each reward presentation step
- `RewardRevealOverlay.gd`
  - draws the mining-themed ceremony and step-specific visuals
- `NodeMapScene.gd` or related read model layer
  - respects stage-based starter color selection availability

## Testing Targets

The implementation should add regression coverage for:

- reward reveal does not auto-dismiss before player confirmation
- quantity tease behaves correctly for `1`, `2`, `3`, `4`, and `5` rewards
- quantity bands behave as `1-2`, `3`, and `4-5`
- rarity reveal order is sorted low-to-high
- rarity VFX package matches real rarity tier rather than queue position
- first confirm accelerates the current readable state
- second confirm advances the ceremony step
- tray and backpack input stay blocked during ceremony steps
- tray and backpack input return in `tray_review`
- stage 1 node select still shows starter color choice
- stage 2+ node select no longer renders or emits starter color choice interactions

## Files Expected To Change During Implementation

- `app-LTL/src/ui/RewardRevealOverlay.gd`
- `app-LTL/src/MainControllerRuntime.gd`
- `app-LTL/src/ui/MainViewRuntime.gd`
- `app-LTL/src/ui/presenters/PhaseLayoutPresenter.gd`
- `app-LTL/src/scenes/node_map/NodeMapScene.gd`
- related read-model and focused test files

## Final Design Decision

The approved direction is:

- mining-themed sealed excavation lids using `tile_panel_nobg.png`
- explicit count suspense before count confirmation
- individual reward reveals instead of simultaneous multi-card reveal
- rewards sorted from low rarity to high rarity
- rarity VFX fixed by actual rarity tier
- starter color picker removed from node select after stage 1
- post-ceremony reward organization flow preserved
