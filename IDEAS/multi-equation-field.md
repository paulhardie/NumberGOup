# Multi-Equation Field (Enemies as Living Equations)

*Batch: 2026-09-23 — standalone pitch.*

Framing enemies as living equations or mathematical expressions is a conceptually pure fit for Number Go Up. It leans entirely into the raw mathematical aesthetic rather than trying to disguise numbers as fantasy monsters or spaceships.

To replicate the visual and mechanical chaos of The Tower—where hundreds of enemies crowd the screen and trigger thousands of calculations per second—you do not need physical spatial units moving across a grid. You can construct a Multi-Equation Field.

Instead of a single monolithic Wave HP ring sitting in the centre of the display, the playfield becomes an active ledger or computational grid populated by multiple concurrent terms, fractions, exponents, and variables that the engine is actively trying to resolve.

## Visualising the Multi-Equation Field

Imagine the centre area not as an empty space, but as a dynamic blackboard or terminal.

- **The Swarm (Linear Terms):** Dozens of small, distinct terms (+450, +1.2k, +85) spawn around the perimeter or scroll down a central matrix. These are your "basic enemies."
- **The Heavies (Exponents & Multipliers):** Floating expressions like × 1.8 or ( )² that hover over the linear terms, actively multiplying their threat or shielding them until solved.
- **The Boss (A Massive Polynomial):** A towering, complex expression sitting at the bottom of the stack—something like [3.4M - 12x] / 4—that requires peeling away outer brackets before the core value can be attacked.

## How combat and calculations function

In The Tower, high-speed calculations occur because your tower fires projectiles with different collision checks, bounce logic, and status procs across hundreds of targets. In Number Go Up, you map those exact systems onto automated equation resolution:

- **Targeting Logic (The Targeting Priority Matrix):** Just like setting a tower to target "Closest," "Strongest," or "Fastest," the player configures their computational focus: Resolve Highest Values First, Target Multipliers First, or Target Quickest to Solve.
- **Multishot & Bounce as Algebraic Expansion:** When a passive damage tick hits a cluster of terms, it fractures. An "Echo" or "Overstrike" doesn't just hit the main number; it distributes damage across adjacent terms, cancelling out several smaller linear equations simultaneously.
- **Tapping as Factoring:** Tapping directly on the screen allows the player to manually select and "factor out" specific dangerous terms (like a nasty multiplier or a division term) before the passive machine gets to it.
- **The 15-Second Resolution Boundary:** The wave timer is the evaluation step. When the 15-second clock hits zero, whatever unsolved mathematical terms remain on the board are calculated together and executed as a single, combined formula directly against the player's Number. If you left three +5k terms and a × 2 multiplier standing, you take a 30k hit.

## Why this works mechanically

- **Massive Multi-Threading Feel:** The player watches passive ticks, crits, and siphon cascades fire across 20 to 50 distinct equations simultaneously, creating the exact visual swarm and auditory density of an endgame tower defence setup without needing physics engines or navigation meshes.
- **Solves the Overkill Problem:** In a single-ring system, a massive 10,000,000 damage crit against a ring with 500 HP left is 99% wasted. In a field of multiple equations, that massive crit can pierce or cascade through the entire chain of terms, wiping out the entire board in a blinding algebraic wipeout.
- **Thematic Integrity:** It solidifies the identity of the game. It is not an abstract tower defence game with missing sprites; it is an active computation game where the player builds an engine powerful enough to balance a violently expanding ledger.

## Fit today

- **The overkill problem doesn't exist here.** Under D012, damage beyond a wave's remaining HP becomes Number (`TaxEncounter.apply_compliance` returns only what the wave absorbed, and the rest overflows). A big crit into a nearly dead wave is income, not waste. Spreading it across more terms would mostly move it from Number into more wave HP, so this argument points the other way.
- **This replaces the core encounter, not a feature.** Today a wave is one Wave HP and one Hit (`src/tax_encounter.gd`, D001, D014). Terms that multiply other terms make the Hit depend on which terms are left. That changes balance, the simulator, every balance target in `docs/WORKSHOP_DESIGN.md`, and the save shape of an active encounter (a list of terms instead of two numbers). This is the highest-risk tier in `docs/QUALITY_GATES.md` and needs a save migration.
- **Pillar 1 tension.** "The main screen never grows into a spreadsheet." A board of 20–50 live terms is close to that by definition. The run screen is also already squeezed to the top half by the Rig panel (D018, D032), which is little space for a swarm on a phone.
- **The Hit stops being readable in advance.** D015's contract is that the number is visible before it kills you. The evaluated formula would need to be shown live as a single "incoming Hit" figure, or × terms turn into surprise damage.
- **Gives several other ideas a home:** Echo and Overstrike as spread damage (`overstrike-and-echo.md`), the Division boss as a ÷ term (`boss-division.md`), taps as targeting (`damage-number-motion.md`). It also retires `ring-stress.md`, since there'd be no single ring.
- **Targeting priority is a new decision** with no current equivalent. It fits "depth lives in menus" if it's set outside the run screen.
- Spawn layouts and bounce/spread must come from the saved run RNG (D006).
- **A lower-risk slice:** keep one Wave HP and one Hit underneath, but draw the wave as an expression whose terms fall away as its HP drops. That gets the look and theme without touching the economy, and would show whether the look earns the full mechanic.
