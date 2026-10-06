extends RefCounted
## One atomic file owns permanent progress and the active battle. Versions 1
## to 3 migrate explicitly, each kept first as a backup; newer files stay in
## place and disable progress writes. Version 3 adds Cards (D146); version 4
## the best Number earned, which the digit ladder climbs (D164).
const Workshop = preload("res://src/tower/workshop.gd")
const Progression = preload("res://src/tower/progression.gd")
const PATH := "user://number_go_up_tower.json"
const VERSION := 4
## The older versions this build migrates.
const OLDER := [1, 2, 3]


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
	if data is Dictionary and _known(data.get("version")) and data.get("workshop") is Dictionary:
		progress.workshop.restore(data.workshop)
		if int(data.version) != VERSION:
			var backup := path + ".v%d-backup.json" % int(data.version)
			if FileAccess.file_exists(backup) and FileAccess.get_file_as_string(backup) != FileAccess.get_file_as_string(path):
				backup = path + ".v%d-backup-%d.json" % [int(data.version), Time.get_ticks_usec()]
			if not FileAccess.file_exists(backup) and DirAccess.copy_absolute(path, backup) != OK:
				progress.writable = false
				progress.notice = "Couldn't back up the older save. Progress is protected until the save folder is writable."
				return progress
		if int(data.version) == 1:
			if data.workshop.has("best_earned"):
				# No version-1 build wrote one (D164): a claimed best could pay digits twice.
				progress.writable = false
				progress.notice = "The save contains unsupported or damaged progress. It has been kept untouched for recovery."
				return progress
			# The old best is Tier 1's reached wave, not proof it was cleared.
			progress.observe(1, progress.workshop.best_wave, maxi(0, progress.workshop.best_wave - 1))
		elif data.get("progression") is Dictionary:
			var migrated = _migrated(data)
			if migrated == null:
				progress.writable = false
				progress.notice = "The save contains unsupported or damaged progress. It has been kept untouched for recovery."
				return progress
			progress.restore(migrated)
			if not _valid_current(_migrated_workshop(data, progress), migrated, progress):
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


## A version-2 or current save's progression as the current schema holds it:
## version 2 had no Cards and gains an empty collection (D146). Null if a
## version-2 save already claims Cards, which no version-2 build wrote.
static func _migrated(data: Dictionary):
	var progression: Dictionary = data.progression.duplicate(true)
	if int(data.version) == 2:
		if progression.has("cards"): return null
		progression.cards = preload("res://src/tower/cards.gd").new().to_dict()
	return progression


## A saved Workshop as the current schema holds it: before version 4 there was
## no best Number earned, and the Workshop seeds it from the best peak (D164).
## Null if an older save already claims one, which no older build wrote.
static func _migrated_workshop(data: Dictionary, progress: Progression):
	var workshop: Dictionary = data.workshop.duplicate(true)
	if int(data.version) < 4:
		if workshop.has("best_earned"): return null
		workshop.best_earned = progress.workshop.best_earned
	return workshop


static func _known(version) -> bool:
	return (version is int or version is float) and (int(version) == VERSION or int(version) in OLDER) and float(version) == int(version)


static func _view(value) -> String:
	var json := JSON.new()
	if json.parse(JSON.stringify(value, "", true, true)) != OK: return "invalid"
	return JSON.stringify(json.data, "", true, true)


static func _valid_current(saved_workshop, progression: Dictionary, progress: Progression) -> bool:
	# A repair in a current schema must not silently delete permanent progress.
	# Legacy sanitisation is backed up separately before the v1 migration.
	if not saved_workshop is Dictionary: return false
	var workshop: Dictionary = saved_workshop.duplicate(true)
	if workshop.has("coin_parts"):
		var parts = preload("res://src/tower/run_config.gd").unpack(workshop.coin_parts)
		if not parts is Dictionary or not parts.has("coins") or not parts.has("remainder"): return false
		workshop.coins = progress.workshop.coins
		workshop.coin_remainder = progress.workshop._coin_remainder
	return _view(workshop) == _view(progress.workshop.to_dict()) and _view(progression) == _view(progress.to_dict()) \
		and preload("res://src/tower/research.gd")._pending_valid(progress.research.completed_effects, progress.research.jobs)


static func load_workshop(path: String = PATH) -> Workshop:
	return load_progress(path).workshop


static func load_run(path: String = PATH) -> Dictionary:
	if not FileAccess.file_exists(path): return {}
	var data = _read(path)
	if not data is Dictionary or not _known(data.get("version")): return {}
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
