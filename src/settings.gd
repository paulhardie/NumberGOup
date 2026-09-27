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
## A test (D097): battles send Multipliers, the Divider's mirror. Off by default.
var multipliers := false


func read(path: String = PATH) -> void:
	if not FileAccess.file_exists(path):
		return
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(path)) != OK or not json.data is Dictionary:
		return
	var playing = json.data.get("music", true)
	music = playing if playing is bool else true
	var multiplying = json.data.get("multipliers", false)
	multipliers = multiplying is bool and multiplying


## Writes to a temporary file first and then swaps it in, as the save does.
func write(path: String = PATH) -> bool:
	var temporary := path + ".tmp"
	var file := FileAccess.open(temporary, FileAccess.WRITE)
	if file == null:
		push_warning("Couldn't write the settings to %s." % temporary)
		return false
	file.store_string(JSON.stringify({"version": VERSION, "music": music, "multipliers": multipliers}, "\t"))
	file.close()
	return DirAccess.rename_absolute(temporary, path) == OK
