# Rig Multi-Buy

*Batch: 2026-09-23 design and mechanics expansion — §1 Early game friction and the Rig curve.*

The Rig must implement the x1 / x5 / x10 / MAX purchase logic present in the Workshop. In high-pressure, late-wave scenarios, the player must be able to "panic buy" temporary stats instantly.

## Fit today

- **Already decided.** D018 accepted `x1 · x5 · x10 · MAX` for both lenses; the in-run half was waiting on the Rig, which has since shipped.
- The domain side exists: `GameState.plan_rig_purchase` and `purchase_rig_ranks` already take a count. Only the Rig panel lacks the multiplier chip (it is built into the Workshop header in `src/main.gd` only).
- Small UI job. Needs the Rig's own per-category step, since D018 says each category carries its own multiplier and it isn't saved.
