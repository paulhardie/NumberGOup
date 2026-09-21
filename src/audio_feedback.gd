class_name AudioFeedback
extends AudioStreamPlayer

## Tiny embedded PCM samples. They are AudioStreamWAV samples, not a procedural
## AudioStreamGenerator, so the web export uses Godot's supported sample path.
var tick_sample: AudioStreamWAV
var critical_sample: AudioStreamWAV

func _ready() -> void:
	tick_sample = _make_sample(520.0, 0.045, 0.12)
	critical_sample = _make_sample(880.0, 0.11, 0.17)

func play_feedback(critical: bool, muted: bool) -> void:
	if muted:
		return
	stream = critical_sample if critical else tick_sample
	play()

func _make_sample(frequency: float, duration: float, volume: float) -> AudioStreamWAV:
	var sample_rate := 22050
	var frames := int(duration * sample_rate)
	var bytes := PackedByteArray()
	bytes.resize(frames)
	for frame in range(frames):
		var progress := float(frame) / float(frames)
		var envelope := pow(1.0 - progress, 2.4)
		var wave := sin(TAU * frequency * float(frame) / float(sample_rate))
		bytes[frame] = clampi(int(128.0 + wave * 127.0 * volume * envelope), 0, 255)
	var result := AudioStreamWAV.new()
	result.format = AudioStreamWAV.FORMAT_8_BITS
	result.mix_rate = sample_rate
	result.stereo = false
	result.data = bytes
	return result
