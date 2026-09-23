# Build Archetypes: Glass Cannon, Martyr, Economist

*Batch: 2026-09-23 design and mechanics expansion — §3 The unified economy and viable meta-strategies.*

Because health, currency, and score are the same resource, three distinct strategies must be mathematically supported through the Workshop and Rig.

- **Glass Cannon (Velocity):** Relies purely on Echo, Overstrike, and Critical multipliers. Shatters waves before the 15-second timer. Highly profitable but incredibly brittle; failing to kill a wave results in instant death. The mandatory meta for the absolute limits of Tier 3.
- **The Martyr/Masochist (Defense):** Ignores early wave-clearing speed. Scales Armor, Recoil, and Siphon. Intentionally allows the 15-second hit. The wave hits, Recoil deals massive reflection damage, and Siphon immediately regenerates the lost Number. Taking damage is monetised into profit.
- **The Economist (Hoarding):** Scales passive Interest (which generates Number based strictly on unspent reserves), Utility modifiers, and Rig Salvage. Relies on the compounding math of massive hoards to organically absorb hits.

## Fit today

- **The Martyr largely exists.** D020 built Defense as a build around Siphon, Recoil and Armor, and measured Armor and Recoil reaching wave 100 by different routes.
- **Glass Cannon's "instant death" isn't how waves work.** A wave that outlasts its timer deals its Hit and keeps its HP (D012); it doesn't kill outright. Getting "brittle" means either a rule change or simply very low Defense. Echo and Overstrike don't exist yet.
- **The Economist has no engine.** There's no Interest stat, and Rig Salvage is a separate proposal. Interest on unspent Number rewards hoarding, which works against the Rig's spend-or-save tension (D015) and is exactly what the Division boss idea then punishes.
- "Mandatory meta" for Tier 3 contradicts the point of three viable builds; worth deciding whether that's intended.
- As a design target this is a good fit for pillar 2. Adopting it would mean adding balance targets for each archetype to `docs/WORKSHOP_DESIGN.md`.
