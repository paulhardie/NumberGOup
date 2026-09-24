extends SceneTree

const RuleModifierPipelineClass = preload("res://src/rule_modifier_pipeline.gd")
const GameDataClass = preload("res://src/game_data.gd")

var failures := 0

func _init() -> void:
	_test_scientific_number()
	_test_category_gates_and_rank_caps()
	_test_research_focus_targets_a_category()
	_test_multi_buy_matches_buying_one_at_a_time()
	_test_workshop_price_onramp()
	_test_stat_values_read_the_row_effect()
	_test_deepened_ladders_keep_their_old_maxima()
	_test_every_ladder_reaches_its_d047_maximum()
	_test_multishot_marks_two_shots()
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
	_test_a_wave_is_a_group()
	_test_group_members_land_one_by_one()
	_test_group_brace_guard_and_thorns()
	_test_group_saves_and_resumes()
	_test_members_stay_and_the_pile_grows()
	_test_tower_shaped_bosses_and_heat_up()
	_test_opening_members_pass()
	_test_d058_opening_save_reconciles()
	_test_output_is_number_and_strikes_the_wave()
	_test_repeated_taps_count_once()
	_test_missed_waves_move_on_and_bosses_stay()
	_test_beaten_wave_gives_way_after_the_minimum_beat()
	_test_missed_checkpoint_pays_when_passed()
	_test_mid_wave_save_resumes_identically()
	_test_collection_is_absolute()
	_test_boss_axes_and_rewards()
	_test_brace_blocks_next_collection()
	_test_armor_reduces_the_hit_and_survives_reset()
	_test_leech_feeds_on_a_standing_boss()
	_test_thorns_deal_the_hit_to_the_wave_in_front()
	_test_brace_cost_falls_to_its_floor()
	_test_second_wind_forgives_one_ending_hit()
	_test_cushion_scales_with_the_tier()
	_test_boss_damage_applies_only_to_bosses()
	_test_coin_and_knowledge_bonuses_lift_what_a_run_pays()
	_test_rig_cost_is_quoted_in_seconds_of_income()
	_test_rig_purchase_spends_cash_and_stacks()
	_test_rig_multi_buy_quotes_and_spends()
	_test_rig_stops_at_the_rows_max_rank()
	_test_rig_is_run_scoped()
	_test_rig_refuses_what_it_does_not_sell()
	_test_rig_save_round_trip()
	_test_cash_flows_at_the_priced_income()
	_test_rig_cushion_pays_its_number_now()
	_test_rig_discount_bulk_matches_singles()
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
	_test_card_pull_duplicate_protection()
	_test_card_equip_respects_slot_cap_and_run_state()
	_test_active_card_applies_its_effect_but_inventory_does_not()
	_test_card_save_round_trip()
	_test_defensive_ceilings_bound_the_combined_effects()
	_test_armor_ceiling_bounds_armor_not_other_rules()
	_test_guard_flat_reduction_and_floor()
	_test_game_data_loads_cleanly()
	_test_catalogues_are_internally_consistent()
	_test_loaded_ranks_stay_within_their_caps()
	_test_v8_save_migrates_to_v9()
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
	_expect(not state.is_unlocked(state.get_definition("faster_cadence")), "Attack Speed should wait for its Workshop level")
	_expect(state.purchase("stronger_tap"), "Tap Damage rank one should purchase")
	_expect(state.purchase_ranks("stronger_tap", 11) == 11, "eleven more Tap Damage ranks should purchase")
	_expect(state.is_unlocked(state.get_definition("faster_cadence")), "Attack Speed should open at Workshop level 12")
	_expect(not state.is_unlocked(state.get_definition("more_critical")), "Crit Chance should still be shut at Workshop level 12")
	state.purchased.stronger_tap = 30
	_expect(state.is_unlocked(state.get_definition("more_critical")), "Crit Chance should open at Workshop level 30")
	state.purchased.stronger_tap = 60
	_expect(state.is_unlocked(state.get_definition("smarter_efficiency")), "Discount should open at Workshop level 60")
	state.purchased.stronger_tap = state.get_definition("stronger_tap").max_rank
	_expect(not state.can_purchase("stronger_tap"), "the rank cap should stop Tap Damage at its last rank")
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
	var cap: int = capped.get_definition("generator_two").max_rank
	_expect(capped.purchase_ranks("generator_two", cap * 2) == cap, "a press larger than the rank cap should stop at the cap")
	_expect(capped.purchase_ranks("generator_two", GameState.MAX_BUY) == 0, "a maxed row should refuse a further press")

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

	# Quotes come from cached running totals (D047); a Discount rank changes
	# every price, so the next quote must use the new ones.
	var discounted := _funded_state()
	discounted.coins = 100000
	var before_discount := int(discounted.plan_purchase("generator", 5).cost)
	discounted.purchased["smarter_efficiency"] = 20
	var singles := 0
	for rank in range(5):
		singles += discounted.get_workshop_coin_cost_at(discounted.get_definition("generator"), rank)
	var after_discount := int(discounted.plan_purchase("generator", 5).cost)
	_expect(after_discount < before_discount and after_discount == singles, "a quote should follow a new Discount rank at once")
	var focused := _funded_state()
	focused.coins = 100000
	var before_focus := int(focused.plan_purchase("generator", 5).cost)
	focused.focus_path = ProgressionTaxonomy.ATTACK
	var focus_singles := 0
	for rank in range(5):
		focus_singles += focused.get_workshop_coin_cost_at(focused.get_definition("generator"), rank)
	var after_focus := int(focused.plan_purchase("generator", 5).cost)
	_expect(after_focus < before_focus and after_focus == focus_singles, "a quote should follow a Research Focus choice at once")

	var deep := _funded_state()
	deep.purchased = {"stronger_tap": 2000}
	deep.coins = 10000000
	var deep_singles := 0
	var deep_tap := deep.get_definition("stronger_tap")
	for rank in range(2000, 2040):
		deep_singles += deep.get_workshop_coin_cost_at(deep_tap, rank)
	var deep_plan := deep.plan_purchase("stronger_tap", 40)
	_expect(int(deep_plan.ranks) == 40 and int(deep_plan.cost) == deep_singles, "a deep-row press should quote exactly what single presses cost")

	var locked := _funded_state()
	_expect(int(locked.plan_purchase("faster_cadence", 5).ranks) == 0, "a row below its Workshop level should quote nothing")
	var running := _funded_state()
	running.start_run(1, 3)
	_expect(int(running.plan_purchase("stronger_tap", 5).ranks) == 0, "a run should refuse a Workshop press of any size")

func _test_workshop_price_onramp() -> void:
	var state := GameState.new()
	var tap := state.get_definition("stronger_tap")
	var damage_per_second := state.get_definition("generator")
	var armor := state.get_definition(GameState.ARMOR_ID)
	_expect(state.get_workshop_coin_cost(tap) == 2 and state.get_workshop_coin_cost(damage_per_second) == 2 and state.get_workshop_coin_cost(armor) == 4, "the opening Attack and Defense ranks should be cheap")
	_expect(state.get_workshop_coin_cost_at(tap, 20) == 4 and state.get_workshop_coin_cost_at(tap, 99) == 84, "Tap Damage should rise smoothly through its cap")
	_expect(state.get_workshop_coin_cost_at(armor, 20) == 9 and state.get_workshop_coin_cost_at(armor, 99) == 224, "Armor should have an affordable start and a meaningful late price")
	var category_totals := {ProgressionTaxonomy.ATTACK: 0, ProgressionTaxonomy.DEFENSE: 0, ProgressionTaxonomy.UTILITY: 0}
	for definition in state.definitions:
		if definition.category != ProgressionTaxonomy.WORKSHOP:
			continue
		for rank in range(definition.max_rank):
			category_totals[definition.workshop_category] += state.get_workshop_coin_cost_at(definition, rank)
	_expect(category_totals[ProgressionTaxonomy.ATTACK] == 22415267 and category_totals[ProgressionTaxonomy.DEFENSE] == 12297232 and category_totals[ProgressionTaxonomy.UTILITY] == 2305008, "the full Workshop should keep the authored category prices")
	state.coins = 48
	_expect(state.purchase_ranks("stronger_tap", 12) == 12, "a first run should fund twelve Tap Damage ranks")
	_expect(state.purchase_ranks("generator", 6) == 6, "a first run should also fund six Damage ranks")
	_expect(state.purchase(GameState.ARMOR_ID) and state.coins == 1, "a first run should still afford an Armor rank with one Coin left")
	_expect(state.start_run(1, 7) and state._tap_base() > 1.5 and state._passive_base() * state._tick_rate() > 0.4, "the next run should feel the permanent Attack purchases")

## The card face is derived from the row's own effect, so it cannot drift from
## what the rank actually does.
func _test_stat_values_read_the_row_effect() -> void:
	var state := _funded_state()
	var tap := state.get_definition("stronger_tap")
	_expect(is_equal_approx(float(state.stat_display(tap, 0).value), 1.0), "Tap Damage at rank zero should read as the base tap")
	var tap_at_100: Dictionary = state.stat_display(tap, 100)
	_expect(is_equal_approx(float(tap_at_100.value), 6.0) and str(tap_at_100.unit) == "flat", "Tap Damage should still reach six at rank 100, one rank at a time (D047)")
	_expect(float(state.stat_display(tap, 101).value) > 6.05, "past rank 100 a Tap Damage rank should add more than one step (D047)")
	state.purchased = {"stronger_tap": tap.max_rank}
	_expect(is_equal_approx(float(state.stat_display(tap, tap.max_rank).value), state._tap_base()), "the card value should equal what the rank actually grants, deep ranks included")

	var multiplier := state.get_definition("generator_two")
	var at_cap: Dictionary = state.stat_display(multiplier, multiplier.max_rank)
	_expect(str(at_cap.unit) == "multiplier" and is_equal_approx(float(at_cap.value), pow(1.15, 3)), "Damage Multiplier should still compound to its old cap")
	state.purchased = {"generator_two": multiplier.max_rank}
	_expect(is_equal_approx(float(state.stat_display(multiplier, multiplier.max_rank).value), state._base_output_multiplier()), "the compounding card value should equal the applied multiplier")

	var armor_def := state.get_definition(GameState.ARMOR_ID)
	var armor: Dictionary = state.stat_display(armor_def, armor_def.max_rank)
	_expect(str(armor.unit) == "percent" and is_equal_approx(float(armor.value), 0.5), "Armor should read as 50% at its rank cap (D047)")
	_expect(is_equal_approx(float(state.stat_display(tap, 1).value), 1.05), "one rank should move the card face, not round away")
	var burst: Dictionary = state.stat_display(state.get_definition("burst_relay"), 2)
	_expect(str(burst.unit) == "rank" and is_equal_approx(float(burst.value), 2.0), "a row with no declared effect should fall back to its rank")
	# D054, D055: the Attack Speed row carries the base shots a second, so it
	# reads as shots a second; the card stacked on it is still a multiplier.
	var speed_row := state.get_definition("faster_cadence")
	_expect(str(state.stat_display(speed_row, 0).unit) == "per_second" and is_equal_approx(float(state.stat_display(speed_row, 0).value), 2.5), "Attack Speed should read as 2.5 shots a second before any rank (D055)")
	var speed: Dictionary = state.stat_display(speed_row, 100)
	_expect(absf(float(speed.value) - 14.87) < 0.01, "Attack Speed should read as about 14.87 shots a second at rank 100")
	_expect(str(state.card_stat_display("card_attack_speed", 1).unit) == "multiplier", "the Attack Speed card should still read as a multiplier")

## D054: Multishot fires the same shot twice. The tick lands as one amount,
## twice the plain shot, and the event says it was two shots so the arena can
## show both.
func _test_multishot_marks_two_shots() -> void:
	var state := _funded_state()
	state.purchased = {"generator": 20, "faster_echo": 125}
	state.start_run(1, 5)
	state.rng.seed = 5
	var single := ScientificNumber.new()
	var double := ScientificNumber.new()
	for tick in range(40):
		var event := state._produce_tick()
		_expect(event.hits == 1 or event.hits == 2, "a shot event should carry one or two shots")
		if event.hits == 1:
			single = event.amount
		else:
			double = event.amount
	_expect(not single.is_zero() and double.compare_to(single.multiply_scalar(2.0)) == 0, "a Multishot tick should deal exactly two shots' damage")
	var plain := _funded_state()
	plain.purchased = {"generator": 20}
	plain.start_run(1, 5)
	for tick in range(40):
		_expect(plain._produce_tick().hits == 1, "without Multishot every tick should be one shot")
	# D055: a fresh run fires 2.5 shots a second before any Attack Speed.
	var fresh := _funded_state()
	fresh.start_run(1, 5)
	var shots := 0
	for step in range(40):
		shots += fresh.advance(0.1).filter(func(event): return event.type == "tick").size()
	_expect(shots == 10, "a fresh run should fire 10 shots in 4 seconds: %d" % shots)

## D047: the deep rows keep today's value for ranks 1-100, so every rank a
## player owns keeps its worth, and past 100 follow their depth curves.
func _test_deepened_ladders_keep_their_old_maxima() -> void:
	var state := _funded_state()
	state.purchased = {"stronger_tap": 100, "generator": 100, "guard": 100, "automation_core": 50}
	_expect(is_equal_approx(state._tap_base(), 6.0), "Tap Damage at rank 100 should still be six")
	_expect(is_equal_approx(state._passive_base(), 5.0), "Damage at 100 plus Auto Crank should be 5 a shot (D055)")
	# D055 shares the old per-second damage across 2.5 times the shots, so the
	# damage a second is what it was: 12.5 a tick at 1 a second, plus the base.
	_expect(is_equal_approx(state.get_rate_per_second().mantissa * pow(10.0, state.get_rate_per_second().exponent), 12.5 + state.balance_profile.BASE_DAMAGE_PER_SECOND), "more, smaller shots should keep the damage a second (D055)")
	_expect(is_equal_approx(state._effect_sum("guard_flat"), 100.0), "Guard at rank 100 should still take 100 off")

## D047: every row's value at its cap. The deep rows follow their depth curves
## to The Tower's shape; the capped rows reach The Tower's maxima where a twin
## exists and keep today's where it does not.
func _test_every_ladder_reaches_its_d047_maximum() -> void:
	var state := _funded_state()
	for definition in state.definitions:
		if definition.category == ProgressionTaxonomy.WORKSHOP:
			state.purchased[definition.id] = definition.max_rank
	_expect(state.get_definition("stronger_tap").max_rank == 6000 and state.get_definition("generator").max_rank == 6000 and state.get_definition("guard").max_rank == 5000, "Tap Damage and Damage should run to 6,000 ranks and Guard to 5,000")
	_expect(is_equal_approx(state._tap_base(), 1.0 + 0.05 * 100.0 * 67500.0), "Tap Damage should cap at 67,500 times its rank-100 bonus")
	_expect(is_equal_approx(state._passive_base(), 0.03 * 100.0 * 67500.0 + 2.0), "Damage should cap at 67,500 times its rank-100 bonus, plus Auto Crank")
	_expect(is_equal_approx(state._effect_sum("guard_flat"), 100.0 * 79000.0), "Guard should cap at 79,000 times its rank-100 reduction")
	_expect(is_equal_approx(state._base_output_multiplier(), pow(1.15, 3)), "Damage Multiplier should keep its cap")
	_expect(absf(state._tick_rate() - 2.5 * 5.95) < 0.02, "Attack Speed should cap at x5.95 on its 2.5-a-second base")
	_expect(is_equal_approx(state._critical_chance(), 0.8), "Crit Chance should cap at 80%")
	_expect(absf(state._critical_multiplier() - 16.2) < 0.01, "Crit Damage should cap at about x16.2")
	_expect(is_equal_approx(state._chain_reaction_step(), 0.3), "Crit Chain should keep its 30% per link")
	_expect(is_equal_approx(state._effect_sum("double_tick_chance"), 0.5), "Multishot should cap at 50%")
	_expect(is_equal_approx(state._effect_sum("cost_discount"), 0.15), "Discount should keep its 15%")
	_expect(is_equal_approx(state._effect_sum("collection_resistance"), 0.5), "Armor should cap at 50%")
	_expect(is_equal_approx(state._effect_sum("starting_number_flat"), 1500.0), "Cushion should cap at 1,500 Number")
	_expect(state._burst_interval() == 6, "Burst should still bottom out at every sixth tick")
	_expect(is_equal_approx(state._effect_sum("siphon_share"), 0.25), "Leech should keep a quarter of the damage dealt")
	_expect(is_equal_approx(state._effect_sum("recoil_share"), 0.99), "Thorns should cap at 99% of an enemy's maximum HP, as The Tower's does")
	_expect(is_equal_approx(state.get_brace_cost_percent(), GameState.BRACE_COST_FLOOR), "Brace Cost should cap at its floor")
	_expect(is_equal_approx(state._effect_sum("second_wind_share"), 0.3), "Second Wind should cap at 30% of the run's peak")
	_expect(is_equal_approx(state._effect_sum("boss_damage"), 1.0), "Boss Damage should keep double damage against bosses")
	_expect(is_equal_approx(state._effect_sum("coin_bonus"), 1.5), "Coin Bonus should cap at x2.5")
	_expect(is_equal_approx(state._effect_sum("knowledge_bonus"), 0.5), "Knowledge Bonus should keep half again")
	var tap := state.get_definition("stronger_tap")
	_expect(is_equal_approx(tap.units_at(100.0), 100.0) and is_equal_approx(tap.units_at(250.0), 500.0) and is_equal_approx(tap.units_at(175.0), 300.0), "a depth curve should run in straight lines between its anchors")
	for definition in state.definitions:
		if definition.depth_curve.is_empty():
			continue
		var worst := INF
		var last_gain := 0.0
		for rank in range(1, definition.max_rank + 1):
			var gain := definition.units_at(float(rank)) - definition.units_at(float(rank - 1))
			worst = minf(worst, gain - last_gain)
			last_gain = gain
		_expect(worst > -1.0e-6, "every %s rank should be worth at least the one before it" % definition.id)
	for definition in state.definitions:
		if definition.deep_cost_growth <= 0.0:
			continue
		var from := definition.deep_price_from
		var kept := definition.cost.multiply_scalar(pow(definition.cost_growth, from))
		_expect(definition.cost_at(from).compare_to(kept) == 0, "%s should keep its old price up to rank %d" % [definition.id, from])
		var ratio := pow(10.0, definition.cost_at(from + 1).log10() - definition.cost_at(from).log10())
		_expect(is_equal_approx(ratio, definition.deep_cost_growth), "%s should switch to its deep growth after rank %d" % [definition.id, from])

func _test_workshop_effects() -> void:
	var state := _funded_state()
	# The same fractions of each ladder the three-rank build used to hold.
	state.purchased = {"stronger_tap": 40, "generator": 40, "generator_two": 20, "faster_cadence": 20, "faster_echo": 20, "more_critical": 20, "magnitude_coil": 20, "smarter_efficiency": 20}
	state.rng.seed = 11
	state.start_run(1, 11)
	var event := state.tap()
	_expect(event.amount.compare_to(ScientificNumber.from_float(3.45)) == 0, "Tap Damage and Damage Multiplier should affect taps")
	# Damage x Multiplier x Attack Speed, plus the flat output every run has (D033).
	var rate := state.get_rate_per_second()
	var expected_rate: float = 3.0 * pow(1.00701257, 20) * pow(1.01799, 20) + state.balance_profile.BASE_DAMAGE_PER_SECOND
	_expect(absf(rate.mantissa * pow(10.0, rate.exponent) - expected_rate) < 0.0001, "Workshop output and speed should affect rate")
	_expect(is_equal_approx(state._effect_sum("cost_discount"), 0.05), "twenty Discount ranks should still be a 5% discount")
	_expect(state.get_workshop_coin_cost(state.get_definition("generator")) == 10, "Discount should reduce permanent Coin costs")
	_expect(is_equal_approx(state._critical_chance(), 0.16), "Crit Chance should add positive critical chance")
	_expect(is_equal_approx(state._critical_multiplier(), 2.0 + 20.0 * 0.0947), "Crit Damage should add critical size")

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
	_expect(state.number.compare_to(ScientificNumber.from_float(500 + state.balance_profile.starting_number(1))) == 0, "Cushion should define the fresh-run Number baseline")
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
	var v4: Dictionary = SaveDataV11.make(v4_source)
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
		if checkpoint <= GameState.TIER_UNLOCK_WAVE:
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
	_expect(int(_read_json(save_path).get("version", 0)) == SaveDataV11.VERSION, "the rewritten save should carry the current version")
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
	var future: Dictionary = SaveDataV11.make(_funded_state())
	future.version = SaveDataV11.VERSION + 1
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
	_write_json(backup_path, SaveDataV11.make(good))
	var torn := JSON.stringify(SaveDataV11.make(_funded_state()))
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
	var typed_wrong: Dictionary = SaveDataV11.make(_funded_state())
	typed_wrong.purchased = "not a dictionary"
	# Cash is read only while a run is saved, so the bad value sits in one.
	var cash_wrong: Dictionary = SaveDataV11.make(_funded_state())
	cash_wrong.in_run = true
	cash_wrong.cash = "not a number"
	var earned_wrong: Dictionary = SaveDataV11.make(_funded_state())
	earned_wrong.in_run = true
	earned_wrong.run_cash_earned = {"exponent": 0, "mantissa": "lots"}
	var not_finite := JSON.stringify(SaveDataV11.make(_funded_state())).replace('"highest":{"exponent":0,"mantissa":0.0}', '"highest":{"exponent":0,"mantissa":1e999}')
	for unreadable in [JSON.stringify(typed_wrong), JSON.stringify(cash_wrong), JSON.stringify(earned_wrong), not_finite, "{", ""]:
		_write_text(save_path, unreadable)
		var fresh := GameState.new()
		fresh.save_path = save_path
		fresh.load()
		_expect(fresh.load_status == GameState.LOAD_UNREADABLE and fresh.coins == 0 and not fresh.in_run, "an unreadable save with no backup should start a fresh game")
		_expect(not FileAccess.file_exists(save_path) and _leftover_save_files().size() == 1, "the unreadable save should be moved aside rather than left to be written over")
		fresh.clear_save()

	# A live save that vanished between the two renames of a save still has its
	# backup.
	_write_json(backup_path, SaveDataV11.make(good))
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
	var v5: Dictionary = SaveDataV11.make(source)
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
	_expect(int(_read_json(save_path).get("version", 0)) == SaveDataV11.VERSION, "a V5 save should be rewritten in the current shape at once")
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
	var profile = state.balance_profile
	var expected := profile.milestone_bonus(1, 10)
	for completed_wave in range(1, 21):
		expected += profile.reward_for_wave(1, completed_wave)
		state.active_encounter.remaining_liability = ScientificNumber.new()
		state._resolve_wave_boundary()
	# D040: every wave pays 0.65 x its number from wave 1 (bosses x5), plus the
	# wave 10 checkpoint bonus, so a first run to wave 20 funds real ranks.
	_expect(state.coins == expected and state.coins > 100, "clearing Tier 1 to wave 20 should pay every wave's Coins and the wave 10 bonus")
	state.end_run()
	var before := state.coins
	var tap_price := state.get_workshop_coin_cost(state.get_definition("stronger_tap"))
	var dps_price := state.get_workshop_coin_cost(state.get_definition("generator"))
	_expect(state.purchase("stronger_tap"), "first-run Coins should buy a permanent Tap Damage rank")
	_expect(state.purchase("generator"), "first-run Coins should also buy the first Damage rank")
	_expect(state.coins == before - tap_price - dps_price, "first Workshop purchases should spend Coins, not Number")
	# A deepened ladder (D019) should turn the first run into a visible stack of
	# ranks rather than the two the five-rank ladders allowed.
	_expect(state.purchase_ranks("stronger_tap", GameState.MAX_BUY) >= 8, "the first failed run should fund a stack of ranks")
	state.start_run(1, 8)
	_expect(state._tap_base() > 1.0 and state._passive_base() > 0.0, "the next run should start from the upgraded permanent baseline")

## D040: Tier 1 runs one set of rules from wave 1. Every run has a flat base
## output that upgrades do not raise; a Tier 1 run starts with 50 Number; Wave
## HP follows one smooth curve, a Hit is 20% of its wave's HP at wave 1 rising
## evenly to 60% by wave 30, a boss is x3 HP
## and x1.5 Hit, and Coins are 0.65 x the wave (x5 on a boss).
func _test_tier_one_opening() -> void:
	var fresh := GameState.new()
	fresh.start_run(1, 3)
	var profile = fresh.balance_profile
	_expect(fresh.get_rate_per_second().compare_to(ScientificNumber.from_float(profile.BASE_DAMAGE_PER_SECOND)) == 0, "a fresh run should produce from its first second")
	_expect(fresh.number.compare_to(ScientificNumber.from_float(50.0)) == 0 and is_equal_approx(profile.starting_number(1), 50.0), "a Tier 1 run should start with 50 Number")
	var multiplied := GameState.new()
	multiplied.purchased = {"generator_two": 60}
	multiplied.start_run(1, 3)
	_expect(multiplied.get_rate_per_second().compare_to(fresh.get_rate_per_second()) == 0, "upgrades should not raise the flat base output")
	var tier_two := GameState.new()
	tier_two.tier_records["1"].highest_wave = GameState.TIER_UNLOCK_WAVE
	tier_two.start_run(2, 3)
	_expect(tier_two.number.is_zero(), "Tier 2 should start with no extra Number")

	# One curve from wave 1: below wave 100, no ordinary wave's HP or Hit is
	# ever more than 1.6 times the ordinary wave before it (the Hit climbs
	# fastest early, as its share grows). The wave-21 spike D040 removed was
	# 3x HP and 30x Hit in five waves. Milestone steps land on boss waves, so
	# neighbours are compared across them; wave 100's x1.5 step is the tier
	# gate and is deliberate.
	var previous := 0
	for check_wave in range(1, 101):
		if profile.is_boss_wave(check_wave):
			continue
		var hp := profile.liability_for_wave(1, check_wave)
		var hit := profile.collection_for_wave(1, check_wave)
		_expect(hit.compare_to(ScientificNumber.new()) > 0, "an ordinary Hit should be positive (wave " + str(check_wave) + ")")
		if previous > 0 and check_wave < 100:
			var growth := pow(10.0, hp.log10() - profile.liability_for_wave(1, previous).log10())
			var hit_growth := pow(10.0, hit.log10() - profile.collection_for_wave(1, previous).log10())
			_expect(growth > 1.0 and growth < 1.6, "Wave HP should rise smoothly from wave " + str(previous) + " to " + str(check_wave))
			_expect(hit_growth > 1.0 and hit_growth < 1.6, "the Hit should rise smoothly from wave " + str(previous) + " to " + str(check_wave))
		previous = check_wave
	_expect(profile.liability_for_wave(1, 21).compare_to(profile.liability_for_wave(1, 19)) > 0 and pow(10.0, profile.liability_for_wave(1, 21).log10() - profile.liability_for_wave(1, 19).log10()) < 1.4, "wave 21 should no longer jump")
	# D063: the Hit is the wave's HP divided by a ratio on The Tower's shape,
	# which grows with the wave: about 2.4 at wave 1, 11 at 100, 118 at 500 and
	# 1,480 at 1,000, so enemies grow tankier than they hit.
	var previous_ratio := 0.0
	for check_wave in [1, 21, 49, 99, 101, 499, 501, 999, 1001, 5001]:
		var hp_log := profile.liability_for_wave(1, check_wave).log10()
		var hit_log := profile.collection_for_wave(1, check_wave).log10()
		var ratio := pow(10.0, hp_log - hit_log)
		_expect(absf(hp_log - hit_log - profile.hit_ratio_log10(check_wave)) < 0.000001, "an ordinary Hit should be the wave's HP over the D063 ratio (wave " + str(check_wave) + ")")
		_expect(ratio >= previous_ratio, "enemies should never grow less tanky relative to their Hit (wave " + str(check_wave) + ")")
		previous_ratio = ratio
	for anchor in [[1, 2.4], [100, 11.0], [500, 118.0], [1000, 1480.0]]:
		var anchor_ratio := pow(10.0, profile.hit_ratio_log10(int(anchor[0])))
		_expect(absf(anchor_ratio / float(anchor[1]) - 1.0) < 0.05, "the ratio should sit on The Tower's shape at wave %d: %f" % [int(anchor[0]), anchor_ratio])
	_expect(profile.collection_for_wave(2, 21).compare_to(profile.collection_for_wave(1, 21).multiply_scalar(20.0)) == 0, "Tier 2 should multiply the same Hit curve by 20")
	# D065: a boss wave sends its ordinary enemies and a boss, which carries
	# twenty enemies' HP and hits like one (D063).
	var boss_run := GameState.new()
	boss_run.start_run(1, 3)
	boss_run.wave = 10
	boss_run.active_encounter = boss_run._make_encounter(10)
	var boss_at: int = boss_run.active_encounter.boss_index()
	var boss_member: Dictionary = boss_run.active_encounter.members[boss_at]
	var one_enemy_hp_10 := profile._from_log10(profile._wave_hp_log10(10))
	var ordinary_hit_10 := profile._from_log10(profile._wave_hit_log10(10))
	_expect(boss_run.active_encounter.members.size() == profile.ordinary_members(10) + 1 and boss_run.active_encounter.members.filter(func(member): return bool(member.boss)).size() == 1, "a boss wave should send its ordinary enemies and one boss")
	_expect(absf(boss_member.max.log10() - one_enemy_hp_10.multiply_scalar(profile.BOSS_HP_WEIGHT).log10()) < 0.000001, "a boss should carry twenty enemies' HP")
	_expect(absf(boss_member.wave_hit.multiply_scalar(float(boss_member.share)).log10() - ordinary_hit_10.log10()) < 0.000001, "a boss should hit like one ordinary enemy of its wave (D063)")
	_expect(profile.reward_for_wave(1, 1) == 1 and profile.reward_for_wave(1, 21) == 14 and profile.reward_for_wave(1, 10) == roundi(10 * profile.WAVE_REWARD_SCALE * profile.BOSS_REWARD_MULTIPLIER), "Coins should follow 0.65 x the wave from wave 1, x5 on a boss")
	# Doing nothing still ends, and earns clearly less than a player tapping
	# once a second.
	var no_action := GameState.new()
	no_action.start_run(1, 7)
	for step in range(4 * 900):
		if not no_action.in_run:
			break
		no_action.advance(0.25)
	var one_tap := GameState.new()
	one_tap.start_run(1, 7)
	for step in range(4 * 900):
		if not one_tap.in_run:
			break
		if step % 4 == 0:
			one_tap.tap()
		one_tap.advance(0.25)
	_expect(not no_action.in_run and not one_tap.in_run, "both openings should end within fifteen minutes")
	_expect(no_action.coins * 4 < one_tap.coins * 3, "a no-action opening must earn clearly less than tapping once a second")
	var armored := GameState.new()
	armored.purchased = {"tax_resistance": 1}
	armored.start_run(1, 3)
	armored.wave = 21
	armored.active_encounter = armored._make_encounter(21)
	_expect(armored.get_effective_collection().compare_to(profile.collection_for_wave(1, 21).multiply_scalar(0.996)) == 0, "Armor should reduce Tier 1's Hit")
	_expect(tier_two.get_effective_collection().compare_to(tier_two.active_encounter.collection) == 0, "Tier 2's opening hit should be its base")

	# An unbeaten wave's members land and stay (D058); at the end of its clock
	# it moves on (D037). Nothing was cleared, so its one Coin is not paid and
	# it sets no record, and its members carry into the next wave.
	var stuck := GameState.new()
	stuck.start_run(1, 3)
	var before: ScientificNumber = stuck.number.copy()
	var hit := stuck.get_effective_collection()
	var one_share: float = stuck.active_encounter.members[0].share
	var event := stuck._resolve_wave_boundary()
	_expect(event.type == "tax_collection" and absf(event.amount.log10() - hit.multiply_scalar(one_share).log10()) < 0.000001, "each member should land its share of the Hit")
	# In the opening (D059) each member hits once and leaves: the whole Hit, once.
	_expect(absf(before.subtract(stuck.number).log10() - hit.log10()) < 0.000001 and not stuck.number.is_zero(), "an opening wave should cost its Hit once, not the run")
	_expect(stuck.active_encounter.at_number_count() == 0, "opening members should not stay at the Number")
	_expect(stuck.wave == 2 and stuck.coins == 0 and stuck.get_tier_best(1) == 0, "the missed wave should move on unpaid and unrecorded")
	# The first boss stays and fights like every boss, but waves keep coming
	# (D063): it joins the next wave's pile.
	stuck.wave = 10
	stuck.active_encounter = stuck._make_encounter(10)
	stuck.number = ScientificNumber.new(1.0, 9)
	stuck._resolve_wave_boundary()
	_expect(stuck.wave == 11 and stuck.active_encounter.boss_index() >= 0, "the wave 10 boss should stay at the Number while the next wave comes")

	# D039: a fresh run's first Rig ranks cost a few seconds of its income in Cash, and
	# repeated purchases climb gently rather than jumping to a wave's HP.
	var rig := GameState.new()
	rig.start_run(1, 3)
	var opening_cost: ScientificNumber = rig.get_rig_cost("generator")
	_expect(opening_cost.compare_to(ScientificNumber.from_float(12.0)) <= 0, "the first Rig rank should cost about 10 Cash")
	var opening_number: ScientificNumber = rig.number.copy()
	_expect(rig.purchase_rig("generator") and rig.purchase_rig("stronger_tap"), "both opening Rig ranks should be affordable immediately")
	_expect(rig.number.compare_to(opening_number) == 0, "opening purchases should not reduce Number")
	_expect(rig.cash.compare_to(ScientificNumber.new()) >= 0, "opening purchases should leave non-negative Cash")
	var climb := GameState.new()
	climb.start_run(1, 3)
	climb.cash = ScientificNumber.new(1.0, 9)
	var last := climb.get_rig_cost("stronger_tap")
	for rank in range(12):
		climb.purchase_rig("stronger_tap")
		var next := climb.get_rig_cost("stronger_tap")
		var ratio := pow(10.0, next.log10() - last.log10())
		_expect(ratio > 1.0 and ratio < 1.6, "each Rig rank should cost a little more than the last, never a cliff (rank " + str(rank + 2) + ")")
		last = next
	var late := GameState.new()
	late.start_run(1, 3)
	var early_price := late.get_rig_cost("generator")
	late.wave = 29
	late.active_encounter = late._make_encounter(29)
	_expect(late.get_rig_cost("generator").compare_to(early_price) == 0, "a harder wave should not raise the price by itself")

func _test_tier_pressure_and_curve_gates() -> void:
	var state := GameState.new()
	var profile = state.balance_profile
	# D040: Tier 1's one curve starts small at wave 1 and keeps rising.
	# D065: many enemies, each small at first.
	var wave_one := profile.liability_for_wave(1, 1)
	_expect(wave_one.multiply_scalar(1.0 / profile.wave_weight(1)).compare_to(ScientificNumber.from_float(3.0)) < 0 and wave_one.compare_to(ScientificNumber.from_float(60.0)) < 0 and not wave_one.is_zero(), "Tier 1 wave 1 should be small enemies in a small wave")
	_expect(profile.liability_for_wave(1, 19).compare_to(profile.liability_for_wave(1, 21)) < 0 and profile.collection_for_wave(1, 19).compare_to(profile.collection_for_wave(1, 21)) < 0, "Tier 1 should keep rising through wave 21")
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
	# D057: one blow beats only the front member; what it carried past that
	# member's HP is lost, as it was past a whole wave's.
	_expect(state.active_encounter.members[0].hp.is_zero() and state.active_encounter.standing_count() == state.active_encounter.members.size() - 1, "one blow should beat only the front member")
	while not state.active_encounter.is_cleared():
		state.active_encounter.apply_compliance(ScientificNumber.new(9.9, 300))
	_expect(state.active_encounter.is_cleared(), "sufficient compliance should clear Liability without making it negative")
	var event := state._resolve_wave_boundary()
	_expect(event.type == "wave_clear" and state.wave == 2, "a cleared Liability should advance at the boundary")

func _test_output_is_number_and_strikes_the_wave() -> void:
	var state := GameState.new()
	state.tier_records["1"].highest_wave = GameState.TIER_UNLOCK_WAVE
	_expect(state.start_run(2, 21), "Tier 2 run should start after unlock")
	state.number = ScientificNumber.from_float(1000)
	_one_enemy(state, ScientificNumber.from_float(50))
	var lifetime_before: ScientificNumber = state.lifetime_generated.copy()

	# D037: every unit is Number and also counts against the wave.
	state._add_number(ScientificNumber.from_float(30))
	_expect(state.number.compare_to(ScientificNumber.from_float(1030)) == 0, "output below remaining Liability should still raise Number")
	_expect(state.active_encounter.remaining_liability.compare_to(ScientificNumber.from_float(20)) == 0, "output should damage the wave one-for-one")

	state._add_number(ScientificNumber.from_float(20))
	_expect(state.active_encounter.is_cleared(), "output exactly equal to remaining Liability should beat the wave")
	_expect(state.number.compare_to(ScientificNumber.from_float(1050)) == 0, "the clearing output should be Number too")

	state._add_number(ScientificNumber.from_float(45))
	_expect(state.number.compare_to(ScientificNumber.from_float(1095)) == 0, "output after the wave is beaten should all become Number")
	_expect(state.lifetime_generated.compare_to(lifetime_before.add(ScientificNumber.from_float(95))) == 0, "lifetime production should count each unit once")

	state.active_encounter = state._make_encounter(state.wave)
	state.active_encounter.remaining_liability = ScientificNumber.from_float(50)
	state._add_number(ScientificNumber.from_float(80))
	_expect(state.active_encounter.members[0].hp.is_zero() and state.number.compare_to(ScientificNumber.from_float(1175)) == 0, "an output past the front member's HP should beat it and bank in full")

	state.active_encounter = state._make_encounter(state.wave)
	state.active_encounter.remaining_liability = ScientificNumber.from_float(50)
	var zero_lifetime: ScientificNumber = state.lifetime_generated.copy()
	state._add_number(ScientificNumber.new())
	_expect(state.number.compare_to(ScientificNumber.from_float(1175)) == 0 and state.active_encounter.remaining_liability.compare_to(ScientificNumber.from_float(50)) == 0, "zero output should change nothing")
	_expect(state.lifetime_generated.compare_to(zero_lifetime) == 0, "zero output should not count as production")

	state.number = ScientificNumber.new()
	_one_enemy(state, ScientificNumber.new(5.0, 300))
	state._add_number(ScientificNumber.new(7.0, 300))
	_expect(state.active_encounter.is_cleared() and state.number.compare_to(ScientificNumber.new(7.0, 300)) == 0, "Number should stay exact at very large values")

	var warm_up := GameState.new()
	warm_up.start_run(1, 22)
	var warm_up_hp: ScientificNumber = warm_up.active_encounter.remaining_liability.copy()
	var starting: ScientificNumber = warm_up.number.copy()
	_expect(warm_up_hp.compare_to(warm_up.balance_profile.liability_for_wave(1, 1)) == 0, "wave 1 should carry a small Wave HP")
	warm_up._add_number(ScientificNumber.from_float(5))
	_expect(warm_up.number.compare_to(starting.add(ScientificNumber.from_float(5))) == 0, "the first tap's worth of output should raise Number at once")

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
	_expect(state.number.compare_to(ScientificNumber.from_float(50)) == 0, "every tap should bank once, before and after the clear")
	_expect(state.lifetime_generated.compare_to(lifetime_before.add(ScientificNumber.from_float(50))) == 0, "every tap should count once toward lifetime production")

func _test_missed_waves_move_on_and_bosses_stay() -> void:
	# D037: an ordinary wave that outlasts its timer hits once and moves on,
	# paying Coins for the share cleared; it is not beaten, so it sets no record.
	var state := GameState.new()
	state.tier_records["1"].highest_wave = GameState.TIER_UNLOCK_WAVE
	state.start_run(2, 24)
	state.wave = 31
	state.active_encounter = state._make_encounter(31)
	state.number = ScientificNumber.from_float(1e9)
	state.active_encounter.remaining_liability = state.active_encounter.max_liability.multiply_scalar(0.4)
	var reward: int = state.active_encounter.reward
	var hit := state.get_effective_collection()
	# Front-first, so the members beaten are the front ones; each still
	# standing lands its full share, however damaged (D057).
	var standing_share := 0.0
	var standing := 0
	for member in state.active_encounter.members:
		if TaxEncounter.is_alive(member):
			standing_share += float(member.share)
			standing += 1
	var event := state._resolve_wave_boundary()
	_expect(event.type == "tax_collection" and state.wave == 32, "a missed ordinary wave should hit and move on")
	_expect(absf(ScientificNumber.from_float(1e9).subtract(state.number).log10() - hit.multiply_scalar(standing_share).log10()) < 0.000001, "only the members left standing should land, each its share")
	_expect(reward > 10 and state.coins == floori(float(reward) * 0.6), "a missed wave should pay Coins for the share cleared")
	_expect(state.get_tier_best(2) == 0, "a missed wave should set no record")
	_expect(state.active_encounter.own_uncleared().compare_to(state.active_encounter.max_liability) == 0, "the next wave should arrive whole")
	_expect(state.active_encounter.at_number_count() == standing and state.active_encounter.front_index() == 0, "the missed wave's standing members should stay at the Number, in front")

	# D063: waves keep coming while a boss stands. An unbeaten boss hits and
	# joins the pile in front of the next wave, keeping the damage dealt.
	var boss := GameState.new()
	boss.tier_records["1"].highest_wave = GameState.TIER_UNLOCK_WAVE
	boss.start_run(2, 25)
	boss.wave = 30
	boss.active_encounter = boss._make_encounter(30)
	boss.number = ScientificNumber.from_float(1e12)
	var boss_hp: ScientificNumber = boss.active_encounter.max_liability.copy()
	boss._add_number(ScientificNumber.from_float(40))
	event = boss._resolve_wave_boundary()
	_expect(event.type == "boss_collection" and boss.wave == 31, "a boss still standing at its boundary should hit and let the next wave come")
	var carried_boss: int = boss.active_encounter.boss_index()
	_expect(carried_boss == 0 and boss.active_encounter.front_index() == 0, "the boss should stay at the Number, in front of the next wave")
	_expect(boss.active_encounter.members[carried_boss].hp.compare_to(boss_hp.subtract(ScientificNumber.from_float(40.0 * boss._boss_damage_multiplier()))) <= 0, "a standing boss should keep the damage already dealt")
	boss._add_number(boss.active_encounter.members[carried_boss].hp.copy())
	_expect(boss.active_encounter.boss_index() < 0 and boss.get_tier_best(2) == 0, "a boss beaten after its wave passed should not count its wave as beaten")
	_beat_wave(boss)
	_advance_seconds(boss, boss.balance_profile.MIN_WAVE_SECONDS)
	_expect(boss.wave == 32 and boss.get_tier_best(2) == 31, "beating the next wave should advance and count")

func _test_missed_checkpoint_pays_when_passed() -> void:
	# D037 with D030: wave 25 is an ordinary checkpoint. Missing it claims
	# nothing; beating a later wave pays it in the run, as a reload would.
	var state := GameState.new()
	state.tier_records["1"] = {"highest_wave": 24, "best_time": 0.0, "milestones_claimed": [10, 20]}
	state.start_run(1, 29)
	state.wave = 25
	state.active_encounter = state._make_encounter(25)
	state.number = ScientificNumber.from_float(1e9)
	var coins_before := state.coins
	var gems_before := state.gems
	state._resolve_wave_boundary()
	_expect(state.wave == 26 and not state.get_tier_record(1).milestones_claimed.has(25), "a missed checkpoint wave should claim nothing")
	_beat_wave(state)
	_advance_seconds(state, state.balance_profile.MIN_WAVE_SECONDS)
	var bonus: int = state.balance_profile.milestone_bonus(1, 25)
	_expect(state.get_tier_record(1).milestones_claimed.has(25), "beating a later wave should claim the passed checkpoint")
	_expect(state.coins - coins_before >= bonus and state.gems - gems_before == state.balance_profile.milestone_gems(1, 25), "the passed checkpoint should pay its Coin bonus and Gems once")
	var paid_coins := state.coins
	var paid_gems := state.gems
	state._catch_up_passed_milestones()
	_expect(state.coins == paid_coins and state.gems == paid_gems, "a reload catch-up should find nothing left to pay")

func _test_beaten_wave_gives_way_after_the_minimum_beat() -> void:
	# D037: a beaten wave no longer waits out its timer. It stays on screen for
	# the minimum beat so the clear registers, then the next wave arrives.
	var state := GameState.new()
	state.start_run(1, 26)
	_beat_wave(state)
	_expect(state.active_encounter.is_cleared() and state.wave == 1, "a cleared wave should hold until the minimum beat")
	var events := state.advance(0.25)
	_expect(state.wave == 1, "the next wave should not arrive before the minimum beat")
	_advance_seconds(state, state.balance_profile.MIN_WAVE_SECONDS)
	_expect(state.wave == 2 and state.coins == 1, "the next wave should arrive once the beat has passed, paying the cleared wave")
	_expect(state.wave_accumulator < state.balance_profile.MIN_WAVE_SECONDS, "the new wave's timer should start fresh")
	_expect(state.balance_profile.MIN_WAVE_SECONDS < GameState.WAVE_INTERVAL_SECONDS, "the minimum beat should be shorter than the timer")
	var cleared_event := false
	for event in events:
		cleared_event = cleared_event or event.type == "wave_clear"
	_expect(not cleared_event, "no clear should be reported before the beat")

	# Driven through the clock: an ordinary wave left standing hits once at 15
	# seconds and moves on, with its partial Coins, exactly like the boundary.
	var clocked := GameState.new()
	clocked.tier_records["1"].highest_wave = GameState.TIER_UNLOCK_WAVE
	clocked.start_run(2, 27)
	clocked.wave = 31
	clocked.active_encounter = clocked._make_encounter(31)
	clocked.number = ScientificNumber.from_float(1e9)
	var hp: ScientificNumber = clocked.active_encounter.max_liability.copy()
	clocked.active_encounter.remaining_liability = hp.multiply_scalar(0.2)
	var reward: int = clocked.active_encounter.reward
	_advance_seconds(clocked, GameState.WAVE_INTERVAL_SECONDS - 0.5)
	_expect(clocked.wave == 31, "a standing wave should not move on before its timer")
	_advance_seconds(clocked, 0.5)
	_expect(clocked.wave == 32 and clocked.coins == floori(float(reward) * 0.8 + 0.000001), "at 15 seconds a standing ordinary wave should hit, pay its share and move on")

	# 20 left of 100 is exactly 0.8 cleared: the share must not round down a Coin.
	var exact := GameState.new()
	exact.start_run(1, 28)
	exact.active_encounter = TaxEncounter.new(1, 1, ScientificNumber.from_float(100), ScientificNumber.from_float(1), 10, false, [6.0, 10.5, 15.0])
	exact.active_encounter.remaining_liability = ScientificNumber.from_float(20)
	_expect(floori(10.0 * exact.get_wave_cleared_share() + 0.000001) == 8, "a cleared share of exactly 0.8 should pay 8 of 10 Coins")

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
	# A wave is many enemies now (D065), so it takes more taps to beat.
	for tap_index in range(600):
		original.tap()
		restored.tap()
	_expect(original.active_encounter.is_cleared(), "continued tapping should carry the wave past its clear point")
	_expect(restored.number.compare_to(original.number) == 0, "a restored run should bank the same overflow as the original")
	_expect(restored.active_encounter.remaining_liability.compare_to(original.active_encounter.remaining_liability) == 0, "a restored run should deal the same damage as the original")
	_expect(restored.lifetime_generated.compare_to(original.lifetime_generated) == 0 and restored.rng.state == original.rng.state, "a restored run should stay deterministic")
	restored.clear_save()

	# A saved encounter keeps its stored Hit: a run saved under an older curve
	# resumes with the Hit it had, and resolves identically after a reload.
	var opening := GameState.new()
	opening.save_path = save_path
	opening.start_run(1, 31)
	opening.wave = 21
	opening.active_encounter = opening._make_encounter(21)
	opening.active_encounter.collection = opening.active_encounter.collection.multiply_scalar(2.0)
	opening.number = ScientificNumber.from_float(1000.0)
	var opening_hit: ScientificNumber = opening.get_effective_collection()
	_expect(opening_hit.compare_to(opening.balance_profile.collection_for_wave(1, 21).multiply_scalar(2.0)) == 0, "a saved larger base hit should be the Hit that lands")
	_expect(opening.save(), "a mid-run Tier 1 wave should save")
	var opening_restored := GameState.new()
	opening_restored.save_path = save_path
	opening_restored.load()
	_expect(opening_restored.wave == 21 and opening_restored.get_effective_collection().compare_to(opening_hit) == 0, "a reloaded wave should keep the same effective hit")
	opening._resolve_wave_boundary()
	opening_restored._resolve_wave_boundary()
	_expect(opening_restored.number.compare_to(opening.number) == 0 and opening_restored.wave == opening.wave, "the reloaded Tier 1 hit should resolve identically")
	opening_restored.clear_save()

	# D040: a run saved under an older balance profile resumes on the current
	# curve. The old profile read a small wave 21 Hit through a ramp it never
	# stored; its saved encounter holds the full old Hit (156), which must not
	# land. The rebuilt wave keeps the share of HP already cleared.
	var legacy := GameState.new()
	legacy.save_path = save_path
	legacy.start_run(1, 32)
	legacy.wave = 21
	legacy.active_encounter = legacy._make_encounter(21)
	legacy.number = ScientificNumber.from_float(1000.0)
	_expect(legacy.save(), "the legacy fixture should save")
	var saved: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(save_path))
	saved.balance_profile_id = "tax-foundation-v6"
	# A save from before groups (D057) had no members, only its wave's HP.
	saved.active_encounter.erase("members")
	saved.active_encounter.erase("passed_liability")
	saved.active_encounter.max_liability = ScientificNumber.from_float(238.0).to_dict()
	saved.active_encounter.remaining_liability = ScientificNumber.from_float(166.6).to_dict()
	saved.active_encounter.collection = ScientificNumber.from_float(156.0).to_dict()
	_write_json(save_path, saved)
	var migrated := GameState.new()
	migrated.save_path = save_path
	migrated.load()
	_expect(migrated.in_run and migrated.wave == 21, "an old-profile run should resume at its wave")
	_expect(migrated.get_effective_collection().compare_to(migrated.balance_profile.collection_for_wave(1, 21)) == 0, "an old-profile wave should hit with today's Hit, not its stored one")
	_expect(absf(migrated.get_wave_cleared_share() - 0.3) < 0.0001, "an old-profile wave should keep the share of HP already cleared")
	migrated.clear_save()

func _test_collection_is_absolute() -> void:
	var small := GameState.new()
	small.tier_records["1"].highest_wave = GameState.TIER_UNLOCK_WAVE
	small.start_run(2, 4)
	small.number = ScientificNumber.from_float(5000)
	var expected := small.get_effective_collection()
	var one_share: float = small.active_encounter.members[0].share
	var small_event := small._resolve_wave_boundary()
	var large := GameState.new()
	large.tier_records["1"].highest_wave = GameState.TIER_UNLOCK_WAVE
	large.start_run(2, 4)
	large.number = ScientificNumber.from_float(500000000)
	var large_event := large._resolve_wave_boundary()
	_expect(small_event.type == "tax_collection" and large_event.type == "tax_collection", "uncleared encounters should collect")
	_expect(small_event.amount.compare_to(large_event.amount) == 0 and absf(small_event.amount.log10() - expected.multiply_scalar(one_share).log10()) < 0.000001, "Collection must be the same absolute value at every player Number")

func _test_boss_axes_and_rewards() -> void:
	var profile = GameState.new().balance_profile
	var normal_liability := profile.liability_for_wave(2, 29)
	var boss_liability := profile.liability_for_wave(2, 30)
	var normal_collection := profile.collection_for_wave(2, 29)
	var boss_collection := profile.collection_for_wave(2, 30)
	_expect(boss_liability.compare_to(normal_liability) > 0, "boss liability should exceed the preceding normal wave")
	var one_enemy_30 := profile._from_log10(profile._wave_hit_log10(30)).multiply_scalar(20.0)
	var boss_lands := profile.boss_wave_hit(2, 30).multiply_scalar(profile.BOSS_HP_WEIGHT / profile.wave_weight(30))
	_expect(absf(boss_lands.log10() - one_enemy_30.log10()) < 0.000001 and boss_lands.compare_to(normal_collection) < 0 and boss_collection.compare_to(normal_collection) > 0, "a boss should be a wall of HP that hits like one enemy, not a whole wave (D063)")
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
	_expect(base_cost == 4, "the first Armor rank should cost the opening price of its ladder")
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
	_expect(maxed_hit.compare_to(maxed_base.multiply_scalar(0.51)) < 0 and maxed_hit.compare_to(maxed_base.multiply_scalar(0.49)) > 0, "a maxed Armor should take about 50% off the hit (D047)")
	_expect(not maxed_hit.is_zero(), "Armor must never remove the hit entirely")

## Siphon is the only route by which damage dealt to a wave also reaches Number.
## It must not reduce what the wave takes.
func _test_leech_feeds_on_a_standing_boss() -> void:
	# D038: Leech (the `siphon` row) adds a share of the damage a boss takes to
	# Number a second time. Ordinary waves are unaffected.
	var state := GameState.new()
	state.tier_records["1"].highest_wave = GameState.TIER_UNLOCK_WAVE
	state.purchased = {"siphon": 100}
	_expect(state.start_run(2, 41), "Tier 2 run should start after unlock")
	state.number = ScientificNumber.from_float(1000)
	_one_enemy(state, ScientificNumber.from_float(100))
	state._add_number(ScientificNumber.from_float(40))
	_expect(state.number.compare_to(ScientificNumber.from_float(1040)) == 0, "Leech should not feed on an ordinary wave")

	# A lone boss, so the damage reaches it rather than the enemies in front.
	state.wave = 20
	_one_enemy(state, ScientificNumber.from_float(100))
	state._add_number(ScientificNumber.from_float(40))
	_expect(state.active_encounter.remaining_liability.compare_to(ScientificNumber.from_float(60)) == 0, "Leech must not change the damage the boss takes")
	_expect(state.number.compare_to(ScientificNumber.from_float(1090)) == 0, "a quarter of the 40 dealt to the boss should be added again")
	state._add_number(ScientificNumber.from_float(100))
	_expect(state.active_encounter.is_cleared(), "output past the remaining HP should beat the boss")
	_expect(state.number.compare_to(ScientificNumber.from_float(1205)) == 0, "only the 60 the boss absorbed should be leeched")

func _test_thorns_deal_the_hit_to_the_wave_in_front() -> void:
	# D064: Thorns (the `recoil` row) deals the enemy that hit a share of its own
	# maximum HP, half on a boss, as The Tower's does.
	var state := GameState.new()
	state.tier_records["1"].highest_wave = GameState.TIER_UNLOCK_WAVE
	state.purchased = {"recoil": 100}
	state.start_run(2, 42)
	state.number = ScientificNumber.from_float(1e9)
	state.wave = 20
	state.active_encounter = state._make_encounter(20)
	var boss_at_start: int = state.active_encounter.boss_index()
	var boss_max: ScientificNumber = state.active_encounter.members[boss_at_start].max.copy()
	var before: ScientificNumber = state.active_encounter.members[boss_at_start].hp.copy()
	state._resolve_wave_boundary()
	_expect(state.wave == 21 and state.active_encounter.boss_index() >= 0, "an unbeaten boss should hit and join the pile (D063)")
	var thorned_boss: Dictionary = state.active_encounter.members[state.active_encounter.boss_index()]
	var boss_thorns := boss_max.multiply_scalar(state._effect_sum("recoil_share") * state.balance_profile.BOSS_THORNS_SHARE)
	# Through the opening a boss hits every 15 seconds: at 15 and 30 before its
	# wave passes at 35 (D065), taking Thorns each time.
	_expect(absf(before.subtract(thorned_boss.hp).log10() - boss_thorns.multiply_scalar(2.0).log10()) < 1.0e-9, "a boss should take half of Thorns' share of its maximum HP each time it hits")

	# An ordinary wave's members stay at the Number (D058), so Thorns returns
	# each hit to them, and the wave that replaces a missed one arrives whole.
	state.wave = 21
	state.active_encounter = state._make_encounter(21)
	var wave_hp: ScientificNumber = state.active_encounter.max_liability.copy()
	state._resolve_wave_boundary()
	_expect(state.wave == 22, "a missed ordinary wave should move on")
	var pile_hp := ScientificNumber.new()
	for member in state.active_encounter.members:
		if not state.active_encounter.is_own(member):
			pile_hp = pile_hp.add(member.hp)
	_expect(pile_hp.compare_to(wave_hp) < 0 and state.active_encounter.own_uncleared().compare_to(state.active_encounter.max_liability) == 0, "Thorns should land on the members at the Number, and the next wave arrive whole")

	# The contact still happens, so Thorns still bites through a Brace (D064).
	# Wave 51's enemies stay after hitting, so the pile shows what Thorns took.
	var braced := GameState.new()
	braced.purchased = {"recoil": 100}
	braced.start_run(1, 43)
	braced.number = ScientificNumber.from_float(1e9)
	braced.wave = 51
	braced.active_encounter = braced._make_encounter(51)
	var braced_wave_hp: ScientificNumber = braced.active_encounter.max_liability.copy()
	_expect(braced.brace(), "Brace should be available against an active wave")
	var after_brace := braced.number.copy()
	braced._resolve_wave_boundary()
	var braced_pile := ScientificNumber.new()
	for member in braced.active_encounter.members:
		if not braced.active_encounter.is_own(member):
			braced_pile = braced_pile.add(member.hp)
	_expect(braced.wave == 52 and braced.number.compare_to(after_brace) == 0 and not braced_pile.is_zero() and braced_pile.compare_to(braced_wave_hp) < 0, "a Brace should block every hit of its clock while Thorns still bites")

	# Guard taking every hit to nothing still leaves the contact, so Thorns
	# still bites: The Tower's Tier 1 turtle (D064).
	var turtle := GameState.new()
	turtle.purchased = {"recoil": 100, "guard": 5000}
	turtle.start_run(1, 44)
	turtle.number = ScientificNumber.from_float(1000)
	turtle.wave = 51
	turtle.active_encounter = turtle._make_encounter(51)
	var turtle_front_max: ScientificNumber = turtle.active_encounter.members[0].max.copy()
	for step in range(25):
		turtle._advance_waves(0.25)
	var turtle_front: Dictionary = turtle.active_encounter.members[0]
	_expect(turtle.number.compare_to(ScientificNumber.from_float(1000)) >= 0 and bool(turtle_front.landed), "Guard should take the first hit to nothing")
	_expect(absf(turtle_front_max.subtract(turtle_front.hp).log10() - turtle_front_max.multiply_scalar(turtle._effect_sum("recoil_share")).log10()) < 1.0e-9, "Thorns should still bite when Guard takes the hit to nothing")

	# At 99%, an opening enemy that hits after taking any damage dies to Thorns
	# before it can leave, so its wave can still be beaten.
	var opener := GameState.new()
	opener.purchased = {"recoil": 200}
	opener.start_run(1, 45)
	opener.number = ScientificNumber.from_float(1e6)
	for member in opener.active_encounter.members:
		member.hp = member.max.multiply_scalar(0.5)
	opener.active_encounter._sum_remaining()
	# The last of wave 1's enemies arrives at 32 seconds (D065).
	for step in range(132):
		opener._advance_waves(0.25)
	_expect(opener.wave == 2 and opener.get_tier_best(1) == 1, "opening enemies Thorns kills as they hit should leave their wave beaten")

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
	var event := _play_until(state, "second_wind")
	_expect(event != null and event.type == "second_wind", "a hit that would end the run should trigger Second Wind instead")
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
	_expect(state.number.compare_to(ScientificNumber.from_float(500 + state.balance_profile.starting_number(1))) == 0, "Cushion should be worth its face value on Tier 1, on top of Tier 1's starting Number")
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
	# A lone boss in front, so the tap strikes the boss itself (D063).
	state.wave = 10
	_one_enemy(state, state.balance_profile.liability_for_wave(2, 10))
	_expect(state.active_encounter.is_boss and state.active_encounter.boss_index() == 0, "wave ten should be a boss")
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

## Guard (Defense Absolute): a flat amount off each enemy's hit, priced in the
## tier's Hit pressure, after Armor and down to nothing, as in The Tower (D063).
func _test_guard_flat_reduction_and_floor() -> void:
	var state := GameState.new()
	state.start_run(1, 4)
	state.wave = 40
	state.active_encounter = state._make_encounter(40)
	var base_hit: ScientificNumber = state.active_encounter.collection.copy()
	_expect(state.get_effective_collection().compare_to(base_hit) == 0, "with no Guard or Armor, hit should match base")

	# 10 ranks of Guard on Tier 1 take exactly 10 off.
	state.purchased = {"guard": 10}
	_expect(state.get_effective_collection().compare_to(base_hit.subtract(ScientificNumber.from_float(10.0))) == 0, "10 ranks of Guard should take exactly 10 off a hit")

	# Guard larger than the hit takes it to nothing: no floor (D063).
	state.purchased = {"guard": 100}
	var wave_one := GameState.new()
	wave_one.purchased = {"guard": 100}
	wave_one.start_run(1, 4)
	_expect(wave_one.get_effective_collection().is_zero(), "Guard larger than a hit should take it to nothing")

	# Armor comes off first, then Guard: 60 Armor ranks (24%) and 10 Guard.
	state.purchased = {"guard": 10, GameState.ARMOR_ID: 60}
	var armor_first := base_hit.multiply_scalar(1.0 - state._effect_sum("collection_resistance")).subtract(ScientificNumber.from_float(10.0))
	_expect(absf(state.get_effective_collection().log10() - armor_first.log10()) < 1.0e-9, "Armor should come off before Guard")

	# A rule that shrinks hits comes off before Guard too.
	state.purchased = {"guard": 10}
	state.active_rule_modifiers = [{"source": "test_perk", "target": "collection", "stage": "multiplicative", "value": 0.5}]
	_expect(absf(state.get_effective_collection().log10() - base_hit.multiply_scalar(0.5).subtract(ScientificNumber.from_float(10.0)).log10()) < 1.0e-9, "a rule that shrinks hits should apply before Guard")
	state.active_rule_modifiers = []

	# The Hit shown on the wave is its raw size; its defences come off at contact
	# (D052). The parts must add up to the Hit that lands, in every mix.
	var bare := GameState.new()
	bare.start_run(1, 4)
	var bare_parts := bare.get_hit_breakdown()
	_expect(bare_parts.guard.is_zero() and bare_parts.armor.is_zero() and bare_parts.raw.compare_to(bare_parts.final) == 0, "with no defences the raw Hit is the Hit that lands")
	bare.wave = 40
	bare.active_encounter = bare._make_encounter(40)
	var front_member: Dictionary = bare.active_encounter.members[bare.active_encounter.front_index()]
	for mix in [{"guard": 3}, {GameState.ARMOR_ID: 60}, {"guard": 3, GameState.ARMOR_ID: 60}]:
		bare.purchased = mix
		for rules in [[], [{"source": "test_perk", "target": "collection", "stage": "multiplicative", "value": 0.5}]]:
			bare.active_rule_modifiers = rules
			var parts := bare.get_hit_breakdown()
			var rebuilt: ScientificNumber = parts.raw.subtract(parts.armor).subtract(parts.guard)
			var lands: ScientificNumber = bare._effective_hit(bare._member_raw_hit(front_member))
			_expect(not parts.final.is_zero() and absf(rebuilt.log10() - parts.final.log10()) < 1.0e-9 and parts.final.compare_to(lands) == 0, "a Hit's parts should add up to the Hit that lands: %s" % str(mix))
	bare.purchased = {"guard": 3, GameState.ARMOR_ID: 60}
	bare.active_rule_modifiers = []
	var both := bare.get_hit_breakdown()
	_expect(not both.guard.is_zero() and not both.armor.is_zero(), "Guard and Armor should each show what they took off")

	# Tier scaling: On Tier 2 (collection_multiplier = 20.0), 10 Guard reduces by 200.
	# A fresh state, since start_run refuses while a run is already going.
	var tier_two := GameState.new()
	tier_two.purchased = {"guard": 10}
	tier_two.tier_records["1"].highest_wave = GameState.TIER_UNLOCK_WAVE
	_expect(tier_two.start_run(2, 4), "the Tier 2 fixture should start")
	tier_two.wave = 40
	tier_two.active_encounter = tier_two._make_encounter(40)
	var t2_base_hit: ScientificNumber = tier_two.active_encounter.collection.copy()
	var t2_expected := t2_base_hit.subtract(ScientificNumber.from_float(200.0))
	var t2_hit := tier_two.get_effective_collection()
	_expect(not t2_expected.is_zero(), "the Tier 2 fixture's Hit should outweigh 200 Guard")
	_expect(t2_hit.compare_to(t2_expected) == 0, "Guard should scale by Tier 2's collection multiplier")

	# Save/load round-trip preserves Guard:
	var save_path := "res://.number_go_up_test_save.json"
	state.save_path = save_path
	state.purchased = {"guard": 25}
	_expect(state.save(), "save with Guard should write")
	var loaded := GameState.new()
	loaded.save_path = save_path
	loaded.load()
	_expect(loaded.get_owned("guard") == 25, "loaded save should keep 25 Guard ranks")
	loaded.clear_save()

func _test_game_data_loads_cleanly() -> void:
	GameDataClass.clear_cache()
	var workshop: Array = GameDataClass.get_workshop_upgrades()
	_expect(workshop.size() == 21, "GameData should load exactly 21 Workshop upgrades")
	var knowledge: Array = GameDataClass.get_knowledge_upgrades()
	_expect(knowledge.size() == 1 and knowledge[0].id == "insight", "GameData should load Insight from knowledge upgrades")
	var all: Array = GameDataClass.get_all_upgrades()
	_expect(all.size() == 22, "GameData should return all 22 upgrades")
	var cached: Array = GameDataClass.get_all_upgrades()
	_expect(cached.size() == 22, "cached upgrades should match")

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
			if definition.deep_cost_growth > 0.0:
				_expect(definition.deep_price_from > 0 and definition.deep_price_from < definition.max_rank, "%s should switch price growth inside its ladder" % definition.id)
		if not definition.depth_curve.is_empty():
			var curve := definition.depth_curve
			var sound: bool = curve.size() >= 2 and is_equal_approx(float(curve[0][1]), 1.0)
			for index in range(1, curve.size()):
				sound = sound and float(curve[index][0]) > float(curve[index - 1][0]) and float(curve[index][1]) > float(curve[index - 1][1])
			_expect(sound, "%s's depth curve should start at x1 and rise through ascending anchors" % definition.id)
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

## D028/D047: a V8 save loads with every rank and its run's Cash intact, keeps
## a copy of the file it read, and is rewritten as V9 at once; a V9 save keeps
## deep ranks past 100, which a V8 build would have clamped.
func _test_v8_save_migrates_to_v9() -> void:
	var save_path := "res://.number_go_up_test_save.json"
	var source := _funded_state()
	source.purchased = {"stronger_tap": 100, "generator": 40}
	source.start_run(1, 31)
	source.cash = ScientificNumber.from_float(1234.0)
	var v8: Dictionary = SaveDataV11.make(source)
	v8.version = 8
	_write_json(save_path, v8)
	var loaded := GameState.new()
	loaded.save_path = save_path
	loaded.load()
	_expect(loaded.get_owned("stronger_tap") == 100 and loaded.get_owned("generator") == 40, "a V8 save should keep every Workshop rank")
	_expect(loaded.in_run and loaded.cash.compare_to(ScientificNumber.from_float(1234.0)) == 0, "a V8 save should keep its run's Cash")
	_expect(int(_read_json(save_path).get("version", 0)) == SaveDataV11.VERSION, "a V8 save should be rewritten in the current version at once")
	_expect(int(_read_json("res://.number_go_up_test_save.v8-backup.json").get("version", 0)) == 8, "the V8 file should be kept beside the new save")
	loaded.clear_save()

	var deep := _funded_state()
	deep.save_path = save_path
	deep.purchased = {"stronger_tap": 4321, "guard": 2500}
	_expect(deep.save(), "a save with deep ranks should write")
	var reloaded := GameState.new()
	reloaded.save_path = save_path
	reloaded.load()
	_expect(reloaded.get_owned("stronger_tap") == 4321 and reloaded.get_owned("guard") == 2500, "deep ranks past 100 should round-trip")
	reloaded.clear_save()

## A save holding more ranks than a row allows loads at the cap, so a lowered
## cap takes effect; a rank under a retired id is kept but counts for nothing.
func _test_loaded_ranks_stay_within_their_caps() -> void:
	var save_path := "res://.number_go_up_test_save.json"
	var data: Dictionary = SaveDataV11.make(GameState.new())
	data.purchased = {"stronger_tap": 90000, "generator": -4, "retired_row": 30}
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
	# The first member to land is the one that ends the run: its share.
	var killing_hit: ScientificNumber = state.get_hit_breakdown().final
	var was_boss: bool = state.active_encounter.is_boss
	var expected_attack_gap: ScientificNumber = state.active_encounter.own_uncleared()
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
	_one_enemy(boss_run, boss_run.balance_profile.liability_for_wave(2, 10))
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
	var recoil_hp_left := recoil_death.get_effective_collection().multiply_scalar(0.25)
	recoil_death.active_encounter.remaining_liability = recoil_hp_left
	# The member left in front lands first, with its share of the Hit (D057).
	var recoil_hit: ScientificNumber = recoil_death.get_hit_breakdown().final
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
	_advance_seconds(state, GameState.WAVE_INTERVAL_SECONDS + 1.0)
	_expect(state.wave == 2, "an opening wave should advance when its 35-second clock runs out (D065)")

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
	var wave_coins := 0
	for paid_wave in range(1, 11):
		wave_coins += first.balance_profile.reward_for_wave(1, paid_wave)
	var bonus: int = first.balance_profile.milestone_bonus(1, 10)
	_expect(first.coins == wave_coins + bonus and first.gems == first_gems, "the first wave-10 clear should pay its waves' Coins, the milestone bonus, and the checkpoint's and the boss wave's Gems")
	_expect(first.save(), "the milestone save should write")
	var reloaded := GameState.new()
	reloaded.save_path = save_path
	reloaded.load()
	var claimed: Array = reloaded.get_tier_record(1).milestones_claimed
	_expect(claimed == [10] and typeof(claimed[0]) == TYPE_INT, "a claimed milestone should reload as the whole-number wave it was")
	reloaded.start_run(1, 5)
	_clear_waves_through(reloaded, 10)
	reloaded.end_run()
	_expect(reloaded.coins == wave_coins + bonus + wave_coins, "a reloaded milestone should pay only its wave Coins, not its bonus again")
	_expect(reloaded.gems == first_gems + reloaded.balance_profile.BOSS_WAVE_GEMS, "a reloaded milestone should not grant its Gems again; only the boss wave pays")
	_expect(reloaded.get_tier_record(1).milestones_claimed == [10], "a reclaimed pass should not list the milestone twice")
	reloaded.clear_save()

	# A save written before the fix can hold the same wave twice, plus junk;
	# it collapses to each real wave once.
	var damaged: Dictionary = SaveDataV11.make(GameState.new())
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
	var passed: Dictionary = SaveDataV11.make(GameState.new())
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

	var old: Dictionary = SaveDataV11.make(GameState.new())
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
	_expect(int(_read_json(save_path).get("version", 0)) == SaveDataV11.VERSION, "the topped-up save should be rewritten in the current version at once")
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
	# D063: a last flat reduction (Guard) comes off after every percentage and
	# before the caps: (100 x 0.5) - 20 = 30, where before the percentage it
	# would give 40, and a cap of 25 then holds rather than leaving 5.
	var last: Array = [
		{"target": "collection", "stage": "flat_reduce_last", "amount": ScientificNumber.from_float(20).to_dict()},
		{"target": "collection", "stage": "multiplicative", "value": 0.5},
	]
	_expect(RuleModifierPipelineClass.apply(ScientificNumber.from_float(100), "collection", last).compare_to(ScientificNumber.from_float(30)) == 0, "a last flat reduction should come off after the percentages")
	last.append({"target": "collection", "stage": "cap_max", "amount": ScientificNumber.from_float(25).to_dict()})
	_expect(RuleModifierPipelineClass.apply(ScientificNumber.from_float(100), "collection", last).compare_to(ScientificNumber.from_float(25)) == 0, "the caps should come after a last flat reduction")

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

## Rig prices follow the player's income (D039), not the wave, so one table
## scales across tiers and depth without jumping when a harder wave arrives.
func _test_rig_cost_is_quoted_in_seconds_of_income() -> void:
	# D039: a rank costs k x RIG_PRICE_SECONDS of the steady income, x the
	# row's growth per rank owned. A fresh run makes 1 a second plus one tap.
	var state := GameState.new()
	state.start_run(1, 5)
	var profile = state.balance_profile
	_expect(is_equal_approx(state.get_rig_income_rate(), 2.0), "a fresh run's steady income should be the base 1 a second plus one tap")
	var first := state.get_rig_cost("stronger_tap", 0)
	_expect(first.compare_to(ScientificNumber.from_float(profile.RIG_PRICE_SECONDS * 2.0)) == 0, "the first Attack rank should cost five seconds of income at k=1")
	_expect(state.get_rig_cost("stronger_tap", 1).compare_to(first.multiply_scalar(profile.RIG_COST_GROWTH.attack)) == 0, "a named rank should be quoted at today's income times the row's growth")
	_expect(state.get_rig_cost(GameState.ARMOR_ID, 0).compare_to(first) == 0, "the first Defense rank should cost the same at k=1")
	_expect(state.get_rig_cost("coin_bonus", 0).compare_to(first.multiply_scalar(2.0)) == 0, "the first Utility rank should cost twice as much at k=2")
	# Income, not the wave, moves the price: a boss does not raise it, and a
	# rank that adds damage does.
	state.purchased = {"boss_damage": 100}
	var ordinary := state.get_rig_cost("stronger_tap")
	state.wave = 30
	state.active_encounter = state._make_encounter(30)
	_expect(state.get_rig_cost("stronger_tap").compare_to(ordinary) == 0, "a boss's damage bonus should not raise Rig prices")
	state.cash = ScientificNumber.new(1.0, 9)
	var before := state.get_rig_cost(GameState.ARMOR_ID)
	state.purchase_rig("generator")
	_expect(state.get_rig_cost(GameState.ARMOR_ID).compare_to(before) > 0, "a rank that raises income should raise every next price")
	# A row that raises income climbs a little faster than its growth, and a
	# single-rank quote always matches what that rank then costs.
	var ladder := GameState.new()
	ladder.start_run(1, 5)
	ladder.cash = ScientificNumber.new(1.0, 9)
	for rank in range(8):
		var quoted: ScientificNumber = ladder.plan_rig_purchase("generator", 1).cost
		var price := ladder.get_rig_cost("generator")
		_expect(quoted.compare_to(price) == 0, "a one-rank quote should equal the live price (rank " + str(rank + 1) + ")")
		ladder.purchase_rig("generator")
	var poor := GameState.new()
	poor.purchased = {}
	_expect(poor.balance_profile.rig_cost(ProgressionTaxonomy.ATTACK, 0, 0.0).compare_to(ScientificNumber.from_float(profile.RIG_PRICE_SECONDS)) == 0, "a price should never fall below the base income's worth")

func _test_rig_purchase_spends_cash_and_stacks() -> void:
	var state := _funded_state()
	state.start_run(1, 6)
	state.cash = ScientificNumber.from_float(1.0e9)
	var base_tap := state._tap_base()
	var price := state.get_rig_cost("stronger_tap")
	var before_cash: ScientificNumber = state.cash.copy()
	var before_number: ScientificNumber = state.number.copy()
	_expect(state.purchase_rig("stronger_tap"), "a Rig rank should purchase with enough Cash")
	_expect(state.rig_owned("stronger_tap") == 1 and state.get_owned("stronger_tap") == 0, "the Rig rank should land beside the permanent Workshop rank, not inside it")
	_expect(state.cash.compare_to(before_cash.subtract(price)) == 0, "the purchase should spend exactly the quoted Cash")
	_expect(state.number.compare_to(before_number) == 0, "the purchase must leave Number completely untouched")
	var multiplier: float = state.balance_profile.rig_effect_multiplier(ProgressionTaxonomy.ATTACK, "stronger_tap")
	_expect(is_equal_approx(state._tap_base(), base_tap + 0.05 * multiplier), "a Rig rank should grant its multiplier of one Workshop rank's effect")
	_expect(state.get_workshop_level() == 0, "Rig ranks must not raise the Workshop level")
	# D044: Workshop and run ranks together stop at the row's max rank.
	state.cash = ScientificNumber.new(1.0, 40)
	var cap: int = state.get_definition("generator_two").max_rank
	for rank in range(cap):
		_expect(state.purchase_rig("generator_two"), "run ranks should sell up to the row's max rank")
	_expect(state.rig_owned("generator_two") == cap and state.rig_room("generator_two") == 0, "run ranks should fill the row exactly to its max rank")
	var cash_at_cap: ScientificNumber = state.cash.copy()
	_expect(not state.can_purchase_rig("generator_two") and not state.purchase_rig("generator_two"), "a full row should sell no more run ranks")
	_expect(state.cash.compare_to(cash_at_cap) == 0 and int(state.plan_rig_purchase("generator_two", GameState.MAX_BUY).ranks) == 0, "a full row should quote nothing and spend nothing")

## D044: a row maxed in the Workshop sells nothing in a run, and a part-built
## row sells only the ranks it has left, whatever the press asks for.
func _test_rig_stops_at_the_rows_max_rank() -> void:
	var state := _funded_state()
	var definition := state.get_definition("generator_two")
	var crit := state.get_definition("more_critical")
	state.purchased = {"generator_two": definition.max_rank, "more_critical": crit.max_rank - 3}
	state.start_run(1, 19)
	state.cash = ScientificNumber.new(1.0, 40)
	_expect(state.rig_room("generator_two") == 0 and not state.can_purchase_rig("generator_two"), "a Workshop-maxed row should sell nothing in a run")
	_expect(state.purchase_rig_ranks("generator_two", GameState.MAX_BUY) == 0, "MAX on a Workshop-maxed row should buy nothing")
	_expect(state.rig_room("more_critical") == 3, "a row should have room for its unbought ranks only")
	_expect(int(state.plan_rig_purchase("more_critical", 5).ranks) == 3, "an x5 press should quote only the room left")
	_expect(state.purchase_rig_ranks("more_critical", GameState.MAX_BUY) == 3 and state.rig_room("more_critical") == 0, "MAX should fill the row to its max rank and stop")

func _test_rig_multi_buy_quotes_and_spends() -> void:
	# An opening x5 press buys what it can afford, and exactly what buying the
	# same ranks one at a time would: each rank raises income and the next price.
	var fresh := GameState.new()
	fresh.start_run(1, 7)
	var one_by_one := GameState.new()
	one_by_one.start_run(1, 7)
	var partial := fresh.plan_rig_purchase("generator", 5)
	_expect(int(partial.ranks) > 0 and int(partial.ranks) < 5, "an opening x5 press should quote only the ranks the starting Cash affords")
	_expect(fresh.rig_owned("generator") == 0 and not fresh.rig_ranks.has("generator"), "quoting should leave the run's Rig ranks untouched")
	var before_cash: ScientificNumber = fresh.cash.copy()
	var before_number: ScientificNumber = fresh.number.copy()
	_expect(fresh.purchase_rig_ranks("generator", 5) == int(partial.ranks), "an opening x5 press should buy exactly the quoted ranks")
	_expect(fresh.cash.compare_to(before_cash.subtract(partial.cost)) == 0, "the opening bulk press should spend exactly its quote")
	_expect(fresh.number.compare_to(before_number) == 0, "bulk Rig purchases must not touch Number")
	for rank in range(int(partial.ranks)):
		one_by_one.purchase_rig("generator")
	_expect(one_by_one.cash.compare_to(fresh.cash) == 0 and one_by_one.rig_owned("generator") == fresh.rig_owned("generator"), "a bulk press should cost exactly what the same ranks cost singly")

	var bulk := _funded_state()
	var singles := _funded_state()
	bulk.start_run(1, 17)
	singles.start_run(1, 17)
	bulk.cash = ScientificNumber.from_float(10000.0)
	singles.cash = ScientificNumber.from_float(10000.0)
	var five := bulk.plan_rig_purchase("stronger_tap", 5)
	_expect(int(five.ranks) == 5, "a funded x5 press should quote five Rig ranks")
	for rank in range(5):
		_expect(singles.purchase_rig("stronger_tap"), "the comparison run should buy each Rig rank singly")
	_expect(bulk.purchase_rig_ranks("stronger_tap", 5) == 5, "a funded x5 press should grant five ranks")
	_expect(bulk.cash.compare_to(singles.cash) == 0 and bulk.rig_owned("stronger_tap") == singles.rig_owned("stronger_tap"), "bulk and single Rig buys should spend the same Cash and grant the same ranks")

	# Past rank 100 each run rank moves further along the depth curve (D047).
	var deep_bulk := _funded_state()
	var deep_singles := _funded_state()
	for deep_state in [deep_bulk, deep_singles]:
		deep_state.purchased["stronger_tap"] = 2000
		deep_state.start_run(1, 19)
		deep_state.cash = ScientificNumber.from_float(1.0e9)
	_expect(int(deep_bulk.plan_rig_purchase("stronger_tap", 5).ranks) == 5, "a funded deep-row x5 press should quote five run ranks")
	for rank in range(5):
		deep_singles.purchase_rig("stronger_tap")
	deep_bulk.purchase_rig_ranks("stronger_tap", 5)
	_expect(deep_bulk.cash.compare_to(deep_singles.cash) == 0 and is_equal_approx(deep_bulk._tap_base(), deep_singles._tap_base()), "a deep-row run press should cost and add what single presses do")

	var maxed := _funded_state()
	maxed.start_run(1, 18)
	maxed.cash = ScientificNumber.from_float(10000.0)
	var all := maxed.plan_rig_purchase("stronger_tap", GameState.MAX_BUY)
	var max_before: ScientificNumber = maxed.cash.copy()
	_expect(int(all.ranks) > 5, "Rig MAX should quote every affordable rank, past x5")
	_expect(maxed.purchase_rig_ranks("stronger_tap", GameState.MAX_BUY) == int(all.ranks), "Rig MAX should buy exactly its quoted ranks")
	_expect(maxed.cash.compare_to(max_before.subtract(all.cost)) == 0 and not maxed.can_purchase_rig("stronger_tap"), "Rig MAX should spend its quote and leave the next rank unaffordable")
	_expect(maxed.purchase_rig_ranks("stronger_tap", 0) == 0 and maxed.purchase_rig_ranks("not_a_row", GameState.MAX_BUY) == 0, "invalid Rig multi-buy requests should change nothing")

func _test_rig_is_run_scoped() -> void:
	var state := _funded_state()
	state.start_run(1, 7)
	state.cash = ScientificNumber.from_float(1.0e9)
	var base_tap := state._tap_base()
	_expect(state.purchase_rig("stronger_tap"), "a Rig rank should purchase during the run")
	_expect(state.end_run() != null, "retreat should end the run")
	_expect(state.rig_ranks.is_empty() and state.cash.is_zero(), "retreat should clear the Rig and Cash")
	_expect(is_equal_approx(state._tap_base(), base_tap), "Rig effects should end with the run")

	# Death shares the ending machinery, so it clears the Rig too.
	state.start_run(1, 7)
	state.cash = ScientificNumber.from_float(1.0e9)
	_expect(state.purchase_rig("stronger_tap"), "the next run should buy its own Rig rank")
	state.wave = 21
	state.active_encounter = state._make_encounter(21)
	state.number = ScientificNumber.from_float(1.0)
	state._resolve_wave_boundary()
	_expect(not state.in_run and state.rig_ranks.is_empty() and state.cash.is_zero(), "death should clear the Rig and Cash like every other ending")

	# Prestige shares the same reset, so it clears the Rig too.
	var prestige_state := _funded_state()
	prestige_state.start_run(1, 7)
	prestige_state.cash = ScientificNumber.from_float(1.0e9)
	_expect(prestige_state.purchase_rig("stronger_tap"), "the Prestige fixture should hold a Rig rank")
	prestige_state.lifetime_generated = ScientificNumber.from_float(1.0e6)
	_expect(prestige_state.prestige() > 0 and prestige_state.rig_ranks.is_empty() and prestige_state.cash.is_zero(), "Prestige should clear the Rig and Cash")

func _test_rig_refuses_what_it_does_not_sell() -> void:
	var state := _funded_state()
	_expect(not state.purchase_rig("stronger_tap"), "the Rig must refuse a purchase outside a run")
	state.start_run(1, 8)
	state.cash = ScientificNumber.from_float(1.0e9)
	for category in state.balance_profile.RIG_ROWS:
		for row_id in state.balance_profile.RIG_ROWS[category]:
			_expect(state.can_purchase_rig(row_id), "the Rig must sell all 21 Workshop rows in-run: " + row_id)
	_expect(not state.can_purchase_rig("not_a_row"), "an unknown row should quote nothing")

	var poor := _funded_state()
	poor.start_run(1, 9)
	poor.cash = ScientificNumber.from_float(0.0)
	_expect(not poor.purchase_rig("stronger_tap"), "a rank the Cash cannot cover should refuse")

	# The exact price sells and leaves zero Cash: the contract is a visible
	# price, not a refusal (D015).
	var exact := _funded_state()
	exact.start_run(1, 10)
	exact.cash = exact.get_rig_cost("stronger_tap").copy()
	_expect(exact.purchase_rig("stronger_tap"), "a rank the Cash exactly covers should sell")
	_expect(exact.cash.is_zero(), "spending the exact price should leave zero Cash")

## D042: Cash comes in at the same income the Rig's prices are quoted in, so a
## rank that speeds up ticks never raises prices faster than Cash.
func _test_cash_flows_at_the_priced_income() -> void:
	var state := GameState.new()
	state.purchased = {"generator": 50, "faster_cadence": 60}
	state.start_run(1, 21)
	state.cash = ScientificNumber.new()
	var ticks := 200
	for tick in range(ticks):
		state._produce_tick()
	var seconds := float(ticks) / state._tick_rate()
	var expected := state.get_rig_income_rate() * seconds
	_expect(state._tick_rate() > TaxBalanceProfile.BASE_SHOTS_PER_SECOND * 1.5, "the fixture should shoot well above the base rate")
	_expect(absf(state.cash.log10() - log(expected) / log(10.0)) < 0.0001, "Cash should flow at the Rig's priced income per second")
	var outside := GameState.new()
	outside._produce_tick()
	_expect(outside.cash.is_zero(), "no Cash should flow outside a run")

	var profile := TaxBalanceProfile.new()
	_expect(is_equal_approx(profile.wave_cash(1), 15.0) and is_equal_approx(profile.wave_cash(21), 115.0) and is_equal_approx(profile.wave_cash(10), 180.0), "a beaten wave should pay 10 + 5 x its number in Cash, x3 on a boss")
	var clearing := GameState.new()
	clearing.start_run(1, 22)
	var before: ScientificNumber = clearing.cash.copy()
	clearing.active_encounter.remaining_liability = ScientificNumber.new()
	clearing._complete_current_wave()
	_expect(clearing.cash.compare_to(before.add(ScientificNumber.from_float(profile.wave_cash(1)))) == 0, "beating wave 1 should pay its Cash")
	_expect(clearing.run_cash_earned.compare_to(clearing.cash) == 0, "Cash earned should count the wave's Cash")

## Cushion is starting Number, and an in-run rank arrives after the start, so
## the Rig pays it into this run's Number at the Rig's worth and the tier's scale.
func _test_rig_cushion_pays_its_number_now() -> void:
	for tier in [1, 2]:
		var state := _funded_state()
		state.tier_records["1"] = {"highest_wave": GameState.TIER_UNLOCK_WAVE, "best_time": 0.0, "milestones_claimed": []}
		_expect(state.start_run(tier, 23), "the Cushion fixture should start Tier " + str(tier))
		state.cash = ScientificNumber.from_float(1.0e9)
		var before: ScientificNumber = state.number.copy()
		var definition := state.get_definition("priority_buffer")
		var per_rank := float(definition.effects["starting_number_flat"]) * state.balance_profile.rig_effect_multiplier(definition.workshop_category, "priority_buffer") * state.get_cushion_scale()
		_expect(state.purchase_rig_ranks("priority_buffer", 2) == 2, "two Cushion ranks should sell")
		_expect(state.number.compare_to(before.add(ScientificNumber.from_float(per_rank * 2.0))) == 0, "Rig Cushion should add its Number now (Tier " + str(tier) + ")")
		_expect(state.run_peak_number.compare_to(state.number) >= 0, "the run peak should include Cushion's Number")
	var armor := _funded_state()
	armor.start_run(1, 24)
	armor.cash = ScientificNumber.from_float(1.0e9)
	var number_before: ScientificNumber = armor.number.copy()
	armor.purchase_rig(GameState.ARMOR_ID)
	_expect(armor.number.compare_to(number_before) == 0, "a row without starting Number should leave Number alone")

## GAME_INVARIANTS: a bulk press costs what the same ranks cost singly. Each
## Discount rank lowers the next Rig price, so the quote has to follow it.
func _test_rig_discount_bulk_matches_singles() -> void:
	var bulk := _funded_state()
	var singles := _funded_state()
	bulk.start_run(1, 25)
	singles.start_run(1, 25)
	bulk.cash = ScientificNumber.from_float(1.0e6)
	singles.cash = ScientificNumber.from_float(1.0e6)
	var single_price := singles.get_rig_cost("stronger_tap")
	_expect(bulk.purchase_rig_ranks("smarter_efficiency", 5) == 5, "a funded x5 Discount press should buy five")
	for rank in range(5):
		_expect(singles.purchase_rig("smarter_efficiency"), "the comparison run should buy each Discount rank singly")
	_expect(bulk.cash.compare_to(singles.cash) == 0, "bulk and single Discount buys should spend the same Cash")
	_expect(singles.get_rig_cost("stronger_tap").compare_to(single_price) < 0, "Rig Discount ranks should lower other Rig prices")

func _test_rig_save_round_trip() -> void:
	var save_path := "res://.number_go_up_test_save.json"
	var original := _funded_state()
	original.save_path = save_path
	original.start_run(1, 77)
	original.cash = ScientificNumber.from_float(1.0e9)
	_expect(original.purchase_rig("stronger_tap") and original.purchase_rig("coin_bonus"), "the fixture should hold two Rig ranks")
	var saved_cash: ScientificNumber = original.cash.copy()
	var saved_number: ScientificNumber = original.number.copy()
	var saved_rng := original.rng.state
	_expect(original.save(), "the Rig save should write")
	var restored := GameState.new()
	restored.save_path = save_path
	restored.load()
	_expect(restored.rig_owned("stronger_tap") == 1 and restored.rig_owned("coin_bonus") == 1, "Rig ranks should round-trip with the active run")
	_expect(restored.cash.compare_to(saved_cash) == 0, "the Cash left after Rig spending should round-trip")
	_expect(restored.number.compare_to(saved_number) == 0, "the Number left after Rig spending should round-trip")
	_expect(restored.rng.state == saved_rng, "Rig spending must not disturb the RNG state")
	restored.clear_save()

	# A save written before the Rig existed resumes with no ranks, and a
	# malformed Rig block reads as empty rather than crashing.
	var pre_rig := GameState.new()
	pre_rig.save_path = save_path
	pre_rig.start_run(1, 5)
	var legacy: Dictionary = SaveDataV11.make(pre_rig)
	legacy.erase("rig_ranks")
	legacy.erase("cash")
	_write_json(save_path, legacy)
	var loaded := GameState.new()
	loaded.save_path = save_path
	loaded.load()
	_expect(loaded.in_run and loaded.rig_ranks.is_empty() and loaded.cash.is_zero(), "a pre-Rig save should resume with an empty Rig and zero Cash")
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
	var v6: Dictionary = SaveDataV11.make(_funded_state())
	v6.version = 6
	v6.erase("lab_slots")
	_write_json(save_path, v6)
	var migrated := GameState.new()
	migrated.save_path = save_path
	migrated.load()
	_expect(migrated.lab_slots_total() == LabResearch.LEGACY_SLOTS, "a V6 save should keep its two Lab slots")
	_expect(int(_read_json(save_path).get("version", 0)) == SaveDataV11.VERSION and int(_read_json("res://.number_go_up_test_save.v6-backup.json").get("version", 0)) == 6, "a V6 save should be rewritten in the current version, with the V6 file kept")
	migrated.clear_save()
	for stored in [99, -3, 0]:
		var odd: Dictionary = SaveDataV11.make(_funded_state())
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
	var legacy: Dictionary = SaveDataV11.make(_funded_state())
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
	_expect(not state.has_unmaxed_cards(), "all cards should now be maxed")
	_expect(not state.can_pull_card(), "pulls should be disabled when all cards are maxed")
	var gems_at_cap := state.gems
	_expect(state.pull_card() == "" and state.gems == gems_at_cap, "pulling when all cards are maxed must not spend gems")

func _test_card_pull_duplicate_protection() -> void:
	var state := _funded_state()
	state.gems = 1000
	state.card_ranks["card_damage"] = CardCollection.MAX_LEVEL
	for i in range(20):
		var drawn := state.pull_card()
		if drawn != "":
			_expect(drawn != "card_damage", "a maxed card should never be drawn while other cards can level up")

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
	var legacy: Dictionary = SaveDataV11.make(_funded_state())
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
	state.cash = ScientificNumber.from_float(1.0e12)
	var before := state._tap_base()
	var multiplier: float = state.balance_profile.rig_effect_multiplier(ProgressionTaxonomy.ATTACK, "stronger_tap")
	_expect(multiplier > 1.0, "a Rig rank should be worth more than a Workshop rank")
	_expect(state.purchase_rig("stronger_tap"), "the Rig rank should buy")
	_expect(is_equal_approx(state._tap_base(), before + 0.05 * multiplier), "one Rig rank should grant its multiplier of a Workshop rank's effect")
	_expect(state.purchase_rig("burst_relay"), "a Rig Burst rank should buy")
	_expect(state._burst_interval() == 11, "a Rig Burst rank should shorten the interval by one step, not by its multiplier")

## D023: the combined defensive effects are bounded. Run ranks worth more than
## Workshop ranks, Labs and Cards can all stack past a row's own cap, so the
## fixture stands in for them with ranks past the Workshop maximum.
func _test_defensive_ceilings_bound_the_combined_effects() -> void:
	var state := _funded_state()
	state.start_run(1, 13)
	state.purchased = {GameState.ARMOR_ID: 250, "siphon": 300, "recoil": 300}
	_expect(state._effect_sum("collection_resistance") > state.balance_profile.COLLECTION_RESISTANCE_CEILING, "the fixture should stack Armor past its ceiling")
	# A lone boss, so Leech and Thorns reach it rather than enemies in front.
	state.wave = 30
	_one_enemy(state, state.balance_profile.liability_for_wave(1, 30))
	var base: ScientificNumber = state.active_encounter.collection.copy()
	var effective := state.get_effective_collection()
	_expect(effective.compare_to(base.multiply_scalar(1.0 - state.balance_profile.COLLECTION_RESISTANCE_CEILING)) == 0, "a hit should never fall below the combined Armor ceiling")
	_expect(not effective.is_zero(), "the ceiling keeps hits real, not free")

	# Leech: the applied share is capped even when the ranks stack past it.
	# Wave 30 is a boss, which is the only wave Leech feeds on.
	_expect(state._effect_sum("siphon_share") > state.balance_profile.SIPHON_CEILING, "the fixture should stack Leech past its ceiling")
	state.number = ScientificNumber.new()
	state._add_number(ScientificNumber.from_float(100))
	_expect(state.number.compare_to(ScientificNumber.from_float(100.0 * (1.0 + state.balance_profile.SIPHON_CEILING))) == 0, "Leech should add exactly the capped share")

	# Thorns: never more than the ceiling's share of an enemy's maximum HP,
	# halved on a boss (D064).
	_expect(state._effect_sum("recoil_share") > state.balance_profile.RECOIL_CEILING, "the fixture should stack Thorns past its ceiling")
	var ceiling_boss_max: ScientificNumber = state.active_encounter.members[0].max.copy()
	var liability_before: ScientificNumber = state.active_encounter.members[0].hp.copy()
	state.number = ScientificNumber.new(1.0, 40)
	state._resolve_wave_boundary()
	# The boss joins the next wave's pile (D063); its own HP shows what came off.
	var dealt := liability_before.subtract(state.active_encounter.members[state.active_encounter.boss_index()].hp)
	_expect(absf(dealt.log10() - ceiling_boss_max.multiply_scalar(state.balance_profile.RECOIL_CEILING * state.balance_profile.BOSS_THORNS_SHARE).log10()) < 1.0e-9, "Thorns should stop at its ceiling's share of a boss's maximum HP")

## D057, D065: a wave is a group of many enemies, each with the full enemy
## HP, as The Tower's are: 20 at wave 1, about 142 by wave 1,000, capped at
## 220. A boss wave adds a boss carrying twenty enemies' HP. Members walk in as
## a column, the front arriving at 6 seconds and the last 26 seconds later.
func _test_a_wave_is_a_group() -> void:
	var profile := TaxBalanceProfile.new()
	_expect(profile.members_for_wave(1) == 20 and profile.members_for_wave(9) == 20 and profile.members_for_wave(101) == 32, "a wave should start as twenty enemies and grow with the wave")
	_expect(profile.members_for_wave(100) == profile.ordinary_members(100) + 1 and profile.member_weights(100).count(profile.BOSS_HP_WEIGHT) == 1, "a boss wave should add one boss to its enemies")
	_expect(profile.members_for_wave(999) == 142 and profile.members_for_wave(10001) == profile.MAX_WAVE_MEMBERS, "the count should reach about 142 at wave 1,000 and stop at its cap")
	_expect(is_equal_approx(profile.member_arrival(0, 20), 6.0) and is_equal_approx(profile.member_arrival(19, 20), 32.0) and is_equal_approx(profile.member_arrival(0, 1), 6.0), "enemies should arrive from 6 seconds through the next 26")
	_expect(profile.member_arrivals(10).has(profile.BOSS_ARRIVAL_SECONDS) and _sorted(profile.member_arrivals(10)), "a boss should walk in among its wave in arrival order")
	var state := GameState.new()
	state.start_run(1, 51)
	var encounter = state.active_encounter
	var count: int = encounter.members.size()
	var total := ScientificNumber.new()
	for member in encounter.members:
		total = total.add(member.max)
		_expect(is_equal_approx(float(member.share), 1.0 / float(count)), "each enemy should carry an equal share of an ordinary wave")
	_expect(absf(total.log10() - encounter.max_liability.log10()) < 0.000001, "the members' HP should add up to the wave's")
	_expect(absf(encounter.members[0].max.log10() - profile._from_log10(profile._wave_hp_log10(1)).log10()) < 0.000001, "each enemy should carry the full enemy HP (D065)")
	_expect(is_equal_approx(state.next_hit_share(), 1.0 / float(count)) and state.get_hit_breakdown().final.compare_to(state.get_effective_collection().multiply_scalar(1.0 / float(count))) == 0, "the next Hit shown should be the front member's share")
	# Damage strikes the front member, and what passes its HP is lost.
	var front_hp: ScientificNumber = encounter.members[0].hp.copy()
	var applied: ScientificNumber = encounter.apply_compliance(front_hp.multiply_scalar(2.0))
	_expect(applied.compare_to(front_hp) == 0 and encounter.members[0].hp.is_zero() and encounter.members[1].hp.compare_to(encounter.members[1].max) == 0, "a blow should stop at the front member")
	_expect(encounter.front_index() == 1 and encounter.standing_count() == count - 1, "the next member should become the front")

func _sorted(values: Array) -> bool:
	for index in range(1, values.size()):
		if float(values[index]) < float(values[index - 1]):
			return false
	return true

## D057: each member left standing reaches the Number at its arrival time and
## lands its share of the Hit. A wave with a member still standing when its
## clock runs out is passed, not beaten, and pays for the share it cleared.
func _test_group_members_land_one_by_one() -> void:
	var state := GameState.new()
	state.start_run(1, 52)
	state.number = ScientificNumber.from_float(1e6)
	var count: int = state.active_encounter.members.size()
	var share_hit := state.get_effective_collection().multiply_scalar(1.0 / float(count))
	var start := state.number.copy()
	var events := state._advance_waves(0.25)
	for step in range(22):
		events.append_array(state._advance_waves(0.25))
	var hits := events.filter(func(event): return event.type == "tax_collection")
	_expect(hits.size() == 0 and state.number.compare_to(start) == 0, "nothing should land before the front member arrives at 6 seconds")
	events = state._advance_waves(0.25)
	hits = events.filter(func(event): return event.type == "tax_collection")
	_expect(hits.size() == 1 and hits[0].amount.compare_to(share_hit) == 0, "the front member should land its share of the Hit at 6 seconds")
	_expect(state.number.compare_to(start.subtract(share_hit)) == 0 and state.active_encounter.landed_count() == 1 and state.wave == 1, "one landing should cost its share and the wave should stand on")
	var landed := 1
	for step in range(120):
		landed += state._advance_waves(0.25).filter(func(event): return event.type == "tax_collection").size()
	_expect(landed == count and state.wave == 2, "every member should land by 32 seconds and the wave should pass at 35")
	_expect(int(state.get_tier_record(1).highest_wave) == 0, "a passed wave should set no record")

	# Beat the front two in time: only the last lands, and the wave pays for
	# the two thirds it cleared.
	var partial := GameState.new()
	partial.start_run(1, 53)
	partial.number = ScientificNumber.from_float(1e6)
	partial.wave = 7
	partial.active_encounter = partial._make_encounter(7)
	var reward: int = partial.active_encounter.reward
	var partial_count: int = partial.active_encounter.members.size()
	var coins_before := partial.coins
	for kill in range(2):
		partial.active_encounter.apply_compliance(partial.active_encounter.members[kill].hp)
	var partial_hits := 0
	for step in range(141):
		partial_hits += partial._advance_waves(0.25).filter(func(event): return event.type == "tax_collection").size()
	_expect(partial_hits == partial_count - 2 and partial.wave == 8, "with two beaten, only the rest should land and the wave should pass")
	_expect(partial.coins - coins_before == floori(float(reward) * 2.0 / float(partial_count) + 0.000001), "a passed wave should pay for the share it cleared")

	# Beat every member in time: no landing, and the wave is beaten.
	var clean := GameState.new()
	clean.start_run(1, 54)
	_beat_wave(clean)
	var clean_events: Array = []
	for step in range(12):
		clean_events.append_array(clean._advance_waves(0.25))
	_expect(clean.wave == 2 and clean_events.any(func(event): return event.type == "wave_clear") and clean.get_tier_record(1).highest_wave >= 1, "a wave beaten before any member lands should count as beaten")

	# A landing that empties the Number ends the run, with that landing as the
	# Hit that did it.
	var fatal := GameState.new()
	fatal.start_run(1, 55)
	fatal.number = ScientificNumber.from_float(0.5)
	var fatal_events: Array = []
	for step in range(25):
		fatal_events.append_array(fatal._advance_waves(0.25))
	_expect(not fatal.in_run and fatal_events.any(func(event): return event.type == "wave_death") and fatal.last_run_summary.wave_reached == 1, "a landing that empties the Number should end the run")

## D057: Brace blocks every member of the wave it was raised against and is
## spent when that wave ends; Guard and Armor work on the whole Hit, so each
## member lands its share of what the single wave would have; Thorns returns a
## share of each landing to what still stands.
func _test_group_brace_guard_and_thorns() -> void:
	var braced := GameState.new()
	braced.start_run(1, 56)
	braced.number = ScientificNumber.from_float(1e6)
	_expect(braced.brace(), "a Brace should be raised")
	var after_brace := braced.number.copy()
	for step in range(43):
		braced._advance_waves(0.25)
	# By 10.75 seconds the first four of wave 1's twenty have arrived (D065).
	_expect(braced.wave == 1 and braced.active_encounter.landed_count() == 4 and braced.number.compare_to(after_brace) == 0, "a Brace should block the first four members")
	for step in range(98):
		braced._advance_waves(0.25)
	_expect(braced.wave == 2 and braced.number.compare_to(after_brace) == 0 and not braced.braced, "a Brace should block every member and be spent when the wave ends")

	var guarded := GameState.new()
	guarded.purchased = {"guard": 3}
	guarded.start_run(1, 57)
	guarded.number = ScientificNumber.from_float(1e6)
	guarded.wave = 31
	guarded.active_encounter = guarded._make_encounter(31)
	var own_hit: ScientificNumber = guarded.active_encounter.collection.multiply_scalar(guarded.active_encounter.members[0].share)
	var before := guarded.number.copy()
	for step in range(25):
		guarded._advance_waves(0.25)
	_expect(before.subtract(guarded.number).compare_to(own_hit.subtract(ScientificNumber.from_float(3.0))) == 0, "a member should land its own share of the Hit less Guard (D063)")

	var thorny := GameState.new()
	thorny.purchased = {"recoil": 100}
	thorny.start_run(1, 58)
	thorny.number = ScientificNumber.from_float(1e6)
	thorny.wave = 31
	thorny.active_encounter = thorny._make_encounter(31)
	var standing_before: ScientificNumber = thorny.active_encounter.remaining_liability.copy()
	var front_hp: ScientificNumber = thorny.active_encounter.members[0].hp.copy()
	var thorns: ScientificNumber = thorny.active_encounter.members[0].max.multiply_scalar(minf(thorny._effect_sum("recoil_share"), thorny.balance_profile.RECOIL_CEILING))
	for step in range(25):
		thorny._advance_waves(0.25)
	# The member that hit takes a share of its own maximum HP (D064).
	var expected_left := standing_before.subtract(thorns if thorns.compare_to(front_hp) < 0 else front_hp)
	_expect(thorny.active_encounter.landed_count() == 1 and absf(thorny.active_encounter.remaining_liability.log10() - expected_left.log10()) < 0.000001, "Thorns should deal the enemy that hit a share of its own maximum HP")

## D057: V10 keeps each member's HP and state, so a run saved mid-wave resumes
## exactly; a V9 run resumes its wave as a group, keeping the share cleared.
func _test_group_saves_and_resumes() -> void:
	var save_path := "res://.number_go_up_test_save.json"
	var source := GameState.new()
	source.save_path = save_path
	source.start_run(1, 59)
	source.number = ScientificNumber.from_float(1e6)
	source.wave = 31
	source.active_encounter = source._make_encounter(31)
	source.active_encounter.apply_compliance(source.active_encounter.members[0].hp)
	source.active_encounter.apply_compliance(source.active_encounter.members[1].hp.multiply_scalar(0.5))
	for step in range(46):
		source.advance(0.25)
	_expect(source.active_encounter.landed_count() >= 1 and source.active_encounter.members[0].state == TaxEncounter.KILLED, "the fixture should have a beaten member and a landed one")
	_expect(source.save(), "a mid-wave group should save")
	var saved := _read_json(save_path)
	_expect(int(saved.version) == SaveDataV11.VERSION and saved.active_encounter.members.size() == source.active_encounter.members.size(), "V10 should write every member")
	var resumed := GameState.new()
	resumed.save_path = save_path
	resumed.load()
	_expect(resumed.active_encounter.members.size() == source.active_encounter.members.size(), "every member should come back")
	for index in range(source.active_encounter.members.size()):
		var a: Dictionary = source.active_encounter.members[index]
		var b: Dictionary = resumed.active_encounter.members[index]
		_expect(int(a.state) == int(b.state) and a.hp.compare_to(b.hp) == 0 and is_equal_approx(float(a.arrive), float(b.arrive)), "member %d should resume exactly" % index)
	_expect(resumed.active_encounter.own_uncleared().compare_to(source.active_encounter.own_uncleared()) == 0 and resumed.active_encounter.at_number_count() == source.active_encounter.at_number_count(), "the members at the Number should resume")
	for step in range(120):
		source.advance(0.25)
		resumed.advance(0.25)
	_expect(resumed.wave == source.wave and resumed.number.compare_to(source.number) == 0 and resumed.coins == source.coins, "a resumed group should play out exactly as the saved one")
	resumed.clear_save()

	# A V9 run saved before groups: its wave was one pool of HP.
	var old := GameState.new()
	old.save_path = save_path
	old.start_run(1, 60)
	old.wave = 31
	old.active_encounter = old._make_encounter(31)
	var v9: Dictionary = SaveDataV11.make(old)
	v9.version = 9
	v9.erase("brace_spent")
	v9.balance_profile_id = "tax-foundation-v10"
	v9.active_encounter.erase("members")
	v9.active_encounter.erase("passed_liability")
	v9.active_encounter.remaining_liability = ScientificNumber.from_dict(v9.active_encounter.max_liability).multiply_scalar(0.4).to_dict()
	_write_json(save_path, v9)
	var migrated := GameState.new()
	migrated.save_path = save_path
	migrated.load()
	_expect(migrated.in_run and migrated.wave == 31 and migrated.active_encounter.members.size() == migrated.balance_profile.members_for_wave(31), "a V9 run should resume its wave as a group")
	_expect(absf(migrated.get_wave_cleared_share() - 0.6) < 0.0001 and migrated.active_encounter.front_index() > 0, "a V9 wave should keep the share it had cleared, taken off the front")
	_expect(int(_read_json(save_path).get("version", 0)) == SaveDataV11.VERSION and int(_read_json("res://.number_go_up_test_save.v9-backup.json").get("version", 0)) == 9, "a V9 save should be rewritten as V10, with the V9 file kept")
	migrated.clear_save()

	# A run saved on an older balance profile keeps each member's state, so a
	# member that has landed never lands again on load.
	var landed_once := GameState.new()
	landed_once.save_path = save_path
	landed_once.start_run(1, 61)
	landed_once.number = ScientificNumber.from_float(1e6)
	landed_once.wave = 31
	landed_once.active_encounter = landed_once._make_encounter(31)
	while landed_once.active_encounter.landed_count() == 0:
		landed_once._advance_waves(0.25)
	var number_after_landing := landed_once.number.copy()
	var states_before: Array = landed_once.active_encounter.members.map(func(member): return int(member.state))
	_expect(landed_once.save(), "the landed fixture should save")
	var older_profile := _read_json(save_path)
	older_profile.balance_profile_id = "tax-foundation-v10"
	_write_json(save_path, older_profile)
	var rebuilt := GameState.new()
	rebuilt.save_path = save_path
	rebuilt.load()
	_expect(rebuilt.active_encounter.members.map(func(member): return int(member.state)) == states_before, "a rebuilt wave should keep each member's state")
	rebuilt._advance_waves(0.05)
	_expect(rebuilt.number.compare_to(number_after_landing) == 0, "a member that landed before the save should not land again")
	rebuilt.clear_save()

	for bad_members in ["three", [1, 2, 3], [{"hp": 5, "max": {}}]]:
		var malformed: Dictionary = SaveDataV11.make(GameState.new())
		malformed.active_encounter = {"members": bad_members}
		_write_json(save_path, malformed)
		var turned_away := GameState.new()
		turned_away.save_path = save_path
		turned_away.load()
		_expect(turned_away.load_status == GameState.LOAD_UNREADABLE, "a save with malformed members should be refused whole: %s" % str(bad_members))
		turned_away.clear_save()

	var damaged: Dictionary = SaveDataV11.make(GameState.new())
	damaged.active_encounter = {"members": "three"}
	_write_json(save_path, damaged)
	var refused := GameState.new()
	refused.save_path = save_path
	refused.load()
	_expect(refused.load_status == GameState.LOAD_UNREADABLE, "a save whose members are not a list should be refused whole")
	refused.clear_save()

## D058: a member that reaches the Number stays and hits again every
## MEMBER_HIT_SECONDS until beaten. When its wave's clock runs out it carries
## into the next wave, in front, so an unbeaten pile grows wave on wave. A boss
## holds the clock and hits every 15 seconds. A member beaten after landing
## still counts towards beating its wave, and a Brace covers the whole clock.
## D063: a boss is a wall that joins the pile when its wave passes, Boss Damage
## and Leech follow the boss itself rather than whatever stands in front of it,
## heat-up and the boss marker survive a save, and older saves load with safe
## defaults.
func _test_tower_shaped_bosses_and_heat_up() -> void:
	var state := GameState.new()
	state.balance_profile.OPENING_HIT_WAVES = 0
	state.balance_profile.OPENING_EASED_BY = 0
	state.purchased = {"boss_damage": 100, "siphon": 100}
	state.start_run(1, 91)
	state.number = ScientificNumber.from_float(1e12)
	state.wave = 20
	state.active_encounter = _lone_boss(state, 20)
	_expect(state._boss_damage_multiplier() > 1.0, "Boss Damage should work on a boss in its own wave")
	state._resolve_wave_boundary()
	var boss_at: int = state.active_encounter.boss_index()
	_expect(state.wave == 21 and boss_at == 0, "the unbeaten boss should lead the next wave's pile")
	_expect(state._boss_damage_multiplier() > 1.0, "Boss Damage should follow the boss into the next wave")
	# Leech feeds on damage to the boss itself.
	state.number = ScientificNumber.from_float(1000)
	state._add_number(ScientificNumber.from_float(100))
	_expect(state.number.compare_to(ScientificNumber.from_float(1125)) == 0, "Leech should feed on the carried boss")
	state.number = ScientificNumber.from_float(1e12)
	# With the boss beaten, what stands in front is ordinary: neither applies.
	state._add_number(state.active_encounter.members[boss_at].hp.copy())
	state.active_encounter.members[1].state = TaxEncounter.AT_NUMBER
	_expect(state.active_encounter.boss_index() < 0 and is_equal_approx(state._boss_damage_multiplier(), 1.0), "Boss Damage should not work on the pile once the boss is beaten")
	state.number = ScientificNumber.from_float(1000)
	state._add_number(ScientificNumber.from_float(1))
	_expect(state.number.compare_to(ScientificNumber.from_float(1001)) == 0, "Leech should not feed on ordinary enemies")

	# A boss standing in front of an ordinary wave hits like one of its enemies,
	# heated up for the hits it has landed.
	var carried := GameState.new()
	carried.balance_profile.OPENING_HIT_WAVES = 0
	carried.balance_profile.OPENING_EASED_BY = 0
	carried.start_run(1, 92)
	carried.number = ScientificNumber.from_float(1e12)
	carried.wave = 10
	carried.active_encounter = _lone_boss(carried, 10)
	carried._resolve_wave_boundary()
	var boss: Dictionary = carried.active_encounter.members[carried.active_encounter.boss_index()]
	# It reaches the Number at 15 seconds and hits every 5 through its wave's
	# boundary at 35: at 15, 20, 25, 30 and 35.
	_expect(int(boss.hits) == 5 and is_equal_approx(float(boss.interval), carried.balance_profile.MEMBER_HIT_SECONDS), "the boss should have hit on its wave's clock and keep it")
	var heated: ScientificNumber = carried.get_hit_breakdown(carried.active_encounter.boss_index()).raw
	_expect(absf(heated.log10() - boss.wave_hit.multiply_scalar(float(boss.share) * pow(carried.balance_profile.HEAT_UP_PER_HIT, 5.0)).log10()) < 1.0e-9, "the boss's next hit should be heated up 4% a hit")

	# The carried boss and its heat survive a save and load exactly.
	var save_path := "res://.number_go_up_test_save.json"
	carried.save_path = save_path
	_expect(carried.save(), "a run with a carried boss should save")
	var loaded := GameState.new()
	loaded.balance_profile.OPENING_HIT_WAVES = 0
	loaded.balance_profile.OPENING_EASED_BY = 0
	loaded.save_path = save_path
	loaded.load()
	var loaded_boss_at: int = loaded.active_encounter.boss_index()
	_expect(loaded_boss_at >= 0 and int(loaded.active_encounter.members[loaded_boss_at].hits) == int(boss.hits) and loaded.active_encounter.members[loaded_boss_at].hp.compare_to(boss.hp) == 0, "the carried boss should load with its HP and heat")
	loaded.clear_save()

	# A member saved before D063 has no marker or count: a boss is its own
	# wave's, and a member that has landed has hit once. No older save could
	# hold a carried boss, so members of an ordinary wave load as ordinary.
	var own_boss: Dictionary = _lone_boss(carried, 10).to_dict()
	var mixed: Dictionary = carried.active_encounter.to_dict()
	for fixture in [own_boss, mixed]:
		for member in fixture.members:
			member.erase("boss")
			member.erase("hits")
			member.erase("unpaid")
	var restored_boss = TaxEncounter.from_dict(own_boss)
	_expect(restored_boss.boss_index() == 0 and restored_boss.members.size() == 1 and int(restored_boss.members[0].hits) == 0, "an older boss wave should load its boss, not yet having hit")
	var restored_mixed = TaxEncounter.from_dict(mixed)
	_expect(restored_mixed.boss_index() < 0 and restored_mixed.members.all(func(member): return int(member.hits) == (1 if bool(member.landed) else 0)), "an older ordinary wave should load no boss and one hit per landed member")

	# A boss beaten after its wave passed pays what its wave still owed: the
	# rest of its Coins, its Cash and its Gem, and says so (D063).
	var owed := GameState.new()
	owed.balance_profile.OPENING_HIT_WAVES = 0
	owed.balance_profile.OPENING_EASED_BY = 0
	owed.start_run(1, 94)
	owed.number = ScientificNumber.from_float(1e12)
	owed.wave = 20
	owed.active_encounter = _lone_boss(owed, 20)
	owed._resolve_wave_boundary()
	var coins_after_pass := owed.coins
	var gems_after_pass := owed.gems
	var owed_at: int = owed.active_encounter.boss_index()
	_expect(coins_after_pass == 0 and is_equal_approx(float(owed.active_encounter.members[owed_at].unpaid), 1.0), "a boss passed untouched should owe its whole reward")
	owed._add_number(owed.active_encounter.members[owed_at].hp.copy())
	var cleared_events: Array = owed.advance(0.0).filter(func(event): return event.type == "boss_clear")
	_expect(owed.coins == owed.balance_profile.reward_for_wave(1, 20) and owed.gems == gems_after_pass + owed.balance_profile.wave_gems(20), "the beaten boss should pay its wave's Coins and Gem")
	_expect(cleared_events.size() == 1 and owed.get_tier_best(1) == 0, "the beaten boss should announce itself once and set no record")
	owed._add_number(ScientificNumber.from_float(1))
	_expect(owed.coins == owed.balance_profile.reward_for_wave(1, 20), "a beaten boss should pay once")

	# Ordinary enemies carried in the pile pay their share of their wave's
	# Coins when beaten later, as The Tower pays on the kill (D063).
	var pile_pay := GameState.new()
	pile_pay.balance_profile.OPENING_HIT_WAVES = 0
	pile_pay.balance_profile.OPENING_EASED_BY = 0
	pile_pay.start_run(1, 96)
	pile_pay.number = ScientificNumber.from_float(1e12)
	pile_pay.wave = 31
	pile_pay.active_encounter = pile_pay._make_encounter(31)
	pile_pay.active_encounter.remaining_liability = pile_pay.active_encounter.max_liability.multiply_scalar(0.4)
	var pile_reward: int = pile_pay.active_encounter.reward
	pile_pay._resolve_wave_boundary()
	var paid_at_pass := pile_pay.coins
	_expect(paid_at_pass == floori(float(pile_reward) * 0.6 + 0.000001), "the passing wave should pay for the share cleared")
	# Each of the carried enemies owes under a Coin (D065); the fraction carries
	# over, so beating them all pays the rest of the wave's reward.
	var carried_count := 0
	for member in pile_pay.active_encounter.members:
		if not pile_pay.active_encounter.is_own(member):
			carried_count += 1
	for kill in range(carried_count):
		pile_pay._add_number(pile_pay.active_encounter.members[pile_pay.active_encounter.front_index()].hp.copy())
	_expect(carried_count > 2 and pile_pay.coins == pile_reward, "the carried enemies beaten later should pay the rest of their wave's Coins between them: %d of %d" % [pile_pay.coins, pile_reward])
	# The part of a Coin still owed survives a save (D065).
	pile_pay.coin_fraction = 0.625
	pile_pay.save_path = "res://.number_go_up_test_save.json"
	_expect(pile_pay.save(), "a run owing part of a Coin should save")
	var fraction_loaded := GameState.new()
	fraction_loaded.save_path = pile_pay.save_path
	fraction_loaded.load()
	_expect(is_equal_approx(fraction_loaded.coin_fraction, 0.625), "the part of a Coin owed should load with the run")
	fraction_loaded.clear_save()

	# A V10 save migrates to V11, keeping a copy, and resumes its boss wave.
	var v10_path := "res://.number_go_up_test_save.json"
	var v10 := GameState.new()
	v10.start_run(1, 95)
	v10.wave = 10
	v10.active_encounter = v10._make_encounter(10)
	v10.save_path = v10_path
	var v10_data: Dictionary = SaveDataV11.make(v10)
	v10_data.version = 10
	for member in v10_data.active_encounter.members:
		member.erase("boss")
		member.erase("hits")
		member.erase("unpaid")
	_write_json(v10_path, v10_data)
	var migrated := GameState.new()
	migrated.save_path = v10_path
	migrated.load()
	_expect(migrated.load_status == GameState.LOAD_OK and migrated.in_run and migrated.active_encounter.boss_index() == 0, "a V10 boss wave should resume with its boss")
	_expect(int(_read_json(v10_path).get("version", 0)) == SaveDataV11.VERSION and FileAccess.file_exists(migrated._migration_backup_path(10)), "a V10 save should be rewritten as V11 and kept as a copy")
	migrated.clear_save()

	# Tier 2 opens with the first beaten wave past 100 when the wave 100 boss
	# was passed rather than beaten.
	var gate := GameState.new()
	gate.start_run(1, 93)
	gate.number = ScientificNumber.from_float(1e30)
	gate.wave = 100
	gate.active_encounter = gate._make_encounter(100)
	gate._resolve_wave_boundary()
	_expect(gate.wave == 101 and not gate.is_tier_unlocked(2), "passing the wave 100 boss should not open Tier 2 by itself")
	_beat_wave(gate)
	var opened := false
	for step in range(12):
		for event in gate.advance(0.25):
			opened = opened or event.type == "tier_unlock"
	_expect(opened and gate.is_tier_unlocked(2), "beating wave 101 should open Tier 2 and say so")

func _test_members_stay_and_the_pile_grows() -> void:
	var state := GameState.new()
	state.balance_profile.OPENING_HIT_WAVES = 0
	state.balance_profile.OPENING_EASED_BY = 0
	state.balance_profile.FIRST_WAVE_MEMBERS = 3
	state.start_run(1, 71)
	state.number = ScientificNumber.from_float(1e9)
	var interval: float = state.balance_profile.MEMBER_HIT_SECONDS
	# Three enemies a wave keep the pile's arithmetic readable; they arrive at
	# 6, 19 and 32 seconds of the 35-second wave (D065).
	var share_hit := state.get_effective_collection().multiply_scalar(1.0 / 3.0)
	var first_hits: Array = []
	var repeats: Array = []
	var clock := 0.0
	while clock < 14.5:
		for event in state._advance_waves(0.25):
			if event.type == "tax_collection":
				first_hits.append(clock)
			elif event.type == "pile_hit":
				repeats.append(clock)
				_expect(absf(event.amount.log10() - share_hit.multiply_scalar(state.balance_profile.HEAT_UP_PER_HIT).log10()) < 1.0e-9, "a repeat hit should be the member's share heated up 4% (D063)")
		clock += 0.25
	# Times are the clock at the start of the step the hit fell in.
	_expect(first_hits.size() == 1 and repeats.size() == 1 and absf(float(repeats[0]) + 0.25 - (6.0 + interval)) < 0.01, "the front member should hit again one interval after it lands: %s" % str(repeats))
	for step in range(82):
		state._advance_waves(0.25)
	_expect(state.wave == 2 and state.active_encounter.at_number_count() == 3 and state.active_encounter.front_index() == 0 and not state.active_encounter.is_own(state.active_encounter.members[0]), "unbeaten members should carry into the next wave, in front")
	var front_before: ScientificNumber = state.active_encounter.members[0].hp.copy()
	state.active_encounter.apply_compliance(ScientificNumber.from_float(0.5))
	_expect(state.active_encounter.members[0].hp.compare_to(front_before.subtract(ScientificNumber.from_float(0.5))) == 0, "damage should strike the carried member at the Number first")

	# A pile saves and resumes exactly, and a run resumed on an older profile
	# keeps its pile where it was, on today's curve.
	var save_path := "res://.number_go_up_test_save.json"
	state.save_path = save_path
	_expect(state.save(), "a run with a pile should save")
	var resumed := GameState.new()
	resumed.balance_profile.OPENING_HIT_WAVES = 0
	resumed.balance_profile.OPENING_EASED_BY = 0
	resumed.balance_profile.FIRST_WAVE_MEMBERS = 3
	resumed.save_path = save_path
	resumed.load()
	_expect(resumed.active_encounter.at_number_count() == state.active_encounter.at_number_count() and resumed.active_encounter.members[0].wave == 1, "the pile should resume in front")
	for step in range(80):
		state._advance_waves(0.25)
		resumed._advance_waves(0.25)
	_expect(resumed.number.compare_to(state.number) == 0 and resumed.wave == state.wave, "a resumed pile should play out exactly as the saved one")
	_expect(resumed.save(), "the resumed pile should save")
	var older := _read_json(save_path)
	older.balance_profile_id = "tax-foundation-v10"
	_write_json(save_path, older)
	var rebuilt := GameState.new()
	rebuilt.balance_profile.OPENING_HIT_WAVES = 0
	rebuilt.balance_profile.OPENING_EASED_BY = 0
	rebuilt.balance_profile.FIRST_WAVE_MEMBERS = 3
	rebuilt.save_path = save_path
	rebuilt.load()
	var carried_hits: Array = rebuilt.active_encounter.members.filter(func(member): return not rebuilt.active_encounter.is_own(member)).map(func(member): return member.wave_hit.compare_to(rebuilt.balance_profile.collection_for_wave(1, int(member.wave))) == 0)
	_expect(not carried_hits.is_empty() and not carried_hits.has(false) and rebuilt.active_encounter.at_number_count() == resumed.active_encounter.at_number_count(), "a rebuilt pile should keep its members at the Number, on today's Hit")
	var rebuilt_before := rebuilt.number.copy()
	rebuilt._advance_waves(0.01)
	_expect(rebuilt.number.compare_to(rebuilt_before) == 0, "a rebuilt pile should not land an extra hit on load")
	rebuilt.clear_save()

	# Left alone, the pile grows, and so do the hits it lands each clock.
	var pile := GameState.new()
	pile.balance_profile.OPENING_HIT_WAVES = 0
	pile.balance_profile.OPENING_EASED_BY = 0
	pile.balance_profile.FIRST_WAVE_MEMBERS = 3
	pile.start_run(1, 72)
	pile.number = ScientificNumber.from_float(1e12)
	var hits_per_clock: Array = []
	for clock_index in range(4):
		var count := 0
		for step in range(140):
			count += pile._advance_waves(0.25).filter(func(event): return event.type == "tax_collection" or event.type == "pile_hit").size()
		hits_per_clock.append(count)
	_expect(hits_per_clock[3] > hits_per_clock[1] and hits_per_clock[1] > hits_per_clock[0], "an unbeaten pile should hit more often clock on clock: %s" % str(hits_per_clock))

	# D063: a boss lets waves keep coming. It reaches the Number at 15 seconds,
	# hits, joins the next wave's pile and hits again on its wave's clock.
	var boss := GameState.new()
	boss.balance_profile.OPENING_HIT_WAVES = 0
	boss.balance_profile.OPENING_EASED_BY = 0
	boss.start_run(1, 73)
	boss.number = ScientificNumber.from_float(1e12)
	boss.wave = 10
	boss.active_encounter = boss._make_encounter(10)
	var boss_hits := 0
	for step in range(150):
		boss_hits += boss._advance_waves(0.25).filter(func(event): return event.type == "boss_collection").size()
	# At 15, 20, 25, 30 and 35 seconds, when its wave passes; its next is 5
	# seconds into wave 11.
	_expect(boss.wave == 11 and boss_hits == 5 and boss.active_encounter.boss_index() >= 0, "a boss should let waves come and hit every %.0f seconds: wave %d, %d hits" % [boss.balance_profile.MEMBER_HIT_SECONDS, boss.wave, boss_hits])

	# Beaten after landing: the wave still counts as beaten.
	var late := GameState.new()
	late.balance_profile.OPENING_HIT_WAVES = 0
	late.balance_profile.OPENING_EASED_BY = 0
	late.balance_profile.FIRST_WAVE_MEMBERS = 3
	late.start_run(1, 74)
	late.number = ScientificNumber.from_float(1e6)
	for step in range(141):
		late._advance_waves(0.25)
	_expect(late.wave == 2, "the fixture should carry wave 1's members into wave 2")
	for step in range(27):
		late._advance_waves(0.25)
	_expect(late.wave == 2 and late.active_encounter.landed_count() >= 1, "the fixture should have one of wave 2's own members at the Number")
	_beat_wave(late)
	var late_events: Array = []
	for step in range(12):
		late_events.append_array(late._advance_waves(0.25))
	_expect(late.wave == 3 and late_events.any(func(event): return event.type == "wave_clear") and late.get_tier_record(1).highest_wave >= 2, "a wave whose members are all beaten should count as beaten")

	# A Brace blocks every hit of the clock it was raised in, the pile's too.
	var braced := GameState.new()
	braced.balance_profile.OPENING_HIT_WAVES = 0
	braced.balance_profile.OPENING_EASED_BY = 0
	braced.balance_profile.FIRST_WAVE_MEMBERS = 3
	braced.start_run(1, 75)
	braced.number = ScientificNumber.from_float(1e6)
	for step in range(141):
		braced._advance_waves(0.25)
	_expect(braced.brace(), "a Brace should be raised against the pile")
	var after_brace := braced.number.copy()
	for step in range(138):
		braced._advance_waves(0.25)
	_expect(braced.number.compare_to(after_brace) == 0 and braced.braced, "a Brace should block every hit until its clock ends")
	for step in range(2):
		braced._advance_waves(0.25)
	_expect(not braced.braced, "a spent Brace should end with its clock")

## D059: to wave 30 a member that reaches the Number hits once and leaves,
## and a wave with one through passes unbeaten; from wave 31 members stay,
## hitting every 15 seconds and easing to MEMBER_HIT_SECONDS by wave 50.
func _test_opening_members_pass() -> void:
	var profile := TaxBalanceProfile.new()
	_expect(profile.member_hit_seconds(1) == 0.0 and profile.member_hit_seconds(30) == 0.0, "opening members should hit once and pass")
	_expect(is_equal_approx(profile.member_hit_seconds(31), 14.5) and is_equal_approx(profile.member_hit_seconds(40), 10.0) and is_equal_approx(profile.member_hit_seconds(50), profile.MEMBER_HIT_SECONDS), "after the opening the interval should ease from 15 seconds to the member interval by wave 50")
	var state := GameState.new()
	state.start_run(1, 81)
	state.number = ScientificNumber.from_float(1e6)
	var hits := 0
	var opening_count: int = state.active_encounter.members.size()
	for step in range(141):
		hits += state._advance_waves(0.25).filter(func(event): return event.type == "tax_collection" or event.type == "pile_hit").size()
	_expect(hits == opening_count and state.wave == 2 and state.active_encounter.living_members().size() == state.active_encounter.members.size(), "an opening wave's enemies should each hit once and leave nothing behind")
	_expect(int(state.get_tier_record(1).highest_wave) == 0, "an opening wave with a member through should not count as beaten")
	state.wave = 31
	state.wave_accumulator = 0.0
	state.active_encounter = state._make_encounter(31)
	for step in range(26):
		state._advance_waves(0.25)
	_expect(state.active_encounter.at_number_count() == 1, "from wave 31 a member that reaches the Number should stay")

## D060: a V10 active save from before the D059 opening rule may contain a
## repeating member from an early wave, despite having the same profile ID.
func _test_d058_opening_save_reconciles() -> void:
	var save_path := "res://.number_go_up_test_save.json"
	var old := GameState.new()
	old.save_path = save_path
	old.start_run(1, 82)
	old.number = ScientificNumber.from_float(1e6)
	old.coins = 123
	old.cash = ScientificNumber.from_float(456)
	old.wave = 2
	old.wave_accumulator = 6.25
	old.active_encounter = old._make_encounter(2)
	var own_count: int = old.active_encounter.members.size()
	for member in old.active_encounter.members:
		member.interval = 5.0
	var own_front: Dictionary = old.active_encounter.members[0]
	own_front.state = TaxEncounter.AT_NUMBER
	own_front.landed = true
	own_front.next_hit = 11.0
	var carried: Dictionary = old._make_encounter(1).members[0]
	carried.state = TaxEncounter.AT_NUMBER
	carried.landed = true
	carried.interval = 5.0
	carried.next_hit = 7.0
	old.active_encounter.carry_in([carried])
	var number_before: ScientificNumber = old.number.copy()
	var own_hp_before: ScientificNumber = old.active_encounter.own_uncleared()
	_expect(old.save(), "a D058-shaped V10 opening run should save")
	var saved := _read_json(save_path)
	_expect(int(saved.version) == SaveDataV11.VERSION and str(saved.balance_profile_id) == old.balance_profile.PROFILE_ID, "the old fixture should have D059's save version and profile ID")
	var resumed := GameState.new()
	resumed.save_path = save_path
	resumed.load()
	_expect(resumed.load_status == GameState.LOAD_OK and resumed.wave == 2, "the old V10 opening run should load")
	_expect(resumed.active_encounter.members.size() == own_count and resumed.active_encounter.members.all(func(member): return int(member.wave) == 2), "members carried from an opening wave should leave on load")
	_expect(int(resumed.active_encounter.members[0].state) == TaxEncounter.LANDED and resumed.active_encounter.members.all(func(member): return float(member.interval) == 0.0), "the old opening member should have hit once and approaching members should pass")
	_expect(resumed.number.compare_to(number_before) == 0 and resumed.active_encounter.own_uncleared().compare_to(own_hp_before) == 0 and resumed.coins == 123 and resumed.cash.compare_to(ScientificNumber.from_float(456)) == 0, "conversion should keep Number, Coins, Cash and this wave's uncleared HP")
	for step in range(3):
		resumed._advance_waves(0.25)
	_expect(resumed.number.compare_to(number_before) == 0, "a converted opening member should not hit again")
	_expect(resumed.save(), "the converted opening run should save in D059 form")
	var current := GameState.new()
	current.save_path = save_path
	current.load()
	_expect(current.active_encounter.to_dict() == resumed.active_encounter.to_dict() and current.number.compare_to(resumed.number) == 0, "the converted D059 encounter should round-trip exactly")
	resumed.clear_save()

	var later := GameState.new()
	later.save_path = save_path
	later.start_run(1, 83)
	later.number = ScientificNumber.from_float(1e9)
	later.wave = 31
	later.wave_accumulator = 6.25
	later.active_encounter = later._make_encounter(31)
	var eased_front: Dictionary = later.active_encounter.members[0]
	eased_front.state = TaxEncounter.AT_NUMBER
	eased_front.landed = true
	eased_front.interval = 5.0
	eased_front.next_hit = 11.0
	var early: Dictionary = later._make_encounter(29).members[0]
	early.state = TaxEncounter.AT_NUMBER
	early.landed = true
	early.interval = 5.0
	later.active_encounter.carry_in([early])
	_expect(later.save(), "a D058-shaped later run with an opening pile should save")
	var later_resumed := GameState.new()
	later_resumed.save_path = save_path
	later_resumed.load()
	_expect(later_resumed.active_encounter.members.all(func(member): return int(member.wave) == 31) and later_resumed.active_encounter.at_number_count() == 1, "an early carried member should leave, while wave 31's own member stays")
	_expect(is_equal_approx(float(later_resumed.active_encounter.members[0].interval), 14.5) and is_equal_approx(float(later_resumed.active_encounter.members[0].next_hit), 20.5), "a D058 member at wave 31 should adopt D059's eased interval and next Hit")
	var premature_hits := 0
	for step in range(20):
		premature_hits += later_resumed._advance_waves(0.25).filter(func(event): return event.type == "pile_hit").size()
	_expect(premature_hits == 0, "a converted wave-31 member should not repeat on D058's old five-second clock")
	_expect(later_resumed.save(), "the converted eased wave should save")
	var later_roundtrip := GameState.new()
	later_roundtrip.save_path = save_path
	later_roundtrip.load()
	_expect(later_roundtrip.active_encounter.to_dict() == later_resumed.active_encounter.to_dict(), "the eased interval and next Hit should round-trip exactly")
	later_roundtrip.clear_save()

	var boss := GameState.new()
	boss.save_path = save_path
	boss.start_run(1, 85)
	boss.wave = 30
	boss.active_encounter = boss._make_encounter(30)
	var early_boss: Dictionary = boss.active_encounter.members[boss.active_encounter.boss_index()]
	early_boss.state = TaxEncounter.AT_NUMBER
	early_boss.landed = true
	early_boss.next_hit = 15.0
	_expect(boss.save(), "an early boss encounter should save")
	var boss_resumed := GameState.new()
	boss_resumed.save_path = save_path
	boss_resumed.load()
	_expect(boss_resumed.active_encounter.to_dict() == boss.active_encounter.to_dict(), "the wave-30 boss should keep its repeat interval and state")
	boss_resumed.clear_save()

	var fresh := GameState.new()
	fresh.save_path = save_path
	fresh.start_run(1, 84)
	fresh.number = ScientificNumber.from_float(1e6)
	for step in range(25):
		fresh._advance_waves(0.25)
	_expect(int(fresh.active_encounter.members[0].state) == TaxEncounter.LANDED, "the D059 fixture should have a member that hit once and left")
	_expect(fresh.save(), "a current D059 opening run should save")
	var fresh_resumed := GameState.new()
	fresh_resumed.save_path = save_path
	fresh_resumed.load()
	_expect(fresh_resumed.active_encounter.to_dict() == fresh.active_encounter.to_dict() and fresh_resumed.number.compare_to(fresh.number) == 0, "a current D059 opening encounter should load exactly")
	for step in range(40):
		fresh._advance_waves(0.25)
		fresh_resumed._advance_waves(0.25)
	_expect(fresh_resumed.wave == fresh.wave and fresh_resumed.number.compare_to(fresh.number) == 0 and fresh_resumed.coins == fresh.coins, "a current D059 opening run should continue identically after load")
	fresh_resumed.clear_save()

## Plays the wave clock in quarter seconds until an event of `type` happens,
## for up to `seconds`, and returns it (null if none).
func _play_until(state: GameState, type: String, seconds: float = 30.0) -> SimulationEvent:
	var elapsed := 0.0
	while elapsed < seconds and state.in_run:
		for event in state._advance_waves(0.25):
			if event.type == type:
				return event
		elapsed += 0.25
	return null

## Beats every member of the active wave with exactly its HP, front first, so
## the Number gains what the whole wave had, as one blow used to (D057).
## A wave of one enemy with `hp` HP, for tests about output and Number rather
## than groups: with many enemies (D065), damage past the front one is lost.
func _one_enemy(state: GameState, hp: ScientificNumber) -> void:
	var profile = state.balance_profile
	state.active_encounter = TaxEncounter.new(state.selected_tier, state.wave, hp, profile.collection_for_wave(state.selected_tier, state.wave), profile.reward_for_wave(state.selected_tier, state.wave), profile.is_boss_wave(state.wave))

## A boss wave that is only its boss: twenty enemies' HP, one enemy's Hit, on
## its wave's clock (D063, D065). For tests of boss rules, where the enemies a
## real boss wave sends would otherwise stand in front of it.
func _lone_boss(state: GameState, boss_wave: int) -> TaxEncounter:
	var profile = state.balance_profile
	var enemy_hp: ScientificNumber = profile.liability_for_wave(state.selected_tier, boss_wave).multiply_scalar(1.0 / profile.wave_weight(boss_wave))
	var enemy_hit: ScientificNumber = profile.collection_for_wave(state.selected_tier, boss_wave).multiply_scalar(1.0 / profile.wave_weight(boss_wave))
	return TaxEncounter.new(state.selected_tier, boss_wave, enemy_hp.multiply_scalar(profile.BOSS_HP_WEIGHT), enemy_hit, profile.reward_for_wave(state.selected_tier, boss_wave), true, [profile.BOSS_ARRIVAL_SECONDS], profile.boss_hit_seconds(boss_wave))

func _beat_wave(state: GameState) -> void:
	while not state.active_encounter.is_cleared():
		var front: int = state.active_encounter.front_index()
		state._add_number(state.active_encounter.members[front].hp)

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
