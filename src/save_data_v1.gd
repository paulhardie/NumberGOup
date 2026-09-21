class_name SaveDataV2
extends RefCounted

## V1 and V2 are read-only migration sources (D007): only is_valid and
## is_legacy_v1 are still used, so the writer that described this shape is gone.
const VERSION := 2

static func is_valid(data: Variant) -> bool:
	return data is Dictionary and int(data.get("version", 0)) == VERSION and data.has("number") and data.has("lifetime")

static func is_legacy_v1(data: Variant) -> bool:
	return data is Dictionary and int(data.get("version", 0)) == 1 and data.has("number") and data.has("lifetime")
