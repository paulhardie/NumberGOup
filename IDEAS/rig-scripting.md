# Rig Scripting (The AI Accountant)

*Batch: 2026-09-23 design and mechanics expansion — §7 Future systems integration.*

Solves the offline automation gap. Players construct IF/THEN logical parameters (e.g., IF Wave HP > 50% at 5s, BUY 1 Attack) before closing the app. The game simulates the run based on the script, providing an after-action report showing exactly which wave broke the logic when the player returns.

## Fit today

- **Directly reverses D003.** "An active run freezes exactly while the app is away, and offline time is never injected into a run." D003 exists because offline growth was an exploit. It would have to be reopened, and its "revisit when" asks for proof the new design can't become a growth exploit.
- The pieces are close: runs are deterministic (D006) and `run_balance.sh` already simulates runs with scripted Rig policies, so an offline simulation is technically feasible.
- An in-run version (autobuy rules while playing) avoids D003 entirely and still removes tap-heavy Rig micromanagement.
- A rule editor is a large UI surface against pillar 1's simple surface.
