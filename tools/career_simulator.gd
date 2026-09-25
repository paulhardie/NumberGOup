extends SceneTree

## A career from a fresh save, on the real rules: run after run at two taps a
## second, spending the Coins between runs, so Workshop pacing is measured as a
## player lives it rather than from injected builds. Since D068 the Workshop is
## The Tower's: rows open a group at a time for Coins, in its order.
##
## Run: bash run_godot.sh --headless --path . -s res://tools/career_simulator.gd
## Options after `--`: `--runs N` (default 40); `--spend even|focused` picks how
## the player spends between runs (default even); `--careers hoard,rig` runs
## only the named careers; `--run-cap-minutes N` caps each run (default 90).
## A career stops early once every Workshop row is at its last level.
##
## A measurement tool, not a gate. Not modelled: Prestige, Labs, Cards, Gems,
## tiers above 1, and retreating early.

const SEED := 7
const STEP := 0.5
var run_cap_seconds := 5400.0
const DEFAULT_RUNS := 40
const WAVE_MARKS := [20, 30, 50, 75, 100]
var spend_policy := "even"
## Run Upgrades the Reinvestor considers, the cheapest next level first, so
## one row does not take every Dollar.
const RIG_ROWS := [
	"damage", "attack_speed", "critical_chance", "critical_factor", "health", "health_regen",
	"defense_percent", "defense_absolute", "thorns", "range", "multishot_chance",
	"bounce_shot_chance", "lifesteal", "cash_bonus", "cash_per_wave", "coins_per_kill",
]
## [key, label, buys run Upgrades]
const CAREERS := [
	["hoard", "hoarding Cash", false],
	["rig", "buying run Upgrades", true],
]

func _init() -> void:
	var runs := DEFAULT_RUNS
	var args := OS.get_cmdline_user_args()
	var runs_at := args.find("--runs")
	if runs_at >= 0 and runs_at + 1 < args.size():
		runs = maxi(1, args[runs_at + 1].to_int())
	var cap_at := args.find("--run-cap-minutes")
	if cap_at >= 0 and cap_at + 1 < args.size():
		run_cap_seconds = maxf(1.0, args[cap_at + 1].to_float()) * 60.0
	var spend_at := args.find("--spend")
	if spend_at >= 0 and spend_at + 1 < args.size() and args[spend_at + 1] == "focused":
		spend_policy = "focused"
	print("CAREER  fresh save, Tier 1, 2 taps/sec, seed ", SEED, " + run, ", runs, " runs, each capped at ", int(run_cap_seconds / 60.0), " min")
	print("CAREER  spending: ", "focused (the cheapest level in its focus tab first: Attack, or Defense after a run that did not beat its best wave)" if spend_policy == "focused" else "even (one level of each open row in turn)")
	print("CAREER  unlocks: every affordable next unlock, cheapest first; the cheapest next one kept back if the last run paid for it")
	var only: Array = []
	var careers_at := args.find("--careers")
	if careers_at >= 0 and careers_at + 1 < args.size():
		only = Array(args[careers_at + 1].split(","))
	for career in CAREERS:
		if only.is_empty() or only.has(career[0]):
			_career(career[1], career[2], runs)
	quit(0)

func _career(label: String, play_rig: bool, runs: int) -> void:
	print("CAREER  ", label)
	var state := GameState.new()
	var hours := 0.0
	var marks := {}
	var best_wave := 0
	for run in range(runs):
		var coins_before := state.coins
		state.start_run(1, SEED + run)
		var seconds := 0.0
		var reached := 1
		var rig_levels := 0
		while seconds < run_cap_seconds and state.in_run:
			reached = state.wave
			state.tap()
			state.advance(STEP * 0.5)
			state.advance(STEP * 0.5)
			seconds += STEP
			if play_rig and state.in_run:
				rig_levels += _play_rig(state)
		if state.in_run:
			state.end_run()
		hours += seconds / 3600.0
		var earned := state.coins - coins_before
		for mark in WAVE_MARKS:
			if reached >= mark and not marks.has(mark):
				marks[mark] = [run + 1, hours]
		var stalled := run > 0 and reached <= best_wave
		best_wave = maxi(best_wave, reached)
		var opened := _buy_unlocks(state)
		var reserve := _unlock_reserve(state, earned)
		if spend_policy == "focused":
			_buy_levels_focused(state, reserve, "defense" if stalled else "attack")
		else:
			_buy_levels(state, reserve)
		var maxed := _workshop_maxed(state)
		if maxed and not marks.has("maxed"):
			marks["maxed"] = [run + 1, hours]
		print(
			"  run ", str(run + 1).lpad(2),
			"  wave=", str(reached).lpad(3),
			"  min=", str(snappedf(seconds / 60.0, 0.1)).lpad(5),
			"  coins+=", str(earned).lpad(8),
			"  hours=", str(snappedf(hours, 0.01)).lpad(5),
			"  level=", str(state.get_workshop_level()).lpad(5),
			"  damage=", _short(state.stat("damage")),
			"  health=", _short(state.stat("health")),
			("  rig=" + str(rig_levels)) if play_rig else "",
			("  opened: " + ", ".join(opened)) if not opened.is_empty() else "",
			"  coins_held=", state.coins
		)
		if maxed:
			break
	var summary: Array[String] = []
	for mark in WAVE_MARKS:
		if marks.has(mark):
			summary.append("wave " + str(mark) + " on run " + str(marks[mark][0]) + " (" + str(snappedf(float(marks[mark][1]), 0.1)) + " h)")
		else:
			summary.append("wave " + str(mark) + " not reached")
	if marks.has("maxed"):
		summary.append("Workshop maxed on run " + str(marks["maxed"][0]) + " (" + str(snappedf(float(marks["maxed"][1]), 0.1)) + " h)")
	else:
		summary.append("Workshop not maxed")
	print("  SUMMARY  ", "  ·  ".join(summary))

static func _short(value: float) -> String:
	return ScientificNumber.from_float(value).format_value()

## Opens every next unlock it can afford, cheapest first, and says what opened.
func _buy_unlocks(state: GameState) -> Array[String]:
	var opened: Array[String] = []
	while true:
		var cheapest := {}
		for category in ProgressionTaxonomy.WORKSHOP_CATEGORIES:
			var next := state.next_locked_group(category)
			if next.is_empty() or not state.can_unlock_group(str(next.id)):
				continue
			if cheapest.is_empty() or float(next.unlock_coins) < float(cheapest.unlock_coins):
				cheapest = next
		if cheapest.is_empty() or not state.unlock_group(str(cheapest.id)):
			return opened
		opened.append(str(cheapest.id) + " (" + str(int(cheapest.unlock_coins)) + ")")
	return opened

## A player saves for the cheapest next unlock only when one run pays for it.
func _unlock_reserve(state: GameState, last_run_coins: int) -> int:
	var cheapest := -1
	for category in ProgressionTaxonomy.WORKSHOP_CATEGORIES:
		var next := state.next_locked_group(category)
		if not next.is_empty():
			var price := int(ceil(float(next.unlock_coins)))
			if cheapest < 0 or price < cheapest:
				cheapest = price
	return cheapest if cheapest >= 0 and cheapest <= last_run_coins else 0

func _buy_levels(state: GameState, reserve: int) -> void:
	var buying := true
	while buying:
		buying = false
		for definition in state.definitions:
			if definition.category != ProgressionTaxonomy.WORKSHOP or not state.can_purchase(definition.id):
				continue
			if state.coins - state.get_workshop_coin_cost(definition) < reserve:
				continue
			if state.purchase(definition.id):
				buying = true

## Cheapest level first in the focus tab, then the other combat tab, then Utility.
func _buy_levels_focused(state: GameState, reserve: int, focus: String) -> void:
	for tab in (["defense", "attack", "utility"] if focus == "defense" else ["attack", "defense", "utility"]):
		while true:
			var cheapest_id := ""
			var cheapest_cost := -1
			for definition in state.definitions:
				if definition.category != ProgressionTaxonomy.WORKSHOP or definition.workshop_category != tab:
					continue
				if not state.can_purchase(definition.id):
					continue
				var cost := state.get_workshop_coin_cost(definition)
				if state.coins - cost < reserve:
					continue
				if cheapest_cost < 0 or cost < cheapest_cost:
					cheapest_id = definition.id
					cheapest_cost = cost
			if cheapest_id == "" or not state.purchase(cheapest_id):
				break

func _workshop_maxed(state: GameState) -> bool:
	for definition in state.definitions:
		if definition.category == ProgressionTaxonomy.WORKSHOP and state.get_owned(definition.id) < definition.max_rank:
			return false
	return true

## The Reinvestor: every step it buys the cheapest next level among the rows it
## plays, while Cash covers one. Returns how many levels landed.
func _play_rig(state: GameState) -> int:
	var bought := 0
	while true:
		var cheapest_id := ""
		var cheapest_cost: ScientificNumber = null
		for row_id in RIG_ROWS:
			if not state.can_purchase_rig(row_id):
				continue
			var cost := state.get_rig_cost(row_id)
			if cheapest_cost == null or cost.compare_to(cheapest_cost) < 0:
				cheapest_id = row_id
				cheapest_cost = cost
		if cheapest_id == "" or not state.purchase_rig(cheapest_id):
			return bought
		bought += 1
	return bought
