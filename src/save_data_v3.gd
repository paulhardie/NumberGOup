class_name SaveDataV3
extends RefCounted

## V3 is a read-only migration source (D007): the writer that described this
## shape is gone, because the state it read no longer has V3's fields.
const VERSION := 3

static func is_valid(data: Variant) -> bool:
	return (
		data is Dictionary
		and int(data.get("version", 0)) == VERSION
		and data.has("number")
		and data.has("lifetime")
	)
