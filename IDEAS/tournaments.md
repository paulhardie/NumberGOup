# Tournaments and Leaderboards

*Batch: 2026-09-23 design and mechanics expansion — §6 Tournaments and leaderboards.*

Because the economy is unified, tournaments must clearly separate endurance from economic optimisation.

- **Endurance format (infinite runs):** Ranked purely by Highest Wave Reached. Peak Number at the exact moment of clearing the last survived wave is the tie-breaker.
- **Efficiency format (fixed runs):** A hard-capped run (e.g., exactly 50 waves). Ranked entirely by Final Number. Challenges players to clear the gauntlet while spending the absolute bare minimum on temporary power.

## Fit today

- **Blocked by an anti-goal.** `docs/GAME_VISION.md`: "No live-operations scaffolding (events, dailies, tournaments) before the core run is proven fun."
- Leaderboards need a server, accounts and anti-cheat, and a local save is trivially editable. That is remote calls and new data collection, which AGENTS.md says needs an explicit product need.
- The **Efficiency format works offline** as a local challenge mode (fixed 50 waves, best Final Number as a personal record), which could enter through the modifier pipeline as a challenge without any live-ops.
