# Baseline Siphon / Visual Debt

*Batch: 2026-09-23 design and mechanics expansion — §1 Early game friction and the Rig curve.*

To resolve the static feel of the early game where Number does not rise until the wave is cleared, the game must provide immediate, tangible feedback for tapping.

Implement a baseline rule where 10% of all damage dealt instantly bleeds over into the Number pool, giving continuous validation. Alternatively, visualise damage accumulating inside the Wave HP ring as a "bank" that violently explodes into the Number pool upon clearing. The Siphon upgrade then scales this conversion rate.

## Fit today

- **The 10% bleed reverses D012.** D012 made output beat the wave before it becomes Number, specifically so the Number rises only while the player is ahead. A free baseline bleed brings back the Number rising while losing.
- Siphon already exists (D020): it banks a share of damage a wave absorbs, capped at 25% in the Workshop and 50% combined with the Rig (D023). D020 measured Siphon at 10% as moving nothing, so a 10% baseline would mostly be a feel change, not a balance one — but it would take away Siphon's reason to be bought.
- **The "visual bank" alternative changes no rule.** It is presentation over D012's existing overflow and could ship without touching the economy.
- D036 already lets the first Tier 1 waves overflow into Number, which attacks the same complaint from the balance side.
