extends SceneTree

const DEFAULT_SECONDS := 3600.0
const STEP := 0.5
const SEED := 7
const CHECKPOINTS := [1, 21, 50, 100]
const MATRIX_SECONDS := 5400.0
const ATTACK_MAX := {
	"stronger_tap": 5, "generator": 5, "generator_two": 3, "faster_cadence": 5,
	"faster_echo": 3, "burst_relay": 3, "more_critical": 5, "magnitude_coil": 3,
	"chain_reaction": 3, "automation_core": 1,
}
const MID := {"stronger_tap": 5, "generator": 5, "generator_two": 3, "faster_cadence": 3}
const EARLY := {"stronger_tap": 2, "generator": 2}
## label, tier, Workshop ranks, Shield Matrix rank. Progressed builds start with
## every Tier 1 milestone claimed, so Coins per minute reflects repeatable rewards.
const BUILD_MATRIX := [
	["early", 1, EARLY, 0],
	["mid", 1, MID, 0],
	["attack max", 1, ATTACK_MAX, 0],
	["attack max + shield 10", 1, ATTACK_MAX, 10],
	["attack max + shield 10", 2, ATTACK_MAX, 10],
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
		_simulate_build(build[0], build[1], build[2], build[3])
	quit(0)

func _simulate_build(label: String, tier: int, ranks: Dictionary, shield: int) -> void:
	var state := GameState.new()
	state.purchased = ranks.duplicate()
	state.tax_resistance_rank = shield
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
			for upgrade_id in PURCHASE_ORDER:
				state.purchase(upgrade_id)
			print(
				"POST-RUN WORKSHOP  level=", state.get_workshop_level(),
				"  coins_remaining=", state.coins,
				"  tap=", state._tap_base(),
				"  number_per_sec=", state.get_rate_per_second().format_value()
			)
			return
	print(
		"REPRESENTATIVE T1  outcome=alive",
		"  seconds=", DEFAULT_SECONDS,
		"  wave=", state.wave,
		"  number=", state.number.format_value(),
		"  coins=", state.coins
	)
