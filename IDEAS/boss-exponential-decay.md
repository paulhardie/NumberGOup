# Exponential Decay Boss

*Batch: 2026-09-23 design and mechanics expansion — §5 Advanced boss architecture.*

Scales its attack power relative to the player's unspent assets or total Rig ranks, directly targeting stagnant meta-strategies.

## Fit today

- Scaling on unspent Number punishes saving; scaling on Rig ranks punishes spending. Picking one sides with a strategy; both at once would punish everything. Needs a decision.
- A Hit that reads the player's own state makes the incoming number harder to predict. D015's contract is that "the number is visible before it kills you", so the scaled Hit must be shown live.
- Overlaps the Division boss's job if it scales on unspent Number.
