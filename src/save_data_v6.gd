class_name SaveDataV6
extends RefCounted

## V6 is a read-only migration source (D028, D029) now that V7 owns the written
## shape. It declared every field added to V5 after V5 shipped and added the
## run's `tick_accumulator` and `critical_chain`; V7 keeps all of them and adds
## only `lab_slots`, so a V6 save loads through the same reader and is
## rewritten as V7.
const VERSION := 6

static func is_valid(data: Variant) -> bool:
	return (
		data is Dictionary
		and int(data.get("version", 0)) == VERSION
		and data.has("number")
		and data.has("lifetime")
	)
