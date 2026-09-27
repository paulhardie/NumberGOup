# Design brief: the game stage

**Status:** sent to Claude Design on 27 September 2026; waiting for the design. When it returns, the owner's choices go into [`DECISIONS.md`](../DECISIONS.md) and this line says which.

**For:** Claude Design. **From:** the owner of *Number Go Up*, via the development agent. **Date:** 27 September 2026.

**Attached:** screenshots of the game as it stands, captured at 540 × 960 (the desktop window; the design canvas is 390 × 844, so scale by 0.72):

| File | What it shows |
|---|---|
| `battle_120s.png` | A fresh run, wave 4: a small Number, basic enemies arriving, kill floats |
| `battle_crowd.png` | Wave 20, the boss (white, with a red glow) and a crowd bunched at the Number |
| `battle_divider_walking.png` | A Divider (÷1.5) inside the range, previewed above the Number ("÷1.5 → 22,712") |
| `battle_divided.png` | A Divider landing: the violet flare and the "÷1.5 −13,988" float |
| `battle_multiplied.png` | A Multiplier (×1.1, a mint-green test enemy) landing |
| `battle_new_digit.png` | The Number reaching 1,000 for the first time: the ring and the flare |
| `battle_strong.png` | A late build: four orbs on the range edge, land mines (orange dots), the Wall (the white ring) and the shockwave |
| `battle_full_range.png` | Range bought up, with the view zoomed out |
| `home.png`, `workshop_attack.png` | Home and the Workshop, for the look the stage has to sit in |

---

## The prompt

*Number Go Up* is a portrait idle tower-defence game for phones, modelled on *The Tower – Idle Tower Defense*, with one twist: **the tower is a number.** It sits in the middle of the screen, large, thin and white, in a soft warm light that breathes. Enemies are numbers too: they walk in from every side and do maths to it when they arrive. Most subtract ("−2.4"), a Divider divides it ("÷1.5"). The tower shoots the nearest enemy automatically, and the player buys upgrades with Cash during a run and with Coins between runs. A run ends when the Number hits zero. The fantasy is watching your Number climb while a crowd of hostile numbers tries to bring it down.

The screens and the enemies have been designed already. **What hasn't been designed is the stage itself**: everything that moves in the arena around the Number. Shots, orbs, mines, the Wall, the shockwave, hits, kills and the floats were drawn by the developer as placeholders (mint dots, orange dots, white rings) and now look like a different game from the Number and the enemies. I want the stage nailed: one visual language for everything in the arena, and a view of how the battle screen's interface wraps round it.

### What I'd like back

1. **A stage language sheet.** Every element below at its real size on the dark ground, with its colour, size, typeface if any, and how it moves (timings in seconds). One grammar across them: what makes something read as *mine* (the tower's) versus *theirs* (an enemy's) at a glance.
2. **Six full phone frames (390 × 844)** of the battle at these moments:
   - a quiet early wave (Number around 12, five or six basic enemies);
   - a busy middle wave (Number in the thousands, 25 enemies, several standing at the Number and hitting it, shots in flight, a Divider walking in);
   - a Divider landing, the game's signature moment;
   - a late build with everything on: 4 orbs, multishot, bounce shots, land mines, the Wall standing, a shockwave going out;
   - the boss at the Number;
   - the Number reaching a new digit (9,999 → 10,000).
3. **Two directions side by side** where there's a real choice, above all for the orbs (see below). Recommend one and say why.
4. **The battle screen's interface around the stage:** the top bar, the Tower and Wave readouts, the run's upgrade panel, and the empty band at the foot of the screen, in the current look or better. Keep the stage the hero.
5. **A colour table** with hex values for everything, checked for colour-blind readability (the enemies were checked with CAM02-UCS ΔE; keep that bar).

### What stays as it is

These were chosen by the owner and should be kept, not redesigned:

- **The Number:** pure white, Geist at weight 200 with tabular figures, 96 px shrinking to fit as digits grow (never below 36), written out in full with commas up to 999,999, then "1.00M". It rolls to new values, and a spring nudges it away from a hit and back.
- **Its light:** a warm-white (`#FFF4E6`) halo behind it that breathes over 5.5 seconds, with a soft bloom at its heart. The owner wants **the light to carry states and, later, Ultimate Weapons**: today a ÷ flares it violet and a new digit flares it white. Design more of these (see below).
- **The ground** `#0A0A0B`, cards `#141416`, text `#EDEDED`, muted `#8C8C8C`, accent `#9CC5AE`, Coins gold `#D4B25C`.
- **Enemies are numbers showing what they do to the Number** ("−2.4", "÷1.5", "×1.1"), each type in its own cut and colour:

  | Type | Cut | Size | Colour |
  |---|---|---|---|
  | Basic (85% of a wave) | Anybody, width 100, weight 650 | 14 pt | red `#E0625A` |
  | Fast (2.3× speed) | Anybody, width 62, weight 720, slanted 12° | 13 pt | cyan `#4DD6E8` |
  | Tank (a third the speed, 5× health) | Anybody, width 150, weight 900 | 18 pt | pink `#FF7AC0` |
  | Ranged (stops on the range edge and shoots) | Anybody, width 125, weight 380, tracked +6% | 14 pt | lime `#C8E05A` |
  | Boss (every tenth wave) | Anybody, width 150, weight 900 | 24 pt | white-hot `#FFF0EA`, red `#FF4A3D` glow |
  | Divider | Fraunces, optical size 48, weight 640 | 18 pt | violet `#B48CF2`, soft glow |
  | Multiplier (on test) | Fraunces, as the Divider | 18 pt | mint `#A8F0C6` |

  An enemy that survives a shot shows the damage dealt so far under it, small and white (9 pt). The enemy cuts can be refined if the stage needs it, but not replaced.
- **Fonts:** Geist, Geist Mono, Anybody and Fraunces, all SIL OFL, all on Google Fonts. Add a fifth only with a strong reason.
- **No combat sounds** (ambient music only), and **no reduced-motion variant**: design the motion as it should be.
- **Portrait, 390 × 844.** The arena is the upper half; the range ring is a hairline (1 px, 6% white) of about 125 pt radius, centred about 190 pt from the top.

### The stage, element by element

For each: what it is in the game, how it's drawn today, and what's wrong.

**Shots.** The tower fires at the nearest enemy, 1 to about 6 shots a second, at 80 m/s (the range is 30 m, so a shot crosses it in under half a second). Today: a 1.8 pt mint dot with a 9 pt fading trail; a critical hit is a white 2.5 pt dot with a 15 pt trail. Multishot fires at up to 9 targets at once, and a bounce shot jumps on to up to 8 more enemies. **Wrong:** shots are the same mint as orbs, kill rewards and the Tower bar, and they come out of nowhere rather than out of the Number. Design where a shot leaves the Number, what it is (a dot, a digit, a sliver of the Number's light?), and how multishot, bounces and crits read differently.

**Hits and kills.** A hit knocks 3 chips off the enemy's number (6 white ones on a crit), and the enemy rocks back by its weight: a tank rocks less than half as much as a basic, the boss a third. A kill swells the enemy's number and fades it over 0.12 s, with a mint "$1" rising. **Wrong:** in a crowd the "$1" floats and the enemy numbers pile into an unreadable mess (see `battle_crowd.png`). Design the kill so it's satisfying in ones and still readable at 20 a second at ×5 speed.

**Enemies at the Number.** Enemies that arrive stand just clear of the Number's digits and hit it once a second, each hit 4% harder. The Number is wide ("32,349"), so they stand in an ellipse round it. **Wrong:** those on the same side overlap. Design how a standing crowd arranges itself and how a hit lands: the Number is knocked by a spring, and "−14" floats up at its upper right in `#E08A7A`. Is that enough? Should the light react?

**The Divider landing.** The signature moment. Today: the light flares violet and fades over 0.8 s, the Number shakes, and "÷1.5 −13,988" floats above it (÷ in Fraunces, the loss in Geist Mono, violet). While a Divider is inside the range, "÷1.5 → 22,712" previews what the Number will read. The Divider's ÷ is always gentle in Tier 1 (a fifth or a third) but in a big run it takes thousands. Make it the biggest moment on the stage.

**Orbs.** Up to 4 balls that circle the tower on the range edge, turning slowly at first (once every 16 seconds) and up to once a second when upgraded. Any non-boss enemy that touches one dies instantly; the boss is immune, and later other enemies will be too. Today: 5 pt mint dots. **The owner's idea: orbs as decimal points,** the Number's own dots orbiting it. Explore that properly (a decimal point that slips off the Number and circles out to the range; a dot with a trail; points that leave a faint arc as they turn) against one alternative. Also design an instant kill by an orb, and an immune enemy passing through one.

**Land mines.** Shots sometimes drop a mine on the ground inside the range (up to 30 at once); an enemy that comes within 2 m sets it off, a blast of 5–15 m radius. Today: 3 pt orange dots and a fading orange disc. **Wrong:** orange is the warning colour. Design the mine at rest and the blast.

**The Wall.** An upgrade that puts a barrier 10 m out; enemies break on it before the Number, and a Divider landing on it divides the Wall instead ("÷1.5 Wall"). It has its own health, falls and rebuilds. Today: a 3 pt white ring, fainter as it weakens, with "Wall down" and "Wall rebuilt" notes. **Wrong:** it looks like the new-digit ring. Design standing, damaged, falling and rebuilding.

**The shockwave.** Every 14–20 seconds a ring pushes out from the tower 6–23 m, knocking enemies back. Today: a white ring fading as it spreads. Design it so it can't be mistaken for the Wall or a new digit.

**Ranged enemies' shots.** A ranged enemy stops on the range edge and fires once a second. Today: a dotted lime line for 0.2 s. Keep it theirs, not the tower's.

**Other tower notes.** Death Defy (survives a killing hit, gold "Death Defied"), Recovery Packages (heal the Number), Rapid Fire (the attack speed bursts for a few seconds; the Number grows one size while it runs). Each is text today. Design them as moments, mostly through the light.

**The new-digit moment.** The first time a run's Number reaches 10, 100, 1,000 and on: the light flares white at twice the strength, a thin ring spreads to the range edge, the Number swells 14% and eases back, and the music chimes, over 1.4 s. It's the "number go up" beat. Refine it; it should feel like a milestone, not a hit.

**The range and the zoom.** The range ring grows as Range is bought, and past a point the whole view zooms out so the ring stays on screen. Enemies spawn off-screen and fade in over their first 2 m.

### The light's vocabulary

The owner wants the light behind the Number to be the stage's main instrument: it already breathes, flares violet on a ÷ and white on a new digit. Propose a small, consistent vocabulary for it: a hit, a crowd pressing in, the Number falling low against its peak, a Divider in range, Rapid Fire, Death Defy, a heal, and room for Ultimate Weapons later (they arrive in version 1.3). Keep it calm enough to breathe for hours; the owner plays half the time at ×5 speed.

### The interface round the stage

Today, top to bottom: Cash and Coins on one line with the ×1 speed pill and End run; the arena; a hairline; two readouts, Tower (the Number against its peak, a thin mint bar, damage and regen a second) and Wave (a thin white bar for how far through, the wave's enemy Attack and Health); Attack, Defense and Utility as underlined tabs with a "buy ×1" pill; two columns of cards (name, value, Cash price) that scroll. Below them the screen is empty. Design how this sits with the new stage, and:

- whether anything from the stage should echo in the interface (the wave's Divider count, the next boss, the Number's peak);
- what the empty band at the foot is for. Coming later: Cards (1.1, a hand of passive effects), Labs (1.2, research between runs) and Ultimate Weapons (1.3, powerful abilities with cooldowns that the player triggers in battle). Leave room for them rather than filling it;
- a run-over sheet: the peak Number, the wave reached, what took the Number (flat hits, ÷, by enemy type) and the Coins earned.

### Numbers and constraints

- **On screen at once:** 5–25 enemies, up to about 40 in a crowded wave; 1–6 shots a second, up to 9 at once with multishot, plus bounces; up to 30 mines and 4 orbs; a kill or more a second.
- **Enemies' numbers** run from "−1" in wave 1 to "−29" by wave 30; bosses hit harder. The Number runs from "5" to hundreds of thousands.
- **The renderer is Godot 4, 2D,** drawn every frame: circles, arcs, lines, polylines with per-point colour, text in any bundled font with variable axes and a synthetic slant, additive blending, and shaders (the light is one shader quad). Particles are cheap in the hundreds, not the thousands. Everything must hold 60 fps on a mid-range phone at ×5 speed. Sprites are possible, but the game's language is type and light: prefer that.
- **Honest:** everything that can hurt the Number is visible before it does.
- **Readable by shape, not colour alone.**
- **The Number is always the most important thing on screen,** except the boss, which the owner decided may outshine it.
