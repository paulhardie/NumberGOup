# The Division Boss (Tax Audit)

*Batch: 2026-09-23 design and mechanics expansion — §5 Advanced boss architecture.*

Bosses must break the monotony of flat numerical subtraction, acting as strategic hazards that test specific build types.

Warns the player in advance, then divides the current Number by a specific factor (e.g., /2). Punishes the Economist build, forcing the player to dump their liquid wealth into the Rig before the hit lands.

## Fit today

- Fits the tax theme well and creates a real Rig decision before a known hit.
- A /2 hit ignores Armor, Cushion and Recoil unless it's designed to interact with them. That makes Defense useless against it, which undercuts pillar 2.
- The Economist build doesn't exist yet (see `build-archetypes.md`), so the thing it counters needs to arrive first.
- Boss modifiers belong in the modifier pipeline and encounter state (D005, `src/tax_encounter.gd`), and the warning needs space on the run screen.
