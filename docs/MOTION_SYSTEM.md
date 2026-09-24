# Number Go Up — Motion system

Status: reference document, last revised 24 September 2026 for D049.
Purpose: the game's motion vocabulary, and the specific techniques worth borrowing from two reviewed animation libraries. It records research; it does not introduce a framework or commit the game to any of these changes.
Companion documents: [`GAME_VISION.md`](GAME_VISION.md) for the feel this serves, [`QUALITY_GATES.md`](QUALITY_GATES.md) for the proof a motion change needs, [`DECISIONS.md`](DECISIONS.md) for choices once the owner accepts them.

## Verdict on the reviewed libraries

- **anime.js v4 (MIT)** — a DOM/SVG/JS-object animation engine. Godot's `Tween` already covers the useful surface: the Penner easing set, sequencing, parallelism, loops and a spring transition. **Do not vendor it.**
- **countUp.js v2.10.1 (MIT)** — a DOM number counter. Its value here is three techniques, not its code: smart easing, a count that lands, and stable digits. **Do not vendor it.**
- Nothing was copied. If a technique is later ported literally (for example anime.js's spring solver, which is itself adapted from WebKit), carry the MIT notice in the file header.

Vendoring either library would add dead weight to a Godot project: they cannot drive `Control` nodes, and the same ideas are a few dozen lines of GDScript at the point of use.

## Motion rules

These describe what the game already does; new motion should stay inside them.

1. **Reduce Motion is a hard gate for movement, not colour.** Translation and scale return early when `state.settings.reduce_motion` is set; colour fades may still run, because they carry no motion-sickness risk. `_pulse_number`, `_shake_number` and `_pulse_stage_impact` already obey this; `_flash_number` deliberately does not.
2. **Severity is duration and size, never a new hue.** One accent for positive states, one warning for negative, with boss hits distinguished by a larger, longer motion than routine tax. Extra colours read as noise on this HUD. The one exception is the currency icons (D049): a gold coin and a blue gem say which currency, not good or bad, so those colours stay on the icons and never tint an amount.
3. **Motion never blocks input and never moves what the player is reading.** A tween is feedback on top of an already-resolved state change, never a gate in front of one.
4. **One animated voice on the Number.** The big Number may pulse, flash or shake, but only one of those at a time, and the resting colour is always restored.
5. **Durations stay in the established bands.** Feedback (tap pulse, shake steps): 0.04–0.12 s. Transition (tab slide, toast fade): 0.15–0.5 s. Celebration (floating text, run-over beats): 0.35–1.2 s.
6. **Entrances ease out; exits ease in.** The tab panel slide (`TRANS_CUBIC`, `EASE_OUT`, 0.18 s) is the reference entrance.

## What Godot already provides (do not port these)

| anime.js feature | Godot 4.7 equivalent |
| --- | --- |
| `linear`, `inQuad` … `outElastic` | `Tween.TRANS_*` with `Tween.EASE_*`, including `TRANS_SPRING` |
| Timeline, `alternate`, `loop`, `delay` | `chain()`, `parallel()`, `set_loops()`, `set_delay()` |
| `cubicBezier()` | a `Curve` resource driven through `tween_method()`, or a hand-written easing |
| Spring physics parameters | not configurable: `TRANS_SPRING` is a fixed curve |
| `stagger()` | no equivalent — see below |
| Auto-animate on visibility | `CanvasItem.visibility_changed` or a `VisibleOnScreenNotifier2D` |

## Techniques worth taking

### 1. Smart easing for the big Number — countUp.js

countUp.js eases a count from its start to its end, but when the distance exceeds `smartEasingThreshold` (default 999) it splits the motion: the bulk moves **linearly**, and only a fixed tail (`smartEasingAmount`, default 333) is eased, with each phase taking half the total duration. This keeps a large jump readable instead of finishing in an eased blur.

Number Go Up's Number spans decades, so the same split belongs in log space, where the unit is a decade rather than a digit. The current `_advance_display_number` in `src/main.gd` is an exponential follow: correct for live production, but its speed scales with distance and it never quite lands. Sketch of the countUp shape for one-shot totals (reward panels, run-over figures), not for live production:

```gdscript
## Distance in decades above which the bulk of the count runs linearly.
const SMART_EASE_DECADES := 0.5
## Decades eased at the end of a large count, so the landing stays visible.
const SMART_EASE_TAIL := 0.15

func _ease_out_expo(t: float) -> float:
	return 1.0 if t >= 1.0 else 1.0 - pow(2.0, -10.0 * t)

func _smart_eased_log(from_log: float, to_log: float, t: float) -> float:
	if t >= 1.0:
		return to_log
	var distance := to_log - from_log
	if absf(distance) <= SMART_EASE_DECADES:
		return lerpf(from_log, to_log, _ease_out_expo(t))
	var direction := signf(distance)
	var linear_target := to_log - direction * SMART_EASE_TAIL
	if t < 0.5:
		return lerpf(from_log, linear_target, t * 2.0)
	return lerpf(linear_target, to_log, _ease_out_expo((t - 0.5) * 2.0))
```

### 2. Stable digits — countUp.js

countUp.js's tabular-numerals note is directly relevant: a counting label must not change width per frame. `_number_font_size` in `src/main.gd` re-measures the string and re-applies a font size every refresh, so a digit count or decimal change can visibly step the size. Options, cheapest first: use a font whose numerals are tabular, set the `tnum` OpenType feature on the shared `FontVariation` (`opentype_features`, when the base font supports it — the default fallback font may not), reserve a fixed width for the label, or animate per-digit labels (below). A stable width also lets the font-size fit run only when the string length actually changes.

### 3. A count that lands — countUp.js `onComplete` / `update`

countUp.js owns its duration, fires `onStartCallback` and `onCompleteCallback` once, and `update()` retargets from the current frame value without restarting from the old start. The follow in `_advance_display_number` has no landing, so nothing can fire "the Number finished moving". The strongest use is the run-over screen: its totals are one-shot, and a landing event is the natural moment for the existing pulse and flash. Live production should keep the follow, because production retargets every tick.

### 4. Odometer digits — countUp.js plugin

The odometer plugin rolls each digit column instead of redrawing a string. It is the highest-polish option and the highest-cost one: cost grows with digit count, and scientific notation has few stable columns to roll. If it is ever wanted, cap it to the last two or three digits of a short display string and leave the exponent static. Treat this as a candidate, not a plan.

### 5. Stagger — anime.js

anime.js's `stagger(value, { from, grid, ease, reversed })` distributes a delay across a set of targets, optionally from the centre. Godot has no equivalent, but it is one `set_delay` per item:

```gdscript
## A list arrives as one gesture rather than a pile of separate pops.
func _stagger_in(rows: Array[Control], step := 0.03) -> void:
	if state.settings.reduce_motion:
		return
	for index in rows.size():
		var row := rows[index]
		row.modulate.a = 0.0
		row.position.x = -12.0
		var tween := create_tween()
		tween.set_parallel(true)
		tween.tween_property(row, "position:x", 0.0, 0.16).set_delay(index * step).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tween.tween_property(row, "modulate:a", 1.0, 0.16).set_delay(index * step)
```

Use it where a set genuinely appears at once (Workshop boards on category change, unlocked rows), keep `step` at 0.02–0.05 s, and never stagger the tap Number or anything on the critical path.

### 6. Configurable spring — anime.js

anime.js exposes a real spring (`bounce`, `duration`, `mass`, `stiffness`, `damping`, `velocity`; defaults 0.5, 628 ms, 1, 100, 10, 0). Godot's `TRANS_SPRING` is fixed, so a celebratory bounce must either approximate with `TRANS_BACK` or `TRANS_ELASTIC`, or port the solver (MIT, via WebKit). Reserve it for milestone and run-over moments; never for routine feedback, and always behind Reduce Motion.

## Combat feedback map

Combat here is two abstract axes: production damages the wave's Liability, and the wave's Collection damages Number. Every event below is already emitted by `GameState.advance`; `main.gd` only presents it, so no rule lives in the UI.

| Event | What the player sees and feels | Reduce Motion |
| --- | --- | --- |
| A tap with Liability left | The ring takes the strike (quick scale pop) and the Number pulses. | Ring strike skipped; Number pulse skipped. |
| Passive ticks | The arc advances only. A strike per tick would strobe, so ticks deliberately have no separate hit. | Unchanged. |
| `tax_collection` | Damage float, Number flash, stage impact flash, a light stage rattle (3.5 px) and a short haptic. | Float and colour only. |
| `boss_collection` | The same at boss weight: a 9 px rattle, a longer flash, a stronger haptic. | Float and colour only. |
| Boss telegraph | Through the last 30% of a boss wave the stage glow throbs at ~1.3 Hz, deepening as the hit nears. | Unchanged: luminance, not movement. |
| `wave_clear` | Accent stage flash, ring pop, wave label pop, and a coin pop when the wave paid. | Label text changes only. |
| `boss_clear` | `wave_clear` at CRITICAL weight, plus the existing toast. | Toast only. |
| `second_wind` | Critical flash, stage impact and a boss-weight rattle. | Colour only. |
| `wave_death` | The run-over sheet counts Coins and Knowledge up from zero and each lands with a pop. | Totals appear at their final value. |
| Hit blocked by Brace | Accent flash, a light ring pop, no movement. | Ring pop skipped. |
| The wave's body (D050) | A pill with the wave's HP travels from the ring's edge to the Number on the wave clock. A clean clear shatters it (0.6 s) with a "BEATEN · NO HIT" float; a Hit slams a copy into the Number (0.43 s); after a boss's Hit it eases back to the edge. | The body holds at the edge; no shatter or slam. |

**Sound is not covered yet.** `AudioFeedback` ships tick and critical samples only; a Collection-hit sample and a wave-clear sample would follow the same map when they exist.

## Attribution

- anime.js — © Julian Garnier, MIT. https://github.com/juliangarnier/anime
- countUp.js — © Jamie Perkins, MIT. https://github.com/inorganik/countUp.js
- Easing functions in anime.js are adapted from Robert Penner's easing equations; its spring solver is adapted from WebKit's spring demo.

## Open questions

- Should one-shot totals count up with a landing event, or is the current always-chasing follow enough everywhere?
- Is odometer polish worth its layout cost, given how few stable digit columns scientific notation leaves?
- Does the Number's font ship tabular figures, or does stability need reserved width instead?
