class_name AudioFeedback
extends AudioStreamPlayer

## Tiny embedded PCM samples. They are AudioStreamWAV samples, not a procedural
## AudioStreamGenerator, so the web export uses Godot's supported sample path.
var tick_sample: AudioStreamWAV
var critical_sample: AudioStreamWAV

func _ready() -> void:
	tick_sample = _make_sample(196.0, 0.10, 0.016, 0.34)
	critical_sample = _make_sample(262.0, 0.14, 0.024, 0.30)

func play_feedback(critical: bool, muted: bool) -> void:
	if muted:
		return
	stream = critical_sample if critical else tick_sample
	play()

## A soft, low tap. 16-bit: at these volumes an 8-bit sample resolves to a
## handful of levels, and that quantisation is the grain that read as a blip.
## Both ends of the envelope are eased — attack_fraction ramps in from silence
## over that fraction of the sample, and the decay is a raised cosine rather
## than a power curve, so neither the onset nor the tail has a corner for the
## ear to catch.
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
