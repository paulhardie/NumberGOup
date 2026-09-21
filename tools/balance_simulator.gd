extends SceneTree

const DEFAULT_SECONDS := 3600.0
const STEP := 0.5
const SEED := 7
const CHECKPOINTS := [1, 21, 50, 100]
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
	quit(0)

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
