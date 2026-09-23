# The Siphon Waterfall

*Batch: 2026-09-23 design and mechanics expansion — §2 Visual feedback and game feel.*

When any damage hits the ring, tiny Neon Green particles physically break off from the damage number and cascade down the screen into the player's main Number pool.

## Fit today

- Siphon exists (D020), so this has a real event to show.
- **Layout:** the Number sits on top of the run screen and the Rig below it (D032), so "down the screen into the Number" would actually travel up. Worth deciding the direction against the real layout.
- Pairs naturally with the "visual bank" half of `baseline-siphon.md`.
- Particles are motion, so Reduce Motion must skip them; the green hue runs into MOTION_SYSTEM rule 2 (see `damage-colour-palette.md`).
