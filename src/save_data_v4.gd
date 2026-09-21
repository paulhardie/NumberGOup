class_name SaveDataV4
extends RefCounted

## V4 is a read-only migration source (D007) now that V5 owns the written
## shape. `tax_resistance_rank` in a V4 save becomes the `tax_resistance`
## Workshop rank on migration.
const VERSION := 4

static func is_valid(data: Variant) -> bool:
	return (
		data is Dictionary
		and int(data.get("version", 0)) == VERSION
		and data.has("number")
		and data.has("lifetime")
	)
