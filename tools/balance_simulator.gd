extends SceneTree

const DEFAULT_SECONDS := 3600.0
const STEP := 0.5
const SEED := 7
const CHECKPOINTS := [1, 21, 50, 100]
const MATRIX_SECONDS := 5400.0
## Builds on The Tower's rows (D068). Each is a set of Workshop levels; the
## Workshop's unlocks are all treated as bought, since a build names its rows.
## What a first failed run's Coins buy (about 250).
const FIRST_RUN_SPEND := {"damage": 3, "health": 2}
const EARLY := {"damage": 20, "attack_speed": 10, "health": 20, "health_regen": 10}
const MID := {
	"damage": 100, "attack_speed": 40, "critical_chance": 40, "critical_factor": 40, "range": 20,
	"health": 100, "health_regen": 50, "defense_percent": 30, "defense_absolute": 50,
}
## Every Attack row at level 100 or its last, and the same for Defense and
## Utility: the reach of a long first career.
const ATTACK_100 := {
	"damage": 100, "attack_speed": 99, "critical_chance": 79, "critical_factor": 100, "range": 79,
	"damage_per_meter": 100, "multishot_chance": 99, "multishot_targets": 7, "rapid_fire_chance": 85,
	"rapid_fire_duration": 99, "bounce_shot_chance": 85, "bounce_shot_targets": 7, "bounce_shot_range": 60,
}
const DEFENSE_100 := {
	"health": 100, "health_regen": 100, "defense_percent": 99, "defense_absolute": 100, "thorns": 99,
	"lifesteal": 80, "knockback_chance": 80, "knockback_force": 40, "orb_speed": 38, "orbs": 4,
}
const UTILITY_MAX := {
	"cash_bonus": 149, "cash_per_wave": 149, "coins_per_kill": 149, "coins_per_wave": 149,
	"free_attack_upgrade": 99, "free_defense_upgrade": 99, "free_utility_upgrade": 99, "interest": 99,
}
const DEFENSE_CORE := {"defense_percent": 99, "defense_absolute": 100}
const THORNS := {"thorns": 99}
const ORBS := {"orb_speed": 38, "orbs": 4}
## label, tier, Workshop levels, optional run Upgrade policy. Progressed builds
## start with every Tier 1 milestone claimed, so Coins per minute reflects
## repeatable rewards. The "reinvest" rows pair a build with in-run spending.
const BUILD_MATRIX := [
	["fresh", 1, {}],
	["fresh + rig", 1, {}, "reinvest"],
	["first spend", 1, FIRST_RUN_SPEND],
	["early", 1, EARLY],
	["early + rig", 1, EARLY, "reinvest"],
	["mid", 1, MID],
	["mid + rig", 1, MID, "reinvest"],
	["attack 100", 1, ATTACK_100],
	["attack 100 + rig", 1, ATTACK_100, "reinvest"],
	["attack 100 + defense", 1, [ATTACK_100, DEFENSE_CORE]],
	["attack 100 + thorns", 1, [ATTACK_100, THORNS]],
	["attack 100 + orbs", 1, [ATTACK_100, ORBS]],
	["attack + defense 100", 1, [ATTACK_100, DEFENSE_100]],
	["attack + defense 100 + utility", 1, [ATTACK_100, DEFENSE_100, UTILITY_MAX]],
	["defense 100 only", 1, DEFENSE_100],
	["attack + defense 100", 2, [ATTACK_100, DEFENSE_100]],
]
const CORE_SECONDS := 3600.0
## Purchases inside this many seconds of a run's end show whether run Upgrade
## prices have outrun Cash.
const RIG_LATE_WINDOW := 600.0
## The first failed run's spend-down, in The Tower's rows: one level of each
## in turn while Coins last.
const PURCHASE_ORDER := ["damage", "health", "attack_speed", "health_regen", "critical_chance", "critical_factor"]

func _init() -> void:
	# `-- --opening` measures only the Tier 1 opening, for quick tuning passes.
	if OS.get_cmdline_user_args().has("--opening"):
		_simulate_opening()
		quit(0)
		return
	# `-- --maxed-workshop` measures a fully maxed Workshop against one stopped at rank 100.
	if OS.get_cmdline_user_args().has("--maxed-workshop"):
		_simulate_maxed_workshop()
		quit(0)
		return
	# `-- --hit-sweep` measures balance target 5 across Hit scales (D063).
	if OS.get_cmdline_user_args().has("--hit-sweep"):
		_simulate_hit_sweep()
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
				"  coins=", snappedf(_wave_coins(state.balance_profile, tier.id, checkpoint, 0), 0.1)
			)
	_simulate_representative_tier_one()
	_simulate_opening()
	print("BUILD MATRIX  2 taps/sec, seed ", SEED)
	for build in BUILD_MATRIX:
		_simulate_build(build[0], build[1], _ranks(build[2]), str(build[3]) if build.size() > 3 else "none")
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
	_core_group("attack + defense", 1, _ranks([ATTACK_100, DEFENSE_CORE]), {}, {}, [], [2.0])
	_core_group("attack + defense", 2, _ranks([ATTACK_100, DEFENSE_CORE]), {}, {}, [], [2.0])
	# Labs and Cards add nothing while parked (D069), so this case would only
	# repeat the one above.
	if GameState.LAYERS_PARKED:
		return
	_core_group(
		"advanced layers", 1, _ranks([ATTACK_100, DEFENSE_CORE]),
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
	_open_all(state)
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
			if first_hit < 0.0 and event.type in ["tax_collection", "pile_hit", "boss_collection", "wave_death"]:
				first_hit = seconds
		if rig_policy != "hoard" and state.in_run and _rig_can_spend(state):
			if tier == 1 and state.wave <= 20 and state.rig_ranks_bought() < 2:
				if state.can_purchase_rig("damage") and state.purchase_rig("damage"):
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

func _simulate_build(label: String, tier: int, ranks: Dictionary, rig_policy: String = "none", hit_scale: float = -1.0) -> void:
	var state := GameState.new()
	if hit_scale > 0.0:
		state.balance_profile.COLLECTION_SCALE = hit_scale
	state.purchased = ranks.duplicate()
	_open_all(state)
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
			if event.type in ["tax_collection", "pile_hit", "boss_collection", "wave_death"]:
				hits += 1
		if state.number.compare_to(peak) > 0:
			peak = state.number.copy()
	for purchase in rig_purchases:
		if float(purchase[0]) >= seconds - RIG_LATE_WINDOW:
			rig_late += int(purchase[1])
	var minutes := seconds / 60.0
	print(
		"  T", tier, "  ", label.rpad(32),
		("death" if not state.in_run else "alive"),
		"  wave=", reached,
		"  minutes=", snappedf(minutes, 0.1),
		"  hits=", hits,
		"  coins=", state.coins,
		"  coins_per_min=", snappedf(float(state.coins) / minutes, 0.1),
		"  knowledge=", state.knowledge,
		"  gems=", state.gems,
		"  peak_number=", peak.format_value(),
		"  run_levels=", rig_bought,
		"  run_levels_last_10m=", rig_late
	)

## How far a player who has maxed the whole Workshop gets, with no Labs, Cards
## or run Upgrades. `rank 100` stops every row at level 100 or its last if
## lower; `maxed` is every row at its last level.
func _maxed_ladder(name: String) -> Dictionary:
	var ranks := {}
	for definition in GameState.new().definitions:
		if definition.category == ProgressionTaxonomy.WORKSHOP:
			ranks[definition.id] = definition.max_rank if name == "maxed" else mini(definition.max_rank, 100)
	return ranks

func _simulate_maxed_workshop() -> void:
	print("MAXED WORKSHOP  every row at its ladder's maximum, no Labs, Cards or run ranks, 2 taps/sec, seed ", SEED)
	for name in ["rank 100", "maxed"]:
		for tier in [1, 2, 3]:
			var state := GameState.new()
			state.purchased = _maxed_ladder(name)
			state.tier_records["1"] = {"highest_wave": 100, "milestones_claimed": [10, 20, 25, 30, 40, 50, 60, 75, 90, 100]}
			state.tier_records["2"] = {"highest_wave": 100, "milestones_claimed": []}
			state.start_run(tier, SEED)
			var seconds := 0.0
			var reached := 1
			while seconds < 10800.0 and state.in_run:
				reached = state.wave
				state.tap()
				state.advance(STEP * 0.5)
				state.advance(STEP * 0.5)
				seconds += STEP
			print(
				"  ", name.rpad(12), "T", tier, "  ", ("alive" if state.in_run else "death"), " at wave ", reached,
				"  minutes=", snappedf(seconds / 60.0, 0.1),
				"  coins=", state.coins,
				"  damage/s=", state.get_damage_per_second().format_value(),
				"  wave HP=", state.balance_profile.liability_for_wave(tier, reached).format_value()
			)

## Balance target 5: the cheapest build that reaches wave 100 includes both
## Attack and Defense. Each Hit scale runs the builds that decide it (max Attack
## alone must stop at or before the wave 100 boss; adding Defense must pass it)
## and the opening that the Hit also shapes (target 10's first Hits).
## Multipliers on D063's Hit (wave HP over the Tower-shaped ratio); 1 is today's.
const HIT_SWEEP_SCALES := [0.5, 0.75, 1.0, 1.5, 2.0, 3.0]
const HIT_SWEEP_BUILDS := [
	["fresh", {}, "none"],
	["fresh + rig", {}, "reinvest"],
	["early", EARLY, "none"],
	["mid", MID, "none"],
	["attack 100", ATTACK_100, "none"],
	["attack 100 + rig", ATTACK_100, "reinvest"],
	["attack 100 + defense", [ATTACK_100, DEFENSE_CORE], "none"],
	["attack + defense 100", [ATTACK_100, DEFENSE_100], "none"],
	["defense 100 only", DEFENSE_100, "none"],
]

func _simulate_hit_sweep() -> void:
	print("HIT SCALE SWEEP  (D063 Hit = scale x wave HP / Tower-shaped ratio; 2 taps/sec, seed ", SEED, ")")
	for scale in HIT_SWEEP_SCALES:
		print("SCALE ", scale)
		for tap_rate in [0.0, 1.0, 2.0]:
			var state := GameState.new()
			state.balance_profile.COLLECTION_SCALE = scale
			state.start_run(1, SEED)
			var seconds := 0.0
			var tap_clock := 0.0
			var first_hit := -1.0
			while seconds < 3600.0 and state.in_run:
				tap_clock += OPENING_STEP
				if tap_rate > 0.0 and tap_clock >= 1.0 / tap_rate:
					tap_clock -= 1.0 / tap_rate
					state.tap()
				var number_before: ScientificNumber = state.number.copy()
				for event in state.advance(OPENING_STEP):
					if first_hit < 0.0 and event.type in ["tax_collection", "pile_hit", "boss_collection", "wave_death"]:
						first_hit = seconds
				seconds += OPENING_STEP
				if first_hit < 0.0 and state.number.compare_to(number_before) < 0:
					first_hit = seconds
			print("  opening taps/s=", tap_rate, "  first_hit=", snappedf(first_hit, 1.0), "s  end=wave ", state.last_run_summary.wave_reached if not state.in_run else state.wave, "  coins=", state.coins)
		for build in HIT_SWEEP_BUILDS:
			_simulate_build(str(build[0]), 1, _ranks(build[1]), str(build[2]), scale)

## Plays run Upgrades the way a player reaching for the next wave does: the
## cheapest next level among the rows worth buying, while Cash covers one.
## Deterministic, so a seeded run stays reproducible. Returns the levels bought.
const RIG_ROWS := [
	"damage", "attack_speed", "critical_chance", "critical_factor", "health", "health_regen",
	"defense_percent", "defense_absolute", "thorns", "range", "multishot_chance",
	"bounce_shot_chance", "lifesteal", "cash_bonus", "cash_per_wave", "coins_per_kill",
]

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

## A build names its rows, so every Workshop unlock is treated as bought.
func _open_all(state: GameState) -> void:
	for group in state.workshop_group_list:
		if float(group.unlock_coins) > 0.0 and not state.workshop_groups.has(str(group.id)):
			state.workshop_groups.append(str(group.id))

## The Reinvestor spends while a wave stands, as before.
func _rig_can_spend(state: GameState) -> bool:
	if state.active_encounter == null:
		return false
	return not state.active_encounter.is_cleared() and not state.active_encounter.max_liability.is_zero()

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
			# Spend down the way a player does, a level of each row in turn.
			var spending := true
			while spending:
				spending = false
				for upgrade_id in PURCHASE_ORDER:
					if state.purchase(upgrade_id):
						spending = true
			print(
				"POST-RUN WORKSHOP  level=", state.get_workshop_level(),
				"  coins_remaining=", state.coins,
				"  damage=", state.stat("damage"),
				"  health=", state.stat("health"),
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
## actually manages. The player buys the cheapest of Damage, Attack Speed and
## Health as soon as Cash covers it.
const OPENING_TAP_RATES := [0.0, 1.0, 2.0, 3.0, 4.0, 6.0]
const OPENING_STEP := 1.0 / 30.0

func _simulate_opening() -> void:
	var preview := GameState.new()
	preview.start_run(1, SEED)
	print("TIER 1 CURVE  one set of rules from wave 1 (D040): Wave HP, Hit and Coins")
	for preview_wave in [1, 2, 5, 9, 10, 15, 19, 20, 21, 25, 30, 50, 100]:
		preview.wave = preview_wave
		preview.active_encounter = preview._make_encounter(preview_wave)
		print("  W", preview_wave, "  hp=", preview.active_encounter.max_liability.format_value(), "  hit=", preview.get_effective_collection().format_value(), "  coins=", snappedf(_wave_coins(preview.balance_profile, 1, preview_wave, SEED), 0.1))
	var no_action := GameState.new()
	no_action.start_run(1, SEED)
	var idle_seconds := 0.0
	while idle_seconds < 1800.0 and no_action.in_run:
		no_action.advance(OPENING_STEP)
		idle_seconds += OPENING_STEP
	var no_action_end := "alive at wave " + str(no_action.wave) if no_action.in_run else "wave " + str(no_action.last_run_summary.wave_reached)
	print("  no action  end=", no_action_end, " at ", snappedf(idle_seconds, 1.0), "s  coins=", no_action.coins)
	print("OPENING  fresh save, Tier 1, cheapest run Upgrade bought when affordable, seed ", SEED)
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
				var landed: bool = event.type in ["tax_collection", "pile_hit", "boss_collection", "death_defy"] and not event.amount.is_zero()
				if landed or event.type == "wave_death":
					hits += 1
					if seconds <= 60.0:
						hits_first_minute += 1
					if first_hit < 0.0:
						first_hit = seconds
			var cheapest := ""
			var cheapest_cost: ScientificNumber = null
			for row_id in ["damage", "attack_speed", "health"]:
				var cost := state.get_rig_cost(row_id)
				if cheapest_cost == null or cost.compare_to(cheapest_cost) < 0:
					cheapest = row_id
					cheapest_cost = cost
			if state.can_purchase_rig(cheapest) and state.purchase_rig(cheapest):
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

## What a wave pays if every enemy of it is killed (D066, D068): its kills by
## type and wave, and a fresh Coins / Wave, before any bonus.
static func _wave_coins(profile, tier_id: int, wave: int, seed: int) -> float:
	var total: float = profile.wave_end_coins(tier_id, 1.0)
	for entry in profile.wave_roster(wave, seed):
		total += profile.kill_coins(tier_id, wave, str(entry.kind))
	return total
