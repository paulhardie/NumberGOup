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
	tick_sample = _make_sample(196.0, 0.10, 0.016, 0.34)
	critical_sample = _make_sample(262.0, 0.14, 0.024, 0.30)
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

## A soft, low tap. 16-bit for the same reason the pad below is: at these
## volumes an 8-bit sample resolves to a handful of levels, and that
## quantisation is the grain that read as a blip. Both ends of the envelope are
## eased — attack_fraction ramps in from silence over that fraction of the
## sample, and the decay is a raised cosine rather than a power curve, so
## neither the onset nor the tail has a corner for the ear to catch.
func _make_sample(frequency: float, duration: float, volume: float, attack_fraction: float = 0.0) -> AudioStreamWAV:
	var sample_rate := 22050
	var frames := int(duration * sample_rate)
	var attack_frames := maxi(1, int(attack_fraction * frames))
	var bytes := PackedByteArray()
	bytes.resize(frames * 2)
	for frame in range(frames):
		var progress := float(frame) / float(frames)
		var decay := 0.5 + 0.5 * cos(PI * progress)
		var attack := minf(1.0, float(frame) / float(attack_frames))
		var envelope := decay * attack * attack
		var wave := sin(TAU * frequency * float(frame) / float(sample_rate))
		bytes.encode_s16(frame * 2, clampi(roundi(wave * volume * envelope * 32767.0), -32768, 32767))
	var result := AudioStreamWAV.new()
	result.format = AudioStreamWAV.FORMAT_16_BITS
	result.mix_rate = sample_rate
	result.stereo = false
	result.data = bytes
	return result

## A hushed, slow-breathing pad: a soft open fifth (A2 + E3) with a faint
## octave shimmer on top, amplitude-swelled once per loop so it never reads as
## a static drone. Every tone and the swell complete a whole number of cycles
## across the loop's exact duration, so the wrap point is click-free without
## needing a manual crossfade.
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
