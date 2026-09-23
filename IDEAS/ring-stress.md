# Ring Stress

*Batch: 2026-09-23 design and mechanics expansion — §2 Visual feedback and game feel.*

When an Overstrike or Crit occurs, the Ring UI flashes white, visually shudders/cracks, and instantly snaps to a smaller size, granting heavy hits intense physical weight.

## Fit today

- Fits MOTION_SYSTEM rule 2 well: severity shown by size and duration, and white is a flash rather than a new hue.
- Could ship for crits now; Overstrike doesn't exist yet.
- The ring already has a strike pop on taps and a stage impact on hits; this needs its own clearly bigger step so it reads as heavier, not just more of the same.
- Shudder and snap are movement and must respect Reduce Motion; the flash can stay.
