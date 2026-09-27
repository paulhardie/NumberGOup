extends Node
## The game's music (D091, D092): soft ambient made as it plays, never a
## recording, so nobody else owns it and it never loops. Slow chords of soft
## tones swell and fade into one another on uneven timings, now and then a
## glassy note sounds over them, a faint tape hiss sits beneath, and all of it
## runs through a low-pass, a chorus and a long reverb, drifting slightly flat
## with a slow wobble: the slowed, washed-out sound of slushwave. It plays the
## same on every screen and never touches the battle.
##
## Only two tiny waveforms are made, once; Godot's mixer plays and pitches them
## and runs the effects, so the music costs next to nothing on a phone.

const BUS := "Music"
const VOLUME_DB := -12.0
## A chord holds for somewhere in this range of seconds, the next swelling in
## over SWELL_SECONDS while the last fades over FADE_SECONDS.
const CHORD_SECONDS := Vector2(14.0, 24.0)
const SWELL_SECONDS := 7.0
const FADE_SECONDS := 9.0
## Each chord tone is two voices this many cents apart, for a slow beating.
const DETUNE_CENTS := 6.0
const PAD_DB := -31.0
## A glassy note sounds every so often, rings in quickly and dies away slowly.
const GLASS_SECONDS := Vector2(5.0, 14.0)
const GLASS_DB := -29.0
const GLASS_RING_SECONDS := 7.0
const HISS_DB := -40.0
## The whole thing sits a little flat and wobbles like a slowed tape.
const TAPE_FLAT := 0.985
const TAPE_WOW := 0.004
const SILENT_DB := -60.0

## A single cycle of each waveform loops at this pitch; other notes play it
## faster or slower. C3.
const BASE_MIDI := 48
const BASE_HZ := 130.8128
const CYCLE_SAMPLES := 256

## Chords in D-flat major, as MIDI notes, spread wide: a low root and open
## sevenths and ninths above, the colour of the genre.
const CHORDS := [
	[37, 44, 53, 60, 63],  # D-flat major nine
	[34, 49, 53, 56, 60],  # B-flat minor nine
	[42, 49, 53, 58, 60],  # G-flat major seven, sharp eleven
	[41, 48, 51, 56, 58],  # F minor eleven
	[39, 46, 49, 53, 54],  # E-flat minor nine
	[44, 51, 58, 60, 63],  # A-flat, added nine
]
## Glassy notes come from the chord's tones, lifted into this range.
const GLASS_RANGE := Vector2i(68, 86)

var _rng := RandomNumberGenerator.new()
var _pad: AudioStreamWAV
var _glass: AudioStreamWAV
var _hiss: AudioStreamPlayer
## Every sounding voice and its pitch before the tape's wobble: {player, pitch}.
var _voices: Array[Dictionary] = []
## The chord sounding now, as its voices.
var _chord: Array[Dictionary] = []
var _chord_index := -1
var _next_chord_in := 0.0
var _next_glass_in := 4.0
var _time := 0.0
var _playing := true


func _ready() -> void:
	_rng.randomize()
	_make_bus()
	_pad = _cycle(func(phase: float) -> float: return sin(phase) + 0.22 * sin(2.0 * phase) + 0.06 * sin(3.0 * phase))
	_glass = _cycle(func(phase: float) -> float: return sin(phase) + 0.12 * sin(3.0 * phase) + 0.05 * sin(5.0 * phase))
	_hiss = AudioStreamPlayer.new()
	_hiss.stream = _noise()
	_hiss.bus = BUS
	_hiss.volume_db = HISS_DB
	add_child(_hiss)
	set_playing(_playing)


## Turns the music on or off (the player's setting, D092). Off, nothing plays
## and nothing is scheduled.
func set_playing(on: bool) -> void:
	_playing = on
	if not is_inside_tree():
		return
	AudioServer.set_bus_mute(AudioServer.get_bus_index(BUS), not on)
	set_process(on)
	if on:
		if not _hiss.playing:
			_hiss.play()
		if _chord.is_empty():
			_next_chord_in = 0.0
	else:
		_hiss.stop()
		for voice in _voices:
			(voice.player as AudioStreamPlayer).queue_free()
		_voices.clear()
		_chord.clear()


func is_playing() -> bool:
	return _playing


func _process(delta: float) -> void:
	_time += delta
	_next_chord_in -= delta
	if _next_chord_in <= 0.0:
		_change_chord()
		_next_chord_in = _rng.randf_range(CHORD_SECONDS.x, CHORD_SECONDS.y)
	_next_glass_in -= delta
	if _next_glass_in <= 0.0:
		_ring_glass()
		_next_glass_in = _rng.randf_range(GLASS_SECONDS.x, GLASS_SECONDS.y)
	# The tape: a little flat, wobbling on two slow sways that never line up.
	var tape := TAPE_FLAT * (1.0 + TAPE_WOW * sin(_time * 0.53) + TAPE_WOW * 0.5 * sin(_time * 1.37 + 1.1))
	_voices = _voices.filter(func(voice): return is_instance_valid(voice.player))
	for voice in _voices:
		(voice.player as AudioStreamPlayer).pitch_scale = voice.pitch * tape


## The next chord swells in as the last fades. Never the same chord twice running.
func _change_chord() -> void:
	for voice in _chord:
		_fade_out(voice.player, FADE_SECONDS)
	_chord.clear()
	var index := _rng.randi_range(0, CHORDS.size() - 1)
	if index == _chord_index:
		index = (index + 1 + _rng.randi_range(0, CHORDS.size() - 2)) % CHORDS.size()
	_chord_index = index
	for note in CHORDS[index]:
		for side in [-1.0, 1.0]:
			# The root sits a little louder, the top a little quieter.
			var level: float = PAD_DB + (2.0 if note == CHORDS[index][0] else 0.0) - (2.0 if note >= 60 else 0.0)
			var voice := _voice(_pad, _pitch(note, side * DETUNE_CENTS * 0.5))
			_chord.append(voice)
			# Each tween belongs to its voice, so turning the music off mid-swell
			# frees the two together.
			var swell: Tween = voice.player.create_tween()
			swell.tween_property(voice.player, "volume_db", level, SWELL_SECONDS * _rng.randf_range(0.8, 1.2)).set_trans(Tween.TRANS_SINE)


## A glassy note from the chord sounding now, high up, ringing and dying away.
func _ring_glass() -> void:
	if _chord_index < 0:
		return
	var choices: Array[int] = []
	for note in CHORDS[_chord_index]:
		var high: int = note
		while high < GLASS_RANGE.x:
			high += 12
		if high <= GLASS_RANGE.y:
			choices.append(high)
	if choices.is_empty():
		return
	var voice := _voice(_glass, _pitch(choices[_rng.randi_range(0, choices.size() - 1)], 0.0))
	var ring: Tween = voice.player.create_tween()
	ring.tween_property(voice.player, "volume_db", GLASS_DB + _rng.randf_range(-4.0, 0.0), 0.35)
	ring.tween_property(voice.player, "volume_db", SILENT_DB, GLASS_RING_SECONDS * _rng.randf_range(0.7, 1.3)).set_ease(Tween.EASE_OUT)
	ring.tween_callback(voice.player.queue_free)


func _voice(stream: AudioStreamWAV, pitch: float) -> Dictionary:
	var player := AudioStreamPlayer.new()
	player.stream = stream
	player.bus = BUS
	player.volume_db = SILENT_DB
	player.pitch_scale = pitch
	add_child(player)
	player.play()
	var voice := {"player": player, "pitch": pitch}
	_voices.append(voice)
	return voice


func _fade_out(player: AudioStreamPlayer, seconds: float) -> void:
	if not is_instance_valid(player):
		return
	var fade := player.create_tween()
	fade.tween_property(player, "volume_db", SILENT_DB, seconds).set_trans(Tween.TRANS_SINE)
	fade.tween_callback(player.queue_free)


## How fast to play the waveform's one cycle for a MIDI note, nudged by cents.
static func _pitch(midi: int, cents: float) -> float:
	return pow(2.0, (midi - BASE_MIDI + cents / 100.0) / 12.0)


## One cycle of a waveform, looping, pitched at BASE_HZ.
func _cycle(shape: Callable) -> AudioStreamWAV:
	var samples := PackedFloat32Array()
	samples.resize(CYCLE_SAMPLES)
	var peak := 0.0
	for i in CYCLE_SAMPLES:
		samples[i] = shape.call(TAU * i / CYCLE_SAMPLES)
		peak = maxf(peak, absf(samples[i]))
	var stream := _sixteen_bit(samples, peak)
	stream.mix_rate = int(roundf(BASE_HZ * CYCLE_SAMPLES))
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_end = CYCLE_SAMPLES
	return stream


## A few seconds of soft, dark noise, looping: the tape's hiss.
func _noise() -> AudioStreamWAV:
	var rate := 22050
	var samples := PackedFloat32Array()
	samples.resize(rate * 3)
	var level := 0.0
	var peak := 0.0
	for i in samples.size():
		# Each sample leans a little toward a random one: brown-ish, soft, no hiss's edge.
		level = lerpf(level, _rng.randf_range(-1.0, 1.0), 0.08)
		samples[i] = level
		peak = maxf(peak, absf(level))
	# The loop's two ends meet at the same level, so it has no click.
	var seam := 400
	for i in seam:
		var blend := float(i) / seam
		samples[samples.size() - seam + i] = lerpf(samples[samples.size() - seam + i], samples[i], blend)
	var stream := _sixteen_bit(samples, peak)
	stream.mix_rate = rate
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_end = samples.size()
	return stream


static func _sixteen_bit(samples: PackedFloat32Array, peak: float) -> AudioStreamWAV:
	var bytes := PackedByteArray()
	bytes.resize(samples.size() * 2)
	for i in samples.size():
		bytes.encode_s16(i * 2, int(samples[i] / maxf(peak, 0.0001) * 30000.0))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.data = bytes
	return stream


## The music's own bus: dark, thickened and washed in a long reverb.
func _make_bus() -> void:
	if AudioServer.get_bus_index(BUS) != -1:
		return
	AudioServer.add_bus()
	var index := AudioServer.bus_count - 1
	AudioServer.set_bus_name(index, BUS)
	AudioServer.set_bus_send(index, "Master")
	AudioServer.set_bus_volume_db(index, VOLUME_DB)
	var dark := AudioEffectLowPassFilter.new()
	dark.cutoff_hz = 2200.0
	AudioServer.add_bus_effect(index, dark)
	var thick := AudioEffectChorus.new()
	thick.wet = 0.2
	AudioServer.add_bus_effect(index, thick)
	var wash := AudioEffectReverb.new()
	wash.room_size = 0.95
	wash.damping = 0.35
	# Wide, but not so wide that a phone's one speaker loses it.
	wash.spread = 0.55
	wash.predelay_msec = 60.0
	wash.wet = 0.5
	wash.dry = 0.7
	AudioServer.add_bus_effect(index, wash)
