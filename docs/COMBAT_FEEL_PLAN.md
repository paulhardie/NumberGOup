# Make the wave contest feel like combat

**Status:** Direction accepted in D041. D049 split the ring into Wave cleared and time to the Hit, and D050 draws each wave as a body that reaches the Number when its Hit lands, with distinct clear, Hit and boss beats. The fresh-player playtest below has not run. The enemy-growth idea below is a candidate, not a rule or a balance decision.
**Owns:** The next playable proof of the run's moment-to-moment feel. [`WORKSHOP_DESIGN.md`](WORKSHOP_DESIGN.md) owns the wave rule and player vocabulary; [`GAME_INVARIANTS.md`](GAME_INVARIANTS.md) owns behaviour; [`MOTION_SYSTEM.md`](MOTION_SYSTEM.md) owns motion and reduce-motion conventions.

## The question to settle before expanding progression

The Number is a strong focal point if a player can see what threatens it, act before the threat lands, and understand why the result changed. More ranks cannot make an unreadable run engaging. Prove the first 10–20 minutes as a visible contest before adding more long-term systems.

Today, output raises Number and damages Wave HP at once. The HP ring closes as the wave is cleared; its colour warms as the 15-second Hit approaches, and a line names the exact effective Hit and seconds left. Clearing the wave before the boundary already prevents its Hit. A missed ordinary wave hits once and moves on; a boss stays and can hit again. Rig spending lowers the Number available to survive a Hit. These rules stay as accepted in D037.

## The intended read during a wave

At a glance, the player should see two independent progress measures competing:

1. **Wave HP:** progress towards beating this wave, with the remaining amount readable. Keep the existing HP ring as the primary combat meter.
2. **Time until contact:** a distinct, steadily advancing meter for the 15-second boundary. Use a thin outer arc or adjacent track rather than relying on the HP ring's changing colour alone. It must remain legible in high contrast and reduce-motion modes.

Keep Number central. Next to the time warning, show the **effective Hit that would land now**, after current Armor, Guard, Rig, Labs, Cards and active modifiers; a visible `0` or `BLOCKED` state must not imply an ordinary wave was beaten. A useful compact read is `HIT 95 IN 6s` with `84 WAVE HP LEFT`. The warning and both meters must agree with `GameState` after purchases, Brace, wave changes, saves and reloads. UI presents the rules; it does not recalculate them.

When the player beats a wave before contact, the time threat resolves without a Hit, with a clear `BEATEN · NO HIT` beat. When an ordinary wave survives the timer, show the exact Number lost and remaining, then advance it. A boss remains visibly threatening through each repeat Hit. A Rig purchase should show its exact Number cost and the new buffer while the incoming Hit remains visible. Preserve the existing single accent and warning colour vocabulary; do not add a second combat HUD full of counters.

## Next playable proof

1. **Capture the current run at phone sizes.** Check whether a new player can distinguish HP cleared from time remaining, read the next effective Hit, and see that a clean clear prevents it. Record actual gaps before choosing the second meter's final shape.
2. **Make one focused HUD and feedback pass.** Separate the two progress measures, keep Number dominant, and make clear/Hit/boss outcomes distinct. Maintain stable touch controls, high contrast and reduce-motion behaviour. No encounter or economy formula changes in this pass.
3. **Test a fresh 10–20-minute run with players who have not read the design docs.** Ask them to predict the next Hit, explain a Rig spend, say why a wave did or did not hit, and name what they would change for the next run. Watch for repeated taps or cheapest-rank purchases made without looking at the wave.
4. **Decide from observed play.** If players understand the contest but have no interesting decision, investigate an encounter choice or counterplay rule. If they have choices but cannot read their effects, refine the presentation. Then measure the accepted change with the real-rules career simulator before expanding the Workshop or tiers.

**Pass condition:** Players can predict the next danger and explain the result without coaching, and at least one meaningful choice during a run makes them want to try a different approach next time. Record the observed sessions and what remained confusing; do not claim that a simulator or screenshot alone proves the loop is fun.

## Candidate: suppress an enemy increase

The Tower's Enemy Level Skip suggests a long-run growth tool: some wave transitions do not increase enemy health or attack pressure. Its useful role here would be to let a build fight the *future slope* of Wave HP or Hit, rather than merely absorb today's Hit. This is **not** part of D041 and does not alter the current curve.

Before deciding whether to add it, compare two designs in the real-rules simulator and a readable HUD mock-up:

- **Independent HP/Hit suppression:** a bounded chance at a wave boundary to hold one pressure axis at its previous effective level. It would need a clear trigger, capped cumulative effect, deterministic saved state, boss and tier rules, and an explanation of why the next wave is weaker than expected.
- **Earned, visible suppression:** a deterministic counter built by clean clears that holds one future increase. It offers a more legible cause and a player goal, but introduces run state and must not make Attack the answer to both offence and survival.

Measure wave reach, run length, Coins per minute, Attack-versus-Defense value and save/reload replay across fresh, mid and strong builds. If suppression only makes runs longer while leaving the player's next decision unchanged, it is a pacing stat rather than the combat answer sought here. Prefer improving the existing clear-before-Hit, Brace and Thorns feedback first.
