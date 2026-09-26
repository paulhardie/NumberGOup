extends RefCounted
## Reads and writes the rebuilt game's save: the Workshop, as JSON with a
## version. It is its own file, so the pre-rebuild save is never touched
## (D073). A file this version can't read is moved aside, never written over.

const Workshop = preload("res://src/tower/workshop.gd")

const PATH := "user://number_go_up_tower.json"
const VERSION := 1


## The saved Workshop, or a fresh one when there's no save. A save that can't
## be read, or is from another version, is kept beside it as
## "<name>.unreadable-<time>.json" and the game starts fresh.
static func load_workshop(path: String = PATH) -> Workshop:
	var workshop := Workshop.new()
	if not FileAccess.file_exists(path):
		return workshop
	# JSON.parse reports a broken file by its return value, where parse_string
	# would print an engine error.
	var json := JSON.new()
	var parsed = json.data if json.parse(FileAccess.get_file_as_string(path)) == OK else null
	if parsed is Dictionary and int(parsed.get("version", 0)) == VERSION and parsed.get("workshop") is Dictionary:
		workshop.restore(parsed.workshop)
		return workshop
	var aside := "%s.unreadable-%d.json" % [path.get_basename(), int(Time.get_unix_time_from_system())]
	DirAccess.rename_absolute(path, aside)
	push_warning("The save at %s couldn't be read, so it was kept as %s and the game started fresh." % [path, aside])
	return workshop


## Writes to a temporary file first and then swaps it in, so a crash mid-write
## never leaves half a save.
static func save_workshop(workshop: Workshop, path: String = PATH) -> bool:
	var temporary := path + ".tmp"
	var file := FileAccess.open(temporary, FileAccess.WRITE)
	if file == null:
		push_warning("Couldn't write the save to %s." % temporary)
		return false
	# Full precision, so a large Coin balance comes back to the last digit.
	file.store_string(JSON.stringify({"version": VERSION, "workshop": workshop.to_dict()}, "", true, true))
	file.close()
	return DirAccess.rename_absolute(temporary, path) == OK
