extends SceneTree

var failures := 0

func _init() -> void:
	_test_scientific_number()
	_test_bay_gates_and_rank_caps()
	_test_workshop_effects()
	_test_burst_and_positive_chance()
	_test_priority_queue()
	_test_save_v2_and_v1_migration()
	_test_offline_cap()
	_test_prestige_reset_and_gain()
	_test_baseline_pacing()
	_test_wave_tax_scales_with_number()
	_test_wave_tax_free_under_wave_21()
	_test_boss_wave_bonus_coins()
	_test_brace_blocks_next_tax()
	_test_shield_matrix_reduces_tax_and_survives_death()
	_test_wave_death_resets_run_but_keeps_meta_progress()
	_test_run_gates_the_wave_clock()
	_test_end_run_banks_progress_without_wiping()
	if failures > 0:
		print("FAIL: ", failures, " economy tests")
		quit(1)
	else:
		print("PASS: economy tests")
		quit(0)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func _test_scientific_number() -> void:
	_expect(ScientificNumber.from_float(1000).format_value() == "1,000", "numbers under a million should stay as full digits, not shrink to a short suffix")
	_expect(ScientificNumber.from_float(999999).format_value() == "999,999", "full digits should extend up to just under a million")
	_expect(ScientificNumber.from_float(1500000).format_value() == "1.5M", "abbreviation should start once a value reaches a million")
	_expect(ScientificNumber.new(4.72, 36).format_value() == "4.72e36", "large numbers should use scientific notation")
	var sum := ScientificNumber.new(9.0, 5).add(ScientificNumber.new(2.0, 5))
	_expect(sum.compare_to(ScientificNumber.new(1.1, 6)) == 0, "addition should normalize")
	_expect(ScientificNumber.from_float(5).subtract(ScientificNumber.from_float(9)).is_zero(), "subtraction cannot go negative")

func _test_bay_gates_and_rank_caps() -> void:
	var state := _funded_state()
	_expect(state.is_bay_active("output"), "Output should be active at Workshop level zero")
	_expect(not state.is_bay_active("speed"), "Speed should wait for Workshop level two")
	_expect(state.purchase("stronger_tap"), "Hand Press rank one should purchase")
	_expect(state.purchase("stronger_tap"), "Hand Press rank two should purchase")
	_expect(state.is_bay_active("speed"), "Speed should open at Workshop level two")
	state.purchased.stronger_tap = 5
	_expect(not state.can_purchase("stronger_tap"), "rank cap should prevent a sixth Hand Press")
	state.purchased.generator = 3
	_expect(state.is_bay_active("chance"), "Chance should open at Workshop level five")
	state.purchased.generator_two = 3
	_expect(state.is_bay_active("logic"), "Logic should open at Workshop level eight")

func _test_workshop_effects() -> void:
	var state := _funded_state()
	state.purchased = {"stronger_tap": 2, "generator": 2, "generator_two": 1, "faster_cadence": 1, "faster_echo": 1, "more_critical": 1, "magnitude_coil": 1, "smarter_efficiency": 1}
	state.rng.seed = 11
	var event := state.tap()
	_expect(event.amount.compare_to(ScientificNumber.from_float(3.45)) == 0, "Hand Press and Number Engine should affect taps")
	_expect(state.get_rate_per_second().compare_to(ScientificNumber.from_float(4.14)) == 0, "Desk Dynamo, Number Engine, and Tick Wheel should affect rate")
	_expect(state.get_cost(state.get_definition("generator")).compare_to(ScientificNumber.from_float(96.0925)) == 0, "Efficiency Matrix should reduce costs by five percent")
	_expect(is_equal_approx(state._critical_chance(), 0.05), "Critical Lens should add positive critical chance")
	_expect(is_equal_approx(state._critical_multiplier(), 3.0), "Magnitude Coil should add critical size")

func _test_burst_and_positive_chance() -> void:
	var state := _funded_state()
	state.purchased = {"generator": 1, "faster_cadence": 1, "burst_relay": 1}
	state.number = ScientificNumber.new()
	state.rng.seed = 999
	for tick in range(12):
		state._produce_tick()
	_expect(state.number.compare_to(ScientificNumber.from_float(19.5)) == 0, "Burst Relay rank one should double exactly the twelfth tick")
	_expect(state.statistics.critical_ticks == 0, "Chance cards must not create negative or forced critical events")
	_expect(state._critical_chance() >= 0.0, "Chance behavior is upside-only")
	var chain := _funded_state()
	chain.purchased = {"generator": 1, "more_critical": 5, "chain_reaction": 3}
	chain.number = ScientificNumber.new()
	chain.rng.seed = 3
	var before := chain.number.copy()
	chain._produce_tick()
	_expect(chain.number.compare_to(before) > 0, "Chance must always retain positive production")

func _test_priority_queue() -> void:
	var state := _funded_state()
	state.purchased = {"stronger_tap": 5, "generator": 3, "generator_two": 3, "smarter_efficiency": 3, "automation_core": 1, "priority_buffer": 2}
	state.set_automation_target(0, "faster_cadence")
	state.set_automation_target(1, "more_critical")
	state.set_automation_target(2, "generator")
	_expect(state.get_auto_slot_count() == 3, "Priority Buffer should expand Autopilot from one to three targets")
	state.number = ScientificNumber.from_float(100000)
	state.advance(1.1)
	_expect(state.get_owned("faster_cadence") == 1, "Autopilot should buy the first affordable priority")
	_expect(state.get_owned("more_critical") == 0, "Autopilot should not skip ahead once it buys a higher priority")

func _test_save_v2_and_v1_migration() -> void:
	var original: GameState = _funded_state()
	original.save_path = "user://number_go_up_test_save.json"
	original.purchased = {"stronger_tap": 2, "generator": 1}
	original.workshop.tick_count = 7
	original.workshop.automation_targets = ["generator"]
	_expect(original.save(), "V2 save should write")
	var restored: GameState = GameState.new()
	restored.save_path = original.save_path
	restored.load()
	_expect(restored.get_owned("stronger_tap") == 2 and restored.workshop.tick_count == 7, "V2 Workshop state should round-trip")
	restored.clear_save()
	var legacy := {
		"version": 1,
		"number": ScientificNumber.from_float(100).to_dict(),
		"lifetime": ScientificNumber.from_float(1000).to_dict(),
		"highest": ScientificNumber.from_float(100).to_dict(),
		"purchased": {"stronger_tap": 1, "steady_hand": 1, "workshop_bench": 2, "prototype_oddity": 4},
		"auto_selected": "generator",
		"statistics": {},
		"settings": {},
		"last_seen_unix": Time.get_unix_time_from_system()
	}
	var migration_path := "user://number_go_up_v1_migration.json"
	var file := FileAccess.open(migration_path, FileAccess.WRITE)
	file.store_string(JSON.stringify(legacy))
	file = null
	var migrated: GameState = GameState.new()
	migrated.save_path = migration_path
	migrated.load()
	_expect(migrated.get_owned("stronger_tap") == 2, "V1 hand upgrades should migrate into Hand Press ranks")
	_expect(migrated.workshop.legacy_credit == 6, "unmatched V1 progress should become non-spendable Workshop credit")
	_expect(migrated.workshop.automation_targets == ["generator"], "V1 automation target should become first priority")
	migrated.clear_save()

func _test_offline_cap() -> void:
	var state := GameState.new()
	state.purchased.generator = 1
	var award := state.apply_offline(GameState.OFFLINE_CAP_SECONDS + 3600.0)
	_expect(is_equal_approx(award.seconds, GameState.OFFLINE_CAP_SECONDS), "offline production must cap at 12 hours")
	_expect(award.capped, "offline award should report its cap")
	_expect(award.amount.compare_to(ScientificNumber.from_float(1)) > 0, "offline award should grant passive production")

func _test_prestige_reset_and_gain() -> void:
	var state := GameState.new()
	state.number = ScientificNumber.from_float(1)
	state.lifetime_generated = ScientificNumber.from_float(1000000000.0)
	state.purchased = {"stronger_tap": 2, "generator": 1}
	state.workshop.tick_count = 5
	state.workshop.selected_bay = "speed"
	var expected_gain := state.get_prestige_knowledge_gain()
	_expect(expected_gain > 0, "a lifetime total far past the teaser threshold should grant Knowledge")
	var gain := state.prestige()
	_expect(gain == expected_gain, "prestige should return the Knowledge it grants")
	_expect(state.knowledge == gain, "Knowledge should accumulate on the state")
	_expect(state.number.is_zero(), "prestige should reset Number")
	_expect(state.lifetime_generated.is_zero(), "prestige should reset lifetime so the next run re-earns Knowledge")
	_expect(state.get_owned("stronger_tap") == 0, "prestige should reset Workshop ranks")
	_expect(state.workshop.tick_count == 0, "prestige should reset Workshop tick state")
	_expect(not state.can_prestige(), "prestiging twice in a row without new progress should grant nothing")
	_expect(state.purchase_insight(), "Knowledge should buy Insight")
	_expect(state.get_owned("insight") == 1, "Insight rank should track purchases")
	_expect(state.knowledge == gain - 1, "Insight should spend one Knowledge per rank")
	var second_prestige := state.prestige()
	_expect(second_prestige == 0, "prestige without renewed lifetime progress should grant nothing")
	_expect(state.get_owned("insight") == 1, "Insight ranks must survive a reset that grants no new Knowledge")

func _test_baseline_pacing() -> void:
	var state := GameState.new()
	# This test locks down the original idle curve on its own terms; the wave-tax
	# prototype is a separate, newer system covered by its own tests below.
	state.wave_tax_enabled = false
	state.rng.seed = 7
	var order := ["stronger_tap", "generator", "generator_two", "faster_cadence", "faster_echo", "burst_relay", "more_critical", "magnitude_coil", "chain_reaction", "smarter_efficiency", "automation_core", "priority_buffer"]
	var desk_by_minute := false
	var speed_by_ninety := false
	var chance_by_three := false
	var logic_by_six := false
	var focus_by_eight := false
	var auto_by_eighteen := false
	for half_second in range(3600):
		state.tap()
		state.advance(0.5)
		for upgrade_id in order:
			state.purchase(upgrade_id)
		if state.focus_path == "" and state.get_workshop_level() >= GameState.RESEARCH_WORKSHOP_LEVEL:
			state.select_focus("output")
		if half_second == 119:
			desk_by_minute = state.get_owned("generator") > 0
		if half_second == 179:
			speed_by_ninety = state.get_owned("faster_cadence") > 0
		if half_second == 359:
			chance_by_three = state.get_owned("more_critical") > 0
		if half_second == 719:
			logic_by_six = state.get_owned("smarter_efficiency") > 0
		if half_second == 959:
			focus_by_eight = state.focus_path != ""
		if half_second == 2159:
			auto_by_eighteen = state.get_owned("automation_core") > 0
	_expect(desk_by_minute, "normal baseline should buy Desk Dynamo before one minute")
	_expect(speed_by_ninety, "normal baseline should reach Speed by ninety seconds")
	_expect(chance_by_three, "normal baseline should reach Chance by three minutes")
	_expect(logic_by_six, "normal baseline should reach Logic by six minutes")
	_expect(focus_by_eight, "normal baseline should set Research Focus by eight minutes")
	_expect(auto_by_eighteen, "normal baseline should buy Autopilot around eighteen minutes")
	_expect(state.lifetime_generated.compare_to(ScientificNumber.from_float(GameState.PRESTIGE_TEASER_UNLOCK)) >= 0, "normal baseline should reveal Prestige by thirty minutes")

func _test_wave_tax_scales_with_number() -> void:
	var small := GameState.new()
	small.number = ScientificNumber.from_float(1000.0)
	var small_event: SimulationEvent = small._resolve_wave(25)
	var large := GameState.new()
	large.number = ScientificNumber.from_float(1000000000.0)
	var large_event: SimulationEvent = large._resolve_wave(25)
	var expected_pct := 0.015 * pow(1.12, 5.0)
	_expect(is_equal_approx(small.get_wave_tax_percent(25), expected_pct), "wave 25 tax should follow the base*growth^(wave-20) curve")
	_expect(small_event.amount.compare_to(ScientificNumber.from_float(1000.0).multiply_scalar(expected_pct)) == 0, "tax removed should equal current Number times the wave's tax percent")
	_expect(large_event.amount.compare_to(ScientificNumber.from_float(1000000000.0).multiply_scalar(expected_pct)) == 0, "tax must scale proportionally at any magnitude of Number, never as a flat amount")

func _test_wave_tax_free_under_wave_21() -> void:
	var state := GameState.new()
	state.number = ScientificNumber.from_float(500.0)
	for w in range(1, GameState.FREE_WAVES + 1):
		var event: SimulationEvent = state._resolve_wave(w)
		_expect(event == null, "waves 1 through " + str(GameState.FREE_WAVES) + " must not tax Number")
	_expect(state.number.compare_to(ScientificNumber.from_float(500.0)) == 0, "Number should be untouched before wave 21")
	var first_taxed: SimulationEvent = state._resolve_wave(GameState.FREE_WAVES + 1)
	_expect(first_taxed != null and first_taxed.type == "wave_tax", "wave 21 should be the first wave to apply tax")

func _test_boss_wave_bonus_coins() -> void:
	var normal := GameState.new()
	normal.number = ScientificNumber.from_float(1000000.0)
	normal._resolve_wave(29)
	var boss := GameState.new()
	boss.number = ScientificNumber.from_float(1000000.0)
	boss._resolve_wave(30)
	_expect(boss.coins > normal.coins, "a boss wave should pay out more coins than an ordinary taxed wave")
	var expected_boss_pct := 0.015 * pow(1.12, 10.0) * GameState.BOSS_WAVE_TAX_MULTIPLIER
	_expect(is_equal_approx(boss.get_wave_tax_percent(30), expected_boss_pct), "a boss wave should multiply the base curve by the boss tax multiplier")

func _test_brace_blocks_next_tax() -> void:
	var state := GameState.new()
	state.number = ScientificNumber.from_float(1000.0)
	state.wave = GameState.FREE_WAVES
	_expect(not state.can_brace(), "bracing should not be available outside an active run")
	state.start_run()
	state.wave = GameState.FREE_WAVES - 1
	_expect(not state.can_brace(), "bracing should not be available while the next wave is still free")
	state.wave = GameState.FREE_WAVES
	_expect(state.can_brace(), "bracing should be available once the next wave would be taxed")
	_expect(state.brace(), "brace should succeed and spend Number")
	_expect(state.number.compare_to(ScientificNumber.from_float(700.0)) == 0, "brace should cost 30% of current Number")
	var event: SimulationEvent = state._resolve_wave(GameState.FREE_WAVES + 1)
	_expect(event != null and event.amount.is_zero(), "a braced wave should apply zero tax")
	_expect(not state.braced, "brace should be consumed after blocking one wave")

func _test_shield_matrix_reduces_tax_and_survives_death() -> void:
	var state := GameState.new()
	state.coins = 1000
	var base_cost := state.get_tax_resistance_cost()
	_expect(base_cost == GameState.TAX_RESISTANCE_COST_BASE, "the first Shield Matrix rank should cost the base coin price")
	_expect(state.purchase_tax_resistance(), "Shield Matrix should be purchasable with enough coins")
	_expect(state.tax_resistance_rank == 1, "purchasing should raise the Shield Matrix rank")
	_expect(state.coins == 1000 - base_cost, "purchasing should spend coins")
	var unresisted := 0.015 * pow(1.12, 5.0)
	var expected := unresisted * (1.0 - GameState.TAX_RESISTANCE_PER_RANK)
	_expect(is_equal_approx(state.get_wave_tax_percent(25), expected), "each Shield Matrix rank should reduce the tax percentage")
	# Coins and the Shield Matrix rank are meta progression: they must outlive a wave reset.
	state.wave = 25
	state._reset_run_state()
	_expect(state.coins == 1000 - base_cost, "coins must survive a run reset")
	_expect(state.tax_resistance_rank == 1, "Shield Matrix rank must survive a run reset")
	_expect(state.wave == 1, "a run reset should return the wave counter to 1")

func _test_wave_death_resets_run_but_keeps_meta_progress() -> void:
	var state := GameState.new()
	state.start_run()
	state.number = ScientificNumber.from_float(1.0)
	state.lifetime_generated = ScientificNumber.from_float(GameState.PRESTIGE_TEASER_UNLOCK * 100.0)
	state.purchased = {"stronger_tap": 3}
	state.workshop.tick_count = 12
	state.focus_path = "output"
	state.coins = 42
	state.run_coins_earned = 5
	state.highest_wave = 33
	state.tax_resistance_rank = 2
	# Wave 90 pushes the uncapped curve well past 100%, guaranteeing a wipe
	# regardless of how small Number already is.
	var expected_knowledge := state.get_prestige_knowledge_gain()
	_expect(expected_knowledge > 0, "the death scenario should have earned Prestige-worthy lifetime progress")
	# Wave 90 is also a boss wave, so it pays out its own coin bonus even though
	# it is the wave that kills the run — dying does not forfeit that payout.
	var expected_coin_gain := (90 - GameState.FREE_WAVES) * GameState.COIN_PER_TAXED_WAVE + (90 - GameState.FREE_WAVES) * GameState.BOSS_COIN_MULTIPLIER
	var event: SimulationEvent = state._resolve_wave(90)
	_expect(event != null and event.type == "wave_death", "tax that fully depletes Number should report a wave death")
	_expect(state.number.is_zero(), "wave death should reset Number")
	_expect(state.lifetime_generated.is_zero(), "wave death should reset lifetime the same way Prestige does")
	_expect(state.get_owned("stronger_tap") == 0, "wave death should reset Workshop purchases")
	_expect(state.focus_path == "", "wave death should reset the Research focus")
	_expect(state.wave == 1, "wave death should return the wave counter to 1 for the next run")
	_expect(not state.in_run, "wave death should end the run so the player returns to the hub")
	_expect(state.knowledge == expected_knowledge, "wave death should still bank any Knowledge the run had earned")
	_expect(state.coins == 42 + expected_coin_gain, "coins already earned, including the killing wave's own payout, must survive a wave death")
	_expect(state.highest_wave == 33, "the personal-best wave should survive a wave death")
	_expect(state.tax_resistance_rank == 2, "the Shield Matrix rank must survive a wave death")
	_expect(state.last_run_summary != null, "wave death should record a run summary for the DIED screen")
	_expect(state.last_run_summary.wave_reached == 90, "the run summary should report the wave the run died on")
	_expect(state.last_run_summary.coins_earned == 5 + expected_coin_gain, "the run summary should report only coins earned during this run, not the lifetime total")
	_expect(state.last_run_summary.knowledge_gained == expected_knowledge, "the run summary should report the Knowledge this run earned")

## advance() clamps each call's contribution to the wave clock (mirroring the
## tick accumulator's own safety clamp), so simulating N seconds means calling
## it repeatedly rather than passing N in one call.
func _advance_seconds(state: GameState, seconds: float) -> void:
	var elapsed := 0.0
	while elapsed < seconds:
		state.advance(0.25)
		elapsed += 0.25

func _test_run_gates_the_wave_clock() -> void:
	var state := GameState.new()
	state.number = ScientificNumber.from_float(1000.0)
	state.wave = GameState.FREE_WAVES
	_advance_seconds(state, 20.0)
	_expect(state.wave == GameState.FREE_WAVES, "the wave clock must not advance outside an active run, even with plenty of elapsed time")
	_expect(state.start_run(), "starting a run should succeed when not already in one")
	_expect(not state.start_run(), "starting a run while already in one should fail rather than silently resetting progress")
	_advance_seconds(state, 20.0)
	_expect(state.wave > GameState.FREE_WAVES, "the wave clock should advance once a run is active")

func _test_end_run_banks_progress_without_wiping() -> void:
	var state := GameState.new()
	state.start_run()
	state.number = ScientificNumber.from_float(1000.0)
	state.wave = 25
	state.coins = 7
	state.end_run()
	_expect(not state.in_run, "end_run should stop wave-clock exposure")
	_expect(state.number.compare_to(ScientificNumber.from_float(1000.0)) == 0, "ending a run voluntarily must not wipe Number")
	_expect(state.wave == 25, "ending a run voluntarily must keep the wave reached so a resumed run continues from there")
	_expect(state.coins == 7, "ending a run voluntarily must not touch coins")
	_advance_seconds(state, 20.0)
	_expect(state.wave == 25, "the wave clock must stay stopped after end_run until another run is started")
	_expect(state.start_run(), "a banked run should be resumable")
	_advance_seconds(state, 20.0)
	_expect(state.wave > 25, "resuming a run should continue the wave clock from where it was banked")

func _funded_state() -> GameState:
	var state := GameState.new()
	state.number = ScientificNumber.from_float(1000000)
	state.lifetime_generated = ScientificNumber.from_float(1000000)
	return state
