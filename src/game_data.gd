class_name GameData
extends RefCounted

## Central data repository and loader for Number Go Up, decoupling content
## definitions (Workshop ladders, Knowledge, Cards, Labs) from game logic.
## Data lives canonically in res://data/ and is loaded at runtime into typed
## domain objects.

const WORKSHOP_UPGRADES_PATH := "res://data/workshop/upgrades.json"
const KNOWLEDGE_UPGRADES_PATH := "res://data/knowledge/upgrades.json"
const CARDS_PATH := "res://data/cards/cards.json"
const LABS_PATH := "res://data/labs/research.json"

static var _workshop_cache: Array[UpgradeDefinition] = []
static var _knowledge_cache: Array[UpgradeDefinition] = []

static func clear_cache() -> void:
	_workshop_cache.clear()
	_knowledge_cache.clear()

## Loads all Workshop upgrade definitions from res://data/workshop/upgrades.json.
static func get_workshop_upgrades() -> Array[UpgradeDefinition]:
	if not _workshop_cache.is_empty():
		return _workshop_cache.duplicate()
	var raw := _read_json(WORKSHOP_UPGRADES_PATH)
	var list: Array = raw.get("upgrades", [])
	var result: Array[UpgradeDefinition] = []
	for item in list:
		if item is Dictionary:
			result.append(UpgradeDefinition.from_dict(item))
	_workshop_cache = result.duplicate()
	return result

## Loads Knowledge-layer upgrade definitions from res://data/knowledge/upgrades.json.
static func get_knowledge_upgrades() -> Array[UpgradeDefinition]:
	if not _knowledge_cache.is_empty():
		return _knowledge_cache.duplicate()
	var raw := _read_json(KNOWLEDGE_UPGRADES_PATH)
	var list: Array = raw.get("upgrades", [])
	var result: Array[UpgradeDefinition] = []
	for item in list:
		if item is Dictionary:
			result.append(UpgradeDefinition.from_dict(item))
	_knowledge_cache = result.duplicate()
	return result

## Returns all upgrade definitions (Workshop + Knowledge) used by GameState.
static func get_all_upgrades() -> Array[UpgradeDefinition]:
	var all: Array[UpgradeDefinition] = []
	all.append_array(get_workshop_upgrades())
	all.append_array(get_knowledge_upgrades())
	return all

## Safely reads and parses a JSON file from disk.
static func _read_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		push_error("GameData: file not found at " + path)
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("GameData: failed to open " + path + " error " + str(FileAccess.get_open_error()))
		return {}
	var content := file.get_as_text()
	var parsed: Variant = JSON.parse_string(content)
	if not (parsed is Dictionary):
		push_error("GameData: invalid JSON dictionary in " + path)
		return {}
	return parsed
