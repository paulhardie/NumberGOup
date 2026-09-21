class_name SaveDataV2
extends RefCounted

const VERSION := 2

static func make(state: GameState) -> Dictionary:
	return {
		"version": VERSION,
		"number": state.number.to_dict(),
		"lifetime": state.lifetime_generated.to_dict(),
		"highest": state.highest_number.to_dict(),
		"purchased": state.purchased,
		"knowledge": state.knowledge,
		"knowledge_purchased": state.knowledge_purchased,
		"focus": state.focus_path,
		"auto_selected": state.auto_selected_id,
		"automation_enabled": state.automation_enabled,
		"workshop": state.workshop.to_dict(),
		"wave": state.wave,
		"wave_accumulator": state.wave_accumulator,
		"coins": state.coins,
		"highest_wave": state.highest_wave,
		"tax_resistance_rank": state.tax_resistance_rank,
		"in_run": state.in_run,
		"run_coins_earned": state.run_coins_earned,
		"statistics": state.statistics,
		"settings": state.settings,
		"last_seen_unix": Time.get_unix_time_from_system()
	}

static func is_valid(data: Variant) -> bool:
	return data is Dictionary and int(data.get("version", 0)) == VERSION and data.has("number") and data.has("lifetime")

static func is_legacy_v1(data: Variant) -> bool:
	return data is Dictionary and int(data.get("version", 0)) == 1 and data.has("number") and data.has("lifetime")
