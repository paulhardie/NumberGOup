extends RefCounted
## The player's settings (D088), in their own small file apart from the save,
## so a preference can never put progress at risk. A file that can't be read,
## or a value that isn't what it should be, falls back to the default. Older
## files may still carry "show_range" (D096), the testing switches
## "multipliers", "peak_regen" and "kill_growth" (D097, D098), which the game no
## longer has (D111), or "number_cash", the Testing switch of D156, which
## became the game's rules (D158); they are ignored, and dropped the next time
## the file is written.

const RunConfig = preload("res://src/tower/run_config.gd")

const PATH := "user://number_go_up_settings.json"
const VERSION := 1

## The generative music (D092); on by default. Missing from older files, so on.
var music := true
## Run upgrades off (D158): the run shop is shut for each new run. Chosen before
## a run, never during one; off unless set.
var upgrades_off := false
## The invaders view (D166, a prototype): the Number at the bottom, enemies
## coming down from the top. Drawing only; off unless set.
var invaders := false


func read(path: String = PATH) -> void:
	if not FileAccess.file_exists(path):
		return
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(path)) != OK or not json.data is Dictionary:
		return
	var playing = json.data.get("music", true)
	music = playing if playing is bool else true
	var shut = json.data.get("upgrades_off", false)
	upgrades_off = shut if shut is bool else false
	var view = json.data.get("invaders", false)
	invaders = view if view is bool else false


## The rules a new run starts with: the game's (RunConfig.game_tuning), with the
## run shop shut if the player chose that.
func run_tuning() -> Dictionary:
	return RunConfig.game_tuning(upgrades_off)


## Writes to a temporary file first and then swaps it in, as the save does.
func write(path: String = PATH) -> bool:
	var temporary := path + ".tmp"
	var file := FileAccess.open(temporary, FileAccess.WRITE)
	if file == null:
		push_warning("Couldn't write the settings to %s." % temporary)
		return false
	file.store_string(JSON.stringify({"version": VERSION, "music": music, "upgrades_off": upgrades_off, "invaders": invaders}, "\t"))
	file.flush()
	var written := file.get_error() == OK
	file.close()
	if not written:
		return false
	return DirAccess.rename_absolute(temporary, path) == OK
