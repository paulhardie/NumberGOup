# Menus and pop-ups

**Status:** built 3 October 2026 (D151) on the owner's request: "a sweep of where The Tower does tap-and-hold info, and where we should… build a framework for menus and pop ups". The framework and what moved onto it are real; the "should" list in section 3 is a recommendation, not a plan.

## 1. The framework

Two scripts under `src/ui/` own every menu and pop-up. A screen never builds its own shade, centred card or top panel again.

- **`overlay.gd` (`Overlay`)** is a card laid over a screen, with two kinds:
  - **SHEET:** centred over a shade that blocks the screen. For something the player answers or reads on its own: Settings, Milestones, a card's details, what a Workshop group opens, one held Workshop row.
  - **BANNER:** pinned under the top bar, blocking nothing, so a run goes on beneath it: Wave Info, a new enemy's card, an upgrade held in battle.
- **`hold_to_read.gd` (`HoldToRead`)** gives a control a tap and a hold. A tap does what the control always did. A hold (0.45 s, drifting less than 10 canvas points) reads it instead, and the lift after a hold does nothing, so reading an upgrade never buys it.
- **`upgrade_info.gd`** is the one layout for "what this upgrade row says", shared by the Workshop (Coins) and a run (Cash).

The rules, which the tests hold:

1. **One SHEET and one BANNER per screen at a time.** Showing another of the same kind replaces it. A SHEET always sits above a BANNER. A card the player didn't ask for (a new enemy's) waits rather than push off one they did (Wave Info, a held upgrade).
2. **A sheet blocks the screen; a banner never does.** A sheet's shade tap and Escape close it, unless it must be answered (`dismissable` off: the Workshop's welcome).
3. **A card's buttons close it first and then act** (`Overlay.action`), so what they do (leave the screen, change a setting) meets a screen with nothing over it.
4. **Nothing here pauses the game.** The Tower's Wave Info stays live and so does ours. A card over a run is a banner for that reason.
5. **What a card says belongs to the screen that opens it.** Overlay lays out and places; it holds no game rule (law 2). The numbers on an upgrade card come from `Workshop`, `TowerData` and `BattleSim` (`stat_with`, a read-only look one level on).
6. **A screen keeps a card it clears itself:** `sheet.closed.connect(func(): if field == sheet: field = null)`. Showing a new card closes the old one first, so an unguarded handler would clear the new card's field.
7. **Hold works on a disabled button.** The gesture reads the control's raw mouse input (a touch arrives as a mouse press too), because the upgrade a player most wants explained is the one they can't afford.

To add a pop-up: `var sheet := Overlay.new()`, fill `sheet.column` (or `heading`, `text`, `rule`, `action`, `done`), `sheet.show_over(self)`. To make an element readable: `HoldToRead.attach(control, on_hold, on_tap)`. A card shown again and again (`Overlay.new(kind, tap_closes, true)`) is kept, hidden, when closed; add it to the screen up front so it goes with the screen.

## 2. What exists, and what The Tower is known to do

**What the repository records of The Tower** is three popups: Wave Info, opened by tapping the wave counter (the owner's screens, [TOWER_RULES.md](TOWER_RULES.md)); an info popup the first time each upgrade unlocks (patch notes 0.2x); and a welcome popup at a first death (the owner, 30 September, D125). The Cards details popup is described in the code as The Tower's own (D146); I haven't seen the screenshot it came from.

**Not proven: any hold gesture in The Tower.** Nothing in the repository records one, and I found nothing in public sources (the community wiki's pages are Notion pages that don't load for a fetch, and a published beginner's guide doesn't mention one). The hold-to-read on tiles is our design, as it was in the pre-rebuild game (D049), not a copied behaviour. A short screen recording of long-pressing around The Tower would settle what to copy.

| Surface | Opens by | Kind | Source |
|---|---|---|---|
| Settings | `•••` on Home | SHEET | ours |
| Milestones | tap the best Number | SHEET | ours (D107) |
| Workshop's welcome | first run's end | SHEET, answered | The Tower (D125) |
| What a group opened | opening it | SHEET | The Tower's unlock popup (D125) |
| A card's details, a card drawn | tap a card, draw | SHEET | modelled on The Tower's (D146) |
| **A Workshop row's card** | **hold the tile** | SHEET | ours (D151) |
| **What the next group unlocks** | **hold the unlock tile** | SHEET | ours (D151) |
| Wave Info | tap the wave line | BANNER | The Tower (D115) |
| A new enemy's card | first meeting past the best wave | BANNER | ours (D133) |
| **A run upgrade's card** | **hold the tile** | BANNER | ours (D151) |
| The run-over panel | the run ending | **not on the framework** | see below |

## 3. Where we should, by value

Each is small unless noted, and none is built. Copy means words that don't exist yet.

| Where | What it would do | Copy | My call |
|---|---|---|---|
| **A hint that holding reads** | Nothing today says a hold does anything. One line in the first unlock popup, or under the Workshop's top bar, until the player has held once. | one line | Do it with this change if the owner wants hold at all. |
| **End run** | It ends the run on one tap, with no confirmation. A confirm sheet is `Overlay` plus two `action`s. | exists | **Owner's call:** it adds a tap to a button the owner uses at ×5 often. Reset already asks twice. |
| **Wave Info rows** | Hold an enemy's row for what it does and its numbers. | 3 of 11 kinds exist (`FIRST_SIGHT`); 8 to write | Worth it; the largest of these (writing 8 cards). |
| **Dock items still locked** (Labs 1.2, Weapons 1.3) | Say what it brings and what opens it (Labs at wave 30). Disabled buttons still hear a hold. | to write | Cheap and answers a question players will have. |
| **Currency chips** (Coins, Gems, Cash) | What it is for and where it comes from. | to write | Low. |
| **The daily Gems pill** | Its explanation is a tooltip, which a phone never shows. Hold it instead. | exists | Tiny; I'd do it next. The Cards tiles' tooltips ("tap for details") have the same fault but say nothing a player needs. |
| **The run-over panel** | Move onto a SHEET, so it shades the arena like every other panel. | exists | **Owner's call:** it changes how the end of a run looks. Left alone here. |
| **The Number** (hold it in battle) | What the Number is and what hit it. | waits on THE_NUMBER.md | Wait until open decision 1 (what the Number is) is settled. |

**A foundation gap, for the owner to sequence.** Home, the Workshop and Cards each build the same screen scaffold by hand (ground, margins, top line, scroll, dock). Labs (1.2) and Weapons (1.3) are two more. That is a candidate for a shared screen base, as `Overlay` is for cards. It touches every screen's layout, so it is not part of D151.
