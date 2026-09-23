extends SceneTree

const DEFAULT_SECONDS := 3600.0
const STEP := 0.5
const SEED := 7
const CHECKPOINTS := [1, 21, 50, 100]
const MATRIX_SECONDS := 5400.0
## Every Attack row at its cap (D019 deepened the ladders without moving where
## they end, so this is the same power the three-rank caps used to reach).
const ATTACK_MAX := {
	"stronger_tap": 100, "generator": 100, "generator_two": 60, "faster_cadence": 100,
	"faster_echo": 60, "burst_relay": 6, "more_critical": 100, "magnitude_coil": 60,
	"chain_reaction": 60, "automation_core": 50, "boss_damage": 100,
}
const UTILITY_MAX := {"smarter_efficiency": 60, "coin_bonus": 100, "knowledge_bonus": 50}
## The same fractions of each ladder the shallow builds held: mid was Output and
## Damage Multiplier maxed with Tick Speed at three fifths; early was two fifths
## of the two opening rows.
const MID := {"stronger_tap": 100, "generator": 100, "generator_two": 60, "faster_cadence": 60}
const EARLY := {"stronger_tap": 40, "generator": 40}
## Forty-eight Coins is the first Tier 1 warm-up payout with checkpoints. D035's pricing
## lets that budget buy a mixed opening instead of Tap Damage alone.
const OLD_FIRST_RUN_SPEND := {"stronger_tap": 12}
const FIRST_RUN_SPEND := {"stronger_tap": 12, "generator": 6, "tax_resistance": 1}
## Defense rows at their caps, and the pieces of that build worth measuring on
## their own: balance target 6 asks that each one visibly move an outcome.
const ARMOR := {"tax_resistance": 100}
const SIPHON := {"siphon": 100}
const RECOIL := {"recoil": 100}
const CUSHION := {"priority_buffer": 50}
const SECOND_WIND := {"second_wind": 50}
const DEFENSE_MAX := {
	"tax_resistance": 100, "siphon": 100, "recoil": 100,
	"priority_buffer": 50, "brace_discount": 60, "second_wind": 50,
}
## label, tier, Workshop ranks, optional Rig policy. Progressed builds start
## with every Tier 1 milestone claimed, so Coins per minute reflects repeatable
## rewards. The Rig rows (targets 7-9) pair a build with and without in-run
## spending so the difference is the Rig's own.
const BUILD_MATRIX := [
	["fresh", 1, {}],
	["fresh + rig", 1, {}, "reinvest"],
	["old 48 Coin spend", 1, OLD_FIRST_RUN_SPEND],
	["new 48 Coin spend", 1, FIRST_RUN_SPEND],
	["early", 1, EARLY],
	["early + rig", 1, EARLY, "reinvest"],
	["mid", 1, MID],
	["mid + rig", 1, MID, "reinvest"],
	["attack max", 1, ATTACK_MAX],
	["attack max + rig", 1, ATTACK_MAX, "reinvest"],
	["attack max + armor", 1, [ATTACK_MAX, ARMOR]],
	["attack max + armor + rig", 1, [ATTACK_MAX, ARMOR], "reinvest"],
	["attack max + siphon", 1, [ATTACK_MAX, SIPHON]],
	["attack max + recoil", 1, [ATTACK_MAX, RECOIL]],
	["attack max + cushion", 1, [ATTACK_MAX, CUSHION]],
	["attack max + 2nd wind", 1, [ATTACK_MAX, SECOND_WIND]],
	["attack max + defense max", 1, [ATTACK_MAX, DEFENSE_MAX]],
	["attack max + utility max", 1, [ATTACK_MAX, UTILITY_MAX]],
	["everything maxed", 1, [ATTACK_MAX, DEFENSE_MAX, UTILITY_MAX]],
	["everything maxed + rig", 1, [ATTACK_MAX, DEFENSE_MAX, UTILITY_MAX], "reinvest"],
	["defense max only", 1, DEFENSE_MAX],
	["defense max only + rig", 1, DEFENSE_MAX, "reinvest"],
	["attack max", 2, ATTACK_MAX],
	["attack max + armor", 2, [ATTACK_MAX, ARMOR]],
	# Cushion is the one stat whose worth depends on the tier, so it is measured
	# where it is meant to matter as well as where it is meant not to.
	["attack max + cushion", 2, [ATTACK_MAX, CUSHION]],
	["attack max + defense max", 2, [ATTACK_MAX, DEFENSE_MAX]],
]
## The Rig policy the simulator plays. "reinvest" spends everything above the
## next hit on Rig ranks, in this order, restarting from the top after every
## purchase: the compounding damage rows first, because they are the ones worth
## going deep on, then the flat ones, then Defense when damage alone is not the
## answer. Deterministic, so a seeded run stays reproducible.
const RIG_PRIORITY := [
	"generator_two", "faster_cadence", "magnitude_coil", "more_critical",
	"stronger_tap", "generator", "faster_echo", "chain_reaction",
	"boss_damage", "tax_resistance", "siphon", "recoil", "coin_bonus",
]
## A boss within the HUD's three-wave warning puts Boss Damage first: the design
## says buying it two waves before a boss is the intended moment, and the first
## policy died on wave 40 bosses because it never did.
const RIG_BOSS_PRIORITY := ["boss_damage", "generator_two", "faster_cadence", "magnitude_coil", "more_critical"]
## Purchases inside this many seconds of the run's end measure whether Rig cost
## growth has outrun income (target 9).
const RIG_LATE_WINDOW := 600.0
## How many incoming hits the policy keeps in reserve. One is not enough: after
## a hit lands, a stuck wave keeps Number flat, so a second hit at zero ends the
## run. A prudent player keeps a margin, and so does the measurement.
const RIG_RESERVE_HITS := 2.0
## The Rig effect multiplier sweep (D023): one Rig rank is worth M Workshop
## ranks. Target 8 needs the Rig to beat hoarding; target 7 forbids a fresh
## build substituting for Workshop investment. The smallest M that passes both
## is the value the profile should keep.
const RIG_MULTIPLIER_SWEEP := [2.0, 3.0, 5.0, 8.0]
## The Rig price growth sweep (D039): each rank of a row costs this many times
## the last, in seconds of income. Gentle enough that prices never cliff, steep
## enough that top builds stop buying before the run becomes endless.
const RIG_GROWTH_SWEEP := [1.3, 1.4, 1.5, 1.6]
const CORE_SECONDS := 3600.0
const SWEEP_BUILDS := [
	["fresh", 1, {}],
	["mid", 1, MID],
	["attack max", 1, ATTACK_MAX],
	["everything maxed", 1, [ATTACK_MAX, DEFENSE_MAX, UTILITY_MAX]],
]
const PURCHASE_ORDER := [
	"stronger_tap",
	"generator",
	"generator_two",
	"faster_cadence",
	"faster_echo",
	"burst_relay",
	"more_critical",
	"magnitude_coil",
	"chain_reaction",
	"smarter_efficiency",
	"automation_core",
	"priority_buffer",
]

func _init() -> void:
	# `-- --opening` measures only the Tier 1 opening, for quick tuning passes.
	if OS.get_cmdline_user_args().has("--opening"):
		_simulate_opening()
		quit(0)
		return
	if OS.get_cmdline_user_args().has("--core-loop"):
		_simulate_core_loop()
		quit(0)
		return
	var state := GameState.new()
	print("BALANCE PROFILE  ", state.balance_profile.PROFILE_ID)
	for tier in state.balance_profile.tiers:
		print("TIER ", tier.id, "  pressure=", tier.liability_multiplier, "x  reward=", tier.reward_multiplier, "x")
		for checkpoint in CHECKPOINTS:
			print(
				"  W", checkpoint,
				"  liability=", state.balance_profile.liability_for_wave(tier.id, checkpoint).format_value(),
				"  collection=", state.balance_profile.collection_for_wave(tier.id, checkpoint).format_value(),
				"  reward=", state.balance_profile.reward_for_wave(tier.id, checkpoint)
			)
	_simulate_representative_tier_one()
	_simulate_opening()
	print("BUILD MATRIX  2 taps/sec, seed ", SEED)
	for build in BUILD_MATRIX:
		_simulate_build(build[0], build[1], _ranks(build[2]), str(build[3]) if build.size() > 3 else "none")
	print("RIG EFFECT MULTIPLIER SWEEP  (reinvest policy, one rank worth M Workshop ranks)")
	for multiplier in RIG_MULTIPLIER_SWEEP:
		for build in SWEEP_BUILDS:
			_simulate_build("M" + str(multiplier) + " " + str(build[0]), build[1], _ranks(build[2]), "reinvest", multiplier)
	print("RIG PRICE GROWTH SWEEP  (reinvest policy, M=3, each rank costs G times the last)")
	for growth in RIG_GROWTH_SWEEP:
		for build in SWEEP_BUILDS:
			_simulate_build("G" + str(growth) + " " + str(build[0]), build[1], _ranks(build[2]), "reinvest", -1.0, growth)
	quit(0)

## How the core loop feels on the shipped rules (D037): when the Number first
## visibly rises, the first Hit, and the longest stretch without a visible gain.
## Injected ranks test scaling interactions; they do not assert that a player
## can afford the build. The full matrix remains the authority for balance gates.
func _simulate_core_loop() -> void:
	print("CORE LOOP  seed=", SEED, "  every unit of output is Number and also strikes the wave")
	print("CORE LOOP  metrics: first_visible/first_hit and dry3m/dry_run are seconds; cap=", CORE_SECONDS, "s")
	_core_group("fresh", 1, {}, {}, {}, [], [0.0, 1.0, 2.0])
	_core_group("first spend", 1, FIRST_RUN_SPEND, {}, {}, [], [1.0, 2.0])
	_core_group("early", 1, EARLY, {}, {}, [], [2.0])
	_core_group("mid", 1, MID, {}, {}, [], [2.0])
	_core_group("attack + armor", 1, _ranks([ATTACK_MAX, ARMOR]), {}, {}, [], [2.0])
	_core_group("attack + armor", 2, _ranks([ATTACK_MAX, ARMOR]), {}, {}, [], [2.0])
	_core_group(
		"advanced layers", 1, _ranks([ATTACK_MAX, ARMOR]),
		{"lab_damage": 40, "lab_resilience": 40, "lab_coin_research": 40},
		{"card_damage": 7, "card_attack_speed": 7, "card_coins": 7, "card_extra_defense": 7},
		["card_damage", "card_attack_speed", "card_coins", "card_extra_defense"], [2.0]
	)

func _core_group(label: String, tier: int, ranks: Dictionary, labs: Dictionary, cards: Dictionary, active_cards: Array, tap_rates: Array) -> void:
	var rig_policies := ["hoard", "reinvest"]
	if label == "fresh" or label == "first spend":
		rig_policies = ["hoard", "first_two", "reinvest"]
	for tap_rate in tap_rates:
		for rig_policy in rig_policies:
			_core_case(label, tier, ranks, labs, cards, active_cards, float(tap_rate), str(rig_policy))

func _core_case(label: String, tier: int, ranks: Dictionary, labs: Dictionary, cards: Dictionary, active_cards: Array, tap_rate: float, rig_policy: String) -> void:
	var state := GameState.new()
	state.purchased = ranks.duplicate()
	state.lab_ranks = labs.duplicate()
	state.card_ranks = cards.duplicate()
	state.card_active.assign(active_cards)
	if label == "first spend":
		state.tier_records["1"] = {"highest_wave": 20, "milestones_claimed": [10, 20]}
	elif not ranks.is_empty():
		var claimed: Array = []
		for checkpoint in state.balance_profile.MILESTONE_WAVES:
			if checkpoint <= 100:
				claimed.append(checkpoint)
		state.tier_records["1"] = {"highest_wave": 100, "milestones_claimed": claimed}
	if tier > 1:
		state.tier_records["1"].highest_wave = GameState.TIER_UNLOCK_WAVE
	state.start_run(tier, SEED)
	var seconds := 0.0
	var tap_clock := 0.0
	var last_gain := 0.0
	var first_visible := -1.0
	var first_hit := -1.0
	var dry_run := 0.0
	var dry_intro := 0.0
	var rig_buys := 0
	while seconds < CORE_SECONDS and state.in_run:
		seconds += STEP
		if tap_rate > 0.0:
			tap_clock += STEP
			while tap_clock + 0.00001 >= 1.0 / tap_rate:
				tap_clock -= 1.0 / tap_rate
				var before_tap: ScientificNumber = state.number.copy()
				var before_tap_display: String = state.number.format_value()
				state.tap()
				if state.number.compare_to(before_tap) > 0 and state.number.format_value() != before_tap_display:
					last_gain = seconds
					if first_visible < 0.0:
						first_visible = seconds
		var before_ticks: ScientificNumber = state.number.copy()
		var before_ticks_display: String = state.number.format_value()
		var events: Array[SimulationEvent] = state.advance(STEP * 0.5)
		events.append_array(state.advance(STEP * 0.5))
		if state.in_run and state.number.compare_to(before_ticks) > 0 and state.number.format_value() != before_ticks_display:
			last_gain = seconds
			if first_visible < 0.0:
				first_visible = seconds
		for event in events:
			if first_hit < 0.0 and event.type in ["tax_collection", "boss_collection", "wave_death"]:
				first_hit = seconds
		if rig_policy != "hoard" and state.in_run and _rig_can_spend(state):
			if tier == 1 and state.wave <= 20 and state.rig_ranks_bought() < 2:
				var cost: ScientificNumber = state.get_rig_cost("generator")
				if state.can_purchase_rig("generator") and state.number.subtract(cost).compare_to(_rig_reserve(state)) >= 0 and state.purchase_rig("generator"):
					rig_buys += 1
			elif rig_policy == "reinvest":
				rig_buys += _play_rig(state)
		var dry := seconds - last_gain
		dry_run = maxf(dry_run, dry)
		if seconds <= 180.0:
			dry_intro = maxf(dry_intro, dry)
	var final_wave: int = state.wave if state.in_run else state.last_run_summary.wave_reached
	print(
		"  ", label.rpad(17), " T", tier,
		" taps=", tap_rate, " rig=", rig_policy,
		" wave=", final_wave, " time=", snappedf(seconds, 0.1),
		" coins=", state.coins,
		" first_visible=", snappedf(first_visible, 0.1),
		" first_hit=", snappedf(first_hit, 0.1),
		" dry3m=", snappedf(dry_intro, 0.1),
		" dry_run=", snappedf(dry_run, 0.1),
		" buys=", rig_buys,
		" status=", "alive" if state.in_run else "ended"
	)

## A build is one rank dictionary or a list of them merged, so the pieces can be
## named once and combined without repeating every Attack rank.
func _ranks(spec: Variant) -> Dictionary:
	if spec is Dictionary:
		return (spec as Dictionary).duplicate()
	var merged := {}
	for part in spec as Array:
		for key in part as Dictionary:
			merged[key] = (part as Dictionary)[key]
	return merged

func _simulate_build(label: String, tier: int, ranks: Dictionary, rig_policy: String = "none", rig_multiplier: float = -1.0, rig_growth: float = -1.0) -> void:
	var state := GameState.new()
	if rig_multiplier > 0.0:
		for category in state.balance_profile.RIG_EFFECT_MULTIPLIER.keys():
			state.balance_profile.RIG_EFFECT_MULTIPLIER[category] = rig_multiplier
	if rig_growth > 0.0:
		for category in state.balance_profile.RIG_COST_GROWTH.keys():
			state.balance_profile.RIG_COST_GROWTH[category] = rig_growth
	state.purchased = ranks.duplicate()
	# A build that has been here before: every Tier 1 checkpoint to wave 100 is
	# claimed, so the Gems column shows what a repeat run pays (D030).
	var claimed: Array = []
	for checkpoint in state.balance_profile.MILESTONE_WAVES:
		if checkpoint <= 100:
			claimed.append(checkpoint)
	state.tier_records["1"] = {"highest_wave": 100, "milestones_claimed": claimed}
	state.start_run(tier, SEED)
	var hits := 0
	var seconds := 0.0
	var reached := 0
	var peak := ScientificNumber.new()
	var rig_bought := 0
	var rig_late := 0
	var rig_purchases: Array = []
	while seconds < MATRIX_SECONDS and state.in_run:
		reached = state.wave
		state.tap()
		var events: Array[SimulationEvent] = state.advance(STEP * 0.5)
		events.append_array(state.advance(STEP * 0.5))
		seconds += STEP
		if rig_policy == "reinvest" and _rig_can_spend(state):
			var bought := _play_rig(state)
			if bought > 0:
				rig_bought += bought
				rig_purchases.append([seconds, bought])
		for event in events:
			if event.type in ["tax_collection", "boss_collection", "wave_death"]:
				hits += 1
		if state.number.compare_to(peak) > 0:
			peak = state.number.copy()
	for purchase in rig_purchases:
		if float(purchase[0]) >= seconds - RIG_LATE_WINDOW:
			rig_late += int(purchase[1])
	var minutes := seconds / 60.0
	print(
		"  T", tier, "  ", label.rpad(24),
		("death" if not state.in_run else "alive"),
		"  wave=", reached,
		"  minutes=", snappedf(minutes, 0.1),
		"  hits=", hits,
		"  coins=", state.coins,
		"  coins_per_min=", snappedf(float(state.coins) / minutes, 0.1),
		"  knowledge=", state.knowledge,
		"  gems=", state.gems,
		"  peak_number=", peak.format_value(),
		"  rig_ranks=", rig_bought,
		"  rig_last_10m=", rig_late
	)

## Plays the Rig the way a player reaching for the next wave does: never spend
## the Number that covers the incoming hit, and put everything else into the
## cheapest useful rank in priority order. Returns how many ranks landed.
func _play_rig(state: GameState) -> int:
	var bought := 0
	var order: Array = RIG_PRIORITY
	for ahead in range(1, 4):
		if state.balance_profile.is_boss_wave(state.wave + ahead):
			order = RIG_BOSS_PRIORITY
			break
	while true:
		var reserve := _rig_reserve(state)
		var purchased := false
		for upgrade_id in order:
			if not state.can_purchase_rig(upgrade_id):
				continue
			var cost: ScientificNumber = state.get_rig_cost(upgrade_id)
			if state.number.subtract(cost).compare_to(reserve) < 0:
				continue
			if state.purchase_rig(upgrade_id):
				bought += 1
				purchased = true
				break
		if not purchased:
			break
	return bought

## The Reinvestor spends "the moment a wave starts resisting": while a wave is
## cleared or still in warm-up it leaves the Number alone, so the buffer grows
## before the spend. Buying on easy waves is what made the first policy drain
## the buffer and die early.
func _rig_can_spend(state: GameState) -> bool:
	if state.active_encounter == null:
		return false
	return not state.active_encounter.is_cleared() and not state.active_encounter.max_liability.is_zero()

## The Number the policy will not spend: the hits that are actually coming, with
## a one-hit margin. While a wave is cleared, that is the next wave's hit, so
## the Number is spent down to a real reserve rather than to zero.
func _rig_reserve(state: GameState) -> ScientificNumber:
	var hit := ScientificNumber.new()
	if state.active_encounter != null and not state.active_encounter.is_cleared() and not state.active_encounter.max_liability.is_zero():
		hit = state.get_effective_collection()
	else:
		hit = state.balance_profile.collection_for_wave(state.selected_tier, state.wave + 1)
	return hit.multiply_scalar(RIG_RESERVE_HITS)

func _simulate_representative_tier_one() -> void:
	var state := GameState.new()
	state.start_run(1, SEED)
	var steps := int(DEFAULT_SECONDS / STEP)
	for step in range(steps):
		state.tap()
		state.advance(STEP * 0.5)
		state.advance(STEP * 0.5)
		if not state.in_run:
			print(
				"REPRESENTATIVE FIRST RUN  outcome=death",
				"  seconds=", snappedf(float(step + 1) * STEP, 0.1),
				"  wave=", state.last_run_summary.wave_reached,
				"  coins=", state.coins,
				"  knowledge=", state.knowledge,
				"  gems=", state.gems
			)
			# Spend down the way a player does, not one rank per row: with
			# ladders 50-100 ranks deep (D019), a single pass through the order
			# leaves almost all of the first run's Coins unspent.
			var spending := true
			while spending:
				spending = false
				for upgrade_id in PURCHASE_ORDER:
					if state.purchase(upgrade_id):
						spending = true
			print(
				"POST-RUN WORKSHOP  level=", state.get_workshop_level(),
				"  coins_remaining=", state.coins,
				"  tap=", state._tap_base(),
				"  number_per_sec=", snappedf(state.get_rate_per_second().mantissa * pow(10.0, state.get_rate_per_second().exponent), 0.01)
			)
			return
	print(
		"REPRESENTATIVE T1  outcome=alive",
		"  seconds=", DEFAULT_SECONDS,
		"  wave=", state.wave,
		"  number=", state.number.format_value(),
		"  coins=", state.coins
	)

## The Tier 1 opening from a fresh save (D033), at the tap rates a new player
## actually manages. The player buys the cheapest Attack Rig rank they can
## while keeping half again its price as a buffer. Opening targets: a first
## purchase within about 15 seconds, hits that do not erase the starting
## buffer, and a first run that funds Workshop ranks without idle farming.
const OPENING_TAP_RATES := [0.0, 1.0, 2.0, 3.0, 4.0, 6.0]
const OPENING_STEP := 1.0 / 30.0

func _simulate_opening() -> void:
	var preview := GameState.new()
	preview.start_run(1, SEED)
	print("TIER 1 OPENING HITS  base Collection and hit after the intro rule")
	for preview_wave in range(20, 27):
		preview.wave = preview_wave
		preview.active_encounter = preview._make_encounter(preview_wave)
		print("  W", preview_wave, "  base=", preview.active_encounter.collection.format_value(), "  effective=", preview.get_effective_collection().format_value())
	var no_action := GameState.new()
	no_action.start_run(1, SEED)
	var idle_seconds := 0.0
	while idle_seconds < 1800.0 and no_action.in_run:
		no_action.advance(OPENING_STEP)
		idle_seconds += OPENING_STEP
	var no_action_end := "alive at wave " + str(no_action.wave) if no_action.in_run else "wave " + str(no_action.last_run_summary.wave_reached)
	print("  no action  end=", no_action_end, " at ", snappedf(idle_seconds, 1.0), "s  coins=", no_action.coins)
	print("OPENING  fresh save, Tier 1, cheapest Rig rank kept 1.5x affordable, seed ", SEED)
	for rate in OPENING_TAP_RATES:
		var state := GameState.new()
		state.start_run(1, SEED)
		var seconds := 0.0
		var tap_clock := 0.0
		var first_purchase := -1.0
		var first_hit := -1.0
		var hits_first_minute := 0
		var hits := 0
		var three_minute := ""
		while seconds < 1800.0 and state.in_run:
			var events: Array[SimulationEvent] = state.advance(OPENING_STEP)
			seconds += OPENING_STEP
			if rate > 0.0:
				tap_clock += OPENING_STEP
				while tap_clock >= 1.0 / rate:
					tap_clock -= 1.0 / rate
					state.tap()
			for event in events:
				var landed: bool = event.type in ["tax_collection", "boss_collection", "second_wind"] and not event.amount.is_zero()
				if landed or event.type == "wave_death":
					hits += 1
					if seconds <= 60.0:
						hits_first_minute += 1
					if first_hit < 0.0:
						first_hit = seconds
			var cheapest := ""
			var cheapest_cost: ScientificNumber = null
			for row_id in ["generator", "stronger_tap", "generator_two"]:
				var cost := state.get_rig_cost(row_id)
				if cheapest_cost == null or cost.compare_to(cheapest_cost) < 0:
					cheapest = row_id
					cheapest_cost = cost
			if state.number.compare_to(cheapest_cost.multiply_scalar(1.5)) >= 0 and state.purchase_rig(cheapest):
				if first_purchase < 0.0:
					first_purchase = seconds
			if three_minute == "" and seconds >= 180.0:
				three_minute = "wave=" + str(state.wave) + " number=" + state.number.format_value()
		var summary := state.last_run_summary
		print(
			"  taps/s=", rate,
			"  first_buy=", (str(snappedf(first_purchase, 1.0)) + "s") if first_purchase >= 0.0 else "never",
			"  first_hit=", (str(snappedf(first_hit, 1.0)) + "s") if first_hit >= 0.0 else "never",
			"  hits_1m=", hits_first_minute,
			"  at_3m=", three_minute if three_minute != "" else "ended",
			"  end=", ("wave " + str(summary.wave_reached) + " at " + str(snappedf(seconds, 1.0)) + "s") if not state.in_run else "alive",
			"  hits=", hits,
			"  coins=", state.coins
		)
