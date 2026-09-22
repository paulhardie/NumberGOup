extends SceneTree

const RuleModifierPipelineClass = preload("res://src/rule_modifier_pipeline.gd")

var failures := 0

func _init() -> void:
	_test_scientific_number()
	_test_category_gates_and_rank_caps()
	_test_research_focus_targets_a_category()
	_test_multi_buy_matches_buying_one_at_a_time()
	_test_stat_values_read_the_row_effect()
	_test_deepened_ladders_keep_their_old_maxima()
	_test_workshop_effects()
	_test_burst_and_positive_chance()
	_test_permanent_baseline_and_starting_reserve()
	_test_save_v5_and_legacy_migration()
	_test_offline_policy()
	_test_prestige_reset_and_gain()
	_test_first_run_funds_permanent_workshop()
	_test_tier_pressure_and_curve_gates()
	_test_production_clears_liability()
	_test_output_beats_the_wave_before_it_becomes_number()
	_test_repeated_taps_count_once()
	_test_stuck_wave_keeps_its_damage_and_hits_again()
	_test_mid_wave_save_resumes_identically()
	_test_collection_is_absolute()
	_test_boss_axes_and_rewards()
	_test_brace_blocks_next_collection()
	_test_armor_reduces_the_hit_and_survives_reset()
	_test_siphon_banks_a_share_of_damage_dealt()
	_test_recoil_deals_the_hit_back_to_the_wave()
	_test_brace_cost_falls_to_its_floor()
	_test_second_wind_forgives_one_ending_hit()
	_test_cushion_scales_with_the_tier()
	_test_boss_damage_applies_only_to_bosses()
	_test_coin_and_knowledge_bonuses_lift_what_a_run_pays()
	_test_wave_death_resets_run_but_keeps_meta_progress()
	_test_run_gates_the_wave_clock()
	_test_retreat_ends_and_resets_run()
	_test_tier_records_milestones_and_unlocks()
	_test_modifier_pipeline_order()
	_test_deterministic_run_seed()
	_test_high_wave_values_remain_valid()
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
	_expect(ScientificNumber.from_float(1000).format_value() == "1,000", "numbers under a million should stay as full digits")
	_expect(ScientificNumber.from_float(999999).format_value() == "999,999", "full digits should extend to just under a million")
	_expect(ScientificNumber.from_float(1500000).format_value() == "1.5M", "abbreviation should start at a million")
	_expect(ScientificNumber.new(4.72, 36).format_value() == "4.72e36", "large numbers should use scientific notation")
	var sum := ScientificNumber.new(9.0, 5).add(ScientificNumber.new(2.0, 5))
	_expect(sum.compare_to(ScientificNumber.new(1.1, 6)) == 0, "addition should normalize")
	_expect(ScientificNumber.from_float(5).subtract(ScientificNumber.from_float(9)).is_zero(), "subtraction cannot go negative")

## The retired bays gated every row at the same Workshop level the row already
## required, so dropping them must not change when anything opens.
func _test_category_gates_and_rank_caps() -> void:
	var state := _funded_state()
	for definition in state.definitions:
		if definition.category == ProgressionTaxonomy.WORKSHOP:
			_expect(ProgressionTaxonomy.WORKSHOP_CATEGORIES.has(definition.workshop_category), "every Workshop row needs one of the four categories: " + definition.id)
	_expect(state.is_unlocked(state.get_definition("stronger_tap")), "Tap Damage should be available at Workshop level zero")
	_expect(state.is_unlocked(state.get_definition(GameState.ARMOR_ID)), "Armor should be available from the start, as Shield Matrix was")
	_expect(not state.is_unlocked(state.get_definition("faster_cadence")), "Tick Speed should wait for its Workshop level")
	_expect(state.purchase("stronger_tap"), "Tap Damage rank one should purchase")
	_expect(state.purchase_ranks("stronger_tap", 11) == 11, "eleven more Tap Damage ranks should purchase")
	_expect(state.is_unlocked(state.get_definition("faster_cadence")), "Tick Speed should open at Workshop level 12")
	_expect(not state.is_unlocked(state.get_definition("more_critical")), "Crit Chance should still be shut at Workshop level 12")
	state.purchased.stronger_tap = 30
	_expect(state.is_unlocked(state.get_definition("more_critical")), "Crit Chance should open at Workshop level 30")
	state.purchased.stronger_tap = 60
	_expect(state.is_unlocked(state.get_definition("smarter_efficiency")), "Discount should open at Workshop level 60")
	state.purchased.stronger_tap = 100
	_expect(not state.can_purchase("stronger_tap"), "the rank cap should prevent a 101st Tap Damage")
	var level_before := state.get_workshop_level()
	state.purchased[GameState.ARMOR_ID] = 2
	_expect(state.get_workshop_level() == level_before + 2, "Armor is a Workshop rank now, so it should count toward the Workshop level")
	_expect(not state.has_category_content(ProgressionTaxonomy.ULTIMATE), "Ultimates should hold no rows until they are authored")

func _test_research_focus_targets_a_category() -> void:
	var state := _funded_state()
	state.purchased = {"stronger_tap": 100, "generator": 100, "generator_two": 60}
	_expect(state.get_workshop_level() >= GameState.RESEARCH_WORKSHOP_LEVEL, "this build should reach the Research Focus level")
	_expect(not state.select_focus("output"), "a retired bay id should no longer be selectable")
	_expect(not state.select_focus(ProgressionTaxonomy.ULTIMATE), "a category with no rows should not be selectable")
	var armor := state.get_definition(GameState.ARMOR_ID)
	var tap := state.get_definition("stronger_tap")
	var armor_before := state.get_workshop_coin_cost(armor)
	var tap_before := state.get_workshop_coin_cost(tap)
	_expect(state.select_focus(ProgressionTaxonomy.DEFENSE), "Defense should be selectable as a Research Focus")
	_expect(state.get_workshop_coin_cost(armor) < armor_before, "Research Focus should discount its own category")
	_expect(state.get_workshop_coin_cost(tap) == tap_before, "Research Focus should not discount another category")
	_expect(not state.select_focus(ProgressionTaxonomy.ATTACK), "Research Focus should lock in until Prestige")

## A multi-buy press must never be a discount or a surcharge: it is the same
## ranks at the same prices, charged in one go.
func _test_multi_buy_matches_buying_one_at_a_time() -> void:
	var one := _funded_state()
	one.coins = 100000
	var single_total := 0
	for rank in range(5):
		single_total += one.get_workshop_coin_cost(one.get_definition("stronger_tap"))
		_expect(one.purchase("stronger_tap"), "each single Tap Damage rank should purchase")
	var bulk := _funded_state()
	bulk.coins = 100000
	var plan := bulk.plan_purchase("stronger_tap", 5)
	_expect(int(plan.ranks) == 5 and int(plan.cost) == single_total, "a five-rank press should quote exactly what five single presses cost")
	_expect(bulk.purchase_ranks("stronger_tap", 5) == 5, "a five-rank press should land five ranks")
	_expect(bulk.coins == one.coins and bulk.get_owned("stronger_tap") == 5, "bulk and single buying should end in the same place")
	var capped := _funded_state()
	capped.coins = 1000000
	var cap: int = capped.get_definition("stronger_tap").max_rank
	_expect(capped.purchase_ranks("stronger_tap", cap * 2) == cap, "a press larger than the rank cap should stop at the cap")
	_expect(capped.purchase_ranks("stronger_tap", GameState.MAX_BUY) == 0, "a maxed row should refuse a further press")

	# Derived rather than hardcoded, so the rule survives retuning: MAX takes
	# ranks while the next one still fits inside the balance.
	var short := _funded_state()
	short.coins = 50
	var tap := short.get_definition("stronger_tap")
	var affordable := 0
	var tally := 0
	while affordable < tap.max_rank and tally + short.get_workshop_coin_cost_at(tap, affordable) <= 50:
		tally += short.get_workshop_coin_cost_at(tap, affordable)
		affordable += 1
	_expect(affordable > 1 and affordable < tap.max_rank, "50 Coins should be a genuinely partial press on this ladder")
	var partial := short.plan_purchase("stronger_tap", GameState.MAX_BUY)
	_expect(int(partial.ranks) == affordable and int(partial.cost) == tally, "MAX should buy exactly the ranks the player can afford")
	_expect(short.purchase_ranks("stronger_tap", GameState.MAX_BUY) == affordable and short.coins == 50 - tally, "a partial press should spend only what it quoted")

	var locked := _funded_state()
	_expect(int(locked.plan_purchase("faster_cadence", 5).ranks) == 0, "a row below its Workshop level should quote nothing")
	var running := _funded_state()
	running.start_run(1, 3)
	_expect(int(running.plan_purchase("stronger_tap", 5).ranks) == 0, "a run should refuse a Workshop press of any size")

## The card face is derived from the row's own effect, so it cannot drift from
## what the rank actually does.
func _test_stat_values_read_the_row_effect() -> void:
	var state := _funded_state()
	var tap := state.get_definition("stronger_tap")
	_expect(is_equal_approx(float(state.stat_display(tap, 0).value), 1.0), "Tap Damage at rank zero should read as the base tap")
	var tap_at_cap: Dictionary = state.stat_display(tap, tap.max_rank)
	_expect(is_equal_approx(float(tap_at_cap.value), 6.0) and str(tap_at_cap.unit) == "flat", "Tap Damage should still reach six at its cap, one rank at a time")
	state.purchased = {"stronger_tap": tap.max_rank}
	_expect(is_equal_approx(float(state.stat_display(tap, tap.max_rank).value), state._tap_base()), "the card value should equal what the rank actually grants")

	var multiplier := state.get_definition("generator_two")
	var at_cap: Dictionary = state.stat_display(multiplier, multiplier.max_rank)
	_expect(str(at_cap.unit) == "multiplier" and is_equal_approx(float(at_cap.value), pow(1.15, 3)), "Damage Multiplier should still compound to its old cap")
	state.purchased = {"generator_two": multiplier.max_rank}
	_expect(is_equal_approx(float(state.stat_display(multiplier, multiplier.max_rank).value), state._base_output_multiplier()), "the compounding card value should equal the applied multiplier")

	var armor_def := state.get_definition(GameState.ARMOR_ID)
	var armor: Dictionary = state.stat_display(armor_def, armor_def.max_rank)
	_expect(str(armor.unit) == "percent" and is_equal_approx(float(armor.value), 0.4), "Armor should read as 40% at its rank cap")
	_expect(is_equal_approx(float(state.stat_display(tap, 1).value), 1.05), "one rank should move the card face, not round away")
	var burst: Dictionary = state.stat_display(state.get_definition("burst_relay"), 2)
	_expect(str(burst.unit) == "rank" and is_equal_approx(float(burst.value), 2.0), "a row with no declared effect should fall back to its rank")

## D019 deepened every ladder without moving where it ends. These are the
## values the three-to-ten-rank ladders reached; a rank count that no longer
## lands on them is a retune, not a deepening.
func _test_deepened_ladders_keep_their_old_maxima() -> void:
	var state := _funded_state()
	state.purchased = {
		"stronger_tap": 100, "generator": 100, "generator_two": 60, "faster_cadence": 100,
		"faster_echo": 60, "burst_relay": 6, "more_critical": 100, "magnitude_coil": 60,
		"chain_reaction": 60, "automation_core": 50, "boss_damage": 100,
		"tax_resistance": 100, "siphon": 100, "recoil": 100, "priority_buffer": 50,
		"brace_discount": 60, "second_wind": 50,
		"smarter_efficiency": 60, "coin_bonus": 100, "knowledge_bonus": 50,
	}
	for definition in state.definitions:
		if definition.category == ProgressionTaxonomy.WORKSHOP:
			_expect(state.get_owned(definition.id) == definition.max_rank, "this build should sit at every cap: " + definition.id)
	_expect(is_equal_approx(state._tap_base(), 6.0), "Tap Damage should still cap at six")
	_expect(is_equal_approx(state._passive_base(), 12.5), "Damage per Second plus Auto Crank should still cap at 12.5")
	_expect(is_equal_approx(state._base_output_multiplier(), pow(1.15, 3)), "Damage Multiplier should still cap where three ranks of 1.15 did")
	_expect(is_equal_approx(state._tick_rate(), pow(1.20, 5)), "Tick Speed should still cap where five ranks of 1.20 did")
	_expect(is_equal_approx(state._critical_chance(), 0.25), "Crit Chance should still cap at 25%")
	_expect(is_equal_approx(state._critical_multiplier(), 5.0), "Crit Damage should still cap at 5x")
	_expect(is_equal_approx(state._chain_reaction_step(), 0.3), "Crit Chain should still cap at 30% per link")
	_expect(is_equal_approx(state._effect_sum("double_tick_chance"), 0.24), "Double Tick should still cap at 24%")
	_expect(is_equal_approx(state._effect_sum("cost_discount"), 0.15), "Discount should still cap at 15%")
	_expect(is_equal_approx(state._effect_sum("collection_resistance"), 0.4), "Armor should still cap at 40%")
	_expect(is_equal_approx(state._effect_sum("starting_number_flat"), 500.0), "Cushion should still cap at 500 Number")
	_expect(state._burst_interval() == 6, "Burst should still bottom out at every sixth tick")
	_expect(is_equal_approx(state._effect_sum("siphon_share"), 0.25), "Siphon should cap at a quarter of the damage dealt")
	_expect(is_equal_approx(state._effect_sum("recoil_share"), 0.5), "Recoil should cap at half of every hit")
	_expect(is_equal_approx(state.get_brace_cost_percent(), GameState.BRACE_COST_FLOOR), "Brace Cost should cap at its floor")
	_expect(is_equal_approx(state._effect_sum("second_wind_share"), 0.25), "Second Wind should cap at a quarter of the run's peak")
	_expect(is_equal_approx(state._effect_sum("boss_damage"), 1.0), "Boss Damage should cap at double damage against bosses")
	_expect(is_equal_approx(state._effect_sum("coin_bonus"), 0.5), "Coin Bonus should cap at half again")
	_expect(is_equal_approx(state._effect_sum("knowledge_bonus"), 0.5), "Knowledge Bonus should cap at half again")

func _test_workshop_effects() -> void:
	var state := _funded_state()
	# The same fractions of each ladder the three-rank build used to hold.
	state.purchased = {"stronger_tap": 40, "generator": 40, "generator_two": 20, "faster_cadence": 20, "faster_echo": 20, "more_critical": 20, "magnitude_coil": 20, "smarter_efficiency": 20}
	state.rng.seed = 11
	state.start_run(1, 11)
	var event := state.tap()
	_expect(event.amount.compare_to(ScientificNumber.from_float(3.45)) == 0, "Tap Damage and Damage Multiplier should affect taps")
	_expect(state.get_rate_per_second().compare_to(ScientificNumber.from_float(4.14)) == 0, "Workshop output and speed should affect rate")
	_expect(is_equal_approx(state._effect_sum("cost_discount"), 0.05), "twenty Discount ranks should still be a 5% discount")
	_expect(state.get_workshop_coin_cost(state.get_definition("generator")) == 16, "Discount should reduce permanent Coin costs")
	_expect(is_equal_approx(state._critical_chance(), 0.05), "Crit Chance should add positive critical chance")
	_expect(is_equal_approx(state._critical_multiplier(), 3.0), "Crit Damage should add critical size")

func _test_burst_and_positive_chance() -> void:
	var state := _funded_state()
	state.purchased = {"generator": 20, "faster_cadence": 20, "burst_relay": 1}
	state.start_run(1, 999)
	state.rng.seed = 999
	# Rank one shortens the interval from twelve to eleven, so the eleventh tick
	# is the one that doubles. Measured against its neighbour rather than a
	# fixed total, so the assertion outlives the next tuning pass.
	var plain := ScientificNumber.new()
	var burst := ScientificNumber.new()
	for tick in range(11):
		var before: ScientificNumber = state.number.copy()
		state._produce_tick()
		var gained := state.number.subtract(before)
		if tick == 9:
			plain = gained
		elif tick == 10:
			burst = gained
	_expect(not plain.is_zero() and burst.compare_to(plain.multiply_scalar(2.0)) == 0, "Burst rank one should double exactly the eleventh tick")
	_expect(state.statistics.critical_ticks == 0, "Chance cards must not create forced critical events")
	var chain := _funded_state()
	chain.purchased = {"generator": 20, "more_critical": 100, "chain_reaction": 60}
	chain.start_run(1, 3)
	chain.rng.seed = 3
	chain._produce_tick()
	_expect(chain.number.compare_to(ScientificNumber.new()) > 0, "Chance must always retain positive production")

func _test_permanent_baseline_and_starting_reserve() -> void:
	var state := _funded_state()
	state.purchased = {"stronger_tap": 100, "generator": 60, "automation_core": 50, "priority_buffer": 50}
	_expect(state.start_run(1, 44), "a fresh run should start from the permanent Workshop")
	_expect(state.number.compare_to(ScientificNumber.from_float(500)) == 0, "Cushion should define the fresh-run Number baseline")
	_expect(state.get_rate_per_second().compare_to(ScientificNumber.from_float(9.5)) == 0, "Auto Crank should permanently raise run production")
	_expect(not state.purchase("faster_cadence"), "permanent Workshop purchases must be locked during a run")
	state.end_run()
	_expect(state.get_owned("priority_buffer") == 50 and state.get_owned("automation_core") == 50, "Workshop ranks must survive retreat")

func _test_save_v5_and_legacy_migration() -> void:
	var save_path := "res://.number_go_up_test_save.json"
	var original: GameState = _funded_state()
	original.save_path = save_path
	original.purchased = {"stronger_tap": 2, "generator": 1}
	original.workshop.automation_targets = ["generator"]
	original.tier_records["1"].highest_wave = GameState.TIER_UNLOCK_WAVE
	_expect(original.start_run(2, 77), "an unlocked Tier 2 run should start")
	original.workshop.tick_count = 7
	original.tap()
	var saved_remaining: ScientificNumber = original.active_encounter.remaining_liability.copy()
	var saved_rng_state := original.rng.state
	_expect(original.save(), "V4 save should write")
	var restored := GameState.new()
	restored.save_path = save_path
	restored.load()
	_expect(restored.get_owned("stronger_tap") == 2 and restored.workshop.tick_count == 7, "V5 permanent Workshop state should round-trip")
	_expect(restored.workshop.selected_category == original.workshop.selected_category, "V5 should round-trip the open Workshop category")
	_expect(restored.in_run and restored.selected_tier == 2, "V5 should restore the active tier run")
	_expect(restored.active_encounter.remaining_liability.compare_to(saved_remaining) == 0, "V5 should restore exact encounter liability")
	_expect(restored.run_seed == 77 and restored.rng.state == saved_rng_state, "V5 should restore deterministic run RNG state")
	_expect(restored.run_peak_number.compare_to(original.run_peak_number) == 0 and restored.second_wind_used == original.second_wind_used, "V5 should restore the run's peak and whether Second Wind is spent")
	restored.clear_save()

	# A real V4 save: built from a live state, then reshaped exactly as V4 stored
	# it, with bays and the Armor rank in a field of its own.
	var v4_source := _funded_state()
	v4_source.purchased = {"stronger_tap": 2, "generator": 1, "tax_resistance": 3}
	v4_source.knowledge = 4
	v4_source.tier_records["1"].highest_wave = GameState.TIER_UNLOCK_WAVE
	_expect(v4_source.start_run(2, 55), "the V4 fixture should start a Tier 2 run")
	v4_source.tap()
	var v4_remaining: ScientificNumber = v4_source.active_encounter.remaining_liability.copy()
	var v4_rng_state := v4_source.rng.state
	var v4: Dictionary = SaveDataV5.make(v4_source)
	v4.version = 4
	v4.purchased = {"stronger_tap": 2, "generator": 1}
	v4.tax_resistance_rank = 3
	v4.focus = "speed"
	v4.workshop = {"selected_bay": "logic", "tick_count": 2, "automation_targets": [], "legacy_credit": 0}
	_write_json(save_path, v4)
	var migrated_v4 := GameState.new()
	migrated_v4.save_path = save_path
	migrated_v4.load()
	_expect(migrated_v4.get_owned(GameState.ARMOR_ID) == 3, "a V4 Shield Matrix rank should become the Armor Workshop rank")
	_expect(migrated_v4.get_owned("stronger_tap") == 2 and migrated_v4.get_owned("generator") == 1, "V4 Workshop ranks should migrate without loss")
	_expect(migrated_v4.coins == v4_source.coins and migrated_v4.knowledge == 4, "V4 permanent currencies should migrate")
	_expect(migrated_v4.get_tier_best(1) == GameState.TIER_UNLOCK_WAVE, "V4 tier records should migrate")
	_expect(migrated_v4.focus_path == ProgressionTaxonomy.ATTACK, "a V4 Speed focus should land on Attack")
	_expect(migrated_v4.workshop.selected_category == ProgressionTaxonomy.UTILITY, "a V4 Logic tab should land on Utility")
	_expect(migrated_v4.workshop.tick_count == 2, "V4 Workshop state beside the bay should survive")
	_expect(migrated_v4.in_run and migrated_v4.selected_tier == 2, "a V4 live run should survive migration")
	_expect(migrated_v4.active_encounter.remaining_liability.compare_to(v4_remaining) == 0, "a migrated V4 run should keep its exact remaining Liability")
	_expect(migrated_v4.rng.state == v4_rng_state, "a migrated V4 run should keep its RNG state")
	var rewritten := GameState.new()
	rewritten.save_path = save_path
	rewritten.load()
	_expect(rewritten.get_owned(GameState.ARMOR_ID) == 3 and rewritten.focus_path == ProgressionTaxonomy.ATTACK, "migration should rewrite the save in V5 shape immediately")
	rewritten.clear_save()

	var v3 := {
		"version": 3,
		"number": ScientificNumber.from_float(500).to_dict(),
		"lifetime": ScientificNumber.from_float(1000).to_dict(),
		"highest": ScientificNumber.from_float(1000).to_dict(),
		"purchased": {"stronger_tap": 2},
		"workshop": {"selected_bay": "chance"},
		"focus": "output",
		"tax_resistance_rank": 4,
		"coins": 25,
		"tier_records": {},
		"in_run": false,
		"statistics": {},
		"settings": {},
	}
	_write_json(save_path, v3)
	var migrated_v3 := GameState.new()
	migrated_v3.save_path = save_path
	migrated_v3.load()
	_expect(migrated_v3.number.is_zero(), "V3 banked Number should retire when migrating to run-only Number")
	_expect(migrated_v3.get_owned("stronger_tap") == 2 and migrated_v3.coins == 25, "V3 Workshop ranks and Coins should become permanent without loss")
	_expect(migrated_v3.get_owned(GameState.ARMOR_ID) == 4, "a V3 Shield Matrix rank should become the Armor Workshop rank")
	_expect(migrated_v3.focus_path == ProgressionTaxonomy.ATTACK and migrated_v3.workshop.selected_category == ProgressionTaxonomy.ATTACK, "V3 bays should map onto categories")
	migrated_v3.clear_save()

	var v2 := {
		"version": 2,
		"number": ScientificNumber.from_float(500).to_dict(),
		"lifetime": ScientificNumber.from_float(1000).to_dict(),
		"highest": ScientificNumber.from_float(500).to_dict(),
		"purchased": {"stronger_tap": 1},
		"workshop": {},
		"wave": 25,
		"highest_wave": 33,
		"in_run": false,
		"statistics": {},
		"settings": {},
		"last_seen_unix": Time.get_unix_time_from_system(),
	}
	_write_json(save_path, v2)
	var migrated_v2 := GameState.new()
	migrated_v2.save_path = save_path
	migrated_v2.load()
	_expect(migrated_v2.number.is_zero(), "V2 banked Number should retire under the run-only Number model")
	_expect(migrated_v2.get_tier_best(1) == 33, "V2 highest wave should become the Tier 1 record")
	_expect(not migrated_v2.in_run and migrated_v2.wave == 1, "a banked V2 run should become a fresh, non-exploitable run")
	migrated_v2.clear_save()

	# Malformed and unknown-version saves must not crash or half-load: the load
	# returns an empty award and the state stays the fresh default.
	for broken in [{"version": 99, "number": ScientificNumber.from_float(5).to_dict(), "lifetime": ScientificNumber.from_float(5).to_dict()}, {"version": 5}, {}]:
		_write_json(save_path, broken)
		var refused := GameState.new()
		refused.save_path = save_path
		refused.load()
		_expect(refused.number.is_zero() and refused.coins == 0 and not refused.in_run, "an unreadable save should leave a fresh state, not a partial one")
		refused.clear_save()
	var v1 := {
		"version": 1,
		"number": ScientificNumber.from_float(100).to_dict(),
		"lifetime": ScientificNumber.from_float(1000).to_dict(),
		"highest": ScientificNumber.from_float(100).to_dict(),
		"purchased": {"stronger_tap": 1, "steady_hand": 1, "workshop_bench": 2, "prototype_oddity": 4},
		"auto_selected": "generator",
		"statistics": {},
		"settings": {},
		"last_seen_unix": Time.get_unix_time_from_system(),
	}
	_write_json(save_path, v1)
	var migrated_v1 := GameState.new()
	migrated_v1.save_path = save_path
	migrated_v1.load()
	_expect(migrated_v1.get_owned("stronger_tap") == 2, "V1 hand upgrades should migrate into Hand Press")
	_expect(migrated_v1.workshop.legacy_credit == 6, "unmatched V1 progress should become Workshop credit")
	_expect(migrated_v1.workshop.automation_targets == ["generator"], "V1 automation should become first priority")
	migrated_v1.clear_save()

func _test_offline_policy() -> void:
	var outside := GameState.new()
	outside.purchased.generator = 1
	var award := outside.apply_offline(GameState.OFFLINE_CAP_SECONDS + 3600.0)
	_expect(award.amount.is_zero(), "the between-run Workshop must not generate run Number offline")
	var hub_tap := outside.tap()
	_expect(hub_tap.amount.is_zero() and outside.number.is_zero(), "tapping outside a run must not bank a head start")
	var active := GameState.new()
	active.purchased.generator = 1
	active.start_run(1, 1)
	active.number = ScientificNumber.from_float(100)
	var before := active.number.copy()
	var frozen := active.apply_offline(3600.0)
	_expect(frozen.amount.is_zero(), "an active run must not receive risk-free offline production")
	_expect(active.number.compare_to(before) == 0, "an active run should resume from the exact frozen Number")

func _test_prestige_reset_and_gain() -> void:
	var state := GameState.new()
	state.number = ScientificNumber.from_float(1)
	state.lifetime_generated = ScientificNumber.from_float(1000000000.0)
	state.purchased = {"stronger_tap": 2, "generator": 1}
	state.workshop.tick_count = 5
	var expected_gain := state.get_prestige_knowledge_gain()
	_expect(expected_gain > 0, "progress far past the threshold should grant Knowledge")
	var gain := state.prestige()
	_expect(gain == expected_gain and state.knowledge == gain, "Prestige should bank the expected Knowledge")
	_expect(state.number.is_zero() and state.get_owned("stronger_tap") == 2, "Prestige should reset run Number but retain permanent Workshop ranks")
	_expect(state.purchase_insight(), "Knowledge should buy Insight")
	_expect(state.get_owned("insight") == 1, "Insight should survive reset")

func _test_first_run_funds_permanent_workshop() -> void:
	var state := GameState.new()
	_expect(state.start_run(1, 7), "the first run should start without prior Workshop ranks")
	for completed_wave in range(1, 21):
		state.active_encounter.remaining_liability = ScientificNumber.new()
		state._resolve_wave_boundary()
	_expect(state.coins == 48, "Tier 1 grace should award 48 repeatable Coins through wave 20")
	state.end_run()
	_expect(state.purchase("stronger_tap"), "first-run Coins should buy a permanent Tap Damage rank")
	_expect(state.purchase("generator"), "first-run Coins should also buy the first Damage Per Second rank")
	_expect(state.coins == 41, "first Workshop purchases should spend Coins, not Number")
	# A deepened ladder (D019) should turn the first run into a visible stack of
	# ranks rather than the two the five-rank ladders allowed.
	_expect(state.purchase_ranks("stronger_tap", GameState.MAX_BUY) >= 8, "the first failed run should fund a stack of ranks")
	state.start_run(1, 8)
	_expect(state._tap_base() > 1.0 and state._passive_base() > 0.0, "the next run should start from the upgraded permanent baseline")

func _test_tier_pressure_and_curve_gates() -> void:
	var state := GameState.new()
	var profile = state.balance_profile
	_expect(profile.liability_for_wave(1, 1).is_zero(), "Tier 1 should retain its 20-wave grace")
	_expect(profile.collection_for_wave(1, 20).is_zero(), "Tier 1 wave 20 should still be free")
	_expect(not profile.liability_for_wave(1, 21).is_zero(), "Tier 1 pressure should begin at wave 21")
	var tier1_liability := profile.liability_for_wave(1, 21)
	var tier2_liability := profile.liability_for_wave(2, 21)
	var tier1_collection := profile.collection_for_wave(1, 21)
	var tier2_collection := profile.collection_for_wave(2, 21)
	var tier3_liability := profile.liability_for_wave(3, 21)
	var tier3_collection := profile.collection_for_wave(3, 21)
	_expect(tier2_liability.compare_to(tier1_liability.multiply_scalar(20.0)) == 0, "Tier 2 liability must be exactly 20x Tier 1")
	_expect(tier2_collection.compare_to(tier1_collection.multiply_scalar(20.0)) == 0, "Tier 2 collection must be exactly 20x Tier 1")
	_expect(tier3_liability.compare_to(tier1_liability.multiply_scalar(60.0)) == 0, "Tier 3 liability must be exactly 60x Tier 1")
	_expect(tier3_collection.compare_to(tier1_collection.multiply_scalar(60.0)) == 0, "Tier 3 collection must be exactly 60x Tier 1")
	_expect(not profile.liability_for_wave(2, 1).is_zero(), "Tier 2 should apply pressure from wave one")
	_expect(is_equal_approx(profile.get_tier(2).reward_multiplier, 1.8), "Tier 2 reward multiplier should be 1.8x")
	_expect(profile.reward_for_wave(2, 100) == roundi(float(profile.reward_for_wave(1, 100)) * 1.8), "Tier 2 rewards should keep the 1.8x ratio at equal pressured waves")

func _test_production_clears_liability() -> void:
	var state := GameState.new()
	state.tier_records["1"].highest_wave = GameState.TIER_UNLOCK_WAVE
	state.number = ScientificNumber.from_float(10000)
	_expect(state.start_run(2, 9), "Tier 2 run should start after unlock")
	var before: ScientificNumber = state.active_encounter.remaining_liability.copy()
	var tap := state.tap()
	_expect(state.active_encounter.remaining_liability.compare_to(before.subtract(tap.amount)) == 0, "every produced unit should deal equal compliance damage")
	state.active_encounter.apply_compliance(ScientificNumber.new(9.9, 300))
	_expect(state.active_encounter.is_cleared(), "sufficient compliance should clear Liability without making it negative")
	var event := state._resolve_wave_boundary()
	_expect(event.type == "wave_clear" and state.wave == 2, "a cleared Liability should advance at the boundary")

func _test_output_beats_the_wave_before_it_becomes_number() -> void:
	var state := GameState.new()
	state.tier_records["1"].highest_wave = GameState.TIER_UNLOCK_WAVE
	_expect(state.start_run(2, 21), "Tier 2 run should start after unlock")
	state.number = ScientificNumber.from_float(1000)
	state.active_encounter.remaining_liability = ScientificNumber.from_float(50)
	var lifetime_before: ScientificNumber = state.lifetime_generated.copy()

	state._add_number(ScientificNumber.from_float(30))
	_expect(state.number.compare_to(ScientificNumber.from_float(1000)) == 0, "output below remaining Liability should not raise Number")
	_expect(state.active_encounter.remaining_liability.compare_to(ScientificNumber.from_float(20)) == 0, "output should damage the wave one-for-one")

	state._add_number(ScientificNumber.from_float(20))
	_expect(state.active_encounter.is_cleared(), "output exactly equal to remaining Liability should beat the wave")
	_expect(state.number.compare_to(ScientificNumber.from_float(1000)) == 0, "an exact clear should bank nothing")

	state._add_number(ScientificNumber.from_float(45))
	_expect(state.number.compare_to(ScientificNumber.from_float(1045)) == 0, "output after the wave is beaten should all become Number")
	_expect(state.lifetime_generated.compare_to(lifetime_before.add(ScientificNumber.from_float(95))) == 0, "lifetime production should count all output, including damage dealt")

	state.active_encounter.remaining_liability = ScientificNumber.from_float(50)
	state._add_number(ScientificNumber.from_float(80))
	_expect(state.active_encounter.is_cleared() and state.number.compare_to(ScientificNumber.from_float(1075)) == 0, "one output past remaining Liability should bank only the overflow")

	state.active_encounter.remaining_liability = ScientificNumber.from_float(50)
	var zero_lifetime: ScientificNumber = state.lifetime_generated.copy()
	state._add_number(ScientificNumber.new())
	_expect(state.number.compare_to(ScientificNumber.from_float(1075)) == 0 and state.active_encounter.remaining_liability.compare_to(ScientificNumber.from_float(50)) == 0, "zero output should change nothing")
	_expect(state.lifetime_generated.compare_to(zero_lifetime) == 0, "zero output should not count as production")

	state.number = ScientificNumber.new()
	state.active_encounter.remaining_liability = ScientificNumber.new(5.0, 300)
	state._add_number(ScientificNumber.new(7.0, 300))
	_expect(state.active_encounter.is_cleared() and state.number.compare_to(ScientificNumber.new(2.0, 300)) == 0, "overflow should stay exact at very large values")

	var warm_up := GameState.new()
	warm_up.start_run(1, 22)
	warm_up._add_number(ScientificNumber.from_float(5))
	_expect(warm_up.number.compare_to(ScientificNumber.from_float(5)) == 0, "warm-up waves have no Liability, so all output should bank")

	var outside := GameState.new()
	outside.tap()
	_expect(outside.number.is_zero() and outside.lifetime_generated.is_zero(), "tapping outside a run should grant nothing")

func _test_repeated_taps_count_once() -> void:
	var state := GameState.new()
	state.tier_records["1"].highest_wave = GameState.TIER_UNLOCK_WAVE
	state.start_run(2, 23)
	state.active_encounter.remaining_liability = ScientificNumber.from_float(30)
	var lifetime_before: ScientificNumber = state.lifetime_generated.copy()
	for tap_index in range(50):
		state.tap()
	_expect(state.active_encounter.is_cleared(), "fifty one-unit taps should beat a 30-HP wave")
	_expect(state.number.compare_to(ScientificNumber.from_float(20)) == 0, "only the 20 units past the wave's HP should bank")
	_expect(state.lifetime_generated.compare_to(lifetime_before.add(ScientificNumber.from_float(50))) == 0, "every tap should count once toward lifetime production")

func _test_stuck_wave_keeps_its_damage_and_hits_again() -> void:
	var state := GameState.new()
	state.tier_records["1"].highest_wave = GameState.TIER_UNLOCK_WAVE
	state.start_run(2, 24)
	state.number = ScientificNumber.from_float(10000)
	state.active_encounter.remaining_liability = ScientificNumber.from_float(100)
	state._add_number(ScientificNumber.from_float(40))
	var hit := state.get_effective_collection()
	var event := state._resolve_wave_boundary()
	_expect(event.type == "tax_collection" and state.wave == 1, "a wave still standing at its boundary should hit and stay")
	_expect(state.number.compare_to(ScientificNumber.from_float(10000).subtract(hit)) == 0, "the hit should come out of Number")
	_expect(state.active_encounter.remaining_liability.compare_to(ScientificNumber.from_float(60)) == 0, "a surviving wave should keep the damage already dealt")
	state._add_number(ScientificNumber.from_float(60))
	event = state._resolve_wave_boundary()
	_expect(event.type == "wave_clear" and state.wave == 2, "finishing a stuck wave should advance at the next boundary")

func _test_mid_wave_save_resumes_identically() -> void:
	var save_path := "res://.number_go_up_test_save.json"
	var original := GameState.new()
	original.save_path = save_path
	original.purchased = {"stronger_tap": 60, "more_critical": 100}
	original.tier_records["1"].highest_wave = GameState.TIER_UNLOCK_WAVE
	original.start_run(2, 31)
	for tap_index in range(5):
		original.tap()
	_expect(not original.active_encounter.is_cleared(), "the save should be taken mid-wave")
	_expect(original.save(), "mid-wave save should write")
	var restored := GameState.new()
	restored.save_path = save_path
	restored.load()
	for tap_index in range(80):
		original.tap()
		restored.tap()
	_expect(original.active_encounter.is_cleared(), "continued tapping should carry the wave past its clear point")
	_expect(restored.number.compare_to(original.number) == 0, "a restored run should bank the same overflow as the original")
	_expect(restored.active_encounter.remaining_liability.compare_to(original.active_encounter.remaining_liability) == 0, "a restored run should deal the same damage as the original")
	_expect(restored.lifetime_generated.compare_to(original.lifetime_generated) == 0 and restored.rng.state == original.rng.state, "a restored run should stay deterministic")
	restored.clear_save()

func _test_collection_is_absolute() -> void:
	var small := GameState.new()
	small.tier_records["1"].highest_wave = GameState.TIER_UNLOCK_WAVE
	small.start_run(2, 4)
	small.number = ScientificNumber.from_float(5000)
	var expected := small.get_effective_collection()
	var small_event := small._resolve_wave_boundary()
	var large := GameState.new()
	large.tier_records["1"].highest_wave = GameState.TIER_UNLOCK_WAVE
	large.start_run(2, 4)
	large.number = ScientificNumber.from_float(500000000)
	var large_event := large._resolve_wave_boundary()
	_expect(small_event.type == "tax_collection" and large_event.type == "tax_collection", "uncleared encounters should collect")
	_expect(small_event.amount.compare_to(expected) == 0 and large_event.amount.compare_to(expected) == 0, "Collection must be the same absolute value at every player Number")

func _test_boss_axes_and_rewards() -> void:
	var profile = GameState.new().balance_profile
	var normal_liability := profile.liability_for_wave(2, 29)
	var boss_liability := profile.liability_for_wave(2, 30)
	var normal_collection := profile.collection_for_wave(2, 29)
	var boss_collection := profile.collection_for_wave(2, 30)
	_expect(boss_liability.compare_to(normal_liability) > 0, "boss liability should exceed the preceding normal wave")
	_expect(boss_collection.compare_to(normal_collection) > 0, "boss collection should exceed the preceding normal wave")
	_expect(profile.reward_for_wave(2, 30) > profile.reward_for_wave(2, 29), "boss waves should grant a larger independent reward")

func _test_brace_blocks_next_collection() -> void:
	var state := GameState.new()
	state.tier_records["1"].highest_wave = GameState.TIER_UNLOCK_WAVE
	state.start_run(2, 5)
	state.number = ScientificNumber.from_float(10000)
	_expect(state.can_brace() and state.brace(), "Brace should be available against active Liability")
	_expect(state.number.compare_to(ScientificNumber.from_float(7000)) == 0, "Brace should cost 30% of current Number")
	var event := state._resolve_wave_boundary()
	_expect(event.type == "tax_collection" and event.amount.is_zero(), "Brace should block one Collection hit")
	_expect(state.number.compare_to(ScientificNumber.from_float(7000)) == 0 and not state.braced, "Brace should preserve Number and then be consumed")

func _test_armor_reduces_the_hit_and_survives_reset() -> void:
	var state := GameState.new()
	state.tier_records["1"].highest_wave = GameState.TIER_UNLOCK_WAVE
	state.coins = 1000
	var armor := state.get_definition(GameState.ARMOR_ID)
	var base_cost := state.get_workshop_coin_cost(armor)
	_expect(base_cost == 8, "the first Armor rank should cost the opening price of its ladder")
	_expect(state.purchase(GameState.ARMOR_ID), "Armor should be purchasable with enough Coins")
	state.start_run(2, 6)
	state.number = ScientificNumber.from_float(10000)
	var base_collection: ScientificNumber = state.active_encounter.collection.copy()
	_expect(state.get_effective_collection().compare_to(base_collection.multiply_scalar(0.996)) == 0, "one Armor rank should reduce the hit by 0.4%")
	_expect(not state.purchase(GameState.ARMOR_ID), "Armor is a Workshop rank, so it must be locked during a run")
	state._reset_run_state()
	_expect(state.coins == 1000 - base_cost and state.get_owned(GameState.ARMOR_ID) == 1, "Coins and Armor ranks must survive reset")
	state.purchased[GameState.ARMOR_ID] = armor.max_rank
	_expect(not state.can_purchase(GameState.ARMOR_ID), "Armor should stop at its rank cap")
	state.start_run(2, 6)
	var maxed_base: ScientificNumber = state.active_encounter.collection.copy()
	var maxed_hit := state.get_effective_collection()
	_expect(maxed_hit.compare_to(maxed_base.multiply_scalar(0.61)) < 0 and maxed_hit.compare_to(maxed_base.multiply_scalar(0.59)) > 0, "a maxed Armor should still take about 40% off the hit")
	_expect(not maxed_hit.is_zero(), "Armor must never remove the hit entirely")

## Siphon is the only route by which damage dealt to a wave also reaches Number.
## It must not reduce what the wave takes.
func _test_siphon_banks_a_share_of_damage_dealt() -> void:
	var plain := GameState.new()
	plain.tier_records["1"].highest_wave = GameState.TIER_UNLOCK_WAVE
	plain.start_run(2, 40)
	plain.number = ScientificNumber.from_float(1000)
	plain.active_encounter.remaining_liability = ScientificNumber.from_float(100)
	plain._add_number(ScientificNumber.from_float(40))
	_expect(plain.number.compare_to(ScientificNumber.from_float(1000)) == 0, "without Siphon, damage into a wave banks nothing")

	var state := GameState.new()
	state.tier_records["1"].highest_wave = GameState.TIER_UNLOCK_WAVE
	state.purchased = {"siphon": 100}
	_expect(state.start_run(2, 41), "Tier 2 run should start after unlock")
	state.number = ScientificNumber.from_float(1000)
	state.active_encounter.remaining_liability = ScientificNumber.from_float(100)
	state._add_number(ScientificNumber.from_float(40))
	_expect(state.active_encounter.remaining_liability.compare_to(ScientificNumber.from_float(60)) == 0, "Siphon must not reduce the damage the wave takes")
	_expect(state.number.compare_to(ScientificNumber.from_float(1010)) == 0, "a quarter of the 40 damage dealt should still reach Number")
	state._add_number(ScientificNumber.from_float(100))
	_expect(state.active_encounter.is_cleared(), "output past the remaining HP should beat the wave")
	_expect(state.number.compare_to(ScientificNumber.from_float(1065)) == 0, "40 of overflow plus a quarter of the 60 absorbed should bank")

func _test_recoil_deals_the_hit_back_to_the_wave() -> void:
	var state := GameState.new()
	state.tier_records["1"].highest_wave = GameState.TIER_UNLOCK_WAVE
	state.purchased = {"recoil": 100}
	state.start_run(2, 42)
	state.number = ScientificNumber.from_float(100000)
	state.active_encounter.remaining_liability = ScientificNumber.from_float(100000)
	var hit := state.get_effective_collection()
	var before: ScientificNumber = state.active_encounter.remaining_liability.copy()
	var event := state._resolve_wave_boundary()
	_expect(event.type == "tax_collection", "an uncleared wave should still hit")
	_expect(state.active_encounter.remaining_liability.compare_to(before.subtract(hit.multiply_scalar(0.5))) == 0, "half the hit should be dealt back to the wave")
	state.active_encounter.remaining_liability = ScientificNumber.from_float(100000)
	var braced_before: ScientificNumber = state.active_encounter.remaining_liability.copy()
	_expect(state.brace(), "Brace should be available against an active wave")
	state._resolve_wave_boundary()
	_expect(state.active_encounter.remaining_liability.compare_to(braced_before) == 0, "a braced boundary should deal no recoil, because no hit landed")

func _test_brace_cost_falls_to_its_floor() -> void:
	var state := GameState.new()
	state.tier_records["1"].highest_wave = GameState.TIER_UNLOCK_WAVE
	_expect(is_equal_approx(state.get_brace_cost_percent(), GameState.BRACE_COST_PERCENT), "Brace should cost 30% with no ranks")
	var row := state.get_definition("brace_discount")
	state.purchased = {"brace_discount": row.max_rank * 2}
	_expect(is_equal_approx(state.get_brace_cost_percent(), GameState.BRACE_COST_FLOOR), "Brace must never fall below its floor, whatever the rank")
	state.purchased = {"brace_discount": row.max_rank}
	state.start_run(2, 43)
	state.number = ScientificNumber.from_float(10000)
	_expect(state.brace(), "Brace should be available against an active wave")
	_expect(state.number.compare_to(ScientificNumber.from_float(8500)) == 0, "a maxed Brace Cost should spend 15%, not 30%")

func _test_second_wind_forgives_one_ending_hit() -> void:
	var bare := GameState.new()
	bare.tier_records["1"].highest_wave = GameState.TIER_UNLOCK_WAVE
	bare.start_run(2, 44)
	bare.number = ScientificNumber.from_float(10)
	_expect(bare._resolve_wave_boundary().type == "wave_death", "without the rank, an ending hit should still end the run")

	var state := GameState.new()
	state.tier_records["1"].highest_wave = GameState.TIER_UNLOCK_WAVE
	state.purchased = {"second_wind": 50}
	state.start_run(2, 45)
	state.active_encounter.remaining_liability = ScientificNumber.new()
	state._add_number(ScientificNumber.from_float(20000))
	_expect(state.run_peak_number.compare_to(ScientificNumber.from_float(20000)) == 0, "the run should track its own peak Number")
	state.active_encounter = state._make_encounter(1)
	state.number = ScientificNumber.from_float(10)
	var event := state._resolve_wave_boundary()
	_expect(event.type == "second_wind", "a hit that would end the run should trigger Second Wind instead")
	_expect(state.in_run and not state.number.is_zero(), "Second Wind should keep the run alive")
	_expect(state.number.compare_to(ScientificNumber.from_float(5000)) == 0, "Second Wind should leave a quarter of the run's peak")
	state.number = ScientificNumber.from_float(10)
	_expect(state._resolve_wave_boundary().type == "wave_death", "Second Wind should fire at most once per run")

	var fresh := GameState.new()
	fresh.tier_records["1"].highest_wave = GameState.TIER_UNLOCK_WAVE
	fresh.purchased = {"second_wind": 50}
	fresh.start_run(2, 46)
	_expect(not fresh.second_wind_used and fresh.run_peak_number.compare_to(ScientificNumber.new()) == 0, "a new run should start with Second Wind unspent and no peak")

## Cushion is priced in the tier's hits rather than in absolute Number, or it is
## a trap everywhere above Tier 1.
func _test_cushion_scales_with_the_tier() -> void:
	var state := GameState.new()
	state.tier_records["1"].highest_wave = GameState.TIER_UNLOCK_WAVE
	state.purchased = {"priority_buffer": 50}
	state.start_run(1, 47)
	_expect(state.number.compare_to(ScientificNumber.from_float(500)) == 0, "Cushion should be worth its face value on Tier 1")
	state.end_run()
	state.start_run(2, 47)
	var scale := state.get_cushion_scale(2)
	_expect(is_equal_approx(scale, 20.0), "Tier 2 should scale Cushion by its own pressure multiplier")
	_expect(state.number.compare_to(ScientificNumber.from_float(500.0 * scale)) == 0, "Cushion should be worth twenty times as much against Tier 2 hits")

## Boss Damage must be a boss-only multiplier: the same ranks on a normal wave
## change nothing, and the displayed rate must agree with what is dealt.
func _test_boss_damage_applies_only_to_bosses() -> void:
	var state := GameState.new()
	state.tier_records["1"].highest_wave = GameState.TIER_UNLOCK_WAVE
	state.purchased = {"stronger_tap": 100, "generator": 100, "boss_damage": 100}
	state.start_run(2, 50)
	state.wave = 9
	state.active_encounter = state._make_encounter(9)
	_expect(not state.active_encounter.is_boss, "wave nine should not be a boss")
	var plain := state.tap()
	state.wave = 10
	state.active_encounter = state._make_encounter(10)
	_expect(state.active_encounter.is_boss, "wave ten should be a boss")
	var against_boss := state.tap()
	_expect(against_boss.amount.compare_to(plain.amount.multiply_scalar(2.0)) == 0, "a maxed Boss Damage should double what a tap deals to a boss")
	var boss_rate := state.get_rate_per_second()
	state.active_encounter = state._make_encounter(9)
	_expect(boss_rate.compare_to(state.get_rate_per_second()) > 0, "the displayed rate should carry the boss bonus too, not just the damage")

	var bare := GameState.new()
	bare.tier_records["1"].highest_wave = GameState.TIER_UNLOCK_WAVE
	bare.purchased = {"stronger_tap": 100, "generator": 100}
	bare.start_run(2, 50)
	bare.active_encounter = bare._make_encounter(10)
	var unbuffed := bare.tap()
	_expect(unbuffed.amount.compare_to(plain.amount) == 0, "without the rank, a boss wave should take ordinary damage")

func _test_coin_and_knowledge_bonuses_lift_what_a_run_pays() -> void:
	var plain := GameState.new()
	plain.tier_records["1"].highest_wave = GameState.TIER_UNLOCK_WAVE
	plain.start_run(2, 51)
	for wave in range(1, 31):
		plain.active_encounter.remaining_liability = ScientificNumber.new()
		plain._resolve_wave_boundary()
	var base_coins := plain.coins
	_expect(base_coins > 0, "thirty pressured waves should pay something to compare against")

	var rich := GameState.new()
	rich.tier_records["1"].highest_wave = GameState.TIER_UNLOCK_WAVE
	rich.purchased = {"coin_bonus": 100}
	rich.start_run(2, 51)
	for wave in range(1, 31):
		rich.active_encounter.remaining_liability = ScientificNumber.new()
		rich._resolve_wave_boundary()
	_expect(rich.coins > base_coins, "Coin Bonus should lift what beaten waves pay")
	# Floored per wave, so the bonus lands just under the stated half again and
	# never over it. That direction is the contract.
	_expect(rich.coins <= int(float(base_coins) * 1.5), "Coin Bonus must never pay more than it states")
	_expect(rich.coins >= int(float(base_coins) * 1.45), "Coin Bonus should land within rounding of its stated half again")

	var grace := GameState.new()
	grace.purchased = {"coin_bonus": 100}
	grace.start_run(1, 52)
	grace.active_encounter.remaining_liability = ScientificNumber.new()
	grace._resolve_wave_boundary()
	_expect(grace.coins == 1, "a one-Coin grace wave cannot carry a percentage, and must not round up into two")

	var learner := GameState.new()
	learner.lifetime_generated = ScientificNumber.from_float(GameState.PRESTIGE_TEASER_UNLOCK * 1000000.0)
	var without := learner.get_prestige_knowledge_gain()
	learner.purchased = {"knowledge_bonus": 50}
	var with_bonus := learner.get_prestige_knowledge_gain()
	_expect(without > 0 and with_bonus > without, "Knowledge Bonus should lift what a run ending grants")
	_expect(with_bonus == int(floor(float(without) * 1.5)) or with_bonus == int(floor(float(without) * 1.5)) + 1, "a maxed Knowledge Bonus should grant about half again")

func _test_wave_death_resets_run_but_keeps_meta_progress() -> void:
	var state := GameState.new()
	state.tier_records["1"].highest_wave = GameState.TIER_UNLOCK_WAVE
	state.purchased = {"stronger_tap": 3, "tax_resistance": 2}
	state.coins = 42
	state.start_run(2, 7)
	state.number = ScientificNumber.from_float(1)
	state.lifetime_generated = ScientificNumber.from_float(GameState.PRESTIGE_TEASER_UNLOCK * 100.0)
	state.workshop.tick_count = 12
	state.run_coins_earned = 5
	var expected_knowledge := state.get_prestige_knowledge_gain()
	var killing_hit := state.get_effective_collection()
	var was_boss: bool = state.active_encounter.is_boss
	var event := state._resolve_wave_boundary()
	_expect(event.type == "wave_death", "Collection that depletes Number should report death")
	_expect(state.number.is_zero() and state.get_owned("stronger_tap") == 3, "death should reset run Number and retain permanent Workshop progress")
	_expect(not state.in_run and state.wave == 1, "death should end the run at the hub")
	_expect(state.knowledge == expected_knowledge and state.coins == 42, "death should retain permanent currencies")
	_expect(state.get_owned(GameState.ARMOR_ID) == 2, "Armor should survive death")
	_expect(state.last_run_summary != null and state.last_run_summary.tier_id == 2, "death should record the tier")
	_expect(state.last_run_summary.coins_earned == 5, "failed waves should not award unearned rewards")
	# The run-over screen names what the run was lost to, so the summary has to
	# carry it: _reset_run_state wipes the encounter before anything can read it.
	_expect(state.last_run_summary.final_hit.compare_to(killing_hit) == 0, "the summary should record the hit the run was lost to")
	_expect(state.last_run_summary.lost_to_boss == was_boss, "the summary should record whether a boss landed it")

	var boss_run := GameState.new()
	boss_run.tier_records["1"].highest_wave = GameState.TIER_UNLOCK_WAVE
	boss_run.start_run(2, 71)
	boss_run.wave = 10
	boss_run.active_encounter = boss_run._make_encounter(10)
	_expect(boss_run.active_encounter.is_boss, "wave ten should be a boss")
	boss_run.number = ScientificNumber.from_float(1)
	_expect(boss_run._resolve_wave_boundary().type == "wave_death", "a boss hit that empties Number should end the run")
	_expect(boss_run.last_run_summary.lost_to_boss, "a run lost to a boss should say so")
	_expect(not boss_run.last_run_summary.final_hit.is_zero(), "a boss hit should be recorded at its real size")

	var retreat := GameState.new()
	retreat.start_run(1, 72)
	var summary := retreat.end_run()
	_expect(summary.final_hit.is_zero() and not summary.lost_to_boss, "a retreat was lost to nothing, so it records no hit")

func _test_run_gates_the_wave_clock() -> void:
	var state := GameState.new()
	state.number = ScientificNumber.from_float(1000)
	_advance_seconds(state, 20.0)
	_expect(state.wave == 1, "wave clock must not advance outside an active run")
	_expect(state.start_run(1, 10), "starting a run should succeed")
	_expect(not state.start_run(1, 10), "starting while already active should fail")
	_advance_seconds(state, 20.0)
	_expect(state.wave == 2, "a cleared grace wave should advance after 15 seconds")

func _test_retreat_ends_and_resets_run() -> void:
	var state := GameState.new()
	state.purchased = {"stronger_tap": 2}
	state.coins = 7
	state.start_run(1, 11)
	state.number = ScientificNumber.from_float(1000)
	state.wave = 25
	var summary := state.end_run()
	_expect(summary != null and summary.outcome == "retreat", "end_run should record a retreat")
	_expect(not state.in_run and state.number.is_zero(), "retreat must end and reset rather than pause")
	_expect(state.wave == 1 and state.get_owned("stronger_tap") == 2, "retreat should create fresh run state while retaining the Workshop")
	_expect(state.coins == 7, "retreat must retain permanent Coins")

func _test_tier_records_milestones_and_unlocks() -> void:
	var state := GameState.new()
	state.number = ScientificNumber.new(9.9, 300)
	state.start_run(1, 12)
	var unlock_event: SimulationEvent = null
	for completed_wave in range(1, GameState.TIER_UNLOCK_WAVE + 1):
		state.active_encounter.remaining_liability = ScientificNumber.new()
		unlock_event = state._resolve_wave_boundary()
	_expect(state.get_tier_best(1) == GameState.TIER_UNLOCK_WAVE, "Tier 1 record should track the highest cleared wave")
	var claimed: Array = state.get_tier_record(1).milestones_claimed
	_expect(claimed == [10, 25, 50, 100], "milestones should be claimed once at authored checkpoints")
	_expect(state.is_tier_unlocked(2), "clearing Tier 1 wave 100 should unlock Tier 2")
	_expect(unlock_event != null and unlock_event.type == "tier_unlock", "the first wave-100 clear should announce the newly unlocked tier")
	_expect(not state.is_tier_unlocked(3), "Tier 3 should remain locked until Tier 2 wave 100")
	state.end_run()
	_expect(state.select_tier(2), "an unlocked tier should be selectable outside a run")

func _test_modifier_pipeline_order() -> void:
	var modifiers: Array = [
		{"target": "collection", "stage": "multiplicative", "value": 0.5},
		{"target": "collection", "stage": "flat", "amount": ScientificNumber.from_float(10).to_dict()},
		{"target": "collection", "stage": "additive", "value": 0.5},
		{"target": "collection", "stage": "cap_max", "amount": ScientificNumber.from_float(80).to_dict()},
	]
	var result := RuleModifierPipelineClass.apply(ScientificNumber.from_float(100), "collection", modifiers)
	_expect(result.compare_to(ScientificNumber.from_float(80)) == 0, "modifier order should be flat, additive, multiplicative, then caps")

func _test_deterministic_run_seed() -> void:
	var left := GameState.new()
	var right := GameState.new()
	left.purchased = {"more_critical": 100}
	right.purchased = {"more_critical": 100}
	left.start_run(1, 123456)
	right.start_run(1, 123456)
	for tap_index in range(20):
		var left_event := left.tap()
		var right_event := right.tap()
		_expect(left_event.is_critical == right_event.is_critical, "matching run seeds should reproduce critical outcomes")
		_expect(left_event.amount.compare_to(right_event.amount) == 0, "matching run seeds should reproduce produced amounts")
	_expect(left.rng.state == right.rng.state, "matching seeded runs should finish with identical RNG state")

func _test_high_wave_values_remain_valid() -> void:
	var profile = GameState.new().balance_profile
	for tier_id in [1, 2, 3]:
		var liability := profile.liability_for_wave(tier_id, 100000)
		var collection := profile.collection_for_wave(tier_id, 100000)
		_expect(not liability.is_zero() and liability.exponent > 0, "high-wave Liability should remain a valid ScientificNumber")
		_expect(not collection.is_zero() and collection.exponent > 0, "high-wave Collection should remain a valid ScientificNumber")

func _advance_seconds(state: GameState, seconds: float) -> void:
	var elapsed := 0.0
	while elapsed < seconds:
		state.advance(0.25)
		elapsed += 0.25

func _write_json(path: String, value: Dictionary) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(value))

func _funded_state() -> GameState:
	var state := GameState.new()
	state.coins = 1000000
	state.number = ScientificNumber.from_float(1000000)
	state.lifetime_generated = ScientificNumber.from_float(1000000)
	return state
