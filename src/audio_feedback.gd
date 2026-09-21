class_name AudioFeedback
extends AudioStreamPlayer

## Tiny embedded PCM samples. They are AudioStreamWAV samples, not a procedural
## AudioStreamGenerator, so the web export uses Godot's supported sample path.
var tick_sample: AudioStreamWAV
var critical_sample: AudioStreamWAV

## A second, dedicated player for the looping ambient pad: the base player's
## stream gets swapped and replayed on every tap, which would cut the pad off
## mid-loop if it shared the same node.
var ambience_player: AudioStreamPlayer
const AMBIENCE_VOLUME := 0.045

func _ready() -> void:
	tick_sample = _make_sample(250.0, 0.06, 0.05, 0.15)
	critical_sample = _make_sample(660.0, 0.14, 0.09, 0.12)
	ambience_player = AudioStreamPlayer.new()
	ambience_player.stream = _make_ambience_sample()
	add_child(ambience_player)

func play_feedback(critical: bool, muted: bool) -> void:
	if muted:
		return
	stream = critical_sample if critical else tick_sample
	play()

## Starts or stops the looping ambient pad. Safe to call every time a setting
## changes: it only acts when the requested state differs from the current one.
func set_ambience_enabled(enabled: bool) -> void:
	if enabled and not ambience_player.playing:
		ambience_player.play()
	elif not enabled and ambience_player.playing:
		ambience_player.stop()

## frequency/duration/volume as before; attack_fraction ramps the envelope in
## from silence over that fraction of the sample instead of starting at full
## volume, which is what read as a harsh click rather than a soft tap.
func _make_sample(frequency: float, duration: float, volume: float, attack_fraction: float = 0.0) -> AudioStreamWAV:
	var sample_rate := 22050
	var frames := int(duration * sample_rate)
	var attack_frames := maxi(1, int(attack_fraction * frames))
	var bytes := PackedByteArray()
	bytes.resize(frames)
	for frame in range(frames):
		var progress := float(frame) / float(frames)
		var decay := pow(1.0 - progress, 2.4)
		var attack := minf(1.0, float(frame) / float(attack_frames))
		var envelope := decay * attack
		var wave := sin(TAU * frequency * float(frame) / float(sample_rate))
		bytes[frame] = clampi(int(128.0 + wave * 127.0 * volume * envelope), 0, 255)
	var result := AudioStreamWAV.new()
	result.format = AudioStreamWAV.FORMAT_8_BITS
	result.mix_rate = sample_rate
	result.stereo = false
	result.data = bytes
	return result

## A hushed, slow-breathing pad: a soft open fifth (A2 + E3) with a faint
## octave shimmer on top, amplitude-swelled once per loop so it never reads as
## a static drone. Every tone and the swell complete a whole number of cycles
## across the loop's exact duration, so the wrap point is click-free without
## needing a manual crossfade. 16-bit rather than the 8-bit used for the short
## UI blips above: a sustained quiet tone shows 8-bit quantisation as audible
## graininess in a way a 60ms tap does not.
func _make_ambience_sample() -> AudioStreamWAV:
	var sample_rate := 22050
	var duration := 8.0
	var frames := int(duration * sample_rate)
	var bytes := PackedByteArray()
	bytes.resize(frames * 2)
	for frame in range(frames):
		var t := float(frame) / float(sample_rate)
		var swell := 0.75 + 0.25 * sin(TAU * (1.0 / duration) * t)
		var wave := 0.5 * sin(TAU * 110.0 * t) + 0.35 * sin(TAU * 165.0 * t) + 0.15 * sin(TAU * 220.0 * t)
		var value := clampi(roundi(wave * swell * AMBIENCE_VOLUME * 32767.0), -32768, 32767)
		bytes.encode_s16(frame * 2, value)
	var result := AudioStreamWAV.new()
	result.format = AudioStreamWAV.FORMAT_16_BITS
	result.mix_rate = sample_rate
	result.stereo = false
	result.data = bytes
	result.loop_mode = AudioStreamWAV.LOOP_FORWARD
	result.loop_begin = 0
	result.loop_end = frames
	return result
