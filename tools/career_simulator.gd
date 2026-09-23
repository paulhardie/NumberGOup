extends SceneTree

## A career from a fresh save, on the real rules: run after run at two taps a
## second, spending the Coins between runs, so Workshop pacing is measured as a
## player lives it rather than from injected builds. It compares today's rules
## (rows open by Workshop level; run Upgrades sell every row) with the proposed
## coin gates (WORKSHOP_EXPANSION's Tower parity plan: starter rows, then
## one-time Coin unlocks in a fixed order per tab; run Upgrades sell only
## unlocked rows), and run ranks at other worths than the game's.
##
## Run: bash run_godot.sh --headless --path . -s res://tools/career_simulator.gd
## Options after `--`: `--runs N` (default 40); `--ladder plan|first|gentle`
## picks the gate prices (default plan); `--careers a,b` runs only the
## named careers (today_hoard, today_rig, gates_hoard, gates_rig, gates_worth1,
## gates_worth3).
##
## A measurement tool, not a gate. Not modelled: Prestige, Labs, Cards, Gems,
## tiers above 1, and retreating early. Gates for rows that do not exist yet are
## skipped at no cost, so later gates open slightly sooner than they will.

const SEED := 7
const STEP := 0.5
const RUN_CAP_SECONDS := 5400.0
const DEFAULT_RUNS := 40
const WAVE_MARKS := [20, 30, 50, 75, 100]

## The proposed starter rows and gates, existing rows only. Each gate names its
## position on the tab's price ladder (1 is the first gate), so a row keeps its
## planned place when rows that do not exist yet are skipped. Burst stands in
## for Frenzy, which replaces it.
const STARTER_ROWS := ["stronger_tap", "generator", "faster_cadence", "tax_resistance", "guard"]
const GATES := {
	"attack": [
		[1, ["more_critical", "magnitude_coil"]],
		[2, ["generator_two"]],
		[3, ["boss_damage"]],
		[4, ["automation_core"]],
		[6, ["burst_relay"]],
		[7, ["faster_echo"]],
		[8, ["chain_reaction"]],
	],
	"defense": [
		[1, ["recoil"]],
		[2, ["priority_buffer"]],
		[3, ["siphon"]],
		[4, ["brace_discount"]],
		[6, ["second_wind"]],
	],
	"utility": [
		[1, ["coin_bonus"]],
		[2, ["smarter_efficiency"]],
		[5, ["knowledge_bonus"]],
	],
}
## Gate prices by position, the same in every tab. `plan` is WORKSHOP_EXPANSION's
## current proposal, `first` and `gentle` the ladders it was measured against;
## `--ladder NAME` picks one.
const LADDERS := {
	"plan": [100, 250, 500, 1000, 2500, 6000, 15000, 35000, 80000, 180000, 400000],
	"first": [60, 150, 400, 1000, 2500, 6000, 15000, 35000, 80000, 180000, 400000],
	"gentle": [25, 75, 200, 500, 1250, 3000, 7500, 17500, 40000, 90000, 200000],
}
var ladder: Array = LADDERS["plan"]
## Between runs the player buys one rank of each row in turn while Coins last,
## so no row is starved and the spend is deterministic.
const RANK_ORDER := [
	"stronger_tap", "generator", "faster_cadence", "tax_resistance", "guard",
	"generator_two", "more_critical", "magnitude_coil", "boss_damage", "recoil",
	"siphon", "coin_bonus", "automation_core", "priority_buffer", "faster_echo",
	"burst_relay", "chain_reaction", "smarter_efficiency", "brace_discount",
	"second_wind", "knowledge_bonus",
]
## The balance simulator's reinvest order, so Rig play matches its measurements.
const RIG_PRIORITY := [
	"generator_two", "faster_cadence", "magnitude_coil", "more_critical",
	"stronger_tap", "generator", "faster_echo", "chain_reaction",
	"boss_damage", "tax_resistance", "siphon", "recoil", "coin_bonus",
]
const RIG_BOSS_PRIORITY := ["boss_damage", "generator_two", "faster_cadence", "magnitude_coil", "more_critical"]

## GameState with the proposed gates layered on top, for this tool only: a
## gated Workshop row is buyable, in the Workshop or during a run, once unlocked.
class CareerState extends GameState:
	var gated := false
	var unlocked := {}

	func set_run_rank_worth(worth: float) -> void:
		for category in balance_profile.RIG_EFFECT_MULTIPLIER.keys():
			balance_profile.RIG_EFFECT_MULTIPLIER[category] = worth

	func row_open(upgrade_id: String) -> bool:
		return not gated or unlocked.has(upgrade_id)

	func is_unlocked(definition: UpgradeDefinition) -> bool:
		if gated and definition.category == ProgressionTaxonomy.WORKSHOP:
			return unlocked.has(definition.id)
		return super.is_unlocked(definition)

	func can_purchase_rig(upgrade_id: String) -> bool:
		return row_open(upgrade_id) and super.can_purchase_rig(upgrade_id)

	func plan_rig_purchase(upgrade_id: String, count: int = 1) -> Dictionary:
		if not row_open(upgrade_id):
			return {"ranks": 0, "cost": ScientificNumber.new()}
		return super.plan_rig_purchase(upgrade_id, count)

func _init() -> void:
	var runs := DEFAULT_RUNS
	var args := OS.get_cmdline_user_args()
	var runs_at := args.find("--runs")
	if runs_at >= 0 and runs_at + 1 < args.size():
		runs = maxi(1, args[runs_at + 1].to_int())
	var ladder_at := args.find("--ladder")
	if ladder_at >= 0 and ladder_at + 1 < args.size() and LADDERS.has(args[ladder_at + 1]):
		ladder = LADDERS[args[ladder_at + 1]]
	print("CAREER  fresh save, Tier 1, 2 taps/sec, seed ", SEED, " + run, ", runs, " runs, each capped at ", int(RUN_CAP_SECONDS / 60.0), " min")
	print("CAREER  gate ladder: ", ladder)
	print("CAREER  gate policy: buy every affordable next gate, cheapest first; keep back the cheapest next gate if it costs no more than the last run's Coins; spend the rest on ranks in turn")
	var only: Array = []
	var careers_at := args.find("--careers")
	if careers_at >= 0 and careers_at + 1 < args.size():
		only = Array(args[careers_at + 1].split(","))
	for career in CAREERS:
		if only.is_empty() or only.has(career[0]):
			_career(career[1], career[2], career[3], runs, career[4])
	quit(0)

## [key, label, coin gates, buys run Upgrades, run rank worth (0: the game's)]
const CAREERS := [
	["today_hoard", "today's rules, hoarding", false, false, 0.0],
	["today_rig", "today's rules, buying run Upgrades", false, true, 0.0],
	["gates_hoard", "coin gates, hoarding", true, false, 0.0],
	["gates_rig", "coin gates, buying run Upgrades", true, true, 0.0],
	["gates_worth1", "coin gates, run ranks worth 1 (The Tower's)", true, true, 1.0],
	["gates_worth3", "coin gates, run ranks worth 3 (before D044)", true, true, 3.0],
]

func _career(label: String, gated: bool, play_rig: bool, runs: int, worth: float) -> void:
	print("CAREER  ", label)
	var state := CareerState.new()
	state.gated = gated
	if worth > 0.0:
		state.set_run_rank_worth(worth)
	for row_id in STARTER_ROWS:
		state.unlocked[row_id] = true
	var next_gate := {"attack": 0, "defense": 0, "utility": 0}
	var hours := 0.0
	var marks := {}
	for run in range(runs):
		var coins_before := state.coins
		state.start_run(1, SEED + run)
		var seconds := 0.0
		var reached := 1
		var rig_ranks := 0
		while seconds < RUN_CAP_SECONDS and state.in_run:
			reached = state.wave
			state.tap()
			state.advance(STEP * 0.5)
			state.advance(STEP * 0.5)
			seconds += STEP
			if play_rig and state.in_run and _wave_standing(state):
				rig_ranks += _play_rig(state)
		if state.in_run:
			state.end_run()
		hours += seconds / 3600.0
		var earned := state.coins - coins_before
		for mark in WAVE_MARKS:
			if reached >= mark and not marks.has(mark):
				marks[mark] = [run + 1, hours]
		var opened: Array[String] = []
		if gated:
			opened = _buy_gates(state, next_gate)
		var reserve := _gate_reserve(next_gate, earned) if gated else 0
		_buy_ranks(state, reserve)
		print(
			"  run ", str(run + 1).lpad(2),
			"  wave=", str(reached).lpad(3),
			"  min=", str(snappedf(seconds / 60.0, 0.1)).lpad(5),
			"  coins+=", str(earned).lpad(6),
			"  hours=", str(snappedf(hours, 0.01)).lpad(5),
			"  level=", str(state.get_workshop_level()).lpad(4),
			"  rows_open=", str(_rows_open(state)).lpad(2),
			("  rig=" + str(rig_ranks)) if play_rig else "",
			("  opened: " + ", ".join(opened)) if not opened.is_empty() else ""
		)
	var summary: Array[String] = []
	for mark in WAVE_MARKS:
		if marks.has(mark):
			summary.append("wave " + str(mark) + " on run " + str(marks[mark][0]) + " (" + str(snappedf(float(marks[mark][1]), 0.1)) + " h)")
		else:
			summary.append("wave " + str(mark) + " not reached")
	print("  SUMMARY  ", "  ·  ".join(summary))

## Buys every next gate it can afford, cheapest first, and returns what opened.
func _buy_gates(state: CareerState, next_gate: Dictionary) -> Array[String]:
	var opened: Array[String] = []
	while true:
		var best_tab := ""
		var best_price := -1
		for tab in GATES:
			var gates: Array = GATES[tab]
			if int(next_gate[tab]) >= gates.size():
				continue
			var price := _gate_price(gates[int(next_gate[tab])])
			if price <= state.coins and (best_price < 0 or price < best_price):
				best_tab = tab
				best_price = price
		if best_tab == "":
			return opened
		var gate: Array = GATES[best_tab][int(next_gate[best_tab])]
		state.coins -= best_price
		for row_id in gate[1]:
			state.unlocked[row_id] = true
		next_gate[best_tab] = int(next_gate[best_tab]) + 1
		opened.append(best_tab + " " + "+".join(gate[1]) + " (" + str(best_price) + ")")
	return opened

func _gate_price(gate: Array) -> int:
	return int(ladder[int(gate[0]) - 1])

## A player saves for the next gate only when one run pays for it.
func _gate_reserve(next_gate: Dictionary, last_run_coins: int) -> int:
	var cheapest := -1
	for tab in GATES:
		var gates: Array = GATES[tab]
		if int(next_gate[tab]) < gates.size():
			var price := _gate_price(gates[int(next_gate[tab])])
			if cheapest < 0 or price < cheapest:
				cheapest = price
	return cheapest if cheapest >= 0 and cheapest <= last_run_coins else 0

func _buy_ranks(state: CareerState, reserve: int) -> void:
	var buying := true
	while buying:
		buying = false
		for row_id in RANK_ORDER:
			var definition := state.get_definition(row_id)
			if definition == null or not state.can_purchase(row_id):
				continue
			if state.coins - state.get_workshop_coin_cost(definition) < reserve:
				continue
			if state.purchase(row_id):
				buying = true

func _rows_open(state: CareerState) -> int:
	var count := 0
	for definition in state.definitions:
		if definition.category == ProgressionTaxonomy.WORKSHOP and state.is_unlocked(definition):
			count += 1
	return count

## The balance simulator's Reinvestor: it spends while a wave is resisting, on
## the first affordable row in priority order, Boss Damage first near a boss.
func _wave_standing(state: GameState) -> bool:
	return state.active_encounter != null and not state.active_encounter.is_cleared() and not state.active_encounter.max_liability.is_zero()

func _play_rig(state: GameState) -> int:
	var bought := 0
	var order: Array = RIG_PRIORITY
	for ahead in range(1, 4):
		if state.balance_profile.is_boss_wave(state.wave + ahead):
			order = RIG_BOSS_PRIORITY
			break
	while true:
		var purchased := false
		for upgrade_id in order:
			if state.can_purchase_rig(upgrade_id) and state.purchase_rig(upgrade_id):
				bought += 1
				purchased = true
				break
		if not purchased:
			break
	return bought
