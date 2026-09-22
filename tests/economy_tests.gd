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
	_test_save_round_trip_and_legacy_migration()
	_test_bad_saves_are_never_written_over()
	_test_v5_saves_migrate_without_loss()
	_test_long_run_replays_identically_across_a_reload()
	_test_offline_policy()
	_test_prestige_reset_and_gain()
	_test_first_run_funds_permanent_workshop()
	_test_tier_pressure_and_curve_gates()
	_test_tier_one_opening()
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
	_test_rig_cost_is_quoted_against_wave_hp()
	_test_rig_purchase_spends_number_and_stacks()
	_test_rig_is_run_scoped()
	_test_rig_refuses_what_it_does_not_sell()
	_test_rig_save_round_trip()
	_test_rig_ranks_are_worth_more_than_workshop_ranks()
	_test_lab_definitions_cover_the_open_categories()
	_test_lab_research_costs_coins_and_takes_real_time()
	_test_lab_slots_limit_concurrent_research()
	_test_lab_slots_open_with_gems()
	_test_research_finished_mid_run_waits_for_the_next_run()
	_test_lab_research_is_a_between_run_action()
	_test_finished_lab_research_applies_its_effect()
	_test_lab_speed_shortens_other_lines_not_itself()
	_test_lab_save_round_trip()
	_test_card_definitions_are_common_and_rare()
	_test_card_pull_costs_gems_and_grants_a_level()
	_test_card_pull_is_a_between_run_action()
	_test_card_pull_never_exceeds_max_level()
	_test_card_equip_respects_slot_cap_and_run_state()
	_test_active_card_applies_its_effect_but_inventory_does_not()
	_test_card_save_round_trip()
	_test_defensive_ceilings_bound_the_combined_effects()
	_test_armor_ceiling_bounds_armor_not_other_rules()
	_test_catalogues_are_internally_consistent()
	_test_loaded_ranks_stay_within_their_caps()
	_test_wave_death_resets_run_but_keeps_meta_progress()
	_test_run_gates_the_wave_clock()
	_test_retreat_ends_and_resets_run()
	_test_tier_records_milestones_and_unlocks()
	_test_claimed_milestones_survive_a_reload()
	_test_boss_waves_and_checkpoints_pay_gems()
	_test_passed_checkpoints_are_paid_on_load()
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
	# 4.14 from the Workshop, plus the flat output every run has (D033).
	_expect(state.get_rate_per_second().compare_to(ScientificNumber.from_float(4.14 + state.balance_profile.BASE_DAMAGE_PER_SECOND)) == 0, "Workshop output and speed should affect rate")
	_expect(is_equal_approx(state._effect_sum("cost_discount"), 0.05), "twenty Discount ranks should still be a 5% discount")
	_expect(state.get_workshop_coin_cost(state.get_definition("generator")) == 16, "Discount should reduce permanent Coin costs")
	_expect(is_equal_approx(state._critical_chance(), 0.05), "Crit Chance should add positive critical chance")
	_expect(is_equal_approx(state._critical_multiplier(), 3.0), "Crit Damage should add critical size")

func _test_burst_and_positive_chance() -> void:
	var state := _funded_state()
	state.purchased = {"generator": 20, "faster_cadence": 20, "burst_relay": 1}
	state.start_run(1, 999)
	state.rng.seed = 999
	# A beaten wave banks everything, so each tick's gain is its whole output.
	state.active_encounter.remaining_liability = ScientificNumber.new()
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
	# Tier 1 adds its warm-up's starting Number, and every run its flat base
	# output (D033), to what the Workshop provides.
	_expect(state.number.compare_to(ScientificNumber.from_float(500 + state.balance_profile.WARM_UP_STARTING_NUMBER)) == 0, "Cushion should define the fresh-run Number baseline")
	_expect(state.get_rate_per_second().compare_to(ScientificNumber.from_float(9.5 + state.balance_profile.BASE_DAMAGE_PER_SECOND)) == 0, "Auto Crank should permanently raise run production")
	_expect(not state.purchase("faster_cadence"), "permanent Workshop purchases must be locked during a run")
	state.end_run()
	_expect(state.get_owned("priority_buffer") == 50 and state.get_owned("automation_core") == 50, "Workshop ranks must survive retreat")

func _test_save_round_trip_and_legacy_migration() -> void:
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
	_expect(original.save(), "the current save should write")
	var restored := GameState.new()
	restored.save_path = save_path
	restored.load()
	_expect(restored.get_owned("stronger_tap") == 2 and restored.workshop.tick_count == 7, "saved permanent Workshop state should round-trip")
	_expect(restored.workshop.selected_category == original.workshop.selected_category, "a save should round-trip the open Workshop category")
	_expect(restored.in_run and restored.selected_tier == 2, "a save should restore the active tier run")
	_expect(restored.active_encounter.remaining_liability.compare_to(saved_remaining) == 0, "a save should restore exact encounter liability")
	_expect(restored.run_seed == 77 and restored.rng.state == saved_rng_state, "a save should restore deterministic run RNG state")
	_expect(restored.run_peak_number.compare_to(original.run_peak_number) == 0 and restored.second_wind_used == original.second_wind_used, "a save should restore the run's peak and whether Second Wind is spent")
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
	var v4: Dictionary = SaveDataV8.make(v4_source)
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
	# The fixture's record reached wave 100 with nothing claimed, so migration
	# also pays those checkpoints' Coin bonuses on load (D030).
	var v4_owed_coins := 0
	for checkpoint in migrated_v4.balance_profile.COIN_MILESTONE_WAVES:
		v4_owed_coins += migrated_v4.balance_profile.milestone_bonus(1, checkpoint)
	_expect(migrated_v4.coins == v4_source.coins + v4_owed_coins and migrated_v4.knowledge == 4, "V4 permanent currencies should migrate, plus the checkpoints the record had passed")
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
	_expect(rewritten.get_owned(GameState.ARMOR_ID) == 3 and rewritten.focus_path == ProgressionTaxonomy.ATTACK, "migration should rewrite the save in the current shape immediately")
	_expect(int(_read_json(save_path).get("version", 0)) == SaveDataV8.VERSION, "the rewritten save should carry the current version")
	var kept_v4 := "res://.number_go_up_test_save.v4-backup.json"
	_expect(int(_read_json(kept_v4).get("version", 0)) == 4, "migration should keep the V4 file it read, unchanged, beside the new save")
	rewritten.clear_save()
	_expect(not FileAccess.file_exists(kept_v4), "clearing the save should also remove its migration copy")

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
		"settings": {"ambience": true, "muted": true},
	}
	_write_json(save_path, v3)
	var migrated_v3 := GameState.new()
	migrated_v3.save_path = save_path
	migrated_v3.load()
	_expect(migrated_v3.settings.get("ambience") == null and bool(migrated_v3.settings.get("muted")), "the retired ambience setting should be purged without disturbing the rest")
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

	# Malformed and newer-version saves must not crash or half-load: the load
	# leaves the fresh default state.
	for broken in [{"version": 99, "number": ScientificNumber.from_float(5).to_dict(), "lifetime": ScientificNumber.from_float(5).to_dict()}, {"version": 5}, {}]:
		_write_json(save_path, broken)
		var refused := GameState.new()
		refused.save_path = save_path
		refused.load()
		_expect(refused.number.is_zero() and refused.coins == 0 and not refused.in_run, "an unreadable save should leave a fresh state, not a partial one")
		refused.clear_save()
	_expect(_leftover_save_files().is_empty(), "clearing the save should leave no file behind")
	var v1 := {
		"version": 1,
		"number": ScientificNumber.from_float(100).to_dict(),
		"lifetime": ScientificNumber.from_float(1000).to_dict(),
		"highest": ScientificNumber.from_float(100).to_dict(),
		"purchased": {"stronger_tap": 1, "steady_hand": 1, "workshop_bench": 2, "prototype_oddity": 4},
		"auto_selected": "generator",
		"statistics": {},
		"settings": {"ambience": true},
		"last_seen_unix": Time.get_unix_time_from_system(),
	}
	_write_json(save_path, v1)
	var migrated_v1 := GameState.new()
	migrated_v1.save_path = save_path
	migrated_v1.load()
	_expect(migrated_v1.settings.get("ambience") == null, "the V1 migration should also purge the retired ambience setting")
	_expect(migrated_v1.get_owned("stronger_tap") == 2, "V1 hand upgrades should migrate into Hand Press")
	_expect(migrated_v1.workshop.legacy_credit == 6, "unmatched V1 progress should become Workshop credit")
	_expect(migrated_v1.workshop.automation_targets == ["generator"], "V1 automation should become first priority")
	migrated_v1.clear_save()

## D028: no save the loader cannot read is ever written over. A newer build's
## save pauses saving; an unreadable one is moved aside intact and the backup
## the previous save left behind loads instead; a write swaps in whole.
func _test_bad_saves_are_never_written_over() -> void:
	var save_path := "res://.number_go_up_test_save.json"
	var backup_path := save_path + ".bak"

	# Every save after the first keeps the one it replaced as the backup, and
	# leaves no temp file behind.
	var writer := _funded_state()
	writer.save_path = save_path
	writer.coins = 111
	_expect(writer.save(), "a first save should write")
	writer.coins = 222
	_expect(writer.save(), "a second save should write")
	_expect(int(_read_json(save_path).get("coins", 0)) == 222 and int(_read_json(backup_path).get("coins", 0)) == 111, "a save should keep the save it replaced as the backup")
	_expect(not FileAccess.file_exists(save_path + ".tmp"), "a finished save should leave no temp file")
	writer.clear_save()

	# A save from a newer build is left byte for byte, and saving pauses.
	var future: Dictionary = SaveDataV8.make(_funded_state())
	future.version = SaveDataV8.VERSION + 1
	_write_json(save_path, future)
	var future_text := FileAccess.get_file_as_string(save_path)
	var older_build := GameState.new()
	older_build.save_path = save_path
	older_build.load()
	_expect(older_build.load_status == GameState.LOAD_NEWER and older_build.saving_paused, "a newer save should pause saving")
	_expect(older_build.coins == 0, "a newer save should not be half-read")
	_expect(not older_build.save(), "a paused save should refuse to write")
	_expect(FileAccess.get_file_as_string(save_path) == future_text, "a newer save should be left exactly as it was")
	older_build.clear_save()

	# A live save that cannot be read is moved aside, and the backup loads.
	var good := _funded_state()
	good.coins = 999
	_write_json(backup_path, SaveDataV8.make(good))
	var torn := JSON.stringify(SaveDataV8.make(_funded_state()))
	_write_text(save_path, torn.substr(0, torn.length() / 2))
	var recovered := GameState.new()
	recovered.save_path = save_path
	recovered.load()
	_expect(recovered.load_status == GameState.LOAD_RECOVERED and recovered.coins == 999, "a torn live save should fall back to the backup")
	var moved_aside := _leftover_save_files().filter(func(name): return str(name).contains(GameState.QUARANTINE_INFIX))
	_expect(moved_aside.size() == 1 and FileAccess.get_file_as_string("res://" + str(moved_aside[0])) == torn.substr(0, torn.length() / 2), "the torn save should be kept, byte for byte, beside the live one")
	_expect(recovered.save() and int(_read_json(save_path).get("coins", 0)) == 999, "saving after a recovery should write the recovered state")
	recovered.clear_save()
	_expect(_leftover_save_files().is_empty(), "clearing the save should also remove the moved-aside copy")

	# With no backup to fall back to, the game starts fresh and says so, and
	# the unreadable save is still kept.
	var typed_wrong: Dictionary = SaveDataV8.make(_funded_state())
	typed_wrong.purchased = "not a dictionary"
	var not_finite := JSON.stringify(SaveDataV8.make(_funded_state())).replace('"highest":{"exponent":0,"mantissa":0.0}', '"highest":{"exponent":0,"mantissa":1e999}')
	for unreadable in [JSON.stringify(typed_wrong), not_finite, "{", ""]:
		_write_text(save_path, unreadable)
		var fresh := GameState.new()
		fresh.save_path = save_path
		fresh.load()
		_expect(fresh.load_status == GameState.LOAD_UNREADABLE and fresh.coins == 0 and not fresh.in_run, "an unreadable save with no backup should start a fresh game")
		_expect(not FileAccess.file_exists(save_path) and _leftover_save_files().size() == 1, "the unreadable save should be moved aside rather than left to be written over")
		fresh.clear_save()

	# A live save that vanished between the two renames of a save still has its
	# backup.
	_write_json(backup_path, SaveDataV8.make(good))
	var interrupted := GameState.new()
	interrupted.save_path = save_path
	interrupted.load()
	_expect(interrupted.load_status == GameState.LOAD_RECOVERED and interrupted.coins == 999, "a missing live save should fall back to the backup")
	interrupted.clear_save()
	var nothing := GameState.new()
	nothing.save_path = save_path
	nothing.load()
	_expect(nothing.load_status == GameState.LOAD_NEW_GAME, "no save at all should read as a new game")
	_expect(ScientificNumber.new(INF, 0).is_zero() and ScientificNumber.new(NAN, 3).is_zero(), "a non-finite value should read as zero rather than hang")
	_expect(_leftover_save_files().is_empty(), "the bad-save checks should leave no file behind")

## Every field V5 gained after it shipped survives migration to the current
## schema, and the V5 file is kept beside the new save.
func _test_v5_saves_migrate_without_loss() -> void:
	var save_path := "res://.number_go_up_test_save.json"
	var source := _funded_state()
	source.purchased = {"stronger_tap": 7, "tax_resistance": 3}
	source.knowledge = 9
	source.gems = 41
	source.card_ranks = {"card_damage": 3}
	source.card_active = ["card_damage"]
	source.lab_ranks = {"lab_damage": 2}
	source.tier_records["1"].highest_wave = GameState.TIER_UNLOCK_WAVE
	source.tier_records["1"].milestones_claimed = [10, 25]
	_expect(source.start_lab("lab_speed"), "the V5 fixture should have research running")
	_expect(source.start_run(2, 88), "the V5 fixture should hold a live run")
	source.rig_ranks = {"stronger_tap": 2}
	for tap_index in range(4):
		source.tap()
	var v5: Dictionary = SaveDataV8.make(source)
	v5.version = 5
	v5.erase("tick_accumulator")
	v5.erase("critical_chain")
	v5.erase("lab_slots")
	_write_json(save_path, v5)
	var migrated := GameState.new()
	migrated.save_path = save_path
	migrated.load()
	_expect(migrated.load_status == GameState.LOAD_OK, "a V5 save should load")
	# The record reached wave 100 but claimed only 10 and 25 at the old rate of
	# one Gem (D030): those two are topped up, and every other checkpoint up to
	# 100 is paid on load, Coin bonus included.
	var profile = migrated.balance_profile
	var expected_gems := 41
	var expected_coins := source.coins
	for checkpoint in profile.MILESTONE_WAVES:
		if checkpoint > GameState.TIER_UNLOCK_WAVE:
			continue
		if checkpoint == 10 or checkpoint == 25:
			expected_gems += profile.milestone_gems(1, checkpoint) - GameState.PRE_V8_MILESTONE_GEMS
		else:
			expected_gems += profile.milestone_gems(1, checkpoint)
			expected_coins += profile.milestone_bonus(1, checkpoint)
	_expect(migrated.coins == expected_coins and migrated.knowledge == 9 and migrated.gems == expected_gems, "V5 currencies should survive migration, plus the milestones it is owed")
	_expect(migrated.get_owned("stronger_tap") == 7 and migrated.get_owned(GameState.ARMOR_ID) == 3, "V5 Workshop ranks should survive migration")
	_expect(migrated.get_card_level("card_damage") == 3 and migrated.is_card_active("card_damage"), "V5 Cards should survive migration")
	_expect(migrated.lab_ranks.get("lab_damage") == 2.0 and migrated.lab_active.has("lab_speed"), "V5 Labs should survive migration")
	_expect(migrated.get_tier_record(1).milestones_claimed == [10, 20, 25, 30, 40, 50, 60, 75, 90, 100], "V5 records should survive migration, with every passed checkpoint claimed")
	_expect(migrated.in_run and migrated.rig_owned("stronger_tap") == 2 and migrated.rng.state == source.rng.state, "a V5 live run should survive migration")
	_expect(migrated.lab_slots_total() == LabResearch.LEGACY_SLOTS, "a V5 save should keep the two Lab slots every player then had")
	_expect(int(_read_json(save_path).get("version", 0)) == SaveDataV8.VERSION, "a V5 save should be rewritten in the current shape at once")
	_expect(int(_read_json("res://.number_go_up_test_save.v5-backup.json").get("version", 0)) == 5, "the V5 file should be kept beside the new save")
	migrated.clear_save()
	_expect(_leftover_save_files().is_empty(), "the V5 migration check should leave no file behind")

## D006 holds past the moment of saving: a run reloaded mid-way, with ticks,
## taps and a live crit chain, ends exactly where the uninterrupted run does.
func _test_long_run_replays_identically_across_a_reload() -> void:
	var save_path := "res://.number_go_up_test_save.json"
	var build := {"generator": 100, "automation_core": 50, "faster_cadence": 100, "more_critical": 100, "faster_echo": 60, "chain_reaction": 60, "tax_resistance": 100}
	var frames := 60 * 400
	var straight := GameState.new()
	straight.purchased = build.duplicate()
	straight.start_run(1, 2024)
	for frame in range(frames):
		straight.advance(1.0 / 60.0)
		if frame % 20 == 0:
			straight.tap()
	var reloaded := GameState.new()
	reloaded.save_path = save_path
	reloaded.purchased = build.duplicate()
	reloaded.start_run(1, 2024)
	var saw_chain := false
	for frame in range(frames):
		if frame == 60 * 137 + 7:
			saw_chain = reloaded.critical_chain > 0 or reloaded.tick_accumulator > 0.0
			reloaded.save()
			var resumed := GameState.new()
			resumed.save_path = save_path
			resumed.load()
			reloaded = resumed
		reloaded.advance(1.0 / 60.0)
		if frame % 20 == 0:
			reloaded.tap()
	_expect(saw_chain, "the reload should land mid-tick or mid-chain, or this check proves nothing")
	_expect(reloaded.lifetime_generated.to_dict() == straight.lifetime_generated.to_dict() and reloaded.number.to_dict() == straight.number.to_dict(), "a reloaded run should produce exactly what the uninterrupted run did")
	_expect(reloaded.rng.state == straight.rng.state and reloaded.wave == straight.wave and reloaded.coins == straight.coins, "a reloaded run should reach the same wave, Coins and RNG state")
	reloaded.clear_save()

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
	state.purchased = {"stronger_tap": 2, "generator": 1}
	_expect(state.start_run(1, 7), "the Prestige fixture should start a run")
	state.wave = 12
	state.number = ScientificNumber.from_float(1)
	state.lifetime_generated = ScientificNumber.from_float(1000000000.0)
	state.workshop.tick_count = 5
	state.run_coins_earned = 9
	state.run_gems_earned = 2
	state.last_run_summary = RunSummary.new(3, 4, 0, null, 1, "retreat")
	var expected_gain := state.get_prestige_knowledge_gain()
	_expect(expected_gain > 0, "progress far past the threshold should grant Knowledge")
	var gain := state.prestige()
	_expect(gain == expected_gain and state.knowledge == gain, "Prestige should bank the expected Knowledge")
	_expect(state.number.is_zero() and state.get_owned("stronger_tap") == 2, "Prestige should reset run Number but retain permanent Workshop ranks")
	var summary := state.last_run_summary
	_expect(summary != null and summary.outcome == "prestige", "Prestige should replace the previous run summary")
	_expect(summary.wave_reached == 12 and summary.tier_id == 1, "Prestige should record the run's wave and tier before reset")
	_expect(summary.coins_earned == 9 and summary.gems_earned == 2 and summary.knowledge_gained == gain, "Prestige should record every reward earned by that run")
	_expect(summary.final_hit.is_zero() and summary.attack_gap.is_zero() and summary.defense_gap.is_zero(), "Prestige should not record a killing hit or gaps")
	_expect(state.prestige() == 0 and state.last_run_summary == summary and state.knowledge == gain, "a repeated Prestige should not change the summary or pay twice")
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

## D033: Tier 1 opens under attack without a hit that can end the run. Every
## run has a flat base output that upgrades do not raise; a Tier 1 run starts
## with some Number; warm-up waves carry small HP and hits, softer bosses, and
## end on their timer, landing their hit and paying as if beaten; and a run's
## first Rig purchases are cheap during the warm-up.
func _test_tier_one_opening() -> void:
	var fresh := GameState.new()
	fresh.start_run(1, 3)
	var profile = fresh.balance_profile
	_expect(fresh.get_rate_per_second().compare_to(ScientificNumber.from_float(profile.BASE_DAMAGE_PER_SECOND)) == 0, "a fresh run should produce from its first second")
	_expect(fresh.number.compare_to(ScientificNumber.from_float(profile.WARM_UP_STARTING_NUMBER)) == 0, "a Tier 1 run should start with the warm-up's Number")
	var multiplied := GameState.new()
	multiplied.purchased = {"generator_two": 60}
	multiplied.start_run(1, 3)
	_expect(multiplied.get_rate_per_second().compare_to(fresh.get_rate_per_second()) == 0, "upgrades should not raise the flat base output")
	var tier_two := GameState.new()
	tier_two.tier_records["1"].highest_wave = GameState.TIER_UNLOCK_WAVE
	tier_two.start_run(2, 3)
	_expect(tier_two.number.is_zero(), "a tier with no warm-up should start with no extra Number")

	_expect(profile.liability_for_wave(1, 2).compare_to(ScientificNumber.from_float(profile.WARM_UP_START_HP * profile.WARM_UP_HP_GROWTH)) == 0, "warm-up HP should grow its share each wave")
	var boss_hp: float = profile.WARM_UP_START_HP * pow(profile.WARM_UP_HP_GROWTH, 9) * profile.WARM_UP_BOSS_HP
	_expect(profile.liability_for_wave(1, 10).compare_to(ScientificNumber.from_float(boss_hp)) == 0, "a warm-up boss should be softened, not tripled")
	var boss_hit: float = profile.WARM_UP_START_HIT * pow(profile.WARM_UP_HIT_GROWTH, 19) * profile.WARM_UP_BOSS_HIT
	_expect(profile.collection_for_wave(1, 20).compare_to(ScientificNumber.from_float(boss_hit)) == 0, "the final warm-up hit should use the gentler growth")
	_expect(boss_hit < 7.0, "the last warm-up boss should leave a reasonable opening buffer")
	# The first pressured hits climb from the warm-up, then return to the full
	# curve. The reduction belongs only to Tier 1; other tiers keep their base.
	for opening_wave in range(21, 27):
		fresh.wave = opening_wave
		fresh.active_encounter = fresh._make_encounter(opening_wave)
		var full_hit: ScientificNumber = profile.collection_for_wave(1, opening_wave)
		var ramped_hit := ScientificNumber.from_float(boss_hit * pow(profile.TIER_ONE_TRANSITION_HIT_GROWTH, float(opening_wave - 20)))
		var expected_hit: ScientificNumber = ramped_hit if opening_wave <= profile.TIER_ONE_TRANSITION_LAST_WAVE and ramped_hit.compare_to(full_hit) < 0 else full_hit
		_expect(fresh.get_effective_collection().compare_to(expected_hit) == 0, "Tier 1's effective hit should climb to the full curve at wave " + str(opening_wave))
		_expect(fresh.active_encounter.collection.compare_to(full_hit) == 0, "the encounter should retain the base hit for wave " + str(opening_wave))
	var armored := GameState.new()
	armored.purchased = {"tax_resistance": 1}
	armored.start_run(1, 3)
	armored.wave = 21
	armored.active_encounter = armored._make_encounter(21)
	var opening_hit: ScientificNumber = fresh.balance_profile.collection_for_wave(1, 21).multiply_scalar(profile.tier_one_transition_hit_multiplier(1, 21, profile.collection_for_wave(1, 21)))
	_expect(armored.get_effective_collection().compare_to(opening_hit.multiply_scalar(0.996)) == 0, "Armor should still reduce Tier 1's transition hit")
	_expect(tier_two.get_effective_collection().compare_to(tier_two.active_encounter.collection) == 0, "Tier 2's opening hit should be unchanged")

	# An unbeaten warm-up wave lands its hit, then ends and pays as if beaten.
	var stuck := GameState.new()
	stuck.start_run(1, 3)
	var before: ScientificNumber = stuck.number.copy()
	var hit := stuck.get_effective_collection()
	var event := stuck._resolve_wave_boundary()
	_expect(event.type == "tax_collection" and event.amount.compare_to(hit) == 0, "an unbeaten warm-up wave should land its hit")
	_expect(stuck.number.compare_to(before.subtract(hit)) == 0, "the hit should cost Number, not the run")
	_expect(stuck.wave == 2 and stuck.coins == 1 and stuck.get_tier_best(1) == 1, "the warm-up wave should then end, pay its Coin and count")
	# Past the warm-up an unbeaten wave keeps its HP and hits again (D012).
	stuck.wave = 21
	stuck.active_encounter = stuck._make_encounter(21)
	stuck.number = ScientificNumber.new(1.0, 9)
	stuck._resolve_wave_boundary()
	_expect(stuck.wave == 21, "past the warm-up an unbeaten wave should stay")

	# The run's first Rig purchases are cheap during the warm-up; later ones,
	# and any after the warm-up, pay the full price.
	var rig := GameState.new()
	rig.start_run(1, 3)
	var opening_cost: ScientificNumber = rig.get_rig_cost("generator")
	_expect(opening_cost.compare_to(ScientificNumber.from_float(12.0)) < 0, "the first Rig rank should cost about 12 Number")
	_expect(rig.purchase_rig("generator") and rig.purchase_rig("stronger_tap"), "both opening Rig ranks should be affordable immediately")
	_expect(rig.number.compare_to(ScientificNumber.from_float(25.0)) > 0, "two opening purchases should leave over half the starting Number")
	var repeat := GameState.new()
	repeat.start_run(1, 3)
	_expect(repeat.purchase_rig("generator") and repeat.get_rig_cost("generator").compare_to(opening_cost) == 0, "a repeated second rank should keep the same opening price")
	var mixed := GameState.new()
	mixed.start_run(1, 3)
	_expect(mixed.get_rig_cost("coin_bonus").compare_to(opening_cost) == 0, "the Utility category should keep the same opening price")
	_expect(mixed.purchase_rig("coin_bonus") and mixed.get_rig_cost("generator").compare_to(opening_cost) == 0, "a mixed-category pair should keep the same opening price")
	rig = GameState.new()
	rig.start_run(1, 3)
	rig.number = ScientificNumber.new(1.0, 9)
	var discounted: ScientificNumber = profile.rig_warm_up_reference_hp(1)
	_expect(rig.get_rig_cost("generator").compare_to(discounted) == 0, "the first warm-up purchase should be discounted")
	rig.purchase_rig("generator")
	_expect(rig.get_rig_cost("stronger_tap").compare_to(discounted) == 0, "the second warm-up purchase should be discounted too, whatever the row")
	rig.purchase_rig("stronger_tap")
	_expect(rig.get_rig_cost("generator_two").compare_to(profile.liability_for_wave(1, 21)) == 0, "the third should pay the full warm-up price")
	var late := GameState.new()
	late.start_run(1, 3)
	late.wave = 21
	late.active_encounter = late._make_encounter(21)
	_expect(late.get_rig_cost("generator").compare_to(profile.liability_for_wave(1, 21)) == 0, "past the warm-up no purchase should be discounted")

func _test_tier_pressure_and_curve_gates() -> void:
	var state := GameState.new()
	var profile = state.balance_profile
	# Tier 1's 20-wave warm-up ramps from a small wave HP and hit (D033); the
	# full curves begin at wave 21.
	_expect(profile.liability_for_wave(1, 1).compare_to(ScientificNumber.from_float(profile.WARM_UP_START_HP)) == 0, "Tier 1 wave 1 should carry the warm-up's opening HP")
	_expect(profile.collection_for_wave(1, 1).compare_to(ScientificNumber.from_float(profile.WARM_UP_START_HIT)) == 0, "Tier 1 wave 1 should carry the warm-up's opening hit")
	_expect(profile.liability_for_wave(1, 19).compare_to(profile.liability_for_wave(1, 21)) < 0 and profile.collection_for_wave(1, 19).compare_to(profile.collection_for_wave(1, 21)) < 0, "the warm-up should stay below the first full wave")
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

	# The warm-up is small but real (D033): its first wave has a little HP, and
	# only output past it banks.
	var warm_up := GameState.new()
	warm_up.start_run(1, 22)
	var warm_up_hp: ScientificNumber = warm_up.active_encounter.remaining_liability.copy()
	var starting: ScientificNumber = warm_up.number.copy()
	_expect(warm_up_hp.compare_to(ScientificNumber.from_float(warm_up.balance_profile.WARM_UP_START_HP)) == 0, "warm-up wave 1 should carry a small Wave HP")
	warm_up._add_number(warm_up_hp.add(ScientificNumber.from_float(5)))
	_expect(warm_up.number.compare_to(starting.add(ScientificNumber.from_float(5))) == 0, "output past a warm-up wave's HP should bank")

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

	# The Tier 1 transition is applied when a hit is read, not stored in the
	# encounter. A saved older encounter may have a larger base hit; reloading
	# at wave 21 must still cap that hit, without applying the cap twice.
	var opening := GameState.new()
	opening.save_path = save_path
	opening.start_run(1, 31)
	opening.wave = 21
	opening.active_encounter = opening._make_encounter(21)
	opening.active_encounter.collection = opening.active_encounter.collection.multiply_scalar(2.0)
	opening.number = ScientificNumber.from_float(100.0)
	var opening_hit: ScientificNumber = opening.get_effective_collection()
	_expect(opening_hit.compare_to(ScientificNumber.from_float(13.0)) < 0, "a saved larger base hit should still use the Tier 1 transition cap")
	_expect(opening.save(), "a Tier 1 transition wave should save")
	var opening_restored := GameState.new()
	opening_restored.save_path = save_path
	opening_restored.load()
	_expect(opening_restored.wave == 21 and opening_restored.get_effective_collection().compare_to(opening_hit) == 0, "a reloaded Tier 1 transition should keep the same effective hit")
	opening._resolve_wave_boundary()
	opening_restored._resolve_wave_boundary()
	_expect(opening_restored.number.compare_to(opening.number) == 0 and opening_restored.wave == opening.wave, "the reloaded Tier 1 hit should resolve identically")
	opening_restored.clear_save()

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
	_expect(state.number.compare_to(ScientificNumber.from_float(500 + state.balance_profile.WARM_UP_STARTING_NUMBER)) == 0, "Cushion should be worth its face value on Tier 1, on top of the warm-up's start")
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

## The Armor ceiling (D023) bounds Armor's own share of a hit. A rule that
## shrinks hits for its own reason stacks on top rather than being clawed back
## to the ceiling.
func _test_armor_ceiling_bounds_armor_not_other_rules() -> void:
	var state := GameState.new()
	state.purchased = {GameState.ARMOR_ID: 100}
	state.lab_ranks = {"lab_resilience": 40}
	state.tier_records["1"].highest_wave = GameState.TIER_UNLOCK_WAVE
	state.start_run(2, 4)
	state.rig_ranks = {GameState.ARMOR_ID: 20}
	_expect(state._effect_sum("collection_resistance") > state.balance_profile.COLLECTION_RESISTANCE_CEILING, "the fixture should stack Armor past its ceiling")
	var base: ScientificNumber = state.active_encounter.collection
	_expect(state.get_effective_collection().compare_to(base.multiply_scalar(0.25)) == 0, "stacked Armor alone should stop at its ceiling")
	state.active_rule_modifiers = [{"source": "test_rule", "target": "collection", "stage": "multiplicative", "value": 0.2}]
	_expect(state.get_effective_collection().compare_to(base.multiply_scalar(0.25 * 0.2)) == 0, "a separate rule that shrinks hits should still apply past Armor's ceiling")

## Every catalogue a save keys ranks by: ids unique across all three, effects
## the game knows how to read, shelves that exist, caps and prices that make
## sense, Rig rows that are real Workshop rows, and Workshop levels a player
## can actually reach.
func _test_catalogues_are_internally_consistent() -> void:
	var state := GameState.new()
	var ids := {}
	var effect_keys: Array = []
	for definition in state.definitions:
		_expect(not ids.has(definition.id), "catalogue id %s should be unique" % definition.id)
		ids[definition.id] = true
		effect_keys.append_array(definition.effects.keys())
		_expect(definition.max_rank > 0 and definition.cost_growth >= 1.0, "%s should have a positive cap and non-shrinking cost growth" % definition.id)
		if definition.category == ProgressionTaxonomy.WORKSHOP:
			_expect(ProgressionTaxonomy.WORKSHOP_CATEGORIES.has(definition.workshop_category), "%s should sit on one of the four Workshop categories" % definition.id)
			_expect(not definition.cost.is_zero(), "%s should cost something" % definition.id)
	for lab_definition in state.lab_research.definitions:
		_expect(not ids.has(lab_definition.id), "catalogue id %s should be unique" % lab_definition.id)
		ids[lab_definition.id] = true
		effect_keys.append_array(lab_definition.effects.keys())
		_expect(lab_definition.max_rank > 0 and lab_definition.base_cost > 0 and lab_definition.base_duration > 0.0, "%s should have a cap, a price and a duration" % lab_definition.id)
		_expect(lab_definition.category == "main" or ProgressionTaxonomy.WORKSHOP_CATEGORIES.has(lab_definition.category), "%s should sit on Main or a Workshop category" % lab_definition.id)
	for card_definition in state.card_collection.definitions:
		_expect(not ids.has(card_definition.id), "catalogue id %s should be unique" % card_definition.id)
		ids[card_definition.id] = true
		effect_keys.append_array(card_definition.effects.keys())
		_expect(CardCollection.RARITY_WEIGHT.has(card_definition.rarity), "%s should have a known rarity" % card_definition.id)
	for effect_name in effect_keys:
		_expect(GameState.STAT_DISPLAY.has(effect_name), "effect %s should be one the game reads and displays; a typo would do nothing" % effect_name)
	for category in state.balance_profile.RIG_ROWS:
		for row_id in state.balance_profile.RIG_ROWS[category]:
			var row := state.get_definition(row_id)
			_expect(row != null and row.workshop_category == category, "Rig row %s should be a Workshop row on the %s shelf" % [row_id, category])
	# A row's Workshop level must be reachable from the rows open below it.
	var rows := state.definitions_for_progression_type(ProgressionTaxonomy.MODULE) + state.definitions_for_progression_type(ProgressionTaxonomy.PROTOCOL) + state.definitions_for_progression_type(ProgressionTaxonomy.ROUTINE)
	for definition in rows:
		if definition.category != ProgressionTaxonomy.WORKSHOP:
			continue
		var reachable := 0
		for other in rows:
			if other.category == ProgressionTaxonomy.WORKSHOP and other.workshop_level_required < definition.workshop_level_required:
				reachable += other.max_rank
		_expect(reachable >= definition.workshop_level_required, "%s should open at a Workshop level the rows below it can reach" % definition.id)

## A save holding more ranks than a row allows loads at the cap, so a lowered
## cap takes effect; a rank under a retired id is kept but counts for nothing.
func _test_loaded_ranks_stay_within_their_caps() -> void:
	var save_path := "res://.number_go_up_test_save.json"
	var data: Dictionary = SaveDataV8.make(GameState.new())
	data.purchased = {"stronger_tap": 5000, "generator": -4, "retired_row": 30}
	data.knowledge_purchased = {"insight": 3}
	data.lab_ranks = {"lab_damage": 900, "retired_line": 2}
	data.card_ranks = {"card_damage": 500, "card_coins": -1}
	data.card_active = ["card_damage"]
	_write_json(save_path, data)
	var loaded := GameState.new()
	loaded.save_path = save_path
	loaded.load()
	var tap := loaded.get_definition("stronger_tap")
	_expect(loaded.get_owned("stronger_tap") == tap.max_rank and loaded.get_owned("generator") == 0, "Workshop ranks should load between zero and the row's cap")
	_expect(loaded.purchased.get("retired_row") == 30 and loaded.get_workshop_level() == tap.max_rank, "a retired row's ranks should be kept but not counted")
	_expect(loaded.get_owned("insight") == 3, "Insight ranks should load unchanged")
	_expect(loaded.get_lab_owned("lab_damage") == loaded.lab_research.get_definition("lab_damage").max_rank and loaded.lab_ranks.get("retired_line") == 2, "Lab ranks should load within their cap, and a retired line's kept")
	_expect(loaded.get_card_level("card_damage") == CardCollection.MAX_LEVEL and loaded.get_card_level("card_coins") == 0, "Card levels should load between zero and the top level")
	loaded.clear_save()

func _test_wave_death_resets_run_but_keeps_meta_progress() -> void:
	var state := GameState.new()
	state.tier_records["1"].highest_wave = GameState.TIER_UNLOCK_WAVE
	state.purchased = {"stronger_tap": 3, "tax_resistance": 2}
	state.coins = 42
	state.start_run(2, 7)
	# Chip the wave down first, so a summary that recorded the wave's full HP
	# would differ from the HP Attack actually left.
	state.active_encounter.apply_compliance(state.active_encounter.max_liability.multiply_scalar(0.4))
	state.number = ScientificNumber.from_float(1)
	state.lifetime_generated = ScientificNumber.from_float(GameState.PRESTIGE_TEASER_UNLOCK * 100.0)
	state.workshop.tick_count = 12
	state.run_coins_earned = 5
	var expected_knowledge := state.get_prestige_knowledge_gain()
	var killing_hit := state.get_effective_collection()
	var was_boss: bool = state.active_encounter.is_boss
	var expected_attack_gap: ScientificNumber = state.active_encounter.remaining_liability.copy()
	var number_before_hit := state.number.copy()
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
	# The two gaps under "Lost to" (step 6): the wave HP Attack left, and the
	# Number the hit exceeded. Both are read before the encounter is wiped.
	_expect(state.last_run_summary.attack_gap.compare_to(expected_attack_gap) == 0, "the summary should record how much wave HP Attack left")
	_expect(state.last_run_summary.defense_gap.compare_to(killing_hit.subtract(number_before_hit)) == 0, "the summary should record how far short of the hit the Number fell")

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

	# Recoil can finish the wave on the very boundary that lands the killing
	# hit. The Attack gap must still be what Attack itself left: Recoil's return
	# is Defense's damage, and crediting it to Attack would mispoint the screen.
	var recoil_death := GameState.new()
	recoil_death.tier_records["1"].highest_wave = GameState.TIER_UNLOCK_WAVE
	recoil_death.purchased = {"recoil": 100}
	recoil_death.start_run(2, 73)
	recoil_death.number = ScientificNumber.from_float(1)
	var recoil_hit := recoil_death.get_effective_collection()
	var recoil_hp_left := recoil_hit.multiply_scalar(0.25)
	recoil_death.active_encounter.remaining_liability = recoil_hp_left
	var recoil_event := recoil_death._resolve_wave_boundary()
	_expect(recoil_event.type == "wave_death", "a killing hit should still end the run when Recoil clears the wave")
	_expect(recoil_death.last_run_summary.attack_gap.compare_to(recoil_hp_left) == 0, "the Attack gap should be the HP Attack left, before Recoil returned part of the hit")
	_expect(recoil_death.last_run_summary.defense_gap.compare_to(recoil_hit.subtract(ScientificNumber.from_float(1))) == 0, "the hit shortfall should still be recorded when Recoil clears the wave")

	# A hit exactly equal to the Number is still a death, with no Defense gap.
	var exact_death := GameState.new()
	exact_death.tier_records["1"].highest_wave = GameState.TIER_UNLOCK_WAVE
	exact_death.start_run(2, 74)
	exact_death.number = exact_death.get_effective_collection()
	exact_death._resolve_wave_boundary()
	_expect(exact_death.last_run_summary.defense_gap.is_zero(), "a Number exactly equal to the hit should leave no Defense gap")

	var retreat := GameState.new()
	retreat.start_run(1, 72)
	var summary := retreat.end_run()
	_expect(summary.final_hit.is_zero() and not summary.lost_to_boss, "a retreat was lost to nothing, so it records no hit")
	_expect(summary.attack_gap.is_zero() and summary.defense_gap.is_zero(), "a retreat was lost to nothing, so it records no gaps")

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
	_expect(claimed == [10, 20, 25, 30, 40, 50, 60, 75, 90, 100], "milestones should be claimed once at authored checkpoints")
	_expect(state.is_tier_unlocked(2), "clearing Tier 1 wave 100 should unlock Tier 2")
	_expect(unlock_event != null and unlock_event.type == "tier_unlock", "the first wave-100 clear should announce the newly unlocked tier")
	_expect(not state.is_tier_unlocked(3), "Tier 3 should remain locked until Tier 2 wave 100")
	state.end_run()
	_expect(state.select_tier(2), "an unlocked tier should be selectable outside a run")

## A milestone claimed before a reload stays claimed after it. JSON reads the
## claimed waves back as floats, which once made every milestone pay again on
## the first pass after each load.
func _test_claimed_milestones_survive_a_reload() -> void:
	var save_path := "res://.number_go_up_test_save.json"
	var first := GameState.new()
	first.save_path = save_path
	first.start_run(1, 5)
	_clear_waves_through(first, 10)
	first.end_run()
	var first_gems: int = first.balance_profile.milestone_gems(1, 10) + first.balance_profile.BOSS_WAVE_GEMS
	_expect(first.coins == 34 and first.gems == first_gems, "the first wave-10 clear should pay 14 wave Coins, the 20-Coin milestone bonus, and the checkpoint's and the boss wave's Gems")
	_expect(first.save(), "the milestone save should write")
	var reloaded := GameState.new()
	reloaded.save_path = save_path
	reloaded.load()
	var claimed: Array = reloaded.get_tier_record(1).milestones_claimed
	_expect(claimed == [10] and typeof(claimed[0]) == TYPE_INT, "a claimed milestone should reload as the whole-number wave it was")
	reloaded.start_run(1, 5)
	_clear_waves_through(reloaded, 10)
	reloaded.end_run()
	_expect(reloaded.coins == 34 + 14, "a reloaded milestone should pay only its wave Coins, not its bonus again")
	_expect(reloaded.gems == first_gems + reloaded.balance_profile.BOSS_WAVE_GEMS, "a reloaded milestone should not grant its Gems again; only the boss wave pays")
	_expect(reloaded.get_tier_record(1).milestones_claimed == [10], "a reclaimed pass should not list the milestone twice")
	reloaded.clear_save()

	# A save written before the fix can hold the same wave twice, plus junk;
	# it collapses to each real wave once.
	var damaged: Dictionary = SaveDataV8.make(GameState.new())
	damaged.tier_records["1"] = {"highest_wave": 30, "best_time": 0.0, "milestones_claimed": [10, 10.0, "junk", -3, 25]}
	damaged.tier_records["9"] = "a tier this build does not know"
	_write_json(save_path, damaged)
	var repaired := GameState.new()
	repaired.save_path = save_path
	repaired.load()
	_expect(repaired.get_tier_record(1).milestones_claimed == [10, 20, 25, 30], "duplicate and junk milestone entries should collapse on load, and passed checkpoints be claimed")
	_expect(typeof(repaired.get_tier_record(1).highest_wave) == TYPE_INT and repaired.get_tier_best(1) == 30, "a reloaded tier best should stay a whole-number wave")
	repaired.clear_save()

## D030: every boss wave pays a Gem, every run; each tier's checkpoints pay a
## larger, growing number of Gems once per tier record; harder tiers pay more.
func _test_boss_waves_and_checkpoints_pay_gems() -> void:
	var profile = GameState.new().balance_profile
	_expect(profile.milestone_gems(1, 10) == 6 and profile.milestone_gems(1, 100) == 20 and profile.milestone_gems(1, 200) == 28, "checkpoint Gems should grow with the wave")
	_expect(profile.milestone_gems(2, 100) == 36 and profile.milestone_gems(3, 100) == 52, "harder tiers should pay more for the same checkpoint")
	_expect(profile.milestone_gems(1, 11) == 0 and profile.wave_gems(11) == 0 and profile.wave_gems(30) == 1, "only checkpoints and boss waves should pay Gems")
	var first_run_gems := 0
	for checkpoint in profile.MILESTONE_WAVES:
		first_run_gems += profile.milestone_gems(1, checkpoint)
	_expect(first_run_gems >= 200, "Tier 1's checkpoints should be worth a lot together")

	var state := GameState.new()
	state.start_run(1, 5)
	_clear_waves_through(state, 30)
	var expected := 0
	for completed in range(1, 31):
		expected += profile.wave_gems(completed) + profile.milestone_gems(1, completed)
	_expect(state.gems == expected and state.run_gems_earned == expected, "a run through wave 30 should pay three boss Gems and four checkpoints")
	var summary := state.end_run()
	_expect(summary.gems_earned == expected and state.run_gems_earned == 0, "the run summary should report the run's Gems, and the next run start at none")
	state.start_run(1, 5)
	_clear_waves_through(state, 30)
	_expect(state.gems == expected + 3, "a second run should pay only the three boss waves again")
	state.end_run()

	# The run's Gems so far survive a mid-run reload.
	var save_path := "res://.number_go_up_test_save.json"
	var mid := GameState.new()
	mid.save_path = save_path
	mid.start_run(1, 6)
	_clear_waves_through(mid, 10)
	var mid_gems := mid.run_gems_earned
	_expect(mid_gems > 0 and mid.save(), "the mid-run fixture should have Gems to save")
	var resumed := GameState.new()
	resumed.save_path = save_path
	resumed.load()
	_expect(resumed.run_gems_earned == mid_gems, "a reloaded run should remember the Gems it has paid")
	resumed.clear_save()

## A checkpoint a record has passed but not claimed pays on load, once; a save
## from before V8 has its old one-Gem claims topped up, once.
func _test_passed_checkpoints_are_paid_on_load() -> void:
	var save_path := "res://.number_go_up_test_save.json"
	var profile = GameState.new().balance_profile
	var passed: Dictionary = SaveDataV8.make(GameState.new())
	passed.tier_records["1"] = {"highest_wave": 60, "best_time": 0.0, "milestones_claimed": [10, 25, 50]}
	_write_json(save_path, passed)
	var loaded := GameState.new()
	loaded.save_path = save_path
	loaded.load()
	var owed: int = profile.milestone_gems(1, 20) + profile.milestone_gems(1, 30) + profile.milestone_gems(1, 40) + profile.milestone_gems(1, 60)
	_expect(loaded.gems == owed and loaded.milestone_gems_caught_up == owed, "passed but unclaimed checkpoints should pay their Gems on load")
	_expect(loaded.coins == 0, "checkpoints without a Coin bonus should pay no Coins")
	_expect(loaded.get_tier_record(1).milestones_claimed == [10, 20, 25, 30, 40, 50, 60], "paid checkpoints should be claimed")
	loaded.save()
	var again := GameState.new()
	again.save_path = save_path
	again.load()
	_expect(again.gems == owed and again.milestone_gems_caught_up == 0, "a second load should pay nothing more")
	again.clear_save()

	var old: Dictionary = SaveDataV8.make(GameState.new())
	old.version = 7
	old.erase("run_gems_earned")
	old.gems = 2
	old.tier_records["1"] = {"highest_wave": 25, "best_time": 0.0, "milestones_claimed": [10, 20, 25]}
	_write_json(save_path, old)
	var topped := GameState.new()
	topped.save_path = save_path
	topped.load()
	var top_up: int = (profile.milestone_gems(1, 10) - GameState.PRE_V8_MILESTONE_GEMS) + (profile.milestone_gems(1, 25) - GameState.PRE_V8_MILESTONE_GEMS)
	_expect(topped.gems == 2 + top_up, "a pre-V8 save should have its old one-Gem Coin checkpoints topped up")
	_expect(int(_read_json(save_path).get("version", 0)) == SaveDataV8.VERSION, "the topped-up save should be rewritten as V8 at once")
	var reread := GameState.new()
	reread.save_path = save_path
	reread.load()
	_expect(reread.gems == 2 + top_up, "a top-up should never be paid twice")
	reread.clear_save()
	_expect(_leftover_save_files().is_empty(), "the checkpoint checks should leave no file behind")

func _clear_waves_through(state: GameState, last_wave: int) -> void:
	while state.in_run and state.wave <= last_wave:
		state.active_encounter.remaining_liability = ScientificNumber.new()
		state._resolve_wave_boundary()

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

## The Rig (D015) is priced against the wave, not in absolute Number, so one
## table scales across tiers and depth. Attack and Defense start at one wave of
## HP with 1.7 and 1.6 growth; Utility starts at two waves with 1.5.
func _test_rig_cost_is_quoted_against_wave_hp() -> void:
	var state := _funded_state()
	state.start_run(1, 5)
	var floor_hp: ScientificNumber = state.balance_profile.liability_for_wave(1, 21)
	_expect(state.get_rig_reference_hp().compare_to(floor_hp) == 0, "Tier 1 warm-up should quote Rig prices against the first pressured wave")
	# Quoting a named rank reads the ladder itself; the warm-up discount (D033)
	# applies only to the run's next purchase.
	var first := state.get_rig_cost("stronger_tap", 0)
	_expect(first.compare_to(floor_hp) == 0, "the first Attack rank should cost one wave of HP at k=1")
	_expect(state.get_rig_cost("stronger_tap", 1).compare_to(first.multiply_scalar(1.7)) == 0, "each Attack rank should cost 1.7x the last")
	_expect(state.get_rig_cost(GameState.ARMOR_ID, 0).compare_to(floor_hp) == 0, "the first Defense rank should cost one wave of HP at k=1")
	_expect(state.get_rig_cost("coin_bonus", 0).compare_to(floor_hp.multiply_scalar(2.0)) == 0, "the first Utility rank should cost two waves of HP at k=2")
	# A pressured wave moves the quote with its own HP.
	state.wave = 30
	state.active_encounter = state._make_encounter(30)
	_expect(state.get_rig_reference_hp().compare_to(state.active_encounter.max_liability) == 0, "a pressured wave should quote against its own HP")
	_expect(state.get_rig_cost("stronger_tap").compare_to(state.active_encounter.max_liability) == 0, "the quote should follow the current wave")

func _test_rig_purchase_spends_number_and_stacks() -> void:
	var state := _funded_state()
	state.start_run(1, 6)
	state.number = ScientificNumber.from_float(1.0e9)
	var base_tap := state._tap_base()
	var price := state.get_rig_cost("stronger_tap")
	var before: ScientificNumber = state.number.copy()
	_expect(state.purchase_rig("stronger_tap"), "a Rig rank should purchase with enough Number")
	_expect(state.rig_owned("stronger_tap") == 1 and state.get_owned("stronger_tap") == 0, "the Rig rank should land beside the permanent Workshop rank, not inside it")
	_expect(state.number.compare_to(before.subtract(price)) == 0, "the purchase should spend exactly the quoted Number")
	var multiplier: float = state.balance_profile.rig_effect_multiplier(ProgressionTaxonomy.ATTACK, "stronger_tap")
	_expect(is_equal_approx(state._tap_base(), base_tap + 0.05 * multiplier), "a Rig rank should grant its multiplier of one Workshop rank's effect")
	_expect(state.get_workshop_level() == 0, "Rig ranks must not raise the Workshop level")
	# Uncapped: the Rig keeps selling past the Workshop's rank cap.
	state.number = ScientificNumber.new(1.0, 40)
	var cap: int = state.get_definition("stronger_tap").max_rank
	for rank in range(cap):
		_expect(state.purchase_rig("stronger_tap"), "Rig ranks are uncapped while Number lasts")
	_expect(state.rig_owned("stronger_tap") == cap + 1, "the Rig should hold ranks past the Workshop cap")

func _test_rig_is_run_scoped() -> void:
	var state := _funded_state()
	state.start_run(1, 7)
	state.number = ScientificNumber.from_float(1.0e9)
	var base_tap := state._tap_base()
	_expect(state.purchase_rig("stronger_tap"), "a Rig rank should purchase during the run")
	_expect(state.end_run() != null, "retreat should end the run")
	_expect(state.rig_ranks.is_empty(), "retreat should clear the Rig")
	_expect(is_equal_approx(state._tap_base(), base_tap), "Rig effects should end with the run")

	# Death shares the ending machinery, so it clears the Rig too.
	state.start_run(1, 7)
	state.number = ScientificNumber.from_float(1.0e9)
	_expect(state.purchase_rig("stronger_tap"), "the next run should buy its own Rig rank")
	state.wave = 21
	state.active_encounter = state._make_encounter(21)
	state.number = ScientificNumber.from_float(1.0)
	state._resolve_wave_boundary()
	_expect(not state.in_run and state.rig_ranks.is_empty(), "death should clear the Rig like every other ending")

	# Prestige shares the same reset, so it clears the Rig too.
	var prestige_state := _funded_state()
	prestige_state.start_run(1, 7)
	prestige_state.number = ScientificNumber.from_float(1.0e9)
	_expect(prestige_state.purchase_rig("stronger_tap"), "the Prestige fixture should hold a Rig rank")
	prestige_state.lifetime_generated = ScientificNumber.from_float(1.0e6)
	_expect(prestige_state.prestige() > 0 and prestige_state.rig_ranks.is_empty(), "Prestige should clear the Rig")

func _test_rig_refuses_what_it_does_not_sell() -> void:
	var state := _funded_state()
	_expect(not state.purchase_rig("stronger_tap"), "the Rig must refuse a purchase outside a run")
	state.start_run(1, 8)
	state.number = ScientificNumber.from_float(1.0e9)
	for workshop_only in ["priority_buffer", "brace_discount", "second_wind", "knowledge_bonus", "smarter_efficiency"]:
		_expect(not state.can_purchase_rig(workshop_only), "the Rig must not sell a Workshop-only row: " + workshop_only)
	_expect(state.can_purchase_rig("coin_bonus"), "the Rig should sell Utility's Coin Bonus")
	_expect(state.can_purchase_rig(GameState.ARMOR_ID), "the Rig should sell Defense's Armor")
	_expect(not state.can_purchase_rig("not_a_row"), "an unknown row should quote nothing")

	var poor := _funded_state()
	poor.start_run(1, 9)
	poor.number = ScientificNumber.from_float(1.0)
	_expect(not poor.purchase_rig("stronger_tap"), "a rank the Number cannot cover should refuse")

	# The exact price sells and leaves zero Number: the contract is a visible
	# price, not a refusal (D015).
	var exact := _funded_state()
	exact.start_run(1, 10)
	exact.number = exact.get_rig_cost("stronger_tap").copy()
	_expect(exact.purchase_rig("stronger_tap"), "a rank the Number exactly covers should sell")
	_expect(exact.number.is_zero(), "spending the exact price should leave zero Number")

func _test_rig_save_round_trip() -> void:
	var save_path := "res://.number_go_up_test_save.json"
	var original := _funded_state()
	original.save_path = save_path
	original.start_run(1, 77)
	original.number = ScientificNumber.from_float(1.0e9)
	_expect(original.purchase_rig("stronger_tap") and original.purchase_rig("coin_bonus"), "the fixture should hold two Rig ranks")
	var saved_number: ScientificNumber = original.number.copy()
	var saved_rng := original.rng.state
	_expect(original.save(), "the Rig save should write")
	var restored := GameState.new()
	restored.save_path = save_path
	restored.load()
	_expect(restored.rig_owned("stronger_tap") == 1 and restored.rig_owned("coin_bonus") == 1, "Rig ranks should round-trip with the active run")
	_expect(restored.number.compare_to(saved_number) == 0, "the Number left after Rig spending should round-trip")
	_expect(restored.rng.state == saved_rng, "Rig spending must not disturb the RNG state")
	restored.clear_save()

	# A save written before the Rig existed resumes with no ranks, and a
	# malformed Rig block reads as empty rather than crashing.
	var pre_rig := GameState.new()
	pre_rig.save_path = save_path
	pre_rig.start_run(1, 5)
	var legacy: Dictionary = SaveDataV8.make(pre_rig)
	legacy.erase("rig_ranks")
	_write_json(save_path, legacy)
	var loaded := GameState.new()
	loaded.save_path = save_path
	loaded.load()
	_expect(loaded.in_run and loaded.rig_ranks.is_empty(), "a pre-Rig save should resume with an empty Rig")
	loaded.clear_save()
	legacy["rig_ranks"] = "garbage"
	_write_json(save_path, legacy)
	var malformed := GameState.new()
	malformed.save_path = save_path
	malformed.load()
	_expect(malformed.in_run and malformed.rig_ranks.is_empty(), "a malformed Rig block should read as empty, not crash")
	malformed.clear_save()

## D024: Labs are permanent research paid in Coins and gated by real time,
## distinct from both the Workshop's instant purchases and the Rig's run-scoped
## ones. The four starting lines cover Main and the three open categories.
func _test_lab_definitions_cover_the_open_categories() -> void:
	var state := GameState.new()
	var ids := []
	for definition in state.lab_research.definitions:
		ids.append(definition.id)
	_expect(ids.has("lab_speed") and ids.has("lab_damage") and ids.has("lab_resilience") and ids.has("lab_coin_research"), "Labs should open with one line for Main and each of Attack, Defense and Utility")
	_expect(state.lab_research.get_definition("lab_damage").category == ProgressionTaxonomy.ATTACK, "Damage Research should sit on the Attack shelf")
	_expect(state.lab_research.get_definition("nope") == null, "an unknown research id should not resolve to a line")

func _test_lab_research_costs_coins_and_takes_real_time() -> void:
	var state := _funded_state()
	_expect(state.can_start_lab("lab_damage"), "Damage Research should be startable with Coins in hand")
	var cost := state.get_lab_cost("lab_damage")
	var duration := state.get_lab_duration("lab_damage")
	_expect(cost > 0 and duration > 0.0, "a research line should cost Coins and take real time")
	var coins_before := state.coins
	_expect(state.start_lab("lab_damage"), "starting research should succeed while a slot and the Coins are free")
	_expect(state.coins == coins_before - cost, "starting research should spend exactly its quoted Coin cost")
	_expect(state.lab_is_active("lab_damage") and state.get_lab_owned("lab_damage") == 0, "research in progress should not yet be a finished rank")
	_expect(not state.can_start_lab("lab_damage"), "a line already researching should not be startable again")
	var started: float = state.lab_active["lab_damage"].started_unix
	_expect(state.get_lab_owned("lab_damage", started + duration - 1.0) == 0, "research should not settle a moment before its duration elapses")
	_expect(state.get_lab_owned("lab_damage", started + duration) == 1, "research should settle into a rank once its duration has elapsed")
	_expect(not state.lab_is_active("lab_damage", started + duration), "a settled line should leave its slot")

func _test_lab_slots_limit_concurrent_research() -> void:
	var state := _funded_state()
	state.gems = LabResearch.SLOT_GEM_COSTS[0]
	_expect(state.unlock_lab_slot(), "the fixture should open a second Lab slot")
	_expect(state.start_lab("lab_speed") and state.start_lab("lab_damage"), "both of the two Lab slots should be fillable")
	_expect(state.lab_active_count() == state.lab_slots_total(), "every slot should now be in use")
	_expect(not state.can_start_lab("lab_resilience") and not state.start_lab("lab_resilience"), "a third line should wait for a slot to free")
	var started: float = state.lab_active["lab_speed"].started_unix
	var duration := state.get_lab_duration("lab_speed", started)
	_expect(state.can_start_lab("lab_resilience", started + duration), "settling one line should free its slot for another")

## D029: Labs start with one slot and open up to five with Gems. Existing
## saves keep the two slots every player had before slots were bought.
func _test_lab_slots_open_with_gems() -> void:
	var state := _funded_state()
	_expect(state.lab_slots_total() == LabResearch.STARTING_SLOTS and LabResearch.STARTING_SLOTS == 1, "a new game should start with one Lab slot")
	_expect(state.start_lab("lab_damage") and not state.can_start_lab("lab_speed"), "one slot should hold one line at a time")
	_expect(state.get_lab_slot_cost() == 20, "the second slot should cost 20 Gems")
	state.gems = 19
	_expect(not state.can_unlock_lab_slot() and not state.unlock_lab_slot() and state.gems == 19, "a slot should not open without its Gems")
	state.gems = 20
	_expect(state.unlock_lab_slot() and state.gems == 0 and state.lab_slots_total() == 2, "a slot should open for exactly its Gem cost")
	_expect(state.can_start_lab("lab_speed"), "an opened slot should take a second line")
	state.gems = 10000
	var spent := 0
	while state.can_unlock_lab_slot():
		spent += state.get_lab_slot_cost()
		state.unlock_lab_slot()
	_expect(state.lab_slots_total() == LabResearch.MAX_SLOTS and spent == 40 + 80 + 160, "slots should open to five, at 40, 80 and 160 Gems after the second")
	_expect(state.get_lab_slot_cost() == 0 and not state.unlock_lab_slot() and state.gems == 10000 - spent, "a sixth slot should not exist")
	var running := _funded_state()
	running.gems = 100
	running.start_run(1, 3)
	_expect(not running.can_unlock_lab_slot() and not running.unlock_lab_slot() and running.gems == 100, "opening a slot mid-run should be refused, like other Gem spends")

	var save_path := "res://.number_go_up_test_save.json"
	var saved := _funded_state()
	saved.save_path = save_path
	saved.gems = 60
	saved.unlock_lab_slot()
	saved.unlock_lab_slot()
	_expect(saved.save(), "the slot save should write")
	var restored := GameState.new()
	restored.save_path = save_path
	restored.load()
	_expect(restored.lab_slots_total() == 3 and restored.gems == 0, "opened slots should survive a reload")
	restored.clear_save()

	# A V6 save predates bought slots: it keeps two, and becomes V7 at once.
	var v6: Dictionary = SaveDataV8.make(_funded_state())
	v6.version = 6
	v6.erase("lab_slots")
	_write_json(save_path, v6)
	var migrated := GameState.new()
	migrated.save_path = save_path
	migrated.load()
	_expect(migrated.lab_slots_total() == LabResearch.LEGACY_SLOTS, "a V6 save should keep its two Lab slots")
	_expect(int(_read_json(save_path).get("version", 0)) == SaveDataV8.VERSION and int(_read_json("res://.number_go_up_test_save.v6-backup.json").get("version", 0)) == 6, "a V6 save should be rewritten as V7, with the V6 file kept")
	migrated.clear_save()
	for stored in [99, -3, 0]:
		var odd: Dictionary = SaveDataV8.make(_funded_state())
		odd.lab_slots = stored
		_write_json(save_path, odd)
		var clamped := GameState.new()
		clamped.save_path = save_path
		clamped.load()
		_expect(clamped.lab_slots_total() >= LabResearch.STARTING_SLOTS and clamped.lab_slots_total() <= LabResearch.MAX_SLOTS, "a stored slot count should stay between one and five")
		clamped.clear_save()
	_expect(_leftover_save_files().is_empty(), "the slot checks should leave no file behind")

## D031: research that finishes during a run takes effect from the next one,
## so a run's power never changes with the wall clock and a seeded run replays
## identically however long research takes.
func _test_research_finished_mid_run_waits_for_the_next_run() -> void:
	var build := {"generator": 100, "automation_core": 50, "more_critical": 100}
	var outcomes := []
	for finish_mid_run in [false, true]:
		var state := _funded_state()
		state.purchased = build.duplicate()
		_expect(state.start_lab("lab_damage"), "the fixture should have Damage Research running")
		state.start_run(1, 42)
		for frame in range(1200):
			if finish_mid_run and frame == 600:
				# The clock passes the line's end mid-run, and the UI asks.
				state.lab_active["lab_damage"].started_unix = 0.0
				_expect(state.get_lab_owned("lab_damage") == 0 and state.lab_is_done_awaiting_run_end("lab_damage"), "a line finishing mid-run should wait, and say so")
			state.advance(1.0 / 60.0)
		outcomes.append([state.lifetime_generated.to_dict(), state.rng.state])
		state.end_run()
		if finish_mid_run:
			_expect(state.get_lab_owned("lab_damage") == 1 and not state.lab_active.has("lab_damage"), "the run's end should settle the finished line")
	_expect(outcomes[0] == outcomes[1], "a seeded run should produce the same output whether research finishes during it or not")

	# Research finished before a run starts counts for all of that run.
	var early := _funded_state()
	early.start_lab("lab_damage")
	early.lab_active["lab_damage"].started_unix = 0.0
	early.start_run(1, 3)
	_expect(early.get_lab_owned("lab_damage") == 1 and is_equal_approx(early._base_output_multiplier(), 1.01), "research finished before the run should count from its start")
	early.end_run()

	# A save taken mid-run keeps the finished line waiting through the reload.
	var save_path := "res://.number_go_up_test_save.json"
	var mid := _funded_state()
	mid.save_path = save_path
	mid.start_lab("lab_damage")
	mid.start_run(1, 3)
	mid.lab_active["lab_damage"].started_unix = 0.0
	mid.save()
	var resumed := GameState.new()
	resumed.save_path = save_path
	resumed.load()
	_expect(resumed.in_run and resumed.get_lab_owned("lab_damage") == 0 and is_equal_approx(resumed._base_output_multiplier(), 1.0), "a run resumed from a save should not gain research that finished while it was away")
	resumed.end_run()
	_expect(resumed.get_lab_owned("lab_damage") == 1, "the resumed run's end should settle the line")
	resumed.clear_save()

	# A clock set back never shows more time left than the line takes.
	var rewound := _funded_state()
	rewound.start_lab("lab_speed", 5000.0)
	var duration := float(rewound.lab_active["lab_speed"].duration)
	_expect(is_equal_approx(rewound.get_lab_time_remaining("lab_speed", 5000.0 - 3600.0), duration), "a clock set back should show the line's full time, not more")

func _test_lab_research_is_a_between_run_action() -> void:
	var state := _funded_state()
	state.start_run(1, 9)
	_expect(not state.can_start_lab("lab_damage"), "starting research mid-run should be refused, like a Workshop purchase")
	_expect(not state.start_lab("lab_damage"), "Labs should not spend Coins while a run is active")

func _test_finished_lab_research_applies_its_effect() -> void:
	var without := GameState.new()
	without.purchased.generator = 1
	var base_rate := without.get_rate_per_second()

	var with_lab := GameState.new()
	with_lab.purchased.generator = 1
	with_lab.lab_active["lab_damage"] = {"started_unix": 1000.0, "duration": 100.0}
	_expect(with_lab.get_lab_owned("lab_damage", 1101.0) == 1, "Damage Research should settle once its duration has passed")
	_expect(with_lab.get_rate_per_second().compare_to(base_rate) > 0, "a finished Damage Research rank should lift produced damage like a Workshop or Rig rank does")

func _test_lab_speed_shortens_other_lines_not_itself() -> void:
	var state := _funded_state()
	var plain_duration := state.get_lab_duration("lab_damage")
	state.lab_ranks["lab_speed"] = 10
	var discounted_duration := state.get_lab_duration("lab_damage")
	_expect(discounted_duration < plain_duration, "Lab Speed should shorten another line's duration")
	var expected := plain_duration * (1.0 - 10.0 * LabResearch.SPEED_DURATION_STEP)
	_expect(is_equal_approx(discounted_duration, expected), "the discount should match its documented per-rank step")
	var base_speed_duration: float = state.lab_research.duration_at(state.lab_research.get_definition("lab_speed"), state.get_lab_owned("lab_speed"), 0)
	_expect(is_equal_approx(state.get_lab_duration("lab_speed"), base_speed_duration), "Lab Speed must not discount itself, at whatever rank it holds")

func _test_lab_save_round_trip() -> void:
	var save_path := "res://.number_go_up_test_save.json"
	var original := _funded_state()
	original.save_path = save_path
	_expect(original.start_lab("lab_speed"), "the fixture should have Lab Speed researching")
	original.lab_ranks["lab_damage"] = 3
	var saved_active: Dictionary = original.lab_active["lab_speed"].duplicate(true)
	_expect(original.save(), "the Labs save should write")
	var restored := GameState.new()
	restored.save_path = save_path
	restored.load()
	_expect(restored.get_lab_owned("lab_damage") == 3, "a finished Labs rank should round-trip")
	_expect(restored.lab_is_active("lab_speed"), "an in-progress line should round-trip as still active")
	var remaining_at_save := restored.get_lab_time_remaining("lab_speed", float(saved_active.started_unix))
	_expect(is_equal_approx(remaining_at_save, float(saved_active.duration)), "the remaining time at the moment it was saved should round-trip exactly")
	restored.clear_save()

	# A save written before Labs existed resumes with none, and a malformed
	# Labs block reads as empty rather than crashing.
	var legacy: Dictionary = SaveDataV8.make(_funded_state())
	legacy.erase("lab_ranks")
	legacy.erase("lab_active")
	_write_json(save_path, legacy)
	var loaded := GameState.new()
	loaded.save_path = save_path
	loaded.load()
	_expect(loaded.lab_ranks.is_empty() and loaded.lab_active.is_empty(), "a pre-Labs save should resume with no Labs state")
	loaded.clear_save()
	legacy["lab_active"] = "garbage"
	_write_json(save_path, legacy)
	var malformed := GameState.new()
	malformed.save_path = save_path
	malformed.load()
	_expect(malformed.lab_active.is_empty(), "a malformed Labs block should read as empty, not crash")
	malformed.clear_save()

## D027: Cards are a permanent, Gem-pulled collection with a capped Active
## set. Only an Active card's effect counts; an owned-but-idle one in
## Inventory does not, unlike a Workshop or Lab rank which always applies.
func _test_card_definitions_are_common_and_rare() -> void:
	var state := GameState.new()
	var common: Array = state.card_collection.definitions_for_rarity(CardCollection.COMMON)
	var rare: Array = state.card_collection.definitions_for_rarity(CardCollection.RARE)
	_expect(not common.is_empty() and not rare.is_empty(), "the starting catalogue should hold both a common and a rare tier")
	_expect(state.card_collection.get_definition("card_damage") != null, "Damage should be a real card")
	_expect(state.card_collection.get_definition("nope") == null, "an unknown card id should not resolve")

func _test_card_pull_costs_gems_and_grants_a_level() -> void:
	var state := _funded_state()
	state.gems = 100
	_expect(state.can_pull_card(), "a pull should be affordable with Gems in hand")
	var gems_before := state.gems
	var drawn := state.pull_card()
	_expect(drawn != "", "an affordable pull should draw a card")
	_expect(state.card_collection.get_definition(drawn) != null, "the drawn id should be a real card")
	_expect(state.gems == gems_before - state.get_pull_cost(), "a pull should spend exactly its quoted Gem cost")
	_expect(state.get_card_level(drawn) == 1, "a first pull of a card should own it at level 1")
	_expect(not state.card_collection.get_definition(drawn).is_maxed(3), "level 3 of 7 should not read as maxed")
	_expect(state.card_collection.get_definition(drawn).is_maxed(CardCollection.MAX_LEVEL), "level 7 should read as maxed")

func _test_card_pull_is_a_between_run_action() -> void:
	var state := _funded_state()
	state.gems = 100
	state.start_run(1, 3)
	_expect(not state.can_pull_card() and state.pull_card() == "", "pulling mid-run should be refused, like a Workshop purchase")

func _test_card_pull_never_exceeds_max_level() -> void:
	var state := _funded_state()
	state.gems = 100000
	state.card_ranks["card_damage"] = CardCollection.MAX_LEVEL
	var gems_before := state.gems
	# Enough pulls that a maxed card is drawn at least once with near
	# certainty (~17.5% per pull, one of four commons); the contract is that
	# no level can ever pass MAX_LEVEL, drawn or not.
	for i in range(200):
		state.pull_card()
	_expect(state.get_card_level("card_damage") == CardCollection.MAX_LEVEL, "a maxed card should never level past its cap")
	_expect(state.gems < gems_before, "pulls should still spend Gems even when a maxed card is drawn")

func _test_card_equip_respects_slot_cap_and_run_state() -> void:
	var state := _funded_state()
	for id in ["card_damage", "card_attack_speed", "card_coins", "card_critical_chance"]:
		state.card_ranks[id] = 1
	_expect(state.card_slots_total() == CardCollection.ACTIVE_SLOTS, "the slot cap should match the catalogue's constant")
	for id in ["card_damage", "card_attack_speed", "card_coins", "card_critical_chance"]:
		_expect(state.equip_card(id), "an owned card should equip while a slot is free")
	_expect(state.active_card_count() == state.card_slots_total(), "every slot should now be in use")
	state.card_ranks["card_health"] = 1
	_expect(not state.can_equip_card("card_health") and not state.equip_card("card_health"), "a full Active set should refuse another card")
	_expect(state.unequip_card("card_damage"), "an equipped card should unequip, freeing its slot")
	_expect(state.equip_card("card_health"), "unequipping should free a slot for another card")
	_expect(state.get_card_level("card_damage") == 1, "unequipping must not touch the card's owned level")
	state.start_run(1, 4)
	_expect(not state.can_equip_card("card_damage"), "equipping mid-run should be refused, like a Workshop purchase")
	_expect(not state.unequip_card("card_coins"), "unequipping mid-run should also be refused")

func _test_active_card_applies_its_effect_but_inventory_does_not() -> void:
	var without := GameState.new()
	without.purchased.generator = 1
	var base_rate := without.get_rate_per_second()

	var owned_only := GameState.new()
	owned_only.purchased.generator = 1
	owned_only.card_ranks["card_damage"] = 3
	_expect(owned_only.get_rate_per_second().compare_to(base_rate) == 0, "an owned-but-inactive card should not affect production")

	var active := GameState.new()
	active.purchased.generator = 1
	active.card_ranks["card_damage"] = 3
	active.card_active.append("card_damage")
	_expect(active.get_rate_per_second().compare_to(base_rate) > 0, "an Active card should lift produced damage like a Workshop or Lab rank does")

func _test_card_save_round_trip() -> void:
	var save_path := "res://.number_go_up_test_save.json"
	var original := _funded_state()
	original.save_path = save_path
	original.gems = 42
	original.card_ranks = {"card_damage": 3, "card_coins": 1}
	original.card_active = ["card_damage"]
	_expect(original.save(), "the Cards save should write")
	var restored := GameState.new()
	restored.save_path = save_path
	restored.load()
	_expect(restored.gems == 42, "Gems should round-trip")
	_expect(restored.get_card_level("card_damage") == 3 and restored.get_card_level("card_coins") == 1, "card levels should round-trip")
	_expect(restored.is_card_active("card_damage") and not restored.is_card_active("card_coins"), "the Active set should round-trip")
	restored.clear_save()

	# A save written before Cards existed resumes with none, and a malformed
	# block reads as empty rather than crashing.
	var legacy: Dictionary = SaveDataV8.make(_funded_state())
	legacy.erase("gems")
	legacy.erase("card_ranks")
	legacy.erase("card_active")
	_write_json(save_path, legacy)
	var loaded := GameState.new()
	loaded.save_path = save_path
	loaded.load()
	_expect(loaded.gems == 0 and loaded.card_ranks.is_empty() and loaded.card_active.is_empty(), "a pre-Cards save should resume with no Cards state")
	loaded.clear_save()
	legacy["card_active"] = "garbage"
	legacy["card_ranks"] = "garbage"
	_write_json(save_path, legacy)
	var malformed := GameState.new()
	malformed.save_path = save_path
	malformed.load()
	_expect(malformed.card_ranks.is_empty() and malformed.card_active.is_empty(), "a malformed Cards block should read as empty, not crash")
	malformed.clear_save()
	# An Active list naming an id outside the catalogue, or repeating one,
	# should be sanitised rather than trusted wholesale.
	legacy["card_ranks"] = {"card_damage": 1}
	legacy["card_active"] = ["card_damage", "not_a_real_card", "card_damage"]
	_write_json(save_path, legacy)
	var sanitised := GameState.new()
	sanitised.save_path = save_path
	sanitised.load()
	_expect(sanitised.card_active == ["card_damage"], "an Active list should drop unknown ids and duplicates")
	sanitised.clear_save()
	# An Active list beyond the slot cap should be truncated to it, not
	# trusted past what equip_card would ever have allowed.
	legacy["card_ranks"] = {"card_damage": 1, "card_attack_speed": 1, "card_coins": 1, "card_critical_chance": 1, "card_health": 1}
	legacy["card_active"] = ["card_damage", "card_attack_speed", "card_coins", "card_critical_chance", "card_health"]
	_write_json(save_path, legacy)
	var overfull := GameState.new()
	overfull.save_path = save_path
	overfull.load()
	_expect(overfull.card_active.size() == CardCollection.ACTIVE_SLOTS, "an Active list beyond the slot cap should be truncated to it on load")
	overfull.clear_save()

## D023: one Rig rank is worth a multiple of a Workshop rank, because the
## Number it spends was the buffer against the next hit. Burst is the one row
## that stays one-for-one: its ranks are tick-interval steps, not magnitudes.
func _test_rig_ranks_are_worth_more_than_workshop_ranks() -> void:
	var state := _funded_state()
	state.purchased = {"stronger_tap": 10}
	state.start_run(1, 12)
	state.number = ScientificNumber.from_float(1.0e12)
	var before := state._tap_base()
	var multiplier: float = state.balance_profile.rig_effect_multiplier(ProgressionTaxonomy.ATTACK, "stronger_tap")
	_expect(multiplier > 1.0, "a Rig rank should be worth more than a Workshop rank")
	_expect(state.purchase_rig("stronger_tap"), "the Rig rank should buy")
	_expect(is_equal_approx(state._tap_base(), before + 0.05 * multiplier), "one Rig rank should grant its multiplier of a Workshop rank's effect")
	_expect(state.purchase_rig("burst_relay"), "a Rig Burst rank should buy")
	_expect(state._burst_interval() == 11, "a Rig Burst rank should shorten the interval by one step, not by its multiplier")

## D023: the combined defensive effects are bounded, so an uncapped Rig cannot
## turn a run immortal.
func _test_defensive_ceilings_bound_the_combined_effects() -> void:
	var state := _funded_state()
	state.start_run(1, 13)
	state.purchased = {GameState.ARMOR_ID: 100, "siphon": 100, "recoil": 100}
	state.number = ScientificNumber.new(1.0, 40)
	for rank in range(200):
		state.purchase_rig(GameState.ARMOR_ID)
		state.purchase_rig("siphon")
		state.purchase_rig("recoil")
	_expect(state._effect_sum("collection_resistance") > state.balance_profile.COLLECTION_RESISTANCE_CEILING, "the fixture should stack Armor past its ceiling")
	state.wave = 30
	state.active_encounter = state._make_encounter(30)
	var base: ScientificNumber = state.active_encounter.collection.copy()
	var effective := state.get_effective_collection()
	_expect(effective.compare_to(base.multiply_scalar(1.0 - state.balance_profile.COLLECTION_RESISTANCE_CEILING)) == 0, "a hit should never fall below the combined Armor ceiling")
	_expect(not effective.is_zero(), "the ceiling keeps hits real, not free")

	# Siphon: the applied share is capped even when the ranks stack past it.
	_expect(state._effect_sum("siphon_share") > state.balance_profile.SIPHON_CEILING, "the fixture should stack Siphon past its ceiling")
	state.number = ScientificNumber.new()
	state._add_number(ScientificNumber.from_float(100))
	_expect(state.number.compare_to(ScientificNumber.from_float(100.0 * state.balance_profile.SIPHON_CEILING)) == 0, "Siphon should bank exactly the capped share")

	# Recoil: a hit can never be returned more than once over.
	_expect(state._effect_sum("recoil_share") > state.balance_profile.RECOIL_CEILING, "the fixture should stack Recoil past its ceiling")
	var liability_before: ScientificNumber = state.active_encounter.remaining_liability.copy()
	var hit := state.get_effective_collection()
	state.number = ScientificNumber.new(1.0, 40)
	state._resolve_wave_boundary()
	var dealt := liability_before.subtract(state.active_encounter.remaining_liability)
	_expect(dealt.compare_to(hit) == 0, "Recoil should deal back exactly the hit, never more")

func _advance_seconds(state: GameState, seconds: float) -> void:
	var elapsed := 0.0
	while elapsed < seconds:
		state.advance(0.25)
		elapsed += 0.25

func _write_json(path: String, value: Dictionary) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(value))

func _write_text(path: String, text: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(text)

func _read_json(path: String) -> Dictionary:
	var json := JSON.new()
	if not FileAccess.file_exists(path) or json.parse(FileAccess.get_file_as_string(path)) != OK or not (json.data is Dictionary):
		return {}
	return json.data

## Every test save file still on disk; a test that leaves one is a bug.
func _leftover_save_files() -> Array:
	var leftovers := []
	var directory := DirAccess.open("res://")
	if directory != null:
		directory.include_hidden = true
		for file_name in directory.get_files():
			if file_name.begins_with(".number_go_up_test_save"):
				leftovers.append(file_name)
	return leftovers

func _funded_state() -> GameState:
	var state := GameState.new()
	state.coins = 1000000
	state.number = ScientificNumber.from_float(1000000)
	state.lifetime_generated = ScientificNumber.from_float(1000000)
	return state
