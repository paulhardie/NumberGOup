# Fever / Momentum Multiplier

*Batch: 2026-09-23 design and mechanics expansion — §1 Early game friction and the Rig curve.*

To make the Rig mathematically viable early on, clearing a wave before the 15-second boundary must provide a compounding reward. If a wave is cleared in 5 seconds, the remaining 10 seconds of output are multiplied by 2x or 3x. This justifies spending Number on Attack; the player spends wealth to unlock a multiplied time window that easily refunds the initial Rig cost.

## Fit today

- Aims straight at D023's open question: **early and mid builds cannot profit from the Rig** under the simulator's policy.
- The wave window is 15 s (`WAVE_INTERVAL_SECONDS` in `src/tax_balance_profile.gd`). Under D012, output after a clear already overflows into Number; this multiplies that overflow.
- **Economy change, so high risk** under `docs/QUALITY_GATES.md`. D023 found that making the Rig cheaper turned the game into a runaway (mid build to wave 204, zero hits); a compounding speed reward pushes the same way at the top end and needs a ceiling or tier scaling.
- Needs to enter through the modifier pipeline (D005), not as a special case in `GameState`.
- Mostly helps Attack builds, which leans against pillar 2 unless Defense gets an equivalent.
