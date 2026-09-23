class_name SaveDataV8
extends RefCounted

## V8 is a read-only migration source now that V9 owns the written shape. It
## added the run's Gems to V7 and marks that old-rate milestone Gems were
## topped up; V9 keeps every V8 key and meaning, so a V8 save loads through the
## same reader and is rewritten as V9.
const VERSION := 8

static func is_valid(data: Variant) -> bool:
	return (
		data is Dictionary
		and int(data.get("version", 0)) == VERSION
		and data.has("number")
		and data.has("lifetime")
	)
