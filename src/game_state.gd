class_name GameState
extends RefCounted

const TaxBalanceProfileClass = preload("res://src/tax_balance_profile.gd")
const TaxEncounterClass = preload("res://src/tax_encounter.gd")
const RuleModifierPipelineClass = preload("res://src/rule_modifier_pipeline.gd")
const LabResearchClass = preload("res://src/lab_research.gd")
const CardCollectionClass = preload("res://src/card_collection.gd")
const SaveDataV3Class = preload("res://src/save_data_v3.gd")
const SaveDataV4Class = preload("res://src/save_data_v4.gd")
const SaveDataV5Class = preload("res://src/save_data_v5.gd")
const SaveDataV6Class = preload("res://src/save_data_v6.gd")
const SaveDataV7Class = preload("res://src/save_data_v7.gd")
const SaveDataV8Class = preload("res://src/save_data_v8.gd")
const SaveDataV9Class = preload("res://src/save_data_v9.gd")
const SaveDataV10Class = preload("res://src/save_data_v10.gd")
const GameDataClass = preload("res://src/game_data.gd")

const SAVE_PATH := "user://number_go_up_save.json"
## What the last load() found, for the UI to report (D028).
const LOAD_NEW_GAME := "new_game"
const LOAD_OK := "ok"
## The live save was missing or unreadable and the backup loaded instead.
const LOAD_RECOVERED := "recovered"
## Neither the live save nor the backup could be read; the live one was moved
## aside intact and a fresh game started.
const LOAD_UNREADABLE := "unreadable"
## The save was written by a newer build; it is left untouched and saving
## pauses until this build is replaced or the save is cleared.
const LOAD_NEWER := "newer"
## What a checkpoint paid in Gems before V8 (D027's placeholder trickle).
const PRE_V8_MILESTONE_GEMS := 1
## Unreadable saves are moved aside under this infix rather than deleted.
const QUARANTINE_INFIX := ".unreadable-"
const READ_OK := "ok"
const READ_MISSING := "missing"
const READ_UNREADABLE := "unreadable"
const READ_NEWER := "newer"
const OFFLINE_CAP_SECONDS := 43200.0
const RESEARCH_WORKSHOP_LEVEL := 120
const PRESTIGE_TEASER_UNLOCK := 110000.0
const PRESTIGE_KNOWLEDGE_SCALE := 4.0

## Public aliases retained for UI/tests. The authored balance lives in
## TaxBalanceProfile rather than being mixed into the state machine.
const WAVE_INTERVAL_SECONDS := 15.0
const FREE_WAVES := 20
const BOSS_WAVE_INTERVAL := 10
const TIER_UNLOCK_WAVE := 100
const BRACE_COST_PERCENT := 0.3
## Brace Cost buys the gap down to here, never to free: a Brace that costs
## nothing stops being a decision.
const BRACE_COST_FLOOR := 0.15
## Armor's id is stable from the Shield Matrix save key it replaced (D013).
const ARMOR_ID := "tax_resistance"
## How many ranks one Workshop press buys. MAX_BUY takes every rank the player
## can afford, up to the row's cap.
const MAX_BUY := -1
const BUY_STEPS := [1, 5, 10, MAX_BUY]

## How to read one row's effect as a player-facing value, keyed by the effect
## the row already declares, so a card cannot drift from what the rank does.
## `base` is the value at rank zero; `op` is how ranks combine, matching the
## _effect_sum / _effect_product call that consumes the effect.
const STAT_DISPLAY := {
	"tap_flat": {"unit": "flat", "base": 1.0, "op": "add"},
	"passive_flat": {"unit": "flat", "base": 0.0, "op": "add"},
	"base_output_multiplier": {"unit": "multiplier", "base": 1.0, "op": "mul"},
	# The Workshop row carries the base shots a second, so it reads as a rate
	# from that base (D054, D055); a card on top of it is still a multiplier.
	"tick_rate": {"unit": "multiplier", "row_unit": "per_second", "row_base": TaxBalanceProfile.BASE_SHOTS_PER_SECOND, "base": 1.0, "op": "mul"},
	"double_tick_chance": {"unit": "percent", "base": 0.0, "op": "add"},
	"critical_chance": {"unit": "percent", "base": 0.0, "op": "add"},
	"critical_multiplier_add": {"unit": "multiplier", "base": 2.0, "op": "add"},
	"cost_discount": {"unit": "percent", "base": 0.0, "op": "add"},
	"starting_number_flat": {"unit": "flat", "base": 0.0, "op": "add"},
	"guard_flat": {"unit": "flat", "base": 0.0, "op": "add"},
	"collection_resistance": {"unit": "percent", "base": 0.0, "op": "add"},
	"siphon_share": {"unit": "percent", "base": 0.0, "op": "add"},
	"recoil_share": {"unit": "percent", "base": 0.0, "op": "add"},
	# The card reads as what Brace costs, so it starts at 30% and descends.
	"brace_discount": {"unit": "percent", "base": BRACE_COST_PERCENT, "op": "add"},
	"second_wind_share": {"unit": "percent", "base": 0.0, "op": "add"},
	# Boss Damage reads as what it multiplies boss damage by, so it starts at x1.
	"boss_damage": {"unit": "multiplier", "base": 1.0, "op": "add"},
	"coin_bonus": {"unit": "percent", "base": 0.0, "op": "add"},
	"knowledge_bonus": {"unit": "percent", "base": 0.0, "op": "add"},
}

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
var braced := false
## True once a Brace has blocked a hit in the current wave's clock (D057,
## D058), so the Brace is used up when that clock ends rather than on the
## first member.
var brace_spent := false
## The run's own peak, which Second Wind restores a share of. Distinct from
## highest_number, which is permanent and drives dock unlocks.
var run_peak_number := ScientificNumber.new()
var second_wind_used := false
## Rig ranks are run-scoped like the Cash that buys them (D015, D042): they
## stack with `purchased` for this run only and die with every ending.
var rig_ranks: Dictionary = {}
## Per-row running price totals for Workshop quotes (see _price_totals).
var _price_total_cache: Dictionary = {}
## In-run currency (The Tower Cash): earned during a run and spent on in-run
## Rig upgrades. Resets when the run ends; spending it never reduces Number.
var cash := ScientificNumber.new()
var run_cash_earned := ScientificNumber.new()
var tax_encounters_enabled := true
var in_run := false
var run_coins_earned := 0
## Gems this run has paid, for the run-over screen (D030). Run-scoped.
var run_gems_earned := 0
## Gems the last load paid for checkpoints the save had already passed or
## claimed at the old rate, for the UI to report once (D030).
var milestone_gems_caught_up := 0
var run_elapsed := 0.0
var run_seed: int = 0
var selected_tier := 1
var tier_records: Dictionary = {}
var active_encounter = null
var active_rule_modifiers: Array = []
var balance_profile = TaxBalanceProfileClass.new()
var lab_research = LabResearchClass.new()
## Permanent, like `purchased`: a finished rank never resets. Keyed by
## research id.
var lab_ranks: Dictionary = {}
## Research slots open, from STARTING_SLOTS to MAX_SLOTS. Permanent: bought
## with Gems and never reset (D029).
var lab_slots: int = LabResearchClass.STARTING_SLOTS
## Research in progress, at most lab_slots entries. Each value is
## {"started_unix": float, "duration": float}; an entry is removed the moment
## it settles into a rank, so this dictionary's size is the slots in use.
var lab_active: Dictionary = {}
var card_collection = CardCollectionClass.new()
## Permanent, like lab_ranks: a card's level never resets on its own.
var card_ranks: Dictionary = {}
## Which owned cards are Active, capped at CardCollectionClass.ACTIVE_SLOTS.
## Only Active cards' effects count; Inventory is a card owned but idle.
var card_active: Array[String] = []
var gems := 0
var last_run_summary: RunSummary = null
var statistics := {
	"taps": 0,
	"ticks": 0,
	"critical_ticks": 0,
	"number_spent": ScientificNumber.new().to_dict(),
	"coins_spent": 0,
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
var load_status := LOAD_NEW_GAME
## True while the save on disk belongs to a newer build (LOAD_NEWER).
var saving_paused := false

func _init() -> void:
	rng.randomize()
	definitions = _make_definitions()
	_ensure_tier_records()

func tap() -> SimulationEvent:
	if not in_run:
		return SimulationEvent.new("tap", ScientificNumber.new(), false)
	statistics.taps += 1
	var is_critical := rng.randf() < _critical_chance()
	var amount := ScientificNumber.from_float(_tap_base() * _damage_multiplier() * _momentum_multiplier())
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
	var amount := ScientificNumber.from_float(_passive_base() * _damage_multiplier() * _momentum_multiplier() + _base_output_per_tick())
	if is_critical:
		amount = amount.multiply_scalar(_critical_multiplier() * (1.0 + _chain_reaction_step() * critical_chain))
		statistics.critical_ticks += 1
		critical_chain += 1
	else:
		critical_chain = 0
	# Multishot (D054): the second shot is the same hit again, so the tick
	# still lands as one amount and only the event says it was two shots.
	var hits := 1
	if rng.randf() < _effect_sum("double_tick_chance"):
		amount = amount.multiply_scalar(2.0)
		hits = 2
	var burst_interval := _burst_interval()
	if burst_interval > 0 and workshop.tick_count % burst_interval == 0:
		amount = amount.multiply_scalar(2.0)
	_add_number(amount)
	if in_run:
		# Cash flows at the income Rig prices are quoted in (D042), shared across
		# the ticks in a second. Anything else lets Attack Speed or Momentum
		# raise every price without raising what pays for it.
		_add_cash(ScientificNumber.from_float(get_rig_income_rate() / _tick_rate()))
	var event := SimulationEvent.new("tick", amount, is_critical)
	event.hits = hits
	return event

## True while the active wave still has HP to clear. Output is Number either
## way (D037); this only says whether it is also striking a wave.
func is_wave_standing() -> bool:
	return in_run and active_encounter != null and not active_encounter.is_cleared()

func get_rate_per_second() -> ScientificNumber:
	return ScientificNumber.from_float(_passive_base() * _damage_multiplier() * _momentum_multiplier() * _tick_rate() + balance_profile.BASE_DAMAGE_PER_SECOND)

func start_run(tier_id: int = -1, seed_override: int = -1) -> bool:
	if in_run:
		return false
	var target_tier := selected_tier if tier_id < 1 else tier_id
	if not select_tier(target_tier):
		return false
	# Research finished before this run starts counts for all of it (D031).
	_settle_labs()
	# Number is run health/resources, never a banked head start. Permanent
	# Workshop ranks define the baseline applied to every fresh attempt.
	# Cushion scales with the tier's pressure, or it is a trap above Tier 1:
	# a flat 500 against a wave-1 hit twenty times that size buys nothing.
	number = ScientificNumber.from_float(balance_profile.starting_number(selected_tier) + _effect_sum("starting_number_flat") * get_cushion_scale())
	run_peak_number = number.copy()
	cash = ScientificNumber.from_float(balance_profile.starting_cash(get_rig_income_rate()))
	run_cash_earned = cash.copy()
	second_wind_used = false
	rig_ranks = {}
	lifetime_generated = ScientificNumber.new()
	workshop.tick_count = 0
	momentum_stacks = 0
	critical_chain = 0
	tick_accumulator = 0.0
	automation_accumulator = 0.0
	in_run = true
	run_coins_earned = 0
	run_gems_earned = 0
	run_elapsed = 0.0
	wave = 1
	wave_accumulator = 0.0
	braced = false
	brace_spent = false
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
	last_run_summary.gems_earned = run_gems_earned
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

## Cushion is the first stat whose worth depends on which tier is being played,
## so it is priced in that tier's hits rather than in absolute Number.
func get_cushion_scale(tier_id: int = selected_tier) -> float:
	return balance_profile.get_tier(tier_id).collection_multiplier

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
	_run_wave_clock(events)
	return events

## Plays the wave clock up to `wave_accumulator`. Every living member hits on
## its own clock: once when it reaches the Number, then every interval while it
## stays (D058). A wave whose own members are all beaten gives way to the next
## after the minimum beat (D037); one still standing when its clock runs out
## passes, and whatever still lives at the Number carries into the next wave,
## so a build that cannot beat them is worn down by the pile. A boss holds the
## clock until beaten (D037), its clock wrapping every 15 seconds.
func _run_wave_clock(events: Array[SimulationEvent]) -> void:
	var safety := 0
	while safety < 200 and in_run:
		safety += 1
		if active_encounter == null:
			active_encounter = _make_encounter(wave)
		var due: int = active_encounter.due_index(wave_accumulator)
		if due >= 0:
			events.append(_member_hit(due))
			continue
		if active_encounter.own_alive_count() == 0 and wave_accumulator >= balance_profile.MIN_WAVE_SECONDS:
			active_encounter.shift_clock(wave_accumulator)
			wave_accumulator = 0.0
			_end_brace_window()
			events.append(_complete_current_wave(active_encounter.living_members()))
		elif wave_accumulator >= WAVE_INTERVAL_SECONDS:
			wave_accumulator -= WAVE_INTERVAL_SECONDS
			active_encounter.shift_clock(WAVE_INTERVAL_SECONDS)
			_end_brace_window()
			if not active_encounter.is_boss:
				_pass_missed_wave(active_encounter.living_members())
		else:
			break

## Plays the clock to the end of the active wave's 15 seconds and returns what
## happened there: the last Hit or clear, not a hit from the pile.
func _resolve_wave_boundary() -> SimulationEvent:
	var events: Array[SimulationEvent] = []
	wave_accumulator = maxf(wave_accumulator, WAVE_INTERVAL_SECONDS)
	_run_wave_clock(events)
	var found: SimulationEvent = null
	for event in events:
		if event.type != "pile_hit":
			found = event
	return found

## A member hits the Number (D057, D058): its share of its wave's Hit, after
## Guard and Armor on that whole Hit, so a group costs what the single wave
## did. Its first hit is its arrival; after that it stays and hits again every
## interval. A Brace blocks every hit until the wave's clock ends. Thorns
## returns part of each hit to whatever stands in front.
func _member_hit(index: int) -> SimulationEvent:
	var member: Dictionary = active_encounter.members[index]
	var first := not bool(member.landed)
	var boss_hit: bool = active_encounter.is_boss and active_encounter.is_own(member)
	var landed := _effective_hit(member.wave_hit).multiply_scalar(float(member.share))
	if braced:
		landed = ScientificNumber.new()
		brace_spent = true
	var number_before_hit := number.copy()
	# Everything Attack left alive, the pile included: a pile that ends the
	# run is HP Attack did not clear.
	var wave_hp_left: ScientificNumber = active_encounter.uncleared()
	number = number.subtract(landed)
	active_encounter.hit(index)
	# Thorns (D038): the combined share is capped (D023) so a hit can never be
	# returned more than once over. The member that hit is still there to take it.
	var thorns_share := minf(_effect_sum("recoil_share"), balance_profile.RECOIL_CEILING)
	if thorns_share > 0.0 and not landed.is_zero():
		active_encounter.apply_compliance(landed.multiply_scalar(thorns_share))
	if number.is_zero():
		if not _try_second_wind():
			return _wave_death(wave, landed, boss_hit, number_before_hit, wave_hp_left)
		return SimulationEvent.new("second_wind", number.copy())
	if boss_hit:
		return SimulationEvent.new("boss_collection", landed)
	return SimulationEvent.new("tax_collection" if first else "pile_hit", landed)

## A Brace covers the wave's clock it was raised in. Spent on any hit, it ends
## with that clock; never tested, it carries on, as before.
func _end_brace_window() -> void:
	if brace_spent:
		braced = false
	brace_spent = false

## An ordinary wave still standing when its clock runs out passes (D037). It
## pays Coins for the share of it that was cleared, floored like Coin Bonus so
## a one-Coin wave pays only when beaten. It was not beaten, so it sets no
## record and pays no Gems; its checkpoint pays when a later wave is beaten.
## Its members still at the Number stay there, ahead of the next wave (D058).
func _pass_missed_wave(carried: Array = []) -> void:
	var share := get_wave_cleared_share()
	var coin_gain := floori(float(active_encounter.reward) * share * (1.0 + _effect_sum("coin_bonus")) + 0.000001)
	coins += coin_gain
	run_coins_earned += coin_gain
	_add_cash(ScientificNumber.from_float(balance_profile.wave_cash(wave) * share))
	wave += 1
	active_encounter = _make_encounter(wave)
	active_encounter.carry_in(carried)

## How much of the active wave's own HP has been cleared, from 0 to 1. Members
## carried in from earlier waves are not counted (D058).
func get_wave_cleared_share() -> float:
	if active_encounter == null or active_encounter.max_liability.is_zero():
		return 1.0
	var remaining: ScientificNumber = active_encounter.own_uncleared()
	if remaining.is_zero():
		return 1.0
	if remaining.compare_to(active_encounter.max_liability) >= 0:
		return 0.0
	# A plain ratio of mantissas, not logarithms, so 20 left of 100 is exactly
	# 0.8 and a floored Coin count never comes out one short.
	var full: ScientificNumber = active_encounter.max_liability
	var left := remaining.mantissa / full.mantissa * pow(10.0, remaining.exponent - full.exponent)
	return clampf(1.0 - left, 0.0, 1.0)

## Once per run, a hit that would end the run leaves a share of the run's peak
## Number instead. The share is the rank's own value, so an early rank buys a
## breath rather than a rescue.
func _try_second_wind() -> bool:
	if second_wind_used:
		return false
	var share := _effect_sum("second_wind_share")
	if share <= 0.0:
		return false
	var restored := run_peak_number.multiply_scalar(share)
	if restored.is_zero():
		return false
	second_wind_used = true
	number = restored
	return true

func _complete_current_wave(carried: Array = []) -> SimulationEvent:
	var completed_wave := wave
	var completed_boss: bool = bool(active_encounter.is_boss)
	var coin_gain: int = int(active_encounter.reward)
	var record := get_tier_record(selected_tier).duplicate(true)
	var previous_best := int(record.get("highest_wave", 0))
	record.highest_wave = maxi(previous_best, completed_wave)
	var claimed: Array = record.get("milestones_claimed", [])
	# Gems (D030): every boss wave pays a little, every run, and each tier's
	# checkpoints pay a lot, once per tier record.
	var gem_gain := balance_profile.wave_gems(completed_wave)
	# Every checkpoint the record has now passed pays, not only this wave's:
	# a missed ordinary checkpoint (D037) pays once a later wave is beaten, the
	# same rule the load-time catch-up applies, so a run and a reload agree.
	for checkpoint in balance_profile.MILESTONE_WAVES:
		if checkpoint > completed_wave or claimed.has(checkpoint):
			continue
		claimed.append(checkpoint)
		coin_gain += balance_profile.milestone_bonus(selected_tier, checkpoint)
		gem_gain += balance_profile.milestone_gems(selected_tier, checkpoint)
	claimed.sort()
	record.milestones_claimed = claimed
	gems += gem_gain
	run_gems_earned += gem_gain
	if completed_wave == TIER_UNLOCK_WAVE:
		var existing_best := float(record.get("best_time", 0.0))
		if existing_best <= 0.0 or run_elapsed < existing_best:
			record.best_time = run_elapsed
	tier_records[str(selected_tier)] = record
	highest_wave = maxi(highest_wave, completed_wave)
	# Coin Bonus lifts everything a beaten wave pays, milestone bonuses included:
	# a milestone is a wave beaten, and one rule is easier to read than two.
	# Floored, not rounded: "+50% Coins" that sometimes pays +100% reads as a
	# bug. Coins are whole, so a 1-Coin early wave carries no percentage at all
	# — which costs nothing real, because this row opens at Workshop level 60,
	# far past the waves that pay one Coin.
	coin_gain = floori(float(coin_gain) * (1.0 + _effect_sum("coin_bonus")))
	coins += coin_gain
	run_coins_earned += coin_gain
	_add_cash(ScientificNumber.from_float(balance_profile.wave_cash(completed_wave)))
	wave += 1
	active_encounter = _make_encounter(wave)
	active_encounter.carry_in(carried)
	if completed_wave == TIER_UNLOCK_WAVE and previous_best < TIER_UNLOCK_WAVE and balance_profile.has_tier(selected_tier + 1):
		return SimulationEvent.new("tier_unlock", ScientificNumber.from_float(float(selected_tier + 1)))
	return SimulationEvent.new("boss_clear" if completed_boss else "wave_clear", ScientificNumber.from_float(float(coin_gain)))

func _make_encounter(target_wave: int):
	var liability := RuleModifierPipelineClass.apply(
		balance_profile.liability_for_wave(selected_tier, target_wave),
		"liability",
		active_rule_modifiers
	)
	var count := balance_profile.members_for_wave(target_wave)
	var arrivals: Array = []
	for index in range(count):
		arrivals.append(balance_profile.member_arrival(index, count))
	return TaxEncounterClass.new(
		selected_tier,
		target_wave,
		liability,
		balance_profile.collection_for_wave(selected_tier, target_wave),
		balance_profile.reward_for_wave(selected_tier, target_wave),
		balance_profile.is_boss_wave(target_wave),
		arrivals,
		WAVE_INTERVAL_SECONDS if balance_profile.is_boss_wave(target_wave) else balance_profile.MEMBER_HIT_SECONDS
	)

func _wave_death(reached: int, hit: ScientificNumber, boss: bool, number_before_hit: ScientificNumber, wave_hp_left: ScientificNumber) -> SimulationEvent:
	var knowledge_gain := get_prestige_knowledge_gain()
	knowledge += knowledge_gain
	# The two gaps under "Lost to" (D022, step 6): how far short Attack fell
	# against the wave's HP, and how far short Defense fell against its hit.
	# Both are captured before _reset_run_state wipes the encounter and Number.
	last_run_summary = RunSummary.new(
		reached,
		run_coins_earned,
		knowledge_gain,
		lifetime_generated.copy(),
		selected_tier,
		"death",
		hit,
		boss,
		wave_hp_left,
		hit.subtract(number_before_hit)
	)
	last_run_summary.gems_earned = run_gems_earned
	_reset_run_state()
	return SimulationEvent.new("wave_death", ScientificNumber.from_float(float(reached)))

func get_effective_collection() -> ScientificNumber:
	if active_encounter == null:
		return ScientificNumber.new()
	return _effective_hit(active_encounter.collection)

## A wave's whole Hit after the run's rules, Guard and Armor.
func _effective_hit(base: ScientificNumber) -> ScientificNumber:
	return RuleModifierPipelineClass.apply(base, "collection", _collection_modifiers(base))

## The next Hit as it is worked out at contact (D052): the Hit after any rule
## that changes it but before the player's defences, what Guard takes off, what
## Armor then takes off, and what lands. Each part is the same pipeline stopped
## earlier, so the parts always add up to what lands. The next Hit is the
## front member's share of its wave's (D057).
func get_hit_breakdown(member_index: int = -1) -> Dictionary:
	if active_encounter == null:
		return {"raw": ScientificNumber.new(), "guard": ScientificNumber.new(), "armor": ScientificNumber.new(), "final": ScientificNumber.new()}
	var front: int = member_index if member_index >= 0 else active_encounter.front_index()
	var base: ScientificNumber = active_encounter.members[front].wave_hit if front >= 0 else active_encounter.collection
	var modifiers := _collection_modifiers(base)
	var raw := RuleModifierPipelineClass.apply(base, "collection", modifiers.filter(func(modifier): return not ["guard", "armor"].has(str(modifier.get("source", "")))))
	var after_guard := RuleModifierPipelineClass.apply(base, "collection", modifiers.filter(func(modifier): return str(modifier.get("source", "")) != "armor"))
	var final := RuleModifierPipelineClass.apply(base, "collection", modifiers)
	var share: float = float(active_encounter.members[front].share) if front >= 0 else 1.0
	return {"raw": raw.multiply_scalar(share), "guard": raw.subtract(after_guard).multiply_scalar(share), "armor": after_guard.subtract(final).multiply_scalar(share), "final": final.multiply_scalar(share)}

## The share of its wave's Hit the front member carries: a third of wave 1's,
## all of a boss's.
func next_hit_share() -> float:
	if active_encounter == null:
		return 1.0
	var front: int = active_encounter.front_index()
	return float(active_encounter.members[front].share) if front >= 0 else 1.0

## Every modifier the Hit passes through, in one list: the run's rules, then
## Guard, then Armor. The pipeline decides the order by stage.
func _collection_modifiers(base: ScientificNumber = null) -> Array:
	var modifiers := active_rule_modifiers.duplicate(true)
	var base_hit: ScientificNumber = base if base != null else active_encounter.collection
	var resistance := clampf(_effect_sum("collection_resistance"), 0.0, balance_profile.COLLECTION_RESISTANCE_CEILING)
	var guard_stat := _effect_sum("guard_flat")

	# Guard (Defense Absolute): flat reduction on every Hit, priced in the tier's
	# Hit pressure. A Hit never drops below 10% of its size after Guard and Armor
	# together (WORKSHOP_EXPANSION). Following D023, the 10% floor bounds the defensive
	# reduction itself so external rules can still shrink hits beyond it.
	if guard_stat > 0.0 and not base_hit.is_zero():
		var tier_multiplier: float = balance_profile.get_tier(selected_tier).collection_multiplier
		var raw_guard := ScientificNumber.from_float(guard_stat * tier_multiplier)
		var max_guard_factor := maxf(0.0, 1.0 - (balance_profile.HIT_FLOOR_PERCENT / (1.0 - resistance)))
		var max_guard := base_hit.multiply_scalar(max_guard_factor)
		var effective_guard := raw_guard if raw_guard.compare_to(max_guard) < 0 else max_guard
		if not effective_guard.is_zero():
			modifiers.append({
				"source": "guard",
				"target": "collection",
				"stage": "flat_reduce",
				"amount": effective_guard.to_dict(),
			})

	# The combined ceiling (D023): Workshop, Rig, Lab and Card Armor stack, and
	# without a limit a run could stop taking hits entirely. The ceiling bounds
	# Armor's own share rather than the final hit, so a later rule that shrinks
	# hits for its own reason keeps its effect instead of being clawed back.
	modifiers.append({
		"source": "armor",
		"target": "collection",
		"stage": "multiplicative",
		"value": 1.0 - resistance,
	})
	return modifiers

func get_effective_liability() -> ScientificNumber:
	if active_encounter == null:
		return ScientificNumber.new()
	return active_encounter.remaining_liability.copy()

func can_brace() -> bool:
	return in_run and active_encounter != null and not active_encounter.is_cleared() and not braced and not number.is_zero()

func get_brace_cost_percent() -> float:
	return clampf(BRACE_COST_PERCENT + _effect_sum("brace_discount"), BRACE_COST_FLOOR, BRACE_COST_PERCENT)

func brace() -> bool:
	if not can_brace():
		return false
	number = number.subtract(number.multiply_scalar(get_brace_cost_percent()))
	braced = true
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
		if definition.category == ProgressionTaxonomy.WORKSHOP:
			level += get_owned(definition.id)
	return level

## How built out one category is, at a glance: Workshop ranks plus any Lab
## ranks on the same shelf. A rank count rather than a fabricated single
## multiplier, since Attack alone already spans several different effects.
func get_category_rank_total(category: String) -> int:
	var total := 0
	for definition in definitions:
		if definition.workshop_category == category:
			total += get_owned(definition.id)
	for lab_definition in lab_research.definitions:
		if lab_definition.category == category:
			total += get_lab_owned(lab_definition.id)
	return total

## The permanent multiplier every beaten wave's Coins pay through, from the
## Workshop's Coin Bonus row and Coin Research in the Labs.
func get_coin_bonus_multiplier() -> float:
	_settle_labs()
	return 1.0 + _effect_sum("coin_bonus")

## A category is open once it has a row to show. Ultimates have none until they
## are authored, so the tab reads as locked without a gate of its own.
func has_category_content(category: String) -> bool:
	for definition in definitions:
		if definition.workshop_category == category:
			return true
	return false

func cards_for_category(category: String) -> Array[UpgradeDefinition]:
	var cards: Array[UpgradeDefinition] = []
	for definition in definitions:
		if definition.workshop_category == category:
			cards.append(definition)
	return cards

func get_owned(upgrade_id: String) -> int:
	if knowledge_purchased.has(upgrade_id):
		return int(knowledge_purchased[upgrade_id])
	return int(purchased.get(upgrade_id, 0))

## The run's Rig ranks, kept beside `purchased` rather than inside it so the
## Workshop screens, Workshop level and every permanent price never see them.
func rig_owned(upgrade_id: String) -> int:
	return int(rig_ranks.get(upgrade_id, 0))

## Every Rig rank this run has bought, across all rows.
func rig_ranks_bought() -> int:
	var total := 0
	for upgrade_id in rig_ranks:
		total += int(rig_ranks[upgrade_id])
	return total

## What a row's Rig ranks are worth in Workshop ranks: a multiple, set when a
## Rig rank spent the Number that buffers the next hit (D023). Since D042 it
## spends Cash, and the multiple awaits a re-sweep.
func rig_rank_equivalent(definition: UpgradeDefinition) -> float:
	var ranks := float(rig_owned(definition.id))
	if ranks <= 0.0:
		return 0.0
	return ranks * balance_profile.rig_effect_multiplier(definition.workshop_category, definition.id)

## What the Rig's prices are quoted against (D039), and the rate Cash flows at
## (D042): the Number a steady player makes each second, which is the passive
## rate plus one tap a second, whether or not the player taps. It leaves
## out the boss-only bonus, so prices do not jump while a boss stands, and it
## rises with every Rig rank that adds damage, so the next price rises too.
func get_rig_income_rate() -> float:
	return _rig_income(_passive_base(), _tap_base(), _tick_rate(), _base_output_multiplier() * _momentum_multiplier())

func _rig_income(passive: float, tap_value: float, ticks: float, multiplier: float) -> float:
	return (passive * ticks + tap_value) * multiplier + balance_profile.BASE_DAMAGE_PER_SECOND

## The Cash price of the row's next rank, or of a named rank for a quote.
func get_rig_cost(upgrade_id: String, rank: int = -1) -> ScientificNumber:
	var definition := get_definition(upgrade_id)
	if definition == null or not balance_profile.rig_has_row(definition.workshop_category, upgrade_id):
		return ScientificNumber.new()
	var at_rank := rig_owned(upgrade_id) if rank < 0 else rank
	return _rig_price(definition.workshop_category, at_rank, get_rig_income_rate(), _effect_sum("cost_discount"))

## Discount lowers Rig prices as well as Workshop ones (D042), never below a
## tenth of the price.
func _rig_price(category: String, rank: int, income: float, discount: float) -> ScientificNumber:
	var price := balance_profile.rig_cost(category, rank, income)
	if discount > 0.0:
		return price.multiply_scalar(clampf(1.0 - discount, 0.1, 1.0))
	return price

func _add_cash(amount: ScientificNumber) -> void:
	cash = cash.add(amount)
	run_cash_earned = run_cash_earned.add(amount)

func can_purchase_rig(upgrade_id: String) -> bool:
	if not in_run or rig_room(upgrade_id) <= 0:
		return false
	var definition := get_definition(upgrade_id)
	if definition == null or not balance_profile.rig_has_row(definition.workshop_category, upgrade_id):
		return false
	return cash.compare_to(get_rig_cost(upgrade_id)) >= 0

## How many more run ranks a row can take this run (D044). A row's Workshop
## ranks and run ranks together stop at its max rank, as The Tower's in-run
## levels do, so a row maxed in the Workshop sells nothing in a run and run
## ranks patch what the permanent build lacks rather than stacking past it.
func rig_room(upgrade_id: String) -> int:
	var definition := get_definition(upgrade_id)
	if definition == null:
		return 0
	return maxi(0, definition.max_rank - get_owned(upgrade_id) - rig_owned(upgrade_id))

## Quote the ranks a single Rig press can afford, priced one rank at a time.
## Each rank can raise income and so the next price (D039), so the quote
## prices every rank at the income it would have by then, exactly as buying
## the same ranks singly would. Only the quoted row's own effect changes as
## its ranks rise, so the income parts are read once and that effect applied
## per rank: the Rig panel re-quotes every card several times a second.
func plan_rig_purchase(upgrade_id: String, count: int = 1) -> Dictionary:
	var refused := {"ranks": 0, "cost": ScientificNumber.new()}
	if not in_run or (count != MAX_BUY and count <= 0):
		return refused
	var definition := get_definition(upgrade_id)
	if definition == null or not balance_profile.rig_has_row(definition.workshop_category, upgrade_id):
		return refused
	var owned := rig_owned(upgrade_id)
	var room := rig_room(upgrade_id)
	var worth := balance_profile.rig_effect_multiplier(definition.workshop_category, upgrade_id)
	var passive := _passive_base()
	var tap_value := _tap_base()
	var ticks := _tick_rate()
	var multiplier := _base_output_multiplier()
	var momentum := _momentum_multiplier()
	var discount := _effect_sum("cost_discount")
	var spent := ScientificNumber.new()
	var ranks := 0
	var held := float(get_owned(upgrade_id)) + rig_rank_equivalent(definition)
	var held_units := definition.units_at(held)
	while ranks < room and (count == MAX_BUY or ranks < count):
		# Steps this press would add, along the row's depth curve (D047).
		var extra := definition.units_at(held + float(ranks) * worth) - held_units
		var p := passive
		var t := tap_value
		var r := ticks
		var m := multiplier
		var d := discount
		for effect in definition.effects:
			var per_rank := float(definition.effects[effect])
			match effect:
				"passive_flat":
					p += per_rank * extra
				"tap_flat":
					t += per_rank * extra
				"tick_rate":
					r *= pow(per_rank, extra)
				"base_output_multiplier":
					m *= pow(per_rank, extra)
				"cost_discount":
					d += per_rank * extra
		var step := _rig_price(definition.workshop_category, owned + ranks, _rig_income(p, t, r, m * momentum), d)
		if step.is_zero():
			break
		var next_spent := spent.add(step)
		if next_spent.compare_to(cash) > 0:
			break
		spent = next_spent
		ranks += 1
	return {"ranks": ranks, "cost": spent}

func purchase_rig_ranks(upgrade_id: String, count: int = 1) -> int:
	var plan := plan_rig_purchase(upgrade_id, count)
	var ranks: int = int(plan.ranks)
	if ranks <= 0:
		return 0
	cash = cash.subtract(plan.cost)
	rig_ranks[upgrade_id] = rig_owned(upgrade_id) + ranks
	# Cushion adds to the Number a run starts with, and this run has already
	# started, so an in-run rank pays its share of that Number now (D042).
	var definition := get_definition(upgrade_id)
	var starting_flat := float(definition.effects.get("starting_number_flat", 0.0))
	if starting_flat > 0.0:
		var worth := balance_profile.rig_effect_multiplier(definition.workshop_category, upgrade_id)
		number = number.add(ScientificNumber.from_float(starting_flat * float(ranks) * worth * get_cushion_scale()))
		if number.compare_to(run_peak_number) > 0:
			run_peak_number = number.copy()
	return ranks

## Buys one run rank with Cash (D042), within the row's max rank (D044).
## Number is never spent.
func purchase_rig(upgrade_id: String) -> bool:
	return purchase_rig_ranks(upgrade_id, 1) > 0

## Labs (The Tower): permanent research paid in Coins, gated by real time
## rather than Coins alone. A line keeps researching whether a run is active or
## the app is closed, but a rank that finishes during a run takes effect from
## the next one (D031): a run's power never changes with the wall clock, so a
## seeded run replays identically and permanent power moves only between runs,
## like the Workshop's. now_unix defaults to wall-clock time; tests pass an
## explicit value instead of waiting.
func _resolve_now(now_unix: float) -> float:
	return now_unix if now_unix >= 0.0 else Time.get_unix_time_from_system()

## Folds finished research into ranks, between runs only. Run start, every run
## ending and loading a save taken between runs all settle; nothing settles
## while a run is live.
func _settle_labs(now_unix: float = -1.0) -> void:
	if in_run:
		return
	var now := _resolve_now(now_unix)
	for research_id in lab_active.keys().duplicate():
		var entry: Dictionary = lab_active[research_id]
		if now - float(entry.get("started_unix", now)) >= float(entry.get("duration", 0.0)):
			lab_ranks[research_id] = int(lab_ranks.get(research_id, 0)) + 1
			lab_active.erase(research_id)

func get_lab_owned(research_id: String, now_unix: float = -1.0) -> int:
	_settle_labs(now_unix)
	return int(lab_ranks.get(research_id, 0))

func lab_is_active(research_id: String, now_unix: float = -1.0) -> bool:
	_settle_labs(now_unix)
	return lab_active.has(research_id)

func get_lab_time_remaining(research_id: String, now_unix: float = -1.0) -> float:
	var now := _resolve_now(now_unix)
	_settle_labs(now)
	if not lab_active.has(research_id):
		return 0.0
	var entry: Dictionary = lab_active[research_id]
	# Clamped both ways: a clock set back must not show more time than the
	# line takes, and one that finished mid-run shows none left.
	var duration := float(entry.get("duration", 0.0))
	return clampf(duration - (now - float(entry.get("started_unix", now))), 0.0, duration)

## A finished line still waiting for the run to end before it counts (D031).
func lab_is_done_awaiting_run_end(research_id: String, now_unix: float = -1.0) -> bool:
	return in_run and lab_active.has(research_id) and get_lab_time_remaining(research_id, now_unix) <= 0.0

## The rank that counts toward effects: settled ranks only, so evaluating an
## effect never reads the clock.
func _lab_rank(research_id: String) -> int:
	return int(lab_ranks.get(research_id, 0))

func lab_active_count(now_unix: float = -1.0) -> int:
	_settle_labs(now_unix)
	return lab_active.size()

func lab_slots_total() -> int:
	return lab_slots

## Gems for the next Lab slot, or 0 once all of them are open.
func get_lab_slot_cost() -> int:
	return lab_research.slot_cost(lab_slots)

## Opening a slot spends Gems, which like Coins are a between-run resource.
func can_unlock_lab_slot() -> bool:
	var cost := get_lab_slot_cost()
	return not in_run and cost > 0 and gems >= cost

func unlock_lab_slot() -> bool:
	if not can_unlock_lab_slot():
		return false
	gems -= get_lab_slot_cost()
	lab_slots += 1
	return true

func get_lab_cost(research_id: String, now_unix: float = -1.0) -> int:
	var definition := lab_research.get_definition(research_id)
	if definition == null:
		return 0
	return lab_research.cost_at(definition, get_lab_owned(research_id, now_unix))

func get_lab_duration(research_id: String, now_unix: float = -1.0) -> float:
	var definition := lab_research.get_definition(research_id)
	if definition == null:
		return 0.0
	var speed_rank := 0 if research_id == LabResearchClass.LAB_SPEED_ID else get_lab_owned(LabResearchClass.LAB_SPEED_ID, now_unix)
	return lab_research.duration_at(definition, get_lab_owned(research_id, now_unix), speed_rank)

## Coins, like the Workshop, are a between-run resource (D015's precedent):
## starting research mid-run would need its own in-run spend UI for no gain,
## since the timer runs in real time regardless of what the run screen shows.
func can_start_lab(research_id: String, now_unix: float = -1.0) -> bool:
	if in_run:
		return false
	var definition := lab_research.get_definition(research_id)
	if definition == null:
		return false
	_settle_labs(now_unix)
	if lab_active.has(research_id) or definition.is_maxed(get_lab_owned(research_id, now_unix)):
		return false
	if lab_active.size() >= lab_slots_total():
		return false
	return coins >= get_lab_cost(research_id, now_unix)

func start_lab(research_id: String, now_unix: float = -1.0) -> bool:
	if not can_start_lab(research_id, now_unix):
		return false
	var now := _resolve_now(now_unix)
	coins -= get_lab_cost(research_id, now_unix)
	lab_active[research_id] = {"started_unix": now, "duration": get_lab_duration(research_id, now_unix)}
	return true

## Reads a Lab line's value the same way stat_display reads a Workshop row's,
## so the two can share a card layout. Lab Speed declares no generic effect
## (it acts on duration, not on the STAT_DISPLAY table) and reads as a rank.
func lab_stat_display(research_id: String, rank: int) -> Dictionary:
	var definition := lab_research.get_definition(research_id)
	if definition == null:
		return {"value": float(rank), "unit": "rank"}
	for effect_name in definition.effects:
		if not STAT_DISPLAY.has(effect_name):
			continue
		var shape: Dictionary = STAT_DISPLAY[effect_name]
		var step := float(definition.effects[effect_name])
		var value: float = float(shape.base)
		if str(shape.op) == "mul":
			value *= pow(step, rank)
		else:
			value += step * float(rank)
		return {"value": value, "unit": str(shape.unit)}
	return {"value": float(rank), "unit": "rank"}

## Cards (The Tower): a permanently-owned collection pulled with Gems, with a
## capped number of Active slots. Pulling, equipping and unequipping are
## between-run actions, like the Workshop and Labs; an Active card's effect
## applies to every run regardless, the same way a finished Lab rank does.
func get_card_level(card_id: String) -> int:
	return int(card_ranks.get(card_id, 0))

func is_card_active(card_id: String) -> bool:
	return card_active.has(card_id)

func active_card_count() -> int:
	return card_active.size()

func card_slots_total() -> int:
	return CardCollectionClass.ACTIVE_SLOTS

func can_equip_card(card_id: String) -> bool:
	if in_run or is_card_active(card_id) or get_card_level(card_id) <= 0:
		return false
	return active_card_count() < card_slots_total()

func equip_card(card_id: String) -> bool:
	if not can_equip_card(card_id):
		return false
	card_active.append(card_id)
	return true

func unequip_card(card_id: String) -> bool:
	if in_run or not is_card_active(card_id):
		return false
	card_active.erase(card_id)
	return true

func get_pull_cost() -> int:
	return CardCollectionClass.PULL_COST_GEMS

func has_unmaxed_cards() -> bool:
	for definition in card_collection.definitions:
		if not definition.is_maxed(get_card_level(definition.id)):
			return true
	return false

func can_pull_card() -> bool:
	return not in_run and gems >= get_pull_cost() and has_unmaxed_cards()

## Draws one card weighted by rarity, uniform within it. Owned cards level up
## one step per repeat pull, to MAX_LEVEL; a new card starts at level 1.
## Maxed cards are excluded from the pull pool (duplicate protection); if all
## cards of a rarity are maxed, pulls roll from the remaining rarities.
## Returns the drawn card's id, or "" if the pull was refused.
func pull_card() -> String:
	if not can_pull_card():
		return ""
	var eligible_rarities: Array[String] = []
	var weight_total := 0
	for rarity in CardCollectionClass.RARITY_WEIGHT:
		var has_available := false
		for card in card_collection.definitions_for_rarity(rarity):
			if not card.is_maxed(get_card_level(card.id)):
				has_available = true
				break
		if has_available:
			eligible_rarities.append(rarity)
			weight_total += int(CardCollectionClass.RARITY_WEIGHT[rarity])
	if eligible_rarities.is_empty():
		return ""
	var roll := rng.randi_range(0, maxi(0, weight_total - 1))
	var chosen_rarity := ""
	var cursor := 0
	for rarity in eligible_rarities:
		cursor += int(CardCollectionClass.RARITY_WEIGHT[rarity])
		if roll < cursor:
			chosen_rarity = rarity
			break
	var available_cards: Array[CardCollection.Definition] = []
	for card in card_collection.definitions_for_rarity(chosen_rarity):
		if not card.is_maxed(get_card_level(card.id)):
			available_cards.append(card)
	if available_cards.is_empty():
		return ""
	var picked: CardCollection.Definition = available_cards[rng.randi_range(0, available_cards.size() - 1)]
	gems -= get_pull_cost()
	card_ranks[picked.id] = get_card_level(picked.id) + 1
	return picked.id

## Reads a card's value the same way stat_display and lab_stat_display do.
func card_stat_display(card_id: String, level: int) -> Dictionary:
	var definition := card_collection.get_definition(card_id)
	if definition == null:
		return {"value": float(level), "unit": "rank"}
	for effect_name in definition.effects:
		if not STAT_DISPLAY.has(effect_name):
			continue
		var shape: Dictionary = STAT_DISPLAY[effect_name]
		var step := float(definition.effects[effect_name])
		var value: float = float(shape.base)
		if str(shape.op) == "mul":
			value *= pow(step, level)
		else:
			value += step * float(level)
		return {"value": value, "unit": str(shape.unit)}
	return {"value": float(level), "unit": "rank"}

func get_cost(definition: UpgradeDefinition) -> ScientificNumber:
	return get_cost_at(definition, get_owned(definition.id))

func get_cost_at(definition: UpgradeDefinition, owned: int) -> ScientificNumber:
	return definition.cost_at(owned, _workshop_discount(definition))

func _workshop_discount(definition: UpgradeDefinition) -> float:
	var discount := _effect_sum("cost_discount")
	# Focus is a nudge toward a first build, never a permanent branch lock.
	if definition.workshop_category == focus_path:
		discount += 0.25
	return discount

func get_workshop_coin_cost(definition: UpgradeDefinition) -> int:
	return get_workshop_coin_cost_at(definition, get_owned(definition.id))

func get_workshop_coin_cost_at(definition: UpgradeDefinition, owned: int) -> int:
	return _workshop_coin_cost(definition, owned, _workshop_discount(definition))

func _workshop_coin_cost(definition: UpgradeDefinition, owned: int, discount: float) -> int:
	var cost := definition.cost_at(owned, discount)
	if cost.is_zero():
		return 0
	# Authored Workshop costs stay in the exact-number helper so growth and
	# discounts remain inspectable, while Coins themselves are whole units.
	return maxi(1, ceili(cost.mantissa * pow(10.0, cost.exponent)))

## What one press of a multi-buy would actually do: how many ranks land and what
## they cost together. Ranks are priced one at a time and summed, so buying in
## bulk is never cheaper than buying the same ranks one by one. The quote uses
## the discount in force now, so buying Discount ranks in bulk does not make the
## later ranks of that same press cheaper: the price shown is the price paid.
func plan_purchase(upgrade_id: String, count: int = 1) -> Dictionary:
	var refused := {"ranks": 0, "cost": 0}
	var definition := get_definition(upgrade_id)
	if definition == null or definition.category != ProgressionTaxonomy.WORKSHOP:
		return refused
	if in_run or not is_unlocked(definition):
		return refused
	var owned := get_owned(upgrade_id)
	var wanted := definition.max_rank - owned if count == MAX_BUY else maxi(0, count)
	wanted = mini(wanted, definition.max_rank - owned)
	if wanted <= 0:
		return {"ranks": 0, "cost": 0}
	# A MAX press on a deep row can span thousands of ranks and the Workshop
	# re-quotes every card several times a second (D047), so ranks are summed
	# once into running totals and the press is a binary search over them: the
	# same ranks and price as buying one at a time, without walking them.
	var totals := _price_totals(definition)
	var low := 0
	var high := wanted
	while low < high:
		var middle := (low + high + 1) / 2
		if totals[owned + middle] - totals[owned] <= coins:
			low = middle
		else:
			high = middle - 1
	return {"ranks": low, "cost": totals[owned + low] - totals[owned]}

## Running totals of a row's Coin prices: entry k is what ranks 0 to k-1 cost
## together at the discount in force. Rebuilt only when that discount changes.
func _price_totals(definition: UpgradeDefinition) -> PackedInt64Array:
	var discount := _workshop_discount(definition)
	var cached: Variant = _price_total_cache.get(definition.id)
	if cached is Dictionary and float(cached.discount) == discount and (cached.totals as PackedInt64Array).size() == definition.max_rank + 1:
		return cached.totals
	var totals := PackedInt64Array()
	totals.resize(definition.max_rank + 1)
	totals[0] = 0
	for rank in range(definition.max_rank):
		totals[rank + 1] = totals[rank] + _workshop_coin_cost(definition, rank, discount)
	_price_total_cache[definition.id] = {"discount": discount, "totals": totals}
	return totals

func is_unlocked(definition: UpgradeDefinition) -> bool:
	if definition.category == ProgressionTaxonomy.WORKSHOP:
		# Each row carries its own Workshop level, which is what the retired bay
		# gates duplicated: every row's requirement equalled its bay's gate.
		return get_workshop_level() >= definition.workshop_level_required
	return lifetime_generated.compare_to(definition.unlock_lifetime) >= 0

func can_purchase(upgrade_id: String) -> bool:
	return int(plan_purchase(upgrade_id, 1).ranks) > 0

func purchase(upgrade_id: String, silent: bool = false) -> bool:
	return purchase_ranks(upgrade_id, 1) > 0

## Buys what plan_purchase quoted and returns the ranks that landed, so the
## press and the quote can never disagree about the price.
func purchase_ranks(upgrade_id: String, count: int = 1) -> int:
	var plan := plan_purchase(upgrade_id, count)
	var ranks := int(plan.ranks)
	if ranks <= 0:
		return 0
	var cost := int(plan.cost)
	coins -= cost
	purchased[upgrade_id] = get_owned(upgrade_id) + ranks
	statistics.coins_spent = int(statistics.get("coins_spent", 0)) + cost
	return ranks

## The value a row reads as at a given rank, and the unit to read it in. Rows
## with no declared effect (Burst, Crit Chain) fall back to their rank, which is
## what their description already talks in.
func stat_display(definition: UpgradeDefinition, rank: int) -> Dictionary:
	var units := definition.units_at(float(rank))
	for effect_name in definition.effects:
		if not STAT_DISPLAY.has(effect_name):
			continue
		var shape: Dictionary = STAT_DISPLAY[effect_name]
		var step := float(definition.effects[effect_name])
		var value: float = float(shape.get("row_base", shape.base))
		if str(shape.op) == "mul":
			value *= pow(step, units)
		else:
			value += step * units
		return {"value": value, "unit": str(shape.get("row_unit", shape.unit))}
	return {"value": float(rank), "unit": "rank"}

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
	var earned := order_of_magnitude * PRESTIGE_KNOWLEDGE_SCALE * (1.0 + _effect_sum("knowledge_bonus"))
	return maxi(0, floori(earned))

func can_prestige() -> bool:
	return get_prestige_knowledge_gain() > 0

func prestige() -> int:
	var gain := get_prestige_knowledge_gain()
	if gain <= 0:
		return 0
	last_run_summary = RunSummary.new(wave, run_coins_earned, gain, lifetime_generated.copy(), selected_tier, "prestige")
	last_run_summary.gems_earned = run_gems_earned
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
	brace_spent = false
	run_peak_number = ScientificNumber.new()
	second_wind_used = false
	rig_ranks = {}
	cash = ScientificNumber.new()
	run_cash_earned = ScientificNumber.new()
	in_run = false
	run_elapsed = 0.0
	run_seed = 0
	run_coins_earned = 0
	run_gems_earned = 0
	active_encounter = null
	# Research that finished during the run takes effect now, between runs.
	_settle_labs()

func select_focus(path: String) -> bool:
	if in_run or focus_path != "" or get_workshop_level() < RESEARCH_WORKSHOP_LEVEL:
		return false
	if not ProgressionTaxonomy.WORKSHOP_CATEGORIES.has(path) or not has_category_content(path):
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

## Writes the new save beside the live one and swaps it in only once it is
## whole, so an interrupted write can never leave a half-written live save.
## The save it replaces becomes the backup a later load falls back to.
func save() -> bool:
	if saving_paused:
		return false
	var temp := _temp_path()
	var file := FileAccess.open(temp, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(SaveDataV10Class.make(self), "", true, true))
	var write_error := file.get_error()
	file.close()
	if write_error != OK:
		_remove_if_present(temp)
		return false
	if FileAccess.file_exists(save_path):
		_remove_if_present(_backup_path())
		if DirAccess.rename_absolute(_global(save_path), _global(_backup_path())) != OK:
			_remove_if_present(temp)
			return false
	return DirAccess.rename_absolute(_global(temp), _global(save_path)) == OK

## Loads the live save, or the backup when the live one is missing or cannot
## be read. Nothing the loader cannot read is ever written over (D028): an
## unreadable live save is moved aside intact, and a save from a newer build
## pauses saving, because writing it back would strip what this build does
## not know. `load_status` says which of these happened, for the UI to report.
func load() -> OfflineAward:
	saving_paused = false
	var live := _read_save(save_path)
	if live.status == READ_NEWER:
		saving_paused = true
		load_status = LOAD_NEWER
		return OfflineAward.new()
	if live.status == READ_OK:
		load_status = LOAD_OK
		return _load_parsed(live.data, save_path)
	if live.status == READ_UNREADABLE:
		DirAccess.rename_absolute(_global(save_path), _global(_quarantine_path()))
	var backup := _read_save(_backup_path())
	if backup.status == READ_OK:
		load_status = LOAD_RECOVERED
		return _load_parsed(backup.data, _backup_path())
	load_status = LOAD_UNREADABLE if live.status == READ_UNREADABLE else LOAD_NEW_GAME
	return OfflineAward.new()

## Reads and classifies one save file without changing any state.
func _read_save(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {"status": READ_MISSING}
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(path)) != OK or not (json.data is Dictionary):
		return {"status": READ_UNREADABLE}
	var data: Dictionary = json.data
	var version := int(data.get("version", 0)) if (data.get("version") is int or data.get("version") is float) else 0
	if version > SaveDataV10Class.VERSION:
		return {"status": READ_NEWER}
	var known := (
		SaveDataV2.is_legacy_v1(data)
		or SaveDataV2.is_valid(data)
		or SaveDataV3Class.is_valid(data)
		or SaveDataV4Class.is_valid(data)
		or SaveDataV5Class.is_valid(data)
		or SaveDataV6Class.is_valid(data)
		or SaveDataV7Class.is_valid(data)
		or SaveDataV8Class.is_valid(data)
		or SaveDataV9Class.is_valid(data)
		or SaveDataV10Class.is_valid(data)
	)
	if not known or SaveDataV10Class.problem(data) != "":
		return {"status": READ_UNREADABLE}
	return {"status": READ_OK, "data": data}

func _load_parsed(data: Dictionary, source_path: String) -> OfflineAward:
	match int(data.version):
		1:
			_migrate_v1(data, source_path)
			return OfflineAward.new()
		2:
			return _migrate_v2(data, source_path)
		3:
			return _migrate_v3(data, source_path)
		4:
			return _migrate_v4(data, source_path)
		5:
			return _migrate_v5(data, source_path)
		6:
			return _migrate_v6(data, source_path)
		7:
			return _migrate_v7(data, source_path)
		8:
			return _migrate_v8(data, source_path)
		9:
			return _migrate_v9(data, source_path)
	return _load_current(data)

## V5 through V10 share every key and meaning. V6 declared the fields added to
## V5 after it shipped and added the run's tick phase and crit chain, which a
## V5 save resumes without, as it always did; V7 added the Lab slot count, which
## an older save reads as the two slots every player then had; V8 added the
## run's Gems and marks that milestones paid at the old rate were topped up;
## V9 declared the run's Cash and marks saves whose deep rows may pass rank 100;
## V10 keeps a wave's members, which a V9 run resumes as one member (D057).
func _load_current(data: Dictionary) -> OfflineAward:
	_load_common_fields(data)
	_load_tier_progress(data)
	_restore_saved_run(data)
	return apply_offline(_seconds_since(data))

func _migrate_v5(data: Dictionary, source_path: String) -> OfflineAward:
	var award := _load_current(data)
	_save_migrated_state(5, source_path)
	return award

func _migrate_v6(data: Dictionary, source_path: String) -> OfflineAward:
	var award := _load_current(data)
	_save_migrated_state(6, source_path)
	return award

func _migrate_v7(data: Dictionary, source_path: String) -> OfflineAward:
	var award := _load_current(data)
	_save_migrated_state(7, source_path)
	return award

func _migrate_v8(data: Dictionary, source_path: String) -> OfflineAward:
	var award := _load_current(data)
	_save_migrated_state(8, source_path)
	return award

func _migrate_v9(data: Dictionary, source_path: String) -> OfflineAward:
	var award := _load_current(data)
	_save_migrated_state(9, source_path)
	return award

## V4 kept the Workshop in four bays, with the Armor rank in a field of its own.
## V5 reads the same run, records and currencies; only the Workshop's shape
## changes, and no rank is lost: the Armor rank becomes an ordinary Workshop
## rank and a bay-shaped Research Focus lands on the category that inherited it.
func _migrate_v4(data: Dictionary, source_path: String) -> OfflineAward:
	_load_common_fields(data)
	_fold_retired_workshop_shape(data)
	_load_tier_progress(data)
	_restore_saved_run(data)
	_save_migrated_state(4, source_path)
	return apply_offline(_seconds_since(data))

## Shared by the V2, V3 and V4 migrations, and by nothing else: a V5 save
## already holds the Armor rank in `purchased` and a category in `focus`. The
## Armor rank moves under its stable id, and the retired bay ids that Research
## Focus and the open tab stored become the categories that inherited them.
func _fold_retired_workshop_shape(data: Dictionary) -> void:
	var legacy_armor := int(data.get("tax_resistance_rank", 0))
	if legacy_armor > 0:
		purchased[ARMOR_ID] = maxi(int(purchased.get(ARMOR_ID, 0)), legacy_armor)
	focus_path = ProgressionTaxonomy.category_for_legacy_bay(focus_path)

func _load_tier_progress(data: Dictionary) -> void:
	var saved_records: Variant = data.get("tier_records", {})
	tier_records = saved_records if saved_records is Dictionary else {}
	_ensure_tier_records()
	for key in tier_records:
		if tier_records[key] is Dictionary:
			_normalise_tier_record(tier_records[key])
	var version: Variant = data.get("version", 0)
	if (version is int or version is float) and int(version) < SaveDataV8Class.VERSION:
		_top_up_old_milestone_gems()
	_catch_up_passed_milestones()
	selected_tier = int(data.get("selected_tier", 1))
	if not balance_profile.has_tier(selected_tier):
		selected_tier = 1

## Before V8 a checkpoint paid one Gem, and only the four Coin checkpoints were
## checkpoints. A save from then gets the difference for every one it already
## claimed; the version bump is what marks the top-up as done (D030).
func _top_up_old_milestone_gems() -> void:
	for tier in balance_profile.tiers:
		var record: Variant = tier_records.get(str(tier.id), {})
		if not (record is Dictionary):
			continue
		for claimed_wave in record.get("milestones_claimed", []):
			if balance_profile.COIN_MILESTONE_WAVES.has(claimed_wave):
				var top_up := maxi(0, balance_profile.milestone_gems(tier.id, claimed_wave) - PRE_V8_MILESTONE_GEMS)
				gems += top_up
				milestone_gems_caught_up += top_up

## A checkpoint a record has already passed but not claimed — one added after
## the player cleared it, or one a migration left unclaimed — pays on load
## exactly what claiming it would have, so no one re-clears a wave to be paid
## for it (D030). Idempotent: a paid checkpoint is claimed.
func _catch_up_passed_milestones() -> void:
	for tier in balance_profile.tiers:
		var record: Variant = tier_records.get(str(tier.id), {})
		if not (record is Dictionary):
			continue
		var best := int(record.get("highest_wave", 0))
		var claimed: Array = record.get("milestones_claimed", [])
		var changed := false
		for checkpoint in balance_profile.MILESTONE_WAVES:
			if checkpoint > best or claimed.has(checkpoint):
				continue
			claimed.append(checkpoint)
			changed = true
			coins += floori(float(balance_profile.milestone_bonus(tier.id, checkpoint)) * (1.0 + _effect_sum("coin_bonus")))
			var gem_bonus := balance_profile.milestone_gems(tier.id, checkpoint)
			gems += gem_bonus
			milestone_gems_caught_up += gem_bonus
		if changed:
			claimed.sort()
			record.milestones_claimed = claimed

## JSON reads every number back as a float, and Array.has(10) does not match
## 10.0, so a milestone claimed before a reload looked unclaimed and paid its
## bonus again. Whole-number waves, each listed once, keep the claim to one
## per tier record; saves that already hold a duplicate collapse to one entry.
func _normalise_tier_record(record: Dictionary) -> void:
	var saved_best: Variant = record.get("highest_wave", 0)
	record.highest_wave = int(saved_best) if (saved_best is int or saved_best is float) else 0
	var claimed: Array = []
	var saved_claimed: Variant = record.get("milestones_claimed", [])
	if saved_claimed is Array:
		for value in saved_claimed:
			if not (value is int or value is float):
				continue
			var claimed_wave := int(value)
			if claimed_wave > 0 and not claimed.has(claimed_wave):
				claimed.append(claimed_wave)
	record.milestones_claimed = claimed

## A saved active run resumes with identical remaining Liability and identical
## RNG state (D006). A save taken between runs restores a clean run instead.
func _restore_saved_run(data: Dictionary) -> void:
	wave = maxi(1, int(data.get("wave", 1)))
	wave_accumulator = clampf(float(data.get("wave_accumulator", 0.0)), 0.0, WAVE_INTERVAL_SECONDS)
	in_run = bool(data.get("in_run", false))
	var loaded_modifiers: Variant = data.get("active_rule_modifiers", [])
	active_rule_modifiers = loaded_modifiers if loaded_modifiers is Array else []
	run_coins_earned = int(data.get("run_coins_earned", 0))
	run_gems_earned = maxi(0, int(data.get("run_gems_earned", 0))) if in_run else 0
	run_elapsed = maxf(0.0, float(data.get("run_elapsed", 0.0)))
	run_seed = str(data.get("run_seed", "0")).to_int()
	braced = bool(data.get("braced", false))
	brace_spent = bool(data.get("brace_spent", false)) and in_run
	# Added after V5 shipped; a save without them resumes with an unspent Second
	# Wind and its peak re-established from the Number it restores.
	var saved_peak: Variant = data.get("run_peak_number", null)
	run_peak_number = ScientificNumber.from_dict(saved_peak) if saved_peak is Dictionary else number.copy()
	second_wind_used = bool(data.get("second_wind_used", false))
	# V6 keeps the tick phase and crit chain, so the outputs after a reload are
	# the ones the saved run would have produced (D006). Older saves resume at
	# a fresh phase and an unbroken chain, as they always did.
	tick_accumulator = maxf(0.0, float(data.get("tick_accumulator", 0.0))) if in_run else 0.0
	critical_chain = maxi(0, int(data.get("critical_chain", 0))) if in_run else 0
	cash = ScientificNumber.from_dict(data.get("cash", {})) if in_run and data.has("cash") else ScientificNumber.new()
	run_cash_earned = ScientificNumber.from_dict(data.get("run_cash_earned", {})) if in_run and data.has("run_cash_earned") else cash.copy()
	rig_ranks = {}
	if in_run:
		var encounter_data: Variant = data.get("active_encounter", null)
		active_encounter = TaxEncounterClass.from_dict(encounter_data) if encounter_data is Dictionary else _make_encounter(wave)
		if str(data.get("balance_profile_id", "")) != balance_profile.PROFILE_ID:
			_rebuild_encounter_on_current_profile()
		# Added after V5 shipped, like the run peak: a save without Rig ranks
		# resumes with none, and malformed ranks read as none rather than crash.
		var saved_rig: Variant = data.get("rig_ranks", {})
		if saved_rig is Dictionary:
			for rig_id in saved_rig:
				rig_ranks[str(rig_id)] = maxi(0, int(saved_rig[rig_id]))
		var saved_rng_state := str(data.get("rng_state", "0")).to_int()
		if saved_rng_state != 0:
			rng.state = saved_rng_state
		elif run_seed != 0:
			rng.seed = run_seed
	else:
		active_encounter = null
		wave = 1
		wave_accumulator = 0.0
		rig_ranks = {}
	# A save taken between runs settles research finished since; one taken
	# mid-run leaves it for the run's end (D031).
	_settle_labs()

## A run saved under an older balance profile resumes on the current one
## (D040). The Hit an old profile read at load time, such as the retired wave
## 21-25 ramp, was never stored, so keeping the old encounter could land a far
## bigger Hit than the player was last shown. The active wave is rebuilt from
## today's curve, keeping the share of its HP already cleared.
func _rebuild_encounter_on_current_profile() -> void:
	if active_encounter == null:
		return
	var cleared := get_wave_cleared_share()
	var rebuilt = _make_encounter(wave)
	# Member for member where the group matches (D057), so a member that has
	# hit never hits again early; otherwise by the share cleared. If members had
	# already landed, every one whose hits are overdue is moved on to its next
	# hit without dealing it; a pre-group wave had landed nothing, so its
	# overdue members land as the rules say. Members carried in from earlier
	# waves come across either way (D058).
	if not rebuilt.carry_from(active_encounter):
		rebuilt.set_remaining(rebuilt.max_liability.multiply_scalar(1.0 - cleared))
		if active_encounter.landed_count() > 0:
			while true:
				var overdue: int = rebuilt.due_index(wave_accumulator)
				if overdue < 0:
					break
				rebuilt.hit(overdue)
		rebuilt.carry_in(active_encounter.living_members().filter(func(member): return not active_encounter.is_own(member)))
	# Carried members are rebuilt on today's curve too, keeping the share of
	# their HP they had left, so no old-profile Hit lands (D040).
	for member in rebuilt.members:
		if rebuilt.is_own(member):
			continue
		var remaining_share := TaxEncounterClass._ratio(member.hp, member.max)
		var liability := RuleModifierPipelineClass.apply(balance_profile.liability_for_wave(selected_tier, int(member.wave)), "liability", active_rule_modifiers)
		member.max = liability.multiply_scalar(float(member.share))
		member.hp = member.max.multiply_scalar(remaining_share)
		member.wave_hit = balance_profile.collection_for_wave(selected_tier, int(member.wave))
	rebuilt._sum_remaining()
	active_encounter = rebuilt

func _seconds_since(data: Dictionary) -> float:
	return Time.get_unix_time_from_system() - float(data.get("last_seen_unix", Time.get_unix_time_from_system()))

func _migrate_v3(data: Dictionary, source_path: String) -> OfflineAward:
	_load_common_fields(data)
	_fold_retired_workshop_shape(data)
	_load_tier_progress(data)
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
		_rebuild_encounter_on_current_profile()
		var saved_rng_state := str(data.get("rng_state", "0")).to_int()
		if saved_rng_state != 0:
			rng.state = saved_rng_state
		elif run_seed != 0:
			rng.seed = run_seed
	else:
		_reset_run_state()
	_save_migrated_state(3, source_path)
	return OfflineAward.new()

func _load_common_fields(data: Dictionary) -> void:
	number = ScientificNumber.from_dict(data.number)
	lifetime_generated = ScientificNumber.from_dict(data.lifetime)
	highest_number = ScientificNumber.from_dict(data.get("highest", data.number))
	purchased = _ranks_within_caps(data.get("purchased", {}))
	knowledge = int(data.get("knowledge", 0))
	knowledge_purchased = _ranks_within_caps(data.get("knowledge_purchased", {}))
	# Added after V5 shipped, like the Rig's ranks (D015): a save without Labs
	# resumes with none, and a malformed block reads as empty rather than
	# crashing. Labs are permanent, so they load in the common fields rather
	# than the active-run block.
	var saved_lab_ranks: Variant = data.get("lab_ranks", {})
	lab_ranks = {}
	if saved_lab_ranks is Dictionary:
		for research_id in saved_lab_ranks:
			var lab_definition = lab_research.get_definition(str(research_id))
			var lab_rank := maxi(0, int(saved_lab_ranks[research_id])) if (saved_lab_ranks[research_id] is int or saved_lab_ranks[research_id] is float) else 0
			lab_ranks[str(research_id)] = mini(lab_rank, lab_definition.max_rank) if lab_definition != null else lab_rank
	lab_active.clear()
	var saved_lab_active: Variant = data.get("lab_active", {})
	if saved_lab_active is Dictionary:
		for research_id in saved_lab_active:
			var entry: Variant = saved_lab_active[research_id]
			if entry is Dictionary and entry.has("started_unix") and entry.has("duration"):
				lab_active[str(research_id)] = {
					"started_unix": float(entry.started_unix),
					"duration": float(entry.duration),
				}
	# V7 (D029). A save without the field predates bought slots, when every
	# player had two, so it keeps two rather than dropping to the new start.
	lab_slots = clampi(int(data.get("lab_slots", LabResearchClass.LEGACY_SLOTS)), LabResearchClass.STARTING_SLOTS, LabResearchClass.MAX_SLOTS)
	# Added after V5 shipped too: Cards are permanent, like Labs (D027).
	gems = int(data.get("gems", 0))
	var saved_card_ranks: Variant = data.get("card_ranks", {})
	card_ranks = {}
	if saved_card_ranks is Dictionary:
		for card_id in saved_card_ranks:
			var level: Variant = saved_card_ranks[card_id]
			card_ranks[str(card_id)] = clampi(int(level), 0, CardCollectionClass.MAX_LEVEL) if (level is int or level is float) else 0
	card_active.clear()
	var saved_card_active: Variant = data.get("card_active", [])
	if saved_card_active is Array:
		for card_id in saved_card_active:
			var id_string := str(card_id)
			if not card_active.has(id_string) and card_collection.get_definition(id_string) != null:
				card_active.append(id_string)
	if card_active.size() > CardCollectionClass.ACTIVE_SLOTS:
		card_active = card_active.slice(0, CardCollectionClass.ACTIVE_SLOTS)
	focus_path = str(data.get("focus", ""))
	automation_enabled = bool(data.get("automation_enabled", true))
	workshop.from_dict(data.get("workshop", {}))
	coins = int(data.get("coins", 0))
	highest_wave = int(data.get("highest_wave", 1))
	statistics.merge(data.get("statistics", {}), true)
	settings.merge(data.get("settings", {}), true)
	# "ambience" named the retired background pad. Dropping it on load keeps the
	# dead key out of saves rewritten in the current shape.
	settings.erase("ambience")

## Ranks as the catalogue allows them: whole, never negative, and never past a
## row's cap, so a cap lowered by a retune takes effect on saves that already
## hold more. A rank under an id the catalogue no longer has is kept as it was:
## nothing counts it, and keeping it leaves a refund possible later.
func _ranks_within_caps(saved: Dictionary) -> Dictionary:
	var ranks := {}
	for upgrade_id in saved:
		var value: Variant = saved[upgrade_id]
		var rank := maxi(0, int(value)) if (value is int or value is float) else 0
		var definition := get_definition(str(upgrade_id))
		ranks[str(upgrade_id)] = mini(rank, definition.max_rank) if definition != null else rank
	return ranks

func _migrate_v2(data: Dictionary, source_path: String) -> OfflineAward:
	_load_common_fields(data)
	_fold_retired_workshop_shape(data)
	selected_tier = 1
	var old_best := maxi(1, int(data.get("highest_wave", 1)))
	tier_records = {"1": {"highest_wave": old_best, "best_time": 0.0, "milestones_claimed": []}}
	_ensure_tier_records()
	_catch_up_passed_milestones()
	in_run = bool(data.get("in_run", false))
	run_coins_earned = int(data.get("run_coins_earned", 0))
	wave = maxi(1, int(data.get("wave", 1))) if in_run else 1
	wave_accumulator = clampf(float(data.get("wave_accumulator", 0.0)), 0.0, WAVE_INTERVAL_SECONDS) if in_run else 0.0
	run_seed = int(Time.get_ticks_usec()) ^ int(Time.get_unix_time_from_system())
	rng.seed = run_seed
	active_encounter = _make_encounter(wave) if in_run else null
	if not in_run:
		_reset_run_state()
	_save_migrated_state(2, source_path)
	return OfflineAward.new()

func _migrate_v1(data: Dictionary, source_path: String) -> void:
	number = ScientificNumber.from_dict(data.number)
	lifetime_generated = ScientificNumber.from_dict(data.lifetime)
	highest_number = ScientificNumber.from_dict(data.get("highest", data.number))
	statistics.merge(data.get("statistics", {}), true)
	settings.merge(data.get("settings", {}), true)
	settings.erase("ambience")
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
	lab_slots = LabResearchClass.LEGACY_SLOTS
	focus_path = ProgressionTaxonomy.category_for_legacy_bay(str(data.get("focus", "")))
	var old_target := str(data.get("auto_selected", ""))
	if old_target != "":
		workshop.automation_targets = [old_target]
	_reset_run_state()
	_save_migrated_state(1, source_path)

## The file a migration read is copied aside, once per version, before the
## migrated save replaces it: a migration that turns out to be wrong can then
## be undone by hand rather than being final.
func _save_migrated_state(from_version: int, source_path: String) -> void:
	var kept := _migration_backup_path(from_version)
	if FileAccess.file_exists(source_path) and not FileAccess.file_exists(kept):
		DirAccess.copy_absolute(_global(source_path), _global(kept))
	save()

## Clearing the save removes every file this save path owns: the live save,
## its backup and temp file, migration copies and moved-aside unreadable saves.
func clear_save() -> void:
	for path in [save_path, _backup_path(), _temp_path()]:
		_remove_if_present(path)
	for version in range(1, SaveDataV10Class.VERSION):
		_remove_if_present(_migration_backup_path(version))
	var folder := save_path.get_base_dir()
	var quarantine_prefix := save_path.get_file().get_basename() + QUARANTINE_INFIX
	var directory := DirAccess.open(folder)
	if directory != null:
		directory.include_hidden = true
		for file_name in directory.get_files():
			if file_name.begins_with(quarantine_prefix) and file_name.ends_with(".json"):
				_remove_if_present(folder.path_join(file_name))
	saving_paused = false

func _backup_path() -> String:
	return save_path + ".bak"

func _temp_path() -> String:
	return save_path + ".tmp"

func _migration_backup_path(version: int) -> String:
	return save_path.get_basename() + ".v%d-backup.json" % version

func _quarantine_path() -> String:
	return save_path.get_basename() + QUARANTINE_INFIX + str(int(Time.get_unix_time_from_system())) + ".json"

func _global(path: String) -> String:
	return ProjectSettings.globalize_path(path)

func _remove_if_present(path: String) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(_global(path))

func has_persistent_storage() -> bool:
	return OS.is_userfs_persistent()

## Everything produced is Number, and the same output also counts against the
## active wave (D037): the Number never stops rising while the player produces.
## Lifetime production counts it once, so Knowledge is unchanged.
func _add_number(amount: ScientificNumber) -> void:
	lifetime_generated = lifetime_generated.add(amount)
	var banked := amount
	if in_run and active_encounter != null:
		var into_wave: ScientificNumber = active_encounter.apply_compliance(amount)
		# Leech (D038) feeds on a boss that stands and fights: a share of the
		# damage it takes is added to the Number a second time. The combined
		# share is capped (D023) so Rig ranks cannot stack it without limit.
		var leech := minf(_effect_sum("siphon_share"), balance_profile.SIPHON_CEILING)
		if leech > 0.0 and active_encounter.is_boss and not into_wave.is_zero():
			banked = banked.add(into_wave.multiply_scalar(leech))
	number = number.add(banked)
	if number.compare_to(highest_number) > 0:
		highest_number = number.copy()
	if number.compare_to(run_peak_number) > 0:
		run_peak_number = number.copy()

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

## Every run produces from its first second (D033): an idle game that does
## nothing until a Workshop rank is bought reads as broken. The base is a flat
## floor per second, not raised by upgrades, so it starts a new player without
## making a built-up one stronger. Per tick it is shared across the ticks in a
## second.
func _base_output_per_tick() -> float:
	return balance_profile.BASE_DAMAGE_PER_SECOND / _tick_rate()

func _tick_rate() -> float:
	return balance_profile.BASE_SHOTS_PER_SECOND * _effect_product("tick_rate", 1.0)

## Everything that scales produced damage, including the boss-only bonus. Taps,
## ticks and the displayed rate all read it, so a boss wave cannot show one
## number and deal another.
func _damage_multiplier() -> float:
	return _base_output_multiplier() * _boss_damage_multiplier()

func _boss_damage_multiplier() -> float:
	if active_encounter == null or not active_encounter.is_boss:
		return 1.0
	return 1.0 + _effect_sum("boss_damage")

func _base_output_multiplier() -> float:
	return _effect_product("base_output_multiplier", 1.0)

func _momentum_multiplier() -> float:
	return 1.0 + float(momentum_stacks) * _effect_sum("momentum_per_tick")

func _critical_chance() -> float:
	return clampf(_effect_sum("critical_chance"), 0.0, 0.8)

func _critical_multiplier() -> float:
	return 2.0 + _effect_sum("critical_multiplier_add")

func _chain_reaction_step() -> float:
	return 0.005 * (float(get_owned("chain_reaction")) + rig_rank_equivalent(get_definition("chain_reaction")))

## Burst shortens the interval by one tick per rank, from 12 down to the same
## floor of 6 the three-rank version reached. The floor is what keeps deepening
## this row a pacing change rather than a power change, and it holds for Rig
## ranks too: a rank is one step, never multiplied, so one purchase cannot
## reach the floor by itself.
func _burst_interval() -> int:
	var rank := get_owned("burst_relay") + rig_owned("burst_relay")
	if rank <= 0:
		return 0
	return maxi(6, 12 - rank)

## What a row's Workshop and run ranks are worth together, in steps of its
## effect: one a rank, or more along a deep row's depth curve (D047).
func _row_units(definition: UpgradeDefinition) -> float:
	return definition.units_at(float(get_owned(definition.id)) + rig_rank_equivalent(definition))

func _effect_sum(effect_name: String) -> float:
	var total := 0.0
	for definition in definitions:
		if definition.effects.has(effect_name):
			total += float(definition.effects[effect_name]) * _row_units(definition)
	total += _lab_effect_sum(effect_name)
	return total

func _effect_product(effect_name: String, base: float) -> float:
	var total := base
	for definition in definitions:
		if definition.effects.has(effect_name):
			total *= pow(float(definition.effects[effect_name]), _row_units(definition))
	for lab_definition in lab_research.definitions:
		if lab_definition.effects.has(effect_name):
			total *= pow(float(lab_definition.effects[effect_name]), float(_lab_rank(lab_definition.id)))
	for card_definition in card_collection.definitions:
		if is_card_active(card_definition.id) and card_definition.effects.has(effect_name):
			total *= pow(float(card_definition.effects[effect_name]), float(get_card_level(card_definition.id)))
	return total

## Labs are permanent and time-gated rather than run-scoped, so they have no
## Rig-style equivalent to add: a finished rank simply always counts.
func _lab_effect_sum(effect_name: String) -> float:
	var total := 0.0
	for lab_definition in lab_research.definitions:
		if lab_definition.effects.has(effect_name):
			total += float(lab_definition.effects[effect_name]) * float(_lab_rank(lab_definition.id))
	total += _card_effect_sum(effect_name)
	return total

## Only an Active card counts: Inventory is owned but idle, matching the
## reference's Active/Inventory split. Level, not rank-plus-Rig-equivalent,
## since a card has no run-scoped counterpart of its own.
func _card_effect_sum(effect_name: String) -> float:
	var total := 0.0
	for card_definition in card_collection.definitions:
		if is_card_active(card_definition.id) and card_definition.effects.has(effect_name):
			total += float(card_definition.effects[effect_name]) * float(get_card_level(card_definition.id))
	return total

## The Workshop and Knowledge catalogues, loaded from res://data/ (the single
## authority for game content).
func _make_definitions() -> Array[UpgradeDefinition]:
	return GameDataClass.get_all_upgrades()

