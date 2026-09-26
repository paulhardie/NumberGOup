# Design brief: enemies as numbers

**Answered:** the design returned, and the owner chose option B, enemies showing their health, with a colour per type: [D085](../DECISIONS.md#d085--enemies-show-their-health-with-a-colour-each).

**For:** Claude Design. **From:** the owner of *Number Go Up*, via the development agent. **Date:** 26 September 2026.
**Attached:** four screenshots of the battle as it stands:
- `battle_120s.png`: a fresh run, wave 4;
- `battle_divider_walking.png`: a Divider walking in;
- `battle_divided.png`: a Divider landing;
- `battle_strong.png`: a strong tower, wave 13.

## The game in a paragraph

*Number Go Up* is a portrait idle tower-defence game modelled on *The Tower – Idle Tower Defense*, with one twist: **the tower is a number.**
- It sits in the middle of the screen and keeps rising while you survive.
- Enemies walk in from every side. When they touch the Number they do maths to it: most subtract, and a Divider divides it.
- The tower shoots the nearest enemy automatically. Between runs, the player spends Coins on permanent upgrades.
- A run ends when the Number hits zero. The fantasy is watching your Number climb while a crowd of hostile numbers tries to bring it down.

## The ask

**Turn the enemies into actual numbers.** At the moment they are small outlined squares and a diamond. Every enemy should *be* a number, with **a different typeface and colour for each type**, so a glance tells you what's coming.

Design:
1. **How each enemy type looks as a number:** typeface, weight, size and colour, and how it shows damage as it's shot.
2. **How the Number in the centre looks** among them. It now stands alone, with no ring round it.
3. **The contact moments:**
   - a subtracting enemy hitting the Number;
   - a Divider landing;
   - an enemy being killed.

## The one decision to explore first: which number does an enemy show?

Please mock up both, side by side. The owner will choose.

- **A. The enemy is its operation:** "−3", "÷1.25".
  - It shows exactly what it will do when it arrives: "−3" walks into 120 and leaves 117.
  - Its health, which is how many shots it takes, drains *within* the numeral, for example as a fill emptying or a fade, never as a second number.
  - **The development agent recommends A.** It's the most honest reading of the game's maths, and there's only one number per enemy.
- **B. The enemy is its health**, counting down as it's shot, from "18" to "0" and gone.
  - Shooting numbers down is visceral.
  - But what it does on arrival then needs a small second mark, such as "−3" or "÷", because health and damage are different numbers. A 54-health enemy only takes 14 off you.

## The screen

- **Portrait, 390 × 844 points** (phone), rendered in Godot 4. The battle arena is the top ~60% of the screen; the panels below are out of scope.
- **The arena** is a dark circle of about 125 pt radius (the tower's Range), centred, on a near-black ground. Enemies spawn off-screen, about 415 pt out, and walk straight at the centre. They're visible for their last ~10 seconds.
- **On screen at once:** usually 5–25 enemies, up to ~40 in a crowded wave. They can overlap while bunching at the centre.
- **The Number in the centre** runs from single digits ("5") to thousands ("18.29K"), in Geist Mono at about 26 pt, shrinking to fit around a 60 pt-wide space. Its colour states:
  - gold while it stands at a new peak;
  - mint (the accent) normally;
  - orange below a quarter of its peak;
  - a brief violet flash and shake when a Divider lands.

## The enemies (Tier 1, the first tier)

| Type | Role | Speed | Health | What it does on contact | Its number, waves 1 → 30 | Now drawn as |
|---|---|---|---|---|---|---|
| **Basic** | 85% of every wave; the crowd | 1× | 1× | Stays at the Number and subtracts once a second, each hit 4% harder than the last | −1 → −29 | 9 pt outlined square, red `#e0625a` |
| **Fast** | 7%; arrives first | 2.3× | 1× | As basic | −1 → −29 | 7 pt square, orange `#d68e5c` |
| **Tank** | 6%; soaks shots | 0.34× | 5× | As basic, half as hard | −0.6 → −14 | 13 pt thick square, red |
| **Ranged** | 2%; stops at the edge of the arena and shoots from there | 0.56× | 1× | Subtracts from range, once a second | −1 → −29 | 9 pt triangle, red |
| **Boss** | Every 10th wave, one per wave; a wall | 0.34× | 20× | Stays and subtracts, like a basic | −5 (wave 10) → −29 (wave 30) | 20 pt thick square, bright red `#ff4a3d` |
| **Divider** | From wave 5, 3–6% of a wave on top of the rest; the game's signature enemy | 1× | 4× | Divides the Number once (÷1.25 takes a fifth; ÷1.5 from wave 18 takes a third), then vanishes | ÷1.25, ÷1.5 | 12 pt diamond with "÷1.25" under it, violet `#b48cf2` |

Enemy health runs from about 2 (wave 1) to 130 (wave 30) for a basic enemy, times its type's multiple. The Tower itself tells types apart by shape: launch enemies are squares, elites are triangles. Here, typeface and colour take over that job.

## The feel

- **Honest.** You can always read what an enemy will do before it arrives. Nothing kills you that you couldn't see coming.
- **Readable at a glance on a phone.** An enemy's type should be clear from its typeface *and* weight, not from colour alone, so colour-blind players can play.
- **A crowd of numbers against one Number.** The centre Number should always be the most important thing on screen: brighter, bigger and calmer than the enemies.
- **The Divider is special:** it's the identity of the game, so its landing should be the biggest moment. Today that's a violet "÷1.25 −3.2K" float, a flash and a small shake.
- **Satisfying kills:** today a "$1" floats up in mint where an enemy dies.

## Constraints

- **Typefaces must be free to bundle:** SIL Open Font License or similar. Google Fonts is ideal. Aim for **no more than about four font files** in total, including the current Geist and Geist Mono if they're kept.
- **What the renderer can do, cheaply:**
  - any TTF/OTF font, including variable weights;
  - solid colour, per-draw alpha, outlines, drop-shadows (drawn as an offset copy), scaling and rotation.
- **What to avoid:** heavy blur or glow, which costs too much on phones. A soft glow faked with a larger low-alpha copy is fine.
- **Smallest readable size:** about 10–11 pt on a phone. Enemies can be larger than today's squares, but the arena is only about 250 pt across, so a crowd of 20 must still read.
- **Stay within the current look:**
  - near-black ground `#111213`, arena floor `#17181a`, lines `#2a2b2f`;
  - text `#ececea`, muted `#8b8c88`;
  - the player's accent is mint `#8fbfa8`, Coins are gold `#d4b04e`, warnings orange `#d68e5c`.

  Enemy colours may be new, but they should sit with this palette and stay apart from the player's mint and gold.
- **Reduced motion:** any shake or bounce must have a still alternative.

## Deliverables

1. **One spec table**, one row per enemy type: typeface and weight, size in points, colour hex, and how damage shows as it's shot. Include the Number in the centre, and the floating texts ("−3" at the Number, "÷1.25 −3.2K" for a Divider, "$1" on a kill).
2. **Mockups of three moments,** each in option A and option B:
   - wave 3 of a first run: a few basics, the Number around 8;
   - wave 10: the boss with some tanks and fast enemies, the Number around 200;
   - wave 20: a crowded wave with two Dividers and a ranged enemy, the Number around 450, one Divider landing.
3. **The Divider's landing** as a short sequence: approach, contact and aftermath.
4. Any notes on how an enemy's hits growing each second could show. Its number ticks up (−3 → −3.1 → …) while it stands at the Number.

**Out of scope:** the panels under the arena, the Workshop and the home screen.
