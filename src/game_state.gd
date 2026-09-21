class_name GameState
extends RefCounted

const TaxBalanceProfileClass = preload("res://src/tax_balance_profile.gd")
const TaxEncounterClass = preload("res://src/tax_encounter.gd")
const RuleModifierPipelineClass = preload("res://src/rule_modifier_pipeline.gd")
const SaveDataV3Class = preload("res://src/save_data_v3.gd")
const SaveDataV4Class = preload("res://src/save_data_v4.gd")

const SAVE_PATH := "user://number_go_up_save.json"
const OFFLINE_CAP_SECONDS := 43200.0
const RESEARCH_WORKSHOP_LEVEL := 12
const PRESTIGE_TEASER_UNLOCK := 110000.0
const PRESTIGE_KNOWLEDGE_SCALE := 4.0

## Public aliases retained for UI/tests. The authored balance lives in
## TaxBalanceProfile rather than being mixed into the state machine.
const WAVE_INTERVAL_SECONDS := 15.0
const FREE_WAVES := 20
const BOSS_WAVE_INTERVAL := 10
const TIER_UNLOCK_WAVE := 100
const BRACE_COST_PERCENT := 0.3
const TAX_RESISTANCE_PER_RANK := 0.04
const TAX_RESISTANCE_MAX_RANK := 10
const TAX_RESISTANCE_COST_BASE := 15
const TAX_RESISTANCE_COST_GROWTH := 1.6

var number := ScientificNumber.new()
var lifetime_generated := ScientificNumber.new()
var highest_number := ScientificNumber.new()
var purchased: Dictionary = {}
var knowledge := 0
var knowledge_purchased: Dictionary = {}
var focus_path := ""
var auto_selected_id := "" # V1 compatibility only; new saves use workshop.automation_targets.
var automation_enabled := true
var workshop := WorkshopState.new()
var wave := 1
var wave_accumulator := 0.0
var coins := 0
var highest_wave := 1
var tax_resistance_rank := 0
var braced := false
var tax_encounters_enabled := true
var in_run := false
var run_coins_earned := 0
var run_elapsed := 0.0
var run_seed: int = 0
var selected_tier := 1
var tier_records: Dictionary = {}
var active_encounter = null
var active_rule_modifiers: Array = []
var balance_profile = TaxBalanceProfileClass.new()
var last_run_summary: RunSummary = null
var statistics := {
	"taps": 0,
	"ticks": 0,
	"critical_ticks": 0,
	"number_spent": ScientificNumber.new().to_dict(),
	"coins_spent": 0,
	"offline_generated": ScientificNumber.new().to_dict()
}
var settings := {"muted": false, "haptics": true, "reduce_motion": false, "high_contrast": false, "ambience": true}
var tick_accumulator := 0.0
var automation_accumulator := 0.0
var momentum_stacks := 0
var critical_chain := 0
var rng := RandomNumberGenerator.new()
var definitions: Array[UpgradeDefinition] = []
var save_path := SAVE_PATH

func _init() -> void:
	rng.randomize()
	definitions = _make_definitions()
	_ensure_tier_records()

func tap() -> SimulationEvent:
	if not in_run:
		return SimulationEvent.new("tap", ScientificNumber.new(), false)
	statistics.taps += 1
	var is_critical := rng.randf() < _critical_chance()
	var amount := ScientificNumber.from_float(_tap_base() * _base_output_multiplier() * _momentum_multiplier())
	if is_critical:
		amount = amount.multiply_scalar(_critical_multiplier() * (1.0 + _chain_reaction_step() * critical_chain))
		critical_chain += 1
	else:
		critical_chain = 0
	_add_number(amount)
	return SimulationEvent.new("tap", amount, is_critical)

func advance(delta: float) -> Array[SimulationEvent]:
	var events: Array[SimulationEvent] = []
	if not in_run:
		return events
	tick_accumulator += minf(delta, 0.25)
	var interval := 1.0 / _tick_rate()
	var safety := 0
	while tick_accumulator >= interval and safety < 20:
		tick_accumulator -= interval
		events.append(_produce_tick())
		safety += 1
	events.append_array(_advance_waves(delta))
	return events

func _produce_tick() -> SimulationEvent:
	statistics.ticks += 1
	workshop.tick_count += 1
	if _effect_sum("momentum_per_tick") > 0.0:
		momentum_stacks = mini(100, momentum_stacks + 1)
	var is_critical := rng.randf() < _critical_chance()
	var amount := ScientificNumber.from_float(_passive_base() * _base_output_multiplier() * _momentum_multiplier())
	if is_critical:
		amount = amount.multiply_scalar(_critical_multiplier() * (1.0 + _chain_reaction_step() * critical_chain))
		statistics.critical_ticks += 1
		critical_chain += 1
	else:
		critical_chain = 0
	if rng.randf() < _effect_sum("double_tick_chance"):
		amount = amount.multiply_scalar(2.0)
	var burst_interval := _burst_interval()
	if burst_interval > 0 and workshop.tick_count % burst_interval == 0:
		amount = amount.multiply_scalar(2.0)
	_add_number(amount)
	return SimulationEvent.new("tick", amount, is_critical)

func is_output_banking() -> bool:
	return in_run and (active_encounter == null or active_encounter.is_cleared())

func get_rate_per_second() -> ScientificNumber:
	return ScientificNumber.from_float(_passive_base() * _base_output_multiplier() * _momentum_multiplier() * _tick_rate())

func start_run(tier_id: int = -1, seed_override: int = -1) -> bool:
	if in_run:
		return false
	var target_tier := selected_tier if tier_id < 1 else tier_id
	if not select_tier(target_tier):
		return false
	# Number is run health/resources, never a banked head start. Permanent
	# Workshop ranks define the baseline applied to every fresh attempt.
	number = ScientificNumber.from_float(_effect_sum("starting_number_flat"))
	lifetime_generated = ScientificNumber.new()
	workshop.tick_count = 0
	momentum_stacks = 0
	critical_chain = 0
	tick_accumulator = 0.0
	automation_accumulator = 0.0
	in_run = true
	run_coins_earned = 0
	run_elapsed = 0.0
	wave = 1
	wave_accumulator = 0.0
	braced = false
	run_seed = seed_override if seed_override >= 0 else int(Time.get_ticks_usec()) ^ int(Time.get_unix_time_from_system())
	rng.seed = run_seed
	active_encounter = _make_encounter(wave)
	return true

## Retreat is an actual run ending, not a pause. It preserves permanent
## Workshop ranks, Coins, Knowledge, Insights, Shield and tier records.
func end_run() -> RunSummary:
	if not in_run:
		return null
	last_run_summary = RunSummary.new(wave, run_coins_earned, 0, lifetime_generated.copy(), selected_tier, "retreat")
	_reset_run_state()
	return last_run_summary

func select_tier(tier_id: int) -> bool:
	if in_run or not balance_profile.has_tier(tier_id) or not is_tier_unlocked(tier_id):
		return false
	selected_tier = tier_id
	return true

func is_tier_unlocked(tier_id: int) -> bool:
	if tier_id <= 1:
		return balance_profile.has_tier(tier_id)
	if not balance_profile.has_tier(tier_id):
		return false
	return get_tier_best(tier_id - 1) >= balance_profile.get_tier(tier_id).unlock_previous_tier_wave

func get_tier_best(tier_id: int = selected_tier) -> int:
	var record: Dictionary = tier_records.get(str(tier_id), {})
	return int(record.get("highest_wave", 0))

func get_tier_record(tier_id: int = selected_tier) -> Dictionary:
	return tier_records.get(str(tier_id), _new_tier_record())

func _advance_waves(delta: float) -> Array[SimulationEvent]:
	var events: Array[SimulationEvent] = []
	if not tax_encounters_enabled or not in_run:
		return events
	var safe_delta := minf(delta, 0.25)
	run_elapsed += safe_delta
	wave_accumulator += safe_delta
	var safety := 0
	while wave_accumulator >= WAVE_INTERVAL_SECONDS and safety < 10 and in_run:
		wave_accumulator -= WAVE_INTERVAL_SECONDS
		var wave_event := _resolve_wave_boundary()
		if wave_event != null:
			events.append(wave_event)
		safety += 1
	return events

func _resolve_wave_boundary() -> SimulationEvent:
	if active_encounter == null:
		active_encounter = _make_encounter(wave)
	if active_encounter.is_cleared():
		return _complete_current_wave()
	var collection := get_effective_collection()
	if braced:
		collection = ScientificNumber.new()
		braced = false
	number = number.subtract(collection)
	if number.is_zero():
		return _wave_death(wave)
	return SimulationEvent.new("boss_collection" if active_encounter.is_boss else "tax_collection", collection)

func _complete_current_wave() -> SimulationEvent:
	var completed_wave := wave
	var completed_boss: bool = bool(active_encounter.is_boss)
	var coin_gain: int = int(active_encounter.reward)
	var record := get_tier_record(selected_tier).duplicate(true)
	var previous_best := int(record.get("highest_wave", 0))
	record.highest_wave = maxi(previous_best, completed_wave)
	var claimed: Array = record.get("milestones_claimed", [])
	if balance_profile.MILESTONE_WAVES.has(completed_wave) and not claimed.has(completed_wave):
		claimed.append(completed_wave)
		record.milestones_claimed = claimed
		coin_gain += balance_profile.milestone_bonus(selected_tier, completed_wave)
	if completed_wave == TIER_UNLOCK_WAVE:
		var existing_best := float(record.get("best_time", 0.0))
		if existing_best <= 0.0 or run_elapsed < existing_best:
			record.best_time = run_elapsed
	tier_records[str(selected_tier)] = record
	highest_wave = maxi(highest_wave, completed_wave)
	coins += coin_gain
	run_coins_earned += coin_gain
	wave += 1
	active_encounter = _make_encounter(wave)
	if completed_wave == TIER_UNLOCK_WAVE and previous_best < TIER_UNLOCK_WAVE and balance_profile.has_tier(selected_tier + 1):
		return SimulationEvent.new("tier_unlock", ScientificNumber.from_float(float(selected_tier + 1)))
	return SimulationEvent.new("boss_clear" if completed_boss else "wave_clear", ScientificNumber.from_float(float(coin_gain)))

func _make_encounter(target_wave: int):
	var liability := RuleModifierPipelineClass.apply(
		balance_profile.liability_for_wave(selected_tier, target_wave),
		"liability",
		active_rule_modifiers
	)
	return TaxEncounterClass.new(
		selected_tier,
		target_wave,
		liability,
		balance_profile.collection_for_wave(selected_tier, target_wave),
		balance_profile.reward_for_wave(selected_tier, target_wave),
		balance_profile.is_boss_wave(target_wave)
	)

func _wave_death(reached: int) -> SimulationEvent:
	var knowledge_gain := get_prestige_knowledge_gain()
	knowledge += knowledge_gain
	last_run_summary = RunSummary.new(reached, run_coins_earned, knowledge_gain, lifetime_generated.copy(), selected_tier, "death")
	_reset_run_state()
	return SimulationEvent.new("wave_death", ScientificNumber.from_float(float(reached)))

func get_effective_collection() -> ScientificNumber:
	if active_encounter == null:
		return ScientificNumber.new()
	var modifiers := active_rule_modifiers.duplicate(true)
	modifiers.append({
		"source": "shield_matrix",
		"target": "collection",
		"stage": "multiplicative",
		"value": maxf(0.0, 1.0 - float(tax_resistance_rank) * TAX_RESISTANCE_PER_RANK),
	})
	return RuleModifierPipelineClass.apply(active_encounter.collection, "collection", modifiers)

func get_effective_liability() -> ScientificNumber:
	if active_encounter == null:
		return ScientificNumber.new()
	return active_encounter.remaining_liability.copy()

func can_brace() -> bool:
	return in_run and active_encounter != null and not active_encounter.is_cleared() and not braced and not number.is_zero()

func brace() -> bool:
	if not can_brace():
		return false
	number = number.subtract(number.multiply_scalar(BRACE_COST_PERCENT))
	braced = true
	return true

func get_tax_resistance_cost() -> int:
	return int(round(float(TAX_RESISTANCE_COST_BASE) * pow(TAX_RESISTANCE_COST_GROWTH, tax_resistance_rank)))

func can_purchase_tax_resistance() -> bool:
	return not in_run and tax_resistance_rank < TAX_RESISTANCE_MAX_RANK and coins >= get_tax_resistance_cost()

func purchase_tax_resistance() -> bool:
	if not can_purchase_tax_resistance():
		return false
	coins -= get_tax_resistance_cost()
	tax_resistance_rank += 1
	return true

func get_definition(upgrade_id: String) -> UpgradeDefinition:
	for definition in definitions:
		if definition.id == upgrade_id:
			return definition
	return null

func definitions_for_progression_type(progression_type: String) -> Array[UpgradeDefinition]:
	var matching: Array[UpgradeDefinition] = []
	for definition in definitions:
		if definition.progression_type == progression_type:
			matching.append(definition)
	return matching

func get_workshop_level() -> int:
	var level := workshop.legacy_credit
	for definition in definitions:
		if definition.bay != "":
			level += get_owned(definition.id)
	return level

func is_bay_active(bay: String) -> bool:
	return get_workshop_level() >= get_bay_required_level(bay)

func get_bay_required_level(bay: String) -> int:
	return {"output": 0, "speed": 2, "chance": 5, "logic": 8}.get(bay, 99)

func cards_for_bay(bay: String) -> Array[UpgradeDefinition]:
	var cards: Array[UpgradeDefinition] = []
	for definition in definitions:
		if definition.bay == bay:
			cards.append(definition)
	return cards

func get_owned(upgrade_id: String) -> int:
	if knowledge_purchased.has(upgrade_id):
		return int(knowledge_purchased[upgrade_id])
	return int(purchased.get(upgrade_id, 0))

func get_cost(definition: UpgradeDefinition) -> ScientificNumber:
	var discount := _effect_sum("cost_discount")
	# Focus is a nudge toward a first build, never a permanent branch lock.
	if definition.bay == focus_path:
		discount += 0.25
	return definition.cost_at(get_owned(definition.id), discount)

func get_workshop_coin_cost(definition: UpgradeDefinition) -> int:
	var cost := get_cost(definition)
	if cost.is_zero():
		return 0
	# Authored Workshop costs stay in the exact-number helper so growth and
	# discounts remain inspectable, while Coins themselves are whole units.
	return maxi(1, ceili(cost.mantissa * pow(10.0, cost.exponent)))

func is_unlocked(definition: UpgradeDefinition) -> bool:
	if definition.category == "workshop":
		return get_workshop_level() >= definition.workshop_level_required and is_bay_active(definition.bay)
	return lifetime_generated.compare_to(definition.unlock_lifetime) >= 0

func can_purchase(upgrade_id: String) -> bool:
	var definition := get_definition(upgrade_id)
	if definition == null or definition.category != "workshop" or in_run or not is_unlocked(definition):
		return false
	if definition.is_maxed(get_owned(upgrade_id)):
		return false
	return coins >= get_workshop_coin_cost(definition)

func purchase(upgrade_id: String, silent: bool = false) -> bool:
	if not can_purchase(upgrade_id):
		return false
	var definition := get_definition(upgrade_id)
	var cost := get_workshop_coin_cost(definition)
	coins -= cost
	purchased[upgrade_id] = get_owned(upgrade_id) + 1
	statistics.coins_spent = int(statistics.get("coins_spent", 0)) + cost
	return true

func can_purchase_insight() -> bool:
	return knowledge > 0

func purchase_insight() -> bool:
	if not can_purchase_insight():
		return false
	knowledge -= 1
	knowledge_purchased["insight"] = get_owned("insight") + 1
	return true

func get_prestige_knowledge_gain() -> int:
	if lifetime_generated.is_zero():
		return 0
	var order_of_magnitude := lifetime_generated.log10() - log(PRESTIGE_TEASER_UNLOCK) / log(10.0)
	return maxi(0, floori(order_of_magnitude * PRESTIGE_KNOWLEDGE_SCALE))

func can_prestige() -> bool:
	return get_prestige_knowledge_gain() > 0

func prestige() -> int:
	var gain := get_prestige_knowledge_gain()
	if gain <= 0:
		return 0
	knowledge += gain
	_reset_run_state()
	focus_path = ""
	return gain

## Shared by voluntary Prestige and run endings. Workshop ranks are permanent;
## only run Number and transient combat state are cleared.
func _reset_run_state() -> void:
	number = ScientificNumber.new()
	lifetime_generated = ScientificNumber.new()
	workshop.tick_count = 0
	momentum_stacks = 0
	critical_chain = 0
	tick_accumulator = 0.0
	automation_accumulator = 0.0
	wave = 1
	wave_accumulator = 0.0
	braced = false
	in_run = false
	run_elapsed = 0.0
	run_seed = 0
	run_coins_earned = 0
	active_encounter = null

func select_focus(path: String) -> bool:
	if in_run or focus_path != "" or get_workshop_level() < RESEARCH_WORKSHOP_LEVEL:
		return false
	if not ProgressionTaxonomy.WORKSHOP_BAYS.has(path):
		return false
	focus_path = path
	return true

func has_automation() -> bool:
	return false

func get_auto_slot_count() -> int:
	return 0

func set_automation_target(slot: int, upgrade_id: String) -> void:
	if slot < 0 or slot >= get_auto_slot_count() or get_definition(upgrade_id) == null:
		return
	while workshop.automation_targets.size() <= slot:
		workshop.automation_targets.append("")
	workshop.automation_targets[slot] = upgrade_id

func apply_offline(seconds_elapsed: float) -> OfflineAward:
	# Runs freeze exactly while away. Between runs the Workshop is a management
	# layer, so there is no run Number to generate offline.
	return OfflineAward.new()

func save() -> bool:
	var file := FileAccess.open(save_path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(SaveDataV4Class.make(self)))
	return true

func load() -> OfflineAward:
	if not FileAccess.file_exists(save_path):
		return OfflineAward.new()
	var file := FileAccess.open(save_path, FileAccess.READ)
	if file == null:
		return OfflineAward.new()
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if SaveDataV2.is_legacy_v1(parsed):
		_migrate_v1(parsed)
		return OfflineAward.new()
	if SaveDataV2.is_valid(parsed):
		return _migrate_v2(parsed)
	if SaveDataV3Class.is_valid(parsed):
		return _migrate_v3(parsed)
	if not SaveDataV4Class.is_valid(parsed):
		return OfflineAward.new()
	var data: Dictionary = parsed
	_load_common_fields(data)
	tier_records = data.get("tier_records", {})
	_ensure_tier_records()
	selected_tier = int(data.get("selected_tier", 1))
	if not balance_profile.has_tier(selected_tier):
		selected_tier = 1
	wave = maxi(1, int(data.get("wave", 1)))
	wave_accumulator = clampf(float(data.get("wave_accumulator", 0.0)), 0.0, WAVE_INTERVAL_SECONDS)
	in_run = bool(data.get("in_run", false))
	var loaded_modifiers: Variant = data.get("active_rule_modifiers", [])
	active_rule_modifiers = loaded_modifiers if loaded_modifiers is Array else []
	run_coins_earned = int(data.get("run_coins_earned", 0))
	run_elapsed = maxf(0.0, float(data.get("run_elapsed", 0.0)))
	run_seed = str(data.get("run_seed", "0")).to_int()
	braced = bool(data.get("braced", false))
	if in_run:
		var encounter_data: Variant = data.get("active_encounter", null)
		active_encounter = TaxEncounterClass.from_dict(encounter_data) if encounter_data is Dictionary else _make_encounter(wave)
		var saved_rng_state := str(data.get("rng_state", "0")).to_int()
		if saved_rng_state != 0:
			rng.state = saved_rng_state
		elif run_seed != 0:
			rng.seed = run_seed
	else:
		active_encounter = null
		wave = 1
		wave_accumulator = 0.0
	var elapsed := Time.get_unix_time_from_system() - float(data.get("last_seen_unix", Time.get_unix_time_from_system()))
	return apply_offline(elapsed)

func _migrate_v3(data: Dictionary) -> OfflineAward:
	_load_common_fields(data)
	tier_records = data.get("tier_records", {})
	_ensure_tier_records()
	selected_tier = int(data.get("selected_tier", 1))
	if not balance_profile.has_tier(selected_tier):
		selected_tier = 1
	# V3 Workshop ranks become permanent without any rank loss. A live run is
	# restored; banked Number is retired because V4 Number exists only in runs.
	in_run = bool(data.get("in_run", false))
	var loaded_modifiers: Variant = data.get("active_rule_modifiers", [])
	active_rule_modifiers = loaded_modifiers if loaded_modifiers is Array else []
	if in_run:
		wave = maxi(1, int(data.get("wave", 1)))
		wave_accumulator = clampf(float(data.get("wave_accumulator", 0.0)), 0.0, WAVE_INTERVAL_SECONDS)
		run_coins_earned = int(data.get("run_coins_earned", 0))
		run_elapsed = maxf(0.0, float(data.get("run_elapsed", 0.0)))
		run_seed = str(data.get("run_seed", "0")).to_int()
		braced = bool(data.get("braced", false))
		var encounter_data: Variant = data.get("active_encounter", null)
		active_encounter = TaxEncounterClass.from_dict(encounter_data) if encounter_data is Dictionary else _make_encounter(wave)
		var saved_rng_state := str(data.get("rng_state", "0")).to_int()
		if saved_rng_state != 0:
			rng.state = saved_rng_state
		elif run_seed != 0:
			rng.seed = run_seed
	else:
		_reset_run_state()
	_save_migrated_state()
	return OfflineAward.new()

func _load_common_fields(data: Dictionary) -> void:
	number = ScientificNumber.from_dict(data.number)
	lifetime_generated = ScientificNumber.from_dict(data.lifetime)
	highest_number = ScientificNumber.from_dict(data.get("highest", data.number))
	purchased = data.get("purchased", {})
	knowledge = int(data.get("knowledge", 0))
	knowledge_purchased = data.get("knowledge_purchased", {})
	focus_path = str(data.get("focus", ""))
	automation_enabled = bool(data.get("automation_enabled", true))
	workshop.from_dict(data.get("workshop", {}))
	coins = int(data.get("coins", 0))
	highest_wave = int(data.get("highest_wave", 1))
	tax_resistance_rank = int(data.get("tax_resistance_rank", 0))
	statistics.merge(data.get("statistics", {}), true)
	settings.merge(data.get("settings", {}), true)

func _migrate_v2(data: Dictionary) -> OfflineAward:
	_load_common_fields(data)
	selected_tier = 1
	var old_best := maxi(1, int(data.get("highest_wave", 1)))
	tier_records = {"1": {"highest_wave": old_best, "best_time": 0.0, "milestones_claimed": []}}
	_ensure_tier_records()
	in_run = bool(data.get("in_run", false))
	run_coins_earned = int(data.get("run_coins_earned", 0))
	wave = maxi(1, int(data.get("wave", 1))) if in_run else 1
	wave_accumulator = clampf(float(data.get("wave_accumulator", 0.0)), 0.0, WAVE_INTERVAL_SECONDS) if in_run else 0.0
	run_seed = int(Time.get_ticks_usec()) ^ int(Time.get_unix_time_from_system())
	rng.seed = run_seed
	active_encounter = _make_encounter(wave) if in_run else null
	if not in_run:
		_reset_run_state()
	_save_migrated_state()
	return OfflineAward.new()

func _migrate_v1(data: Dictionary) -> void:
	number = ScientificNumber.from_dict(data.number)
	lifetime_generated = ScientificNumber.from_dict(data.lifetime)
	highest_number = ScientificNumber.from_dict(data.get("highest", data.number))
	statistics.merge(data.get("statistics", {}), true)
	settings.merge(data.get("settings", {}), true)
	var legacy: Dictionary = data.get("purchased", {})
	purchased = {}
	# Preserve directly comparable items as ranked Workshop cards. Any excess or
	# unmatched prototype rank becomes non-spendable level credit, never lost progress.
	var hand_ranks := int(legacy.get("stronger_tap", 0)) + int(legacy.get("steady_hand", 0))
	var engine_ranks := int(legacy.get("generator_two", 0)) + int(legacy.get("more_power", 0))
	purchased["stronger_tap"] = mini(5, hand_ranks)
	purchased["generator"] = mini(5, int(legacy.get("generator", 0)))
	purchased["generator_two"] = mini(3, engine_ranks)
	purchased["faster_cadence"] = mini(5, int(legacy.get("faster_cadence", 0)))
	purchased["faster_echo"] = mini(3, int(legacy.get("faster_echo", 0)))
	purchased["more_critical"] = mini(5, int(legacy.get("more_critical", 0)))
	purchased["chain_reaction"] = mini(3, int(legacy.get("chain_reaction", 0)))
	purchased["smarter_efficiency"] = mini(3, int(legacy.get("smarter_efficiency", 0)))
	purchased["automation_core"] = mini(1, int(legacy.get("automation_core", 0)))
	var mapped_ids := ["stronger_tap", "steady_hand", "generator", "generator_two", "more_power", "faster_cadence", "faster_echo", "more_critical", "chain_reaction", "smarter_efficiency", "automation_core", "workshop_bench", "smarter_momentum", "auto_generator"]
	var credit := int(legacy.get("workshop_bench", 0)) + int(legacy.get("smarter_momentum", 0)) + int(legacy.get("auto_generator", 0))
	credit += maxi(0, hand_ranks - 5) + maxi(0, int(legacy.get("generator", 0)) - 5) + maxi(0, engine_ranks - 3)
	credit += maxi(0, int(legacy.get("faster_cadence", 0)) - 5) + maxi(0, int(legacy.get("faster_echo", 0)) - 3)
	credit += maxi(0, int(legacy.get("more_critical", 0)) - 5) + maxi(0, int(legacy.get("chain_reaction", 0)) - 3)
	credit += maxi(0, int(legacy.get("smarter_efficiency", 0)) - 3) + maxi(0, int(legacy.get("automation_core", 0)) - 1)
	for legacy_id in legacy:
		if not mapped_ids.has(legacy_id):
			credit += maxi(0, int(legacy[legacy_id]))
	workshop.legacy_credit = credit
	if str(data.get("focus", "")) in ProgressionTaxonomy.WORKSHOP_BAYS:
		focus_path = str(data.get("focus", ""))
	var old_target := str(data.get("auto_selected", ""))
	if old_target != "":
		workshop.automation_targets = [old_target]
	_reset_run_state()
	_save_migrated_state()

func _save_migrated_state() -> void:
	save()

func clear_save() -> void:
	if FileAccess.file_exists(save_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path))

func has_persistent_storage() -> bool:
	return OS.is_userfs_persistent()

## Output damages the active wave first and only the overflow becomes Number
## (D012); lifetime production still counts all of it, so Knowledge is unchanged.
func _add_number(amount: ScientificNumber) -> void:
	lifetime_generated = lifetime_generated.add(amount)
	var overflow := amount
	if in_run and active_encounter != null:
		overflow = amount.subtract(active_encounter.apply_compliance(amount))
	number = number.add(overflow)
	if number.compare_to(highest_number) > 0:
		highest_number = number.copy()

func _ensure_tier_records() -> void:
	for tier in balance_profile.tiers:
		var key := str(tier.id)
		if not tier_records.has(key) or not (tier_records[key] is Dictionary):
			tier_records[key] = _new_tier_record()

func _new_tier_record() -> Dictionary:
	return {"highest_wave": 0, "best_time": 0.0, "milestones_claimed": []}

func _tap_base() -> float:
	return 1.0 + _effect_sum("tap_flat")

func _passive_base() -> float:
	return _effect_sum("passive_flat")

func _tick_rate() -> float:
	return _effect_product("tick_rate", 1.0)

func _base_output_multiplier() -> float:
	return _effect_product("base_output_multiplier", 1.0)

func _momentum_multiplier() -> float:
	return 1.0 + float(momentum_stacks) * _effect_sum("momentum_per_tick")

func _critical_chance() -> float:
	return clampf(_effect_sum("critical_chance"), 0.0, 0.8)

func _critical_multiplier() -> float:
	return 2.0 + _effect_sum("critical_multiplier_add")

func _chain_reaction_step() -> float:
	return 0.1 * get_owned("chain_reaction")

func _burst_interval() -> int:
	var rank := get_owned("burst_relay")
	if rank <= 0:
		return 0
	return [0, 12, 9, 6][rank]

func _effect_sum(effect_name: String) -> float:
	var total := 0.0
	for definition in definitions:
		if definition.effects.has(effect_name):
			total += float(definition.effects[effect_name]) * get_owned(definition.id)
	return total

func _effect_product(effect_name: String, base: float) -> float:
	var total := base
	for definition in definitions:
		if definition.effects.has(effect_name):
			total *= pow(float(definition.effects[effect_name]), get_owned(definition.id))
	return total

func _make_definitions() -> Array[UpgradeDefinition]:
	return [
		UpgradeDefinition.new("stronger_tap", "HAND PRESS", "+1 base tap per rank.", ScientificNumber.from_float(10), ScientificNumber.from_float(10), "workshop", {"tap_flat": 1.0}, false, 1.55, ProgressionTaxonomy.MODULE, "output", 5, 0),
		UpgradeDefinition.new("generator", "DESK DYNAMO", "+1.5 base Number/sec per rank.", ScientificNumber.from_float(35), ScientificNumber.from_float(20), "workshop", {"passive_flat": 1.5}, false, 1.7, ProgressionTaxonomy.MODULE, "output", 5, 0),
		UpgradeDefinition.new("generator_two", "NUMBER ENGINE", "Base production ×1.15 per rank.", ScientificNumber.from_float(180), ScientificNumber.from_float(120), "workshop", {"base_output_multiplier": 1.15}, false, 2.0, ProgressionTaxonomy.MODULE, "output", 3, 0),
		UpgradeDefinition.new("faster_cadence", "TICK WHEEL", "Production ticks ×1.20 faster per rank.", ScientificNumber.from_float(130), ScientificNumber.from_float(100), "workshop", {"tick_rate": 1.20}, false, 1.7, ProgressionTaxonomy.MODULE, "speed", 5, 2),
		UpgradeDefinition.new("faster_echo", "DOUBLE TICK", "+8% repeated production-tick chance per rank.", ScientificNumber.from_float(420), ScientificNumber.from_float(300), "workshop", {"double_tick_chance": 0.08}, false, 1.85, ProgressionTaxonomy.PROTOCOL, "speed", 3, 2),
		UpgradeDefinition.new("burst_relay", "BURST RELAY", "Every 12 / 9 / 6 ticks produces an extra tick.", ScientificNumber.from_float(1100), ScientificNumber.from_float(700), "workshop", {}, false, 2.0, ProgressionTaxonomy.PROTOCOL, "speed", 3, 2),
		UpgradeDefinition.new("more_critical", "CRITICAL LENS", "+5% critical chance per rank.", ScientificNumber.from_float(360), ScientificNumber.from_float(500), "workshop", {"critical_chance": 0.05}, false, 1.75, ProgressionTaxonomy.PROTOCOL, "chance", 5, 5),
		UpgradeDefinition.new("magnitude_coil", "MAGNITUDE COIL", "+1 critical multiplier per rank.", ScientificNumber.from_float(1050), ScientificNumber.from_float(900), "workshop", {"critical_multiplier_add": 1.0}, false, 2.0, ProgressionTaxonomy.PROTOCOL, "chance", 3, 5),
		UpgradeDefinition.new("chain_reaction", "CHAIN REACTION", "Each critical strengthens the next critical by 10% per rank.", ScientificNumber.from_float(2400), ScientificNumber.from_float(1800), "workshop", {}, false, 2.0, ProgressionTaxonomy.PROTOCOL, "chance", 3, 5),
		UpgradeDefinition.new("smarter_efficiency", "EFFICIENCY MATRIX", "All upgrade costs 5% lower per rank.", ScientificNumber.from_float(1000), ScientificNumber.from_float(2500), "workshop", {"cost_discount": 0.05}, false, 2.0, ProgressionTaxonomy.MODULE, "logic", 3, 8),
		UpgradeDefinition.new("automation_core", "AUTO CRANK", "+5 base Number/sec per rank.", ScientificNumber.from_float(4000), ScientificNumber.new(), "workshop", {"passive_flat": 5.0}, false, 1.0, ProgressionTaxonomy.ROUTINE, "logic", 1, 8),
		UpgradeDefinition.new("priority_buffer", "STARTING RESERVE", "Begin every run with 250 Number per rank.", ScientificNumber.from_float(8500), ScientificNumber.new(), "workshop", {"starting_number_flat": 250.0}, false, 2.0, ProgressionTaxonomy.ROUTINE, "logic", 2, 8),
		UpgradeDefinition.new("insight", "INSIGHT", "Base production ×1.02 per rank. Costs Knowledge; survives every reset.", ScientificNumber.new(), ScientificNumber.new(), "knowledge", {"base_output_multiplier": 1.02}, true, 1.0, ProgressionTaxonomy.KNOWLEDGE, "", 999999, 0)
	]
