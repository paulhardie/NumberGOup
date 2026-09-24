class_name SaveDataV11
extends RefCounted

const SaveDataV10Class = preload("res://src/save_data_v10.gd")

## V11 is V10 plus three facts about each member of the active wave (D063):
## `boss`, whether it is a boss (which can now be carried into later waves),
## `hits`, how many hits it has landed (each heats up the next by 4%), and
## `unpaid`, the share of its passed wave's reward an enemy still owes when
## it is beaten. A V10 build would read a carried boss as an ordinary enemy and lose
## its heat, so it refuses a V11 save instead (D028). A V10 save loads through
## the same reader: a boss is its own wave's, a member that landed has hit
## once, and nothing is owed.
const VERSION := 11

static func make(state) -> Dictionary:
	var data: Dictionary = SaveDataV10Class.make(state)
	data.version = VERSION
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
