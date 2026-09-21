class_name GameState
extends RefCounted

const SAVE_PATH := "user://number_go_up_save.json"
const OFFLINE_CAP_SECONDS := 43200.0
const RESEARCH_WORKSHOP_LEVEL := 12
const PRESTIGE_TEASER_UNLOCK := 110000.0
const PRESTIGE_KNOWLEDGE_SCALE := 4.0

## Wave tax prototype: from wave 21 on, each wave deducts a growing percentage
## of current Number rather than a flat amount, so the threat stays proportional
## no matter how large Number has grown.
const WAVE_INTERVAL_SECONDS := 15.0
const FREE_WAVES := 20
const BOSS_WAVE_INTERVAL := 10
const WAVE_TAX_BASE := 0.015
const WAVE_TAX_GROWTH := 1.12
const BOSS_WAVE_TAX_MULTIPLIER := 1.5
const BRACE_COST_PERCENT := 0.3
const TAX_RESISTANCE_PER_RANK := 0.04
const TAX_RESISTANCE_MAX_RANK := 10
const TAX_RESISTANCE_COST_BASE := 15
const TAX_RESISTANCE_COST_GROWTH := 1.6
const COIN_PER_TAXED_WAVE := 1
const BOSS_COIN_MULTIPLIER := 5

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
# Off only for the legacy baseline-pacing test, which validates the original
# idle curve on its own terms rather than through this newer, separate system.
var wave_tax_enabled := true
# The wave clock only advances while a run is active (see start_run/end_run):
# tapping, passive production, Workshop, and offline rewards are unaffected
# and keep running whether or not a run is in progress.
var in_run := false
var run_coins_earned := 0
var last_run_summary: RunSummary = null
var statistics := {
	"taps": 0,
	"ticks": 0,
	"critical_ticks": 0,
	"number_spent": ScientificNumber.new().to_dict(),
	"offline_generated": ScientificNumber.new().to_dict()
}
var settings := {"muted": false, "haptics": true, "reduce_motion": false, "high_contrast": false}
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

func tap() -> SimulationEvent:
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
	tick_accumulator += minf(delta, 0.25)
	var interval := 1.0 / _tick_rate()
	var safety := 0
	while tick_accumulator >= interval and safety < 20:
		tick_accumulator -= interval
		events.append(_produce_tick())
		safety += 1
	if has_automation():
		automation_accumulator += delta
		if automation_accumulator >= 1.0:
			automation_accumulator = fmod(automation_accumulator, 1.0)
			for target in workshop.automation_targets.slice(0, get_auto_slot_count()):
				if purchase(target, true):
					break
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

func get_rate_per_second() -> ScientificNumber:
	return ScientificNumber.from_float(_passive_base() * _base_output_multiplier() * _momentum_multiplier() * _tick_rate())

func start_run() -> bool:
	if in_run:
		return false
	in_run = true
	run_coins_earned = 0
	return true

## Voluntary bank: stops wave-clock exposure but keeps Number, wave, and coins
## exactly as they are. Resuming later (start_run) continues from this wave.
func end_run() -> void:
	in_run = false

func _advance_waves(delta: float) -> Array[SimulationEvent]:
	var events: Array[SimulationEvent] = []
	if not wave_tax_enabled or not in_run:
		return events
	wave_accumulator += minf(delta, 0.25)
	var safety := 0
	while wave_accumulator >= WAVE_INTERVAL_SECONDS and safety < 10:
		wave_accumulator -= WAVE_INTERVAL_SECONDS
		wave += 1
		highest_wave = maxi(highest_wave, wave)
		var wave_event := _resolve_wave(wave)
		if wave_event != null:
			events.append(wave_event)
		safety += 1
	return events

func _resolve_wave(current_wave: int) -> SimulationEvent:
	if current_wave <= FREE_WAVES:
		return null
	var is_boss := current_wave % BOSS_WAVE_INTERVAL == 0
	var tax_percent := get_wave_tax_percent(current_wave)
	if braced:
		tax_percent = 0.0
		braced = false
	var tax := number.multiply_scalar(tax_percent)
	number = number.subtract(tax)
	var coin_gain := (current_wave - FREE_WAVES) * COIN_PER_TAXED_WAVE
	if is_boss:
		coin_gain += (current_wave - FREE_WAVES) * BOSS_COIN_MULTIPLIER
	coins += coin_gain
	run_coins_earned += coin_gain
	if number.is_zero():
		return _wave_death(current_wave)
	return SimulationEvent.new("wave_boss" if is_boss else "wave_tax", tax)

func _wave_death(reached: int) -> SimulationEvent:
	var knowledge_gain := get_prestige_knowledge_gain()
	knowledge += knowledge_gain
	last_run_summary = RunSummary.new(reached, run_coins_earned, knowledge_gain, lifetime_generated.copy())
	_reset_run_state()
	return SimulationEvent.new("wave_death", ScientificNumber.from_float(float(reached)))

## The percentage of current Number the tax removes on a given wave, including
## the boss multiplier. Public (not prefixed) so the UI can preview the next
## hit. Deliberately uncapped: once the curve demands 100% or more, that wave
## wipes Number outright (ScientificNumber.subtract floors at zero), which is
## what actually makes death inevitable without countering it, rather than an
## asymptote that current Number can shrink toward forever without ever
## reaching zero.
func get_wave_tax_percent(target_wave: int) -> float:
	if target_wave <= FREE_WAVES:
		return 0.0
	var raw := WAVE_TAX_BASE * pow(WAVE_TAX_GROWTH, float(target_wave - FREE_WAVES))
	if target_wave % BOSS_WAVE_INTERVAL == 0:
		raw *= BOSS_WAVE_TAX_MULTIPLIER
	var resisted := raw * (1.0 - float(tax_resistance_rank) * TAX_RESISTANCE_PER_RANK)
	return maxf(0.0, resisted)

func can_brace() -> bool:
	return in_run and not braced and not number.is_zero() and wave + 1 > FREE_WAVES

func brace() -> bool:
	if not can_brace():
		return false
	number = number.subtract(number.multiply_scalar(BRACE_COST_PERCENT))
	braced = true
	return true

func get_tax_resistance_cost() -> int:
	return int(round(float(TAX_RESISTANCE_COST_BASE) * pow(TAX_RESISTANCE_COST_GROWTH, tax_resistance_rank)))

func can_purchase_tax_resistance() -> bool:
	return tax_resistance_rank < TAX_RESISTANCE_MAX_RANK and coins >= get_tax_resistance_cost()

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

func is_unlocked(definition: UpgradeDefinition) -> bool:
	return lifetime_generated.compare_to(definition.unlock_lifetime) >= 0 and get_workshop_level() >= definition.workshop_level_required and is_bay_active(definition.bay)

func can_purchase(upgrade_id: String) -> bool:
	var definition := get_definition(upgrade_id)
	if definition == null or not is_unlocked(definition):
		return false
	if definition.is_maxed(get_owned(upgrade_id)):
		return false
	return number.compare_to(get_cost(definition)) >= 0

func purchase(upgrade_id: String, silent: bool = false) -> bool:
	if not can_purchase(upgrade_id):
		return false
	var definition := get_definition(upgrade_id)
	var cost := get_cost(definition)
	number = number.subtract(cost)
	purchased[upgrade_id] = get_owned(upgrade_id) + 1
	var spent := ScientificNumber.from_dict(statistics.number_spent).add(cost)
	statistics.number_spent = spent.to_dict()
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
	return gain

## Shared by voluntary Prestige and forced wave death. Knowledge, Insight, coins
## and the Shield Matrix rank are permanent and survive this; everything
## Number-funded resets so the loop is "start over, a bit stronger."
func _reset_run_state() -> void:
	number = ScientificNumber.new()
	lifetime_generated = ScientificNumber.new()
	purchased = {}
	focus_path = ""
	workshop = WorkshopState.new()
	momentum_stacks = 0
	critical_chain = 0
	tick_accumulator = 0.0
	automation_accumulator = 0.0
	wave = 1
	wave_accumulator = 0.0
	braced = false
	in_run = false

func select_focus(path: String) -> bool:
	if focus_path != "" or get_workshop_level() < RESEARCH_WORKSHOP_LEVEL:
		return false
	if not ProgressionTaxonomy.WORKSHOP_BAYS.has(path):
		return false
	focus_path = path
	return true

func has_automation() -> bool:
	if not automation_enabled or get_auto_slot_count() <= 0:
		return false
	for target in workshop.automation_targets:
		if get_definition(target) != null:
			return true
	return false

func get_auto_slot_count() -> int:
	if get_owned("automation_core") <= 0:
		return 0
	return mini(3, 1 + get_owned("priority_buffer"))

func set_automation_target(slot: int, upgrade_id: String) -> void:
	if slot < 0 or slot >= get_auto_slot_count() or get_definition(upgrade_id) == null:
		return
	while workshop.automation_targets.size() <= slot:
		workshop.automation_targets.append("")
	workshop.automation_targets[slot] = upgrade_id

func apply_offline(seconds_elapsed: float) -> OfflineAward:
	var seconds := clampf(seconds_elapsed, 0.0, OFFLINE_CAP_SECONDS)
	var amount := get_rate_per_second().multiply_scalar(seconds)
	_add_number(amount)
	var offline := ScientificNumber.from_dict(statistics.offline_generated).add(amount)
	statistics.offline_generated = offline.to_dict()
	return OfflineAward.new(amount, seconds, seconds_elapsed > OFFLINE_CAP_SECONDS)

func save() -> bool:
	var file := FileAccess.open(save_path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(SaveDataV2.make(self)))
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
	if not SaveDataV2.is_valid(parsed):
		return OfflineAward.new()
	var data: Dictionary = parsed
	number = ScientificNumber.from_dict(data.number)
	lifetime_generated = ScientificNumber.from_dict(data.lifetime)
	highest_number = ScientificNumber.from_dict(data.get("highest", data.number))
	purchased = data.get("purchased", {})
	knowledge = int(data.get("knowledge", 0))
	knowledge_purchased = data.get("knowledge_purchased", {})
	focus_path = str(data.get("focus", ""))
	automation_enabled = bool(data.get("automation_enabled", true))
	workshop.from_dict(data.get("workshop", {}))
	wave = int(data.get("wave", 1))
	wave_accumulator = float(data.get("wave_accumulator", 0.0))
	coins = int(data.get("coins", 0))
	highest_wave = int(data.get("highest_wave", 1))
	tax_resistance_rank = int(data.get("tax_resistance_rank", 0))
	in_run = bool(data.get("in_run", false))
	run_coins_earned = int(data.get("run_coins_earned", 0))
	statistics.merge(data.get("statistics", {}), true)
	settings.merge(data.get("settings", {}), true)
	var elapsed := Time.get_unix_time_from_system() - float(data.get("last_seen_unix", Time.get_unix_time_from_system()))
	return apply_offline(elapsed)

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
	_save_migrated_state()

func _save_migrated_state() -> void:
	save()

func clear_save() -> void:
	if FileAccess.file_exists(save_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path))

func has_persistent_storage() -> bool:
	return OS.is_userfs_persistent()

func _add_number(amount: ScientificNumber) -> void:
	number = number.add(amount)
	lifetime_generated = lifetime_generated.add(amount)
	if number.compare_to(highest_number) > 0:
		highest_number = number.copy()

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
		UpgradeDefinition.new("automation_core", "AUTOPILOT", "Automatically buys the first affordable priority target.", ScientificNumber.from_float(4000), ScientificNumber.from_float(5000), "workshop", {}, false, 1.0, ProgressionTaxonomy.ROUTINE, "logic", 1, 8),
		UpgradeDefinition.new("priority_buffer", "PRIORITY BUFFER", "Adds one automation priority target per rank.", ScientificNumber.from_float(8500), ScientificNumber.from_float(9000), "workshop", {}, false, 2.0, ProgressionTaxonomy.ROUTINE, "logic", 2, 8),
		UpgradeDefinition.new("insight", "INSIGHT", "Base production ×1.02 per rank. Costs Knowledge; survives every reset.", ScientificNumber.new(), ScientificNumber.new(), "knowledge", {"base_output_multiplier": 1.02}, true, 1.0, ProgressionTaxonomy.KNOWLEDGE, "", 999999, 0)
	]
