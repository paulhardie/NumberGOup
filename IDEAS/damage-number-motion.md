# Damage Number Motion

*Batch: 2026-09-23 design and mechanics expansion — §2 Visual feedback and game feel.*

**Spatial mapping:** Grey passive ticks "melt" and float slowly upward. Yellow tap damage "pops" and scales aggressively exactly where the finger touched.

**Overstrike and Echo animation:** When a Teal Echo or Blue Overstrike procs, it spawns directly from the centre of the standard damage number and arcs away horizontally, filling the screen with chaotic, secondary projectiles.

## Fit today

- Separating passive from tap by motion rather than colour fits `docs/MOTION_SYSTEM.md` rule 2 better than the palette idea does.
- Tap-at-finger placement: taps today strike the ring as a whole ("quick scale pop", MOTION_SYSTEM's event table), not a touch point.
- All movement must return early under Reduce Motion (rule 1) and stay in the duration bands (rule 5).
- "Filling the screen with chaotic projectiles" pulls against pillar 1's simple surface; it would need a cap on concurrent floats, also for performance on phones.
- The Overstrike/Echo half depends on `overstrike-and-echo.md`.
