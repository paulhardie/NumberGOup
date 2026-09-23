# Cards as Mutators

*Batch: 2026-09-23 design and mechanics expansion — §7 Future systems integration.*

Instead of flat percentage buffs, Cards fundamentally alter run rules.

- *Pacifist:* Disables taps, triples passive damage.
- *Adrenaline:* Reverses Siphon; deal bonus damage based on missing Number.
- *Contraband:* Rig prices never scale, but upgrades disappear after 3 waves.

## Fit today

- **Redesigns a shipped system.** D027 built Cards as flat per-level steps on existing effect keys, pulled with Gems and levelled by repeats. The owner reaffirmed Cards "as built, for now" and floated revisiting them as deterministic Protocols; this is one direction for that revisit.
- Rule-changing cards are exactly what the modifier pipeline is for (D005, pillar 5).
- Levelling a mutator by duplicate pulls is awkward: what does level 7 Pacifist do? The pull-and-level model and the mutator model may not fit together.
- *Contraband* ("Rig prices never scale") is the runaway D023 measured; the three-wave expiry is what would have to hold it back.
- *Adrenaline* ("missing Number") needs a reference point, probably the run's peak Number, which D020 already tracks.
