extends RefCounted
## Saved UTC high-water mark. A backwards clock earns no time twice.
## Research and later away play share this clock, not the battle speed.

const LAST_SUPPORTED_UTC := 253402300799.0
var last_utc := -1.0


func advance(now: float = Time.get_unix_time_from_system()) -> float:
	if not is_finite(now) or now < 0.0 or now > LAST_SUPPORTED_UTC:
		return 0.0
	if last_utc < 0.0:
		last_utc = now
		return 0.0
	var elapsed := maxf(now - last_utc, 0.0)
	last_utc = maxf(last_utc, now)
	return elapsed


func restore(value) -> void:
	if (value is int or value is float) and is_finite(float(value)) and float(value) >= -1.0 and float(value) <= LAST_SUPPORTED_UTC:
		last_utc = float(value)
