# The Bleed Boss

*Batch: 2026-09-23 design and mechanics expansion — §5 Advanced boss architecture.*

Drains a percentage of the player's Number every second it remains standing. A hard DPS check that counters the Martyr/Defense strategy, forcing an immediate, aggressive clear.

## Fit today

- Counters the Defense build that D020 made real; a clean counterpart to the Division boss.
- A percentage drain never reaches zero on its own, so it shrinks the buffer before the boss's Hit rather than killing. Worth deciding whether Siphon or Recoil should push back against it, or it simply invalidates Defense for that wave.
- Per-second drain must be deterministic and saved mid-wave (D006).
- Boss Damage (D021) already exists as the Attack lever for bosses.
