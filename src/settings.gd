extends RefCounted
## The player's settings (D088), in their own small file apart from the save,
## so a preference can never put progress at risk. A file that can't be read,
## or a value that isn't what it should be, falls back to the default. Older
## files may still carry "show_range", which the game no longer has (D096);
## it is ignored, and dropped the next time the file is written.

const PATH := "user://number_go_up_settings.json"
const VERSION := 1

## The generative music (D092); on by default. Missing from older files, so on.
var music := true
## Tests (D097, D098), all off by default: battles send Multipliers, the
## Divider's mirror; regen stops at the Number's best; kills grow the Number.
var multipliers := false
var peak_regen := false
var kill_growth := false


## The tests a new battle plays by, as BattleSim takes them.
func switches() -> Dictionary:
	return {"multipliers": multipliers, "peak_regen": peak_regen, "kill_growth": kill_growth}


func read(path: String = PATH) -> void:
	if not FileAccess.file_exists(path):
		return
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(path)) != OK or not json.data is Dictionary:
		return
	var playing = json.data.get("music", true)
	music = playing if playing is bool else true
	multipliers = json.data.get("multipliers", false) == true
	peak_regen = json.data.get("peak_regen", false) == true
	kill_growth = json.data.get("kill_growth", false) == true


## Writes to a temporary file first and then swaps it in, as the save does.
func write(path: String = PATH) -> bool:
	var temporary := path + ".tmp"
	var file := FileAccess.open(temporary, FileAccess.WRITE)
	if file == null:
		push_warning("Couldn't write the settings to %s." % temporary)
		return false
	file.store_string(JSON.stringify({"version": VERSION, "music": music, "multipliers": multipliers, "peak_regen": peak_regen,
		"kill_growth": kill_growth}, "\t"))
	file.close()
	return DirAccess.rename_absolute(temporary, path) == OK
