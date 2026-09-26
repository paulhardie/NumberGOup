extends RefCounted
## The activity log (D077): every run and every Workshop purchase, one JSON
## line each, in its own file beside the save, so the owner can export a
## report for an agent to read and replay (tools/read_report.gd). It holds
## game numbers and times only, and never leaves the machine by itself: the
## owner exports a file and hands it over.

const PATH := "user://number_go_up_activity.jsonl"
const REPORTS := "user://reports"
const FORMAT := "number-go-up-activity"
const VERSION := 1

static var _game := ""


## Adds `entry`, stamped with the time (UTC) and the game's version, unless
## it already names the version that recorded it (a saved run lost to an
## update keeps its own, so a replay is only tried on that one). Appends
## one whole line, so a crash can at worst tear the last line, which read()
## skips.
static func append(entry: Dictionary, path: String = PATH) -> bool:
	var line := entry.duplicate(true)
	line["at"] = Time.get_datetime_string_from_system(true)
	if not line.get("game") is String:
		line["game"] = game_version()
	var file := FileAccess.open(path, FileAccess.READ_WRITE) if FileAccess.file_exists(path) else FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_warning("Couldn't write the activity log at %s." % path)
		return false
	file.seek_end()
	# Full precision, so a replay starts from exactly the recorded numbers.
	file.store_line(JSON.stringify(line, "", false, true))
	file.close()
	return true


## Every entry that reads, oldest first. A line that doesn't read (torn by a
## crash) is skipped.
static func read(path: String = PATH) -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	if not FileAccess.file_exists(path):
		return entries
	for text in FileAccess.get_file_as_string(path).split("\n", false):
		var json := JSON.new()
		if json.parse(text) == OK and json.data is Dictionary:
			entries.append(json.data)
	return entries


## Writes the whole log and the Workshop as it stands to one report file in
## `folder`: {path, runs, entries}, or {} if it couldn't be written.
static func export_report(workshop_state: Dictionary, path: String = PATH, folder: String = REPORTS) -> Dictionary:
	DirAccess.make_dir_recursive_absolute(folder)
	var stamp := Time.get_datetime_string_from_system(false).replace("-", "").replace(":", "")
	var out := "%s/number_go_up_report-%s.json" % [folder, stamp]
	var copy := 2
	while FileAccess.file_exists(out):
		out = "%s/number_go_up_report-%s-%d.json" % [folder, stamp, copy]
		copy += 1
	var entries := read(path)
	var file := FileAccess.open(out, FileAccess.WRITE)
	if file == null:
		push_warning("Couldn't write the report to %s." % out)
		return {}
	file.store_string(JSON.stringify({
		"format": FORMAT, "version": VERSION, "exported_at": Time.get_datetime_string_from_system(true),
		"game": game_version(), "workshop": workshop_state, "entries": entries,
	}, "", false, true))
	file.close()
	return {"path": out, "runs": entries.filter(func(entry): return entry.get("kind") == "run").size(), "entries": entries.size()}


## The commit the game is running, read from the checkout's .git folder (the
## owner plays from a git checkout), or "unknown" where there is none, as in an
## exported build.
static func game_version() -> String:
	if _game != "":
		return _game
	_game = "unknown"
	var head := _read("res://.git/HEAD")
	if head.begins_with("ref: "):
		var ref := head.substr(5)
		head = _read("res://.git/" + ref)
		if head == "":
			for line in _read("res://.git/packed-refs").split("\n"):
				if line.ends_with(" " + ref):
					head = line.get_slice(" ", 0)
	if head.length() >= 7 and head.is_valid_hex_number():
		_game = head.substr(0, 12)
	return _game


## A file's text, or "" without an engine error when it isn't there.
static func _read(path: String) -> String:
	return FileAccess.get_file_as_string(path).strip_edges() if FileAccess.file_exists(path) else ""
