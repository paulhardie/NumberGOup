class_name SaveDataV3
extends RefCounted

const VERSION := 3

static func make(state) -> Dictionary:
	return {
		"version": VERSION,
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
		"tax_resistance_rank": state.tax_resistance_rank,
		"braced": state.braced,
		"in_run": state.in_run,
		"run_coins_earned": state.run_coins_earned,
		"run_elapsed": state.run_elapsed,
		# JSON numbers cannot exactly represent every 64-bit RNG value. Strings
		# preserve deterministic replay across save/load without precision loss.
		"run_seed": str(state.run_seed),
		"rng_state": str(state.rng.state),
		"selected_tier": state.selected_tier,
		"tier_records": state.tier_records,
		"active_encounter": state.active_encounter.to_dict() if state.active_encounter != null else null,
		"active_rule_modifiers": state.active_rule_modifiers,
		"balance_profile_id": "tax-foundation-v1",
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
