class_name SaveDataV8
extends RefCounted

## V8 is V7 plus `run_gems_earned`, the Gems the active run has paid (D030).
## The version also marks that milestones claimed at the old rate of one Gem
## were topped up to the new table: a save from before V8 gets the difference
## once, on load, and a V8 save never does. Every other key keeps its V7 name
## and meaning.
const VERSION := 8

static func make(state) -> Dictionary:
	return {
		"version": VERSION,
		"economy_model": "workshop-categories-v1",
		"number": state.number.to_dict(),
		"lifetime": state.lifetime_generated.to_dict(),
		"highest": state.highest_number.to_dict(),
		"purchased": state.purchased,
		"knowledge": state.knowledge,
		"knowledge_purchased": state.knowledge_purchased,
		"focus": state.focus_path,
		"automation_enabled": state.automation_enabled,
		"workshop": state.workshop.to_dict(),
		"wave": state.wave,
		"wave_accumulator": state.wave_accumulator,
		"coins": state.coins,
		"highest_wave": state.highest_wave,
		"braced": state.braced,
		"run_peak_number": state.run_peak_number.to_dict(),
		"second_wind_used": state.second_wind_used,
		"cash": state.cash.to_dict(),
		"run_cash_earned": state.run_cash_earned.to_dict(),
		"rig_ranks": state.rig_ranks,
		"tick_accumulator": state.tick_accumulator,
		"critical_chain": state.critical_chain,
		"lab_ranks": state.lab_ranks,
		"lab_active": state.lab_active,
		"lab_slots": state.lab_slots,
		"gems": state.gems,
		"card_ranks": state.card_ranks,
		"card_active": state.card_active,
		"in_run": state.in_run,
		"run_coins_earned": state.run_coins_earned,
		"run_gems_earned": state.run_gems_earned,
		"run_elapsed": state.run_elapsed,
		# JSON numbers cannot exactly represent every 64-bit RNG value. Strings
		# preserve deterministic replay across save/load without precision loss.
		"run_seed": str(state.run_seed),
		"rng_state": str(state.rng.state),
		"selected_tier": state.selected_tier,
		"tier_records": state.tier_records,
		"active_encounter": state.active_encounter.to_dict() if state.active_encounter != null else null,
		"active_rule_modifiers": state.active_rule_modifiers,
		"balance_profile_id": state.balance_profile.PROFILE_ID,
		"statistics": state.statistics,
		"settings": state.settings,
		"last_seen_unix": Time.get_unix_time_from_system(),
	}

static func is_valid(data: Variant) -> bool:
	return (
		data is Dictionary
		and int(data.get("version", 0)) == VERSION
		and data.has("number")
		and data.has("lifetime")
	)

## Why a parsed save of any version cannot be loaded, or "" if it can. The
## loader assigns these blocks to typed fields, so a wrong type would stop the
## load halfway and leave a partial state for the next autosave to write over
## the player's progress. Checking first turns such a file away whole.
static func problem(data: Dictionary) -> String:
	for key in ["number", "lifetime"]:
		if not (data.get(key) is Dictionary):
			return key + " is missing"
	for key in ["number", "lifetime", "highest"]:
		if data.has(key) and data[key] is Dictionary:
			var mantissa: Variant = data[key].get("mantissa", 0.0)
			if not ((mantissa is int or mantissa is float) and is_finite(float(mantissa))):
				return key + " is not a finite number"
	for key in ["highest", "purchased", "knowledge_purchased", "workshop", "tier_records", "statistics", "settings"]:
		if data.has(key) and not (data[key] is Dictionary):
			return key + " is not an object"
	for key in ["coins", "knowledge", "gems", "lab_slots", "run_gems_earned", "wave", "highest_wave", "selected_tier"]:
		if data.has(key) and not (data[key] is int or data[key] is float):
			return key + " is not a number"
	return ""
