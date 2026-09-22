class_name SaveDataV5
extends RefCounted

## V5 is a read-only migration source (D007, D028) now that V6 owns the written
## shape. It is V4 with the Workshop reorganised into four categories (D013,
## D017), plus the Rig, Labs and Cards fields that were added to it after it
## shipped; V6 keeps every one of those keys and meanings, so a V5 save loads
## through the same reader and is rewritten as V6.
const VERSION := 5

static func is_valid(data: Variant) -> bool:
	return (
		data is Dictionary
		and int(data.get("version", 0)) == VERSION
		and data.has("number")
		and data.has("lifetime")
	)
