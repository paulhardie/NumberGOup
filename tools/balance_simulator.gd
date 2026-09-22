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
	"chain_reaction": 60, "automation_core": 50,
}
## The same fractions of each ladder the shallow builds held: mid was Output and
## Damage Multiplier maxed with Tick Speed at three fifths; early was two fifths
## of the two opening rows.
const MID := {"stronger_tap": 100, "generator": 100, "generator_two": 60, "faster_cadence": 60}
const EARLY := {"stronger_tap": 40, "generator": 40}
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
## label, tier, Workshop ranks. Progressed builds start with every Tier 1
## milestone claimed, so Coins per minute reflects repeatable rewards.
const BUILD_MATRIX := [
	["early", 1, EARLY],
	["mid", 1, MID],
	["attack max", 1, ATTACK_MAX],
	["attack max + armor", 1, [ATTACK_MAX, ARMOR]],
	["attack max + siphon", 1, [ATTACK_MAX, SIPHON]],
	["attack max + recoil", 1, [ATTACK_MAX, RECOIL]],
	["attack max + cushion", 1, [ATTACK_MAX, CUSHION]],
	["attack max + 2nd wind", 1, [ATTACK_MAX, SECOND_WIND]],
	["attack max + defense max", 1, [ATTACK_MAX, DEFENSE_MAX]],
	["defense max only", 1, DEFENSE_MAX],
	["attack max", 2, ATTACK_MAX],
	["attack max + armor", 2, [ATTACK_MAX, ARMOR]],
	# Cushion is the one stat whose worth depends on the tier, so it is measured
	# where it is meant to matter as well as where it is meant not to.
	["attack max + cushion", 2, [ATTACK_MAX, CUSHION]],
	["attack max + defense max", 2, [ATTACK_MAX, DEFENSE_MAX]],
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
	print("BUILD MATRIX  2 taps/sec, seed ", SEED)
	for build in BUILD_MATRIX:
		_simulate_build(build[0], build[1], _ranks(build[2]))
	quit(0)

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

func _simulate_build(label: String, tier: int, ranks: Dictionary) -> void:
	var state := GameState.new()
	state.purchased = ranks.duplicate()
	state.tier_records["1"] = {"highest_wave": 100, "milestones_claimed": [10, 25, 50, 100]}
	state.start_run(tier, SEED)
	var hits := 0
	var seconds := 0.0
	var reached := 0
	var peak := ScientificNumber.new()
	while seconds < MATRIX_SECONDS and state.in_run:
		reached = state.wave
		state.tap()
		var events: Array[SimulationEvent] = state.advance(STEP * 0.5)
		events.append_array(state.advance(STEP * 0.5))
		seconds += STEP
		for event in events:
			if event.type in ["tax_collection", "boss_collection", "wave_death"]:
				hits += 1
		if state.number.compare_to(peak) > 0:
			peak = state.number.copy()
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
		"  peak_number=", peak.format_value()
	)

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
				"  knowledge=", state.knowledge
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
