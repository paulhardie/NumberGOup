extends SceneTree
## Records the game's generative music (D092) to user://music_preview.wav, so
## it can be listened to outside the game or shared. It plays in real time:
##
##   bash run_godot.sh --headless --path . -s res://tools/record_music.gd -- --seconds 90
##
## Only the music plays; no save, settings or battle is touched.

const AmbientMusic = preload("res://src/ui/ambient_music.gd")
const PATH := "user://music_preview.wav"


func _init() -> void:
	_record.call_deferred()


func _record() -> void:
	var seconds := 60.0
	var args := OS.get_cmdline_user_args()
	var at := args.find("--seconds")
	if at >= 0 and at + 1 < args.size():
		seconds = float(args[at + 1])
	var music := AmbientMusic.new()
	root.add_child(music)
	await process_frame
	# On the master bus, so the file is what a player hears, after every volume.
	var recorder := AudioEffectRecord.new()
	AudioServer.add_bus_effect(0, recorder)
	recorder.set_recording_active(true)
	await create_timer(seconds).timeout
	recorder.set_recording_active(false)
	var recording := recorder.get_recording()
	if recording == null:
		printerr("Nothing was recorded: this Godot has no running audio driver.")
		quit(1)
		return
	recording.save_to_wav(PATH)
	print("wrote %.0f s to %s" % [seconds, ProjectSettings.globalize_path(PATH)])
	music.queue_free()
	await process_frame
	quit()
