class_name SaveDataV11
extends RefCounted

const SaveDataV10Class = preload("res://src/save_data_v10.gd")

## V11 is V10 plus facts about each member of the active wave: `boss`,
## whether it is a boss (which can now be carried into later waves, D063);
## `hits`, how many hits it has landed (each heats up the next by 4%); its
## `weight` and its wave's total (`of`), from which its share is read back
## exactly (D065); and its `kind`, the enemy type, and `paid`, whether its kill
## has paid (D066). The run adds `coin_fraction`, the part of a Coin kills have
## earned but not yet paid. A V10 build would read a carried boss as an
## ordinary enemy and lose its heat, so it refuses a V11 save instead (D028).
## A V10 save loads through the same reader: a boss is its own wave's, a member
## that landed has hit once, members are basic enemies or bosses, and one
## already killed is paid when the rebuild onto today's profile carries it.
const VERSION := 11

static func make(state) -> Dictionary:
	var data: Dictionary = SaveDataV10Class.make(state)
	data.version = VERSION
	data.coin_fraction = state.coin_fraction
	return data

static func is_valid(data: Variant) -> bool:
	return (
		data is Dictionary
		and int(data.get("version", 0)) == VERSION
		and data.has("number")
		and data.has("lifetime")
	)

## Why a parsed save of any version cannot be loaded, or "" if it can.
static func problem(data: Dictionary) -> String:
	return SaveDataV10Class.problem(data)
