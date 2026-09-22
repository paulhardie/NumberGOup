class_name SaveDataV7
extends RefCounted

## V7 is a read-only migration source (D029, D030) now that V8 owns the written
## shape. It added `lab_slots` to V6; V8 keeps every V7 key and meaning and
## adds only the run's Gems, so a V7 save loads through the same reader, has
## its old-rate milestone Gems topped up, and is rewritten as V8.
const VERSION := 7

static func is_valid(data: Variant) -> bool:
	return (
		data is Dictionary
		and int(data.get("version", 0)) == VERSION
		and data.has("number")
		and data.has("lifetime")
	)
