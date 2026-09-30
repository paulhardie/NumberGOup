extends RefCounted
## One atomic file owns permanent progress and the active battle. Version 1
## migrates explicitly; newer files stay in place and disable progress writes.
const Workshop = preload("res://src/tower/workshop.gd")
const Progression = preload("res://src/tower/progression.gd")
const PATH := "user://number_go_up_tower.json"
const VERSION := 2


static func _read(path: String):
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(path)) != OK: return null
	return json.data


static func load_progress(path: String = PATH) -> Progression:
	var progress := Progression.new()
	if not FileAccess.file_exists(path): return progress
	var data = _read(path)
	if data is Dictionary and (data.get("version") is float or data.get("version") is int) and float(data.version) > VERSION:
		progress.writable = false
		progress.notice = "This save needs a newer game version. Progress is protected; update the game to continue."
		return progress
	if data is Dictionary and (data.get("version") == 1 or data.get("version") == VERSION) and data.get("workshop") is Dictionary:
		progress.workshop.restore(data.workshop)
		if data.version == 1:
			var backup := path + ".v1-backup.json"
			if FileAccess.file_exists(backup) and FileAccess.get_file_as_string(backup) != FileAccess.get_file_as_string(path):
				backup = path + ".v1-backup-%d.json" % Time.get_ticks_usec()
			if not FileAccess.file_exists(backup) and DirAccess.copy_absolute(path, backup) != OK:
				progress.writable = false
				progress.notice = "Couldn't back up the older save. Progress is protected until the save folder is writable."
				return progress
			# The old best is Tier 1's reached wave, not proof it was cleared.
			progress.observe(1, progress.workshop.best_wave, maxi(0, progress.workshop.best_wave - 1))
		elif data.get("progression") is Dictionary:
			progress.restore(data.progression)
			if not _valid_current(data, progress):
				progress.writable = false
				progress.notice = "The save contains unsupported or damaged progress. It has been kept untouched for recovery."
		else:
			progress.writable = false
			progress.notice = "The save is missing progression data. It has been kept untouched for recovery."
		return progress
	var aside := "%s.unreadable-%d.json" % [path.get_basename(), Time.get_ticks_usec()]
	if DirAccess.rename_absolute(path, aside) != OK:
		progress.writable = false
		progress.notice = "Couldn't read or move the save. It has been kept untouched for recovery."
	else:
		progress.notice = "The unreadable save was kept as %s. A fresh game is ready." % aside.get_file()
		push_warning(progress.notice)
	return progress


static func _view(value) -> String:
	var json := JSON.new()
	if json.parse(JSON.stringify(value, "", true, true)) != OK: return "invalid"
	return JSON.stringify(json.data, "", true, true)


static func _valid_current(data: Dictionary, progress: Progression) -> bool:
	# A repair in a current schema must not silently delete permanent progress.
	# Legacy sanitisation is backed up separately before the v1 migration.
	var workshop: Dictionary = data.workshop.duplicate(true)
	if workshop.has("coin_parts"):
		var parts = preload("res://src/tower/run_config.gd").unpack(workshop.coin_parts)
		if not parts is Dictionary or not parts.has("coins") or not parts.has("remainder"): return false
		workshop.coins = progress.workshop.coins
		workshop.coin_remainder = progress.workshop._coin_remainder
	return _view(workshop) == _view(progress.workshop.to_dict()) and _view(data.progression) == _view(progress.to_dict()) \
		and preload("res://src/tower/research.gd")._pending_valid(progress.research.completed_effects, progress.research.jobs)


static func load_workshop(path: String = PATH) -> Workshop:
	return load_progress(path).workshop


static func load_run(path: String = PATH) -> Dictionary:
	if not FileAccess.file_exists(path): return {}
	var data = _read(path)
	if not data is Dictionary or (data.get("version") != 1 and data.get("version") != VERSION): return {}
	var run = data.get("run")
	return run if run is Dictionary else {}


static func save_progress(progress: Progression, path: String = PATH, run: Dictionary = {}) -> bool:
	if not progress.writable: return false
	# Guard stale in-memory objects after another build wrote a newer schema.
	if FileAccess.file_exists(path):
		var existing = _read(path)
		if existing is Dictionary and (existing.get("version") is float or existing.get("version") is int) and float(existing.version) > VERSION:
			progress.writable = false
			return false
	var temporary := path + ".tmp"
	var file := FileAccess.open(temporary, FileAccess.WRITE)
	if file == null:
		push_warning("Couldn't write the save to %s." % temporary)
		return false
	var data := {"version": VERSION, "workshop": progress.workshop.to_dict(), "progression": progress.to_dict()}
	if not run.is_empty(): data.run = run
	file.store_string(JSON.stringify(data, "", true, true))
	file.flush()
	var written := file.get_error() == OK
	file.close()
	if not written: return false
	return DirAccess.rename_absolute(temporary, path) == OK


## Compatibility for tools/tests that own only a Workshop: preserve saved
## Gems and research rather than silently dropping the other domain.
static func save_workshop(workshop: Workshop, path: String = PATH, run: Dictionary = {}) -> bool:
	var progress := load_progress(path)
	progress.workshop = workshop
	return save_progress(progress, path, run)
