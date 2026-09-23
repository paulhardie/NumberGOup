# Ultimates: Time and State Manipulation

*Batch: 2026-09-23 design and mechanics expansion — §7 Future systems integration.*

- *Time Dilation:* Pauses the 15-second timer for 5 seconds (no Number generation, but allows damage).
- *Blood Magic:* Sacrifice 50% of current Number to deal 500% of that value as true damage.
- *Total Eclipse:* Brace is free, but any unblocked damage is doubled.

## Fit today

- Ultimates are designed: Surge, Bulwark, Breach and Windfall, one per milestone, each **firing on its own so the run screen gains no buttons** (pillar 1, `docs/WORKSHOP_DESIGN.md`). Blood Magic and Total Eclipse are player choices, so they need buttons or a different trigger.
- **Time Dilation was rejected before** as "Stop the Clock" for breaking the anti-goal "no pausing an active run while Number keeps growing". This version answers that by stopping Number generation during the pause, which may be enough to reopen it.
- Blood Magic overlaps Breach (instant damage as a share of wave HP), but pays in Number, which is a sharper decision.
- These would replace or add to the four milestone slots; that is a decision in itself.
